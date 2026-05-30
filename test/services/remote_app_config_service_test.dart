import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';

void main() {
  test(
    'static product config service returns disabled config by default',
    () async {
      final service = StaticRemoteAppConfigService();

      final config = await service.fetch();

      expect(config.enabledAdSlots, isEmpty);
      expect(config.popupNotice.enabled, isFalse);
    },
  );

  test('fallback service uses primary config when it succeeds', () async {
    final primary = FakeRemoteAppConfigService(
      const RemoteAppConfig(
        popupNotice: RemotePopupNotice(title: '主配置', enabled: true),
      ),
    );
    final fallback = FakeRemoteAppConfigService(
      const RemoteAppConfig(
        popupNotice: RemotePopupNotice(title: '兜底配置', enabled: true),
      ),
    );

    final config = await FallbackRemoteAppConfigService(
      primary: primary,
      fallback: fallback,
    ).fetch();

    expect(config.popupNotice.title, '主配置');
    expect(primary.fetchCount, 1);
    expect(fallback.fetchCount, 0);
  });

  test('fallback service uses static fallback after primary failure', () async {
    final primary = FakeRemoteAppConfigService.throwing();
    final fallback = FakeRemoteAppConfigService(
      const RemoteAppConfig(
        popupNotice: RemotePopupNotice(title: '兜底配置', enabled: true),
      ),
    );

    final config = await FallbackRemoteAppConfigService(
      primary: primary,
      fallback: fallback,
    ).fetch();

    expect(config.popupNotice.title, '兜底配置');
    expect(primary.fetchCount, 1);
    expect(fallback.fetchCount, 1);
  });

  test('http product config service parses json config endpoint', () async {
    final service = HttpRemoteAppConfigService(
      configUrl: 'https://config.example.com/shenghui.json',
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://config.example.com/shenghui.json',
        );
        return http.Response.bytes(
          utf8.encode('''
          {
            "popup_notice": {
              "id": "notice-1",
              "title": "产品公告",
              "message": "配置来自 JSON",
              "enabled": true
            },
            "ad_slots": [
              {
                "placement": "settings_footer",
                "title": "底部入口",
                "enabled": true
              }
            ]
          }
          '''),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final config = await service.fetch();

    expect(config.popupNotice.title, '产品公告');
    expect(config.enabledAdSlots.single.title, '底部入口');
  });
}

class FakeRemoteAppConfigService implements RemoteAppConfigService {
  FakeRemoteAppConfigService(this.config) : error = null;

  FakeRemoteAppConfigService.throwing()
    : config = const RemoteAppConfig.disabled(),
      error = StateError('boom');

  final RemoteAppConfig config;
  final Object? error;
  int fetchCount = 0;

  @override
  Future<RemoteAppConfig> fetch() async {
    fetchCount += 1;
    final currentError = error;
    if (currentError != null) throw currentError;
    return config;
  }
}
