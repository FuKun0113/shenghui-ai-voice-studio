import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_library_screen.dart';

void main() {
  testWidgets('shows MiMo default voices with labels', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    expect(find.text('9 个默认音色 · 0 个 AI 音色'), findsOneWidget);
    expect(find.text('MiMo-默认'), findsOneWidget);
    expect(find.text('冰糖'), findsWidgets);
    expect(find.text('官方预置'), findsWidgets);
  });

  testWidgets('design voice saves an AI voice', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    await tester.tap(find.text('创建音色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计音色'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('voiceNameField')), '温柔旁白');
    await tester.tap(find.byKey(const Key('femaleVoiceSegment')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stylePromptField')),
      '年轻女性，温柔，清晰',
    );
    await tester.tap(find.text('生成并保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 音色'));
    await tester.pumpAndSettle();

    expect(find.text('温柔旁白'), findsOneWidget);
    final created = state.voices.singleWhere((voice) => voice.name == '温柔旁白');
    expect(created.gender, '女声');
    expect(created.tags, contains('女声'));
  });

  testWidgets('clone mode explains recording and upload audio requirements', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    await tester.tap(find.text('创建音色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('克隆音色'));
    await tester.pumpAndSettle();

    expect(find.textContaining('请跟读'), findsNothing);
    expect(find.text('立即录音'), findsOneWidget);
    expect(find.textContaining('10-30 秒'), findsOneWidget);
    expect(find.textContaining('5 MB'), findsOneWidget);
    expect(find.textContaining('mp3/wav'), findsOneWidget);
  });

  testWidgets('filters by search and gender chips', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    await tester.enterText(find.byKey(const Key('voiceSearchField')), '冰糖');
    await tester.pumpAndSettle();

    expect(find.text('冰糖'), findsWidgets);
    expect(find.text('茉莉'), findsNothing);

    await tester.enterText(find.byKey(const Key('voiceSearchField')), '');
    await tester.tap(find.text('男声'));
    await tester.pumpAndSettle();

    expect(find.text('苏打'), findsOneWidget);
  });

  testWidgets('can favorite a voice', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(home: VoiceLibraryScreen(appState: state)),
    );

    await tester.tap(find.byTooltip('收藏').first);
    await tester.pumpAndSettle();

    expect(state.voices.any((voice) => voice.favorite), isTrue);
  });
}
