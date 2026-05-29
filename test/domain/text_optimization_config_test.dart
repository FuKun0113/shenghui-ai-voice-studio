import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/text_optimization_config.dart';

void main() {
  test('uses an OpenAI-compatible v1 base URL for settings display', () {
    const config = TextOptimizationConfig(
      apiUrl: 'https://api.example.com/v1/chat/completions',
      apiKey: 'key',
      model: 'general-model',
    );

    expect(TextOptimizationConfig.defaultApiUrl, 'https://api.openai.com/v1');
    expect(config.normalizedApiUrl, 'https://api.example.com/v1');
    expect(
      config.resolvedApiUrl,
      'https://api.example.com/v1/chat/completions',
    );
    expect(config.hasApiKey, isTrue);
  });

  test('normalizes OpenAI-compatible base URL', () {
    const config = TextOptimizationConfig(
      apiUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      model: 'general-model',
    );

    expect(
      config.resolvedApiUrl,
      'https://api.example.com/v1/chat/completions',
    );
  });

  test('derives OpenAI-compatible models URL from chat completions URL', () {
    const chatConfig = TextOptimizationConfig(
      apiUrl: 'https://api.example.com/v1/chat/completions',
    );
    const rootConfig = TextOptimizationConfig(
      apiUrl: 'https://api.example.com/v1',
    );

    expect(
      chatConfig.resolvedModelsApiUrl,
      'https://api.example.com/v1/models',
    );
    expect(
      rootConfig.resolvedModelsApiUrl,
      'https://api.example.com/v1/models',
    );
  });
}
