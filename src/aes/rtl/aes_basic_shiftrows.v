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
// File          : aes_basic_shiftrows.v
// Description   : AES Shiftrows in composite field
//               : dir = 0 -> decryption; dir = 1 -> encryption

`include "aes.vh"

module aes_basic_shiftrows (
    // inputs
    a_i,
    dir_i,
    // outputs
    b_o
);

input [3:0][3:0][7:0]   a_i;
input                   dir_i;
output [3:0][3:0][7:0]  b_o;

wire [3:0][3:0][7:0]    b_enc;
wire [3:0][3:0][7:0]    b_dec;

genvar i, j;
generate
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            assign b_enc[i][j] = a_i[i][(j+i)%4];
            assign b_dec[i][j] = a_i[i][(j+4-i)%4];
        end
    end
endgenerate

assign b_o = dir_i ? b_enc : b_dec;

endmodule

