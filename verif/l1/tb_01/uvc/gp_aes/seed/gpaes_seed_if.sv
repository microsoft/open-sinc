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
// File        : gpaes_seed_if.sv
// Description : 

`ifndef GPAES_SEED_IF
`define GPAES_SEED_IF

interface gpaes_seed_if
  #(time OUTPUT_DLY  = `GPAES_IF_OUTPUT_DLY)
  (
    input logic ACLK,
    input logic ARESETn
    );

  logic [(`GPAES_MAX_SEED_DATA_WIDTH-1):0] seed_i; 
  logic                                    seed_vld_i;
  logic                                    seed_rdy_o;

  // for configuration default value
  shortint unsigned seed_data_width = `GPAES_MAX_SEED_DATA_WIDTH;

  // cb_passive for monitoring seed interface
  default clocking cb_passive @(posedge ACLK);
    default input #1step;
    input  ARESETn;
    input  seed_i; 
    input  seed_vld_i;
    input  seed_rdy_o;
  endclocking // cb_passive

  string IFNAME   = "MSFT_GPAES_SEED_IF_UNNAMED";

  // One modport for each testbench role (driver/monitor)
  modport mp_passive(clocking cb_passive, input ARESETn);

  //----------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------
  // N/A

endinterface : gpaes_seed_if

`endif // GPAES_SEED_IF
