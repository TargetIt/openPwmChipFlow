# OpenPWM Digest

这个目录用于消化 `openPwmChipFlow` 从综合到后端的知识。

建议阅读顺序：

1. [01-standard-cell-library-and-ppa.md](01-standard-cell-library-and-ppa.md)
   - 先理解本项目使用的 SKY130 PDK、`sky130_fd_sc_hd` 标准单元库、Liberty/LEF/GDS 等库文件，以及面积、延时、功耗这些 PPA 指标从哪里来。
2. [02-sta-by-hand.md](02-sta-by-hand.md)
   - 再学习 STA 静态时序分析的算法。重点是不用 STA 工具时，如何根据库参数、约束、网表和寄生参数手动算一条路径。
3. [03-pnr-library-and-wire-delay.md](03-pnr-library-and-wire-delay.md)
   - 最后理解布局布线阶段用到的物理库、DEF/LEF/SPEF/SDF/GDS，以及线延时、过孔、拥塞、DRC/LVS/Antenna 为什么会改变后端结果。

本 digest 主要基于：

- 项目配置：`openlane/pwm_ctrl/config.tcl`
- 综合日志：`delivery/phase3_synthesis/1-synthesis.log`
- STA 日志：`delivery/phase3_synthesis/2-sta.log`
- 指标表：`delivery/phase3_synthesis/metrics.csv`
- PnR 产物：`delivery/phase4_pnr/pwm_ctrl.def`
- 时序/寄生产物：`delivery/phase4_pnr/sdf/`、`delivery/phase4_pnr/spef/`
- 最终交付件：`delivery/phase6_gds/`

注意：仓库里早期自动报告存在一些字段解读错误，比如把密度字段误当面积、把 wire/via 指标误写到 DRC/Antenna 表格。本 digest 尽量回到原始日志、CSV 字段、SDF/SPEF/LIB/DEF 产物来解释。
