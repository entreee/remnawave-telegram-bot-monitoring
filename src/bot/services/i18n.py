from __future__ import annotations

from dataclasses import dataclass
from typing import Dict


TRANSLATIONS: Dict[str, Dict[str, str]] = {
    "en": {
        "start": "Start",
        "help": "Help",
    },
    "ru": {
        "start": "Старт",
        "help": "Помощь",
    },
}


@dataclass
class I18n:
    """Very small helper that mimics a translation system."""

    default: str = "ru"

    def t(self, key: str, lang: str | None = None) -> str:
        lang = lang or self.default
        return TRANSLATIONS.get(lang, {}).get(key, key)
