from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from caseforge import workspace_cli


class WorkspaceCliTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

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

        workspace_dirs = [p for p in self.root.iterdir() if p.is_dir()]
        self.assertEqual(len(workspace_dirs), 1)
        manifest = json.loads((workspace_dirs[0] / ".caseforge" / "workspace.json").read_text(encoding="utf-8"))
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


if __name__ == "__main__":
    unittest.main()
