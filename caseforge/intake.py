from __future__ import annotations

import hashlib
import json
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence

from .fs import ensure_dir
from .util import slugify


MANIFEST_REL = Path("data/manifest.json")


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _normalize_source(source: str) -> str:
    s = (source or "").strip().lower()
    if s not in {"trm", "qlue"}:
        raise ValueError("source must be one of: trm, qlue")
    return s


def _normalize_tx_model(model: Optional[str]) -> Optional[str]:
    if model is None:
        return None
    m = model.strip().lower()
    if not m:
        return None
    if m not in {"account", "utxo"}:
        raise ValueError("model must be one of: account, utxo")
    return m


def _normalize_export_type(export_type: Optional[str], source: str, tx_model: Optional[str]) -> str:
    et = (export_type or "").strip().lower()
    if et == "account":
        et = "qlue_account" if source == "qlue" else "trm"
    if et == "utxo":
        et = "qlue_utxo" if source == "qlue" else "trm"

    if source == "trm":
        if et and et != "trm":
            raise ValueError("TRM source supports only export_type=trm")
        if tx_model not in {"account", "utxo"}:
            raise ValueError("TRM files require --model account|utxo")
        return "trm"

    if source == "qlue":
        if et not in {"qlue_account", "qlue_utxo"}:
            if tx_model == "account":
                return "qlue_account"
            if tx_model == "utxo":
                return "qlue_utxo"
            raise ValueError("Qlue files require --export-type account|utxo (or qlue_account|qlue_utxo)")
        return et

    raise ValueError(f"Unsupported source: {source}")


def _normalize_blockchain(chain: Optional[str]) -> Optional[str]:
    if chain is None:
        return None
    c = chain.strip().lower()
    return c if c else None


def _load_manifest(case_root: Path) -> Dict[str, Any]:
    manifest_path = case_root / MANIFEST_REL
    if not manifest_path.exists():
        return {
            "schema_version": 2,
            "created_at": _utc_now_iso(),
            "updated_at": _utc_now_iso(),
            "files": [],
        }

    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise RuntimeError(f"manifest.json exists but is not valid JSON: {manifest_path}") from e

    if "files" not in data or not isinstance(data["files"], list):
        raise RuntimeError(f"manifest.json missing 'files' array: {manifest_path}")

    data.setdefault("schema_version", 2)
    data.setdefault("created_at", _utc_now_iso())
    data.setdefault("updated_at", _utc_now_iso())
    return data


def _save_manifest(case_root: Path, manifest: Dict[str, Any]) -> None:
    manifest_path = case_root / MANIFEST_REL
    ensure_dir(manifest_path.parent)
    manifest["updated_at"] = _utc_now_iso()
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def assert_case_root(case_root: Path) -> None:
    is_legacy_repo = (case_root / "package.json").exists() and (case_root / "pages").exists()
    is_workspace_sources_root = (case_root / "config" / "caseforge.json").exists() and (case_root / "data").exists()
    if is_legacy_repo or is_workspace_sources_root:
        return
    raise RuntimeError(
        "Not a compatible case root "
        f"(expected legacy package/pages or workspace Sources config/data): {case_root}"
    )


@dataclass(frozen=True)
class AddedFile:
    original_path: Path
    vendor_path: Path
    sha256: str


def _next_file_id(manifest: Dict[str, Any], src_name: str) -> str:
    base = slugify(Path(src_name).stem).replace("-", "_")
    base = f"f_{base}" if base and base[0].isdigit() else base
    if not base:
        base = "file"

    existing = {
        str(e.get("file_id"))
        for e in manifest.get("files", [])
        if isinstance(e, dict) and e.get("file_id")
    }
    candidate = base
    counter = 2
    while candidate in existing:
        candidate = f"{base}_{counter}"
        counter += 1
    return candidate


def add_files(
    *,
    case_root: Path,
    files: Sequence[Path],
    source_system: str,
    tx_model: Optional[str] = None,
    export_type: Optional[str] = None,
    blockchain: Optional[str] = None,
    overwrite: bool = False,
) -> List[AddedFile]:
    """
    Copy raw files into the case repo and register them in data/manifest.json.

    Files are stored under data/raw/<source_system>/<filename>.
    """
    case_root = case_root.expanduser().resolve()
    assert_case_root(case_root)

    source_n = _normalize_source(source_system)
    model_n = _normalize_tx_model(tx_model)
    export_n = _normalize_export_type(export_type, source_n, model_n)
    blockchain_n = _normalize_blockchain(blockchain)

    if source_n == "qlue" and not blockchain_n:
        raise ValueError("Qlue inputs require --blockchain because chain is not present in export CSVs")

    raw_vendor_dir = case_root / "data" / "raw" / source_n
    ensure_dir(raw_vendor_dir)

    manifest = _load_manifest(case_root)
    added: List[AddedFile] = []

    for src in files:
        src = src.expanduser().resolve()
        if not src.exists() or not src.is_file():
            raise FileNotFoundError(f"Input file not found: {src}")

        dest_vendor = raw_vendor_dir / src.name
        if dest_vendor.exists() and not overwrite:
            raise FileExistsError(f"Destination already exists (use --overwrite to replace): {dest_vendor}")

        shutil.copy2(src, dest_vendor)
        sha = _sha256_file(dest_vendor)
        file_id = _next_file_id(manifest, src.name)

        entry = {
            "added_at": _utc_now_iso(),
            "source_system": source_n,
            "export_type": export_n,
            "tx_model": model_n,
            "blockchain": blockchain_n,
            "source_file": src.name,
            "file_id": file_id,
            "sha256": sha,
            "original_path": str(src),
            "stored_paths": {
                "vendor": str(dest_vendor.relative_to(case_root)),
            },
            # Backward-compatible keys
            "vendor": source_n,
            "format": export_n,
            "chain": blockchain_n,
            "filename": src.name,
        }
        manifest["files"].append(entry)

        added.append(
            AddedFile(
                original_path=src,
                vendor_path=dest_vendor,
                sha256=sha,
            )
        )

    _save_manifest(case_root, manifest)
    return added
