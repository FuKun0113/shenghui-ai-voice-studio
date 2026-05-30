import 'dart:async';

import 'package:flutter/material.dart';

import 'src/app/build_config.dart';
import 'src/app/shenghui_app.dart';
import 'src/services/local_draft_store.dart';
import 'src/services/local_history_store.dart';
import 'src/services/local_json_store.dart';
import 'src/services/local_popup_notice_store.dart';
import 'src/services/local_voice_store.dart';
import 'src/services/mimo_client.dart';
import 'src/services/remote_app_config_service.dart';
import 'src/services/service_config_store.dart';
import 'src/services/text_optimization_config_store.dart';
import 'src/services/text_optimization_service.dart';
import 'src/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const buildConfig = AppBuildConfig.fromEnvironment();
  final jsonStore = SharedPreferencesJsonStore();
  final configStore = LocalServiceConfigStore();
  final textOptimizationConfigStore = LocalTextOptimizationConfigStore();
  final serviceConfig = await configStore.load();
  final textOptimizationConfig = await textOptimizationConfigStore.load();
  final appState = AppState(
    mimoService: MimoApiService(),
    textOptimizationService: OpenAiCompatibleTextOptimizationService(),
    serviceConfig: serviceConfig,
    textOptimizationConfig: textOptimizationConfig,
    serviceConfigStore: configStore,
    textOptimizationConfigStore: textOptimizationConfigStore,
    voiceStore: LocalVoiceStore(jsonStore: jsonStore),
    historyStore: LocalHistoryStore(jsonStore: jsonStore),
    draftStore: LocalDraftStore(jsonStore: jsonStore),
    remoteAppConfigService: buildRemoteAppConfigService(
      buildConfig: buildConfig,
    ),
  );
  await appState.loadLocalData();
  runApp(
    ShenghuiApp(
      appState: appState,
      popupNoticeStore: LocalPopupNoticeStore(jsonStore: jsonStore),
    ),
  );
  unawaited(appState.loadRemoteAppConfig());
}

@visibleForTesting
RemoteAppConfigService buildRemoteAppConfigService({
  AppBuildConfig buildConfig = const AppBuildConfig.fromEnvironment(),
}) {
  final normalizedUrl = buildConfig.normalizedRemoteConfigUrl;
  if (!buildConfig.canUseRemoteConfig || normalizedUrl.isEmpty) {
    return StaticRemoteAppConfigService();
  }
  return FallbackRemoteAppConfigService(
    primary: HttpRemoteAppConfigService(configUrl: normalizedUrl),
    fallback: StaticRemoteAppConfigService(),
  );
}
