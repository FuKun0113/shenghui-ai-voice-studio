import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/app_shell.dart';
import 'package:shenghui_ai_voice_studio/src/app/shenghui_app.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/audio_playback_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_popup_notice_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';

void main() {
  testWidgets('bottom navigation switches between main tabs', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.text('生成'), findsWidgets);
    expect(find.byKey(const Key('draftTextField')), findsOneWidget);

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();
    expect(find.text('默认音色'), findsWidgets);

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();
    expect(find.text('暂无生成记录'), findsOneWidget);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.text('语音服务'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes a visible selected indicator', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bottomNavSelectedIndicator-0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bottomNavSelectedIndicator-1')), findsNothing);

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottomNavSelectedIndicator-0')), findsNothing);
    expect(
      find.byKey(const Key('bottomNavSelectedIndicator-1')),
      findsOneWidget,
    );
  });

  testWidgets('leaving voice library stops voice preview playback', (
    tester,
  ) async {
    final state = AppState(mimoService: MockMimoService());
    final playback = FakePlaybackController();
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(appState: state, playbackService: playback),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('播放').first);
    await tester.pumpAndSettle();

    expect(playback.playedPaths, isNotEmpty);

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();

    expect(playback.stopCount, greaterThanOrEqualTo(1));
    expect(playback.playbackState.value.path, isNull);
  });

  testWidgets('product popup notice is shown after app starts', (tester) async {
    final noticeStore = LocalPopupNoticeStore(jsonStore: MemoryJsonStore());
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          popupNotice: RemotePopupNotice(
            id: 'notice-20260531',
            title: '产品公告',
            message: '欢迎使用正式包',
            enabled: true,
          ),
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(
      ShenghuiApp(appState: state, popupNoticeStore: noticeStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('产品公告'), findsOneWidget);
    expect(find.text('欢迎使用正式包'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
  });
}

class FakePlaybackController implements AudioPlaybackController {
  @override
  final ValueNotifier<AudioPlaybackSnapshot> playbackState =
      ValueNotifier<AudioPlaybackSnapshot>(const AudioPlaybackSnapshot());

  final List<String> playedPaths = <String>[];
  int stopCount = 0;

  @override
  Future<void> playFile(String path) async {
    playedPaths.add(path);
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
    stopCount += 1;
    playbackState.value = const AudioPlaybackSnapshot();
  }

  @override
  Future<void> dispose() async {
    playbackState.dispose();
  }
}
