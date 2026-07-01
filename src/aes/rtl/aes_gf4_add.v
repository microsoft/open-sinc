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
// File          : aes_gf4_add.v
// Description   : 2nd-order masked DRP GF4 adder

`include "aes.vh"

module aes_gf4_add (
    // outputs
    c,
    // inputs
    a,
    b
);

output [3:0]   c;
input [3:0]    b;
input [3:0]    a;

genvar j;
generate
    for (j=0; j<4; j=j+1) begin : aes_mtech_xor2_inner_for
        aes_mtech_xor2 aes_mtech_xor2_x (
            .Z (c[j]),
            .A (a[j]),
            .B (b[j])
        );
    end
endgenerate

endmodule

