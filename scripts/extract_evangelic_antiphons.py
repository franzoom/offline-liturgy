#!/usr/bin/env python3
"""
Extract yearA/B/C from evangelicAntiphon sub-keys to root level in ot_*_0.yaml files.

Rules:
- Only process ot_*_0.yaml files
- Look for evangelicAntiphon in firstVespers, morning, vespers
- Compare yearA/B/C across all offices that have them
- If identical: create root-level evangelicAntiphon with yearA/B/C (after oration)
  - In sub-sections: replace evangelicAntiphon block with just the common value
  - If no common value: remove evangelicAntiphon (and empty parent section)
- If different: log and skip

Usage:
  python3 scripts/extract_evangelic_antiphons.py --dry-run
  python3 scripts/extract_evangelic_antiphons.py
"""

import glob
import os
import re
import sys


YAML_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets",
    "calendar_data",
    "ferial_days",
)

OFFICE_KEYS = ["firstVespers", "morning", "vespers"]


def is_root_key(line):
    """Check if a line is a root-level YAML key."""
    stripped = line.rstrip("\n")
    return stripped and not stripped[0].isspace() and ":" in stripped and not stripped.startswith("#")


def get_indent(line):
    """Return the number of leading spaces."""
    return len(line) - len(line.lstrip(" "))


def find_evangelic_blocks(lines):
    """Find all evangelicAntiphon blocks inside office sub-sections.

    Returns list of dicts with:
      - parent: the office key (firstVespers, morning, vespers)
      - start: start line index of the evangelicAntiphon block
      - end: end line index (exclusive)
      - common: value of common key (or None)
      - yearA, yearB, yearC: values
      - common_line_raw: the raw line for common (to preserve formatting)
      - year_lines_raw: list of raw lines for yearA/B/C
    """
    blocks = []
    current_parent = None
    i = 0

    while i < len(lines):
        stripped = lines[i].rstrip("\n")

        # Track root-level parent key
        if is_root_key(stripped):
            key = stripped.split(":")[0].strip()
            if key in OFFICE_KEYS:
                current_parent = key
            else:
                current_parent = None

        # Find evangelicAntiphon at 2 spaces indentation (sub-key of an office)
        if stripped == "  evangelicAntiphon:" and current_parent in OFFICE_KEYS:
            block_start = i
            common_val = None
            year_a = None
            year_b = None
            year_c = None
            common_line_raw = None
            year_lines_raw = []

            j = i + 1
            while j < len(lines):
                next_stripped = lines[j].rstrip("\n")
                indent = get_indent(next_stripped)
                # Still inside the block if indented > 2 spaces, or empty line
                if next_stripped == "":
                    j += 1
                    break
                if indent <= 2 and next_stripped.strip():
                    break
                # Parse sub-keys at 4 spaces
                if indent == 4:
                    if next_stripped.strip().startswith("common:"):
                        common_val = next_stripped.strip()[len("common:"):].strip()
                        common_line_raw = lines[j]
                    elif next_stripped.strip().startswith("yearA:"):
                        year_a = next_stripped.strip()[len("yearA:"):].strip()
                        year_lines_raw.append(lines[j])
                    elif next_stripped.strip().startswith("yearB:"):
                        year_b = next_stripped.strip()[len("yearB:"):].strip()
                        year_lines_raw.append(lines[j])
                    elif next_stripped.strip().startswith("yearC:"):
                        year_c = next_stripped.strip()[len("yearC:"):].strip()
                        year_lines_raw.append(lines[j])
                j += 1

            block_end = j

            blocks.append({
                "parent": current_parent,
                "start": block_start,
                "end": block_end,
                "common": common_val,
                "yearA": year_a,
                "yearB": year_b,
                "yearC": year_c,
                "year_lines_raw": year_lines_raw,
            })
            i = j
            continue

        # Handle simple evangelicAntiphon (value on same line, e.g. already transformed)
        if current_parent in OFFICE_KEYS and stripped.startswith("  evangelicAntiphon:") and stripped != "  evangelicAntiphon:":
            # Simple value, no sub-keys - skip
            i += 1
            continue

        i += 1

    return blocks


def find_oration_end(lines):
    """Find the line index right after the oration block at root level."""
    in_oration = False
    for i, line in enumerate(lines):
        stripped = line.rstrip("\n")
        if is_root_key(stripped) and stripped.startswith("oration:"):
            in_oration = True
            continue
        if in_oration and is_root_key(stripped):
            return i
    # If oration is last root key, return end
    if in_oration:
        return len(lines)
    return None


def is_section_empty_after_removal(lines, section_start, block_start, block_end):
    """Check if removing a block would leave the section header with no content."""
    # Look at lines between section_start+1 and the next root key
    j = section_start + 1
    while j < len(lines):
        stripped = lines[j].rstrip("\n")
        if is_root_key(stripped):
            break
        # Skip the block being removed
        if block_start <= j < block_end:
            j += 1
            continue
        # If there's any non-empty content line, section is not empty
        if stripped.strip():
            return False
        j += 1
    return True


def find_section_start(lines, block_start):
    """Find the root-level section header line for a given block."""
    for i in range(block_start - 1, -1, -1):
        if is_root_key(lines[i].rstrip("\n")):
            return i
    return None


def build_root_evangelic_block(year_lines_raw):
    """Build the root-level evangelicAntiphon block."""
    result = ["evangelicAntiphon:\n"]
    for raw_line in year_lines_raw:
        # Convert from 4-space indent (sub-sub-key) to 4-space indent (root sub-key)
        content = raw_line.strip()
        result.append(f"    {content}\n")
    result.append("\n")
    return result


def process_file(filepath, dry_run=False):
    """Process a single YAML file."""
    filename = os.path.basename(filepath)

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    blocks = find_evangelic_blocks(lines)

    if not blocks:
        return f"SKIP (no evangelicAntiphon with years): {filename}"

    # Check that all blocks have yearA/B/C
    blocks_with_years = [b for b in blocks if b["yearA"] and b["yearB"] and b["yearC"]]
    if not blocks_with_years:
        return f"SKIP (no yearA/B/C found): {filename}"

    # Compare yearA/B/C across all blocks
    ref = blocks_with_years[0]
    all_same = all(
        b["yearA"] == ref["yearA"] and b["yearB"] == ref["yearB"] and b["yearC"] == ref["yearC"]
        for b in blocks_with_years
    )

    if not all_same:
        parents = ", ".join(b["parent"] for b in blocks_with_years)
        return f"CONFLICT (different yearA/B/C in {parents}): {filename}"

    # Check if root evangelicAntiphon already exists
    for line in lines:
        stripped = line.rstrip("\n")
        if is_root_key(stripped) and stripped.startswith("evangelicAntiphon:"):
            return f"SKIP (root evangelicAntiphon exists): {filename}"

    # Find insertion point (after oration)
    insert_pos = find_oration_end(lines)
    if insert_pos is None:
        return f"ERROR (no oration found): {filename}"

    # Build new content
    new_lines = list(lines)

    # Process blocks from end to start to preserve indices
    sections_to_remove = []  # (section_start, next_root_start) for empty sections
    for block in reversed(blocks_with_years):
        start = block["start"]
        end = block["end"]

        if block["common"]:
            # Replace the block with simple evangelicAntiphon: common_value
            replacement = f"  evangelicAntiphon: {block['common']}\n"
            new_lines[start:end] = [replacement]
        else:
            # No common value - remove the evangelicAntiphon block
            section_start = find_section_start(new_lines, start)
            if section_start is not None and is_section_empty_after_removal(new_lines, section_start, start, end):
                # Remove the entire section (header + empty content + block)
                # Find the next root key after this section
                section_end = end
                for k in range(end, len(new_lines)):
                    stripped_k = new_lines[k].rstrip("\n")
                    if stripped_k.strip():
                        if is_root_key(stripped_k):
                            section_end = k
                        else:
                            section_end = end
                        break
                new_lines[section_start:section_end] = []
            else:
                # Just remove the evangelicAntiphon block
                new_lines[start:end] = []

    # Recalculate insertion point
    insert_pos_new = find_oration_end(new_lines)
    if insert_pos_new is None:
        return f"ERROR (lost oration after edits): {filename}"

    # Build and insert root-level block using the first block's year lines
    root_block = build_root_evangelic_block(ref["year_lines_raw"])
    for j, rl in enumerate(root_block):
        new_lines.insert(insert_pos_new + j, rl)

    if not dry_run:
        with open(filepath, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    parents = ", ".join(b["parent"] for b in blocks_with_years)
    has_common = any(b["common"] for b in blocks_with_years)
    return f"EXTRACTED (from {parents}, common={'yes' if has_common else 'no'}): {filename}"


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("=== DRY RUN MODE (no files will be modified) ===\n")
    else:
        print("=== APPLYING CHANGES ===\n")

    pattern = os.path.join(YAML_DIR, "ot_*_0.yaml")
    yaml_files = sorted(glob.glob(pattern))
    print(f"Found {len(yaml_files)} ot_*_0.yaml files\n")

    results = {"extracted": [], "skip": [], "conflict": [], "error": []}

    for filepath in yaml_files:
        status = process_file(filepath, dry_run)
        print(status)

        if status.startswith("EXTRACTED"):
            results["extracted"].append(status)
        elif status.startswith("SKIP"):
            results["skip"].append(status)
        elif status.startswith("CONFLICT"):
            results["conflict"].append(status)
        else:
            results["error"].append(status)

    print("\n=== SUMMARY ===")
    print(f"Extracted:    {len(results['extracted'])}")
    print(f"Skipped:      {len(results['skip'])}")
    print(f"Conflict:     {len(results['conflict'])}")
    print(f"Errors:       {len(results['error'])}")

    if results["conflict"]:
        print("\n=== FILES WITH CONFLICTING YEAR VALUES ===")
        for c in results["conflict"]:
            print(f"  {c}")


if __name__ == "__main__":
    main()
