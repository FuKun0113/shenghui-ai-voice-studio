import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/voice_clone_app.dart';
import 'package:voice_clone_app/src/domain/remote_app_config.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/services/remote_app_config_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';

void main() {
  testWidgets('bottom navigation switches between main tabs', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(VoiceCloneApp(appState: state));
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
    await tester.pumpWidget(VoiceCloneApp(appState: state));
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

  testWidgets('remote popup notice is shown after app starts', (tester) async {
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          popupNotice: RemotePopupNotice(
            title: '维护提醒',
            message: '今晚 23:00 后可能短暂不可用',
            enabled: true,
          ),
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(VoiceCloneApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.text('维护提醒'), findsOneWidget);
    expect(find.text('今晚 23:00 后可能短暂不可用'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
  });

  testWidgets('force update policy blocks the app with update dialog', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          updatePolicy: RemoteUpdatePolicy(
            minSupportedVersionCode: 2,
            forceUpdate: true,
            updateUrl: 'https://example.com/download',
          ),
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(VoiceCloneApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.text('需要更新声绘'), findsOneWidget);
    expect(find.textContaining('当前版本已不可用'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
  });
}
