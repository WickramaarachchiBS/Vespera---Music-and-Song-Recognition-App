import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/recognition_config.dart';
import 'package:vespera/services/recognition/recognition_models.dart';
import 'package:vespera/services/recognition/recognizers.dart';

class _FakeRecognizer implements SongRecognizer {
  _FakeRecognizer(this._result);

  final SongIdentificationResult _result;
  int calls = 0;

  @override
  Future<SongIdentificationResult> identify({
    required String filePath,
    required RecognitionCancellationToken cancellationToken,
  }) async {
    calls += 1;
    return _result;
  }
}

void main() {
  test('orchestrator falls back to audio when peak fails', () async {
    final _FakeRecognizer peak = _FakeRecognizer(const SongIdentificationResult.failure('peak down'));
    final _FakeRecognizer audio = _FakeRecognizer(
      const SongIdentificationResult.success(title: 'Song', artist: 'Artist', confidence: 88.2),
    );

    final RecognitionOrchestrator orchestrator = RecognitionOrchestrator(
      config: RecognitionConfig(
        peakEndpoint: Uri.parse('https://example.test/api/identify-peaks'),
        audioEndpoint: Uri.parse('https://example.test/api/identify'),
        mode: RecognizerMode.peakPrimary,
      ),
      peakRecognizer: peak,
      audioUploadRecognizer: audio,
    );

    final SongIdentificationResult result = await orchestrator.identify(
      filePath: '/tmp/ignored.wav',
      cancellationToken: RecognitionCancellationToken(),
    );

    expect(result.ok, isTrue);
    expect(peak.calls, 1);
    expect(audio.calls, 1);
  });
}
