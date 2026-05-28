import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('MiMo 服务'));
  }
}
