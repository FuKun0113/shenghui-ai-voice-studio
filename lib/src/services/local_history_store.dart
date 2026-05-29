import 'dart:convert';

import '../domain/generated_audio.dart';
import 'local_json_store.dart';

class LocalHistoryStore {
  LocalHistoryStore({LocalJsonStore? jsonStore})
    : _jsonStore = jsonStore ?? MemoryJsonStore();

  static const String _historyKey = 'mimo_generated_history';

  final LocalJsonStore _jsonStore;

  Future<List<GeneratedAudio>> loadHistory() async {
    final raw = await _jsonStore.getString(_historyKey);
    if (raw == null || raw.isEmpty) return <GeneratedAudio>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <GeneratedAudio>[];
    return decoded
        .whereType<Map>()
        .map((item) => GeneratedAudio.fromJson(Map<String, Object?>.from(item)))
        .toList();
  }

  Future<void> saveHistory(List<GeneratedAudio> history) {
    return _jsonStore.setString(
      _historyKey,
      jsonEncode(history.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() {
    return _jsonStore.remove(_historyKey);
  }
}
