import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/service_config.dart';

void main() {
  test('uses a v1 base URL for voice service settings display', () {
    const config = ServiceConfig.directApi(
      apiUrl: 'https://api.xiaomimimo.com/v1/chat/completions',
      apiKey: 'key',
    );

    expect(ServiceConfig.defaultApiUrl, 'https://api.xiaomimimo.com/v1');
    expect(config.normalizedApiUrl, 'https://api.xiaomimimo.com/v1');
    expect(
      config.resolvedApiUrl,
      'https://api.xiaomimimo.com/v1/chat/completions',
    );
  });

  test('keeps backend proxy URL independent from direct API base URL', () {
    const config = ServiceConfig.backend(
      backendUrl: 'https://voice.example.com/proxy',
    );

    expect(config.mode, ServiceMode.backendProxy);
    expect(config.backendUrl, 'https://voice.example.com/proxy');
    expect(config.normalizedApiUrl, 'https://api.xiaomimimo.com/v1');
  });
}
