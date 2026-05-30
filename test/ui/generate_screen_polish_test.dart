import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/app_theme.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';
import 'package:shenghui_ai_voice_studio/src/ui/generate/generate_screen.dart';

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
    expect(find.text('表演指令'), findsOneWidget);
    expect(find.text('表演指令 / Instruct'), findsNothing);
    expect(find.text('声音参数'), findsNothing);

    final voiceSelectorPanelHeight = tester
        .getSize(find.byKey(const Key('voiceSelectorPanel')))
        .height;
    expect(voiceSelectorPanelHeight, lessThanOrEqualTo(132));
  });
}
