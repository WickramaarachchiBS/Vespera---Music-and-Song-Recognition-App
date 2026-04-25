import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_config.dart';
import 'package:vespera/services/recognition/recognition_models.dart';
import 'package:vespera/services/recognition/recognizers.dart';

import '../helpers/audio_test_utils.dart';

void main() {
  test('integration: peak recognition success path', () async {
    final Directory dir = await Directory.systemTemp.createTemp('vespera_peak_success_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    final String wavPath = await createTestWavFile(
      dir: dir,
      fileName: 'success.wav',
      durationSeconds: 10,
      sampleRate: 44100,
    );

    final RecognitionConfig config = RecognitionConfig(
      peakEndpoint: Uri.parse('https://example.test/api/identify-peaks'),
      audioEndpoint: Uri.parse('https://example.test/api/identify'),
      mode: RecognizerMode.peakPrimary,
    );

    final MockClient peakClient = MockClient((http.Request request) async {
      expect(request.url.path, '/api/identify-peaks');
      List<int> payloadBytes = request.bodyBytes;
      if (request.headers['content-encoding'] == 'gzip') {
        payloadBytes = gzip.decode(payloadBytes);
      }
      final Map<String, dynamic> body = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
      expect(body['schema_version'], '1.0');
      expect((body['peaks'] as List<dynamic>).isNotEmpty, isTrue);
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'song_id': 1,
          'title': 'Peak Song',
          'artist': 'Peak Artist',
          'match_count': 127,
          'confidence': 85.32,
          'total_fingerprints': 149,
          'message': null,
        }),
        200,
      );
    });

    final MockClient audioClient = MockClient((http.Request request) async {
      fail('Audio fallback should not be called when peak path succeeds.');
    });

    final RecognitionOrchestrator orchestrator = RecognitionOrchestrator(
      config: config,
      peakRecognizer: PeakBasedRecognizer(config: config, extractor: const PeakExtractor(), client: peakClient),
      audioUploadRecognizer: AudioUploadRecognizer(config: config, client: audioClient),
    );

    final SongIdentificationResult result = await orchestrator.identify(
      filePath: wavPath,
      cancellationToken: RecognitionCancellationToken(),
    );

    expect(result.ok, isTrue);
    expect(result.title, 'Peak Song');
    expect(result.metrics, isNotNull);
    expect(result.metrics!.usedFallback, isFalse);
  });

  test('integration: peak failure falls back to audio upload', () async {
    final Directory dir = await Directory.systemTemp.createTemp('vespera_peak_fallback_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    final String wavPath = await createTestWavFile(
      dir: dir,
      fileName: 'fallback.wav',
      durationSeconds: 10,
      sampleRate: 44100,
    );

    final RecognitionConfig config = RecognitionConfig(
      peakEndpoint: Uri.parse('https://example.test/api/identify-peaks'),
      audioEndpoint: Uri.parse('https://example.test/api/identify'),
      mode: RecognizerMode.peakPrimary,
    );

    final MockClient peakClient = MockClient((http.Request request) async {
      return http.Response('peak unavailable', 503);
    });

    final MockClient audioClient = MockClient((http.BaseRequest request) async {
      expect(request.url.path, '/api/identify');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'song_id': 2,
          'title': 'Fallback Song',
          'artist': 'Fallback Artist',
          'match_count': 111,
          'confidence': 72.10,
          'total_fingerprints': 141,
          'message': null,
        }),
        200,
      );
    });

    final RecognitionOrchestrator orchestrator = RecognitionOrchestrator(
      config: config,
      peakRecognizer: PeakBasedRecognizer(config: config, extractor: const PeakExtractor(), client: peakClient),
      audioUploadRecognizer: AudioUploadRecognizer(config: config, client: audioClient),
    );

    final SongIdentificationResult result = await orchestrator.identify(
      filePath: wavPath,
      cancellationToken: RecognitionCancellationToken(),
    );

    expect(result.ok, isTrue);
    expect(result.title, 'Fallback Song');
    expect(result.metrics, isNotNull);
    expect(result.metrics!.usedFallback, isTrue);
  });

  test('benchmark summary: old upload vs new peak path', () async {
    final Directory dir = await Directory.systemTemp.createTemp('vespera_benchmark_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    final String peakWavPath = await createTestWavFile(
      dir: dir,
      fileName: 'benchmark_peak.wav',
      durationSeconds: 10,
      sampleRate: 44100,
    );
    final String audioWavPath = await createTestWavFile(
      dir: dir,
      fileName: 'benchmark_audio.wav',
      durationSeconds: 10,
      sampleRate: 44100,
    );

    final RecognitionConfig config = RecognitionConfig(
      peakEndpoint: Uri.parse('https://example.test/api/identify-peaks'),
      audioEndpoint: Uri.parse('https://example.test/api/identify'),
      mode: RecognizerMode.peakPrimary,
      retryCount: 0,
    );

    final MockClient peakClient = MockClient((http.Request request) async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'song_id': 3,
          'title': 'Peak Benchmark',
          'artist': 'Artist',
          'match_count': 77,
          'confidence': 90.0,
        }),
        200,
      );
    });

    final MockClient audioClient = MockClient((http.BaseRequest request) async {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'song_id': 4,
          'title': 'Audio Benchmark',
          'artist': 'Artist',
          'confidence': 90.0,
        }),
        200,
      );
    });

    final PeakBasedRecognizer peakRecognizer = PeakBasedRecognizer(
      config: config,
      extractor: const PeakExtractor(),
      client: peakClient,
    );
    final AudioUploadRecognizer audioRecognizer = AudioUploadRecognizer(config: config, client: audioClient);

    final SongIdentificationResult peakResult = await peakRecognizer.identify(
      filePath: peakWavPath,
      cancellationToken: RecognitionCancellationToken(),
    );
    final SongIdentificationResult audioResult = await audioRecognizer.identify(
      filePath: audioWavPath,
      cancellationToken: RecognitionCancellationToken(),
    );

    expect(peakResult.ok, isTrue);
    expect(audioResult.ok, isTrue);

    final RecognitionMetrics peakMetrics = peakResult.metrics!;
    final RecognitionMetrics audioMetrics = audioResult.metrics!;

    print('Benchmark Summary (test synthetic clip)');
    print('metric | old_audio_upload | new_peak_json');
    print('payload_bytes | ${audioMetrics.requestBytes} | ${peakMetrics.requestBytes}');
    print('api_latency_ms | ${audioMetrics.apiLatency.inMilliseconds} | ${peakMetrics.apiLatency.inMilliseconds}');
    print('total_time_ms | ${audioMetrics.totalDuration.inMilliseconds} | ${peakMetrics.totalDuration.inMilliseconds}');
  });
}
