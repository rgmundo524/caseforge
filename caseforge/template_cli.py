from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence

from .template_layers import describe_plan, list_feature_overlays, list_primary_templates, plan_template_layers


@dataclass(frozen=True)
class TemplateSelection:
    template_name: str
    feature_names: tuple[str, ...]
    show_plan: bool = False
    dry_run: bool = False



def add_new_case_template_args(parser) -> None:
    parser.add_argument(
        "--template",
        default="default",
        help="Primary template to apply (default: %(default)s)",
    )
    parser.add_argument(
        "--feature",
        action="append",
        default=[],
        help="Feature overlay to apply. Repeat the flag to add multiple features.",
    )
    parser.add_argument(
        "--list-templates",
        action="store_true",
        help="List available primary templates and exit.",
    )
    parser.add_argument(
        "--list-features",
        action="store_true",
        help="List available feature overlays and exit.",
    )
    parser.add_argument(
        "--show-plan",
        action="store_true",
        help="Print the resolved template / feature layer plan.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs and print the plan without creating the case.",
    )



def handle_template_listing_flags(args, *, repo_root: Path | None = None) -> Optional[int]:
    if getattr(args, "list_templates", False):
        for name in list_primary_templates(repo_root=repo_root):
            print(name)
        return 0

    if getattr(args, "list_features", False):
        for name in list_feature_overlays(repo_root=repo_root):
            print(name)
        return 0

    return None



def resolve_template_selection(args) -> TemplateSelection:
    feature_names = tuple(args.feature or [])
    return TemplateSelection(
        template_name=str(getattr(args, "template", "default") or "default"),
        feature_names=feature_names,
        show_plan=bool(getattr(args, "show_plan", False)),
        dry_run=bool(getattr(args, "dry_run", False)),
    )



def render_template_plan(*, case_root: Path, selection: TemplateSelection, repo_root: Path | None = None) -> str:
    plan = plan_template_layers(
        Path(case_root),
        template_name=selection.template_name,
        feature_names=selection.feature_names,
        repo_root=repo_root,
    )
    return describe_plan(plan)
