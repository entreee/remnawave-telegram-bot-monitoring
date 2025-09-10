from __future__ import annotations

from typing import List

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class AlertConfig(BaseSettings):
    """Configuration for the alert forwarding bot."""

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    token: str = Field(alias="ALERT_BOT_TOKEN")
    secret: str = Field(alias="ALERT_SECRET")
    chat_ids: List[int] = Field(default_factory=list, alias="ALERT_CHAT_IDS")
    lang_default: str = Field("ru", alias="LANG_DEFAULT")

    @field_validator("chat_ids", mode="before")
    @classmethod
    def _split(cls, value: str | List[int]) -> List[int]:
        if isinstance(value, str):
            return [int(x.strip()) for x in value.split(",") if x.strip()]
        return value
