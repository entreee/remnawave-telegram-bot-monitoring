from __future__ import annotations

from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup


TABS = [
    ("overview", "Overview"),
    ("nodes", "Nodes"),
    ("users", "Users"),
    ("plans", "Plans"),
    ("payments", "Payments"),
    ("traffic", "Traffic"),
    ("alerts", "Alerts"),
]


def build_main_menu(
    enable_kuma: bool = False, kuma_url: str | None = None
) -> InlineKeyboardMarkup:
    buttons = [
        [InlineKeyboardButton(text=title, callback_data=cb)] for cb, title in TABS
    ]
    if enable_kuma and kuma_url:
        buttons.append([InlineKeyboardButton(text="Uptime Kuma", url=kuma_url)])
    return InlineKeyboardMarkup(inline_keyboard=buttons)
