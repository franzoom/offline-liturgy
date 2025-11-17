#!/usr/bin/env python3
"""
Complete script to restructure liturgical JSON files to match the new Morning class structure.

Transformations:
- celebrationTitle, celebrationSubtitle, etc. -> celebration{title, subtitle, ...}
- commonTitle -> preserved at root level
- invitatoryAntiphon, invitatoryPsalms -> invitatory{antiphon, psalms}
- evangelicAntiphon, evangelicAntiphonA/B/C -> evangelicAntiphon{common, yearA/B/C}
- Map in evangelicAntiphon -> wrapped in 'common'
- intercessionDescription, intercession -> intercession{description, content}
- reading.ref -> reading.biblicalReference
- oration, oration2 -> oration (as list)
- biblicalReading, biblicalReading2, etc. -> biblicalReading: [...]
- patristicReading, patristicReading2, etc. -> patristicReading: [...]
- readingsOration -> readings.oration
- firstVespersPsalm1/2/3 -> firstVespers.psalmody
- sundayEvangelicAntiphonA/B/C -> integrated into offices ONLY for _0.json files (Sundays)
- Orders keys according to DayOffices class structure
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional
from collections import OrderedDict


# Define the logical order of keys
ROOT_KEY_ORDER = [
    'celebration',
    'commonTitle',
    'firstVespers',
    'invitatory',
    'morning',
    'readings',
    'middleOfDay',
    'vespers',
    # Legacy fields (should not appear after restructuring)
    'sundayEvangelicAntiphonA',
    'sundayEvangelicAntiphonB',
    'sundayEvangelicAntiphonC',
    'evangelicAntiphon',
    'oration',
]

OFFICE_KEY_ORDER = [
    'hymn',
    'psalmody',
    'reading',
    'biblicalReading',
    'patristicReading',
    'verse',
    'responsory',
    'evangelicAntiphon',
    'intercession',
    'intercession2',
    'oration',
]


def is_sunday_file(filepath: Path) -> bool:
    """
    Check if the file is a Sunday file (ends with _0.json).
    
    Args:
        filepath: Path to the JSON file
    
    Returns:
        True if the file is a Sunday file, False otherwise
    """
    filename = filepath.stem  # Get filename without extension
    return filename.endswith('_0')


def ordered_dict_from_keys(data: Dict[str, Any], key_order: List[str]) -> OrderedDict:
    """
    Create an OrderedDict with keys in the specified order.
    Keys not in key_order are appended at the end in their original order.
    """
    result = OrderedDict()
    
    # First add keys in the specified order
    for key in key_order:
        if key in data:
            result[key] = data[key]
    
    # Then add any remaining keys not in the order list
    for key in data:
        if key not in result:
            result[key] = data[key]
    
    return result


def restructure_celebration(data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract and restructure celebration-related fields.
    
    Returns None if no celebration fields are present.
    """
    celebration_fields = {
        'celebrationTitle': 'title',
        'celebrationSubtitle': 'subtitle',
        'celebrationDescription': 'description',
        'commons': 'commons',
        'liturgicalGrade': 'grade',
        'celebration Grade': 'grade',  # Handle typo
        'liturgicalColor': 'color',
    }
    
    celebration = {}
    for old_key, new_key in celebration_fields.items():
        if old_key in data:
            celebration[new_key] = data[old_key]
    
    return celebration if celebration else None


def restructure_invitatory(data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract and restructure invitatory-related fields from root level.
    
    Returns None if no invitatory fields are present.
    """
    invitatory = {}
    
    if 'invitatoryAntiphon' in data:
        invitatory['antiphon'] = data['invitatoryAntiphon']
    
    if 'invitatoryPsalms' in data:
        invitatory['psalms'] = data['invitatoryPsalms']
    
    return invitatory if invitatory else None


def restructure_reading(office_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract and restructure reading fields from an office structure.
    
    Transforms ref -> biblicalReference, content -> content
    Returns None if no reading fields are present.
    """
    reading = {}
    
    # Handle old structure (ref/content)
    if 'reading' in office_data:
        old_reading = office_data['reading']
        if isinstance(old_reading, dict):
            if 'ref' in old_reading:
                reading['biblicalReference'] = old_reading['ref']
            if 'content' in old_reading:
                reading['content'] = old_reading['content']
        elif isinstance(old_reading, str):
            # If reading is just a string, assume it's content
            reading['content'] = old_reading
    
    # Handle separate readingRef field at office level
    if 'readingRef' in office_data:
        reading['biblicalReference'] = office_data['readingRef']
    
    return reading if reading else None


def restructure_evangelic_antiphon(office_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract and restructure evangelic antiphon fields from an office structure.
    
    If evangelicAntiphon is already a dict/map, wrap it in 'common' subkey.
    
    Returns None if no evangelic antiphon fields are present.
    """
    evangelic = {}
    
    if 'evangelicAntiphon' in office_data:
        existing = office_data['evangelicAntiphon']
        
        # If it's already a dict/map, check if it needs wrapping
        if isinstance(existing, dict):
            # Check if it already has 'common', 'yearA', 'yearB', 'yearC' keys
            # If it has these keys, it's already in the correct format
            if any(key in existing for key in ['common', 'yearA', 'yearB', 'yearC']):
                return existing
            else:
                # It's a dict but not in the right format, wrap it in 'common'
                evangelic['common'] = existing
        # If it's a string, put it as common
        elif isinstance(existing, str):
            evangelic['common'] = existing
    
    # Add yearA/B/C if they exist at office level (legacy)
    if 'evangelicAntiphonA' in office_data:
        evangelic['yearA'] = office_data['evangelicAntiphonA']
    
    if 'evangelicAntiphonB' in office_data:
        evangelic['yearB'] = office_data['evangelicAntiphonB']
    
    if 'evangelicAntiphonC' in office_data:
        evangelic['yearC'] = office_data['evangelicAntiphonC']
    
    return evangelic if evangelic else None


def restructure_intercession(office_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract and restructure intercession fields from an office structure.
    
    Returns None if no intercession fields are present.
    """
    intercession = {}
    
    # If intercession is already a dict, keep it
    if 'intercession' in office_data and isinstance(office_data['intercession'], dict):
        return office_data['intercession']
    
    if 'intercessionDescription' in office_data:
        intercession['description'] = office_data['intercessionDescription']
    
    if 'intercession' in office_data and isinstance(office_data['intercession'], str):
        intercession['content'] = office_data['intercession']
    
    return intercession if intercession else None


def restructure_oration(office_data: Dict[str, Any]) -> Optional[List[str]]:
    """
    Extract and restructure oration field(s) into a list.
    
    Returns None if no oration fields are present.
    """
    orations = []
    
    # Handle case where oration is already a list
    if 'oration' in office_data:
        if isinstance(office_data['oration'], list):
            orations.extend(office_data['oration'])
        else:
            orations.append(office_data['oration'])
    
    if 'oration2' in office_data:
        orations.append(office_data['oration2'])
    
    return orations if orations else None


def restructure_first_vespers_psalms(data: Dict[str, Any]) -> Optional[List[Dict[str, Any]]]:
    """
    Restructure firstVespersPsalm1/2/3 into psalmody list structure.
    
    Returns None if no psalms are present.
    """
    psalmody = []
    
    for i in range(1, 10):  # Check up to psalm 9
        psalm_key = f'firstVespersPsalm{i}'
        antiphon_key = f'firstVespersPsalm{i}Antiphon'
        antiphon2_key = f'firstVespersPsalm{i}Antiphon2'
        
        if psalm_key in data:
            psalm_entry = {
                'psalm': data[psalm_key]
            }
            
            # Add antiphons if they exist
            antiphons = []
            if antiphon_key in data and data[antiphon_key]:
                antiphons.append(data[antiphon_key])
            if antiphon2_key in data and data[antiphon2_key]:
                antiphons.append(data[antiphon2_key])
            
            if antiphons:
                psalm_entry['antiphon'] = antiphons
            
            psalmody.append(psalm_entry)
    
    return psalmody if psalmody else None


def handle_readings_oration_from_root(data: Dict[str, Any]) -> Optional[List[str]]:
    """
    Extract readingsOration from root level to be placed in readings.oration.
    
    Returns None if readingsOration is not present.
    """
    if 'readingsOration' in data:
        # Convert to list if it's a string
        if isinstance(data['readingsOration'], str):
            return [data['readingsOration']]
        elif isinstance(data['readingsOration'], list):
            return data['readingsOration']
    
    return None


def integrate_sunday_antiphons_into_office(
    office_data: Dict[str, Any], 
    sunday_antiphons: Dict[str, str]
) -> Dict[str, Any]:
    """
    Integrate sunday antiphons into an office's evangelicAntiphon structure.
    
    Args:
        office_data: The office data dictionary
        sunday_antiphons: Dict with yearA, yearB, yearC from root level
    
    Returns:
        Modified office data with integrated sunday antiphons
    """
    if not sunday_antiphons:
        return office_data
    
    # Check if office has evangelicAntiphon field
    if 'evangelicAntiphon' in office_data:
        evangelic = office_data['evangelicAntiphon']
        
        # If it's already an object (dict), add yearA/B/C to it
        if isinstance(evangelic, dict):
            if 'yearA' in sunday_antiphons:
                evangelic['yearA'] = sunday_antiphons['yearA']
            if 'yearB' in sunday_antiphons:
                evangelic['yearB'] = sunday_antiphons['yearB']
            if 'yearC' in sunday_antiphons:
                evangelic['yearC'] = sunday_antiphons['yearC']
        
        # If it's a string, convert it to object with common and years
        elif isinstance(evangelic, str):
            new_evangelic = {
                'common': evangelic
            }
            if 'yearA' in sunday_antiphons:
                new_evangelic['yearA'] = sunday_antiphons['yearA']
            if 'yearB' in sunday_antiphons:
                new_evangelic['yearB'] = sunday_antiphons['yearB']
            if 'yearC' in sunday_antiphons:
                new_evangelic['yearC'] = sunday_antiphons['yearC']
            office_data['evangelicAntiphon'] = new_evangelic
    
    else:
        # Office has no evangelicAntiphon, create one with just the years
        new_evangelic = {}
        if 'yearA' in sunday_antiphons:
            new_evangelic['yearA'] = sunday_antiphons['yearA']
        if 'yearB' in sunday_antiphons:
            new_evangelic['yearB'] = sunday_antiphons['yearB']
        if 'yearC' in sunday_antiphons:
            new_evangelic['yearC'] = sunday_antiphons['yearC']
        
        if new_evangelic:
            office_data['evangelicAntiphon'] = new_evangelic
    
    return office_data


def restructure_office(
    office_data: Dict[str, Any], 
    office_type: str, 
    sunday_antiphons: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Restructure an office section (morning, vespers, readings, etc.).
    
    Args:
        office_data: The office data dictionary
        office_type: Type of office ('morning', 'vespers', 'readings', etc.)
        sunday_antiphons: Optional dict with yearA, yearB, yearC from root level
    
    Returns:
        Restructured office data with proper key ordering
    """
    restructured = {}
    
    # Fields that should be kept as-is
    keep_fields = ['hymn', 'psalmody', 'responsory', 'verse']
    for field in keep_fields:
        if field in office_data:
            restructured[field] = office_data[field]
    
    # Handle biblicalReading for readings office - consolidate into list
    if office_type == 'readings':
        biblical_readings = []
        for i in range(1, 10):  # Check up to biblicalReading9
            field_name = 'biblicalReading' if i == 1 else f'biblicalReading{i}'
            if field_name in office_data:
                biblical_readings.append(office_data[field_name])
        
        if biblical_readings:
            restructured['biblicalReading'] = biblical_readings
        
        # Handle patristicReading - consolidate into list
        patristic_readings = []
        for i in range(1, 10):  # Check up to patristicReading9
            field_name = 'patristicReading' if i == 1 else f'patristicReading{i}'
            if field_name in office_data:
                patristic_readings.append(office_data[field_name])
        
        if patristic_readings:
            restructured['patristicReading'] = patristic_readings
    
    # Restructure reading
    reading = restructure_reading(office_data)
    if reading:
        restructured['reading'] = reading
    
    # Restructure evangelic antiphon
    evangelic = restructure_evangelic_antiphon(office_data)
    
    # For morning, vespers, and firstVespers: add sunday antiphons if present
    if office_type in ['morning', 'vespers', 'firstVespers'] and sunday_antiphons:
        if evangelic is None:
            evangelic = {}
        # Add yearA, yearB, yearC from sunday antiphons
        if 'yearA' in sunday_antiphons:
            evangelic['yearA'] = sunday_antiphons['yearA']
        if 'yearB' in sunday_antiphons:
            evangelic['yearB'] = sunday_antiphons['yearB']
        if 'yearC' in sunday_antiphons:
            evangelic['yearC'] = sunday_antiphons['yearC']
    
    if evangelic:
        restructured['evangelicAntiphon'] = evangelic
    
    # Restructure intercession
    intercession = restructure_intercession(office_data)
    if intercession:
        restructured['intercession'] = intercession
    
    # Handle intercession2 separately if present (morning office)
    if 'intercession2' in office_data:
        restructured['intercession2'] = office_data['intercession2']
    
    # Restructure oration
    oration = restructure_oration(office_data)
    if oration:
        restructured['oration'] = oration
    
    # Order keys according to OFFICE_KEY_ORDER
    return dict(ordered_dict_from_keys(restructured, OFFICE_KEY_ORDER))


def restructure_middle_of_day(middle_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Restructure middle of day office, handling tierce/sexte/none.
    """
    restructured = {}
    
    # Keep psalmody as-is
    if 'psalmody' in middle_data:
        restructured['psalmody'] = middle_data['psalmody']
    
    # Keep legacy psalm fields
    for psalm_field in ['psalm1', 'psalm2', 'psalm3']:
        if psalm_field in middle_data:
            restructured[psalm_field] = middle_data[psalm_field]
    
    # Handle tierce, sexte, none - restructure their reading fields
    for hour in ['tierce', 'sexte', 'none']:
        if hour in middle_data and isinstance(middle_data[hour], dict):
            hour_data = middle_data[hour].copy()
            
            # Restructure reading in hour
            if 'reading' in hour_data:
                reading = restructure_reading({'reading': hour_data['reading']})
                if reading:
                    hour_data['reading'] = reading
            
            restructured[hour] = hour_data
    
    # Restructure oration
    oration = restructure_oration(middle_data)
    if oration:
        restructured['oration'] = oration
    
    return restructured


def restructure_json_file(data: Dict[str, Any], filepath: Path) -> Dict[str, Any]:
    """
    Restructure an entire JSON file according to the new schema.
    
    Args:
        data: The original JSON data
        filepath: Path to the file being processed (to check if it's a Sunday file)
    
    Returns:
        Restructured JSON data with proper key ordering
    """
    restructured = {}
    
    # 1. Restructure celebration (from root level)
    celebration = restructure_celebration(data)
    if celebration:
        restructured['celebration'] = celebration
    
    # 1.5. Preserve commonTitle for files in commons/ directory
    if 'commonTitle' in data:
        restructured['commonTitle'] = data['commonTitle']
    
    # 2. Extract sunday evangelic antiphons from root level
    # Only integrate if it's a Sunday file (_0.json)
    sunday_antiphons = {}
    is_sunday = is_sunday_file(filepath)
    
    if is_sunday:
        if 'sundayEvangelicAntiphonA' in data:
            sunday_antiphons['yearA'] = data['sundayEvangelicAntiphonA']
        if 'sundayEvangelicAntiphonB' in data:
            sunday_antiphons['yearB'] = data['sundayEvangelicAntiphonB']
        if 'sundayEvangelicAntiphonC' in data:
            sunday_antiphons['yearC'] = data['sundayEvangelicAntiphonC']
    
    # 3. Restructure invitatory (from root level)
    invitatory_root = restructure_invitatory(data)
    if invitatory_root:
        restructured['invitatory'] = invitatory_root
    
    # Handle invitatory office if present (different from root invitatory fields)
    if 'invitatory' in data and isinstance(data['invitatory'], dict):
        if 'antiphon' in data['invitatory'] or 'psalm' in data['invitatory']:
            restructured['invitatory'] = data['invitatory']
    
    # 4. Handle firstVespers - check for both nested structure and flat psalm fields
    if 'firstVespers' in data and isinstance(data['firstVespers'], dict):
        # Restructure existing firstVespers office
        restructured['firstVespers'] = restructure_office(
            data['firstVespers'], 
            'firstVespers',
            sunday_antiphons if is_sunday and sunday_antiphons else None
        )
    else:
        # Check for flat firstVespersPsalm1/2/3 fields at root level
        first_vespers_psalms = restructure_first_vespers_psalms(data)
        if first_vespers_psalms:
            restructured['firstVespers'] = {
                'psalmody': first_vespers_psalms
            }
            # Add sunday antiphons if it's a Sunday file
            if is_sunday and sunday_antiphons:
                restructured['firstVespers']['evangelicAntiphon'] = sunday_antiphons
    
    # 5. Restructure morning office
    if 'morning' in data and isinstance(data['morning'], dict):
        restructured['morning'] = restructure_office(
            data['morning'], 
            'morning',
            sunday_antiphons if is_sunday and sunday_antiphons else None
        )
    elif is_sunday and sunday_antiphons:
        # Create morning office with just sunday antiphons
        restructured['morning'] = restructure_office(
            {}, 
            'morning',
            sunday_antiphons
        )
    
    # 6. Restructure readings office with special handling for readingsOration
    if 'readings' in data and isinstance(data['readings'], dict):
        restructured['readings'] = restructure_office(data['readings'], 'readings')
        
        # Add readingsOration from root level if it exists
        readings_oration = handle_readings_oration_from_root(data)
        if readings_oration:
            restructured['readings']['oration'] = readings_oration
    
    # 7. Handle middle of day office
    if 'middleOfDay' in data and isinstance(data['middleOfDay'], dict):
        restructured['middleOfDay'] = restructure_middle_of_day(data['middleOfDay'])
    
    # 8. Restructure vespers office
    if 'vespers' in data and isinstance(data['vespers'], dict):
        restructured['vespers'] = restructure_office(
            data['vespers'], 
            'vespers',
            sunday_antiphons if is_sunday and sunday_antiphons else None
        )
    elif is_sunday and sunday_antiphons:
        # Create vespers office with just sunday antiphons
        restructured['vespers'] = restructure_office(
            {}, 
            'vespers',
            sunday_antiphons
        )
    
    # 9. Handle root-level oration (not readingsOration which was handled above)
    root_oration = restructure_oration(data)
    if root_oration:
        restructured['oration'] = root_oration
    
    # Note: sundayEvangelicAntiphonA/B/C are NOT added to restructured
    # They are either integrated into offices (if Sunday) or removed (if not Sunday)
    # readingsOration is NOT added to root, it goes into readings.oration
    
    # Handle root-level evangelicAntiphon (legacy) only if no morning office
    if 'evangelicAntiphon' in data and 'morning' not in data:
        restructured['evangelicAntiphon'] = data['evangelicAntiphon']
    
    # Order keys according to ROOT_KEY_ORDER
    return dict(ordered_dict_from_keys(restructured, ROOT_KEY_ORDER))


def process_file(input_path: Path, output_path: Path, dry_run: bool = False) -> bool:
    """
    Process a single JSON file.
    
    Args:
        input_path: Path to input JSON file
        output_path: Path to output JSON file
        dry_run: If True, don't write the file, just check
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Read input file
        with open(input_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Restructure the data
        restructured = restructure_json_file(data, input_path)
        
        # Write output file (unless dry run)
        if not dry_run:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(restructured, f, ensure_ascii=False, indent=2)
        
        print(f"✓ Processed: {input_path.relative_to(input_path.parent.parent)}")
        return True
        
    except json.JSONDecodeError as e:
        print(f"✗ JSON error in {input_path}: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"✗ Error processing {input_path}: {e}", file=sys.stderr)
        return False


def process_directory(input_dir: Path, output_dir: Path, dry_run: bool = False) -> tuple:
    """
    Process all JSON files in a directory and its subdirectories.
    
    Args:
        input_dir: Input directory path
        output_dir: Output directory path
        dry_run: If True, don't write files
    
    Returns:
        Tuple of (success_count, error_count)
    """
    success_count = 0
    error_count = 0
    
    # Find all JSON files
    json_files = list(input_dir.rglob('*.json'))
    
    if not json_files:
        print(f"No JSON files found in {input_dir}")
        return (0, 0)
    
    print(f"Found {len(json_files)} JSON files to process")
    if dry_run:
        print("DRY RUN - No files will be modified")
    print()
    
    for json_file in json_files:
        # Calculate relative path to preserve directory structure
        relative_path = json_file.relative_to(input_dir)
        output_file = output_dir / relative_path
        
        if process_file(json_file, output_file, dry_run):
            success_count += 1
        else:
            error_count += 1
    
    return (success_count, error_count)


def main():
    """Main function to handle command-line interface."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Restructure liturgical JSON files to new schema',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process files in-place (overwrites originals!)
  python3 restructure_json.py assets/calendar_data
  
  # Process to a different output directory
  python3 restructure_json.py assets/calendar_data assets/calendar_data_new
  
  # Dry run to check what would be changed
  python3 restructure_json.py assets/calendar_data --dry-run
  
  # Process single file
  python3 restructure_json.py assets/calendar_data/special_days/immaculate_conception.json
        """
    )
    
    parser.add_argument(
        'input_path',
        help='Input directory or file path'
    )
    parser.add_argument(
        'output_path',
        nargs='?',
        help='Output directory or file path (defaults to input_path for in-place editing)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Check files without writing changes'
    )
    parser.add_argument(
        '--backup',
        action='store_true',
        help='Create .bak backup files before overwriting'
    )
    
    args = parser.parse_args()
    
    input_path = Path(args.input_path)
    output_path = Path(args.output_path) if args.output_path else input_path
    
    # Check if input exists
    if not input_path.exists():
        print(f"Error: Input path does not exist: {input_path}", file=sys.stderr)
        sys.exit(1)
    
    # Create backup if requested and doing in-place edit
    if args.backup and input_path == output_path and not args.dry_run:
        import shutil
        backup_path = Path(str(input_path) + '.bak')
        if input_path.is_file():
            shutil.copy2(input_path, backup_path)
            print(f"Created backup: {backup_path}")
        else:
            shutil.copytree(input_path, backup_path, dirs_exist_ok=True)
            print(f"Created backup directory: {backup_path}")
        print()
    
    # Process file or directory
    if input_path.is_file():
        # Single file
        if output_path.is_dir():
            output_file = output_path / input_path.name
        else:
            output_file = output_path
        
        success = process_file(input_path, output_file, args.dry_run)
        sys.exit(0 if success else 1)
    else:
        # Directory
        success_count, error_count = process_directory(
            input_path, 
            output_path, 
            args.dry_run
        )
        
        print()
        print(f"Summary:")
        print(f"  Success: {success_count}")
        print(f"  Errors:  {error_count}")
        
        sys.exit(0 if error_count == 0 else 1)


if __name__ == '__main__':
    main()