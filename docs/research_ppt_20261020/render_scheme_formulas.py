"""Render formula image assets for rebuild_scheme_v2.py (Python 3.9 runtime)."""
import json
import sys
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

out=Path(sys.argv[1]);out.mkdir(exist_ok=True)
formulas=json.loads(sys.argv[2])
plt.rcParams.update({'mathtext.fontset':'stix','font.family':'STIXGeneral','svg.fonttype':'path'})
tex=[]
for name,expr in formulas.items():
    fig=plt.figure(figsize=(1,1),facecolor='none')
    fig.text(0,0,f'${expr}$',fontsize=29,color='black')
    for ext in ('png','svg'):
        fig.savefig(out/f'{name}.{ext}',dpi=330,transparent=True,
                    bbox_inches='tight',pad_inches=.04)
    plt.close(fig)
    tex.append(f'% {name}\n\\[{expr}\\]\n')
(out/'scheme_v2_equations.tex').write_text('\n'.join(tex),encoding='utf-8')
