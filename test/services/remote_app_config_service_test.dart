import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';

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

  test('firebase remote config keys cover ads notices and updates', () {
    expect(
      FirebaseRemoteConfigKeys.all,
      containsAll(<String>[
        'ad_slots',
        'popup_notice',
        'latest_version',
        'min_supported_version',
        'latest_version_code',
        'min_supported_version_code',
        'force_update',
        'update_url',
      ]),
    );
  });

  test(
    'firebase remote app config service maps remote config values into app config',
    () async {
      final client = FakeRemoteConfigClient(
        stringValues: const <String, String>{
          FirebaseRemoteConfigKeys.adSlots:
              '[{"placement":"settings_footer","title":"服务推荐","message":"领取额度","target_url":"https://example.com/promo","enabled":true},{"placement":"voice_service","title":"语音服务推荐","enabled":true},{"placement":"text_optimization_service","title":"文本模型推荐","enabled":true}]',
          FirebaseRemoteConfigKeys.popupNotice:
              '{"title":"版本提醒","message":"新版本体验更顺滑","target_url":"https://example.com/update","enabled":true}',
          FirebaseRemoteConfigKeys.latestVersion: '1.2.0',
          FirebaseRemoteConfigKeys.minSupportedVersion: '1.1.0',
          FirebaseRemoteConfigKeys.updateUrl: 'https://example.com/download',
        },
        intValues: const <String, int>{
          FirebaseRemoteConfigKeys.latestVersionCode: 12,
          FirebaseRemoteConfigKeys.minSupportedVersionCode: 10,
        },
        boolValues: const <String, bool>{
          FirebaseRemoteConfigKeys.forceUpdate: true,
        },
      );
      final service = FirebaseRemoteAppConfigService(client: client);

      final config = await service.fetch();

      expect(client.didSetDefaults, isTrue);
      expect(client.didFetchAndActivate, isTrue);
      expect(config.enabledAdSlots.map((slot) => slot.placement), <String>[
        'settings_footer',
        'voice_service',
        'text_optimization_service',
      ]);
      expect(config.popupNotice.message, '新版本体验更顺滑');
      expect(config.updatePolicy.latestVersion, '1.2.0');
      expect(config.updatePolicy.minSupportedVersion, '1.1.0');
      expect(config.updatePolicy.latestVersionCode, 12);
      expect(config.updatePolicy.minSupportedVersionCode, 10);
      expect(config.updatePolicy.forceUpdate, isTrue);
      expect(config.updatePolicy.updateUrl, 'https://example.com/download');
    },
  );

  test(
    'firebase remote app config service disables config when fetch fails',
    () async {
      final service = FirebaseRemoteAppConfigService(
        client: FakeRemoteConfigClient(shouldThrowOnFetch: true),
      );

      final config = await service.fetch();

      expect(config.enabledAdSlots, isEmpty);
      expect(config.popupNotice.enabled, isFalse);
      expect(config.updatePolicy.latestVersionCode, 0);
    },
  );

  test(
    'fallback remote config service uses primary config when it succeeds',
    () async {
      final primary = FakeRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'settings_footer',
              title: '国内配置',
              enabled: true,
            ),
          ],
        ),
      );
      final fallback = FakeRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'settings_footer',
              title: 'Firebase 配置',
              enabled: true,
            ),
          ],
        ),
      );

      final config = await FallbackRemoteAppConfigService(
        primary: primary,
        fallback: fallback,
      ).fetch();

      expect(config.enabledAdSlots.single.title, '国内配置');
      expect(primary.fetchCount, 1);
      expect(fallback.fetchCount, 0);
    },
  );

  test(
    'fallback remote config service uses firebase fallback after primary failure',
    () async {
      final primary = FakeRemoteAppConfigService.throwing();
      final fallback = FakeRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'settings_footer',
              title: 'Firebase 配置',
              enabled: true,
            ),
          ],
        ),
      );

      final config = await FallbackRemoteAppConfigService(
        primary: primary,
        fallback: fallback,
      ).fetch();

      expect(config.enabledAdSlots.single.title, 'Firebase 配置');
      expect(primary.fetchCount, 1);
      expect(fallback.fetchCount, 1);
    },
  );

  test(
    'http remote config service parses domestic json config endpoint',
    () async {
      final service = HttpRemoteAppConfigService(
        configUrl: 'https://config.example.com/shenghui.json',
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://config.example.com/shenghui.json',
          );
          return http.Response(
            '''
          {
            "popup_notice": {
              "title": "国内公告",
              "message": "配置来自国内通道",
              "enabled": true
            },
            "ad_slots": [
              {
                "placement": "settings_footer",
                "title": "国内广告位",
                "enabled": true
              },
              {
                "placement": "voice_service",
                "title": "语音服务广告",
                "enabled": true
              },
              {
                "placement": "text_optimization_service",
                "title": "文本优化广告",
                "enabled": true
              }
            ],
            "latest_version": "1.0.1",
            "min_supported_version": "1.0.0",
            "latest_version_code": 3
          }
          ''',
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final config = await service.fetch();

      expect(config.popupNotice.title, '国内公告');
      expect(config.enabledAdSlots.map((slot) => slot.title), <String>[
        '国内广告位',
        '语音服务广告',
        '文本优化广告',
      ]);
      expect(config.updatePolicy.latestVersion, '1.0.1');
      expect(config.updatePolicy.minSupportedVersion, '1.0.0');
      expect(config.updatePolicy.latestVersionCode, 3);
    },
  );
}

class FakeRemoteAppConfigService implements RemoteAppConfigService {
  FakeRemoteAppConfigService(this.config) : error = null;

  FakeRemoteAppConfigService.throwing()
    : config = const RemoteAppConfig.disabled(),
      error = Exception('primary unavailable');

  final RemoteAppConfig config;
  final Object? error;
  int fetchCount = 0;

  @override
  Future<RemoteAppConfig> fetch() async {
    fetchCount += 1;
    final exception = error;
    if (exception != null) throw exception;
    return config;
  }
}

class FakeRemoteConfigClient implements RemoteConfigClient {
  FakeRemoteConfigClient({
    this.stringValues = const <String, String>{},
    this.intValues = const <String, int>{},
    this.boolValues = const <String, bool>{},
    this.shouldThrowOnFetch = false,
  });

  final Map<String, String> stringValues;
  final Map<String, int> intValues;
  final Map<String, bool> boolValues;
  final bool shouldThrowOnFetch;
  bool didSetDefaults = false;
  bool didFetchAndActivate = false;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {}

  @override
  Future<bool> fetchAndActivate() async {
    if (shouldThrowOnFetch) {
      throw Exception('offline');
    }
    didFetchAndActivate = true;
    return true;
  }

  @override
  bool getBool(String key) => boolValues[key] ?? false;

  @override
  int getInt(String key) => intValues[key] ?? 0;

  @override
  String getString(String key) => stringValues[key] ?? '';

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    didSetDefaults = true;
  }
}
