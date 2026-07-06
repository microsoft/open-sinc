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
// File        : secded_enc.sv
// Description : SECDED (single error correct, double error detect) encoder.
//               Takes in 32 bits of data and up to 25 bits of address and
//               produces 7 check bits based on a Hamming code. All done
//               combinatorially.


module secded_enc(/*AUTOARG*/
   // Outputs
   code_out,
   // Inputs
   data_in, addr
   );

   //-------------------------------------------
   // Parameters
   //-------------------------------------------
   parameter ADDR_WIDTH = 24;                        // up to 24 bits of address


   input logic [31:0] data_in;
   input logic [ADDR_WIDTH-1:0] addr;

   output logic [38:0] code_out;

   // data size is fixed to 32,
   // total nubmer of input bits this code can consider is fixed to 57,
   // so the remainder will be used to consider the address
   logic [24:0] padded_addr;
   logic [56:0] input_vec;
   logic [6:0] check_bits;

   // to ensure the all '0' and all '1' codes at the output are impossible, pad to 25
   // bits with the negation of the MSB of address

   // e.g.: 
   // if address = 01111, take the MSB, which in this case is a '0', invert it, and
   // use that to pad out to 25 bits, ending up with 0x1FFFFDF

   assign padded_addr = {{(25-ADDR_WIDTH){~addr[ADDR_WIDTH-1]}},addr};

   assign input_vec = {padded_addr, data_in};

   assign check_bits[0] = ^{input_vec[0], input_vec[1], input_vec[3], input_vec[4],
                           input_vec[6], input_vec[8], input_vec[10], input_vec[11],
                           input_vec[13], input_vec[15], input_vec[17], input_vec[19],
                           input_vec[21], input_vec[23], input_vec[25], input_vec[26],
                           input_vec[28], input_vec[30], input_vec[32], input_vec[34],
                           input_vec[36], input_vec[38], input_vec[40], input_vec[42],
                           input_vec[44], input_vec[46], input_vec[48], input_vec[50],
                           input_vec[52], input_vec[54], input_vec[56]};

   assign check_bits[1] = ^{input_vec[0], input_vec[2], input_vec[3], input_vec[5],
                           input_vec[6], input_vec[9], input_vec[10], input_vec[12],
                           input_vec[13], input_vec[16], input_vec[17], input_vec[20],
                           input_vec[21], input_vec[24], input_vec[25], input_vec[27],
                           input_vec[28], input_vec[31], input_vec[32], input_vec[35],
                           input_vec[36], input_vec[39], input_vec[40], input_vec[43],
                           input_vec[44], input_vec[47], input_vec[48], input_vec[51],
                           input_vec[52], input_vec[55], input_vec[56]};

   assign check_bits[2] = ^{input_vec[1], input_vec[2], input_vec[3], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[29],
                           input_vec[30], input_vec[31], input_vec[32], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign check_bits[3] = ^{input_vec[4], input_vec[5], input_vec[6], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[33],
                           input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign check_bits[4] = ^{input_vec[11], input_vec[12], input_vec[13], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[41],
                           input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign check_bits[5] = ^{input_vec[26], input_vec[27], input_vec[28], input_vec[29],
                              input_vec[30], input_vec[31], input_vec[32], input_vec[33],
                              input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                              input_vec[38], input_vec[39], input_vec[40], input_vec[41],
                              input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                              input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                              input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                              input_vec[54], input_vec[55], input_vec[56]};

   assign check_bits[6] = ^{input_vec[0], input_vec[1], input_vec[2], input_vec[4],
                           input_vec[5], input_vec[7], input_vec[10], input_vec[11],
                           input_vec[12], input_vec[14], input_vec[17], input_vec[18],
                           input_vec[21], input_vec[23], input_vec[24], input_vec[26],
                           input_vec[27], input_vec[29], input_vec[32], input_vec[33],
                           input_vec[36], input_vec[38], input_vec[39], input_vec[41],
                           input_vec[44], input_vec[46], input_vec[47], input_vec[50],
                           input_vec[51], input_vec[53], input_vec[56]};

   // interleave check bits within data to create the code word which is the output
   // check bits are code[38, 32, 27, 21, 16, 10, 5]

   assign code_out = {check_bits[6], data_in[31:27],
                     check_bits[5], data_in[26:23],
                     check_bits[4], data_in[22:18],
                     check_bits[3], data_in[17:14],
                     check_bits[2], data_in[13:9],
                     check_bits[1], data_in[8:5], 
                     check_bits[0], data_in[4:0]
                     };

endmodule
