import '../domain/generation_request.dart';

class MimoRequestBuilder {
  static Map<String, Object?> buildSpeechBody(GenerationRequest request) {
    return switch (request.route) {
      GenerationRoute.builtinTts => <String, Object?>{
          'model': 'mimo-v2.5-tts',
          'text': request.text,
          'voice': request.providerVoiceId,
          'speed': request.speed,
          'emotion': request.emotion,
          'stylePrompt': request.stylePrompt,
        },
      GenerationRoute.voiceClone => <String, Object?>{
          'model': 'mimo-v2.5-tts-voiceclone',
          'text': request.text,
          'referenceAudioPath': request.referenceAudioPath,
          'speed': request.speed,
          'emotion': request.emotion,
          'stylePrompt': request.stylePrompt,
        },
    };
  }
}
