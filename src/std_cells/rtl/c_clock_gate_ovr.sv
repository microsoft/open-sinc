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
// File         : c_clock_gate_ovr.sv
// Description  : Clock-gating cell wrapper with a functional-gate override
//                input and test-mode bypass for scan/DFT.

module c_clock_gate_ovr (
    // input ports
    input  clk,
    input  enable,     // Functional Clock Gate
    input  ovr_en,     // Override Functional Clock Gate
    input  rst_en,     // Reset Override Clock Gate for synchronous reset
    input  test_mode,
    // output ports
    output gated_clk
);
    wire en_cond;

    // function
    assign en_cond = enable | ovr_en | rst_en;

    c_clock_gate i_clock_gate (
        .clk      (clk      ),
        .enable   (en_cond  ),
        .test_mode(test_mode),
        .gated_clk(gated_clk)
    );

endmodule : c_clock_gate_ovr
