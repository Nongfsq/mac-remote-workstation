# 构建与发布说明

远程工作站目前仍是本地开发构建。DMG 脚本只是为了生成便于安装和测试的磁盘镜像，不代表已经完成 Developer ID 签名或 Apple notarization。

## 环境要求

- macOS 13 或更新版本
- Xcode Command Line Tools 或 Xcode
- 兼容 Swift 6 的工具链
- ImageMagick，用于把 SVG 图标编译为 `.icns`
- macOS 自带的 `iconutil` 和 `hdiutil`

安装 ImageMagick：

```zsh
brew install imagemagick
```

## 运行测试

```zsh
swift test
```

## 构建本地 App

```zsh
Packaging/Scripts/build-local-app.sh
```

输出位置：

```text
.build/app/RemoteWorkstation.app
```

脚本会同时把：

```text
Design/remote-workstation-icon.svg
```

编译成：

```text
.build/app/RemoteWorkstation.app/Contents/Resources/RemoteWorkstation.icns
```

## 构建 DMG

```zsh
Packaging/Scripts/build-dmg.sh
```

输出位置：

```text
.build/dist/RemoteWorkstation-<version>.dmg
.build/dist/RemoteWorkstation-<version>.dmg.sha256
```

DMG 内包含：

- `RemoteWorkstation.app`
- 指向 `/Applications` 的快捷方式
- `LICENSE`
- 简短的 `README-FIRST.txt` 风险提醒

## 可选签名

本地测试可以不签名。

如果要使用本机 Developer ID 证书签名：

```zsh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  Packaging/Scripts/build-dmg.sh
```

当前还没有实现 notarization。正式公开发布前，应补齐 Developer ID 签名、notarization、staple 验证和卸载说明。

## 发布前隐私检查

提交或公开仓库前，建议运行：

```zsh
git status --short
rg -n -uu "PRIVATE KEY|github_pat_|ghp_|sk-|password|secret|token|/Users/" .
```

不要提交 `.build/`、RustDesk 用户配置、本机状态文件、`.env`、本地 app bundle、DMG、签名产物或无关的本地私有仓库。

