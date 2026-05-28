import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class VoiceCloneApp extends StatelessWidget {
  const VoiceCloneApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 语音工作台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(appState: appState),
    );
  }
}
