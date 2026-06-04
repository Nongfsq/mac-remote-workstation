# 远程工作站

<p align="center">
  <img src="../Design/remote-workstation-icon.svg" width="128" alt="远程工作站图标">
</p>

远程工作站是一个原生 macOS 工具，用来把一台已经接入电源的 MacBook 临时变成可远程访问的工作站：合上盖子后，系统继续运行，RustDesk、Codex、Claude CLI、终端任务等仍然尽量保持可用。

它不是电池管理软件，也不是 AlDente 的替代品。限制充电、停在 80% 电量、保护电池寿命，这些属于电池工具或 macOS 自身；本项目只处理睡眠策略、合盖风险、验证和回滚。

## 当前阶段

本项目仍处于测试阶段，不保证在所有 Mac、所有 macOS 版本、所有远程桌面工具、扩展坞、外接显示器或电源状态下都能可靠工作。

请先在自己的机器上做 10 分钟、30 分钟合盖测试，再把它用于真实的长时间任务。

## 它会做什么

- 识别当前是否接入电源，即使电池因为限充而显示“不在充电”。
- 在接电状态下启用固定的远程工作站电源策略。
- 开启 `SleepDisabled`，降低合盖后系统睡眠导致远程断开的风险。
- 合盖后请求 `pmset displaysleepnow`，让显示器熄灭，但不关闭工作站模式。
- 检查是否有 App 正在阻止显示器睡眠。
- 针对 RustDesk 写入官方 keep-awake 设置，让远程会话不再强行点亮显示器。
- 关闭模式时恢复之前保存的接电电源配置，并强制执行 `pmset disablesleep 0`。

## 固定命令

开启模式：

```zsh
/usr/bin/pmset -c sleep 0 displaysleep 1 disksleep 0 womp 1 tcpkeepalive 1
/usr/bin/pmset disablesleep 1
```

合盖后请求熄灭显示器：

```zsh
/usr/bin/pmset displaysleepnow
```

关闭模式时会恢复快照，并始终执行：

```zsh
/usr/bin/pmset disablesleep 0
```

应用和 Helper 不接受任意 shell 命令，只允许固定的受控命令。

## 构建

```zsh
swift test
Packaging/Scripts/build-local-app.sh
open .build/app/RemoteWorkstation.app
```

构建 DMG：

```zsh
Packaging/Scripts/build-dmg.sh
```

生成文件位于：

```text
.build/dist/
```

更完整的说明见 [中文构建说明](BUILDING.zh-CN.md)。

## 手动回滚

如果任何状态看起来不对，优先在 App 里点击关闭模式。必要时可以手动执行：

```zsh
sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1
pmset -g live
pmset -g batt
```

## 隐私

本项目不采集遥测，不上传网络数据，不保存密码。它只在本机保存模式状态、恢复快照、验证结果和最近事件。

开源或提交代码前，请不要提交：

- `.build/` 构建产物
- DMG、PKG、签名产物
- RustDesk 用户配置或备份
- 本机状态文件
- `.env`、密钥、token
- 任何无关的本地私有仓库

根目录 `.gitignore` 已经排除了这些常见风险项。

## 免责声明

本项目按“现状”提供，不保证一定可用，也不保证适合任何特定用途。它可能影响系统睡眠、远程连接、电源消耗、散热状态或正在运行的任务。

作者和贡献者不对因使用本项目造成的法律责任、数据丢失、硬件损坏、服务中断、任务失败、财务损失或其他任何直接或间接损失承担责任。

## 许可证

MIT。见根目录 [LICENSE](../LICENSE)。

