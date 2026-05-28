import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generation_request.dart';
import 'package:voice_clone_app/src/domain/voice.dart';
import 'package:voice_clone_app/src/services/mimo_client.dart';

void main() {
  test('builtin request uses provider voice id', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'mimo_mia',
    );
    final request = GenerationRequest.fromVoice(
      text: '你好',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    final body = MimoRequestBuilder.buildSpeechBody(request);

    expect(body['model'], 'mimo-v2.5-tts');
    expect(body['voice'], 'mimo_mia');
  });

  test('designed request uses voice clone model and reference audio path', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );
    final request = GenerationRequest.fromVoice(
      text: '你好',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    final body = MimoRequestBuilder.buildSpeechBody(request);

    expect(body['model'], 'mimo-v2.5-tts-voiceclone');
    expect(body['referenceAudioPath'], '/tmp/designed.wav');
  });
}
