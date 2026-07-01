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
// File          : aes_affine_mul_ti.v
// Description   : affine multiplier for field inverse transition
//               : b = M * a (M is the inverse transition matrix)

module aes_affine_mul_ti (
    // inputs
    a,
    // outputs
    b
);

input       [7:0]   a;
output reg  [7:0]   b;

wire [7:0][7:0]     M;
reg  [7:0][7:0]     ma_temp;

integer i, j;

// M VALUE SHOULD BE KEPT SECRET     

localparam TMI0 = 8'b1111_0001;
localparam TMI1 = 8'b1111_0000;
localparam TMI2 = 8'b1010_0110;
localparam TMI3 = 8'b1000_0110;
localparam TMI4 = 8'b1001_1110;
localparam TMI5 = 8'b0011_1010;
localparam TMI6 = 8'b1011_0100;
localparam TMI7 = 8'b1011_1010;


assign M[0] = TMI0;
assign M[1] = TMI1;
assign M[2] = TMI2;
assign M[3] = TMI3;
assign M[4] = TMI4;
assign M[5] = TMI5;
assign M[6] = TMI6;
assign M[7] = TMI7;

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

