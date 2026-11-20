#!/usr/bin/env python3
"""
import_hebrew_canticles.py — Builds assets/psalms/hebrew/OT_x.yaml for the
18 Old Testament canticles (assets/psalms/OT_x.yaml) whose book exists in
the Hebrew Masoretic text (Exodus, Deuteronomy, 1 Samuel, 1 Chronicles,
Isaiah, Jeremiah, Ezekiel, Habakkuk). The 8 canticles from deuterocanonical
books or Greek-only Daniel additions (Tobit, Judith, Wisdom, Sirach, the
Daniel 3 additions) have no Hebrew source and are handled separately (see
import_greek_deuterocanon.py, using Swete's Septuagint).

Unlike the Psalter (see import_hebrew_psalms.py), these books use the SAME
chapter numbering in the Hebrew and Vulgate/Greek traditions — no
Vulgate->Hebrew shift table is needed here, and biblicalReference is kept
unchanged from the French file.

Verse markers are usually a bare verse number (`{10}`), implicitly within
the chapter named by biblicalReference; OT_30 (Is 61-62) crosses a chapter
boundary and marks that transition explicitly (`{61,10}`, then `{11}`,
then `{62,1}`...) — this script tracks the "current chapter" the same way
the French file's own markers do, updating it only when a marker names one.

Reuses, unchanged, the text-extraction (qere/ketiv, maqaf, sof pasuq,
notes), line-splitting (disjunctive-accent based) and imprecatory-bracket
grouping already validated in import_hebrew_psalms.py for the Psalter.

Usage:
    python3 scripts/import_hebrew_canticles.py [--write]
    (run from the root of the offline-liturgy project; requires network
    access to fetch the source text)

Without --write: only writes assets/psalms/hebrew/_ot_canticles_report.md.
With --write: also writes assets/psalms/hebrew/OT_x.yaml for every
resolved canticle, plus appends low-confidence line splits to
assets/psalms/hebrew/_lines_review.md.
"""

import re
import sys
import unicodedata
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

NS = "{http://www.bibletechnologies.net/2003/OSIS/namespace}"
WLC_BASE_URL = "https://raw.githubusercontent.com/openscriptures/morphhb/master/wlc"

PSALMS_DIR = Path("assets/psalms")
HEBREW_DIR = PSALMS_DIR / "hebrew"
REPORT_PATH = HEBREW_DIR / "_ot_canticles_report.md"
LINES_REVIEW_PATH = HEBREW_DIR / "_lines_review.md"

# French biblicalReference book abbreviation -> WLC OSIS book code.
BOOK_CODES = {
    "Ex": "Exod",
    "Dt": "Deut",
    "1S": "1Sam",
    "1Chr": "1Chr",
    "Is": "Isa",
    "Jr": "Jer",
    "Ez": "Ezek",
    "Ha": "Hab",
}

CANTICLES = ["OT_1", "OT_2", "OT_3", "OT_4", "OT_17", "OT_19", "OT_20", "OT_22",
             "OT_23", "OT_25", "OT_26", "OT_27", "OT_30", "OT_32", "OT_34",
             "OT_36", "OT_38", "OT_43"]

BIBREF_RE = re.compile(r"^(1?[A-Za-z]+)\s+(\d+),")
MARKER_RE = re.compile(r"\{([^}]*)\}")

_COMBINING_RE = re.compile(r"[֑-ׇֽֿׁׂׅׄ]")


def consonants_only(word: str) -> str:
    return _COMBINING_RE.sub("", unicodedata.normalize("NFC", word))


def clean_word(text: str) -> str:
    return unicodedata.normalize("NFC", (text or "").replace("/", ""))


def extract_verse_tokens(verse_elem):
    tokens = []
    children = list(verse_elem)
    i = 0
    while i < len(children):
        el = children[i]
        tag = el.tag.replace(NS, "")
        if tag == "w":
            if el.get("type") == "x-ketiv":
                nxt = children[i + 1] if i + 1 < len(children) else None
                qere_w = None
                if nxt is not None and nxt.tag.replace(NS, "") == "note":
                    rdg = nxt.find(f"{NS}rdg[@type='x-qere']")
                    if rdg is not None:
                        qere_w = rdg.find(f"{NS}w")
                tokens.append((clean_word(qere_w.text if qere_w is not None else el.text), "space"))
            else:
                tokens.append((clean_word(el.text), "space"))
        elif tag == "seg":
            seg_type = el.get("type")
            if seg_type == "x-maqqef":
                tokens.append((el.text, "maqaf"))
            elif seg_type == "x-sof-pasuq":
                tokens.append((el.text, "tight"))
            else:
                tokens.append((el.text or "", "space"))
        i += 1
    return [(t, m) for t, m in tokens if t]


def group_into_words(tokens):
    words = []
    cur_text, cur_join = "", "space"
    for text, mode in tokens:
        if cur_text == "":
            cur_text, cur_join = text, mode
        elif mode == "maqaf" or cur_text.endswith("־"):
            cur_text += text
        elif mode == "tight":
            cur_text += text
        else:
            words.append((cur_text, cur_join))
            cur_text, cur_join = text, mode
    if cur_text:
        words.append((cur_text, cur_join))
    return words


def render_line(words) -> str:
    out = ""
    for text, mode in words:
        if out == "":
            out = text
        elif mode == "tight":
            out += text
        else:
            out += " " + text
    return out


ACCENT_TIERS = [
    {"֑"},
    {"֔", "֕", "֖", "֗", "֒"},
    {"֙", "֘", "֛", "֜", "֡", "֚"},
]
ALL_DISJUNCTIVES = set.union(*ACCENT_TIERS)


def word_accents(word: str):
    return {c for c in word if c in ALL_DISJUNCTIVES}


def split_into_lines(words, n_lines):
    if n_lines <= 1 or len(words) <= 1:
        return [render_line(words)], True
    total_len = sum(len(w[0]) for w in words)
    targets = [total_len * k / n_lines for k in range(1, n_lines)]
    cum, acc = [], 0
    for w in words:
        acc += len(w[0])
        cum.append(acc)

    def candidates_for(tier_set, used):
        return [i for i, w in enumerate(words[:-1]) if word_accents(w[0]) & tier_set and i not in used]

    breaks, used, confident = [], set(), True
    for target in targets:
        chosen = None
        for tier in ACCENT_TIERS:
            pool = candidates_for(tier, used)
            if pool:
                chosen = min(pool, key=lambda i: abs(cum[i] - target))
                break
        if chosen is None:
            chosen = min((i for i in range(len(words) - 1) if i not in used),
                         key=lambda i: abs(cum[i] - target), default=None)
            confident = False
        if chosen is None:
            confident = False
            continue
        used.add(chosen)
        breaks.append(chosen)

    breaks = sorted(set(breaks))
    if len(breaks) != n_lines - 1:
        confident = False
        for i in range(len(words) - 1):
            if len(breaks) >= n_lines - 1:
                break
            if i not in breaks:
                breaks.append(i)
        breaks = sorted(breaks[: n_lines - 1])

    lines, start = [], 0
    for b in breaks:
        lines.append(render_line(words[start:b + 1]))
        start = b + 1
    lines.append(render_line(words[start:]))
    return lines, confident


def load_wlc_book(book_code: str):
    url = f"{WLC_BASE_URL}/{book_code}.xml"
    with urllib.request.urlopen(url) as response:
        root = ET.fromstring(response.read().decode("utf-8"))
    verse_words, verse_count = {}, {}
    for verse in root.iter(f"{NS}verse"):
        _, ch_str, v_str = verse.get("osisID").split(".")
        ch, v = int(ch_str), int(v_str)
        tokens = extract_verse_tokens(verse)
        verse_words[(ch, v)] = group_into_words(tokens)
        verse_count[ch] = max(verse_count.get(ch, 0), v)
    return verse_words, verse_count


def french_verse_layout(content_block: str):
    lines_by_verse = {}
    current = None
    for raw_line in content_block.split("\n"):
        stripped = raw_line.strip()
        marker = MARKER_RE.match(stripped)
        if marker:
            current = marker.group(1)
            rest = stripped[marker.end():]
            lines_by_verse[current] = [rest]
        elif stripped == "":
            current = None
        elif current is not None:
            lines_by_verse[current].append(stripped)
    return lines_by_verse


def bracketed_markers(content_block: str):
    bracketed = set()
    depth = 0
    current = None
    for raw_line in content_block.split("\n"):
        stripped = raw_line.strip()
        marker = MARKER_RE.match(stripped)
        if marker:
            current = marker.group(1)
        if depth > 0 and current is not None:
            bracketed.add(current)
        depth += stripped.count("[") - stripped.count("]")
        if "[" in stripped and current is not None:
            bracketed.add(current)
    return bracketed


def resolve_markers(markers, start_chapter):
    """Returns [(marker_string, chapter, verse)], tracking the current
    chapter across bare-number markers, per this module's docstring."""
    resolved = []
    current_chapter = start_chapter
    for marker in markers:
        if "," in marker:
            ch_str, v_str = marker.split(",")
            current_chapter = int(ch_str)
            resolved.append((marker, current_chapter, int(v_str)))
        else:
            resolved.append((marker, current_chapter, int(marker)))
    return resolved


def build_canticle(code, verse_words, hebrew_counts):
    path = PSALMS_DIR / f"{code}.yaml"
    text = path.read_text(encoding="utf-8")

    m_bibref = re.search(r"^biblicalReference:\s*(.+)$", text, re.M)
    bibref_raw = m_bibref.group(1).strip()
    bibref_match = BIBREF_RE.match(bibref_raw)
    book_abbr, start_chapter = bibref_match.group(1), int(bibref_match.group(2))
    book_code = BOOK_CODES[book_abbr]

    m_content = re.search(r"^content:\s*\|-\n(.*)", text, re.S | re.M)
    verse_block = m_content.group(1)
    markers = [m for m in MARKER_RE.findall(verse_block)]
    resolved = resolve_markers(markers, start_chapter)

    hebrew_max = hebrew_counts.get(book_code, {})
    flags = []
    for marker, ch, v in resolved:
        if v > hebrew_max.get(ch, 0):
            flags.append(f"{book_abbr} {ch}:{v} (marker {{{marker}}}) not found in WLC {book_code}")

    if flags:
        return None, flags, None

    french_lines = french_verse_layout(verse_block)
    bracketed = bracketed_markers(verse_block)

    paragraphs = []
    review_entries = []
    for marker, ch, v in resolved:
        words = verse_words[book_code].get((ch, v), [])
        n_lines = len(french_lines.get(marker, [""]))
        lines, confident = split_into_lines(words, n_lines)
        verse_lines = [f"{{{marker}}}" + lines[0]] + lines[1:]
        paragraphs.append((marker, verse_lines, marker in bracketed))
        if not confident:
            review_entries.append({
                "file": code,
                "verse": marker,
                "n_lines": n_lines,
                "french": french_lines.get(marker, []),
                "hebrew": lines,
            })

    grouped = []
    i = 0
    while i < len(paragraphs):
        _, verse_lines, is_bracketed = paragraphs[i]
        if not is_bracketed:
            grouped.append("\n".join(verse_lines))
            i += 1
            continue
        run = ["\n".join(verse_lines)]
        i += 1
        while i < len(paragraphs) and paragraphs[i][2]:
            run.append("\n".join(paragraphs[i][1]))
            i += 1
        grouped.append("[" + "\n\n".join(run) + "]")

    content = "\n\n".join(grouped)
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
    return yaml_text, [], review_entries


def main():
    write = "--write" in sys.argv
    books_needed = {BOOK_CODES[BIBREF_RE.match(
        re.search(r"^biblicalReference:\s*(.+)$",
                   (PSALMS_DIR / f"{code}.yaml").read_text(encoding="utf-8"), re.M).group(1).strip()
    ).group(1)] for code in CANTICLES}

    print(f"Fetching {len(books_needed)} WLC books: {sorted(books_needed)}")
    verse_words = {}
    hebrew_counts = {}
    for book_code in books_needed:
        vw, counts = load_wlc_book(book_code)
        verse_words[book_code] = vw
        hebrew_counts[book_code] = counts

    results = {}
    all_review = []
    for code in CANTICLES:
        yaml_text, flags, review_entries = build_canticle(code, verse_words, hebrew_counts)
        results[code] = (yaml_text, flags)
        if review_entries:
            all_review.extend(review_entries)

    resolved = {c: y for c, (y, f) in results.items() if y}
    blocked = {c: f for c, (y, f) in results.items() if not y}

    lines = [
        "# Old Testament canticles — Hebrew correspondence report",
        "",
        f"{len(CANTICLES)} canticles checked: {len(resolved)} resolved, {len(blocked)} blocking.",
        "",
        "Book chapter numbers are the same in Hebrew and Vulgate/Greek for "
        "these books (unlike the Psalter) — biblicalReference is kept as-is.",
        "",
    ]
    if blocked:
        lines += ["## Blocking", ""]
        for code, flags in blocked.items():
            lines.append(f"### {code}")
            for f in flags:
                lines.append(f"- {f}")
            lines.append("")
    lines += ["## Resolved", ""]
    for code in resolved:
        lines.append(f"- {code}: OK")

    HEBREW_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {REPORT_PATH} ({len(resolved)} resolved, {len(blocked)} blocking)")

    if write:
        for code, yaml_text in resolved.items():
            out_path = HEBREW_DIR / f"{code}.yaml"
            out_path.write_text(yaml_text, encoding="utf-8")
        print(f"wrote {len(resolved)} OT canticle YAML files")

        if all_review:
            existing = LINES_REVIEW_PATH.read_text(encoding="utf-8") if LINES_REVIEW_PATH.exists() else \
                "# Hebrew line-split review\n\n"
            extra = ["## OT canticles (import_hebrew_canticles.py)", ""]
            for e in all_review:
                extra.append(f"### {e['file']} verse {e['verse']} ({e['n_lines']} line(s))")
                extra.append("")
                extra.append("French:")
                for fl in e["french"]:
                    extra.append(f"  {fl}")
                extra.append("")
                extra.append("Hebrew (as split):")
                for hl in e["hebrew"]:
                    extra.append(f"  {hl}")
                extra.append("")
            LINES_REVIEW_PATH.write_text(existing + "\n".join(extra) + "\n", encoding="utf-8")
            print(f"appended {len(all_review)} low-confidence verses to {LINES_REVIEW_PATH}")


if __name__ == "__main__":
    main()
