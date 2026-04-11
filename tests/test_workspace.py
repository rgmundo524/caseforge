from __future__ import annotations

import json
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

from caseforge.workspace import init_workspace


class WorkspaceInitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)

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


if __name__ == "__main__":
    unittest.main()
