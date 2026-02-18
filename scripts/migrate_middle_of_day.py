#!/usr/bin/env python3
"""
Migration script: Extract middle-of-day office data from liturgie-plus HTML files
and insert into offline-liturgy YAML files.

Sources (liturgie-plus/www/milieu/):
  - antiennes/antienne_N_x_y_z.html  → psalmody antiphons
  - capitules/capituleN_x_y_z.html   → reading (biblicalReference + content)
  - repons/reponsN_x_y_z.html        → responsory
  - oraisons/oraisonN_x_y_z.html     → oration

Target: offline-liturgy/assets/calendar_data/ferial_days/{prefix}_{week}_{day}.yaml

N mapping: 1=advent, 2=christmas, 3=ot, 4=lent, 5=easter
Office z: 1=tierce, 2=sexte, 3=none
"""

import os
import re
import html
import glob as globmod
from pathlib import Path

# Paths
LITURGIE_PLUS_DIR = Path("/Users/franzoom/development/liturgie-plus/www/milieu")
FERIAL_DAYS_DIR = Path(
    "/Users/franzoom/development/offline-liturgy/assets/calendar_data/ferial_days"
)

SEASON_MAP = {
    "1": "advent",
    "2": "christmas",
    "3": "ot",
    "4": "lent",
    "5": "easter",
}

OFFICE_MAP = {
    "1": "tierce",
    "2": "sexte",
    "3": "none",
}


def clean_html(text):
    """Remove HTML tags and decode entities."""
    text = html.unescape(text)
    text = re.sub(r"<[^>]+>", "", text)
    return text.strip()


def parse_antienne(filepath):
    """Parse an antienne HTML file.
    Returns either:
      - a string (single antiphon for all psalms/offices)
      - a dict {'tierce': text, 'sexte': text, 'none': text} for per-office antiphons (Easter)
    """
    with open(filepath, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        return None

    # Check for per-office antiphons (Easter format with m_office_1, m_office_2, m_office_3)
    office_matches = re.findall(
        r'<p class="antienne m_office_(\d+)">(.*?)</p>', raw, re.DOTALL
    )
    if office_matches:
        per_office = {}
        for office_num, ant_html in office_matches:
            office_name = OFFICE_MAP.get(office_num)
            if office_name:
                text = clean_html(ant_html)
                text = re.sub(r"^Ant\.\s*", "", text)
                text = " ".join(text.split())  # single line, collapse spaces
                if text.strip():
                    per_office[office_name] = text.strip()
        return per_office if per_office else None

    # Standard format: single antiphon
    text = clean_html(raw)
    text = re.sub(r"^Ant\.\s*", "", text)
    text = " ".join(text.split())  # single line, collapse spaces
    return text.strip() if text.strip() else None


def parse_capitule(filepath):
    """Parse a capitule HTML file, return (biblicalReference, content)."""
    with open(filepath, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        return None, None

    # Extract biblical reference from first <p class="ref"> line
    ref_match = re.search(r'<p class="ref">\((.+?)\)</p>', raw, re.DOTALL)
    if not ref_match:
        return None, None
    ref = html.unescape(ref_match.group(1)).strip()

    # Extract content from subsequent <p> tag(s)
    # Remove the ref line first
    content_part = re.sub(r'<p class="ref">.*?</p>', "", raw, flags=re.DOTALL).strip()
    # Clean HTML tags
    content = clean_html(content_part)
    # Join lines into single line, collapse multiple spaces
    content = " ".join(content.split())
    return ref, content if content else None


def parse_repons(filepath):
    """Parse a repons HTML file, return cleaned responsory text."""
    with open(filepath, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        return None

    # Replace <br> and <br/> with newline markers
    text = re.sub(r"<br\s*/?>", "\n", raw)
    # Remove span tags but keep content
    text = re.sub(r'<span class="symbole-verset"></span>', "", text)
    text = re.sub(r'<span class="espace"></span>', "", text)
    # Remove remaining HTML tags
    text = re.sub(r"<[^>]+>", "", text)
    # Decode HTML entities
    text = html.unescape(text)
    # Add V/ prefix
    lines = [line.strip() for line in text.strip().split("\n")]
    lines = [line for line in lines if line]  # Remove empty lines
    if lines:
        lines[0] = "V/ " + lines[0]
    result = "\n".join(lines)
    return result if result.strip() else None


def parse_oraison(filepath):
    """Parse an oraison HTML file, return cleaned oration text."""
    with open(filepath, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        return None
    text = clean_html(raw)
    # Join lines, collapse spaces
    text = " ".join(text.split())
    return text if text else None


def yaml_escape_inline(text):
    """Escape a string for inline YAML if it contains special characters."""
    if not text:
        return '""'
    # If contains colon followed by space, or starts with special chars, quote it
    needs_quoting = any(
        c in text for c in [":", "#", "{", "}", "[", "]", ",", "&", "*", "?", "|", ">"]
    )
    if needs_quoting or text.startswith(("'", '"', " ", "-")):
        # Use double quotes with escaped inner quotes
        escaped = text.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    return text


def format_block_scalar(text, indent):
    """Format text as a YAML block scalar (|-) with proper indentation."""
    lines = text.split("\n")
    prefix = " " * indent
    return "|-\n" + "\n".join(prefix + line for line in lines)


def needs_block_scalar(text):
    """Check if text needs block scalar formatting (multiline or contains colons)."""
    return "\n" in text or ":" in text


# ─── Collect data per YAML file ─────────────────────────────────────────

# Structure: data[yaml_key] = {
#   'antiennes': {psalm_index: text, ...} or {0: text},  # 0 = all same
#   'tierce': {'reading_ref': ..., 'reading_content': ..., 'responsory': ..., 'oration': ...},
#   'sexte': {...},
#   'none': {...},
# }
data = {}


def get_yaml_key(season_n, week, day):
    """Build the yaml key like 'advent_1_0'."""
    prefix = SEASON_MAP.get(season_n)
    if not prefix:
        return None
    return f"{prefix}_{week}_{day}"


def ensure_entry(yaml_key):
    if yaml_key not in data:
        data[yaml_key] = {
            "antiennes": {},
            "tierce": {},
            "sexte": {},
            "none": {},
        }


# ─── Parse antiennes ────────────────────────────────────────────────────
print("Parsing antiennes...")
antienne_dir = LITURGIE_PLUS_DIR / "antiennes"
for fpath in sorted(antienne_dir.glob("antienne_*.html")):
    fname = fpath.stem  # antienne_N_x_y_z
    parts = fname.split("_")
    # antienne _ N _ x _ y _ z → parts = ['antienne', N, x, y, z]
    if len(parts) != 5:
        print(f"  SKIP (unexpected format): {fname}")
        continue
    _, season_n, week, day, psalm_z = parts
    yaml_key = get_yaml_key(season_n, week, day)
    if not yaml_key:
        print(f"  SKIP (unknown season {season_n}): {fname}")
        continue
    result = parse_antienne(fpath)
    if result:
        ensure_entry(yaml_key)
        if isinstance(result, dict):
            # Per-office antiphons (Easter): store in office antiphon fields
            for office_name, ant_text in result.items():
                data[yaml_key][office_name]["antiphon"] = ant_text
        else:
            # Standard: store in psalmody antiennes
            data[yaml_key]["antiennes"][int(psalm_z)] = result

# ─── Parse capitules ────────────────────────────────────────────────────
# Format: capituleZ_N_x_y where Z=office (1=tierce, 2=sexte, 3=none), N=season, x=week, y=day
print("Parsing capitules...")
capitule_dir = LITURGIE_PLUS_DIR / "capitules"
for fpath in sorted(capitule_dir.glob("capitule*.html")):
    fname = fpath.stem
    m = re.match(r"^capitule(\d+)_(\d+)_(\d+)_(\d+)$", fname)
    if not m:
        print(f"  SKIP (unexpected format): {fname}")
        continue
    office_z, season_n, week, day = m.groups()
    offices = [OFFICE_MAP[office_z]] if office_z in OFFICE_MAP else (
        list(OFFICE_MAP.values()) if office_z == "0" else []
    )
    if not offices:
        continue
    yaml_key = get_yaml_key(season_n, week, day)
    if not yaml_key:
        print(f"  SKIP (unknown season {season_n}): {fname}")
        continue
    ref, content = parse_capitule(fpath)
    if ref and content:
        ensure_entry(yaml_key)
        for office_name in offices:
            if office_z == "0" and data[yaml_key][office_name].get("reading_ref"):
                continue
            data[yaml_key][office_name]["reading_ref"] = ref
            data[yaml_key][office_name]["reading_content"] = content

# ─── Parse repons ───────────────────────────────────────────────────────
# Format: reponsZ_N_x_y where Z=office (1=tierce, 2=sexte, 3=none), N=season, x=week, y=day
print("Parsing repons...")
repons_dir = LITURGIE_PLUS_DIR / "repons"
for fpath in sorted(repons_dir.glob("repons*.html")):
    fname = fpath.stem
    m = re.match(r"^repons(\d+)_(\d+)_(\d+)_(\d+)$", fname)
    if not m:
        print(f"  SKIP (unexpected format): {fname}")
        continue
    office_z, season_n, week, day = m.groups()
    offices = [OFFICE_MAP[office_z]] if office_z in OFFICE_MAP else (
        list(OFFICE_MAP.values()) if office_z == "0" else []
    )
    if not offices:
        continue
    yaml_key = get_yaml_key(season_n, week, day)
    if not yaml_key:
        print(f"  SKIP (unknown season {season_n}): {fname}")
        continue
    text = parse_repons(fpath)
    if text:
        ensure_entry(yaml_key)
        for office_name in offices:
            if office_z == "0" and data[yaml_key][office_name].get("responsory"):
                continue
            data[yaml_key][office_name]["responsory"] = text

# ─── Parse oraisons ─────────────────────────────────────────────────────
# Format: oraisonZ_N_x_y where Z=office, N=season, x=week, y=day
# ONLY oraisonZ files (digit right after 'oraison'), NOT oraison_x_y_z
print("Parsing oraisons...")
oraison_dir = LITURGIE_PLUS_DIR / "oraisons"
for fpath in sorted(oraison_dir.glob("oraison*.html")):
    fname = fpath.stem
    m = re.match(r"^oraison(\d+)_(\d+)_(\d+)_(\d+)$", fname)
    if not m:
        continue
    office_z, season_n, week, day = m.groups()
    offices = [OFFICE_MAP[office_z]] if office_z in OFFICE_MAP else (
        list(OFFICE_MAP.values()) if office_z == "0" else []
    )
    if not offices:
        continue
    yaml_key = get_yaml_key(season_n, week, day)
    if not yaml_key:
        print(f"  SKIP (unknown season {season_n}): {fname}")
        continue
    text = parse_oraison(fpath)
    if text:
        ensure_entry(yaml_key)
        for office_name in offices:
            if office_z == "0" and data[yaml_key][office_name].get("oration"):
                continue
            data[yaml_key][office_name]["oration"] = text


# ─── Insert data into YAML files ────────────────────────────────────────

def find_section_range(lines, section_name):
    """Find the start line and end line (exclusive) of a top-level YAML section."""
    start = None
    for i, line in enumerate(lines):
        if line.rstrip() == f"{section_name}:" or line.startswith(f"{section_name}:"):
            start = i
            break
    if start is None:
        return None, None
    # Find end: next top-level key (no indentation) or end of file
    end = len(lines)
    for i in range(start + 1, len(lines)):
        stripped = lines[i]
        if stripped and not stripped[0].isspace() and not stripped.startswith("#"):
            end = i
            break
    return start, end


def find_insertion_point_after_psalmody(lines, mod_start, mod_end):
    """Find where to insert tierce/sexte/none data after the psalmody sub-section."""
    # Look for the end of the psalmody sub-section within middleOfDay
    in_psalmody = False
    last_psalmody_line = mod_start
    for i in range(mod_start + 1, mod_end):
        stripped = lines[i].strip()
        if not stripped:
            continue
        indent = len(lines[i]) - len(lines[i].lstrip())
        if stripped.startswith("psalmody:"):
            in_psalmody = True
            last_psalmody_line = i
        elif in_psalmody:
            if indent <= 2 and not stripped.startswith("-") and not stripped.startswith("psalm:") and not stripped.startswith("antiphon:"):
                # We've exited psalmody, this is the insertion point
                return i
            last_psalmody_line = i
    return mod_end


def build_office_yaml(office_name, office_data, indent=2):
    """Build YAML text for a single office (tierce/sexte/none)."""
    prefix = " " * indent
    inner = " " * (indent + 2)
    lines = [f"{prefix}{office_name}:"]

    if "antiphon" in office_data:
        lines.append(f"{inner}antiphon: {yaml_escape_inline(office_data['antiphon'])}")

    if "reading_ref" in office_data:
        lines.append(f"{inner}reading:")
        ref = office_data["reading_ref"]
        lines.append(f"{inner}  biblicalReference: {ref}")
        content = office_data["reading_content"]
        if needs_block_scalar(content):
            lines.append(f"{inner}  content: {format_block_scalar(content, indent + 6)}")
        else:
            lines.append(f"{inner}  content: {yaml_escape_inline(content)}")

    if "responsory" in office_data:
        resp = office_data["responsory"]
        lines.append(f"{inner}responsory: {format_block_scalar(resp, indent + 4)}")

    if "oration" in office_data:
        oration = office_data["oration"]
        if needs_block_scalar(oration):
            lines.append(f"{inner}oration: {format_block_scalar(oration, indent + 4)}")
        else:
            lines.append(f"{inner}oration: {yaml_escape_inline(oration)}")

    return lines


def update_antiphons_in_psalmody(lines, mod_start, mod_end, antiennes):
    """Update antiphons in the existing psalmody section. Returns modified lines."""
    if not antiennes:
        return lines

    # If z=0, all psalms get the same antiphon
    all_same = 0 in antiennes
    if all_same:
        antiphon_text = antiennes[0]

    # Find psalm entries in the psalmody section
    psalm_index = 0
    i = mod_start
    new_lines = list(lines)
    offset = 0

    while i < mod_end + offset:
        stripped = new_lines[i].strip()
        if stripped.startswith("- psalm:"):
            psalm_index += 1
            # Check if next line(s) already have antiphon
            has_antiphon = False
            j = i + 1
            while j < mod_end + offset and new_lines[j].strip().startswith(("antiphon:", "-")):
                if new_lines[j].strip().startswith("antiphon:"):
                    has_antiphon = True
                    break
                if not new_lines[j].strip().startswith("-"):
                    break
                j += 1

            # Determine which antiphon to use
            ant_text = None
            if all_same:
                ant_text = antiphon_text
            elif psalm_index in antiennes:
                ant_text = antiennes[psalm_index]

            if ant_text and not has_antiphon:
                # Determine indentation from the psalm line
                indent = len(new_lines[i]) - len(new_lines[i].lstrip())
                ant_indent = " " * (indent + 2)
                ant_lines = [
                    f"{ant_indent}antiphon:",
                    f"{ant_indent}  - {yaml_escape_inline(ant_text)}",
                ]
                # Insert after the psalm line
                for k, ant_line in enumerate(ant_lines):
                    new_lines.insert(i + 1 + k, ant_line)
                offset += len(ant_lines)
                mod_end_adj = mod_end + len(ant_lines)
                i += len(ant_lines)
        i += 1

    return new_lines


print("\nInserting data into YAML files...")
stats = {"updated": 0, "skipped_no_file": 0, "skipped_no_data": 0, "created_mod": 0}

for yaml_key, entry in sorted(data.items()):
    yaml_file = FERIAL_DAYS_DIR / f"{yaml_key}.yaml"
    if not yaml_file.exists():
        stats["skipped_no_file"] += 1
        print(f"  SKIP (no YAML file): {yaml_key}")
        continue

    # Check if there's any office data to add
    has_office_data = any(
        entry[office] for office in ["tierce", "sexte", "none"]
    )
    has_antienne_data = bool(entry["antiennes"])

    if not has_office_data and not has_antienne_data:
        stats["skipped_no_data"] += 1
        continue

    with open(yaml_file, "r", encoding="utf-8") as f:
        content = f.read()
    lines = content.split("\n")

    mod_start, mod_end = find_section_range(lines, "middleOfDay")

    if mod_start is None:
        # No middleOfDay section exists - we need to create it
        # Find a good insertion point (before vespers or at end)
        vesp_start, _ = find_section_range(lines, "vespers")
        if vesp_start is not None:
            insert_at = vesp_start
        else:
            insert_at = len(lines)

        # Build the middleOfDay section
        new_section_lines = ["middleOfDay:"]

        # Add office data
        for office_name in ["tierce", "sexte", "none"]:
            if entry[office_name]:
                new_section_lines.extend(
                    build_office_yaml(office_name, entry[office_name])
                )

        new_section_lines.append("")  # blank line after section

        for k, line in enumerate(new_section_lines):
            lines.insert(insert_at + k, line)

        stats["created_mod"] += 1
    else:
        # middleOfDay section exists
        # First, update antiphons if we have them
        if has_antienne_data:
            lines = update_antiphons_in_psalmody(
                lines, mod_start, mod_end, entry["antiennes"]
            )
            # Recalculate section range after possible modifications
            mod_start, mod_end = find_section_range(lines, "middleOfDay")

        # Check if tierce/sexte/none already exist
        existing_offices = set()
        for i in range(mod_start, mod_end):
            stripped = lines[i].strip()
            for oname in ["tierce", "sexte", "none"]:
                if stripped == f"{oname}:":
                    existing_offices.add(oname)

        # Find insertion point (after psalmody, before next section)
        insert_at = find_insertion_point_after_psalmody(lines, mod_start, mod_end)

        # Insert office data
        new_lines = []
        for office_name in ["tierce", "sexte", "none"]:
            if entry[office_name] and office_name not in existing_offices:
                new_lines.extend(build_office_yaml(office_name, entry[office_name]))

        if new_lines:
            for k, line in enumerate(new_lines):
                lines.insert(insert_at + k, line)

    # Write back
    with open(yaml_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    stats["updated"] += 1

print(f"\nDone!")
print(f"  Updated: {stats['updated']}")
print(f"  Created middleOfDay: {stats['created_mod']}")
print(f"  Skipped (no YAML): {stats['skipped_no_file']}")
print(f"  Skipped (no data): {stats['skipped_no_data']}")
print(f"  Total entries processed: {len(data)}")
