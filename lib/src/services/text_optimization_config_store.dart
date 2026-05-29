import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/text_optimization_config.dart';

class LocalTextOptimizationConfigStore {
  LocalTextOptimizationConfigStore({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const String _apiKeyKey = 'text_optimization_api_key';
  static const String _apiUrlKey = 'text_optimization_api_url';
  static const String _modelKey = 'text_optimization_model';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _preferences;

  Future<TextOptimizationConfig> load() async {
    final apiUrl =
        await _preferences.getString(_apiUrlKey) ??
        TextOptimizationConfig.defaultApiUrl;
    final model = await _preferences.getString(_modelKey) ?? '';
    final apiKey = await _secureStorage.read(key: _apiKeyKey) ?? '';
    return TextOptimizationConfig(
      apiUrl: TextOptimizationConfig.normalizeBaseApiUrl(apiUrl),
      apiKey: apiKey,
      model: model,
    );
  }

  Future<void> save(TextOptimizationConfig config) async {
    await _preferences.setString(_apiUrlKey, config.normalizedApiUrl);
    await _preferences.setString(_modelKey, config.model);
    if (config.apiKey.trim().isEmpty) {
      await _secureStorage.delete(key: _apiKeyKey);
    } else {
      await _secureStorage.write(key: _apiKeyKey, value: config.apiKey.trim());
    }
  }
}
