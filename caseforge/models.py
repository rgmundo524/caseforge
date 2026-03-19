from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CaseCreated:
    """Return value for case creation."""

    case_root: Path
    slug: str
    scaffold_mode: str  # "local" | "git" | "none"
    duckdb_path: Path
    connection_yaml: Path
