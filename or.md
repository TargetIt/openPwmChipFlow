# PWM 数字芯片全流程开发策略

**PWM Controller + Sky130 (130nm) + OpenLane2 + AI 辅助**

> 目标：用最简单的设计，跑通 RTL → GDS 完整流程

---

## 为什么选 PWM

| 对比项 | PWM | UART TX | FemtoRV32 |
|--------|-----|---------|-----------|
| 代码行数 | ~25 行 | ~50 行 | ~1500 行 |
| 状态机 | 无 | 有（4状态）| 有（多层）|
| 验证难度 | ⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| 全流程时间 | 4–5 天 | 2–3 周 | 2–3 月 |
| 推荐顺序 | **第 1 个** | 第 2 个 | 第 3 个 |

PWM 只有计数器 + 比较器，逻辑一眼看穿，适合把全部精力放在学习工具链上。

---

## PWM 模块设计规格

### 端口定义

| 端口 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| `clk` | input | 1 | 时钟 |
| `rst` | input | 1 | 同步复位，高有效 |
| `duty` | input | 8 | 占空比 0–255，对应 0%–100% |
| `pwm_out` | output | 1 | PWM 输出信号 |

### 完整 RTL（约 25 行）

```verilog
module pwm_ctrl (
  input        clk,
  input        rst,
  input  [7:0] duty,
  output       pwm_out
);
  reg [7:0] counter;

  always @(posedge clk) begin
    if (rst)
      counter <= 8'd0;
    else
      counter <= counter + 8'd1;  // 自动溢出回绕
  end

  assign pwm_out = (counter < duty);

endmodule
```

就这些。没有状态机、没有复杂时序，逻辑一眼看穿。

---

## 全流程总览

```
pwm_ctrl.v
    │
    ├─ Phase 1: RTL 编写       VS Code + Claude         0.5 天
    │
    ├─ Phase 2: 仿真验证       iverilog + GTKWave        1 天
    │
    ├─ Phase 3: 综合           Yosys (via OpenLane2)    0.5 天
    │
    ├─ Phase 4: 布局布线       OpenROAD (via OpenLane2) 1–2 天
    │
    ├─ Phase 5: 物理验证       Magic + Netgen           0.5 天
    │
    └─ Phase 6: GDS 输出       KLayout                  0.5 天

总计：约 4–5 天
```

---

## Phase 1 — RTL 编写（0.5 天）

### 目录结构

```
pwm_project/
  ├── src/
  │   └── pwm_ctrl.v        ← 主设计文件
  ├── tb/
  │   └── tb_pwm.v          ← Testbench
  └── openlane/
      └── config.json       ← OpenLane2 配置
```

### AI 辅助要点

- 让 Claude 生成 `pwm_ctrl.v`，确认端口与规格一致
- 让 AI 检查：reset 极性、位宽匹配、综合风险
- 保持 25 行以内，不要过度设计

---

## Phase 2 — 仿真验证（1 天）

### 工具安装

```bash
sudo apt install iverilog gtkwave
```

### Testbench

```verilog
// tb/tb_pwm.v
module tb_pwm;
  reg clk = 0, rst = 1;
  reg [7:0] duty;
  wire pwm_out;

  pwm_ctrl dut (
    .clk(clk), .rst(rst),
    .duty(duty), .pwm_out(pwm_out)
  );

  always #5 clk = ~clk;  // 100MHz

  initial begin
    $dumpfile("wave.vcd"); $dumpvars;
    #20 rst = 0; duty = 8'd128;   // 50% 占空比
    #2560;
    duty = 8'd64;                  // 25% 占空比
    #2560;
    duty = 8'd0;                   // 0%
    #512; $finish;
  end
endmodule
```

### 运行仿真

```bash
iverilog -o sim tb/tb_pwm.v src/pwm_ctrl.v
./sim
gtkwave wave.vcd
```

### 验证检查点

| 检查项 | 预期结果 |
|--------|----------|
| duty=128，占空比 | 50% |
| duty=64，占空比 | 25% |
| duty=0，输出 | 全低电平 |
| duty=255，输出 | 接近全高 |
| rst=1 时 | counter=0，pwm_out=0 |

> ✅ 波形正确后，才进入下一阶段

---

## Phase 3 — 综合（0.5 天）

### OpenLane2 配置

```json
{
  "DESIGN_NAME": "pwm_ctrl",
  "VERILOG_FILES": "src/pwm_ctrl.v",
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 20.0,
  "PDK": "sky130A",
  "STD_CELL_LIBRARY": "sky130_fd_sc_hd"
}
```

### 只跑综合步骤

```bash
openlane config.json --to synthesis
```

### 预期综合结果

| 指标 | PWM 预期值 | 说明 |
|------|-----------|------|
| 标准单元数 | 20–50 个 | 极少 |
| 关键路径 | < 2 ns | 远优于 20ns 约束 |
| 面积 | < 200 μm² | 极小 |
| 时序违例 | 0 | 必须干净 |

---

## Phase 4 — 布局布线（1–2 天）

### 运行完整流程

```bash
openlane config.json   # RTL → GDS 一键完成
```

### 推荐初始参数

| 参数 | 推荐值 | 原因 |
|------|--------|------|
| `CLOCK_PERIOD` | 20.0 ns | 50 MHz，PWM 完全够用 |
| `FP_CORE_UTIL` | 30 | 设计极小，低利用率更稳定 |
| `PL_TARGET_DENSITY` | 0.3 | 留足余量，避免拥塞 |

PWM 设计极小，整个 PnR 流程通常 **5 分钟内**完成。

---

## Phase 5 — 物理验证（0.5 天）

OpenLane2 流程结束后自动运行 DRC 和 LVS，报告位于：

```
runs/RUN_xxx/reports/signoff/drc.rpt
runs/RUN_xxx/reports/signoff/lvs.rpt
```

### PWM 常见违例（极少）

| 违例类型 | 原因 | 处理方法 |
|----------|------|----------|
| Antenna violation | 金属线过长 | OpenLane2 默认自动插入 antenna diode |
| Metal spacing | 绕线密度过高 | 降低 `PL_TARGET_DENSITY` 重跑 |
| LVS mismatch | 端口连接错误 | 检查 `pwm_ctrl.v` 端口声明 |

> ✅ DRC=0，LVS=clean，即完成全流程

---

## Phase 6 — GDS 输出（0.5 天）

### 输出文件

| 文件 | 路径 | 用途 |
|------|------|------|
| `pwm_ctrl.gds` | `results/final/gds/` | 流片主文件 |
| `pwm_ctrl.lef` | `results/final/lef/` | IP 集成接口 |
| `pwm_ctrl.lib` | `results/final/lib/` | 时序模型 |
| `final_summary.html` | `runs/RUN_xxx/` | 完整流程报告 |

### 查看 GDS

```bash
klayout runs/RUN_xxx/results/final/gds/pwm_ctrl.gds
```

看到真实的芯片版图，全流程完成 🎉

---

## 工具链汇总

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| OpenLane2 | 全流程框架（含 Yosys/OpenROAD/Magic）| Docker（推荐）|
| iverilog | RTL 仿真 | `apt install iverilog` |
| GTKWave | 波形查看 | `apt install gtkwave` |
| KLayout | GDS 查看 | `apt install klayout` |
| Sky130 PDK | 130nm 工艺库 | OpenLane2 自动下载 |

### Docker 安装 OpenLane2（最省事）

```bash
docker pull efabless/openlane2:latest
```

---

## AI 辅助策略

| 阶段 | Claude 做什么 | 你做什么 |
|------|--------------|----------|
| RTL | 生成初稿，检查综合风险 | 确认逻辑符合需求 |
| 仿真 | 生成 testbench，分析波形异常 | 对比波形与预期 |
| 综合 | 解读报告，分析面积/时序 | 确认无违例 |
| PnR | 分析拥塞，建议调参 | 更新 config.json 重跑 |
| 验证 | 解读 DRC/LVS 报告，给出修复建议 | 按建议修改重跑 |

---

## 快速启动（5步）

```bash
# Step 1：安装 OpenLane2
docker pull efabless/openlane2:latest

# Step 2：创建项目
mkdir pwm_project && cd pwm_project
mkdir src tb openlane

# Step 3：写 RTL（或让 Claude 生成）
# 把 pwm_ctrl.v 放入 src/

# Step 4：仿真验证
iverilog -o sim tb/tb_pwm.v src/pwm_ctrl.v && ./sim
gtkwave wave.vcd

# Step 5：跑全流程
docker run -v $(pwd):/work efabless/openlane2 \
  openlane /work/openlane/config.json
```

---

## 里程碑检查表

- [ ] RTL 完成 — `pwm_ctrl.v` 不超过 30 行，端口清晰
- [ ] 仿真通过 — GTKWave 波形占空比与 duty 值一致
- [ ] 综合干净 — Yosys 报告无时序违例
- [ ] PnR 完成 — OpenLane2 流程无 ERROR 结束
- [ ] DRC clean — violation = 0
- [ ] LVS clean — net/device match
- [ ] GDS 生成 — KLayout 可正常打开版图
- [ ] **全流程跑通 🎉 — 下一步挑战 UART TX！**

---

*从 25 行代码出发，走完芯片设计的完整旅程。*
