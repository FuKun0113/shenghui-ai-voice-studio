import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/connection_test_result.dart';
import '../../domain/service_config.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
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
              title: 'MiMo 服务',
              subtitle: 'API URL、API Key、连接测试和代理模式。',
              onTap: () => _openPage(
                context,
                title: 'MiMo 服务',
                icon: HugeIcons.strokeRoundedCloudServer,
                child: _MiMoServicePage(appState: widget.appState),
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: HugeIcons.strokeRoundedInformationCircle,
              title: '关于本 App',
              subtitle: '版本、定位和产品说明。',
              onTap: () => _openInfoPage(
                context,
                title: '关于 AI 语音工作台',
                icon: HugeIcons.strokeRoundedInformationCircle,
                body: const <Widget>[
                  _DetailParagraph(
                    'AI 语音工作台是一个面向 Android 的 MiMo 语音生成原型，重点提供音色管理、语音生成、历史保存和本地体验。',
                  ),
                  _DetailBullet('产品当前聚焦本地体验，不包含账号体系。'),
                  _DetailBullet('MiMo API、广告和通知仅保留轻量预留位。'),
                  _DetailBullet('发布版可补充版本号、更新说明和第三方组件说明。'),
                ],
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
                icon: HugeIcons.strokeRoundedCopyright,
                body: const <Widget>[
                  _DetailParagraph(
                    '本应用仅提供语音合成和音色管理工具，不负责验证用户上传或克隆的声音是否拥有合法授权。',
                  ),
                  _DetailBullet('禁止未经授权使用他人声音进行克隆或生成。'),
                  _DetailBullet('所有使用行为由用户自行承担责任。'),
                  _DetailBullet('建议在首次使用克隆功能前再次确认授权声明。'),
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
                icon: HugeIcons.strokeRoundedShield01,
                body: const <Widget>[
                  _DetailParagraph('应用需要录音、文件选择和本地存储权限，以便采集参考音频、读取文档并保存生成结果。'),
                  _DetailBullet('音频和文档默认保存在本机。'),
                  _DetailBullet('当前实现不主动上传用户本地历史到云端。'),
                  _DetailBullet('后续若接入云功能，应补充单独的隐私说明。'),
                ],
              ),
            ),
          ],
        ),
      ),
      AppPanel(
        padding: EdgeInsets.zero,
        child: _MenuTile(
          icon: HugeIcons.strokeRoundedNotification01,
          title: '弹窗通知预留',
          subtitle: '只保留应用内弹窗提醒入口。',
          onTap: () => _openInfoPage(
            context,
            title: '弹窗通知预留',
            icon: HugeIcons.strokeRoundedNotification01,
            body: const <Widget>[
              _DetailParagraph('当前版本不接真实推送，只保留轻量弹窗提醒接口。'),
              _DetailBullet('后续可用于生成完成弹窗或系统公告。'),
              _DetailBullet('远程推送能力暂不接入。'),
            ],
          ),
        ),
      ),
      AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const <Widget>[
            SectionHeader(
              title: '常驻广告位预留',
              subtitle: '当前只占位，不加载真实广告或广告 SDK。',
              trailing: IconBadge(icon: HugeIcons.strokeRoundedMegaphone01),
            ),
            SizedBox(height: 12),
            _ReservedAdSlot(title: '设置页常驻位', subtitle: '后续可接 Banner 或原生广告'),
            SizedBox(height: 10),
            _ReservedAdSlot(title: '启动页广告位', subtitle: '仅预留，不改变当前启动流程'),
          ],
        ),
      ),
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
    required List<List<dynamic>> icon,
    required Widget child,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            _SettingsDetailPage(title: title, icon: icon, child: child),
      ),
    );
  }

  void _openInfoPage(
    BuildContext context, {
    required String title,
    required List<List<dynamic>> icon,
    required List<Widget> body,
  }) {
    _openPage(
      context,
      title: title,
      icon: icon,
      child: _SettingsInfoPage(title: title, icon: icon, body: body),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final List<List<dynamic>> icon;
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
  const _SettingsInfoPage({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final List<List<dynamic>> icon;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPanel(
          child: Row(
            children: <Widget>[
              IconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
      ],
    );
  }
}

class _MiMoServicePage extends StatefulWidget {
  const _MiMoServicePage({required this.appState});

  final AppState appState;

  @override
  State<_MiMoServicePage> createState() => _MiMoServicePageState();
}

class _MiMoServicePageState extends State<_MiMoServicePage> {
  late final TextEditingController _apiUrlController;
  late final TextEditingController _apiKeyController;
  ServiceMode _mode = ServiceMode.directApiKey;
  bool _showApiKey = false;
  bool _testing = false;
  ConnectionTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    final config = widget.appState.serviceConfig;
    _mode = config.mode;
    _apiUrlController = TextEditingController(text: config.apiUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.appState.updateServiceConfig(
      ServiceConfig(
        mode: _mode,
        backendUrl: _mode == ServiceMode.backendProxy
            ? _apiUrlController.text.trim()
            : null,
        apiUrl: _apiUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('MiMo API 配置已保存')));
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await widget.appState.mimoService.testConnection(
      config: ServiceConfig(
        mode: _mode,
        backendUrl: _mode == ServiceMode.backendProxy
            ? _apiUrlController.text.trim()
            : null,
        apiUrl: _apiUrlController.text.trim(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<ServiceMode>(
                segments: const <ButtonSegment<ServiceMode>>[
                  ButtonSegment<ServiceMode>(
                    value: ServiceMode.directApiKey,
                    icon: AppHugeIcon(HugeIcons.strokeRoundedKey01),
                    label: Text('直连'),
                  ),
                  ButtonSegment<ServiceMode>(
                    value: ServiceMode.backendProxy,
                    icon: AppHugeIcon(HugeIcons.strokeRoundedCloudServer),
                    label: Text('代理'),
                  ),
                ],
                selected: <ServiceMode>{_mode},
                onSelectionChanged: (values) =>
                    setState(() => _mode = values.first),
              ),
              const SizedBox(height: 14),
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
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const AppHugeIcon(HugeIcons.strokeRoundedSave),
                      label: const Text('保存配置'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: AppHugeIcon(
                        _testing
                            ? HugeIcons.strokeRoundedLoading03
                            : HugeIcons.strokeRoundedCloudSavingDone01,
                      ),
                      label: Text(_testing ? '测试中...' : '测试连接'),
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
        const SizedBox(height: 12),
        const AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LabeledInfoBlock(
                label: '后端代理',
                description: '正式版本推荐，API Key 保存在服务端。',
              ),
              SizedBox(height: 10),
              _LabeledInfoBlock(
                label: '原型直连 API Key',
                description: '仅用于本机 Demo。',
              ),
            ],
          ),
        ),
      ],
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

class _DetailParagraph extends StatelessWidget {
  const _DetailParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DetailBullet extends StatelessWidget {
  const _DetailBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
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

class _ReservedAdSlot extends StatelessWidget {
  const _ReservedAdSlot({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            AppHugeIcon(
              HugeIcons.strokeRoundedMegaphone01,
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '预留',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
