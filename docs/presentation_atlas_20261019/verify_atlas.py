from pathlib import Path
from pypdf import PdfReader
from PIL import Image

root=Path(__file__).resolve().parent
stems=["01_research_framework","02_scene_cooperation","03_method_timescales",
       "04_wmmse_admm","05_nonuniform_robustness","06_execution_evidence"]
pdf=PdfReader(root/"PRESENTATION_ATLAS.pdf")
assert len(pdf.pages)==6
for i,p in enumerate(pdf.pages):
    w,h=float(p.mediabox.width),float(p.mediabox.height)
    assert abs(w/h-16/9)<0.001,(i,w,h)
    assert len(p.extract_text())>120
for s in stems:
    svg=root/"figures"/(s+".svg")
    png=root/"figures"/(s+".png")
    assert svg.exists() and "<svg" in svg.read_text(encoding="utf-8")
    assert Image.open(png).size==(3520,1980)
print("PASS: 6 searchable 16:9 PDF pages and 6 editable SVG / 3520x1980 PNG pairs")
