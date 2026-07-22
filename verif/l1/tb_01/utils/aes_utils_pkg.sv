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
// File        : aes_utils_pkg.sv
// Description : Package containing all the utility files for the TB

`ifndef AES_UTILS_PKG
`define AES_UTILS_PKG

package aes_utils_pkg;

  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import common_utils_pkg::*;
  import pal_params_pkg::*;
  import sinc_parameters_pkg::*;

  import "DPI-C" function string getenv(input string env_name);

  import "DPI-C" context dpi_sv_aes_evp_ref_model=function void dpi_sv_aes_evp_ref_model(
    input  byte         msg_h[],
    input  int unsigned ed_h,
    input  int unsigned key_length_h,
    input  byte         key_h[],
    input  byte         iv_h[],
    input  int unsigned mode_h,
    input  int unsigned unit_sz_h,
    input  bit          a_print_debug_msg,
    output byte         ossl_rslt_h[]
    );

  `include "uvm_macros.svh"

  `include "plusargs.svh"
  `include "aes_plusargs.sv"
  `include "aes_ref_rslt_utils.sv"

endpackage : aes_utils_pkg

`endif // AES_UTILS_PKG
