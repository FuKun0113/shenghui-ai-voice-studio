# 声绘 AI Voice Studio

声绘是一款基于 Flutter 的 AI 语音生成、音色设计与声音克隆应用。项目面向 Android 优先开发，同时保留 iOS、macOS、Web 等 Flutter 多端扩展能力。

English keywords: Flutter AI voice studio, TTS, voice cloning, speech synthesis, voice design, OpenAI-compatible API.

## 功能特性

- AI 语音生成：输入文本后生成语音，支持历史记录、播放、下载、分享、删除和重生成。
- 音色库：内置官方音色、自定义音色、收藏音色和分类筛选。
- 音色设计：通过音色描述生成试听，并保存为可复用音色。
- 声音克隆：支持录音或上传参考音频，生成自定义音色。
- 高级标签：支持在文本中插入风格标签、音频标签和方言标签，并在页面中高亮渲染。
- 文档导入：支持 TXT、Word、PDF 文档文本提取，用于分段语音生成。
- 文本优化服务：支持 OpenAI 兼容接口，用于生成表演指令、优化文本和补充标签。
- 版本与公告配置：源码默认关闭远程配置；官方 APK 可通过构建参数启用。

## 技术栈

- Flutter / Dart
- Android 原生构建链路
- Optional Cloudflare R2 JSON remote config
- OpenAI-compatible HTTP API
- MiMo-compatible speech synthesis API

## 快速开始

```bash
flutter pub get
flutter run
```

源码默认构建不启用远程配置：

```bash
flutter build apk --release
```

官方发布包可通过构建参数启用版本与公告配置：

```bash
flutter build apk --release \
  --dart-define=SHENGHUI_OFFICIAL_BUILD=true \
  --dart-define=SHENGHUI_BUILD_CHANNEL=github-release \
  --dart-define=SHENGHUI_REMOTE_CONFIG_URL=https://your-domain.example/shenghui-config.json
```

## 服务配置

App 不内置语音服务或文本优化服务的私有 API Key。用户在本地设置页中填写自己的 API URL 和 API Key，配置保存在设备本地。

语音服务需要提供兼容项目当前调用方式的语音生成、音色设计和声音克隆模型。文本优化服务使用 OpenAI 兼容接口，用于辅助生成表演指令、改写文本和插入语音标签。

## 远程配置

公开仓库只保留关闭状态的示例配置：

```text
config/shenghui-config.example.json
```

真实配置建议放在私有 ops 仓库、私有存储桶或发布流水线 Secrets 中，不提交到开源源码。配置说明见：

```text
docs/official-build-config.md
```

远程配置只应保存公开的弹窗通知和版本更新策略。不要把 API Key、签名密钥、用户隐私数据写入远程配置文件。

## 合规提醒

声音克隆功能只应用于用户本人声音，或已经获得明确授权的声音。请勿使用本项目克隆、合成或传播他人声音，尤其是公众人物、未成年人或未授权个人的声音。使用者需要自行承担由内容生成、传播和授权问题带来的法律责任。

## 开源协议

本项目使用 MIT License。详见 `LICENSE`。

## Topics

`flutter` `dart` `tts` `voice-cloning` `ai-voice` `speech-synthesis` `android` `mimo` `openai-compatible`
