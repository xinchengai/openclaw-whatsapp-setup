#!/bin/bash
#============================================================================
# OpenClaw WhatsApp allowlist setup helper
#============================================================================

set -euo pipefail

SCRIPT_VERSION="1.0.0"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat << EOF
OpenClaw WhatsApp 白名单配置脚本 v${SCRIPT_VERSION}

用法:
  $0 --allow-from NUMBERS [选项]

必需参数:
  --allow-from NUMBERS       允许发消息的手机号，多个用逗号或空格分隔
                             示例: "+86150XXXXXXX,+86189XXXXXXX"

选项:
  --account ID               WhatsApp account id，默认 default
  --login                    配置后执行扫码登录
  --install-plugin           先尝试安装 npm 版 @openclaw/whatsapp 插件
  --no-restart-hint          不显示重启提示
  --help                     显示帮助

示例:
  $0 --allow-from "+86150XXXXXXX,+86189XXXXXXX"
  $0 --allow-from "+852XXXXXXX" --login
  $0 --account work --allow-from "+86150XXXXXXX +86189XXXXXXX" --install-plugin --login

说明:
  - 本脚本使用 channels.whatsapp.dmPolicy="allowlist"，不会给陌生人发送配对码
  - allowFrom 应填写允许和 WhatsApp bot 对话的用户手机号，使用 +国家码 的国际格式
  - 如果配置里存在 plugins.allow，本脚本会自动追加 whatsapp 和 @openclaw/whatsapp
EOF
    exit 0
}

check_openclaw() {
    if ! command -v openclaw >/dev/null 2>&1; then
        error "OpenClaw 未安装。请先安装 OpenClaw。"
        exit 1
    fi
    info "OpenClaw 版本: $(openclaw -v 2>/dev/null | head -1)"
}

normalize_numbers_json() {
    local input="$1"
    python3 - "$input" << 'PY'
import json
import re
import sys

raw = sys.argv[1]
parts = [p.strip() for p in re.split(r"[,，\s]+", raw) if p.strip()]
numbers = []
seen = set()

for number in parts:
    normalized = number.replace(" ", "")
    if not normalized.startswith("+") or not normalized[1:].isdigit():
        raise SystemExit(
            f"手机号格式错误: {number}。请使用国际格式，例如 +86150XXXXXXX"
        )
    if normalized not in seen:
        seen.add(normalized)
        numbers.append(normalized)

if not numbers:
    raise SystemExit("allowFrom 不能为空")

print(json.dumps(numbers, ensure_ascii=False))
PY
}

configure_whatsapp() {
    local allow_from_raw="$1"
    local account_id="$2"
    local numbers_json

    numbers_json="$(normalize_numbers_json "$allow_from_raw")"

    python3 - "$OPENCLAW_CONFIG" "$numbers_json" "$account_id" << 'PY'
import json
import os
import shutil
import sys
from datetime import datetime

config_path = os.path.expanduser(sys.argv[1])
allow_from = json.loads(sys.argv[2])
account_id = sys.argv[3]

if os.path.exists(config_path):
    backup_path = config_path + f".backup-whatsapp-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy(config_path, backup_path)
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
else:
    backup_path = None
    config = {}

plugins = config.setdefault("plugins", {})
plugins["enabled"] = True
plugin_allow = plugins.setdefault("allow", [])
for plugin_id in ("whatsapp", "@openclaw/whatsapp"):
    if plugin_id not in plugin_allow:
        plugin_allow.append(plugin_id)

plugin_entries = plugins.setdefault("entries", {})
whatsapp_entry = plugin_entries.setdefault("whatsapp", {})
whatsapp_entry["enabled"] = True
whatsapp_entry.setdefault("config", {})

channels = config.setdefault("channels", {})
whatsapp = channels.setdefault("whatsapp", {})
whatsapp["enabled"] = True

if account_id == "default":
    whatsapp["dmPolicy"] = "allowlist"
    whatsapp["allowFrom"] = allow_from
else:
    accounts = whatsapp.setdefault("accounts", {})
    account = accounts.setdefault(account_id, {})
    account["enabled"] = True
    account["dmPolicy"] = "allowlist"
    account["allowFrom"] = allow_from

os.makedirs(os.path.dirname(config_path), exist_ok=True)
with open(config_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")

if backup_path:
    print(f"已备份配置到: {backup_path}")
else:
    print("未发现旧配置，已创建新配置文件")
print(f"WhatsApp account: {account_id}")
print("allowFrom:")
for number in allow_from:
    print(f"  - {number}")
print("已启用 WhatsApp channel，并追加 plugins.allow: whatsapp, @openclaw/whatsapp")
PY
}

install_plugin() {
    info "尝试安装 npm 版 @openclaw/whatsapp 插件"
    if openclaw plugins install @openclaw/whatsapp; then
        success "WhatsApp 插件安装命令已完成"
    else
        warn "插件安装命令失败。你仍可稍后运行 openclaw channels login --channel whatsapp，并在提示时选择 npm 版。"
    fi
}

main() {
    local allow_from=""
    local account_id="default"
    local do_login="false"
    local do_install="false"
    local show_restart_hint="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help) usage ;;
            --allow-from)
                allow_from="${2:-}"
                shift 2
                ;;
            --account)
                account_id="${2:-}"
                shift 2
                ;;
            --login)
                do_login="true"
                shift
                ;;
            --install-plugin)
                do_install="true"
                shift
                ;;
            --no-restart-hint)
                show_restart_hint="false"
                shift
                ;;
            *)
                error "未知参数: $1"
                usage
                ;;
        esac
    done

    check_openclaw

    if [ -z "$allow_from" ]; then
        if [ -t 0 ]; then
            read -r -p "允许发消息的手机号(多个用逗号分隔): " allow_from
            read -r -p "WhatsApp account id [default]: " input_account
            if [ -n "$input_account" ]; then
                account_id="$input_account"
            fi
        else
            error "缺少必需参数: --allow-from"
            usage
        fi
    fi

    if [ -z "$account_id" ]; then
        account_id="default"
    fi

    configure_whatsapp "$allow_from" "$account_id"

    if [ "$do_install" = "true" ]; then
        install_plugin
    fi

    success "WhatsApp 白名单配置完成"
    echo ""

    if [ "$show_restart_hint" = "true" ]; then
        echo "建议执行:"
        echo "  openclaw config validate && openclaw gateway restart"
        echo ""
    fi

    if [ "$do_login" = "true" ]; then
        info "开始 WhatsApp 扫码登录"
        if [ "$account_id" = "default" ]; then
            openclaw channels login --channel whatsapp
        else
            openclaw channels login --channel whatsapp --account "$account_id"
        fi
    else
        echo "扫码登录:"
        if [ "$account_id" = "default" ]; then
            echo "  openclaw channels login --channel whatsapp"
        else
            echo "  openclaw channels login --channel whatsapp --account $account_id"
        fi
        echo ""
        echo "状态检查:"
        echo "  openclaw channels status --channel whatsapp"
    fi
}

main "$@"
