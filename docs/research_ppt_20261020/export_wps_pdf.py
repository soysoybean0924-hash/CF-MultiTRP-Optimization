"""Export the enhanced deck to PDF with local WPS Presentation COM.

The source PPTX is opened read-only and never re-saved.
"""
from pathlib import Path
import win32com.client

root = Path(__file__).parent
src = root / 'CHASI_研究汇报_图示增强版_20261020.pptx'
dst = src.with_suffix('.pdf')
app = win32com.client.DispatchEx('KWPP.Application')
deck = None
try:
    deck = app.Presentations.Open(str(src), ReadOnly=True, WithWindow=False)
    print('opened', deck.Slides.Count, flush=True)
    deck.SaveAs(str(dst), 32)
    print('exported', dst, flush=True)
finally:
    if deck is not None: deck.Close()
    app.Quit()
