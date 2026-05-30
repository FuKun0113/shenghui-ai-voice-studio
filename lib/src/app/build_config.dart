class AppBuildConfig {
  const AppBuildConfig({
    this.isOfficialBuild = false,
    this.remoteConfigUrl = '',
    this.channel = '',
  });

  const AppBuildConfig.fromEnvironment()
    : isOfficialBuild = const bool.fromEnvironment('SHENGHUI_OFFICIAL_BUILD'),
      remoteConfigUrl = const String.fromEnvironment(
        'SHENGHUI_REMOTE_CONFIG_URL',
      ),
      channel = const String.fromEnvironment('SHENGHUI_BUILD_CHANNEL');

  final bool isOfficialBuild;
  final String remoteConfigUrl;
  final String channel;

  String get normalizedRemoteConfigUrl => remoteConfigUrl.trim();

  String get normalizedChannel {
    final value = channel.trim();
    if (value.isNotEmpty) return value;
    return isOfficialBuild ? 'official' : 'oss';
  }

  bool get canUseRemoteConfig => isOfficialBuild;
}
