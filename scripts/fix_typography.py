#!/usr/bin/env python3
"""
YAML typography fixer for French liturgical texts.
Fixes in values only (not in keys):
  1. Straight apostrophes (U+0027) -> typographic apostrophe (U+2019)
  2. Double typographic apostrophes -> single (artefact from YAML-escaped strings)
  3. Regular space before ! ? : ; and closing guillemet -> non-breaking space (U+00A0)
  4. Regular space after opening guillemet -> non-breaking space (U+00A0)
  5. Double-quoted values: remove quotes if no colon; convert to block scalar if colon present

Usage:
  python fix_typography.py             # dry-run: shows issues without modifying
  python fix_typography.py --fix       # apply fixes
  python fix_typography.py path/       # scan a specific directory
  python fix_typography.py --fix path/ # fix in a specific directory
"""

import re
import sys
from pathlib import Path

APOSTROPHE      = "'"  # straight apostrophe '
TYPO_APOSTROPHE = "’"  # typographic apostrophe '
NBSP            = " "  # non-breaking space
GUILLEMET_OPEN  = "«"  # «
GUILLEMET_CLOSE = "»"  # »
DOUBLE_PUNCT    = "!?:;" + GUILLEMET_CLOSE


def fix_value(s: str) -> str:
    # 1. Straight apostrophes -> typographic
    s = s.replace(APOSTROPHE, TYPO_APOSTROPHE)
    # 2. Double typographic apostrophes -> single
    s = s.replace(TYPO_APOSTROPHE * 2, TYPO_APOSTROPHE)
    # 3. Regular space before double punctuation and closing guillemet -> NBSP
    s = re.sub(r" ([!?:;" + GUILLEMET_CLOSE + r"])", NBSP + r"\1", s)
    # 4. Regular space after opening guillemet -> NBSP
    s = re.sub(GUILLEMET_OPEN + r" ", GUILLEMET_OPEN + NBSP, s)
    return s


def is_yaml_single_quoted(value: str) -> bool:
    """Return True if value is a YAML single-quoted scalar (e.g. '2', '1')."""
    s = value.strip()
    return len(s) >= 2 and s[0] == "'" and s[-1] == "'"


def extract_double_quoted(value: str) -> "tuple[str, bool] | None":
    """
    If value is a double-quoted YAML string, return (inner_content, has_colon).
    Returns None if not double-quoted. Handles basic \" escape.
    """
    s = value.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        inner = s[1:-1].replace('\\"', '"')
        return inner, ":" in inner
    return None


def process_yaml_file(path: Path, fix: bool) -> "list[tuple[int, str, str]]":
    """Return list of (lineno, old_line_content, new_line_content) for changed lines.
    new_line_content may contain a literal newline when a line expands to a block scalar.
    """
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    changes: list[tuple[int, str, str]] = []
    new_lines: list[str] = []

    in_block = False
    block_base_indent = -1

    for lineno, line in enumerate(lines, 1):
        raw = line.rstrip("\n\r")
        lstripped = raw.lstrip()
        indent = len(raw) - len(lstripped)
        ending = line[len(raw):]  # preserve original line ending (\n or \r\n)

        # Empty lines pass through unchanged; only exit block scalar if not already in one
        if not lstripped:
            if not in_block:
                block_base_indent = -1
            new_lines.append(line)
            continue

        # Comments pass through unchanged
        if lstripped.startswith("#"):
            new_lines.append(line)
            continue

        # Exit block scalar when indentation returns to key level
        if in_block and indent <= block_base_indent:
            in_block = False
            block_base_indent = -1

        # Inside block scalar: entire line is value content
        if in_block:
            fixed = fix_value(raw)
            if fixed != raw:
                changes.append((lineno, raw, fixed))
                new_lines.append(fixed + ending)
            else:
                new_lines.append(line)
            continue

        # Strip optional list marker to get the "payload" for parsing
        list_pfx = ""
        payload = raw
        m = re.match(r"^(\s*-\s+)(.*)", raw)
        if m:
            list_pfx = m.group(1)
            payload = m.group(2)

        # Block scalar start: key: | or key: |- or key: >
        if re.match(r"^\s*\w+:\s*[|>][-+]?\s*$", payload):
            in_block = True
            block_base_indent = indent
            new_lines.append(line)
            continue

        # key: value  (key is a camelCase/snake_case identifier)
        m = re.match(r"^(\s*)(\w+):\s*(.*)", payload)
        if m:
            key_indent = m.group(1)
            key = m.group(2)
            value = m.group(3)

            if is_yaml_single_quoted(value):
                new_lines.append(line)
                continue
            quoted = extract_double_quoted(value)
            if quoted is not None:
                inner, has_colon = quoted
                fixed_inner = fix_value(inner)
                if has_colon:
                    # Convert to block scalar
                    content_indent = " " * (len(list_pfx) + len(key_indent) + 2)
                    line1 = list_pfx + key_indent + key + ": |-"
                    line2 = content_indent + fixed_inner
                    changes.append((lineno, raw, line1 + "\n" + line2))
                    new_lines.append(line1 + ending)
                    new_lines.append(line2 + ending)
                else:
                    # Remove quotes
                    new_raw = list_pfx + key_indent + key + ": " + fixed_inner
                    changes.append((lineno, raw, new_raw))
                    new_lines.append(new_raw + ending)
            else:
                fixed_value = fix_value(value)
                if fixed_value != value:
                    new_raw = list_pfx + key_indent + key + ": " + fixed_value
                    changes.append((lineno, raw, new_raw))
                    new_lines.append(new_raw + ending)
                else:
                    new_lines.append(line)
            continue

        # Plain list value (no key: just a scalar after "- ")
        if list_pfx:
            if is_yaml_single_quoted(payload):
                new_lines.append(line)
                continue
            quoted = extract_double_quoted(payload)
            if quoted is not None:
                inner, has_colon = quoted
                fixed_inner = fix_value(inner)
                if has_colon:
                    # Convert to block scalar list item
                    content_indent = " " * len(list_pfx)
                    line1 = list_pfx.rstrip() + " |-"
                    line2 = content_indent + fixed_inner
                    changes.append((lineno, raw, line1 + "\n" + line2))
                    new_lines.append(line1 + ending)
                    new_lines.append(line2 + ending)
                else:
                    new_raw = list_pfx + fixed_inner
                    changes.append((lineno, raw, new_raw))
                    new_lines.append(new_raw + ending)
            else:
                fixed_payload = fix_value(payload)
                if fixed_payload != payload:
                    new_raw = list_pfx + fixed_payload
                    changes.append((lineno, raw, new_raw))
                    new_lines.append(new_raw + ending)
                else:
                    new_lines.append(line)
            continue

        new_lines.append(line)

    if fix and changes:
        path.write_text("".join(new_lines), encoding="utf-8")

    return changes


def main() -> None:
    args = sys.argv[1:]
    fix = "--fix" in args
    args = [a for a in args if a != "--fix"]

    root = Path(args[0]) if args else Path(".")
    yaml_files = sorted(root.rglob("*.yaml")) + sorted(root.rglob("*.yml"))

    total_files = 0
    total_changes = 0

    for path in yaml_files:
        changes = process_yaml_file(path, fix)
        if changes:
            total_files += 1
            total_changes += len(changes)
            rel = path.relative_to(root) if path.is_relative_to(root) else path
            print(f"\n{rel}")
            for lineno, old, new in changes:
                print(f"  {lineno:4d} - {repr(old)}")
                for part in new.split("\n"):
                    print(f"       + {repr(part)}")

    print()
    print("=" * 70)
    action = "Fixed" if fix else "Found"
    print(f"{action} {total_changes} issue(s) in {total_files} file(s).")
    if not fix and total_changes:
        print("Run with --fix to apply corrections.")


if __name__ == "__main__":
    main()
