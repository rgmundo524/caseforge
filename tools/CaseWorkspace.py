#!/usr/bin/env python3
"""CaseWorkspace CLI wrapper.

Preferred invocation (also works):
  python -m caseforge.workspace_cli <command> ...
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from caseforge.workspace_cli import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
