// test/models/audio_peak_test.dart
//
// Unit tests for AudioPeak, PeakRecognitionPayload, and
// SongIdentificationResult in recognition_models.dart.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/recognition_models.dart';

void main() {
  // ── AudioPeak ──────────────────────────────────────────────────────────────
  group('AudioPeak', () {
    test('toJson emits correct keys', () {
      const AudioPeak peak = AudioPeak(freqIdx: 42, timeIdx: 7);
      final Map<String, dynamic> json = peak.toJson();
      expect(json['freq_idx'], 42);
      expect(json['time_idx'], 7);
    });

    test('toJson only contains freq_idx and time_idx keys', () {
      const AudioPeak peak = AudioPeak(freqIdx: 0, timeIdx: 0);
      expect(peak.toJson().keys.toSet(), {'freq_idx', 'time_idx'});
    });

    test('AudioPeak with large indices serialises correctly', () {
      const AudioPeak peak = AudioPeak(freqIdx: 2048, timeIdx: 99999);
      final Map<String, dynamic> json = peak.toJson();
      expect(json['freq_idx'], 2048);
      expect(json['time_idx'], 99999);
    });
  });

  // ── PeakRecognitionPayload – serialisation ─────────────────────────────────
  group('PeakRecognitionPayload – serialisation', () {
    PeakRecognitionPayload _makePayload({List<AudioPeak>? peaks}) {
      return PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: 44100,
        hopSize: 512,
        windowSize: 4096,
        peaks: peaks ??
            const <AudioPeak>[
              AudioPeak(freqIdx: 100, timeIdx: 1),
              AudioPeak(freqIdx: 200, timeIdx: 5),
            ],
        clientMeta: const <String, dynamic>{
          'platform': 'test',
          'app_version': '1.0.0',
        },
      );
    }

    test('toJson round-trips through jsonEncode → jsonDecode', () {
      final PeakRecognitionPayload payload = _makePayload();
      final String encoded = jsonEncode(payload.toJson());
      final Map<String, dynamic> decoded =
          jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['schema_version'], '1.0');
      expect(decoded['clip_duration_seconds'], 10.0);
      expect(decoded['sample_rate_hz'], 44100);
      expect(decoded['hop_size'], 512);
      expect(decoded['window_size'], 4096);

      final List<dynamic> peaks = decoded['peaks'] as List<dynamic>;
      expect(peaks.length, 2);
      expect((peaks[0] as Map<String, dynamic>)['freq_idx'], 100);
      expect((peaks[1] as Map<String, dynamic>)['time_idx'], 5);
    });

    test('estimatedJsonBytes returns positive value', () {
      final PeakRecognitionPayload payload = _makePayload();
      expect(payload.estimatedJsonBytes(), greaterThan(0));
    });

    test('estimatedJsonBytes increases with more peaks', () {
      final PeakRecognitionPayload small = _makePayload(
        peaks: const <AudioPeak>[AudioPeak(freqIdx: 1, timeIdx: 1)],
      );
      final PeakRecognitionPayload large = _makePayload(
        peaks: List<AudioPeak>.generate(
          200,
          (int i) => AudioPeak(freqIdx: i, timeIdx: i),
        ),
      );
      expect(large.estimatedJsonBytes(), greaterThan(small.estimatedJsonBytes()));
    });

    test('peaks list is serialised in insertion order', () {
      final List<AudioPeak> ordered = <AudioPeak>[
        const AudioPeak(freqIdx: 10, timeIdx: 1),
        const AudioPeak(freqIdx: 20, timeIdx: 2),
        const AudioPeak(freqIdx: 30, timeIdx: 3),
      ];
      final PeakRecognitionPayload payload = _makePayload(peaks: ordered);
      final List<dynamic> jsonPeaks =
          payload.toJson()['peaks'] as List<dynamic>;
      for (int i = 0; i < ordered.length; i++) {
        final Map<String, dynamic> p = jsonPeaks[i] as Map<String, dynamic>;
        expect(p['freq_idx'], ordered[i].freqIdx);
        expect(p['time_idx'], ordered[i].timeIdx);
      }
    });
  });

  // ── PeakRecognitionPayload – validate() ────────────────────────────────────
  group('PeakRecognitionPayload – validate()', () {
    const int kMaxPeaks = 3500;
    const int kMaxFreqIdx = 2047;
    const int kMaxTimeIdx = 5000;
    const int kSampleRate = 44100;
    const int kHopSize = 512;
    const int kWindowSize = 4096;

    List<String> _validate(PeakRecognitionPayload payload) => payload.validate(
          maxPeaks: kMaxPeaks,
          maxFreqIdx: kMaxFreqIdx,
          maxTimeIdx: kMaxTimeIdx,
          expectedSampleRateHz: kSampleRate,
          expectedHopSize: kHopSize,
          expectedWindowSize: kWindowSize,
        );

    test('valid payload produces no errors', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 100, timeIdx: 50)],
        clientMeta: <String, dynamic>{'platform': 'test'},
      );
      expect(_validate(payload), isEmpty);
    });

    test('empty schema_version is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('schema_version')));
    });

    test('non-positive clip duration is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 0.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('clip_duration_seconds')));
    });

    test('mismatched sample_rate_hz is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: 22050, // wrong
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('sample_rate_hz')));
    });

    test('mismatched hop_size is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: 256, // wrong
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('hop_size')));
    });

    test('odd window_size is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: 4097, // odd
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      final List<String> errors = _validate(payload);
      // window_size mismatch AND odd check
      expect(errors.length, greaterThanOrEqualTo(2));
    });

    test('empty peaks list is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('peaks must not be empty')));
    });

    test('peaks exceeding maxPeaks limit is flagged', () {
      final List<AudioPeak> tooMany = List<AudioPeak>.generate(
        kMaxPeaks + 1,
        (int i) => AudioPeak(freqIdx: 100, timeIdx: i),
      );
      final PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: tooMany,
        clientMeta: const <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('exceeds max')));
    });

    test('peak with negative freq_idx is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: -1, timeIdx: 2)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('freq_idx')));
    });

    test('peak with freq_idx exceeding maxFreqIdx is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: kMaxFreqIdx + 1, timeIdx: 1)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('freq_idx')));
    });

    test('peak with negative time_idx is flagged', () {
      const PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: '1.0',
        clipDurationSeconds: 10.0,
        sampleRateHz: kSampleRate,
        hopSize: kHopSize,
        windowSize: kWindowSize,
        peaks: <AudioPeak>[AudioPeak(freqIdx: 10, timeIdx: -5)],
        clientMeta: <String, dynamic>{},
      );
      expect(_validate(payload), anyElement(contains('time_idx')));
    });
  });

  // ── SongIdentificationResult ───────────────────────────────────────────────
  group('SongIdentificationResult', () {
    test('success factory sets ok=true and populates fields', () {
      const SongIdentificationResult result = SongIdentificationResult.success(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        confidence: 91.5,
        matchCount: 130,
        queriedPeakCount: 340,
      );
      expect(result.ok, isTrue);
      expect(result.title, 'Bohemian Rhapsody');
      expect(result.artist, 'Queen');
      expect(result.confidence, closeTo(91.5, 0.001));
      expect(result.matchCount, 130);
      expect(result.queriedPeakCount, 340);
      expect(result.error, isNull);
    });

    test('failure factory sets ok=false and populates error', () {
      const SongIdentificationResult result =
          SongIdentificationResult.failure('No match found');
      expect(result.ok, isFalse);
      expect(result.error, 'No match found');
      expect(result.title, isNull);
      expect(result.artist, isNull);
      expect(result.confidence, isNull);
    });

    test('success result has null error field', () {
      const SongIdentificationResult result =
          SongIdentificationResult.success(title: 'T', artist: 'A');
      expect(result.error, isNull);
    });

    test('failure result has null title and artist', () {
      const SongIdentificationResult result =
          SongIdentificationResult.failure('err');
      expect(result.title, isNull);
      expect(result.artist, isNull);
    });

    test('RecognitionMetrics usedFallback flag is preserved', () {
      const RecognitionMetrics metrics = RecognitionMetrics(
        requestBytes: 1024,
        preprocessingDuration: Duration(milliseconds: 200),
        apiLatency: Duration(milliseconds: 500),
        totalDuration: Duration(milliseconds: 700),
        usedFallback: true,
      );
      const SongIdentificationResult result = SongIdentificationResult.success(
        title: 'Song',
        artist: 'Artist',
        metrics: metrics,
      );
      expect(result.metrics, isNotNull);
      expect(result.metrics!.usedFallback, isTrue);
      expect(result.metrics!.requestBytes, 1024);
    });
  });
}
