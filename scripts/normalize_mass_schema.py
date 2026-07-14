#!/usr/bin/env python3
"""
One-off migration for the mass: block schema in assets/calendar_data/{ferial_days,sanctoral}/*.yaml

- Renames sundayAndWeekCycles -> cycle (single neutral field; Dart-side code decides
  whether it means weekday Year I/II, Sunday Year A/B/C, or a free alternative).
- Quotes bare integer cycle values (- 1 / - 2 -> - '1' / - '2') so they parse as strings,
  matching the quoted convention used everywhere else.
- Normalizes truly-empty Mass fields (note, entranceAntiphon, collect, readingParts,
  offeringPrayer, prefaceList, communionAntiphon, prayerAfterCommunion, solemnBlessingList)
  to an explicit `null`, instead of leaving the key with nothing after the colon.

Operates only on the text from the top-level `mass:` line to the end of file (confirmed
to always be the last top-level key in every affected file), so the Office content
(readings/morning/vespers/etc.) that precedes it is left untouched byte-for-byte.
"""

from pathlib import Path

BASE = Path(__file__).resolve().parent.parent / "assets" / "calendar_data"

TARGET_FILES = sorted((BASE / "ferial_days").glob("*.yaml")) + [
    BASE / "sanctoral" / "roman" / "pentecost.yaml",
    BASE / "sanctoral" / "roman" / "christ_king.yaml",
    BASE / "sanctoral" / "roman" / "mary_mother_of_god.yaml",
    BASE / "sanctoral" / "roman" / "mary_mother_of_the_church.yaml",
    BASE / "sanctoral" / "roman" / "immaculate_heart_of_mary.yaml",
    BASE / "sanctoral" / "lyon" / "gregory_x_pope.yaml",
    BASE / "sanctoral" / "lyon" / "polycarp_of_smyrna_bishop.yaml",
    BASE / "sanctoral" / "lyon" / "marie_of_saint_ignatius_claudine_thevenet_religious.yaml",
]

BLANKABLE_KEYS = {
    "note",
    "entranceAntiphon",
    "collect",
    "readingParts",
    "offeringPrayer",
    "prefaceList",
    "communionAntiphon",
    "prayerAfterCommunion",
    "solemnBlessingList",
}


def normalize_mass_block(lines):
    """lines: list of raw lines (with trailing \\n) starting at `mass:` through EOF."""
    n = len(lines)
    out = []
    i = 0
    while i < n:
        line = lines[i]
        indent = line[: len(line) - len(line.lstrip(" "))]
        stripped = line.rstrip("\n")

        # 1. Rename sundayAndWeekCycles -> cycle
        if "sundayAndWeekCycles:" in stripped:
            stripped = stripped.replace("sundayAndWeekCycles:", "cycle:")

        key_part = stripped.strip()

        # 2. Quote bare integer cycle values on the line right after a `cycle:` key
        if key_part == "cycle:" and i + 1 < n:
            next_line = lines[i + 1]
            next_key = next_line.strip()
            if next_key in ("- 1", "- 2"):
                next_indent = next_line[: len(next_line) - len(next_line.lstrip(" "))]
                value = next_key[2:]
                lines[i + 1] = f"{next_indent}- '{value}'\n"

        # 3. Normalize truly-blank Mass fields to explicit null.
        # A `-` on the next line only means "this key has a nested list value" if
        # that line is indented at least as much as the key itself; a `-` at a
        # shallower indent is the *next* Mass entry in the outer `mass:` list, not
        # a child of this key (this distinction matters for the last field of a
        # Mass object, e.g. solemnBlessingList right before the next massType).
        key_name = key_part[:-1] if key_part.endswith(":") else None
        if key_name in BLANKABLE_KEYS and key_part == f"{key_name}:":
            key_indent_len = len(indent)
            has_children = False
            if i + 1 < n:
                next_line = lines[i + 1]
                next_stripped = next_line.strip()
                next_indent_len = len(next_line) - len(next_line.lstrip(" "))
                if next_stripped.startswith("-") and next_indent_len >= key_indent_len:
                    has_children = True
            if not has_children:
                stripped = f"{indent}{key_name}: null"

        out.append(stripped + "\n")
        i += 1
    return out


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    mass_start = None
    for idx, l in enumerate(lines):
        if l.startswith("mass:"):
            mass_start = idx
            break

    if mass_start is None:
        return False

    head = lines[:mass_start]
    mass_lines = normalize_mass_block(lines[mass_start:])

    new_text = "".join(head + mass_lines)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
        return True
    return False


def main():
    changed = 0
    missing = 0
    for path in TARGET_FILES:
        if not path.exists():
            print(f"[!] missing: {path}")
            missing += 1
            continue
        if process_file(path):
            changed += 1
            print(f"  ~ {path.relative_to(BASE)}")

    print(f"\n{changed} file(s) modified, {missing} missing, {len(TARGET_FILES)} total scanned.")


if __name__ == "__main__":
    main()
