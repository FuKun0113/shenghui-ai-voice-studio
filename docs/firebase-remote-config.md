# 远程配置参数说明

声绘当前使用“双通道远程配置”管理启动弹窗、版本更新策略和三个广告位。

配置文件由 GitHub 管理，发布出口使用 Cloudflare R2：

- GitHub 文件：`config/shenghui-config.json`
- R2 公开地址：`https://shenghuiconfig.cloudlark.net/shenghui-config.json`
- GitHub Actions：`.github/workflows/publish-remote-config.yml`

优先级：

1. 国内 JSON 配置接口，例如 Cloudflare R2 自定义域名。
2. Firebase Remote Config。
3. 空配置兜底，所有广告、弹窗和更新提示隐藏。

远程配置只放公开运营配置，不要放任何 API Key、签名密钥或用户隐私数据。

## 国内配置通道

当前 R2 配置地址：

```text
https://shenghuiconfig.cloudlark.net/shenghui-config.json
```

构建时通过 `--dart-define` 写入国内 JSON 地址：

```bash
flutter build apk --release --no-pub \
  --dart-define=SHENGHUI_REMOTE_CONFIG_URL=https://shenghuiconfig.cloudlark.net/shenghui-config.json
```

如果不传 `SHENGHUI_REMOTE_CONFIG_URL`，App 会直接使用 Firebase Remote Config。国内配置接口建议放在 Cloudflare R2 自定义域名、阿里云 OSS、腾讯云 COS、七牛云或自己的服务器上，并确保 URL 可以公网访问。

接口返回非 2xx、超时、JSON 解析失败时，会自动回退 Firebase。

## GitHub 管理和自动发布

日常运营时，不需要手动进入 R2 后台改文件。推荐流程：

1. 修改 `config/shenghui-config.json`。
2. 提交到 GitHub。
3. GitHub Actions 自动校验 JSON。
4. 校验通过后自动上传到 R2 的 `shenghui-config.json`。
5. App 继续读取原来的 R2 公开地址。

这样既有 GitHub 版本历史、差异对比和回滚能力，又保留 R2 面向用户访问的稳定性。

### GitHub Secrets

发布工作流需要在 GitHub 仓库中配置这些 Secrets：

```text
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_BUCKET
```

配置路径：

```text
GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret
```

字段说明：

- `R2_ACCOUNT_ID`: Cloudflare 账号 ID。
- `R2_ACCESS_KEY_ID`: R2 API Token 的 Access Key ID。
- `R2_SECRET_ACCESS_KEY`: R2 API Token 的 Secret Access Key。
- `R2_BUCKET`: R2 存储桶名称。

R2 Token 建议只给目标 bucket 的对象读写权限，不要使用全账号最高权限 Token。

### 手动发布

如果没有改文件但想重新发布一次，可以在 GitHub：

```text
Actions → Publish Remote Config → Run workflow
```

## 国内 JSON 示例

R2 文件使用标准 JSON 类型，推荐结构如下：

```json
{
  "ad_slots": [
    {
      "placement": "settings_footer",
      "title": "设置页推荐",
      "message": "领取语音生成 API 额度",
      "target_url": "https://example.com/promo",
      "enabled": true
    },
    {
      "placement": "voice_service",
      "title": "语音服务推荐",
      "message": "申请或管理语音生成 API 额度。",
      "target_url": "https://example.com/voice-service",
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
    "id": "maintenance-20260530",
    "title": "维护提醒",
    "message": "今晚 23:00 后服务可能短暂不可用。",
    "target_url": "https://example.com/status",
    "enabled": true
  },
  "latest_version": "1.0.0",
  "min_supported_version": "1.0.0",
  "force_update": true,
  "update_url": "https://example.com/download"
}
```

测试阶段如果不想触发强制更新，可以先使用：

```json
{
  "latest_version": "1.0.0",
  "min_supported_version": "0.0.0",
  "force_update": false
}
```

## 拉取策略

- 国内 JSON 接口超时：4 秒。
- Firebase `fetchTimeout`: 8 秒。
- Firebase `minimumFetchInterval`: 1 小时。
- 远程配置异步拉取，不阻塞 App 首屏启动。
- 拉取失败时使用空配置，App 继续可用。

## 配置字段

### `ad_slots`

类型：数组。Firebase Remote Config 中使用 JSON 字符串保存。

用于页面广告位。目前已接入的 `placement`：

- `settings_footer`: 设置中心底部广告卡片。
- `voice_service`: 语音服务详情页广告卡片。
- `text_optimization_service`: 文本优化服务详情页广告卡片。

字段说明：

- `placement`: 广告位置标识。
- `title`: 广告标题。
- `message`: 广告说明。
- `target_url`: 点击后打开的外部链接。
- `enabled`: 是否显示。

`enabled` 为 `false` 或 `placement` 不匹配时，App 会隐藏该广告位。

### `popup_notice`

类型：对象。Firebase Remote Config 中使用 JSON 字符串保存。

用于 App 启动后的弹窗通知。`enabled` 为 `false` 或未设置时不显示。

字段说明：

- `id`: 通知唯一标识。建议每次发布新通知时递增或更换，例如 `maintenance-20260530`。用户点过“知道了”或“查看”后，同一个 `id` 不会再次弹出。
- `title`: 弹窗标题。
- `message`: 弹窗正文。
- `target_url`: 可选，非空时显示“查看”按钮。
- `enabled`: 是否显示。

如果没有填写 `id`，App 会用 `title + message + target_url` 作为兜底标识；内容不变就只弹一次，内容变化后会被视为新通知。

### 版本更新字段

推荐使用用户可见版本号管理更新，例如 `1.0.0`、`1.0.1`、`1.1.0`。

- `latest_version`: 最新可用版本号。高于当前 App 版本时显示可选更新弹窗。
- `min_supported_version`: 最低可用版本号。
- `force_update`: 是否启用强制更新。
- `update_url`: 更新按钮打开的下载地址或应用商店地址。

仍然兼容旧字段 `latest_version_code` 和 `min_supported_version_code`，但后续建议只维护版本号字符串，运营时更直观。

强制更新判断：

```text
force_update == true
并且 currentVersionName < min_supported_version
```

可选更新判断：

```text
currentVersionName < latest_version
```

当前测试包使用：

```text
versionName = 1.0.0
```

因此如果 R2 中保持：

```json
{
  "latest_version": "1.0.0",
  "min_supported_version": "1.0.0",
  "force_update": true
}
```

当前 `versionName=1.0.0` 的包不会被拦住。如果以后发布 `1.0.1`，可以把 `latest_version` 改成 `1.0.1`；如果要强制低于 `1.0.1` 的版本更新，就把 `min_supported_version` 也改成 `1.0.1` 并保持 `force_update=true`。

## Firebase 参数列表

Firebase Remote Config 的复杂字段需要以字符串保存，数字和布尔值使用 Remote Config 原生类型。

建议参数：

```text
ad_slots = [{"placement":"settings_footer","title":"设置页推荐","message":"领取语音生成 API 额度","target_url":"https://example.com/promo","enabled":true},{"placement":"voice_service","title":"语音服务推荐","message":"申请或管理语音生成 API 额度。","target_url":"https://example.com/voice-service","enabled":true},{"placement":"text_optimization_service","title":"文本模型推荐","message":"选择适合润色和标签生成的文本模型。","target_url":"https://example.com/text-model","enabled":true}]
popup_notice = {"id":"maintenance-20260530","title":"维护提醒","message":"今晚 23:00 后服务可能短暂不可用。","target_url":"https://example.com/status","enabled":true}
latest_version = 1.0.0
min_supported_version = 1.0.0
force_update = true
update_url = https://example.com/download
```

Firebase 只是回退通道。面向国内用户时，优先维护 R2 JSON 文件即可。

## Firebase 应用别名

Firebase 的 Android 应用别名只是控制台展示名，不会写入 `android/app/google-services.json`，也不影响包名 `com.yunque.shenghui`。

当前项目里 Firebase 应用包名已经是：

```text
com.yunque.shenghui
```

如果 Firebase 控制台里还显示旧的默认应用别名，建议改成：

```text
声绘 Android
```

操作路径：Firebase 控制台 → 项目设置 → 您的应用 → Android 应用 → 点击“应用别名”右侧铅笔 → 保存。保存后不需要重新下载 `google-services.json`，除非你改的是包名、SHA 指纹或重新创建了应用。
