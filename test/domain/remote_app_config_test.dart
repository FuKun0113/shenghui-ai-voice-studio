import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';

void main() {
  test('default product config keeps ads and popup disabled', () {
    const config = RemoteAppConfig.disabled();

    expect(config.enabledAdSlots, isEmpty);
    expect(config.popupNotice.enabled, isFalse);
    expect(config.appUpdate.enabled, isFalse);
  });

  test('parses enabled ad slots popup notice and app update', () {
    final config = RemoteAppConfig.fromJson(<String, Object?>{
      'ad_slots': <Object?>[
        <String, Object?>{
          'placement': 'settings_footer',
          'title': '服务推荐',
          'message': '查看服务入口',
          'target_url': 'https://example.com/service',
          'enabled': true,
        },
        <String, Object?>{
          'placement': 'voice_service',
          'title': '隐藏入口',
          'enabled': false,
        },
      ],
      'popup_notice': <String, Object?>{
        'id': 'notice-20260531',
        'title': '公告',
        'message': '欢迎使用正式版',
        'target_url': 'https://example.com',
        'enabled': true,
      },
      'app_update': <String, Object?>{
        'latest_version': '0.0.2',
        'title': '新版可用',
        'message': '新增更稳定的更新检测。',
        'update_url': 'https://download.example.com/shenghui-0.0.2.apk',
        'force_update': true,
        'enabled': true,
      },
    });

    expect(config.enabledAdSlots, hasLength(1));
    expect(config.enabledAdSlots.single.placement, 'settings_footer');
    expect(config.popupNotice.acknowledgementKey, 'notice-20260531');
    expect(config.popupNotice.title, '公告');
    expect(config.appUpdate.hasVersion, isTrue);
    expect(config.appUpdate.latestVersion, '0.0.2');
    expect(config.appUpdate.title, '新版可用');
    expect(config.appUpdate.message, '新增更稳定的更新检测。');
    expect(
      config.appUpdate.updateUrl,
      'https://download.example.com/shenghui-0.0.2.apk',
    );
    expect(config.appUpdate.force, isTrue);
  });

  test('popup notice without explicit id falls back to content identity', () {
    const notice = RemotePopupNotice(
      title: '公告',
      message: '内容',
      targetUrl: 'https://example.com',
      enabled: true,
    );

    expect(notice.acknowledgementKey, contains('公告'));
    expect(notice.acknowledgementKey, contains('内容'));
  });

  test('parses website changelog endpoint as app update config', () {
    final config = RemoteAppConfig.fromJson(<String, Object?>{
      'success': true,
      'latestVersion': 'v0.0.3',
      'changelog': <Object?>[
        <String, Object?>{
          'version': 'v0.0.3',
          'name': '声绘 0.0.3',
          'description': '优化更新检测和下载入口。',
          'isLatest': true,
          'url':
              'https://github.com/FuKun0113/shenghui-ai-voice-studio/releases/tag/v0.0.3',
        },
      ],
    });

    expect(config.appUpdate.enabled, isTrue);
    expect(config.appUpdate.latestVersion, 'v0.0.3');
    expect(config.appUpdate.title, '声绘 0.0.3');
    expect(config.appUpdate.message, '优化更新检测和下载入口。');
    expect(
      config.appUpdate.updateUrl,
      'https://shenghui.cloudlark.net/#download',
    );
  });
}
