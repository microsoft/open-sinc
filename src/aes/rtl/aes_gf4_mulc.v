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
// File          : aes_gf4_mulc.v
// Description   : GF4 multiplier with constant alpha

`include "aes.vh"

module aes_gf4_mulc (
    // outputs
    c,
    // inputs
    a
);

output [3:0]   c;
input [3:0]    a;

wire  a0a1;
wire  a2a3;

aes_mtech_xor2 aes_mtech_xor2_x0 (.Z (a0a1), .A (a[0]), .B (a[1]));
aes_mtech_xor2 aes_mtech_xor2_x1 (.Z (a2a3), .A (a[2]), .B (a[3]));
aes_mtech_xor2 aes_mtech_xor2_x2 (.Z (c[3]), .A (a0a1), .B (a2a3));
aes_mtech_xor2 aes_mtech_xor2_x3 (.Z (c[2]), .A (a[1]), .B (a[3]));
assign c[1] = a[2];
assign c[0] = a2a3;

endmodule

