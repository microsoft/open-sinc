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
// File          : aes_basic_affine_mul_m.v
// Description   : affine multiplier (and adder) for AES Sbox
//               : b = M * a + C
//               : M is the affine matrix of Sbox in composite field
//               : C is the addition constant in binary field

module aes_basic_affine_mul_m (
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

localparam AFM0 = 8'b0110_1110;
localparam AFM1 = 8'b0110_0010;
localparam AFM2 = 8'b1010_0001;
localparam AFM3 = 8'b1101_1111;
localparam AFM4 = 8'b1111_1011;
localparam AFM5 = 8'b0011_0010;
localparam AFM6 = 8'b1010_0100;
localparam AFM7 = 8'b0101_1000; 

localparam AFC  = 8'h82;

assign M[0] = AFM0;
assign M[1] = AFM1;
assign M[2] = AFM2;
assign M[3] = AFM3;
assign M[4] = AFM4;
assign M[5] = AFM5;
assign M[6] = AFM6;
assign M[7] = AFM7;

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

assign b = ma ^ AFC;

endmodule

