enum ConnectionTestStatus {
  success,
  missingApiKey,
  invalidUrl,
  networkError,
  httpError,
  invalidResponse,
}

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.status,
    required this.message,
    this.statusCode,
  });

  final ConnectionTestStatus status;
  final String message;
  final int? statusCode;

  bool get isSuccess => status == ConnectionTestStatus.success;
}
