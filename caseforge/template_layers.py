from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence

CASEFORGE_CONFIG_REL = Path("config/caseforge.json")
_METADATA_REL = CASEFORGE_CONFIG_REL

# Generated/transient artifacts that must never be copied from template layers
# into a newly scaffolded Evidence project.
IGNORED_TEMPLATE_NAMES = {
    ".git",
    ".evidence",
    ".svelte-kit",
    ".vite",
    "node_modules",
    "dist",
    "build",
    ".DS_Store",
    "__pycache__",
}


class TemplateLayerError(RuntimeError):
    pass


@dataclass(frozen=True)
class TemplateSelection:
    template_name: str
    feature_names: tuple[str, ...] = ()
    show_plan: bool = False


@dataclass(frozen=True)
class LayerEntry:
    name: str
    path: Path
    kind: str  # common | template | feature


@dataclass(frozen=True)
class MaterializedTemplatePlan:
    repo_root: Path
    case_root: Path
    selection: TemplateSelection
    layers: tuple[LayerEntry, ...]
    collisions: tuple[str, ...]

    @property
    def template_name(self) -> str:
        return self.selection.template_name

    @property
    def feature_names(self) -> tuple[str, ...]:
        return self.selection.feature_names

    @property
    def layer_roots(self) -> tuple[Path, ...]:
        return tuple(layer.path for layer in self.layers)


# Backward-compat alias for earlier helper name.
TemplatePlan = MaterializedTemplatePlan


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _templates_root() -> Path:
    return _repo_root() / "templates"


def _common_root() -> Path:
    return _templates_root() / "common"


def _template_root(template_name: str) -> Path:
    return _templates_root() / template_name


def _features_root() -> Path:
    return _templates_root() / "features"


def _feature_root(feature_name: str) -> Path:
    return _features_root() / feature_name


def _iter_child_dirs(root: Path) -> list[Path]:
    if not root.exists() or not root.is_dir():
        return []
    return sorted((p for p in root.iterdir() if p.is_dir()), key=lambda p: p.name)


def available_templates() -> list[str]:
    templates_root = _templates_root()
    excluded = {"common", "features", "sql", "__pycache__"}
    return [
        p.name
        for p in _iter_child_dirs(templates_root)
        if p.name not in excluded and not p.name.startswith(".")
    ]


def list_available_templates() -> list[str]:
    return available_templates()


def available_features() -> list[str]:
    return [p.name for p in _iter_child_dirs(_features_root()) if not p.name.startswith(".")]


def list_available_features() -> list[str]:
    return available_features()


def validate_template_name(template_name: str) -> str:
    name = (template_name or "default").strip() or "default"
    root = _template_root(name)
    if not root.exists() or not root.is_dir():
        raise TemplateLayerError(
            f"Unknown template '{name}'. Available templates: {', '.join(available_templates()) or 'none'}"
        )
    return name


def validate_feature_names(feature_names: Sequence[str] | None) -> tuple[str, ...]:
    seen: set[str] = set()
    ordered: list[str] = []
    for raw in feature_names or ():
        name = (raw or "").strip()
        if not name or name in seen:
            continue
        root = _feature_root(name)
        if not root.exists() or not root.is_dir():
            raise TemplateLayerError(
                f"Unknown feature '{name}'. Available features: {', '.join(available_features()) or 'none'}"
            )
        seen.add(name)
        ordered.append(name)
    return tuple(ordered)


def _should_skip(path: Path) -> bool:
    return any(part in IGNORED_TEMPLATE_NAMES for part in path.parts)


def _iter_files(root: Path) -> Iterable[Path]:
    if not root.exists():
        return []
    return sorted(
        p for p in root.rglob("*") if p.is_file() and not _should_skip(p.relative_to(root))
    )


def _collect_collisions(layers: Sequence[LayerEntry]) -> list[str]:
    seen: dict[Path, str] = {}
    collisions: list[str] = []
    for layer in layers:
        for path in _iter_files(layer.path):
            rel = path.relative_to(layer.path)
            if rel in seen:
                collisions.append(f"{rel.as_posix()}: {seen[rel]} -> {layer.name}")
            seen[rel] = layer.name
    return collisions


def detect_collisions(plan: MaterializedTemplatePlan) -> dict[str, list[str]]:
    owners: dict[str, list[str]] = {}
    for layer in plan.layers:
        for path in _iter_files(layer.path):
            rel = path.relative_to(layer.path).as_posix()
            owners.setdefault(rel, []).append(layer.name)
    return {rel: names for rel, names in owners.items() if len(names) > 1}


def plan_template_layers(
    case_root: Path,
    template_name: str = "default",
    feature_names: Sequence[str] | None = None,
) -> MaterializedTemplatePlan:
    case_root = case_root.resolve()
    repo_root = _repo_root()
    template_name = validate_template_name(template_name)
    feature_names = validate_feature_names(feature_names)

    common = _common_root()
    if not common.exists() or not common.is_dir():
        raise TemplateLayerError(f"Missing common template layer: {common}")

    layers: list[LayerEntry] = [
        LayerEntry(name="common", path=common, kind="common"),
        LayerEntry(name=template_name, path=_template_root(template_name), kind="template"),
    ]
    for feature_name in feature_names:
        layers.append(LayerEntry(name=feature_name, path=_feature_root(feature_name), kind="feature"))

    collisions = tuple(_collect_collisions(layers))
    return MaterializedTemplatePlan(
        repo_root=repo_root,
        case_root=case_root,
        selection=TemplateSelection(template_name=template_name, feature_names=feature_names),
        layers=tuple(layers),
        collisions=collisions,
    )


def describe_plan(plan: MaterializedTemplatePlan) -> str:
    lines = [
        "Template layer plan:",
        f"  case_root: {plan.case_root}",
        f"  template:  {plan.selection.template_name}",
        f"  features:  {', '.join(plan.selection.feature_names) if plan.selection.feature_names else '(none)'}",
        "  layers:",
    ]
    for idx, layer in enumerate(plan.layers, start=1):
        lines.append(f"    {idx}. {layer.kind}:{layer.name} -> {layer.path}")
    if plan.collisions:
        lines.append("  collisions:")
        for item in plan.collisions:
            lines.append(f"    - {item}")
    else:
        lines.append("  collisions: none")
    return "\n".join(lines)


def _copy_tree_overlay(*, src: Path, dst: Path) -> None:
    for path in _iter_files(src):
        rel = path.relative_to(src)
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, out)


def _purge_transient_paths(case_root: Path) -> list[str]:
    removed: list[str] = []
    for name in sorted(IGNORED_TEMPLATE_NAMES):
        if name in {".git", ".DS_Store", "__pycache__"}:
            continue
        for path in case_root.rglob(name):
            if not path.exists():
                continue
            try:
                if path.is_dir():
                    shutil.rmtree(path)
                else:
                    path.unlink()
                removed.append(path.relative_to(case_root).as_posix())
            except FileNotFoundError:
                pass
    return removed


def write_case_template_metadata(case_root: Path, selection: TemplateSelection) -> Path:
    case_root = case_root.resolve()
    out = case_root / _METADATA_REL
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "template": selection.template_name,
        "features": list(selection.feature_names),
    }
    out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return out


def write_caseforge_config(case_root: Path, plan: MaterializedTemplatePlan) -> Path:
    return write_case_template_metadata(case_root, plan.selection)


def read_case_template_metadata(case_root: Path) -> TemplateSelection | None:
    path = case_root.resolve() / _METADATA_REL
    if not path.exists():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    return TemplateSelection(
        template_name=str(data.get("template") or "default"),
        feature_names=tuple(str(x) for x in data.get("features") or ()),
    )


def materialize_template_layers(
    case_root: Path,
    *,
    template_name: str = "default",
    feature_names: Sequence[str] | None = None,
) -> MaterializedTemplatePlan:
    plan = plan_template_layers(case_root=case_root, template_name=template_name, feature_names=feature_names)
    plan.case_root.mkdir(parents=True, exist_ok=True)
    for layer in plan.layers:
        _copy_tree_overlay(src=layer.path, dst=plan.case_root)
    _purge_transient_paths(plan.case_root)
    write_case_template_metadata(plan.case_root, plan.selection)
    return plan
