import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show max;

import 'package:http/http.dart' as http;
import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_config.dart';
import 'package:vespera/services/recognition/recognition_models.dart';

class RecognitionCancellationToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  Future<void> get cancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  void throwIfCancelled() {
    if (isCancelled) {
      throw const _RecognitionCancelledException();
    }
  }
}

abstract class SongRecognizer {
  Future<SongIdentificationResult> identify({
    required String filePath,
    required RecognitionCancellationToken cancellationToken,
  });
}

class PeakBasedRecognizer implements SongRecognizer {
  PeakBasedRecognizer({
    required RecognitionConfig config,
    required PeakExtractor extractor,
    http.Client? client,
  }) : _config = config,
       _extractor = extractor,
       _client = client ?? http.Client();

  final RecognitionConfig _config;
  final PeakExtractor _extractor;
  final http.Client _client;

  @override
  Future<SongIdentificationResult> identify({
    required String filePath,
    required RecognitionCancellationToken cancellationToken,
  }) async {
    final Stopwatch totalSw = Stopwatch()..start();
    try {
      cancellationToken.throwIfCancelled();

      final PeakExtractionResult extraction = await _extractor.extractPeaks(
        wavPath: filePath,
        targetSampleRateHz: _config.targetSampleRateHz,
        windowSize: _config.windowSize,
        hopSize: _config.hopSize,
        localMaxNeighborhoodSize: _config.localMaxNeighborhoodSize,
        minAmplitudeDb: _config.minAmplitudeDb,
        minFrequencyHz: _config.minFrequencyHz,
        maxFrequencyHz: _config.maxFrequencyHz,
        maxPeaks: _config.maxPeaks,
        minDurationSeconds: _config.minDurationSeconds,
        maxDurationSeconds: _config.maxDurationSeconds,
      );

      cancellationToken.throwIfCancelled();

      final PeakRecognitionPayload payload = PeakRecognitionPayload(
        schemaVersion: _config.schemaVersion,
        clipDurationSeconds: extraction.clipDurationSeconds,
        sampleRateHz: extraction.outputSampleRate,
        hopSize: _config.hopSize,
        windowSize: _config.windowSize,
        peaks: extraction.peaks,
        clientMeta: <String, dynamic>{
          'platform': Platform.operatingSystem,
          'app_version': _config.appVersion,
        },
      );

      final int maxFreqIdx = (_config.windowSize ~/ 2) - 1;
      final int estimatedSamples = max(
        1,
        (extraction.clipDurationSeconds * _config.targetSampleRateHz).round(),
      );
      final int maxTimeIdx =
          estimatedSamples < _config.windowSize
              ? 0
              : (estimatedSamples - _config.windowSize) ~/ _config.hopSize;
      final List<String> validationErrors = payload.validate(
        maxPeaks: _config.maxPeaks,
        maxFreqIdx: maxFreqIdx,
        maxTimeIdx: maxTimeIdx,
        expectedSampleRateHz: _config.targetSampleRateHz,
        expectedHopSize: _config.hopSize,
        expectedWindowSize: _config.windowSize,
      );
      if (validationErrors.isNotEmpty) {
        return SongIdentificationResult.failure(
          'Invalid peak payload: ${validationErrors.join('; ')}',
        );
      }

      final List<int> jsonBytes = utf8.encode(jsonEncode(payload.toJson()));
      List<int> bodyBytes = jsonBytes;
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (_config.enableGzipForLargePayload) {
        bodyBytes = gzip.encode(jsonBytes);
        headers['Content-Encoding'] = 'gzip';
      }

      final List<Map<String, int>> first20Peaks = extraction.peaks
          .take(20)
          .map(
            (AudioPeak p) => <String, int>{
              'freq_idx': p.freqIdx,
              'time_idx': p.timeIdx,
            },
          )
          .toList(growable: false);

      _logStructured('peak_request_built', <String, Object?>{
        'request_bytes': bodyBytes.length,
        'raw_json_bytes': jsonBytes.length,
        'preprocessing_ms': extraction.preprocessingDuration.inMilliseconds,
        'peak_count': extraction.peaks.length,
        'first_20_peaks': first20Peaks,
        'source_sample_rate_hz': extraction.sourceSampleRate,
        'output_sample_rate_hz': extraction.outputSampleRate,
      });

      final Stopwatch apiSw = Stopwatch()..start();
      Object? lastError;

      for (int attempt = 0; attempt <= _config.retryCount; attempt++) {
        cancellationToken.throwIfCancelled();
        try {
          final http.Response response = await _postWithCancellation(
            uri: _config.peakEndpoint,
            bodyBytes: bodyBytes,
            headers: headers,
            timeout: _config.apiTimeout,
            cancellationToken: cancellationToken,
          );

          if (response.statusCode < 200 || response.statusCode >= 300) {
            final bool retryable = response.statusCode >= 500;
            if (retryable && attempt < _config.retryCount) {
              await Future<void>.delayed(const Duration(milliseconds: 250));
              continue;
            }
            apiSw.stop();
            totalSw.stop();
            return SongIdentificationResult.failure(
              'Peak endpoint error (${response.statusCode}): ${response.body.isNotEmpty ? response.body : 'No body'}',
              metrics: RecognitionMetrics(
                requestBytes: bodyBytes.length,
                preprocessingDuration: extraction.preprocessingDuration,
                apiLatency: apiSw.elapsed,
                totalDuration: totalSw.elapsed,
                usedFallback: false,
              ),
            );
          }

          final dynamic decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            apiSw.stop();
            totalSw.stop();
            return SongIdentificationResult.failure(
              'Unexpected peak response format.',
              metrics: RecognitionMetrics(
                requestBytes: bodyBytes.length,
                preprocessingDuration: extraction.preprocessingDuration,
                apiLatency: apiSw.elapsed,
                totalDuration: totalSw.elapsed,
                usedFallback: false,
              ),
            );
          }

          final Object? confidenceRaw = decoded['confidence'];
          final double? confidence =
              confidenceRaw is num
                  ? confidenceRaw.toDouble()
                  : double.tryParse(confidenceRaw?.toString() ?? '');
          final int? matchCount = _toInt(decoded['match_count']);
          final bool success = decoded['success'] == true;
          final String? title = decoded['title']?.toString();
          final String? artist = decoded['artist']?.toString();

          final String? acceptanceError = _peakAcceptanceError(
            success: success,
            title: title,
            matchCount: matchCount,
            confidence: confidence,
          );
          if (acceptanceError != null) {
            apiSw.stop();
            totalSw.stop();
            return SongIdentificationResult.failure(
              acceptanceError,
              metrics: RecognitionMetrics(
                requestBytes: bodyBytes.length,
                preprocessingDuration: extraction.preprocessingDuration,
                apiLatency: apiSw.elapsed,
                totalDuration: totalSw.elapsed,
                usedFallback: false,
              ),
            );
          }

          apiSw.stop();
          totalSw.stop();

          _logStructured('peak_request_success', <String, Object?>{
            'request_bytes': bodyBytes.length,
            'api_latency_ms': apiSw.elapsed.inMilliseconds,
            'total_ms': totalSw.elapsed.inMilliseconds,
          });

          return SongIdentificationResult.success(
            title: title,
            artist: artist,
            confidence: confidence,
            raw: decoded,
            metrics: RecognitionMetrics(
              requestBytes: bodyBytes.length,
              preprocessingDuration: extraction.preprocessingDuration,
              apiLatency: apiSw.elapsed,
              totalDuration: totalSw.elapsed,
              usedFallback: false,
            ),
          );
        } on TimeoutException catch (e) {
          lastError = e;
          if (attempt >= _config.retryCount) {
            break;
          }
        } on _RecognitionCancelledException {
          return const SongIdentificationResult.failure(
            'Recognition cancelled.',
          );
        } catch (e) {
          lastError = e;
          if (attempt >= _config.retryCount) {
            break;
          }
        }
      }

      apiSw.stop();
      totalSw.stop();
      _logStructured('peak_request_failed', <String, Object?>{
        'request_bytes': bodyBytes.length,
        'api_latency_ms': apiSw.elapsed.inMilliseconds,
        'total_ms': totalSw.elapsed.inMilliseconds,
        'error': lastError?.toString() ?? 'unknown',
      });

      return SongIdentificationResult.failure(
        'Peak recognition failed: ${lastError ?? 'unknown error'}',
        metrics: RecognitionMetrics(
          requestBytes: bodyBytes.length,
          preprocessingDuration: extraction.preprocessingDuration,
          apiLatency: apiSw.elapsed,
          totalDuration: totalSw.elapsed,
          usedFallback: false,
        ),
      );
    } on PeakExtractionException catch (e) {
      totalSw.stop();
      return SongIdentificationResult.failure(
        'Peak extraction failed: ${e.message}',
      );
    } on _RecognitionCancelledException {
      totalSw.stop();
      return const SongIdentificationResult.failure('Recognition cancelled.');
    }
  }

  Future<http.Response> _postWithCancellation({
    required Uri uri,
    required List<int> bodyBytes,
    required Map<String, String> headers,
    required Duration timeout,
    required RecognitionCancellationToken cancellationToken,
  }) async {
    final http.Request request =
        http.Request('POST', uri)
          ..headers.addAll(headers)
          ..bodyBytes = bodyBytes;

    final Future<http.StreamedResponse> sendFuture = _client
        .send(request)
        .timeout(timeout);
    final http.StreamedResponse streamed =
        await Future.any<http.StreamedResponse>(<Future<http.StreamedResponse>>[
          sendFuture,
          cancellationToken.cancelled.then(
            (_) => throw const _RecognitionCancelledException(),
          ),
        ]);

    return http.Response.fromStream(streamed);
  }

  void _logStructured(String event, Map<String, Object?> fields) {
    final Map<String, Object?> payload = <String, Object?>{
      'event': event,
      ...fields,
    };
    log(jsonEncode(payload), name: 'vespera.recognition');
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  String? _peakAcceptanceError({
    required bool success,
    required String? title,
    required int? matchCount,
    required double? confidence,
  }) {
    if (!success) {
      return 'Peak response indicates no match (success=false).';
    }

    final String normalizedTitle = (title ?? '').trim().toLowerCase();
    if (normalizedTitle.isEmpty || normalizedTitle == 'unknown title') {
      return 'Peak response has invalid/unknown title.';
    }

    if (matchCount == null ||
        matchCount < _config.minPeakMatchCountForAcceptance) {
      return 'Peak match_count below threshold (${_config.minPeakMatchCountForAcceptance}).';
    }

    final double parsedConfidence = confidence ?? 0.0;
    if (parsedConfidence < _config.minPeakConfidenceForAcceptance) {
      return 'Peak confidence below threshold (${_config.minPeakConfidenceForAcceptance}).';
    }

    return null;
  }
}

class AudioUploadRecognizer implements SongRecognizer {
  AudioUploadRecognizer({
    required RecognitionConfig config,
    http.Client? client,
  }) : _config = config,
       _client = client ?? http.Client();

  final RecognitionConfig _config;
  final http.Client _client;

  @override
  Future<SongIdentificationResult> identify({
    required String filePath,
    required RecognitionCancellationToken cancellationToken,
  }) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return const SongIdentificationResult.failure('Recorded file not found.');
    }

    final Stopwatch totalSw = Stopwatch()..start();
    final Stopwatch apiSw = Stopwatch()..start();

    try {
      cancellationToken.throwIfCancelled();

      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        _config.audioEndpoint,
      );
      request.files.add(
        await http.MultipartFile.fromPath('audio_file', filePath),
      );

      final int requestSize = await file.length();
      final Future<http.StreamedResponse> sendFuture = _client
          .send(request)
          .timeout(_config.apiTimeout);
      final http.StreamedResponse streamed = await Future.any<
        http.StreamedResponse
      >(<Future<http.StreamedResponse>>[
        sendFuture,
        cancellationToken.cancelled.then(
          (_) => throw const _RecognitionCancelledException(),
        ),
      ]);

      final http.Response response = await http.Response.fromStream(streamed);
      apiSw.stop();
      totalSw.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SongIdentificationResult.failure(
          'Server error (${response.statusCode}): ${response.body.isNotEmpty ? response.body : 'No body'}',
          metrics: RecognitionMetrics(
            requestBytes: requestSize,
            preprocessingDuration: Duration.zero,
            apiLatency: apiSw.elapsed,
            totalDuration: totalSw.elapsed,
            usedFallback: true,
          ),
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return SongIdentificationResult.failure(
          'Unexpected server response (not a JSON object).',
          metrics: RecognitionMetrics(
            requestBytes: requestSize,
            preprocessingDuration: Duration.zero,
            apiLatency: apiSw.elapsed,
            totalDuration: totalSw.elapsed,
            usedFallback: true,
          ),
        );
      }

      final Object? confidenceRaw = decoded['confidence'];
      final double? confidence =
          confidenceRaw is num
              ? confidenceRaw.toDouble()
              : double.tryParse(confidenceRaw?.toString() ?? '');

      log(
        jsonEncode(<String, Object?>{
          'event': 'audio_upload_success',
          'request_bytes': requestSize,
          'api_latency_ms': apiSw.elapsed.inMilliseconds,
          'total_ms': totalSw.elapsed.inMilliseconds,
        }),
        name: 'vespera.recognition',
      );

      return SongIdentificationResult.success(
        title: decoded['title']?.toString(),
        artist: decoded['artist']?.toString(),
        confidence: confidence,
        raw: decoded,
        metrics: RecognitionMetrics(
          requestBytes: requestSize,
          preprocessingDuration: Duration.zero,
          apiLatency: apiSw.elapsed,
          totalDuration: totalSw.elapsed,
          usedFallback: true,
        ),
      );
    } on _RecognitionCancelledException {
      return const SongIdentificationResult.failure('Recognition cancelled.');
    } catch (e) {
      return SongIdentificationResult.failure('Upload failed: $e');
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }
}

class RecognitionOrchestrator {
  RecognitionOrchestrator({
    required RecognitionConfig config,
    required SongRecognizer peakRecognizer,
    required SongRecognizer audioUploadRecognizer,
  }) : _config = config,
       _peakRecognizer = peakRecognizer,
       _audioUploadRecognizer = audioUploadRecognizer;

  final RecognitionConfig _config;
  final SongRecognizer _peakRecognizer;
  final SongRecognizer _audioUploadRecognizer;

  Future<SongIdentificationResult> identify({
    required String filePath,
    required RecognitionCancellationToken cancellationToken,
  }) async {
    switch (_config.mode) {
      case RecognizerMode.audioOnly:
        return _audioUploadRecognizer.identify(
          filePath: filePath,
          cancellationToken: cancellationToken,
        );
      case RecognizerMode.peakOnly:
        return _peakRecognizer.identify(
          filePath: filePath,
          cancellationToken: cancellationToken,
        );
      case RecognizerMode.peakPrimary:
        final SongIdentificationResult peakResult = await _peakRecognizer
            .identify(filePath: filePath, cancellationToken: cancellationToken);
        if (peakResult.ok) {
          return peakResult;
        }
        if (cancellationToken.isCancelled) {
          return const SongIdentificationResult.failure(
            'Recognition cancelled.',
          );
        }

        log(
          jsonEncode(<String, Object?>{
            'event': 'peak_fallback_triggered',
            'reason': peakResult.error,
          }),
          name: 'vespera.recognition',
        );

        final SongIdentificationResult audioResult =
            await _audioUploadRecognizer.identify(
              filePath: filePath,
              cancellationToken: cancellationToken,
            );

        if (!audioResult.ok) {
          return SongIdentificationResult.failure(
            'Peak failed (${peakResult.error}) and fallback failed (${audioResult.error}).',
            metrics: audioResult.metrics,
          );
        }
        return audioResult;
    }
  }
}

class _RecognitionCancelledException implements Exception {
  const _RecognitionCancelledException();
}
