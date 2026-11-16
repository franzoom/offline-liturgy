#!/usr/bin/env python3
"""
make_index.py — Generates assets/calendar_data/index.json and
assets/calendar_data/validated_locations.json

Scans calendar_data/sanctoral/ for every YAML file and extracts
celebration.title, celebration.color, and celebration.commons.
A small list of ferial_days files with liturgically significant names is also
included (Holy Thursday, Good Friday, Holy Saturday, Easter Sunday, etc.).

The resulting index.json is the single source of truth for feast display names
in the Flutter app, replacing the need to load hundreds of YAML files at runtime.

It also decides which assets/locations/*.yaml ids the Flutter location picker
may show (validated_locations.json) — see compute_validated_locations() and
CLAUDE.md's "Location picker (locationTree) pruning" section.

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
SOURCE_DIRS = ["sanctoral"]

OUTPUT_FILE = ASSETS_ROOT / "index.json"
COMMON_FEASTS_FILE = ASSETS_ROOT / "common_feasts.yaml"
LOCATIONS_DIR = Path("assets/locations")
VALIDATED_LOCATIONS_FILE = ASSETS_ROOT / "validated_locations.json"
PUBSPEC_FILE = Path("pubspec.yaml")

# Glob patterns for ferial_days files whose celebration titles matter for display.
# Each pattern is matched against ferial_days/*.yaml (stem only, no extension).
FERIAL_PATTERNS = [
    "*_0",                                  # All Sundays (ferial codes ending in _0)
    "advent_1[7-9]", "advent_2[0-4]",      # Dec 17–24 proper days
    "christmas_2[6-9]", "christmas_3[0-1]", # Dec 26–31 Christmas octave days
    "christmas-ferial_before_epiphany_*",   # Jan 2 to Epiphany eve proper days
    "lent_0_[3-6]",                         # Ash Wednesday and following days
    "lent_6_[1-6]",                         # Holy Thursday, Good Friday, Holy Saturday
]


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

        files = sorted(source_dir.rglob("*.yaml"))
        print(f"{dir_name}/: {len(files)} files")

        for path in files:
            key = str(path.relative_to(source_dir).with_suffix(""))
            total += 1
            entry = extract_entry(path, dir_name)
            if entry is None:
                skipped += 1
                print(f"  SKIP: {path.name} (no usable celebration block)", file=sys.stderr)
                continue
            index[key] = entry

    ferial_dir = ASSETS_ROOT / "ferial_days"
    ferial_keys: dict[str, Path] = {}
    for pattern in FERIAL_PATTERNS:
        for path in sorted(ferial_dir.glob(f"{pattern}.yaml")):
            ferial_keys[path.stem] = path

    print(f"ferial_days/ (selected): {len(ferial_keys)} files")
    for key, path in ferial_keys.items():
        total += 1
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

    compute_validated_locations(index)


def compute_validated_locations(index: dict) -> None:
    """Writes assets/calendar_data/validated_locations.json: the ids from
    assets/locations/*.yaml the Flutter location picker may show.

    A location with its own non-empty `sanctoral/<id>/` folder always
    qualifies. One with none — a diocese file that only re-ranks or
    relocates an inherited feast via `move:`/`feasts:`, reusing a parent's
    or the universal Roman calendar's text (e.g. basel.yaml,
    lausanne_geneva_fribourg.yaml, sion_saint_maurice.yaml) — qualifies only
    if EVERY one of its `move:`/`feasts:` entries resolves without a file of
    its own. This mirrors how Calendar.addItemToDay / moveItemToDate
    (lib/classes/calendar_class.dart) actually resolve a bare feast key at
    runtime: same-day key-preservation, or a prefix-agnostic base-name
    search against whatever an ancestor already placed. One unresolved
    (dead-reference) entry disqualifies the whole location — most French
    diocese files are mostly dead references and stay excluded. See
    CLAUDE.md, "Location picker (locationTree) pruning".
    """
    if not LOCATIONS_DIR.exists():
        print(f"WARNING: {LOCATIONS_DIR} not found, skipping {VALIDATED_LOCATIONS_FILE}.",
              file=sys.stderr)
        return

    common_doc = {}
    if COMMON_FEASTS_FILE.exists():
        with open(COMMON_FEASTS_FILE, encoding="utf-8") as f:
            common_doc = yaml.safe_load(f) or {}
    common_keys = set((common_doc.get("feasts") or {}).keys())

    locations: dict[str, dict] = {}
    for path in sorted(LOCATIONS_DIR.glob("*.yaml")):
        with open(path, encoding="utf-8") as f:
            locations[path.stem] = yaml.safe_load(f) or {}

    # Base names each location's own sanctoral/<id>/ folder actually backs —
    # only successfully-indexed files count, same as the Dart side's
    # knownCodes (built from this same index).
    own_names: dict[str, set[str]] = {}
    for code in index:
        if "/" in code:
            prefix, name = code.split("/", 1)
            own_names.setdefault(prefix, set()).add(name)

    cache: dict[str, set[str]] = {}

    def resolvable_for_children(loc_id: str) -> set[str]:
        """Base names resolvable for loc_id's children: the universal Roman
        calendar, plus every ancestor's (and loc_id's own) sanctoral files."""
        if loc_id in cache:
            return cache[loc_id]
        parent_id = locations[loc_id].get("parent")
        inherited = (resolvable_for_children(parent_id)
                     if parent_id in locations else set(common_keys))
        result = inherited | own_names.get(loc_id, set())
        cache[loc_id] = result
        return result

    usable: list[str] = []
    for loc_id, doc in locations.items():
        own = own_names.get(loc_id, set())
        parent_id = doc.get("parent")
        inherited = (resolvable_for_children(parent_id)
                     if parent_id in locations else set(common_keys))

        entries = list((doc.get("feasts") or {}).keys()) + \
            list((doc.get("move") or {}).keys())
        dead = [k for k in entries if k not in own and k not in inherited]

        if own or (entries and not dead):
            usable.append(loc_id)
        elif dead:
            print(f"  NOTE: {loc_id} not shown in the picker — dead reference(s): "
                  f"{', '.join(dead)}", file=sys.stderr)

    VALIDATED_LOCATIONS_FILE.write_text(
        json.dumps(sorted(usable), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"{len(usable)}/{len(locations)} locations written to {VALIDATED_LOCATIONS_FILE}")


def sync_pubspec_sanctoral() -> None:
    """Add/remove assets/calendar_data/sanctoral/<subdir>/ entries in pubspec.yaml."""
    sanctoral_dir = ASSETS_ROOT / "sanctoral"
    if not sanctoral_dir.exists():
        return

    actual_subdirs = sorted(
        p.name for p in sanctoral_dir.iterdir() if p.is_dir()
    )

    if not PUBSPEC_FILE.exists():
        print(f"WARNING: {PUBSPEC_FILE} not found, skipping pubspec sync.", file=sys.stderr)
        return

    lines = PUBSPEC_FILE.read_text(encoding="utf-8").splitlines(keepends=True)

    declared = set()
    last_sanctoral_index = -1
    prefix = "    - assets/calendar_data/sanctoral/"
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("- assets/calendar_data/sanctoral/"):
            subdir = stripped.removeprefix("- assets/calendar_data/sanctoral/").rstrip("/")
            if subdir:
                declared.add(subdir)
            last_sanctoral_index = i

    actual_set = set(actual_subdirs)
    missing = [d for d in actual_subdirs if d not in declared]
    obsolete = [d for d in declared if d not in actual_set]

    if not missing and not obsolete:
        print("\npubspec.yaml: all sanctoral subdirectories already declared.")
        return

    if obsolete:
        obsolete_entries = {f"assets/calendar_data/sanctoral/{d}/" for d in obsolete}
        lines = [
            line for line in lines
            if line.strip().lstrip("- ") not in obsolete_entries
        ]
        last_sanctoral_index = next(
            (i for i in range(len(lines) - 1, -1, -1)
             if lines[i].strip().startswith("- assets/calendar_data/sanctoral/")),
            last_sanctoral_index,
        )

    if missing:
        new_lines = [f"{prefix}{d}/\n" for d in missing]
        insert_at = last_sanctoral_index + 1
        lines[insert_at:insert_at] = new_lines

    PUBSPEC_FILE.write_text("".join(lines), encoding="utf-8")
    if missing:
        print(f"\npubspec.yaml: added {len(missing)} missing sanctoral entries:")
        for d in missing:
            print(f"  + assets/calendar_data/sanctoral/{d}/")
    if obsolete:
        print(f"\npubspec.yaml: removed {len(obsolete)} obsolete sanctoral entries:")
        for d in obsolete:
            print(f"  - assets/calendar_data/sanctoral/{d}/")


if __name__ == "__main__":
    main()
    sync_pubspec_sanctoral()
