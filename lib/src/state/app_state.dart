import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';
import '../domain/voice.dart';
import '../services/local_voice_store.dart';
import '../services/mock_mimo_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.mimoService,
    LocalVoiceStore? voiceStore,
  }) : _voiceStore = voiceStore ?? LocalVoiceStore() {
    _voices = _voiceStore.builtinVoices();
    _selectedVoiceId = _voices.first.id;
  }

  final MockMimoService mimoService;
  final LocalVoiceStore _voiceStore;
  final Uuid _uuid = const Uuid();

  late List<Voice> _voices;
  final List<GeneratedAudio> _history = <GeneratedAudio>[];
  String? _selectedVoiceId;
  String _draftText = '';
  double _speed = 1.0;
  String _emotion = '自然';
  String _stylePrompt = '';
  bool _isGenerating = false;

  List<Voice> get voices => List<Voice>.unmodifiable(_voices);
  List<GeneratedAudio> get history =>
      List<GeneratedAudio>.unmodifiable(_history);
  String get draftText => _draftText;
  double get speed => _speed;
  String get emotion => _emotion;
  String get stylePrompt => _stylePrompt;
  bool get isGenerating => _isGenerating;

  Voice? get selectedVoice {
    for (final voice in _voices) {
      if (voice.id == _selectedVoiceId) return voice;
    }
    return _voices.isEmpty ? null : _voices.first;
  }

  void selectVoice(String voiceId) {
    _selectedVoiceId = voiceId;
    notifyListeners();
  }

  void updateDraftText(String value) {
    _draftText = value;
    notifyListeners();
  }

  void updateSpeed(double value) {
    _speed = value;
    notifyListeners();
  }

  void updateEmotion(String value) {
    _emotion = value;
    notifyListeners();
  }

  void updateStylePrompt(String value) {
    _stylePrompt = value;
    notifyListeners();
  }

  Future<Voice> designVoice({
    required String name,
    required String stylePrompt,
  }) async {
    const sampleText = '你好，这是一段用于固定 AI 设计音色的标准试听文本。';
    final referenceAudioPath = await mimoService.designVoiceReferenceAudio(
      stylePrompt: stylePrompt,
      sampleText: sampleText,
    );
    final now = DateTime.now();
    final voice = Voice.designed(
      id: _uuid.v4(),
      name: name,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: referenceAudioPath,
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    notifyListeners();
    return voice;
  }

  Future<Voice> saveClonedVoice({
    required String name,
    required String referenceAudioPath,
  }) async {
    final now = DateTime.now();
    final voice = Voice.cloned(
      id: _uuid.v4(),
      name: name,
      referenceAudioPath: referenceAudioPath,
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    notifyListeners();
    return voice;
  }

  void deleteVoice(String voiceId) {
    _voices = _voices
        .where((voice) => voice.id != voiceId || !voice.isUserCreated)
        .toList();
    if (_selectedVoiceId == voiceId) {
      _selectedVoiceId = _voices.first.id;
    }
    notifyListeners();
  }

  Future<GeneratedAudio> generateCurrentVoice() async {
    final voice = selectedVoice;
    if (voice == null) {
      throw StateError('请选择音色');
    }
    if (_draftText.trim().isEmpty) {
      throw StateError('请输入要生成的文本');
    }
    _isGenerating = true;
    notifyListeners();
    try {
      final request = GenerationRequest.fromVoice(
        text: _draftText.trim(),
        voice: voice,
        speed: _speed,
        emotion: _emotion,
        stylePrompt: _stylePrompt,
      );
      final generated = await mimoService.generateSpeech(request: request);
      _history.insert(0, generated);
      return generated;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
