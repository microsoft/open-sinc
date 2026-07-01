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
// File          : aes_gf4_mul.v
// Description   : GF4 multiplier
//               : Karatsuba multiplication reduces the required AND 
//               : gates from 4 to 3

`include "aes.vh"


module aes_gf4_mul (
    // outputs
    c,
    // inputs
    a,
    b
);

output [3:0] c;
input [3:0]  a;
input [3:0]  b;

wire [1:0]    ah;
wire [1:0]    al;
wire [1:0]    bh;
wire [1:0]    bl;
wire [1:0]    ch;
wire [1:0]    cl;
wire [1:0]    albl;
wire [1:0]    ahbh;
wire [1:0]    ah_al;
wire [1:0]    bh_bl;
wire [1:0]    ah_albh_bl;
wire [1:0]    ahbhmbeta;

// conversion between GF4 signals and GF2 signals
assign ah[1] = a[3];
assign ah[0] = a[2];
assign al[1] = a[1];
assign al[0] = a[0];
assign bh[1] = b[3];
assign bh[0] = b[2];
assign bl[1] = b[1];
assign bl[0] = b[0];
assign c[3]  = ch[1];
assign c[2]  = ch[0];
assign c[1]  = cl[1];
assign c[0]  = cl[0];


aes_gf2_mul aes_gf2_mul0 (
    .c (albl),
    .a (al),
    .b (bl)
);

// use Karatsuba to calculate
// ch = ah*bh + ah*bl + al*bh
aes_gf2_add aes_gf2_add0 (
    .c (ah_al),
    .a (ah),
    .b (al)
);

aes_gf2_add aes_gf2_add1 (
    .c (bh_bl),
    .a (bh),
    .b (bl)
);

aes_gf2_mul aes_gf2_mul1 (
    .c (ah_albh_bl),
    .a (ah_al),
    .b (bh_bl)
);

aes_gf2_add aes_gf2_add2 (
    .c (ch),
    .a (ah_albh_bl),
    .b (albl)
);

// calculate cl = al*bl + ah*bh*m_beta
aes_gf2_mul aes_gf2_mul2 (
    .c (ahbh),
    .a (ah),
    .b (bh)
);

aes_gf2_mulc aes_gf2_mulc0 (
    .c (ahbhmbeta),
    .a (ahbh)
);

aes_gf2_add aes_gf2_add3 (
    .c (cl),
    .a (albl),
    .b (ahbhmbeta)
);

endmodule

