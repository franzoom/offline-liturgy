#!/usr/bin/env python3
"""
Script to restructure liturgical JSON files by:
1. Grouping keys by prefix (morning, readings, vespers, middleOfDay, invitatory)
2. Converting psalm structures to list of objects with antiphons arrays
3. Processing all JSON files recursively in subdirectories
"""

import json
import os
from pathlib import Path
from typing import Any, Dict, List

def extract_psalmody(data: Dict[str, Any], prefix: str) -> List[Dict[str, Any]]:
    """
    Extract psalm data and convert to list of objects with antiphons array.
    
    Args:
        data: Source dictionary
        prefix: Prefix to search for (e.g., 'morning', 'readings')
    
    Returns:
        List of psalm objects with psalm and antiphons
    """
    psalmody = []
    
    # Check for up to 3 psalms
    for i in range(1, 4):
        psalm_key = f"{prefix}Psalm{i}"
        if psalm_key in data:
            psalm_obj = {
                "psalm": data[psalm_key],
                "antiphons": []
            }
            
            # Collect antiphons (up to 3 per psalm)
            for j in range(1, 4):
                antiphon_key = f"{prefix}Psalm{i}Antiphon" + ("" if j == 1 else str(j))
                if antiphon_key in data:
                    psalm_obj["antiphons"].append(data[antiphon_key])
            
            # Only add antiphons array if there are antiphons
            if not psalm_obj["antiphons"]:
                del psalm_obj["antiphons"]
            
            psalmody.append(psalm_obj)
    
    return psalmody if psalmody else None

def group_by_prefix(data: Dict[str, Any], prefix: str) -> Dict[str, Any]:
    """
    Group all keys starting with prefix into a nested object.
    Handles special psalmody structure.
    
    Args:
        data: Source dictionary
        prefix: Prefix to group by (e.g., 'morning')
    
    Returns:
        Grouped dictionary
    """
    grouped = {}
    prefix_capitalized = prefix[0].upper() + prefix[1:]
    
    # Extract psalmody first
    psalmody = extract_psalmody(data, prefix)
    if psalmody:
        grouped["psalmody"] = psalmody
    
    # Process other keys
    for key, value in data.items():
        if key.startswith(prefix) and "Psalm" not in key:
            # Remove prefix and lowercase first letter
            new_key = key[len(prefix):]
            if new_key:
                new_key = new_key[0].lower() + new_key[1:]
                grouped[new_key] = value
    
    return grouped if grouped else None

def restructure_json(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Restructure the entire JSON object.
    
    Args:
        data: Original JSON data
    
    Returns:
        Restructured JSON data
    """
    new_data = {}
    
    # Prefixes to process
    prefixes = ['invitatory', 'morning', 'readings', 'vespers', 'middleOfDay', 'firstVespers']
    
    # Process each prefix
    for prefix in prefixes:
        grouped = group_by_prefix(data, prefix)
        if grouped:
            new_data[prefix] = grouped
    
    # Copy keys that don't match any prefix
    processed_keys = set()
    for prefix in prefixes:
        for key in data.keys():
            if key.startswith(prefix):
                processed_keys.add(key)
    
    for key, value in data.items():
        if key not in processed_keys:
            new_data[key] = value
    
    return new_data

def process_json_file(filepath: Path) -> bool:
    """
    Process a single JSON file.
    
    Args:
        filepath: Path to the JSON file
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Read original file
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Restructure
        new_data = restructure_json(data)
        
        # Write back with proper formatting
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, ensure_ascii=False, indent=2)
        
        print(f"✓ Processed: {filepath}")
        return True
    
    except json.JSONDecodeError as e:
        print(f"✗ JSON Error in {filepath}: {e}")
        return False
    except Exception as e:
        print(f"✗ Error processing {filepath}: {e}")
        return False

def process_directory(directory: str = '.'):
    """
    Process all JSON files recursively in directory.
    
    Args:
        directory: Root directory to start from
    """
    root_path = Path(directory)
    
    print(f"📂 Scanning directory: {root_path.absolute()}")
    
    if not root_path.exists():
        print(f"❌ Error: Directory '{directory}' does not exist")
        print(f"   Full path: {root_path.absolute()}")
        return
    
    # Find all JSON files recursively
    print("🔎 Searching for JSON files...")
    json_files = list(root_path.rglob('*.json'))
    
    if not json_files:
        print(f"\n⚠️  No JSON files found in '{directory}'")
        print(f"   Searched in: {root_path.absolute()}")
        print(f"   Pattern used: **/*.json")
        
        # List what's actually in the directory
        try:
            items = list(root_path.iterdir())
            if items:
                print(f"\n📋 Contents of directory ({len(items)} items):")
                for item in items[:10]:  # Show first 10 items
                    print(f"   - {item.name} {'(dir)' if item.is_dir() else '(file)'}")
                if len(items) > 10:
                    print(f"   ... and {len(items) - 10} more items")
            else:
                print("   Directory is empty!")
        except Exception as e:
            print(f"   Could not list directory contents: {e}")
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
    print("JSON RESTRUCTURING SCRIPT STARTED")
    print("=" * 60)
    
    # Get directory from command line argument or use current directory
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'
    
    print(f"\n📁 Working directory: {os.path.abspath(directory)}")
    print(f"🔍 Python version: {sys.version}")
    print(f"💻 Script location: {os.path.abspath(__file__)}")
    
    if not os.path.exists(directory):
        print(f"\n❌ ERROR: Directory '{directory}' does not exist!")
        print(f"   Absolute path checked: {os.path.abspath(directory)}")
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