import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/remote_app_config.dart';

void main() {
  test('default remote app config keeps ads notices and updates disabled', () {
    const config = RemoteAppConfig.disabled();

    expect(config.enabledAdSlots, isEmpty);
    expect(config.popupNotice.enabled, isFalse);
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 1), isFalse);
  });

  test('parses firebase remote config style payload', () {
    final config = RemoteAppConfig.fromJson(<String, Object?>{
      'ad_slots': <Object?>[
        <String, Object?>{
          'placement': 'settings_footer',
          'title': '小米语音服务',
          'message': '领取 API 额度',
          'target_url': 'https://example.com/mimo',
          'enabled': true,
        },
        <String, Object?>{
          'placement': 'launch',
          'title': '未启用',
          'enabled': false,
        },
      ],
      'popup_notice': <String, Object?>{
        'title': '维护提醒',
        'message': '今晚 23:00 后可能短暂不可用',
        'target_url': 'https://example.com/status',
        'enabled': true,
      },
      'promo_link': 'https://example.com/register',
      'latest_version_code': 8,
      'min_supported_version_code': 6,
      'force_update': true,
      'update_url': 'https://example.com/download',
    });

    expect(config.enabledAdSlots, hasLength(1));
    expect(config.enabledAdSlots.single.placement, 'settings_footer');
    expect(config.popupNotice.title, '维护提醒');
    expect(config.promoLink, 'https://example.com/register');
    expect(config.updatePolicy.latestVersionCode, 8);
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 5), isTrue);
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 6), isFalse);
    expect(
      config.updatePolicy.hasOptionalUpdate(currentVersionCode: 7),
      isTrue,
    );
  });
}
