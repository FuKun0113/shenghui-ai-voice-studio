import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/connection_test_result.dart';
import '../../domain/remote_app_config.dart';
import '../../domain/service_config.dart';
import '../../domain/text_optimization_config.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';

const double _settingsInlineControlHeight = 58;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_syncProductConfig);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_syncProductConfig);
    super.dispose();
  }

  void _syncProductConfig() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settingsAdSlots = widget.appState.remoteAppConfig.enabledAdSlots
        .where((slot) => slot.placement == 'settings_footer')
        .toList();
    final sections = <Widget>[
      AppPanel(
        child: Row(
          children: <Widget>[
            const IconBadge(icon: HugeIcons.strokeRoundedSettings01),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '设置中心',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      AppPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            _MenuTile(
              icon: HugeIcons.strokeRoundedCloudServer,
              title: '语音服务',
              subtitle: 'API URL、API Key 和连接测试。',
              onTap: () => _openPage(
                context,
                title: '语音服务',
                child: _VoiceServicePage(appState: widget.appState),
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: HugeIcons.strokeRoundedMagicWand02,
              title: '文本优化服务',
              subtitle: 'OpenAI 兼容 API，用于生成指令和优化文本。',
              onTap: () => _openPage(
                context,
                title: '文本优化服务',
                child: _TextOptimizationServicePage(appState: widget.appState),
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: HugeIcons.strokeRoundedCopyright,
              title: '版权与授权声明',
              subtitle: '授权边界和用户责任提醒。',
              onTap: () => _openInfoPage(
                context,
                title: '版权与授权声明',
                body: const <Widget>[
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedShieldUser,
                    title: '使用边界',
                    text:
                        '本应用是语音合成、音色设计和音色管理工具。应用不会自动判断用户上传、录制或克隆的声音是否拥有合法授权，相关授权核验需要由用户自行完成。',
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedMicOff01,
                    title: '禁止行为',
                    bullets: <String>[
                      '禁止未经授权使用他人声音进行克隆、仿冒、传播或商业化使用。',
                      '禁止生成误导他人身份、侵犯肖像权/声音权益/名誉权的内容。',
                      '禁止将生成音频用于诈骗、骚扰、冒充、虚假宣传或其他违法用途。',
                    ],
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedAgreement01,
                    title: '用户责任',
                    text:
                        '用户应确保自己拥有素材、声音和文本内容的合法使用权。因上传、克隆、生成、下载、分享音频产生的法律责任，由用户自行承担。',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: HugeIcons.strokeRoundedShield01,
              title: '隐私与权限',
              subtitle: '录音、文件和存储权限说明。',
              onTap: () => _openInfoPage(
                context,
                title: '隐私与权限',
                body: const <Widget>[
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedMic01,
                    title: '录音权限',
                    text:
                        '录音权限仅用于用户主动录制参考音频或创建克隆音色。应用不会在后台自动录音，也不会在用户未触发录音时采集麦克风内容。',
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedFolder01,
                    title: '文件与存储',
                    bullets: <String>[
                      '文件选择用于读取 Word、PDF、TXT 文档中的文本内容。',
                      '本地存储用于保存生成音频、历史记录和用户创建的音色。',
                      '下载和分享动作由用户主动触发，应用不会自动分享本地文件。',
                    ],
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedCloudOff,
                    title: '数据传输',
                    text:
                        '生成历史、用户音色和草稿默认只保存在本机。调用语音服务或文本优化服务时，请求所需文本、指令或参考音频会发送到用户配置的服务。',
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedKey02,
                    title: '服务密钥本地保存',
                    text:
                        '用户填写的语音服务和文本优化服务密钥仅保存在本机本 App 的本地配置中，不会上传到声绘后台。请妥善保管自己的密钥，并确认第三方服务的数据处理规则。',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: HugeIcons.strokeRoundedInformationCircle,
              title: '关于本 App',
              subtitle: '版本、定位和产品说明。',
              onTap: () => _openInfoPage(
                context,
                title: '关于声绘',
                body: const <Widget>[
                  _AboutBrandCard(),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedRocket01,
                    title: '产品定位',
                    text:
                        '声绘是一款面向 Android 的语音生成工具，重点提供音色选择、音色设计、音色克隆、文本转语音、历史管理和本地播放体验。',
                  ),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedSettings05,
                    title: '使用建议',
                    bullets: <String>[
                      '第一次使用前，请先在“语音服务”中填写服务地址和密钥。',
                      '需要自动优化文本时，可在“文本优化服务”中选择一个文本模型。',
                      '生成音频会保存在本机历史记录，可播放、下载、分享或删除。',
                      '创建或克隆音色前，请确认你拥有对应声音素材的使用授权。',
                    ],
                  ),
                  _VersionInfoCard(),
                  _RepositoryLinkCard(),
                  _InfoSectionCard(
                    icon: HugeIcons.strokeRoundedPackage,
                    title: '服务说明',
                    text:
                        '语音生成和文本优化由用户配置的服务提供。不同服务的可用地区、额度、价格和数据处理规则可能不同，请以服务商说明为准。',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      for (final slot in settingsAdSlots)
        _RemoteAdSlotCard(slot: slot, icon: HugeIcons.strokeRoundedMegaphone01),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final entry in sections.indexed) ...<Widget>[
            if (entry.$1 != 0) const SizedBox(height: 12),
            entry.$2
                .animate()
                .fadeIn(duration: 220.ms, delay: (entry.$1 * 35).ms)
                .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }

  void _openPage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _SettingsDetailPage(title: title, child: child),
      ),
    );
  }

  void _openInfoPage(
    BuildContext context, {
    required String title,
    required List<Widget> body,
  }) {
    _openPage(
      context,
      title: title,
      child: _SettingsInfoPage(body: body),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsInfoPage extends StatelessWidget {
  const _SettingsInfoPage({required this.body});

  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final entry in body.indexed) ...<Widget>[
          if (entry.$1 != 0) const SizedBox(height: 12),
          entry.$2,
        ],
      ],
    );
  }
}

class _VoiceServicePage extends StatefulWidget {
  const _VoiceServicePage({required this.appState});

  final AppState appState;

  @override
  State<_VoiceServicePage> createState() => _VoiceServicePageState();
}

class _VoiceServicePageState extends State<_VoiceServicePage> {
  late final TextEditingController _apiUrlController;
  late final TextEditingController _apiKeyController;
  bool _showApiKey = false;
  bool _testing = false;
  ConnectionTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    final config = widget.appState.serviceConfig;
    _apiUrlController = TextEditingController(text: config.normalizedApiUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    widget.appState.addListener(_syncProductConfig);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_syncProductConfig);
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _syncProductConfig() {
    if (mounted) setState(() {});
  }

  void _save() {
    final normalizedApiUrl = ServiceConfig.normalizeBaseApiUrl(
      _apiUrlController.text,
    );
    _apiUrlController.text = normalizedApiUrl;
    widget.appState.updateServiceConfig(
      ServiceConfig.directApi(
        apiUrl: normalizedApiUrl,
        apiKey: _apiKeyController.text.trim(),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('语音服务配置已保存')));
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await widget.appState.mimoService.testConnection(
      config: ServiceConfig.directApi(
        apiUrl: ServiceConfig.normalizeBaseApiUrl(_apiUrlController.text),
        apiKey: _apiKeyController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceServiceAdSlots = widget.appState.remoteAppConfig.enabledAdSlots
        .where((slot) => slot.placement == 'voice_service')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '语音服务用于生成语音和创建音色。请填写服务商提供的 API URL 和 API Key，保存后可以先测试连接。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const _LabeledInfoBlock(
                label: '服务要求',
                description:
                    '你可以使用小米 MiMo 官方 API，也可以填写第三方兼容 API；所选服务需要同时支持文本转语音、音色克隆和音色设计三项能力，否则部分功能可能不可用。',
              ),
              const SizedBox(height: 10),
              const _LabeledInfoBlock(
                label: '填写方式',
                description:
                    'API URL 建议只填写到 /v1，例如 https://api.xiaomimimo.com/v1；应用会自动拼接 /chat/completions。API Key 填写服务商提供的密钥，仅保存在本机。',
              ),
            ],
          ),
        ),
        for (final slot in voiceServiceAdSlots) ...<Widget>[
          const SizedBox(height: 12),
          _RemoteAdSlotCard(slot: slot, icon: HugeIcons.strokeRoundedRocket01),
        ],
        const SizedBox(height: 12),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  hintText: ServiceConfig.defaultApiUrl,
                  prefixIcon: AppPrefixIcon(HugeIcons.strokeRoundedLink01),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_showApiKey,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  prefixIcon: const AppPrefixIcon(HugeIcons.strokeRoundedKey02),
                  suffixIcon: IconButton(
                    tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    icon: const AppHugeIcon(HugeIcons.strokeRoundedEye),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _FixedHeightControl(
                      key: const Key('voiceServiceSaveButton'),
                      child: AppFlatActionButton(
                        icon: HugeIcons.strokeRoundedSave,
                        label: '保存配置',
                        onPressed: _save,
                        prominent: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FixedHeightControl(
                      key: const Key('voiceServiceTestButton'),
                      child: AppFlatActionButton(
                        icon: _testing
                            ? HugeIcons.strokeRoundedLoading03
                            : HugeIcons.strokeRoundedCloudSavingDone01,
                        label: _testing ? '测试中...' : '测试连接',
                        onPressed: _testing ? null : _testConnection,
                      ),
                    ),
                  ),
                ],
              ),
              if (_testResult != null) ...<Widget>[
                const SizedBox(height: 12),
                _ConnectionResultBox(result: _testResult!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TextOptimizationServicePage extends StatefulWidget {
  const _TextOptimizationServicePage({required this.appState});

  final AppState appState;

  @override
  State<_TextOptimizationServicePage> createState() =>
      _TextOptimizationServicePageState();
}

class _TextOptimizationServicePageState
    extends State<_TextOptimizationServicePage> {
  late final TextEditingController _apiUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  bool _showApiKey = false;
  bool _loadingModels = false;
  List<String> _models = const <String>[];
  String? _modelMessage;
  bool _modelMessageIsError = false;

  @override
  void initState() {
    super.initState();
    final config = widget.appState.textOptimizationConfig;
    _apiUrlController = TextEditingController(text: config.normalizedApiUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
    widget.appState.addListener(_syncProductConfig);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_syncProductConfig);
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _syncProductConfig() {
    if (mounted) setState(() {});
  }

  void _save() {
    final normalizedApiUrl = TextOptimizationConfig.normalizeBaseApiUrl(
      _apiUrlController.text,
    );
    _apiUrlController.text = normalizedApiUrl;
    widget.appState.updateTextOptimizationConfig(
      TextOptimizationConfig(
        apiUrl: normalizedApiUrl,
        apiKey: _apiKeyController.text.trim(),
        model: _modelController.text.trim(),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('文本优化服务配置已保存')));
  }

  TextOptimizationConfig _formConfig() {
    return TextOptimizationConfig(
      apiUrl: TextOptimizationConfig.normalizeBaseApiUrl(
        _apiUrlController.text,
      ),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );
  }

  Future<void> _fetchModels() async {
    setState(() {
      _loadingModels = true;
      _modelMessage = null;
      _modelMessageIsError = false;
    });
    try {
      final models = await widget.appState.fetchTextOptimizationModels(
        _formConfig(),
      );
      if (!mounted) return;
      final current = _modelController.text.trim();
      setState(() {
        _models = models;
        if (current.isEmpty || !models.contains(current)) {
          _modelController.text = models.first;
        }
        _loadingModels = false;
        _modelMessage = '已获取 ${models.length} 个模型，请选择要用于文本优化的模型。';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingModels = false;
        _modelMessage = '模型列表获取失败：$error';
        _modelMessageIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = _modelController.text.trim();
    final selectorModels = _models.isNotEmpty
        ? _models
        : currentModel.isNotEmpty
        ? <String>[currentModel]
        : const <String>[];
    final textOptimizationAdSlots = widget
        .appState
        .remoteAppConfig
        .enabledAdSlots
        .where((slot) => slot.placement == 'text_optimization_service')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(
                title: 'OpenAI 兼容 API',
                subtitle: '用于生成表演指令、润色正文、自动加入风格标签和音频标签。',
              ),
              SizedBox(height: 10),
              _LabeledInfoBlock(
                label: '用途',
                description:
                    '这个模型只负责文本优化：根据正文生成表演指令、把已有文本润色成更适合配音的表达，或自动插入风格标签和音频标签；它不会直接生成语音。',
              ),
              SizedBox(height: 10),
              _LabeledInfoBlock(
                label: '填写方式',
                description:
                    'API URL 填写 OpenAI 兼容服务的基础地址，通常到 /v1 为止，例如 https://api.openai.com/v1。API Key 填写该服务提供的密钥。填写后点击获取模型，再选择一个用于文本优化的模型。',
              ),
            ],
          ),
        ),
        for (final slot in textOptimizationAdSlots) ...<Widget>[
          const SizedBox(height: 12),
          _RemoteAdSlotCard(
            slot: slot,
            icon: HugeIcons.strokeRoundedMagicWand02,
          ),
        ],
        const SizedBox(height: 12),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 14),
              TextField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  hintText: TextOptimizationConfig.defaultApiUrl,
                  prefixIcon: AppPrefixIcon(HugeIcons.strokeRoundedLink01),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_showApiKey,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  prefixIcon: const AppPrefixIcon(HugeIcons.strokeRoundedKey02),
                  suffixIcon: IconButton(
                    tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    icon: const AppHugeIcon(HugeIcons.strokeRoundedEye),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _FixedHeightControl(
                      key: selectorModels.isEmpty
                          ? const Key('textOptimizationModelFieldFrame')
                          : const Key('textOptimizationModelSelector'),
                      child: selectorModels.isEmpty
                          ? TextField(
                              key: const Key('textOptimizationModelField'),
                              controller: _modelController,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                labelText: '模型',
                                hintText: '先获取模型列表，或手动填写兼容模型名',
                                prefixIcon: AppPrefixIcon(
                                  HugeIcons.strokeRoundedAiBrain01,
                                ),
                              ),
                            )
                          : _ModelSelectorField(
                              models: selectorModels,
                              selectedModel:
                                  selectorModels.contains(currentModel)
                                  ? currentModel
                                  : selectorModels.first,
                              onSelected: (value) {
                                setState(() => _modelController.text = value);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    key: const Key('fetchTextOptimizationModelsButton'),
                    width: 126,
                    child: _FixedHeightControl(
                      child: AppFlatActionButton(
                        icon: _loadingModels
                            ? HugeIcons.strokeRoundedLoading03
                            : HugeIcons.strokeRoundedCloudDownload,
                        label: _loadingModels ? '获取中' : '获取模型',
                        onPressed: _loadingModels ? null : _fetchModels,
                      ),
                    ),
                  ),
                ],
              ),
              if (_modelMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                _InlineStatusBox(
                  message: _modelMessage!,
                  isError: _modelMessageIsError,
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _save,
                icon: const AppHugeIcon(HugeIcons.strokeRoundedSave),
                label: const Text('保存配置'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FixedHeightControl extends StatelessWidget {
  const _FixedHeightControl({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: _settingsInlineControlHeight, child: child);
  }
}

class _ModelSelectorField extends StatelessWidget {
  const _ModelSelectorField({
    required this.models,
    required this.selectedModel,
    required this.onSelected,
  });

  final List<String> models;
  final String selectedModel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openModelSheet(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: <Widget>[
                const AppPrefixIcon(HugeIcons.strokeRoundedAiBrain01),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '模型',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppHugeIcon(
                  HugeIcons.strokeRoundedArrowDown01,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openModelSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            key: const Key('modelSelectorSheet'),
            color: scheme.surface,
            elevation: 12,
            shadowColor: scheme.shadow.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.68,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: <Widget>[
                        const AppHugeIcon(HugeIcons.strokeRoundedAiBrain01),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '选择模型',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      itemCount: models.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.46),
                      ),
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final selected = model == selectedModel;
                        return ListTile(
                          title: Text(
                            model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                          leading: IconBadge(
                            icon: selected
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedAiBrain01,
                            selected: selected,
                          ),
                          trailing: selected
                              ? AppHugeIcon(
                                  HugeIcons.strokeRoundedCheckmarkCircle02,
                                  color: scheme.primary,
                                )
                              : null,
                          onTap: () {
                            onSelected(model);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionResultBox extends StatelessWidget {
  const _ConnectionResultBox({required this.result});

  final ConnectionTestResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = result.isSuccess;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: success
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success
              ? scheme.primary.withValues(alpha: 0.24)
              : scheme.error.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            AppHugeIcon(
              success
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedAlertCircle,
              color: success ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(result.message)),
          ],
        ),
      ),
    );
  }
}

class _InlineStatusBox extends StatelessWidget {
  const _InlineStatusBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.primary;
    final background = isError
        ? scheme.errorContainer.withValues(alpha: 0.56)
        : scheme.primaryContainer.withValues(alpha: 0.58);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            AppHugeIcon(
              isError
                  ? HugeIcons.strokeRoundedAlertCircle
                  : HugeIcons.strokeRoundedCheckmarkCircle02,
              color: color,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isError ? scheme.onErrorContainer : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: IconBadge(icon: icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const AppHugeIcon(HugeIcons.strokeRoundedArrowRight01),
        onTap: onTap,
      ),
    );
  }
}

class _RemoteAdSlotCard extends StatelessWidget {
  const _RemoteAdSlotCard({required this.slot, required this.icon});

  final RemoteAdSlot slot;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: slot.targetUrl.isEmpty
            ? null
            : () => _openExternalUrl(slot.targetUrl),
        child: AppPanel(
          emphasized: true,
          child: Row(
            children: <Widget>[
              AppHugeIcon(icon, color: scheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      slot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (slot.message.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        slot.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (slot.targetUrl.isNotEmpty) ...<Widget>[
                const SizedBox(width: 10),
                AppHugeIcon(
                  HugeIcons.strokeRoundedArrowUpRight01,
                  color: scheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutBrandCard extends StatelessWidget {
  const _AboutBrandCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPanel(
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/brand/shenghui_icon_1024.png',
              key: const Key('aboutAppIcon'),
              width: 88,
              height: 88,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '声绘',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '把文字绘成有表情的声音',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepositoryLinkCard extends StatelessWidget {
  const _RepositoryLinkCard();

  static const String _repositoryUrl =
      'https://github.com/FuKun0113/shenghui-ai-voice-studio';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openExternalUrl(_repositoryUrl),
        child: AppPanel(
          child: Row(
            children: <Widget>[
              AppHugeIcon(
                HugeIcons.strokeRoundedCodeCircle,
                color: scheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '开源仓库',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _repositoryUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppHugeIcon(
                HugeIcons.strokeRoundedArrowUpRight01,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _VersionInfoCard extends StatelessWidget {
  const _VersionInfoCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null || info.version.trim().isEmpty
            ? '1.0.0'
            : info.version.trim();
        final build = info == null || info.buildNumber.trim().isEmpty
            ? ''
            : info.buildNumber.trim();
        final versionText = build.isEmpty ? version : '$version ($build)';
        return _InfoSectionCard(
          icon: HugeIcons.strokeRoundedInformationCircle,
          title: '版本信息',
          text: '当前安装版本：$versionText。后续版本请以正式下载渠道为准。',
        );
      },
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.icon,
    required this.title,
    this.text,
    this.bullets = const <String>[],
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? text;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppHugeIcon(icon, color: scheme.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (text != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              text!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final bullet in bullets.indexed) ...<Widget>[
              if (bullet.$1 != 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LabeledInfoBlock extends StatelessWidget {
  const _LabeledInfoBlock({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppHugeIcon(
                HugeIcons.strokeRoundedSettings05,
                size: 18,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
