"""Build an indexed HTML reader from the editable, authoritative TeX file.

Documentation tooling only. It does not participate in formal MATLAB runs.
The searchable PDF is available when a browser cannot load MathJax.
"""
from __future__ import annotations

import html
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "CHASI_UNIFIED_TRACE.tex"
TARGET = Path(__file__).with_name("formula_reader.html")


def groups(line: str) -> list[str]:
    result: list[str] = []
    pos = len(r"\fe")
    while pos < len(line):
        if line[pos] != "{":
            break
        depth = 1
        start = pos + 1
        pos += 1
        while depth and pos < len(line):
            if line[pos] == "{" and line[pos - 1] != "\\":
                depth += 1
            elif line[pos] == "}" and line[pos - 1] != "\\":
                depth -= 1
            pos += 1
        if depth:
            raise ValueError(f"Unbalanced formula line: {line[:80]}")
        result.append(line[start : pos - 1])
    return result


def plain(tex: str) -> str:
    tex = re.sub(r"\\code\{([^{}]*)\}", r"\1", tex)
    tex = re.sub(r"\\textbf\{([^{}]*)\}", r"\1", tex)
    tex = tex.replace(r"\quad", " ").replace(r"\%", "%")
    return html.escape(tex)


def main() -> None:
    source = SOURCE.read_text(encoding="utf-8")
    cards = []
    ids = []
    for line in source.splitlines():
        if not line.startswith(r"\fe{"):
            continue
        parts = groups(line)
        if len(parts) != 5:
            raise ValueError(f"Expected five formula arguments, got {len(parts)}")
        ident, title, latex, meaning, evidence = parts
        ids.append(ident)
        cards.append(
            f'<section id="{ident}"><h2>{ident} · {plain(title)}</h2>'
            f'<div class="equation">\\[{html.escape(latex)}\\]</div>'
            f'<p><b>含义、维度与输入输出：</b>{plain(meaning)}</p>'
            f'<p><b>源码与例子：</b>{plain(evidence)}</p>'
            f'<p><a href="../CHASI_UNIFIED_TRACE.pdf">可检索 PDF</a> · '
            f'<a href="../CHASI_UNIFIED_TRACE.tex">可编辑 TeX</a> · '
            f'<a href="../CHASI_VARIABLE_ACCEPTANCE_20261017.md">变量验收</a></p></section>'
        )
    assert len(cards) == 58 and len(ids) == len(set(ids)), (len(cards), ids)
    nav = " ".join(f'<a href="#{ident}">{ident}</a>' for ident in ids)
    page = f'''<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CHASI 公式与源码阅读版</title>
<style>
body{{font:16px/1.7 system-ui,"Microsoft YaHei",sans-serif;color:#17324e;background:#f6f9fb;margin:0}}
main{{max-width:1060px;margin:auto;padding:32px 28px}}
h1{{font-size:2rem}}nav{{position:sticky;top:0;background:white;padding:12px;line-height:2.2;box-shadow:0 2px 8px #ccd6dd}}
nav a{{margin-right:9px}}section{{background:white;margin:26px 0;padding:24px 30px;border-left:4px solid #2b72a9;border-radius:7px}}
h2{{font-size:1.3rem;margin:0 0 10px}}.equation{{overflow-x:auto;background:#eef5fa;padding:18px 12px;font-size:1.14rem}}
a{{color:#1267a1}}p{{margin:8px 0}}small{{color:#526474}}</style>
<script>window.MathJax={{tex:{{inlineMath:[['$','$']],displayMath:[['\\\\[','\\\\]']],packages:{{'[+]':['ams']}}}},svg:{{fontCache:'global'}}}};</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
</head><body><main><h1>CHASI 公式—变量—源码阅读版</h1>
<p>与 <a href="../CHASI_UNIFIED_TRACE.tex">TeX 源</a> 同步生成，覆盖 C01–C38、L01–L17、Z01–Z03。
正式代码基线 <code>9527089</code>；旧链 L 和参考 Z 均未接入正式入口。
公式渲染依赖浏览器加载 MathJax；离线阅读请用同目录的可检索 PDF。</p>
<nav>{nav}</nav>{''.join(cards)}
<small>生成脚本 build_formula_html.py；浏览器阅读页不参与通信计算。</small></main></body></html>'''
    TARGET.write_text(page, encoding="utf-8")
    print(f"Wrote {TARGET} with {len(cards)} formulas")


if __name__ == "__main__":
    main()
