import 'dart:convert';

import '../domain/voice.dart';
import 'local_json_store.dart';

class LocalVoiceStore {
  LocalVoiceStore({LocalJsonStore? jsonStore})
    : _jsonStore = jsonStore ?? MemoryJsonStore();

  static const String _userVoicesKey = 'mimo_user_voices';
  static const String _voiceOverlaysKey = 'mimo_voice_overlays';

  final LocalJsonStore _jsonStore;

  Future<List<Voice>> loadVoices() async {
    final builtins = builtinVoices();
    final users = await loadUserVoices();
    final overlays = await _loadVoiceOverlays();
    return <Voice>[
      for (final voice in builtins) _applyOverlay(voice, overlays[voice.id]),
      for (final voice in users) _applyOverlay(voice, overlays[voice.id]),
    ];
  }

  Future<List<Voice>> loadUserVoices() async {
    final raw = await _jsonStore.getString(_userVoicesKey);
    if (raw == null || raw.isEmpty) return <Voice>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Voice>[];
    return decoded
        .whereType<Map>()
        .map((item) => Voice.fromJson(Map<String, Object?>.from(item)))
        .where((voice) => voice.isUserCreated)
        .toList();
  }

  Future<void> saveUserVoices(List<Voice> voices) {
    final userVoices = voices.where((voice) => voice.isUserCreated).toList();
    return _jsonStore.setString(
      _userVoicesKey,
      jsonEncode(userVoices.map((voice) => voice.toJson()).toList()),
    );
  }

  Future<void> saveVoiceOverlay(
    String voiceId, {
    required bool favorite,
    DateTime? lastUsedAt,
  }) async {
    final overlays = await _loadVoiceOverlays();
    overlays[voiceId] = _VoiceOverlay(
      favorite: favorite,
      lastUsedAt: lastUsedAt,
    );
    await _jsonStore.setString(
      _voiceOverlaysKey,
      jsonEncode(<String, Object?>{
        for (final entry in overlays.entries) entry.key: entry.value.toJson(),
      }),
    );
  }

  List<Voice> builtinVoices() {
    return <Voice>[
      Voice.builtin(
        id: 'mimo-default',
        name: 'MiMo-默认',
        providerVoiceId: 'mimo_default',
        previewAudioPath: 'assets/audio/previews/mimo-default.wav',
        language: '自动',
        gender: '自动',
        tags: const <String>['官方预置', '默认路由', '中国集群冰糖', '海外集群 Mia'],
      ),
      Voice.builtin(
        id: 'mimo-bingtang',
        name: '冰糖',
        providerVoiceId: '冰糖',
        previewAudioPath: 'assets/audio/previews/bingtang.wav',
        language: '中文',
        gender: '女性',
        tags: const <String>['官方预置', '中文', '女声'],
      ),
      Voice.builtin(
        id: 'mimo-moli',
        name: '茉莉',
        providerVoiceId: '茉莉',
        previewAudioPath: 'assets/audio/previews/moli.wav',
        language: '中文',
        gender: '女性',
        tags: const <String>['官方预置', '中文', '女声'],
      ),
      Voice.builtin(
        id: 'mimo-soda',
        name: '苏打',
        providerVoiceId: '苏打',
        previewAudioPath: 'assets/audio/previews/soda.wav',
        language: '中文',
        gender: '男性',
        tags: const <String>['官方预置', '中文', '男声'],
      ),
      Voice.builtin(
        id: 'mimo-baihua',
        name: '白桦',
        providerVoiceId: '白桦',
        previewAudioPath: 'assets/audio/previews/baihua.wav',
        language: '中文',
        gender: '男性',
        tags: const <String>['官方预置', '中文', '男声'],
      ),
      Voice.builtin(
        id: 'mimo-mia',
        name: 'Mia',
        providerVoiceId: 'Mia',
        previewAudioPath: 'assets/audio/previews/mia.wav',
        language: 'English',
        gender: 'Female',
        tags: const <String>['官方预置', 'English', 'Female'],
      ),
      Voice.builtin(
        id: 'mimo-chloe',
        name: 'Chloe',
        providerVoiceId: 'Chloe',
        previewAudioPath: 'assets/audio/previews/chloe.wav',
        language: 'English',
        gender: 'Female',
        tags: const <String>['官方预置', 'English', 'Female'],
      ),
      Voice.builtin(
        id: 'mimo-milo',
        name: 'Milo',
        providerVoiceId: 'Milo',
        previewAudioPath: 'assets/audio/previews/milo.wav',
        language: 'English',
        gender: 'Male',
        tags: const <String>['官方预置', 'English', 'Male'],
      ),
      Voice.builtin(
        id: 'mimo-dean',
        name: 'Dean',
        providerVoiceId: 'Dean',
        previewAudioPath: 'assets/audio/previews/dean.wav',
        language: 'English',
        gender: 'Male',
        tags: const <String>['官方预置', 'English', 'Male'],
      ),
    ];
  }

  Future<Map<String, _VoiceOverlay>> _loadVoiceOverlays() async {
    final raw = await _jsonStore.getString(_voiceOverlaysKey);
    if (raw == null || raw.isEmpty) return <String, _VoiceOverlay>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, _VoiceOverlay>{};
    return <String, _VoiceOverlay>{
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is Map)
          entry.key as String: _VoiceOverlay.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          ),
    };
  }

  Voice _applyOverlay(Voice voice, _VoiceOverlay? overlay) {
    if (overlay == null) return voice;
    return voice.copyWith(
      favorite: overlay.favorite,
      lastUsedAt: overlay.lastUsedAt,
    );
  }
}

class _VoiceOverlay {
  const _VoiceOverlay({required this.favorite, this.lastUsedAt});

  final bool favorite;
  final DateTime? lastUsedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'favorite': favorite,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory _VoiceOverlay.fromJson(Map<String, Object?> json) {
    final date = json['lastUsedAt'] as String?;
    return _VoiceOverlay(
      favorite: json['favorite'] as bool? ?? false,
      lastUsedAt: date == null ? null : DateTime.tryParse(date),
    );
  }
}
