from __future__ import annotations

import hashlib
import json
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence

from .fs import ensure_dir


MANIFEST_REL = Path("data/manifest.json")


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _normalize_vendor(vendor: str) -> str:
    v = (vendor or "").strip().lower()
    if not v:
        raise ValueError("vendor must be a non-empty string (examples: qlue, trm, manual)")
    return v


def _normalize_format(fmt: str) -> str:
    f = (fmt or "").strip().lower()
    if not f:
        raise ValueError("format must be a non-empty string (examples: qlue_account, qlue_utxo, trm_multi, manual)")

    # Common typo normalization
    if f == "qule_account":
        f = "qlue_account"
    if f == "qule_utxo":
        f = "qlue_utxo"

    return f


def _normalize_chain(chain: Optional[str]) -> Optional[str]:
    if chain is None:
        return None
    c = chain.strip().lower()
    return c if c else None


def _load_manifest(case_root: Path) -> Dict[str, Any]:
    manifest_path = case_root / MANIFEST_REL
    if not manifest_path.exists():
        return {
            "schema_version": 1,
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

    data.setdefault("schema_version", 1)
    data.setdefault("created_at", _utc_now_iso())
    data.setdefault("updated_at", _utc_now_iso())
    return data


def _save_manifest(case_root: Path, manifest: Dict[str, Any]) -> None:
    manifest_path = case_root / MANIFEST_REL
    ensure_dir(manifest_path.parent)
    manifest["updated_at"] = _utc_now_iso()
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def assert_case_root(case_root: Path) -> None:
    if not (case_root / "package.json").exists():
        raise RuntimeError(f"Not a case repo (missing package.json): {case_root}")
    if not (case_root / "pages").exists():
        raise RuntimeError(f"Not a case repo (missing pages/): {case_root}")


@dataclass(frozen=True)
class AddedFile:
    original_path: Path
    vendor_path: Path
    sha256: str


def add_files(
    *,
    case_root: Path,
    files: Sequence[Path],
    vendor: str,
    data_format: str,
    chain: Optional[str] = None,
    overwrite: bool = False,
) -> List[AddedFile]:
    """
    Copy raw files into the case repo and register them in data/manifest.json.

    New behavior:
    - Store a single copy only under: data/raw/<vendor>/<filename>
    - Do not duplicate into data/raw/<filename>

    Manifest records the stored vendor path.

    Returns:
      list of AddedFile (paths + sha256)
    """
    case_root = case_root.expanduser().resolve()
    assert_case_root(case_root)

    vendor_n = _normalize_vendor(vendor)
    fmt_n = _normalize_format(data_format)
    chain_n = _normalize_chain(chain)

    raw_vendor_dir = case_root / "data" / "raw" / vendor_n
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

        entry = {
            "added_at": _utc_now_iso(),
            "vendor": vendor_n,
            "format": fmt_n,
            "chain": chain_n,
            "filename": src.name,
            "sha256": sha,
            "original_path": str(src),
            "stored_paths": {
                "vendor": str(dest_vendor.relative_to(case_root)),
            },
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

