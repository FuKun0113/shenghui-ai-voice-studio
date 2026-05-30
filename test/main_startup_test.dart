import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/main.dart' as app;
import 'package:shenghui_ai_voice_studio/src/app/product_build_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';

void main() {
  test('product config stays disabled without a json url', () async {
    final service = app.buildRemoteAppConfigService(
      buildConfig: const ProductBuildConfig(),
    );

    final config = await service.fetch();

    expect(service, isA<StaticRemoteAppConfigService>());
    expect(config.popupNotice.enabled, isFalse);
  });

  test('product config uses json endpoint when url is provided', () {
    final service = app.buildRemoteAppConfigService(
      buildConfig: const ProductBuildConfig(
        configUrl: 'https://config.example.com/shenghui.json',
      ),
    );

    expect(service, isA<FallbackRemoteAppConfigService>());
  });
}
