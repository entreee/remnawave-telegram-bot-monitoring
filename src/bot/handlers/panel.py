from __future__ import annotations

from aiogram import Router
from aiogram.types import Message

router = Router()


@router.message(lambda m: m.text == "/panel")
async def cmd_panel(message: Message) -> None:  # pragma: no cover - placeholder
    await message.answer("panel selection")
