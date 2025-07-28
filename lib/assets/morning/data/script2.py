import os
import json
import re

# Parcourir tous les fichiers JSON du répertoire courant
for filename in os.listdir('.'):
    if filename.endswith('.json'):
        with open(filename, 'r', encoding='utf-8') as json_file:
            data = json.load(json_file)

        # Nettoyer la clé 'morningOration' si elle existe
        if 'morningOration' in data and isinstance(data['morningOration'], str):
            cleaned = data['morningOration'].replace('\n', ' ')
            cleaned = re.sub(r'\s{2,}', ' ', cleaned)
            data['morningOration'] = cleaned.strip()

            # Sauvegarder les modifications
            with open(filename, 'w', encoding='utf-8') as json_file:
                json.dump(data, json_file, ensure_ascii=False, indent=4)

            print(f"✅ Clé 'morningOration' nettoyée dans {filename}")
