from __future__ import annotations

import asyncio

from aiogram import Bot, Dispatcher
from aiogram.filters import Command
from aiogram.types import Message

from .config import Config
from .services.i18n import I18n


def create_bot() -> tuple[Bot, Dispatcher]:
    cfg = Config()  # type: ignore[call-arg]
    bot = Bot(cfg.bot_token)
    dp = Dispatcher()
    i18n = I18n(cfg.lang_default)

    @dp.message(Command("start"))
    async def handle_start(message: Message) -> None:  # pragma: no cover - trivial
        await message.answer(i18n.t("start"))

    return bot, dp


async def main() -> None:  # pragma: no cover - manual run helper
    bot, dp = create_bot()
    await dp.start_polling(bot)


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
