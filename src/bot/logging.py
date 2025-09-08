from __future__ import annotations

import json
import logging


def configure_logging(fmt: str = "text") -> None:
    """Configure global logging format.

    The real project would have a much more elaborate setup including
    structured logging.  For the purposes of the tests we only switch between
    a plain text and JSON formatter.
    """

    handler = logging.StreamHandler()
    if fmt == "json":
        formatter = logging.Formatter(json.dumps({"msg": "%(message)s"}))
    else:
        formatter = logging.Formatter("%(levelname)s: %(message)s")
    handler.setFormatter(formatter)
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO)
