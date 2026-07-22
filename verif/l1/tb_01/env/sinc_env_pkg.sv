// Copyright (c) Microsoft Corporation and contributors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// File        : sinc_env_pkg.sv
// Description : 

`ifndef SINC_ENV_PKG
`define SINC_ENV_PKG

package sinc_env_pkg;

  import uvm_pkg::*;
`include "uvm_macros.svh"
  import uvmf_base_pkg::*;

  import uvmf_base_pkg::*;
  import clk_env_pkg::*;
  import rst_pkg::*;

  import csr_pkg_sinc_regs::*;
  import pal_sys_wrapper_env_pkg::*;
  import pal_pkg::*;
  import memory_pkg::*;
  import ramwrap_engine_pkg::*;
  import ramwrap_erase_pkg::*;
  import ramwrap_inject_pkg::*;
  import ramwrap_sys_wrapper_env_pkg::*;
    
  // GPAES
  import gpaes_seed_pkg::*;
  import gpaes_sys_wrapper_env_pkg::*;

  // ccpui
  import ccpui_cpu_mem_pkg::*;
  import ccpui_mpu_pkg::*;
  import ccpui_sys_wrapper_env_pkg::*;

  // Packets
  // packets is now dependent on env_pkg
  // import sinc_packet_pkg::*;

  // CSD
  import sinc_csd_pkg::*;

  import sinc_pkg::*;
  import sinc_regmodel_pkg::*;
  import sinc_monitor_pkg::*;
  import pal_params_pkg::*;
  import sinc_parameters_pkg::*;

  `uvm_analysis_imp_decl(_sinc_reset_ae)
  `uvm_analysis_imp_decl(_sinc_axi_sub_ae)
  `uvm_analysis_imp_decl(_sinc_axi_mgr_ae)
  `uvm_analysis_imp_decl(_sinc_cache_mem_mem_ae)
  `uvm_analysis_imp_decl(_sinc_cache_mem_erase_ae)
  `uvm_analysis_imp_decl(_sinc_cpu_mem_ae)
  `uvm_analysis_imp_decl(_sinc_mpu_ae)
  `uvm_analysis_imp_decl(_sinc_sideband_ae)

  // pragma uvmf custom package_imports_additional begin
  // pragma uvmf custom package_imports_additional end

  // Parameters defined as HVL parameters
  `include "sinc_aes_item.svh"
  `include "sinc_aes_packet.svh"
  `include "sinc_pal_axi_xaction.sv"
  `include "sinc_env_typedefs.svh"
  `include "sinc_env_defines.svh"
//  `include "sinc_sys_mem_comp_cfg.svh"
  `include "sinc_sys_comp_cfg.svh"
  `include "sinc_sys_cfg.svh"
  `include "sinc_address_decoder.svh"

  `include "ip_base_env_configuration.svh"
  `include "ip_base_environment.svh"
  `include "sinc_virtual_sequencer.svh"
  `include "sinc_env_configuration.svh"
//  `include "sinc_storage_directory_intf.svh"
//  `include "sinc_storage_directory.svh"
  `include "sinc_sb_pkt_item.svh"
  `include "sinc_sb_cov.sv"
  `include "sinc_scoreboard.svh"
  `include "sinc_env.svh"

  // pragma uvmf custom package_item_additional begin
  // UVMF_CHANGE_ME : When adding new environment level sequences to the src directory
  //    be sure to add the sequence file here so that it will be
  //    compiled as part of the environment package.  Be sure to place
  //    the new sequence after any base sequence of the new sequence.
  // pragma uvmf custom package_item_additional end

endpackage  : sinc_env_pkg
// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_ENV_PKG
