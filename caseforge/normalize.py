from __future__ import annotations

import csv
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

from .intake import MANIFEST_REL, assert_case_root


NORMALIZED_COLUMNS = [
    "vendor",
    "tx_model",
    "source_file",
    "blockchain",
    "time",
    "tx",
    "tx_label",
    "source_address",
    "source_label",
    "source_group",
    "source_group_description",
    "destination_address",
    "destination_label",
    "destination_group",
    "destination_group_description",
    "asset",
    "value",
    "usd",
]

REQUIRED_HEADERS = {
    # Keep validation strict enough to prevent wrong export wiring, but only require
    # columns that are actually consumed by the normalizer SQL.
    "trm": {
        "Type",
        "Chain",
        "Address",
        "Entity URN",
        "Name",
        "Categories",
        "Notes",
        "Txn Hash",
        "Timestamp",
        "From",
        "To",
        "Asset",
        "Value",
        "Value USD",
    },
    "qlue_account": {
        "Time",
        "Transfer Label",
        "Transaction",
        "Source Address Label",
        "Source Address Hash",
        "Source Group",
        "Source Group Description",
        "Recipient Address Label",
        "Recipient Address Hash",
        "Recipient Group",
        "Recipient Group Description",
        "Crypto Value",
        "Crypto Asset",
        "USD",
    },
    "qlue_utxo": {
        "Time",
        "Transaction Label",
        "Transaction Hash",
        "Address Label",
        "Address Hash",
        "Crypto Value",
        "Token Policy",
        "USD",
        "Direction",
        "Source Group",
        "Source Group Description",
        "Recipient Group",
        "Recipient Group Description",
    },
}



@dataclass(frozen=True)
class NormalizationEntry:
    source_system: str
    export_type: str
    tx_model: str
    blockchain: Optional[str]
    source_file: str
    file_id: str
    raw_path: Path


@dataclass(frozen=True)
class NormalizationTemplate:
    name: str
    path: Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _sql_template_dir() -> Path:
    return _repo_root() / "templates" / "sql" / "normalize"


def _load_manifest(case_root: Path) -> Dict[str, Any]:
    manifest_path = case_root / MANIFEST_REL
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing {manifest_path}. Run add-files first.")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def _clean_str(value: Any) -> Optional[str]:
    if value is None:
        return None
    s = str(value).strip()
    return s if s else None


def _safe_identifier(value: str) -> str:
    token = re.sub(r"[^a-z0-9_]", "_", value.lower())
    token = re.sub(r"_+", "_", token).strip("_")
    if not token:
        token = "file"
    if token[0].isdigit():
        token = f"f_{token}"
    return token


def _legacy_export_type(entry: Dict[str, Any]) -> Optional[str]:
    fmt = _clean_str(entry.get("format"))
    if not fmt:
        return None
    normalized = fmt.lower()
    if normalized == "trm_multi":
        return "trm"
    if normalized in {"qlue_account", "qlue_utxo"}:
        return normalized
    return None


def _entry_from_manifest(case_root: Path, entry: Dict[str, Any], idx: int) -> NormalizationEntry:
    source_system = (_clean_str(entry.get("source_system")) or _clean_str(entry.get("vendor")) or "").lower()
    export_type = (_clean_str(entry.get("export_type")) or _legacy_export_type(entry) or "").lower()
    tx_model = (_clean_str(entry.get("tx_model")) or "").lower()

    if not tx_model and export_type == "qlue_account":
        tx_model = "account"
    if not tx_model and export_type == "qlue_utxo":
        tx_model = "utxo"

    if export_type == "trm" and tx_model not in {"account", "utxo"}:
        raise RuntimeError(
            "TRM entries require tx_model (account|utxo). Re-add the file with: "
            "caseforge add-files <file> --source trm --model account|utxo"
        )

    blockchain = _clean_str(entry.get("blockchain") or entry.get("chain"))
    if source_system == "qlue" and not blockchain:
        raise RuntimeError("Qlue entries require blockchain metadata. Re-add with --blockchain.")

    source_file = _clean_str(entry.get("source_file") or entry.get("filename"))
    if not source_file:
        raise RuntimeError("Manifest entry is missing source_file/filename.")

    stored_paths = entry.get("stored_paths", {})
    rel_raw = _clean_str(stored_paths.get("vendor") if isinstance(stored_paths, dict) else None)
    if not rel_raw:
        raise RuntimeError(f"Manifest entry for {source_file} is missing stored_paths.vendor")

    raw_path = case_root / rel_raw
    if not raw_path.exists():
        raise FileNotFoundError(f"Raw file referenced by manifest does not exist: {raw_path}")

    file_id = _clean_str(entry.get("file_id"))
    if not file_id:
        stem = Path(source_file).stem
        file_id = _safe_identifier(f"{idx}_{stem}")

    if export_type not in {"trm", "qlue_account", "qlue_utxo"}:
        raise RuntimeError(f"Unsupported export_type '{export_type}' for {source_file}")

    return NormalizationEntry(
        source_system=source_system,
        export_type=export_type,
        tx_model=tx_model,
        blockchain=blockchain,
        source_file=source_file,
        file_id=_safe_identifier(file_id),
        raw_path=raw_path,
    )


def _iter_entries(case_root: Path, manifest: Dict[str, Any]) -> Iterable[NormalizationEntry]:
    files = manifest.get("files", [])
    if not isinstance(files, list) or not files:
        raise RuntimeError("manifest.json has no files. Run add-files first.")
    for idx, entry in enumerate(files, start=1):
        if not isinstance(entry, dict):
            continue
        yield _entry_from_manifest(case_root, entry, idx)


def _read_headers(csv_path: Path) -> set[str]:
    with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        header = next(reader, [])
    return {h.strip() for h in header if h is not None and str(h).strip()}


def _validate_headers(entry: NormalizationEntry) -> None:
    required = REQUIRED_HEADERS[entry.export_type]
    present = _read_headers(entry.raw_path)
    missing = sorted(required - present)
    if missing:
        raise RuntimeError(
            "Header validation failed for file "
            f"{entry.raw_path} (expected export_type={entry.export_type}). Missing columns: {', '.join(missing)}"
        )


def _template_for(entry: NormalizationEntry) -> NormalizationTemplate:
    sql_dir = _sql_template_dir()
    mapping = {
        ("trm", "account"): "trm_account.sql",
        ("trm", "utxo"): "trm_utxo.sql",
        ("qlue_account", "account"): "qlue_account.sql",
        ("qlue_utxo", "utxo"): "qlue_utxo.sql",
    }
    key = (entry.export_type, entry.tx_model)
    file_name = mapping.get(key)
    if not file_name:
        raise RuntimeError(
            f"No normalizer for source_system={entry.source_system}, export_type={entry.export_type}, tx_model={entry.tx_model}"
        )
    path = sql_dir / file_name
    if not path.exists():
        raise FileNotFoundError(f"Missing SQL template: {path}")
    return NormalizationTemplate(name=file_name, path=path)


def _render_template(template_text: str, *, raw_table: str, file_id: str, source_file: str, blockchain: Optional[str]) -> str:
    replacements = {
        "{{RAW_TABLE}}": raw_table,
        "{{FILE_ID}}": file_id,
        "{{SOURCE_FILE}}": source_file.replace("'", "''"),
        "{{BLOCKCHAIN}}": (blockchain or "").replace("'", "''"),
    }
    rendered = template_text
    for token, value in replacements.items():
        rendered = rendered.replace(token, value)
    return rendered


def _run_sql(db_path: Path, sql: str, duckdb_bin: str, cwd: Path) -> None:
    subprocess.run(
        [duckdb_bin, str(db_path)],
        cwd=str(cwd),
        input=sql.encode("utf-8"),
        check=True,
    )


def normalize_db(*, case_root: Path, duckdb_bin: str = "duckdb") -> None:
    case_root = case_root.resolve()
    assert_case_root(case_root)

    manifest = _load_manifest(case_root)
    entries = list(_iter_entries(case_root, manifest))

    db_path = case_root / "data" / "case.duckdb"

    bootstrap_sql = f"""
    CREATE OR REPLACE TABLE normalized_combined_transactions (
      vendor VARCHAR,
      tx_model VARCHAR,
      source_file VARCHAR,
      blockchain VARCHAR,
      time TIMESTAMP,
      tx VARCHAR,
      tx_label VARCHAR,
      source_address VARCHAR,
      source_label VARCHAR,
      source_group VARCHAR,
      source_group_description VARCHAR,
      destination_address VARCHAR,
      destination_label VARCHAR,
      destination_group VARCHAR,
      destination_group_description VARCHAR,
      asset VARCHAR,
      value DOUBLE,
      usd DOUBLE
    );

    CREATE OR REPLACE VIEW v_normalized_transactions AS
    SELECT * FROM normalized_combined_transactions;
    """
    _run_sql(db_path, bootstrap_sql, duckdb_bin, case_root)

    for entry in entries:
        _validate_headers(entry)

        raw_table = f"raw_{entry.file_id}"
        template = _template_for(entry)
        template_text = template.path.read_text(encoding="utf-8")
        normalized_sql = _render_template(
            template_text,
            raw_table=raw_table,
            file_id=entry.file_id,
            source_file=entry.source_file,
            blockchain=entry.blockchain,
        )

        load_sql = f"""
        CREATE OR REPLACE TEMP TABLE {raw_table} AS
        SELECT *
        FROM read_csv_auto('{entry.raw_path.as_posix().replace("'", "''")}', header=true, union_by_name=true);

        {normalized_sql}

        INSERT INTO normalized_combined_transactions ({", ".join(NORMALIZED_COLUMNS)})
        SELECT {", ".join(NORMALIZED_COLUMNS)}
        FROM norm_{entry.file_id};
        """
        _run_sql(db_path, load_sql, duckdb_bin, case_root)
