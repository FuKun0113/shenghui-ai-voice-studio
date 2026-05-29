import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';
import '../domain/service_config.dart';
import '../domain/connection_test_result.dart';

abstract class MimoService {
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
    required ServiceConfig config,
  });

  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
    required ServiceConfig config,
  });

  Future<ConnectionTestResult> testConnection({required ServiceConfig config});
}

class MimoRequestBuilder {
  static Map<String, Object?> buildSpeechBody(
    GenerationRequest request, {
    String? referenceAudioDataUri,
    String format = 'wav',
  }) {
    final messages = <Map<String, String>>[
      if (_instructionFor(request).isNotEmpty)
        <String, String>{'role': 'user', 'content': _instructionFor(request)},
      <String, String>{'role': 'assistant', 'content': request.text},
    ];

    return switch (request.route) {
      GenerationRoute.builtinTts => <String, Object?>{
        'model': 'mimo-v2.5-tts',
        'messages': messages,
        'audio': <String, String>{
          'format': format,
          'voice': request.providerVoiceId ?? 'mimo_default',
        },
        'stream': false,
      },
      GenerationRoute.voiceClone => <String, Object?>{
        'model': 'mimo-v2.5-tts-voiceclone',
        'messages': messages,
        'audio': <String, String>{
          'format': format,
          'voice': referenceAudioDataUri ?? '',
        },
        'stream': false,
      },
    };
  }

  static Map<String, Object?> buildVoiceDesignBody({
    required String stylePrompt,
    required String sampleText,
    String format = 'wav',
  }) {
    return <String, Object?>{
      'model': 'mimo-v2.5-tts-voicedesign',
      'messages': <Map<String, String>>[
        <String, String>{'role': 'user', 'content': stylePrompt},
        <String, String>{'role': 'assistant', 'content': sampleText},
      ],
      'audio': <String, Object>{
        'format': format,
        'optimize_text_preview': true,
      },
      'stream': false,
    };
  }

  static String _instructionFor(GenerationRequest request) {
    final controlParts = <String>[];
    final emotion = request.emotion.trim();
    if (emotion.isNotEmpty && emotion != '自然') {
      controlParts.add('请以$emotion的情绪表达');
    }
    if (request.speed != 1.0) {
      controlParts.add('语速约 ${request.speed.toStringAsFixed(1)}x');
    } else if (emotion.isNotEmpty && emotion != '自然') {
      controlParts.add('语速约 ${request.speed.toStringAsFixed(1)}x');
    }
    final stylePrompt = request.stylePrompt.trim();
    if (controlParts.isEmpty) return stylePrompt;
    final control = '${controlParts.join('，')}。';
    if (stylePrompt.isEmpty) return control;
    return '$control$stylePrompt';
  }
}

class MimoResponseParser {
  static String extractAudioBase64(Map<String, Object?> response) {
    final choices = response['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('MiMo 响应中没有音频结果');
    }
    final first = choices.first;
    if (first is! Map) {
      throw StateError('MiMo 响应格式不正确');
    }
    final message = first['message'];
    if (message is! Map) {
      throw StateError('MiMo 响应中没有 message');
    }
    final audio = message['audio'];
    if (audio is! Map) {
      throw StateError('MiMo 响应中没有 audio');
    }
    final data = audio['data'];
    if (data is! String || data.isEmpty) {
      throw StateError('MiMo 响应中没有音频数据');
    }
    return data;
  }
}

class MimoAudioInspector {
  static int durationMsFromBytes(List<int> bytes) {
    if (bytes.length < 44) return 0;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    if (_ascii(bytes, 0, 4) != 'RIFF' || _ascii(bytes, 8, 12) != 'WAVE') {
      return 0;
    }

    var offset = 12;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = _ascii(bytes, offset, offset + 4);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      if (chunkDataOffset + chunkSize > bytes.length && chunkId != 'data') {
        break;
      }

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        channels = data.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = data.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = data.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
      }

      if (channels != null &&
          sampleRate != null &&
          bitsPerSample != null &&
          dataSize != null) {
        final bytesPerSecond = sampleRate * channels * bitsPerSample / 8;
        if (bytesPerSecond <= 0) return 0;
        return (dataSize / bytesPerSecond * 1000).round();
      }

      offset = chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }
    return 0;
  }

  static String _ascii(List<int> bytes, int start, int end) {
    if (end > bytes.length) return '';
    return String.fromCharCodes(bytes.sublist(start, end));
  }
}

class MimoApiService implements MimoService {
  MimoApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<ConnectionTestResult> testConnection({
    required ServiceConfig config,
  }) async {
    if (!config.hasApiKey) {
      return const ConnectionTestResult(
        status: ConnectionTestStatus.missingApiKey,
        message: '请先填写 MiMo API Key',
      );
    }
    final uri = Uri.tryParse(config.resolvedApiUrl);
    if (uri == null || !uri.hasScheme) {
      return const ConnectionTestResult(
        status: ConnectionTestStatus.invalidUrl,
        message: 'API URL 无效',
      );
    }
    try {
      final request = GenerationRequest(
        text: '连接测试',
        voiceId: 'mimo-default',
        voiceName: 'MiMo-默认',
        route: GenerationRoute.builtinTts,
        speed: 1.0,
        emotion: '自然',
        stylePrompt: '',
        providerVoiceId: 'mimo_default',
      );
      await _postForAudio(
        config: config,
        body: MimoRequestBuilder.buildSpeechBody(request),
      );
      return const ConnectionTestResult(
        status: ConnectionTestStatus.success,
        message: '连接成功，MiMo API 可用',
      );
    } on FormatException catch (error) {
      return ConnectionTestResult(
        status: ConnectionTestStatus.invalidResponse,
        message: '响应格式异常：$error',
      );
    } on StateError catch (error) {
      final message = error.message;
      final statusMatch = RegExp(r'失败：(\d+)').firstMatch(message);
      return ConnectionTestResult(
        status: statusMatch == null
            ? ConnectionTestStatus.invalidResponse
            : ConnectionTestStatus.httpError,
        statusCode: int.tryParse(statusMatch?.group(1) ?? ''),
        message: message,
      );
    } on SocketException catch (error) {
      return ConnectionTestResult(
        status: ConnectionTestStatus.networkError,
        message: '网络连接失败：${error.message}',
      );
    } on Object catch (error) {
      return ConnectionTestResult(
        status: ConnectionTestStatus.networkError,
        message: '连接测试失败：$error',
      );
    }
  }

  @override
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
    required ServiceConfig config,
  }) async {
    final body = MimoRequestBuilder.buildVoiceDesignBody(
      stylePrompt: stylePrompt,
      sampleText: sampleText,
    );
    final bytes = await _postForAudio(config: config, body: body);
    return _writeAudio(bytes, prefix: 'designed-voice');
  }

  @override
  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
    required ServiceConfig config,
  }) async {
    final referenceAudioDataUri = request.route == GenerationRoute.voiceClone
        ? await _readReferenceAudioDataUri(request.referenceAudioPath)
        : null;
    final body = MimoRequestBuilder.buildSpeechBody(
      request,
      referenceAudioDataUri: referenceAudioDataUri,
    );
    final bytes = await _postForAudio(config: config, body: body);
    final audioPath = await _writeAudio(bytes, prefix: 'generated');
    final durationMs = MimoAudioInspector.durationMsFromBytes(bytes);
    return GeneratedAudio(
      id: 'audio-${DateTime.now().microsecondsSinceEpoch}',
      text: request.text,
      voiceId: request.voiceId,
      voiceName: request.voiceName,
      audioPath: audioPath,
      durationMs: durationMs,
      createdAt: DateTime.now(),
    );
  }

  Future<List<int>> _postForAudio({
    required ServiceConfig config,
    required Map<String, Object?> body,
  }) async {
    if (!config.hasApiKey) {
      throw StateError('请先在设置里填写 MiMo API Key');
    }
    final response = await _client.post(
      Uri.parse(config.resolvedApiUrl),
      headers: <String, String>{
        'api-key': config.apiKey.trim(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('MiMo API 调用失败：${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw StateError('MiMo API 返回格式不正确');
    }
    return base64Decode(MimoResponseParser.extractAudioBase64(decoded));
  }

  Future<String?> _readReferenceAudioDataUri(String? path) async {
    if (path == null || path.trim().isEmpty) {
      throw StateError('缺少参考音频');
    }
    final file = File(path);
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    if (encoded.length > 10 * 1024 * 1024) {
      throw StateError('参考音频超过 MiMo 10 MB Base64 限制');
    }
    return 'data:${_mimeTypeFor(path)};base64,$encoded';
  }

  String _mimeTypeFor(String path) {
    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.mp3' => 'audio/mpeg',
      '.wav' => 'audio/wav',
      _ => throw StateError('MiMo 声音克隆仅支持 mp3 或 wav 参考音频'),
    };
  }

  Future<String> _writeAudio(List<int> bytes, {required String prefix}) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        directory.path,
        '$prefix-${DateTime.now().microsecondsSinceEpoch}.wav',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
