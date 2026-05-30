import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/text_optimization_config.dart';

enum TextOptimizationTask { writeInstruct, polishText, enrichTags }

abstract interface class TextOptimizationService {
  Future<String> optimize({
    required TextOptimizationTask task,
    required String inputText,
    required String stylePrompt,
    required TextOptimizationConfig config,
  });

  Future<List<String>> fetchModels({required TextOptimizationConfig config});
}

class OpenAiCompatibleTextOptimizationService
    implements TextOptimizationService {
  OpenAiCompatibleTextOptimizationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<String>> fetchModels({
    required TextOptimizationConfig config,
  }) async {
    if (!config.hasApiKey) {
      throw StateError('请先填写文本优化服务密钥');
    }
    final response = await _client.get(
      Uri.parse(config.resolvedModelsApiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer ${config.apiKey.trim()}',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('模型列表获取失败：${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw StateError('模型列表返回格式不正确');
    }
    final data = decoded['data'];
    if (data is! List) {
      throw StateError('模型列表返回格式不正确');
    }
    final models =
        data
            .whereType<Map>()
            .map((item) => item['id'])
            .whereType<String>()
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (models.isEmpty) {
      throw StateError('没有获取到可用模型');
    }
    return models;
  }

  @override
  Future<String> optimize({
    required TextOptimizationTask task,
    required String inputText,
    required String stylePrompt,
    required TextOptimizationConfig config,
  }) async {
    if (!config.hasApiKey) {
      throw StateError('请先在设置里填写文本优化服务密钥');
    }
    final response = await _client.post(
      Uri.parse(config.resolvedApiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer ${config.apiKey.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_buildBody(task, inputText, stylePrompt, config)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('文本优化服务调用失败：${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw StateError('文本优化服务返回格式不正确');
    }
    return _extractContent(decoded).trim();
  }

  Map<String, Object?> _buildBody(
    TextOptimizationTask task,
    String inputText,
    String stylePrompt,
    TextOptimizationConfig config,
  ) {
    return <String, Object?>{
      'model': config.resolvedModel,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': _systemPrompt(task)},
        <String, String>{
          'role': 'user',
          'content': _userPrompt(task, inputText, stylePrompt),
        },
      ],
      'temperature': _temperatureFor(task),
    };
  }

  String _systemPrompt(TextOptimizationTask task) {
    return switch (task) {
      TextOptimizationTask.writeInstruct =>
        '你是中文语音合成导演。根据正文判断人物、场景、情绪、节奏和咬字方式，'
            '只输出一段可直接放入 Instruct 的表演指令；不要复述正文，不要解释，不要加标题。',
      TextOptimizationTask.polishText =>
        '你是中文语音脚本编辑。把输入整理成适合 TTS 朗读的正文；'
            '保留原意和事实，不添加新情节，不解释修改过程。',
      TextOptimizationTask.enrichTags =>
        '你是语音合成标签编排助手。只使用已支持的标签增强朗读效果，'
            '输出可直接合成的正文，不要解释，不要列清单。',
    };
  }

  double _temperatureFor(TextOptimizationTask task) {
    return switch (task) {
      TextOptimizationTask.writeInstruct => 0.55,
      TextOptimizationTask.polishText => 0.35,
      TextOptimizationTask.enrichTags => 0.45,
    };
  }

  String _userPrompt(
    TextOptimizationTask task,
    String inputText,
    String stylePrompt,
  ) {
    return switch (task) {
      TextOptimizationTask.writeInstruct =>
        '请根据下面的语音正文生成一段表演指令。\n'
            '要求：\n'
            '1. 只输出表演指令，20-80 个中文字符。\n'
            '2. 描述语气、情绪强度、语速节奏、停顿、角色感和咬字方式。\n'
            '3. 不要复述正文，不要写“请朗读”，不要加入风格标签或音频标签。\n'
            '4. 如果正文是故事/角色对白，要明确旁白感、人物状态或场景氛围。\n\n'
            '正文：\n$inputText',
      TextOptimizationTask.polishText =>
        '请优化下面的语音合成正文，让它更适合朗读。\n'
            '要求：\n'
            '1. 保留原意、人名、数字、称谓和事实，不新增剧情。\n'
            '2. 修正不自然标点，拆分过长句，加入自然停顿，但不要堆砌省略号。\n'
            '3. 保留原有风格标签和音频标签的位置；不要主动新增标签。\n'
            '4. 只输出优化后的正文。\n\n'
            '表演指令：$stylePrompt\n\n正文：\n$inputText',
      TextOptimizationTask.enrichTags =>
        '请给下面正文适度加入语音合成标签。\n'
            '规则：\n'
            '1. 风格标签使用中文圆括号，通常放在段落开头，例如（沉稳）。\n'
            '2. 音频标签使用方括号，插入到具体语气变化处，例如[停顿]、[轻笑]。\n'
            '3. 不要把标签插得过密，平均 1-3 句最多插入 1 个标签；原文很短时只加 1 个。\n'
            '4. 只使用已支持的标签；如果不确定，优先选择“平静、温柔、严肃、无奈、深沉、停顿、轻笑、叹气、低声”。\n'
            '5. 不改变正文含义，不输出解释。\n\n'
            '可用风格标签：开心、悲伤、愤怒、恐惧、惊讶、兴奋、委屈、平静、冷漠、怅然、欣慰、无奈、愧疚、释然、温柔、严肃、慵懒、深沉、磁性、苍老、沙哑、唱歌。\n'
            '可用音频标签：笑、轻笑、大笑、抽泣、哽咽、吸气、深呼吸、叹气、停顿、咳嗽、紧张、疲惫、颤抖、低声、呼喊。\n\n'
            '表演指令：$stylePrompt\n\n正文：\n$inputText',
    };
  }

  String _extractContent(Map<String, Object?> response) {
    final choices = response['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('文本优化服务没有返回结果');
    }
    final first = choices.first;
    if (first is! Map) throw StateError('文本优化服务返回格式不正确');
    final message = first['message'];
    if (message is! Map) throw StateError('文本优化服务没有返回 message');
    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw StateError('文本优化服务没有返回文本');
    }
    return content;
  }
}

class MockTextOptimizationService implements TextOptimizationService {
  @override
  Future<List<String>> fetchModels({
    required TextOptimizationConfig config,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return const <String>['gpt-4o-mini', 'gpt-4o', 'compatible-text-model'];
  }

  @override
  Future<String> optimize({
    required TextOptimizationTask task,
    required String inputText,
    required String stylePrompt,
    required TextOptimizationConfig config,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return switch (task) {
      TextOptimizationTask.writeInstruct => '声音自然清晰，语气亲切，节奏舒缓，重点词略微停顿。',
      TextOptimizationTask.polishText => '$inputText\n\n请以更自然的节奏朗读。',
      TextOptimizationTask.enrichTags => '(自然)$inputText[停顿]',
    };
  }
}
