# 官方构建参数

声绘开源源码默认不启用远程运营配置或匿名统计。只有官方发布包在构建时显式传入参数后，才会连接你的运营接口。

## 默认构建

```bash
flutter build apk --release
```

默认构建行为：

- 不读取远程运营配置。
- 不展示远程弹窗通知。
- 不执行远程版本策略。
- 不上报匿名统计。

## 官方发布包

```bash
flutter build apk --release --no-pub \
  --dart-define=SHENGHUI_OFFICIAL_BUILD=true \
  --dart-define=SHENGHUI_BUILD_CHANNEL=github-release \
  --dart-define=SHENGHUI_REMOTE_CONFIG_URL=https://your-domain.example/shenghui-config.json \
  --dart-define=SHENGHUI_ANALYTICS_ENDPOINT=https://your-domain.example/events
```

字段说明：

- `SHENGHUI_OFFICIAL_BUILD`: 设为 `true` 后启用官方构建能力。
- `SHENGHUI_BUILD_CHANNEL`: 发布渠道标识，例如 `github-release`、`play-store`、`internal-test`。
- `SHENGHUI_REMOTE_CONFIG_URL`: 官方远程 JSON 配置地址。
- `SHENGHUI_ANALYTICS_ENDPOINT`: 官方匿名统计接口地址。不传则不会上报统计。

公开仓库只保留关闭状态的示例文件：

```text
config/shenghui-config.example.json
```

真实运营配置建议放在私有 ops 仓库、私有存储桶、后台管理系统或发布流水线 Secrets 中。

## 匿名统计

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
