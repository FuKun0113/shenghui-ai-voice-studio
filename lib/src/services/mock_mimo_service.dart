import '../domain/generated_audio.dart';
import '../domain/connection_test_result.dart';
import '../domain/generation_request.dart';
import '../domain/service_config.dart';
import 'mimo_client.dart';

class MockMimoService implements MimoService {
  @override
  Future<ConnectionTestResult> testConnection({
    required ServiceConfig config,
  }) async {
    if (!config.hasApiKey) {
      return const ConnectionTestResult(
        status: ConnectionTestStatus.missingApiKey,
        message: '请先填写语音服务密钥',
      );
    }
    return const ConnectionTestResult(
      status: ConnectionTestStatus.success,
      message: '连接成功，语音服务可用',
    );
  }

  @override
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
    required ServiceConfig config,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '/mock/audio/designed-voice-$stamp.wav';
  }

  @override
  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
    required ServiceConfig config,
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
      stylePrompt: request.stylePrompt,
    );
  }
}
