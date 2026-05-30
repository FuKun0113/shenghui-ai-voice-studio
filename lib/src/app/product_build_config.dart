class ProductBuildConfig {
  const ProductBuildConfig({this.configUrl = ''});

  const ProductBuildConfig.fromEnvironment()
    : configUrl = const String.fromEnvironment('SHENGHUI_PRODUCT_CONFIG_URL');

  final String configUrl;

  String get normalizedConfigUrl => configUrl.trim();

  bool get canUseProductConfig => normalizedConfigUrl.isNotEmpty;
}
