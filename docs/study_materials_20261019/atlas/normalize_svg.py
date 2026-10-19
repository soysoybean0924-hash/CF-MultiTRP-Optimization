"""Remove renderer trailing spaces from SVG without changing geometry."""

from pathlib import Path
from xml.etree import ElementTree

root = Path(__file__).resolve().parent
for path in sorted(root.glob("[0-1][0-9]_*.svg")):
    source = path.read_text(encoding="utf-8")
    clean = "\n".join(line.rstrip() for line in source.splitlines()) + "\n"
    ElementTree.fromstring(clean)
    path.write_text(clean, encoding="utf-8", newline="\n")
print("Normalized 16 SVG files")
