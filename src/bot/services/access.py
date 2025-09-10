from __future__ import annotations

import sqlite3
from pathlib import Path


class AccessService:
    """Simple SQLite based access control."""

    def __init__(self, db_path: str | Path):
        self.db_path = Path(db_path)
        self._init_db()

    def _init_db(self) -> None:
        conn = sqlite3.connect(self.db_path)
        conn.execute(
            "CREATE TABLE IF NOT EXISTS access (user_id INTEGER PRIMARY KEY, username TEXT, ts REAL)"
        )
        conn.commit()
        conn.close()

    # CRUD operations -------------------------------------------------
    def login(self, user_id: int, username: str) -> None:
        conn = sqlite3.connect(self.db_path)
        conn.execute(
            "INSERT OR REPLACE INTO access(user_id, username, ts) VALUES (?, ?, strftime('%s','now'))",
            (user_id, username),
        )
        conn.commit()
        conn.close()

    def logout(self, user_id: int) -> None:
        conn = sqlite3.connect(self.db_path)
        conn.execute("DELETE FROM access WHERE user_id = ?", (user_id,))
        conn.commit()
        conn.close()

    def is_authorized(self, user_id: int) -> bool:
        conn = sqlite3.connect(self.db_path)
        cur = conn.execute("SELECT 1 FROM access WHERE user_id = ?", (user_id,))
        row = cur.fetchone()
        conn.close()
        return row is not None
