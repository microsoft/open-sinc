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
// File          : aes_gf8_inv  
// Description   : GF8 invertor

`include "aes.vh"

module aes_gf8_inv (
    // outputs
    b,
    // inputs
    a
);

output  [7:0]                  b;
input   [7:0]                  a;

wire    [3:0]                  bh;
wire    [3:0]                  bl;
wire    [3:0]                  ah;
wire    [3:0]                  al;
wire    [3:0]                  theta;
wire    [3:0]                  ah2;
wire    [3:0]                  ah2malpha;
wire    [3:0]                  ah_al;
wire    [3:0]                  alah_al;
wire    [3:0]                  inv_theta;

// conversion between GF8 signals and GF4 signals
assign ah[3] = a[7];
assign ah[2] = a[6];
assign ah[1] = a[5];
assign ah[0] = a[4];
assign al[3] = a[3];
assign al[2] = a[2];
assign al[1] = a[1];
assign al[0] = a[0];
assign b[7]  = bh[3];
assign b[6]  = bh[2];
assign b[5]  = bh[1];
assign b[4]  = bh[0];
assign b[3]  = bl[3];
assign b[2]  = bl[2];
assign b[1]  = bl[1];
assign b[0]  = bl[0];


// calculate theta
aes_gf4_squ aes_gf4_squ0 (
    .b (ah2),
    .a (ah)
);

aes_gf4_mulc aes_gf4_mulc0 (
    .c (ah2malpha),
    .a (ah2)
);

aes_gf4_add aes_gf4_add0 (
    .c (ah_al),
    .a (ah),
    .b (al)
);

aes_gf4_mul aes_gf4_mul0 (
    .c (alah_al),
    .a (al),
    .b (ah_al)
);

aes_gf4_add aes_gf4_add1 (
    .c (theta),
    .a (ah2malpha),
    .b (alah_al)
);

// calculate inv(theta)
aes_gf4_inv aes_gf4_inv0 (
    .b (inv_theta),
    .a (theta)
);

// calculate bh
aes_gf4_mul aes_gf4_mul1 (
    .c (bh),
    .a (inv_theta),
    .b (ah)
);

// calculate bl
aes_gf4_mul aes_gf4_mul2 (
    .c (bl),
    .a (inv_theta),
    .b (ah_al)
);

endmodule

