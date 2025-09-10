from __future__ import annotations

from typing import List

from ..models import Node


def parse(data: list[dict]) -> List[Node]:
    """Parse list of nodes."""
    return [Node(**item) for item in data]
