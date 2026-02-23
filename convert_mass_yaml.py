#!/usr/bin/env python3
"""
Convert ferial_days YAML files to the new mass missal format (modele.yaml).
Creates converted files in assets/mass_missal/new/.

Key mappings:
  - book + ref  →  biblicalRef (space-joined)
  - title / context  →  celebration.title / .subtitle
  - id, commons  →  dropped
  - READING_1 / READING_2  →  READING
  - ALLELUIA.content  →  acclamationAntiphon of the following GOSPEL entry
  - toSundayCyclesOnly / toWeekdayCyclesOnly  →  sundayAndWeekCycles
  - PRAYER_AFTER_COMMUNION.note  →  dropped
  - PREFACE.prefaceId  →  prefaceList
  - massType  →  lowercased
"""

import sys
import yaml
from pathlib import Path


# --- YAML output helpers ---

def _literal_representer(dumper, data):
    """Output multiline strings as literal blocks (|-  or  |)."""
    if '\n' in data:
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)


yaml.add_representer(str, _literal_representer)


# --- Conversion helpers ---

def _merge_book_ref(book, ref):
    parts = [str(p) for p in (book, ref) if p is not None]
    return ' '.join(parts) if parts else None


def _get_cycles(content_item):
    return (
        content_item.get('toSundayCyclesOnly')
        or content_item.get('toWeekdayCyclesOnly')
    )


# --- Per-partType converters ---

def _convert_reading(c):
    result = {}
    bref = _merge_book_ref(c.get('book'), c.get('ref'))
    if bref:
        result['biblicalRef'] = bref
    cycles = _get_cycles(c)
    if cycles:
        result['sundayAndWeekCycles'] = cycles
    for key in ('headline', 'content', 'shortReadingRef', 'shortReadingContent'):
        if c.get(key) is not None:
            result[key] = c[key]
    return result


def _convert_psalm(c):
    result = {}
    bref = _merge_book_ref(c.get('book'), c.get('ref'))
    if bref:
        result['biblicalRef'] = bref
    if c.get('refAbbr') is not None:
        result['refAbbr'] = c['refAbbr']
    cycles = _get_cycles(c)
    if cycles:
        result['sundayAndWeekCycles'] = cycles
    if c.get('chorus') is not None:
        result['chorus'] = c['chorus']
    if c.get('content') is not None:
        result['content'] = c['content']
    return result


def _convert_gospel(c, alleluia_verse):
    result = {}
    bref = _merge_book_ref(c.get('book'), c.get('ref'))
    if bref:
        result['biblicalRef'] = bref
    cycles = _get_cycles(c)
    if cycles:
        result['sundayAndWeekCycles'] = cycles
    if c.get('headline') is not None:
        result['headline'] = c['headline']
    if alleluia_verse is not None:
        result['acclamationAntiphon'] = alleluia_verse
    if c.get('content') is not None:
        result['content'] = c['content']
    return result


def _convert_antiphon(c):
    result = {}
    bref = _merge_book_ref(c.get('book'), c.get('ref'))
    if bref:
        result['biblicalRef'] = bref
    if c.get('content') is not None:
        result['content'] = c['content']
    return result


# --- Alleluia verse lookup ---

def _build_alleluia_map(alleluia_parts):
    """
    Returns a dict: frozenset(cycles) | None  →  verse_text
    None key means the verse applies to all cycles.
    """
    mapping = {}
    for part in alleluia_parts:
        for c in part.get('partContents', []):
            verse = c.get('content')
            if verse is None:
                continue
            cycles = _get_cycles(c)
            key = frozenset(cycles) if cycles else None
            mapping[key] = verse
    return mapping


def _find_verse(alleluia_map, gospel_cycles):
    if not alleluia_map:
        return None
    # Universal entry (no cycle restriction) takes priority
    if None in alleluia_map:
        return alleluia_map[None]
    if gospel_cycles is None:
        return next(iter(alleluia_map.values()), None)
    gospel_set = frozenset(gospel_cycles)
    for key, verse in alleluia_map.items():
        if key and key & gospel_set:
            return verse
    return next(iter(alleluia_map.values()), None)


# --- Main conversion ---

def _convert_mass(liturgy, alleluia_map):
    mass_type = liturgy.get('massType')
    mass = {
        'massType': mass_type.lower() if mass_type else None,
        'name': liturgy.get('name'),
        'note': None,
    }

    entrance_antiphon = []
    collect = []
    reading_parts = []
    offering_prayer = []
    preface_list = []
    communion_antiphon = []
    prayer_after_communion = []

    for part in liturgy.get('massParts', []):
        part_type = part.get('partType', '')
        contents = part.get('partContents', []) or []

        if part_type == 'ENTRANCE_ANTIPHON':
            entrance_antiphon.extend(_convert_antiphon(c) for c in contents)

        elif part_type == 'COLLECT':
            collect.extend(c['content'] for c in contents if c.get('content') is not None)

        elif part_type in ('READING_1', 'READING_2'):
            reading_parts.append({
                'partType': 'READING',
                'partContents': [_convert_reading(c) for c in contents],
            })

        elif part_type == 'EPISTLE':
            reading_parts.append({
                'partType': 'EPISTLE',
                'partContents': [_convert_reading(c) for c in contents],
            })

        elif part_type in ('PSALM', 'CANTICLE'):
            reading_parts.append({
                'partType': part_type,
                'partContents': [_convert_psalm(c) for c in contents],
            })

        elif part_type == 'ALLELUIA':
            pass  # Handled via alleluia_map, injected into GOSPEL

        elif part_type == 'GOSPEL':
            converted = []
            for c in contents:
                verse = _find_verse(alleluia_map, _get_cycles(c))
                converted.append(_convert_gospel(c, verse))
            reading_parts.append({'partType': 'GOSPEL', 'partContents': converted})

        elif part_type == 'PRAYER_OVER_THE_OFFERINGS':
            offering_prayer.extend(
                c['content'] for c in contents if c.get('content') is not None
            )

        elif part_type == 'PREFACE':
            preface_list.extend(
                c['prefaceId'] for c in contents if c.get('prefaceId') is not None
            )

        elif part_type == 'COMMUNION_ANTIPHON':
            communion_antiphon.extend(_convert_antiphon(c) for c in contents)

        elif part_type == 'PRAYER_AFTER_COMMUNION':
            # note field is dropped
            prayer_after_communion.extend(
                c['content'] for c in contents if c.get('content') is not None
            )

    mass['entranceAntiphon'] = entrance_antiphon or None
    mass['collect'] = collect or None
    mass['readingParts'] = reading_parts or None
    mass['offeringPrayer'] = offering_prayer or None
    mass['prefaceList'] = preface_list or None
    mass['communionAntiphon'] = communion_antiphon or None
    mass['prayerAfterCommunion'] = prayer_after_communion or None
    mass['solemnBlessingList'] = None

    return mass


def convert_file(source_path: Path, target_path: Path):
    with open(source_path, encoding='utf-8') as f:
        data = yaml.safe_load(f)

    celebration = {
        'title': data.get('title'),
        'subtitle': data.get('context'),
    }

    masses = []
    for liturgy in data.get('liturgies', []):
        if liturgy.get('liturgyType') != 'MASS':
            continue
        alleluia_parts = [
            p for p in liturgy.get('massParts', [])
            if p.get('partType') == 'ALLELUIA'
        ]
        alleluia_map = _build_alleluia_map(alleluia_parts)
        masses.append(_convert_mass(liturgy, alleluia_map))

    result = {'celebration': celebration, 'mass': masses}

    target_path.parent.mkdir(parents=True, exist_ok=True)
    with open(target_path, 'w', encoding='utf-8') as f:
        yaml.dump(result, f, allow_unicode=True, default_flow_style=False, sort_keys=False)


def main():
    source_dir = Path(__file__).parent / 'assets' / 'mass_missal' / 'ferial_days'
    target_dir = Path(__file__).parent / 'assets' / 'mass_missal' / 'new'

    if not source_dir.exists():
        print(f"Source directory not found: {source_dir}", file=sys.stderr)
        sys.exit(1)

    yaml_files = sorted(source_dir.glob('*.yaml'))
    if not yaml_files:
        print("No YAML files found.")
        return

    errors = []
    for source_path in yaml_files:
        target_path = target_dir / source_path.name
        try:
            convert_file(source_path, target_path)
            print(f"  OK  {source_path.name}")
        except Exception as e:
            print(f"  ERR {source_path.name}: {e}")
            errors.append((source_path.name, str(e)))

    total = len(yaml_files)
    ok = total - len(errors)
    print(f"\n{ok}/{total} files converted → {target_dir}")
    if errors:
        sys.exit(1)


if __name__ == '__main__':
    main()
