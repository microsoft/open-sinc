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
// File          : aes_affine_mul_mi.v
// Description   : 2nd-order masked affine multiplier (and adder) for InvSbox
//               : b = M * a + C
//               : M is the inverse affine matrix of Sbox in composite field
//               : C is the inverse addition constant in binary field

`include "aes.vh"

module aes_affine_mul_mi (
    // inputs
    a,
    // outputs
    b
);
   
input [7:0]        a;
output reg [7:0]   b;

reg     [7:0]     va;
wire    [7:0]     vma;
wire    [7:0]     vb;

integer i;

localparam AFIC = 8'h67;

// transpose of input and output matrices
always @ * begin
    for (i=0; i<8; i=i+1) begin
        va[i] = a[i];
        b[i] = vb[i];
    end
end

aes_basic_affine_mul_mi aes_basic_affine_mul_mi_x (
    .a (va),
    .b (vma)
);
assign vb = vma;

endmodule


