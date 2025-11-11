#!/usr/bin/env python3
"""
Script to restructure liturgical JSON files with deep nesting:
1. Grouping keys by prefix (morning, readings, vespers, middleOfDay, invitatory, firstVespers)
2. Converting psalm structures to list of objects with antiphons arrays
3. Creating nested reading objects
4. Structuring middleOfDay with tierce/sexte/none sub-objects
5. Structuring readings with biblicalReading/patristicReading sub-objects
"""

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

def extract_psalmody(data: Dict[str, Any], prefix: str) -> Optional[List[Dict[str, Any]]]:
    """
    Extract psalm data and convert to list of objects with antiphon array.
    Note: Uses 'antiphon' (singular) as the key, even though it's a list.
    """
    psalmody = []
    
    for i in range(1, 4):
        psalm_key = f"{prefix}Psalm{i}"
        if psalm_key not in data:
            continue
            
        psalm_obj = {"psalm": data[psalm_key]}
        
        # Collect antiphons (up to 3 per psalm) - use singular 'antiphon' key
        antiphon_list = []
        for j in range(1, 4):
            if j == 1:
                antiphon_key = f"{prefix}Psalm{i}Antiphon"
            else:
                antiphon_key = f"{prefix}Psalm{i}Antiphon{j}"
            
            if antiphon_key in data:
                antiphon_list.append(data[antiphon_key])
        
        if antiphon_list:
            psalm_obj["antiphon"] = antiphon_list  # singular key, list value
        
        psalmody.append(psalm_obj)
    
    return psalmody if psalmody else None

def create_reading_object(data: Dict[str, Any], prefix: str) -> Optional[Dict[str, str]]:
    """
    Create a reading object with ref and content.
    Looks for {prefix}ReadingRef and {prefix}Reading
    
    Example: morningReadingRef + morningReading -> reading: {ref, content}
    """
    ref_key = f"{prefix}ReadingRef"
    content_key = f"{prefix}Reading"
    
    reading = {}
    if ref_key in data:
        reading["ref"] = data[ref_key]
    if content_key in data:
        reading["content"] = data[content_key]
    
    return reading if reading else None

def group_middle_of_day(data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Special handling for middleOfDay with tierce/sexte/none sub-objects.
    
    Mapping:
    - tierce: TierceAntiphon, Reading1Ref, Reading1Content, Responsory1
    - sexte: SexteAntiphon, Reading2Ref, Reading2Content, Responsory2
    - none: NoneAntiphon, Reading3Ref, Reading3Content, Responsory3
    
    Structure:
    middleOfDay:
      tierce:
        antiphon: ...
        reading: {ref, content}
        responsory: ...
      sexte: ...
      none: ...
      psalmody: [...]
      oration: ...
    """
    grouped = {}
    prefix = "middleOfDay"
    
    # Extract psalmody if it exists
    psalmody = extract_psalmody(data, prefix)
    if psalmody:
        grouped["psalmody"] = psalmody
    
    # Handle tierce, sexte, none sub-objects
    # Map office name to number for reading/responsory
    office_mapping = {
        "Tierce": "1",
        "Sexte": "2",
        "None": "3"
    }
    
    for office_name, reading_num in office_mapping.items():
        office_lower = office_name.lower()
        office_obj = {}
        
        # Antiphon - uses office name (e.g., middleOfDayTierceAntiphon)
        antiphon_key = f"{prefix}{office_name}Antiphon"
        if antiphon_key in data:
            office_obj["antiphon"] = data[antiphon_key]
        
        # Reading - uses number (e.g., middleOfDayReading1Ref)
        reading_ref_key = f"{prefix}Reading{reading_num}Ref"
        reading_content_key = f"{prefix}Reading{reading_num}Content"
        reading = {}
        if reading_ref_key in data:
            reading["ref"] = data[reading_ref_key]
        if reading_content_key in data:
            reading["content"] = data[reading_content_key]
        if reading:
            office_obj["reading"] = reading
        
        # Responsory - uses number (e.g., middleOfDayResponsory1)
        responsory_key = f"{prefix}Responsory{reading_num}"
        if responsory_key in data:
            office_obj["responsory"] = data[responsory_key]
        
        if office_obj:
            grouped[office_lower] = office_obj
    
    # Handle other middleOfDay keys (oration, etc.)
    for key, value in data.items():
        if not key.startswith(prefix):
            continue
        
        # Skip already processed keys
        if any(x in key for x in ["Psalm", "Tierce", "Sexte", "None", "Reading", "Responsory"]):
            continue
        
        # Remove prefix and lowercase first letter
        new_key = key[len(prefix):]
        if new_key:
            new_key = new_key[0].lower() + new_key[1:]
            grouped[new_key] = value
    
    return grouped if grouped else None

def group_readings(data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Special handling for readings with biblicalReading and patristicReading sub-objects.
    
    Structure:
    readings:
      hymn: [...]
      psalmody: [...]
      verse: ...
      biblicalReading:
        title: ...
        ref: ...
        content: ...
        responsory: ...
      biblicalReading2: (if exists)
        title: ...
        ref: ...
        content: ...
        responsory: ...
      patristicReading:
        title: ...
        subtitle: ...
        content: ...
        responsory: ...
      patristicReading2/3: (if exists)
      oration: ...
    """
    grouped = {}
    prefix = "readings"
    
    # Extract psalmody
    psalmody = extract_psalmody(data, prefix)
    if psalmody:
        grouped["psalmody"] = psalmody
    
    # Handle biblical readings (can have 1 or 2)
    for i in ["", "2"]:
        suffix = i if i else ""
        biblical_obj = {}
        
        title_key = f"{prefix}BiblicalReadingTitle{suffix}"
        ref_key = f"{prefix}BiblicalReadingRef{suffix}"
        content_key = f"{prefix}BiblicalReadingContent{suffix}"
        responsory_key = f"{prefix}BiblicalReadingResponsory{suffix}"
        
        if title_key in data:
            biblical_obj["title"] = data[title_key]
        if ref_key in data:
            biblical_obj["ref"] = data[ref_key]
        if content_key in data:
            biblical_obj["content"] = data[content_key]
        if responsory_key in data:
            biblical_obj["responsory"] = data[responsory_key]
        
        if biblical_obj:
            key_name = "biblicalReading" if not suffix else f"biblicalReading{suffix}"
            grouped[key_name] = biblical_obj
    
    # Handle patristic readings (can have 1, 2, or 3)
    for i in ["", "2", "3"]:
        suffix = i if i else ""
        patristic_obj = {}
        
        title_key = f"{prefix}PatristicReadingTitle{suffix}"
        subtitle_key = f"{prefix}PatristicReadingSubtitle{suffix}"
        content_key = f"{prefix}PatristicReadingContent{suffix}"
        responsory_key = f"{prefix}PatristicReadingResponsory{suffix}"
        
        if title_key in data:
            patristic_obj["title"] = data[title_key]
        if subtitle_key in data:
            patristic_obj["subtitle"] = data[subtitle_key]
        if content_key in data:
            patristic_obj["content"] = data[content_key]
        if responsory_key in data:
            patristic_obj["responsory"] = data[responsory_key]
        
        if patristic_obj:
            key_name = "patristicReading" if not suffix else f"patristicReading{suffix}"
            grouped[key_name] = patristic_obj
    
    # Handle other readings keys
    for key, value in data.items():
        if not key.startswith(prefix):
            continue
        
        # Skip already processed keys
        if any(x in key for x in ["Psalm", "BiblicalReading", "PatristicReading"]):
            continue
        
        # Remove prefix and lowercase first letter
        new_key = key[len(prefix):]
        if new_key:
            new_key = new_key[0].lower() + new_key[1:]
            grouped[new_key] = value
    
    return grouped if grouped else None

def group_office_with_reading(data: Dict[str, Any], prefix: str) -> Optional[Dict[str, Any]]:
    """
    Group office keys (morning, vespers, firstVespers) with nested reading object.
    
    Structure:
    morning/vespers/firstVespers:
      hymn: [...]
      psalmody: [...]
      reading:
        ref: ...
        content: ...
      responsory: ...
      evangelicAntiphon: ...
      etc.
    """
    grouped = {}
    
    # Extract psalmody
    psalmody = extract_psalmody(data, prefix)
    if psalmody:
        grouped["psalmody"] = psalmody
    
    # Create reading object
    reading = create_reading_object(data, prefix)
    if reading:
        grouped["reading"] = reading
    
    # Process other keys
    for key, value in data.items():
        if not key.startswith(prefix):
            continue
        
        # Skip already processed keys
        if any(x in key for x in ["Psalm", "Reading"]):
            continue
        
        # Remove prefix and lowercase first letter
        new_key = key[len(prefix):]
        if new_key:
            new_key = new_key[0].lower() + new_key[1:]
            grouped[new_key] = value
    
    return grouped if grouped else None

def group_by_prefix(data: Dict[str, Any], prefix: str) -> Optional[Dict[str, Any]]:
    """
    Group all keys starting with prefix into a nested object.
    Applies special handling based on prefix type.
    """
    # Special handlers
    if prefix == "middleOfDay":
        return group_middle_of_day(data)
    elif prefix == "readings":
        return group_readings(data)
    elif prefix in ["morning", "vespers", "firstVespers"]:
        return group_office_with_reading(data, prefix)
    elif prefix == "invitatory":
        # Special handling for invitatory - group antiphons into a list
        grouped = {}
        
        # Collect antiphons (antiphon, antiphon2, antiphon3) into a list
        antiphon_list = []
        for i in ["", "2", "3"]:
            suffix = i if i else ""
            antiphon_key = f"{prefix}Antiphon{suffix}"
            if antiphon_key in data:
                antiphon_list.append(data[antiphon_key])
        
        if antiphon_list:
            grouped["antiphon"] = antiphon_list  # singular key, list value
        
        # Handle other invitatory keys (psalm, etc.)
        for key, value in data.items():
            if not key.startswith(prefix):
                continue
            if "Antiphon" in key:  # Skip antiphons (already processed)
                continue
            
            new_key = key[len(prefix):]
            if new_key:
                new_key = new_key[0].lower() + new_key[1:]
                grouped[new_key] = value
        
        return grouped if grouped else None
    
    return None

def restructure_json(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Restructure the entire JSON object with deep nesting.
    """
    new_data = {}
    
    # Prefixes to process (order matters)
    prefixes = ['invitatory', 'firstVespers', 'morning', 'readings', 'vespers', 'middleOfDay']
    
    # Track which keys have been processed
    processed_keys = set()
    
    # Process each prefix
    for prefix in prefixes:
        grouped = group_by_prefix(data, prefix)
        if grouped:
            new_data[prefix] = grouped
            # Mark all keys with this prefix as processed
            for key in data.keys():
                if key.startswith(prefix):
                    processed_keys.add(key)
    
    # Copy keys that don't match any prefix
    for key, value in data.items():
        if key not in processed_keys:
            new_data[key] = value
    
    return new_data

def process_json_file(filepath: Path) -> bool:
    """Process a single JSON file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        new_data = restructure_json(data)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, ensure_ascii=False, indent=2)
        
        print(f"✓ Processed: {filepath}")
        return True
    
    except json.JSONDecodeError as e:
        print(f"✗ JSON Error in {filepath}: {e}")
        return False
    except Exception as e:
        print(f"✗ Error processing {filepath}: {e}")
        import traceback
        traceback.print_exc()
        return False

def process_directory(directory: str = '.'):
    """Process all JSON files recursively in directory."""
    root_path = Path(directory)
    
    print(f"📂 Scanning directory: {root_path.absolute()}")
    
    if not root_path.exists():
        print(f"❌ Error: Directory '{directory}' does not exist")
        return
    
    print("🔎 Searching for JSON files...")
    json_files = list(root_path.rglob('*.json'))
    
    if not json_files:
        print(f"\n⚠️  No JSON files found in '{directory}'")
        return
    
    print(f"\n✅ Found {len(json_files)} JSON file(s)")
    print("=" * 60)
    
    success_count = 0
    fail_count = 0
    
    for filepath in json_files:
        if process_json_file(filepath):
            success_count += 1
        else:
            fail_count += 1
    
    print("=" * 60)
    print(f"\n📊 Results: {success_count} succeeded, {fail_count} failed")
    
    if fail_count > 0:
        print(f"⚠️  Warning: {fail_count} file(s) had errors")
    else:
        print("🎉 All files processed successfully!")

if __name__ == "__main__":
    import sys
    
    print("=" * 60)
    print("JSON RESTRUCTURING SCRIPT - DEEP NESTING")
    print("=" * 60)
    
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'
    
    print(f"\n📁 Working directory: {os.path.abspath(directory)}")
    
    if not os.path.exists(directory):
        print(f"\n❌ ERROR: Directory '{directory}' does not exist!")
        sys.exit(1)
    
    print(f"\n🚀 Starting JSON restructuring...")
    print("-" * 60)
    
    try:
        process_directory(directory)
    except Exception as e:
        print(f"\n❌ FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✅ SCRIPT COMPLETED")
    print("=" * 60)