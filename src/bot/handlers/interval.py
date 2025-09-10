from __future__ import annotations

from aiogram import Router
from aiogram.types import Message

router = Router()


@router.message(lambda m: m.text and m.text.startswith("/interval"))
async def cmd_interval(message: Message) -> None:  # pragma: no cover - placeholder
    await message.answer("interval updated")
