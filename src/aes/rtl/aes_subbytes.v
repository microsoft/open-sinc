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
// File          : aes_subbytes.v
// Description   : SubBytes in composite field

`include "aes.vh"

module aes_subbytes (
    // inputs
    clk_i,
    reset_nai,
    a_i,
    dir_i,
    en_i,
    // outputs
    b_o,
    error_o
);

input                           clk_i;
input                           reset_nai;
input  [3:0][3:0][7:0]          a_i;
input                           dir_i;
input                           en_i;
output [3:0][3:0][7:0]          b_o;
output                          error_o;
                            
wire   [3:0][3:0][7:0]          va;
wire   [3:0][3:0][7:0]          vb;
wire   [3:0][3:0]               error;

// reorganize the linear signals for SBox operation
genvar i, j, k;
generate
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<8; k=k+1) begin
                assign va[i][j][k] = a_i[i][j][k];
                assign b_o[i][j][k] = vb[i][j][k];
            end
        end
    end
endgenerate

genvar m, n;
generate
    for (m=0; m<4; m=m+1) begin : row_sbox
        for (n=0; n<4; n=n+1) begin : column_sbox
            aes_sbox #(0) aes_sbox_x (
                .clk_i      (clk_i),
                .reset_nai  (reset_nai),
                .sbox_i     (va[m][n]),
                .dir_i      (dir_i),
                .en_i       (en_i),
                .sbox_o     (vb[m][n]),
                .error_o    (error[m][n])
            );
        end
    end
endgenerate

assign error_o = (error != '0);

endmodule

