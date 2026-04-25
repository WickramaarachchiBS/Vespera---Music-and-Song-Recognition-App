import 'dart:io';

import 'package:vespera/services/recognition/peak_extractor.dart';
import 'package:vespera/services/recognition/recognition_config.dart';
import 'package:vespera/services/recognition/recognition_models.dart';
import 'package:vespera/services/recognition/recognizers.dart';

Future<void> main(List<String> args) async {
  final _Args parsed = _Args.parse(args);
  if (parsed == null) {
    _printUsage();
    exitCode = 64;
    return;
  }

  if (parsed.clipPaths.length < 5) {
    stderr.writeln(
      'Please provide at least 5 clips for reproducible A/B evaluation.',
    );
    _printUsage();
    exitCode = 64;
    return;
  }

  final RecognitionConfig config = RecognitionConfig(
    peakEndpoint: Uri.parse('${parsed.baseUrl}/api/identify-peaks'),
    audioEndpoint: Uri.parse('${parsed.baseUrl}/api/identify'),
    mode: RecognizerMode.peakPrimary,
    apiTimeout: Duration(seconds: parsed.timeoutSeconds),
    retryCount: 0,
    enableGzipForLargePayload: false,
  );

  final PeakBasedRecognizer peakRecognizer = PeakBasedRecognizer(
    config: config,
    extractor: const PeakExtractor(),
  );
  final AudioUploadRecognizer audioRecognizer = AudioUploadRecognizer(
    config: config,
  );

  int total = 0;
  int comparable = 0;
  int agreements = 0;

  final List<int> peakPayloads = <int>[];
  final List<int> peakLatencyMs = <int>[];
  final List<int> audioLatencyMs = <int>[];

  stdout.writeln('Running A/B comparison against ${parsed.baseUrl}');
  stdout.writeln(
    'clip | peak_title | audio_title | agree | peak_payload_bytes | peak_api_ms | audio_api_ms',
  );

  for (final String clipPath in parsed.clipPaths) {
    total += 1;

    final File clip = File(clipPath);
    if (!await clip.exists()) {
      stderr.writeln('Skipping missing clip: $clipPath');
      continue;
    }

    final SongIdentificationResult peakResult = await peakRecognizer.identify(
      filePath: clipPath,
      cancellationToken: RecognitionCancellationToken(),
    );

    final String copiedPath = await _copyForAudio(clipPath);
    final SongIdentificationResult audioResult = await audioRecognizer.identify(
      filePath: copiedPath,
      cancellationToken: RecognitionCancellationToken(),
    );

    final String peakTitle = peakResult.title ?? '<none>';
    final String audioTitle = audioResult.title ?? '<none>';

    final bool bothOk = peakResult.ok && audioResult.ok;
    bool agreed = false;
    if (bothOk) {
      comparable += 1;
      agreed =
          _normalize(peakResult.title) == _normalize(audioResult.title) &&
          _normalize(peakResult.artist) == _normalize(audioResult.artist);
      if (agreed) {
        agreements += 1;
      }
    }

    final int peakPayload = peakResult.metrics?.requestBytes ?? -1;
    final int peakApiMs = peakResult.metrics?.apiLatency.inMilliseconds ?? -1;
    final int audioApiMs = audioResult.metrics?.apiLatency.inMilliseconds ?? -1;

    if (peakPayload >= 0) {
      peakPayloads.add(peakPayload);
    }
    if (peakApiMs >= 0) {
      peakLatencyMs.add(peakApiMs);
    }
    if (audioApiMs >= 0) {
      audioLatencyMs.add(audioApiMs);
    }

    stdout.writeln(
      '$clipPath | $peakTitle | $audioTitle | ${agreed ? 'PASS' : 'FAIL'} | $peakPayload | $peakApiMs | $audioApiMs',
    );

    if (!peakResult.ok) {
      stdout.writeln('  peak_error: ${peakResult.error}');
    }
    if (!audioResult.ok) {
      stdout.writeln('  audio_error: ${audioResult.error}');
    }
  }

  final double agreementRate =
      comparable == 0 ? 0.0 : (agreements * 100.0 / comparable);
  stdout.writeln('');
  stdout.writeln('Summary');
  stdout.writeln(
    'total_clips=$total comparable=$comparable agreements=$agreements agreement_rate=${agreementRate.toStringAsFixed(2)}%',
  );
  stdout.writeln(
    'peak_payload_avg_bytes=${_avg(peakPayloads).toStringAsFixed(1)}',
  );
  stdout.writeln('peak_api_avg_ms=${_avg(peakLatencyMs).toStringAsFixed(1)}');
  stdout.writeln('audio_api_avg_ms=${_avg(audioLatencyMs).toStringAsFixed(1)}');
}

class _Args {
  final String baseUrl;
  final List<String> clipPaths;
  final int timeoutSeconds;

  const _Args({
    required this.baseUrl,
    required this.clipPaths,
    required this.timeoutSeconds,
  });

  static _Args? parse(List<String> args) {
    String? baseUrl;
    final List<String> clipPaths = <String>[];
    int timeoutSeconds = 30;

    for (int i = 0; i < args.length; i++) {
      final String arg = args[i];
      if (arg == '--base-url' && i + 1 < args.length) {
        baseUrl = args[++i];
      } else if (arg == '--clip' && i + 1 < args.length) {
        clipPaths.add(args[++i]);
      } else if (arg == '--timeout-seconds' && i + 1 < args.length) {
        timeoutSeconds = int.tryParse(args[++i]) ?? timeoutSeconds;
      } else {
        return null;
      }
    }

    if (baseUrl == null || clipPaths.isEmpty) {
      return null;
    }

    return _Args(
      baseUrl: baseUrl,
      clipPaths: clipPaths,
      timeoutSeconds: timeoutSeconds,
    );
  }
}

String _normalize(String? value) {
  return (value ?? '').trim().toLowerCase();
}

double _avg(List<int> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final int total = values.reduce((int a, int b) => a + b);
  return total / values.length;
}

Future<String> _copyForAudio(String sourcePath) async {
  final File src = File(sourcePath);
  final Directory dir = await Directory.systemTemp.createTemp('vespera_ab_');
  final String targetPath =
      '${dir.path}${Platform.pathSeparator}${src.uri.pathSegments.last}';
  await src.copy(targetPath);
  return targetPath;
}

void _printUsage() {
  stdout.writeln('Usage:');
  stdout.writeln(
    '  dart run tool/recognition_ab_runner.dart --base-url <url> --clip <path1> --clip <path2> --clip <path3> --clip <path4> --clip <path5> [--timeout-seconds 30]',
  );
}
