import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  test(
    'firebase remote app config service maps remote config values into app config',
    () async {
      final client = FakeRemoteConfigClient(
        stringValues: const <String, String>{
          FirebaseRemoteConfigKeys.adSlots:
              '[{"placement":"settings_footer","title":"服务推荐","message":"领取额度","target_url":"https://example.com/promo","enabled":true}]',
          FirebaseRemoteConfigKeys.popupNotice:
              '{"title":"版本提醒","message":"新版本体验更顺滑","target_url":"https://example.com/update","enabled":true}',
          FirebaseRemoteConfigKeys.promoLink: 'https://example.com/register',
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
      expect(config.enabledAdSlots.single.title, '服务推荐');
      expect(config.popupNotice.message, '新版本体验更顺滑');
      expect(config.promoLink, 'https://example.com/register');
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
        const RemoteAppConfig(promoLink: 'https://cn.example.com/promo'),
      );
      final fallback = FakeRemoteAppConfigService(
        const RemoteAppConfig(promoLink: 'https://firebase.example.com/promo'),
      );

      final config = await FallbackRemoteAppConfigService(
        primary: primary,
        fallback: fallback,
      ).fetch();

      expect(config.promoLink, 'https://cn.example.com/promo');
      expect(primary.fetchCount, 1);
      expect(fallback.fetchCount, 0);
    },
  );

  test(
    'fallback remote config service uses firebase fallback after primary failure',
    () async {
      final primary = FakeRemoteAppConfigService.throwing();
      final fallback = FakeRemoteAppConfigService(
        const RemoteAppConfig(promoLink: 'https://firebase.example.com/promo'),
      );

      final config = await FallbackRemoteAppConfigService(
        primary: primary,
        fallback: fallback,
      ).fetch();

      expect(config.promoLink, 'https://firebase.example.com/promo');
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
            "promo_link": "https://cn.example.com/register",
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
              }
            ],
            "latest_version_code": 3
          }
          ''',
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final config = await service.fetch();

      expect(config.promoLink, 'https://cn.example.com/register');
      expect(config.popupNotice.title, '国内公告');
      expect(config.enabledAdSlots.single.title, '国内广告位');
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
