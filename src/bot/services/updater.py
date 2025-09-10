from __future__ import annotations

import asyncio
from typing import Callable


class MessageUpdater:
    """Periodically call a coroutine to update a message.

    The implementation is intentionally tiny; in the real project this would
    manage per-chat tasks and interact with Telegram APIs.
    """

    def __init__(self, interval: int, callback: Callable[[], asyncio.Future]):
        self.interval = interval
        self.callback = callback
        self._task: asyncio.Task | None = None

    async def _runner(self) -> None:
        while True:
            await self.callback()
            await asyncio.sleep(self.interval)

    def start(self) -> None:
        if not self._task:
            self._task = asyncio.create_task(self._runner())

    def stop(self) -> None:
        if self._task:
            self._task.cancel()
            self._task = None
