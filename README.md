 Copyright (c) Microsoft Corporation and contributors. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


# **SINC Hands-On Guide** #

Trademarks This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft’s Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.

## **Introduction** ##

SInC (**S**ecure **In**struction **C**ache) is a hardware instruction cache that lets a security subsystem execute firmware images that are too large to fit in its on-chip instruction SRAM. A small local IRAM holds boot/critical code, and SInC transparently caches the rest of the instruction space — up to 16 MB — from external memory. Cache blocks stored externally are encrypted and authenticated so that integrity and confidentiality of the firmware image are preserved even when it lives off-die.

SInC is composed of two cooperating hardware blocks:

- **Cache Interface Unit (CIU)** — sits on the processor side of the cache. Owns the cache SRAM, tag/state, the 4-way set-associative lookup, and the FIFO replacement policy. Also enforces memory-protection attributes (via the integrated [MPU](src/mpu/)) on every fetch.
- **Cache Management Unit (CMU)** — services block misses by issuing AXI reads to external memory, decrypting and authenticating each block (AES-GCM / AES-XTS via the integrated [AES](src/aes/) core), and delivering the plaintext block to the CIU. The CMU also handles firmware-driven initialization commands (key install, image encrypt-on-load, address-translation programming, cache lockdown, performance counters, debug, etc.).

The block diagram, command set, register interface, and full programmer's model are documented in [docs/SInC_0100_AS.md](docs/SInC_0100_AS.md) (architecture) and [docs/sinc_0101_MAS.md](docs/sinc_0101_MAS.md) (micro-architecture). The verification plan lives in [docs/SInC_0100_UVM.md](docs/SInC_0100_UVM.md).

This repository contains the open-source RTL for SInC plus its sub-components (AES, MPU, AXI manager/subordinate, RAM wrapper with ECC, replaceable std-cell templates) and a set of C-based directed tests under [verif/c_tests/](verif/c_tests/). A UVM testbench will be added in a follow-up drop.

## **Tools Used** ##

OS:
 - Build instructions assume a Linux environment

Lint:
 - Synopsys Spyglass
   - `Version X-2025.06-SP1-1`
 - Real Intent AscentLint
   - `Version 2019.A.p15 for RHEL 6.0-64, Rev 116515, Built On 12/18/2020`

Simulation:
 - Synopsys VCS with Verdi
   - `Version R-2020.12-SP2-7_Full64`
 - Verilator
   - `Version 5.044`
 - Mentor Graphics QVIP
   - `Version 2021.2.1` of AHB models
 - Avery AXI VIP
   - `Version 2025.1` of axixactor
 - ARM AXI Protocol Checker
   - `BP063-BU-01000-r0p1-00rel0` Axi4PC.sv must be acquired from the ARM website
 - UVM installation
   - `Version 1.1d`
 - Mentor Graphics UVM-Frameworks
   - `2022.3`

Synthesis:
 - Synopsys Fusion Compiler
   - `Version 2022.12-SP3`

GCC:
 - RISCV Toolchain for generating memory initialization files
   - `Version 2023.04.29`
   - `riscv64-unknown-elf-gcc (g) 12.2.0`
 - G++ Used to compile Verilator objects and test firmware
   - `g++ (GCC) 11.2.0`

CDC:
 - Questa CDC
   - `2023.4_3 5762808 linux_x86_64 29-Feb-2024`
  
RDC:
 - Real Intent Meridian
   - `2022.A.P18.3`

RDL Compiler:
 - systemrdl-compiler==1.27.3
 - peakrdl-systemrdl==0.3.0
 - peakrdl-regblock==0.21.0
 - peakrdl-uvm==2.3.0
 - peakrdl-ipxact==3.4.3
 - peakrdl-html==2.10.1
 - peakrdl-cheader==1.0.0
 - peakrdl==1.1.0

Other:
 - Playbook (Microsoft Internal workflow management tool)


## **Repository Overview** ##
```
open_sinc
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── README.md
├── SECURITY.md
├── SUPPORT.md
├── config
│   └── all_boms.yml
├── docs
│   ├── sinc_0101_CTESTS.md  # L3 C test plan
│   ├── sinc_0101_AS.md      # Architecture Specification
│   ├── sinc_0101_UVM.md     # Verification Plan
│   ├── sinc_0101_MAS.md     # Micro-Architecture Specification
│   └── media/
├── src
│   ├── aes                  # AES core (incl. GF math, key expansion, modes)
│   ├── axi_mgr              # AXI manager (master) interface
│   ├── axi_sub              # AXI subordinate (slave) interface
│   ├── gp_aes               # General-purpose AES wrapper
│   ├── mpu                  # Memory Protection Unit
│   ├── ram_wrapper          # RAM wrapper (EDC/ECC, erase, RMW)
│   ├── sinc                 # SInC top-level + CMU / CIU / register block
│   │   ├── config
│   │   │   ├── bom.yml
│   │   │   ├── sinc_top.vf  # Top-level Verilog filelist for sinc_top
│   │   │   ├── cdc/         # Questa CDC setup (waivers, constraints)
│   │   │   ├── lint/        # Spyglass / AscentLint setup
│   │   │   ├── rdc/         # Meridian RDC setup
│   │   │   └── synthesis/   # Fusion Compiler synthesis setup
│   │   ├── include/         # Shared `*.vh` / `*.svh` headers
│   │   ├── registers/       # SystemRDL register definitions
│   │   ├── upf/             # sinc upf file
│   │   └── rtl/             # SystemVerilog sources (sinc_top, CMU, CIU, ...)
│   └── std_cells            # Replaceable std-cell templates (e.g. clock gate)
└── verif
    └── c_tests              # C-based firmware tests run by the embedded core
```
Each sub-component under `src/<block>/` follows the same internal layout:
```
src/<block>/
├── config/                  # *.vf filelists and BOM metadata
├── include/                 # *.vh / *.svh headers (if any)
└── rtl/                     # SystemVerilog / Verilog sources
```
The top-level fileset for `sinc_top` lives at [src/sinc/config/sinc.vf](src/sinc/config/sinc.vf) and pulls in every block listed above.


## **Environment Variables** ##

Required for build / lint / simulation:<BR>
`COMPILE_ROOT`: Absolute path to the root of this repository. The top-level Verilog filelist [src/sinc/config/sinc.vf](src/sinc/config/sinc.vf) and every per-block `*.vf` reference `${COMPILE_ROOT}` to locate sources. The `Makefile` defaults this to the directory that contains it, so it is only needed when invoking tools outside of `make`.<BR>
`BUILD_DIR`: Absolute path where build artifacts (expanded filelist, Verilator `obj_dir/`, VCS `simv`, logs) are placed. Defaults to `${COMPILE_ROOT}/build`.<BR>
`TOP`: Top-level module name used by `lint`, `build`, and `vcs` targets. Defaults to `sinc_top`.<BR>
`VERILATOR`: Path or name of the Verilator binary. Defaults to `verilator` (must be on `PATH`).<BR>
`VCS`: Path or name of the Synopsys VCS binary. Defaults to `vcs` (must be on `PATH`).<BR>
`VCS_HOME`: Root installation directory of VCS (e.g. `/path/to/vcs/W-2024.09-SP2-8`). VCS uses this to locate its helper scripts. The `Makefile` auto-derives it from the resolved `VCS` binary, so it only needs to be set explicitly if `VCS` is a wrapper script that does not live under `<VCS_HOME>/bin/`.<BR>
`SNPSLMD_LICENSE_FILE`: Synopsys FlexLM license server(s) required to run VCS. VCS is a commercial tool — users must obtain a license from Synopsys and point this variable at their license server before running `make vcs`:<BR>
```sh
SNPSLMD_LICENSE_FILE=<port>@<licserver>
```
Required only for UVM simulation (added later, alongside the UVM testbenches):<BR>
`UVM_HOME`, `UVMF_HOME`, `QUESTA_MVC_HOME`, `AVERY_SIM`, `AVERY_PLI`, `AVERY_AXI` — filesystem paths to the UVM library, Mentor UVM-Frameworks, QVIP, and Avery AXI VIP installations respectively. See the **Run Simulation** section (TBD) for details.

Required only for firmware (`verif/c_tests`) builds:<BR>
`TESTNAME`: Name of one of the directories under [verif/c_tests/](verif/c_tests/) (e.g. `sinc_aes_test_mode`, `sinc_reinit`). Selects which test source is compiled into the SRAM init hex files.<BR>


## **Build Steps** ##

A top-level `Makefile` drives the open-source elaboration and the VCS compile flow. All targets honor the environment variables described above; any of them can also be overridden inline (e.g. `make lint VERILATOR=/path/to/verilator`).

Common targets:

| Target          | Description                                                                       |
| --------------- | --------------------------------------------------------------------------------- |
| `make help`     | Lists the available targets.                                                      |
| `make env`      | Prints the resolved build environment (`COMPILE_ROOT`, `BUILD_DIR`, `TOP`, etc.). |
| `make filelist` | Expands `${COMPILE_ROOT}` in `sinc_top.vf` and writes `$(BUILD_DIR)/sinc_top.expanded.vf`. |
| `make lint`     | Runs Verilator in `--lint-only` mode over `$(TOP)`.                               |
| `make build`    | Elaborates `$(TOP)` with Verilator (`--cc --timing`) into `$(BUILD_DIR)/obj_dir/`. |
| `make vcs`      | Compiles `$(TOP)` with Synopsys VCS, producing `$(BUILD_DIR)/simv`.               |
| `make clean`    | Removes `$(BUILD_DIR)`.                                                           |

### Typical Verilator flow ###

1. Make sure the open-source tools are on your `PATH` (Verilator ≥ 5.0 and a recent GCC/G++).
2. From the repository root, generate the expanded filelist and run lint:
   ```sh
   make filelist
   make lint
   ```
3. Elaborate the design:
   ```sh
   make build
   ```
   Outputs are written under [build/](build/) — specifically `build/sinc_top.expanded.vf` and `build/obj_dir/`. A runnable simulator is *not* produced at this stage; that requires a SystemVerilog or C++ testbench (added in the **Run Simulation** section, TBD).

### Typical VCS flow ###

VCS is a commercial Synopsys tool. You must have a valid license before proceeding.

1. Set your Synopsys license server:
   ```sh
   export SNPSLMD_LICENSE_FILE=<port>@<licserver>
   ```
2. Make sure VCS is on your `PATH` (or pass `VCS=/abs/path/to/vcs` on the make command line). `VCS_HOME` is derived automatically from the binary location.
3. From the repository root:
   ```sh
   make vcs
   ```
   This produces `build/simv`. The current target only compiles `sinc_top` — wiring up a testbench top and running `simv` will be described in **Run Simulation**.

### Per-block compilation ###

Each sub-component under `src/<block>` has its own `config/*.vf` filelist that enumerates only that block's sources (and dependencies). New RTL files must be added to the appropriate `*.vf` so the top-level build picks them up. The top-level `sinc_top.vf` aggregates these into the full `sinc_top` build target.


## **Run Simulation** ##

TBD — this section will be filled in once the UVM testbenches under [verif/](verif/) are wired up. It will document the SInC top-level UVM bench, the per-block UVM unit benches, the supporting C tests under [verif/c_tests/](verif/c_tests/), and the regression scripts that drive them.


## **Verilog File Lists** ##

Verilog file lists live under each block's `config/` directory (e.g. [src/sinc/config/sinc.vf](src/sinc/config/sinc.vf)) and use absolute paths prefixed by `${COMPILE_ROOT}`. They define the compilation sources (including all dependencies) required to build and simulate a given module or testbench and should be reused by integrators for simulation, lint, and synthesis.

When new RTL files are added to a block, append them to the block's `*.vf`. The `make filelist` target expands the `${COMPILE_ROOT}` variable into absolute paths so tools that don't perform shell expansion (some Verilator versions) can consume the list directly.


## **Replacement Cells** ##

sinc uses std cell templates that can be replaced with vendor specific cells.

src/std_cells/c_clock_gate contains a template for a generic clock gate. 

src/std_cells/c_clock_gate_ovr contains a template for a generic clock gate.

src/std_cells/gtech_lib.sv contains generic cells (nand, xor, xnor) used by gpaes module

## **NOTES** ##

* Register documentation is auto-generated from the SystemRDL sources under [src/sinc/registers/](src/sinc/registers/).
* The architectural and micro-architectural specifications live in [docs/](docs/) — see [docs/SInC_0100_AS.md](docs/SInC_0100_AS.md) (architecture), [docs/sinc_0101_MAS.md](docs/sinc_0101_MAS.md) (micro-architecture), and [docs/SInC_0100_UVM.md](docs/SInC_0100_UVM.md) (verification plan).
* UVM verif infrastructure will be provided in update soon.
* **Disclaimer:** The C tests under [verif/c_tests/](verif/c_tests/) carry no functional guarantee. They were originally developed in tight integration with internal Microsoft modules and dependencies that are not included in this release. They are provided for reference purposes only — intended to illustrate simulation structure and test intent rather than for direct functional use.
* **Disclaimer:** The synthesis, CDC, and RDC setup files (under each block's `config/synthesis/`, `config/cdc/`, and `config/rdc/` directories) have not been tested in this release because a technology node was not available to us at the time. They are provided for reference only and will be validated in the next release.



