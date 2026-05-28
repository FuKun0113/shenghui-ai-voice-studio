import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/generate/generate_screen.dart';

void main() {
  testWidgets('generates speech and shows player', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '欢迎使用 AI 语音工作台。');
    await tester.tap(find.text('生成语音'));
    await tester.pump();
    expect(find.text('生成中...'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('播放生成结果'), findsOneWidget);
    expect(state.history, hasLength(1));
  });
}
