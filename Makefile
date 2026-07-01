# Copyright (c) Microsoft Corporation and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# File          : Makefile
# Description   : Top-level Makefile for building / elaborating the open_sinc RTL.
#
# Usage:
#   make help            # list available targets
#   make lint            # lint sinc with Verilator (open-source)
#   make build           # elaborate sinc with Verilator (no main, --lint-only off)
#   make vcs             # compile sinc with Synopsys VCS (requires VCS)
#   make filelist        # print expanded file list used to build sinc
#   make clean           # remove build artifacts
#
# Environment variables (overridable on the command line, e.g. `make COMPILE_ROOT=/path`):
#   COMPILE_ROOT  -- absolute path to the root of this repository
#                    (defaults to the directory containing this Makefile)
#   BUILD_DIR     -- directory for build outputs (default: $(COMPILE_ROOT)/build)
#   TOP           -- top-level module name (default: sinc)
#   VERILATOR     -- path/name of the verilator binary (default: verilator)
#   VCS           -- path/name of the VCS binary (default: vcs)
#   SNPSLMD_LICENSE_FILE -- Synopsys FlexLM license server(s) required by VCS.
#                    VCS is a commercial tool; users must supply their own license.
#                    e.g.  export SNPSLMD_LICENSE_FILE=<port>@<licserver>
#                    or    make vcs SNPSLMD_LICENSE_FILE=<port>@<licserver>

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
# Absolute path of the directory containing this Makefile.
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
REPO_ROOT    := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))

# COMPILE_ROOT is referenced by the .vf file list and BOMs.
# *************************************************************************************
# *****************ACTION REQUIRED: FILL IN ENV VARIABLE PATHS*************************
# *************************************************************************************
export COMPILE_ROOT ?= $(REPO_ROOT)

BUILD_DIR ?= $(COMPILE_ROOT)/build
TOP       ?= sinc_top

VERILATOR ?= verilator
VCS       ?= vcs
export SNPSLMD_LICENSE_FILE ?= license path

# VCS needs VCS_HOME to locate its helper scripts (e.g. vcsMsgReport). If it is
# not already exported (module not loaded), derive it from the resolved vcs
# binary: <VCS_HOME>/bin/vcs -> <VCS_HOME>.
ifeq ($(strip $(VCS_HOME)),)
VCS_BIN := $(shell command -v $(VCS) 2>/dev/null)
ifneq ($(strip $(VCS_BIN)),)
export VCS_HOME := $(patsubst %/bin/,%,$(dir $(VCS_BIN)))
endif
endif


# Source filelist (uses ${COMPILE_ROOT} expansion at tool-invocation time).
FILELIST_SRC := $(COMPILE_ROOT)/src/sinc/config/sinc.vf
FILELIST     := $(BUILD_DIR)/sinc.expanded.vf

# Include dirs (also embedded in the .vf, but useful for additional tools).
INCDIRS := \
	+incdir+$(COMPILE_ROOT)/src/sinc/include \
	+incdir+$(COMPILE_ROOT)/src/sinc/include \
	+incdir+$(COMPILE_ROOT)/src/mpu/include \
	+incdir+$(COMPILE_ROOT)/src/aes/include

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
.PHONY: help env filelist lint build vcs clean

help:
	@echo "open_sinc build targets:"
	@echo "  make env        - print build environment"
	@echo "  make filelist   - generate expanded filelist at $(FILELIST)"
	@echo "  make lint       - run Verilator in lint-only mode on $(TOP)"
	@echo "  make build      - elaborate $(TOP) with Verilator (--lint-only off)"
	@echo "  make vcs        - compile $(TOP) with Synopsys VCS (requires SNPSLMD_LICENSE_FILE)"
	@echo "  make clean      - remove $(BUILD_DIR)"

env:
	@echo "COMPILE_ROOT = $(COMPILE_ROOT)"
	@echo "BUILD_DIR    = $(BUILD_DIR)"
	@echo "TOP          = $(TOP)"
	@echo "FILELIST_SRC = $(FILELIST_SRC)"
	@echo "VERILATOR    = $(VERILATOR)"
	@echo "VCS          = $(VCS)"
	@echo "VCS_HOME     = $(VCS_HOME)"
	@echo "SNPSLMD_LICENSE_FILE = $(SNPSLMD_LICENSE_FILE)"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Expand ${COMPILE_ROOT} in the source .vf so tools that don't perform shell
# expansion (some Verilator versions) see absolute paths.
$(FILELIST): $(FILELIST_SRC) | $(BUILD_DIR)
	@sed -e 's|$${COMPILE_ROOT}|$(COMPILE_ROOT)|g' \
	     -e 's|$$(COMPILE_ROOT)|$(COMPILE_ROOT)|g' \
	     $(FILELIST_SRC) > $(FILELIST)

filelist: $(FILELIST)
	@echo "Expanded filelist written to $(FILELIST)"

lint: $(FILELIST)
	cd $(BUILD_DIR) && $(VERILATOR) --lint-only -sv \
		$(DEFINES) $(INCDIRS) \
		-f $(FILELIST) \
		--top-module $(TOP)

build: $(FILELIST)
	cd $(BUILD_DIR) && $(VERILATOR) -sv --timing -Wno-fatal \
		$(DEFINES) $(INCDIRS) \
		-f $(FILELIST) \
		--top-module $(TOP) \
		--Mdir $(BUILD_DIR)/obj_dir

vcs: $(FILELIST)
	@if [ -z "$(SNPSLMD_LICENSE_FILE)" ]; then \
		echo "ERROR: SNPSLMD_LICENSE_FILE is not set. VCS requires a Synopsys license."; \
		echo "  Set your license server and retry:"; \
		echo "    export SNPSLMD_LICENSE_FILE=<port>@<licserver>"; \
		echo "  or pass it directly:"; \
		echo "    make vcs SNPSLMD_LICENSE_FILE=<port>@<licserver>"; \
		exit 1; \
	fi
	cd $(BUILD_DIR) && $(VCS) -full64 -sverilog -kdb -debug_access+all \
		$(DEFINES) $(INCDIRS) \
		-f $(FILELIST) \
		-top $(TOP) \
		-o $(BUILD_DIR)/simv

clean:
	rm -rf $(BUILD_DIR)
