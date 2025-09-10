import pytest

from remna_client.auth import AuthMode, RemnaAuth


@pytest.mark.asyncio
async def test_api_key_headers():
    auth = RemnaAuth(AuthMode.API_KEY, api_keys={"https://a": "key"})
    headers = await auth.get_headers("https://a")
    assert headers["Authorization"] == "Bearer key"


@pytest.mark.asyncio
async def test_credentials_headers():
    auth = RemnaAuth(AuthMode.CREDENTIALS, credentials={"https://a": ("user", "pass")})
    headers = await auth.get_headers("https://a")
    assert headers["Authorization"] == "Bearer user_token"
