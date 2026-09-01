#!/usr/bin/env python3
"""Normalize French insecable-space typography in the liturgical YAML assets.

Scans every *.yaml file under a root directory (default: assets/), skipping
the psalms/ subtree, and fixes spacing around French double punctuation,
guillemets, and a few liturgical line markers. Only text VALUES are ever
rewritten -- YAML structure (the "key:" separator itself, list markers,
block-scalar indicators) is left byte-for-byte untouched, by parsing each
line's role (key, list item, or raw block-scalar content) before touching
anything.

Rules:
  1. Before ? ; ! -> narrow no-break space (U+202F).
  2. Before :     -> no-break space (U+00A0).
  3. Before »     -> no-break space (U+00A0).
  4. After  «     -> no-break space (U+00A0).
  5. * at the start of a text line  -> no-break space right after it.
  6. R/ or V/ at the start of a text line -> no-break space right after it.
  7. Inside collect / offeringPrayer / prayerAfterCommunion (raw string
     lists) and entranceAntiphon[].content / communionAntiphon[].content:
     a trailing * + or / at end of line gets a no-break space before it,
     and any trailing space after it is dropped.
  8. Straight apostrophe (U+0027) -> typographic apostrophe (U+2019).
     Skipped inside a single-quoted YAML scalar ('...'), since ' is that
     scalar's own delimiter there.

Any existing run of regular spaces/tabs/no-break spaces adjacent to these
positions is collapsed into the single correct character; if none is
present, one is inserted.

Usage:
  python3 scripts/fix_nbsp.py                 # dry-run, prints a diff
  python3 scripts/fix_nbsp.py --write         # apply changes in place
  python3 scripts/fix_nbsp.py --root assets/calendar_data/commons --write
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

APOSTROPHE = "'"  # straight apostrophe (U+0027)
TYPO_APOSTROPHE = "’"  # typographic apostrophe (U+2019)
NNBSP = " "  # narrow no-break space ("demi-insecable")
NBSP = " "  # no-break space ("insecable pleine")
SPACE_RUN = r"[ \t  ]*"

RULE7_SUFFIXES_1 = {("collect",), ("offeringPrayer",), ("prayerAfterCommunion",)}
RULE7_SUFFIXES_2 = {("entranceAntiphon", "content"), ("communionAntiphon", "content")}


def matches_rule7_path(key_path: tuple[str, ...]) -> bool:
    return key_path[-1:] in RULE7_SUFFIXES_1 or key_path[-2:] in RULE7_SUFFIXES_2


RE_BEFORE_DEMI = re.compile(SPACE_RUN + r"([?;!])")
RE_BEFORE_COLON = re.compile(SPACE_RUN + r"(:)")
RE_BEFORE_CLOSE_GUILLEMET = re.compile(SPACE_RUN + r"(»)")
RE_AFTER_OPEN_GUILLEMET = re.compile(r"(«)" + SPACE_RUN)
RE_LEADING_MARKER = re.compile(r"^(\s*)(\*|R/|V/)" + SPACE_RUN)
RE_TRAILING_MARK = re.compile(r"^(.*?)" + SPACE_RUN + r"([*+/])[ \t]*$")

KEY_LINE_RE = re.compile(r"^(\s*(?:-\s+)?)([a-zA-Z][a-zA-Z0-9]*):(.*)$")
LIST_SCALAR_RE = re.compile(r"^(\s*-\s+)(.*)$")
BLOCK_HEADER_RE = re.compile(r"^\s*[|>][+-]?\s*(?:#.*)?$")


def is_single_quoted_scalar(value: str) -> bool:
    s = value.strip()
    return len(s) >= 2 and s[0] == "'" and s[-1] == "'"


def fix_apostrophes(text: str) -> str:
    return text.replace(APOSTROPHE, TYPO_APOSTROPHE)


def fix_inline_text(text: str, apostrophes: bool) -> str:
    if apostrophes:
        text = fix_apostrophes(text)
    text = RE_BEFORE_DEMI.sub(NNBSP + r"\1", text)
    text = RE_BEFORE_COLON.sub(NBSP + r"\1", text)
    text = RE_BEFORE_CLOSE_GUILLEMET.sub(NBSP + r"\1", text)
    text = RE_AFTER_OPEN_GUILLEMET.sub(r"\1" + NBSP, text)
    return text


def fix_leading_marker(text: str) -> str:
    m = RE_LEADING_MARKER.match(text)
    if not m:
        return text
    marker = m.group(2)
    return text[: m.start(2)] + marker + NBSP + text[m.end() :]


def fix_trailing_mark(text: str, key_path: tuple[str, ...]) -> str:
    if not matches_rule7_path(key_path):
        return text
    m = RE_TRAILING_MARK.match(text)
    if not m:
        return text
    pre, mark = m.group(1), m.group(2)
    if mark == "/" and pre[-1:] in ("R", "V"):
        return text
    return pre + NBSP + mark


def fix_text(text: str, key_path: tuple[str, ...], apostrophes: bool = True) -> str:
    text = fix_inline_text(text, apostrophes)
    text = fix_leading_marker(text)
    text = fix_trailing_mark(text, key_path)
    return text


class FileFixer:
    def __init__(self) -> None:
        self.stack: list[tuple[int, str]] = []
        self.in_block = False
        self.block_indent: int | None = None
        self.block_key_path: tuple[str, ...] = ()

    def current_key_path(self) -> tuple[str, ...]:
        return tuple(key for _, key in self.stack)

    def process_block_line(self, line: str) -> str | None:
        """Return the fixed line while inside a block scalar, or None if
        this line actually dedents out of the block (caller should
        reprocess it as a normal line)."""
        if line.strip() == "":
            return line
        indent = len(line) - len(line.lstrip(" "))
        if self.block_indent is None:
            self.block_indent = indent
        if indent < self.block_indent:
            self.in_block = False
            return None
        return fix_text(line, self.block_key_path)

    def process_normal_line(self, line: str) -> str:
        if line.strip() == "" or line.lstrip().startswith("#"):
            return line

        indent = len(line) - len(line.lstrip(" "))

        m = KEY_LINE_RE.match(line)
        if m:
            prefix, key, value = m.group(1), m.group(2), m.group(3)
            key_col = m.start(2)
            while self.stack and self.stack[-1][0] >= key_col:
                self.stack.pop()
            self.stack.append((key_col, key))
            key_path = self.current_key_path()

            if BLOCK_HEADER_RE.match(value):
                self.in_block = True
                self.block_indent = None
                self.block_key_path = key_path
                return line

            apostrophes = not is_single_quoted_scalar(value)
            return prefix + key + ":" + fix_text(value, key_path, apostrophes)

        m = LIST_SCALAR_RE.match(line)
        if m:
            prefix, value = m.group(1), m.group(2)
            key_path = self.current_key_path()

            if BLOCK_HEADER_RE.match(value):
                self.in_block = True
                self.block_indent = None
                self.block_key_path = key_path
                return line

            apostrophes = not is_single_quoted_scalar(value)
            return prefix + fix_text(value, key_path, apostrophes)

        # Anything else (document markers, unexpected syntax, ...) is left
        # untouched rather than guessed at.
        _ = indent
        return line

    def process_line(self, line: str) -> str:
        if self.in_block:
            fixed = self.process_block_line(line)
            if fixed is not None:
                return fixed
            # fall through: this line dedents out of the block scalar
        return self.process_normal_line(line)


def compute_fixed_lines(original: str) -> tuple[list[str], list[tuple[int, str, str]]]:
    lines = original.splitlines(keepends=True)
    fixer = FileFixer()
    changes: list[tuple[int, str, str]] = []
    new_lines: list[str] = []

    for lineno, raw_line in enumerate(lines, start=1):
        line = raw_line.rstrip("\n")
        ending = raw_line[len(line) :]
        fixed = fixer.process_line(line)
        if fixed != line:
            changes.append((lineno, line, fixed))
        new_lines.append(fixed + ending)

    return new_lines, changes


def process_file(path: Path, write: bool) -> list[tuple[int, str, str]]:
    original = path.read_text(encoding="utf-8")
    new_lines, changes = compute_fixed_lines(original)
    if write and changes:
        path.write_text("".join(new_lines), encoding="utf-8")
    return changes


def iter_yaml_files(root: Path):
    for path in sorted(root.rglob("*.yaml")):
        if "psalms" in path.relative_to(root).parts or "psalms" in path.parts:
            continue
        yield path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default="assets", help="Directory to scan (default: assets)")
    parser.add_argument("--write", action="store_true", help="Apply changes in place (default: dry-run)")
    args = parser.parse_args()

    root = Path(args.root)
    total_files = 0
    total_changes = 0

    for path in iter_yaml_files(root):
        changes = process_file(path, args.write)

        if changes:
            total_files += 1
            total_changes += len(changes)
            print(f"\n{path}")
            for lineno, old, new in changes:
                print(f"  {lineno:5d} - {old!r}")
                print(f"        + {new!r}")

    print()
    print("=" * 70)
    action = "Fixed" if args.write else "Found"
    print(f"{action} {total_changes} change(s) in {total_files} file(s).")
    if not args.write and total_changes:
        print("Run with --write to apply.")


if __name__ == "__main__":
    main()
