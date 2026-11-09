#!/usr/bin/env python3
"""
Check the '%' quotation markers in the string values of all YAML files under
./assets (recursively). Three checks:

  1. Glued '%': a '%' with a non-space character on both sides.
     Not reported:
       - a '%' directly followed by ',' or '.';
       - a '%' preceded by '>' (indentation markup);
       - the '%%' marker (Passion dialogue markup);
       - a '%' opening a quotation right after an apostrophe, an opening
         bracket or an opening quote: qu’%il, (%bis%), “%…, [/rubric]%…;
       - a '%' closing a quotation right before a closing bracket or quote,
         or before markup: %), %], %”, %[rubric].
  2. Empty quotation: '% %' or '%  %' (spaces may be non-breaking).
  3. Odd number of '%' in a value.

Each finding starts with path:line[:column], clickable in the VS Code
terminal. The line is exact for '|' block scalars, approximate otherwise.

Usage:
  python scripts/find_unspaced_percent.py
"""

import re
import sys
from pathlib import Path

import yaml

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
CONTEXT = 25

# Characters allowed right before / right after a '%' (see the docstring).
ALLOWED_BEFORE = ">%’'(“«[]"
ALLOWED_AFTER = ",.%)]”»["

# A '%' with a non-space character on both sides, neither of them allowed.
GLUED_PATTERN = re.compile(
    rf"(?<=[^\s{re.escape(ALLOWED_BEFORE)}])%(?=[^\s{re.escape(ALLOWED_AFTER)}])"
)

# Two '%' separated by one or two spaces (regular or non-breaking).
EMPTY_PATTERN = re.compile("%[   ]{1,2}%")

STR_TAG = "tag:yaml.org,2002:str"


def string_scalars(node, path):
    """Yield (key_path, ScalarNode) for every string value in the YAML tree."""
    if isinstance(node, yaml.MappingNode):
        for key_node, value_node in node.value:
            key = key_node.value
            yield from string_scalars(value_node, f"{path}.{key}" if path else key)
    elif isinstance(node, yaml.SequenceNode):
        for index, value_node in enumerate(node.value):
            yield from string_scalars(value_node, f"{path}[{index}]")
    elif isinstance(node, yaml.ScalarNode) and node.tag == STR_TAG:
        yield path, node


def location(file, raw_lines, node, pos):
    """Return 'path:line[:column]' of character `pos` of the scalar's value."""
    relative = file.relative_to(ASSETS_DIR.parent)
    if node.style != "|":
        return f"{relative}:{node.start_mark.line + 1}"
    # Literal block: the content starts on the line after the '|' indicator,
    # and every '\n' of the value is a line break of the file.
    line_index = node.start_mark.line + 1 + node.value.count("\n", 0, pos)
    raw_line = raw_lines[line_index] if line_index < len(raw_lines) else ""
    indent = len(raw_line) - len(raw_line.lstrip(" "))
    column = indent + pos - (node.value.rfind("\n", 0, pos) + 1) + 1
    return f"{relative}:{line_index + 1}:{column}"


def excerpt(text, start, end):
    """Return the text around [start, end) on a single line."""
    snippet = text[max(0, start - CONTEXT) : min(len(text), end + CONTEXT)]
    return "…" + snippet.replace("\n", "⏎") + "…"


def main():
    glued = []
    empty = []
    odd = []
    for file in sorted(ASSETS_DIR.rglob("*.yaml")):
        raw = file.read_text(encoding="utf-8")
        try:
            root = yaml.compose(raw)
        except yaml.YAMLError as error:
            print(f"!! {file.relative_to(ASSETS_DIR.parent)}: YAML error: {error}")
            continue
        if root is None:
            continue
        raw_lines = raw.splitlines()
        scalars = list(string_scalars(root, ""))

        for key_path, node in scalars:
            for match in GLUED_PATTERN.finditer(node.value):
                where = location(file, raw_lines, node, match.start())
                glued.append(f"{where} | {key_path} | {excerpt(node.value, match.start(), match.end())}")

        for key_path, node in scalars:
            for match in EMPTY_PATTERN.finditer(node.value):
                where = location(file, raw_lines, node, match.start())
                empty.append(f"{where} | {key_path} | {excerpt(node.value, match.start(), match.end())}")

        for key_path, node in scalars:
            count = node.value.count("%")
            if count % 2:
                where = location(file, raw_lines, node, 0)
                odd.append(f"{where} | {key_path} | {count} '%'")

    for title, findings in (
        ("% collé entre deux caractères", glued),
        ("« % % » ou « %  % »", empty),
        ("Nombre impair de %", odd),
    ):
        print(f"=== {title} : {len(findings)} ===")
        for finding in findings:
            print(finding)
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
