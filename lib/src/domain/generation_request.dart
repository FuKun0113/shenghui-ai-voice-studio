import 'voice.dart';

enum GenerationRoute { builtinTts, voiceClone }

class GenerationRequest {
  const GenerationRequest({
    required this.text,
    required this.voiceId,
    required this.voiceName,
    required this.route,
    required this.speed,
    required this.emotion,
    required this.stylePrompt,
    this.providerVoiceId,
    this.referenceAudioPath,
  });

  factory GenerationRequest.fromVoice({
    required String text,
    required Voice voice,
    required double speed,
    required String emotion,
    required String stylePrompt,
  }) {
    return GenerationRequest(
      text: text,
      voiceId: voice.id,
      voiceName: voice.name,
      route: voice.requiresReferenceAudio
          ? GenerationRoute.voiceClone
          : GenerationRoute.builtinTts,
      speed: speed,
      emotion: emotion,
      stylePrompt: stylePrompt,
      providerVoiceId: voice.providerVoiceId,
      referenceAudioPath: voice.referenceAudioPath,
    );
  }

  final String text;
  final String voiceId;
  final String voiceName;
  final GenerationRoute route;
  final double speed;
  final String emotion;
  final String stylePrompt;
  final String? providerVoiceId;
  final String? referenceAudioPath;
}
