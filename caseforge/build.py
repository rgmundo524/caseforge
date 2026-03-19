from __future__ import annotations

import subprocess
from pathlib import Path

from .intake import assert_case_root
from .util import run


def _init_duckdb(db_path: Path, duckdb_bin: str, cwd: Path) -> None:
    subprocess.run([duckdb_bin, str(db_path), "-c", "select 1;"], cwd=str(cwd), check=True)


def _evidence_cli_path(case_root: Path) -> Path:
    return case_root / "node_modules" / ".bin" / "evidence"


def _ensure_node_deps(case_root: Path) -> None:
    if not _evidence_cli_path(case_root).exists():
        run(["npm", "install"], cwd=case_root)


def _build_sql_path() -> Path:
    return Path(__file__).resolve().parent.parent / "templates" / "sql" / "build_from_normalized.sql"


def _assert_normalized_table(case_root: Path, db_path: Path, duckdb_bin: str) -> None:
    sql = """
    SELECT count(*)
    FROM information_schema.tables
    WHERE lower(table_name) = 'normalized_combined_transactions';
    """
    result = subprocess.run(
        [duckdb_bin, str(db_path), "-c", sql],
        cwd=str(case_root),
        capture_output=True,
        text=True,
        check=True,
    )
    if "0" in result.stdout.split():
        raise RuntimeError(
            "normalized_combined_transactions was not found. Run `caseforge normalize` before `caseforge build-db`."
        )


def build_db(
    *,
    case_root: Path,
    duckdb_bin: str = "duckdb",
    run_sources: bool = False,
    ensure_npm: bool = True,
) -> None:
    """
    Build (or rebuild) case-level derived views/tables from normalized_combined_transactions.
    """
    case_root = case_root.resolve()
    assert_case_root(case_root)

    db_path = case_root / "data" / "case.duckdb"
    if db_path.exists() and db_path.stat().st_size == 0:
        db_path.unlink()

    _init_duckdb(db_path, duckdb_bin, case_root)
    _assert_normalized_table(case_root, db_path, duckdb_bin)

    build_sql = _build_sql_path()
    if not build_sql.exists():
        raise FileNotFoundError(f"Missing build SQL template: {build_sql}")

    with build_sql.open("rb") as sql_in:
        subprocess.run([duckdb_bin, str(db_path)], cwd=str(case_root), stdin=sql_in, check=True)

    if run_sources:
        if ensure_npm:
            _ensure_node_deps(case_root)
        run(["npm", "run", "sources"], cwd=case_root)
