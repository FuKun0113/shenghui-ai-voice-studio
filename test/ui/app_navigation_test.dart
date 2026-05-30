import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/shenghui_app.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';

void main() {
  testWidgets('bottom navigation switches between main tabs', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.text('生成'), findsWidgets);
    expect(find.byKey(const Key('draftTextField')), findsOneWidget);

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();
    expect(find.text('默认音色'), findsWidgets);

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();
    expect(find.text('暂无生成记录'), findsOneWidget);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.text('语音服务'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes a visible selected indicator', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bottomNavSelectedIndicator-0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bottomNavSelectedIndicator-1')), findsNothing);

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottomNavSelectedIndicator-0')), findsNothing);
    expect(
      find.byKey(const Key('bottomNavSelectedIndicator-1')),
      findsOneWidget,
    );
  });
}
