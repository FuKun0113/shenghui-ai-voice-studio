import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/app_theme.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/generate/generate_screen.dart';

void main() {
  testWidgets('generate screen shows polished workspace sections', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('文本生成'), findsOneWidget);
    expect(find.text('当前音色'), findsOneWidget);
    expect(find.text('风格提示'), findsOneWidget);
    expect(find.text('声音参数'), findsNothing);
  });
}
