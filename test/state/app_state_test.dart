import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/voice.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';

void main() {
  test('starts with builtin voices and selects the first one', () {
    final state = AppState(mimoService: MockMimoService());

    expect(
      state.voices.where((voice) => voice.type == VoiceType.builtin),
      isNotEmpty,
    );
    expect(state.selectedVoice, isNotNull);
  });

  test(
    'saving a designed voice stores reference audio and routes through clone',
    () async {
      final state = AppState(mimoService: MockMimoService());

      final voice = await state.designVoice(
        name: '温柔旁白',
        stylePrompt: '年轻女性，温柔，清晰',
      );

      expect(voice.type, VoiceType.designed);
      expect(voice.referenceAudioPath, contains('designed-voice'));
      expect(state.voices.any((item) => item.id == voice.id), isTrue);
    },
  );

  test('generated audio is appended to history', () async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('你好，欢迎使用 AI 语音工作台。');

    final generated = await state.generateCurrentVoice();

    expect(generated.text, '你好，欢迎使用 AI 语音工作台。');
    expect(state.history.single.id, generated.id);
  });
}
