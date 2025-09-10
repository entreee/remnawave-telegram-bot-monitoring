from __future__ import annotations

import asyncio
from datetime import datetime
from pathlib import Path
import shutil


async def backup_loop(db_path: Path, backup_dir: Path) -> None:
    """Periodically dump SQLite database to timestamped files."""
    backup_dir.mkdir(parents=True, exist_ok=True)
    while True:
        if db_path.exists():
            ts = datetime.utcnow().strftime("%Y%m%d")
            dest = backup_dir / f"backup_{ts}.db"
            shutil.copy2(db_path, dest)
        await asyncio.sleep(24 * 3600)
