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
// File         : c_clock_gate.sv
// Description  : Behavioral integrated clock-gating cell wrapper with a
//                test-mode bypass for scan/DFT.

module c_clock_gate (
   // input ports
   clk,
   enable,
   test_mode,
   // output ports
   gated_clk

);

// declare inputs

input clk;
input enable;
input test_mode;

// declare outputs

output gated_clk;

// function
`ifdef MSIP_FPGA_TECH

  assign gated_clk = clk;

`else

  wire clk_gate = enable | test_mode;
  reg gate_latched;

  assign gated_clk = gate_latched & clk;

  always @(clk_gate, clk) begin
    if (~clk)
     gate_latched = clk_gate;
  end
  
`endif
endmodule



