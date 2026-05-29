class RemoteAppConfig {
  const RemoteAppConfig({
    this.adSlots = const <RemoteAdSlot>[],
    this.popupNotice = const RemotePopupNotice.disabled(),
    this.updatePolicy = const RemoteUpdatePolicy.disabled(),
    this.promoLink = '',
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
      promoLink: json['promo_link'] as String? ?? '',
    );
  }

  final List<RemoteAdSlot> adSlots;
  final RemotePopupNotice popupNotice;
  final RemoteUpdatePolicy updatePolicy;
  final String promoLink;

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
    this.title = '',
    this.message = '',
    this.targetUrl = '',
    this.enabled = false,
  });

  const RemotePopupNotice.disabled() : this();

  factory RemotePopupNotice.fromJson(Map<String, Object?> json) {
    return RemotePopupNotice(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetUrl:
          json['target_url'] as String? ?? json['targetUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final String title;
  final String message;
  final String targetUrl;
  final bool enabled;
}

class RemoteUpdatePolicy {
  const RemoteUpdatePolicy({
    this.latestVersionCode = 0,
    this.minSupportedVersionCode = 0,
    this.forceUpdate = false,
    this.updateUrl = '',
  });

  const RemoteUpdatePolicy.disabled() : this();

  factory RemoteUpdatePolicy.fromJson(Map<String, Object?> json) {
    return RemoteUpdatePolicy(
      latestVersionCode: _intValue(json['latest_version_code']),
      minSupportedVersionCode: _intValue(json['min_supported_version_code']),
      forceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String? ?? '',
    );
  }

  final int latestVersionCode;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String updateUrl;

  bool requiresUpdate({required int currentVersionCode}) {
    return forceUpdate &&
        minSupportedVersionCode > 0 &&
        currentVersionCode < minSupportedVersionCode;
  }

  bool hasOptionalUpdate({required int currentVersionCode}) {
    return latestVersionCode > 0 && currentVersionCode < latestVersionCode;
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
