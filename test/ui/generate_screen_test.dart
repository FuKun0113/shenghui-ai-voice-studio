import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/service_config.dart';
import 'package:voice_clone_app/src/services/audio_playback_service.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/generate/generate_screen.dart';

void main() {
  testWidgets('generates speech and shows player', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateServiceConfig(
      const ServiceConfig.directApi(apiKey: 'test-key'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenerateScreen(
            appState: state,
            playbackService: FakePlaybackController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('voiceSelectorField')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('上传文档'), findsOneWidget);
    expect(find.text('插入标签'), findsOneWidget);
    expect(find.text('表演指令'), findsOneWidget);
    expect(find.text('表演指令 / Instruct'), findsNothing);
    expect(find.textContaining('role:user'), findsNothing);
    expect(find.text('温柔'), findsNothing);
    expect(find.text('粤语'), findsNothing);
    expect(find.text('四川话'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '欢迎使用 AI 语音工作台。');
    await tester.tap(find.text('生成语音'));
    await tester.pump();
    expect(find.text('生成中...'), findsOneWidget);
    expect(
      find.byKey(const Key('generationButtonActivityIcon')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('generationActivityStrip')), findsNothing);

    await tester.pumpAndSettle();
    final item = state.history.single;
    expect(
      find.byKey(ValueKey<String>('generated-audio-card-${item.id}')),
      findsOneWidget,
    );
    expect(find.text('欢迎使用 AI 语音工作台。'), findsWidgets);
    expect(find.byTooltip('暂停'), findsOneWidget);
    expect(find.byTooltip('重生成'), findsOneWidget);
    expect(state.history, hasLength(1));
  });

  testWidgets('missing api key offers settings guidance', (tester) async {
    var openedSettings = false;
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('测试文本');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenerateScreen(
            appState: state,
            onOpenSettings: () => openedSettings = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('生成语音'));
    await tester.pumpAndSettle();

    expect(find.textContaining('请先填写语音服务 API Key'), findsOneWidget);
    expect(openedSettings, isFalse);

    await tester.tap(find.text('去设置'));
    await tester.pump();

    expect(openedSettings, isTrue);
  });

  testWidgets('long text shows segment controls', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateServiceConfig(
      const ServiceConfig.directApi(apiKey: 'test-key'),
    );
    state.updateDraftText('第一段内容\n\n第二段内容'.padRight(260, '长'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('已分为'), findsOneWidget);
    expect(find.text('生成全部'), findsOneWidget);
  });

  testWidgets('draft and instruct fields can open fullscreen editors', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('全屏编辑输入文本'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('全屏编辑输入文本'));
    await tester.pumpAndSettle();
    expect(find.text('全屏编辑输入文本'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('fullscreenTextEditorField')),
      '全屏输入后的正文',
    );
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(state.draftText, '全屏输入后的正文');

    await tester.ensureVisible(find.text('表演指令'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('表演指令'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('全屏编辑表演指令'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('全屏编辑表演指令'));
    await tester.pumpAndSettle();
    expect(find.text('全屏编辑表演指令'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('fullscreenTextEditorField')),
      '全屏输入后的表演指令',
    );
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(state.stylePrompt, '全屏输入后的表演指令');
  });

  testWidgets('fullscreen draft editor can insert repeatable tags', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('欢迎使用 AI 语音工作台。');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('全屏编辑输入文本'));
    await tester.tap(find.byTooltip('全屏编辑输入文本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('插入标签'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('粤语'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('插入标签'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('轻笑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(state.draftText, '(粤语)欢迎使用 AI 语音工作台。[轻笑]');
  });

  testWidgets('long draft warns about the 8K token context limit', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('长' * 6500);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('8K token'), findsOneWidget);
    expect(find.textContaining('建议分段生成'), findsOneWidget);
  });

  testWidgets('tag insert sheet inserts repeatable style and audio tags', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    final draftField = find.byKey(const Key('draftTextField'));
    await tester.enterText(draftField, '欢迎使用 AI 语音工作台。');
    await tester.tap(find.text('插入标签'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('粤语'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('插入标签'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('粤语'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('插入标签'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('轻笑'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(draftField);
    expect(textField.controller?.text, '(粤语 粤语)欢迎使用 AI 语音工作台。[轻笑]');
    expect(state.draftText, '(粤语 粤语)欢迎使用 AI 语音工作台。[轻笑]');
  });

  testWidgets('tag guide opens and applies an advanced example', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerateScreen(appState: state)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('高级案例'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '标签与高级案例'), findsOneWidget);
    expect(find.text('风格标签'), findsOneWidget);
    expect(find.text('音频标签'), findsOneWidget);
    expect(find.text('沧桑老前辈叙事'), findsOneWidget);
    expect(find.textContaining('低沉沙哑、娓娓道来'), findsOneWidget);
    expect(find.textContaining('MiMo V2.5'), findsNothing);
    expect(find.textContaining('Case1'), findsNothing);
    expect(find.text('基础情绪'), findsNothing);

    await tester.tap(find.text('沧桑老前辈叙事'));
    await tester.pumpAndSettle();
    expect(find.text('案例详情'), findsOneWidget);
    expect(find.textContaining('1970年'), findsNothing);
    expect(find.textContaining('MiMo V2.5'), findsNothing);
    expect(find.textContaining('Case1'), findsNothing);
    expect(find.text('删除'), findsNothing);
    expect(find.text('重生成'), findsNothing);
    expect(find.text('套用文本'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('useMimoExample-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('useMimoExample-0')));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('draftTextField')),
    );
    expect(textField.controller?.text, contains('街口那个老周'));
    expect(state.stylePrompt, contains('声音低沉沙哑'));
    expect(state.draftText, textField.controller?.text);
  });
}

class FakePlaybackController implements AudioPlaybackController {
  @override
  final ValueNotifier<AudioPlaybackSnapshot> playbackState =
      ValueNotifier<AudioPlaybackSnapshot>(const AudioPlaybackSnapshot());

  @override
  Future<void> playFile(String path) async {
    playbackState.value = AudioPlaybackSnapshot(
      path: path,
      isPlaying: true,
      position: Duration.zero,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Future<void> pause() async {
    playbackState.value = playbackState.value.copyWith(isPlaying: false);
  }

  @override
  Future<void> stop() async {
    playbackState.value = const AudioPlaybackSnapshot();
  }

  @override
  Future<void> dispose() async {
    playbackState.dispose();
  }
}
