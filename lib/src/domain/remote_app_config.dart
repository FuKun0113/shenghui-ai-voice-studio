class RemoteAppConfig {
  const RemoteAppConfig({
    this.adSlots = const <RemoteAdSlot>[],
    this.popupNotice = const RemotePopupNotice.disabled(),
    this.appUpdate = const RemoteAppUpdate.disabled(),
  });

  const RemoteAppConfig.disabled() : this();

  factory RemoteAppConfig.fromJson(Map<String, Object?> json) {
    final slots = json['ad_slots'];
    final appUpdate = json['app_update'];
    return RemoteAppConfig(
      adSlots: slots is List
          ? slots
                .whereType<Map>()
                .map(
                  (item) =>
                      RemoteAdSlot.fromJson(Map<String, Object?>.from(item)),
                )
                .toList()
          : const <RemoteAdSlot>[],
      popupNotice: json['popup_notice'] is Map
          ? RemotePopupNotice.fromJson(
              Map<String, Object?>.from(json['popup_notice']! as Map),
            )
          : const RemotePopupNotice.disabled(),
      appUpdate: appUpdate is Map
          ? RemoteAppUpdate.fromJson(Map<String, Object?>.from(appUpdate))
          : RemoteAppUpdate.fromChangelogJson(json),
    );
  }

  final List<RemoteAdSlot> adSlots;
  final RemotePopupNotice popupNotice;
  final RemoteAppUpdate appUpdate;

  List<RemoteAdSlot> get enabledAdSlots =>
      adSlots.where((slot) => slot.enabled).toList();
}

class RemoteAdSlot {
  const RemoteAdSlot({
    required this.placement,
    this.title = '',
    this.message = '',
    this.targetUrl = '',
    this.enabled = false,
  });

  factory RemoteAdSlot.fromJson(Map<String, Object?> json) {
    return RemoteAdSlot(
      placement: json['placement'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetUrl:
          json['target_url'] as String? ?? json['targetUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final String placement;
  final String title;
  final String message;
  final String targetUrl;
  final bool enabled;
}

class RemotePopupNotice {
  const RemotePopupNotice({
    this.id = '',
    this.title = '',
    this.message = '',
    this.targetUrl = '',
    this.enabled = false,
  });

  const RemotePopupNotice.disabled() : this();

  factory RemotePopupNotice.fromJson(Map<String, Object?> json) {
    return RemotePopupNotice(
      id: json['id'] as String? ?? json['notice_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetUrl:
          json['target_url'] as String? ?? json['targetUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String message;
  final String targetUrl;
  final bool enabled;

  String get acknowledgementKey {
    final normalizedId = id.trim();
    if (normalizedId.isNotEmpty) return normalizedId;
    return <String>[
      title.trim(),
      message.trim(),
      targetUrl.trim(),
    ].join('\u001f');
  }
}

class RemoteAppUpdate {
  const RemoteAppUpdate({
    this.latestVersion = '',
    this.title = '',
    this.message = '',
    this.updateUrl = '',
    this.enabled = false,
    this.force = false,
  });

  const RemoteAppUpdate.disabled() : this();

  static const String defaultUpdateUrl =
      'https://shenghui.cloudlark.net/#download';

  factory RemoteAppUpdate.fromJson(Map<String, Object?> json) {
    return RemoteAppUpdate(
      latestVersion:
          json['latest_version'] as String? ??
          json['latestVersion'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      updateUrl:
          json['update_url'] as String? ?? json['updateUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      force:
          json['force_update'] as bool? ??
          json['forceUpdate'] as bool? ??
          json['force'] as bool? ??
          false,
    );
  }

  factory RemoteAppUpdate.fromChangelogJson(Map<String, Object?> json) {
    final success = json['success'];
    if (success is bool && !success) return const RemoteAppUpdate.disabled();

    final latestEntry = _latestChangelogEntry(json['changelog']);
    final latestVersion = _firstString(<Object?>[
      json['latest_version'],
      json['latestVersion'],
      latestEntry?['version'],
    ]);
    if (latestVersion.isEmpty) return const RemoteAppUpdate.disabled();

    final updateUrl = _firstString(<Object?>[
      json['download_url'],
      json['downloadUrl'],
      json['update_url'],
      json['updateUrl'],
    ]);
    return RemoteAppUpdate(
      latestVersion: latestVersion,
      title: _firstString(<Object?>[
        latestEntry?['name'],
        latestEntry?['title'],
      ]),
      message: _firstString(<Object?>[
        latestEntry?['description'],
        latestEntry?['message'],
        latestEntry?['body'],
      ]),
      updateUrl: updateUrl.isEmpty ? defaultUpdateUrl : updateUrl,
      enabled: json['enabled'] as bool? ?? true,
      force:
          json['force_update'] as bool? ??
          json['forceUpdate'] as bool? ??
          json['force'] as bool? ??
          false,
    );
  }

  final String latestVersion;
  final String title;
  final String message;
  final String updateUrl;
  final bool enabled;
  final bool force;

  bool get hasVersion => latestVersion.trim().isNotEmpty;
  bool get hasUpdateUrl => updateUrl.trim().isNotEmpty;
}

Map<String, Object?>? _latestChangelogEntry(Object? value) {
  if (value is! List) return null;
  final entries = value
      .whereType<Map>()
      .map((entry) => Map<String, Object?>.from(entry))
      .toList();
  if (entries.isEmpty) return null;
  for (final entry in entries) {
    if (entry['isLatest'] == true) return entry;
  }
  return entries.first;
}

String _firstString(List<Object?> values) {
  for (final value in values) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
