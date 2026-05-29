import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/connection_test_result.dart';
import 'package:voice_clone_app/src/domain/generation_request.dart';
import 'package:voice_clone_app/src/domain/service_config.dart';
import 'package:voice_clone_app/src/domain/voice.dart';
import 'package:voice_clone_app/src/services/mimo_client.dart';

void main() {
  test('builtin request follows MiMo OpenAI-compatible TTS schema', () {
    final voice = Voice.builtin(
      id: 'mimo-chloe',
      name: 'Chloe',
      providerVoiceId: 'Chloe',
    );
    final request = GenerationRequest.fromVoice(
      text: '你好，欢迎使用 AI 语音工作台。',
      voice: voice,
      speed: 1.0,
      emotion: '开心',
      stylePrompt: '用轻快上扬的语调，语速稍快。',
    );

    final body = MimoRequestBuilder.buildSpeechBody(request);

    expect(body['model'], 'mimo-v2.5-tts');
    expect(body['stream'], isFalse);
    expect(body['messages'], <Map<String, String>>[
      <String, String>{
        'role': 'user',
        'content': '请以开心的情绪表达，语速约 1.0x。用轻快上扬的语调，语速稍快。',
      },
      <String, String>{'role': 'assistant', 'content': '你好，欢迎使用 AI 语音工作台。'},
    ]);
    expect(body['audio'], <String, String>{'format': 'wav', 'voice': 'Chloe'});
  });

  test('voice clone request sends audio data uri as voice parameter', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );
    final request = GenerationRequest.fromVoice(
      text: '你好',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    final body = MimoRequestBuilder.buildSpeechBody(
      request,
      referenceAudioDataUri: 'data:audio/wav;base64,AAAA',
    );

    expect(body['model'], 'mimo-v2.5-tts-voiceclone');
    expect(body['messages'], <Map<String, String>>[
      <String, String>{'role': 'assistant', 'content': '你好'},
    ]);
    expect(body['audio'], <String, String>{
      'format': 'wav',
      'voice': 'data:audio/wav;base64,AAAA',
    });
  });

  test('voice design request uses description as user message', () {
    final body = MimoRequestBuilder.buildVoiceDesignBody(
      stylePrompt: '年轻女性，温柔、清晰，适合旁白。',
      sampleText: '你好，这是一段用于固定 AI 设计音色的标准试听文本。',
    );

    expect(body['model'], 'mimo-v2.5-tts-voicedesign');
    expect(body['messages'], <Map<String, String>>[
      <String, String>{'role': 'user', 'content': '年轻女性，温柔、清晰，适合旁白。'},
      <String, String>{
        'role': 'assistant',
        'content': '你好，这是一段用于固定 AI 设计音色的标准试听文本。',
      },
    ]);
    expect(body['audio'], <String, Object>{
      'format': 'wav',
      'optimize_text_preview': true,
    });
  });

  test('extracts base64 audio from non-streaming response', () {
    final data = MimoResponseParser.extractAudioBase64(<String, Object?>{
      'choices': <Object?>[
        <String, Object?>{
          'message': <String, Object?>{
            'audio': <String, Object?>{'data': 'UklGRg=='},
          },
        },
      ],
    });

    expect(data, 'UklGRg==');
  });

  test('estimates duration from MiMo wav response bytes', () {
    final bytes = _wavBytes(
      sampleRate: 16000,
      channels: 1,
      bitsPerSample: 16,
      durationMs: 1250,
    );

    expect(MimoAudioInspector.durationMsFromBytes(bytes), 1250);
  });

  test('connection test reports missing api key', () async {
    final service = MimoApiService();
    final result = await service.testConnection(
      config: const ServiceConfig.directApi(),
    );

    expect(result.status, ConnectionTestStatus.missingApiKey);
  });
}

Uint8List _wavBytes({
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
  required int durationMs,
}) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final dataSize = sampleRate * channels * bytesPerSample * durationMs ~/ 1000;
  final bytes = Uint8List(44 + dataSize);
  final data = ByteData.view(bytes.buffer);

  void writeAscii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes[offset + i] = value.codeUnitAt(i);
    }
  }

  writeAscii(0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  data.setUint16(32, channels * bytesPerSample, Endian.little);
  data.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  data.setUint32(40, dataSize, Endian.little);
  return bytes;
}
