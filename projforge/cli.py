from __future__ import annotations

import argparse
from pathlib import Path

from .case_scaffold import create_case
from .intake import add_files
from .build import build_db


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="caseforge",
        description="CaseForge (v1.x): per-case Evidence scaffolding + intake + build",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    # -------------------------
    # new-case
    # -------------------------
    new_case = sub.add_parser(
        "new-case",
        help="Create a new case (Evidence repo + data scaffold).",
    )
    new_case.add_argument(
        "--cases-home",
        default=".",
        help="Directory where all cases live (default: current directory).",
    )
    new_case.add_argument(
        "--case-id",
        required=True,
        help="Case identifier (example: 12343).",
    )
    new_case.add_argument(
        "--title",
        default=None,
        help="Display title (defaults to case-id).",
    )
    new_case.add_argument(
        "--template",
        default="default",
        help="Template name under CaseForge templates/ (default: default).",
    )
    new_case.add_argument(
        "--no-git",
        action="store_true",
        help="Do not scaffold Evidence template (creates empty case_root then writes pages/data/sources).",
    )

    # -------------------------
    # add-files
    # -------------------------
    addf = sub.add_parser(
        "add-files",
        help="Copy input files into data/raw and register them in data/manifest.json.",
    )
    addf.add_argument(
        "--case-root",
        default=".",
        help="Case repo root (default: current directory).",
    )
    addf.add_argument(
        "--vendor",
        required=True,
        help="Data vendor/source (examples: qlue, trm, manual).",
    )
    addf.add_argument(
        "--format",
        required=True,
        dest="data_format",
        help="Data format identifier (examples: qlue_account, qlue_utxo, trm_multi, manual).",
    )
    addf.add_argument(
        "--chain",
        default=None,
        help="Chain name (optional). For TRM multi-chain exports, omit this.",
    )
    addf.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite files in data/raw if they already exist.",
    )
    addf.add_argument(
        "files",
        nargs="+",
        help="File paths to add (CSV exports).",
    )

    # -------------------------
    # build-db
    # -------------------------
    bdb = sub.add_parser(
        "build-db",
        help="Generate data/load.sql from manifest+templates, then load into data/case.duckdb.",
    )
    bdb.add_argument(
        "--case-root",
        default=".",
        help="Case repo root (default: current directory).",
    )
    bdb.add_argument(
        "--duckdb-bin",
        default="duckdb",
        help="DuckDB executable name/path (default: duckdb).",
    )
    bdb.add_argument(
        "--sources",
        action="store_true",
        help="Also run `npm run sources` after building the DB.",
    )
    bdb.add_argument(
        "--no-npm-install",
        action="store_true",
        help="Do not auto-run npm install (only relevant with --sources).",
    )
    bdb.add_argument(
        "--no-regenerate-load",
        action="store_true",
        help="Do not regenerate data/load.sql from manifest/templates before building.",
    )

    return p


def main(argv: list[str] | None = None) -> int:
    p = build_parser()
    args = p.parse_args(argv)

    if args.cmd == "new-case":
        created = create_case(
            cases_home=Path(args.cases_home),
            case_id=args.case_id,
            title=args.title,
            template_name=args.template,
            no_git=args.no_git,
        )

        print("Created case:")
        print(f"  case_root:     {created.case_root}")
        print(f"  scaffold:      {created.scaffold_mode} (local template or git)")
        print(f"  duckdb:        {created.duckdb_path}")
        print(f"  source yaml:   {created.connection_yaml}")
        print("")
        print("Next steps:")
        print(f"  cd {created.case_root}")
        print("  npm install")
        print("  npm run dev")
        print("")
        print("Then (after you place CSVs into data/raw):")
        print("  python /path/to/CaseForge.py build-db --sources")
        return 0

    if args.cmd == "add-files":
        case_root = Path(args.case_root).expanduser().resolve()
        file_paths = [Path(x).expanduser() for x in args.files]

        added = add_files(
            case_root=case_root,
            files=file_paths,
            vendor=args.vendor,
            data_format=args.data_format,
            chain=args.chain,
            overwrite=args.overwrite,
        )

        print("Added files:")
        for a in added:
            print(f"  - {a.original_path} -> {a.vendor_path.relative_to(case_root)} (sha256={a.sha256[:12]}...)")
        print("Updated manifest: data/manifest.json")
        return 0

    if args.cmd == "build-db":
        case_root = Path(args.case_root).expanduser().resolve()
        build_db(
            case_root=case_root,
            duckdb_bin=args.duckdb_bin,
            run_sources=args.sources,
            ensure_npm=(not args.no_npm_install),
            regenerate_load=(not args.no_regenerate_load),
        )
        print("DB build complete.")
        if args.sources:
            print("Evidence sources refreshed (npm run sources).")
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
