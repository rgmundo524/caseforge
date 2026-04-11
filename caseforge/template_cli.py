from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from .template_layers import (
    TemplateSelection,
    available_features,
    available_templates,
    describe_plan,
    plan_template_layers,
    validate_feature_names,
    validate_template_name,
)


@dataclass(frozen=True)
class NewCaseTemplateSelection:
    template_name: str
    feature_names: tuple[str, ...]
    show_plan: bool


def add_new_case_template_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--template",
        default="default",
        help="Primary template to apply. Default: default",
    )
    parser.add_argument(
        "--feature",
        action="append",
        default=[],
        help="Feature overlay to apply. Repeatable.",
    )
    parser.add_argument(
        "--list-templates",
        action="store_true",
        help="List available templates and exit.",
    )
    parser.add_argument(
        "--list-features",
        action="store_true",
        help="List available features and exit.",
    )
    parser.add_argument(
        "--show-plan",
        action="store_true",
        help="Print the resolved template/feature layer plan.",
    )


def handle_template_listing_flags(args: argparse.Namespace) -> int | None:
    if getattr(args, "list_templates", False):
        print("Available templates:")
        for name in available_templates():
            print(f"  {name}")
        return 0

    if getattr(args, "list_features", False):
        print("Available features:")
        for name in available_features():
            print(f"  {name}")
        return 0

    return None


def resolve_template_selection(args: argparse.Namespace) -> NewCaseTemplateSelection:
    template_name = validate_template_name(getattr(args, "template", "default"))
    feature_names = validate_feature_names(getattr(args, "feature", ()))
    return NewCaseTemplateSelection(
        template_name=template_name,
        feature_names=feature_names,
        show_plan=bool(getattr(args, "show_plan", False)),
    )


def render_template_plan(*, case_root: Path, selection: NewCaseTemplateSelection) -> str:
    plan = plan_template_layers(
        case_root=case_root,
        template_name=selection.template_name,
        feature_names=selection.feature_names,
    )
    return describe_plan(plan)
