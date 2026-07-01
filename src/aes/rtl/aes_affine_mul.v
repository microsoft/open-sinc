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
// File          : aes_affine_mul.v
// Description   : affine multiplier
//               : b = M * a (M is the multiplication matrix)

`include "aes.vh"

module aes_affine_mul (
    // inputs
    a,
    m,
    // outputs
    b
);

input      [7:0]  a;
input [7:0]       [7:0]  m;
output     [7:0]  b;

wire [7:0]        [7:0]  b_temp;

// b = m * a
genvar i, j;
generate
    for (i=0; i<8; i=i+1) begin
        assign b_temp[i][0] = m[i][0] & a[0];
        for (j=1; j<8; j=j+1) begin
            assign b_temp[i][j] = b_temp[i][j-1] ^ (m[i][j] & a[j]);
        end
        assign b[i] = b_temp[i][7];
    end
endgenerate

endmodule

