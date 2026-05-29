import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/app_theme.dart';
import 'package:voice_clone_app/src/domain/service_config.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/settings/settings_screen.dart';

void main() {
  Widget buildSettings(AppState state) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SettingsScreen(appState: state)),
    );
  }

  testWidgets('settings shows backend and direct api options', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    expect(find.text('设置中心'), findsOneWidget);
    expect(find.text('MiMo 服务'), findsOneWidget);
    expect(find.text('关于本 App'), findsOneWidget);
    expect(find.text('版权与授权声明'), findsOneWidget);
    expect(find.text('隐私与权限'), findsOneWidget);
    expect(find.text('常驻广告位预留'), findsOneWidget);
    expect(find.text('API URL'), findsNothing);
    expect(find.text('保存配置'), findsNothing);
  });

  testWidgets('settings menu opens the MiMo service page', (tester) async {
    final state = AppState(
      mimoService: MockMimoService(),
      serviceConfig: const ServiceConfig.directApi(apiKey: 'saved-key'),
    );

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MiMo 服务'));
    await tester.pumpAndSettle();
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('后端代理'), findsOneWidget);
    expect(find.text('原型直连 API Key'), findsOneWidget);
  });

  testWidgets('settings detail pages open as separate screens', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('关于本 App'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '关于 AI 语音工作台'), findsOneWidget);
    expect(find.textContaining('MiMo'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('版权与授权声明'));
    await tester.pumpAndSettle();
    expect(find.text('版权与授权声明'), findsWidgets);
    expect(find.textContaining('未经授权'), findsWidgets);
    expect(find.textContaining('用户自行承担'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('隐私与权限'));
    await tester.pumpAndSettle();
    expect(find.text('隐私与权限'), findsWidgets);
    expect(find.textContaining('录音'), findsWidgets);
    expect(find.textContaining('本地存储'), findsWidgets);
  });
}
