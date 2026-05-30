import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/shenghui_app.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
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

  testWidgets('remote popup notice is shown after app starts', (tester) async {
    final noticeStore = LocalPopupNoticeStore(jsonStore: MemoryJsonStore());
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          popupNotice: RemotePopupNotice(
            id: 'maintenance-20260530',
            title: '维护提醒',
            message: '今晚 23:00 后可能短暂不可用',
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

    expect(find.text('维护提醒'), findsOneWidget);
    expect(find.text('今晚 23:00 后可能短暂不可用'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
  });

  testWidgets('acknowledged remote popup notice is not shown again', (
    tester,
  ) async {
    final noticeStore = LocalPopupNoticeStore(jsonStore: MemoryJsonStore());
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          popupNotice: RemotePopupNotice(
            id: 'maintenance-20260530',
            title: '维护提醒',
            message: '今晚 23:00 后可能短暂不可用',
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
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      ShenghuiApp(
        key: UniqueKey(),
        appState: state,
        popupNoticeStore: noticeStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('维护提醒'), findsNothing);
  });

  testWidgets('force update policy blocks the app with update dialog', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          updatePolicy: RemoteUpdatePolicy(
            minSupportedVersion: '2.0.0',
            forceUpdate: true,
            updateUrl: 'https://example.com/download',
          ),
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(ShenghuiApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.text('需要更新声绘'), findsOneWidget);
    expect(find.textContaining('当前版本已不可用'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
  });
}
