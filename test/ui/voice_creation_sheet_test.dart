import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_creation_sheet.dart';

void main() {
  testWidgets('clone sheet requires name and reference audio before saving', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => VoiceCreationSheet(appState: state),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('克隆音色'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('生成并保存'));
    await tester.tap(find.text('生成并保存'));
    await tester.pump();

    expect(find.textContaining('请输入音色名称'), findsOneWidget);
  });
}
