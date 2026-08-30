#!/usr/bin/env python3
"""
Validate all YAML files under ./assets (recursively).

Checks performed for every .yaml file:
  1. The file parses as valid YAML.
  2. No mapping in the file contains a duplicate key (at any nesting level).
  3. No line contains a tab character (YAML indentation must use spaces).
  4. Every hymn ('hymn' / 'marialHymns'), psalm ('psalm'), common ('commons')
     and preface ('prefaceList') code points to an existing file under
     assets/hymns, assets/psalms, assets/calendar_data/commons or
     assets/mass_missal/prefaces.

Usage:
  python scripts/validate_yaml.py
"""

import sys
from pathlib import Path

import yaml

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
HYMNS_DIR = ASSETS_DIR / "hymns"
PSALMS_DIR = ASSETS_DIR / "psalms"
COMMONS_DIR = ASSETS_DIR / "calendar_data" / "commons"
PREFACES_DIR = ASSETS_DIR / "mass_missal" / "prefaces"

# YAML key -> kind of code it holds
REFERENCE_KEYS = {
    "commons": "commons",
    "hymn": "hymn",
    "marialHymns": "hymn",
    "psalm": "psalm",
    "prefaceList": "preface",
}


class DuplicateKeyError(Exception):
    def __init__(self, key, line):
        self.key = key
        self.line = line
        super().__init__(f"duplicate key '{key}' at line {line}")


class DuplicateKeyLoader(yaml.SafeLoader):
    """SafeLoader that raises DuplicateKeyError on duplicate mapping keys."""

    def construct_mapping(self, node, deep=False):
        seen = set()
        for key_node, _ in node.value:
            key = self.construct_object(key_node, deep=deep)
            if key in seen:
                raise DuplicateKeyError(key, key_node.start_mark.line + 1)
            seen.add(key)
        return super().construct_mapping(node, deep=deep)


def find_yaml_files(root: Path):
    return sorted(root.rglob("*.yaml"))


def find_tabs(text: str):
    """Return a list of (line, column) 1-indexed positions of tab characters."""
    positions = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        for col, char in enumerate(line, start=1):
            if char == "\t":
                positions.append((lineno, col))
    return positions


def reference_exists(kind: str, code: str) -> bool:
    if kind == "commons":
        return (COMMONS_DIR / f"{code}.yaml").is_file()
    if kind == "hymn":
        return (HYMNS_DIR / f"{code}.yaml").is_file()
    if kind == "psalm":
        return (PSALMS_DIR / f"{code}.yaml").is_file() or (
            PSALMS_DIR / "hebrew-greek" / f"{code}.yaml"
        ).is_file()
    if kind == "preface":
        return (PREFACES_DIR / f"{code}.yaml").is_file()
    return True


def _scalar_values(node):
    """Collect (value, line) pairs from a scalar node or a sequence of scalars."""
    if isinstance(node, yaml.ScalarNode):
        if node.tag == "tag:yaml.org,2002:null" or node.value == "":
            return []
        return [(node.value, node.start_mark.line + 1)]
    if isinstance(node, yaml.SequenceNode):
        values = []
        for item in node.value:
            values.extend(_scalar_values(item))
        return values
    return []


def collect_references(node, refs):
    """Walk a composed YAML node tree, collecting (kind, code, line) for every
    'commons' / 'hymn' / 'marialHymns' / 'psalm' key found at any depth."""
    if isinstance(node, yaml.MappingNode):
        for key_node, value_node in node.value:
            if isinstance(key_node, yaml.ScalarNode) and key_node.value in REFERENCE_KEYS:
                kind = REFERENCE_KEYS[key_node.value]
                for code, line in _scalar_values(value_node):
                    refs.append((kind, code, line))
            collect_references(value_node, refs)
    elif isinstance(node, yaml.SequenceNode):
        for item in node.value:
            collect_references(item, refs)


def check_file(path: Path):
    """Return a list of issue dicts for this file (empty list if the file is valid)."""
    issues = []
    text = path.read_text(encoding="utf-8")

    for lineno, col in find_tabs(text):
        issues.append({"type": "tab_character", "line": lineno, "column": col})

    loader = DuplicateKeyLoader(text)
    try:
        loader.get_single_data()
    except DuplicateKeyError as e:
        issues.append({"type": "duplicate_key", "line": e.line, "key": e.key})
    except yaml.YAMLError as e:
        mark = getattr(e, "problem_mark", None)
        line = mark.line + 1 if mark else None
        issues.append({"type": "syntax_error", "line": line, "message": str(e)})
    else:
        refs = []
        collect_references(yaml.compose(text, Loader=yaml.SafeLoader), refs)
        for kind, code, line in refs:
            if not reference_exists(kind, code):
                issues.append({"type": "broken_reference", "line": line, "kind": kind, "code": code})
    finally:
        loader.dispose()

    return issues


def format_issue(issue: dict) -> str:
    if issue["type"] == "duplicate_key":
        return f"line {issue['line']}, duplicate key '{issue['key']}'"
    if issue["type"] == "syntax_error":
        return f"line {issue['line']}, syntax error: {issue['message']}"
    if issue["type"] == "tab_character":
        return f"line {issue['line']}, column {issue['column']}, tab character found (use spaces for indentation)"
    if issue["type"] == "broken_reference":
        return f"line {issue['line']}, {issue['kind']} code '{issue['code']}' has no matching file"
    return str(issue)


def main():
    if not ASSETS_DIR.is_dir():
        print(f"Error: {ASSETS_DIR} is not a directory", file=sys.stderr)
        return 1

    files = find_yaml_files(ASSETS_DIR)
    failures = []
    ok_count = 0

    for path in files:
        rel_path = path.relative_to(ASSETS_DIR.parent)
        print(f"Checking: {rel_path}")
        issues = check_file(path)
        if not issues:
            print("  OK")
            ok_count += 1
        else:
            failures.append((rel_path, issues))
            for issue in issues:
                print(f"  FAILED: {format_issue(issue)}")

    print()
    print("=" * 60)
    print(f"Summary: {ok_count}/{len(files)} files OK")
    if failures:
        print(f"{len(failures)} file(s) with problems:")
        for rel_path, issues in failures:
            for issue in issues:
                print(f"  - {rel_path}: {format_issue(issue)}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
