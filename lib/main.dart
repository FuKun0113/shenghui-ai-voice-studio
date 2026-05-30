import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
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
  final firebaseReady = await initializeFirebaseForStartup();
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
      firebaseReady: firebaseReady,
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
  required bool firebaseReady,
  String domesticConfigUrl = const String.fromEnvironment(
    'SHENGHUI_REMOTE_CONFIG_URL',
  ),
}) {
  final firebaseFallback = firebaseReady
      ? FirebaseRemoteAppConfigService()
      : StaticRemoteAppConfigService();
  final normalizedUrl = domesticConfigUrl.trim();
  if (normalizedUrl.isEmpty) return firebaseFallback;
  return FallbackRemoteAppConfigService(
    primary: HttpRemoteAppConfigService(configUrl: normalizedUrl),
    fallback: firebaseFallback,
  );
}

@visibleForTesting
Future<bool> initializeFirebaseForStartup({
  Future<void> Function()? initialize,
  Duration timeout = const Duration(seconds: 2),
  bool logFailures = true,
}) async {
  try {
    await (initialize ?? _initializeFirebaseApp)().timeout(timeout);
    return true;
  } on TimeoutException catch (error) {
    _logFirebaseStartupFailure(
      'Firebase startup timed out: $error',
      logFailures,
    );
  } on UnsupportedError catch (error) {
    _logFirebaseStartupFailure('Firebase skipped: $error', logFailures);
  } on FirebaseException catch (error) {
    _logFirebaseStartupFailure(
      'Firebase initialization failed: ${error.message}',
      logFailures,
    );
  } on Object catch (error) {
    _logFirebaseStartupFailure(
      'Firebase initialization skipped: $error',
      logFailures,
    );
  }
  return false;
}

void _logFirebaseStartupFailure(String message, bool enabled) {
  if (enabled) debugPrint(message);
}

Future<void> _initializeFirebaseApp() {
  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
