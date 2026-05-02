import 'dart:convert';

class AudioPeak {
  final int freqIdx;
  final int timeIdx;

  const AudioPeak({required this.freqIdx, required this.timeIdx});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'freq_idx': freqIdx,
    'time_idx': timeIdx,
  };
}

class PeakRecognitionPayload {
  final String schemaVersion;
  final double clipDurationSeconds;
  final int sampleRateHz;
  final int hopSize;
  final int windowSize;
  final List<AudioPeak> peaks;
  final Map<String, dynamic> clientMeta;

  const PeakRecognitionPayload({
    required this.schemaVersion,
    required this.clipDurationSeconds,
    required this.sampleRateHz,
    required this.hopSize,
    required this.windowSize,
    required this.peaks,
    required this.clientMeta,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema_version': schemaVersion,
    'clip_duration_seconds': clipDurationSeconds,
    'sample_rate_hz': sampleRateHz,
    'hop_size': hopSize,
    'window_size': windowSize,
    'peaks': peaks.map((AudioPeak p) => p.toJson()).toList(growable: false),
    'client_meta': clientMeta,
  };

  List<String> validate({
    required int maxPeaks,
    required int maxFreqIdx,
    required int maxTimeIdx,
    required int expectedSampleRateHz,
    required int expectedHopSize,
    required int expectedWindowSize,
  }) {
    final List<String> errors = <String>[];
    if (schemaVersion.isEmpty) {
      errors.add('schema_version is required');
    }
    if (clipDurationSeconds <= 0) {
      errors.add('clip_duration_seconds must be > 0');
    }
    if (sampleRateHz != expectedSampleRateHz) {
      errors.add('sample_rate_hz must be exactly $expectedSampleRateHz');
    }
    if (hopSize != expectedHopSize) {
      errors.add('hop_size must be exactly $expectedHopSize');
    }
    if (windowSize != expectedWindowSize) {
      errors.add('window_size must be exactly $expectedWindowSize');
    }
    if (windowSize % 2 != 0) {
      errors.add('window_size must be even');
    }
    if (peaks.isEmpty) {
      errors.add('peaks must not be empty');
    }
    if (peaks.length > maxPeaks) {
      errors.add('peaks length ${peaks.length} exceeds max $maxPeaks');
    }
    for (int i = 0; i < peaks.length; i++) {
      final AudioPeak peak = peaks[i];
      if (peak.freqIdx < 0 || peak.freqIdx > maxFreqIdx) {
        errors.add('peak[$i].freq_idx out of range');
      }
      if (peak.timeIdx < 0 || peak.timeIdx > maxTimeIdx) {
        errors.add('peak[$i].time_idx out of range');
      }
    }
    return errors;
  }

  int estimatedJsonBytes() => utf8.encode(jsonEncode(toJson())).length;
}

class PeakExtractionResult {
  final List<AudioPeak> peaks;
  final Duration preprocessingDuration;
  final int sourceSampleRate;
  final int outputSampleRate;
  final double clipDurationSeconds;

  const PeakExtractionResult({
    required this.peaks,
    required this.preprocessingDuration,
    required this.sourceSampleRate,
    required this.outputSampleRate,
    required this.clipDurationSeconds,
  });
}

class RecognitionMetrics {
  final int requestBytes;
  final Duration preprocessingDuration;
  final Duration apiLatency;
  final Duration totalDuration;
  final bool usedFallback;

  const RecognitionMetrics({
    required this.requestBytes,
    required this.preprocessingDuration,
    required this.apiLatency,
    required this.totalDuration,
    required this.usedFallback,
  });
}

class SongIdentificationResult {
  final bool ok;
  final String? title;
  final String? artist;
  final double? confidence;
  final int? matchCount;
  final int? queriedPeakCount;
  final Map<String, dynamic>? raw;
  final String? error;
  final RecognitionMetrics? metrics;

  const SongIdentificationResult._({
    required this.ok,
    required this.title,
    required this.artist,
    required this.confidence,
    required this.matchCount,
    required this.queriedPeakCount,
    required this.raw,
    required this.error,
    required this.metrics,
  });

  const SongIdentificationResult.success({
    String? title,
    String? artist,
    double? confidence,
    int? matchCount,
    int? queriedPeakCount,
    Map<String, dynamic>? raw,
    RecognitionMetrics? metrics,
  }) : this._(
         ok: true,
         title: title,
         artist: artist,
         confidence: confidence,
         matchCount: matchCount,
         queriedPeakCount: queriedPeakCount,
         raw: raw,
         error: null,
         metrics: metrics,
       );

  const SongIdentificationResult.failure(
    String message, {
    RecognitionMetrics? metrics,
  }) : this._(
         ok: false,
         title: null,
         artist: null,
         confidence: null,
         matchCount: null,
         queriedPeakCount: null,
         raw: null,
         error: message,
         metrics: metrics,
       );
}
