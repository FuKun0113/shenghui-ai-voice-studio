import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class VoiceLibraryScreen extends StatelessWidget {
  const VoiceLibraryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('默认音色'));
  }
}
