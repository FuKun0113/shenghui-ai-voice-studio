import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/voice.dart';

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
      id: 'mimo-chloe',
      name: 'Chloe',
      providerVoiceId: 'Chloe',
      language: 'English',
      gender: 'Female',
      tags: const <String>['官方预置', 'English', 'Female'],
    );

    expect(voice.type, VoiceType.builtin);
    expect(voice.requiresReferenceAudio, isFalse);
    expect(voice.providerVoiceId, 'Chloe');
    expect(voice.tags, containsAll(<String>['官方预置', 'English', 'Female']));
  });

  test('copyWith preserves fields and updates favorite metadata', () {
    final created = DateTime(2026, 5, 29, 10);
    final voice = Voice.cloned(
      id: 'voice-1',
      name: '我的音色',
      referenceAudioPath: '/tmp/ref.wav',
      gender: '女声',
      tags: const <String>['用户创建', '女声'],
      createdAt: created,
    );

    final updated = voice.copyWith(
      favorite: true,
      lastUsedAt: DateTime(2026, 5, 29, 11),
    );

    expect(updated.id, 'voice-1');
    expect(updated.favorite, isTrue);
    expect(updated.lastUsedAt, DateTime(2026, 5, 29, 11));
    expect(updated.referenceAudioPath, '/tmp/ref.wav');
  });

  test('json round trip keeps clone metadata', () {
    final created = DateTime(2026, 5, 29, 10);
    final voice = Voice.cloned(
      id: 'voice-1',
      name: '我的音色',
      referenceAudioPath: '/tmp/ref.wav',
      gender: '男声',
      tags: const <String>['用户创建', '男声'],
      createdAt: created,
    ).copyWith(favorite: true, lastUsedAt: DateTime(2026, 5, 29, 11));

    final restored = Voice.fromJson(voice.toJson());

    expect(restored.id, voice.id);
    expect(restored.type, VoiceType.cloned);
    expect(restored.favorite, isTrue);
    expect(restored.lastUsedAt, DateTime(2026, 5, 29, 11));
  });
}
