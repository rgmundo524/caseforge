from __future__ import annotations

import shutil
from pathlib import Path


def ensure_dir(p: Path) -> None:
    """Create a directory and parents if needed."""
    p.mkdir(parents=True, exist_ok=True)


def copy_tree(src: Path, dst: Path) -> None:
    """
    Copy the contents of src directory into dst directory.

    Expectations:
    - dst does not exist or is empty
    - copies immediate children from src into dst (not nesting src itself)
    """
    if dst.exists() and any(dst.iterdir()):
        raise RuntimeError(f"Destination directory is not empty: {dst}")

    ensure_dir(dst)

    for item in src.iterdir():
        dest = dst / item.name
        if item.is_dir():
            shutil.copytree(item, dest, dirs_exist_ok=False)
        else:
            shutil.copy2(item, dest)
