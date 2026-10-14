> **2026-10-14 最终展示版入口：**请先打开 [七张最终图与进度核查](../final_figures_20261014/README.md)，图1–7的PNG/PDF都从该页进入。本文件以下段落是2026-10-13学习版及辅助图说明；历史图和辅助图没有覆盖。新展示版已修正整数状态刻度、图1增量、图2数学纵轴、图3双残差、图4真实组分配和图5左尾。所有新图只读存档重画。
>
> **对初始化的细化：**solver.py:_initial 是对每条服务TRP–UE的4×64估计信道分别SVD，取前rank个右奇异向量；不是把多TRP信道拼起来做联合SVD。奇异值被丢弃，每列初始单位范数；天线间相对幅度和相位来自向量，但整体功率由跨组预算投影限定，跨TRP整体相位不预先配准。随后U/W由当前V计算，ADMM更新V。详见最终图README。
>
# 茶思七图学习与组会答辩（2026-10-13）

本页按原始图片、七张PNG/PDF、原CSV、MAT/JSON夹具和源码核查。原图/CSV在 ../migration_20261013/，本目录 aid* 是只改显示方式的辅助图。没有重跑210UE，也没有改历史结果。

## 迁移全貌

2023参考 WMMSE_ADMM_Func.py 优化固定MR/RZF方向的实数、单流功率系数 μ；茶思需要 H(g,l,k)∈C^(4×64)、V(g,l,k)∈C^(64×d)、U(g,k)∈C^(4×d)、W_MSE(g,k)∈C^(d×d)。多TRP发同一UE的数据，期望信号 G_ki=Σ_l H_kl V_li 先复数相干相加。先在 chasi_formal_implementation/solver.py 重推矩阵 U/W/V 和固定U/W的二次V子问题，再在 chasi_matrix_wmmse.m 按相同输入改写 MATLAB。旧 cf_search.m→cf_evaluate_candidate.m 仍用旧内层。cf_run_chasi_formal.m 经CLI只传标量配置，Python重新生成网络和复信道；MATLAB读回复数V/U/W。export_scene_to_matlab.py 可显式导出实际H、误差C、调度、服务掩码、rank、RB权重、噪声、预算，但正式入口/旧评价器还未调用它；MATLAB当前是估计总速率，不是Python正式PF目标。CLI先用于隔离验证Python原型是工程推断，缺完整开发日志。

7站×3TRP、210UE这次运行、每TRP 64Tx、UE 2上行SRS发端口/4下行收端口、273RB分17组（前16组16RB，末组17RB）；每组至多42UE，同UE可跨组。rank2是配置/规则，不是已优化变量。V以估计H的SVD方向初始化并投影到功率预算，U/W每外轮由当前V计算，不是每轮随机抽。seed27为整数20261027；主场景派生真H +201、CSI +202、SRS +203、复用 +204、校准 +101、业务 +303、移动 +90817。

## 图1：估计信道PF目标

目的：看外层估计信道比例公平（proportional fairness）效用是否上升。横轴0–18是19个状态快照，0为初始V、之后18次V更新；原图2.5之类是Matplotlib自动刻度，没有半轮。纵轴 F=Σ_{被调度UE} ln(1+Rhat_k/f)，Rhat_k=Σ_g(n_g/273)(-log2 det E_gk)，f=0.001 bit/s/Hz。这是无量纲对数效用，既非Mbps也非真信道/正式UE秒体验。源码 solver.py:_objective_snapshot,_pf_derivatives,solve；数据 fig01_pf_objective.csv。数值0=753.602990，1=1040.358361，12–18依次为1066.931651、1067.045553、1067.142059、1067.224528、1067.295577、1067.357362、1067.411583。末次仍加0.054222，相对变化约5.08e-5；原纵轴压扁尾部。辅助 aid01_integer_rounds_and_tail 按真实点标整数并放大。老师问“平了为何还算”：目标虽小仍变，且外层同时看V相对变化和末次内层ADMM；不能把753→1067换算成体验提升41.6%或全局最优。

## 图2：V相对变化

目的：看相邻两次外轮完整复预编码数组是否稳定。横轴更新0–17；纵轴 ||V新−V旧||F/max(1,||V旧||F)，汇总所有组/TRP/UE/天线/流，不按RB加权。源码 solver.py:solve；数据 fig02_v_change.csv。第0次1.59614，第1次约0.2645，末次0.00474159657<阈值0.005；即整体变化约0.474%。本次趋势下降，不是必然单调。小变化不等于梯度为零、全局最优或边缘体验已好；还要看图1目标和图3内层。

## 图3：ADMM末端残差

目的：逐外轮检查内层是否满足自己的双停止条件。每点是该WMMSE轮固定U/W后一个独立ADMM问题的末值，不是连续18次内层迭代。X为全局二次更新，Z为投影到TRP跨组预算的副本，y为缩放对偶；原始r=||X−Z||F，对偶s=ρ||Z本次−Z上次||F。各自阈值 eps_pri=√N eps_abs+eps_rel max(||X||,||Z||)，eps_dual=√N eps_abs+eps_rel ρ||y||，N为V全部复元素数；配置abs=1e-5、rel=1e-4，最多80轮。源码 solver.py:_solve_v_admm；数据 fig03_admm_end_residuals.csv。纠错：蓝色原始残差18点全低于自己的蓝阈值；不能拿它和橙色对偶阈值比较。首轮r=.0020625<.0187546，对偶s=.0110345>.0101002，80轮上限未双达标；代码允许可行Z且目标不降时以非精确内层进入下一外轮。末轮r=.0121651<.0188333，s=.00298780<.0101227，8轮双达标。辅助 aid03_residual_over_own_threshold 把每种残差除以对应阈值，1为达标线。跨外轮U/W变、子问题变，终点残差不须单调。小例600轮未停、sharing原型1200轮未停是其他问题，不能混为本图的内轮。

## 图4：21个TRP功率

目的：验证20W逐TRP跨组预算。纵轴 P_l=Σ_g(n_g/273)Σ_{k,n,d}|V_g,l,k,n,d|² W，权重反映组占273RB的比例。源码 solver.py:_project,power_by_trp；数据 fig04_trp_power.csv。21项范围19.999999999775014至19.999999999991232W，最大差2.162e-10W，精确21项在 aid04_exact_trp_power.csv。投影只缩超预算项，不自动拉满低预算项；此次所有约束贴边，但没有每轮投影前功率，不能判定贴边来源。相同总功率不等于波束/逐UE功率相同，逐UE加权功率约0.331–5.144W。此图只证功率可行，节能须和原图无协同独立功控基线、同体验条件比较。

## 图5：三种PF方案的逐UE静态CDF

名义：优化仍用非理想H_est，但误差协方差C=0，不是理想CSI。统一相对误差：Cuni_gkl=β_gkl [Σ活跃链路 Chet_gkl/Σ活跃链路 β_gkl]，β是先验链路增益；统一的是组内按β归一的4×4协方差形状，不是绝对误差功率。异质误差：Chet按SRS复用、CSI-RS质量、年龄和链路方向生成。C在 solver.py:_state 中进入Ryy的 Σ_l||V_l||²C_kl，也在 _quadratic_parts 进入V二次项。源码 scenario.py:generate、srs_reuse.py:update_from_reused_pilots、uniform_error.py。三支同seed20261027、H_est/H_true、网络/调度/rank2/RB/初始V/20W/业务，区别是优化中的C；最终同H_true评价。横轴每UE 0.34秒静态业务容量代理Mbps，纵轴 #UE(速率≤x)/210，每台阶1/210；不是协议UE秒感知率。数据 fig05_static_per_ue.csv、源码 evaluate.py。x=1Mbps时名义17/210=8.10%低于等于此值，另两支各14/210=6.67%，曲线局部交叉，不能说一支处处更好。原图横向至约70Mbps，左尾难看，用 aid05_static_cdf_left_tail 放大。图中5%标签是NumPy线性插值，而经验阶梯第11项分别约.769835/.730449/.730559Mbps，两者不能混同。

## 图6：静态底部5%

指标是图5每支210个UE速率的 np.percentile(rate_mbps,5) 线性插值，并非最差5%用户速率均值；源码 evaluate.py:140–152。名义0.7915785506、统一0.7492153542、异质0.7477252150Mbps。异质比统一低0.0014901392Mbps（约0.199%），比名义低0.0438533356Mbps（约5.54%）。误差模型实际改变V，服务链路756个且本次无缺测，异质归一化后验误差迹中位约.708，统一/异质迹比中位约.986（seed27_error_mechanism_20261013/diagnostic.json）；但优化目标PF与5%分位数不同。近饱和误差、固定调度、合成测量失配等是待验证假设。一个seed的静态代理负结果不证明鲁棒方向无效，也不支持鲁棒收益。

## 图7：seed22秒级候选CDF

seed22=20261022，是另一网络与冻结名义V的一秒回放，不可与seed27图5/6直接比性能。蓝线仅有效UE秒n=138，橙线把72个无样本UE秒置0后n=210；横轴候选Mbps、纵轴CDF。3107个到达burst中1518个队列完成，1589个终端未完成；1个仅终端标记的完成不计，1517个合格完成burst最后覆盖138个UE秒，72个无样本。valid-only 5%为2.7891156463Mbps；置零时72/210=34.29%为0，5%自然0。图与数据 results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013/summary.json；源码 protocol_contract.py:completed_burst_ue_second_candidates、time_evolution.py；辅助 aid07_event_to_sample_accounting。若慢UE业务未完成而快UE完成，只统计完成者会虚抬尾部；2.789不是算法收益。原协议图有去前空闲/末时隙和burst/UE秒定义，但“只留同秒完成”和“无样本置零”仍是诊断口径，且当前delivered bits非完整ACKed RLC。

## 公式与代码迁移问答

固定方向实数μ无法表达64Tx复相位、多流d=2及多个TRP同数据相干叠加，故 V 为复矩阵。G_ki=Σ_l H_kl V_li，Ryy_k=I+Σ_iG_kiG_ki^H+Σ_l||V_l||²C_kl，U_k=Ryy_k^(-1)G_kk，E_k=I−U^HG−G^HU+U^HRyyU，W_MSE=E^(-1)。固定U/W后V是复矩阵二次目标，约束 Σ_g(n_g/273)||V_gl||F²≤P_l；Python solver.py:_state,_quadratic_parts,_q_apply,_solve_v_admm,_project；MATLAB chasi_matrix_wmmse.m 对应状态、共轭转置、Q作用、复CG、X/Z ADMM、跨组投影。W_MSE与PF的UE标量导数权重及旧项目波束W不是同一变量。

MATLAB/Python同MAT小例为2TRP、2UE、2组、4Rx4Tx、rank1、每TRP预算0.11W。原 matlab_python_comparison.json 的终态V最大绝对差6.11e-16，目标差不超过1.67e-16，功率差8.33e-17W。本次 saved_matlab_state_check.json 从现存终态复算U最大差9.64e-17、W最大差8.88e-16、速率最大差8.88e-16 bit/s/Hz。证明同一输入下已实现部分在浮点误差内一致；不涵盖中间Q/CG轨迹、rank2/64Tx/PF/210UE。独立SLSQP（Sequential Least Squares Programming，序列最小二乘规划）固定U/W小例目标差约6.20e-10，严格容差时ADMM 600轮未停；目标接近、预算可行、残差停止和全局最优是不同命题，0.11是功率预算W，不是误差率。

正式 solver.py:_solve_v_admm 的X更新仍集中，只有Z预算投影按TRP可分。trp_sharing_admm_demo.py 把物理V_l放本地，协调方汇总各TRP发给UE的有效信号贡献，不强制不同TRP的V相等；3TRP小例串行模拟，目标较集中SLSQP差约9.81e-6，每TRP每轮单向16复数（256字节，未计U/W/控制），1200轮到上限且双残差未全停。尚无真实并行执行、完整CSI分发与低交互预算验证。

## 15–20分钟主讲

0–3分钟：三张茶思原图，说明7站21TRP、两SRS发/四下行收、资源/时间，80%按 (E候选−E共同基线)/(E理想−E共同基线)≥0.8，绝不说达到理想速率80%；共同基线的具体实验定义还须锁定。老师两PDF是技术建议。3–7分钟：参考μ→矩阵H/V/U/W，打开WMMSE_ADMM_Func.py和solver.py。7–10分钟：MATLAB模块、显式导出器、两份小例对拍JSON，主动说PF正式链未等价接通。10–15分钟：图1/2/3及辅助图，图4只讲预算。15–18分钟：图5/6和左尾放大，讲负结果。18–20分钟：图7样本流与待讨论问题。

老师追问清单：①最近新增什么？Python复矩阵、MATLAB小例、导出器、sharing原型；看对应源码。②为何重推？原μ固定单流实数；看参考WMMSE_ADMM_Func.py与solver.py。③为何先Python？动机仅工程推断；看CLI和对拍JSON。④正确性？小例终态机器精度；看两个对拍JSON。⑤为何不对拍正式规模？MATLAB尚缺PF导数和正式入口；看chasi_matrix_wmmse.m/export_scene_to_matlab.py。⑥目标平为何算？尾部仍增且三重停止；看图1/2 CSV。⑦内层没停为何继续？首轮对偶超阈值、可行Z且目标不降；看图3 CSV/solve。⑧功率为何都20W？只缩超限的投影，最终活跃；看_project/精确CSV。⑨三误差模型？C=0、统一按β缩放、异质链路C；看uniform_error.py/scenario.py。⑩鲁棒为何差？此seed静态5%负结果，原因待消融；看图5/6、diagnostic.json。⑪距验收？缺标准端口级信道测量、正式UE秒口径、同条件基线和80%判断；看原图与图7。⑫TRP本地x在哪？正式X集中、sharing原型串行本地V_l；看两份ADMM源码。⑬请老师讨论什么？跨窗未完成burst/无样本处理、两上行SRS端口到四下行接收端口的统计映射、尾部目标与信息交换预算；这些尚无直接证明。

七原PNG已目视核对、七PDF均为单页；三原图和老师两PDF已读。辅助图只变刻度/放大/归一化。需纠正的旧印象：图1没有半轮、图3蓝原始残差未超自己的线、图5名义不是理想CSI、图6不是尾部均值、图7不是两算法性能对照。
