import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../state/app_state.dart';
import '../ui/generate/generate_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/voices/voice_library_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

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
            fontSize: 23,
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
