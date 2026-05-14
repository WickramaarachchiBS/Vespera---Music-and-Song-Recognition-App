// test/services/recognition_config_test.dart
//
// Unit tests for RecognitionConfig and RecognizerMode parsing.

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/recognition_config.dart';

void main() {
  group('RecognitionConfig – default values', () {
    late RecognitionConfig config;

    setUp(() {
      config = RecognitionConfig(
        peakEndpoint: Uri.parse('https://api.example.com/api/identify-peaks'),
        audioEndpoint: Uri.parse('https://api.example.com/api/identify'),
        mode: RecognizerMode.peakPrimary,
      );
    });

    test('default targetSampleRateHz is 44100', () {
      expect(config.targetSampleRateHz, 44100);
    });

    test('default windowSize is 4096', () {
      expect(config.windowSize, 4096);
    });

    test('default hopSize is 512', () {
      expect(config.hopSize, 512);
    });

    test('default maxPeaks is 3500', () {
      expect(config.maxPeaks, 3500);
    });

    test('default minDurationSeconds is 8.0', () {
      expect(config.minDurationSeconds, 8.0);
    });

    test('default maxDurationSeconds is 15.0', () {
      expect(config.maxDurationSeconds, 15.0);
    });

    test('default schemaVersion is 1.0', () {
      expect(config.schemaVersion, '1.0');
    });

    test('default apiTimeout is 20 seconds', () {
      expect(config.apiTimeout, const Duration(seconds: 20));
    });

    test('default retryCount is 0', () {
      expect(config.retryCount, 0);
    });

    test('default minPeakMatchCountForAcceptance is 10', () {
      expect(config.minPeakMatchCountForAcceptance, 10);
    });

    test('default minFrequencyHz is 300', () {
      expect(config.minFrequencyHz, 300.0);
    });

    test('default maxFrequencyHz is 5000', () {
      expect(config.maxFrequencyHz, 5000.0);
    });
  });

  group('RecognitionConfig – custom values', () {
    test('custom values are stored correctly', () {
      final RecognitionConfig config = RecognitionConfig(
        peakEndpoint: Uri.parse('https://peak.example.com/peaks'),
        audioEndpoint: Uri.parse('https://audio.example.com/upload'),
        mode: RecognizerMode.audioOnly,
        apiTimeout: const Duration(seconds: 30),
        retryCount: 2,
        targetSampleRateHz: 22050,
        windowSize: 2048,
        hopSize: 256,
        maxPeaks: 1000,
        minDurationSeconds: 5.0,
        maxDurationSeconds: 20.0,
        minPeakMatchCountForAcceptance: 15,
        schemaVersion: '2.0',
        appVersion: '2.1.0',
      );

      expect(config.peakEndpoint.host, 'peak.example.com');
      expect(config.audioEndpoint.host, 'audio.example.com');
      expect(config.mode, RecognizerMode.audioOnly);
      expect(config.apiTimeout.inSeconds, 30);
      expect(config.retryCount, 2);
      expect(config.targetSampleRateHz, 22050);
      expect(config.windowSize, 2048);
      expect(config.hopSize, 256);
      expect(config.maxPeaks, 1000);
      expect(config.minDurationSeconds, 5.0);
      expect(config.maxDurationSeconds, 20.0);
      expect(config.minPeakMatchCountForAcceptance, 15);
      expect(config.schemaVersion, '2.0');
      expect(config.appVersion, '2.1.0');
    });
  });

  group('RecognitionConfig – endpoint URIs', () {
    test('peakEndpoint path is preserved', () {
      final RecognitionConfig config = RecognitionConfig(
        peakEndpoint:
            Uri.parse('https://vesper.azure.com/api/identify-peaks'),
        audioEndpoint: Uri.parse('https://vesper.azure.com/api/identify'),
        mode: RecognizerMode.peakPrimary,
      );
      expect(config.peakEndpoint.path, '/api/identify-peaks');
      expect(config.audioEndpoint.path, '/api/identify');
    });

    test('peakEndpoint scheme is https', () {
      final RecognitionConfig config = RecognitionConfig(
        peakEndpoint:
            Uri.parse('https://vesper.azure.com/api/identify-peaks'),
        audioEndpoint: Uri.parse('https://vesper.azure.com/api/identify'),
        mode: RecognizerMode.peakPrimary,
      );
      expect(config.peakEndpoint.scheme, 'https');
    });
  });

  group('RecognizerMode – modeFromEnvironment', () {
    // The VESPER_RECOGNIZER_MODE dart-define is not set in test,
    // so the default 'peak_primary' value must be returned.
    test('returns peakPrimary when no dart-define is set', () {
      expect(
        RecognitionConfig.modeFromEnvironment(),
        RecognizerMode.peakPrimary,
      );
    });
  });

  group('RecognizerMode – enum values', () {
    test('all three modes exist', () {
      expect(RecognizerMode.values.length, 3);
      expect(RecognizerMode.values, contains(RecognizerMode.peakPrimary));
      expect(RecognizerMode.values, contains(RecognizerMode.audioOnly));
      expect(RecognizerMode.values, contains(RecognizerMode.peakOnly));
    });
  });
}
