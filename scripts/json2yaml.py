#!/usr/bin/env python3
"""
Convert JSON liturgical files to YAML format with HTML tag transformation.

HTML transformations applied to string values:
- If original string contains <p> or ':' → use |- block scalar
- <p>   → removed
- </p>  → paragraph break (double newline by default, single for biblical/patristic readings),
          except at end of string (removed)
- <br>  → newline
- <i>, </i> → %
- &nbsp; → non-breaking space (U+00A0)
- Each line is stripped of leading/trailing spaces after transformation
"""

import json
import re
import sys
from pathlib import Path


NBSP = '\u00A0'


SINGLE_PARA_BREAK_KEYS = {'biblicalReading', 'patristicReading'}


def transform_html(text: str, para_sep: str = '\n\n') -> tuple[str, bool]:
    """
    Apply HTML transformations to a string.
    Returns (transformed_text, use_block_scalar).
    use_block_scalar is True if original contained <p> or ':'.
    para_sep: separator used for </p> (default double newline, single for readings content).
    """
    use_block = '<p>' in text or ':' in text

    # &nbsp; → non-breaking space
    text = text.replace('&nbsp;', NBSP)

    # <i> and </i> → %
    text = text.replace('<i>', '%')
    text = text.replace('</i>', '%')

    # <br> → newline
    text = re.sub(r'<br\s*/?>', '\n', text)

    # </p> at end of string → removed
    text = re.sub(r'(\s*</p>)+\s*$', '', text.strip())

    # remaining </p> → paragraph separator
    text = text.replace('</p>', para_sep)

    # <p> → removed
    text = text.replace('<p>', '')

    # (Stance) → [rubric](Stance)[/rubric]
    text = text.replace('(Stance)', '[rubric](Stance)[/rubric]')

    # Strip each line (removes spaces left by tag removal)
    lines = [line.strip() for line in text.split('\n')]
    text = '\n'.join(lines)

    # Clean up leading/trailing and excess blank lines
    text = text.strip()
    text = re.sub(r'\n{3,}', '\n\n', text)

    return text, use_block


def needs_quoting(s: str) -> bool:
    """Check if a plain YAML scalar needs to be quoted."""
    if not s:
        return True
    if s[0] in '-?:,[]{}#&*!|>\'"@`':
        return True
    if ': ' in s or ' #' in s:
        return True
    if s.lower() in ('true', 'false', 'null', 'yes', 'no', 'on', 'off', '~'):
        return True
    if re.match(r'^[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$', s):
        return True
    return False


def serialize_string(value: str, indent: int, para_sep: str = '\n\n') -> str:
    """Serialize a string value to YAML representation."""
    transformed, use_block = transform_html(value, para_sep)

    if use_block or '\n' in transformed:
        ind = '  ' * indent
        lines = transformed.split('\n')
        block_content = '\n'.join(ind + line for line in lines)
        return f'|-\n{block_content}'

    if needs_quoting(transformed):
        escaped = transformed.replace('\\', '\\\\').replace('"', '\\"')
        return f'"{escaped}"'

    return transformed


def serialize_value(value, indent: int, para_sep: str = '\n\n') -> str:
    """Serialize any JSON value to YAML representation."""
    if value is None:
        return 'null'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return serialize_string(value, indent, para_sep)
    if isinstance(value, list):
        return serialize_list(value, indent, para_sep)
    if isinstance(value, dict):
        return serialize_dict(value, indent, para_sep)
    return repr(value)


def serialize_list(items: list, indent: int, para_sep: str = '\n\n') -> str:
    """Serialize a list to YAML block sequence."""
    if not items:
        return '[]'

    ind = '  ' * indent
    parts = []

    for item in items:
        if isinstance(item, list):
            # Nested list: "- " on its own line
            sub_str = serialize_list(item, indent + 1, para_sep)
            parts.append(f'{ind}-\n{sub_str}')
        elif isinstance(item, dict) and item:
            # Dict: first key on same line as "- "
            dict_str = serialize_dict(item, indent + 1, para_sep)
            dict_lines = dict_str.split('\n')
            first = dict_lines[0].lstrip()
            result = f'{ind}- {first}'
            if len(dict_lines) > 1:
                result += '\n' + '\n'.join(dict_lines[1:])
            parts.append(result)
        else:
            val_str = serialize_value(item, indent + 1, para_sep)
            parts.append(f'{ind}- {val_str}')

    return '\n'.join(parts)


def serialize_dict(d: dict, indent: int, para_sep: str = '\n\n') -> str:
    """Serialize a dict to YAML block mapping."""
    if not d:
        return '{}'

    ind = '  ' * indent
    parts = []

    for key, value in d.items():
        # biblicalReading and patristicReading: </p> → single newline
        child_para_sep = '\n' if key in SINGLE_PARA_BREAK_KEYS else para_sep
        if isinstance(value, (dict, list)) and value:
            val_str = serialize_value(value, indent + 1, child_para_sep)
            parts.append(f'{ind}{key}:\n{val_str}')
        else:
            val_str = serialize_value(value, indent + 1, child_para_sep)
            parts.append(f'{ind}{key}: {val_str}')

    return '\n'.join(parts)


def convert(input_path: Path, output_path: Path) -> None:
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    yaml_content = serialize_dict(data, 0)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
        f.write('\n')

    print(f'✓ {input_path} → {output_path}')


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Convert JSON liturgical files to YAML with HTML tag transformation'
    )
    parser.add_argument('input', help='Input JSON file')
    parser.add_argument(
        'output',
        nargs='?',
        help='Output YAML file (default: same name with .yaml extension)'
    )

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f'Error: {input_path} does not exist', file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_suffix('.yaml')

    convert(input_path, output_path)


if __name__ == '__main__':
    main()
