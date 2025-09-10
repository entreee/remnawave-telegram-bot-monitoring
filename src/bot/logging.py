from __future__ import annotations

import json
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path


def configure_logging(fmt: str = "text") -> None:
    """Configure global logging format.

    The real project would have a much more elaborate setup including
    structured logging.  For the purposes of the tests we only switch between
    a plain text and JSON formatter.
    """

    stream_handler = logging.StreamHandler()
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    file_handler = RotatingFileHandler(
        log_dir / "bot.log", maxBytes=1_000_000, backupCount=3
    )
    if fmt == "json":
        formatter = logging.Formatter(json.dumps({"msg": "%(message)s"}))
    else:
        formatter = logging.Formatter("%(levelname)s: %(message)s")
    stream_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(stream_handler)
    root.addHandler(file_handler)
    root.setLevel(logging.INFO)
