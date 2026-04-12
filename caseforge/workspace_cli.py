from __future__ import annotations

import argparse
from pathlib import Path

from .workspace import build_web_draft, init_workspace


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
