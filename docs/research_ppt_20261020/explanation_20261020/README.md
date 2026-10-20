# 研究汇报讲解稿交付说明

以磁盘上的 15 页用户编辑版 `CHASI_研究汇报_研究计划表达_20261020.pptx` 为基准；读取前后 SHA-256 均为 `f460c1bcdd725b24e2624c977ab223126004ecf4f11cabd47d1c2ba5d629a55a`。没有修改 PPTX。正式 MATLAB 链对应 `D:\GitHubProjects\CF-MultiTRP-Optimization` 的 `db9d7e3c71a75f8f9724b743fc78023185b5cddf`，`matlab/chasi/` 未提交状态为空；`matlab/core/` 的另一会话工作区修改未引用为正式调用证据。

## 阅读顺序

1. `CHASI_现场答辩速查.pdf`：先记 30 秒主线、必背公式和五个边界。
2. `CHASI_逐页汇报与答辩讲解稿.pdf` 第一部分：对照 PPT 15 页逐页练讲。
3. 同一详细稿第二部分：沿物理网络→测量→接收→WMMSE→ADMM→真实评价逐式复盘；第三部分作追问练习。

Markdown 是完整可编辑原稿，TeX 是从它生成的公式排版源。重新生成 PDF：

```powershell
python render_markdown_pdf.py CHASI_逐页汇报与答辩讲解稿.md --title '茶思研究汇报逐页讲解与答辩手册'
python render_markdown_pdf.py CHASI_现场答辩速查.md --title '茶思研究汇报现场答辩速查' --compact
```

依赖 XeLaTeX 与 `ctexart`。实际编译后详细稿为 18 页、速查为 2 页；两份 PDF 均已逐页渲染检查，中文、公式、表格正常，XeLaTeX 日志未报缺字、公式错误或文本越界。内容核查覆盖正式 MATLAB 入口、场景/测量/资源、WMMSE/ADMM、静态评价的主要函数；未重跑正式规模实验。

**答辩时主动修正 PPT 口径：** 第 8 页默认静态评价无队列出队；第 12 页的体验率是静态代理且 `b,χ` 的中文顺序应为“服务、调度”；第 14 页数字是原始目标；第 15 页对拍与功率可行不等于收敛。详细稿首页及逐页段落有解释。新版最坏情况、稀疏、休眠、TRP 本地计算和事件触发均作为研究计划陈述。
