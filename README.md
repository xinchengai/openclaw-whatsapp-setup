# OpenClaw WhatsApp Setup

一键配置 OpenClaw WhatsApp channel 的白名单访问策略，适合把一个独立 WhatsApp 号作为 bot 号使用。

## 功能

- 启用 `channels.whatsapp`
- 设置 `dmPolicy` 为 `allowlist`，避免陌生人收到配对码
- 支持多个 `allowFrom` 手机号
- 自动把插件 id `whatsapp` 加入 `plugins.allow`
- 可安装与当前 OpenClaw 版本匹配的 npm 版 WhatsApp 插件
- 自动重启 Gateway、触发扫码登录，并显示最终状态
- 修改前自动备份 `~/.openclaw/openclaw.json`

## 使用

下载并交互运行：

```bash
curl -sSL https://raw.githubusercontent.com/xinchengai/openclaw-whatsapp-setup/main/setup_whatsapp_allowlist.sh > setup_whatsapp_allowlist.sh && chmod +x setup_whatsapp_allowlist.sh && ./setup_whatsapp_allowlist.sh
```

脚本会提示你输入允许访问的手机号，多个号码用逗号分隔。默认完整流程会安装匹配版本插件、重启 Gateway、扫码登录、再次重启并显示最终状态。

也可以直接用参数传入手机号：

```bash
./setup_whatsapp_allowlist.sh --allow-from "+86150XXXXXXX,+86189XXXXXXX"
```

不带参数运行时，也可以交互输入手机号：

```bash
./setup_whatsapp_allowlist.sh
```

## 参数

| 参数 | 说明 |
|------|------|
| `--allow-from` | 允许发消息的手机号，多个用逗号或空格分隔，必须使用 `+国家码` 格式 |
| `--login` | 执行 `openclaw channels login --channel whatsapp --verbose`，默认开启 |
| `--install-plugin` | 安装 npm 版 `@openclaw/whatsapp` 插件，默认开启并匹配当前 OpenClaw 版本 |
| `--restart` | 执行 `openclaw config validate`、重启 Gateway，并显示 channel 状态，默认开启 |
| `--no-login` | 不执行扫码登录 |
| `--no-install-plugin` | 不安装插件 |
| `--no-restart` | 不自动验证配置/重启 Gateway/显示状态 |
| `--plugin-version` | 指定 WhatsApp 插件版本，例如 `2026.5.19` |
| `--plugin-spec` | 指定完整 npm 包，例如 `@openclaw/whatsapp@2026.5.19` |
| `--no-restart-hint` | 不显示重启提示 |

## 注意

- `allowFrom` 应填写允许给 WhatsApp bot 号发消息的用户手机号，不一定是扫码登录的 bot 号。
- 如果你想允许多个号码，重新执行脚本并传入完整列表即可；脚本会覆盖旧的 `allowFrom`。
- 脚本固定配置默认 WhatsApp account，适合大多数单 WhatsApp bot 号场景。
- 重新执行脚本会清理旧的 `channels.whatsapp.accounts`，避免误写 account id 导致登录异常。
- OpenClaw 2026.5.19 应安装 `@openclaw/whatsapp@2026.5.19`。脚本会自动按当前 OpenClaw 版本选择插件版本。
- `plugins.allow` 里应该写插件 id `whatsapp`，不是 npm 包名 `@openclaw/whatsapp`。脚本会自动清理旧的错误项。
- 如果你之前误装过不兼容的新版本插件，重新执行 `--install-plugin` 会先移除本地 WhatsApp 插件目录，再安装匹配版本。
- 脚本默认会重启 Gateway。只有使用 `--no-restart` 时，才需要手动执行：

```bash
openclaw config validate && openclaw gateway restart
```
