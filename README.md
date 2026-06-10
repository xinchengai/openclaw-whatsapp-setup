# OpenClaw WhatsApp Setup

一键配置 OpenClaw WhatsApp channel 的白名单访问策略，适合把一个独立 WhatsApp 号作为 bot 号使用。

## 功能

- 启用 `channels.whatsapp`
- 设置 `dmPolicy` 为 `allowlist`，避免陌生人收到配对码
- 支持多个 `allowFrom` 手机号
- 自动把 `whatsapp` / `@openclaw/whatsapp` 加入 `plugins.allow`
- 可选安装 WhatsApp 插件和触发扫码登录
- 修改前自动备份 `~/.openclaw/openclaw.json`

## 使用

下载并运行：

```bash
curl -sSL https://raw.githubusercontent.com/xinchengai/openclaw-whatsapp-setup/main/setup_whatsapp_allowlist.sh > setup_whatsapp_allowlist.sh && chmod +x setup_whatsapp_allowlist.sh
```

配置多个允许访问的手机号：

```bash
./setup_whatsapp_allowlist.sh --allow-from "+86150XXXXXXX,+86189XXXXXXX"
```

配置后执行：

```bash
openclaw config validate && openclaw gateway restart
openclaw channels login --channel whatsapp
```

也可以配置后直接进入扫码登录：

```bash
./setup_whatsapp_allowlist.sh --allow-from "+86150XXXXXXX,+86189XXXXXXX" --login
```

如果 WhatsApp 插件还没安装，可以加：

```bash
./setup_whatsapp_allowlist.sh --allow-from "+86150XXXXXXX,+86189XXXXXXX" --install-plugin --login
```

## 参数

| 参数 | 说明 |
|------|------|
| `--allow-from` | 允许发消息的手机号，多个用逗号或空格分隔，必须使用 `+国家码` 格式 |
| `--account` | WhatsApp account id，默认 `default` |
| `--login` | 配置完成后执行 `openclaw channels login --channel whatsapp` |
| `--install-plugin` | 尝试安装 npm 版 `@openclaw/whatsapp` 插件 |
| `--no-restart-hint` | 不显示重启提示 |

## 注意

- `allowFrom` 应填写允许给 WhatsApp bot 号发消息的用户手机号，不一定是扫码登录的 bot 号。
- 如果你想允许多个号码，重新执行脚本并传入完整列表即可；脚本会覆盖旧的 `allowFrom`。
- OpenClaw 2026.5.19 上如果 ClawHub 版 WhatsApp 插件提示 plugin API 不兼容，请选择 npm 版 `@openclaw/whatsapp`。
- 修改配置后需要重启 Gateway：

```bash
openclaw config validate && openclaw gateway restart
```

