from __future__ import annotations

from typing import Dict, List, Tuple

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, EnvSettingsSource, SettingsConfigDict


class PlainEnv(EnvSettingsSource):
    """Environment source that returns raw values without JSON parsing."""

    def decode_complex_value(
        self, field_name, field, value
    ):  # pragma: no cover - passthrough
        return value


class Config(BaseSettings):
    """Application configuration loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    bot_token: str = Field(alias="BOT_TOKEN")
    access_password: str = Field(alias="ACCESS_PASSWORD")

    remna_base_urls: List[str] = Field(default_factory=list, alias="REMNA_BASE_URLS")
    remna_auth_mode: str = Field("api_key", alias="REMNA_AUTH_MODE")
    remna_api_key: str | Dict[str, str] | None = Field(None, alias="REMNA_API_KEY")
    remna_username: str | Dict[str, Tuple[str, str]] | None = Field(
        None, alias="REMNA_USERNAME"
    )
    remna_password: str | None = Field(None, alias="REMNA_PASSWORD")

    refresh_default: int = Field(15, alias="REFRESH_DEFAULT")
    refresh_min: int = Field(1, alias="REFRESH_MIN")
    refresh_max: int = Field(3600, alias="REFRESH_MAX")

    log_format: str = Field("text", alias="LOG_FORMAT")
    lang_default: str = Field("ru", alias="LANG_DEFAULT")

    enable_kuma: bool = Field(False, alias="ENABLE_KUMA")
    kuma_url: str | None = Field(None, alias="KUMA_URL")

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls,
        init_settings,
        env_settings,
        dotenv_settings,
        file_secret_settings,
    ):
        return (
            init_settings,
            PlainEnv(settings_cls),
            dotenv_settings,
            file_secret_settings,
        )

    @field_validator("remna_base_urls", mode="before")
    @classmethod
    def _split_urls(cls, value: str | List[str]) -> List[str]:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator("remna_api_key", mode="before")
    @classmethod
    def _parse_api_key(cls, value: str | None) -> str | Dict[str, str] | None:
        if value and "|" in value:
            mapping: Dict[str, str] = {}
            for item in value.split(","):
                if "|" not in item:
                    continue
                url, key = item.split("|", 1)
                mapping[url.strip()] = key.strip()
            return mapping
        return value

    @field_validator("remna_username", mode="before")
    @classmethod
    def _parse_usernames(
        cls, value: str | None
    ) -> str | Dict[str, Tuple[str, str]] | None:
        if value and "|" in value:
            mapping: Dict[str, Tuple[str, str]] = {}
            for item in value.split(","):
                parts = item.split("|")
                if len(parts) != 3:
                    continue
                url, user, pwd = parts
                mapping[url.strip()] = (user.strip(), pwd.strip())
            return mapping
        return value

    # ------------------------------------------------------------------
    # Helper properties
    # ------------------------------------------------------------------
    @property
    def api_key_map(self) -> Dict[str, str]:
        if isinstance(self.remna_api_key, dict):
            return self.remna_api_key
        if isinstance(self.remna_api_key, str):
            return {url: self.remna_api_key for url in self.remna_base_urls}
        return {}

    @property
    def credentials_map(self) -> Dict[str, Tuple[str, str]]:
        if isinstance(self.remna_username, dict):
            return self.remna_username
        if self.remna_username and self.remna_password:
            return {
                url: (self.remna_username, self.remna_password)
                for url in self.remna_base_urls
            }
        return {}
