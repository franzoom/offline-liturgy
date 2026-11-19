#!/usr/bin/env python3
"""
import_greek_deuterocanon.py — Builds assets/psalms/greek/OT_x.yaml for the
deuterocanonical/Greek-only OT canticles that have no Hebrew source (see
import_hebrew_canticles.py's docstring), using H.B. Swete's "The Old
Testament in Greek According to the Septuagint" (public domain, 1887-1894),
via its transcription in github.com/nathans/lxx-swete (CC BY-SA 4.0, itself
derived from the First1KGreek project's TEI transcription of Swete).

## Scope: only Wisdom and Daniel — NOT Tobit, Judith or Sirach

Of the 8 canticles with no Hebrew source, only 2 books are generated here:

  OT_10 (Wisdom 9) and OT_39/OT_40/OT_41 (Daniel 3's Greek additions,
  Theodotion text: 57.Daniel_Theodotionis_versio.txt) — verified clean for
  every verse these 4 files need: no OCR corruption beyond one isolated,
  identifiable gap (see KNOWN_OCR_FIXES), and no embedded apparatus marks
  overlapping the needed verses.

Tobit (OT_5, OT_6), Judith (OT_7) and Sirach (OT_15) are NOT generated:
this source's transcription carries embedded parenthetical cross-reference
numbers mid-verse (e.g. Judith 16:2 "²ὅτι θεὸς ... (4)ὕτι εἰς παρεμβολὰς
..."), growing by an irregular, book-specific offset across each chapter.
These three books are exactly the ones with well-documented, substantial
Greek/Vulgate verse-numbering divergence (Jerome translated/expanded them
freely from an Aramaic source now largely lost), so the parenthetical
numbers are very likely Vulgate cross-references — but which exact verse
boundary they mark, and whether the French biblicalReference numbering
follows the Greek or the Vulgate scheme here, could not be established
with confidence from the text alone. Per the project's standing rule to
never guess in ambiguous numbering cases, these are left for a decision
(either resolving the correspondence by hand against a second source, or
leaving those 3 canticles' Greek toggle unavailable) rather than imported
here.

## Fixes applied

Per-verse known OCR corrections (verified against the sense of the verse
and cross-checked against the French translation and, where available,
the Old Greek Daniel text for the same verse):
  - Wisdom 9:1: "ἐυ λόγῳ" -> "ἐν λόγῳ" ("by your word" — ἐυ is not a word).
  - Daniel(Th) 3:52: "θ??ὸς" -> "θεὸς" (OCR gap; cross-checked against
    Daniel(OG) 3:52, which reads the same word cleanly).

A leading superscript/parenthesised verse-number glyph on a verse's first
word (e.g. "²ὅτι", "(16)Κύριε") is stripped as typesetting, not text —
same situation as SBLGNT's apparatus marks in import_greek_canticles.py.

Usage:
    python3 scripts/import_greek_deuterocanon.py [--write]
"""

import re
import sys
import unicodedata
import urllib.request
from pathlib import Path

SOURCE_BASE = "https://raw.githubusercontent.com/nathans/lxx-swete/master/data"
GREEK_DIR = Path("assets/psalms/greek")
PSALMS_DIR = Path("assets/psalms")

MARKER_RE = re.compile(r"\{([^}]*)\}")
BIBREF_RE = re.compile(r"^(1?[A-Za-z]+)\s+(\d+),")

# code -> (SBLGNT-style source file, French biblicalReference book abbrev)
SOURCE_FILES = {
    "Sg": "33.Sapientia_Salomonis.txt",
    "Dn": "57.Daniel_Theodotionis_versio.txt",
}

# This transcription of the Theodotion text is simply missing Dn 3:71-72
# (a transcription gap: 3:70 is directly followed by 3:73). The Old Greek
# file has them, and for this specific "Bless the Lord, X and Y..." refrain
# pattern OG and Theodotion read identically (verified against 3:70/3:73's
# wording in both, and against the French, which the OG text matches
# exactly for both verses) — not a guess, a verified narrow substitution.
DANIEL_OG_FALLBACK_URL = f"{SOURCE_BASE}/56.Daniel_translatio_Graeca.txt"
DANIEL_OG_FALLBACK_VERSES = {71, 72}

CANTICLES = ["OT_10", "OT_39", "OT_40", "OT_41"]

SUPERSCRIPT_DIGITS = "⁰¹²³⁴⁵⁶⁷⁸⁹"
_LEADING_NUMERAL_RE = re.compile(
    rf"^(?:\(\d+\)|[0-9{SUPERSCRIPT_DIGITS}]+)"
)


def strip_leading_numeral(word: str) -> str:
    return _LEADING_NUMERAL_RE.sub("", word, count=1)


# This transcription has recurring, systematic OCR errors (verified by
# reading every word of every verse these 4 files use, not a sample):
#
#  1. The verse-initial word is sometimes corrupted at its very first
#     letter (the stripped leading verse-number glyph sits right against
#     it in the scan) — e.g. "χὐλογεῖτε", "τὐλογεῖτε", "κὺλογεῖτε" for
#     "εὐλογεῖτε"/"εὐλογείτω" ("Bless!"), the refrain opening most verses
#     of Dn 3:57-88. The only letter that makes these words real Greek is
#     ε, so any first letter is corrected to it.
#  2. A standalone "ἐυ" (epsilon + plain upsilon — not a Greek word) for
#     "ἐν" ("in"/"by"): ν misread as υ. Confirmed at Sg 9:1 ("ἐν λόγῳ σου",
#     matching the French "par ta parole"), Dn 3:39 and 3:40. Never
#     confused with the genuine diphthong "εὐ-" (as in "εὐλογεῖτε" above),
#     which keeps its breathing mark and is never a standalone word.
#  3. "ὑπερυψαωμένος/-ον" for "ὑπερυψωμένος/-ον" ("highly exalted"): a
#     spurious α inserted before -ωμένος. Confirmed at Dn 3:54, 3:55 (and
#     in the Old Greek text's 3:52, independently, ruling out a one-off).
_FIXES = [
    # First letter corrupted (χ/τ/κ for ε) and/or the breathing mark on υ
    # corrupted to a grave accent (ὺ for ὐ) — "εὐλογεῖτε"/"εὐλογείτω" never
    # carry an accent on that syllable, only the breathing.
    (re.compile(r"^.[ὐὺ](λογ(?:εῖτε|είτω))"), r"εὐ\1"),
    (re.compile(r"^ἐυ$"), "ἐν"),
    (re.compile(r"ὑπερυψαωμέν(ος|ον)"), r"ὑπερυψωμέν\1"),
]

# Isolated fixes that don't fit a repeatable pattern, each individually
# verified against the sense of the verse and the French translation.
KNOWN_OCR_FIXES = {
    ("Dn", 3, 52): [("θ??ὸς", "θεὸς")],
    ("Dn", 3, 35): [("ὄι Ἀβραὰμ", "διὰ Ἀβραὰμ")],  # parallel to "καὶ διὰ Ἰσαὰκ" just after
    ("Sg", 9, 4): [("σῶυ θρόνων", "σῶν θρόνων")],
    ("Sg", 9, 5): [("ἐλάσσαων", "ἐλάσσων"), ("κρίσεαως", "κρίσεως")],
    ("Sg", 9, 6): [("ἀπδὐισης", "ἀπούσης")],
    ("Sg", 9, 2): [("ἴνα", "ἵνα")],
    ("Sg", 9, 10): [("ἴνα", "ἵνα"), ("συνπαροῦσά", "συμπαροῦσά")],
    ("Sg", 9, 11): [("ἐν τῆ δόξῃ", "ἐν τῇ δόξῃ")],
    ("Dn", 3, 87): [("τῇ καρδία", "τῇ καρδίᾳ")],
}


def fetch_book(file_name: str, book_key: str) -> dict:
    url = f"{SOURCE_BASE}/{file_name}"
    with urllib.request.urlopen(url) as response:
        raw = response.read().decode("utf-8")

    verses = {}
    current_ref = None
    words = []
    for line in raw.splitlines():
        parts = line.split(" ", 1)
        if len(parts) != 2:
            continue
        ref, word = parts
        if ref != current_ref:
            if current_ref:
                _, ch, v = current_ref.split(".")
                if v.isdigit():
                    verses[(int(ch), int(v))] = words
            current_ref = ref
            words = []
        words.append(word)
    if current_ref:
        _, ch, v = current_ref.split(".")
        if v.isdigit():
            verses[(int(ch), int(v))] = words

    cleaned = {}
    for (ch, v), words in verses.items():
        if words:
            words = [strip_leading_numeral(words[0])] + words[1:]
        words = [apply_recurring_fixes(w) for w in words]
        text = unicodedata.normalize("NFC", " ".join(w for w in words if w))
        for old, new in KNOWN_OCR_FIXES.get((book_key, ch, v), []):
            if old not in text:
                sys.exit(f"Expected {book_key} {ch}:{v} to contain {old!r}")
            text = text.replace(old, new)
        cleaned[(ch, v)] = text
    return cleaned


def apply_recurring_fixes(word: str) -> str:
    for pattern, repl in _FIXES:
        word = pattern.sub(repl, word)
    return word


def build_canticle(code, book_verses):
    path = PSALMS_DIR / f"{code}.yaml"
    text = path.read_text(encoding="utf-8")

    m_bibref = re.search(r"^biblicalReference:\s*(.+)$", text, re.M)
    bibref_raw = m_bibref.group(1).strip()
    bibref_match = BIBREF_RE.match(bibref_raw)
    book_abbr, start_chapter = bibref_match.group(1), int(bibref_match.group(2))

    m_content = re.search(r"^content:\s*\|-\n(.*)", text, re.S | re.M)
    verse_block = m_content.group(1)
    markers = MARKER_RE.findall(verse_block)

    current_chapter = start_chapter
    paragraphs = []
    for marker in markers:
        sep = "." if "." in marker else ("," if "," in marker else None)
        if sep:
            ch_str, v_str = marker.split(sep)
            current_chapter = int(ch_str)
            verse_num = int(v_str)
        else:
            verse_num = int(marker)
        key = (current_chapter, verse_num)
        if key not in book_verses[book_abbr]:
            return None, [f"{book_abbr} {key[0]}:{key[1]} (marker {{{marker}}}) not found"]
        paragraphs.append(f"{{{marker}}}" + book_verses[book_abbr][key])

    content = "\n\n".join(paragraphs)
    title = re.search(r"^title:\s*(.+)$", text, re.M).group(1).strip()
    yaml_text = (
        f"title: {title}\n"
        "subtitle: null\n"
        "commentary: null\n"
        f"biblicalReference: {bibref_raw}\n"
        f"shortReference: {code.replace('OT_', 'AT ')}\n"
        "content: |-\n"
        + "\n".join(("  " + line if line else "") for line in content.split("\n"))
        + "\n"
    )
    return yaml_text, []


def fetch_daniel_og_fallback() -> dict:
    with urllib.request.urlopen(DANIEL_OG_FALLBACK_URL) as response:
        raw = response.read().decode("utf-8")
    out = {}
    current_ref, words = None, []
    for line in raw.splitlines():
        parts = line.split(" ", 1)
        if len(parts) != 2:
            continue
        ref, word = parts
        if ref != current_ref:
            if current_ref:
                _, ch, v = current_ref.split(".")
                if v.isdigit():
                    out[(int(ch), int(v))] = words
            current_ref, words = ref, []
        words.append(word)
    if current_ref:
        _, ch, v = current_ref.split(".")
        if v.isdigit():
            out[(int(ch), int(v))] = words

    cleaned = {}
    for key, words in out.items():
        if key[1] not in DANIEL_OG_FALLBACK_VERSES:
            continue
        if words:
            words = [strip_leading_numeral(words[0])] + words[1:]
        words = [apply_recurring_fixes(w) for w in words]
        cleaned[key] = unicodedata.normalize("NFC", " ".join(w for w in words if w))
    return cleaned


def main():
    write = "--write" in sys.argv

    books_needed = {}
    for code in CANTICLES:
        bibref = re.search(r"^biblicalReference:\s*(.+)$",
                             (PSALMS_DIR / f"{code}.yaml").read_text(encoding="utf-8"), re.M).group(1).strip()
        book_abbr = BIBREF_RE.match(bibref).group(1)
        books_needed[book_abbr] = SOURCE_FILES[book_abbr]

    print(f"Fetching: {books_needed}")
    book_verses = {abbr: fetch_book(fname, abbr) for abbr, fname in books_needed.items()}
    if "Dn" in book_verses:
        og_fallback = fetch_daniel_og_fallback()
        for key, text in og_fallback.items():
            book_verses["Dn"].setdefault(key, text)

    results = {}
    for code in CANTICLES:
        yaml_text, flags = build_canticle(code, book_verses)
        results[code] = (yaml_text, flags)

    resolved = {c: y for c, (y, f) in results.items() if y}
    blocked = {c: f for c, (y, f) in results.items() if not y}
    print(f"{len(resolved)} resolved, {len(blocked)} blocking")
    for code, flags in blocked.items():
        print(f"  {code}: {flags}")

    if write:
        GREEK_DIR.mkdir(parents=True, exist_ok=True)
        for code, yaml_text in resolved.items():
            (GREEK_DIR / f"{code}.yaml").write_text(yaml_text, encoding="utf-8")
        print(f"wrote {len(resolved)} deuterocanonical canticle YAML files")


if __name__ == "__main__":
    main()
