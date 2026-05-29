import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/remote_app_config.dart';
import 'package:voice_clone_app/src/services/remote_app_config_service.dart';

void main() {
  test(
    'static remote app config service returns disabled config by default',
    () async {
      final service = StaticRemoteAppConfigService();

      final config = await service.fetch();

      expect(config, isA<RemoteAppConfig>());
      expect(config.enabledAdSlots, isEmpty);
      expect(config.popupNotice.enabled, isFalse);
    },
  );

  test(
    'firebase remote config keys cover ads notices updates and promo link',
    () {
      expect(
        FirebaseRemoteConfigKeys.all,
        containsAll(<String>[
          'ad_slots',
          'popup_notice',
          'promo_link',
          'latest_version_code',
          'min_supported_version_code',
          'force_update',
          'update_url',
        ]),
      );
    },
  );
}
