class RemoteAppConfig {
  const RemoteAppConfig({
    this.adSlots = const <RemoteAdSlot>[],
    this.popupNotice = const RemotePopupNotice.disabled(),
    this.updatePolicy = const RemoteUpdatePolicy.disabled(),
  });

  const RemoteAppConfig.disabled() : this();

  factory RemoteAppConfig.fromJson(Map<String, Object?> json) {
    final slots = json['ad_slots'];
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
      updatePolicy: RemoteUpdatePolicy.fromJson(json),
    );
  }

  final List<RemoteAdSlot> adSlots;
  final RemotePopupNotice popupNotice;
  final RemoteUpdatePolicy updatePolicy;

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

class RemoteUpdatePolicy {
  const RemoteUpdatePolicy({
    this.latestVersion = '',
    this.minSupportedVersion = '',
    this.latestVersionCode = 0,
    this.minSupportedVersionCode = 0,
    this.forceUpdate = false,
    this.updateUrl = '',
  });

  const RemoteUpdatePolicy.disabled() : this();

  factory RemoteUpdatePolicy.fromJson(Map<String, Object?> json) {
    return RemoteUpdatePolicy(
      latestVersion: _stringValue(
        json['latest_version'] ?? json['latest_version_name'],
      ),
      minSupportedVersion: _stringValue(
        json['min_supported_version'] ?? json['min_supported_version_name'],
      ),
      latestVersionCode: _intValue(json['latest_version_code']),
      minSupportedVersionCode: _intValue(json['min_supported_version_code']),
      forceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String? ?? '',
    );
  }

  final String latestVersion;
  final String minSupportedVersion;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String updateUrl;

  bool requiresUpdate({
    int currentVersionCode = 0,
    String currentVersionName = '',
  }) {
    final versionResult = _compareIfPossible(
      currentVersionName,
      minSupportedVersion,
    );
    if (forceUpdate && versionResult != null) {
      return versionResult < 0;
    }
    return forceUpdate &&
        minSupportedVersionCode > 0 &&
        currentVersionCode < minSupportedVersionCode;
  }

  bool hasOptionalUpdate({
    int currentVersionCode = 0,
    String currentVersionName = '',
  }) {
    final versionResult = _compareIfPossible(currentVersionName, latestVersion);
    if (versionResult != null) {
      return versionResult < 0;
    }
    return latestVersionCode > 0 && currentVersionCode < latestVersionCode;
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _stringValue(Object? value) {
    return value is String ? value.trim() : '';
  }

  static int? _compareIfPossible(String current, String target) {
    final currentParts = _versionParts(current);
    final targetParts = _versionParts(target);
    if (currentParts == null || targetParts == null) return null;
    final length = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;
    for (var i = 0; i < length; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final targetPart = i < targetParts.length ? targetParts[i] : 0;
      if (currentPart != targetPart) {
        return currentPart.compareTo(targetPart);
      }
    }
    return 0;
  }

  static List<int>? _versionParts(String value) {
    final normalized = value.split('+').first.trim();
    if (normalized.isEmpty) return null;
    final parts = normalized.split('.');
    final parsed = <int>[];
    for (final part in parts) {
      final match = RegExp(r'^\d+').firstMatch(part);
      if (match == null) return null;
      parsed.add(int.parse(match.group(0)!));
    }
    return parsed;
  }
}
