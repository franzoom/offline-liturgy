import os
import json

# Nouvelles clés à ajouter
new_keys = {
    "invitatoryAntiphon1": "Le Seigneur est vraiment ressuscité, alléluia !",
    "invitatoryAntiphon2": "Nous te louons, splendeur du Père, Jésus, Fils de Dieu."
}

# Parcours des fichiers dans le répertoire courant
for filename in os.listdir():
    if filename.startswith("antienne_5") and filename.endswith(".json"):
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                original_data = json.load(f)

            # Fusion des nouvelles clés avec les données existantes
            updated_data = {**new_keys, **original_data}

            # Écriture dans le fichier
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(updated_data, f, ensure_ascii=False, indent=2)

            print(f"Clés ajoutées à : {filename}")
        except Exception as e:
            print(f"Erreur avec le fichier {filename} : {e}")
