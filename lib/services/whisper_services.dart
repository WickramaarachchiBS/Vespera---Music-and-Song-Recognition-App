import 'dart:io';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class WhisperRecordingResult {
  final String? savedPath;
  final WhisperRecordingFailure? failure;

  const WhisperRecordingResult._({required this.savedPath, required this.failure});

  const WhisperRecordingResult.success(String path) : this._(savedPath: path, failure: null);

  const WhisperRecordingResult.failure(WhisperRecordingFailure failure) : this._(savedPath: null, failure: failure);

  bool get isSuccess => savedPath != null;
}

enum WhisperRecordingFailure { permissionDenied, alreadyRecording, failed }

class SongIdentificationResult {
  final bool ok;
  final String? title;
  final String? artist;
  final double? confidence;
  final Map<String, dynamic>? raw;
  final String? error;

  const SongIdentificationResult._({
    required this.ok,
    required this.title,
    required this.artist,
    required this.confidence,
    required this.raw,
    required this.error,
  });

  const SongIdentificationResult.success({String? title, String? artist, double? confidence, Map<String, dynamic>? raw})
    : this._(ok: true, title: title, artist: artist, confidence: confidence, raw: raw, error: null);

  const SongIdentificationResult.failure(String message)
    : this._(ok: false, title: null, artist: null, confidence: null, raw: null, error: message);
}

class WhisperService {
  WhisperService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  bool _isRecording = false;
  String? _lastSavedPath;

  bool get isRecording => _isRecording;
  String? get lastSavedPath => _lastSavedPath;

  Future<void> dispose() async {
    // record's AudioRecorder implements dispose in v6.
    await _recorder.dispose();
  }

  Future<WhisperRecordingResult> startTenSecondRecording() async {
    if (_isRecording) {
      return const WhisperRecordingResult.failure(WhisperRecordingFailure.alreadyRecording);
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return const WhisperRecordingResult.failure(WhisperRecordingFailure.permissionDenied);
    }

    try {
      _isRecording = true;

      final outputPath = await _buildOutputPath();

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: outputPath,
      );

      await Future.delayed(const Duration(seconds: 10));

      final stoppedPath = await _recorder.stop();
      _isRecording = false;

      final savedPath = stoppedPath ?? outputPath;
      _lastSavedPath = savedPath;

      return WhisperRecordingResult.success(savedPath);
    } catch (_) {
      _isRecording = false;
      return const WhisperRecordingResult.failure(WhisperRecordingFailure.failed);
    }
  }

  /// Uploads a recorded audio file to a Python server for identification.
  ///
  /// Expected server behavior (flexible):
  /// - Accepts `multipart/form-data` with field [fileField] (default: `file`).
  /// - Returns JSON. Common keys we try to read: `title`, `artist`, `confidence`.
  Future<SongIdentificationResult> identifySongFromFile({
    required String filePath,
    required Uri endpoint,
    String fileField = 'file',
    Map<String, String>? extraFields,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final file = File(filePath);
    final exists = await file.exists();
    if (!exists) {
      return const SongIdentificationResult.failure('Recorded file not found.');
    }

    try {
      final request = http.MultipartRequest('POST', endpoint);
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SongIdentificationResult.failure(
          'Server error (${response.statusCode}): ${response.body.isNotEmpty ? response.body : 'No body'}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const SongIdentificationResult.failure('Unexpected server response (not a JSON object).');
      }

      final title = decoded['title']?.toString();
      final artist = decoded['artist']?.toString();
      final confidenceRaw = decoded['confidence'];
      final confidence =
          confidenceRaw is num ? confidenceRaw.toDouble() : double.tryParse(confidenceRaw?.toString() ?? '');

      return SongIdentificationResult.success(title: title, artist: artist, confidence: confidence, raw: decoded);
    } catch (e) {
      return SongIdentificationResult.failure('Upload failed: $e');
    }
  }

  Future<String> _buildOutputPath() async {
    final String sep = Platform.pathSeparator;

    Directory baseDir;
    if (Platform.isAndroid) {
      final externalDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
      baseDir =
          (externalDirs != null && externalDirs.isNotEmpty)
              ? externalDirs.first
              : await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final recordingsDir = Directory('${baseDir.path}${sep}Vespera${sep}recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${recordingsDir.path}${sep}whisper_$timestamp.m4a';
  }
}
