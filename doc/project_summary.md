# openPwmChipFlow 本地运行总结

## 运行环境

| 项目 | 详情 |
|------|------|
| 操作系统 | Windows 11 Home China (10.0.26200) |
| WSL | Ubuntu 24.04 (WSL2) |
| Docker | Docker Desktop 29.4.1, 镜像 `efabless/openlane:latest` (OpenLane v1.1.1) |
| 仿真工具 | iverilog (Icarus Verilog) |
| PDK | Sky130A, `sky130_fd_sc_hd` 标准单元库 |

## 全流程结果

| 阶段 | 工具 | 状态 | 关键指标 |
|------|------|------|----------|
| Phase 1 RTL | VS Code | ✅ | `pwm_ctrl.v` 18 行 |
| Phase 2 仿真 | iverilog | ✅ | 6/6 测试通过 |
| Phase 3 综合 | Yosys (OpenLane) | ✅ | 53 cells, 关键路径 0.86ns |
| Phase 4 布局布线 | OpenROAD (OpenLane) | ✅ | 面积 0.0025mm², 耗时 1min |
| Phase 5 物理验证 | Magic + Netgen | ✅ | DRC=0, LVS=0 errors |
| Phase 6 GDS 输出 | Magic + KLayout | ✅ | GDS(408K) + LEF + LIB |

## 遇到的问题与修复

### 问题 1：Shell 脚本 CRLF 换行符

**现象**：在 WSL 中执行 `.sh` 脚本时报 `$'\r': command not found` 和语法错误。

**原因**：Git 在 Windows 上默认使用 CRLF 换行符，而 Linux/WSL 的 bash 只接受 LF。

**修复**：
```bash
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} +
```

**教训**：跨平台项目应在 `.gitattributes` 中设置 `*.sh text eol=lf`，或配置 `git config core.autocrlf input`。

---

### 问题 2：Docker 镜像名错误

**现象**：`docker pull efabless/openlane2:latest` 失败，报 `repository does not exist`。

**原因**：OpenLane 2 项目已迁移到 Nix 构建系统，不再在 Docker Hub 发布预构建镜像。Docker Hub 上只有 OpenLane v1 的镜像 `efabless/openlane`。

**修复**：
- 将所有脚本中的 `efabless/openlane2:latest` 改为 `efabless/openlane:latest`
- 使用 `flow.tcl` 而非 `openlane` 作为 CLI 命令

**教训**：开源项目在快速迭代期，文档和实际可用资源可能存在偏差。遇到镜像拉取失败时，先到 Docker Hub 确认实际的镜像名和 Tag。

---

### 问题 3：OpenLane v2 配置格式不兼容 v1

**现象**：OpenLane v1 不支持 `--to synthesis` 参数，JSON 配置中的 `dir::` 路径前缀也不被识别。

**原因**：项目原始配置按 OpenLane v2 格式编写，而实际可用镜像是 OpenLane v1。两者配置格式差异大：
- v1 使用 TCL 配置 (`config.tcl`)，变量为 `set ::env(VAR) value`
- v2 使用 JSON 配置 (`config.json`)，路径前缀 `dir::`
- v1 不支持 `--to`/`--from` 分步运行，通常一键跑全流程

**修复**：
- 创建统一设计目录 `openlane/pwm_ctrl/`，包含 `src/pwm_ctrl.v` 和 `config.tcl`
- 用 `set ::env(PDK_ROOT)` 显式指定 PDK 路径
- 将 SCL 相关配置改为 v1 格式

**v2 配置 (原)**：
```json
{
  "DESIGN_NAME": "pwm_ctrl",
  "VERILOG_FILES": ["dir::../../phase1_rtl/src/pwm_ctrl.v"],
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 20.0,
  "PDK": "sky130A",
  "STD_CELL_LIBRARY": "sky130_fd_sc_hd"
}
```

**v1 配置 (修复后)**：
```tcl
set ::env(DESIGN_NAME) pwm_ctrl
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 20.0
set ::env(PDK) sky130A
set ::env(PDK_ROOT) /root/.volare/volare/sky130/versions/<hash>
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
```

---

### 问题 4：PDK 下载网络超时

**现象**：`volare fetch` 下载 Sky130 PDK 时反复出现 TLS 握手超时和读取超时，尤其在下载较大库文件时。

**原因**：Volare 从 GitHub Releases 下载 PDK 文件，部分库（如 `sky130_fd_sc_hs`、`sky130_fd_sc_ms`）文件较大（数百 MB），在中国大陆网络环境下容易超时。

**修复**：
- 用 `-l sky130_fd_sc_hd` 仅下载设计所需的单个标准单元库，而非全部库
- 重试机制：网络抖动时自动重试（第二次重试成功）

```bash
volare fetch --pdk sky130 -l sky130_fd_sc_hd <version_hash>
```

**教训**：下载 PDK 时按需获取最小集合，不要盲目 `-l all`。如果网络实在不行，可以尝试：
- 使用 GitHub 代理/镜像
- 在网络稳定时段（如清晨）下载
- 提前将 PDK 缓存到本地持久化目录

---

### 问题 5：PDK_ROOT 自动覆盖

**现象**：即使在 `config.tcl` 中设置了 `PDK_ROOT`，运行时仍被 Volare 覆盖为 `tool_metadata.yml` 中指定的版本。

**原因**：OpenLane 加载配置后，Volare 会根据 `tool_metadata.yml` 重新设置 `PDK_ROOT`，覆盖用户自定义值。

**修复**：通过 Docker 的 `-e` 环境变量传入 `PDK_ROOT`，优先级高于内部覆盖：

```bash
docker run --rm \
  -v $(pwd):/work \
  -v $HOME/.volare:/root/.volare \
  -e PDK_ROOT=/root/.volare/volare/sky130/versions/<hash> \
  -w /work/openlane/pwm_ctrl \
  efabless/openlane:latest \
  flow.tcl
```

**教训**：Docker 容器的 `-e` 环境变量优先级高于容器内脚本的 `set ::env()`。当配置文件中的值被覆盖时，尝试用更上层的方式注入。

---

### 问题 6：Docker Hub 网络访问

**现象**：首次 `docker pull` 时报 TLS 握手超时。

**原因**：Docker Hub (`auth.docker.io`) 在中国大陆访问不稳定。

**修复**：Docker Desktop 已预先配置了镜像加速器（`docker.1ms.run`、`dockerproxy.com` 等），重试后成功。

---

## 运行命令速查

### 前置条件
```bash
# 进入 WSL
wsl -d Ubuntu-24.04

# 确认工具有效
iverilog -V       # 仿真编译器
docker info       # Docker 运行时
```

### 一键运行全流程
```bash
cd /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow
bash run_all.sh
```

### 分阶段运行
```bash
# 健康检查
bash scripts/health_check.sh

# Phase 2: 仿真 (仅需 iverilog，无需 Docker)
bash phase2_sim/run_sim.sh

# Phase 3: 全流程 RTL→GDS (需要 Docker)
bash phase3_synthesis/run_synthesis.sh

# Phase 4: PnR 优化版全流程 (需要 Docker)
bash phase4_pnr/run_pnr.sh

# Phase 5: 物理验证
bash phase5_verification/run_verify.sh

# Phase 6: GDS 输出检查
bash phase6_gds/run_gds.sh
```

### PDK 管理
```bash
# 下载 PDK (持久化到 WSL home)
docker run --rm \
  -v $HOME/.volare:/root/.volare \
  --entrypoint bash \
  efabless/openlane:latest \
  -c "volare fetch --pdk sky130 -l sky130_fd_sc_hd <version>"
```

### 查看 GDS 版图
```bash
klayout openlane/pwm_ctrl/runs/RUN_*/results/final/gds/pwm_ctrl.gds
```

## 关键经验

1. **跨平台项目须规范换行符**：`.gitattributes` 设置 `*.sh text eol=lf` 可避免 Windows/Linux 协作时的 CRLF 问题。

2. **开源项目文档 ≠ 可运行代码**：本项目由 AI 辅助生成，镜像名和配置格式未经实际验证。遇到问题先确认上游资源（Docker Hub、GitHub Releases）的实际情况。

3. **按需下载 PDK**：Sky130 PDK 全量下载数 GB，设计只用其中一个库。`volare fetch -l <lib>` 精确控制下载量，既省时间也降低网络中断风险。

4. **持久化 Docker 缓存**：PDK 和 Docker 镜像应挂载到宿主机目录持久化，避免每次运行重复下载。

5. **配置覆盖的优先级链**：config.tcl → Volare 自动设置 → Docker `-e` 环境变量，后者优先级最高。遇到变量被覆盖时沿此链向上排查。

6. **PWM 是最简单的全流程载体**：~18 行 Verilog，53 标准单元，整个 RTL→GDS 流程仅 1 分钟，非常适合作为 EDA 工具链学习和验证的起点。

7. **全流程环境就绪**：本次运行验证了从 RTL 到 GDS 的完整工具链在本地 Windows+WSL2+Docker 环境下可用，后续可以此为基础挑战更复杂的设计（UART TX、RISC-V 核心等）。
