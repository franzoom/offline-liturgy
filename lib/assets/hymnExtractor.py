import os
import json
import re
import unicodedata

def normalize_text(text):
    """Enlève les accents et normalise le texte pour créer un identifiant."""
    # Convertit en minuscules
    text = text.lower()
    # Remplace les caractères spéciaux avant de normaliser
    text = text.replace('œ', 'oe')  # œ -> oe
    text = text.replace("'", '-')   # apostrophes -> tirets
    text = text.replace("'", '-')   # apostrophes courbes -> tirets
    # Enlève les accents
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    # Garde seulement lettres, chiffres, espaces et tirets
    text = re.sub(r'[^a-z0-9\s-]', '', text)
    # Remplace les espaces par des tirets
    text = re.sub(r'\s+', '-', text)
    # Évite les tirets multiples
    text = re.sub(r'-+', '-', text)
    # Enlève les tirets en début/fin
    text = text.strip('-')
    
    return text

def extract_title(content):
    """Extrait le titre de la première ligne avant <br>."""
    # Cherche le premier texte après une balise ouvrante et avant <br>
    match = re.search(r'>([^<]+?)(?:<br>|$)', content)
    if match:
        return match.group(1).strip()
    return "hymne-sans-titre"

def read_calendar_files(dir_path):
    """Lit tous les fichiers JSON du répertoire et extrait les hymnes."""
    hymns = {}  # Dictionnaire pour éviter les doublons
    
    if not os.path.exists(dir_path):
        print(f"Le répertoire {dir_path} n'existe pas")
        return hymns
    
    json_files = [f for f in os.listdir(dir_path) if f.endswith('.json')]
    
    for file in json_files:
        file_path = os.path.join(dir_path, file)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Parcourt toutes les clés de l'objet JSON
            for key, value in data.items():
                if key.endswith('Hymn') and value:
                    hymn_content = value
                    first_line = extract_title(hymn_content)
                    normalized_title = normalize_text(first_line)
                    
                    # Évite les doublons en utilisant le titre normalisé comme clé
                    if normalized_title not in hymns:
                        hymns[normalized_title] = {
                            'title': first_line,
                            'content': hymn_content
                        }
                        print(f"Trouvé: {first_line} -> {normalized_title}")
                    else:
                        print(f"Doublon ignoré: {first_line} -> {normalized_title}")
        
        except json.JSONDecodeError as e:
            print(f"Erreur JSON dans {file}: {e}")
        except Exception as e:
            print(f"Erreur lors de la lecture de {file}: {e}")
    
    return hymns

def read_existing_hymns(library_path):
    """Lit le fichier existant pour connaître les hymnes déjà présentes."""
    existing_hymns = set()
    
    if not os.path.exists(library_path):
        return existing_hymns
    
    try:
        with open(library_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extrait tous les identifiants d'hymnes existants
        matches = re.findall(r'"([^"]+)"\s*:\s*Hymns\(', content)
        existing_hymns = set(matches)
        
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier existant: {e}")
    
    return existing_hymns

def generate_dart_code(hymns):
    """Génère le code Dart pour les hymnes."""
    dart_code = ''
    
    for key, hymn in hymns.items():
        # Échappe les guillemets dans le contenu
        title_escaped = hymn['title'].replace('"', '\\"')
        content_escaped = hymn['content'].replace('"', '\\"').replace('\n', '\\n')
        
        dart_code += f'"{key}": Hymns(\n'
        dart_code += f'title: "{title_escaped}",\n'
        dart_code += f'author: "",\n'
        dart_code += f'content:\n'
        dart_code += f'"{content_escaped}",\n'
        dart_code += ' ),\n'
    
    return dart_code

def update_json_files(calendar_dir, hymn_keys):
    """Remplace le contenu des hymnes dans les fichiers JSON par leurs clés."""
    json_files = [f for f in os.listdir(calendar_dir) if f.endswith('.json')]
    files_updated = 0
    
    for file in json_files:
        file_path = os.path.join(calendar_dir, file)
        modified = False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Parcourt toutes les clés de l'objet JSON
            for key in list(data.keys()):  # list() pour éviter les modifications pendant l'itération
                if key.endswith('Hymn') and data[key]:
                    hymn_content = data[key]
                    first_line = extract_title(hymn_content)
                    normalized_title = normalize_text(first_line)
                    
                    # Remplace le contenu par la clé si elle existe dans hymn_keys
                    if normalized_title in hymn_keys:
                        data[key] = normalized_title
                        modified = True
                        print(f"  {key} -> {normalized_title}")
            
            # Sauvegarde le fichier s'il a été modifié
            if modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                files_updated += 1
                print(f"📝 Fichier {file} mis à jour")
        
        except Exception as e:
            print(f"Erreur lors de la mise à jour de {file}: {e}")
    
    return files_updated

def update_hymns_library(new_hymns, library_path):
    """Met à jour le fichier hymns_library.dart avec les nouvelles hymnes."""
    
    if not new_hymns:
        print("Aucune nouvelle hymne à ajouter.")
        return
    
    try:
        # Lit le fichier existant
        with open(library_path, 'r', encoding='utf-8') as f:
            existing_content = f.read()
        
        # Trouve la position où insérer les nouvelles hymnes
        # Cherche la dernière occurrence de " )," suivie de "}"
        last_hymn_pos = existing_content.rfind(' ),\n}')
        
        if last_hymn_pos == -1:
            print('Format du fichier hymns_library.dart non reconnu')
            return
        
        # Génère le code Dart pour les nouvelles hymnes
        new_dart_code = generate_dart_code(new_hymns)
        
        # Insère les nouvelles hymnes avant la fermeture du Map
        updated_content = (
            existing_content[:last_hymn_pos] + 
            ' ),\n' + 
            new_dart_code + 
            existing_content[last_hymn_pos + 4:]  # +4 pour " ),\n"
        )
        
        # Écrit le fichier mis à jour
        with open(library_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        
        print(f"\n✅ {len(new_hymns)} nouvelles hymnes ajoutées au fichier hymns_library.dart")
        
    except FileNotFoundError:
        print('Le fichier hymns_library.dart n\'existe pas')
    except Exception as e:
        print(f'Erreur lors de la mise à jour: {e}')

def main():
    """Script principal."""
    calendar_dir = './calendar_data/days'
    library_path = './hymns_library.dart'
    
    print('🔍 Recherche des hymnes dans les fichiers JSON...\n')
    
    # Lit les hymnes existantes
    existing_hymns = read_existing_hymns(library_path)
    print(f"📖 {len(existing_hymns)} hymnes déjà présentes dans la librairie")
    
    # Extrait les hymnes des fichiers JSON
    all_hymns = read_calendar_files(calendar_dir)
    
    if not all_hymns:
        print('Aucune hymne trouvée.')
        return
    
    # Filtre les hymnes qui ne sont pas déjà dans la librairie
    new_hymns = {k: v for k, v in all_hymns.items() if k not in existing_hymns}
    
    print(f"\n📚 {len(all_hymns)} hymnes trouvées au total")
    print(f"🆕 {len(new_hymns)} nouvelles hymnes à ajouter")
    
    if new_hymns:
        print('\n📝 Mise à jour du fichier hymns_library.dart...')
        update_hymns_library(new_hymns, library_path)
    else:
        print("\n✅ Toutes les hymnes sont déjà présentes dans la librairie")

if __name__ == "__main__":
    main()