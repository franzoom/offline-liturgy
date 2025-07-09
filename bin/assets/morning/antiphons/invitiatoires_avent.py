import os
import re

# Expression régulière pour identifier les fichiers antienne_3_x_y.json
pattern = re.compile(r'antienne_3_(\d+)_(\d+)\.json')

# Parcours des fichiers dans le répertoire courant
for filename in os.listdir():
    match = pattern.match(filename)
    if match:
        x = int(match.group(1))
        y = int(match.group(2))
        if x >= 5 and y != 0:
            try:
                os.remove(filename)
                print(f"Supprimé : {filename}")
            except Exception as e:
                print(f"Erreur lors de la suppression de {filename} : {e}")
