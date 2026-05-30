# 产品发版工作流

`Product Release` 是用于构建产品分支的手动 GitHub Actions 工作流：

```text
product/official-release
```

工作流文件放在默认分支，方便 GitHub 显示 `Run workflow` 手动运行按钮；
但实际 checkout、改版本、构建、打 tag 和发 Release 的都是
`product/official-release`。

## 一次性设置

在 GitHub 仓库的 Actions Variables 中创建变量：

```text
PRODUCT_CONFIG_URL=https://your-domain.example/shenghui-product-config.json
```

这个 URL 会被打进产品安装包里，所以不要把密钥放进这个 URL 或对应 JSON。
用户自己的 API Key 仍然只保存在本地 App 中。

## 版本规则

Flutter 从 `pubspec.yaml` 读取应用版本：

```yaml
version: 1.0.0+8
```

- `1.0.0` 是用户看到的版本号。
- `8` 是构建号，也是 Android `versionCode`。
- 每次产品发版都必须使用更大的构建号。
- GitHub Release tag 使用 `product-v1.0.0+8`。

## 发版步骤

1. 打开 GitHub Actions。
2. 选择 `Product Release`。
3. 点击 `Run workflow`。
4. 填写 `version_name`，例如 `1.0.1`。
5. 填写 `build_number`，例如 `9`。
6. `config_url` 留空会使用 `PRODUCT_CONFIG_URL`，也可以临时填写其他地址。
7. 正常发版时保持 `create_release` 开启。

工作流会依次执行代码检查、测试、构建 APK/AAB，把版本号提交到
`product/official-release`，创建产品 tag，并把产物上传到 GitHub Releases。
