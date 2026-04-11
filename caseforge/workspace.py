from __future__ import annotations

import datetime as dt
import json
from pathlib import Path

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

    return workspace_root
