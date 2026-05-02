import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

Future<String> createTestWavFile({
  required Directory dir,
  required String fileName,
  required double durationSeconds,
  int sampleRate = 44100,
  double frequencyHz = 440.0,
}) async {
  final int sampleCount = (durationSeconds * sampleRate).round();
  final List<int> pcmBytes = <int>[];
  for (int i = 0; i < sampleCount; i++) {
    final double t = i / sampleRate;
    final double sample = sin(2 * pi * frequencyHz * t) * 0.4;
    final int v = (sample * 32767).round().clamp(-32768, 32767);
    pcmBytes.add(v & 0xFF);
    pcmBytes.add((v >> 8) & 0xFF);
  }

  final Uint8List header = _wavHeader(
    sampleRate: sampleRate,
    channels: 1,
    bitsPerSample: 16,
    dataSize: pcmBytes.length,
  );

  final File file = File('${dir.path}${Platform.pathSeparator}$fileName');
  final IOSink sink = file.openWrite();
  sink.add(header);
  sink.add(pcmBytes);
  await sink.close();
  return file.path;
}

Uint8List _wavHeader({
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
  required int dataSize,
}) {
  final int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final int blockAlign = channels * bitsPerSample ~/ 8;
  final int chunkSize = 36 + dataSize;

  final ByteData data = ByteData(44);
  void writeAscii(int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  data.setUint32(4, chunkSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, byteRate, Endian.little);
  data.setUint16(32, blockAlign, Endian.little);
  data.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  data.setUint32(40, dataSize, Endian.little);

  return data.buffer.asUint8List();
}
