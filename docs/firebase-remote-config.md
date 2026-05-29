# 远程配置参数说明

声绘当前使用双通道远程配置管理启动弹窗、版本更新策略、设置页广告位和语音服务推广入口。国内 JSON 配置接口优先，访问失败后再回退 Firebase Remote Config；未配置或配置为禁用时，App 会自动隐藏对应入口。

## 国内配置通道

构建时通过 `--dart-define` 指定国内可访问的 JSON 配置地址：

```bash
flutter build apk --release \
  --dart-define=SHENGHUI_REMOTE_CONFIG_URL=https://your-domain.com/shenghui-config.json
```

如果不传 `SHENGHUI_REMOTE_CONFIG_URL`，App 会直接使用 Firebase Remote Config。国内配置接口建议放在阿里云、腾讯云、华为云、七牛云、Cloudflare R2 自定义域名或自己的服务器上，只返回公开配置，不要放任何 API Key。

国内 JSON 配置使用标准 JSON 类型，示例：

```json
{
  "ad_slots": [
    {
      "placement": "settings_footer",
      "title": "语音服务推荐",
      "message": "领取语音生成 API 额度",
      "target_url": "https://example.com/promo",
      "enabled": true
    },
    {
      "placement": "text_optimization_service",
      "title": "文本模型推荐",
      "message": "选择适合润色和标签生成的文本模型。",
      "target_url": "https://example.com/text-model",
      "enabled": true
    }
  ],
  "popup_notice": {
    "title": "维护提醒",
    "message": "今晚 23:00 后服务可能短暂不可用。",
    "target_url": "https://example.com/status",
    "enabled": true
  },
  "promo_link": "https://example.com/register",
  "latest_version_code": 8,
  "min_supported_version_code": 6,
  "force_update": true,
  "update_url": "https://example.com/download"
}
```

接口返回非 2xx、超时、JSON 解析失败时，会自动回退 Firebase。

## 拉取策略

- 国内配置接口超时：4 秒。
- Firebase `fetchTimeout`: 8 秒。
- Firebase `minimumFetchInterval`: 1 小时。
- 拉取失败时使用空配置，不阻塞 App 启动。

## Firebase 参数列表

Firebase Remote Config 的复杂字段以字符串保存；数字和布尔值使用 Remote Config 原生类型。

### `ad_slots`

类型：字符串，内容为 JSON 数组。

用于设置页和服务详情页广告位。目前已接入的 `placement`：

- `settings_footer`: 设置中心底部广告卡片。
- `text_optimization_service`: 文本优化服务详情页广告卡片。

示例：

```json
[
  {
    "placement": "settings_footer",
    "title": "语音服务推荐",
    "message": "领取语音生成 API 额度",
    "target_url": "https://example.com/promo",
    "enabled": true
  },
  {
    "placement": "text_optimization_service",
    "title": "文本模型推荐",
    "message": "选择适合润色和标签生成的文本模型。",
    "target_url": "https://example.com/text-model",
    "enabled": true
  }
]
```

### `popup_notice`

类型：字符串，内容为 JSON 对象。

用于 App 启动后的弹窗通知。`enabled` 为 `false` 或未设置时不显示。

示例：

```json
{
  "title": "维护提醒",
  "message": "今晚 23:00 后服务可能短暂不可用。",
  "target_url": "https://example.com/status",
  "enabled": true
}
```

### `promo_link`

类型：字符串。

用于语音服务设置页的推广入口。如果为空，入口隐藏。

示例：

```text
https://example.com/register
```

### 版本更新参数

`latest_version_code`

类型：数字。高于当前 App build number 时显示可选更新弹窗。

`min_supported_version_code`

类型：数字。当前 App build number 低于该值，且 `force_update` 为 `true` 时显示强制更新弹窗。

`force_update`

类型：布尔值。是否启用强制更新。

`update_url`

类型：字符串。更新按钮打开的下载地址或应用商店地址。

示例：

```text
latest_version_code = 8
min_supported_version_code = 6
force_update = true
update_url = https://example.com/download
```
