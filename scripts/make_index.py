#!/usr/bin/env python3
"""
make_index.py — Generates assets/calendar_data/index.json

Scans calendar_data/sanctoral/ and calendar_data/special_days/ for every YAML
file and extracts celebration.title, celebration.color, and celebration.commons.
A small list of ferial_days files with liturgically significant names is also
included (Holy Thursday, Good Friday, Holy Saturday, Easter Sunday, etc.).

The resulting index.json is the single source of truth for feast display names
in the Flutter app, replacing the need to load hundreds of YAML files at runtime.

Usage:
    python3 scripts/make_index.py
    (run from the root of the offline-liturgy project)
"""

import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

ASSETS_ROOT = Path("assets/calendar_data")
SOURCE_DIRS = ["sanctoral", "special_days"]

# Individual ferial_days files whose celebration titles matter for display.
EXTRA_FERIAL_FILES = [
    "advent_1_0",
    "lent_0_3",
    "lent_6_0",
    "lent_6_4",
    "lent_6_5",
    "lent_6_6",
    "easter_1_0",
]

OUTPUT_FILE = ASSETS_ROOT / "index.json"


def extract_entry(path: Path, dir_name: str) -> dict | None:
    """Return {dir, title, color?, commons?} from a YAML file, or None if unusable."""
    try:
        with open(path, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except Exception as e:
        print(f"  WARNING: could not parse {path.name}: {e}", file=sys.stderr)
        return None

    if not isinstance(data, dict):
        return None

    celebration = data.get("celebration")
    if not isinstance(celebration, dict):
        return None

    title = celebration.get("title")
    if not title or not isinstance(title, str) or not title.strip():
        return None

    entry: dict = {"dir": dir_name, "title": title.strip()}

    color = celebration.get("color")
    if isinstance(color, str) and color.strip():
        entry["color"] = color.strip()

    commons = celebration.get("commons")
    if isinstance(commons, list) and commons:
        entry["commons"] = [str(c) for c in commons if c]

    return entry


def main() -> None:
    if not ASSETS_ROOT.exists():
        sys.exit(
            f"Directory not found: {ASSETS_ROOT}\n"
            "Run this script from the root of the offline-liturgy project."
        )

    index: dict[str, dict] = {}
    total = 0
    skipped = 0

    for dir_name in SOURCE_DIRS:
        source_dir = ASSETS_ROOT / dir_name
        if not source_dir.exists():
            print(f"WARNING: {source_dir} not found, skipping.", file=sys.stderr)
            continue

        files = sorted(source_dir.glob("*.yaml"))
        print(f"{dir_name}/: {len(files)} files")

        for path in files:
            key = path.stem
            total += 1
            entry = extract_entry(path, dir_name)
            if entry is None:
                skipped += 1
                print(f"  SKIP: {path.name} (no usable celebration block)", file=sys.stderr)
                continue
            index[key] = entry

    ferial_dir = ASSETS_ROOT / "ferial_days"
    print(f"ferial_days/ (selected): {len(EXTRA_FERIAL_FILES)} files")
    for key in EXTRA_FERIAL_FILES:
        path = ferial_dir / f"{key}.yaml"
        total += 1
        if not path.exists():
            skipped += 1
            print(f"  SKIP: {path.name} (file not found)", file=sys.stderr)
            continue
        entry = extract_entry(path, "ferial_days")
        if entry is None:
            skipped += 1
            print(f"  SKIP: {path.name} (no usable celebration block)", file=sys.stderr)
            continue
        index[key] = entry

    OUTPUT_FILE.write_text(
        json.dumps(index, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    indexed = total - skipped
    print(f"\n{indexed}/{total} entries written to {OUTPUT_FILE}")
    if skipped:
        print(f"{skipped} files skipped (see warnings above).")


if __name__ == "__main__":
    main()
