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

  static const String defaultApiUrl =
      'https://api.xiaomimimo.com/v1/chat/completions';

  final ServiceMode mode;
  final String? backendUrl;
  final String apiUrl;
  final String apiKey;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  String get resolvedApiUrl {
    final value = apiUrl.trim();
    if (value.isEmpty) return defaultApiUrl;
    final normalized = value.endsWith('/')
        ? value.substring(0, value.length - 1)
        : value;
    if (normalized.endsWith('/chat/completions')) return normalized;
    if (normalized.endsWith('/v1')) return '$normalized/chat/completions';
    return normalized;
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
