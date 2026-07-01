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
// File          : aes_gf4_inv.v
// Description   : GF4 invertor

`include "aes.vh"

module aes_gf4_inv (
    // outputs
    b,
    // inputs
    a
);

output [3:0]      b;
input  [3:0]      a;

wire [1:0]     bh;
wire [1:0]     bl;
wire [1:0]     ah;
wire [1:0]     al;
wire [1:0]     theta;
wire [1:0]     ah2;
wire [1:0]     ah2mbeta;
//wire [1:0][0:0]    [1-1:0] ahal;
//wire [1:0][0:0]    [1-1:0] ah2mbeta_ahal;
//wire [1:0][0:0]    [1-1:0] al2;
wire [1:0]     ah_al;
wire [1:0]     alah_al;
wire [1:0]     inv_theta;

// conversion between GF4 signals and GF2 signals
        assign ah[1] = a[3];
        assign ah[0] = a[2];
        assign al[1] = a[1];
        assign al[0] = a[0];
        assign b[3]  = bh[1];
        assign b[2]  = bh[0];
        assign b[1]  = bl[1];
        assign b[0]  = bl[0];


// calculate theta


// calculate theta
aes_gf2_squ aes_gf2_squ0 (
    .b (ah2),
    .a (ah)
);

aes_gf2_mulc aes_gf2_mulc0 (
    .c (ah2mbeta),
    .a (ah2)
);

aes_gf2_add aes_gf2_add0 (
    .c (ah_al),
    .a (ah),
    .b (al)
);

aes_gf2_mul aes_gf2_mul0 (
    .c (alah_al),
    .a (al),
    .b (ah_al)
);

aes_gf2_add aes_gf2_add1 (
    .c (theta),
    .a (ah2mbeta),
    .b (alah_al)
);

// calculate inv(theta)
aes_gf2_inv aes_gf2_inv0 (
    .b (inv_theta),
    .a (theta)
);

// calculate bh
aes_gf2_mul aes_gf2_mul1 (
    .c (bh),
    .a (inv_theta),
    .b (ah)
);

// calculate bl
aes_gf2_mul aes_gf2_mul2 (
    .c (bl),
    .a (inv_theta),
    .b (ah_al)
);

endmodule

