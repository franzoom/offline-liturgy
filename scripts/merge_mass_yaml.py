#!/usr/bin/env python3
"""
Merge mass data from new/ferial_days into ferial_days.

For each pair of files with the same name:
  - Prepend the 'celebration' block (from source) at the top of the target.
    If target already has a 'celebration' key, sub-keys with non-null values
    in target are preserved; missing or null sub-keys are filled from source.
  - Append the 'mass' block (from source) at the bottom of the target.
"""

import re
import sys
import yaml
from pathlib import Path

SOURCE_BASE = Path("assets/mass_missal/new")
TARGET_BASE = Path("assets/calendar_data")

DIRS = ["ferial_days", "special_days"]


# ---------------------------------------------------------------------------
# Raw text block extraction
# ---------------------------------------------------------------------------

def split_source_blocks(text):
    """Return (celebration_raw, mass_raw) extracted from source text."""
    lines = text.splitlines(keepends=True)

    mass_start = None
    for i, line in enumerate(lines):
        if re.match(r"^mass:", line):
            mass_start = i
            break

    if mass_start is None:
        # No mass key found
        celeb = "".join(lines).rstrip("\n") or None
        return celeb, None

    celeb_part = "".join(lines[:mass_start]).rstrip("\n")
    mass_part = "".join(lines[mass_start:]).rstrip("\n")
    return (celeb_part or None), (mass_part or None)


# ---------------------------------------------------------------------------
# Celebration merging when target already has the key
# ---------------------------------------------------------------------------

def merge_celebration_dict(source: dict, target: dict) -> dict:
    """Merge source into target: keep target values when non-null."""
    result = dict(source)
    for key, value in target.items():
        if value is not None:
            result[key] = value
    return result


def celebration_to_yaml_block(celeb: dict) -> str:
    """Serialise a simple celebration dict as a YAML block string."""
    lines = ["celebration:"]
    for key, value in celeb.items():
        if value is None:
            lines.append(f"  {key}: null")
        else:
            lines.append(f"  {key}: {value}")
    return "\n".join(lines)


def remove_top_level_key_block(text: str, key: str) -> str:
    """Remove a top-level YAML key and its indented children from text."""
    lines = text.splitlines(keepends=True)
    result = []
    skip = False
    for line in lines:
        if re.match(rf"^{re.escape(key)}:", line):
            skip = True
            continue
        if skip and (line.startswith(" ") or line.startswith("\t") or line.strip() == ""):
            continue
        skip = False
        result.append(line)
    return "".join(result)


# ---------------------------------------------------------------------------
# Main processing
# ---------------------------------------------------------------------------

def process_dir(source_dir, target_dir):
    print(f"\n=== {source_dir} → {target_dir} ===")
    source_files = {p.name for p in source_dir.glob("*.yaml")}
    target_files = {p.name for p in target_dir.glob("*.yaml")}

    only_source = sorted(source_files - target_files)
    only_target = sorted(target_files - source_files)
    common = sorted(source_files & target_files)

    if only_source:
        print("[!] Files only in SOURCE (no matching target):")
        for f in only_source:
            print(f"    - {f}")

    if only_target:
        print("[!] Files only in TARGET (no matching source):")
        for f in only_target:
            print(f"    - {f}")

    print(f"Processing {len(common)} common files...")
    errors = []

    for filename in common:
        source_path = source_dir / filename
        target_path = target_dir / filename

        source_text = source_path.read_text(encoding="utf-8")
        target_text = target_path.read_text(encoding="utf-8")

        celeb_raw, mass_raw = split_source_blocks(source_text)

        # --- Handle celebration ---
        target_has_celebration = bool(re.search(r"^celebration:", target_text, re.MULTILINE))

        if target_has_celebration:
            # Parse only the celebration blocks (simple key-value, safe to parse)
            source_celeb = yaml.safe_load(celeb_raw).get("celebration") or {} if celeb_raw else {}
            target_celeb_raw = celeb_raw  # reuse variable name
            # Extract target celebration block as raw text to parse it alone
            target_celeb_lines = []
            for line in target_text.splitlines(keepends=True):
                if re.match(r"^celebration:", line):
                    target_celeb_lines.append(line)
                    continue
                if target_celeb_lines and (line.startswith(" ") or line.startswith("\t")):
                    target_celeb_lines.append(line)
                    continue
                if target_celeb_lines:
                    break
            target_celeb_block = "".join(target_celeb_lines)
            target_celeb = yaml.safe_load(target_celeb_block).get("celebration") or {} if target_celeb_block else {}
            merged = merge_celebration_dict(source_celeb, target_celeb)
            celeb_block = celebration_to_yaml_block(merged)
            # Remove old celebration block from target
            target_body = remove_top_level_key_block(target_text, "celebration").lstrip("\n")
            new_content = celeb_block + "\n" + target_body
        else:
            if celeb_raw:
                new_content = celeb_raw + "\n" + target_text
            else:
                new_content = target_text

        # --- Append mass ---
        if mass_raw:
            new_content = new_content.rstrip("\n") + "\n" + mass_raw + "\n"

        target_path.write_text(new_content, encoding="utf-8")
        print(f"  ✓  {filename}")

    if errors:
        print("[!] Errors encountered:")
        for e in errors:
            print(f"    {e}")
    else:
        print(f"Done. {len(common)} files updated.")


def process():
    for d in DIRS:
        source_dir = SOURCE_BASE / d
        target_dir = TARGET_BASE / d
        if not source_dir.exists():
            print(f"[!] Source not found: {source_dir}")
            continue
        if not target_dir.exists():
            print(f"[!] Target not found: {target_dir}")
            continue
        process_dir(source_dir, target_dir)


if __name__ == "__main__":
    process()
