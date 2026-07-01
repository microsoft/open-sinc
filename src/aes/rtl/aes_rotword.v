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
// File          : aes_rotword.v
// Description   : 2nd-order masked RotWord in composite field

`include "aes.vh"

module aes_rotword (
    // inputs
    a_i,
    // outputs
    b_o
);

input [3:0]   [7:0]     a_i;
output [3:0]  [7:0]     b_o;


assign b_o[0] = a_i[1];
assign b_o[1] = a_i[2];
assign b_o[2] = a_i[3];
assign b_o[3] = a_i[0];

endmodule

