"""Check exported study files and optionally make visual review sheets."""

from pathlib import Path
import re
import sys

from pypdf import PdfReader
from PIL import Image

root = Path(__file__).resolve().parent
atlas = root / "atlas"
assert len(PdfReader(root / "FORMULA_TRACE.pdf").pages) == 16
assert len(PdfReader(atlas / "STUDY_ATLAS.pdf").pages) == 16
tex = (root / "FORMULA_TRACE.tex").read_text(encoding="utf-8")
for prefix, count in (("C", 38), ("L", 17), ("Z", 3), ("R", 4)):
    for n in range(1, count + 1):
        assert f"\\fe{{{prefix}{n:02d}}}" in tex, f"Missing {prefix}{n:02d}"
for n in range(1, 17):
    pages = list(atlas.glob(f"{n:02d}_*.pdf"))
    assert len(pages) == 1, (n, pages)
    stem = pages[0].stem
    assert (atlas / f"{stem}.svg").stat().st_size > 1000
    assert (atlas / f"{stem}.png").stat().st_size > 1000
    assert len(PdfReader(pages[0]).pages) == 1
for path, min_text in ((root / "FORMULA_TRACE.pdf", 3000), (atlas / "STUDY_ATLAS.pdf", 1000)):
    extracted = "".join(page.extract_text() or "" for page in PdfReader(path).pages)
    assert len(extracted) > min_text, (path.name, len(extracted))
log_path = root / "FORMULA_TRACE.log"
if log_path.exists():
    log = log_path.read_text(encoding="utf-8", errors="replace")
    assert not re.search(r"Missing character:|Overfull \\hbox", log)
    print("PASS: TeX glyph and overflow log")
print("PASS: 16 formula pages, 16 atlas pages, C/L/Z/R IDs, SVG/PNG/PDF triplets, searchable text")

if len(sys.argv) > 1:
    review = Path(sys.argv[1])
    for prefix, columns, width in (("atlas", 3, 480), ("formula", 4, 310)):
        files = sorted(review.glob(f"{prefix}-*.png"))
        expected = 16
        assert len(files) == expected, (prefix, len(files))
        images = [Image.open(path).convert("RGB") for path in files]
        height = round(images[0].height * width / images[0].width)
        rows = (len(images) + columns - 1) // columns
        sheet = Image.new("RGB", (columns * width, rows * height), "white")
        for i, item in enumerate(images):
            sheet.paste(item.resize((width, height)), ((i % columns) * width, (i // columns) * height))
        sheet.save(review / f"{prefix}_contact.png")
        print(f"Visual sheet: {review / (prefix + '_contact.png')}")
