#!/usr/bin/env python3
"""
Move oration fields from sub-keys to root level in ferial_days YAML files.

Rules:
- If oration already at root level: skip
- If no oration anywhere: skip
- If 1 oration in a sub-key: move to root after invitatory, remove from sub-key
- If N identical orations: move 1 to root, remove all from sub-keys
- If N different orations: log and skip (don't modify)

Usage:
  python3 scripts/move_orations.py --dry-run   # preview changes
  python3 scripts/move_orations.py              # apply changes
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

SUB_KEYS = ["firstVespers", "morning", "readings", "middleOfDay", "vespers"]


def is_root_key(line):
    """Check if a line is a root-level YAML key (no leading whitespace)."""
    return line and not line[0].isspace() and ":" in line and not line.startswith("#")


def find_oration_blocks(lines):
    """Find all oration blocks in the file.

    Returns:
      root_oration: True if oration exists at root level
      sub_orations: list of (start_line, end_line, oration_text, parent_key)
    """
    root_oration = False
    sub_orations = []
    current_parent = None

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.rstrip("\n")

        # Track current root-level parent key
        if is_root_key(stripped):
            key = stripped.split(":")[0].strip()
            if key in SUB_KEYS:
                current_parent = key
            elif key == "oration":
                root_oration = True
                current_parent = None
            else:
                current_parent = key

        # Check for sub-key oration (exactly 2 spaces indentation)
        if stripped == "  oration:" and current_parent in SUB_KEYS:
            block_start = i
            oration_text = ""

            # Read the oration value (next line(s) with deeper indentation)
            j = i + 1
            while j < len(lines):
                next_line = lines[j].rstrip("\n")
                if next_line == "" or (next_line.strip() and len(next_line) - len(next_line.lstrip()) <= 2):
                    break
                if next_line.strip().startswith("- "):
                    # Extract text after "- "
                    oration_text = next_line.strip()[2:]
                else:
                    # Continuation line
                    oration_text += " " + next_line.strip()
                j += 1

            # Include trailing blank line in the block
            block_end = j
            if block_end < len(lines) and lines[block_end].strip() == "":
                block_end += 1

            sub_orations.append((block_start, block_end, oration_text, current_parent))
            i = j
            continue

        i += 1

    return root_oration, sub_orations


def find_invitatory_end(lines):
    """Find the line index right after the invitatory block (including trailing blank line)."""
    in_invitatory = False

    for i, line in enumerate(lines):
        stripped = line.rstrip("\n")
        if stripped == "invitatory:":
            in_invitatory = True
            continue
        if in_invitatory and is_root_key(stripped):
            return i

    return None


def build_oration_block(oration_text):
    """Build the root-level oration block lines."""
    # Handle text that may contain quotes
    needs_quotes = oration_text.startswith('"') and oration_text.endswith('"')
    if needs_quotes:
        text = oration_text
    else:
        text = oration_text

    return [
        "oration:\n",
        f"    - {text}\n",
        "\n",
    ]


def process_file(filepath, dry_run=False):
    """Process a single YAML file. Returns a status string."""
    filename = os.path.basename(filepath)

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    root_oration, sub_orations = find_oration_blocks(lines)

    # Skip if oration already at root
    if root_oration:
        return f"SKIP (root oration exists): {filename}"

    # Skip if no oration found anywhere
    if not sub_orations:
        return f"SKIP (no oration): {filename}"

    # Extract oration texts
    texts = [o[2] for o in sub_orations]
    parents = [o[3] for o in sub_orations]
    unique_texts = set(texts)

    # Multiple different orations: log and skip
    if len(unique_texts) > 1:
        sections = ", ".join(parents)
        return f"CONFLICT (different orations in {sections}): {filename}"

    # Find insertion point (after invitatory)
    insert_pos = find_invitatory_end(lines)
    if insert_pos is None:
        return f"ERROR (no invitatory found): {filename}"

    # Build new file content
    # First, remove all sub-oration blocks (process from end to start to preserve indices)
    new_lines = list(lines)
    for start, end, _, _ in reversed(sub_orations):
        del new_lines[start:end]

    # Recalculate insertion point after deletions above it
    # Count how many lines were removed before insert_pos
    removed_before = 0
    for start, end, _, _ in sub_orations:
        if start < insert_pos:
            removed_count = end - start
            if end <= insert_pos:
                removed_before += removed_count
            else:
                removed_before += insert_pos - start

    adjusted_insert = insert_pos - removed_before

    # Insert oration block at root level after invitatory
    oration_block = build_oration_block(texts[0])
    for j, oration_line in enumerate(oration_block):
        new_lines.insert(adjusted_insert + j, oration_line)

    if not dry_run:
        with open(filepath, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    count = len(sub_orations)
    if count == 1:
        return f"MOVED (from {parents[0]}): {filename}"
    else:
        sections = ", ".join(parents)
        return f"MERGED ({count} identical from {sections}): {filename}"


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("=== DRY RUN MODE (no files will be modified) ===\n")
    else:
        print("=== APPLYING CHANGES ===\n")

    yaml_files = sorted(glob.glob(os.path.join(YAML_DIR, "*.yaml")))
    print(f"Found {len(yaml_files)} YAML files\n")

    results = {"moved": [], "merged": [], "skip_root": [], "skip_none": [], "conflict": [], "error": []}

    for filepath in yaml_files:
        status = process_file(filepath, dry_run)
        print(status)

        if status.startswith("MOVED"):
            results["moved"].append(status)
        elif status.startswith("MERGED"):
            results["merged"].append(status)
        elif "root oration" in status:
            results["skip_root"].append(status)
        elif "no oration" in status:
            results["skip_none"].append(status)
        elif status.startswith("CONFLICT"):
            results["conflict"].append(status)
        else:
            results["error"].append(status)

    print("\n=== SUMMARY ===")
    print(f"Moved (1 oration):       {len(results['moved'])}")
    print(f"Merged (N identical):    {len(results['merged'])}")
    print(f"Skipped (root exists):   {len(results['skip_root'])}")
    print(f"Skipped (no oration):    {len(results['skip_none'])}")
    print(f"Conflict (different):    {len(results['conflict'])}")
    print(f"Errors:                  {len(results['error'])}")

    if results["conflict"]:
        print("\n=== FILES WITH CONFLICTING ORATIONS ===")
        for c in results["conflict"]:
            print(f"  {c}")


if __name__ == "__main__":
    main()
