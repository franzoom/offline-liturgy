#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import re
import unicodedata
from pathlib import Path

def normalize_key(text):
    """
    Génère une clé normalisée à partir du titre de l'hymne.
    - Supprime les accents et majuscules
    - Remplace espaces et apostrophes par des tirets
    - Remplace œ par oe et æ par ae
    - Supprime les caractères spéciaux
    """
    if not text:
        return ""
    
    # Extraire la première ligne (avant <br>)
    first_line = text.split('<br>')[0].strip()
    
    # Nettoyer les balises HTML
    first_line = re.sub(r'<[^>]+>', '', first_line)
    
    # Remplacements spéciaux
    first_line = first_line.replace('œ', 'oe').replace('Œ', 'oe')
    first_line = first_line.replace('æ', 'ae').replace('Æ', 'ae')
    
    # Supprimer les accents
    first_line = unicodedata.normalize('NFD', first_line)
    first_line = ''.join(c for c in first_line if unicodedata.category(c) != 'Mn')
    
    # Convertir en minuscules
    first_line = first_line.lower()
    
    # Remplacer espaces et apostrophes par des tirets
    first_line = re.sub(r'[\s\']+', '-', first_line)
    
    # Supprimer les caractères spéciaux sauf tirets
    first_line = re.sub(r'[^a-z0-9\-]', '', first_line)
    
    # Supprimer les tirets multiples et en début/fin
    first_line = re.sub(r'-+', '-', first_line).strip('-')
    
    return first_line

def extract_title(text):
    """Extrait le titre (première ligne) de l'hymne."""
    if not text:
        return ""
    
    first_line = text.split('<br>')[0].strip()
    # Nettoyer les balises HTML
    first_line = re.sub(r'<[^>]+>', '', first_line)
    return first_line.strip()

def load_existing_library():
    """Charge la librairie existante d'hymnes."""
    library_path = Path('./libraries/hymns_library.dart')
    
    if not library_path.exists():
        return {}
    
    try:
        with open(library_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extraire les hymnes existantes avec une regex simple
        hymns = {}
        pattern = r'"([^"]+)":\s*Hymns\(\s*title:\s*"([^"]*)",\s*author:\s*"([^"]*)",\s*content:\s*"""([^"]*(?:"[^"]*)*?)"""\s*\)'
        
        matches = re.finditer(pattern, content, re.DOTALL)
        for match in matches:
            key, title, author, hymn_content = match.groups()
            hymns[key] = {
                'title': title,
                'author': author,
                'content': hymn_content
            }
        
        print(f"Librairie chargée avec {len(hymns)} hymnes existantes.")
        return hymns
        
    except Exception as e:
        print(f"Erreur lors du chargement de la librairie : {e}")
        return {}

def save_library(hymns):
    """Sauvegarde la librairie d'hymnes au format Dart."""
    library_path = Path('./libraries/hymns_library.dart')
    library_path.parent.mkdir(exist_ok=True)
    
    content = '''import "../../../classes/hymns_class.dart";

final Map<String, Hymns> hymnsLibraryContent = {
'''
    
    for key, hymn in hymns.items():
        # Échapper les guillemets dans le contenu
        escaped_content = hymn['content'].replace('\\', '\\\\').replace('"', '\\"')
        escaped_title = hymn['title'].replace('\\', '\\\\').replace('"', '\\"')
        escaped_author = hymn['author'].replace('\\', '\\\\').replace('"', '\\"')
        
        content += f'  "{key}": Hymns(\n'
        content += f'      title: "{escaped_title}",\n'
        content += f'      author: "{escaped_author}",\n'
        content += f'      content:\n'
        content += f'          """{escaped_content}"""),\n'
    
    content += '};\n'
    
    with open(library_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Librairie sauvegardée avec {len(hymns)} hymnes.")

def process_json_files():
    """Traite tous les fichiers JSON dans le répertoire calendar_data/days/."""
    
    calendar_dir = Path('./calendar_data/days')
    if not calendar_dir.exists():
        print(f"Le répertoire {calendar_dir} n'existe pas.")
        return
    
    # Charger la librairie existante
    hymns_library = load_existing_library()
    
    json_files = list(calendar_dir.glob('*.json'))
    print(f"Traitement de {len(json_files)} fichiers JSON...")
    
    new_hymns_count = 0
    updated_files_count = 0
    
    for json_file in json_files:
        try:
            # Charger le fichier JSON
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            file_modified = False
            
            # Parcourir toutes les clés du JSON
            def process_dict(obj, path=""):
                nonlocal file_modified, new_hymns_count
                
                if isinstance(obj, dict):
                    for key, value in list(obj.items()):
                        if key.endswith('Hymn') and isinstance(value, str) and value.strip():
                            # C'est une hymne !
                            print(f"Traitement de l'hymne : {path}.{key}")
                            
                            # Générer la clé normalisée
                            hymn_key = normalize_key(value)
                            
                            if not hymn_key:
                                print(f"  ⚠️  Impossible de générer une clé pour cette hymne")
                                continue
                            
                            # Vérifier si l'hymne existe déjà
                            if hymn_key not in hymns_library:
                                # Nouvelle hymne !
                                title = extract_title(value)
                                hymns_library[hymn_key] = {
                                    'title': title,
                                    'author': '',
                                    'content': value
                                }
                                new_hymns_count += 1
                                print(f"  ✅ Nouvelle hymne ajoutée : '{title}' -> {hymn_key}")
                            else:
                                print(f"  📚 Hymne existante : {hymn_key}")
                            
                            # Remplacer le contenu par la clé
                            obj[key] = hymn_key
                            file_modified = True
                        
                        elif isinstance(value, (dict, list)):
                            process_dict(value, f"{path}.{key}" if path else key)
                
                elif isinstance(obj, list):
                    for i, item in enumerate(obj):
                        if isinstance(item, (dict, list)):
                            process_dict(item, f"{path}[{i}]")
            
            # Traiter le fichier
            process_dict(data)
            
            # Sauvegarder si modifié
            if file_modified:
                with open(json_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                updated_files_count += 1
                print(f"✅ Fichier mis à jour : {json_file.name}")
        
        except Exception as e:
            print(f"❌ Erreur lors du traitement de {json_file.name} : {e}")
    
    # Sauvegarder la librairie mise à jour
    if new_hymns_count > 0:
        save_library(hymns_library)
    
    print(f"\n📊 Résumé :")
    print(f"   - {new_hymns_count} nouvelles hymnes ajoutées")
    print(f"   - {updated_files_count} fichiers JSON mis à jour")
    print(f"   - {len(hymns_library)} hymnes au total dans la librairie")

if __name__ == "__main__":
    process_json_files()