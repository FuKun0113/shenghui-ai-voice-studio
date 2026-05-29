import 'package:flutter/material.dart';

import 'src/app/voice_clone_app.dart';
import 'src/services/local_draft_store.dart';
import 'src/services/local_history_store.dart';
import 'src/services/local_json_store.dart';
import 'src/services/local_voice_store.dart';
import 'src/services/mimo_client.dart';
import 'src/services/service_config_store.dart';
import 'src/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jsonStore = SharedPreferencesJsonStore();
  final configStore = LocalServiceConfigStore();
  final serviceConfig = await configStore.load();
  final appState = AppState(
    mimoService: MimoApiService(),
    serviceConfig: serviceConfig,
    serviceConfigStore: configStore,
    voiceStore: LocalVoiceStore(jsonStore: jsonStore),
    historyStore: LocalHistoryStore(jsonStore: jsonStore),
    draftStore: LocalDraftStore(jsonStore: jsonStore),
  );
  await appState.loadLocalData();
  runApp(VoiceCloneApp(appState: appState));
}
