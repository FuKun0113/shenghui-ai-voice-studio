import '../domain/voice.dart';

class LocalVoiceStore {
  List<Voice> builtinVoices() {
    return <Voice>[
      Voice.builtin(
        id: 'mimo-mia',
        name: 'Mia',
        providerVoiceId: 'mimo_mia',
      ),
      Voice.builtin(
        id: 'mimo-chloe',
        name: 'Chloe',
        providerVoiceId: 'mimo_chloe',
      ),
      Voice.builtin(
        id: 'mimo-milo',
        name: 'Milo',
        providerVoiceId: 'mimo_milo',
      ),
      Voice.builtin(
        id: 'mimo-dean',
        name: 'Dean',
        providerVoiceId: 'mimo_dean',
      ),
    ];
  }
}
