from __future__ import annotations

from aiogram import Router
from aiogram.types import CallbackQuery

router = Router()


@router.callback_query()
async def handle_callback(
    callback: CallbackQuery,
) -> None:  # pragma: no cover - placeholder
    await callback.answer()
