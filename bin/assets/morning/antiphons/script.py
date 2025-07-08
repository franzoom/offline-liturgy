import os
import re
import json
from collections import defaultdict

x_to_keys = {
    "inv": ("invitatoryAntiphon1", "invitatoryAntiphon2"),
    "1": ("morningPsalm1Antiphon1", "morningPsalm1Antiphon2"),
    "2": ("morningPsalm2Antiphon1", "morningPsalm2Antiphon2"),
    "ct": ("morningPsalm3Antiphon1", "morningPsalm3Antiphon2"),
    "ev": ("morningEvangelicAntiphon", None),
    "evA": ("morningEvangelicAntiphonA", None),
    "evB": ("morningEvangelicAntiphonB", None),
    "evC": ("morningEvangelicAntiphonC", None),
}

data_by_base = defaultdict(dict)

for filename in os.listdir():
    if filename.endswith(".html"):
        match = re.match(r"(.+?)_([^_ ]+)\s*\d*\.html$", filename)
        if not match:
            continue

        base = match.group(1)
        x = match.group(2)

        with open(filename, "r", encoding="utf-8") as f:
            text = f.read()

        text = re.sub(r"&lt;[^&gt;]+&gt;", "", text)

        ant1_match = re.search(r"Ant 1\.\s*(.*?)(?=Ant 2\.|$)", text, re.DOTALL)
        ant2_match = re.search(r"Ant 2\.\s*(.*?)(?=$)", text, re.DOTALL)

        key1, key2 = x_to_keys.get(x, (None, None))
        if key1 and ant1_match:
            data_by_base[base][key1] = ant1_match.group(1).strip()
        if key2 and ant2_match:
            data_by_base[base][key2] = ant2_match.group(1).strip()

for base, content in data_by_base.items():
    json_filename = f"{base}.json"
    with open(json_filename, "w", encoding="utf-8") as f:
        json.dump(content, f, ensure_ascii=False, indent=2)
    print(f"Fichier JSON écrit : {json_filename}")
