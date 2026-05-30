import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/remote_app_config.dart';

abstract class RemoteAppConfigService {
  Future<RemoteAppConfig> fetch();
}

class StaticRemoteAppConfigService implements RemoteAppConfigService {
  StaticRemoteAppConfigService([
    this.config = const RemoteAppConfig.disabled(),
  ]);

  final RemoteAppConfig config;

  @override
  Future<RemoteAppConfig> fetch() async => config;
}

class FallbackRemoteAppConfigService implements RemoteAppConfigService {
  const FallbackRemoteAppConfigService({
    required this.primary,
    required this.fallback,
  });

  final RemoteAppConfigService primary;
  final RemoteAppConfigService fallback;

  @override
  Future<RemoteAppConfig> fetch() async {
    try {
      return await primary.fetch();
    } on Object {
      return fallback.fetch();
    }
  }
}

class HttpRemoteAppConfigService implements RemoteAppConfigService {
  HttpRemoteAppConfigService({
    required this.configUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 4),
  }) : _client = client ?? http.Client();

  final String configUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<RemoteAppConfig> fetch() async {
    final uri = Uri.parse(configUrl);
    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Remote config http ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Remote config root must be a JSON object');
    }
    return RemoteAppConfig.fromJson(Map<String, Object?>.from(decoded));
  }
}
