from __future__ import annotations

import base64
from typing import Any

from aiohttp import web
from aiogram import Bot

from .config import AlertConfig

cfg = AlertConfig()  # type: ignore[call-arg]
bot = Bot(cfg.token)


def _check_auth(request: web.Request) -> bool:
    auth = request.headers.get("Authorization", "")
    expected = "Basic " + base64.b64encode(f"alert:{cfg.secret}".encode()).decode()
    return auth == expected


async def alerts(request: web.Request) -> web.Response:
    if not _check_auth(request):
        return web.Response(status=401)
    payload: dict[str, Any] = await request.json()
    for alert in payload.get("alerts", []):
        title = alert.get("labels", {}).get("alertname", "alert")
        severity = alert.get("labels", {}).get("severity", "info")
        description = alert.get("annotations", {}).get("description", "")
        text = f"{title}\nseverity: {severity}\n{description}"
        for chat_id in cfg.chat_ids:
            await bot.send_message(chat_id, text)
    return web.Response(text="ok")


app = web.Application()
app.router.add_post("/alerts", alerts)


if __name__ == "__main__":  # pragma: no cover
    web.run_app(app, port=8080)
