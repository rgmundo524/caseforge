from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set


MANIFEST_REL = Path("data/manifest.json")
PLACEHOLDER_TRANSFERS_UNION = "{{V_TRANSFERS_UNION}}"


@dataclass(frozen=True)
class LoadPlan:
    formats_present: Set[str]
    sql_fragments: List[Path]


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _templates_sql_dir() -> Path:
    return _repo_root() / "templates" / "sql"


def _load_manifest(case_root: Path) -> Dict:
    manifest_path = case_root / MANIFEST_REL
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing manifest: {manifest_path}. Run add-files first.")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def _normalize_format(fmt: str) -> str:
    f = (fmt or "").strip().lower()
    if f == "qule_account":
        f = "qlue_account"
    if f == "qule_utxo":
        f = "qlue_utxo"
    return f


def detect_formats_present(case_root: Path) -> Set[str]:
    manifest = _load_manifest(case_root)
    files = manifest.get("files", [])
    if not isinstance(files, list):
        raise RuntimeError("manifest.json has no 'files' array")

    formats: Set[str] = set()
    for entry in files:
        if not isinstance(entry, dict):
            continue
        fmt = _normalize_format(entry.get("format", ""))
        if fmt:
            formats.add(fmt)
    return formats


def plan_load(case_root: Path) -> LoadPlan:
    """
    Build the list of SQL fragments to include.

    Always includes (must exist):
      templates/sql/prelude.sql
      templates/sql/derived_views.sql

    Includes ingest fragments only if format is present in manifest:
      ingest_qlue_account.sql
      ingest_qlue_utxo.sql
      ingest_trm_multi.sql
    """
    formats = detect_formats_present(case_root)

    sql_dir = _templates_sql_dir()

    prelude = sql_dir / "prelude.sql"
    if not prelude.exists():
        raise FileNotFoundError(
            f"Missing {prelude}. Create templates/sql/prelude.sql (required)."
        )

    derived = sql_dir / "derived_views.sql"
    if not derived.exists():
        raise FileNotFoundError(
            f"Missing {derived}. Create templates/sql/derived_views.sql (required)."
        )

    fragments: List[Path] = [prelude]

    if "qlue_account" in formats:
        p = sql_dir / "ingest_qlue_account.sql"
        if not p.exists():
            raise FileNotFoundError(f"Missing {p}")
        fragments.append(p)

    if "qlue_utxo" in formats:
        p = sql_dir / "ingest_qlue_utxo.sql"
        if not p.exists():
            raise FileNotFoundError(f"Missing {p}")
        fragments.append(p)

    if "trm_multi" in formats:
        p = sql_dir / "ingest_trm_multi.sql"
        if not p.exists():
            raise FileNotFoundError(f"Missing {p}")
        fragments.append(p)

    fragments.append(derived)

    return LoadPlan(formats_present=formats, sql_fragments=fragments)


def _build_v_transfers_union(formats_present: Set[str]) -> str:
    sources: List[str] = []
    if "qlue_account" in formats_present:
        sources.append("v_map_qlue_account")
    if "qlue_utxo" in formats_present:
        sources.append("v_map_qlue_utxo")
    if "trm_multi" in formats_present:
        sources.append("v_map_trm")

    if not sources:
        return (
            "CREATE OR REPLACE VIEW v_transfers AS\n"
            "SELECT\n"
            "  NULL::VARCHAR AS vendor,\n"
            "  NULL::VARCHAR AS format,\n"
            "  NULL::VARCHAR AS chain,\n"
            "  NULL::TIMESTAMP AS ts,\n"
            "  NULL::VARCHAR AS tx_hash,\n"
            "  NULL::VARCHAR AS from_address,\n"
            "  NULL::VARCHAR AS to_address,\n"
            "  NULL::VARCHAR AS from_label,\n"
            "  NULL::VARCHAR AS to_label,\n"
            "  NULL::VARCHAR AS address_label,\n"
            "  NULL::VARCHAR AS direction,\n"
            "  NULL::VARCHAR AS asset,\n"
            "  NULL::DOUBLE AS amount_native,\n"
            "  NULL::DOUBLE AS amount_usd,\n"
            "  NULL::VARCHAR AS transfer_label,\n"
            "  NULL::INTEGER AS theft_id,\n"
            "  NULL::DOUBLE AS stolen_amount_native,\n"
            "  NULL::DOUBLE AS stolen_amount_usd,\n"
            "  NULL::VARCHAR AS source_file\n"
            "WHERE FALSE;\n"
        )

    lines: List[str] = []
    lines.append("CREATE OR REPLACE VIEW v_transfers AS")
    for i, view in enumerate(sources):
        prefix = "SELECT * FROM" if i == 0 else "UNION ALL SELECT * FROM"
        lines.append(f"{prefix} {view}")
    lines.append(";")
    return "\n".join(lines) + "\n"


def _render_fragment_text(path: Path, formats_present: Set[str]) -> str:
    text = path.read_text(encoding="utf-8")

    if path.name == "derived_views.sql":
        union_sql = _build_v_transfers_union(formats_present)
        if PLACEHOLDER_TRANSFERS_UNION not in text:
            raise RuntimeError(
                f"{path} missing placeholder {PLACEHOLDER_TRANSFERS_UNION}."
            )
        text = text.replace(PLACEHOLDER_TRANSFERS_UNION, union_sql)

    return text


def generate_load_sql(case_root: Path) -> Path:
    case_root = case_root.resolve()
    plan = plan_load(case_root)

    out_path = case_root / "data" / "load.sql"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    parts: List[str] = []
    parts.append("-- GENERATED FILE: data/load.sql\n")
    parts.append("-- Generated by CaseForge from templates/sql/*.sql\n")
    parts.append(f"-- Formats present: {', '.join(sorted(plan.formats_present)) or 'none'}\n")
    parts.append("--\n\n")

    for frag in plan.sql_fragments:
        parts.append("-- =========================\n")
        parts.append(f"-- BEGIN {frag.name}\n")
        parts.append("-- =========================\n\n")
        parts.append(_render_fragment_text(frag, plan.formats_present))
        if not parts[-1].endswith("\n"):
            parts.append("\n")
        parts.append("\n-- =========================\n")
        parts.append(f"-- END {frag.name}\n")
        parts.append("-- =========================\n\n")

    out_path.write_text("".join(parts), encoding="utf-8")
    return out_path

