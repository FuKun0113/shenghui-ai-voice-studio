import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('暂无生成记录'));
  }
}
