import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:vespera/services/recognition/recognition_models.dart';

class PeakExtractionException implements Exception {
  final String message;

  const PeakExtractionException(this.message);

  @override
  String toString() => 'PeakExtractionException: $message';
}

class PeakExtractor {
  const PeakExtractor();

  Future<PeakExtractionResult> extractPeaks({
    required String wavPath,
    required int targetSampleRateHz,
    required int windowSize,
    required int hopSize,
    required int localMaxNeighborhoodSize,
    required double minAmplitudeDb,
    required double minFrequencyHz,
    required double maxFrequencyHz,
    required int maxPeaks,
    required double minDurationSeconds,
    required double maxDurationSeconds,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    final _WavData wav = await _readWav(wavPath);

    if (wav.samples.isEmpty) {
      throw const PeakExtractionException('WAV contains no audio samples');
    }

    List<double> mono = wav.samples;
    if (wav.channels > 1) {
      mono = _toMono(wav.samples, wav.channels);
    }

    List<double> resampled = mono;
    if (wav.sampleRate != targetSampleRateHz) {
      resampled = _resampleLinear(mono, wav.sampleRate, targetSampleRateHz);
    }

    final double fullDuration = resampled.length / targetSampleRateHz;
    if (fullDuration < minDurationSeconds) {
      throw PeakExtractionException(
        'Clip too short (${fullDuration.toStringAsFixed(2)}s). Minimum is $minDurationSeconds s.',
      );
    }

    final int maxSamples = (maxDurationSeconds * targetSampleRateHz).floor();
    if (resampled.length > maxSamples) {
      resampled = resampled.sublist(0, maxSamples);
    }

    final List<AudioPeak> peaks = _extractStftPeaks(
      samples: resampled,
      sampleRateHz: targetSampleRateHz,
      windowSize: windowSize,
      hopSize: hopSize,
      localMaxNeighborhoodSize: localMaxNeighborhoodSize,
      minAmplitudeDb: minAmplitudeDb,
      minFrequencyHz: minFrequencyHz,
      maxFrequencyHz: maxFrequencyHz,
      maxPeaks: maxPeaks,
    );

    sw.stop();

    return PeakExtractionResult(
      peaks: peaks,
      preprocessingDuration: sw.elapsed,
      sourceSampleRate: wav.sampleRate,
      outputSampleRate: targetSampleRateHz,
      clipDurationSeconds: resampled.length / targetSampleRateHz,
    );
  }

  List<AudioPeak> _extractStftPeaks({
    required List<double> samples,
    required int sampleRateHz,
    required int windowSize,
    required int hopSize,
    required int localMaxNeighborhoodSize,
    required double minAmplitudeDb,
    required double minFrequencyHz,
    required double maxFrequencyHz,
    required int maxPeaks,
  }) {
    if (samples.length < windowSize) {
      return const <AudioPeak>[];
    }

    final int frameCount = 1 + ((samples.length - windowSize) ~/ hopSize);
    final List<double> window = _hann(windowSize);

    final List<double> real = List<double>.filled(windowSize, 0.0);
    final List<double> imag = List<double>.filled(windowSize, 0.0);

    final int bins = windowSize ~/ 2;
    final double binHz = sampleRateHz / windowSize;
    final int minBin = max(0, (minFrequencyHz / binHz).ceil());
    final int maxBin = min(bins - 1, (maxFrequencyHz / binHz).floor());

    if (minBin > maxBin) {
      throw const PeakExtractionException(
        'Invalid frequency band for peak extraction.',
      );
    }

    final int bandBins = (maxBin - minBin) + 1;
    final List<Float32List> spectrogramDb = List<Float32List>.generate(
      frameCount,
      (_) => Float32List(bandBins),
      growable: false,
    );

    for (int frame = 0; frame < frameCount; frame++) {
      final int offset = frame * hopSize;
      for (int i = 0; i < windowSize; i++) {
        real[i] = samples[offset + i] * window[i];
        imag[i] = 0.0;
      }

      _fft(real, imag);

      for (int bandOffset = 0; bandOffset < bandBins; bandOffset++) {
        final int bin = minBin + bandOffset;
        final double power = (real[bin] * real[bin]) + (imag[bin] * imag[bin]);
        spectrogramDb[frame][bandOffset] = _powerToDb(power);
      }
    }

    final int neighborhood = max(1, localMaxNeighborhoodSize);
    final List<_DetectedPeak> candidates = <_DetectedPeak>[];

    for (int frame = 0; frame < frameCount; frame++) {
      final int tStart = max(0, frame - neighborhood);
      final int tEnd = min(frameCount - 1, frame + neighborhood);

      for (int bandOffset = 0; bandOffset < bandBins; bandOffset++) {
        final double valueDb = spectrogramDb[frame][bandOffset];
        if (valueDb < minAmplitudeDb) {
          continue;
        }

        final int fStart = max(0, bandOffset - neighborhood);
        final int fEnd = min(bandBins - 1, bandOffset + neighborhood);

        bool isLocalMaximum = true;
        for (int t = tStart; t <= tEnd && isLocalMaximum; t++) {
          for (int f = fStart; f <= fEnd; f++) {
            if (t == frame && f == bandOffset) {
              continue;
            }

            final double neighborDb = spectrogramDb[t][f];
            if (neighborDb > valueDb) {
              isLocalMaximum = false;
              break;
            }

            if (neighborDb == valueDb &&
                (t < frame || (t == frame && f < bandOffset))) {
              isLocalMaximum = false;
              break;
            }
          }
        }

        if (!isLocalMaximum) {
          continue;
        }

        candidates.add(
          _DetectedPeak(
            freqIdx: minBin + bandOffset,
            timeIdx: frame,
            amplitudeDb: valueDb,
          ),
        );
      }
    }

    candidates.sort((a, b) {
      final int ampSort = b.amplitudeDb.compareTo(a.amplitudeDb);
      if (ampSort != 0) {
        return ampSort;
      }
      final int timeSort = a.timeIdx.compareTo(b.timeIdx);
      if (timeSort != 0) {
        return timeSort;
      }
      return a.freqIdx.compareTo(b.freqIdx);
    });

    if (candidates.length > maxPeaks) {
      candidates.removeRange(maxPeaks, candidates.length);
    }

    candidates.sort((a, b) {
      final int timeSort = a.timeIdx.compareTo(b.timeIdx);
      if (timeSort != 0) {
        return timeSort;
      }
      return a.freqIdx.compareTo(b.freqIdx);
    });

    final List<AudioPeak> peaks = candidates
        .map((p) => AudioPeak(freqIdx: p.freqIdx, timeIdx: p.timeIdx))
        .toList(growable: false);

    return peaks;
  }

  double _powerToDb(double power) {
    final double clampedPower = power <= 1e-12 ? 1e-12 : power;
    return 10.0 * (log(clampedPower) / ln10);
  }

  Future<_WavData> _readWav(String wavPath) async {
    final File file = File(wavPath);
    if (!await file.exists()) {
      throw const PeakExtractionException('WAV file does not exist');
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length < 44) {
      throw const PeakExtractionException('Invalid WAV: too short');
    }

    final ByteData data = ByteData.sublistView(bytes);

    String readString(int offset, int length) {
      return String.fromCharCodes(bytes.sublist(offset, offset + length));
    }

    if (readString(0, 4) != 'RIFF' || readString(8, 4) != 'WAVE') {
      throw const PeakExtractionException('Invalid WAV header');
    }

    int? sampleRate;
    int? channels;
    int? bitsPerSample;
    int? dataStart;
    int? dataLength;

    int cursor = 12;
    while (cursor + 8 <= bytes.length) {
      final String chunkId = readString(cursor, 4);
      final int chunkSize = data.getUint32(cursor + 4, Endian.little);
      final int chunkDataStart = cursor + 8;
      final int nextChunk = chunkDataStart + chunkSize;

      if (chunkId == 'fmt ') {
        final int audioFormat = data.getUint16(chunkDataStart, Endian.little);
        channels = data.getUint16(chunkDataStart + 2, Endian.little);
        sampleRate = data.getUint32(chunkDataStart + 4, Endian.little);
        bitsPerSample = data.getUint16(chunkDataStart + 14, Endian.little);

        if (audioFormat != 1) {
          throw const PeakExtractionException(
            'Unsupported WAV format. Only PCM is supported.',
          );
        }
      } else if (chunkId == 'data') {
        dataStart = chunkDataStart;
        dataLength = chunkSize;
        break;
      }

      cursor = nextChunk;
    }

    if (sampleRate == null ||
        channels == null ||
        bitsPerSample == null ||
        dataStart == null ||
        dataLength == null) {
      throw const PeakExtractionException('Incomplete WAV metadata');
    }

    if (bitsPerSample != 16) {
      throw PeakExtractionException(
        'Unsupported bit depth: $bitsPerSample. Only 16-bit PCM WAV is supported.',
      );
    }

    final int sampleCount = dataLength ~/ 2;
    final List<double> samples = List<double>.filled(
      sampleCount,
      0.0,
      growable: false,
    );
    int readOffset = dataStart;
    for (int i = 0; i < sampleCount; i++) {
      final int value = data.getInt16(readOffset, Endian.little);
      samples[i] = value / 32768.0;
      readOffset += 2;
    }

    return _WavData(
      sampleRate: sampleRate,
      channels: channels,
      samples: samples,
    );
  }

  List<double> _toMono(List<double> interleaved, int channels) {
    if (channels <= 1) {
      return interleaved;
    }

    final int frameCount = interleaved.length ~/ channels;
    final List<double> mono = List<double>.filled(
      frameCount,
      0.0,
      growable: false,
    );

    for (int frame = 0; frame < frameCount; frame++) {
      double sum = 0;
      final int base = frame * channels;
      for (int ch = 0; ch < channels; ch++) {
        sum += interleaved[base + ch];
      }
      mono[frame] = sum / channels;
    }

    return mono;
  }

  List<double> _resampleLinear(
    List<double> input,
    int sourceRate,
    int targetRate,
  ) {
    if (sourceRate == targetRate) {
      return input;
    }

    final double ratio = targetRate / sourceRate;
    final int outputLength = max(1, (input.length * ratio).round());
    final List<double> output = List<double>.filled(
      outputLength,
      0.0,
      growable: false,
    );

    for (int i = 0; i < outputLength; i++) {
      final double srcIndex = i / ratio;
      final int left = srcIndex.floor();
      final int right = min(left + 1, input.length - 1);
      final double t = srcIndex - left;
      output[i] = (input[left] * (1.0 - t)) + (input[right] * t);
    }

    return output;
  }

  List<double> _hann(int n) {
    return List<double>.generate(n, (int i) {
      return 0.5 * (1 - cos((2 * pi * i) / (n - 1)));
    }, growable: false);
  }

  void _fft(List<double> real, List<double> imag) {
    final int n = real.length;
    if (n == 0 || (n & (n - 1)) != 0) {
      throw const PeakExtractionException('FFT length must be a power of 2');
    }

    int j = 0;
    for (int i = 1; i < n; i++) {
      int bit = n >> 1;
      while (j & bit != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final double tempReal = real[i];
        real[i] = real[j];
        real[j] = tempReal;

        final double tempImag = imag[i];
        imag[i] = imag[j];
        imag[j] = tempImag;
      }
    }

    for (int len = 2; len <= n; len <<= 1) {
      final double angle = -2 * pi / len;
      final double wLenReal = cos(angle);
      final double wLenImag = sin(angle);

      for (int i = 0; i < n; i += len) {
        double wReal = 1;
        double wImag = 0;

        for (int k = 0; k < (len >> 1); k++) {
          final int even = i + k;
          final int odd = even + (len >> 1);

          final double oddReal = (real[odd] * wReal) - (imag[odd] * wImag);
          final double oddImag = (real[odd] * wImag) + (imag[odd] * wReal);

          final double evenReal = real[even];
          final double evenImag = imag[even];

          real[even] = evenReal + oddReal;
          imag[even] = evenImag + oddImag;
          real[odd] = evenReal - oddReal;
          imag[odd] = evenImag - oddImag;

          final double nextWReal = (wReal * wLenReal) - (wImag * wLenImag);
          wImag = (wReal * wLenImag) + (wImag * wLenReal);
          wReal = nextWReal;
        }
      }
    }
  }
}

class _WavData {
  final int sampleRate;
  final int channels;
  final List<double> samples;

  const _WavData({
    required this.sampleRate,
    required this.channels,
    required this.samples,
  });
}

class _DetectedPeak {
  final int freqIdx;
  final int timeIdx;
  final double amplitudeDb;

  const _DetectedPeak({
    required this.freqIdx,
    required this.timeIdx,
    required this.amplitudeDb,
  });
}
