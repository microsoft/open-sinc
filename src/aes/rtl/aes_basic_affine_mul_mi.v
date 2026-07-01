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
// File          : aes_basic_affine_mul_mi.v
// Description   : inverse affine multiplier (and adder) for AES Sbox
//               : b = M * a + C
//               : M is the inverse affine matrix of Sbox in composite field
//               : C is the inverse addition constant in binary field

module aes_basic_affine_mul_mi (
    // inputs
    a,
    // outputs
    b
);

input  [7:0] a;
output [7:0] b;

wire [7:0]    [7:0] M;
reg    [7:0] ma;
reg [7:0]     [7:0] ma_temp;

integer i, j;

// M VALUE SHOULD BE KEPT SECRET

localparam AFMI0 = 8'b1110_0101;
localparam AFMI1 = 8'b1001_0100;
localparam AFMI2 = 8'b1010_0001;
localparam AFMI3 = 8'b1010_0010;
localparam AFMI4 = 8'b0000_1101;
localparam AFMI5 = 8'b1011_1001;
localparam AFMI6 = 8'b0010_1111;
localparam AFMI7 = 8'b0101_1000;

localparam AFIC = 8'h67;

assign M[0] = AFMI0;
assign M[1] = AFMI1;
assign M[2] = AFMI2;
assign M[3] = AFMI3;
assign M[4] = AFMI4;
assign M[5] = AFMI5;
assign M[6] = AFMI6;
assign M[7] = AFMI7;

// ma = M * a
always @ * begin
    for (i=0; i<8; i=i+1) begin
        ma_temp[i][0] = a[0] & M[i][0];
        for (j=1; j<8; j=j+1) begin
            ma_temp[i][j] = ma_temp[i][j-1] ^ (a[j] & M[i][j]);
        end
        ma[i] = ma_temp[i][7];
    end
end

assign b = ma ^ AFIC;

endmodule

