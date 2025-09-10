# Remnawave Telegram Bot Monitoring

[![Build Status](https://img.shields.io/github/actions/workflow/status/remnawave/remnawave-telegram-bot-monitoring/tests.yml?branch=main&label=build)](https://github.com/remnawave/remnawave-telegram-bot-monitoring/actions/workflows/tests.yml)
[![Tests](https://img.shields.io/github/actions/workflow/status/remnawave/remnawave-telegram-bot-monitoring/tests.yml?branch=main&label=tests)](https://github.com/remnawave/remnawave-telegram-bot-monitoring/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**English**

### Overview
Remnawave Telegram Bot Monitoring is an aiogram‑based bot that polls several Remnawave panels and posts the most relevant metrics in a single Telegram message. Optional Uptime Kuma, Prometheus exporter and alert bot can be enabled for richer observability.

### Key Features
- Async **aiogram v3** polling bot
- SQLite storage for chat settings and authorisation
- RU/EN localisation with runtime switch
- Inline tabs: Overview, Nodes, Users, Plans, Payments, Traffic, Alerts
- Optional [Uptime Kuma](https://github.com/louislam/uptime-kuma) dashboard
- Optional Prometheus exporter with Alertmanager webhook bot
- Daily SQLite backups and rotating logs

### Quick Start
```bash
curl -sL https://raw.githubusercontent.com/remnawave/remnawave-telegram-bot-monitoring/main/scripts/install.sh | bash
```
The script installs Docker if needed, generates `.env`, asks about Uptime Kuma or Prometheus and starts the stack.

Manage the stack later with `remna-tg-monitoring start|stop|status|links|help`.

### Environment Variables
| Variable | Description |
| --- | --- |
| `BOT_TOKEN` | Telegram bot token |
| `BOT_USERNAME` | Bot username used for links |
| `ACCESS_PASSWORD` | Password used by `/login` |
| `REMNA_BASE_URLS` | Comma‑separated list of panel URLs |
| `REMNA_AUTH_MODE` | `api_key` or `credentials` |
| `REMNA_API_KEY` | API key or `url\|key` mappings |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | Credentials or `url\|user\|pass` mappings |
| `REFRESH_DEFAULT` | Default refresh interval (sec) |
| `REFRESH_MIN` / `REFRESH_MAX` | Allowed interval range |
| `LOG_FORMAT` | `text` or `json` |
| `LANG_DEFAULT` | Default UI language `ru`/`en` |
| `ENABLE_KUMA` | `true` to start Uptime Kuma |
| `KUMA_URL` | Public URL of the Kuma dashboard |
| `ENABLE_PROMETHEUS` | `true` to run exporter and alert stack |
| `METRICS_PORT` | Port for `/metrics` endpoint |
| `ALERT_BOT_TOKEN` | Token of alert-forwarding bot |
| `ALERT_SECRET` | Basic auth password for Alertmanager webhook |
| `ALERT_CHAT_IDS` | Comma‑separated chat IDs for alerts |

### Bot Commands
- `/start` – create or refresh main message
- `/login <password>` – authorise user
- `/logout` – revoke access
- `/interval <sec>` – change refresh interval
- `/lang ru|en` – switch language
- `/panel` – choose active panels
- `/help` – show short help
- `/status` – bot status summary
- `/report` – download CSV report
- `/setalert <value>` – set alert threshold

### Development
```bash
make format   # black
make lint     # ruff + mypy
make test     # pytest
```

### License
Licensed under the [MIT License](LICENSE).

---

**Русский**

### Обзор
Remnawave Telegram Bot Monitoring — бот на aiogram, который опрашивает несколько панелей Remnawave и выводит ключевые метрики в одном сообщении Telegram. При желании можно подключить Uptime Kuma, экспортёр Prometheus и бот‑получатель алертов.

### Основные возможности
- Асинхронный бот на **aiogram v3** (polling)
- Хранение настроек и авторизаций в SQLite
- Локализация RU/EN с переключением на лету
- Вкладки: Overview, Nodes, Users, Plans, Payments, Traffic, Alerts
- Опциональный дашборд [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- Опциональный экспортёр Prometheus и вебхуковый alert‑бот
- Ежедневные бэкапы SQLite и ротация логов

### Быстрый старт
```bash
curl -sL https://raw.githubusercontent.com/remnawave/remnawave-telegram-bot-monitoring/main/scripts/install.sh | bash
```
Скрипт установит Docker при необходимости, создаст `.env`, предложит включить Uptime Kuma или Prometheus и запустит весь стек.

Управлять стеком позже можно через `remna-tg-monitoring start|stop|status|links|help`.

### Переменные окружения
| Переменная | Описание |
| --- | --- |
| `BOT_TOKEN` | Токен телеграм‑бота |
| `BOT_USERNAME` | Имя бота для ссылок |
| `ACCESS_PASSWORD` | Пароль для `/login` |
| `REMNA_BASE_URLS` | Список URL панелей через запятую |
| `REMNA_AUTH_MODE` | `api_key` или `credentials` |
| `REMNA_API_KEY` | API‑ключ или пары `url\|key` |
| `REMNA_USERNAME` / `REMNA_PASSWORD` | Логин/пароль или `url\|user\|pass` |
| `REFRESH_DEFAULT` | Интервал обновления по умолчанию (сек) |
| `REFRESH_MIN` / `REFRESH_MAX` | Допустимые границы интервала |
| `LOG_FORMAT` | `text` или `json` |
| `LANG_DEFAULT` | Язык интерфейса по умолчанию `ru`/`en` |
| `ENABLE_KUMA` | `true` — запускать Uptime Kuma |
| `KUMA_URL` | Публичная ссылка на дашборд Kuma |
| `ENABLE_PROMETHEUS` | `true` — включить экспортёр и стек алертов |
| `METRICS_PORT` | Порт эндпойнта `/metrics` |
| `ALERT_BOT_TOKEN` | Токен бота для алертов |
| `ALERT_SECRET` | Пароль вебхука Alertmanager |
| `ALERT_CHAT_IDS` | Список Telegram ID для уведомлений |

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
- `/setalert <число>` – задать порог уведомлений

### Разработка
```bash
make format   # форматирование black
make lint     # ruff + mypy
make test     # юнит‑тесты
```

### Лицензия
Лицензия [MIT](LICENSE).
