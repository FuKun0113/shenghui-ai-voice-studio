import '../domain/remote_app_config.dart';

abstract class RemoteAppConfigService {
  Future<RemoteAppConfig> fetch();
}

class StaticRemoteAppConfigService implements RemoteAppConfigService {
  StaticRemoteAppConfigService([
    this.config = const RemoteAppConfig.disabled(),
  ]);

  final RemoteAppConfig config;

  @override
  Future<RemoteAppConfig> fetch() async => config;
}

class FirebaseRemoteConfigKeys {
  const FirebaseRemoteConfigKeys._();

  static const String adSlots = 'ad_slots';
  static const String popupNotice = 'popup_notice';
  static const String promoLink = 'promo_link';
  static const String latestVersionCode = 'latest_version_code';
  static const String minSupportedVersionCode = 'min_supported_version_code';
  static const String forceUpdate = 'force_update';
  static const String updateUrl = 'update_url';

  static const List<String> all = <String>[
    adSlots,
    popupNotice,
    promoLink,
    latestVersionCode,
    minSupportedVersionCode,
    forceUpdate,
    updateUrl,
  ];
}
