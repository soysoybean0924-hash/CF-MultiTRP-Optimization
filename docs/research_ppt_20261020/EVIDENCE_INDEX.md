# 汇报证据索引与边界

## 版本

- 幻灯片源码基线：`db9d7e3c71a75f8f9724b743fc78023185b5cddf`，提交于 2026-10-19 19:28:56 +08；本材料另存于独立材料分支。
- 与旧 `FORMULA_TRACE.pdf` 对应的 `3efa44c` 相比，最新提交已把默认 UE 抽样改为 `sqrt(25²+(150²−25²)U)`，并补充站/扇区/归属映射。旧报告的 `25+125sqrt(U)` 只属于历史分布。
- 当前正式配置 seed=`20261011`；本次 MATLAB 图使用该默认 seed、每小区 10 UE。并没有在主展示使用 seed27。生成过程只调用 `chasi_generate_scene`，未调用求解器或运行新性能实验。
- 本次 MATLAB 批处理生成了 7 行站址、21 行 TRP、210 行 UE、选定UE服务 manifest 和两份矢量 PDF；但命令在写出全部文件后未自行返回退出码，本会话终止了该命令。图件确为 MATLAB 输出，批处理完整退出状态未通过；旧场景级测试的退出与断言见 `CHASI_TOPOLOGY_AUDIT_20261019.md`。
- 原工作区在制作期间仍有未提交的 `matlab/core/cf_search.m`、`cf_evaluate_candidate.m`、`cf_decode_candidate.m` 等搜索链改动与新增脚本，属于另一会话进行中的工作。本材料只把已提交 `db9d7e3` 作为可复核基线。新的候选编码、搜索连接和运行效果须待其提交与验证后同步；本轮未复制或修改该工作区。抽查时 `cf_evaluate_candidate.m` 工作区 SHA256 为 `05191F0908A22BED1D68678A4128D1FA60A6721A34509109DE236A633B851127`，仅用于识别当时快照，不作为 PPT 的正式源码证据。

## 原始材料

| 材料 | 本轮使用方式 | 限度 |
|---|---|---|
| `难题1.png` | 困难、边缘体验、功率比较目标 | 百分比不是当前实验已达成绩 |
| `典型验收场景.png` | 7站/3小区/站、300 m、10–20 UE/小区、273 RB、SRS跳频、规模与资源约束 | 25–150 m 环扇区及绝对原点未由原图规定 |
| `用户速率协议定义.png` | 体验率样本口径 | 当前 `legacy_bursts` 是代理，尚未证成协议严格等价 |
| `FORMULA_TRACE.pdf` | C01–C38、L01–L17 编号和符号参照 | 对应旧代码 `3efa44c`，最新 C01/C02 以当前源码为准 |
| `202610-系统方案v2.pdf` | 最后四页的拟议椭球、公平、稀疏、事件触发框架 | 不作为已实现或性能保证 |
| `1.png / 2.png / 3.png` | Cell-Free、UE–AP–CPU、MATLAB拓扑的视觉参考 | 图中的PUSCH/LLR/前传不是当前代码功能；本次拓扑由MATLAB重绘 |
| 指定 PPTX 模板 | 保留 16:9 版式、母版校徽、标题栏和蓝红配色；新建内容页 | 原文件保持原样 |

## 正式主线

| 幻灯片 | 结论 | 源码/记录 | 状态 |
|---|---|---|---|
| 5–6 | 7个站址、21个共址TRP、真实坐标与服务关系 | `matlab/chasi/chasi_geometry_from_samples.m`; `chasi_generate_scene.m`; 本目录 `topology/*.csv/json/pdf` | seed20261011 MATLAB 场景生成已执行；边界为项目假设 |
| 7–8 | 正式 MATLAB 集中式调用链 | `matlab/chasi/chasi_run.m:39–135` | 已实现；无分布式前传 |
| 9–11 | 几何、真信道、SRS/CSI、固定资源规则 | `chasi_generate_scene.m:14–138`; `chasi_config.m` | 当前 surrogate/统计实现；物理阵列和逐RB波形未实现 |
| 12–13 | 相干有效信道、真信道率和体验代理 | `chasi_matrix_wmmse.m:352–408`; `chasi_evaluate.m` | 计算链已实现；协议级体验待核定 |
| 14 | 旧 GA/PSO/SRACOS 与正式链分离 | `matlab/core/cf_search.m`; `cf_decode_candidate.m`; `cf_evaluate_chasi_native_candidate.m`; `chasi_run.m` | 旧场景存在可选矩阵适配入口；正式 `chasi_run` 无旧搜索调用，未形成正式场景联合闭环 |
| 15–19 | A/E/Ω/η、二次系数、CG/ADMM、跨组投影 | `chasi_matrix_wmmse.m:307–550` | 集中式已实现，正式规模未达到收敛停止 |
| 20–21 | 非均匀统计 C 同时进入接收与二次项 | `chasi_generate_scene.m:65–103`; `chasi_matrix_wmmse.m:380–445` | 机制已接入；相对统一误差的收益未证实 |
| 23 | 210/420 UE 静态运行与同输入对拍 | `docs/CHASI_VALIDATION_20261017.md`; `docs/CHASI_TOPOLOGY_AUDIT_20261019.md` | 旧保存场景数值证据；不能挪作新面积均匀场景性能 |
| 24–27 | 新版鲁棒椭球/稀疏/事件触发 | `202610-系统方案v2.pdf` | 拟研究，不在正式求解器中 |

## 不能合并的判断

- 最新 210/420 UE 保存运行完成、功率违规为 0 W、显式同输入 Python/MATLAB 数值对拍通过；两个正式矩阵运行都以 `max_outer_iterations_with_latest_inexact_admm` 停止，`converged=false`。
- 新面积均匀场景已做场景级生成和几何核查；旧正式运行在旧半径分布上生成，不能用其体验/SE数值说明新部署收益。
- `trafficLoad=.30` 默认 `legacy_bursts` 未按 30% 校准；100 MHz 名义带宽不直接进入当前率运算；严格协议分母、标准物理阵列、独立功控无合作基线仍待核定。
- `C` 是接收侧 4×4 条件统计量并按发射列共享；新版确定性椭球、最坏情况内层、TRP本地求解、事件触发通信尚未实现。更大的误差并不必然意味着更宽波束。

## 图与备注

PPT每页备注均含本页问题、讲解顺序、公式通俗解释、衔接、来源和可能追问。正文图除 MATLAB 拓扑图外由原生可编辑 PowerPoint 对象构成；拓扑 PDF 为 MATLAB 矢量输出，PNG 为该 PDF 的预览。`archify/code-chain.html` 是按提交源码验证的交互补充图，不冒充实际网络部署。
