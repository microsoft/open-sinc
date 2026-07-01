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
// File         : aes_addroundkey.v
// Description  : AES round-key addition stage; XORs the round key with the
//                state to produce the next round input.

`include "aes.vh"

module aes_addroundkey (
    // inputs
    a_i,
    key_i,
    // outputs
    b_o
);

input [3:0][3:0]   [7:0]     a_i;
input [3:0][3:0]   [7:0]     key_i;
output [3:0][3:0]  [7:0]     b_o;

genvar i, j;
generate
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            assign b_o[i][j] = a_i[i][j] ^ key_i[j][i];
        end
    end
endgenerate

endmodule

