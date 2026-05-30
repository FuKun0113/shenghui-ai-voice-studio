import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'local_json_store.dart';

abstract class UsageAnalyticsService {
  Future<void> trackAppOpen({
    required String versionName,
    required String buildNumber,
    required String platform,
    required String channel,
  });
}

class NoopUsageAnalyticsService implements UsageAnalyticsService {
  const NoopUsageAnalyticsService();

  @override
  Future<void> trackAppOpen({
    required String versionName,
    required String buildNumber,
    required String platform,
    required String channel,
  }) async {}
}

class HttpUsageAnalyticsService implements UsageAnalyticsService {
  HttpUsageAnalyticsService({
    required this.endpoint,
    LocalJsonStore? store,
    http.Client? client,
    DateTime Function()? now,
    String Function()? idFactory,
    this.timeout = const Duration(seconds: 4),
  }) : _store = store ?? SharedPreferencesJsonStore(),
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4;

  static const String _installIdKey = 'shenghui_usage_install_id';
  static const String _lastAppOpenDayKey = 'shenghui_usage_last_app_open_day';

  final String endpoint;
  final LocalJsonStore _store;
  final http.Client _client;
  final DateTime Function() _now;
  final String Function() _idFactory;
  final Duration timeout;

  @override
  Future<void> trackAppOpen({
    required String versionName,
    required String buildNumber,
    required String platform,
    required String channel,
  }) async {
    try {
      final day = _dayKey(_now().toUtc());
      if (await _store.getString(_lastAppOpenDayKey) == day) return;
      final installId = await _loadInstallId();
      final uri = Uri.parse(endpoint);
      final response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(<String, Object?>{
              'event': 'app_open',
              'install_id_hash': _hashInstallId(installId),
              'version': versionName,
              'build_number': buildNumber,
              'platform': platform,
              'channel': channel,
              'day': day,
            }),
          )
          .timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _store.setString(_lastAppOpenDayKey, day);
      }
    } on Object {
      // Usage analytics must never affect app startup or user workflows.
    }
  }

  Future<String> _loadInstallId() async {
    final existing = await _store.getString(_installIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final created = _idFactory();
    await _store.setString(_installIdKey, created);
    return created;
  }

  static String _hashInstallId(String installId) {
    return sha256.convert(utf8.encode(installId)).toString();
  }

  static String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
