import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/audio_format.dart';
import 'package:voice_clone_app/src/services/audio_validator.dart';

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
}
