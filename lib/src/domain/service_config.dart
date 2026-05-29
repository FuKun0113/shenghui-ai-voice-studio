enum ServiceMode { backendProxy, directApiKey }

class ServiceConfig {
  const ServiceConfig({
    required this.mode,
    this.backendUrl,
    this.apiUrl = defaultApiUrl,
    this.apiKey = '',
  });

  const ServiceConfig.backend({this.backendUrl = ''})
    : mode = ServiceMode.backendProxy,
      apiUrl = defaultApiUrl,
      apiKey = '';

  const ServiceConfig.directApi({this.apiUrl = defaultApiUrl, this.apiKey = ''})
    : mode = ServiceMode.directApiKey,
      backendUrl = null;

  static const String defaultApiUrl = 'https://api.xiaomimimo.com/v1';

  final ServiceMode mode;
  final String? backendUrl;
  final String apiUrl;
  final String apiKey;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  static String normalizeBaseApiUrl(String value) {
    final fallback = value.trim().isEmpty ? defaultApiUrl : value.trim();
    final withoutTrailingSlash = fallback.endsWith('/')
        ? fallback.substring(0, fallback.length - 1)
        : fallback;
    return withoutTrailingSlash.replaceFirst(RegExp(r'/chat/completions$'), '');
  }

  String get normalizedApiUrl => normalizeBaseApiUrl(apiUrl);

  String get resolvedApiUrl => '$normalizedApiUrl/chat/completions';

  ServiceConfig normalized() {
    return copyWith(apiUrl: normalizedApiUrl);
  }

  ServiceConfig copyWith({
    ServiceMode? mode,
    String? backendUrl,
    String? apiUrl,
    String? apiKey,
  }) {
    return ServiceConfig(
      mode: mode ?? this.mode,
      backendUrl: backendUrl ?? this.backendUrl,
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
