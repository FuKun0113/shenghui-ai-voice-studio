import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/generated_audio.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_history_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';

void main() {
  test('persists generated audio list', () async {
    final store = LocalHistoryStore(jsonStore: MemoryJsonStore());
    final item = GeneratedAudio(
      id: 'audio-1',
      text: '文本',
      voiceId: 'voice-1',
      voiceName: '音色',
      audioPath: '/tmp/audio.wav',
      durationMs: 1200,
      createdAt: DateTime(2026, 5, 29, 10),
    );

    await store.saveHistory(<GeneratedAudio>[item]);

    final restored = await store.loadHistory();
    expect(restored.single.id, 'audio-1');
    expect(restored.single.text, '文本');
  });
}
