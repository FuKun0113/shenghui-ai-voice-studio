import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/history/history_screen.dart';

void main() {
  testWidgets('shows generated audio history and supports delete', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('历史记录测试文本');
    final generatedFuture = state.generateCurrentVoice();
    await tester.pump(const Duration(milliseconds: 200));
    await generatedFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryScreen(appState: state)),
      ),
    );
    expect(find.text('历史记录测试文本'), findsOneWidget);

    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    expect(find.text('暂无生成记录'), findsOneWidget);
  });
}
