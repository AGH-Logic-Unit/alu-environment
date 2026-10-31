# ALU Unified Development Environment (`alu-environment`)

Official repository for development container images, hardware standards, verification toolchains, and project templates for the [AGH Logic Unit](https://github.com/AGH-Logic-Unit) academic circle (computer architecture, RISC-V processors, FPGA, discrete digital logic, and PCB design).

---

## Architecture & Container Flavors

The environment follows a modular layered architecture based on Ubuntu 24.04:

```
ghcr.io/agh-logic-unit/alu-base (Core OS, Just runner, ccache, standards)
 ├── ghcr.io/agh-logic-unit/alu-rtl  (SystemVerilog IEEE 1800-2017, Verilator 5.x, Slang, Cocotb, RISC-V GCC, Spike)
 └── ghcr.io/agh-logic-unit/alu-pcb  (KiCad CLI, KiKit panelization, Interactive HTML BOM, Gerber diffs)
```

- **`alu-base`**: Minimal shared foundation with persistent caching (`ccache`), the `just` task runner, and non-root developer user (`vscode`).
- **`alu-rtl`**: Specialized for digital design and microarchitecture (`pv-crab-core`, `onb-digital`). Includes full multi-threaded SystemVerilog simulation and formal verification tools.
- **`alu-pcb`**: Dedicated to automated hardware design rule checks (`DRC`), manufacturing package exports (JLCPCB), and visual schematic diffing (`PCB_EDU`).

---

## Repository Structure

```
alu-environment/
├── docker/                  # Dockerfiles & version tracking files
│   ├── base.Dockerfile      # Base OS & utilities
│   ├── rtl.Dockerfile       # Digital & RISC-V stack
│   ├── pcb.Dockerfile       # Hardware & KiCad stack
│   ├── base.version         # Base version (e.g. 1.0.0)
│   ├── rtl.version          # RTL flavor version (e.g. 1.0.0)
│   └── pcb.version          # PCB flavor version (e.g. 1.0.0)
├── devcontainers/           # Ready-to-use DevContainer templates for projects
│   ├── rtl/devcontainer.json
│   └── pcb/devcontainer.json
├── standards/               # Single source of truth for linters & formatters
│   ├── .rules.verible_format
│   ├── .rules.verible_lint
│   ├── ruff.toml
│   └── .clang-format
├── ai/                      # Guidelines for LLM assistants (Cursor, Claude, Copilot)
│   └── AGENTS.md            # Hardware & HDL prompt guidelines
├── scripts/
│   ├── baner.sh             # Interactive terminal MOTD and version notifier
│   └── setup-host-udev.sh   # Host USB/JTAG permissions installer (Linux/WSL2)
└── justfile                 # Central task runner
```

---

## Quickstart

### Local Management Commands

```bash
# List all available recipes
just --list

# Inspect image versions
just versions

# Build local images
just build-base
just build-rtl
just build-pcb

# Sync templates to a member project
just sync-to ../pv-crab-core rtl
```

### Hardware Debugging (JTAG / USB)

To enable non-root USB access for FPGA debuggers (Digilent FTDI, ST-Link, CMSIS-DAP, Gowin) on Linux or Windows WSL2, run once on the host:

```bash
sudo bash scripts/setup-host-udev.sh
```

---

## License

SPDX-License-Identifier: [Apache-2.0](LICENSE)
