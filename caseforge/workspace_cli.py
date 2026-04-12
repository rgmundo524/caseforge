from __future__ import annotations

import argparse
from pathlib import Path

from .build import build_db
from .intake import add_files
from .normalize import normalize_db
from .workspace import (
    build_web_draft,
    ensure_workspace_sources_engine_bridge,
    init_workspace,
)


def _init_workspace_cmd(args: argparse.Namespace) -> int:
    try:
        workspace_root = init_workspace(
            cases_home=Path(args.cases_home),
            case_id=args.case_id,
            title=args.title,
            template=args.template,
            features=args.features or [],
        )
    except (ValueError, RuntimeError) as exc:
        raise SystemExit(str(exc)) from exc

    print("Initialized workspace:")
    print(f"  workspace_root: {workspace_root}")
    print(f"  manifest:       {workspace_root / '.caseforge' / 'workspace.json'}")
    return 0


def _build_web_draft_cmd(args: argparse.Namespace) -> int:
    try:
        snapshot_path, draft_path = build_web_draft(
            workspace_root=Path(args.workspace_root),
            output_name=args.output_name,
        )
    except (ValueError, RuntimeError) as exc:
        raise SystemExit(str(exc)) from exc

    print("Built web draft:")
    print(f"  snapshot:       {snapshot_path}")
    print(f"  draft_index:    {draft_path}")
    return 0


def _derive_export_type(*, source: str, model: str | None, export_type: str | None) -> str | None:
    if export_type:
        return export_type
    source = (source or "").strip().lower()
    model = (model or "").strip().lower()
    if source == "qlue" and model in {"account", "utxo"}:
        return f"qlue_{model}"
    if source == "trm":
        return "trm"
    return export_type


def _add_files_cmd(args: argparse.Namespace) -> int:
    try:
        case_root = ensure_workspace_sources_engine_bridge(workspace_root=Path(args.workspace_root))
        files = [Path(path).resolve() for path in args.files]
        add_files(
            case_root=case_root,
            files=files,
            source_system=args.source,
            tx_model=args.model,
            export_type=_derive_export_type(source=args.source, model=args.model, export_type=args.export_type),
            blockchain=args.blockchain,
        )
    except (ValueError, RuntimeError, FileNotFoundError, FileExistsError) as exc:
        raise SystemExit(str(exc)) from exc

    print(f"Added {len(args.files)} file(s) to workspace sources:")
    print(f"  case_root:      {case_root}")
    return 0


def _normalize_cmd(args: argparse.Namespace) -> int:
    try:
        case_root = ensure_workspace_sources_engine_bridge(workspace_root=Path(args.workspace_root))
        normalize_db(
            case_root=case_root,
            duckdb_bin=args.duckdb_bin,
        )
    except (ValueError, RuntimeError, FileNotFoundError) as exc:
        raise SystemExit(str(exc)) from exc

    print("Normalized workspace sources:")
    print(f"  case_root:      {case_root}")
    return 0


def _build_db_cmd(args: argparse.Namespace) -> int:
    try:
        case_root = ensure_workspace_sources_engine_bridge(workspace_root=Path(args.workspace_root))
        build_db(
            case_root=case_root,
            duckdb_bin=args.duckdb_bin,
            run_sources=False,
        )
    except (ValueError, RuntimeError, FileNotFoundError) as exc:
        raise SystemExit(str(exc)) from exc

    print("Built workspace database:")
    print(f"  case_root:      {case_root}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="caseworkspace")
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init-workspace", help="Initialize a persistent case workspace")
    p_init.add_argument("--cases-home", required=True, help="Directory where workspaces are created")
    p_init.add_argument("--case-id", required=True, help="Case identifier")
    p_init.add_argument("--title", required=True, help="Human-readable case title")
    p_init.add_argument("--template", required=True, help="Primary template name")
    p_init.add_argument("--feature", dest="features", action="append", help="Feature flag (repeatable)")
    p_init.set_defaults(func=_init_workspace_cmd)

    p_web = sub.add_parser("build-web-draft", help="Build snapshot and minimal web draft page")
    p_web.add_argument("--workspace-root", required=True, help="Workspace root directory")
    p_web.add_argument("--output-name", required=True, help="Output name under WEB/")
    p_web.set_defaults(func=_build_web_draft_cmd)

    p_add = sub.add_parser("add-files", help="Register raw input files under workspace Sources")
    p_add.add_argument("files", nargs="+", help="Files to register")
    p_add.add_argument("--workspace-root", required=True, help="Workspace root directory")
    p_add.add_argument("--source", required=True, help="Source system, e.g. qlue or trm")
    p_add.add_argument("--model", choices=["account", "utxo"], help="Transaction model")
    p_add.add_argument("--export-type", help="Explicit export type override")
    p_add.add_argument("--blockchain", help="Blockchain name")
    p_add.set_defaults(func=_add_files_cmd)

    p_norm = sub.add_parser("normalize", help="Normalize workspace Sources raw files into canonical tables")
    p_norm.add_argument("--workspace-root", required=True, help="Workspace root directory")
    p_norm.add_argument("--duckdb-bin", default="duckdb", help="DuckDB binary name/path")
    p_norm.set_defaults(func=_normalize_cmd)

    p_build = sub.add_parser("build-db", help="Build derived case tables/views for workspace Sources")
    p_build.add_argument("--workspace-root", required=True, help="Workspace root directory")
    p_build.add_argument("--duckdb-bin", default="duckdb", help="DuckDB binary name/path")
    p_build.set_defaults(func=_build_db_cmd)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    func = getattr(args, "func", None)
    if not callable(func):
        parser.print_help()
        return 2
    return int(func(args) or 0)


if __name__ == "__main__":
    raise SystemExit(main())
