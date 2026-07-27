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
// File        : sinc_regmodel_pkg.sv
// Description : 

`ifndef SINC_REGMODEL_PKG
`define SINC_REGMODEL_PKG

package sinc_regmodel_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import csr_pkg_sinc_regs::*;
  import pal_sys_wrapper_env_pkg::*;
  import pal_params_pkg::*;
  import pal_user_params_pkg::*;
  import pal_pkg::*;

  `include "sinc_reg_typedefs.svh"
  `include "pal_uvm_reg_map.svh"
  `include "sinc_axi_reg_access_extension.svh"
  `include "sinc_reg2pal_adapter.svh"
  `include "sinc_regmodel.svh"
  `include "sinc_register_field.svh"
  `include "sinc_register.svh"
  // `include "sinc_tlb_reg.svh"
endpackage : sinc_regmodel_pkg

`endif // SINC_REGMODEL_PKG
