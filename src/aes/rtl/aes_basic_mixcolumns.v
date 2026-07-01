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
// File          : aes_basic_mixcolumns.v
// Description   : AES MixColumns in composite field
//               : dir = 0 -> decryption; dir = 1 -> encryption

module aes_basic_mixcolumns (
    // inputs
    a_i,
    dir_i,
    // outputs
    b_o
);

input [3:0][3:0][7:0]       a_i;
input                       dir_i;
output [3:0][3:0][7:0]      b_o;

wire   [7:0]                comp_0;
wire   [7:0]                comp_1;
wire   [7:0]                comp_2;
wire   [7:0]                comp_3;
wire   [7:0]                comp_t_0;
wire   [7:0]                comp_t_1;
wire   [7:0]                comp_t_2;
wire   [7:0]                comp_t_3;
wire [3:0][3:0][7:0]        comp;
wire [3:0][3:0][3:0][7:0]   temp;
wire [7:0][7:0]             M;

// M VALUE SHOULD BE KEPT SECRET
localparam TM0  = 8'b0000_0011;
localparam TM1  = 8'b0011_0100;
localparam TM2  = 8'b1001_1100;
localparam TM3  = 8'b0110_1000;
localparam TM4  = 8'b0111_0000;
localparam TM5  = 8'b0000_1100;
localparam TM6  = 8'b1101_1110;
localparam TM7  = 8'b1010_0000;

assign M[0] = TM0;
assign M[1] = TM1;
assign M[2] = TM2;
assign M[3] = TM3;
assign M[4] = TM4;
assign M[5] = TM5;
assign M[6] = TM6;
assign M[7] = TM7;

// convert binary constants to composite constants
assign comp_0 = dir_i ? 8'h2 : 8'he;
assign comp_1 = dir_i ? 8'h3 : 8'hb;
assign comp_2 = dir_i ? 8'h1 : 8'hd;
assign comp_3 = dir_i ? 8'h1 : 8'h9;

aes_affine_mul aes_affine_mul0 (.a (comp_0), .m (M), .b (comp_t_0));
aes_affine_mul aes_affine_mul1 (.a (comp_1), .m (M), .b (comp_t_1));
aes_affine_mul aes_affine_mul2 (.a (comp_2), .m (M), .b (comp_t_2));
aes_affine_mul aes_affine_mul3 (.a (comp_3), .m (M), .b (comp_t_3));

// distribute constants for affine multiplication
assign comp[0][0] = comp_t_0;
assign comp[0][1] = comp_t_1;
assign comp[0][2] = comp_t_2;
assign comp[0][3] = comp_t_3;

assign comp[1][0] = comp_t_3;
assign comp[1][1] = comp_t_0;
assign comp[1][2] = comp_t_1;
assign comp[1][3] = comp_t_2;

assign comp[2][0] = comp_t_2;
assign comp[2][1] = comp_t_3;
assign comp[2][2] = comp_t_0;
assign comp[2][3] = comp_t_1;

assign comp[3][0] = comp_t_1;
assign comp[3][1] = comp_t_2;
assign comp[3][2] = comp_t_3;
assign comp[3][3] = comp_t_0;

// matrix multiplication
genvar i, j;
generate
    for (i=0; i<4; i=i+1) begin : aes_gf8_mul_outer_for
        for (j=0; j<4; j=j+1) begin : aes_gf8_mul_inner_for
            aes_gf8_mul aes_gf8_mul_0x(.a(comp[j][0]), .b(a_i[0][i]), .c(temp[j][i][0]));
            aes_gf8_mul aes_gf8_mul_1x(.a(comp[j][1]), .b(a_i[1][i]), .c(temp[j][i][1]));
            aes_gf8_mul aes_gf8_mul_2x(.a(comp[j][2]), .b(a_i[2][i]), .c(temp[j][i][2]));
            aes_gf8_mul aes_gf8_mul_3x(.a(comp[j][3]), .b(a_i[3][i]), .c(temp[j][i][3]));
            assign b_o[j][i] = temp[j][i][0] ^ temp[j][i][1] ^ 
                               temp[j][i][2] ^ temp[j][i][3];
        end
    end
endgenerate

endmodule

