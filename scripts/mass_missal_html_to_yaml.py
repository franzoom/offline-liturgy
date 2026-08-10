#!/usr/bin/env python3
"""
Convert mass_missal HTML source fragments (TinyMCE exports) to YAML.

Each input file's converted text is written to a sibling `<stem>.yaml`
file under a single top-level key named after the file's stem:

    ouverture: |-
      [center][title][rubric]OUVERTURE DE LA CELEBRATION[/rubric][/title][/center]

      [rubric]Lorsque le peuple est rassemble ...[/rubric]
      ...

Conversion rules (confirmed with the user):
  - HTML entities are decoded to real characters (stdlib HTMLParser).
  - Each <p> becomes a paragraph, paragraphs separated by a blank line.
  - <hr /> becomes its own block: [section]
  - class "rubrica" -> wrapped in [rubric]...[/rubric]
  - class "body_3" combined with "rubrica" on the SAME element (the
    all-caps section headers) -> also wrapped in [title]...[/title].
    Plain "body_3" (the spoken-formula text, without rubrica) is left
    untagged, per the user's decision to reserve [title] for section
    headers only.
  - style="text-align: center" -> wrapped in [center]...[/center]
  - <em> -> wrapped in %...% (italic, matches the existing convention
    used elsewhere in this repo's YAML content, e.g. underscore_to_percent_italic.py)
  - <span class="capolettera_piccolo|capolettera_grande"> -> the span is
    dropped, its text (the drop-cap letter) is kept inline.
  - <br /> -> a single line break within the current paragraph.
  - &nbsp; -> a run of one or more consecutive &nbsp; collapses to a
    single '>' (matches the existing "hanging indent" marker convention,
    see assets/mass_missal/eucharistic_prayers/christmas.yaml, and the
    indentLevel stacking logic in aelf-flutter's YamlTextParser).

Note: as of writing, aelf-flutter's YamlTextParser only understands
[rubric]/[/rubric], %..%  and leading '>'. It does NOT yet understand
[title], [center] or [section] -- those are expected to be added to the
parser separately.

Usage:
  python3 scripts/mass_missal_html_to_yaml.py                  # all .html in assets/mass_missal/elements/
  python3 scripts/mass_missal_html_to_yaml.py path/to/one.html [more.html ...]
  python3 scripts/mass_missal_html_to_yaml.py --dry-run [...]  # print instead of writing
"""

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

DEFAULT_DIR = (
    Path(__file__).resolve().parent.parent / "assets" / "mass_missal" / "elements"
)

VOID_TAGS = {"br", "hr", "img", "meta", "link", "input"}
NBSP_RUN_RE = re.compile(r"(?: [ \t]*)+")
BARE_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+$")


class Node:
    __slots__ = ("tag", "attrs", "children")

    def __init__(self, tag, attrs=None):
        self.tag = tag
        self.attrs = attrs or {}
        self.children = []


class TreeBuilder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("#root")
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = Node(tag, dict((k, v or "") for k, v in attrs))
        self.stack[-1].children.append(node)
        if tag not in VOID_TAGS:
            self.stack.append(node)

    def handle_endtag(self, tag):
        if tag in VOID_TAGS:
            return
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                return

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def find_first(node, tag):
    if node.tag == tag:
        return node
    for child in node.children:
        if isinstance(child, Node):
            found = find_first(child, tag)
            if found:
                return found
    return None


def has_class(attrs, name):
    return name in (attrs.get("class") or "").split()


def is_centered(attrs):
    style = (attrs.get("style") or "").replace(" ", "").lower()
    return "text-align:center" in style


def render_inline(node, ctx):
    """ctx: {'center': bool, 'rubric': bool, 'title': bool} -- tracks which
    wrappers are already open on an ancestor, so the same feature is never
    double-wrapped when nested markup repeats it (e.g. two nested
    text-align:center elements)."""
    if isinstance(node, str):
        return node

    if node.tag == "br":
        return "\n"

    is_title_here = (
        has_class(node.attrs, "body_3")
        and has_class(node.attrs, "rubrica")
        and not ctx["title"]
    )
    is_rubric_here = has_class(node.attrs, "rubrica") and not ctx["rubric"]
    is_center_here = is_centered(node.attrs) and not ctx["center"]

    child_ctx = dict(ctx)
    if is_title_here:
        child_ctx["title"] = True
    if is_rubric_here:
        child_ctx["rubric"] = True
    if is_center_here:
        child_ctx["center"] = True

    inner = "".join(render_inline(c, child_ctx) for c in node.children)
    # Only strip a *leading* stray "\n" (from a decorative <br/> placed
    # before any real content, e.g. before a centered title). A trailing
    # "\n" is kept -- it usually separates two sibling instructions (e.g.
    # two consecutive rubrica spans) and must stay, or their text would
    # run together with no separator.
    inner = inner.lstrip("\n")

    if node.tag == "em":
        inner = f"%{inner}%"

    if is_rubric_here:
        inner = f"[rubric]{inner}[/rubric]"
    if is_title_here:
        inner = f"[title]{inner}[/title]"
    if is_center_here:
        inner = f"[center]{inner}[/center]"

    return inner


BASE_CTX = {"center": False, "rubric": False, "title": False}


def normalize_paragraph(text):
    text = NBSP_RUN_RE.sub(">", text)
    lines = [line.strip() for line in text.split("\n")]
    lines = [line for line in lines if line]
    return "\n".join(lines)


def convert_html(html_text):
    builder = TreeBuilder()
    builder.feed(html_text)
    root = builder.root

    body = find_first(root, "body")
    container = body if body is not None else root

    blocks = []
    for child in container.children:
        if not isinstance(child, Node):
            continue
        if child.tag == "p":
            raw = render_inline(child, BASE_CTX)
            text = normalize_paragraph(raw)
            if text and text != ">":
                blocks.append(text)
        elif child.tag == "hr":
            blocks.append("[section]")

    return "\n\n".join(blocks)


def yaml_key(name):
    return name if BARE_KEY_RE.match(name) else f'"{name}"'


def to_yaml(key, content):
    lines = [f"{yaml_key(key)}: |-"]
    for line in content.split("\n"):
        lines.append(f"  {line}" if line else "")
    return "\n".join(lines) + "\n"


def process_file(path: Path, dry_run: bool) -> bool:
    html_text = path.read_text(encoding="utf-8")
    content = convert_html(html_text)

    if not content.strip():
        print(f"  skip {path.name}: no <p>/<hr> content found")
        return False

    yaml_text = to_yaml(path.stem, content)
    out_path = path.with_suffix(".yaml")

    if dry_run:
        print(f"--- {out_path.name} (dry-run) ---")
        print(yaml_text)
    else:
        out_path.write_text(yaml_text, encoding="utf-8")
        print(f"  wrote {out_path.name}")
    return True


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if args:
        files = [Path(a) for a in args]
    else:
        files = sorted(DEFAULT_DIR.glob("*.html"))

    converted = 0
    for path in files:
        if not path.exists():
            print(f"  missing {path}")
            continue
        if process_file(path, dry_run):
            converted += 1

    print(f"\n{converted}/{len(files)} file(s) converted.")


if __name__ == "__main__":
    main()
