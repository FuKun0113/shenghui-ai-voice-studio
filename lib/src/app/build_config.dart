class AppBuildConfig {
  const AppBuildConfig({
    this.isOfficialBuild = false,
    this.remoteConfigUrl = '',
    this.analyticsEndpoint = '',
    this.channel = '',
  });

  const AppBuildConfig.fromEnvironment()
    : isOfficialBuild = const bool.fromEnvironment('SHENGHUI_OFFICIAL_BUILD'),
      remoteConfigUrl = const String.fromEnvironment(
        'SHENGHUI_REMOTE_CONFIG_URL',
      ),
      analyticsEndpoint = const String.fromEnvironment(
        'SHENGHUI_ANALYTICS_ENDPOINT',
      ),
      channel = const String.fromEnvironment('SHENGHUI_BUILD_CHANNEL');

  final bool isOfficialBuild;
  final String remoteConfigUrl;
  final String analyticsEndpoint;
  final String channel;

  String get normalizedRemoteConfigUrl => remoteConfigUrl.trim();

  String get normalizedAnalyticsEndpoint => analyticsEndpoint.trim();

  String get normalizedChannel {
    final value = channel.trim();
    if (value.isNotEmpty) return value;
    return isOfficialBuild ? 'official' : 'oss';
  }

  bool get canUseRemoteConfig => isOfficialBuild;

  bool get canUseUsageAnalytics =>
      isOfficialBuild && normalizedAnalyticsEndpoint.isNotEmpty;
}
