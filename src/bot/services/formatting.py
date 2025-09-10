"""Utility helpers for formatting messages.

Only a stub is implemented; the full project would contain rich formatting
logic for each bot tab.
"""
from __future__ import annotations

from typing import Iterable


def format_table(rows: Iterable[Iterable[str]]) -> str:
    """Format an iterable of rows into a monospaced table."""
    return "\n".join(" | ".join(col for col in row) for row in rows)
