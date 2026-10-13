"""Read existing figure CSV and seed22 summary; make teaching aids only.

No scenario generation, optimizer call, interpolation, or source-file overwrite.
"""
from pathlib import Path
import csv
import json
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/'experiments/chasi_formal/migration_20261013'
HERE=Path(__file__).resolve().parent

def rows(name):
    with (SOURCE/name).open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))

def save(fig,stem):
    fig.subplots_adjust(top=.78,bottom=.24)
    for ext in ('png','pdf'):
        path=HERE/f'{stem}.{ext}'
        if path.exists(): raise FileExistsError(path)
        fig.savefig(path,dpi=300,bbox_inches='tight')
    plt.close(fig)

font='Microsoft YaHei'
if font not in {f.name for f in font_manager.fontManager.ttflist}:
    raise RuntimeError('Chinese font unavailable')
mpl.rcParams.update({'font.sans-serif':[font],'axes.unicode_minus':False,
                     'pdf.fonttype':42,'font.size':10})

# 1. Integer rounds and true tail changes.
src=rows('fig01_pf_objective.csv')
x=np.array([int(r['outer']) for r in src])
y=np.array([float(r['pf_objective_sum_ln_1_plus_R_over_floor']) for r in src])
fig,(a,b)=plt.subplots(1,2,figsize=(10,3.5),gridspec_kw={'width_ratios':[1.2,1]})
a.plot(x,y,'o-',color='#245b91',ms=3);a.set_xticks(np.arange(0,19,2))
a.set(xlabel='整数WMMSE快照轮',ylabel='PF目标（无量纲）',title='完整轨迹')
last=x>=12
b.plot(x[last],y[last],'o-',color='#245b91',ms=4)
b.set_xticks(x[last]);b.set(xlabel='整数WMMSE快照轮',title='真实尾部放大')
b.ticklabel_format(axis='y',style='plain',useOffset=False)
b.set_ylim(1066.86,1067.48)
for xx,yy in zip(x[-3:],y[-3:]):b.annotate(f'{yy:.3f}',(xx,yy),xytext=(0,8),textcoords='offset points',ha='center',fontsize=8)
for ax in (a,b):ax.grid(alpha=.2)
fig.suptitle('图1补读：半轮只是原图自动刻度；尾部仍在增加')
fig.text(.01,.035,'seed20261027；轮18为最后一次V更新后的目标快照，不是第18次更新',fontsize=8)
save(fig,'aid01_integer_rounds_and_tail')

# 3. Each residual divided by its OWN tolerance.
src=rows('fig03_admm_end_residuals.csv')
t=np.array([int(r['update_outer']) for r in src]);p=np.array([float(r['primal'])/float(r['eps_primal']) for r in src]);
d=np.array([float(r['dual'])/float(r['eps_dual']) for r in src]); n=np.array([int(r['admm_iterations']) for r in src])
fig,ax=plt.subplots(figsize=(9,4))
ax.plot(t,p,'o-',label='原始残差÷原始阈值',color='#245b91')
ax.plot(t,d,'o-',label='对偶残差÷对偶阈值',color='#bb7838')
ax.axhline(1,color='#aa4d45',ls='--',label='各自达标线 = 1')
ax.annotate('首轮对偶1.093 > 1；ADMM达80轮上限',xy=(0,d[0]),xytext=(1.1,1.2),arrowprops={'arrowstyle':'->'},fontsize=8)
ax.set(xlabel='执行V更新的整数WMMSE轮',ylabel='残差/对应阈值（无量纲）',title='图3补读：只把各残差与自己的阈值比较')
ax.set_xticks(t[::2]);ax.set_ylim(0,1.28);ax.legend();ax.grid(alpha=.2)
fig.text(.01,.035,'每点为该轮内层ADMM末值；原始比值18点均<1，对偶仅首轮>1；完整内层轨迹另见summary的admm_trace',fontsize=8)
save(fig,'aid03_residual_over_own_threshold')

# 4. Exact values and numerical budget slack, without an exaggerated plot.
src=rows('fig04_trp_power.csv')
with (HERE/'aid04_exact_trp_power.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f);w.writerow(['TRP','power_W','budget_W','budget_minus_power_W'])
    for r in src:
        power=float(r['weighted_radiated_power_watt']);budget=float(r['budget_watt'])
        w.writerow([r['trp_id_1based'],format(power,'.15f'),budget,format(budget-power,'.15g')])

# 5. Actual left tail of the same three empirical CDFs.
src=rows('fig05_static_per_ue.csv')
labels=[('matrix_pf_nominal','名义PF','#245b91'),
        ('matrix_pf_uniform_relative','统一相对误差PF','#bb7838'),
        ('matrix_pf_statistical','异质误差PF','#527f65')]
fig,ax=plt.subplots(figsize=(9,4))
for key,label,color in labels:
    v=np.sort(np.array([float(r[key]) for r in src]));
    ax.step(v,np.arange(1,len(v)+1)/len(v),where='post',label=label,color=color,lw=1.8)
    j=int(np.ceil(.05*len(v)))-1;ax.scatter(v[j],(j+1)/len(v),s=40,color=color,zorder=4)
ax.axhline(.05,color='#777',ls='--',label='5%累计比例')
ax.set(xlim=(0,2),ylim=(0,.18),xlabel='静态业务容量代理（Mbps）',ylabel='累计UE比例',
       title='图5补读：左尾放大；圆点为第11/210个UE')
ax.legend(loc='upper left',fontsize=8);ax.grid(alpha=.2)
fig.text(.01,.035,'三支各210人、同一场景和真信道评价；曲线可交叉，不能说误差分支让所有人更差',fontsize=8)
save(fig,'aid05_static_cdf_left_tail')

# 7. Event/sample accounting from the saved seed22 candidate.
replay=json.loads((ROOT/'results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013/summary.json').read_text(encoding='utf-8'))['runs'][0]['result']
c=replay['completed_burst_ue_second_candidate']
assert replay['total_bursts']==3107 and c['terminal_bursts_not_queue_completed']==1589
assert c['completed_bursts_counted']==1517 and c['valid_ue_second_samples']==138
fig,ax=plt.subplots(figsize=(9,3.6));ax.axis('off')
boxes=[(.02,.55,'3107次burst终止事件'),(.30,.73,'1589次队列未完成'),(.30,.36,'1518次队列完成'),
       (.57,.53,'1517次合格完成\n1次仅末TTI'),(.80,.53,'138个有样本UE秒\n72个无样本UE秒')]
for xx,yy,s in boxes:
    ax.text(xx,yy,s,transform=ax.transAxes,ha='left',va='center',fontsize=10,
            bbox={'boxstyle':'round,pad=.4','fc':'#e8eff4','ec':'#245b91'})
for x1,y1,x2,y2 in [(.21,.55,.29,.73),(.21,.55,.29,.36),(.49,.36,.56,.53),(.74,.53,.79,.53)]:
    ax.annotate('',xy=(x2,y2),xytext=(x1,y1),xycoords='axes fraction',textcoords='axes fraction',arrowprops={'arrowstyle':'->'})
ax.set_title('图7补读：burst事件计数与UE秒样本不是同一统计单位')
fig.text(.01,.035,'seed20261022；完成业务筛选是评价口径诊断；缺样本置零只是敏感性分析，不代表协议最终规定',fontsize=8)
save(fig,'aid07_event_to_sample_accounting')
print('created four teaching PNG/PDF pairs and exact TRP power CSV')
