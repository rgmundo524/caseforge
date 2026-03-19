#!/usr/bin/env python3
"""Legacy ProjForge CLI wrapper.

Kept for backward compatibility. Use `python tools/CaseForge.py ...` for the
canonical command path.
"""

import sys
from pathlib import Path

# Add project root (parent of tools/) to import path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from caseforge.cli import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
