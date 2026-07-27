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
// File        : sinc_monitor_pkg.sv
// Description : 

`ifndef SINC_MONITOR_PKG
`define SINC_MONITOR_PKG

package sinc_monitor_pkg;

  import uvm_pkg::*;
`include "uvm_macros.svh"
  import uvmf_base_pkg::*;

  `include "sinc_monitor_typedefs.svh"
  `include "sinc_status_monitor.svh"


  // pragma uvmf custom package_item_additional begin
  // UVMF_CHANGE_ME : When adding new environment level sequences to the src directory
  //    be sure to add the sequence file here so that it will be
  //    compiled as part of the environment package.  Be sure to place
  //    the new sequence after any base sequence of the new sequence.
  // pragma uvmf custom package_item_additional end

endpackage  : sinc_monitor_pkg
// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_MONITOR_PKG
