import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/audio_input_service.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_creation_sheet.dart';

void main() {
  Widget buildSheet(AppState state, {AudioInputController? audioInputService}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => VoiceCreationSheet(
                appState: state,
                audioInputService: audioInputService,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('design mode guides users to write professional voice prompts', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(buildSheet(state));

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
    await tester.pumpWidget(buildSheet(state));

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
    await tester.pumpWidget(buildSheet(state));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('克隆音色'));
    await tester.pumpAndSettle();

    expect(find.text('生成试听'), findsOneWidget);
    expect(find.text('播放试听'), findsOneWidget);
  });

  testWidgets(
    'clone mode removes authorization card and overlays requirements while recording',
    (tester) async {
      final state = AppState(mimoService: MockMimoService());
      await tester.pumpWidget(
        buildSheet(state, audioInputService: FakeAudioInputController()),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('克隆音色'));
      await tester.pumpAndSettle();
      expect(find.textContaining('合法授权'), findsNothing);
      expect(find.text('上传音频要求'), findsOneWidget);

      await tester.ensureVisible(find.text('立即录音'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('立即录音'));
      await tester.pumpAndSettle();

      expect(find.text('上传音频要求'), findsNothing);
      expect(find.text('正在录音，请自然朗读'), findsOneWidget);
      expect(find.textContaining('今天阳光很好'), findsOneWidget);
      expect(find.textContaining('请跟读：'), findsNothing);
    },
  );
}

class FakeAudioInputController implements AudioInputController {
  @override
  Future<void> dispose() async {}

  @override
  Future<String?> pickReferenceAudio() async => null;

  @override
  Future<String> startRecording() async => '/tmp/reference.wav';

  @override
  Future<String?> stopRecording() async => '/tmp/reference.wav';
}
