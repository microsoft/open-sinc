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
// File          : aes_gf8_mul.v
// Description   : GF8 multiplier. Used by MixColumns.

`include "aes.vh"

module aes_gf8_mul (
    // outputs
    c,
    // inputs
    a,
    b
);

input  [7:0]    a;
input  [7:0]    b;
output [7:0]    c;


wire [3:0][0:0]    [0:0]  ah;
wire [3:0][0:0]    [0:0]  al;
wire [3:0][0:0]    [0:0]  bh;
wire [3:0][0:0]    [0:0]  bl;
wire [3:0][0:0]    [0:0]  ch;
wire [3:0][0:0]    [0:0]  cl;

wire [3:0][0:0]    [0:0]  albl;
wire [3:0][0:0]    [0:0]  ahbh;
wire [3:0][0:0]    [0:0]  ah_al;
wire [3:0][0:0]    [0:0]  bh_bl;
wire [3:0][0:0]    [0:0]  ah_albh_bl;
wire [3:0][0:0]    [0:0]  ahbhmalpha;


// convertion between GF8 signals and GF4 signals
assign ah[3][0][0] = a[7];
assign ah[2][0][0] = a[6];
assign ah[1][0][0] = a[5];
assign ah[0][0][0] = a[4];
assign al[3][0][0] = a[3];
assign al[2][0][0] = a[2];
assign al[1][0][0] = a[1];
assign al[0][0][0] = a[0];

assign bh[3][0][0] = b[7];
assign bh[2][0][0] = b[6];
assign bh[1][0][0] = b[5];
assign bh[0][0][0] = b[4];
assign bl[3][0][0] = b[3];
assign bl[2][0][0] = b[2];
assign bl[1][0][0] = b[1];
assign bl[0][0][0] = b[0];

aes_gf4_mul aes_gf4_mul0 (
    .c (albl),
    .a (al),
    .b (bl)
);

// use Karatsuba to calculate
// ch = ah*bh + ah*bl + al*bh
aes_gf4_add aes_gf4_add0 (
    .c (ah_al),
    .a (ah),
    .b (al)
);

aes_gf4_add aes_gf4_add1 (
    .c (bh_bl),
    .a (bh),
    .b (bl)
);

aes_gf4_mul aes_gf4_mul1 (
    .c (ah_albh_bl),
    .a (ah_al),
    .b (bh_bl)
);

aes_gf4_add aes_gf4_add2 (
    .c (ch),
    .a (ah_albh_bl),
    .b (albl)
);

// calculate cl = al*bl + ah*bh*alpha
aes_gf4_mul aes_gf4_mul2 (
    .c (ahbh),
    .a (ah),
    .b (bh)
);

aes_gf4_mulc aes_gf4_mulc0 (
    .c (ahbhmalpha),
    .a (ahbh)
);

aes_gf4_add aes_gf4_add3 (
    .c (cl),
    .a (albl),
    .b (ahbhmalpha)
);


assign c[7] = ch[3][0][0];
assign c[6] = ch[2][0][0];
assign c[5] = ch[1][0][0];
assign c[4] = ch[0][0][0];
assign c[3] = cl[3][0][0];
assign c[2] = cl[2][0][0];
assign c[1] = cl[1][0][0];
assign c[0] = cl[0][0][0];

endmodule

