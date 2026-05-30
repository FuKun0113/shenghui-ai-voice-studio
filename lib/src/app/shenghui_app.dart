import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class ShenghuiApp extends StatelessWidget {
  const ShenghuiApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '声绘',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(appState: appState),
    );
  }
}
