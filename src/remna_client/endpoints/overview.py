from __future__ import annotations

from ..models import Overview


def parse(data: dict) -> Overview:
    """Parse raw dictionary data into :class:`Overview`."""
    return Overview(status=data.get("status", "unknown"))
