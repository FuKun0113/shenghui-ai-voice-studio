import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generated_audio.dart';
import 'package:voice_clone_app/src/services/audio_export_service.dart';
import 'package:voice_clone_app/src/services/audio_playback_service.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/history/history_screen.dart';

void main() {
  testWidgets('shows generated audio history and supports delete', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('历史记录测试文本');
    final generatedFuture = state.generateCurrentVoice();
    await tester.pump(const Duration(milliseconds: 200));
    await generatedFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryScreen(appState: state)),
      ),
    );
    final item = state.history.single;
    expect(
      find.byKey(ValueKey<String>('generated-audio-card-${item.id}')),
      findsOneWidget,
    );
    expect(find.text('历史记录测试文本'), findsOneWidget);

    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    expect(find.text('暂无生成记录'), findsOneWidget);
  });

  testWidgets('history audio can be played exported and shared', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('历史操作测试文本');
    final generatedFuture = state.generateCurrentVoice();
    await tester.pump(const Duration(milliseconds: 200));
    await generatedFuture;

    final playback = FakePlaybackController();
    final export = FakeExportController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            appState: state,
            playbackService: playback,
            exportService: export,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    await tester.tap(find.byTooltip('下载'));
    await tester.pump();
    await tester.tap(find.byTooltip('分享'));
    await tester.pump();

    expect(playback.playedPaths, <String>[state.history.single.audioPath]);
    expect(export.exportedIds, <String>[state.history.single.id]);
    expect(export.sharedIds, <String>[state.history.single.id]);
  });

  testWidgets('history item opens a generated audio detail page', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateStylePrompt('整体自然亲切，像熟人当面提醒。');
    state.updateDraftText('历史操作测试文本');
    final generatedFuture = state.generateCurrentVoice();
    await tester.pump(const Duration(milliseconds: 200));
    await generatedFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryScreen(appState: state)),
      ),
    );

    await tester.tap(find.text('历史操作测试文本').first);
    await tester.pumpAndSettle();

    final item = state.history.single;
    expect(find.text('语音详情'), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('generated-audio-detail-player-${item.id}')),
      findsOneWidget,
    );
    expect(find.text('生成文本'), findsOneWidget);
    expect(find.text('音色'), findsOneWidget);
    expect(find.text('表演指令'), findsOneWidget);
    expect(find.textContaining('整体自然亲切'), findsOneWidget);
    expect(find.text('历史操作测试文本'), findsWidgets);
    expect(find.byTooltip('播放'), findsOneWidget);

    await tester.tap(find.byTooltip('命名语音'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('audioTitleField')), '我的历史语音');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(state.history.single.title, '我的历史语音');
    expect(find.text('我的历史语音'), findsOneWidget);
  });

  testWidgets('history item can regenerate audio from the capsule action', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('复用文本');
    final generatedFuture = state.generateCurrentVoice();
    await tester.pump(const Duration(milliseconds: 200));
    await generatedFuture;
    final playback = FakePlaybackController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(appState: state, playbackService: playback),
        ),
      ),
    );

    await tester.tap(find.byTooltip('重生成'));
    await tester.pumpAndSettle();

    expect(state.history, hasLength(2));
    expect(state.history.first.text, '复用文本');
    expect(playback.playedPaths, <String>[state.history.first.audioPath]);
  });
}

class FakePlaybackController implements AudioPlaybackController {
  final List<String> playedPaths = <String>[];
  @override
  final ValueNotifier<AudioPlaybackSnapshot> playbackState =
      ValueNotifier<AudioPlaybackSnapshot>(const AudioPlaybackSnapshot());

  @override
  Future<void> playFile(String path) async {
    playedPaths.add(path);
    playbackState.value = AudioPlaybackSnapshot(path: path, isPlaying: true);
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

class FakeExportController implements AudioExportController {
  final List<String> exportedIds = <String>[];
  final List<String> sharedIds = <String>[];

  @override
  Future<String?> exportAudio(GeneratedAudio audio) async {
    exportedIds.add(audio.id);
    return '/downloads/${audio.id}.wav';
  }

  @override
  Future<void> shareAudio(GeneratedAudio audio) async {
    sharedIds.add(audio.id);
  }
}
