enum ServiceMode { backendProxy, directApiKey }

class ServiceConfig {
  const ServiceConfig({
    required this.mode,
    this.backendUrl,
    this.hasApiKey = false,
  });

  const ServiceConfig.backend()
      : mode = ServiceMode.backendProxy,
        backendUrl = '',
        hasApiKey = false;

  final ServiceMode mode;
  final String? backendUrl;
  final bool hasApiKey;
}
