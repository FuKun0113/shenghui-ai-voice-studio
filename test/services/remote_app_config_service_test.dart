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
              title: '兜底配置',
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
    'fallback remote config service uses static fallback after primary failure',
    () async {
      final primary = FakeRemoteAppConfigService.throwing();
      final fallback = FakeRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'settings_footer',
              title: '兜底配置',
              enabled: true,
            ),
          ],
        ),
      );

      final config = await FallbackRemoteAppConfigService(
        primary: primary,
        fallback: fallback,
      ).fetch();

      expect(config.enabledAdSlots.single.title, '兜底配置');
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
