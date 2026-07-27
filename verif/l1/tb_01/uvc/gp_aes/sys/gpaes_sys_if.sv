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
// File        : gpaes_sys_if.sv
// Description : GPAES System Interface container to hold the various GPAES

`ifndef GPAES_SYS_IF__SV
`define GPAES_SYS_IF__SV


//------------------------------------------------------------------//
//  Interface to hold clock and reset signals to be accesssed by    //
//  Protocol Abstraction Layer UVM part                             //
//------------------------------------------------------------------//

`ifndef GPAES_CLKRST_IF__SV
`define GPAES_CLKRST_IF__SV
interface gpaes_clkrst_if
    (
        input logic ACLK,
        input logic ARESETn
    );

endinterface
`endif

//------------------------------------------------------------------//
// NOTES:
// Why not use the generate blocks to instantiate master / slave IF
// based on num_masters and num_slaves parameters and use the same
// gpaes_sys_if for the components?
// Why do we need separate gpaes_sys_if_<engine|seed|mem|error_inj>_only?
//
// This is due to a VCS tool limitation; apparently cross-referencing
// into the scopes within interfaces (generate blocks) is not supported.
//
// Will get below Error if not
//   0:00:04.67: Error-[NYI] Not Yet Implemented
//   0:00:04.67:   Feature is not yet supported: Xmrs into scopes within interface
//   0:00:04.67:
//------------------------------------------------------------------//

//------------------------------------------------------------------//
//  Main GPAES System Interface for sub agents            //
//------------------------------------------------------------------//

interface gpaes_sys_if
    #(
      time OUPUT_DLY = `GPAES_IF_OUTPUT_DLY
    )
    (
        input logic ACLK,
        input logic ARESETn
    );

    //CLKRST Interface
    gpaes_clkrst_if gpaes_clkrst_if_inst(ACLK, ARESETn);

    //Seed Interfaces
    gpaes_seed_if#(OUPUT_DLY) gpaes_seed_mif(ACLK, ARESETn);

endinterface

`endif //GPAES_SYS_IF__SV

