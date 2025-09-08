from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ChatSettings:
    """Represents minimal settings stored for each chat."""

    chat_id: int
    refresh_interval: int
    language: str
