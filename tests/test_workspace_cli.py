from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from caseforge import workspace_cli


def _seed_local_evidence_template(cases_home: Path) -> None:
    template_root = cases_home / "evidence-templates" / "template"
    template_root.mkdir(parents=True, exist_ok=True)
    (template_root / "package.json").write_text(
        json.dumps({"name": "evidence-template", "scripts": {"dev": "evidence dev", "sources": "evidence sources"}})
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


class WorkspaceCliTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        _seed_local_evidence_template(self.root)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _workspace_dir(self) -> Path:
        matches = [p for p in self.root.iterdir() if (p / ".caseforge" / "workspace.json").exists()]
        self.assertEqual(len(matches), 1)
        return matches[0]

    def test_cli_successful_init(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            rc = workspace_cli.main(
                [
                    "init-workspace",
                    "--cases-home",
                    str(self.root),
                    "--case-id",
                    "12345",
                    "--title",
                    "Test Case",
                    "--template",
                    "default",
                    "--feature",
                    "cross-chain-activity",
                    "--feature",
                    "urls",
                ]
            )

        self.assertEqual(rc, 0)
        stdout = out.getvalue()
        self.assertIn("Initialized workspace:", stdout)

        manifest = json.loads((self._workspace_dir() / ".caseforge" / "workspace.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["features"], ["cross-chain-activity", "urls"])

    def test_cli_duplicate_features_is_clean_system_exit(self) -> None:
        with self.assertRaises(SystemExit) as ctx:
            workspace_cli.main(
                [
                    "init-workspace",
                    "--cases-home",
                    str(self.root),
                    "--case-id",
                    "12345",
                    "--title",
                    "Test Case",
                    "--template",
                    "default",
                    "--feature",
                    "urls",
                    "--feature",
                    "urls",
                ]
            )

        self.assertIn("Duplicate --feature values are not allowed", str(ctx.exception))

    def test_cli_existing_workspace_is_clean_system_exit(self) -> None:
        args = [
            "init-workspace",
            "--cases-home",
            str(self.root),
            "--case-id",
            "12345",
            "--title",
            "Test Case",
            "--template",
            "default",
        ]

        with patch("caseforge.workspace.now_stamp", return_value="20260101_010101"):
            self.assertEqual(workspace_cli.main(args), 0)
            with self.assertRaises(SystemExit) as ctx:
                workspace_cli.main(args)

        self.assertIn("Workspace directory already exists", str(ctx.exception))

    def test_cli_build_web_draft_success(self) -> None:
        init_args = [
            "init-workspace",
            "--cases-home",
            str(self.root),
            "--case-id",
            "12345",
            "--title",
            "Test Case",
            "--template",
            "default",
        ]
        self.assertEqual(workspace_cli.main(init_args), 0)
        workspace = self._workspace_dir()

        out = io.StringIO()
        with redirect_stdout(out):
            rc = workspace_cli.main(
                [
                    "build-web-draft",
                    "--workspace-root",
                    str(workspace),
                    "--output-name",
                    "analysis-site",
                    "--bootstrap-cases-home",
                    str(self.root),
                ]
            )

        self.assertEqual(rc, 0)
        stdout = out.getvalue()
        self.assertIn("Built web draft:", stdout)
        self.assertTrue((workspace / "Sources" / "derived" / "sections_snapshot.json").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "pages" / "index.md").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "evidence.config.yaml").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / ".caseforge" / "web_output.json").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "package.json").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "package-lock.json").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / ".npmrc").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "degit.json").exists())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "scripts").is_dir())
        self.assertTrue((workspace / "WEB" / "analysis-site" / "sources" / "case" / "connection.yaml").exists())
        self.assertFalse((workspace / "WEB" / "analysis-site" / "sources" / "needful_things").exists())

    def test_cli_build_web_draft_invalid_section_metadata_is_clean_system_exit(self) -> None:
        init_args = [
            "init-workspace",
            "--cases-home",
            str(self.root),
            "--case-id",
            "12345",
            "--title",
            "Test Case",
            "--template",
            "default",
        ]
        self.assertEqual(workspace_cli.main(init_args), 0)
        workspace = self._workspace_dir()
        bad_file = workspace / "Sections" / "case-background.md"
        bad_file.write_text("# Case Background\n\nBroken.\n", encoding="utf-8")

        with self.assertRaises(SystemExit) as ctx:
            workspace_cli.main(
                [
                    "build-web-draft",
                    "--workspace-root",
                    str(workspace),
                    "--output-name",
                    "analysis-site",
                    "--bootstrap-cases-home",
                    str(self.root),
                ]
            )

        self.assertIn("missing frontmatter block", str(ctx.exception))

    def test_cli_build_web_draft_invalid_output_name_is_clean_system_exit(self) -> None:
        init_args = [
            "init-workspace",
            "--cases-home",
            str(self.root),
            "--case-id",
            "12345",
            "--title",
            "Test Case",
            "--template",
            "default",
        ]
        self.assertEqual(workspace_cli.main(init_args), 0)
        workspace = self._workspace_dir()

        with self.assertRaises(SystemExit) as ctx:
            workspace_cli.main(
                [
                    "build-web-draft",
                    "--workspace-root",
                    str(workspace),
                    "--output-name",
                    "../outside",
                    "--bootstrap-cases-home",
                    str(self.root),
                ]
            )

        self.assertIn("Invalid --output-name", str(ctx.exception))

    def test_cli_add_files_delegates_to_sources_case_root(self) -> None:
        self.assertEqual(
            workspace_cli.main(
                [
                    "init-workspace",
                    "--cases-home",
                    str(self.root),
                    "--case-id",
                    "12345",
                    "--title",
                    "Test Case",
                    "--template",
                    "default",
                ]
            ),
            0,
        )
        workspace = self._workspace_dir()

        sample = self.root / "sample.csv"
        sample.write_text("a,b\n1,2\n", encoding="utf-8")

        with patch("caseforge.workspace_cli.add_files") as add_files_mock:
            self.assertEqual(
                workspace_cli.main(
                    [
                        "add-files",
                        "--workspace-root",
                        str(workspace),
                        "--source",
                        "trm",
                        "--model",
                        "account",
                        str(sample),
                    ]
                ),
                0,
            )

        kwargs = add_files_mock.call_args.kwargs
        self.assertEqual(kwargs["case_root"], workspace / "Sources")
        self.assertEqual(kwargs["source_system"], "trm")
        self.assertEqual(kwargs["tx_model"], "account")
        self.assertEqual(kwargs["export_type"], "trm")
        self.assertEqual(kwargs["files"], [sample.resolve()])

    def test_cli_normalize_delegates_to_sources_case_root(self) -> None:
        self.assertEqual(
            workspace_cli.main(
                [
                    "init-workspace",
                    "--cases-home",
                    str(self.root),
                    "--case-id",
                    "12345",
                    "--title",
                    "Test Case",
                    "--template",
                    "default",
                ]
            ),
            0,
        )
        workspace = self._workspace_dir()

        with patch("caseforge.workspace_cli.normalize_db") as normalize_mock:
            self.assertEqual(
                workspace_cli.main(
                    [
                        "normalize",
                        "--workspace-root",
                        str(workspace),
                    ]
                ),
                0,
            )

        kwargs = normalize_mock.call_args.kwargs
        self.assertEqual(kwargs["case_root"], workspace / "Sources")
        self.assertEqual(kwargs["duckdb_bin"], "duckdb")

    def test_cli_build_db_delegates_to_sources_case_root_and_disables_sources_flag(self) -> None:
        self.assertEqual(
            workspace_cli.main(
                [
                    "init-workspace",
                    "--cases-home",
                    str(self.root),
                    "--case-id",
                    "12345",
                    "--title",
                    "Test Case",
                    "--template",
                    "default",
                ]
            ),
            0,
        )
        workspace = self._workspace_dir()

        with patch("caseforge.workspace_cli.build_db") as build_mock:
            self.assertEqual(
                workspace_cli.main(
                    [
                        "build-db",
                        "--workspace-root",
                        str(workspace),
                    ]
                ),
                0,
            )

        kwargs = build_mock.call_args.kwargs
        self.assertEqual(kwargs["case_root"], workspace / "Sources")
        self.assertEqual(kwargs["duckdb_bin"], "duckdb")
        self.assertFalse(kwargs["run_sources"])

    def test_cli_workspace_command_missing_manifest_fails_cleanly(self) -> None:
        bad_workspace = self.root / "bad-workspace"
        (bad_workspace / "Sources").mkdir(parents=True)

        with self.assertRaises(SystemExit) as ctx:
            workspace_cli.main(
                [
                    "normalize",
                    "--workspace-root",
                    str(bad_workspace),
                ]
            )

        self.assertIn("Workspace manifest not found", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
