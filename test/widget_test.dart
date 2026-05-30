import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/shenghui_app.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';

void main() {
  testWidgets('app starts on generate screen', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mainBrandTitle')), findsOneWidget);
    expect(find.text('声绘'), findsOneWidget);
    expect(find.byKey(const Key('mainBrandIcon')), findsNothing);
    expect(find.byKey(const Key('draftTextField')), findsOneWidget);
    expect(tester.getSize(find.byType(AppBar)).height, 64);
  });
}
