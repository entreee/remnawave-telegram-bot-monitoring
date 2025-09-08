#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or with sudo." >&2
  exit 1
fi

read -rp "Bot token: " BOT_TOKEN
read -rp "Access password: " ACCESS_PASSWORD
read -rp "Remnawave panel URLs (comma separated): " REMNA_BASE_URLS
read -rp "Authentication mode (api_key/credentials) [api_key]: " REMNA_AUTH_MODE
REMNA_AUTH_MODE=${REMNA_AUTH_MODE:-api_key}

if [ "$REMNA_AUTH_MODE" = "api_key" ]; then
  read -rp "API key or mappings: " REMNA_API_KEY
  AUTH_BLOCK="REMNA_API_KEY=$REMNA_API_KEY"
else
  read -rp "Username or mappings: " REMNA_USERNAME
  read -rp "Password (if common): " REMNA_PASSWORD
  AUTH_BLOCK="REMNA_USERNAME=$REMNA_USERNAME\nREMNA_PASSWORD=$REMNA_PASSWORD"
fi

read -rp "Default refresh interval seconds [15]: " REFRESH_DEFAULT
REFRESH_DEFAULT=${REFRESH_DEFAULT:-15}
read -rp "Default language (ru/en) [ru]: " LANG_DEFAULT
LANG_DEFAULT=${LANG_DEFAULT:-ru}

read -rp "Enable Uptime Kuma? (y/N): " ENABLE_KUMA
ENABLE_KUMA=${ENABLE_KUMA:-N}
if [[ $ENABLE_KUMA =~ ^[Yy]$ ]]; then
  ENABLE_KUMA=true
  read -rp "Kuma public URL: " KUMA_URL
  KUMA_PROFILE="--profile kuma"
else
  ENABLE_KUMA=false
  KUMA_URL=https://status.example.com/uptime
  KUMA_PROFILE=""
fi

cat > .env <<ENV
BOT_TOKEN=$BOT_TOKEN
ACCESS_PASSWORD=$ACCESS_PASSWORD

REMNA_BASE_URLS=$REMNA_BASE_URLS
REMNA_AUTH_MODE=$REMNA_AUTH_MODE
$AUTH_BLOCK

REFRESH_DEFAULT=$REFRESH_DEFAULT
REFRESH_MIN=1
REFRESH_MAX=3600

LOG_FORMAT=text
LANG_DEFAULT=$LANG_DEFAULT

ENABLE_KUMA=$ENABLE_KUMA
KUMA_URL=$KUMA_URL
ENV

echo ".env generated"

read -rp "Start containers now? (y/N): " START_NOW
START_NOW=${START_NOW:-N}
if [[ $START_NOW =~ ^[Yy]$ ]]; then
  docker compose $KUMA_PROFILE up -d
fi

echo "Done. Bot commands: /start, /login <password>, /help"
