import 'dart:convert';

import '../domain/remote_app_config.dart';
import 'local_json_store.dart';

class LocalPopupNoticeStore {
  LocalPopupNoticeStore({LocalJsonStore? jsonStore})
    : _jsonStore = jsonStore ?? MemoryJsonStore();

  static const String _acknowledgedNoticeKey =
      'shenghui_acknowledged_popup_notices';

  final LocalJsonStore _jsonStore;

  Future<bool> isAcknowledged(RemotePopupNotice notice) async {
    final key = notice.acknowledgementKey;
    if (key.isEmpty) return false;
    final acknowledgedKeys = await _loadAcknowledgedKeys();
    return acknowledgedKeys.contains(key);
  }

  Future<void> acknowledge(RemotePopupNotice notice) async {
    final key = notice.acknowledgementKey;
    if (key.isEmpty) return;
    final acknowledgedKeys = await _loadAcknowledgedKeys();
    if (!acknowledgedKeys.add(key)) return;
    await _jsonStore.setString(
      _acknowledgedNoticeKey,
      jsonEncode(acknowledgedKeys.toList()),
    );
  }

  Future<Set<String>> _loadAcknowledgedKeys() async {
    final raw = await _jsonStore.getString(_acknowledgedNoticeKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <String>{};
    }
    if (decoded is! List) return <String>{};
    return decoded.whereType<String>().toSet();
  }
}
