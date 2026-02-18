#!/usr/bin/env python3
"""
Synchronise les sauts de paragraphe depuis les fichiers HTML (liturgie-plus)
vers les fichiers YAML (offline-liturgy).

Traite deux types de lectures :
- biblicalReading : depuis lecture_3_x_y.html
- patristicReading : depuis patristique_3_x_y.html
"""

import os
import re
import glob
import html as html_module
import argparse

SCRIPT_DIR = os.path.dirname(__file__)
BIBLICAL_HTML_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "../../liturgie-plus/www/lectures/lectures"))
PATRISTIC_HTML_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "../../liturgie-plus/www/lectures/patristiques"))
YAML_BASE_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "../assets/calendar_data"))

# Correspondance préfixe HTML -> préfixe YAML et sous-dossier
PREFIX_MAP = {
    "1": ("advent", "ferial_days"),
    "2": ("christmas", "ferial_days"),
    "3": ("ot", "ferial_days"),
    "4": ("lent", "ferial_days"),
    "5": ("easter", "ferial_days"),
}

WORD_CONTEXT = 5


def normalize(text):
    """Normalise un texte pour la comparaison :
    supprime espaces, apostrophes, * et balises <i>."""
    text = re.sub(r'</?i>', '', text)
    text = text.replace("&nbsp;", "")
    text = text.replace("*", "")
    text = text.replace("\u2019", "")
    text = text.replace("\u2018", "")
    text = text.replace("'", "")
    text = text.replace("\u02BC", "")
    text = re.sub(r'[\s\u00A0\u202F\u2007\u2008\u2009\u200A]+', '', text)
    return text


def html_to_plain(html_text):
    """Convertit un fragment HTML en texte brut."""
    text = html_text
    # Supprimer toutes les balises HTML
    text = re.sub(r'<[^>]+>', '', text)
    # Décoder toutes les entités HTML (&nbsp;, &eacute;, &#8217;, etc.)
    text = html_module.unescape(text)
    # Normaliser les espaces multiples
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def extract_paragraphs(html_content, skip_bold=False):
    """Extrait les paragraphes (balises <p> sans classe).
    Si skip_bold=True, ignore les <p> dont le contenu est entièrement en <b>."""
    paragraphs = []
    for m in re.finditer(r'<p(\s[^>]*)?>(.+?)</p>', html_content, re.DOTALL):
        attrs = m.group(1) or ""
        if 'class=' in attrs:
            continue
        content = m.group(2)
        if skip_bold and re.match(r'^\s*<b>.*</b>\s*$', content, re.DOTALL):
            continue
        paragraphs.append(html_to_plain(content))
    return paragraphs


def find_split_position(yaml_text, context_words):
    """Trouve dans yaml_text la position (index) juste après la séquence
    de mots de contexte, en utilisant la comparaison normalisée."""
    norm_context = normalize(" ".join(context_words))
    norm_yaml = normalize(yaml_text)

    pos = norm_yaml.find(norm_context)
    if pos == -1:
        return -1

    target = pos + len(norm_context)
    orig_pos = 0
    norm_count = 0

    while orig_pos < len(yaml_text) and norm_count < target:
        norm_char = normalize(yaml_text[orig_pos])
        norm_count += len(norm_char)
        orig_pos += 1

    while orig_pos < len(yaml_text) and yaml_text[orig_pos] in ' \u00A0\u202F':
        orig_pos += 1

    return orig_pos


def find_content_in_section(yaml_content, section_name):
    """Trouve le content: "..." dans une section YAML donnée.
    Retourne (content_match, abs_start, abs_end, zone) ou None."""
    section_match = re.search(rf'^  {section_name}:', yaml_content, re.MULTILINE)
    if not section_match:
        return None

    section_start = section_match.start()

    # Trouver la fin de la section (prochaine section de même niveau ou fin)
    next_section = re.search(r'^  \w+:', yaml_content[section_start + 1:], re.MULTILINE)
    section_end = (section_start + 1 + next_section.start()) if next_section else len(yaml_content)
    zone = yaml_content[section_start:section_end]

    content_match = re.search(
        r'^(\s*)content:\s*"(.*)"$',
        zone,
        re.MULTILINE
    )

    if not content_match:
        return None

    abs_start = section_start + content_match.start()
    abs_end = section_start + content_match.end()
    return content_match, abs_start, abs_end, zone


def process_reading(html_path, yaml_path, section_name, skip_bold=False, dry_run=False):
    """Traite une section (biblicalReading ou patristicReading) d'un fichier YAML."""
    yaml_name = os.path.basename(yaml_path)
    label = section_name

    with open(html_path, 'r', encoding='utf-8') as f:
        html_content = f.read()
    with open(yaml_path, 'r', encoding='utf-8') as f:
        yaml_content = f.read()

    paragraphs = extract_paragraphs(html_content, skip_bold=skip_bold)

    if len(paragraphs) <= 1:
        return yaml_content, False

    result = find_content_in_section(yaml_content, section_name)
    if not result:
        zone_match = re.search(rf'^  {section_name}:', yaml_content, re.MULTILINE)
        if zone_match:
            # Section existe mais content pas en format "..."
            section_start = zone_match.start()
            next_section = re.search(r'^  \w+:', yaml_content[section_start + 1:], re.MULTILINE)
            section_end = (section_start + 1 + next_section.start()) if next_section else len(yaml_content)
            zone = yaml_content[section_start:section_end]
            if re.search(r'content:\s*\|-', zone):
                print(f"  {yaml_name} [{label}]: déjà en format bloc, ignoré")
            else:
                print(f"  {yaml_name} [{label}]: content non trouvé")
        else:
            print(f"  {yaml_name} [{label}]: section non trouvée")
        return yaml_content, False

    content_match, abs_start, abs_end, zone = result
    indent = content_match.group(1)
    yaml_text = content_match.group(2).replace('\\"', '"')

    if "\n" in yaml_text:
        print(f"  {yaml_name} [{label}]: contient déjà des sauts de ligne, ignoré")
        return yaml_content, False

    # Trouver les positions de coupure
    split_positions = []
    for i in range(1, len(paragraphs)):
        prev_words = paragraphs[i - 1].split()
        context = prev_words[-WORD_CONTEXT:] if len(prev_words) >= WORD_CONTEXT else prev_words

        pos = find_split_position(yaml_text, context)
        if pos == -1:
            print(f"  {yaml_name} [{label}]: ATTENTION - contexte non trouvé pour §{i+1}: "
                  f"'{' '.join(context)}'")
            continue
        split_positions.append(pos)

    if not split_positions:
        return yaml_content, False

    # Insérer les sauts de ligne (de la fin vers le début)
    split_positions.sort(reverse=True)
    new_text = yaml_text
    for pos in split_positions:
        new_text = new_text[:pos] + "\n" + new_text[pos:]

    # Construire le bloc YAML
    lines = new_text.split("\n")
    block_lines = [f"{indent}content: |-"]
    for line in lines:
        block_lines.append(f"{indent}  {line}")
    block_content = "\n".join(block_lines)

    new_yaml = yaml_content[:abs_start] + block_content + yaml_content[abs_end:]

    if dry_run:
        print(f"  {yaml_name} [{label}]: {len(split_positions)} saut(s) de ligne à insérer")
        for j, line in enumerate(lines):
            preview = line[:100] + ("..." if len(line) > 100 else "")
            print(f"    §{j+1}: {preview}")
        return new_yaml, True

    print(f"  {yaml_name} [{label}]: {len(split_positions)} saut(s) de ligne inséré(s)")
    return new_yaml, True


def process_file(biblical_html, patristic_html, yaml_path, dry_run=False):
    """Traite les deux lectures (biblique et patristique) d'un fichier YAML."""
    modified = False

    with open(yaml_path, 'r', encoding='utf-8') as f:
        yaml_content = f.read()

    # Lecture biblique
    if biblical_html and os.path.exists(biblical_html):
        with open(biblical_html, 'r', encoding='utf-8') as f:
            html_content = f.read()
        paragraphs = extract_paragraphs(html_content)
        if len(paragraphs) > 1:
            result = find_content_in_section(yaml_content, 'biblicalReading')
            if result:
                new_yaml, changed = process_reading_from_content(
                    yaml_content, html_content, 'biblicalReading',
                    os.path.basename(yaml_path), dry_run=dry_run)
                if changed:
                    yaml_content = new_yaml
                    modified = True

    # Lecture patristique
    if patristic_html and os.path.exists(patristic_html):
        with open(patristic_html, 'r', encoding='utf-8') as f:
            html_content = f.read()
        paragraphs = extract_paragraphs(html_content, skip_bold=True)
        if len(paragraphs) > 1:
            result = find_content_in_section(yaml_content, 'patristicReading')
            if result:
                new_yaml, changed = process_reading_from_content(
                    yaml_content, html_content, 'patristicReading',
                    os.path.basename(yaml_path), skip_bold=True, dry_run=dry_run)
                if changed:
                    yaml_content = new_yaml
                    modified = True

    if modified and not dry_run:
        with open(yaml_path, 'w', encoding='utf-8') as f:
            f.write(yaml_content)

    return modified


def process_reading_from_content(yaml_content, html_content, section_name,
                                  yaml_name, skip_bold=False, dry_run=False):
    """Traite une section à partir du contenu déjà chargé."""
    label = section_name

    paragraphs = extract_paragraphs(html_content, skip_bold=skip_bold)

    if len(paragraphs) <= 1:
        return yaml_content, False

    result = find_content_in_section(yaml_content, section_name)
    if not result:
        section_match = re.search(rf'^  {section_name}:', yaml_content, re.MULTILINE)
        if section_match:
            section_start = section_match.start()
            next_section = re.search(r'^  \w+:', yaml_content[section_start + 1:], re.MULTILINE)
            section_end = (section_start + 1 + next_section.start()) if next_section else len(yaml_content)
            zone = yaml_content[section_start:section_end]
            if re.search(r'content:\s*\|-', zone):
                print(f"  {yaml_name} [{label}]: déjà en format bloc, ignoré")
            else:
                print(f"  {yaml_name} [{label}]: content non trouvé")
        else:
            print(f"  {yaml_name} [{label}]: section non trouvée")
        return yaml_content, False

    content_match, abs_start, abs_end, zone = result
    indent = content_match.group(1)
    yaml_text = content_match.group(2).replace('\\"', '"')

    if "\n" in yaml_text:
        print(f"  {yaml_name} [{label}]: contient déjà des sauts de ligne, ignoré")
        return yaml_content, False

    split_positions = []
    for i in range(1, len(paragraphs)):
        prev_words = paragraphs[i - 1].split()
        context = prev_words[-WORD_CONTEXT:] if len(prev_words) >= WORD_CONTEXT else prev_words

        pos = find_split_position(yaml_text, context)
        if pos == -1:
            print(f"  {yaml_name} [{label}]: ATTENTION - contexte non trouvé pour §{i+1}: "
                  f"'{' '.join(context)}'")
            continue
        split_positions.append(pos)

    if not split_positions:
        return yaml_content, False

    split_positions.sort(reverse=True)
    new_text = yaml_text
    for pos in split_positions:
        new_text = new_text[:pos] + "\n" + new_text[pos:]

    lines = new_text.split("\n")
    block_lines = [f"{indent}content: |-"]
    for line in lines:
        block_lines.append(f"{indent}  {line}")
    block_content = "\n".join(block_lines)

    new_yaml = yaml_content[:abs_start] + block_content + yaml_content[abs_end:]

    if dry_run:
        print(f"  {yaml_name} [{label}]: {len(split_positions)} saut(s) de ligne à insérer")
        for j, line in enumerate(lines):
            preview = line[:100] + ("..." if len(line) > 100 else "")
            print(f"    §{j+1}: {preview}")

    else:
        print(f"  {yaml_name} [{label}]: {len(split_positions)} saut(s) de ligne inséré(s)")

    return new_yaml, True


def main():
    parser = argparse.ArgumentParser(
        description="Synchronise les paragraphes HTML vers YAML"
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Afficher les changements sans modifier les fichiers")
    parser.add_argument("--file", type=str, default=None,
                        help="Traiter un seul fichier (ex: 10_2)")
    parser.add_argument("--prefix", type=str, default=None,
                        help="Traiter un seul préfixe (1=advent, 2=christmas, 3=ot, 4=lent, 5=easter)")
    parser.add_argument("--biblical-only", action="store_true",
                        help="Traiter uniquement les lectures bibliques")
    parser.add_argument("--patristic-only", action="store_true",
                        help="Traiter uniquement les lectures patristiques")
    args = parser.parse_args()

    if not os.path.isdir(BIBLICAL_HTML_DIR):
        print(f"Répertoire HTML biblique non trouvé: {BIBLICAL_HTML_DIR}")
        return
    if not os.path.isdir(PATRISTIC_HTML_DIR):
        print(f"Répertoire HTML patristique non trouvé: {PATRISTIC_HTML_DIR}")
        return

    do_biblical = not args.patristic_only
    do_patristic = not args.biblical_only

    prefixes = {args.prefix: PREFIX_MAP[args.prefix]} if args.prefix else PREFIX_MAP

    total_processed = 0
    total_modified = 0

    for html_prefix, (yaml_prefix, yaml_subdir) in sorted(prefixes.items()):
        yaml_dir = os.path.join(YAML_BASE_DIR, yaml_subdir)
        if not os.path.isdir(yaml_dir):
            print(f"Répertoire YAML non trouvé: {yaml_dir}")
            continue

        print(f"\n=== Préfixe {html_prefix} ({yaml_prefix}) ===")

        if args.file:
            yaml_path = os.path.join(yaml_dir, f"{yaml_prefix}_{args.file}.yaml")
            if not os.path.exists(yaml_path):
                print(f"Fichier YAML non trouvé: {yaml_path}")
                continue
            biblical_html = os.path.join(BIBLICAL_HTML_DIR, f"lecture_{html_prefix}_{args.file}.html") if do_biblical else None
            patristic_html = os.path.join(PATRISTIC_HTML_DIR, f"patristique_{html_prefix}_{args.file}.html") if do_patristic else None
            process_file(biblical_html, patristic_html, yaml_path, dry_run=args.dry_run)
            continue

        yaml_files = sorted(glob.glob(os.path.join(yaml_dir, f"{yaml_prefix}_*.yaml")))
        processed = 0
        modified = 0

        for yaml_path in yaml_files:
            basename = os.path.basename(yaml_path)
            match = re.match(rf'{yaml_prefix}_(.+)\.yaml', basename)
            if not match:
                continue
            xy = match.group(1)
            biblical_html = os.path.join(BIBLICAL_HTML_DIR, f"lecture_{html_prefix}_{xy}.html") if do_biblical else None
            patristic_html = os.path.join(PATRISTIC_HTML_DIR, f"patristique_{html_prefix}_{xy}.html") if do_patristic else None

            processed += 1
            if process_file(biblical_html, patristic_html, yaml_path, dry_run=args.dry_run):
                modified += 1

        print(f"  {yaml_prefix}: {processed} fichiers traités, {modified} modifiés")
        total_processed += processed
        total_modified += modified

    print(f"\nTotal: {total_processed} fichiers traités, {total_modified} modifiés")


if __name__ == "__main__":
    main()
