"""Generate research/index.qmd from the Overleaf CV (main.tex).

The CV is the source of truth. This reads the Publications, Working Papers and
Presentations sections and writes them out as the website's Research page.

    python3 scripts/cv_to_research.py path/to/main.tex research/index.qmd
"""
import re
import sys

SECTIONS = ["Publications", "Working Papers", "Presentations"]


def strip_comment(line):
    # drop an unescaped % and everything after it
    return re.split(r"(?<!\\)%", line, maxsplit=1)[0].rstrip()


def balanced(s, i):
    """Return (content, end) for the {...} group that opens at s[i]."""
    depth = 0
    for j in range(i, len(s)):
        if s[j] == "{":
            depth += 1
        elif s[j] == "}":
            depth -= 1
            if depth == 0:
                return s[i + 1:j], j + 1
    return s[i + 1:], len(s)


def tex_to_md(s):
    s = s.replace("\\me{}", "\\me").replace("\\me", "**Dada, J.**")
    s = re.sub(r"\\textit\{([^{}]*)\}", r"*\1*", s)
    s = re.sub(r"\\emph\{([^{}]*)\}", r"*\1*", s)
    s = re.sub(r"\\textbf\{([^{}]*)\}", r"**\1**", s)
    s = re.sub(r"\\href\{([^{}]*)\}\{([^{}]*)\}", r"[\2](\1)", s)
    for a, b in [("\\&", "&"), ("---", "—"), ("--", "–"), ("``", "“"), ("''", "”"),
                 ("\\~n", "ñ"), ("\\'e", "é"), ("\\'a", "á"), ("\\'i", "í"), ("\\'o", "ó"),
                 ("\\textperiodcentered", "·"), ("~", " "), ("\\ ", " ")]:
        s = s.replace(a, b)
    s = re.sub(r"\\[a-zA-Z]+\*?", "", s)  # any other command
    return re.sub(r"\s+", " ", s).strip()


def paper(item):
    """Format an item with a quoted title as: bold title, coauthors, status."""
    m = re.match(r"(.*?)``(.*?)''\s*(.*)", item, re.S)
    if not m:
        return tex_to_md(item)
    authors, title, rest = m.groups()
    title = tex_to_md(title).rstrip(".")
    # authors are APA style ("Last, F. M., Last, F., & Last, F."); show them as "F. M. Last"
    names = [f"{init.strip()} {last}" for last, init in
             re.findall(r"([A-Z][^\s,&*]+(?: [A-Z][^\s,&*.]+)*), ((?:[A-Z]\.\s?)+)", tex_to_md(authors))
             if last != "Dada"]
    lines = [f"**{title}**"]
    if names:
        lines.append("With " + (", ".join(names[:-1]) + ", and " + names[-1] if len(names) > 2
                                else " and ".join(names)) + ".")
    status = tex_to_md(rest).rstrip(".")
    if status:
        lines.append(status + ".")
    return " \\\n".join(lines)


def parse(tex):
    lines = [strip_comment(l) for l in tex.splitlines()]
    out, section, sub = {}, None, None
    buf = "\n".join(lines)
    for m in re.finditer(r"\\(section|subsection)\*\{([^}]*)\}|\\item\s|\\dated\{", buf):
        if m.group(1) == "section":
            section = m.group(2) if m.group(2) in SECTIONS else None
            sub = None
            continue
        if section is None:
            continue
        if m.group(1) == "subsection":
            sub = m.group(2)
            continue
        if m.group(0).startswith("\\dated"):
            text, end = balanced(buf, m.end() - 1)
            date, _ = balanced(buf, end) if end < len(buf) and buf[end] == "{" else ("", end)
            entry = tex_to_md(text) + (f" {tex_to_md(date)}." if date else "")
        else:
            nxt = re.search(r"\\item\s|\\end\{|\\(sub)?section\*", buf[m.end():])
            text = buf[m.end():m.end() + nxt.start()] if nxt else buf[m.end():]
            entry = paper(text) if "``" in text else tex_to_md(text)
        out.setdefault(section, {}).setdefault(sub, []).append(entry)
    return out


def render(data):
    md = ["---", 'title: "Research"', "---", "",
          "<!-- Generated from my CV by scripts/cv_to_research.py. Edit the CV in Overleaf, not this file. -->", ""]
    for section in SECTIONS:
        if section not in data:
            continue
        md += [f"## {section}", ""]
        for sub, entries in data[section].items():
            if sub:
                md += [f"### {sub}", ""]
            for e in entries:
                md += [e, ""]
    return "\n".join(md)


if __name__ == "__main__":
    src, dest = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as f:
        page = render(parse(f.read()))
    with open(dest, "w", encoding="utf-8") as f:
        f.write(page)
