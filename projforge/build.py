from __future__ import annotations

import json
import subprocess
from pathlib import Path

from .intake import assert_case_root
from .loadgen import generate_load_sql
from .util import run


def _init_duckdb(db_path: Path, duckdb_bin: str, cwd: Path) -> None:
    subprocess.run([duckdb_bin, str(db_path), "-c", "select 1;"], cwd=str(cwd), check=True)


def _evidence_cli_path(case_root: Path) -> Path:
    return case_root / "node_modules" / ".bin" / "evidence"


def _ensure_node_deps(case_root: Path) -> None:
    if not _evidence_cli_path(case_root).exists():
        run(["npm", "install"], cwd=case_root)


def _preflight_manifest_files(case_root: Path) -> None:
    manifest_path = case_root / "data" / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing {manifest_path}. Run add-files first.")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    if not isinstance(files, list) or len(files) == 0:
        raise RuntimeError("manifest.json has no files. Run add-files first.")

    missing = []
    for entry in files:
        if not isinstance(entry, dict):
            continue
        stored = entry.get("stored_paths", {})
        if not isinstance(stored, dict):
            continue
        rel = stored.get("vendor")
        if not rel:
            continue
        p = case_root / rel
        if not p.exists():
            missing.append(str(p))

    if missing:
        msg = "Manifest references files that do not exist on disk:\n" + "\n".join(f"  - {m}" for m in missing)
        raise FileNotFoundError(msg)


def build_db(
    *,
    case_root: Path,
    duckdb_bin: str = "duckdb",
    run_sources: bool = False,
    ensure_npm: bool = True,
    regenerate_load: bool = True,
) -> None:
    """
    Build (or rebuild) the case DuckDB.

    - Preflight manifest paths
    - Generate data/load.sql (from templates/sql) based on manifest
    - Run duckdb with data/load.sql
    - Optionally run npm install + npm run sources
    """
    case_root = case_root.resolve()
    assert_case_root(case_root)

    _preflight_manifest_files(case_root)

    db_path = case_root / "data" / "case.duckdb"
    load_sql = case_root / "data" / "load.sql"

    if regenerate_load:
        generate_load_sql(case_root)

    if not load_sql.exists():
        raise FileNotFoundError(f"Missing loader SQL: {load_sql}")

    if db_path.exists() and db_path.stat().st_size == 0:
        db_path.unlink()

    try:
        _init_duckdb(db_path, duckdb_bin, case_root)
    except subprocess.CalledProcessError:
        if db_path.exists():
            db_path.unlink()
        _init_duckdb(db_path, duckdb_bin, case_root)

    with load_sql.open("rb") as sql_in:
        subprocess.run([duckdb_bin, str(db_path)], cwd=str(case_root), stdin=sql_in, check=True)

    if run_sources:
        if ensure_npm:
            _ensure_node_deps(case_root)
        run(["npm", "run", "sources"], cwd=case_root)

