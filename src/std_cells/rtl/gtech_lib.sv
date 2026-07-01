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
// File         : gtech_lib.sv
// Description  : Behavioral stubs for Synopsys GTECH cells used by gp_aes;
//                replaces the vendor GTECH library for open-source simulation.

module GTECH_NAND2 (A, B, Z);
  input  A, B;
  output Z;
  assign Z = ~(A & B);
endmodule

module GTECH_XOR2 (A, B, Z);
  input  A, B;
  output Z;
  assign Z = A ^ B;
endmodule

module GTECH_XNOR2 (A, B, Z);
  input  A, B;
  output Z;
  assign Z = ~(A ^ B);
endmodule

module GTECH_XOR3 (A, B, C, Z);
  input  A, B, C;
  output Z;
  assign Z = A ^ B ^ C;
endmodule

module GTECH_XNOR3 (A, B, C, Z);
  input  A, B, C;
  output Z;
  assign Z = ~(A ^ B ^ C);
endmodule
