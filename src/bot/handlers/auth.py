from __future__ import annotations

from aiogram import Router
from aiogram.types import Message

from ..config import Config
from ..services.access import AccessService

router = Router()


@router.message(lambda m: m.text and m.text.startswith("/login"))
async def cmd_login(message: Message) -> None:  # pragma: no cover - demonstration
    cfg = Config()  # type: ignore[call-arg]
    parts = message.text.split(maxsplit=1)
    if len(parts) == 2 and parts[1] == cfg.access_password:
        AccessService("data/bot.db").login(
            message.from_user.id, message.from_user.username or ""
        )
        await message.answer("ok")
    else:
        await message.answer("fail")


@router.message(lambda m: m.text == "/logout")
async def cmd_logout(message: Message) -> None:  # pragma: no cover - demonstration
    AccessService("data/bot.db").logout(message.from_user.id)
    await message.answer("logged out")
