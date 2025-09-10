# Remnawave Telegram Bot Monitoring

[![build](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![tests](https://img.shields.io/badge/tests-passing-brightgreen)](#)
[![license: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## English

### Overview
Remnawave Telegram Bot Monitoring is a ready‑to‑run stack that polls multiple Remnawave panels and displays the most important metrics right inside Telegram. The project targets self‑hosted installations and embraces simplicity, RU/EN localisation and Docker deployment.

### Features
- Asynchronous **aiogram v3** bot (polling)
- SQLite persistence for chat settings, authorisations and refresh intervals
- Runtime language switcher (RU/EN)
- Inline tabs: Overview, Nodes, Users, Plans, Payments, Traffic, Alerts
- Optional [Uptime Kuma](https://github.com/louislam/uptime-kuma) dashboard
- Optional Prometheus exporter with Alertmanager and secondary alert bot
- Daily SQLite backups and rotating logs

### Quick start
```bash
curl -sL https://raw.githubusercontent.com/remnawave/remnawave-telegram-bot-monitoring/main/scripts/install.sh | bash
```
The installer will ask for the bot token, access password, Remnawave panel URLs and
authentication mode. You can optionally enable Uptime Kuma or the Prometheus/
Alertmanager stack. At the end the containers will be started automatically.

### Bot commands
- `/start` – create or refresh main message
- `/login <password>` – authorise user
- `/logout` – revoke authorisation
- `/interval <sec>` – change refresh interval
- `/lang ru|en` – switch interface language
- `/panel` – choose active panels
- `/help` – show short help
- `/status` – bot status summary
- `/report` – download CSV report
- `/setalert <value>` – set alert threshold

### Environment variables
| Variable | Description |
| --- | --- |
| `BOT_TOKEN` | Telegram bot token |
| `ACCESS_PASSWORD` | Password for `/login` |
| `REMNA_BASE_URLS` | Comma separated list of Remnawave panel URLs |
| `REMNA_AUTH_MODE` | `api_key` or `credentials` |
| `REMNA_API_KEY` | API key or `url\|key` mappings |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | Credentials or `url\|user\|pass` mappings |
| `REFRESH_DEFAULT` | Default refresh interval in seconds |
| `REFRESH_MIN` / `REFRESH_MAX` | Allowed range for interval |
| `LOG_FORMAT` | `text` or `json` |
| `LANG_DEFAULT` | Default language `ru`/`en` |
| `ENABLE_KUMA` | `true` to start Uptime Kuma service |
| `KUMA_URL` | Public link to Uptime Kuma dashboard |
| `ENABLE_PROMETHEUS` | `true` to expose `/metrics` and run alert stack |
| `METRICS_PORT` | Port for `/metrics` endpoint |
| `ALERT_BOT_TOKEN` | Token of alert forwarding bot |
| `ALERT_SECRET` | Basic auth password for Alertmanager webhook |
| `ALERT_CHAT_IDS` | Comma separated Telegram chat IDs for alerts |

### Development
```bash
make format   # format code with black
make lint     # ruff + mypy
make test     # pytest
```

### License
Licensed under the [MIT License](LICENSE).

---

## Русский

### Обзор
Remnawave Telegram Bot Monitoring — готовый к запуску стек, который опрашивает
несколько панелей Remnawave и показывает ключевые метрики прямо в Telegram.
Проект ориентирован на простоту, локализацию RU/EN и развёртывание в Docker.

### Возможности
- Асинхронный бот на **aiogram v3** (polling)
- Хранение настроек в SQLite
- Переключение языка во время работы (RU/EN)
- Вкладки: Overview, Nodes, Users, Plans, Payments, Traffic, Alerts
- Опциональный дашборд [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- Опциональный экспортёр Prometheus и Alertmanager с отдельным ботом
- Ежедневные бэкапы SQLite и ротация логов

### Быстрый старт
```bash
curl -sL https://raw.githubusercontent.com/remnawave/remnawave-telegram-bot-monitoring/main/scripts/install.sh | bash
```
Установщик попросит токен бота, пароль доступа, адреса панелей Remnawave и режим
аутентификации. При желании можно включить Uptime Kuma и стек Prometheus/
Alertmanager. В конце контейнеры будут запущены автоматически.

### Команды бота
- `/start` – создать или обновить главное сообщение
- `/login <пароль>` – авторизация
- `/logout` – удалить доступ
- `/interval <сек>` – изменить интервал обновления
- `/lang ru|en` – переключить язык
- `/panel` – выбрать активные панели
- `/help` – краткая справка
- `/status` – показать состояние бота
- `/report` – отправить CSV отчёт
- `/setalert <число>` – настроить порог уведомлений

### Переменные окружения
| Переменная | Описание |
| --- | --- |
| `BOT_TOKEN` | Токен телеграм‑бота |
| `ACCESS_PASSWORD` | Пароль для `/login` |
| `REMNA_BASE_URLS` | Список URL панелей через запятую |
| `REMNA_AUTH_MODE` | `api_key` или `credentials` |
| `REMNA_API_KEY` | API‑ключ или пары `url\|key` |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | Логин/пароль или `url\|user\|pass` |
| `REFRESH_DEFAULT` | Интервал обновления по умолчанию |
| `REFRESH_MIN` / `REFRESH_MAX` | Допустимые границы интервала |
| `LOG_FORMAT` | `text` или `json` |
| `LANG_DEFAULT` | Язык по умолчанию `ru`/`en` |
| `ENABLE_KUMA` | `true` – запускать Uptime Kuma |
| `KUMA_URL` | Ссылка на дашборд Uptime Kuma |
| `ENABLE_PROMETHEUS` | `true` – включить `/metrics` и стек алертов |
| `METRICS_PORT` | Порт эндпойнта `/metrics` |
| `ALERT_BOT_TOKEN` | Токен бота, принимающего алерты |
| `ALERT_SECRET` | Пароль для базовой аутентификации вебхука |
| `ALERT_CHAT_IDS` | Список Telegram ID для уведомлений |

### Разработка
```bash
make format   # форматирование black
make lint     # ruff + mypy
make test     # юнит‑тесты
```

### Лицензия
Лицензия [MIT](LICENSE).
