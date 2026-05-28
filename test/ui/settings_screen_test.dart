import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/settings/settings_screen.dart';

void main() {
  testWidgets('settings shows backend and direct api options', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SettingsScreen(appState: state))),
    );

    expect(find.text('MiMo 服务'), findsOneWidget);
    expect(find.text('后端代理'), findsOneWidget);
    expect(find.text('原型直连 API Key'), findsOneWidget);
    expect(find.text('授权和隐私'), findsOneWidget);
  });
}
