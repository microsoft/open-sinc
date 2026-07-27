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
// File        : sinc_packet_pkg.sv
// Description : Package of SINC packets used by SINC sequences.

`ifndef SINC_PACKET_PKG
`define SINC_PACKET_PKG

package sinc_packet_pkg;

  //Fixme: need to add in rtl pkg istead of here
  localparam STATE_WIDTH = 4;
  typedef enum bit [STATE_WIDTH-1:0] {
    S_IDLE    = 4'h0,
    S_LOAD0   = 4'h1,
    S_LOAD1   = 4'h2,
    S_ADJUST  = 4'h3,
    S_ACTIVE  = 4'h4,
    S_LASTKEY = 4'h5,
    S_RELOAD0 = 4'h6,
    S_RELOAD1 = 4'h7,
    S_WRITE   = 4'h8,
    S_WAIT    = 4'h9
  } aes_keyexp_fsm_e;

  import uvm_pkg::*;
  import uvmf_base_pkg::*;

  import sinc_pkg::*;
  import gp_aes_pkg::*;

  import sinc_parameters_pkg::*;
  import sinc_env_pkg::*;
  import rst_pkg::*;
  import sinc_regmodel_pkg::*;

  import msft_axi_pkg::*;
  import pal_params_pkg::*;
  import pal_pkg::*;
  import pal_sys_wrapper_env_pkg::*;

  import ramwrap_engine_pkg::*;
  import ramwrap_erase_pkg::*;
  import ramwrap_sys_wrapper_env_pkg::*;

  // ccpui
  import ccpui_cpu_mem_pkg::*;
  import ccpui_mpu_pkg::*;
  import ccpui_sys_wrapper_env_pkg::*;

  // csd
  import sinc_csd_pkg::*;

  `include "uvm_macros.svh"

  `include "sinc_packet_typedefs.svh"
  `include "sinc_base_packet.svh"
  `include "sinc_mpu_packet.svh"
  `include "sinc_axi_packet.svh"
  `include "sinc_axi_err_inj_packet.svh"
  `include "sinc_cpu_packet.svh"
  `include "sinc_transaction_packet.svh"
  `include "sinc_stimulus_packet.svh"
  `include "sinc_fault_err_packet.svh"
  `include "sinc_err_stimulus_packet.svh"
  `include "sinc_cpu_err_inj_packet.svh"
  `include "sinc_mpu_err_inj_packet.svh"

endpackage : sinc_packet_pkg

`endif // SINC_PACKET_PKG
