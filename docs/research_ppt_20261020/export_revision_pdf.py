"""Export revised PowerPoint to PDF with a dedicated PowerPoint COM process."""
from pathlib import Path
import win32com.client

p = Path(__file__).parent
src = p / 'CHASI_研究汇报_修订版_20261020.pptx'
dst = p / 'CHASI_研究汇报_修订版_20261020.pdf'
app = win32com.client.DispatchEx('PowerPoint.Application')
app.Visible = 1
deck = None
try:
    deck = app.Presentations.Open(str(src), WithWindow=False, ReadOnly=True)
    deck.SaveAs(str(dst), 32)
    print(dst)
finally:
    if deck is not None: deck.Close()
    app.Quit()
