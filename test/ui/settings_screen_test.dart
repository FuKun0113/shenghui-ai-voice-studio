import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/app_theme.dart';
import 'package:voice_clone_app/src/domain/remote_app_config.dart';
import 'package:voice_clone_app/src/domain/service_config.dart';
import 'package:voice_clone_app/src/domain/text_optimization_config.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/services/remote_app_config_service.dart';
import 'package:voice_clone_app/src/services/text_optimization_service.dart';
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
    expect(find.text('语音服务'), findsOneWidget);
    expect(find.text('文本优化服务'), findsOneWidget);
    expect(find.text('版权与授权声明'), findsOneWidget);
    expect(find.text('隐私与权限'), findsOneWidget);
    expect(find.text('内容举报与反馈'), findsNothing);
    expect(find.text('关于本 App'), findsOneWidget);
    expect(find.text('常驻广告位预留'), findsNothing);
    expect(find.text('MiMo 服务'), findsNothing);
    expect(find.text('API URL'), findsNothing);
    expect(find.text('保存配置'), findsNothing);
  });

  testWidgets('settings menu opens the voice service page', (tester) async {
    final state = AppState(
      mimoService: MockMimoService(),
      serviceConfig: const ServiceConfig.directApi(apiKey: 'saved-key'),
    );

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('语音服务'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '语音服务'), findsOneWidget);
    expect(find.text('语音服务'), findsOneWidget);
    expect(find.textContaining('目前默认适配小米 MiMo'), findsOneWidget);
    expect(find.textContaining('官方 API 接口和 API Key'), findsOneWidget);
    expect(find.textContaining('第三方兼容服务'), findsOneWidget);
    expect(find.textContaining('mimo-v2.5-tts'), findsOneWidget);
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('后端代理'), findsNothing);
    expect(find.text('原型直连 API Key'), findsNothing);

    final saveHeight = tester
        .getSize(find.byKey(const Key('voiceServiceSaveButton')))
        .height;
    final testHeight = tester
        .getSize(find.byKey(const Key('voiceServiceTestButton')))
        .height;
    expect(saveHeight, testHeight);
  });

  testWidgets('settings menu opens the text optimization service page', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'text_optimization_service',
              title: '文本模型推荐',
              message: '选择适合润色和标签生成的文本模型。',
              targetUrl: 'https://example.com/text-model',
              enabled: true,
            ),
            RemoteAdSlot(
              placement: 'text_optimization_service',
              title: '隐藏文本广告',
              enabled: false,
            ),
          ],
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('文本优化服务'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '文本优化服务'), findsOneWidget);
    expect(find.textContaining('生成表演指令'), findsWidgets);
    expect(find.textContaining('OpenAI 兼容'), findsWidgets);
    expect(find.textContaining('/v1'), findsWidgets);
    expect(find.text('模型'), findsOneWidget);
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('文本模型推荐'), findsOneWidget);
    expect(find.text('选择适合润色和标签生成的文本模型。'), findsOneWidget);
    expect(find.text('隐藏文本广告'), findsNothing);
    expect(find.text('广告位预留'), findsNothing);
  });

  testWidgets('settings shows enabled remote ad slot cards only', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      remoteAppConfigService: StaticRemoteAppConfigService(
        const RemoteAppConfig(
          adSlots: <RemoteAdSlot>[
            RemoteAdSlot(
              placement: 'settings_footer',
              title: '服务推荐',
              message: '领取语音服务额度',
              targetUrl: 'https://example.com/promo',
              enabled: true,
            ),
            RemoteAdSlot(
              placement: 'settings_footer',
              title: '隐藏广告',
              enabled: false,
            ),
          ],
        ),
      ),
    );
    await state.loadRemoteAppConfig();

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    expect(find.text('服务推荐'), findsOneWidget);
    expect(find.text('领取语音服务额度'), findsOneWidget);
    expect(find.text('隐藏广告'), findsNothing);
    expect(find.text('常驻广告位预留'), findsNothing);
  });

  testWidgets('saved text optimization model remains selectable', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      textOptimizationConfig: const TextOptimizationConfig(
        model: 'compatible-text-model',
      ),
    );

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('文本优化服务'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('textOptimizationModelSelector')),
      findsOneWidget,
    );
    expect(find.text('compatible-text-model'), findsOneWidget);

    await tester.tap(find.byKey(const Key('textOptimizationModelSelector')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('modelSelectorSheet')), findsOneWidget);
    expect(find.text('compatible-text-model'), findsWidgets);
  });

  testWidgets('text optimization page fetches models for selection', (
    tester,
  ) async {
    final state = AppState(
      mimoService: MockMimoService(),
      textOptimizationService: MockTextOptimizationService(),
    );

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('文本优化服务'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('fetchTextOptimizationModelsButton')),
    );
    await tester.pump();
    expect(find.text('获取中'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(
      find.byKey(const Key('textOptimizationModelSelector')),
      findsOneWidget,
    );
    expect(find.text('gpt-4o-mini'), findsWidgets);
    expect(find.textContaining('已获取'), findsOneWidget);

    final modelHeight = tester
        .getSize(find.byKey(const Key('textOptimizationModelSelector')))
        .height;
    final fetchHeight = tester
        .getSize(find.byKey(const Key('fetchTextOptimizationModelsButton')))
        .height;
    expect(modelHeight, fetchHeight);

    await tester.tap(find.byKey(const Key('textOptimizationModelSelector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSelectorSheet')), findsOneWidget);
    expect(find.text('compatible-text-model'), findsOneWidget);
  });

  testWidgets('settings detail pages open as separate screens', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('关于本 App'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '关于声绘'), findsOneWidget);
    expect(find.byKey(const Key('aboutAppIcon')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('版权与授权声明'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '版权与授权声明'), findsOneWidget);
    expect(find.text('版权与授权声明'), findsOneWidget);
    expect(find.textContaining('未经授权'), findsWidgets);
    expect(find.textContaining('用户自行承担'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('隐私与权限'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '隐私与权限'), findsOneWidget);
    expect(find.text('隐私与权限'), findsOneWidget);
    expect(find.textContaining('录音'), findsWidgets);
    expect(find.textContaining('本地存储'), findsWidgets);
    expect(find.textContaining('API Key'), findsWidgets);
    expect(find.textContaining('不会上传到声绘后台'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('内容举报与反馈'), findsNothing);
  });
}
