import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_config.dart';
import 'package:vespera/services/recognition/recognition_models.dart';
import 'package:vespera/services/recognition/recognizers.dart';

class WhisperRecordingResult {
  final String? savedPath;
  final WhisperRecordingFailure? failure;

  const WhisperRecordingResult._({required this.savedPath, required this.failure});

  const WhisperRecordingResult.success(String path) : this._(savedPath: path, failure: null);

  const WhisperRecordingResult.failure(WhisperRecordingFailure failure) : this._(savedPath: null, failure: failure);

  bool get isSuccess => savedPath != null;
}

enum WhisperRecordingFailure { permissionDenied, alreadyRecording, failed, cancelled }

class WhisperService {
  WhisperService({AudioRecorder? recorder, RecognitionOrchestrator? orchestrator})
    : _recorder = recorder ?? AudioRecorder(),
      _orchestrator = orchestrator ?? _buildDefaultOrchestrator();

  final AudioRecorder _recorder;
  final RecognitionOrchestrator _orchestrator;

  static const String _baseEndpoint =
      'https://vesper-song-recognition-hrd3bsgagre6adc0.centralindia-01.azurewebsites.net';
  static const String identifyAudioEndpoint = '$_baseEndpoint/api/identify';
  static const String identifyPeaksEndpoint = '$_baseEndpoint/api/identify-peaks';

  static RecognitionConfig _defaultConfig() {
    return RecognitionConfig(
      peakEndpoint: Uri.parse(identifyPeaksEndpoint),
      audioEndpoint: Uri.parse(identifyAudioEndpoint),
      mode: RecognitionConfig.modeFromEnvironment(),
      appVersion: const String.fromEnvironment('VESPER_APP_VERSION', defaultValue: '1.0.0'),
    );
  }

  static RecognitionOrchestrator _buildDefaultOrchestrator() {
    final RecognitionConfig config = _defaultConfig();
    return RecognitionOrchestrator(
      config: config,
      peakRecognizer: PeakBasedRecognizer(config: config, extractor: const PeakExtractor()),
      audioUploadRecognizer: AudioUploadRecognizer(config: config),
    );
  }

  bool _isRecording = false;
  String? _lastSavedPath;
  Completer<void>? _cancelCompleter;
  RecognitionCancellationToken? _activeRecognitionToken;

  bool get isRecording => _isRecording;
  String? get lastSavedPath => _lastSavedPath;

  void cancelRecording() {
    if (_cancelCompleter != null && !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete();
    }
    _activeRecognitionToken?.cancel();
  }

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
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1, noiseSuppress: true),
        path: outputPath,
      );

      // ---------------------
      // Recording time (or early cancel)
      //----------------------
      _cancelCompleter = Completer<void>();
      await Future.any([Future.delayed(const Duration(seconds: 12)), _cancelCompleter!.future]);
      final wasCancelled = _cancelCompleter!.isCompleted;
      _cancelCompleter = null;

      final stoppedPath = await _recorder.stop();
      _isRecording = false;

      if (wasCancelled) {
        // Delete the partial recording
        try {
          final f = File(stoppedPath ?? outputPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
        return const WhisperRecordingResult.failure(WhisperRecordingFailure.cancelled);
      }

      final savedPath = stoppedPath ?? outputPath;
      _lastSavedPath = savedPath;

      return WhisperRecordingResult.success(savedPath);
    } catch (_) {
      _isRecording = false;
      _cancelCompleter = null;
      return const WhisperRecordingResult.failure(WhisperRecordingFailure.failed);
    }
  }

  Future<SongIdentificationResult> identifySongFromFile({required String filePath}) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return const SongIdentificationResult.failure('Recorded file not found.');
    }

    final RecognitionCancellationToken token = RecognitionCancellationToken();
    _activeRecognitionToken = token;
    try {
      final SongIdentificationResult result = await _orchestrator.identify(
        filePath: filePath,
        cancellationToken: token,
      );
      return result;
    } finally {
      if (identical(_activeRecognitionToken, token)) {
        _activeRecognitionToken = null;
      }
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
    return '${recordingsDir.path}${sep}whisper_$timestamp.wav';
  }
}
