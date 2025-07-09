import os
import json
import re

# Fonction pour extraire les données du HTML
def extraire_infos_html(html_content):
    # Extraire MorningReadingRef entre <p class="ref">( ... )</p>
    ref_match = re.search(r'<p class="ref">\((.*?)\)</p>', html_content, re.DOTALL)
    morning_ref = ref_match.group(1).strip() if ref_match else ""

    # Extraire morningReading depuis le premier <p> sans attribut class
    p_tags = re.findall(r'<p>(.*?)</p>', html_content, re.DOTALL)
    morning_reading = p_tags[0].strip() if p_tags else ""

    return morning_ref, morning_reading

# Répertoire courant
folder = "."

# Parcours des fichiers capitule_5_z.html pour z de 0 à 6
for z in range(7):
    html_filename = f"capitule_5_{z}.html"
    html_path = os.path.join(folder, html_filename)

    if not os.path.exists(html_path):
        print(f"Fichier HTML manquant : {html_filename}")
        continue

    # Lecture du HTML
    with open(html_path, "r", encoding="utf-8") as f:
        html_content = f.read()

    morning_ref, morning_reading = extraire_infos_html(html_content)

    # Pour chaque y de 2 à 5, mettre à jour antienne_5_y_z.json
    for y in range(2, 6):
        json_filename = f"antienne_5_{y}_{z}.json"
        json_path = os.path.join(folder, json_filename)

        if not os.path.exists(json_path):
            print(f"Fichier JSON manquant : {json_filename}")
            continue

        # Lecture et mise à jour du JSON
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Ajout des champs à la racine
        data["MorningReadingRef"] = morning_ref
        data["morningReading"] = morning_reading
        # Sauvegarde du fichier JSON mis à jour
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"Mis à jour : {json_filename}")
