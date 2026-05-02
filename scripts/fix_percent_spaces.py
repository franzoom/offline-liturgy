#!/usr/bin/env python3
"""Fix missing spaces around % italic markers in patristicReading.content YAML fields."""

import re
import sys
from pathlib import Path

PUNCTUATION = set('.,:;!?)' + '»' + '’' + '"')
APOSTROPHES = ("'", "’")


def fix_percent_spaces(text: str) -> tuple[str, int]:
    """Return (fixed_text, number_of_corrections)."""
    result = []
    corrections = 0
    percent_count = 0
    i = 0

    while i < len(text):
        if text[i] == '%':
            percent_count += 1
            is_opening = (percent_count % 2 == 1)
            next_char = text[i + 1] if i + 1 < len(text) else ""

            if is_opening:
                # Add space before % only if not already followed by a space
                if next_char != " " and result and result[-1] not in (" ", " ", "\n") and result[-1] not in APOSTROPHES:
                    result.append(" ")
                    corrections += 1
            else:
                # Add space after % unless followed by punctuation or space
                result.append("%")
                if next_char and next_char not in PUNCTUATION and next_char not in (" ", " ", "\n"):
                    result.append(" ")
                    corrections += 1
                i += 1
                continue

            result.append("%")
        else:
            result.append(text[i])
        i += 1

    fixed = "".join(result)
    for punc in (",", "."):
        fixed = fixed.replace(punc + "% ", "%" + punc + " ")
    return fixed, corrections


def process_file(path: Path, dry_run: bool) -> int:
    """Process a single YAML file. Returns total corrections made."""
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines(keepends=True)

    in_patristic = False
    in_content = False
    content_indent = ""
    new_lines = []
    total_corrections = 0
    changed_lines = []

    for lineno, line in enumerate(lines, 1):
        stripped = line.lstrip()
        indent = line[:len(line) - len(stripped)]

        if "patristicReading:" in line:
            in_patristic = True
            in_content = False
            new_lines.append(line)
            continue

        if in_patristic and re.match(r"\s+content:\s*\|-", line):
            in_content = True
            content_indent = indent + "  "
            new_lines.append(line)
            continue

        if in_content:
            if stripped and not line.startswith(content_indent):
                in_content = False
                in_patristic = False
            else:
                if "%" in line:
                    fixed, n = fix_percent_spaces(line)
                    if n > 0:
                        total_corrections += n
                        changed_lines.append((lineno, line.rstrip("\n"), fixed.rstrip("\n"), n))
                    new_lines.append(fixed)
                    continue

        new_lines.append(line)

    if total_corrections == 0:
        return 0

    try:
        display_path = path.relative_to(Path.cwd())
    except ValueError:
        display_path = path
    print(f"\n  {display_path}  ({total_corrections} correction{'s' if total_corrections > 1 else ''})")
    for lineno, before, after, n in changed_lines:
        print(f"    line {lineno:4d} [{n}]:  {before.strip()}")
        print(f"               ->  {after.strip()}")

    if not dry_run:
        path.write_text("".join(new_lines), encoding="utf-8")

    return total_corrections


def main():
    dry_run = "--dry-run" in sys.argv
    root = Path("assets/calendar_data")

    if not root.exists():
        print(f"Error: directory '{root}' not found. Run from the project root.")
        sys.exit(1)

    yaml_files = sorted(root.rglob("*.yaml"))
    total_files = 0
    total_corrections = 0

    mode = "DRY-RUN" if dry_run else "APPLYING FIXES"
    print(f"=== fix_percent_spaces.py --- {mode} ===")
    print(f"Scanning {len(yaml_files)} YAML files in {root}/\n")

    for path in yaml_files:
        n = process_file(path, dry_run)
        if n > 0:
            total_files += 1
            total_corrections += n

    print(f"\n{'=' * 50}")
    if total_corrections == 0:
        print("No corrections needed.")
    else:
        print(f"{'Would fix' if dry_run else 'Fixed'} {total_corrections} spacing issue{'s' if total_corrections > 1 else ''} in {total_files} file{'s' if total_files > 1 else ''}.")
        if dry_run:
            print("Run without --dry-run to apply changes.")


if __name__ == "__main__":
    main()
