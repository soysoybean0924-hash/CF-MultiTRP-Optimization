"""Merge the sixteen vector diagram pages in numeric order."""

from pathlib import Path
from pypdf import PdfReader, PdfWriter


root = Path(__file__).resolve().parent
pages = sorted(root.glob("[0-1][0-9]_*.pdf"))
if len(pages) != 16:
    raise SystemExit(f"Expected 16 single-page diagrams, found {len(pages)}")
writer = PdfWriter()
for path in pages:
    reader = PdfReader(path)
    if len(reader.pages) != 1:
        raise SystemExit(f"Expected one page in {path.name}")
    writer.add_page(reader.pages[0])
writer.add_metadata({"/Title": "CHASI study atlas", "/Subject": "Source-traced research diagrams"})
with (root / "STUDY_ATLAS.pdf").open("wb") as stream:
    writer.write(stream)
print(f"Merged {len(pages)} vector pages")
