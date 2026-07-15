#!/usr/bin/env python3
"""
One-off migration: convert `_text_` emphasis pairs to `%text%` inside YAML
block-scalar text bodies (content/headline/chorus/etc.), across the whole
calendar_data corpus.

Why: the Flutter YamlTextParser only ever recognized `%text%` as the italic
toggle. `_..._` was never implemented, so this content has always silently
rendered as plain text. `_` is otherwise heavily used elsewhere in this data
as an identifier separator (celebration codes like `ot_25_0`,
`roman/josephine_bakhita_virgin`) — those must NOT be touched, so this script
only rewrites underscores found inside literal block-scalar bodies (`key: |-`
style), never in scalar identifier values, which are never written as block
literals in this codebase.

A pair can legitimately span multiple lines (e.g. a multi-line quoted list),
so each block-scalar body is treated as a single string (newlines preserved)
before the underscore pair is located; only the two underscore characters
themselves are swapped for `%`, so line structure is never altered.
"""

import re
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent / "assets" / "calendar_data"

BLOCK_HEADER_RE = re.compile(r'^(\s*)(?:-\s+)?[\w]+:\s*[|>][-+0-9]*\s*$')
# Underscore-pair emphasis: opening _ immediately followed by a letter (never
# a digit, to avoid touching numeric identifiers), closing _ anywhere after.
PAIR_RE = re.compile(r'_([A-Za-zÀ-ÿ][^_]*?)_', re.DOTALL)


def find_block_ranges(lines):
    """Returns list of (start, end) exclusive line-index ranges that are the
    *body* of a block scalar (the line after the `key: |-` header, through
    the last line at greater indentation)."""
    ranges = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        m = BLOCK_HEADER_RE.match(line)
        if m:
            header_indent = len(m.group(1))
            body_start = i + 1
            j = body_start
            while j < n:
                l = lines[j]
                if l.strip() == "":
                    j += 1
                    continue
                indent = len(l) - len(l.lstrip(" "))
                if indent <= header_indent:
                    break
                j += 1
            if j > body_start:
                ranges.append((body_start, j))
            i = j
        else:
            i += 1
    return ranges


def process_file(path: Path):
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    ranges = find_block_ranges(lines)

    total_subs = 0
    for start, end in ranges:
        block_lines = lines[start:end]
        block_text = "\n".join(block_lines)
        new_text, n_subs = PAIR_RE.subn(lambda m: "%" + m.group(1) + "%", block_text)
        if n_subs:
            total_subs += n_subs
            lines[start:end] = new_text.split("\n")

    if total_subs:
        new_content = "\n".join(lines)
        if new_content != text:
            path.write_text(new_content, encoding="utf-8")
    return total_subs


def main():
    dry_run = "--dry-run" in sys.argv
    files = sorted(BASE.glob("**/*.yaml"))
    changed = 0
    total = 0
    for path in files:
        if dry_run:
            text = path.read_text(encoding="utf-8")
            lines = text.split("\n")
            ranges = find_block_ranges(lines)
            n_subs = 0
            for start, end in ranges:
                block_text = "\n".join(lines[start:end])
                n_subs += len(PAIR_RE.findall(block_text))
            if n_subs:
                changed += 1
                total += n_subs
                print(f"  ~ {path.relative_to(BASE)}: {n_subs} pair(s)")
        else:
            n = process_file(path)
            if n:
                changed += 1
                total += n
                print(f"  ~ {path.relative_to(BASE)}: {n} pair(s)")

    print(f"\n{changed} file(s) {'would be ' if dry_run else ''}modified, {total} pair(s) total.")


if __name__ == "__main__":
    main()
