"""Render only the two new equations used by the enhanced deck.

Older equation assets remain byte-for-byte as in the prior delivery.
"""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

out = Path(__file__).parent / 'enhanced_equations'
out.mkdir(exist_ok=True)
plt.rcParams.update({'mathtext.fontset':'stix', 'font.family':'STIXGeneral',
                     'svg.fonttype':'path'})
expressions = {
    'ue_radius': r'r=\sqrt{r_{\min}^{2}+u(r_{\max}^{2}-r_{\min}^{2})},\qquad u\sim\mathcal{U}(0,1)',
    'rx_factor': r'\mathbf{L}_{\mathrm{rx}}\mathbf{L}_{\mathrm{rx}}^{H}=\mathbf{R}_{\mathrm{rx}},\quad \Xi(a,m)\sim\mathcal{CN}(0,1)',
}
for name, expression in expressions.items():
    fig=plt.figure(figsize=(1,1),facecolor='none')
    fig.text(0,0,f'${expression}$',fontsize=27,color='black')
    for extension in ('png','svg'):
        fig.savefig(out/f'{name}.{extension}',dpi=320,transparent=True,
                    bbox_inches='tight',pad_inches=.04)
    svg = out/f'{name}.svg'
    svg.write_text('\n'.join(line.rstrip() for line in svg.read_text(encoding='utf-8').splitlines())+'\n',encoding='utf-8')
    plt.close(fig)
(out/'equations.tex').write_text('\n'.join(f'\\[{v}\\]' for v in expressions.values()),encoding='utf-8')
