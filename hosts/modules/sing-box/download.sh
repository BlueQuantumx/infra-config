#!/usr/bin/env bash

set -euo pipefail

SECRET_FILE="/run/secrets/singbox/subscription_url"

CONFIG_DIR="/var/lib/sing-box"
OUTPUT="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

URL="$(cat "$SECRET_FILE")"

TMP="$(mktemp)"

echo "Downloading subscription..."

write_empty_config() {
    echo "Writing empty fallback config..."
    echo "{}" > "$OUTPUT"
    chmod 600 "$OUTPUT"
}

# 增加连接超时(10s)、最大执行时间(30s)以及失败重试(最高3次，间隔2秒)
if ! curl -fsSL --connect-timeout 10 --max-time 30 --retry 3 --retry-delay 2 "$URL" -o "$TMP"; then
    echo "Download failed"
    write_empty_config
    exit 0
fi

# 如果订阅本身已经是 sing-box json
if jq empty "$TMP" >/dev/null 2>&1; then
    echo "Testing sing-box configuration..."
    if sing-box check -c "$TMP"; then
        cp "$TMP" "$OUTPUT"
    else
        echo "Subscription is not a valid sing-box configuration"
        write_empty_config
        exit 0
    fi
else
    echo "Subscription is not valid JSON"
    write_empty_config
    exit 0
fi

chmod 600 "$OUTPUT"
