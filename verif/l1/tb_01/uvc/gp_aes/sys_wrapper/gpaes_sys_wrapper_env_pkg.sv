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
// File        : gpaes_sys_wrapper_env_pkg.sv
// Description : Environment HVL package

`ifndef GPAES_SYS_WRAPPER_ENV_PKG
`define GPAES_SYS_WRAPPER_ENV_PKG

package gpaes_sys_wrapper_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvmf_base_pkg::*;
  import uvmf_base_pkg_hdl::*;
  import gpaes_agent_config_pkg::*;
  import gpaes_sys_params_pkg::*;
  import gpaes_seed_pkg::*;
  import gpaes_sys_pkg::*;
  // import gpaes_user_params_pkg::*;

  `include "gpaes_sys_wrapper_virtual_sequencer.sv"
  `include "gpaes_sys_wrapper_env_typedefs.svh"
  `include "gpaes_sys_wrapper_env_configuration.svh"
  `include "gpaes_sys_wrapper_environment.svh"

endpackage : gpaes_sys_wrapper_env_pkg


`endif // GPAES_SYS_WRAPPER_ENV_PKG
