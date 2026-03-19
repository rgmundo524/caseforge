#!/usr/bin/env python3
"""CaseForge CLI wrapper.

Why this file exists:
- Running `python tools/CaseForge.py ...` sets sys.path[0] to tools/.
- Our package currently lives one directory up at ./caseforge, so we add the project root to sys.path.

Preferred invocation (also works):
  python -m caseforge.cli <command> ...
"""

import sys
from pathlib import Path

# Add project root (parent of tools/) to import path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from caseforge.cli import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
