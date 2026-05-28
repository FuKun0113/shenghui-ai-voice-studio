import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('输入文本'));
  }
}
