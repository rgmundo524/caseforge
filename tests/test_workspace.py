from __future__ import annotations

import json
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

from caseforge.workspace import (
    build_web_draft,
    ensure_workspace_sources_engine_bridge,
    init_workspace,
    write_sections_snapshot,
)


def _seed_local_evidence_template(cases_home: Path) -> None:
    template_root = cases_home / "evidence-templates" / "template"
    template_root.mkdir(parents=True, exist_ok=True)
    (template_root / "package.json").write_text(
        json.dumps(
            {
                "name": "evidence-template",
                "scripts": {
                    "dev": "evidence dev",
                    "sources": "evidence sources",
                },
            }
        )
        + "\n",
        encoding="utf-8",
    )
    (template_root / "package-lock.json").write_text(
        json.dumps({"name": "evidence-template", "lockfileVersion": 3, "packages": {"": {"name": "x"}}})
        + "\n",
        encoding="utf-8",
    )
    (template_root / ".npmrc").write_text("loglevel=error\n", encoding="utf-8")
    (template_root / "degit.json").write_text("{}\n", encoding="utf-8")
    (template_root / "scripts").mkdir(parents=True, exist_ok=True)
    (template_root / "scripts" / "postinstall.js").write_text("console.log('ok');\n", encoding="utf-8")
    (template_root / "pages").mkdir(parents=True, exist_ok=True)
    (template_root / "pages" / "starter.md").write_text("# Starter\n", encoding="utf-8")
    (template_root / "sources" / "needful_things").mkdir(parents=True, exist_ok=True)
    (template_root / "sources" / "needful_things" / "orders.sql").write_text("select 1;\n", encoding="utf-8")
    (template_root / "sources" / "needful_things" / "needful_things.duckdb").write_text("", encoding="utf-8")


class WorkspaceInitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        _seed_local_evidence_template(self.root)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_init_workspace_creates_structure_and_manifest(self) -> None:
        workspace = init_workspace(
            cases_home=self.root,
            case_id="12345",
            title="Test Case",
            template="default",
            features=["cross-chain-activity", "urls"],
        )

        self.assertTrue(workspace.exists())
        self.assertTrue((workspace / "Sections").is_dir())
        self.assertTrue((workspace / "Sources").is_dir())
        self.assertTrue((workspace / "Sources" / "data").is_dir())
        self.assertTrue((workspace / "Sources" / "data" / "raw").is_dir())
        self.assertTrue((workspace / "Sources" / "derived").is_dir())
        self.assertTrue((workspace / "Sources" / "config").is_dir())
        self.assertTrue((workspace / "Sources" / "data" / "manifest.json").exists())
        self.assertTrue((workspace / "Sources" / "config" / "caseforge.json").exists())
        self.assertTrue((workspace / "WEB").is_dir())
        self.assertTrue((workspace / "PDF").is_dir())
        manifest_path = workspace / ".caseforge" / "workspace.json"
        self.assertTrue(manifest_path.exists())

        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(manifest["schema_version"], 1)
        self.assertEqual(manifest["workspace_type"], "case_workspace")
        self.assertEqual(manifest["case_id"], "12345")
        self.assertEqual(manifest["title"], "Test Case")
        self.assertEqual(manifest["primary_template"], "default")
        self.assertEqual(manifest["features"], ["cross-chain-activity", "urls"])
        self.assertEqual(manifest["status"], "initialized")
        self.assertTrue(manifest["created_at"].endswith("Z"))

        sources_manifest = json.loads((workspace / "Sources" / "data" / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(sources_manifest["schema_version"], 2)
        self.assertEqual(sources_manifest["files"], [])

        sources_config = json.loads((workspace / "Sources" / "config" / "caseforge.json").read_text(encoding="utf-8"))
        self.assertEqual(sources_config, {"template": "default", "features": ["cross-chain-activity", "urls"]})

    def test_seeded_sections_frontmatter(self) -> None:
        workspace = init_workspace(
            cases_home=self.root,
            case_id="C-01",
            title="Case",
            template="default",
        )

        expected = {
            "case-background.md": "report.case_background",
            "client-narrative.md": "report.client_narrative",
            "investigative-findings.md": "report.investigative_findings",
            "conclusions.md": "report.conclusions",
            "limitations.md": "report.limitations",
        }

        for filename, placement in expected.items():
            content = (workspace / "Sections" / filename).read_text(encoding="utf-8")
            self.assertIn("---\n", content)
            self.assertIn("content_class: case_authored", content)
            self.assertIn(f"placement_key: {placement}", content)
            self.assertIn("outputs:\n  - web\n  - pdf", content)
            self.assertIn("status: draft", content)
            self.assertIn("# ", content)

    def test_duplicate_features_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "Duplicate --feature"):
            init_workspace(
                cases_home=self.root,
                case_id="12345",
                title="Test",
                template="default",
                features=["urls", "urls"],
            )

    def test_workspace_exists_fails(self) -> None:
        with patch("caseforge.workspace.now_stamp", return_value="20260101_010101"):
            first = init_workspace(
                cases_home=self.root,
                case_id="12345",
                title="Test",
                template="default",
            )

            with self.assertRaisesRegex(RuntimeError, "Workspace directory already exists"):
                init_workspace(
                    cases_home=self.root,
                    case_id="12345",
                    title="Test",
                    template="default",
                    features=[],
                )

        self.assertTrue(first.exists())


class WorkspaceSectionsPipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        _seed_local_evidence_template(self.root)
        self.workspace = init_workspace(
            cases_home=self.root,
            case_id="12345",
            title="Test Case",
            template="default",
            features=["cross-chain-activity", "urls"],
        )

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_write_sections_snapshot_from_seeded_workspace(self) -> None:
        snapshot_path = write_sections_snapshot(workspace_root=self.workspace)
        self.assertEqual(snapshot_path, self.workspace / "Sources" / "derived" / "sections_snapshot.json")
        self.assertTrue(snapshot_path.exists())

        snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
        self.assertEqual(snapshot["schema_version"], 1)
        self.assertEqual(snapshot["snapshot_type"], "sections_snapshot")
        self.assertEqual(snapshot["workspace_type"], "case_workspace")
        self.assertEqual(snapshot["case_id"], "12345")
        self.assertEqual(snapshot["title"], "Test Case")
        self.assertEqual(snapshot["primary_template"], "default")
        self.assertEqual(snapshot["features"], ["cross-chain-activity", "urls"])
        self.assertEqual(len(snapshot["sections"]), 5)
        self.assertTrue(snapshot["generated_at"].endswith("Z"))

        section_ids = [section["section_id"] for section in snapshot["sections"]]
        self.assertEqual(
            section_ids,
            [
                "case_background",
                "client_narrative",
                "investigative_findings",
                "conclusions",
                "limitations",
            ],
        )
        self.assertEqual([section["source_order"] for section in snapshot["sections"]], [1, 2, 3, 4, 5])
        first = snapshot["sections"][0]
        self.assertEqual(first["filename"], "case-background.md")
        self.assertEqual(first["relative_path"], "Sections/case-background.md")
        self.assertEqual(first["content_class"], "case_authored")
        self.assertEqual(first["placement_key"], "report.case_background")
        self.assertEqual(first["outputs"], ["web", "pdf"])
        self.assertEqual(first["status"], "draft")
        self.assertIn("# Case Background", first["body_markdown"])

    def test_engine_bridge_sync_repairs_missing_or_stale_config_without_clobbering_manifest(self) -> None:
        manifest_path = self.workspace / "Sources" / "data" / "manifest.json"
        manifest_path.write_text(
            json.dumps(
                {
                    "schema_version": 2,
                    "created_at": "2026-01-01T00:00:00+00:00",
                    "updated_at": "2026-01-01T00:00:00+00:00",
                    "files": [{"file_id": "existing_file"}],
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        config_path = self.workspace / "Sources" / "config" / "caseforge.json"
        config_path.write_text(json.dumps({"template": "wrong", "features": []}) + "\n", encoding="utf-8")

        ensure_workspace_sources_engine_bridge(workspace_root=self.workspace)

        updated_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(updated_manifest["files"], [{"file_id": "existing_file"}])

        updated_config = json.loads(config_path.read_text(encoding="utf-8"))
        self.assertEqual(updated_config, {"template": "default", "features": ["cross-chain-activity", "urls"]})

    def test_write_sections_snapshot_missing_frontmatter_fails_cleanly(self) -> None:
        bad_file = self.workspace / "Sections" / "conclusions.md"
        bad_file.write_text("# Conclusions\n\nNo frontmatter.\n", encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "missing frontmatter block"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_write_sections_snapshot_missing_required_key_fails_cleanly(self) -> None:
        bad_file = self.workspace / "Sections" / "limitations.md"
        content = bad_file.read_text(encoding="utf-8")
        bad_file.write_text(content.replace("status: draft\n", ""), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "missing required key 'status'"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_write_sections_snapshot_invalid_status_value_fails_cleanly(self) -> None:
        bad_file = self.workspace / "Sections" / "limitations.md"
        content = bad_file.read_text(encoding="utf-8")
        bad_file.write_text(content.replace("status: draft\n", "status:\n"), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "invalid 'status'"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_write_sections_snapshot_invalid_placement_key_value_fails_cleanly(self) -> None:
        bad_file = self.workspace / "Sections" / "conclusions.md"
        content = bad_file.read_text(encoding="utf-8")
        bad_file.write_text(content.replace("placement_key: report.conclusions\n", "placement_key:\n"), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "invalid 'placement_key'"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_write_sections_snapshot_invalid_content_class_value_fails_cleanly(self) -> None:
        bad_file = self.workspace / "Sections" / "client-narrative.md"
        content = bad_file.read_text(encoding="utf-8")
        bad_file.write_text(content.replace("content_class: case_authored\n", "content_class:\n"), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "invalid 'content_class'"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_write_sections_snapshot_duplicate_section_ids_fail_cleanly(self) -> None:
        duplicate = self.workspace / "Sections" / "duplicate.md"
        duplicate.write_text(
            (
                "---\n"
                "section_id: conclusions\n"
                "title: Duplicate Conclusions\n"
                "content_class: case_authored\n"
                "placement_key: report.duplicate\n"
                "outputs:\n"
                "  - web\n"
                "status: draft\n"
                "---\n\n"
                "Duplicate section body\n"
            ),
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "Duplicate section_id 'conclusions'"):
            write_sections_snapshot(workspace_root=self.workspace)

    def test_build_web_draft_creates_ordered_index_and_excludes_non_web_sections(self) -> None:
        conclusions = self.workspace / "Sections" / "conclusions.md"
        text = conclusions.read_text(encoding="utf-8")
        conclusions.write_text(text.replace("  - web\n", ""), encoding="utf-8")

        snapshot_path, draft_path = build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        self.assertTrue(snapshot_path.exists())
        self.assertTrue(draft_path.exists())
        self.assertEqual(draft_path, self.workspace / "WEB" / "analysis-site" / "pages" / "index.md")
        self.assertTrue((self.workspace / "WEB" / "analysis-site" / ".caseforge" / "web_output.json").exists())
        self.assertTrue((self.workspace / "WEB" / "analysis-site" / "evidence.config.yaml").exists())
        evidence_config = (self.workspace / "WEB" / "analysis-site" / "evidence.config.yaml").read_text(encoding="utf-8")
        self.assertIn("plugins:", evidence_config)
        package_path = self.workspace / "WEB" / "analysis-site" / "package.json"
        lock_path = self.workspace / "WEB" / "analysis-site" / "package-lock.json"
        self.assertTrue(package_path.exists())
        self.assertTrue(lock_path.exists())
        package_json = json.loads(package_path.read_text(encoding="utf-8"))
        lock_json = json.loads(lock_path.read_text(encoding="utf-8"))
        self.assertIsInstance(package_json, dict)
        self.assertIsInstance(lock_json, dict)
        self.assertTrue(package_json)
        self.assertTrue(lock_json)
        self.assertTrue((self.workspace / "WEB" / "analysis-site" / ".npmrc").exists())
        self.assertTrue((self.workspace / "WEB" / "analysis-site" / "degit.json").exists())
        self.assertTrue((self.workspace / "WEB" / "analysis-site" / "scripts").is_dir())
        self.assertFalse((self.workspace / "WEB" / "analysis-site" / "sources" / "needful_things").exists())
        self.assertFalse((self.workspace / "WEB" / "analysis-site" / "sources" / "needful_things" / "orders.sql").exists())
        self.assertFalse(
            (self.workspace / "WEB" / "analysis-site" / "sources" / "needful_things" / "needful_things.duckdb").exists()
        )

        draft = draft_path.read_text(encoding="utf-8")
        self.assertIn("# Test Case", draft)
        self.assertIn("> Generated draft from case-authored sections snapshot.", draft)
        self.assertLess(draft.index("## Case Background"), draft.index("## Client Narrative"))
        self.assertLess(draft.index("## Client Narrative"), draft.index("## Investigative Findings"))
        self.assertNotIn("## Conclusions", draft)
        self.assertIn("Document factual findings, supporting evidence, and notable analytical outcomes.", draft)

    def test_build_web_draft_writes_output_manifest_with_template_features_and_relative_links(self) -> None:
        build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        output_root = self.workspace / "WEB" / "analysis-site"

        manifest = json.loads((output_root / ".caseforge" / "web_output.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["output_name"], "analysis-site")
        self.assertEqual(manifest["renderer"], "evidence")
        self.assertEqual(manifest["template"], "default")
        self.assertEqual(manifest["features"], ["cross-chain-activity", "urls"])
        self.assertEqual(manifest["section_snapshot"], "../../Sources/derived/sections_snapshot.json")
        self.assertEqual(manifest["sources_root"], "../../Sources")
        self.assertEqual(manifest["workspace_root"], "../..")
        self.assertTrue(manifest["built_at"].endswith("Z"))

    def test_build_web_draft_points_connection_to_workspace_sources_data(self) -> None:
        build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        output_root = self.workspace / "WEB" / "analysis-site"

        evidence_config = (output_root / "evidence.config.yaml").read_text(encoding="utf-8")
        self.assertIn("plugins:", evidence_config)
        self.assertNotIn("filename: ../../Sources/data/case.duckdb", evidence_config)
        connection = (output_root / "sources" / "case" / "connection.yaml").read_text(encoding="utf-8")
        self.assertIn("filename: ../../../../Sources/data/case.duckdb", connection)
        self.assertFalse((output_root / "data" / "case.duckdb").exists())
        self.assertFalse((output_root / "Sources").exists())

    def test_build_web_draft_is_refresh_safe(self) -> None:
        _, draft_path = build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        self.assertTrue(draft_path.exists())
        first = draft_path.read_text(encoding="utf-8")

        output_root = self.workspace / "WEB" / "analysis-site"
        stale_path = output_root / "pages" / "stale.md"
        stale_path.write_text("stale generated file\n", encoding="utf-8")
        self.assertTrue(stale_path.exists())

        section_path = self.workspace / "Sections" / "case-background.md"
        updated = section_path.read_text(encoding="utf-8").replace(
            "Summarize the case context, objectives, and key entities relevant to this investigation.",
            "Updated background content.",
        )
        section_path.write_text(updated, encoding="utf-8")

        _, draft_path_second = build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        self.assertEqual(draft_path, draft_path_second)
        second = draft_path_second.read_text(encoding="utf-8")
        self.assertNotEqual(first, second)
        self.assertIn("Updated background content.", second)
        self.assertFalse(stale_path.exists())
        self.assertTrue((output_root / ".caseforge" / "web_output.json").exists())
        self.assertTrue((output_root / "evidence.config.yaml").exists())
        self.assertTrue((output_root / "package.json").exists())
        self.assertTrue((output_root / "package-lock.json").exists())

        build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        third = draft_path_second.read_text(encoding="utf-8")
        self.assertEqual(second, third)

    def test_build_web_draft_rejects_unsafe_output_name_path_traversal(self) -> None:
        with self.assertRaisesRegex(ValueError, "Invalid --output-name"):
            build_web_draft(workspace_root=self.workspace, output_name="../outside", bootstrap_cases_home=self.root)

    def test_build_web_draft_rejects_unsafe_output_name_nested_path(self) -> None:
        with self.assertRaisesRegex(ValueError, "Invalid --output-name"):
            build_web_draft(workspace_root=self.workspace, output_name="nested/name", bootstrap_cases_home=self.root)

    def test_build_web_draft_rejects_unsafe_output_name_backslash_path(self) -> None:
        with self.assertRaisesRegex(ValueError, "Invalid --output-name"):
            build_web_draft(workspace_root=self.workspace, output_name="nested\\name")

    def test_build_web_draft_fails_when_runtime_bootstrap_fails_cleanly(self) -> None:
        with patch("caseforge.workspace.scaffold_evidence", side_effect=RuntimeError("bootstrap failed")):
            with self.assertRaisesRegex(RuntimeError, "Failed to bootstrap WEB Evidence runtime root: bootstrap failed"):
                build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)

    def test_build_web_draft_does_not_depend_on_templates_runtime_evidence_path(self) -> None:
        self.assertFalse((Path(__file__).resolve().parent.parent / "templates" / "runtime" / "evidence").exists())
        _, draft_path = build_web_draft(workspace_root=self.workspace, output_name="analysis-site", bootstrap_cases_home=self.root)
        self.assertTrue(draft_path.exists())


if __name__ == "__main__":
    unittest.main()
