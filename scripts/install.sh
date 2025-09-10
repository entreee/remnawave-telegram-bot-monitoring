#!/usr/bin/env bash
set -e

GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BOLD=$(tput bold)
RESET=$(tput sgr0)

if [ "$(id -u)" -ne 0 ]; then
  echo "${RED}Please run as root (use sudo).${RESET}" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update >/dev/null && apt-get install -y curl >/dev/null
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "${GREEN}Installing Docker...${RESET}"
  curl -fsSL https://get.docker.com | sh >/dev/null
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "${GREEN}Installing docker compose plugin...${RESET}"
  apt-get update >/dev/null && apt-get install -y docker-compose-plugin >/dev/null
fi

read -rp "Bot token: " BOT_TOKEN
read -rp "Bot username (without @): " BOT_USERNAME
read -rp "Your Telegram ID: " TELEGRAM_ID
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

read -rp "Enable Prometheus/Alertmanager? (y/N): " ENABLE_PROM
ENABLE_PROM=${ENABLE_PROM:-N}
if [[ $ENABLE_PROM =~ ^[Yy]$ ]]; then
  ENABLE_PROMETHEUS=true
  read -rp "Metrics port [9100]: " METRICS_PORT
  METRICS_PORT=${METRICS_PORT:-9100}
  read -rp "Alert bot token: " ALERT_BOT_TOKEN
  read -rp "Alert secret: " ALERT_SECRET
  read -rp "Alert chat IDs (comma separated) [$TELEGRAM_ID]: " ALERT_CHAT_IDS
  ALERT_CHAT_IDS=${ALERT_CHAT_IDS:-$TELEGRAM_ID}
  MONITOR_PROFILE="--profile monitoring"
else
  ENABLE_PROMETHEUS=false
  METRICS_PORT=9100
  ALERT_BOT_TOKEN=replace_me
  ALERT_SECRET=super_secret
  ALERT_CHAT_IDS=$TELEGRAM_ID
  MONITOR_PROFILE=""
fi

cat > .env <<ENV
BOT_TOKEN=$BOT_TOKEN
ACCESS_PASSWORD=$ACCESS_PASSWORD

REMNA_BASE_URLS=$REMNA_BASE_URLS
REMNA_AUTH_MODE=$REMNA_AUTH_MODE
$AUTH_BLOCK

REFRESH_DEFAULT=15
REFRESH_MIN=1
REFRESH_MAX=3600

LOG_FORMAT=text
LANG_DEFAULT=ru

ENABLE_KUMA=$ENABLE_KUMA
KUMA_URL=$KUMA_URL
ENABLE_PROMETHEUS=$ENABLE_PROMETHEUS
METRICS_PORT=$METRICS_PORT
ALERT_BOT_TOKEN=$ALERT_BOT_TOKEN
ALERT_SECRET=$ALERT_SECRET
ALERT_CHAT_IDS=$ALERT_CHAT_IDS
ENV

echo "${GREEN}.env generated${RESET}"

if [[ $ENABLE_PROM =~ ^[Yy]$ ]]; then
  mkdir -p prometheus alertmanager
  cat > prometheus/prometheus.yml <<PROM
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'remnawave-bot'
    static_configs:
      - targets: ['bot:$METRICS_PORT']
PROM
  cat > alertmanager/alertmanager.yml <<ALERT
route:
  receiver: 'telegram'
receivers:
  - name: 'telegram'
    webhook_configs:
      - url: http://alert-bot:8080/alerts
        http_config:
          basic_auth:
            username: alert
            password: $ALERT_SECRET
ALERT
fi

mkdir -p data backups kuma

docker compose $KUMA_PROFILE $MONITOR_PROFILE up -d

BOT_LINK="https://t.me/$BOT_USERNAME"

echo "${GREEN}Bot: $BOT_LINK${RESET}"
echo "${GREEN}Metrics: http://localhost:$METRICS_PORT/metrics${RESET}"
if [[ $ENABLE_KUMA == true ]]; then
  echo "${GREEN}Kuma: $KUMA_URL${RESET}"
fi
if [[ $ENABLE_PROM =~ ^[Yy]$ ]]; then
  echo "${GREEN}Prometheus: http://localhost:9090${RESET}"
  echo "${GREEN}Alertmanager: http://localhost:9093${RESET}"
fi

echo "${GREEN}✅ Установка завершена!${RESET}"
