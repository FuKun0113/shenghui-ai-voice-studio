import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/voice_clone_app.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';

void main() {
  testWidgets('app starts on generate screen', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(VoiceCloneApp(appState: state));

    expect(find.text('AI 语音工作台'), findsOneWidget);
    expect(find.text('输入文本'), findsOneWidget);
  });
}
