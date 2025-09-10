# Remnawave Telegram Bot Monitoring

## English

### Overview
Open‑source template of a Telegram bot that polls Remnawave panels and shows
basic metrics.  The project focuses on clean architecture, RU/EN i18n and a
pleasant user experience.  It is intentionally lightweight so it can be used as
an example or extended for real deployments.

### Quick start
```bash
git clone https://example.com/remnawave-telegram-bot-monitoring.git
cd remnawave-telegram-bot-monitoring
./scripts/install.sh   # generates .env and can start containers
```
The script asks for the bot token, access password and Remnawave credentials.  If
you enable Uptime Kuma it will start an additional monitoring container.

### Bot commands
- `/start` – create or refresh main message
- `/login <password>` – authorize user
- `/logout` – revoke authorization
- `/interval <sec>` – change refresh interval
- `/lang ru|en` – switch interface language
- `/panel` – choose active panels
- `/help` – show short help
- `/status` – bot status summary
- `/report` – download simple CSV report
- `/setalert <value>` – set alert threshold

### Environment variables
| Variable | Description |
| --- | --- |
| `BOT_TOKEN` | Telegram bot token |
| `ACCESS_PASSWORD` | Password for `/login` |
| `REMNA_BASE_URLS` | Comma separated list of Remnawave panel URLs |
| `REMNA_AUTH_MODE` | `api_key` or `credentials` |
| `REMNA_API_KEY` | When using API key mode: key or `url|key` mappings |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | When using credentials mode: common pair or `url|user|pass` mappings |
| `REFRESH_DEFAULT` | Default refresh interval in seconds |
| `REFRESH_MIN` / `REFRESH_MAX` | Allowed range for interval |
| `LOG_FORMAT` | `text` or `json` |
| `LANG_DEFAULT` | Default language `ru`/`en` |
| `ENABLE_KUMA` | `true` to start Uptime Kuma service |
| `KUMA_URL` | Public link to Uptime Kuma dashboard |
| `ENABLE_PROMETHEUS` | `true` to expose Prometheus metrics and run alert stack |
| `METRICS_PORT` | Port for `/metrics` endpoint |
| `ALERT_BOT_TOKEN` | Token of alert forwarding bot |
| `ALERT_SECRET` | Basic auth password for Alertmanager webhook |
| `ALERT_CHAT_IDS` | Comma separated chat IDs for alerts |

### Enable or disable Kuma later
Run the install script again or edit `.env` and start containers with profile:
```bash
docker compose --profile kuma up -d   # start Kuma as well
docker compose up -d                  # bot only
```

### Prometheus & Alerts
When enabling Prometheus in the install script the stack will expose metrics on
`/metrics` and start Prometheus (http://localhost:9090) together with
Alertmanager (http://localhost:9093).  Alertmanager sends webhooks to the second
Telegram bot which forwards alerts to configured chats.

## Русский

### Обзор
Открытый шаблон телеграм‑бота для мониторинга панелей Remnawave.  Основной упор
на простоту, поддержку русского/английского языков и удобство пользователя.
Проект лёгкий, поэтому его легко расширять под собственные нужды.

### Быстрый старт
```bash
git clone https://example.com/remnawave-telegram-bot-monitoring.git
cd remnawave-telegram-bot-monitoring
./scripts/install.sh   # генерация .env и запуск контейнеров
```
Скрипт запросит токен бота, пароль доступа и параметры Remnawave.  При желании
можно включить дополнительный контейнер Uptime Kuma.

### Команды бота
- `/start` – создать или обновить главное сообщение
- `/login <пароль>` – авторизация
- `/logout` – удалить доступ
- `/interval <сек>` – изменить интервал обновления
- `/lang ru|en` – переключить язык интерфейса
- `/panel` – выбрать активные панели
- `/help` – краткая справка
- `/status` – показать состояние бота
- `/report` – отправить простой CSV отчёт
- `/setalert <число>` – настроить порог уведомлений

### Переменные окружения
| Переменная | Описание |
| --- | --- |
| `BOT_TOKEN` | Токен телеграм‑бота |
| `ACCESS_PASSWORD` | Пароль для `/login` |
| `REMNA_BASE_URLS` | Список URL панелей через запятую |
| `REMNA_AUTH_MODE` | `api_key` или `credentials` |
| `REMNA_API_KEY` | Для режима API‑ключа: ключ или пары `url|key` |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | Для режима логин/пароль: общие или `url|user|pass` |
| `REFRESH_DEFAULT` | Интервал обновления по умолчанию |
| `REFRESH_MIN` / `REFRESH_MAX` | Допустимые границы интервала |
| `LOG_FORMAT` | `text` или `json` |
| `LANG_DEFAULT` | Язык по умолчанию `ru`/`en` |
| `ENABLE_KUMA` | `true` – запускать сервис Uptime Kuma |
| `KUMA_URL` | Ссылка на дашборд Uptime Kuma |
| `ENABLE_PROMETHEUS` | `true` – включить экспорт метрик и стек алертов |
| `METRICS_PORT` | Порт для `/metrics` |
| `ALERT_BOT_TOKEN` | Токен бота, принимающего алерты |
| `ALERT_SECRET` | Пароль для базовой аутентификации вебхука |
| `ALERT_CHAT_IDS` | Список chat_id для уведомлений |

### Как включить или выключить Kuma позже
Повторно запустите скрипт установки или измените `.env` и используйте
следующие команды:
```bash
docker compose --profile kuma up -d   # запуск с Kuma
docker compose up -d                  # только бот
```

### Prometheus и алерты
При включении Prometheus в установщике появляется эндпойнт `/metrics`, а также
запускаются Prometheus (http://localhost:9090) и Alertmanager
(http://localhost:9093).  Alertmanager отправляет вебхуки во второй телеграм‑бот,
который пересылает сообщения в указанные чаты.

### Разработка
- `make format` – форматирование кода
- `make lint` – статические проверки
- `make test` – юнит‑тесты

Лицензия: MIT.
