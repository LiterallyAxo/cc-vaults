#!/usr/bin/env python3
"""Download the reference docs this repo works against into docs/.

    python tools/fetch_docs.py            # everything
    python tools/fetch_docs.py cc         # just CC: Tweaked
    python tools/fetch_docs.py cccbridge  # just CC:C Bridge

Pages are converted to plain markdown so they are cheap to grep and read.
Re-running overwrites, so this doubles as an update command.
"""
import os
import re
import sys
import urllib.request
from html.parser import HTMLParser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
UA = {"User-Agent": "Mozilla/5.0 (cc-vaults docs fetcher)"}

SKIP_TAGS = {"script", "style", "nav", "svg", "button"}
BLOCK_END = {"p", "div", "section", "article", "tr", "dd", "dl", "ul", "ol", "table"}


class ToMarkdown(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skip = 0
        self.pre = 0
        self.list_depth = 0

    def emit(self, text):
        self.out.append(text)

    def handle_starttag(self, tag, attrs):
        if tag in SKIP_TAGS:
            self.skip += 1
            return
        if self.skip:
            return
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self.emit("\n\n" + "#" * int(tag[1]) + " ")
        elif tag == "p":
            self.emit("\n\n")
        elif tag == "br":
            self.emit("\n")
        elif tag == "li":
            self.emit("\n" + "  " * max(0, self.list_depth - 1) + "- ")
        elif tag in ("ul", "ol"):
            self.list_depth += 1
            self.emit("\n")
        elif tag == "pre":
            self.pre += 1
            self.emit("\n\n```lua\n")
        elif tag == "code" and not self.pre:
            self.emit("`")
        elif tag == "dt":
            self.emit("\n\n### ")
        elif tag == "dd":
            self.emit("\n")
        elif tag in ("th", "td"):
            self.emit("| ")
        elif tag == "tr":
            self.emit("\n")

    def handle_endtag(self, tag):
        if tag in SKIP_TAGS:
            self.skip = max(0, self.skip - 1)
            return
        if self.skip:
            return
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self.emit("\n")
        elif tag == "tr":
            self.emit(" |")
        elif tag in ("th", "td"):
            self.emit(" ")
        elif tag == "pre":
            self.pre = max(0, self.pre - 1)
            self.emit("\n```\n")
        elif tag == "code" and not self.pre:
            self.emit("`")
        elif tag in ("ul", "ol"):
            self.list_depth = max(0, self.list_depth - 1)
            self.emit("\n")
        elif tag in BLOCK_END:
            self.emit("\n")

    def handle_data(self, data):
        if self.skip:
            return
        if self.pre:
            self.emit(data)
        elif data.strip():
            self.emit(re.sub(r"\s+", " ", data))
        elif data:
            self.emit(" ")

    def result(self):
        text = "".join(self.out)
        text = text.replace("¶", "")                     # mkdocs permalinks
        text = re.sub(r"(?m)^(#+ .*?)\s*Source\s*$", r"\1", text)  # tweaked.cc ones
        text = re.sub(r"[ \t]+\n", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        text = re.sub(r"[ \t]{2,}", " ", text)
        text = re.sub(r"(?m)^\|\s*\|", "|", text)             # empty leading cell
        return text.strip() + "\n"


def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=45) as resp:
        return resp.read().decode("utf-8", "replace")


def slice_element(html, tag, attr):
    """Return the inner html of the first <tag ...attr...> element."""
    start = re.search(r"<%s[^>]*%s[^>]*>" % (tag, attr), html)
    if not start:
        return html
    depth, pos = 1, start.end()
    pattern = re.compile(r"</?%s\b" % tag)
    while depth and pos < len(html):
        m = pattern.search(html, pos)
        if not m:
            break
        depth += -1 if m.group(0).startswith("</") else 1
        pos = m.end()
    return html[start.end(): pos - len(tag) - 3]


def to_markdown(html, tag="section", attr='id="content"'):
    parser = ToMarkdown()
    parser.feed(slice_element(html, tag, attr))
    return parser.result()


def save(relpath, title, source, body):
    path = os.path.join(DOCS, relpath)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("<!-- fetched from %s -->\n# %s\n\n%s" % (source, title, body))
    return path


def fetch_cc_tweaked():
    base = "https://tweaked.cc/"
    index = get(base)
    links = sorted(set(re.findall(r'href="([^"#?]+\.html)"', index)))
    links = [l for l in links if not l.startswith(("http", "//"))]
    print("CC: Tweaked -- %d pages" % (len(links) + 1))

    save("cc-tweaked/index.md", "CC: Tweaked index", base, to_markdown(index))
    for i, link in enumerate(links, 1):
        try:
            html = get(base + link)
        except Exception as exc:                      # noqa: BLE001
            print("  !! %s: %s" % (link, exc))
            continue
        title = link[:-5].replace("/", " / ").replace("_", " ")
        save("cc-tweaked/%s.md" % link[:-5], title, base + link, to_markdown(html))
        if i % 20 == 0:
            print("  %d/%d" % (i, len(links)))
    print("  done")


def fetch_cccbridge():
    # mkdocs-material site: the sitemap lists every page, and the body lives in
    # <article class="md-content__inner ...">
    base = "https://cccbridge.kleinbox.dev/"
    pages = re.findall(r"<loc>([^<]+)</loc>", get(base + "sitemap.xml"))
    print("CC:C Bridge -- %d pages" % len(pages))

    for url in pages:
        try:
            html = get(url)
        except Exception as exc:                      # noqa: BLE001
            print("  !! %s: %s" % (url, exc))
            continue
        body = to_markdown(html, "article", 'class="md-content__inner')
        name = url[len(base):].strip("/").replace("/", "-") or "index"
        save("cccbridge/%s.md" % name, "CC:C Bridge / " + name, url, body)
    print("  done")


TARGETS = {"cc": fetch_cc_tweaked, "cccbridge": fetch_cccbridge}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(TARGETS)
    for name in wanted:
        if name not in TARGETS:
            sys.exit("unknown target %r; pick from %s" % (name, ", ".join(TARGETS)))
        TARGETS[name]()
