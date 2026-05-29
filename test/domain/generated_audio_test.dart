import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generated_audio.dart';

void main() {
  test('json round trip keeps title and favorite', () {
    final audio = GeneratedAudio(
      id: 'audio-1',
      text: '欢迎使用',
      voiceId: 'mimo-default',
      voiceName: 'MiMo-默认',
      audioPath: '/tmp/audio.wav',
      durationMs: 3200,
      createdAt: DateTime(2026, 5, 29, 10),
      title: '欢迎词',
      stylePrompt: '温柔讲述',
      favorite: true,
    );

    final restored = GeneratedAudio.fromJson(audio.toJson());

    expect(restored.title, '欢迎词');
    expect(restored.stylePrompt, '温柔讲述');
    expect(restored.favorite, isTrue);
    expect(restored.createdAt, DateTime(2026, 5, 29, 10));
  });
}
