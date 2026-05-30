import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/main.dart' as app;
import 'package:shenghui_ai_voice_studio/src/app/build_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/usage_analytics_service.dart';

void main() {
  test(
    'open source builds keep remote config disabled even when firebase is ready',
    () async {
      final service = app.buildRemoteAppConfigService(
        firebaseReady: true,
        buildConfig: const AppBuildConfig(
          isOfficialBuild: false,
          remoteConfigUrl: 'https://config.example.com/shenghui.json',
        ),
      );

      final config = await service.fetch();

      expect(service, isA<StaticRemoteAppConfigService>());
      expect(config.enabledAdSlots, isEmpty);
      expect(config.popupNotice.enabled, isFalse);
    },
  );

  test('official builds can use domestic remote config', () {
    final service = app.buildRemoteAppConfigService(
      firebaseReady: false,
      buildConfig: const AppBuildConfig(
        isOfficialBuild: true,
        remoteConfigUrl: 'https://config.example.com/shenghui.json',
      ),
    );

    expect(service, isA<FallbackRemoteAppConfigService>());
  });

  test(
    'analytics service is disabled unless an official endpoint is provided',
    () {
      expect(
        app.buildUsageAnalyticsService(
          buildConfig: const AppBuildConfig(isOfficialBuild: true),
        ),
        isA<NoopUsageAnalyticsService>(),
      );
      expect(
        app.buildUsageAnalyticsService(
          buildConfig: const AppBuildConfig(
            isOfficialBuild: false,
            analyticsEndpoint: 'https://analytics.example.com/events',
          ),
        ),
        isA<NoopUsageAnalyticsService>(),
      );
      expect(
        app.buildUsageAnalyticsService(
          buildConfig: const AppBuildConfig(
            isOfficialBuild: true,
            analyticsEndpoint: 'https://analytics.example.com/events',
          ),
          jsonStore: MemoryJsonStore(),
        ),
        isA<HttpUsageAnalyticsService>(),
      );
    },
  );

  test(
    'firebase startup initialization times out instead of blocking startup',
    () async {
      final neverCompletes = Completer<void>();

      final initialized = await app.initializeFirebaseForStartup(
        initialize: () => neverCompletes.future,
        timeout: const Duration(milliseconds: 1),
        logFailures: false,
      );

      expect(initialized, isFalse);
    },
  );

  test(
    'firebase startup initialization reports success when it completes',
    () async {
      final initialized = await app.initializeFirebaseForStartup(
        initialize: () async {},
        timeout: const Duration(milliseconds: 1),
      );

      expect(initialized, isTrue);
    },
  );
}
