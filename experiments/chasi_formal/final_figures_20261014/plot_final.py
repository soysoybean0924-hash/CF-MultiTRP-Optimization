"""Replot seven presentation figures from saved CSV, summary and V only."""
from pathlib import Path
import csv
import hashlib
import json
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager

ROOT=Path(__file__).resolve().parents[3]
SRC=ROOT/'experiments/chasi_formal/migration_20261013'
RUN=ROOT/'results/chasi_formal/b3b_uniform_relative210_seed20261027_20261013'
REPLAY=ROOT/'results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013'
OUT=Path(__file__).resolve().parent
KEYS=('matrix_pf_nominal','matrix_pf_uniform_relative','matrix_pf_statistical')
NAMES=('\u540d\u4e49 PF','\u7edf\u4e00\u76f8\u5bf9\u8bef\u5dee PF','\u5f02\u8d28\u8bef\u5dee PF')
COLORS=('#26638e','#b77439','#4d806b')
STYLES=('-','--',':')

def rows(name):
    with (SRC/name).open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def check(value,message):
    if not value: raise ValueError(message)

def save(fig,name):
    fig.savefig(OUT/f'{name}.png',dpi=300,bbox_inches='tight')
    fig.savefig(OUT/f'{name}.pdf',bbox_inches='tight')
    svg=OUT/f'{name}.svg'
    fig.savefig(svg,bbox_inches='tight')
    svg.write_text('\n'.join(line.rstrip() for line in svg.read_text(encoding='utf-8').splitlines())+'\n',encoding='utf-8')
    plt.close(fig)

def style():
    names={x.name for x in font_manager.fontManager.ttflist}
    font=next((x for x in ('Microsoft YaHei','Noto Sans CJK SC','SimHei') if x in names),None)
    check(font is not None,'Chinese font missing')
    mpl.rcParams.update({'font.family':'sans-serif','font.sans-serif':[font,'DejaVu Sans'],
        'axes.unicode_minus':False,'pdf.fonttype':42,'svg.fonttype':'none',
        'font.size':10,'axes.titlesize':12,'axes.labelsize':10,
        'axes.spines.top':False,'axes.spines.right':False,'legend.frameon':False,
        'figure.facecolor':'white','savefig.facecolor':'white'})
    return font

def grid(ax,xlabel,ylabel):
    ax.set(xlabel=xlabel,ylabel=ylabel)
    ax.grid(axis='y',alpha=.23)
    ax.set_axisbelow(True)

def fig1(summary):
    data=rows('fig01_pf_objective.csv')
    x=np.array([int(r['outer']) for r in data])
    y=np.array([float(r['pf_objective_sum_ln_1_plus_R_over_floor']) for r in data])
    check(np.array_equal(x,np.arange(19)) and np.all(np.isfinite(y)),'PF snapshots')
    delta=np.diff(y)
    check(np.all(delta>0),'Log increment axis requires positive values; change representation if future data differ')
    check(summary['config']['pf_rate_floor_bits_per_s_hz']==.001,'PF floor changed')
    fig,ax=plt.subplots(figsize=(12.2,6.7))
    fig.subplots_adjust(left=.11,right=.96,top=.84,bottom=.15)
    ax.plot(x,y,'o-',color=COLORS[0],lw=2.2,ms=5)
    ax.set_xticks(x);ax.set_xlim(-.4,18.4)
    grid(ax,'\u72b6\u6001\u7f16\u53f7\uff080 \u4e3a\u521d\u59cb V\uff0c18 \u4e3a\u7b2c 18 \u6b21\u66f4\u65b0\u540e\uff09',
         '\u4f30\u8ba1\u4fe1\u9053 PF \u5bf9\u6570\u6548\u7528\uff08\u65e0\u91cf\u7eb2\uff09')
    ax.annotate(f'{y[0]:.3f}',xy=(0,y[0]),xytext=(.8,y[0]+25),
                arrowprops={'arrowstyle':'-','color':COLORS[0]},color=COLORS[0])
    ax.annotate(f'{y[-1]:.3f}',xy=(18,y[-1]),xytext=(15.0,y[-1]-40),
                arrowprops={'arrowstyle':'-','color':COLORS[0]},color=COLORS[0])
    inset=ax.inset_axes([.43,.18,.54,.48])
    inset.plot(x[12:],y[12:],'o-',color=COLORS[1],lw=2,ms=4.5)
    inset.set_xticks(x[12:]);inset.set_ylim(y[12]-.05,y[-1]+.05)
    inset.ticklabel_format(axis='y',style='plain',useOffset=False)
    inset.grid(axis='y',alpha=.2)
    inset.set_title('\u540c\u56fe\u653e\u5927\uff1a\u72b6\u6001 12\u201318',loc='left',fontsize=10,weight='bold')
    inset.set_xlabel('\u72b6\u6001\u7f16\u53f7',fontsize=9)
    inset.tick_params(labelsize=8)
    fig.suptitle('\u56fe 1\uff5c\u4f30\u8ba1\u4fe1\u9053 PF \u4f18\u5316\u76ee\u6807\uff1a\u7b2c 18 \u6b21\u66f4\u65b0\u540e\u89e6\u53d1\u505c\u6b62',
                 x=.11,ha='left',fontsize=15,weight='bold')
    save(fig,'final01_pf_trajectory')
    return {'last_delta':float(delta[-1]),'last_relative_delta':float(delta[-1]/y[-2])}

def fig2(summary):
    data=rows('fig02_v_change.csv')
    x=np.array([int(r['update_outer']) for r in data])
    y=np.array([float(r['relative_V_change']) for r in data])
    threshold=np.array([float(r['stop_threshold']) for r in data])
    check(np.array_equal(x,np.arange(18)) and np.all(y>0),'V change data')
    check(np.allclose(threshold,summary['config']['outer_precoder_rel_tol']),'V threshold')
    fig,ax=plt.subplots(figsize=(11.5,5.8))
    fig.subplots_adjust(left=.11,right=.96,top=.82,bottom=.19)
    ax.plot(x,y,'o-',color=COLORS[0],lw=2,ms=5,label='\u5b9e\u9645\u76f8\u5bf9\u53d8\u5316')
    ax.axhline(threshold[0],ls='--',color='#b44b49',lw=1.7,label=f'\u914d\u7f6e\u9608\u503c {threshold[0]:.3f}')
    ax.set_yscale('log');ax.set_xticks(x);ax.set_xlim(-.4,18.6)
    ax.annotate(f'\u672b\u6b21 $\\delta_V$ = {y[-1]:.6f}',xy=(17,y[-1]),xytext=(-95,28),
                textcoords='offset points',fontsize=10,color=COLORS[0],
                arrowprops={'arrowstyle':'-','color':COLORS[0]})
    grid(ax,'V \u66f4\u65b0\u7f16\u53f7 t\uff08\u56fe 1 \u7684\u72b6\u6001 t \u2192 t+1\uff09','\u9884\u7f16\u7801\u76f8\u5bf9\u53d8\u5316 $\\delta_V$')
    ax.legend(loc='upper right',bbox_to_anchor=(1,1.02))
    ax.text(.98,.75,r'$\delta_V=\|V_{t+1}-V_t\|_F/\max(1,\|V_t\|_F)$',
            transform=ax.transAxes,ha='right',va='top',fontsize=10,
            bbox={'boxstyle':'round,pad=.35','fc':'white','ec':'#cbd6dc'})
    fig.suptitle('\u56fe 2\uff5c\u6574\u5957\u590d\u6570\u9884\u7f16\u7801\u7684\u76f8\u90bb\u53d8\u5316\u9010\u6e10\u51cf\u5c0f',
                 x=.11,ha='left',fontsize=15,weight='bold')
    save(fig,'final02_v_change')
    return {'last_change':float(y[-1]),'threshold':float(threshold[0])}

def fig3():
    data=rows('fig03_admm_end_residuals.csv')
    x=np.array([int(r['update_outer']) for r in data])
    primal=np.array([float(r['primal']) for r in data])
    epsp=np.array([float(r['eps_primal']) for r in data])
    dual=np.array([float(r['dual']) for r in data])
    epsd=np.array([float(r['eps_dual']) for r in data])
    rp=primal/epsp; rd=dual/epsd
    n=np.array([int(r['admm_iterations']) for r in data])
    passed=np.array([r['admm_converged'].lower()=='true' for r in data])
    check(np.array_equal(x,np.arange(18)) and np.all(np.isfinite(rp+rd)),'ADMM data')
    fig,ax=plt.subplots(1,2,figsize=(13.0,5.8),sharex=True)
    fig.subplots_adjust(left=.09,right=.97,top=.82,bottom=.16,wspace=.21)
    specs=((ax[0],primal,epsp,COLORS[0],
            'A  \u539f\u59cb\uff1ar=\u2016X\u2212Z\u2016','r \u4e0e\u5176\u9608\u503c\uff08\u8303\u6570\uff09',rp),
           (ax[1],dual,epsd,COLORS[1],
            'B  \u5bf9\u5076\uff1as=\u03c1\u2016Z\u672c\u8f6e\u2212Z\u4e0a\u8f6e\u2016','s \u4e0e\u5176\u9608\u503c\uff08\u8303\u6570\uff09',rd))
    for a,v,limit,color,title,label,ratio in specs:
        a.plot(x,v,'o-',color=color,lw=2.1,ms=5,label='\u8f6e\u672b\u6b8b\u5dee')
        a.plot(x,limit,'--',color='#b44b49',lw=1.8,label='\u5bf9\u5e94\u505c\u6b62\u9608\u503c')
        a.fill_between(x,v,limit,where=v>limit,color='#b44b49',alpha=.16)
        a.set_xticks(np.arange(0,18,2));a.set_xlim(-.3,17.4)
        a.set_ylim(0,max(v.max(),limit.max())*1.22)
        a.set_title(title,loc='left',weight='bold')
        grid(a,'WMMSE \u5916\u8f6e\u7f16\u53f7\uff08\u6bcf\u70b9\u662f\u4e00\u6b21 ADMM \u7ec8\u503c\uff09',label)
        a.legend(loc='upper right',fontsize=8.7)
        a.text(.98,.08,f'\u672b\u8f6e\uff1a\u6b8b\u5dee/\u81ea\u5df1\u9608\u503c = {ratio[-1]:.3f}',
               transform=a.transAxes,ha='right',va='bottom',fontsize=9,
               bbox={'boxstyle':'round,pad=.3','fc':'white','ec':'#cbd6dc'})
    for j in np.flatnonzero(~passed):
        ax[1].scatter(x[j],dual[j],s=130,facecolors='none',edgecolors='#b44b49',lw=2,zorder=5)
    ax[1].annotate(f'\u5916\u8f6e 0\uff1as/\u03b5={rd[0]:.3f}>1\n\u89e6\u53ca {n[0]} \u6b21\u4e0a\u9650',
                   (0,dual[0]),xytext=(1.7,dual[0]*1.08),fontsize=9,
                   arrowprops={'arrowstyle':'->','color':'#b44b49'})
    fig.suptitle('\u56fe 3\uff5c\u6bcf\u8f6e ADMM \u7ec8\u503c\u53ea\u548c\u672c\u9879\u9608\u503c\u6bd4\uff1b\u7b2c 0 \u8f6e\u5bf9\u5076\u9879\u672a\u8fc7',
                 x=.09,ha='left',fontsize=14,weight='bold')
    save(fig,'final03_admm_residuals')
    return {'not_converged_outer':x[~passed].tolist(),'last_primal_ratio':float(rp[-1]),
            'last_dual_ratio':float(rd[-1])}

def fig4(summary,manifest):
    data=rows('fig04_trp_power.csv')
    trp=np.array([int(r['trp_id_1based']) for r in data])
    total=np.array([float(r['weighted_radiated_power_watt']) for r in data])
    budget=np.array([float(r['budget_watt']) for r in data])
    check(np.array_equal(trp,np.arange(1,22)) and np.allclose(budget,20),'Power data')
    counts=np.array([int(g['tx_rb_count']) for g in manifest['groups']])
    check(len(counts)==17 and counts.sum()==136,'Active RB groups')
    w=counts/273
    z=np.load(RUN/'matrix_pf_nominal_precoders.npz')
    raw=np.zeros((21,17))
    for g in range(17):
        v=z[f'V_{g:02d}']
        check(v.dtype==np.complex64 and v.shape[0]==21,'Saved V format')
        raw[:,g]=np.sum(np.abs(v.astype(np.complex128))**2,axis=(1,2,3))
    contribution=raw*w[None,:]
    gap=float(np.max(abs(contribution.sum(axis=1)-total)))
    check(gap<3e-6,'Saved V quantization gap too large')
    with (OUT/'final04_group_power.csv').open('w',newline='',encoding='utf-8-sig') as f:
        writer=csv.writer(f)
        writer.writerow(['trp_id_1based','group_id_1based','active_rb','raw_P_lg_norm2',
                         'weighted_contribution_watt','summary_total_watt','budget_watt'])
        for l in range(21):
            for g in range(17):
                writer.writerow([l+1,g+1,counts[g],f'{raw[l,g]:.12g}',
                                 f'{contribution[l,g]:.12g}',f'{total[l]:.15f}',20])
    fig=plt.figure(figsize=(13.2,9))
    grid_spec=fig.add_gridspec(2,1,left=.09,right=.89,top=.84,bottom=.10,
                              height_ratios=[.65,2.3],hspace=.47)
    a=fig.add_subplot(grid_spec[0]);b=fig.add_subplot(grid_spec[1])
    a.bar(trp,total,color=COLORS[0],width=.74)
    a.axhline(20,color='#b44b49',ls='--',lw=1.6,label='20 W / TRP \u603b\u9884\u7b97')
    a.set_xticks(trp);a.set_ylim(0,22.2)
    a.set_title('A  \u8de8\u7ec4\u52a0\u6743\u603b\u529f\u7387\uff1a\u9884\u7b97\u53ef\u884c\u6027',loc='left',weight='bold')
    grid(a,'TRP \u7f16\u53f7','\u603b\u529f\u7387 P_l\uff08W\uff09')
    a.legend(loc='upper right',bbox_to_anchor=(1,1.29),fontsize=9)
    im=b.imshow(contribution,cmap='Blues',aspect='auto',origin='lower',vmin=0)
    b.set_xticks(np.arange(17))
    b.set_xticklabels([f'{g+1}\n({counts[g]})' for g in range(17)],fontsize=7.8)
    b.set_yticks(np.arange(0,21,2));b.set_yticklabels(np.arange(1,22,2))
    b.set(xlabel='\u8d44\u6e90\u7ec4\u7f16\u53f7\uff08\u62ec\u53f7\u4e3a\u8be5\u7ec4\u6fc0\u6d3b RB \u6570\uff09',ylabel='TRP \u7f16\u53f7')
    b.set_title('B  \u6bcf\u683c\u662f\u4e00\u7ec4\u8ba1\u5165\u8be5 TRP \u603b\u529f\u7387\u7684 W \u6570\uff1b\u6bcf\u884c\u76f8\u52a0\u7ea6 20 W',loc='left',weight='bold')
    c=fig.colorbar(im,ax=b,fraction=.025,pad=.015);c.set_label('\u7ec4\u8d21\u732e $a_g P_{lg}$\uff08W\uff09')
    fig.suptitle('\u56fe 4\uff5c20 W \u7ea6\u675f\u6bcf TRP \u7684\u8de8\u8d44\u6e90\u7ec4\u52a0\u6743\u603b\u548c\uff0c\u800c\u975e\u6bcf\u7ec4\u5404 20 W',
                 x=.09,ha='left',fontsize=15,weight='bold')
    save(fig,'final04_power_and_groups')
    return {'active_groups':int(np.count_nonzero(counts)),'active_rb':int(counts.sum()),
            'saved_v_dtype':'complex64','max_summary_vs_saved_v_rounding_watt':gap,
            'contribution_active_min_max':[float(contribution[:,w>0].min()),float(contribution.max())]}

def static():
    data=rows('fig05_static_per_ue.csv')
    check(len(data)==210 and [int(r['ue_id_0based']) for r in data]==list(range(210)),'UE IDs')
    values=[np.array([float(r[key]) for r in data]) for key in KEYS]
    qrows=rows('fig06_static_bottom5.csv')
    check([r['branch'] for r in qrows]==list(KEYS),'Branch order')
    q=[float(r['linear_bottom5_mbps']) for r in qrows]
    for v,t in zip(values,q):
        check(np.all(np.isfinite(v)) and np.isclose(np.percentile(v,5),t,atol=1e-10),'q05 mismatch')
    return values,q

def fig5(values,q):
    fig=plt.figure(figsize=(13.2,6.8))
    gs=fig.add_gridspec(1,2,left=.08,right=.97,top=.75,bottom=.19,
                        width_ratios=[1.5,1],wspace=.27)
    a=fig.add_subplot(gs[0]);b=fig.add_subplot(gs[1])
    for v,t,name,color,style in zip(values,q,NAMES,COLORS,STYLES):
        ordered=np.sort(v);y=np.arange(1,211)/210
        for ax in (a,b):
            ax.step(ordered,y,where='post',color=color,ls=style,lw=2,label=name)
        a.plot(t,.05,marker='o',color=color,ms=6,zorder=5)
        a.vlines(t,0,.05,color=color,linestyles=style,alpha=.7,lw=1)
    for ax in (a,b):ax.axhline(.05,color='#68747a',ls='-.',lw=1)
    a.set_xlim(0,1.6);a.set_ylim(0,.125)
    a.set_xticks(np.arange(0,1.61,.2));a.set_yticks([0,.025,.05,.075,.1,.125])
    a.set_title('A  \u5de6\u5c3e\u4e3b\u56fe\uff1a\u7ea6\u6700\u4f4e 10% UE \u6240\u5728\u533a\u57df',loc='left',weight='bold')
    grid(a,'\u9759\u6001\u4e1a\u52a1/\u5bb9\u91cf\u4ee3\u7406\u901f\u7387\uff08Mbps\uff09','\u7d2f\u8ba1 UE \u6bd4\u4f8b')
    b.set_xlim(0,max(float(v.max()) for v in values)*1.03);b.set_ylim(0,1.02)
    b.set_title('B  210 UE \u5168\u5206\u5e03',loc='left',weight='bold')
    grid(b,'\u9759\u6001\u4e1a\u52a1/\u5bb9\u91cf\u4ee3\u7406\u901f\u7387\uff08Mbps\uff09','\u7d2f\u8ba1 UE \u6bd4\u4f8b')
    h,l=a.get_legend_handles_labels()
    fig.legend(h,l,loc='upper left',bbox_to_anchor=(.08,.87),ncol=3,fontsize=9.3,handlelength=3)
    fig.suptitle('\u56fe 5\uff5c\u4e09\u5206\u652f\u7684\u9010 UE \u9759\u6001\u4ee3\u7406 CDF\uff1a\u5de6\u5c3e\u66f2\u7ebf\u53ef\u4ea4\u53c9',
                 x=.08,ha='left',fontsize=15,weight='bold')
    for i,(name,t,color) in enumerate(zip(NAMES,q,COLORS)):
        fig.text(.09+.29*i,.085,f'{name}  5% = {t:.6f} Mbps',color=color,fontsize=9.2,weight='bold')
    save(fig,'final05_static_cdf_left_tail')
    return {'q05_linear_mbps':q,'sample_count_each':210,'left_tail_xlim_mbps':[0,1.6]}

def fig6(q):
    fig,ax=plt.subplots(figsize=(10.8,5.8))
    fig.subplots_adjust(left=.14,right=.96,top=.78,bottom=.2)
    x=np.arange(3);v=np.array(q)
    ax.bar(x,v,color=COLORS,width=.58);ax.set_xticks(x,NAMES);ax.set_ylim(0,.92)
    for i,t in enumerate(v):
        ax.text(i,t+.018,f'{t:.6f}',ha='center',va='bottom',fontsize=10,weight='bold')
    grid(ax,'','\u9759\u6001\u4ee3\u7406\u901f\u7387 5% \u5206\u4f4d\u6570\uff08Mbps\uff09')
    ax.text(.98,.93,f'\u5f02\u8d28 \u2212 \u540d\u4e49 = {v[2]-v[0]:+.6f} Mbps\n'
            f'\u5f02\u8d28 \u2212 \u7edf\u4e00 = {v[2]-v[1]:+.6f} Mbps',
            transform=ax.transAxes,ha='right',va='top',fontsize=9.2,
            bbox={'boxstyle':'round,pad=.35','fc':'white','ec':'#cbd6dc'})
    fig.suptitle('\u56fe 6\uff5c\u8fd9\u6b21\u9759\u6001\u5c3e\u90e8\u901f\u7387\u4ee3\u7406\uff1a\u540d\u4e49\u5206\u652f\u6700\u9ad8\uff0c\u8bef\u5dee\u5206\u652f\u672a\u83b7\u76ca',
                 x=.14,ha='left',fontsize=15,weight='bold')
    save(fig,'final06_static_rate_q05')
    return {'hetero_minus_nominal_mbps':float(v[2]-v[0]),
            'hetero_minus_uniform_mbps':float(v[2]-v[1])}

def fig7():
    data=rows('fig07_seed22_second_candidate.csv')
    valid=np.array([float(r['value_mbps']) for r in data if r['sample_policy']=='valid_only'])
    missing=np.array([float(r['value_mbps']) for r in data if r['sample_policy']=='missing_as_zero'])
    check(len(valid)==138 and len(missing)==72 and np.all(missing==0),'UE-second count')
    replay=read(REPLAY/'summary.json')['runs'][0]['result']
    c=replay['completed_burst_ue_second_candidate']
    check(replay['total_bursts']==3107 and c['terminal_bursts_not_queue_completed']==1589
          and c['completed_bursts_counted']==1517,'Burst count')
    fig,ax=plt.subplots(figsize=(11.5,5.8))
    fig.subplots_adjust(left=.11,right=.96,top=.78,bottom=.22)
    for v,color,style,label in ((valid,COLORS[0],'-','\u4ec5\u6709\u6548 UE \u79d2\uff1an=138'),
                                 (np.r_[valid,missing],COLORS[1],'--','72 \u4e2a\u65e0\u6837\u672c\u7f6e\u96f6\uff1an=210')):
        ordered=np.sort(v)
        ax.step(ordered,np.arange(1,len(v)+1)/len(v),where='post',
                color=color,ls=style,lw=2,label=label)
    ax.axhline(.05,color='#68747a',ls='-.',lw=1)
    q=float(np.percentile(valid,5));ax.plot(q,.05,'o',color=COLORS[0],ms=7)
    ax.set_xlim(-.06,max(valid)*1.06);ax.set_ylim(0,1.02)
    grid(ax,'\u5b8c\u6210\u4e1a\u52a1\u7b5b\u9009\u540e\u7684 UE \u79d2\u5019\u9009\u901f\u7387\uff08Mbps\uff09','\u7d2f\u8ba1 UE \u79d2\u6bd4\u4f8b')
    ax.legend(loc='lower right',bbox_to_anchor=(1,1.02),ncol=2,fontsize=9)
    fig.suptitle('\u56fe 7\uff5c\u540c\u4e00\u6b21\u56de\u653e\u7684\u4e24\u79cd\u6837\u672c\u5904\u7406\uff1b\u4e0d\u662f\u4e24\u4e2a\u7b97\u6cd5\u7684\u6027\u80fd\u5bf9\u6bd4',
                 x=.11,ha='left',fontsize=15,weight='bold')
    fig.text(.11,.105,f'\u5230\u8fbe burst 3107\uff1a\u961f\u5217\u5b8c\u6210 1518\u3001\u672a\u5b8c\u6210 1589\uff1b\u6709\u6548 UE \u79d2 138/210\u3002'
             f'\u6709\u6548\u6837\u672c q05={q:.6f} Mbps\uff1b\u65e0\u6837\u672c\u7f6e\u96f6 q05=0\u3002',fontsize=8.5)
    fig.text(.11,.065,'\u72ec\u7acb\u51bb\u7ed3\u51b3\u7b56 1 \u79d2\u6837\u672c\uff1b\u7f3a\u6837\u672c\u7f6e\u96f6\u53ea\u662f\u53e3\u5f84\u654f\u611f\u6027\u8bca\u65ad\uff0c'
             '\u4e0d\u5f97\u4e0e\u524d\u516d\u56fe\u76f4\u63a5\u6bd4\u8f83\u6536\u76ca\u3002',fontsize=8.2)
    save(fig,'final07_ue_second_policy_cdf')
    return {'valid_ue_seconds':138,'missing_ue_seconds':72,
            'q05_valid_only_mbps':q,'q05_missing_zero_mbps':0.0}

def main():
    font=style()
    summary=read(RUN/'summary.json');audit=read(RUN/'paired_error_ablation_audit.json')
    manifest=read(RUN/'scene_manifest.json')
    check(summary['config']['seed']==20261027 and summary['config']['rank']==2,'Run identity')
    check(audit['shared_per_ue_resource_and_traffic_arrays_verified'],'Paired inputs')
    check(sha(RUN/'scene_manifest.json')==
          summary['controlled_comparison_contract']['scene_manifest_sha256'],'Manifest hash')
    for key in KEYS:
        record=summary['branches'][key]
        check(record['status']=='completed' and record['evaluation']['users_total']==210,'Branch count')
    values,q=static()
    metrics={'fig01':fig1(summary),'fig02':fig2(summary),'fig03':fig3(),
             'fig04':fig4(summary,manifest),'fig05':fig5(values,q),
             'fig06':fig6(q),'fig07':fig7()}
    manifest_out={'plotting_only':True,'font':font,'run_seed':20261027,
        'source_code_sha256_at_run_start':summary['source_sha256_at_run_start'],
        'source_files_sha256':{str(p.relative_to(ROOT)):sha(p) for p in
            [RUN/'summary.json',RUN/'scene_manifest.json',
             RUN/'paired_error_ablation_audit.json',
             RUN/'matrix_pf_nominal_precoders.npz',REPLAY/'summary.json']},
        'historical_csv_sha256':{p.name:sha(p) for p in sorted(SRC.glob('fig*.csv'))},
        'metrics':metrics}
    (OUT/'final_figure_manifest.json').write_text(
        json.dumps(manifest_out,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(metrics,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
