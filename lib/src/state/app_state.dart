import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';
import '../domain/service_config.dart';
import '../domain/text_optimization_config.dart';
import '../domain/voice.dart';
import '../domain/draft_state.dart';
import '../services/local_draft_store.dart';
import '../services/local_history_store.dart';
import '../services/local_voice_store.dart';
import '../services/mimo_client.dart';
import '../services/reference_audio_store.dart';
import '../services/service_config_store.dart';
import '../services/text_optimization_config_store.dart';
import '../services/text_optimization_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.mimoService,
    TextOptimizationService? textOptimizationService,
    LocalVoiceStore? voiceStore,
    LocalHistoryStore? historyStore,
    LocalDraftStore? draftStore,
    ReferenceAudioStore? referenceAudioStore,
    ServiceConfig? serviceConfig,
    TextOptimizationConfig? textOptimizationConfig,
    this.serviceConfigStore,
    this.textOptimizationConfigStore,
  }) : _voiceStore = voiceStore ?? LocalVoiceStore(),
       _historyStore = historyStore ?? LocalHistoryStore(),
       _draftStore = draftStore ?? LocalDraftStore(),
       _referenceAudioStore = referenceAudioStore ?? ReferenceAudioStore(),
       _serviceConfig =
           serviceConfig?.normalized() ?? const ServiceConfig.directApi(),
       _textOptimizationService =
           textOptimizationService ?? OpenAiCompatibleTextOptimizationService(),
       _textOptimizationConfig =
           textOptimizationConfig ?? const TextOptimizationConfig() {
    _voices = _voiceStore.builtinVoices();
    _selectedVoiceId = _voices.first.id;
  }

  final MimoService mimoService;
  final TextOptimizationService _textOptimizationService;
  final LocalVoiceStore _voiceStore;
  final LocalHistoryStore _historyStore;
  final LocalDraftStore _draftStore;
  final ReferenceAudioStore _referenceAudioStore;
  final LocalServiceConfigStore? serviceConfigStore;
  final LocalTextOptimizationConfigStore? textOptimizationConfigStore;
  final Uuid _uuid = const Uuid();

  late List<Voice> _voices;
  final List<GeneratedAudio> _history = <GeneratedAudio>[];
  String? _selectedVoiceId;
  String _draftText = '';
  double _speed = 1.0;
  String _emotion = '自然';
  String _stylePrompt = '';
  ServiceConfig _serviceConfig;
  TextOptimizationConfig _textOptimizationConfig;
  bool _isGenerating = false;
  bool _isOptimizingText = false;
  static const String voicePreviewSampleText = '你好，欢迎使用声绘。这是一段用于比较音色的标准试听文本。';

  List<Voice> get voices => List<Voice>.unmodifiable(_voices);
  List<GeneratedAudio> get history =>
      List<GeneratedAudio>.unmodifiable(_history);
  String get draftText => _draftText;
  double get speed => _speed;
  String get emotion => _emotion;
  String get stylePrompt => _stylePrompt;
  ServiceConfig get serviceConfig => _serviceConfig;
  TextOptimizationConfig get textOptimizationConfig => _textOptimizationConfig;
  bool get isGenerating => _isGenerating;
  bool get isOptimizingText => _isOptimizingText;

  Voice? get selectedVoice {
    for (final voice in _voices) {
      if (voice.id == _selectedVoiceId) return voice;
    }
    return _voices.isEmpty ? null : _voices.first;
  }

  Future<void> loadLocalData() async {
    final textConfigStore = textOptimizationConfigStore;
    if (textConfigStore != null) {
      _textOptimizationConfig = await textConfigStore.load();
    }
    _voices = await _voiceStore.loadVoices();
    _history
      ..clear()
      ..addAll(await _historyStore.loadHistory());
    final draft = await _draftStore.load();
    _draftText = draft.text;
    _stylePrompt = draft.stylePrompt;
    _speed = draft.speed;
    _emotion = draft.emotion;
    _selectedVoiceId = _resolveSelectedVoiceId(draft.selectedVoiceId);
    notifyListeners();
  }

  void selectVoice(String voiceId) {
    _selectedVoiceId = voiceId;
    _markVoiceRecentlyUsed(voiceId);
    _persistDraft();
    notifyListeners();
  }

  void updateDraftText(String value) {
    _draftText = value;
    _persistDraft();
    notifyListeners();
  }

  void updateSpeed(double value) {
    _speed = value;
    _persistDraft();
    notifyListeners();
  }

  void updateEmotion(String value) {
    _emotion = value;
    _persistDraft();
    notifyListeners();
  }

  void updateStylePrompt(String value) {
    _stylePrompt = value;
    _persistDraft();
    notifyListeners();
  }

  void updateServiceConfig(ServiceConfig value) {
    _serviceConfig = value.normalized();
    final store = serviceConfigStore;
    if (store != null) {
      unawaited(store.save(_serviceConfig));
    }
    notifyListeners();
  }

  void updateTextOptimizationConfig(TextOptimizationConfig value) {
    _textOptimizationConfig = value;
    final store = textOptimizationConfigStore;
    if (store != null) {
      unawaited(store.save(value));
    }
    notifyListeners();
  }

  Future<List<String>> fetchTextOptimizationModels(
    TextOptimizationConfig config,
  ) {
    return _textOptimizationService.fetchModels(config: config);
  }

  Future<String> optimizeText({
    required TextOptimizationTask task,
    required String inputText,
    String stylePrompt = '',
  }) async {
    final normalized = inputText.trim();
    if (normalized.isEmpty && task != TextOptimizationTask.writeInstruct) {
      throw StateError('请输入需要优化的文本');
    }
    _isOptimizingText = true;
    notifyListeners();
    try {
      return await _textOptimizationService.optimize(
        task: task,
        inputText: normalized,
        stylePrompt: stylePrompt,
        config: _textOptimizationConfig,
      );
    } finally {
      _isOptimizingText = false;
      notifyListeners();
    }
  }

  Future<Voice> designVoice({
    required String name,
    required String stylePrompt,
    String? gender,
  }) async {
    final referenceAudioPath = await previewDesignedVoice(
      stylePrompt: stylePrompt,
    );
    return saveDesignedVoice(
      name: name,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      gender: gender,
    );
  }

  Future<String> previewDesignedVoice({required String stylePrompt}) {
    return mimoService.designVoiceReferenceAudio(
      stylePrompt: stylePrompt,
      sampleText: voicePreviewSampleText,
      config: _serviceConfig,
    );
  }

  Future<Voice> saveDesignedVoice({
    required String name,
    required String stylePrompt,
    required String referenceAudioPath,
    String? gender,
  }) async {
    final now = DateTime.now();
    final voice = Voice.designed(
      id: _uuid.v4(),
      name: name,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: referenceAudioPath,
      gender: _normalizedGender(gender),
      tags: _userVoiceTags(gender),
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    unawaited(_voiceStore.saveUserVoices(_voices));
    _persistDraft();
    notifyListeners();
    return voice;
  }

  Future<Voice> saveClonedVoice({
    required String name,
    required String referenceAudioPath,
    String? previewAudioPath,
    String? gender,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final managedReferencePath = await _referenceAudioStore
        .persistReferenceAudio(referenceAudioPath);
    final normalizedGender = _normalizedGender(gender);
    final tags = _userVoiceTags(gender);
    final previewPath =
        previewAudioPath ??
        (await _generateVoicePreviewAudio(
          Voice.cloned(
            id: id,
            name: name,
            referenceAudioPath: managedReferencePath,
            gender: normalizedGender,
            tags: tags,
            createdAt: now,
          ),
        )).audioPath;
    final voice = Voice.cloned(
      id: id,
      name: name,
      referenceAudioPath: managedReferencePath,
      previewAudioPath: previewPath,
      gender: normalizedGender,
      tags: tags,
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    unawaited(_voiceStore.saveUserVoices(_voices));
    _persistDraft();
    notifyListeners();
    return voice;
  }

  Future<({String referenceAudioPath, String previewAudioPath})>
  previewClonedVoice({
    required String name,
    required String referenceAudioPath,
    String? gender,
  }) async {
    final managedReferencePath = await _referenceAudioStore
        .persistReferenceAudio(referenceAudioPath);
    final now = DateTime.now();
    final previewAudio = await _generateVoicePreviewAudio(
      Voice.cloned(
        id: 'preview-${_uuid.v4()}',
        name: name.trim().isEmpty ? '未命名音色' : name.trim(),
        referenceAudioPath: managedReferencePath,
        gender: _normalizedGender(gender),
        tags: _userVoiceTags(gender),
        createdAt: now,
      ),
    );
    return (
      referenceAudioPath: managedReferencePath,
      previewAudioPath: previewAudio.audioPath,
    );
  }

  void deleteVoice(String voiceId) {
    _voices = _voices
        .where((voice) => voice.id != voiceId || !voice.isUserCreated)
        .toList();
    if (_selectedVoiceId == voiceId) {
      _selectedVoiceId = _voices.isEmpty ? null : _voices.first.id;
    }
    unawaited(_voiceStore.saveUserVoices(_voices));
    _persistDraft();
    notifyListeners();
  }

  Future<GeneratedAudio> generateCurrentVoice() async {
    return generateText(_draftText);
  }

  Future<GeneratedAudio> generateText(String text) async {
    final voice = selectedVoice;
    if (voice == null) {
      throw StateError('请选择音色');
    }
    return _generateTextWithVoice(text: text, voice: voice);
  }

  Future<GeneratedAudio> regenerateAudio(GeneratedAudio audio) async {
    final voice = _voices
        .where((voice) => voice.id == audio.voiceId)
        .firstOrNull;
    if (voice == null) {
      throw StateError('原音色已不存在，请重新选择音色');
    }
    final generated = await _requestGeneratedAudioWithVoice(
      text: audio.text,
      voice: voice,
      stylePrompt: audio.stylePrompt ?? _stylePrompt,
      title: audio.title,
    );
    final replacement = generated.copyWith(
      id: audio.id,
      title: audio.title,
      favorite: audio.favorite,
    );
    final index = _history.indexWhere((item) => item.id == audio.id);
    if (index >= 0) {
      _history[index] = replacement;
    } else {
      _history.insert(0, replacement);
    }
    unawaited(_historyStore.saveHistory(_history));
    _markVoiceRecentlyUsed(voice.id);
    notifyListeners();
    return replacement;
  }

  Future<GeneratedAudio> _generateTextWithVoice({
    required String text,
    required Voice voice,
    String? stylePromptOverride,
    String? title,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final generated = await _requestGeneratedAudioWithVoice(
        text: text,
        voice: voice,
        stylePrompt: stylePromptOverride ?? _stylePrompt,
        title: title,
      );
      _history.insert(0, generated);
      unawaited(_historyStore.saveHistory(_history));
      _markVoiceRecentlyUsed(voice.id);
      return generated;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<GeneratedAudio> _requestGeneratedAudioWithVoice({
    required String text,
    required Voice voice,
    String? stylePrompt,
    String? title,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw StateError('请输入要生成的文本');
    }
    final request = GenerationRequest.fromVoice(
      text: normalizedText,
      voice: voice,
      speed: 1.0,
      emotion: _emotion,
      stylePrompt: stylePrompt ?? _stylePrompt,
    );
    return (await mimoService.generateSpeech(
      request: request,
      config: _serviceConfig,
    )).copyWith(title: title);
  }

  Future<GeneratedAudio> previewVoice(Voice voice) {
    return _generateVoicePreviewAudio(voice);
  }

  Future<GeneratedAudio> _generateVoicePreviewAudio(Voice voice) {
    final request = GenerationRequest.fromVoice(
      text: voicePreviewSampleText,
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '保持自然清晰，适合快速试听。',
    );
    return mimoService.generateSpeech(request: request, config: _serviceConfig);
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    unawaited(_historyStore.saveHistory(_history));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    unawaited(_historyStore.clear());
    notifyListeners();
  }

  void toggleVoiceFavorite(String voiceId) {
    Voice? updatedVoice;
    _voices = _voices.map((voice) {
      if (voice.id != voiceId) return voice;
      updatedVoice = voice.copyWith(favorite: !voice.favorite);
      return updatedVoice!;
    }).toList();
    if (updatedVoice != null) {
      unawaited(
        _voiceStore.saveVoiceOverlay(
          updatedVoice!.id,
          favorite: updatedVoice!.favorite,
          lastUsedAt: updatedVoice!.lastUsedAt,
        ),
      );
    }
    notifyListeners();
  }

  void toggleHistoryFavorite(String audioId) {
    _updateHistoryItem(
      audioId,
      (audio) => audio.copyWith(favorite: !audio.favorite),
    );
  }

  void renameHistoryItem(String audioId, String title) {
    _updateHistoryItem(audioId, (audio) => audio.copyWith(title: title.trim()));
  }

  void useHistoryText(String audioId) {
    final item = _history.where((audio) => audio.id == audioId).firstOrNull;
    if (item == null) return;
    updateDraftText(item.text);
  }

  String? _normalizedGender(String? gender) {
    final value = gender?.trim();
    if (value == null || value.isEmpty || value == '不限定') return null;
    return value;
  }

  List<String> _userVoiceTags(String? gender) {
    final normalized = _normalizedGender(gender);
    return <String>['用户创建', ?normalized];
  }

  String? _resolveSelectedVoiceId(String? savedVoiceId) {
    if (_voices.isEmpty) return null;
    if (savedVoiceId != null &&
        _voices.any((voice) => voice.id == savedVoiceId)) {
      return savedVoiceId;
    }
    if (_selectedVoiceId != null &&
        _voices.any((voice) => voice.id == _selectedVoiceId)) {
      return _selectedVoiceId;
    }
    return _voices.first.id;
  }

  void _persistDraft() {
    unawaited(
      _draftStore.save(
        DraftState(
          text: _draftText,
          stylePrompt: _stylePrompt,
          speed: _speed,
          emotion: _emotion,
          selectedVoiceId: _selectedVoiceId,
        ),
      ),
    );
  }

  void _markVoiceRecentlyUsed(String voiceId) {
    Voice? updatedVoice;
    final now = DateTime.now();
    _voices = _voices.map((voice) {
      if (voice.id != voiceId) return voice;
      updatedVoice = voice.copyWith(lastUsedAt: now);
      return updatedVoice!;
    }).toList();
    if (updatedVoice == null) return;
    unawaited(
      _voiceStore.saveVoiceOverlay(
        updatedVoice!.id,
        favorite: updatedVoice!.favorite,
        lastUsedAt: updatedVoice!.lastUsedAt,
      ),
    );
  }

  void _updateHistoryItem(
    String audioId,
    GeneratedAudio Function(GeneratedAudio audio) update,
  ) {
    final index = _history.indexWhere((audio) => audio.id == audioId);
    if (index < 0) return;
    _history[index] = update(_history[index]);
    unawaited(_historyStore.saveHistory(_history));
    notifyListeners();
  }
}
