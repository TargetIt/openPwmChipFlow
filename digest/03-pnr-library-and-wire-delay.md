# 布局布线阶段：物理库、线延时、SPEF/SDF/DEF/GDS 如何进入后端

## 1. 综合之后，事情还远远没结束

综合结束后，我们有一个门级网表：

```text
53 个 sky130_fd_sc_hd 逻辑单元
8 个触发器
若干组合逻辑门
```

但门级网表只回答：

```text
用哪些门？
门和门之间逻辑上怎么连？
```

它还没有回答：

```text
这些门放在哪里？
线从哪里走？
电源怎么送？
时钟怎么分发？
金属层够不够？
会不会违反工艺间距？
版图和网表是否一致？
```

这些就是 PnR，Place and Route，布局布线。

## 2. PnR 阶段用哪些库文件

从综合进入 PnR，工具需要更多“物理视图”。

| 视图 | 文件 | PnR 中的作用 |
| --- | --- | --- |
| Liberty `.lib` | `sky130_fd_sc_hd__*.lib` | 仍然用于 timing、cell area、pin cap、power |
| LEF | standard cell LEF + tech LEF | cell 外形、pin 位置、routing blockage、site/row |
| tech LEF / tech file | PDK tech files | 金属层、via、pitch、spacing、min width |
| DEF | `pwm_ctrl.def` | 本设计实例化后的位置、连线、row、track |
| SPEF | `pwm_ctrl.nom.spef` 等 | 布线后提取的寄生电阻/电容 |
| SDF | `pwm_ctrl.nom.Typical.sdf` 等 | 反标延时，给仿真/检查用 |
| GDS/MAG | `pwm_ctrl.gds` / `.mag` | 真实几何版图 |
| SPICE | `pwm_ctrl.spice` | LVS 比对用电路网表 |

综合阶段主要看 Liberty；PnR 阶段要同时看 Liberty + LEF + tech + DEF + SPEF。

## 3. DEF 告诉我们：综合单元和物理单元不是一回事

综合网表里有 53 个逻辑单元。但 `delivery/phase4_pnr/pwm_ctrl.def` 里有：

```text
COMPONENTS 220 ;
```

从 DEF 统计，PnR 后主要 component 包括：

| 单元 | 数量 | 类型 |
| --- | ---: | --- |
| `decap_3` | 96 | 去耦电容单元 |
| `fill_1/fill_2` | 34 | filler 填充单元 |
| `tapvpwrvgnd_1` | 14 | well tap / tap cell |
| `dlygate4sd3_1` | 8 | 延时/修 hold 等物理优化相关单元 |
| `clkbuf_*` | 11 | 时钟 buffer |
| `buf_*` | 4 | 普通 buffer |
| 逻辑门/触发器 | 53 左右 | 综合功能逻辑 |

为什么会多出这么多？

因为真实芯片不是把逻辑门孤零零摆上去就完了。

### filler cell

标准单元 row 需要连续填满，不能留下奇怪空洞。filler 像“填缝剂”，保证版图连续、well/implant 层连接正确。

### tap cell

晶体管的 body/well 需要正确接到电源/地，防止 latch-up、body 电位漂移。tap cell 像地基上的接地桩。

SkyWater 文档也说明，标准单元大多不在每个 cell 内自带 tap，而是通过 tap cell 形成 staggered tap grid。

### decap cell

decap 是去耦电容。数字电路翻转时会瞬间拉电流，电源网络会抖。decap 像附近的小水箱，短时间补电荷，降低电源噪声。

### clock buffer

时钟要送到所有触发器。时钟线负载大，不能一个端口直接拉全片。clock buffer 像沿途的泵站，把时钟边沿重新放大、分发。

## 4. 为什么线会有延时

数字设计刚开始看起来像逻辑：

```text
Y = A & B
```

但放到硅片上，它变成电学问题：

```text
A/B/Y 都是金属线
金属线有电阻 R
金属线对衬底/邻线有电容 C
```

要让一根线从 0 变 1，本质是给电容充电：

```text
Q = C · V
I = dQ/dt
```

如果线电容 C 大、驱动电流 I 小，就需要更久。粗略看：

```text
delay ≈ R · C
```

所以同一个逻辑门，在综合阶段可能很快；布局布线后，因为线变长、via 变多、负载变大，就会变慢。

## 5. SPEF 怎么描述线

SPEF 是 Standard Parasitic Exchange Format。它描述每根 net 的寄生参数。

本项目 `delivery/phase4_pnr/spef/pwm_ctrl.nom.spef` 开头：

```text
*T_UNIT 1 NS
*C_UNIT 1 PF
*R_UNIT 1 OHM

*D_NET *3 0.00218423
*CONN
*CAP
*RES
```

解释：

- 时间单位 ns。
- 电容单位 pF。
- 电阻单位 Ohm。
- `D_NET` 表示一个 net。
- 后面的 `0.00218423` 是总电容，单位 pF。
- `CAP` 列出电容分布。
- `RES` 列出电阻分段。

手算线延时时，可以先做很粗的 lumped 近似：

```text
net_cap = SPEF 中 D_NET 后面的总电容
wire_delay ≈ driver_resistance * net_cap + wire_resistance * net_cap 的一部分
```

STA 工具会比这个更精细，因为它知道每段 RC 网络和拓扑。

## 6. SDF 怎么描述布线后延时

SDF 是计算结果的一种交付格式。

`delivery/phase4_pnr/sdf/pwm_ctrl.nom.Typical.sdf` 里有：

```text
(INTERCONNECT clk clkbuf_0_clk.A (0.034:0.034:0.034) ...)
(INTERCONNECT duty[0] input1.A (0.017:0.017:0.017) ...)
```

这表示具体连线延时已经被算出来：

- `clk -> clkbuf_0_clk.A` 约 0.034ns。
- `duty[0] -> input1.A` 约 0.017ns。

SDF 里的三元组：

```text
(min:typ:max)
```

本项目这个文件是 Typical corner，所以很多地方 min/typ/max 相同。

## 7. 布局布线的主要阶段

OpenLane 的 PnR 大致可按下面理解：

```text
1. Floorplan
   决定 die/core 大小、row、IO pin、power grid 初始形态。

2. Placement
   把标准单元放到 row 上，先 global placement，再 detailed placement。

3. CTS
   Clock Tree Synthesis，建立时钟树，加 clock buffer，控制 skew。

4. Routing
   先 global routing 规划大概通道，再 detailed routing 画出具体金属线/via。

5. Fill / Tap / Decap / Diode
   插入物理辅助单元，满足制造、电源、antenna 等需求。

6. Extraction
   从版图提取 SPEF、SPICE。

7. Signoff checks
   STA、DRC、LVS、Antenna、GDS stream-out。
```

本项目的 `metrics.csv` 给出：

```text
Final_Util      = 61.758%
wire_length     = 1190 um
vias            = 498
tritonRoute violations = 0
Magic violations       = 0
KLayout violations     = 0
LVS total errors       = 0
Antenna violations     = 0
```

## 8. 为什么 CTS 会改变时序

综合阶段常常把时钟网络当成 ideal：

```text
clock network delay = 0
```

真实 PnR 后，时钟线需要：

- 从 clk port 出发。
- 经 clock buffer。
- 到每个触发器 CLK pin。

不同触发器收到时钟的时间不完全一样，这叫 skew。

如果 launch FF 的时钟晚、capture FF 的时钟早，setup 更紧。

如果 launch FF 的时钟早、capture FF 的时钟晚，hold 更紧。

所以 CTS 的目标不是“让时钟线最短”，而是：

```text
让时钟尽量同步到达所有触发器，同时控制功耗和面积。
```

本项目最终 DEF 里出现了 `clkbuf_1/2/16` 等时钟 buffer，这就是 CTS/后端优化留下的痕迹。

## 9. 布线层和 via 的直觉

SKY130A 是 5 层金属 + local interconnect。OpenLane 文档说明 `sky130A` 是默认变体，包含 local interconnect 和 5 metal layers。

金属层越高，通常越适合走长线，但 via 也会带来额外电阻/电容。

可以把布线理解成城市道路：

- 低层金属像小巷，适合局部连接。
- 高层金属像主干道，适合长距离连接。
- via 像上下匝道，必要但有代价。

本项目 via 数量是 498。这个数字不是违例，它只是说明跨层连接出现了 498 次。

早期自动报告里曾把 via/wire 数误写到物理验证表，这是误读。真正 DRC/LVS/Antenna 结果应看对应字段：

```text
Magic_violations = 0
klayout_violations = 0
lvs_total_errors = 0
pin_antenna_violations = 0
net_antenna_violations = 0
```

## 10. DRC、LVS、Antenna 各自检查什么

### DRC

Design Rule Check，几何规则检查。

它问：

```text
线宽够不够？
间距够不够？
via 是否合法？
金属密度是否满足？
```

DRC 不关心你的 PWM 功能对不对，只关心版图是否符合工艺制造规则。

### LVS

Layout Versus Schematic。

它问：

```text
从版图提取出来的电路，和原始网表是不是同一个电路？
```

如果一个门接错、少接、多接，LVS 会发现。

### Antenna

制造过程中，长金属线可能像天线一样积累电荷，损坏晶体管栅氧。

Antenna check 问：

```text
某个 gate 连接的金属面积是否太大？
制造过程中是否可能积累过多电荷？
```

修复方法可能包括：

- 插 antenna diode。
- 改 routing，跳到高层金属。
- 分段连接。

## 11. PnR 对 PPA 的影响

综合阶段只知道逻辑，不知道真实线。

PnR 后，PPA 会变化：

### Area

增加：

- tap cell
- decap cell
- filler
- clock buffer
- hold buffer

所以 PnR 后 `TotalCells=220`，远大于综合逻辑单元 `53`。

### Performance

增加：

- wire delay
- clock skew
- via RC

减少：

- 通过 sizing/buffer/placement 优化改善关键路径。

本项目很小，20ns 目标很宽松，所以 PnR 后仍然没有 timing violation。

### Power

增加：

- clock tree buffer 功耗。
- 长线电容切换功耗。
- decap/tap/fill 对版图和泄漏的影响。

降低：

- 合理 placement 可以减少线长。
- clock gating 可减少不必要切换，但本项目没有复杂 clock gating。

## 12. 从本项目读后端产物的顺序

建议你按这个顺序看：

```text
1. delivery/phase3_synthesis/pwm_ctrl_synth.v
   看综合后用了哪些 sky130_fd_sc_hd cell。

2. delivery/phase4_pnr/pwm_ctrl.def
   看这些 cell 被放到哪里，以及 PnR 增加了哪些物理 cell。

3. delivery/phase4_pnr/spef/pwm_ctrl.nom.spef
   看每根 net 的寄生电容和电阻。

4. delivery/phase4_pnr/sdf/pwm_ctrl.nom.Typical.sdf
   看线延时和 cell 延时如何被反标。

5. delivery/phase6_gds/pwm_ctrl.gds
   看最终流片版图。

6. delivery/phase5_verification/
   看 DRC/LVS/Antenna 签核结果。
```

## 13. 小结

布局布线阶段的核心变化是：

```text
逻辑世界
  -> 物理世界
```

综合说：

```text
这个 PWM 可以用 53 个逻辑 cell 实现。
```

PnR 说：

```text
为了让它真的能制造、能供电、能布线、能收敛时序，
我要把它扩展成 220 个 physical components，
加入 tap、decap、fill、clock buffer，
提取 1190um 走线和 498 个 via，
再用 SPEF/SDF 回到 STA 检查。
```

这就是后端最重要的思想：

```text
功能正确只是开始。
真正的芯片还必须在面积、时序、功耗、制造规则、电源完整性、版图一致性之间同时成立。
```
