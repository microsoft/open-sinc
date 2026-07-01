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
// File          : aes_gf2_mul.v
// Description   : GF2 multiplier
//               : Karatsuba multiplication reduces the required AND 
//               : gates from 4 to 3

`include "aes.vh"


module aes_gf2_mul (
    // inputs
    a,
    b,
    // outputs
    c
);

input [1:0]    a;
input [1:0]    b;
output [1:0]   c;

wire a0b0;
wire a1b1;
wire a1_a0;
wire b1_b0;
wire a1_a0b1_b0;


aes_gf1_and aes_gf1_and0 (
    .c (a0b0),
    .a (a[0]),
    .b (b[0])
);

aes_gf1_and aes_gf1_and1 (
    .c (a1b1),
    .a (a[1]),
    .b (b[1])
);

aes_gf1_and aes_gf1_and2 (
    .c (a1_a0b1_b0),
    .a (a1_a0),
    .b (b1_b0)
);

aes_mtech_xor2 aes_mtech_xor2_x0 (.Z (a1_a0), .A (a[1]), .B (a[0]));
aes_mtech_xor2 aes_mtech_xor2_x1 (.Z (b1_b0), .A (b[1]), .B (b[0]));
aes_mtech_xor2 aes_mtech_xor2_x2 (.Z (c[1]), .A (a1_a0b1_b0), .B (a0b0));
aes_mtech_xor2 aes_mtech_xor2_x3 (.Z (c[0]), .A (a1b1), .B (a0b0));

endmodule

