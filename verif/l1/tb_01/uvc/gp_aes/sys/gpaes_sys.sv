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
// File        : gpaes_sys.sv
// Description : GPAES System container module to hold the various

`ifndef GPAES_SYS__SV
`define GPAES_SYS__SV

`ifdef SIMULATION
import uvm_pkg::*;
`endif

import gpaes_sys_params_pkg::*;

//---------------------------------------------------------------//
//  GPAES System with Seed                                       //
//---------------------------------------------------------------//
module gpaes_sys
  #(
    parameter string           uvm_path_inst = "",
    parameter string           SYS_NAME = ""
    )
  (
   gpaes_sys_if m_gpaes_sys_if
   );

`ifdef SIMULATION
    `include "gpaes_sys_inc.sv"
`endif

endmodule

`endif //GPAES_SYS__SV
