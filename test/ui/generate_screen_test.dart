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
    expect(find.text('温柔'), findsOneWidget);
    expect(find.text('粤语'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '欢迎使用 AI 语音工作台。');
    await tester.tap(find.text('生成语音'));
    await tester.pump();
    expect(find.text('生成中...'), findsOneWidget);

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

    expect(find.textContaining('请先填写 MiMo API Key'), findsOneWidget);
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
