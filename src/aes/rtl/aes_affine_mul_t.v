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
// File          : aes_affine_mul_t.v
// Description   : affine multiplier for field transition
//               : b = M * a (M is the transition matrix)

module aes_affine_mul_t (
    // inputs
    a,
    // outputs
    b
);

input  [7:0]        a;
output reg [7:0]    b;

wire [7:0][7:0]     M;
reg  [7:0][7:0]     ma_temp;

integer i, j;


localparam TM0  = 8'b0000_0011;
localparam TM1  = 8'b0011_0100;
localparam TM2  = 8'b1001_1100;
localparam TM3  = 8'b0110_1000;
localparam TM4  = 8'b0111_0000;
localparam TM5  = 8'b0000_1100;
localparam TM6  = 8'b1101_1110;
localparam TM7  = 8'b1010_0000;


// M VALUE SHOULD BE KEPT SECRET
assign M[0] = TM0;
assign M[1] = TM1;
assign M[2] = TM2;
assign M[3] = TM3;
assign M[4] = TM4;
assign M[5] = TM5;
assign M[6] = TM6;
assign M[7] = TM7;

// b = m * a
always @ * begin
    for (i=0; i<8; i=i+1) begin
        ma_temp[i][0] = a[0] & M[i][0];
        for (j=1; j<8; j=j+1) begin
            ma_temp[i][j] = ma_temp[i][j-1] ^ (a[j] & M[i][j]);
        end
        b[i] = ma_temp[i][7];
    end
end

endmodule

