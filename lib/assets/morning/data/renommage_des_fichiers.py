import os
import re

# Mapping pour les fichiers antienne_x_y_z.json
x_mapping = {
    "1": "ADVENT_FERIALE",
    "2": "CHRISTMAS_FERIALE",
    "3": "OT",
    "4": "LENT_FERIALE",
    "5": "PT"
}

# Parcours des fichiers dans le répertoire courant
for filename in os.listdir('.'):
    if not filename.endswith('.json'):
        continue

    original_filename = filename

    # Règle 1 : antienne_x_y_z.json → morning_TYPE_y_z.json
    match1 = re.match(r'antienne_(\d+)_(\d+)_(\d+)\.json$', filename)
    if match1:
        x, y, z = match1.groups()
        if x in x_mapping:
            new_filename = f"morning_{x_mapping[x]}_{y}_{z}.json"
            os.rename(filename, new_filename)
            print(f"Renamed (Rule 1): {filename} -> {new_filename}")
            filename = new_filename

    # Règle 2 : x_y_z.json → x_SUNDAY_y.json si z == 0
    name_part = filename[:-5]  # retire ".json"
    parts = name_part.rsplit('_', 2)
    if len(parts) == 3:
        x, y, z = parts
        if z == '0':
            new_filename = f"{x}_SUNDAY_{y}.json"
            os.rename(filename, new_filename)
            print(f"Renamed (Rule 2): {filename} -> {new_filename}")
            filename = new_filename

    # Règle 3 : remplacer FERIALE_SUNDAY par SUNDAY
    if 'FERIALE_SUNDAY' in filename:
        new_filename = filename.replace('FERIALE_SUNDAY', 'SUNDAY')
        os.rename(filename, new_filename)
        print(f"Renamed (Rule 3): {filename} -> {new_filename}")
        filename = new_filename

    # Règle 4 : x_FERIALE_SUNDAY_y.json → x_SUNDAY_y.json
    match4 = re.match(r'^(.*)_FERIALE_SUNDAY_(\d+)\.json$', filename)
    if match4:
        x, y = match4.groups()
        new_filename = f"{x}_SUNDAY_{y}.json"
        os.rename(filename, new_filename)
        print(f"Renamed (Rule 4): {filename} -> {new_filename}")
