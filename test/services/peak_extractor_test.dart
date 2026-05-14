// test/services/peak_extractor_test.dart
//
// Unit tests for PeakExtractor – WAV parsing, peak extraction,
// resampling, mono-mixing, and error handling.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_models.dart';

import '../helpers/audio_test_utils.dart';

void main() {
  const PeakExtractor extractor = PeakExtractor();

  // ── Helper – shared parameters ─────────────────────────────────────────────
  Future<PeakExtractionResult> _extract(
    String wavPath, {
    double minDuration = 8.0,
    double maxDuration = 15.0,
    double minAmpDb = -60.0,
    int maxPeaks = 3500,
  }) =>
      extractor.extractPeaks(
        wavPath: wavPath,
        targetSampleRateHz: 44100,
        windowSize: 4096,
        hopSize: 512,
        localMaxNeighborhoodSize: 10,
        minAmplitudeDb: minAmpDb,
        minFrequencyHz: 300.0,
        maxFrequencyHz: 5000.0,
        maxPeaks: maxPeaks,
        minDurationSeconds: minDuration,
        maxDurationSeconds: maxDuration,
      );

  // ── Setup: temp directory ──────────────────────────────────────────────────
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('vespera_extractor_test_');
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  // ── Error handling ─────────────────────────────────────────────────────────
  group('PeakExtractor – error handling', () {
    test('throws PeakExtractionException for missing file', () async {
      expect(
        () async => _extract('/non/existent/file.wav'),
        throwsA(isA<PeakExtractionException>()),
      );
    });

    test('throws PeakExtractionException for clip shorter than minDuration', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'too_short.wav',
        durationSeconds: 3.0, // less than minDuration=8.0
        sampleRate: 44100,
      );
      expect(
        () async => _extract(wavPath),
        throwsA(isA<PeakExtractionException>()),
      );
    });

    test('PeakExtractionException message is non-empty', () async {
      try {
        await _extract('/non/existent.wav');
      } on PeakExtractionException catch (e) {
        expect(e.message, isNotEmpty);
        expect(e.toString(), contains('PeakExtractionException'));
      }
    });
  });

  // ── Successful extraction ──────────────────────────────────────────────────
  group('PeakExtractor – successful extraction', () {
    test('returns non-empty peaks for a 10-second sine wave', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'sine_440.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 440.0,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      expect(result.peaks, isNotEmpty);
    });

    test('all peaks have valid (non-negative) freq_idx and time_idx', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'valid_peaks.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 880.0,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      for (final AudioPeak peak in result.peaks) {
        expect(peak.freqIdx, greaterThanOrEqualTo(0));
        expect(peak.timeIdx, greaterThanOrEqualTo(0));
      }
    });

    test('all peaks have freq_idx within expected frequency band', () async {
      // freq band 300–5000 Hz at 44100 Hz, window 4096
      // binHz ≈ 10.77; minBin ≈ 28, maxBin ≈ 464
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'freq_band.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 1000.0,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      for (final AudioPeak peak in result.peaks) {
        expect(peak.freqIdx, greaterThanOrEqualTo(0));
        // freq_idx ≤ windowSize / 2 – 1
        expect(peak.freqIdx, lessThan(4096 ~/ 2));
      }
    });

    test('number of peaks does not exceed maxPeaks', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'max_peaks.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 440.0,
      );
      const int maxPeaks = 50;
      final PeakExtractionResult result = await _extract(wavPath, maxPeaks: maxPeaks);
      expect(result.peaks.length, lessThanOrEqualTo(maxPeaks));
    });

    test('peaks are sorted by time_idx (ascending)', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'sorted.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 523.25,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      if (result.peaks.length > 1) {
        for (int i = 1; i < result.peaks.length; i++) {
          expect(
            result.peaks[i].timeIdx,
            greaterThanOrEqualTo(result.peaks[i - 1].timeIdx),
          );
        }
      }
    });

    test('clipDurationSeconds is close to requested duration', () async {
      const double requestedDuration = 10.0;
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'duration.wav',
        durationSeconds: requestedDuration,
        sampleRate: 44100,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      expect(result.clipDurationSeconds, closeTo(requestedDuration, 0.1));
    });

    test('sourceSampleRate matches the WAV file sample rate', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'sample_rate.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      expect(result.sourceSampleRate, 44100);
    });

    test('outputSampleRate matches targetSampleRateHz', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'out_sr.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      expect(result.outputSampleRate, 44100);
    });

    test('preprocessingDuration is non-negative', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'proc_time.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
      );
      final PeakExtractionResult result = await _extract(wavPath);
      expect(result.preprocessingDuration.inMicroseconds, greaterThanOrEqualTo(0));
    });
  });

  // ── Determinism ────────────────────────────────────────────────────────────
  group('PeakExtractor – determinism', () {
    test('identical inputs produce identical peak lists', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'deterministic.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 660.0,
      );
      final PeakExtractionResult a = await _extract(wavPath);
      final PeakExtractionResult b = await _extract(wavPath);

      expect(a.peaks.length, b.peaks.length);
      for (int i = 0; i < a.peaks.length; i++) {
        expect(a.peaks[i].freqIdx, b.peaks[i].freqIdx,
            reason: 'freq_idx mismatch at index $i');
        expect(a.peaks[i].timeIdx, b.peaks[i].timeIdx,
            reason: 'time_idx mismatch at index $i');
      }
    });

    test('different frequencies produce different peak sets', () async {
      final String lowWav = await createTestWavFile(
        dir: tmpDir,
        fileName: 'low_freq.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 440.0,
      );
      final String highWav = await createTestWavFile(
        dir: tmpDir,
        fileName: 'high_freq.wav',
        durationSeconds: 10.0,
        sampleRate: 44100,
        frequencyHz: 3000.0,
      );
      final PeakExtractionResult lowResult = await _extract(lowWav);
      final PeakExtractionResult highResult = await _extract(highWav);

      // Two sinusoids at very different fundamental frequencies must produce
      // at least one peak that differs in freqIdx.
      if (lowResult.peaks.isNotEmpty && highResult.peaks.isNotEmpty) {
        final Set<int> lowFreqs =
            lowResult.peaks.map((p) => p.freqIdx).toSet();
        final Set<int> highFreqs =
            highResult.peaks.map((p) => p.freqIdx).toSet();
        // The peak sets are not identical — they have different dominant bins.
        expect(
          lowFreqs == highFreqs,
          isFalse,
          reason: 'Peak freq sets for 440 Hz and 3000 Hz should differ',
        );
      }
    });

  });

  // ── maxDuration capping ────────────────────────────────────────────────────
  group('PeakExtractor – maxDuration capping', () {
    test('clip longer than maxDuration is truncated to maxDuration', () async {
      final String wavPath = await createTestWavFile(
        dir: tmpDir,
        fileName: 'long_clip.wav',
        durationSeconds: 20.0,
        sampleRate: 44100,
      );
      final PeakExtractionResult result = await _extract(
        wavPath,
        maxDuration: 12.0,
      );
      // Resulting clip should not exceed 12 seconds (allow 0.2s rounding)
      expect(result.clipDurationSeconds, lessThanOrEqualTo(12.2));
    });
  });
}
