from __future__ import annotations

import sqlite3
from pathlib import Path


DEFAULT_DB_PATH = Path("data/bot.db")


def get_connection(path: str | Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Return a SQLite connection.  The database is created if it does not exist."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    return conn
