# 茶思原材料—正式 MATLAB 实现对应与缺口

源码基线 `9527089`。原件在用户提供的 `C:\Users\sypxx\Desktop\AAAa研一\AAAa研二\MIMO huawei`，本仓库不复制研究原件。下表“要求”来自原图，“方案”来自 `202609-系统方案.pdf` 和 `研究主题分析.pdf`；方案的文字不是程序执行证据。代码和运行证据另列。

| 原件位置与原意 | 当前代码位置／实现 | 判断与后果 |
|---|---|---|
| `典型验收场景.png`：7站、每站3扇区、站间距300m，10–20 UE/小区 | `chasi_config.m:6,33-42`; `chasi_generate_scene>geometry:142-159`；中心+六站、21共址三扇区 | **已核实代码**。方位扇区规则是项目假设；原图未精确定义小区边界 |
| 同图：小区内均匀分布 UE | `geometry:149-158` 用 $25+125\sqrt\xi$ 半径、均匀扇区角 | **未通过严格面积均匀**，也不能在原图没有边界时擅自选环扇区 |
| 同图：8水平×4垂直×2极化、半波长距、64TRX，UE 2Tx/4Rx | `chasi_config.m:33-42`; `chasi_generate_scene.m:11,74-102` 仅4×64相关高斯 H，SRS 选4行中的2行 | **维度已实现，物理阵列未实现**；2Tx到DL4Rx的端口映射/校准为项目假设 |
| 同图：2.6/3.5GHz、TR38.901典型UMi/UMa | `link_gain:207`, `outdoor_pathloss:232` 提供可选子集；默认 `geometry_correlated_surrogate` | **默认未满足**标准完整信道；载频字段在默认分支不进入公式 |
| 同图：100MHz、30kHz SCS、273数据RB | `chasi_config.m:38-52`, `chasi_evaluate.m:75-81` | 数据组16×16+17；业务容量按12×30kHz×RB计算，98.28MHz净RB带宽与名义100MHz分列 |
| 同图：SRS每跳16RB，**末跳17RB**，20ms/跳，17跳/340ms | `chasi_config.m:50-57`; `chasi_generate_scene.m:47-56,123-146`; `chasi_run.m:45-85` | **组级统计模型已修**，总273测量RB元数据；无逐RB SRS波形、时频序列或真实TRP IQ |
| 同图：CSI-RS 40 TTI、速度3km/h、IRC、rank自适应 | CSI-RS年龄 `chasi_generate_scene:56`；`speedKmh` 仅可选 `chasi_time_evolution`; `rank=2` 固定；求解器用MMSE接收矩阵 | **部分实现/未实现**：无协议级CSI-RS/IRC，默认静态不消费速度，rank未自适应 |
| 同图：30%业务负载、突发 PRB利用30–50%、尾部数据/TTI占比 | `prbUtilization=.4` 控制调度RB；`trafficLoad=.3` 在默认 `legacy_bursts` 不决定空闲长度；`chasi_evaluate` 用尾部需求2/7代理 | **未通过正式业务口径**；PRB占比不能代替业务负载，尾部比率须按实际记录核查 |
| `难题1.png`：$\max_{b,p,r,W}$，非理想SRS/CSI，边缘80%相对理想集中参考，平均体验损失<10%，空口总功率降低>30% | `chasi_matrix_wmmse` 固定规则 b/χ/r、优化复矩阵 w；`chasi_evaluate` 记录SE/体验和辐射功率 | **部分实现**：不是对全部 b/p/r/w 联合优化，80%共同基线及30%对照尚无可验收证据；不能把 `basic` 当规定基线 |
| 同图所需无协作独立功率参照 | `chasi_no_cooperation.m:1-75` 仅 home TRP SVD 波束，并把每 TRP 组平均功率缩放到共享预算；`out.converged=true` 表示固定构造完成 | **基线定义不一致**：没有独立功率控制问题求解；不能用其和理想集中分支直接宣布80%/30%验收 |
| `用户速率协议定义.png`：突发样本、排除首包前空闲和末时隙、UE秒、5%尾部 | `chasi_traffic`, `chasi_evaluate`, 可选 `chasi_burst_metrics`/`chasi_second_metrics` | **代理及可选工具**；正式静态输出的“全UE有效”不等于协议样本验收 |
| `202609-系统方案.pdf` p1–2：非理想CSI下 WMMSE 接收/MSE权重/波束交替 | `chasi_matrix_wmmse>state:374`, `quadratic:403`, `precoder_admm:440` | **同类方法但非逐式继承证明**；此处当前记号 $A,E,\Omega,w$，proposal `u,w,v` 禁混 |
| 同 PDF p3–5：TRP侧分布式ADMM、低交互乘子 | `precoder_admm:440-483` 在一个 MATLAB 函数内集中处理全部资源组和TRP | **未实现分布式TRP计算/前传协议**；程序的变量分裂不等于物理部署 |
| 同 PDF p7–8、p11：误差椭球、稀疏化/能耗、算法展开等研究方向 | `C_stat` 为4×4后验误差；没有完整误差椭球的正式最坏情况内层或展开模型 | **方案/待研究**，不能以 PDF 的承诺推断代码已有 |
| `研究主题分析.pdf` p1–3、p8–10：对旧GA/PSO规模与分布式问题的分析、分层建议 | 旧 `matlab/core/cf_search` 是独立搜索链，正式 `chasi_run` 不调用 | **研究建议与现有路径分开**；不是外层搜索已经接到正式矩阵内层的证据 |

未找到原图对项目常数 `0.08/0.92`、方向图指数4、增益尺度0.025、100m、路径指数3.2、接收相关0.35、750m截断及20W预算的直接定义。它们保持为**未校准项目假设**。修这些物理模型需独立配置/版本和新验证，不能与本次语言等价性数值对拍混报。
