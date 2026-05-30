# 产品发版工作流

`Product Release` 是用于构建正式安装包的手动 GitHub Actions 工作流。
它直接基于 `main` 构建：

```text
main
```

如果仓库变量里配置了 `PRODUCT_CONFIG_URL`，构建出来的包会启用远程推广位
和弹窗通知；如果没有配置，构建出来的包就是不带远程配置的干净版本。

## 可选远程配置

如果希望产品包启用远程推广位和弹窗通知，可以在 GitHub 仓库的
Actions Variables 中创建变量：

```text
PRODUCT_CONFIG_URL=https://your-domain.example/shenghui-product-config.json
```

这个 URL 会被打进产品安装包里，所以不要把密钥放进这个 URL 或对应 JSON。
用户自己的 API Key 仍然只保存在本地 App 中。
工作流只读取 Actions Variables，不读取 Secrets。

如果不设置 `PRODUCT_CONFIG_URL`，产品包仍然会正常构建，只是不会启用远程推广位和弹窗通知。

## 版本规则

Flutter 从 `pubspec.yaml` 读取应用版本：

```yaml
version: 0.0.1+1
```

- `0.0.1` 是用户看到的版本号。
- `1` 是构建号，也是 Android `versionCode` 的起点。
- 运行发版 workflow 时只需要填写用户看到的版本号。
- 构建号由 GitHub Actions 自动生成，规则是 `workflow run number + 1000`。
- 每次产品发版都会得到更大的构建号。
- GitHub Release tag 使用 `v0.0.1`、`v0.0.2` 这样的纯版本号格式。
- GitHub Release 说明由工作流自动生成，会列出版本、构建号、配置状态、下载文件、校验文件和上一个 tag 之后的提交记录。

## 发版步骤

1. 打开 GitHub Actions。
2. 选择 `Product Release`。
3. 点击 `Run workflow`。
4. 填写 `version_name`，例如 `0.0.2`。
5. 正常发版时保持 `create_release` 开启。

工作流会依次执行代码检查、测试、构建 APK/AAB，把版本号提交到
`main`，创建版本 tag，并把产物上传到 GitHub Releases。
