# 本项目用到的库，以及从 PPA 角度怎么理解它们

## 1. 我们到底用了什么库

`openlane/pwm_ctrl/config.tcl` 里写得很直接：

```tcl
set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 20.0
```

也就是说，本项目的后端目标是：

```text
工艺平台: SKY130
PDK 变体: sky130A
标准单元库: sky130_fd_sc_hd
时钟周期约束: 20 ns
```

GitHub Actions 里启用的 PDK 版本是：

```text
0fe599b2afb6708d281543108caf8310912f54af
```

本地 `delivery/` 目录里的历史产物来自更早的 OpenLane run，但用的标准单元库仍然是 `sky130_fd_sc_hd`，所以对理解库和 STA 仍然有参考价值。

OpenLane 官方文档说明，PDK 是 foundry 提供的一组工艺文件；标准单元库是 PDK 中的一组已经设计好、分析过 timing 和物理信息的小电路块。OpenLane 对 sky130 的默认标准单元库就是 `sky130_fd_sc_hd`。参考：

- OpenLane PDK 文档：https://openlane2.readthedocs.io/en/latest/usage/about_pdks.html
- SkyWater 标准单元库文档：https://skywater-pdk.readthedocs.io/en/main/contents/libraries/foundry-provided.html
- `sky130_fd_sc_hd` 仓库：https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd

## 2. 标准单元库是什么：把“晶体管细节”包装成“积木”

从第一性原理看，数字芯片最终只有两类东西：

```text
晶体管 + 金属连线
```

晶体管控制电流，金属线搬运电荷。一个反相器、与门、或门、触发器，本质上都是一些晶体管按固定方式连接出来的“小电路”。

如果每次综合都从晶体管级开始拼，会非常慢，也非常容易出错。所以 foundry/库团队预先做了一批标准小电路：

```text
inv_1, inv_2, and2_1, nor2_2, dfxtp_2, clkbuf_1, decap_3, tapvpwrvgnd_1 ...
```

综合工具做的事情可以理解为：

```text
RTL 行为
  -> 逻辑表达式
  -> 通用门
  -> 选库中真实存在的标准单元
```

例如本项目 RTL 里有一个 8 位 counter 和一个比较：

```verilog
counter <= counter + 1;
pwm_out <= (counter < duty);
```

Yosys/ABC 会把它变成加法器、比较器、触发器和若干组合逻辑，最后映射成 `sky130_fd_sc_hd__dfxtp_2`、`sky130_fd_sc_hd__a21oi_2`、`sky130_fd_sc_hd__or2b_2` 等真实单元。

## 3. `sky130_fd_sc_hd` 的定位：高密度，不是最高速

`hd` 是 high density。SkyWater 文档里说，`sky130_fd_sc_hd` 是高密度标准单元库。它的目标是让单位面积里放更多逻辑，而不是追求最高速度。

官方文档中几个关键参数：

| 指标 | `sky130_fd_sc_hd` 的含义 |
| --- | --- |
| cell site | 约 `0.46um x 2.72um = 1.2512 um²`，8-grid cell height |
| 定位 | high density |
| routed gate density | 160 kGates/mm² 或更高 |
| leakage | 文档给出约 `0.86 nA/kGate` 的典型级别说明 |
| trade-off | 密度高、动态功耗较低，但驱动能力不是最高 |

这和生活里的“货架”很像：

- 高密度库：货架格子更小，一个仓库能放更多小盒子。
- 高速库：每个盒子可能更大，搬运通道更宽，速度更快但占地方。
- 低漏电库：盒子关得更严，平时耗电少，但开关速度可能慢。

本项目是一个很小的 PWM 控制器，不是高速 CPU 数据通路，所以选择 `sky130_fd_sc_hd` 合理：面积小、简单、工具链默认支持好。

## 4. 库文件不止一个：每一种文件服务一个工具

同一个标准单元库，会被拆成很多“视图”。每个视图不是重复，而是给不同工具看的。

| 文件/目录 | 给谁用 | 里面是什么 | 作用 |
| --- | --- | --- | --- |
| `.lib` Liberty | 综合、STA | cell 面积、输入电容、delay table、setup/hold、功耗 | 算 PPA 的核心数据 |
| `.lef` | PnR | cell 外形、pin 位置、阻塞层、site 信息 | 告诉布局布线工具单元怎么摆、线怎么接 |
| `.gds`/`.mag` | 版图、DRC | 单元内部真实几何图形 | 最终制造和几何检查 |
| SPICE/CDL | LVS/电路级 | transistor/netlist | 和版图提取结果比对 |
| tech LEF / tech file | PnR/Magic/KLayout | 金属层、via、设计规则 | 告诉工具工艺层级和规则 |

可以把它理解成同一辆车的不同资料：

- Liberty 像性能表：油耗、百公里加速、最大载重。
- LEF 像外形尺寸图：长宽高、门在哪里、轮子在哪里。
- GDS 像制造图纸：每一个螺丝孔、焊点、金属片。
- SPICE 像电路原理图：电线和元件怎么连。

## 5. PPA 三个字母：面积、性能、功耗

PPA 是：

```text
P = Performance 性能，主要看频率/延时/时序裕量
P = Power 功耗，动态功耗 + 静态漏电
A = Area 面积，标准单元面积 + 布线/宏单元/物理填充
```

它们互相牵制：

- 想更快：常常要用更大驱动单元、更多 buffer、更宽布线，面积和功耗上升。
- 想更省电：常常要降低切换、降低电压、用低漏电单元，速度可能下降。
- 想更小：常常用小驱动单元和高密度库，但线可能更拥挤，时序更难。

PWM 这个项目很小，所以 PPA 不像大芯片那样复杂，但它正好适合学习“指标从哪里来”。

## 6. 本项目的真实 PPA 摘要

从 `delivery/phase3_synthesis/metrics.csv` 抽取关键字段：

| 指标 | 值 | 怎么理解 |
| --- | ---: | --- |
| `STD_CELL_LIBRARY` | `sky130_fd_sc_hd` | 用的标准单元库 |
| `CLOCK_PERIOD` | `20.0 ns` | 目标时钟周期，等价 50 MHz |
| `critical_path_ns` | `0.86 ns` | 工具统计的关键路径延时量级 |
| `wns` / `tns` | `0.0 / 0.0` | 无 setup 违例 |
| `spef_wns` / `spef_tns` | `0.0 / 0.0` | 提取寄生后仍无违例 |
| `synth_cell_count` | `53` | 综合后非物理逻辑单元数量 |
| `TotalCells` | `220` | PnR 后总 component，含 fill/decap/tap/clock buffer |
| `CoreArea_um^2` | `1096.0512 um²` | core 面积 |
| `DIEAREA_mm^2` | `0.002503876 mm²` | die 面积 |
| `Final_Util` | `61.758%` | 最终利用率 |
| `wire_length` | `1190 um` | 总走线长度 |
| `vias` | `498` | 过孔数量 |
| `Magic/KLayout/LVS/Antenna` | `0/0/0/0` | 物理验证通过 |

注意：早期自动报告里有字段误读，把 `(Cell/mm^2)/Core_Util` 当成面积，这是不对的。面积请优先看 `DIEAREA_mm^2` 和 `CoreArea_um^2`。

面积单位要特别小心：

```text
1 mm = 1000 um
1 mm² = 1,000,000 um²
0.002503876 mm² = 2503.876 um²
```

所以本项目的 die 面积约 `2503.876 um²`，core 面积约 `1096.0512 um²`。die 是外框，core 是里面真正摆标准单元和布线的核心区域。

## 7. 本项目综合后用了哪些真实标准单元

从 `delivery/phase3_synthesis/pwm_ctrl_synth.v` 统计，综合后共 53 个 `sky130_fd_sc_hd` 单元：

| 单元 | 数量 | 直观解释 |
| --- | ---: | --- |
| `sky130_fd_sc_hd__dfxtp_2` | 8 | 8 个 D 触发器，对应 8 位 counter |
| `sky130_fd_sc_hd__a21oi_2` | 7 | 复合门，常用于比较/加法逻辑 |
| `sky130_fd_sc_hd__or2b_2` | 5 | 带反相输入的 OR 组合 |
| `sky130_fd_sc_hd__o21a_2` | 5 | OR-AND 复合门 |
| `sky130_fd_sc_hd__inv_2` | 4 | 反相器 |
| `sky130_fd_sc_hd__and2b_2` | 3 | 带反相输入的 AND |
| `sky130_fd_sc_hd__nor2_2` | 3 | 2 输入 NOR |
| 其他组合门 | 18 | `and3/and4/xor/or/nor/复合 AOI/OAI` 等 |

为什么有这么多复合门？因为真实综合不是只用 NAND/NOR 慢慢搭。库里有很多复合单元，例如 AOI/OAI 类单元，可以把几级简单逻辑压到一个 cell 里：

```text
简单门拼法: AND -> OR -> INV，可能要 2~3 级
复合门拼法: 一个 AOI/OAI 单元完成，可能只要 1 级
```

这会同时影响：

- 面积：一个复合门可能比多个简单门更省。
- 延时：少一级逻辑通常更快。
- 功耗：少一些中间节点切换，动态功耗可能更低。

## 8. 单元面积、电容、漏电从哪里来

以本地 `sky130_fd_sc_hd__tt_025C_1v80.lib` 中几个单元为例。Liberty 里的 `area` 对 SKY130 标准单元可以按 `um²` 理解：

| 单元 | area (um²) | leakage power | 输入/输出电容示例 |
| --- | ---: | ---: | --- |
| `dfxtp_2` | `21.2704` | `0.008444527 pW` | `CLK=0.001787 pF`, `D=0.001677 pF` |
| `inv_2` | `3.7536` | `0.004247907 pW` | `A=0.004459 pF` |
| `a21oi_2` | `8.7584` | `0.001787537 pW` | `A1=0.004443 pF`, `A2=0.004830 pF` |
| `or2b_2` | `8.7584` | `0.003727983 pW` | `A=0.001706 pF`, `B_N=0.001422 pF` |
| `xor2_2` | `16.2656` | `0.005594192 pW` | `A=0.008980 pF`, `B=0.008165 pF` |
| `clkbuf_1` | `3.7536` | `0.001181018 pW` | `A=0.002098 pF` |

这些数字的意义：

- `area`：这个 cell 在标准单元 row 中占多少面积，单位是 `um²`。例如一个 site 约 `1.2512 um²`，`inv_2` 的面积 `3.7536 um²` 大约是 3 个 site。
- `capacitance`：驱动这个 pin 需要搬多少电荷。电容越大，前一级越吃力。
- `cell_leakage_power`：静态不切换时也会漏掉的功耗。
- delay table：不同输入 slew、不同输出 load 下，cell 延时是多少。

## 9. 功耗从第一性原理怎么理解

数字电路功耗粗略分三类：

```text
动态开关功耗: P_dynamic ≈ α · C · V² · f
短路功耗: 输入翻转时 PMOS/NMOS 短暂同时导通
漏电功耗: 晶体管关着也有微小电流
```

其中最重要的是：

- `C`：总电容，来自 cell pin 电容 + wire 电容。
- `V`：电压，1.8V 比 1.0V 功耗高很多，因为是平方关系。
- `f`：频率，时钟越快，翻转次数越多。
- `α`：活动因子，不是每个节点每拍都翻转。

本项目 `metrics.csv` 里的 typical 功耗非常小：

```text
internal power  ≈ 4.55e-05 uW
switching power ≈ 1.05e-05 uW
leakage power   ≈ 5.83e-10 uW
```

这个量级看起来很小，原因是 PWM 模块极小，而且这里没有真实业务 toggle activity 的完整功耗签核。它适合学习功耗字段，不适合当作产品级功耗结论。

## 10. 小结

本项目从综合往后，最核心的库就是：

```text
sky130A PDK
  -> sky130_fd_sc_hd 标准单元库
  -> Liberty: 面积/延时/功耗
  -> LEF: 外形/pin/布线抽象
  -> GDS/MAG: 真实几何版图
  -> SPICE/CDL: LVS 电路连接
```

用一句话概括：

```text
综合工具用 Liberty 决定“选哪个 cell”；
布局布线工具用 LEF 决定“cell 怎么摆、线怎么接”；
STA 用 Liberty + SDC + SPEF/SDF 算“够不够快”；
DRC/LVS/GDS 用物理版图检查“能不能制造、版图和电路是否一致”。
```
