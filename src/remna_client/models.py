from __future__ import annotations

from pydantic import BaseModel


class Overview(BaseModel):
    status: str = "unknown"


class Node(BaseModel):
    name: str
    status: str
    cpu: float | None = None
