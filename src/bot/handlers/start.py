from __future__ import annotations

from aiogram import Router
from aiogram.filters import Command
from aiogram.types import Message

from ..services.i18n import I18n

router = Router()


@router.message(Command("start"))
async def cmd_start(message: Message) -> None:  # pragma: no cover - simple forwarding
    i18n = I18n()
    await message.answer(i18n.t("start"))
