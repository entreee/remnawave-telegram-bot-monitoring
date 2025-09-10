#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path


def main() -> None:
    src = Path(__file__).resolve().parent.parent / ".env.example"
    dst = Path(__file__).resolve().parent.parent / ".env"
    shutil.copy(src, dst)


if __name__ == "__main__":  # pragma: no cover
    main()
