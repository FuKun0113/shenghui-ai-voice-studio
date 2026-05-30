import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';

void main() {
  test('default remote app config keeps notices and updates disabled', () {
    const config = RemoteAppConfig.disabled();

    expect(config.popupNotice.enabled, isFalse);
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 1), isFalse);
    expect(
      config.updatePolicy.hasOptionalUpdate(currentVersionName: '1.0.0'),
      isFalse,
    );
  });

  test('parses remote json config payload', () {
    final config = RemoteAppConfig.fromJson(<String, Object?>{
      'popup_notice': <String, Object?>{
        'id': 'maintenance-20260530',
        'title': '维护提醒',
        'message': '今晚 23:00 后可能短暂不可用',
        'target_url': 'https://example.com/status',
        'enabled': true,
      },
      'latest_version_code': 8,
      'min_supported_version_code': 6,
      'latest_version': '1.1.0',
      'min_supported_version': '1.0.0',
      'force_update': true,
      'update_url': 'https://example.com/download',
    });

    expect(config.popupNotice.id, 'maintenance-20260530');
    expect(config.popupNotice.acknowledgementKey, 'maintenance-20260530');
    expect(config.popupNotice.title, '维护提醒');
    expect(config.updatePolicy.latestVersionCode, 8);
    expect(config.updatePolicy.latestVersion, '1.1.0');
    expect(config.updatePolicy.minSupportedVersion, '1.0.0');
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 5), isTrue);
    expect(config.updatePolicy.requiresUpdate(currentVersionCode: 6), isFalse);
    expect(
      config.updatePolicy.requiresUpdate(currentVersionName: '0.9.9'),
      isTrue,
    );
    expect(
      config.updatePolicy.requiresUpdate(currentVersionName: '1.0.0'),
      isFalse,
    );
    expect(
      config.updatePolicy.hasOptionalUpdate(currentVersionCode: 7),
      isTrue,
    );
    expect(
      config.updatePolicy.hasOptionalUpdate(currentVersionName: '1.0.9'),
      isTrue,
    );
    expect(
      config.updatePolicy.hasOptionalUpdate(currentVersionName: '1.1.0'),
      isFalse,
    );
  });

  test(
    'semantic version comparison handles build metadata and patch width',
    () {
      const policy = RemoteUpdatePolicy(
        latestVersion: '1.0.10',
        minSupportedVersion: '1.0.0',
        forceUpdate: true,
      );

      expect(policy.requiresUpdate(currentVersionName: '0.9.9+7'), isTrue);
      expect(policy.requiresUpdate(currentVersionName: '1.0.0+1'), isFalse);
      expect(policy.hasOptionalUpdate(currentVersionName: '1.0.9'), isTrue);
      expect(policy.hasOptionalUpdate(currentVersionName: '1.0.10'), isFalse);
    },
  );

  test('popup notice without explicit id falls back to content identity', () {
    const notice = RemotePopupNotice(
      title: '维护提醒',
      message: '今晚 23:00 后可能短暂不可用',
      targetUrl: 'https://example.com/status',
      enabled: true,
    );

    expect(
      notice.acknowledgementKey,
      '维护提醒\u001f今晚 23:00 后可能短暂不可用\u001fhttps://example.com/status',
    );
  });
}
