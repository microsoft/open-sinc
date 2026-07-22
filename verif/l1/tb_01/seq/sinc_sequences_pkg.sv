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
// File        : sinc_sequences_pkg.sv
// Description : This package includes all high level sequence classes used

`ifndef SINC_SEQUENCES_PKG
`define SINC_SEQUENCES_PKG

package sinc_sequences_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;

  import sinc_pkg::*;
  import gp_aes_pkg::*;

  import sinc_parameters_pkg::*;
  import sinc_env_pkg::*;
  import rst_pkg::*;
  import sinc_regmodel_pkg::*;
  import sinc_packet_pkg::*;
  // import sinc_packet_pkg::*;

  import msft_axi_pkg::*;
  import pal_params_pkg::*;
  import pal_pkg::*;
  import pal_sys_wrapper_env_pkg::*;

  import ramwrap_engine_pkg::*;
  import ramwrap_erase_pkg::*;
  import ramwrap_inject_pkg::*;
  import ramwrap_sys_wrapper_env_pkg::*;

  // ccpui
  import ccpui_cpu_mem_pkg::*;
  import ccpui_mpu_pkg::*;
  import ccpui_sys_wrapper_env_pkg::*;

  import sinc_csd_pkg::*;

  `include "uvm_macros.svh"

  // pragma uvmf custom package_imports_additional begin
  // pragma uvmf custom package_imports_additional end

  `include "hsp_axi_base_seq.svh"
  `include "hsp_virt_base_seq.svh"
  `include "sinc_axi_base_sequence.svh"
  `include "axi_slv_ext_seq.svh"
  `include "sinc_axi_rand_seq.svh"
  `include "sinc_erase_base_sequence.svh"
  `include "sinc_erase_rand_seq.svh"
  `include "sinc_cpu_mem_base_sequence.svh"
  `include "sinc_cpu_rand_sequence.svh"
  `include "sinc_mpu_base_sequence.svh"
  `include "sinc_mpu_rand_sequence.svh"
  `include "sinc_ramwrap_inj_base_sequence.svh"
  `include "sinc_ramwrap_inj_rand_seq.svh"
  `include "sinc_bench_sequence_base.svh"
  `include "sinc_virtual_base_sequence.svh"
  `include "sinc_sanity_seq.svh"
  `include "sinc_ramwrap_err_inj_test_seq.svh"
  `include "sinc_random_base_seq.svh"
  `include "sinc_random_err_inj_seq.svh"
  `include "sinc_ecc_error_inj_test_seq.svh"
  `include "sinc_vtag_parity_error_inj_seq.svh"
  `include "sinc_random_fault_err_inj_seq.svh"
  `include "sinc_invalid_aes_test_directed_seq.svh"
  `include "sinc_resp_error_aes_test_directed_seq.svh"
  `include "sinc_cpu_b2b_cache_fail_direct_test_seq.svh"
  `include "sinc_cpu_req_on_last_erase_mem_direct_test_seq.svh"
  `include "sinc_lp_rst_rng_fetch_fail_direct_test_seq.svh"
  `include "sinc_concurrent_fw_op_and_fetch_block_direct_test_seq.svh"
  

endpackage : sinc_sequences_pkg

// pragma uvmf custom external begin
// pragma uvmf custom external end
`endif // SINC_SEQUENCES_PKG
