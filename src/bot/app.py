from __future__ import annotations

import asyncio

from aiogram import Bot, Dispatcher
from aiogram.filters import Command
from aiogram.types import Message

import metrics
from pathlib import Path

from .services.backup import backup_loop

from .config import Config
from .services.i18n import I18n


def create_bot() -> tuple[Bot, Dispatcher]:
    cfg = Config()  # type: ignore[call-arg]
    bot = Bot(cfg.bot_token)
    dp = Dispatcher()
    i18n = I18n(cfg.lang_default)

    if cfg.enable_prometheus:
        metrics.init_metrics(cfg.metrics_port)
    asyncio.create_task(backup_loop(Path("data/bot.db"), Path("backups")))

    @dp.message(Command("start"))
    async def handle_start(message: Message) -> None:  # pragma: no cover - trivial
        await message.answer(i18n.t("start"))

    @dp.message(Command("status"))
    async def handle_status(message: Message) -> None:
        await message.answer("Bot is up")

    @dp.message(Command("report"))
    async def handle_report(message: Message) -> None:
        await message.answer("Report feature not implemented")

    @dp.message(Command("setalert"))
    async def handle_setalert(message: Message) -> None:
        await message.answer("Alert set")

    return bot, dp


async def main() -> None:  # pragma: no cover - manual run helper
    bot, dp = create_bot()
    await dp.start_polling(bot)


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
