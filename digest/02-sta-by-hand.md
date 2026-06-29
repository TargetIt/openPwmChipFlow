# 手动理解 STA：不用工具时，怎样一步一步算静态时序

## 1. STA 到底在算什么

STA 是 Static Timing Analysis，静态时序分析。

它不跑仿真，不枚举所有输入波形，而是把电路看成一张有向图：

```text
节点: pin / net / cell
边: cell delay / wire delay / setup/hold constraint
```

STA 的核心问题只有两个：

```text
setup: 数据能不能在下一个时钟沿之前稳定？
hold : 数据会不会在当前时钟沿之后太快变化？
```

从第一性原理看，一个触发器像一个带门禁的仓库：

- 时钟沿来时，仓库门打开一瞬间，把 D 端数据锁进 Q。
- setup 要求：门打开前，货物已经摆好。
- hold 要求：门刚关上后，货物不要立刻被搬走。

## 2. STA 需要哪些输入

手算 STA，需要这些东西：

| 输入 | 本项目对应文件 | 作用 |
| --- | --- | --- |
| 门级网表 | `delivery/phase3_synthesis/pwm_ctrl_synth.v` | 知道路径上有哪些 cell |
| Liberty | `sky130_fd_sc_hd__tt_025C_1v80.lib` | 查 cell delay、setup/hold、pin cap、area、power |
| SDC 约束 | `delivery/phase4_pnr/pwm_ctrl.sdc` | 知道 clock、input/output delay、uncertainty、load |
| SPEF | `delivery/phase4_pnr/spef/pwm_ctrl.nom.spef` | 知道每根线的 R/C 寄生 |
| SDF | `delivery/phase4_pnr/sdf/` | 记录计算后的 interconnect/cell delay |
| STA 日志 | `delivery/phase3_synthesis/2-sta.log` | 工具算出的路径明细，可用于对照 |

项目 SDC 里最关键的约束：

```tcl
create_clock -name clk -period 20.0000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_input_delay 4.0000 -clock [get_clocks {clk}] [get_ports ...]
set_output_delay 4.0000 -clock [get_clocks {clk}] [get_ports {pwm_out}]
set_load -pin_load 0.0334 [get_ports {pwm_out}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 ...
set_timing_derate -early 0.9500
set_timing_derate -late 1.0500
```

翻译成人话：

- 时钟周期是 20ns，也就是 50MHz。
- 时钟边沿自身有 0.15ns transition。
- 留 0.25ns 不确定性，防止时钟抖动、模型误差。
- 外部输入默认已经花掉 4ns 才到芯片端口。
- 输出端口外面挂了约 0.0334pF 的负载。
- 输入端假设由 `inv_2` 这类驱动单元推动。
- early/late derate 分别给 hold/setup 留模型余量。

## 3. 一条 setup 路径怎么定义

典型寄存器到寄存器 setup 路径：

```text
launch FF 的 CLK
  -> launch FF 的 Q
  -> 组合逻辑 cell 1
  -> 组合逻辑 cell 2
  -> ...
  -> capture FF 的 D
```

setup 要求：

```text
数据到达时间 <= 数据要求时间
```

写成公式：

```text
arrival_setup =
  launch_clock_arrival
  + clk_to_q_max
  + max(combinational_cell_delay)
  + max(wire_delay)

required_setup =
  capture_clock_arrival
  + clock_period
  - setup_time
  - clock_uncertainty
  - setup_margin

setup_slack = required_setup - arrival_setup
```

如果 `setup_slack >= 0`，路径通过。

如果 `setup_slack < 0`，数据太慢，下一拍来不及被正确采样。

## 4. 一条 hold 路径怎么定义

hold 路径也从 launch FF 到 capture FF，但看的是“太快”：

```text
arrival_hold =
  launch_clock_arrival
  + clk_to_q_min
  + min(combinational_cell_delay)
  + min(wire_delay)

required_hold =
  capture_clock_arrival
  + hold_time
  + clock_uncertainty
  + hold_margin

hold_slack = arrival_hold - required_hold
```

如果 `hold_slack >= 0`，路径通过。

如果 `hold_slack < 0`，数据变化太早，可能破坏当前拍刚采到的数据。

注意 setup 和 hold 的直觉相反：

- setup 怕慢。
- hold 怕快。

## 5. 从 Liberty 查 cell delay：为什么不是一个固定数字

很多初学者会以为：

```text
一个 AND 门延时 = 固定 0.1ns
```

真实情况不是这样。cell 延时取决于两个主要变量：

```text
输入 slew: 输入信号自己翻转得快不快
输出 load: 输出端要驱动多少电容
```

原因很物理：

- 输出电容越大，要搬的电荷越多，延时越大。
- 输入边沿越慢，晶体管打开得越磨叽，延时也变大。

Liberty 里通常是二维表：

```text
delay = table[input_slew][output_cap]
transition = table[input_slew][output_cap]
```

如果实际 slew/cap 落在表格之间，STA 工具插值：

```text
delay ≈ 周围四个表格点的双线性插值结果
```

所以 STA 的算法不是魔法，它就是：

```text
沿路径传播 slew/cap
  -> 查表
  -> 插值
  -> 累加 delay
  -> 和 required time 比较
```

## 6. 用本项目一条 hold 路径手算

`delivery/phase3_synthesis/2-sta.log` 里第一条 hold 路径：

```text
Startpoint: _96_ (rising edge-triggered flip-flop clocked by clk)
Endpoint  : _96_ (rising edge-triggered flip-flop clocked by clk)
Path Type : min
```

路径摘录：

```text
clock clk                              time 0.00
_96_/CLK
_96_/Q      dfxtp_2 delay 0.35         time 0.35
_88_/A1
_88_/X      o21a_2 delay 0.11          time 0.47
_96_/D                               arrival 0.47

capture clock                          time 0.00
clock uncertainty                       0.25
library hold time                      -0.01
required time                           0.24

slack = arrival - required = 0.47 - 0.24 = 0.23 ns
```

所以这条 hold 路径通过：

```text
hold_slack = 0.23ns > 0
```

这里有一个看起来奇怪的地方：library hold time 是 `-0.01ns`。这在真实 Liberty 模型中可能出现。它表示这个触发器在特定 slew/load 条件下，对 hold 的等效要求可以是负值。不要把 setup/hold 理解成永远正数；它们也是表征模型的一部分。

## 7. 用本项目一条 setup 路径手算

STA 日志里有一条输入到输出路径：

```text
Startpoint: duty[3] (input port clocked by clk)
Endpoint  : pwm_out (output port clocked by clk)
Path Type : max
```

摘录的核心数字：

```text
data arrival time   = 5.24 ns
clock period        = 20.00 ns
clock uncertainty   = 0.25 ns
output delay        = 4.00 ns
data required time  = 15.75 ns
slack               = 10.51 ns
```

怎么来的？

第一步，外部输入已经消耗了 4ns：

```text
input_delay = 4.00ns
```

第二步，信号经过输入驱动假设、组合逻辑、内部连线，累计到：

```text
arrival = 5.24ns
```

第三步，输出端要求不能占满整个 20ns，因为外部接收电路还需要时间，所以扣掉 output delay 和 uncertainty：

```text
required = clock_period - output_delay - uncertainty
         = 20.00 - 4.00 - 0.25
         = 15.75ns
```

第四步，算 slack：

```text
setup_slack = required - arrival
            = 15.75 - 5.24
            = 10.51ns
```

所以这条输入到输出路径非常宽松。

## 8. WNS 和 TNS 是什么

STA 会检查很多路径。每条路径都有 slack。

```text
WNS = Worst Negative Slack
TNS = Total Negative Slack
```

更通俗地说：

- WNS：最差那条路径差多少。
- TNS：所有失败路径一共差多少。

如果全部路径都通过，很多工具会把 WNS/TNS 报成 0 或非负通过状态。

本项目 `metrics.csv`：

```text
wns      = 0.0
tns      = 0.0
spef_wns = 0.0
spef_tns = 0.0
```

这说明在当前约束和模型下没有时序违例。

## 9. SPEF 为什么会改变 STA

综合阶段通常对线延时估得比较粗。布局布线后，线真的被拉出来了：

- 线多长？
- 走在哪一层金属？
- 中间有几个 via？
- 旁边有多少耦合电容？

这些信息写在 SPEF 中。

`delivery/phase4_pnr/spef/pwm_ctrl.nom.spef` 里可以看到：

```text
*T_UNIT 1 NS
*C_UNIT 1 PF
*R_UNIT 1 OHM

*D_NET *3 0.00218423
*CAP
*RES
```

每个 `D_NET` 后面的数是该 net 的总电容，单位是 pF。后面 `CAP` 和 `RES` 会列出分布电容和电阻。

线延时的第一性原理是 RC 充放电：

```text
电容 C 越大，充电越慢
电阻 R 越大，电流越小，充电越慢
```

一个很粗的近似：

```text
wire_delay ≈ R * C
```

实际 STA 会用更细的 RC 网络和算法，比如 Elmore delay 或更复杂的模型。

## 10. SDF 是什么：把 STA 结果写成仿真可读格式

SDF 是 Standard Delay Format。

如果 Liberty 像“原始性能手册”，SPEF 像“真实线缆参数”，那 SDF 就像“这次设计算完后的延时清单”。

本项目 `delivery/phase4_pnr/sdf/pwm_ctrl.nom.Typical.sdf` 里有：

```text
(INTERCONNECT clk clkbuf_0_clk.A (0.034:0.034:0.034) ...)
(INTERCONNECT duty[0] input1.A (0.017:0.017:0.017) ...)
```

意思是：

```text
从 clk 端口到 clkbuf_0_clk.A 这段 interconnect 延时约 0.034ns
从 duty[0] 到 input1.A 这段 interconnect 延时约 0.017ns
```

仿真器可以把 SDF 反标到门级网表上，做 gate-level simulation。

## 11. 手动 STA 的完整算法流程

把上面全部合起来，手动 STA 可以按这个流程：

```text
1. 读取门级网表
   找出所有触发器、输入、输出、组合 cell、net 连接。

2. 读取 SDC
   得到 clock period、input delay、output delay、uncertainty、load、driving cell。

3. 读取 Liberty
   为每个 cell 准备:
     area
     input capacitance
     delay table
     transition table
     setup/hold table
     clk->q delay

4. 读取 SPEF
   为每根线准备:
     lumped capacitance
     distributed R/C
     coupling capacitance

5. 建 timing graph
   pin 是节点，cell arc / net arc 是边。

6. 从 startpoint 前向传播 arrival time
   arrival(next) = arrival(prev) + cell_delay + wire_delay

7. 同时传播 slew
   下一级 delay 查表需要用当前输出 slew。

8. 从 endpoint 反向传播 required time
   required(prev) = required(next) - setup/hold requirement - margin

9. 对每条路径算 slack
   setup_slack = required - arrival
   hold_slack  = arrival - required

10. 汇总
   WNS = 最差负 slack
   TNS = 所有负 slack 之和
```

## 12. 和 PWM 项目的关系

本项目很小，所以 20ns 时钟很宽松：

```text
目标周期: 20ns
关键路径量级: 0.86ns
建议频率: 50MHz
```

但它足够展示 STA 的完整链条：

```text
Verilog RTL
  -> Yosys/ABC 映射到 sky130_fd_sc_hd cell
  -> OpenSTA 读取 Liberty + SDC
  -> PnR 后提取 SPEF
  -> 生成 SDF
  -> 计算 WNS/TNS
```

理解 STA 的关键不是背工具命令，而是记住一句话：

```text
STA = 在 timing graph 上，把库里的 cell delay 和版图里的 wire delay 累加起来，再和时钟约束比较。
```
