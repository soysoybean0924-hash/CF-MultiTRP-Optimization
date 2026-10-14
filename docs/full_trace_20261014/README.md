# CF 与 MathWorks Cell-Free 溯源审计（2026-10-14）

本目录以本轮可读源码为准。证据标记：`S` 静态源码，`R` 已保存运行记录（本轮未重跑），`M` 由源码作数学还原，`T` 理论说明而未实现，`?` 不可见或未证实。行号指本轮工作树。

阅读顺序：[01 实际框架](01_真实框架.md) → [02 符号字典](02_符号字典.md) → [03 公式索引](03_公式索引.md) → [04 预编码全程](04_预编码全程.md) → [05 MathWorks](05_MathWorks_R2025a.md) → [06 三方对照](06_三方来源对照.md) → [07 答辩问题](07_老师追问.md) → [08 覆盖与缺口](08_覆盖清单.md)。

这里的“正式”仅指仓库 CHASI 可执行入口及其结果结构，不等于华为正式验收。旧论文消融线、Python CHASI 线、独立 MATLAB 矩阵模块是不同链。运行参数优先于源码默认值；已有 `summary.json` 代表特定运行，不能外推。

本轮未运行 MATLAB/Python 求解或大规模实验。指定 R2025a URL 的网页工具抓取失败，官方页面可见证据只能限定为当前网页版本，详情见 05。[MathWorks 当前页面](https://www.mathworks.com/help/5g/ug/evaluate-performance-of-cell-free-mmimo-networks.html)。
