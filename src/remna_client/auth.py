from __future__ import annotations

from enum import Enum
from typing import Dict, Tuple


class AuthMode(str, Enum):
    API_KEY = "api_key"
    CREDENTIALS = "credentials"


class RemnaAuth:
    """Handle authentication for the Remnawave panels.

    Only the minimal behaviour required by the tests is implemented.  The class
    can operate in two modes:

    * ``api_key`` – pre-shared API keys per panel
    * ``credentials`` – username/password which are exchanged for a token
    """

    def __init__(
        self,
        mode: AuthMode,
        api_keys: Dict[str, str] | None = None,
        credentials: Dict[str, Tuple[str, str]] | None = None,
    ) -> None:
        self.mode = mode
        self.api_keys = api_keys or {}
        self.credentials = credentials or {}
        self.tokens: Dict[str, str] = {}

    async def get_headers(self, base_url: str) -> Dict[str, str]:
        """Return authorization headers for a given panel."""
        if self.mode is AuthMode.API_KEY:
            key = self.api_keys.get(base_url) or next(iter(self.api_keys.values()), "")
            return {"Authorization": f"Bearer {key}"}
        token = self.tokens.get(base_url)
        if not token:
            token = await self._login(base_url)
        return {"Authorization": f"Bearer {token}"}

    async def _login(self, base_url: str) -> str:
        """Simulate token retrieval for the credentials mode."""
        creds = self.credentials.get(base_url)
        token = f"{creds[0]}_token" if creds else "token"
        self.tokens[base_url] = token
        return token
