import 'package:flutter/material.dart';

import 'src/app/voice_clone_app.dart';
import 'src/services/mock_mimo_service.dart';
import 'src/state/app_state.dart';

void main() {
  runApp(VoiceCloneApp(appState: AppState(mimoService: MockMimoService())));
}
