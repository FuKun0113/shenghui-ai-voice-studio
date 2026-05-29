import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voice_clone_app/src/domain/text_optimization_config.dart';
import 'package:voice_clone_app/src/services/text_optimization_service.dart';

void main() {
  test('builds OpenAI-compatible request for tag enrichment', () async {
    Object? capturedBody;
    final service = OpenAiCompatibleTextOptimizationService(
      client: MockClient((request) async {
        capturedBody = jsonDecode(request.body);
        expect(request.headers['Authorization'], 'Bearer test-key');
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': '(沉稳)你好。[停顿]'},
              },
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );

    final result = await service.optimize(
      task: TextOptimizationTask.enrichTags,
      inputText: '你好。',
      stylePrompt: '沉稳一些',
      config: const TextOptimizationConfig(
        apiUrl: 'https://api.example.com/v1/chat/completions',
        apiKey: 'test-key',
        model: 'general-model',
      ),
    );

    expect(result, '(沉稳)你好。[停顿]');
    expect(capturedBody, isA<Map<String, Object?>>());
    expect((capturedBody as Map<String, Object?>)['model'], 'general-model');
    expect(
      ((capturedBody as Map<String, Object?>)['messages'] as List).last,
      containsPair('role', 'user'),
    );
    final messages = (capturedBody as Map<String, Object?>)['messages'] as List;
    expect(messages.first['content'], contains('只使用已支持的标签'));
    expect(messages.last['content'], contains('不要把标签插得过密'));
    expect(messages.last['content'], contains('可用风格标签'));
  });

  test(
    'write-instruct prompt constrains output to a usable direction',
    () async {
      Object? capturedBody;
      final service = OpenAiCompatibleTextOptimizationService(
        client: MockClient((request) async {
          capturedBody = jsonDecode(request.body);
          return http.Response(
            jsonEncode(<String, Object?>{
              'choices': <Object?>[
                <String, Object?>{
                  'message': <String, Object?>{'content': '语气沉稳，节奏缓慢。'},
                },
              ],
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      await service.optimize(
        task: TextOptimizationTask.writeInstruct,
        inputText: '老人讲述旧事。',
        stylePrompt: '',
        config: const TextOptimizationConfig(apiKey: 'test-key'),
      );

      final messages =
          (capturedBody as Map<String, Object?>)['messages'] as List;
      expect(messages.first['content'], contains('不要复述正文'));
      expect(messages.last['content'], contains('20-80 个中文字符'));
      expect(messages.last['content'], contains('只输出表演指令'));
    },
  );

  test('fetches and sorts OpenAI-compatible model ids', () async {
    Uri? capturedUrl;
    final service = OpenAiCompatibleTextOptimizationService(
      client: MockClient((request) async {
        capturedUrl = request.url;
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer test-key');
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <Object?>[
              <String, Object?>{'id': 'zeta-model'},
              <String, Object?>{'id': 'alpha-model'},
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );

    final models = await service.fetchModels(
      config: const TextOptimizationConfig(
        apiUrl: 'https://api.example.com/v1/chat/completions',
        apiKey: 'test-key',
      ),
    );

    expect(capturedUrl.toString(), 'https://api.example.com/v1/models');
    expect(models, <String>['alpha-model', 'zeta-model']);
  });
}
