#!/usr/bin/env python3
"""
import_hebrew_psalms.py — Builds assets/psalms/hebrew/PSALM_x.yaml for every
assets/psalms/PSALM_x.yaml, from the Westminster Leningrad Codex (WLC) via
the Open Scriptures Hebrew Bible (OSHB) project.

Source: CC BY 4.0 (morphology/segmentation) over a Public Domain base text
(https://github.com/openscriptures/morphhb), fetched from its canonical
GitHub mirror:
https://raw.githubusercontent.com/openscriptures/morphhb/master/wlc/Ps.xml

## The numbering discovery

assets/psalms/PSALM_x.yaml's own `biblicalReference` field looks like it
cites the Hebrew (Masoretic/MT) chapter directly (e.g. "Ps 23, 1-10"), but
it does not: cross-checking French incipits against the Hebrew text shows
the WHOLE corpus is numbered after the old Vulgate/Septuagint psalter, not
the Hebrew one. For example PSALM_22.yaml ("Le Seigneur est mon berger...")
is the Hebrew Psalm 23 (the Shepherd Psalm); PSALM_23.yaml ("Au Seigneur,
le monde et sa richesse...") is Hebrew Psalm 24; PSALM_50.yaml (the
Miserere, "Pitié pour moi, mon Dieu...") is Hebrew Psalm 51.

This is the standard, well-documented Vulgate<->Hebrew(MT) correspondence
(see e.g. any study Bible's psalm-numbering table), empirically confirmed
here at 8 independent content-checked points across the whole psalter, and
by every one of this app's 301 PSALM_*.yaml files passing automated
consistency checks under this mapping:

    Vulgate 1-8     -> Hebrew 1-8      (identical)
    Vulgate 9       -> Hebrew 9 ("9A" codes) or Hebrew 10 ("9B" codes)
    Vulgate 10-112  -> Hebrew Vulgate+1
    Vulgate 113     -> Hebrew 114 ("113A" codes) or Hebrew 115 ("113B" codes)
    Vulgate 114     -> Hebrew 116 (verses 1-9, native Hebrew numbering)
    Vulgate 115     -> Hebrew 116 (verses 10-19, native Hebrew numbering)
    Vulgate 116-145 -> Hebrew Vulgate+1
    Vulgate 146     -> Hebrew 147 (verses 1-11, native Hebrew numbering)
    Vulgate 147     -> Hebrew 147 (verses 12-20, native Hebrew numbering)
    Vulgate 148-150 -> Hebrew 148-150  (identical)

Within a resolved Hebrew chapter, this app's own `{N}` verse numbers are
the real Hebrew verse numbers already (no renumbering needed) — confirmed
by the "9B"/"113A"/"113B" cases, whose stated ranges already equal their
target Hebrew chapter's own native numbers.

Per the project owner's decision: `biblicalReference` in the generated
Hebrew files keeps the Vulgate number (matching the French file, so both
sides cite the psalm the same way) with the Hebrew chapter appended in
parentheses when it differs, e.g. "Ps 32(33), 1-22" — their own example.
No parentheses when the chapter is identical in both systems (1-8, 148-150,
and the second half of the 146/147 split, which is already cited as "147").

## Text extraction

Per verse: word text comes from OSHB's <w> elements (the `/` internal
morphological-segment marks are stripped); a ketiv (<w type="x-ketiv">) is
replaced by its paired qere reading (<note type="variant"><rdg
type="x-qere"><w>), since the qere is what is meant to be read aloud —
confirmed by spot-checking Ps 100:3; plain editorial <note>s (not part of
a qere pair) are dropped; a maqaf (seg type="x-maqqef") fuses directly to
its neighbours with no space; a sof pasuq (x-sof-pasuq) attaches directly
to the end of the verse; anything else (e.g. a paseq) gets normal spacing.
Niqqud and te'amim (cantillation) are kept as published. Verified against
an independently-sourced Masoretic edition of Ps 1:1 (Sefaria's MAM text),
character-for-character identical for the maqaf/paseq handling.

## Superscriptions (per the project owner's decision)

For psalms where WLC keeps the superscription (title) in the SAME verse
unit as the first line of the body (e.g. Hebrew Ps 23:1 "מזמור לדוד יהוה
רעי..."), the superscription words are stripped before import, keeping
only the body — matching the French, which never translates these
superscriptions (model: use the French text's own scope as the boundary).
Detected via a vocabulary of standard superscription terms (לדוד, לאסף,
מזמור, שיר, למנצח, שיר המעלות, etc. — see SUPERSCRIPTION_VOCABULARY),
matched as whole words from the start of verse 1 only, so an ordinary verb
that happens to contain one as a substring (e.g. שירו, "sing!") is not
mistaken for the noun שיר, "a song". This is NOT the same situation as
Psalm 3, where the superscription is already its own separate verse 1 in
the WLC and the French file already starts at verse 2 — nothing to do
there, the general per-file verse list already skips it.

## Line splitting

Each verse is split purely from its own Masoretic cantillation, independent
of how many lines any other text's version uses. The etnachta (atnach) is
the verse's primary caesura and always divides it first — a verse with none
stays whole. Each resulting half is split once more, at its own strongest
secondary disjunctive accent (zaqef/tipcha/revia/segol, then weaker ones),
but only when: (a) the half is long enough (LONG_SEGMENT_THRESHOLD chars)
that a further pause is plausible — calibrated against the WLC Psalter's
own half-verse length distribution (median ~30, 80th percentile ~38 chars);
and (b) the candidate accent falls within BALANCE_MARGIN of the half's
midpoint, so an off-centre accent near one edge (e.g. a minor accent on the
very first word) doesn't split off a one-word sliver. No further recursion,
and no fallback to a plain word boundary: a verse or half the cantillation
itself doesn't divide further stays as one line, even if long.

## Imprecatory verses

27 French files bracket some verses as `[...]` (hidden when the app's
"versets imprécatoires" setting is off). This script brackets the same
VERSE NUMBERS in the Hebrew output, at whole-verse granularity — it does
not attempt to reproduce a bracket that starts or ends mid-verse in
French (e.g. PSALM_58's verse 6, which is half in/half out): the whole
Hebrew verse is bracketed if any part of the matching French verse is.

Usage:
    python3 scripts/import_hebrew_psalms.py [--write]
    (run from the root of the offline-liturgy project; requires network
    access to fetch the source text)

Without --write: only (re)writes assets/psalms/hebrew/_correspondence_report.md.
With --write: also writes assets/psalms/hebrew/PSALM_x.yaml for every
resolved file.
"""

import re
import sys
import unicodedata
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

WLC_URL = "https://raw.githubusercontent.com/openscriptures/morphhb/master/wlc/Ps.xml"
NS = "{http://www.bibletechnologies.net/2003/OSIS/namespace}"

PSALMS_DIR = Path("assets/psalms")
HEBREW_DIR = PSALMS_DIR / "hebrew"
REPORT_PATH = HEBREW_DIR / "_correspondence_report.md"

FILENAME_RE = re.compile(r"^PSALM_(\d+)([A-Za-z]?)")
BIBREF_RE = re.compile(r"^Ps\s+(\d+),\s*([\d.\-,]+)$")

# Superscription vocabulary, consonants only (no niqqud/cantillation) so it
# matches regardless of pointing. Checked word-by-word from the start of a
# verse only (prefix match), never as a substring — "שירו" ("sing!", a
# verb) must not match "שיר" ("a song", the noun used in superscriptions).
SUPERSCRIPTION_VOCABULARY = {
    "למנצח", "מזמור", "שיר", "מכתם", "משכיל", "תפלה", "תהלה",
    "שגיון", "לדוד", "לאסף", "למשה", "לבני־קרח", "לידותון",
    "איש־האלהים", "לתודה", "לשלמה", "לעני", "הללויה", "הללו־יה",
    "המעלות", "למעלות",
}

# Disjunctive-accent tiers for line splitting, strongest first. Etnachta
# (U+0591) is the verse's main divider; the rest are secondary disjunctives
# (Masoretic poetic accentuation used in Psalms/Proverbs/Job shares these
# codepoints with the prose system even though the two systems' accent
# hierarchies differ in finer detail — adequate for a best-effort split).
ACCENT_TIERS = [
    {"֑"},
    {"֔", "֕", "֖", "֗", "֒"},
    {"֙", "֘", "֛", "֜", "֡", "֚"},
]
ALL_DISJUNCTIVES = set.union(*ACCENT_TIERS)

_COMBINING_RE = re.compile(r"[֑-ׇֽֿׁׂׅׄ]")


def consonants_only(word: str) -> str:
    return _COMBINING_RE.sub("", unicodedata.normalize("NFC", word))


def fetch_wlc_text() -> str:
    with urllib.request.urlopen(WLC_URL) as response:
        return response.read().decode("utf-8")


def clean_word(text: str) -> str:
    return unicodedata.normalize("NFC", (text or "").replace("/", ""))


def extract_verse_tokens(verse_elem):
    """Returns [(word_text, join_mode)] for one <verse>, cantillation and
    niqqud kept, per the rules in this module's docstring (qere/ketiv,
    morphological slashes, notes)."""
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
        # plain <note> (not a qere pair): no text contributed
        i += 1
    return [(t, m) for t, m in tokens if t]


def group_into_words(tokens):
    """Merges maqaf-fused tokens into single logical words, so a line break
    never lands inside a maqaf unit."""
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


def word_accents(word: str):
    return {c for c in word if c in ALL_DISJUNCTIVES}


def strip_superscription(words):
    """Greedily strips leading words matching SUPERSCRIPTION_VOCABULARY.
    Returns (stripped_words, remaining_words)."""
    i = 0
    while i < len(words):
        bare = consonants_only(words[i][0]).rstrip("׃")
        if bare in SUPERSCRIPTION_VOCABULARY:
            i += 1
        else:
            break
    return words[:i], words[i:]


# A half-verse (post-etnachta segment) shorter than this is left as one
# line: two hemistichs already read naturally at this length. See the
# "Line splitting" docstring section for how this was calibrated.
LONG_SEGMENT_THRESHOLD = 42

# A secondary-accent candidate is only accepted if it falls within
# [margin, 1-margin] of the segment's own length, so a minor accent near
# one edge can't split off a tiny sliver far from the midpoint.
BALANCE_MARGIN = 0.25


def split_at_accent(words, accent_set):
    """Splits words into segments right after every word bearing an accent
    in accent_set (a verse normally carries at most one etnachta, but this
    handles the general case of more than one)."""
    segments, current = [], []
    for w in words:
        current.append(w)
        if word_accents(w[0]) & accent_set:
            segments.append(current)
            current = []
    if current:
        segments.append(current)
    return segments


def split_segment_further(segment):
    """Splits one segment at its own strongest available secondary
    disjunctive accent (tier 2, falling back to tier 3), chosen closest to
    its midpoint among candidates within BALANCE_MARGIN of it. Returns
    [segment] unchanged if it's too short, or no such candidate exists."""
    seg_len = sum(len(w[0]) for w in segment)
    if seg_len <= LONG_SEGMENT_THRESHOLD or len(segment) <= 1:
        return [segment]

    lo, hi = seg_len * BALANCE_MARGIN, seg_len * (1 - BALANCE_MARGIN)
    target = seg_len / 2
    cum, acc = [], 0
    for w in segment:
        acc += len(w[0])
        cum.append(acc)

    for tier in ACCENT_TIERS[1:]:
        candidates = [i for i, w in enumerate(segment[:-1])
                      if word_accents(w[0]) & tier and lo <= cum[i] <= hi]
        if candidates:
            cut = min(candidates, key=lambda i: abs(cum[i] - target))
            return [segment[:cut + 1], segment[cut + 1:]]
    return [segment]


def split_into_lines(words):
    """Splits a verse into display lines from its own cantillation alone
    (see the "Line splitting" docstring section)."""
    if len(words) <= 1:
        return [render_line(words)]
    segments = split_at_accent(words, ACCENT_TIERS[0])
    lines = []
    for seg in segments:
        lines.extend(split_segment_further(seg))
    return [render_line(s) for s in lines]


def load_wlc():
    """Returns ({(chapter, verse): [(word, join_mode)]}, {chapter: max_verse})."""
    root = ET.fromstring(fetch_wlc_text())
    verse_words = {}
    verse_count = {}
    for verse in root.iter(f"{NS}verse"):
        _, ch_str, v_str = verse.get("osisID").split(".")
        ch, v = int(ch_str), int(v_str)
        tokens = extract_verse_tokens(verse)
        verse_words[(ch, v)] = group_into_words(tokens)
        verse_count[ch] = max(verse_count.get(ch, 0), v)
    return verse_words, verse_count


def vulgate_to_hebrew_chapter(vulgate_num: int, suffix_letter: str):
    if vulgate_num <= 8:
        return vulgate_num
    if vulgate_num == 9:
        return 10 if suffix_letter == "b" else 9
    if 10 <= vulgate_num <= 112:
        return vulgate_num + 1
    if vulgate_num == 113:
        return 115 if suffix_letter == "b" else 114
    if vulgate_num in (114, 115):
        return 116
    if 116 <= vulgate_num <= 145:
        return vulgate_num + 1
    if vulgate_num in (146, 147):
        return 147
    if 148 <= vulgate_num <= 150:
        return vulgate_num
    return None


def parse_ranges(range_str: str):
    parts = []
    for chunk in re.split(r"[,.]", range_str):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            a, b = chunk.split("-")
            parts.append((int(a), int(b)))
        else:
            parts.append((int(chunk), int(chunk)))
    return parts


def bracketed_verses(content_block: str):
    """Whole verse numbers that have any part of their French text inside
    an imprecatory [...] block."""
    bracketed = set()
    depth = 0
    current = None
    for raw_line in content_block.split("\n"):
        stripped = raw_line.strip()
        marker = re.match(r"^\{(\d+)\}", stripped)
        if marker:
            current = int(marker.group(1))
        if depth > 0 and current is not None:
            bracketed.add(current)
        depth += stripped.count("[") - stripped.count("]")
        if "[" in stripped and current is not None:
            bracketed.add(current)
    return bracketed


def build_rows(hebrew_words, hebrew_counts):
    rows = []
    for path in sorted(PSALMS_DIR.glob("PSALM_*.yaml")):
        stem = path.stem
        text = path.read_text(encoding="utf-8")

        m_title = re.search(r"^title:\s*(.+)$", text, re.M)
        french_title = m_title.group(1).strip() if m_title else stem.replace("PSALM_", "Psaume ")

        m_bibref = re.search(r"^biblicalReference:\s*(.+)$", text, re.M)
        bibref_raw = m_bibref.group(1).strip() if m_bibref else None

        m_content = re.search(r"^content:\s*\|-\n(.*)", text, re.S | re.M)
        verse_block = m_content.group(1) if m_content else ""
        content_verses = sorted(set(int(n) for n in re.findall(r"\{(\d+)\}", verse_block)))

        fname_match = FILENAME_RE.match(stem)
        vulgate_num = int(fname_match.group(1))
        suffix_letter = fname_match.group(2).lower() if fname_match.group(2) else ""

        hebrew_chapter = vulgate_to_hebrew_chapter(vulgate_num, suffix_letter)
        hebrew_max = hebrew_counts.get(hebrew_chapter)

        bibref_match = BIBREF_RE.match(bibref_raw) if bibref_raw else None
        ranges = parse_ranges(bibref_match.group(2)) if bibref_match else []
        range_min = min((r[0] for r in ranges), default=None)
        range_max = max((r[1] for r in ranges), default=None)

        flags = []
        if bibref_raw is None:
            flags.append("no biblicalReference field")
        elif bibref_match is None:
            flags.append(f"unparsed biblicalReference {bibref_raw!r}")
        if hebrew_chapter is None:
            flags.append(f"no Vulgate->Hebrew rule for {vulgate_num}")
        elif hebrew_max is None:
            flags.append(f"Hebrew chapter {hebrew_chapter} not found in WLC")
        elif range_max is not None and range_max > hebrew_max:
            flags.append(f"stated max verse {range_max} > Hebrew {hebrew_chapter}'s {hebrew_max} verses")

        if content_verses and range_min is not None and (
            content_verses[0] != range_min or content_verses[-1] != range_max
        ):
            flags.append(
                f"content markers {content_verses[0]}-{content_verses[-1]} "
                f"!= biblicalReference range {range_min}-{range_max}"
            )

        starts_at_1 = bool(content_verses) and content_verses[0] == 1
        v1_words = hebrew_words.get((hebrew_chapter, 1), []) if hebrew_chapter else []
        stripped, _ = strip_superscription(v1_words) if starts_at_1 else ([], [])
        superscription_in_v1 = bool(stripped)

        rows.append({
            "file": stem,
            "path": path,
            "french_title": french_title,
            "vulgate_num": vulgate_num,
            "suffix_letter": suffix_letter,
            "vulgate_label": f"{vulgate_num}{suffix_letter.upper()}" if suffix_letter else str(vulgate_num),
            "hebrew_chapter": hebrew_chapter,
            "verses": content_verses,
            "verse_block": verse_block,
            "bibref": bibref_raw,
            "flags": flags,
            "superscription_in_v1": superscription_in_v1,
            "superscription_stripped": render_line(stripped) if stripped else None,
        })
    return rows


def write_report(rows):
    def other_flags(r):
        return [f for f in r["flags"] if not f.startswith("content markers")]

    blocking = [r for r in rows if other_flags(r)]
    clean = [r for r in rows if not r["flags"]]
    stale_bibref = [r for r in rows if not other_flags(r)
                     and any(f.startswith("content markers") for f in r["flags"])]

    lines = [
        "# Hebrew psalm correspondence report",
        "",
        f"{len(rows)} French psalm files checked: {len(clean)} resolved cleanly, "
        f"{len(blocking)} blocking.",
        "",
        "Numbering: this app's PSALM_x codes follow the old Vulgate/Septuagint "
        "psalm numbering, not the Hebrew (Masoretic) one. See this script's "
        "module docstring for the full Vulgate->Hebrew table and how it was "
        "validated.",
        "",
        "Superscriptions combined into verse 1 (e.g. Hebrew Ps 23:1 'מזמור "
        "לדוד יהוה רעי...') are stripped to the body text only, per the "
        "project owner's instruction to use the French text's own scope as "
        "the model. See this script's docstring for the vocabulary used.",
        "",
    ]

    if blocking:
        lines += ["## Blocking — needs a decision before import", ""]
        for r in blocking:
            lines.append(f"### {r['file']} (`{r['bibref']}`)")
            for f in r["flags"]:
                lines.append(f"- {f}")
            lines.append("")

    if stale_bibref:
        lines += [
            "## Data quality notes (non-blocking)",
            "",
            "These files' `biblicalReference` field doesn't cover every verse "
            "their own `{N}` content markers use — not a chapter-mapping "
            "problem; import uses each file's actual `{N}` markers as the "
            "verse list.",
            "",
        ]
        for r in stale_bibref:
            note = next(f for f in r["flags"] if f.startswith("content markers"))
            lines.append(f"- {r['file']}: {note}")
        lines.append("")

    lines += ["## Resolved correspondence table", "",
              "| File | Vulgate label | Hebrew chapter | Verses used | Note |",
              "| --- | --- | --- | --- | --- |"]
    for r in rows:
        if r in blocking:
            continue
        verses_str = ",".join(str(v) for v in r["verses"]) if r["verses"] else "?"
        note = "superscription stripped from v1" if r["superscription_in_v1"] else ""
        if any(f.startswith("content markers") for f in r["flags"]):
            note = (note + "; " if note else "") + "stale biblicalReference (content is ground truth)"
        lines.append(f"| {r['file']} | {r['vulgate_label']} | {r['hebrew_chapter']} | {verses_str} | {note} |")

    HEBREW_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {REPORT_PATH} ({len(clean)} clean, {len(blocking)} blocking)")
    return blocking


def biblical_reference_for(r):
    vulgate_label = r["vulgate_label"]
    hebrew_chapter = r["hebrew_chapter"]
    bare_vulgate_num = r["vulgate_num"]
    verses_str = ",".join(
        f"{a}-{b}" if a != b else str(a)
        for a, b in _ranges_from_sorted(r["verses"])
    )
    if hebrew_chapter != bare_vulgate_num or r["suffix_letter"]:
        chapter_part = f"{vulgate_label}({hebrew_chapter})"
    else:
        chapter_part = vulgate_label
    return f"Ps {chapter_part}, {verses_str}"


def _ranges_from_sorted(verses):
    if not verses:
        return []
    ranges = []
    start = prev = verses[0]
    for v in verses[1:]:
        if v == prev + 1:
            prev = v
            continue
        ranges.append((start, prev))
        start = prev = v
    ranges.append((start, prev))
    return ranges


def build_hebrew_yaml(r, hebrew_words, bracketed):
    hebrew_chapter = r["hebrew_chapter"]
    verse_texts = []  # [(verse_number, text, is_bracketed)]

    for n in r["verses"]:
        words = hebrew_words.get((hebrew_chapter, n), [])
        if n == 1 and r["superscription_in_v1"]:
            _, words = strip_superscription(words)
        lines = split_into_lines(words)
        marker_line = f"{{{n}}}" + lines[0]
        verse_lines = [marker_line] + lines[1:]
        verse_texts.append((n, "\n".join(verse_lines), n in bracketed))

    # Consecutive bracketed verses share ONE [...] pair (like the French
    # source), instead of one per verse — avoids a run of extra blank
    # paragraphs when the imprecatory-verses setting hides them.
    paragraphs = []
    i = 0
    while i < len(verse_texts):
        _, text, is_bracketed = verse_texts[i]
        if not is_bracketed:
            paragraphs.append(text)
            i += 1
            continue
        run = [text]
        i += 1
        while i < len(verse_texts) and verse_texts[i][2]:
            run.append(verse_texts[i][1])
            i += 1
        paragraphs.append("[" + "\n\n".join(run) + "]")

    content = "\n\n".join(paragraphs)
    yaml_text = (
        f"title: {r['french_title']}\n"
        "subtitle: null\n"
        "commentary: null\n"
        f"biblicalReference: {biblical_reference_for(r)}\n"
        f"shortReference: Ps {r['vulgate_label']}\n"
        "content: |-\n"
        + "\n".join(("  " + line if line else "") for line in content.split("\n"))
        + "\n"
    )
    return yaml_text


def write_yaml_files(rows, hebrew_words):
    written = 0
    for r in rows:
        if r["flags"] and any(not f.startswith("content markers") for f in r["flags"]):
            continue  # blocking, skip
        bracketed = bracketed_verses(r["verse_block"])
        yaml_text = build_hebrew_yaml(r, hebrew_words, bracketed)
        out_path = HEBREW_DIR / f"{r['file']}.yaml"
        out_path.write_text(yaml_text, encoding="utf-8")
        written += 1
    print(f"wrote {written} Hebrew psalm YAML files")


def main():
    write = "--write" in sys.argv
    hebrew_words, hebrew_counts = load_wlc()
    rows = build_rows(hebrew_words, hebrew_counts)
    blocking = write_report(rows)
    if blocking:
        print(f"{len(blocking)} file(s) blocking — not writing Hebrew YAML for those")
    if write:
        write_yaml_files(rows, hebrew_words)


if __name__ == "__main__":
    main()
