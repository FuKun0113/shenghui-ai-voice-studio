import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/usage_analytics_service.dart';

void main() {
  test('http usage analytics posts one anonymous app open per day', () async {
    final requests = <Map<String, Object?>>[];
    final store = MemoryJsonStore();
    final service = HttpUsageAnalyticsService(
      endpoint: 'https://analytics.example.com/events',
      store: store,
      client: MockClient((request) async {
        requests.add(
          Map<String, Object?>.from(
            jsonDecode(request.body) as Map<String, Object?>,
          ),
        );
        return http.Response('', 204);
      }),
      now: () => DateTime.utc(2026, 5, 30, 10),
      idFactory: () => 'install-id-1',
    );

    await service.trackAppOpen(
      versionName: '1.0.0',
      buildNumber: '8',
      platform: 'android',
      channel: 'official',
    );
    await service.trackAppOpen(
      versionName: '1.0.0',
      buildNumber: '8',
      platform: 'android',
      channel: 'official',
    );

    expect(requests, hasLength(1));
    expect(requests.single['event'], 'app_open');
    expect(requests.single['install_id_hash'], isA<String>());
    expect(requests.single['install_id_hash'], isNot('install-id-1'));
    expect(requests.single['version'], '1.0.0');
    expect(requests.single['build_number'], '8');
    expect(requests.single['platform'], 'android');
    expect(requests.single['channel'], 'official');
  });

  test('http usage analytics does not throw when the endpoint fails', () async {
    final service = HttpUsageAnalyticsService(
      endpoint: 'https://analytics.example.com/events',
      store: MemoryJsonStore(),
      client: MockClient((request) async => http.Response('bad gateway', 502)),
      now: () => DateTime.utc(2026, 5, 30, 10),
      idFactory: () => 'install-id-2',
    );

    await service.trackAppOpen(
      versionName: '1.0.0',
      buildNumber: '8',
      platform: 'android',
      channel: 'official',
    );
  });
}
