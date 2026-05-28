import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/voice.dart';

void main() {
  test('designed voices require reference audio after save', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );

    expect(voice.type, VoiceType.designed);
    expect(voice.requiresReferenceAudio, isTrue);
    expect(voice.referenceAudioPath, '/tmp/designed.wav');
  });

  test('builtin voices do not require local reference audio', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'mimo_mia',
    );

    expect(voice.type, VoiceType.builtin);
    expect(voice.requiresReferenceAudio, isFalse);
    expect(voice.providerVoiceId, 'mimo_mia');
  });
}
