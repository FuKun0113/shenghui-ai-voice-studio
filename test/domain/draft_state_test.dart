import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/draft_state.dart';

void main() {
  test('stores current generation choices', () {
    const draft = DraftState(
      text: '稿件',
      stylePrompt: '温柔',
      speed: 1.2,
      emotion: '开心',
      selectedVoiceId: 'voice-1',
    );

    final restored = DraftState.fromJson(draft.toJson());

    expect(restored.text, '稿件');
    expect(restored.speed, 1.2);
    expect(restored.selectedVoiceId, 'voice-1');
  });
}
