from __future__ import annotations

import argparse
import inspect
from pathlib import Path
from typing import Any, Callable, Iterable

from . import build as _build_mod
from . import case_scaffold as _case_scaffold_mod
from . import intake as _intake_mod
from . import normalize as _normalize_mod
from .template_cli import (
    add_new_case_template_args,
    handle_template_listing_flags,
    render_template_plan,
    resolve_template_selection,
)
from .template_layers import materialize_template_layers


def _resolve_callable(module: object, candidates: Iterable[str]) -> Callable[..., Any]:
    for name in candidates:
        fn = getattr(module, name, None)
        if callable(fn):
            return fn
    raise RuntimeError(
        f"Could not find any expected callable in {getattr(module, '__name__', module)}. "
        f"Tried: {', '.join(candidates)}"
    )


def _call_with_compatible_kwargs(fn: Callable[..., Any], **kwargs: Any) -> Any:
    sig = inspect.signature(fn)
    params = sig.parameters
    accepts_var_kw = any(p.kind == inspect.Parameter.VAR_KEYWORD for p in params.values())
    if accepts_var_kw:
        return fn(**kwargs)
    filtered = {k: v for k, v in kwargs.items() if k in params}
    return fn(**filtered)


def _extract_case_root(result: Any, *, cases_home: Path, case_id: str, before_dirs: set[Path]) -> Path:
    if result is not None:
        if isinstance(result, Path):
            return result.resolve()
        if isinstance(result, str):
            p = Path(result)
            if p.exists():
                return p.resolve()
        if isinstance(result, dict):
            for key in ("case_root", "root", "path"):
                val = result.get(key)
                if val:
                    return Path(val).resolve()
        for attr in ("case_root", "root", "path"):
            val = getattr(result, attr, None)
            if val:
                return Path(val).resolve()

    after_dirs = {p.resolve() for p in cases_home.iterdir() if p.is_dir()}
    created = sorted(after_dirs - before_dirs)
    if len(created) == 1:
        return created[0]

    prefix_matches = [p for p in created if p.name.startswith(f"{case_id}_") or p.name == case_id]
    if len(prefix_matches) == 1:
        return prefix_matches[0]

    raise RuntimeError("Unable to determine case_root from scaffold result.")


def _print_created_case(result: Any, *, case_root: Path) -> None:
    print("Created case:")
    print(f"  case_root:     {case_root}")
    scaffold = getattr(result, "scaffold", None) or (result.get("scaffold") if isinstance(result, dict) else None)
    duckdb = getattr(result, "duckdb", None) or (result.get("duckdb") if isinstance(result, dict) else None)
    source_yaml = getattr(result, "source_yaml", None) or (result.get("source_yaml") if isinstance(result, dict) else None)
    if scaffold:
        print(f"  scaffold:      {scaffold}")
    if duckdb:
        print(f"  duckdb:        {duckdb}")
    if source_yaml:
        print(f"  source yaml:   {source_yaml}")
    print("\nNext steps:")
    print(f"  cd {case_root}")
    print("  npm install")
    print("  npm run dev")
    print("\nThen:")
    print("  caseforge add-files <file.csv> --source ...")
    print("  caseforge normalize")
    print("  caseforge build-db --sources")


def _new_case(args: argparse.Namespace) -> int:
    maybe_exit = handle_template_listing_flags(args)
    if maybe_exit is not None:
        return maybe_exit

    if not args.case_id or not args.title:
        raise SystemExit("new-case requires --case-id and --title")

    selection = resolve_template_selection(args)
    cases_home = Path(args.cases_home).resolve()
    cases_home.mkdir(parents=True, exist_ok=True)
    before_dirs = {p.resolve() for p in cases_home.iterdir() if p.is_dir()}

    fn = _resolve_callable(
        _case_scaffold_mod,
        [
            "create_case",
            "new_case",
            "scaffold_case",
            "init_case",
        ],
    )
    result = _call_with_compatible_kwargs(
        fn,
        cases_home=cases_home,
        case_id=args.case_id,
        title=args.title,
        template=selection.template_name,
    )

    case_root = _extract_case_root(result, cases_home=cases_home, case_id=args.case_id, before_dirs=before_dirs)

    plan = materialize_template_layers(
        case_root,
        template_name=selection.template_name,
        feature_names=selection.feature_names,
    )
    if selection.show_plan:
        print(render_template_plan(case_root=case_root, selection=selection))
        print()
    _print_created_case(result, case_root=case_root)
    if selection.feature_names:
        print(f"\nApplied features: {', '.join(selection.feature_names)}")
    return 0


def _derive_export_type(*, source: str, model: str | None, export_type: str | None) -> str | None:
    if export_type:
        return export_type
    model = (model or "").strip().lower()
    source = (source or "").strip().lower()
    if source == "qlue" and model in {"account", "utxo"}:
        return f"qlue_{model}"
    if source == "trm":
        return "trm"
    return export_type


def _add_files(args: argparse.Namespace) -> int:
    fn = _resolve_callable(
        _intake_mod,
        [
            "add_files",
            "register_files",
            "add_case_files",
            "register_input_files",
        ],
    )
    paths = [Path(p).resolve() for p in args.files]
    export_type = _derive_export_type(source=args.source, model=args.model, export_type=args.export_type)
    _call_with_compatible_kwargs(
        fn,
        case_root=Path(args.case_root).resolve(),
        files=paths,
        file_paths=paths,
        paths=paths,
        source=args.source,
        source_system=args.source,
        vendor=args.source,
        export_type=export_type,
        format=export_type,
        model=args.model,
        tx_model=args.model,
        blockchain=args.blockchain,
    )
    return 0


def _normalize(args: argparse.Namespace) -> int:
    fn = _resolve_callable(_normalize_mod, ["normalize_db"])
    _call_with_compatible_kwargs(
        fn,
        case_root=Path(args.case_root).resolve(),
        duckdb_bin=args.duckdb_bin,
    )
    return 0


def _build_db(args: argparse.Namespace) -> int:
    fn = _resolve_callable(
        _build_mod,
        ["build_db", "build_case_db", "build_case"],
    )
    run_sources = bool(getattr(args, "run_sources", False) or getattr(args, "sources", False))
    _call_with_compatible_kwargs(
        fn,
        case_root=Path(args.case_root).resolve(),
        duckdb_bin=args.duckdb_bin,
        sources=run_sources,
        run_sources=run_sources,
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="caseforge")
    sub = parser.add_subparsers(dest="command", required=True)

    p_new = sub.add_parser("new-case", help="Create a new case project")
    p_new.add_argument("--cases-home", default=".", help="Directory where the new case folder will be created")
    p_new.add_argument("--case-id", help="Case identifier")
    p_new.add_argument("--title", help="Human-readable case title")
    add_new_case_template_args(p_new)
    p_new.set_defaults(func=_new_case)

    p_add = sub.add_parser("add-files", help="Register raw input files into the case manifest")
    p_add.add_argument("files", nargs="+", help="Files to register")
    p_add.add_argument("--case-root", default=".", help="Case root directory")
    p_add.add_argument("--source", required=True, help="Source system, e.g. qlue or trm")
    p_add.add_argument("--model", choices=["account", "utxo"], help="Transaction model")
    p_add.add_argument("--export-type", help="Explicit export type override")
    p_add.add_argument("--blockchain", help="Blockchain name")
    p_add.set_defaults(func=_add_files)

    p_norm = sub.add_parser("normalize", help="Normalize raw files into canonical case tables")
    p_norm.add_argument("--case-root", default=".", help="Case root directory")
    p_norm.add_argument("--duckdb-bin", default="duckdb", help="DuckDB binary name/path")
    p_norm.set_defaults(func=_normalize)

    p_build = sub.add_parser("build-db", help="Build downstream case views/tables from normalized data")
    p_build.add_argument("--case-root", default=".", help="Case root directory")
    p_build.add_argument("--duckdb-bin", default="duckdb", help="DuckDB binary name/path")
    p_build.add_argument("--run-sources", action="store_true", help="Refresh Evidence sources after building")
    p_build.add_argument("--sources", action="store_true", help="Compatibility alias for --run-sources")
    p_build.set_defaults(func=_build_db)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    func = getattr(args, "func", None)
    if not callable(func):
        parser.print_help()
        return 2
    return int(func(args) or 0)
