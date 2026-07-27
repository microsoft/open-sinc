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
// File        : sinc_csd_pkg.sv
// Description : Package of SINC Cache Storage Directory.

`ifndef SINC_CSD_PKG
`define SINC_CSD_PKG

package sinc_csd_pkg;

  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import memory_pkg::*;
  import ramwrap_sys_wrapper_env_pkg::*;
  import sinc_parameters_pkg::*;
  // ccpui
  import ccpui_cpu_mem_pkg::*;

  `include "uvm_macros.svh"

  `include "sinc_csd_typedefs.svh"
  `include "sinc_csd_mem_line_comp_w_cfg.svh"
  `include "sinc_csd_cache_line_comp_w_cfg.svh"
  `include "sinc_csd_cache_set_comp_w_cfg.svh"
  `include "sinc_csd_cache_comp_w_cfg.svh"
  `include "sinc_csd.svh"

endpackage : sinc_csd_pkg

`endif // SINC_CSD_PKG
