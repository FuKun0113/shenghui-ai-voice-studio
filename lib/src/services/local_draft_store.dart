import 'dart:convert';

import '../domain/draft_state.dart';
import 'local_json_store.dart';

class LocalDraftStore {
  LocalDraftStore({LocalJsonStore? jsonStore})
    : _jsonStore = jsonStore ?? MemoryJsonStore();

  static const String _draftKey = 'mimo_generation_draft';

  final LocalJsonStore _jsonStore;

  Future<DraftState> load() async {
    final raw = await _jsonStore.getString(_draftKey);
    if (raw == null || raw.isEmpty) return const DraftState();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const DraftState();
    return DraftState.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<void> save(DraftState draft) {
    return _jsonStore.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clear() {
    return _jsonStore.remove(_draftKey);
  }
}
