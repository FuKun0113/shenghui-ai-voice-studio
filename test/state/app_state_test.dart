import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/generation_request.dart';
import 'package:shenghui_ai_voice_studio/src/domain/draft_state.dart';
import 'package:shenghui_ai_voice_studio/src/domain/generated_audio.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/domain/service_config.dart';
import 'package:shenghui_ai_voice_studio/src/domain/voice.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_draft_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_history_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_voice_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts with builtin voices and selects the first one', () {
    final state = AppState(mimoService: MockMimoService());

    expect(
      state.voices.where((voice) => voice.type == VoiceType.builtin),
      isNotEmpty,
    );
    expect(state.selectedVoice, isNotNull);
  });

  test('loads all MiMo V2.5 built-in voices with tags', () {
    final state = AppState(mimoService: MockMimoService());
    final builtinVoices = state.voices
        .where((voice) => voice.type == VoiceType.builtin)
        .toList();

    expect(builtinVoices, hasLength(9));
    expect(
      builtinVoices.map((voice) => voice.providerVoiceId),
      containsAll(<String>[
        'mimo_default',
        '冰糖',
        '茉莉',
        '苏打',
        '白桦',
        'Mia',
        'Chloe',
        'Milo',
        'Dean',
      ]),
    );
    expect(builtinVoices.first.tags, isNotEmpty);
    expect(
      builtinVoices.every(
        (voice) =>
            voice.previewAudioPath?.startsWith('assets/audio/previews/') ??
            false,
      ),
      isTrue,
    );
    for (final voice in builtinVoices) {
      expect(File(voice.previewAudioPath!).existsSync(), isTrue);
    }
  });

  test('updates direct MiMo API configuration', () {
    final state = AppState(mimoService: MockMimoService());

    state.updateServiceConfig(
      const ServiceConfig.directApi(
        apiUrl: 'https://api.xiaomimimo.com/v1/chat/completions',
        apiKey: 'test-key',
      ),
    );

    expect(state.serviceConfig.mode, ServiceMode.directApiKey);
    expect(state.serviceConfig.apiUrl, 'https://api.xiaomimimo.com/v1');
    expect(
      state.serviceConfig.resolvedApiUrl,
      'https://api.xiaomimimo.com/v1/chat/completions',
    );
    expect(state.serviceConfig.hasApiKey, isTrue);
  });

  test('can start with a saved MiMo API configuration', () {
    final state = AppState(
      mimoService: MockMimoService(),
      serviceConfig: const ServiceConfig.directApi(
        apiUrl: 'https://api.example.com/v1/chat/completions',
        apiKey: 'saved-key',
      ),
    );

    expect(state.serviceConfig.apiUrl, 'https://api.example.com/v1');
    expect(
      state.serviceConfig.resolvedApiUrl,
      'https://api.example.com/v1/chat/completions',
    );
    expect(state.serviceConfig.apiKey, 'saved-key');
  });

  test('loads remote app config from injected service', () async {
    const remoteConfig = RemoteAppConfig(
      popupNotice: RemotePopupNotice(
        title: '欢迎',
        message: '查看最新公告',
        enabled: true,
      ),
    );
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(remoteConfig),
    );

    expect(state.remoteAppConfig.popupNotice.enabled, isFalse);

    await state.loadRemoteAppConfig();

    expect(state.remoteAppConfig.popupNotice.title, '欢迎');
  });

  test(
    'saving a designed voice stores reference audio and routes through clone',
    () async {
      final state = AppState(mimoService: MockMimoService());

      final voice = await state.designVoice(
        name: '温柔旁白',
        stylePrompt: '年轻女性，温柔，清晰',
        gender: '女声',
      );

      expect(voice.type, VoiceType.designed);
      expect(voice.referenceAudioPath, contains('designed-voice'));
      expect(voice.gender, '女声');
      expect(voice.tags, contains('女声'));
      expect(state.voices.any((item) => item.id == voice.id), isTrue);
    },
  );

  test('saving a cloned voice stores gender label as a tag', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'voice-gender-test-',
    );
    addTearDown(() => tempRoot.delete(recursive: true));
    final documentsDir = Directory('${tempRoot.path}/documents')
      ..createSync(recursive: true);
    await _mockPathProviderDocumentsDirectory(documentsDir.path);
    addTearDown(_clearPathProviderMock);
    final reference = File('${tempRoot.path}/reference.wav')
      ..writeAsBytesSync(_tinyWavBytes());
    final state = AppState(mimoService: MockMimoService());

    final voice = await state.saveClonedVoice(
      name: '低沉男声',
      referenceAudioPath: reference.path,
      gender: '男声',
    );

    expect(voice.type, VoiceType.cloned);
    expect(voice.gender, '男声');
    expect(voice.tags, contains('男声'));
  });

  test(
    'saving a cloned voice copies reference audio into app storage',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'voice-reference-test-',
      );
      addTearDown(() => tempRoot.delete(recursive: true));
      final documentsDir = Directory('${tempRoot.path}/documents')
        ..createSync(recursive: true);
      await _mockPathProviderDocumentsDirectory(documentsDir.path);
      addTearDown(_clearPathProviderMock);

      final original = File('${tempRoot.path}/external-reference.wav')
        ..writeAsBytesSync(_tinyWavBytes());
      final service = _ReferenceCheckingMimoService();
      final state = AppState(mimoService: service);

      final voice = await state.saveClonedVoice(
        name: '本地托管音色',
        referenceAudioPath: original.path,
        gender: '男声',
      );

      expect(voice.referenceAudioPath, isNot(original.path));
      expect(voice.referenceAudioPath, contains('reference-audio'));
      expect(File(voice.referenceAudioPath!).existsSync(), isTrue);
      expect(
        File(voice.referenceAudioPath!).readAsBytesSync(),
        original.readAsBytesSync(),
      );
      expect(voice.previewAudioPath, isNot(voice.referenceAudioPath));
      expect(service.previewTexts, <String>['你好，欢迎使用声绘。这是一段用于比较音色的标准试听文本。']);

      await original.delete();
      state.selectVoice(voice.id);
      state.updateDraftText('原始文件删除后仍然可以生成。');

      final generated = await state.generateCurrentVoice();

      expect(generated.voiceId, voice.id);
    },
  );

  test('cloned voice preview is generated before saving and reused', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'voice-preview-test-',
    );
    addTearDown(() => tempRoot.delete(recursive: true));
    final documentsDir = Directory('${tempRoot.path}/documents')
      ..createSync(recursive: true);
    await _mockPathProviderDocumentsDirectory(documentsDir.path);
    addTearDown(_clearPathProviderMock);

    final original = File('${tempRoot.path}/external-reference.wav')
      ..writeAsBytesSync(_tinyWavBytes());
    final service = _ReferenceCheckingMimoService();
    final state = AppState(mimoService: service);

    final preview = await state.previewClonedVoice(
      name: '预览音色',
      referenceAudioPath: original.path,
      gender: '女声',
    );

    expect(preview.referenceAudioPath, contains('reference-audio'));
    expect(File(preview.referenceAudioPath).existsSync(), isTrue);
    expect(preview.previewAudioPath, isNotEmpty);

    await original.delete();
    final voice = await state.saveClonedVoice(
      name: '预览音色',
      referenceAudioPath: preview.referenceAudioPath,
      previewAudioPath: preview.previewAudioPath,
      gender: '女声',
    );

    expect(voice.referenceAudioPath, preview.referenceAudioPath);
    expect(voice.previewAudioPath, preview.previewAudioPath);
    expect(service.previewTexts, <String>['你好，欢迎使用声绘。这是一段用于比较音色的标准试听文本。']);
  });

  test('voice previews use one fixed comparison sample text', () async {
    const expectedSample = '你好，欢迎使用声绘。这是一段用于比较音色的标准试听文本。';
    final service = _RecordingMimoService();
    final state = AppState(mimoService: service);

    await state.previewDesignedVoice(stylePrompt: '温柔清晰的年轻女性声音');
    await state.previewVoice(state.voices.first);

    expect(service.designSampleTexts, <String>[expectedSample]);
    expect(service.generatedSampleTexts, <String>[expectedSample]);
  });

  test('generated audio is appended to history', () async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('你好，欢迎使用 AI 语音工作台。');
    state.updateStylePrompt('像熟人当面提醒');

    final generated = await state.generateCurrentVoice();

    expect(generated.text, '你好，欢迎使用 AI 语音工作台。');
    expect(generated.stylePrompt, '像熟人当面提醒');
    expect(state.history.single.id, generated.id);
  });

  test('regenerates history audio by replacing the original record', () async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('需要重生成的文本');
    state.updateStylePrompt('原始表演指令');

    final generated = await state.generateCurrentVoice();
    state.updateStylePrompt('当前页面新指令');
    final regenerateFuture = state.regenerateAudio(generated);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(state.isGenerating, isFalse);

    final regenerated = await regenerateFuture;

    expect(regenerated.text, generated.text);
    expect(regenerated.id, generated.id);
    expect(regenerated.voiceId, generated.voiceId);
    expect(regenerated.stylePrompt, '原始表演指令');
    expect(state.history, hasLength(1));
    expect(state.history.single.id, generated.id);
    expect(state.history.single.audioPath, regenerated.audioPath);
  });

  test('loads persisted voices history and draft data', () async {
    final jsonStore = MemoryJsonStore();
    final voiceStore = LocalVoiceStore(jsonStore: jsonStore);
    final historyStore = LocalHistoryStore(jsonStore: jsonStore);
    final draftStore = LocalDraftStore(jsonStore: jsonStore);

    await voiceStore.saveUserVoices(<Voice>[
      Voice.cloned(
        id: 'voice-custom',
        name: '我的音色',
        referenceAudioPath: '/tmp/ref.wav',
        createdAt: DateTime(2026, 5, 29, 10),
      ),
    ]);
    await historyStore.saveHistory(<GeneratedAudio>[
      GeneratedAudio(
        id: 'audio-1',
        text: '历史文本',
        voiceId: 'voice-custom',
        voiceName: '我的音色',
        audioPath: '/tmp/audio.wav',
        durationMs: 1000,
        createdAt: DateTime(2026, 5, 29, 11),
      ),
    ]);
    await draftStore.save(
      const DraftState(
        text: '草稿',
        stylePrompt: '温柔',
        speed: 1.2,
        emotion: '开心',
        selectedVoiceId: 'voice-custom',
      ),
    );

    final state = AppState(
      mimoService: MockMimoService(),
      voiceStore: voiceStore,
      historyStore: historyStore,
      draftStore: draftStore,
    );
    await state.loadLocalData();

    expect(state.selectedVoice?.id, 'voice-custom');
    expect(state.draftText, '草稿');
    expect(state.stylePrompt, '温柔');
    expect(state.speed, 1.2);
    expect(state.emotion, '开心');
    expect(state.history.single.id, 'audio-1');
  });

  test(
    'generation persists history and marks selected voice as recently used',
    () async {
      final jsonStore = MemoryJsonStore();
      final voiceStore = LocalVoiceStore(jsonStore: jsonStore);
      final historyStore = LocalHistoryStore(jsonStore: jsonStore);
      final state = AppState(
        mimoService: MockMimoService(),
        voiceStore: voiceStore,
        historyStore: historyStore,
        draftStore: LocalDraftStore(jsonStore: jsonStore),
      );

      state.updateDraftText('要生成的文本');
      final audio = await state.generateCurrentVoice();

      final persisted = await historyStore.loadHistory();
      final reloadedVoices = await voiceStore.loadVoices();

      expect(persisted.single.id, audio.id);
      expect(reloadedVoices.first.lastUsedAt, isNotNull);
    },
  );
}

Future<void> _mockPathProviderDocumentsDirectory(String path) async {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return path;
        }
        if (call.method == 'getTemporaryDirectory') {
          return path;
        }
        return null;
      });
}

Future<void> _clearPathProviderMock() async {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

List<int> _tinyWavBytes() {
  return <int>[
    0x52,
    0x49,
    0x46,
    0x46,
    0x24,
    0x00,
    0x00,
    0x00,
    0x57,
    0x41,
    0x56,
    0x45,
    0x66,
    0x6d,
    0x74,
    0x20,
    0x10,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x01,
    0x00,
    0x40,
    0x1f,
    0x00,
    0x00,
    0x80,
    0x3e,
    0x00,
    0x00,
    0x02,
    0x00,
    0x10,
    0x00,
    0x64,
    0x61,
    0x74,
    0x61,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
}

class _ReferenceCheckingMimoService extends MockMimoService {
  final List<String> previewTexts = <String>[];

  @override
  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
    required ServiceConfig config,
  }) {
    if (request.referenceAudioPath == null ||
        !File(request.referenceAudioPath!).existsSync()) {
      throw StateError('托管参考音频不存在');
    }
    previewTexts.add(request.text);
    return super.generateSpeech(request: request, config: config);
  }
}

class _RecordingMimoService extends MockMimoService {
  final List<String> designSampleTexts = <String>[];
  final List<String> generatedSampleTexts = <String>[];

  @override
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
    required ServiceConfig config,
  }) {
    designSampleTexts.add(sampleText);
    return super.designVoiceReferenceAudio(
      stylePrompt: stylePrompt,
      sampleText: sampleText,
      config: config,
    );
  }

  @override
  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
    required ServiceConfig config,
  }) {
    generatedSampleTexts.add(request.text);
    return super.generateSpeech(request: request, config: config);
  }
}
