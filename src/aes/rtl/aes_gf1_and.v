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
// File          : aes_gf1_and.v
// Description   : AND gate

`include "aes.vh"

module aes_gf1_and (
    c,
    a,
    b
);

output       c;
input        a;
input        b;

wire ab;

// Partial product
aes_mtech_nand2 aes_mtech_nand2_x (.Z(ab), .A(a), .B(b));

assign c = ab ^ 1'b1;

endmodule
