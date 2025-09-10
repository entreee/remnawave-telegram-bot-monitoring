from __future__ import annotations

import asyncio
import random
import time

import httpx

from .auth import RemnaAuth
import metrics


class RemnaClient:
    """Tiny HTTP client with very small retry/backoff logic."""

    def __init__(self, base_url: str, auth: RemnaAuth) -> None:
        self.base_url = base_url
        self.auth = auth
        self.client = httpx.AsyncClient(base_url=base_url, timeout=10.0)

    async def get(self, path: str) -> httpx.Response:
        headers = await self.auth.get_headers(self.base_url)
        delay = 1.0
        for _ in range(5):
            start = time.perf_counter()
            resp = await self.client.get(path, headers=headers)
            duration = time.perf_counter() - start
            error = resp.status_code >= 400
            metrics.observe_api_request(self.base_url, duration, error)
            if resp.status_code < 400:
                return resp
            if resp.status_code in {429, 500, 502, 503, 504}:
                await asyncio.sleep(min(delay + random.random(), 60))
                delay *= 2
                continue
            resp.raise_for_status()
        return resp

    async def aclose(self) -> None:
        await self.client.aclose()
