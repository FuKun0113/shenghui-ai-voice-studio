import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_library_screen.dart';

void main() {
  testWidgets('design voice saves an AI voice', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    await tester.tap(find.text('创建音色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计音色'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('voiceNameField')), '温柔旁白');
    await tester.enterText(
      find.byKey(const Key('stylePromptField')),
      '年轻女性，温柔，清晰',
    );
    await tester.tap(find.text('生成并保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 音色'));
    await tester.pumpAndSettle();

    expect(find.text('温柔旁白'), findsOneWidget);
    expect(state.voices.any((voice) => voice.name == '温柔旁白'), isTrue);
  });
}
