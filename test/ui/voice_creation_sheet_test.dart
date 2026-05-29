import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_creation_sheet.dart';

void main() {
  testWidgets('design mode guides users to write professional voice prompts', (
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

    expect(find.textContaining('合法授权'), findsNothing);
    expect(find.textContaining('不会克隆'), findsNothing);
    expect(find.text('写作维度'), findsOneWidget);
    expect(find.text('性别/年龄'), findsOneWidget);
    expect(find.text('音色/质感'), findsOneWidget);
    expect(find.text('角色/人设'), findsOneWidget);
    expect(find.textContaining('不要写混响'), findsOneWidget);

    await tester.ensureVisible(find.text('专业示例'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('专业示例'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('stylePromptField')),
    );
    expect(field.controller?.text, contains('年迈的老先生'));
  });

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

  testWidgets('clone mode offers generated preview controls before saving', (
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

    expect(find.text('生成试听'), findsOneWidget);
    expect(find.text('播放试听'), findsOneWidget);
  });

  testWidgets('clone mode requires explicit authorization confirmation', (
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
    expect(find.textContaining('合法授权'), findsWidgets);
    await tester.enterText(find.byKey(const Key('voiceNameField')), '授权测试');
    await tester.ensureVisible(find.text('生成并保存'));
    await tester.tap(find.text('生成并保存'));
    await tester.pump();

    expect(find.textContaining('请先确认拥有合法授权'), findsOneWidget);
    expect(find.textContaining('不克隆或冒用他人声音'), findsOneWidget);
  });
}
