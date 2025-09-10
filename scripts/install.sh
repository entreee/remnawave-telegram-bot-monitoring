#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors and styles via tput (with graceful fallback)
RED=$(tput setaf 1 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
BLUE=$(tput setaf 4 2>/dev/null || true)
BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)
init_colors() {
  if ! tput colors >/dev/null 2>&1 || [[ -n "${NO_COLOR:-}" ]]; then
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
  fi
}
init_colors

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
on_error() {
  local line=$1 cmd=$2
  stop_spin || true
  echo "${RED}❌ Ошибка на строке ${line}${RESET}"
  echo "${RED}Команда: ${cmd}${RESET}"
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR
trap 'stop_spin' EXIT

# Styled prints
title() { echo "${BLUE}${BOLD}$*${RESET}"; }
ask() { echo -n "${YELLOW}$*${RESET}"; }
info() { echo "${BLUE}$*${RESET}"; }
ok() { echo "${GREEN}$*${RESET}"; }
err() { echo "${RED}$*${RESET}"; }
warn() { echo "${YELLOW}$*${RESET}"; }

# Input helpers
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

prompt_port() {
  local label="$1" default="$2" value
  while :; do
    value=$(prompt_number "$label" "$default")
    if (( value >= 1 && value <= 65535 )); then
      echo "$value"; return 0
    fi
    err "❌ Ошибка:${RESET} порт вне диапазона 1-65535."
  done
}

# Validation helpers
validate_username() { [[ "$1" =~ ^[A-Za-z0-9_]{5,64}$ ]]; }
validate_token() { [[ "$1" == *:* ]]; }
validate_urls_csv() {
  local csv="$1" item
  IFS=',' read -r -a arr <<<"$csv"
  for item in "${arr[@]}"; do
    item="${item//[[:space:]]/}"
    [[ "$item" =~ ^https?://[^,]+$ ]] || return 1
  done
  return 0
}

# Command wrappers
compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    return 1
  fi
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

compose_run() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  else
    docker-compose "$@"
  fi
}

ensure_docker_running() {
  if docker info >/dev/null 2>&1; then return 0; fi
  if command -v systemctl >/dev/null 2>&1; then
    title "Запускаю сервис docker"
    spin
    if systemctl start docker >/dev/null 2>&1; then
      stop_spin; ok "✅ Docker запущен"; return 0
    fi
    stop_spin
  fi
  warn "Docker daemon не запущен. Запустите его вручную (systemctl start docker) и повторите."
  exit 1
}

# Header
title "Установка Remnawave Telegram Bot Monitoring"
info "Этот мастер поможет настроить .env и запустить сервисы."

# Root check
if [[ $(id -u) -ne 0 ]]; then
  err "❌ Ошибка:${RESET} требуется запуск от root (sudo)."
  exit 1
fi

# Dependencies
if ! command -v curl >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    must_succeed "Устанавливаю curl" bash -lc 'apt-get update && apt-get install -y curl'
  else
    err "curl не найден. Установите curl вручную и перезапустите скрипт."
    exit 1
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  must_succeed "Устанавливаю Docker" bash -lc 'curl -fsSL https://get.docker.com | sh'
fi

if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    must_succeed "Устанавливаю docker compose" bash -lc 'apt-get update && apt-get install -y docker-compose-plugin || apt-get install -y docker-compose'
  else
    warn "docker compose не найден. Установите docker-compose вручную."
  fi
fi

ensure_docker_running

COMPOSE_BIN=$(compose_cmd || true)
if [[ -z "${COMPOSE_BIN:-}" ]]; then
  err "docker compose не найден. Установите его и повторите."
  exit 1
fi

# Collect configuration with confirmation loop
gather_inputs() {
  title "Параметры бота"
  while :; do
    BOT_TOKEN=$(prompt_non_empty "Bot token")
    if ! validate_token "$BOT_TOKEN"; then warn "Токен выглядит необычно (нет двоеточия), но продолжим."; fi
    break
  done
  while :; do
    BOT_USERNAME=$(prompt_non_empty "Bot username (без @)")
    if ! validate_username "$BOT_USERNAME"; then warn "Имя пользователя содержит необычные символы."; fi
    break
  done
  TELEGRAM_ID=$(prompt_non_empty "Ваш Telegram ID")
  ask "Пароль доступа к панели: "
  IFS= read -rs ACCESS_PASSWORD || true
  echo
  while :; do
    REMNA_BASE_URLS=$(prompt_non_empty "URL панели Remnawave (через запятую)")
    if validate_urls_csv "$REMNA_BASE_URLS"; then break; fi
    err "❌ Ошибка:${RESET} ожидаются URL вида https://example.com, разделённые запятыми."
  done

  choice=$(prompt_menu "Выберите режим аутентификации:" "API-ключ" "Логин/Пароль")
  if [[ "$choice" == "1" ]]; then
    REMNA_AUTH_MODE="api_key"
    REMNA_API_KEY=$(prompt_non_empty "API-ключ или маппинг (domain=key,...)")
    AUTH_BLOCK="REMNA_API_KEY=$REMNA_API_KEY"
  else
    REMNA_AUTH_MODE="credentials"
    REMNA_USERNAME=$(prompt_non_empty "Логин или маппинг (domain=user,...)")
    ask "Пароль (если общий, можно пусто): "
    IFS= read -rs REMNA_PASSWORD || true
    echo
    AUTH_BLOCK="REMNA_USERNAME=$REMNA_USERNAME\nREMNA_PASSWORD=${REMNA_PASSWORD:-}"
  fi

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
    METRICS_PORT=$(prompt_port "Порт метрик" 9100)
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
}

confirm_inputs() {
  title "Проверка настроек"
  printf 'Bot:        %s\n' "$BOT_USERNAME"
  printf 'TelegramID: %s\n' "$TELEGRAM_ID"
  printf 'RemnaURL:   %s\n' "$REMNA_BASE_URLS"
  printf 'Auth mode:  %s\n' "$REMNA_AUTH_MODE"
  if [[ $REMNA_AUTH_MODE == api_key ]]; then
    printf 'API key:    %s\n' "*** скрыто ***"
  else
    printf 'Login map:  %s\n' "$REMNA_USERNAME"
    printf 'Password:   %s\n' "*** скрыто ***"
  fi
  printf 'Kuma:       %s\n' "$ENABLE_KUMA"
  if [[ $ENABLE_KUMA == true ]]; then printf 'Kuma URL:   %s\n' "$KUMA_URL"; fi
  printf 'Prometheus: %s\n' "$ENABLE_PROMETHEUS"
  if [[ $ENABLE_PROMETHEUS == true ]]; then
    printf 'Metrics:    %s\n' "$METRICS_PORT"
    printf 'Alert chat: %s\n' "$ALERT_CHAT_IDS"
  fi
  choice=$(prompt_menu "Продолжить установку?" "Да" "Нет, ввести заново")
  [[ "$choice" == "1" ]]
}

while :; do
  gather_inputs
  if confirm_inputs; then break; fi
done

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

# Validate compose config
title "Проверяю docker compose конфигурацию"
spin
if compose_run config -q >/dev/null 2>&1; then
  stop_spin; ok "✅ Конфигурация корректна"
else
  stop_spin; err "❌ Ошибка: docker compose config не прошёл проверку"; exit 1
fi

# Start stack
title "Запускаю контейнеры Docker"
spin
PROFILE_ARGS=()
[[ $ENABLE_KUMA == true ]] && PROFILE_ARGS+=(--profile kuma)
[[ $ENABLE_PROMETHEUS == true ]] && PROFILE_ARGS+=(--profile monitoring)
if compose_run "${PROFILE_ARGS[@]}" up -d >/dev/null 2>&1; then
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
