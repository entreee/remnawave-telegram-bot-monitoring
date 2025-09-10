from __future__ import annotations

from aiohttp import web


async def handle_health(_: web.Request) -> web.Response:
    return web.Response(text="ok")


def create_app() -> web.Application:
    app = web.Application()
    app.router.add_get("/healthz", handle_health)
    return app
