import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/app/app_theme.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/domain/service_config.dart';
import 'package:shenghui_ai_voice_studio/src/domain/text_optimization_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/mock_mimo_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/remote_app_config_service.dart';
import 'package:shenghui_ai_voice_studio/src/services/text_optimization_service.dart';
import 'package:shenghui_ai_voice_studio/src/state/app_state.dart';
import 'package:shenghui_ai_voice_studio/src/ui/settings/settings_screen.dart';

void main() {
  Widget buildSettings(AppState state) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SettingsScreen(appState: state)),
    );
  }

  testWidgets('settings shows user-facing service options', (tester) async {
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
    expect(find.text('MiMo 服务'), findsNothing);
    expect(find.text('API URL'), findsNothing);
    expect(find.text('API Key'), findsNothing);
    expect(find.text('保存配置'), findsNothing);
  });

  testWidgets('settings shows enabled product promotion cards only', (
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
              message: '查看服务入口',
              enabled: true,
            ),
            RemoteAdSlot(
              placement: 'settings_footer',
              title: '隐藏推荐',
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
    expect(find.text('查看服务入口'), findsOneWidget);
    expect(find.text('隐藏推荐'), findsNothing);
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
    expect(find.textContaining('API URL 和 API Key'), findsOneWidget);
    expect(find.textContaining('文本转语音、音色克隆和音色设计'), findsOneWidget);
    expect(find.textContaining('兼容 API'), findsOneWidget);
    expect(find.textContaining('/chat/completions'), findsOneWidget);
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('服务地址'), findsNothing);
    expect(find.text('服务密钥'), findsNothing);
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
    final state = AppState(mimoService: MockMimoService());

    await tester.pumpWidget(buildSettings(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('文本优化服务'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '文本优化服务'), findsOneWidget);
    expect(find.textContaining('生成表演指令'), findsWidgets);
    expect(find.textContaining('OpenAI 兼容'), findsWidgets);
    expect(find.textContaining('API URL'), findsWidgets);
    expect(find.textContaining('API Key'), findsWidgets);
    expect(find.textContaining('/v1'), findsWidgets);
    expect(find.text('模型'), findsOneWidget);
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('服务地址'), findsNothing);
    expect(find.text('服务密钥'), findsNothing);
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
    expect(find.text('版本信息'), findsOneWidget);
    expect(find.text('开源仓库'), findsOneWidget);
    expect(
      find.text('https://github.com/FuKun0113/shenghui-ai-voice-studio'),
      findsOneWidget,
    );
    expect(find.text('使用建议'), findsOneWidget);
    expect(find.textContaining('正式发布'), findsNothing);
    expect(find.textContaining('预留'), findsNothing);
    expect(find.textContaining('占位'), findsNothing);
    expect(find.textContaining('SDK'), findsNothing);
    expect(find.textContaining('云端资产'), findsNothing);
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
    expect(find.textContaining('服务密钥'), findsWidgets);
    expect(find.textContaining('不会上传到声绘后台'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('内容举报与反馈'), findsNothing);
  });
}
