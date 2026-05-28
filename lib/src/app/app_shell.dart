import 'package:flutter/material.dart';

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
      GenerateScreen(appState: widget.appState),
      VoiceLibraryScreen(appState: widget.appState),
      HistoryScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI 语音工作台')),
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: '生成'),
          NavigationDestination(icon: Icon(Icons.record_voice_over), label: '音色库'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
