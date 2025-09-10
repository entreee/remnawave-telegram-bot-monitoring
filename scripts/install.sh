#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors and styles via tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Spinner
SPINNER_PID=0
spin() {
  local marks=('/' '-' '\\' '|')
  local i=0
  tput civis 2>/dev/null || true
  while :; do
    printf "\r%s" "${marks[$i]}"
    i=$(( (i + 1) % 4 ))
    sleep 0.1
  done &
  SPINNER_PID=$!
}
stop_spin() {
  if [[ "${SPINNER_PID}" -ne 0 ]]; then
    kill "${SPINNER_PID}" >/dev/null 2>&1 || true
    wait "${SPINNER_PID}" 2>/dev/null || true
    SPINNER_PID=0
    printf "\r "
  fi
  tput cnorm 2>/dev/null || true
}

# Error handling
trap 'echo "${RED}❌ Ошибка на строке $LINENO${RESET}"' ERR

# Helpers for styled prints
title() { echo "${BLUE}${BOLD}$*${RESET}"; }
ask() { echo -n "${YELLOW}$*${RESET}"; }
info() { echo "${BLUE}$*${RESET}"; }
ok() { echo "${GREEN}$*${RESET}"; }
err() { echo "${RED}$*${RESET}"; }

# Input validators
prompt_non_empty() {
  local label="$1" value
  while :; do
    ask "$label: "
    IFS= read -r value || true
    if [[ -n ${value:-} ]]; then
      printf "%s\n" "$value"
      return 0
    fi
    err "❌ Ошибка:${RESET} некорректный ввод, попробуйте снова."
  done
}

prompt_number() {
  local label="$1" default="$2" value
  while :; do
    ask "$label [$default]: "
    IFS= read -r value || true
    value=${value:-$default}
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf "%s\n" "$value"
      return 0
    fi
    err "❌ Ошибка:${RESET} некорректный ввод, попробуйте снова."
  done
}

prompt_menu() {
  local header="$1"; shift
  local -a options=("$@")
  local choice
  while :; do
    echo "${YELLOW}${BOLD}$header${RESET}"
    local i=1
    for opt in "${options[@]}"; do
      echo "[$i] $opt"
      i=$((i+1))
    done
    ask "> "
    IFS= read -r choice || true
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf "%s\n" "$choice"
      return 0
    fi
    err "❌ Ошибка:${RESET} некорректный ввод, попробуйте снова."
  done
}

must_succeed() {
  local action_msg="$1"; shift
  title "$action_msg"
  spin
  if "$@" >/dev/null 2>&1; then
    stop_spin
    ok "✅ Готово"
  else
    stop_spin
    err "❌ Ошибка: не удалось выполнить: $*"
    return 1
  fi
}

# Header
title "Установка Remnawave Telegram Bot Monitoring"

# Root check
if [[ $(id -u) -ne 0 ]]; then
  err "❌ Ошибка:${RESET} требуется запуск от root (sudo)."
  exit 1
fi

# Dependencies
if ! command -v curl >/dev/null 2>&1; then
  must_succeed "Устанавливаю curl" bash -lc 'apt-get update && apt-get install -y curl'
fi

if ! command -v docker >/dev/null 2>&1; then
  must_succeed "Устанавливаю Docker" bash -lc 'curl -fsSL https://get.docker.com | sh'
fi

if ! docker compose version >/dev/null 2>&1; then
  must_succeed "Устанавливаю docker compose plugin" bash -lc 'apt-get update && apt-get install -y docker-compose-plugin'
fi

# Collect configuration
title "Параметры бота"
BOT_TOKEN=$(prompt_non_empty "Bot token")
BOT_USERNAME=$(prompt_non_empty "Bot username (без @)")
TELEGRAM_ID=$(prompt_non_empty "Ваш Telegram ID")
ACCESS_PASSWORD=$(prompt_non_empty "Пароль доступа к панели")
REMNA_BASE_URLS=$(prompt_non_empty "URL панели Remnawave (через запятую)")

# Auth mode
choice=$(prompt_menu "Выберите режим аутентификации:" "API-ключ" "Логин/Пароль")
if [[ "$choice" == "1" ]]; then
  REMNA_AUTH_MODE="api_key"
  REMNA_API_KEY=$(prompt_non_empty "API-ключ или маппинг (domain=key,...)" )
  AUTH_BLOCK="REMNA_API_KEY=$REMNA_API_KEY"
else
  REMNA_AUTH_MODE="credentials"
  REMNA_USERNAME=$(prompt_non_empty "Логин или маппинг (domain=user,...)" )
  ask "Пароль (если общий, можно пусто): "
  IFS= read -r REMNA_PASSWORD || true
  AUTH_BLOCK="REMNA_USERNAME=$REMNA_USERNAME\nREMNA_PASSWORD=${REMNA_PASSWORD:-}"
fi

# Optional services
choice=$(prompt_menu "Включить Uptime Kuma?" "Да" "Нет")
if [[ "$choice" == "1" ]]; then
  ENABLE_KUMA=true
  KUMA_URL=$(prompt_non_empty "Публичный URL Kuma")
  KUMA_PROFILE="--profile kuma"
else
  ENABLE_KUMA=false
  KUMA_URL="https://status.example.com/uptime"
  KUMA_PROFILE=""
fi

choice=$(prompt_menu "Включить Prometheus/Alertmanager?" "Да" "Нет")
if [[ "$choice" == "1" ]]; then
  ENABLE_PROMETHEUS=true
  METRICS_PORT=$(prompt_number "Порт метрик" 9100)
  ALERT_BOT_TOKEN=$(prompt_non_empty "Токен бота для алертов")
  ALERT_SECRET=$(prompt_non_empty "Секрет для Alertmanager вебхука")
  ask "ID чатов для алертов (через запятую) [${TELEGRAM_ID}]: "
  IFS= read -r ALERT_CHAT_IDS || true
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

# Write .env
title "Генерирую .env"
spin
cat > .env <<ENV
BOT_TOKEN=$BOT_TOKEN
BOT_USERNAME=$BOT_USERNAME
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
stop_spin
ok "✅ .env создан"

# Monitoring configs
if [[ $ENABLE_PROMETHEUS == true ]]; then
  title "Генерирую конфиги Prometheus/Alertmanager"
  spin
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
  stop_spin
  ok "✅ Конфиги Prometheus/Alertmanager готовы"
fi

# Prepare dirs
mkdir -p data backups kuma

# Start stack
title "Запускаю контейнеры Docker"
spin
if docker compose $KUMA_PROFILE $MONITOR_PROFILE up -d >/dev/null 2>&1; then
  stop_spin
  ok "✅ Контейнеры запущены"
else
  stop_spin
  err "❌ Ошибка: не удалось запустить docker compose"
  exit 1
fi

# Symlink helper
ln -sf "$SCRIPT_DIR/remna-tg-monitoring" /usr/local/bin/remna-tg-monitoring || true
ok "Ссылка /usr/local/bin/remna-tg-monitoring создана"

# Final output
BOT_LINK="https://t.me/$BOT_USERNAME"

echo
title "Полезные ссылки"
printf '%s\n' "Bot:        $BOT_LINK"
printf '%s\n' "Metrics:    http://localhost:$METRICS_PORT/metrics"
if [[ $ENABLE_KUMA == true ]]; then
  printf '%s\n' "Kuma:       $KUMA_URL"
fi
if [[ $ENABLE_PROMETHEUS == true ]]; then
  printf '%s\n' "Prometheus: http://localhost:9090"
  printf '%s\n' "Alertmgr:   http://localhost:9093"
fi

echo
echo "${GREEN}${BOLD}✅ Установка завершена успешно!${RESET}"

