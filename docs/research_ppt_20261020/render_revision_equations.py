"""Render editable SVG and transparent PNG math for the revised deck.

The LaTeX-like math source below is the editable formula source.  Matplotlib
mathtext is used only for typography; no scientific values are calculated.
"""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUT = Path(__file__).parent / 'revision_equations'
OUT.mkdir(exist_ok=True)
plt.rcParams.update({'mathtext.fontset': 'stix', 'font.family': 'STIXGeneral',
                     'svg.fonttype': 'path'})

EQ = {
 'geometry': r'\mathbf{s}_m=\mathbf{s}_c+300[\cos(m\pi/3),\ \sin(m\pi/3)]^T\ \mathrm{m}',
 'channel': r'\mathbf{H}^{\mathrm{true}}_{klg}=\sqrt{\beta_{kl}}\,\mathbf{L}_{\mathrm{rx}}\boldsymbol{\Xi}_{klg}\ \in\mathbb{C}^{4\times64}',
 'posterior': r'\mathbf{C}_{klg}=\left(\mathbf{C}_{0,kl}^{-1}+\mathbf{I}/n_c+\mathbf{P}_{\mathrm{SRS}}^H\mathbf{P}_{\mathrm{SRS}}/n_s\right)^{-1}',
 'estimate': r'\widehat{\mathbf{H}}_{klg}=\mathbf{C}_{klg}\left(\mathbf{Y}_{c}/n_c+\mathbf{P}_{\mathrm{SRS}}^H\mathbf{Y}_{s}/n_s\right)',
 'power': r'\sum_g\nu_g\sum_j\|\mathbf{w}_{ljg}\|_F^2\leq P_l',
 'effective': r'\mathbf{F}_{kjg}=\sum_l\mathbf{H}_{klg}\mathbf{w}_{ljg}\ \in\mathbb{C}^{4\times r_{jg}}',
 'covariance': r'\mathbf{R}^{yy}_{kg}=\mathbf{I}+\sum_j\mathbf{F}_{kjg}\mathbf{F}_{kjg}^H+\sum_l p_{lg}\mathbf{C}_{klg}',
 'rate': r'R_{kg}^{\mathrm{SE}}=\log_2\det\!\left(\mathbf{I}+\mathbf{F}_{kkg}^H\mathbf{R}_{kg}^{-1}\mathbf{F}_{kkg}\right)',
 'receiver': r'\mathbf{A}_{kg}=\left(\mathbf{R}^{yy}_{kg}\right)^{-1}\mathbf{F}_{kkg}',
 'mse': r'\mathbf{E}_{kg}=\mathbf{I}-\mathbf{A}_{kg}^H\mathbf{F}_{kkg}-\mathbf{F}_{kkg}^H\mathbf{A}_{kg}+\mathbf{A}_{kg}^H\mathbf{R}^{yy}_{kg}\mathbf{A}_{kg}',
 'weight': r'\boldsymbol{\Omega}_{kg}=\mathbf{E}_{kg}^{-1}',
 'admm_linear': r'\left(\nu_g\mathbf{Q}_g+\frac{\rho}{2}\mathbf{I}\right)\mathbf{x}_g=\nu_g\mathbf{B}_g+\frac{\rho}{2}(\mathbf{z}_g-\mathbf{y}_g)',
 'admm_update': r'\mathbf{z}=\Pi_{\mathcal{C}}(\mathbf{x}+\mathbf{y}),\qquad\mathbf{y}^{+}=\mathbf{y}+\mathbf{x}-\mathbf{z}',
 'noise': r'n_s=\beta_{kl}\,10^{-\gamma_s/10}\exp(2t_s/\tau)',
 'robust': r'\mathcal{U}_{kl}=\{\mathbf{e}:\mathbf{e}^H\boldsymbol{\Sigma}_{kl}^{-1}\mathbf{e}\leq\delta_{kl}\}',
 'proposal': r'\max_{\mathbf{w}}\ \min_{\mathbf{e}\in\mathcal{U}}U(R(\mathbf{w},\mathbf{e}))-\lambda_p\sum_l p_l-\lambda_s\sum_{l,k}\|\mathbf{w}_{lk}\|_F',
}

for name, expr in EQ.items():
    fig = plt.figure(figsize=(1, 1), facecolor='none')
    fig.text(0, 0, f'${expr}$', fontsize=27, color='black')
    for ext in ('png', 'svg'):
        fig.savefig(OUT / f'{name}.{ext}', dpi=320, transparent=True,
                    bbox_inches='tight', pad_inches=0.04)
    plt.close(fig)

(OUT / 'equations.tex').write_text('\n'.join(
    f'% {name}\n\\[{expr}\\]\n' for name, expr in EQ.items()), encoding='utf-8')
print(f'{len(EQ)} equations rendered to {OUT}')



