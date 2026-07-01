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
# File          : sinc.constraints.tcl
# Description   : CDC tool constraints (clocks, resets, and exceptions) for SInC top-level analysis

#-----------------------------------------------------------------------------
# File      : sinc_top.cdc.tcl
# Purpose   : QuestaCDC constraints for sinc_top
#-----------------------------------------------------------------------------

set module_top "sinc_top"

#***************************************************************************************************
# Section 1: Clock Constraints
#***************************************************************************************************
# Main functional clock
netlist clock clk_i -module $module_top -domain clk_i

# Generated memory clocks (driven from clk_i, gated/buffered out to RAMs)
netlist clock sinc_ciram_clk_o -module $module_top -domain clk_i
netlist clock sinc_vtag_clk_o  -module $module_top -domain clk_i

#***************************************************************************************************
# Section 2: Reset Constraints
#***************************************************************************************************
netlist reset {rstn_i}    -module $module_top -active_low -async
netlist reset {lp_rstn_i} -module $module_top -active_low -async

#***************************************************************************************************
# Section 3: Port Constraints
#***************************************************************************************************
# Note: reset ports are declared via 'netlist reset' above and do not need
# additional 'netlist port domain' assignments.

# Test / pervasive
netlist port domain clkg_override_i        -clock clk_i
netlist port domain clkg_test_mode_i       -clock clk_i
netlist port domain sinc_chkpt_spramnx_i   -clock clk_i

# Power / UPF control signals
netlist port domain sinc_ret_en_ni         -clock clk_i
netlist port domain sinc_iso_en_i          -clock clk_i

# Control / disable signals
netlist port domain disable_encr_auth_check_i    -clock clk_i
netlist port domain sinc_err_chk_disable_i       -clock clk_i
netlist port domain sinc_err_parity_chk_disable_i -clock clk_i

# AXI Subordinate Interface
netlist port domain sinc_axi_sub_* -clock clk_i

# AXI Manager Interface
netlist port domain sinc_axi_mgr_* -clock clk_i

# CPU Interface
netlist port domain cpu_sinc_* -clock clk_i
netlist port domain sinc_cpu_* -clock clk_i

# Memory Erase Interface
netlist port domain sinc_erase_* -clock clk_i

# Error Inject and Error Log Interface
netlist port domain sinc_err_* -clock clk_i

# Cache IRAM Memory Interface (clk_o handled in Section 1)
netlist port domain sinc_ciram_addr_o  -clock clk_i
netlist port domain sinc_ciram_en_o    -clock clk_i
netlist port domain sinc_ciram_we_o    -clock clk_i
netlist port domain sinc_ciram_wdata_o -clock clk_i
netlist port domain sinc_ciram_rdata_i -clock clk_i

# VTAG Memory Interface (clk_o handled in Section 1)
netlist port domain sinc_vtag_addr_o  -clock clk_i
netlist port domain sinc_vtag_en_o    -clock clk_i
netlist port domain sinc_vtag_we_o    -clock clk_i
netlist port domain sinc_vtag_wdata_o -clock clk_i
netlist port domain sinc_vtag_rdata_i -clock clk_i

# MPU Interface
netlist port domain sinc_mpu_* -clock clk_i

# Status outputs
netlist port domain sinc_done_o   -clock clk_i
netlist port domain sinc_active_o -clock clk_i

#***************************************************************************************************
# Section 4: Local constraints (stable/static signals, blackboxes, etc.)
#***************************************************************************************************
# Pervasive / quasi-static configuration inputs
cdc signal -stable clkg_test_mode_i
cdc signal -stable clkg_override_i
cdc signal -stable sinc_chkpt_spramnx_i
cdc signal -stable disable_encr_auth_check_i
cdc signal -stable sinc_err_chk_disable_i
cdc signal -stable sinc_err_parity_chk_disable_i
cdc signal -stable sinc_mpu_disable_i

# Power-domain control (from PMU). If a UPF-aware run is used, these are
# handled via the UPF and these directives may be removed.
cdc signal -stable sinc_iso_en_i
cdc signal -stable sinc_ret_en_ni
