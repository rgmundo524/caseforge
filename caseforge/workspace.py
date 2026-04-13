from __future__ import annotations

import datetime as dt
import json
import os
import re
import shutil
from pathlib import Path

from .case_scaffold import scaffold_evidence
from .template_layers import (
    TemplateLayerError,
    TemplateSelection,
    materialize_template_layers,
    write_case_template_metadata,
)
from .util import now_stamp, slugify


SECTION_SPECS = (
    {
        "filename": "case-background.md",
        "section_id": "case_background",
        "title": "Case Background",
        "placement_key": "report.case_background",
        "prompt": "Summarize the case context, objectives, and key entities relevant to this investigation.",
    },
    {
        "filename": "client-narrative.md",
        "section_id": "client_narrative",
        "title": "Client Narrative",
        "placement_key": "report.client_narrative",
        "prompt": "Capture the client-provided narrative, scope, and timeline in their own terms.",
    },
    {
        "filename": "investigative-findings.md",
        "section_id": "investigative_findings",
        "title": "Investigative Findings",
        "placement_key": "report.investigative_findings",
        "prompt": "Document factual findings, supporting evidence, and notable analytical outcomes.",
    },
    {
        "filename": "conclusions.md",
        "section_id": "conclusions",
        "title": "Conclusions",
        "placement_key": "report.conclusions",
        "prompt": "Provide conclusions tied directly to the findings and indicate confidence level where appropriate.",
    },
    {
        "filename": "limitations.md",
        "section_id": "limitations",
        "title": "Limitations",
        "placement_key": "report.limitations",
        "prompt": "List investigative limitations, assumptions, and known data gaps.",
    },
)
REQUIRED_SECTION_KEYS = (
    "section_id",
    "title",
    "content_class",
    "placement_key",
    "outputs",
    "status",
)
REQUIRED_STRING_SECTION_KEYS = (
    "section_id",
    "title",
    "content_class",
    "placement_key",
    "status",
)


def _utc_iso_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _workspace_slug(case_id: str) -> str:
    return f"{slugify(case_id)}_{now_stamp()}"


def _reject_duplicate_features(features: list[str]) -> None:
    seen: set[str] = set()
    dupes: list[str] = []
    for feature in features:
        if feature in seen and feature not in dupes:
            dupes.append(feature)
        seen.add(feature)
    if dupes:
        raise ValueError(f"Duplicate --feature values are not allowed: {', '.join(dupes)}")


def _manifest_payload(*, case_id: str, title: str, template: str, features: list[str]) -> dict[str, object]:
    return {
        "schema_version": 1,
        "workspace_type": "case_workspace",
        "case_id": case_id,
        "title": title,
        "primary_template": template,
        "features": list(features),
        "created_at": _utc_iso_now(),
        "status": "initialized",
    }


def workspace_sources_case_root(*, workspace_root: Path) -> Path:
    return workspace_root / "Sources"


def _engine_config_payload_from_workspace_manifest(manifest: dict[str, object]) -> dict[str, object]:
    return {
        "template": str(manifest.get("primary_template") or "default"),
        "features": [str(feature) for feature in (manifest.get("features") or [])],
    }


def _default_engine_manifest_payload() -> dict[str, object]:
    now = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    return {
        "schema_version": 2,
        "created_at": now,
        "updated_at": now,
        "files": [],
    }


def ensure_workspace_sources_engine_bridge(*, workspace_root: Path) -> Path:
    workspace_root = workspace_root.expanduser().resolve()
    manifest = _read_workspace_manifest(workspace_root)
    sources_root = workspace_sources_case_root(workspace_root=workspace_root)

    (sources_root / "data" / "raw").mkdir(parents=True, exist_ok=True)
    (sources_root / "derived").mkdir(parents=True, exist_ok=True)
    (sources_root / "config").mkdir(parents=True, exist_ok=True)

    engine_manifest_path = sources_root / "data" / "manifest.json"
    if not engine_manifest_path.exists():
        engine_manifest_path.write_text(json.dumps(_default_engine_manifest_payload(), indent=2) + "\n", encoding="utf-8")

    desired_config = _engine_config_payload_from_workspace_manifest(manifest)
    config_path = sources_root / "config" / "caseforge.json"
    current_config: dict[str, object] | None = None
    if config_path.exists():
        try:
            parsed = json.loads(config_path.read_text(encoding="utf-8"))
            if isinstance(parsed, dict):
                current_config = parsed
        except json.JSONDecodeError:
            current_config = None
    if current_config != desired_config:
        write_case_template_metadata(
            sources_root,
            TemplateSelection(
                template_name=str(desired_config["template"]),
                feature_names=tuple(str(feature) for feature in desired_config["features"]),
            ),
        )

    return sources_root


def _section_text(*, section_id: str, title: str, placement_key: str, prompt: str) -> str:
    return (
        "---\n"
        f"section_id: {section_id}\n"
        f"title: {title}\n"
        "content_class: case_authored\n"
        f"placement_key: {placement_key}\n"
        "outputs:\n"
        "  - web\n"
        "  - pdf\n"
        "status: draft\n"
        "---\n\n"
        f"# {title}\n\n"
        f"{prompt}\n"
    )


def init_workspace(
    *,
    cases_home: Path,
    case_id: str,
    title: str,
    template: str,
    features: list[str] | None = None,
) -> Path:
    case_id = case_id.strip()
    title = title.strip()
    template = template.strip()
    features = [f.strip() for f in (features or [])]

    _reject_duplicate_features(features)

    cases_home = cases_home.expanduser().resolve()
    cases_home.mkdir(parents=True, exist_ok=True)

    workspace_root = cases_home / _workspace_slug(case_id)
    if workspace_root.exists():
        raise RuntimeError(f"Workspace directory already exists: {workspace_root}")

    workspace_root.mkdir(parents=False, exist_ok=False)

    sections_dir = workspace_root / "Sections"
    sources_dir = workspace_root / "Sources"
    web_dir = workspace_root / "WEB"
    pdf_dir = workspace_root / "PDF"
    meta_dir = workspace_root / ".caseforge"

    for d in (sections_dir, sources_dir, web_dir, pdf_dir, meta_dir):
        d.mkdir(parents=True, exist_ok=False)

    manifest = _manifest_payload(case_id=case_id, title=title, template=template, features=features)
    manifest_path = meta_dir / "workspace.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    for section in SECTION_SPECS:
        path = sections_dir / section["filename"]
        path.write_text(
            _section_text(
                section_id=section["section_id"],
                title=section["title"],
                placement_key=section["placement_key"],
                prompt=section["prompt"],
            ),
            encoding="utf-8",
        )

    ensure_workspace_sources_engine_bridge(workspace_root=workspace_root)

    return workspace_root


def _read_workspace_manifest(workspace_root: Path) -> dict[str, object]:
    manifest_path = workspace_root / ".caseforge" / "workspace.json"
    if not manifest_path.exists():
        raise RuntimeError(f"Workspace manifest not found: {manifest_path}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def _parse_frontmatter_block(section_path: Path, text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError(f"Section file is missing frontmatter block: {section_path}")
    end_marker = "\n---\n"
    end_idx = text.find(end_marker, 4)
    if end_idx == -1:
        raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
    frontmatter = text[4:end_idx]
    if not frontmatter.strip():
        raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
    body = text[end_idx + len(end_marker) :]
    return frontmatter, body


def _parse_simple_yaml_frontmatter(section_path: Path, frontmatter: str) -> dict[str, object]:
    parsed: dict[str, object] = {}
    current_list_key: str | None = None

    for raw_line in frontmatter.splitlines():
        if not raw_line.strip():
            continue
        if raw_line.startswith("  - "):
            if current_list_key is None:
                raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
            value = raw_line[4:].strip()
            if not value:
                raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
            parsed.setdefault(current_list_key, [])
            casted = parsed[current_list_key]
            if not isinstance(casted, list):
                raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
            casted.append(value)
            continue

        match = re.match(r"^([A-Za-z0-9_]+):(.*)$", raw_line)
        if not match:
            raise ValueError(f"Section file has malformed frontmatter block: {section_path}")

        key = match.group(1).strip()
        value = match.group(2).strip()
        if value:
            parsed[key] = value
            current_list_key = None
        else:
            parsed[key] = []
            current_list_key = key

    if not parsed:
        raise ValueError(f"Section file has malformed frontmatter block: {section_path}")
    return parsed


def _parse_section_file(*, workspace_root: Path, section_path: Path) -> dict[str, object]:
    text = section_path.read_text(encoding="utf-8")
    frontmatter, body = _parse_frontmatter_block(section_path, text)
    metadata = _parse_simple_yaml_frontmatter(section_path, frontmatter)

    for required_key in REQUIRED_SECTION_KEYS:
        if required_key not in metadata:
            raise ValueError(f"Section file is missing required key '{required_key}': {section_path}")

    outputs = metadata["outputs"]
    if not isinstance(outputs, list) or any(not isinstance(item, str) or not item for item in outputs):
        raise ValueError(f"Section file has invalid 'outputs' list: {section_path}")

    for key in REQUIRED_STRING_SECTION_KEYS:
        value = metadata[key]
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"Section file has invalid '{key}': {section_path}")

    section_id = metadata["section_id"]
    title = metadata["title"]

    return {
        "filename": section_path.name,
        "relative_path": f"Sections/{section_path.name}",
        "section_id": section_id,
        "title": title,
        "content_class": metadata["content_class"],
        "placement_key": metadata["placement_key"],
        "outputs": outputs,
        "status": metadata["status"],
        "body_markdown": body,
    }


def _ordered_sections(sections: list[dict[str, object]]) -> list[dict[str, object]]:
    canonical_index = {spec["section_id"]: idx for idx, spec in enumerate(SECTION_SPECS)}
    ordered = sorted(
        sections,
        key=lambda item: (
            0 if item["section_id"] in canonical_index else 1,
            canonical_index.get(item["section_id"], 0),
            str(item["filename"]),
        ),
    )
    for idx, section in enumerate(ordered, start=1):
        section["source_order"] = idx
    return ordered


def _build_sections_snapshot_payload(workspace_root: Path) -> dict[str, object]:
    manifest = _read_workspace_manifest(workspace_root)
    sections_dir = workspace_root / "Sections"
    if not sections_dir.exists():
        raise RuntimeError(f"Sections directory not found: {sections_dir}")

    parsed_sections: list[dict[str, object]] = []
    seen_section_ids: dict[str, str] = {}
    for section_path in sorted(sections_dir.glob("*.md"), key=lambda p: p.name):
        section = _parse_section_file(workspace_root=workspace_root, section_path=section_path)
        section_id = str(section["section_id"])
        if section_id in seen_section_ids:
            raise ValueError(
                f"Duplicate section_id '{section_id}' found in {seen_section_ids[section_id]} and {section_path}"
            )
        seen_section_ids[section_id] = str(section_path)
        parsed_sections.append(section)

    ordered_sections = _ordered_sections(parsed_sections)

    return {
        "schema_version": 1,
        "snapshot_type": "sections_snapshot",
        "workspace_type": "case_workspace",
        "generated_at": _utc_iso_now(),
        "case_id": manifest.get("case_id"),
        "title": manifest.get("title"),
        "primary_template": manifest.get("primary_template"),
        "features": list(manifest.get("features", [])),
        "sections": ordered_sections,
    }


def write_sections_snapshot(*, workspace_root: Path) -> Path:
    workspace_root = workspace_root.expanduser().resolve()
    snapshot = _build_sections_snapshot_payload(workspace_root)
    snapshot_path = workspace_root / "Sources" / "derived" / "sections_snapshot.json"
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)
    snapshot_path.write_text(json.dumps(snapshot, indent=2) + "\n", encoding="utf-8")
    return snapshot_path


def _strip_leading_matching_h1(body_markdown: str, title: str) -> str:
    lines = body_markdown.splitlines()
    first_non_empty_idx = None
    for idx, line in enumerate(lines):
        if line.strip():
            first_non_empty_idx = idx
            break
    if first_non_empty_idx is None:
        return ""

    if lines[first_non_empty_idx].strip() == f"# {title}":
        del lines[first_non_empty_idx]
        while first_non_empty_idx < len(lines) and not lines[first_non_empty_idx].strip():
            del lines[first_non_empty_idx]
    return "\n".join(lines).strip()


def _validate_output_name(output_name: str) -> str:
    candidate = output_name.strip()
    if not candidate:
        raise ValueError("--output-name must not be empty")
    if candidate in {".", ".."}:
        raise ValueError(f"Invalid --output-name '{output_name}': must be a single safe identifier")
    if "/" in candidate or "\\" in candidate:
        raise ValueError(f"Invalid --output-name '{output_name}': must be a single safe identifier")
    if Path(candidate).name != candidate:
        raise ValueError(f"Invalid --output-name '{output_name}': must be a single safe identifier")
    return candidate


def _compose_web_index_markdown(snapshot: dict[str, object]) -> str:
    lines: list[str] = [
        f"# {snapshot.get('title', '')}",
        "",
        "> Generated draft from case-authored sections snapshot.",
        "",
    ]
    for section in snapshot.get("sections", []):
        outputs = section.get("outputs", [])
        if not isinstance(outputs, list) or "web" not in outputs:
            continue
        title = str(section.get("title", ""))
        lines.append(f"## {title}")
        lines.append("")
        body = _strip_leading_matching_h1(str(section.get("body_markdown", "")), title)
        if body:
            lines.append(body)
            lines.append("")
        else:
            lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def _write_workspace_sources_connection(*, output_root: Path, workspace_root: Path) -> Path:
    sources_root = workspace_root / "Sources"
    connection_path = output_root / "sources" / "case" / "connection.yaml"
    connection_path.parent.mkdir(parents=True, exist_ok=True)
    relative_db_path = Path(os.path.relpath(sources_root / "data" / "case.duckdb", connection_path.parent))

    connection_lines = [
        "name: case",
        "type: duckdb",
        "options:",
        f"  filename: {relative_db_path.as_posix()}",
        "",
    ]
    connection_path.write_text("\n".join(connection_lines), encoding="utf-8")
    return connection_path


def _write_web_output_manifest(
    *,
    workspace_root: Path,
    output_root: Path,
    output_name: str,
    snapshot_path: Path,
    manifest: dict[str, object],
) -> Path:
    web_meta_path = output_root / ".caseforge" / "web_output.json"
    web_meta_path.parent.mkdir(parents=True, exist_ok=True)

    payload = {
        "output_name": output_name,
        "renderer": "evidence",
        "built_at": _utc_iso_now(),
        "template": str(manifest.get("primary_template") or "default"),
        "features": [str(feature) for feature in (manifest.get("features") or [])],
        "section_snapshot": Path(os.path.relpath(snapshot_path, output_root)).as_posix(),
        "sources_root": Path(os.path.relpath(workspace_root / "Sources", output_root)).as_posix(),
        "workspace_root": str(Path("..") / ".."),
    }
    web_meta_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return web_meta_path


def _bootstrap_web_runtime_from_case_scaffold(*, output_root: Path, cases_home: Path) -> None:
    try:
        scaffold_evidence(case_root=output_root, cases_home=cases_home)
    except RuntimeError as exc:
        raise RuntimeError(f"Failed to bootstrap WEB Evidence runtime root: {exc}") from exc

    required = ("package.json", "package-lock.json")
    missing = [name for name in required if not (output_root / name).is_file()]
    if missing:
        raise RuntimeError(
            "Evidence bootstrap did not produce required runtime file(s): "
            + ", ".join(str(output_root / name) for name in missing)
        )

    for name in required:
        try:
            parsed = json.loads((output_root / name).read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Evidence bootstrap produced invalid JSON for {output_root / name}: {exc}") from exc
        if not isinstance(parsed, dict) or not parsed:
            raise RuntimeError(f"Evidence bootstrap produced invalid {output_root / name}: must be non-empty JSON object")


def build_web_draft(*, workspace_root: Path, output_name: str, bootstrap_cases_home: Path | None = None) -> tuple[Path, Path]:
    output_name = _validate_output_name(output_name)

    workspace_root = workspace_root.expanduser().resolve()
    bootstrap_cases_home = (bootstrap_cases_home or Path(".")).expanduser().resolve()
    manifest = _read_workspace_manifest(workspace_root)
    snapshot_path = write_sections_snapshot(workspace_root=workspace_root)
    snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))

    output_root = workspace_root / "WEB" / output_name
    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.parent.mkdir(parents=True, exist_ok=True)
    _bootstrap_web_runtime_from_case_scaffold(output_root=output_root, cases_home=bootstrap_cases_home)
    # Keep bootstrap-owned runtime root files, but clear bootstrap starter/demo content
    # so CaseForge owns final pages/ and sources/ surfaces deterministically.
    shutil.rmtree(output_root / "pages", ignore_errors=True)
    shutil.rmtree(output_root / "sources", ignore_errors=True)

    try:
        materialize_template_layers(
            output_root,
            template_name=str(manifest.get("primary_template") or "default"),
            feature_names=[str(feature) for feature in (manifest.get("features") or [])],
        )
    except TemplateLayerError as exc:
        raise RuntimeError(str(exc)) from exc

    _write_web_output_manifest(
        workspace_root=workspace_root,
        output_root=output_root,
        output_name=output_name,
        snapshot_path=snapshot_path,
        manifest=manifest,
    )
    _write_workspace_sources_connection(output_root=output_root, workspace_root=workspace_root)

    draft_path = output_root / "pages" / "index.md"
    draft_path.parent.mkdir(parents=True, exist_ok=True)
    draft_path.write_text(_compose_web_index_markdown(snapshot), encoding="utf-8")
    return snapshot_path, draft_path
