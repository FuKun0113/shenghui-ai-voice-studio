import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/remote_app_config.dart';
import '../services/audio_playback_service.dart';
import '../services/local_popup_notice_store.dart';
import '../state/app_state.dart';
import '../ui/generate/generate_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/voices/voice_library_screen.dart';

class AppShell extends StatefulWidget {
  AppShell({
    super.key,
    required this.appState,
    this.popupNoticeStore,
    AudioPlaybackController? playbackService,
  }) : playbackService = playbackService ?? AudioPlaybackService.instance;

  final AppState appState;
  final LocalPopupNoticeStore? popupNoticeStore;
  final AudioPlaybackController playbackService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final LocalPopupNoticeStore _popupNoticeStore;
  bool _popupPromptScheduled = false;
  bool _popupPromptRunning = false;
  String? _shownPopupNoticeKey;

  @override
  void initState() {
    super.initState();
    _popupNoticeStore = widget.popupNoticeStore ?? LocalPopupNoticeStore();
    widget.appState.addListener(_schedulePopupNotice);
    _schedulePopupNotice();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_schedulePopupNotice);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      GenerateScreen(
        appState: widget.appState,
        onOpenSettings: () => setState(() => _index = 3),
      ),
      VoiceLibraryScreen(
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
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
        onDestinationSelected: _selectDestination,
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

  void _selectDestination(int value) {
    if (_index == 1 && value != 1) {
      unawaited(widget.playbackService.stop());
    }
    setState(() => _index = value);
  }

  void _schedulePopupNotice() {
    if (_popupPromptScheduled || !mounted) return;
    _popupPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _popupPromptScheduled = false;
      unawaited(_showPopupNoticeWhenIdle());
    });
  }

  Future<void> _showPopupNoticeWhenIdle() async {
    if (_popupPromptRunning) return;
    _popupPromptRunning = true;
    try {
      final notice = widget.appState.remoteAppConfig.popupNotice;
      final noticeKey = notice.acknowledgementKey;
      if (!notice.enabled ||
          noticeKey.isEmpty ||
          _shownPopupNoticeKey == noticeKey) {
        return;
      }
      final alreadyAcknowledged = await _popupNoticeStore.isAcknowledged(
        notice,
      );
      if (!mounted || alreadyAcknowledged) return;
      _shownPopupNoticeKey = noticeKey;
      await _showPopupNotice(notice);
    } finally {
      _popupPromptRunning = false;
    }
  }

  Future<void> _showPopupNotice(RemotePopupNotice notice) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedNotification01,
            color: scheme.primary,
            size: 30,
          ),
          title: Text(notice.title),
          content: Text(notice.message),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                await _popupNoticeStore.acknowledge(notice);
                navigator.pop();
              },
              child: const Text('知道了'),
            ),
            if (notice.targetUrl.isNotEmpty)
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(dialogContext);
                  await _popupNoticeStore.acknowledge(notice);
                  navigator.pop();
                  await _openExternalUrl(notice.targetUrl);
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
