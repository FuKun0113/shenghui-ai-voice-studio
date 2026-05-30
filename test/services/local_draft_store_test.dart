import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/draft_state.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_draft_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';

void main() {
  test('persists draft state', () async {
    final store = LocalDraftStore(jsonStore: MemoryJsonStore());
    const draft = DraftState(
      text: '脚本',
      stylePrompt: '亲切',
      speed: 1.1,
      emotion: '开心',
      selectedVoiceId: 'voice-1',
    );

    await store.save(draft);

    final restored = await store.load();
    expect(restored.text, '脚本');
    expect(restored.selectedVoiceId, 'voice-1');
  });
}
