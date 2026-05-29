import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generation_request.dart';
import 'package:voice_clone_app/src/domain/voice.dart';

void main() {
  test('builtin voice routes to builtin tts', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'Mia',
    );

    final request = GenerationRequest.fromVoice(
      text: '你好，欢迎使用 AI 语音工作台。',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    expect(request.route, GenerationRoute.builtinTts);
    expect(request.referenceAudioPath, isNull);
    expect(request.providerVoiceId, 'Mia');
  });

  test('designed voice routes to voice clone with saved reference audio', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );

    final request = GenerationRequest.fromVoice(
      text: '这段文字应该使用固定参考音色生成。',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '更有亲和力',
    );

    expect(request.route, GenerationRoute.voiceClone);
    expect(request.referenceAudioPath, '/tmp/designed.wav');
    expect(request.providerVoiceId, isNull);
  });
}
