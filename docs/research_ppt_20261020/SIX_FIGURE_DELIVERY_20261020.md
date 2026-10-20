# 两版汇报材料：六类关系图修订

## 基准与保留

- 正式 MATLAB 代码依据：`db9d7e3c71a75f8f9724b743fc78023185b5cddf`。本轮未修改算法、配置或实验结果。
- 两版各从对应的当前 PPTX 读取，另存带“六图完善”的文件。原修订版存在用户未提交的手动编辑，未暂存、覆盖或提交该原文件。
- 两版均为 14 页。封面、目录和手调的拓扑页形状树保持一致；其余未选中的页面保留各版差异。两版的演讲者备注仍为 14 页完整保留或更新。

## 图与页面

| 图 | 内容 | 两版页面 | 独立矢量源 |
|---|---|---:|---|
| 1 | UE–TRP–CPU 的测量、集中计算和下行 | 5 | `six_figure_sources/01_ue_trp_cpu.svg` |
| 2 | 几何、观测、资源、求解、真信道评价的数据流 | 5 | `six_figure_sources/02_communication_dataflow.svg` |
| 3 | WMMSE 外层和 ADMM 内层嵌套 | 9–10 | `six_figure_sources/03_wmmse_admm_nested.svg`、`03b_admm_detail.svg` |
| 4 | 历史慢层搜索、测量更新、正式快层求解和反馈边界 | 7 | `six_figure_sources/04_timescales_search.svg` |
| 5 | 研究困难、当前方法和检验结果 | 3 | `six_figure_sources/05_problem_method.svg` |
| 6 | SRS 质量、条件协方差、接收器与预编码的作用机制 | 11 | `six_figure_sources/06_nonuniform_error.svg` |

每张 SVG 有同名 2400 px PNG；图形在 PPTX 中由可编辑 PowerPoint 形状绘制。数学式沿用此前 TeX 排版的图形源。绘图脚本为 `complete_six_figures.py`。

## 源码溯源与状态

Archify 根据正式入口、场景生成、资源规则、矩阵 WMMSE–ADMM 和评价源码形成 `archify/research-dataflow-20261020/code-chain.html`，对应的 finalize 收据记录四道自动检查通过。它用于核对代码依赖；PPT 采用重新绘制的通信表达。正式入口使用估计信道和条件协方差求预编码，以真信道作最终评价。历史搜索链的候选评价未接入正式矩阵求解闭环。当前 ADMM 为集中式数值实现，正式规模停止条件仍未满足；椭球最坏情况、TRP 本地求解和事件触发属于待研究方案。

## 排版与检查

两份新 PPTX 及新 PDF 各 14 页，PDF 为 16:9。最终 PDF 逐页渲染检查；正文无悬空 `[n]` 引用、seed、manifest、路径或“证据索引”字样。第 10–11 页公式改用已有 TeX 排版源，避免下标在普通文本中错位。原手改的拓扑图与颜色解释留在第 4 页；本轮未重算拓扑或实验。
