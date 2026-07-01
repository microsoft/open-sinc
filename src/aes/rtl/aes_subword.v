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
// File          : aes_subword.v
// Description   : SubWord in composite field for key expansion

`include "aes.vh"

module aes_subword (
    // inputs
    clk_i,
    reset_nai,
    a_i,
    dir_i,
    // outputs
    b_o,
    error_o
);

input                       clk_i;
input                       reset_nai;
input [3:0][7:0]            a_i;
input                       dir_i;
output [3:0][7:0]           b_o;
output                      error_o;

wire [3:0][7:0]             va;
wire [3:0][7:0]             vb;
wire [3:0]                  error; 

genvar i, j;

// reorganize signal for Sboxes
generate
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<8; j=j+1) begin
                assign va[i][j] = a_i[i][j];
                assign b_o[i][j] = vb[i][j];
        end
    end
endgenerate


// 4 Sboxes
generate
    for (i=0; i<4; i=i+1) begin : aes_sbox_gen
        aes_sbox#(1) aes_sbox_x (
            .clk_i  (clk_i),
            .reset_nai (reset_nai),
            .sbox_i (va[i]),
            .dir_i  (dir_i),
            .en_i   (1'b1),
            .sbox_o (vb[i]),
            .error_o(error[i])
        );
    end
endgenerate

assign error_o = error[0] | error[1] | error[2] | error[3];

endmodule

