"""Render the controlled Markdown syntax in this folder with XeLaTeX.

This deliberately supports only the constructs used by the authored guides:
headings, paragraphs, lists, Markdown pipe tables, inline/display LaTeX math,
bold, inline code and rules. It does not alter any PPT or research code.
"""
from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path


def escape_plain(value: str) -> str:
    return "".join(
        {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "#": r"\#", "_": r"\_", "{": r"\{", "}": r"\}", "~": r"\textasciitilde{}",
         "①": r"\textcircled{1}", "②": r"\textcircled{2}", "③": r"\textcircled{3}", "④": r"\textcircled{4}",
         "⑤": r"\textcircled{5}", "⑥": r"\textcircled{6}", "≠": r"$\ne$"}.get(c, c)
        for c in value
    )


TOKEN = re.compile(r"(\$[^$\n]+\$|`[^`\n]+`|\*\*[^*\n]+\*\*)")


def inline(value: str) -> str:
    parts = []
    for part in TOKEN.split(value):
        if not part:
            continue
        if part.startswith("$") and part.endswith("$"):
            parts.append(part)
        elif part.startswith("`") and part.endswith("`"):
            content = part[1:-1]
            if any(ord(c) > 127 for c in content):
                parts.append(r"\textsf{" + escape_plain(content) + "}")
            else:
                parts.append(r"\path{" + content + "}")
        elif part.startswith("**") and part.endswith("**"):
            parts.append(r"\textbf{" + inline(part[2:-2]) + "}")
        else:
            parts.append(escape_plain(part))
    return "".join(parts)


def table(block: list[str]) -> str:
    rows = [[c.strip() for c in row.strip().strip("|").split("|")] for row in block]
    rows = [row for row in rows if not all(re.fullmatch(r":?-{3,}:?", c) for c in row)]
    cols = len(rows[0])
    if cols == 3:
        widths = [".18", ".39", ".35"]
    elif cols == 5:
        widths = [".17", ".19", ".17", ".15", ".16"]
    else:
        widths = [str(round(.91 / cols, 3))] * cols
    spec = "|" + "|".join("p{" + w + r"\textwidth}" for w in widths) + "|"
    output = [r"\begin{small}", r"\begin{longtable}{" + spec + "}", r"\hline"]
    for i, row in enumerate(rows):
        cells = [inline(c) for c in row]
        if i == 0:
            cells = [r"\textbf{" + c + "}" for c in cells]
        output.append(" & ".join(cells) + r" \\ \hline")
        if i == 0:
            output.append(r"\endfirsthead")
            output.append(r"\hline " + " & ".join(cells) + r" \\ \hline")
            output.append(r"\endhead")
    output += [r"\end{longtable}", r"\end{small}"]
    return "\n".join(output)


def convert(source: str, title: str, compact: bool = False) -> str:
    out = []
    lines = source.splitlines()
    i = 0
    listing = False
    first_heading = True
    while i < len(lines):
        line = lines[i]
        s = line.strip()
        if listing and not s.startswith("- "):
            out.append(r"\end{itemize}")
            listing = False
        if not s:
            out.append("")
        elif s == r"\[":
            math = [s]
            i += 1
            while i < len(lines):
                math.append(lines[i])
                if lines[i].strip() == r"\]":
                    break
                i += 1
            out.extend(math)
        elif s.startswith("|"):
            block = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                block.append(lines[i])
                i += 1
            out.append(table(block))
            continue
        elif s.startswith("# "):
            if not (compact and first_heading):
                out.append(r"\clearpage\section*{" + inline(s[2:]) + "}")
                if not compact:
                    out.append(r"\addcontentsline{toc}{section}{" + inline(s[2:]) + "}")
            first_heading = False
        elif s.startswith("## "):
            out.append(r"\subsection*{" + inline(s[3:]) + "}")
        elif s.startswith("### "):
            out.append(r"\subsubsection*{" + inline(s[4:]) + "}")
        elif s == "---":
            out.append(r"\par\medskip\hrule\medskip")
        elif s.startswith("> "):
            out.append(r"\begin{quote}\small " + inline(s[2:]) + r"\end{quote}")
        elif s.startswith("- "):
            if not listing:
                out.append(r"\begin{itemize}[leftmargin=2em,itemsep=1pt]")
                listing = True
            out.append(r"\item " + inline(s[2:]))
        else:
            out.append(inline(s) + r"\par")
        i += 1
    if listing:
        out.append(r"\end{itemize}")
    header = r"""\documentclass[11pt,a4paper]{ctexart}
\usepackage[margin=18mm,headheight=15pt]{geometry}
\usepackage{amsmath,amssymb,mathtools,bm,longtable,array,enumitem,xcolor,hyperref,fancyhdr,url}
\hypersetup{colorlinks=true,linkcolor=blue!55!black,pdfauthor={CHASI research notes},pdftitle={""" + escape_plain(title) + r"""}}
\setlength{\parindent}{2em}
\setlength{\parskip}{4pt}
\setlength{\emergencystretch}{3em}
\allowdisplaybreaks
\pagestyle{fancy}\fancyhf{}\fancyfoot[C]{\thepage}
\begin{document}
\begin{center}\LARGE\bfseries """ + escape_plain(title) + r"""\end{center}
"""
    if not compact:
        header += r"\tableofcontents\clearpage" + "\n"
    return header + "\n".join(out) + "\n\\end{document}\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("markdown", type=Path)
    ap.add_argument("--title", default="茶思研究汇报讲解稿")
    ap.add_argument("--compact", action="store_true", help="omit TOC and repeated title (for the live cheat sheet)")
    args = ap.parse_args()
    src = args.markdown.resolve()
    tex = src.with_suffix(".tex")
    tex.write_text(convert(src.read_text(encoding="utf-8-sig"), args.title, args.compact), encoding="utf-8")
    for _ in range(2):
        result = subprocess.run(
            ["xelatex", "-interaction=nonstopmode", "-halt-on-error", "-file-line-error", tex.name],
            cwd=tex.parent, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace", timeout=180,
        )
        if result.returncode:
            print(result.stdout[-6000:])
            raise SystemExit(result.returncode)
    print(tex.with_suffix(".pdf"))


if __name__ == "__main__":
    main()
