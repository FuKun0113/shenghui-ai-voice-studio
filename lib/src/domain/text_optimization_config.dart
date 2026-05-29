class TextOptimizationConfig {
  const TextOptimizationConfig({
    this.apiUrl = defaultApiUrl,
    this.apiKey = '',
    this.model = '',
  });

  static const String defaultApiUrl = 'https://api.openai.com/v1';

  final String apiUrl;
  final String apiKey;
  final String model;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  static String normalizeBaseApiUrl(String value) {
    final fallback = value.trim().isEmpty ? defaultApiUrl : value.trim();
    final withoutTrailingSlash = fallback.endsWith('/')
        ? fallback.substring(0, fallback.length - 1)
        : fallback;
    return withoutTrailingSlash
        .replaceFirst(RegExp(r'/chat/completions$'), '')
        .replaceFirst(RegExp(r'/models$'), '');
  }

  String get normalizedApiUrl => normalizeBaseApiUrl(apiUrl);

  String get resolvedApiUrl => '$normalizedApiUrl/chat/completions';

  String get resolvedModelsApiUrl => '$normalizedApiUrl/models';

  String get resolvedModel {
    final value = model.trim();
    return value.isEmpty ? 'gpt-4o-mini' : value;
  }

  TextOptimizationConfig copyWith({
    String? apiUrl,
    String? apiKey,
    String? model,
  }) {
    return TextOptimizationConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}
