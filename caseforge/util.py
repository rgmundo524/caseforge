from __future__ import annotations

import datetime as dt
import re
import subprocess
from pathlib import Path
from typing import Optional


def slugify(s: str) -> str:
    """Convert an identifier into a filesystem-friendly slug."""
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-{2,}", "-", s).strip("-")
    return s or "case"


def now_stamp() -> str:
    """Timestamp used in case directory names (local time)."""
    return dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def run(cmd: list[str], cwd: Optional[Path] = None) -> None:
    """Run a subprocess command; raises on failure."""
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)
