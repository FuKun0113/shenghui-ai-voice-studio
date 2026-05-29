import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
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

abstract class RemoteConfigClient {
  Future<void> setDefaults(Map<String, Object> defaults);

  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });

  Future<bool> fetchAndActivate();

  String getString(String key);

  int getInt(String key);

  bool getBool(String key);
}

class FirebaseRemoteConfigClient implements RemoteConfigClient {
  FirebaseRemoteConfigClient([FirebaseRemoteConfig? remoteConfig])
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> setDefaults(Map<String, Object> defaults) {
    return _remoteConfig.setDefaults(defaults);
  }

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) {
    return _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
  }

  @override
  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();

  @override
  bool getBool(String key) => _remoteConfig.getBool(key);

  @override
  int getInt(String key) => _remoteConfig.getInt(key);

  @override
  String getString(String key) => _remoteConfig.getString(key);
}

class FirebaseRemoteAppConfigService implements RemoteAppConfigService {
  FirebaseRemoteAppConfigService({
    RemoteConfigClient? client,
    this.fetchTimeout = const Duration(seconds: 8),
    this.minimumFetchInterval = const Duration(hours: 1),
  }) : _client = client ?? FirebaseRemoteConfigClient();

  final RemoteConfigClient _client;
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;

  static const Map<String, Object> defaults = <String, Object>{
    FirebaseRemoteConfigKeys.adSlots: '[]',
    FirebaseRemoteConfigKeys.popupNotice: '{"enabled":false}',
    FirebaseRemoteConfigKeys.promoLink: '',
    FirebaseRemoteConfigKeys.latestVersionCode: 0,
    FirebaseRemoteConfigKeys.minSupportedVersionCode: 0,
    FirebaseRemoteConfigKeys.forceUpdate: false,
    FirebaseRemoteConfigKeys.updateUrl: '',
  };

  @override
  Future<RemoteAppConfig> fetch() async {
    try {
      await _client.setDefaults(defaults);
      await _client.configure(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      );
      await _client.fetchAndActivate();
      return RemoteAppConfig.fromJson(<String, Object?>{
        FirebaseRemoteConfigKeys.adSlots: _decodeList(
          _client.getString(FirebaseRemoteConfigKeys.adSlots),
        ),
        FirebaseRemoteConfigKeys.popupNotice: _decodeMap(
          _client.getString(FirebaseRemoteConfigKeys.popupNotice),
        ),
        FirebaseRemoteConfigKeys.promoLink: _client.getString(
          FirebaseRemoteConfigKeys.promoLink,
        ),
        FirebaseRemoteConfigKeys.latestVersionCode: _client.getInt(
          FirebaseRemoteConfigKeys.latestVersionCode,
        ),
        FirebaseRemoteConfigKeys.minSupportedVersionCode: _client.getInt(
          FirebaseRemoteConfigKeys.minSupportedVersionCode,
        ),
        FirebaseRemoteConfigKeys.forceUpdate: _client.getBool(
          FirebaseRemoteConfigKeys.forceUpdate,
        ),
        FirebaseRemoteConfigKeys.updateUrl: _client.getString(
          FirebaseRemoteConfigKeys.updateUrl,
        ),
      });
    } on Object {
      return const RemoteAppConfig.disabled();
    }
  }

  static List<Object?> _decodeList(String value) {
    final decoded = _decodeJson(value);
    return decoded is List ? decoded : const <Object?>[];
  }

  static Map<String, Object?> _decodeMap(String value) {
    final decoded = _decodeJson(value);
    return decoded is Map
        ? Map<String, Object?>.from(decoded)
        : const <String, Object?>{};
  }

  static Object? _decodeJson(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }
}

class FirebaseRemoteConfigKeys {
  const FirebaseRemoteConfigKeys._();

  static const String adSlots = 'ad_slots';
  static const String popupNotice = 'popup_notice';
  static const String promoLink = 'promo_link';
  static const String latestVersionCode = 'latest_version_code';
  static const String minSupportedVersionCode = 'min_supported_version_code';
  static const String forceUpdate = 'force_update';
  static const String updateUrl = 'update_url';

  static const List<String> all = <String>[
    adSlots,
    popupNotice,
    promoLink,
    latestVersionCode,
    minSupportedVersionCode,
    forceUpdate,
    updateUrl,
  ];
}
