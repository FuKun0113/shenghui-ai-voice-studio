import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';

class MockMimoService {
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '/mock/audio/designed-voice-$stamp.wav';
  }

  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return GeneratedAudio(
      id: 'audio-$stamp',
      text: request.text,
      voiceId: request.voiceId,
      voiceName: request.voiceName,
      audioPath: '/mock/audio/generated-$stamp.wav',
      durationMs: 3200,
      createdAt: DateTime.now(),
    );
  }
}
