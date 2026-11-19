#!/usr/bin/env python3
"""
validate_hebrew_psalms.py — Consistency checks between assets/psalms/*.yaml
(French) and assets/psalms/hebrew/*.yaml (Hebrew), run after
import_hebrew_psalms.py --write.

Checks:
  1. Every assets/psalms/PSALM_*.yaml has a matching
     assets/psalms/hebrew/PSALM_*.yaml.
  2. Both files use exactly the same set of `{N}` verse numbers (same
     verses present, none added or dropped).
  3. The Hebrew file's content has no residual `/` (OSHB's internal
     morphological-segment marker — should already be stripped by the
     importer).
  4. No `{...}` verse marker contains anything but ASCII digits (a Hebrew
     verse must never be numbered in Hebrew letters).

Usage:
    python3 scripts/validate_hebrew_psalms.py
    (run from the root of the offline-liturgy project)
"""

import glob
import re
import sys
from pathlib import Path

PSALMS_DIR = Path("assets/psalms")
HEBREW_DIR = PSALMS_DIR / "hebrew"

VERSE_MARKER_RE = re.compile(r"\{([^}]*)\}")
NUMERIC_MARKER_RE = re.compile(r"^\d+$")


def main() -> int:
    french_files = sorted(glob.glob(str(PSALMS_DIR / "PSALM_*.yaml")))
    problems = []

    for path in french_files:
        stem = Path(path).name
        hebrew_path = HEBREW_DIR / stem

        if not hebrew_path.exists():
            problems.append(f"{stem}: no matching Hebrew file")
            continue

        french_text = Path(path).read_text(encoding="utf-8")
        hebrew_text = hebrew_path.read_text(encoding="utf-8")

        french_verses = sorted(set(VERSE_MARKER_RE.findall(french_text)))
        hebrew_markers = VERSE_MARKER_RE.findall(hebrew_text)
        hebrew_verses = sorted(set(hebrew_markers))

        if french_verses != hebrew_verses:
            problems.append(
                f"{stem}: verse sets differ — French {french_verses} "
                f"vs Hebrew {hebrew_verses}"
            )

        for marker in hebrew_markers:
            if not NUMERIC_MARKER_RE.match(marker):
                problems.append(
                    f"{stem}: non-numeric verse marker {{{marker}}} "
                    "(Hebrew letters are never used for verse numbers)"
                )

        if "/" in hebrew_text:
            problems.append(f"{stem}: residual '/' morphological marker in Hebrew text")

    if problems:
        print(f"{len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"OK: {len(french_files)} French/Hebrew psalm pairs checked, all consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
