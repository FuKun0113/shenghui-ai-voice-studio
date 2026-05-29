import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/service_config.dart';

class LocalServiceConfigStore {
  LocalServiceConfigStore({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const String _apiKeyKey = 'mimo_api_key';
  static const String _apiUrlKey = 'mimo_api_url';
  static const String _modeKey = 'mimo_service_mode';
  static const String _backendUrlKey = 'mimo_backend_url';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _preferences;

  Future<ServiceConfig> load() async {
    final modeName = await _preferences.getString(_modeKey);
    final apiUrl =
        await _preferences.getString(_apiUrlKey) ?? ServiceConfig.defaultApiUrl;
    final apiKey = await _secureStorage.read(key: _apiKeyKey) ?? '';
    final backendUrl = await _preferences.getString(_backendUrlKey);
    return ServiceConfig(
      mode: modeName == ServiceMode.backendProxy.name
          ? ServiceMode.backendProxy
          : ServiceMode.directApiKey,
      backendUrl: backendUrl,
      apiUrl: ServiceConfig.normalizeBaseApiUrl(apiUrl),
      apiKey: apiKey,
    );
  }

  Future<void> save(ServiceConfig config) async {
    await _preferences.setString(_modeKey, config.mode.name);
    await _preferences.setString(_apiUrlKey, config.normalizedApiUrl);
    if (config.backendUrl != null) {
      await _preferences.setString(_backendUrlKey, config.backendUrl!);
    } else {
      await _preferences.remove(_backendUrlKey);
    }
    if (config.apiKey.trim().isEmpty) {
      await _secureStorage.delete(key: _apiKeyKey);
    } else {
      await _secureStorage.write(key: _apiKeyKey, value: config.apiKey.trim());
    }
  }
}
