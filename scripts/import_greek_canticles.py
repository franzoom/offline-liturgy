#!/usr/bin/env python3
"""
import_greek_canticles.py — Generates assets/psalms/greek/NT_1.yaml,
NT_2.yaml and NT_3.yaml (Magnificat, Benedictus, Nunc dimittis in Greek).

Source: SBLGNT (Society of Biblical Literature Greek New Testament),
copyright 2010 Society of Biblical Literature and Logos Bible Software,
CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Fetched from the
canonical GitHub mirror of the SBLGNT data files:
https://raw.githubusercontent.com/Faithlife/SBLGNT/master/data/sblgnt/text/Luke.txt

Modifications made to the published text (CC BY 4.0 requires noting these):
  1. SBLGNT's own critical-apparatus substitution markers (U+2E00-U+2E05:
     ⸀ ⸁ ⸂ ⸃ ⸄ ⸅) are stripped. These point to textual-variant notes in
     SBLGNT's printed apparatus; they are not part of the running text.
  2. For the Magnificat only, Luke 1:46 is merged into the verse printed
     as "{47}", matching the verse grouping already used by this app's
     French (usual_texts.dart) and Latin (assets/psalms/latin/NT_1.yaml)
     Magnificat texts. Verse 46 opens with the narrative tag "Καὶ εἶπεν
     Μαριάμ·" ("And Mary said:"), set off by the source's own middle dot
     (·); that narrative tag is dropped, as it is in the French and Latin
     texts, keeping only "Μεγαλύνει ἡ ψυχή μου τὸν κύριον" — the start of
     the canticle itself.
  No other changes: wording, word order and all diacritics/accents are
  exactly as published.

Each canticle verse becomes its own paragraph (one line, {N} marker, blank
line before the next), matching the Latin texts' layout. This script does
not attempt to reproduce the French text's internal hemistich line-breaks:
unlike the Hebrew psalms (see import_hebrew_psalms.py), only verse-level
correspondence with French/Latin was required for the Greek canticles.

Usage:
    python3 scripts/import_greek_canticles.py
    (run from the root of the offline-liturgy project; requires network
    access to fetch the source text)
"""

import re
import sys
import urllib.request
from pathlib import Path

SOURCE_URL = (
    "https://raw.githubusercontent.com/Faithlife/SBLGNT/master/"
    "data/sblgnt/text/Luke.txt"
)

OUTPUT_DIR = Path("assets/psalms/greek")

# SBLGNT's own critical-apparatus substitution markers (not part of the text).
APPARATUS_MARKS = re.compile("[⸀-⸅]")

# Narrative tags that introduce a canticle but aren't part of it, dropped the
# same way the French/Latin texts drop them. Each ends at the source's own
# middle dot (·), which marks where the quoted speech begins.
NARRATIVE_INTROS = {
    (1, 46): "Καὶ εἶπεν Μαριάμ·",
}

# code -> (title, biblicalReference, shortReference, verse groups)
# Each verse group is (displayed_number, [source_verse_numbers]).
CANTICLES = {
    "NT_1": (
        "Magnificat",
        "Lc 1, 46-55",
        "NT 1",
        1,
        [(47, [46, 47])] + [(n, [n]) for n in range(48, 56)],
    ),
    "NT_2": (
        "Benedictus",
        "Lc 1, 68-79",
        "NT 2",
        1,
        [(n, [n]) for n in range(68, 80)],
    ),
    "NT_3": (
        "Nunc dimittis",
        "Lc 2, 29-32",
        "NT 3",
        2,
        [(n, [n]) for n in range(29, 33)],
    ),
}


def fetch_source_verses() -> dict[tuple[int, int], str]:
    """Downloads Luke.txt and returns {(chapter, verse): text}."""
    with urllib.request.urlopen(SOURCE_URL) as response:
        raw = response.read().decode("utf-8")

    verses: dict[tuple[int, int], str] = {}
    pattern = re.compile(r"^Luke (\d+):(\d+)\t(.+)$")
    for line in raw.splitlines():
        match = pattern.match(line)
        if not match:
            continue
        chapter, verse, text = match.groups()
        key = (int(chapter), int(verse))
        cleaned = APPARATUS_MARKS.sub("", text).strip()
        intro = NARRATIVE_INTROS.get(key)
        if intro:
            if not cleaned.startswith(intro):
                sys.exit(f"Expected Luke {key[0]}:{key[1]} to start with {intro!r}")
            cleaned = cleaned[len(intro):].strip()
        verses[key] = cleaned
    return verses


def build_content(chapter: int, groups: list[tuple[int, list[int]]],
                   source_verses: dict[tuple[int, int], str]) -> str:
    paragraphs = []
    for displayed_number, source_numbers in groups:
        texts = []
        for n in source_numbers:
            key = (chapter, n)
            if key not in source_verses:
                sys.exit(f"Missing source verse Luke {chapter}:{n}")
            texts.append(source_verses[key])
        paragraphs.append(f"{{{displayed_number}}}" + " ".join(texts))
    return "\n\n".join(paragraphs)


def write_canticle(code: str, title: str, biblical_reference: str,
                    short_reference: str, content: str) -> None:
    indented_content = "\n".join(
        ("  " + line if line else "") for line in content.split("\n")
    )
    yaml_text = (
        f"title: {title}\n"
        "subtitle: null\n"
        "commentary: null\n"
        f"biblicalReference: {biblical_reference}\n"
        f"shortReference: {short_reference}\n"
        "content: |-\n"
        f"{indented_content}\n"
    )
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / f"{code}.yaml"
    path.write_text(yaml_text, encoding="utf-8")
    print(f"wrote {path}")


def main() -> None:
    source_verses = fetch_source_verses()
    for code, (title, biblical_reference, short_reference, chapter, groups) in CANTICLES.items():
        content = build_content(chapter, groups, source_verses)
        write_canticle(code, title, biblical_reference, short_reference, content)


if __name__ == "__main__":
    main()
