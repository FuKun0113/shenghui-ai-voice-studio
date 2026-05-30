import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/voice.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_voice_store.dart';

void main() {
  test('loads builtins and persisted user voices', () async {
    final jsonStore = MemoryJsonStore();
    final store = LocalVoiceStore(jsonStore: jsonStore);
    final created = DateTime(2026, 5, 29, 10);

    await store.saveUserVoices(<Voice>[
      Voice.cloned(
        id: 'custom-1',
        name: '我的音色',
        referenceAudioPath: '/tmp/ref.wav',
        createdAt: created,
      ),
    ]);

    final voices = await store.loadVoices();

    expect(
      voices.where((voice) => voice.type == VoiceType.builtin),
      hasLength(9),
    );
    expect(voices.any((voice) => voice.id == 'custom-1'), isTrue);
  });

  test('persists favorite overlays for builtin voices', () async {
    final jsonStore = MemoryJsonStore();
    final store = LocalVoiceStore(jsonStore: jsonStore);

    await store.saveVoiceOverlay(
      'mimo-default',
      favorite: true,
      lastUsedAt: DateTime(2026, 5, 29, 12),
    );

    final voices = await store.loadVoices();
    final voice = voices.singleWhere((item) => item.id == 'mimo-default');

    expect(voice.favorite, isTrue);
    expect(voice.lastUsedAt, DateTime(2026, 5, 29, 12));
  });
}
