# CHASI 原生 MATLAB 图集与阅读入口

最终图集：[12 页矢量 PDF](CHASI_ATLAS.pdf) · [HTML 预览](atlas.html)。12 张图的 PNG、单页 PDF 和统一 MATLAB 源码均在本目录。已实际查看导出图；下行泳道中 CPU、TRP、UE 的处理位置及 ADMM 箭头已据此修正。

交互调用图 `interactive_calls.html` 仅为补充候选件。Archify 的结构、来源和交付检查通过，但 Chrome 临时配置清理失败使浏览器检查门槛未通过；本轮验收以 MATLAB 图 01 和本图集 PDF 为准。

图 01–10 最初依据 `9527089` 数值运行制作；图 11–12 又按 `9b591cc` 双精度修复、正式210/420 UE实测和可选动态1 UE小例更新。原始公式源 [CHASI_UNIFIED_TRACE.tex](../CHASI_UNIFIED_TRACE.tex)，[可检索 PDF](../CHASI_UNIFIED_TRACE.pdf)，[按编号跳转的 HTML](formula_reader.html)；变量与参数 [验收表](../CHASI_VARIABLE_ACCEPTANCE_20261017.md)，正式规模同输入误差见 [验证记录](../CHASI_VALIDATION_20261017.md)。图源统一为 [build_chasi_atlas.m](build_chasi_atlas.m)，MATLAB 执行 `addpath('docs/chasi_native_atlas'); build_chasi_atlas`，生成各图 PNG 预览和矢量 PDF。图是教学布局；真实抽样坐标和真实服务关联只认运行所得 `scene_manifest.json`。

| 图 | 要回答的问题 | 公式 | 源码入口与核查边界 |
|---|---|---|---|
| [01 调用图](01_calls.pdf) | 哪个 MATLAB 函数实际调用哪个？ | C01–C38 | `chasi_run.m:39-142`；可选回放单独标明 |
| [02 正式流程](02_formal_flow.pdf) | 原生全链的运行顺序？ | C01–C38 | `chasi_run.m:1-142`；没有 Python 调用 |
| [03 网络拓扑](03_network.pdf) | 站、TRP、UE、逻辑CPU、服务和干扰？ | C01,C02,C09,C15,C16 | `chasi_generate_scene.m:142-159,59-64`；示意位置，真实坐标读 manifest |
| [04 天线与维度](04_ports.pdf) | 64 Tx/4 Rx/2 SRS 与物理阵列有何区别？ | C06,C11,C14 | `chasi_config.m:6-42`; `chasi_generate_scene.m:11,74-102`；双极化响应未实现 |
| [05 SRS/CSI 泳道](05_srs_csi.pdf) | UE→TRP→CPU 模型传递何物？ | C07,C10–C12 | `chasi_generate_scene.m:47-130`；无波形/原始IQ/真实前传 |
| [06 决策与功率](06_resources.pdf) | b、χ、r、w、ν、p 如何相接？ | C07–C09,C14,C26–C29 | `chasi_generate_scene.m:159-205`; `chasi_matrix_wmmse.m:499-541` |
| [07 求解循环](07_wmmse_admm.pdf) | 何时固定 A/Ω，何时更新 w；为何停在上限？ | C18–C31 | `chasi_matrix_wmmse.m:35-109,374-483`；集中式ADMM，实测停止数值见验证记录 |
| [08 下行泳道](08_signal.pdf) | 谁算预编码，谁发送，UE怎样接收？ | C15–C19,C32 | `chasi_matrix_wmmse.m:374-400`; `chasi_evaluate.m:137-154`；仅协方差等效计算 |
| [09 指标](09_metrics.pdf) | 真信道如何进入SE、业务代理和5%？ | C32–C38 | `chasi_evaluate.m:43-136,137-205`；非正式TS28.554证明 |
| [10 生命周期](10_lifecycle.pdf) | 变量最后保存到何处？ | C01–C38 | `chasi_run.m:39-142`；v3 MAT字段分离 w 与 Ω |
| [11 语言对应](11_languages.pdf) | MATLAB 与 Python 是否桥接？ | C14–C31,L01–L17,Z01–Z03 | 两条独立链；历史210 UE保存 Ω 绝对门槛未过，双精度修复后同一 w 重算已过，修复版210 UE全链已运行但未收敛；场景随机生成尚未对拍 |
| [12 动态边界](12_dynamic.pdf) | 回放与在线优化的实际界线？ | C37,C38 | `chasi_time_evolution.m`；SRS步长按配置，210 UE零速度/冻结波束业务回放同输入对拍通过；可选在线WMMSE已在1 UE确定性小例核查，正式移动规模及资源重新决策未验证 |

上述 PDF 同名 PNG 便于预览。重要箭头的含义：蓝实线为程序／数组更新，灰实线为逻辑前传，绿虚线为无线服务或已验证传递，红点线为干扰或尚缺映射；各图脚注说明例外。物理箭头并不表示代码中产生了波形。

## 下午按这个顺序打开

先看图 02 和图 03，再开 `matlab/chasi/chasi_run.m:1`、`chasi_config.m:1`、`chasi_generate_scene.m:1,142,159`，对照变量表 V01–V18 和公式 C01–C13。随后看图 04–06，确认组内 `ueIds` 和四个矩阵轴。打开 `chasi_matrix_wmmse.m:1,301,374,403,420,440,485,499`，跟图 07–08 和 C14–C31 走一次迭代。最后开 `chasi_evaluate.m:1,137,186`、`chasi_traffic.m:1`、`chasi_run.m:110`，跟图 09–10 追指标到文件。第一遍跳过 `chasi_time_evolution.m`、`matlab/core/` 的旧 GA/PSO，以及参考 Python；读懂正式静态链后再用图 11–12 比较。

图 03 的**服务边身份**来自已有 `results/chasi_matlab/formal420_20261017_schema3_named_final/scene_manifest.json` 的第 3 组：UE 41 由 TRP 3/16 服务，UE 78 由 TRP 4/6 服务，配置种子 20261011。图内位置是教学排版，**不是**运行坐标。红线仅表示按真信道评价式其他用户波束对 UE 78 可形成干扰，未展示所有干扰链。核实新一次运行的真实服务边时，以该次 `groups[g].ueIds[localUeIdx]` 和 `serving_trps_by_user[localUeIdx]` 为准；MATLAB 一基 ID，JSON 数组访问注意阅读器索引。
需要查看真实抽样坐标时，另开已有的 [210 UE 保存场景拓扑 PNG](../CHASI_TOPOLOGY_210_SAVED.png)（[矢量 PDF](../CHASI_TOPOLOGY_210_SAVED.pdf)）；它只画选定资源组的服务边，不应推断未画的干扰不存在。

## 实际使用的技能与产物

`test-driven-development` 用于 SRS 末跳/跳间隔先失败再通过的轻量检查；`domain-modeling` 用于明确旧波束、当前预编码、MSE权重、服务与调度的命名边界，产物是变量验收表；`pdf` 用于 TeX→PDF 后的逐页渲染检查；`archify` 用于按源码证据绘制并验证 Archify candidate (automated browser gate failed; not in the verified atlas)；`verification-before-completion` 用于正式规模运行、保存读回、图件检查及 Git diff。MATLAB 图集仍以本目录的 `.m` 为可编辑主源。此轮没有调用演示文稿技能或生成 PPT。

**顺着这两个 UE 走一遍：** 第3组中，UE41 的有用等效信道是 $T_{41,41,3}=H_{41,3,3}w_{3,41,3}+H_{41,16,3}w_{16,41,3}$；每项为 $(4\times64)(64\times r)=4\times r$，先把两个 TRP 的复幅度相加，再形成协方差。UE78 的有用项来自 TRP4/6；UE41 数据在 UE78 的干扰等效信道是 $T_{78,41,3}=\sum_lH_{78,l,3}w_{l,41,3}$，在当前服务掩码下只可能有 TRP3/16 的非零波束。`chasi_evaluate>true_rates:137-154` 将 $T_{78,41,3}T_{78,41,3}^{H}$ 放入 UE78 的干扰协方差，随后计算两个 logdet 之差。代码没有真正产生 $s_{41}$、OFDM 波形或 UE 端解调样本；这些 $T$ 与协方差是模型等效计算。
