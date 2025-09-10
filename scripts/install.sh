#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bash_loading_animations.sh"

trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

handle_error() {
  local line=$1
  local cmd=$2
  BLA::print_error "Ошибка на строке $line: $cmd"
  exit 1
}

ask_non_empty() {
  local prompt=$1
  local value
  while true; do
    read -rp "$(BLA::yellow "$prompt: ")" value
    if [[ -n $value ]]; then
      echo "$value"
      return
    fi
    BLA::print_error "Значение не может быть пустым"
  done
}

ask_number() {
  local prompt=$1
  local default=$2
  local value
  while true; do
    read -rp "$(BLA::yellow "$prompt [$default]: ")" value
    value=${value:-$default}
    if [[ $value =~ ^[0-9]+$ ]]; then
      echo "$value"
      return
    fi
    BLA::print_error "Введите целое число"
  done
}

ask_menu() {
  local prompt=$1
  local choice
  while true; do
    BLA::print_warning "$prompt"
    BLA::print_warning "1) Да"
    BLA::print_warning "2) Нет"
    read -rp "$(BLA::yellow "> ")" choice
    case $choice in
      1) return 0 ;;
      2) return 1 ;;
      *) BLA::print_error "Введите 1 или 2" ;;
    esac
  done
}

ask_auth_mode() {
  local choice
  while true; do
    BLA::print_warning "Режим аутентификации Remnawave:"
    BLA::print_warning "1) api_key"
    BLA::print_warning "2) credentials"
    read -rp "$(BLA::yellow "> ")" choice
    case $choice in
      1) REMNA_AUTH_MODE="api_key"; return ;;
      2) REMNA_AUTH_MODE="credentials"; return ;;
      *) BLA::print_error "Введите 1 или 2" ;;
    esac
  done
}

if [[ $(id -u) -ne 0 ]]; then
  BLA::print_error "Запустите скрипт от root (sudo)"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  BLA::start_loading_animation "Установка curl"
  apt-get update >/dev/null && apt-get install -y curl >/dev/null
  BLA::stop_loading_animation
  BLA::print_success "curl установлена"
fi

if ! command -v docker >/dev/null 2>&1; then
  BLA::start_loading_animation "Установка Docker"
  curl -fsSL https://get.docker.com | sh >/dev/null
  BLA::stop_loading_animation
  BLA::print_success "Docker установлен"
fi

if ! docker compose version >/dev/null 2>&1; then
  BLA::start_loading_animation "Установка docker compose"
  apt-get update >/dev/null && apt-get install -y docker-compose-plugin >/dev/null
  BLA::stop_loading_animation
  BLA::print_success "docker compose установлен"
fi

BOT_TOKEN=$(ask_non_empty "Bot token")
BOT_USERNAME=$(ask_non_empty "Bot username (without @)")
TELEGRAM_ID=$(ask_non_empty "Your Telegram ID")
ACCESS_PASSWORD=$(ask_non_empty "Access password")
REMNA_BASE_URLS=$(ask_non_empty "Remnawave panel URLs (comma separated)")
ask_auth_mode

if [[ $REMNA_AUTH_MODE == "api_key" ]]; then
  REMNA_API_KEY=$(ask_non_empty "API key or mappings")
  AUTH_BLOCK="REMNA_API_KEY=$REMNA_API_KEY"
else
  REMNA_USERNAME=$(ask_non_empty "Username or mappings")
  read -rp "$(BLA::yellow "Password (if common): ")" REMNA_PASSWORD
  AUTH_BLOCK="REMNA_USERNAME=$REMNA_USERNAME\nREMNA_PASSWORD=$REMNA_PASSWORD"
fi

if ask_menu "Хотите включить Uptime Kuma?"; then
  ENABLE_KUMA=true
  KUMA_URL=$(ask_non_empty "Kuma public URL")
  KUMA_PROFILE="--profile kuma"
else
  ENABLE_KUMA=false
  KUMA_URL=https://status.example.com/uptime
  KUMA_PROFILE=""
fi

if ask_menu "Хотите включить Prometheus/Alertmanager?"; then
  ENABLE_PROMETHEUS=true
  METRICS_PORT=$(ask_number "Metrics port" 9100)
  ALERT_BOT_TOKEN=$(ask_non_empty "Alert bot token")
  ALERT_SECRET=$(ask_non_empty "Alert secret")
  read -rp "$(BLA::yellow "Alert chat IDs (comma separated) [$TELEGRAM_ID]: ")" ALERT_CHAT_IDS
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

BLA::start_loading_animation "Создание .env"
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
BLA::stop_loading_animation
BLA::print_success ".env создан"

if [[ $ENABLE_PROMETHEUS == true ]]; then
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

BLA::start_loading_animation "Запуск контейнеров"
docker compose $KUMA_PROFILE $MONITOR_PROFILE up -d >/dev/null
BLA::stop_loading_animation
BLA::print_success "Контейнеры запущены"

ln -sf "$SCRIPT_DIR/remna-tg-monitoring" /usr/local/bin/remna-tg-monitoring
BLA::print_success "Утилита remna-tg-monitoring установлена"

BOT_LINK="https://t.me/$BOT_USERNAME"

printf '\n'
printf '+---------------+--------------------------------------+'\n
printf '| %-13s | %-36s |\n' "Service" "URL"
printf '+---------------+--------------------------------------+'\n
printf '| %-13s | %-36s |\n' "Bot" "$BOT_LINK"
printf '| %-13s | %-36s |\n' "Metrics" "http://localhost:$METRICS_PORT/metrics"
if [[ $ENABLE_KUMA == true ]]; then
  printf '| %-13s | %-36s |\n' "Kuma" "$KUMA_URL"
fi
if [[ $ENABLE_PROMETHEUS == true ]]; then
  printf '| %-13s | %-36s |\n' "Prometheus" "http://localhost:9090"
  printf '| %-13s | %-36s |\n' "Alertmanager" "http://localhost:9093"
fi
printf '+---------------+--------------------------------------+'\n

BLA::print_success "$(BLA::bold 'Установка завершена успешно!')"
