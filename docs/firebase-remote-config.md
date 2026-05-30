# 官方构建与远程配置说明

声绘开源源码默认不启用推广位、弹窗运营配置、强制更新策略或匿名统计。只有官方发布包在构建时显式传入开关和地址后，才会启用这些运营能力。

## 构建开关

默认构建：

```bash
flutter build apk --release
```

默认构建行为：

- 不初始化 Firebase。
- 不读取 Firebase Remote Config。
- 不读取 R2 / OSS / CDN JSON 配置。
- 不展示远程推广位。
- 不展示远程弹窗通知。
- 不上报匿名统计。

官方发布包：

```bash
flutter build apk --release --no-pub \
  --dart-define=SHENGHUI_OFFICIAL_BUILD=true \
  --dart-define=SHENGHUI_BUILD_CHANNEL=github-release \
  --dart-define=SHENGHUI_REMOTE_CONFIG_URL=https://your-domain.example/shenghui-config.json \
  --dart-define=SHENGHUI_ANALYTICS_ENDPOINT=https://your-domain.example/events
```

字段说明：

- `SHENGHUI_OFFICIAL_BUILD`: 设为 `true` 后启用官方运营能力。
- `SHENGHUI_BUILD_CHANNEL`: 发布渠道标识，例如 `github-release`、`play-store`、`internal-test`。
- `SHENGHUI_REMOTE_CONFIG_URL`: 官方远程配置 JSON 地址。建议使用 R2 自定义域名、OSS、COS、七牛云或自己的 API 服务。
- `SHENGHUI_ANALYTICS_ENDPOINT`: 官方匿名统计接口地址。不传则不会上报统计。

## 公开仓库配置

公开仓库只保留示例配置：

```text
config/shenghui-config.example.json
```

示例配置必须保持关闭状态，用于说明字段结构，不承载真实推广内容。

不要把这些内容提交到开源仓库：

- 真实推广链接。
- 真实弹窗运营内容。
- 真实强制更新策略。
- API Key、签名密钥、R2 Secret、用户隐私数据。

真实运营配置建议放在私有 ops 仓库、私有存储桶、后台管理系统或发布流水线 Secrets 中。

## 远程配置优先级

官方构建启用后，App 的远程配置优先级是：

1. `SHENGHUI_REMOTE_CONFIG_URL` 指向的国内 JSON 配置。
2. Firebase Remote Config。
3. 空配置兜底。

如果不是官方构建，App 直接使用空配置兜底。

接口返回非 2xx、超时或 JSON 解析失败时，会自动回退 Firebase；如果 Firebase 不可用，则继续使用空配置，App 仍可正常启动。

## JSON 示例

```json
{
  "ad_slots": [
    {
      "placement": "settings_footer",
      "title": "设置页推荐",
      "message": "这里填写官方构建展示的推荐内容。",
      "target_url": "https://example.com/promo",
      "enabled": true
    },
    {
      "placement": "voice_service",
      "title": "语音服务推荐",
      "message": "这里填写语音服务页的推荐内容。",
      "target_url": "https://example.com/voice-service",
      "enabled": true
    },
    {
      "placement": "text_optimization_service",
      "title": "文本模型推荐",
      "message": "这里填写文本优化服务页的推荐内容。",
      "target_url": "https://example.com/text-model",
      "enabled": true
    }
  ],
  "popup_notice": {
    "id": "notice-20260530",
    "title": "服务提醒",
    "message": "这里填写官方弹窗通知。",
    "target_url": "https://example.com/status",
    "enabled": true
  },
  "latest_version": "1.0.1",
  "min_supported_version": "1.0.0",
  "force_update": false,
  "update_url": "https://example.com/download"
}
```

## 配置字段

### `ad_slots`

用于官方构建的推荐位。目前已接入：

- `settings_footer`: 设置中心底部推荐卡片。
- `voice_service`: 语音服务详情页推荐卡片。
- `text_optimization_service`: 文本优化服务详情页推荐卡片。

字段说明：

- `placement`: 位置标识。
- `title`: 标题。
- `message`: 说明。
- `target_url`: 点击后打开的外部链接。
- `enabled`: 是否显示。

`enabled=false` 或 `placement` 不匹配时，App 会隐藏该位置。

### `popup_notice`

用于官方构建启动后的弹窗通知。字段说明：

- `id`: 通知唯一标识。用户点过“知道了”或“查看”后，同一个 `id` 不会再次弹出。
- `title`: 弹窗标题。
- `message`: 弹窗正文。
- `target_url`: 可选，非空时显示“查看”按钮。
- `enabled`: 是否显示。

如果没有填写 `id`，App 会用 `title + message + target_url` 作为兜底标识；内容变化后会被视为新通知。

### 版本更新字段

- `latest_version`: 最新可用版本号，例如 `1.0.1`。
- `min_supported_version`: 最低可用版本号。
- `force_update`: 是否启用强制更新。
- `update_url`: 更新按钮打开的下载地址或应用商店地址。

强制更新判断：

```text
force_update == true
并且 currentVersionName < min_supported_version
```

可选更新判断：

```text
currentVersionName < latest_version
```

## 匿名统计接口

官方构建传入 `SHENGHUI_ANALYTICS_ENDPOINT` 后，App 每天最多上报一次 `app_open` 事件。

请求示例：

```json
{
  "event": "app_open",
  "install_id_hash": "sha256-hash",
  "version": "1.0.0",
  "build_number": "8",
  "platform": "android",
  "channel": "github-release",
  "day": "2026-05-30"
}
```

统计接口建议返回任意 2xx 状态码。上报失败不会影响 App 启动或用户操作。

匿名统计不要收集：

- 用户输入文本。
- 用户生成音频。
- 用户上传音频。
- 用户 API Key。
- 手机号、邮箱、真实姓名等个人身份信息。

## Firebase 说明

Firebase 现在只作为官方构建的远程配置回退通道。公开源码默认不会初始化 Firebase，也不会读取 Firebase Remote Config。

Firebase 的 Android 应用别名只是控制台展示名，不会写入 `android/app/google-services.json`，也不影响包名 `com.yunque.shenghui`。
