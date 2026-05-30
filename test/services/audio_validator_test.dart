import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/audio_format.dart';
import 'package:shenghui_ai_voice_studio/src/services/audio_validator.dart';

void main() {
  test('accepts mp3 and wav reference audio', () {
    expect(AudioValidator.detectFormat('/tmp/sample.mp3'), AudioFormat.mp3);
    expect(AudioValidator.detectFormat('/tmp/sample.wav'), AudioFormat.wav);
  });

  test('rejects unsupported reference audio formats', () {
    expect(
      () => AudioValidator.requireSupported('/tmp/sample.m4a'),
      throwsA(isA<UnsupportedAudioFormatException>()),
    );
  });

  test('returns the original path for supported reference audio', () {
    expect(
      AudioValidator.requireSupported('/tmp/reference.wav'),
      '/tmp/reference.wav',
    );
    expect(
      AudioValidator.requireSupported('/tmp/reference.mp3'),
      '/tmp/reference.mp3',
    );
  });

  test('validates existing reference audio file and size', () async {
    final directory = await Directory.systemTemp.createTemp('mimo-audio-test');
    final file = File('${directory.path}/reference.wav');
    await file.writeAsBytes(List<int>.filled(32, 1));

    final result = await AudioValidator.validateReferenceFile(file.path);

    expect(result.isValid, isTrue);
    expect(result.message, contains('可用'));
  });

  test('rejects missing reference audio file', () async {
    final result = await AudioValidator.validateReferenceFile(
      '/missing/reference.wav',
    );
    expect(result.isValid, isFalse);
    expect(result.message, contains('文件不存在'));
  });

  test('rejects reference audio larger than five megabytes', () async {
    final directory = await Directory.systemTemp.createTemp('mimo-audio-test');
    final file = File('${directory.path}/too-large.wav');
    await file.writeAsBytes(
      List<int>.filled(AudioValidator.maxReferenceFileBytes + 1, 1),
    );

    final result = await AudioValidator.validateReferenceFile(file.path);

    expect(result.isValid, isFalse);
    expect(result.message, contains('5 MB'));
  });
}
