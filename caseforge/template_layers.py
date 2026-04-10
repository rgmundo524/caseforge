from __future__ import annotations

import json
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

CASE_TEMPLATE_CONFIG_REL = Path("config/caseforge.json")


@dataclass(frozen=True)
class TemplateLayer:
    name: str
    kind: str  # common | template | feature
    path: Path


@dataclass(frozen=True)
class TemplatePlan:
    case_root: Path
    template_name: str
    feature_names: Tuple[str, ...]
    layers: Tuple[TemplateLayer, ...]



def _repo_root(anchor: Path | None = None) -> Path:
    anchor = anchor or Path(__file__).resolve()
    return anchor.parent.parent.resolve()



def _templates_root(repo_root: Path | None = None) -> Path:
    repo_root = repo_root or _repo_root()
    return (repo_root / "templates").resolve()



def _normalize_name(name: str) -> str:
    slug = re.sub(r"[^a-z0-9_-]+", "-", (name or "").strip().lower())
    slug = re.sub(r"-{2,}", "-", slug).strip("-")
    if not slug:
        raise ValueError("Empty template/feature name.")
    return slug



def _dedupe_preserve_order(names: Iterable[str]) -> Tuple[str, ...]:
    seen = set()
    out: List[str] = []
    for raw in names:
        if raw is None:
            continue
        name = _normalize_name(raw)
        if name not in seen:
            seen.add(name)
            out.append(name)
    return tuple(out)



def _layer_file_map(layer: TemplateLayer) -> Dict[Path, Path]:
    out: Dict[Path, Path] = {}
    if not layer.path.exists():
        return out
    for src in layer.path.rglob("*"):
        if src.is_file():
            rel = src.relative_to(layer.path)
            out[rel] = src
    return out



def list_primary_templates(*, repo_root: Path | None = None) -> Tuple[str, ...]:
    templates_root = _templates_root(repo_root)
    out: List[str] = []
    if not templates_root.exists():
        return tuple()
    for child in sorted(templates_root.iterdir()):
        if not child.is_dir():
            continue
        if child.name in {"common", "features", "sql"}:
            continue
        out.append(child.name)
    return tuple(out)



def list_feature_overlays(*, repo_root: Path | None = None) -> Tuple[str, ...]:
    features_root = _templates_root(repo_root) / "features"
    if not features_root.exists():
        return tuple()
    return tuple(sorted(child.name for child in features_root.iterdir() if child.is_dir()))



def validate_template_name(template_name: str, *, repo_root: Path | None = None) -> str:
    normalized = _normalize_name(template_name or "default")
    available = set(list_primary_templates(repo_root=repo_root))
    if normalized not in available:
        raise FileNotFoundError(
            f"Unknown template '{normalized}'. Available templates: {', '.join(sorted(available)) or '(none)'}"
        )
    return normalized



def validate_feature_names(feature_names: Iterable[str], *, repo_root: Path | None = None) -> Tuple[str, ...]:
    requested = _dedupe_preserve_order(feature_names)
    available = set(list_feature_overlays(repo_root=repo_root))
    missing = [name for name in requested if name not in available]
    if missing:
        raise FileNotFoundError(
            f"Unknown feature overlay(s): {', '.join(missing)}. Available features: {', '.join(sorted(available)) or '(none)'}"
        )
    return requested



def plan_template_layers(
    case_root: Path,
    template_name: str = "default",
    feature_names: Iterable[str] = (),
    *,
    repo_root: Path | None = None,
) -> TemplatePlan:
    case_root = Path(case_root).resolve()
    template_name = validate_template_name(template_name, repo_root=repo_root)
    feature_names = validate_feature_names(feature_names, repo_root=repo_root)

    templates_root = _templates_root(repo_root)
    common_root = templates_root / "common"
    template_root = templates_root / template_name
    features_root = templates_root / "features"

    if not common_root.exists():
        raise FileNotFoundError(f"Missing common template layer: {common_root}")

    layers: List[TemplateLayer] = [
        TemplateLayer(name="common", kind="common", path=common_root),
        TemplateLayer(name=template_name, kind="template", path=template_root),
    ]
    for feature_name in feature_names:
        layers.append(TemplateLayer(name=feature_name, kind="feature", path=features_root / feature_name))

    return TemplatePlan(
        case_root=case_root,
        template_name=template_name,
        feature_names=feature_names,
        layers=tuple(layers),
    )



def collect_collisions(plan: TemplatePlan) -> Dict[Path, Tuple[TemplateLayer, ...]]:
    collisions: Dict[Path, List[TemplateLayer]] = {}
    for layer in plan.layers:
        for rel in _layer_file_map(layer):
            collisions.setdefault(rel, []).append(layer)
    return {rel: tuple(owners) for rel, owners in collisions.items() if len(owners) > 1}



def materialize_template_layers(
    case_root: Path,
    template_name: str = "default",
    feature_names: Iterable[str] = (),
    *,
    repo_root: Path | None = None,
) -> TemplatePlan:
    plan = plan_template_layers(
        case_root=case_root,
        template_name=template_name,
        feature_names=feature_names,
        repo_root=repo_root,
    )

    for layer in plan.layers:
        for rel, src in _layer_file_map(layer).items():
            dst = plan.case_root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)

    return plan



def case_template_config_path(case_root: Path) -> Path:
    return Path(case_root).resolve() / CASE_TEMPLATE_CONFIG_REL



def write_case_template_config(
    case_root: Path,
    *,
    template_name: str,
    feature_names: Iterable[str] = (),
) -> Path:
    payload = {
        "template": _normalize_name(template_name or "default"),
        "features": list(_dedupe_preserve_order(feature_names)),
    }
    out_path = case_template_config_path(case_root)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return out_path



def load_case_template_config(case_root: Path) -> Dict[str, object]:
    cfg_path = case_template_config_path(case_root)
    if not cfg_path.exists():
        return {"template": "default", "features": []}
    data = json.loads(cfg_path.read_text(encoding="utf-8"))
    template_name = _normalize_name(str(data.get("template") or "default"))
    feature_names = [str(x) for x in (data.get("features") or [])]
    return {
        "template": template_name,
        "features": list(_dedupe_preserve_order(feature_names)),
    }



def describe_plan(plan: TemplatePlan) -> str:
    lines: List[str] = []
    lines.append(f"Case root: {plan.case_root}")
    lines.append(f"Primary template: {plan.template_name}")
    lines.append("Feature overlays: " + (", ".join(plan.feature_names) if plan.feature_names else "(none)"))
    lines.append("Layer order:")
    for idx, layer in enumerate(plan.layers, start=1):
        lines.append(f"  {idx}. [{layer.kind}] {layer.name} -> {layer.path}")

    collisions = collect_collisions(plan)
    if not collisions:
        lines.append("Path collisions: none")
    else:
        lines.append("Path collisions (later layers win on exact relative path):")
        for rel in sorted(collisions):
            owners = " -> ".join(f"{layer.kind}:{layer.name}" for layer in collisions[rel])
            lines.append(f"  - {rel.as_posix()} :: {owners}")

    return "\n".join(lines)
