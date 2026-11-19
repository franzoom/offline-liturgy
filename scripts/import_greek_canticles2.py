#!/usr/bin/env python3
"""
import_greek_canticles2.py — Builds assets/psalms/greek/NT_x.yaml for the 9
remaining New Testament canticles (NT_4-NT_12; NT_1-NT_3, the evangelic
canticles, were done in Phase 1 by import_greek_canticles.py). All 9 are
from canonical NT books, so — unlike the OT deuterocanon — there is no
missing-source question; this reuses the same SBLGNT source and
apparatus-stripping as import_greek_canticles.py.

Source: SBLGNT, CC BY 4.0, fetched from
https://raw.githubusercontent.com/Faithlife/SBLGNT/master/data/sblgnt/text/

## Chapter-crossing markers

NT_9 and NT_10 (both from Revelation) cross a chapter boundary mid-canticle
and mark it explicitly in the French content, e.g. "{4.11}" then "{5.9}"
then the bare "{10}" (still chapter 5) — same mechanism as OT_30 in
import_hebrew_canticles.py, but with "." instead of "," as the separator
(an inconsistency already present in the French source data, not
introduced here). This script tracks the "current chapter" the same way.

## No line-splitting

Unlike the Hebrew Psalter, no attempt is made to match the French text's
internal line count per verse: each verse becomes one paragraph, same
policy as the Phase 1 evangelic canticles (Greek has no equivalent to
Masoretic cantillation accents to break at, and this was not requested).

## The "R/" response marker

NT_9 and NT_10 are structured as responsorial canticles: an opening line
before the first verse marker gives the congregation's refrain (e.g. "R/
Puissance, honneur et gloire à l'Agneau de Dieu !") — this is a liturgical
paraphrase for responsorial use, not a Bible quotation, so it has no
Greek/Hebrew source and is dropped from the generated file entirely (the
Greek content starts directly at the first verse, same as every other
canticle). Where "R/" or "(R/)" appears inside a verse's own text, marking
where the congregation repeats the refrain, the literal marker "R/" (a
liturgical symbol, not language-specific) is kept, appended to that
verse's Greek paragraph.

Usage:
    python3 scripts/import_greek_canticles2.py [--write]
"""

import re
import sys
import unicodedata
import urllib.request
from pathlib import Path

SOURCE_BASE = "https://raw.githubusercontent.com/Faithlife/SBLGNT/master/data/sblgnt/text"
GREEK_DIR = Path("assets/psalms/greek")
PSALMS_DIR = Path("assets/psalms")

APPARATUS_MARKS = re.compile("[⸀-⸅]")
MARKER_RE = re.compile(r"\{([^}]*)\}")

# French biblicalReference book abbreviation -> SBLGNT file name.
BOOK_FILES = {
    "Ep": "Eph",
    "Ph": "Phil",
    "Col": "Col",
    "1Tm": "1Tim",
    "1P": "1Pet",
    "Ap": "Rev",
}

CANTICLES = ["NT_4", "NT_5", "NT_6", "NT_7", "NT_8", "NT_9", "NT_10", "NT_11", "NT_12"]

BIBREF_RE = re.compile(r"^(1?[A-Za-z]+)\s+(\d+),")

# Several Revelation verses open with a narrative "and X heard/sang, saying:"
# clause that the French never translates (same situation as the
# Magnificat's v46 in import_greek_canticles.py) — stripped here, verified
# against the fetched SBLGNT text for each.
NARRATIVE_PREFIXES = {
    ("Rev", 5, 9): "καὶ ᾄδουσιν ᾠδὴν καινὴν λέγοντες·",
    ("Rev", 5, 12): "λέγοντες φωνῇ μεγάλῃ·",
    ("Rev", 11, 17): "λέγοντες·",
    ("Rev", 12, 10): "Καὶ ἤκουσα φωνὴν μεγάλην ἐν τῷ οὐρανῷ λέγουσαν·",
    ("Rev", 15, 3): "καὶ ᾄδουσιν τὴν ᾠδὴν Μωϋσέως τοῦ δούλου τοῦ θεοῦ καὶ τὴν ᾠδὴν τοῦ ἀρνίου λέγοντες·",
    ("Rev", 19, 1): "Μετὰ ταῦτα ἤκουσα ὡς φωνὴν μεγάλην ὄχλου πολλοῦ ἐν τῷ οὐρανῷ λεγόντων·",
    ("Rev", 19, 5): "Καὶ φωνὴ ἀπὸ τοῦ θρόνου ἐξῆλθεν λέγουσα·",
    ("Rev", 19, 6): "καὶ ἤκουσα ὡς φωνὴν ὄχλου πολλοῦ καὶ ὡς φωνὴν ὑδάτων πολλῶν καὶ ὡς φωνὴν βροντῶν ἰσχυρῶν, λεγόντων·",
}

# Rev 12:12's second half ("Woe to the earth and sea...") isn't in the
# French, which ends the canticle on the call to rejoice — truncated here
# to match, keeping the "διὰ τοῦτο" ("therefore") the French does translate
# ("Soyez donc...").
TRUNCATE_AFTER = {
    ("Rev", 12, 12): "σκηνοῦντες.",
}

# Known SBLGNT/French divergences, kept as SBLGNT reads (not silently
# "corrected" to match French) and reported instead:
#   - Rev 5:10: SBLGNT has 3rd person "αὐτοὺς ... βασιλεύουσιν" ("them...
#     they reign"); the French follows a manuscript tradition with 1st
#     person ("nous... nous régnerons", "us... we will reign").
#   - Rev 15:3: SBLGNT reads "ὁ βασιλεὺς τῶν αἰώνων" ("king of the ages");
#     the French follows a variant "τῶν ἐθνῶν" ("king of the nations").


def fetch_book(file_name: str) -> dict:
    url = f"{SOURCE_BASE}/{file_name}.txt"
    with urllib.request.urlopen(url) as response:
        raw = response.read().decode("utf-8")
    verses = {}
    pattern = re.compile(rf"^{re.escape(file_name)} (\d+):(\d+)\t(.+)$")
    for line in raw.splitlines():
        m = pattern.match(line)
        if not m:
            continue
        ch, v, text = int(m.group(1)), int(m.group(2)), m.group(3)
        cleaned = APPARATUS_MARKS.sub("", text).strip()

        key = (file_name, ch, v)
        prefix = NARRATIVE_PREFIXES.get(key)
        if prefix:
            if not cleaned.startswith(prefix):
                sys.exit(f"Expected {file_name} {ch}:{v} to start with {prefix!r}, got {cleaned!r}")
            cleaned = cleaned[len(prefix):].strip()
        cutoff = TRUNCATE_AFTER.get(key)
        if cutoff:
            idx = cleaned.find(cutoff)
            if idx == -1:
                sys.exit(f"Expected {file_name} {ch}:{v} to contain {cutoff!r}")
            cleaned = cleaned[: idx + len(cutoff)]

        verses[(ch, v)] = cleaned
    return verses


def resolve_markers(markers, start_chapter):
    resolved = []
    current_chapter = start_chapter
    for marker in markers:
        sep = "." if "." in marker else ("," if "," in marker else None)
        if sep:
            ch_str, v_str = marker.split(sep)
            current_chapter = int(ch_str)
            resolved.append((marker, current_chapter, int(v_str)))
        else:
            resolved.append((marker, current_chapter, int(marker)))
    return resolved


# A standalone "R/ <text>" paragraph (its own refrain declaration, not a
# "repeat it here" cue) always starts its line with "R/" followed by
# whitespace (regular or the non-breaking space \xa0 French typography
# uses before punctuation) and more text, e.g. "R/ À la louange de sa
# gloire." It is never part of any verse, so it is excluded before
# scanning for a repeat-cue, to avoid misattributing it to a neighbour.
_STANDALONE_REFRAIN_RE = re.compile(r"^R/[ \t\xa0]+\S")


def verse_block_with_markers(content_block: str):
    """Returns {marker: concatenated_text_of_that_verse's lines} to scan
    for a R/ repeat-cue. A verse's span runs from its own {N} marker up to
    (but not past) the next {M} marker, carried across any blank lines in
    between: a verse can span more than one French paragraph (e.g. NT_6
    verse 20), so a blank line alone does not end it. Standalone "R/ ..."
    declaration lines are skipped (contribute to no verse)."""
    blocks = {}
    current = None
    for raw_line in content_block.split("\n"):
        stripped = raw_line.strip()
        marker = MARKER_RE.match(stripped)
        if marker:
            current = marker.group(1)
            blocks[current] = stripped
        elif _STANDALONE_REFRAIN_RE.match(stripped):
            continue
        elif current is not None:
            blocks[current] = blocks.get(current, "") + "\n" + stripped
    return blocks


def build_canticle(code, book_verses):
    path = PSALMS_DIR / f"{code}.yaml"
    text = path.read_text(encoding="utf-8")

    m_bibref = re.search(r"^biblicalReference:\s*(.+)$", text, re.M)
    bibref_raw = m_bibref.group(1).strip()
    bibref_match = BIBREF_RE.match(bibref_raw)
    book_abbr, start_chapter = bibref_match.group(1), int(bibref_match.group(2))
    file_name = BOOK_FILES[book_abbr]

    m_content = re.search(r"^content:\s*\|-\n(.*)", text, re.S | re.M)
    verse_block = m_content.group(1)
    markers = MARKER_RE.findall(verse_block)
    resolved = resolve_markers(markers, start_chapter)
    french_blocks = verse_block_with_markers(verse_block)

    flags = []
    for marker, ch, v in resolved:
        if (ch, v) not in book_verses[file_name]:
            flags.append(f"{book_abbr} {ch}:{v} (marker {{{marker}}}) not found in SBLGNT {file_name}")
    if flags:
        return None, flags

    paragraphs = []
    for marker, ch, v in resolved:
        greek_text = book_verses[file_name][(ch, v)]
        needs_response = bool(re.search(r"\(?R/\)?", french_blocks.get(marker, "")))
        line = f"{{{marker}}}{greek_text}"
        if needs_response:
            line += " R/"
        paragraphs.append(line)

    content = "\n\n".join(paragraphs)
    title = re.search(r"^title:\s*(.+)$", text, re.M).group(1).strip()
    yaml_text = (
        f"title: {title}\n"
        "subtitle: null\n"
        "commentary: null\n"
        f"biblicalReference: {bibref_raw}\n"
        f"shortReference: {code.replace('NT_', 'NT ')}\n"
        "content: |-\n"
        + "\n".join(("  " + line if line else "") for line in content.split("\n"))
        + "\n"
    )
    return yaml_text, []


def main():
    write = "--write" in sys.argv

    books_needed = set()
    for code in CANTICLES:
        bibref = re.search(r"^biblicalReference:\s*(.+)$",
                             (PSALMS_DIR / f"{code}.yaml").read_text(encoding="utf-8"), re.M).group(1).strip()
        book_abbr = BIBREF_RE.match(bibref).group(1)
        books_needed.add(BOOK_FILES[book_abbr])

    print(f"Fetching {len(books_needed)} SBLGNT books: {sorted(books_needed)}")
    book_verses = {name: fetch_book(name) for name in books_needed}

    results = {}
    for code in CANTICLES:
        yaml_text, flags = build_canticle(code, book_verses)
        results[code] = (yaml_text, flags)

    resolved = {c: y for c, (y, f) in results.items() if y}
    blocked = {c: f for c, (y, f) in results.items() if not y}

    print(f"{len(resolved)} resolved, {len(blocked)} blocking")
    for code, flags in blocked.items():
        print(f"  {code}:")
        for f in flags:
            print(f"    - {f}")

    if write:
        GREEK_DIR.mkdir(parents=True, exist_ok=True)
        for code, yaml_text in resolved.items():
            (GREEK_DIR / f"{code}.yaml").write_text(yaml_text, encoding="utf-8")
        print(f"wrote {len(resolved)} NT canticle YAML files")


if __name__ == "__main__":
    main()
