import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_models.dart';

import '../helpers/audio_test_utils.dart';

void main() {
  test('payload validation catches invalid peaks', () {
    const PeakRecognitionPayload payload = PeakRecognitionPayload(
      schemaVersion: '1.0',
      clipDurationSeconds: 10.0,
      sampleRateHz: 44100,
      hopSize: 512,
      windowSize: 4096,
      peaks: <AudioPeak>[AudioPeak(freqIdx: -1, timeIdx: 2)],
      clientMeta: <String, dynamic>{'platform': 'test', 'app_version': '1.0.0'},
    );

    final List<String> errors = payload.validate(
      maxPeaks: 100,
      maxFreqIdx: 2047,
      maxTimeIdx: 1000,
      expectedSampleRateHz: 44100,
      expectedHopSize: 512,
      expectedWindowSize: 4096,
    );
    expect(errors.isNotEmpty, isTrue);
  });

  test('peak extraction is deterministic for same clip', () async {
    final Directory dir = await Directory.systemTemp.createTemp(
      'vespera_payload_test_',
    );
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    final String wavPath = await createTestWavFile(
      dir: dir,
      fileName: 'deterministic.wav',
      durationSeconds: 8.0,
      sampleRate: 44100,
      frequencyHz: 523.25,
    );

    const PeakExtractor extractor = PeakExtractor();
    final PeakExtractionResult a = await extractor.extractPeaks(
      wavPath: wavPath,
      targetSampleRateHz: 44100,
      windowSize: 4096,
      hopSize: 512,
      localMaxNeighborhoodSize: 15,
      minAmplitudeDb: -60.0,
      minFrequencyHz: 300.0,
      maxFrequencyHz: 5000.0,
      maxPeaks: 300,
      minDurationSeconds: 8,
      maxDurationSeconds: 15,
    );
    final PeakExtractionResult b = await extractor.extractPeaks(
      wavPath: wavPath,
      targetSampleRateHz: 44100,
      windowSize: 4096,
      hopSize: 512,
      localMaxNeighborhoodSize: 15,
      minAmplitudeDb: -60.0,
      minFrequencyHz: 300.0,
      maxFrequencyHz: 5000.0,
      maxPeaks: 300,
      minDurationSeconds: 8,
      maxDurationSeconds: 15,
    );

    expect(a.peaks.length, b.peaks.length);
    for (int i = 0; i < a.peaks.length; i++) {
      expect(a.peaks[i].freqIdx, b.peaks[i].freqIdx);
      expect(a.peaks[i].timeIdx, b.peaks[i].timeIdx);
    }
  });
}
