from __future__ import annotations

from aiogram import Router
from aiogram.types import Message

router = Router()


@router.message(lambda m: m.text and m.text.startswith("/lang"))
async def cmd_lang(message: Message) -> None:  # pragma: no cover - placeholder
    await message.answer("language updated")
