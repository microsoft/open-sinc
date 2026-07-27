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
// File        : gpaes_sys_pkg.svh
// Description : MSFT Protocol Abstraction Layer Package

`ifndef GPAES_SYS_PKG__SVH
`define GPAES_SYS_PKG__SVH

package gpaes_sys_pkg;

`timescale 1ps/1ps

  import uvm_pkg::*;
  import uvmf_base_pkg_hdl::*;
  import uvmf_base_pkg::*;
  import gpaes_agent_config_pkg::*;
  import gpaes_seed_pkg::*;
  import gpaes_sys_params_pkg::*;

`include "uvm_macros.svh"
`include "gpaes_sys_defines.svh"
`include "gpaes_sys_virtual_sequencer.svh"
`include "gpaes_sys_config.svh"
`include "gpaes_sys_env.svh"
`include "gpaes_sys_user_config_creator.sv"

endpackage // gpaes_sys_pkg

`endif //GPAES_SYS_PKG__SVH


