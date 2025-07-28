import os
import re

# Parcours des fichiers dans le répertoire courant
for filename in os.listdir('.'):
    if filename.endswith('.json'):
        # Cherche les fichiers contenant 'FERIALE_SUNDAY'
        new_filename = re.sub(r'(.*)_FERIALE_SUNDAY_(\d+)\.json$', r'\1_SUNDAY_\2.json', filename)
        if new_filename != filename:
            os.rename(filename, new_filename)
            print(f"Renamed: {filename} -> {new_filename}")
