import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/remote_app_config.dart';
import '../state/app_state.dart';
import '../ui/generate/generate_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/voices/voice_library_screen.dart';
import '../ui/widgets/app_panel.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _currentVersionCode = 1;
  bool _remotePromptScheduled = false;
  bool _updateDialogShown = false;
  bool _popupNoticeShown = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_scheduleRemotePrompts);
    _loadVersionCode();
    _scheduleRemotePrompts();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_scheduleRemotePrompts);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      GenerateScreen(
        appState: widget.appState,
        onOpenSettings: () => setState(() => _index = 3),
      ),
      VoiceLibraryScreen(appState: widget.appState),
      HistoryScreen(
        appState: widget.appState,
        onReuseText: (_) => setState(() => _index = 0),
      ),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        toolbarHeight: 64,
        title: Text(
          '声绘',
          key: const Key('mainBrandTitle'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            height: 1,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: screens[_index],
          ),
        ),
      ),
      bottomNavigationBar: _FlatBottomNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        items: const <_FlatNavItem>[
          _FlatNavItem(
            label: '生成',
            icon: HugeIcons.strokeRoundedAudioWave01,
            selectedIcon: HugeIcons.strokeRoundedMagicWand02,
          ),
          _FlatNavItem(
            label: '音色库',
            icon: HugeIcons.strokeRoundedLibrary,
            selectedIcon: HugeIcons.strokeRoundedVoiceId,
          ),
          _FlatNavItem(
            label: '历史',
            icon: HugeIcons.strokeRoundedFileClock,
            selectedIcon: HugeIcons.strokeRoundedClock01,
          ),
          _FlatNavItem(
            label: '设置',
            icon: HugeIcons.strokeRoundedSettings03,
            selectedIcon: HugeIcons.strokeRoundedSettings01,
          ),
        ],
      ),
    );
  }

  Future<void> _loadVersionCode() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber);
      if (!mounted || buildNumber == null) return;
      setState(() => _currentVersionCode = buildNumber);
      _scheduleRemotePrompts();
    } on Object {
      _scheduleRemotePrompts();
    }
  }

  void _scheduleRemotePrompts() {
    if (_remotePromptScheduled || !mounted) return;
    _remotePromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _remotePromptScheduled = false;
      _showRemotePrompts();
    });
  }

  void _showRemotePrompts() {
    final config = widget.appState.remoteAppConfig;
    if (!_updateDialogShown &&
        (config.updatePolicy.requiresUpdate(
              currentVersionCode: _currentVersionCode,
            ) ||
            config.updatePolicy.hasOptionalUpdate(
              currentVersionCode: _currentVersionCode,
            ))) {
      _updateDialogShown = true;
      final forceUpdate = config.updatePolicy.requiresUpdate(
        currentVersionCode: _currentVersionCode,
      );
      _showUpdateDialog(config.updatePolicy, forceUpdate: forceUpdate);
      return;
    }
    final notice = config.popupNotice;
    if (!_popupNoticeShown && notice.enabled) {
      _popupNoticeShown = true;
      _showPopupNotice(notice);
    }
  }

  Future<void> _showUpdateDialog(
    RemoteUpdatePolicy policy, {
    required bool forceUpdate,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            icon: AppHugeIcon(
              forceUpdate
                  ? HugeIcons.strokeRoundedAlert02
                  : HugeIcons.strokeRoundedRocket01,
              color: forceUpdate ? scheme.error : scheme.primary,
              size: 30,
            ),
            title: Text(forceUpdate ? '需要更新声绘' : '发现新版本'),
            content: Text(
              forceUpdate ? '当前版本已不可用，请更新后继续使用。' : '新版本已经可用，建议更新以获得更好的体验。',
            ),
            actions: <Widget>[
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('稍后'),
                ),
              FilledButton(
                onPressed: policy.updateUrl.isEmpty
                    ? null
                    : () => _openExternalUrl(policy.updateUrl),
                child: const Text('立即更新'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPopupNotice(RemotePopupNotice notice) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: AppHugeIcon(
            HugeIcons.strokeRoundedNotification01,
            color: scheme.primary,
            size: 30,
          ),
          title: Text(notice.title),
          content: Text(notice.message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            if (notice.targetUrl.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openExternalUrl(notice.targetUrl);
                },
                child: const Text('查看'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FlatBottomNavigationBar extends StatelessWidget {
  const _FlatBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_FlatNavItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: <Widget>[
              for (final entry in items.indexed)
                Expanded(
                  child: _FlatNavDestination(
                    index: entry.$1,
                    item: entry.$2,
                    selected: selectedIndex == entry.$1,
                    onTap: () => onDestinationSelected(entry.$1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlatNavDestination extends StatelessWidget {
  const _FlatNavDestination({
    required this.index,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _FlatNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('bottomNavItem-$index'),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              key: selected ? Key('bottomNavSelectedIndicator-$index') : null,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: selected ? 34 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            HugeIcon(
              icon: selected ? item.selectedIcon : item.icon,
              color: color,
              size: selected ? 27 : 24,
            ),
            const SizedBox(height: 5),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatNavItem {
  const _FlatNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final List<List<dynamic>> icon;
  final List<List<dynamic>> selectedIcon;
}
