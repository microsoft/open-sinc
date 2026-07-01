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
// File         : secded_dec.sv
// Description  : SECDED decoder. Takes in 32 bits of data plus check bits and corrects single-bit
//                errors while detecting double-bit errors based on a Hamming code.


module secded_dec(/*AUTOARG*/
   // Outputs
   data_out, err_corr, err_uncorr,
   // Inputs
   code_in, addr, err_chk_disable
   );

   //-------------------------------------------
   // Parameters
   //-------------------------------------------
   parameter ADDR_WIDTH = 25;                        // up to 23 bits of address


   input logic [38:0] code_in;
   input logic [ADDR_WIDTH-1:0] addr;
   input logic err_chk_disable;

   output logic [31:0] data_out;
   output logic err_corr;
   output logic err_uncorr;

   localparam c_ERRDATA = 32'hDEADBEEF; // this is what is returned as rdata if there is an EDC error


   // data size is fixed to 32,
   // total nubmer of input bits this code can consider is fixed to 57,
   // so the remainder will be used to consider the address
   logic [24:0] padded_addr;
   logic [56:0] input_vec;
   logic [6:0] syn_vec;
   logic [6:0] expected_check_bits;
   logic [31:0] data_in;
   logic [31:0] corrected_data;

   // to ensure the all '0' and all '1' codes at the output are impossible, pad to 25
   // bits with the negation of the MSB of address

   // e.g.:
   // if address = 01111, take the MSB, which in this case is a '0', invert it, and
   // use that to pad out to 25 bits, ending up with 0xFFFEF

   assign padded_addr = {{(25-ADDR_WIDTH){~addr[ADDR_WIDTH-1]}},addr};

   // Extracted data from code
   assign data_in = {code_in[37:33],
                     code_in[31:28],
                     code_in[26:22],
                     code_in[20:17],
                     code_in[15:11],
                     code_in[9:6],
                     code_in[4:0]};

   // expected_check_bit[6] is technically XOR of all the bits during code generation
   assign expected_check_bits = {code_in[38],
                                 code_in[32],
                                 code_in[27],
                                 code_in[21],
                                 code_in[16],
                                 code_in[10],
                                 code_in[5]};

   assign input_vec = {padded_addr, data_in};

   assign syn_vec[0] = ^{expected_check_bits[0], input_vec[0], input_vec[1], input_vec[3], input_vec[4],
                           input_vec[6], input_vec[8], input_vec[10], input_vec[11],
                           input_vec[13], input_vec[15], input_vec[17], input_vec[19],
                           input_vec[21], input_vec[23], input_vec[25], input_vec[26],
                           input_vec[28], input_vec[30], input_vec[32], input_vec[34],
                           input_vec[36], input_vec[38], input_vec[40], input_vec[42],
                           input_vec[44], input_vec[46], input_vec[48], input_vec[50],
                           input_vec[52], input_vec[54], input_vec[56]};

   assign syn_vec[1] = ^{expected_check_bits[1],input_vec[0], input_vec[2], input_vec[3], input_vec[5],
                           input_vec[6], input_vec[9], input_vec[10], input_vec[12],
                           input_vec[13], input_vec[16], input_vec[17], input_vec[20],
                           input_vec[21], input_vec[24], input_vec[25], input_vec[27],
                           input_vec[28], input_vec[31], input_vec[32], input_vec[35],
                           input_vec[36], input_vec[39], input_vec[40], input_vec[43],
                           input_vec[44], input_vec[47], input_vec[48], input_vec[51],
                           input_vec[52], input_vec[55], input_vec[56]};

   assign syn_vec[2] = ^{expected_check_bits[2], input_vec[1], input_vec[2], input_vec[3], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[29],
                           input_vec[30], input_vec[31], input_vec[32], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign syn_vec[3] = ^{expected_check_bits[3], input_vec[4], input_vec[5], input_vec[6], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[33],
                           input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign syn_vec[4] = ^{expected_check_bits[4], input_vec[11], input_vec[12], input_vec[13], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[41],
                           input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55], input_vec[56]};

   assign syn_vec[5] = ^{expected_check_bits[5], input_vec[26], input_vec[27], input_vec[28], input_vec[29],
                              input_vec[30], input_vec[31], input_vec[32], input_vec[33],
                              input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                              input_vec[38], input_vec[39], input_vec[40], input_vec[41],
                              input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                              input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                              input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                              input_vec[54], input_vec[55], input_vec[56]};

   // assign syn_vec[6] = ^{expected_check_bits[6], input_vec[0], input_vec[1], input_vec[2], input_vec[3],
   //                         input_vec[4],  input_vec[5], input_vec[6], input_vec[7], input_vec[8],
   //                         input_vec[9], input_vec[10], input_vec[11], input_vec[12], input_vec[13],
   //                         input_vec[14], input_vec[15], input_vec[16], input_vec[17], input_vec[18],
   //                         input_vec[19], input_vec[20], input_vec[21], input_vec[22], input_vec[23],
   //                         input_vec[24], input_vec[25], input_vec[26], input_vec[27], input_vec[28],
   //                         input_vec[29], input_vec[30], input_vec[31], input_vec[32], input_vec[33],
   //                         input_vec[34], input_vec[35], input_vec[36], input_vec[37], input_vec[38],
   //                         input_vec[39], input_vec[40], input_vec[41], input_vec[42], input_vec[43],
   //                         input_vec[44], input_vec[45], input_vec[46], input_vec[47], input_vec[48],
   //                         input_vec[49], input_vec[50], input_vec[51], input_vec[52], input_vec[53],
   //                         input_vec[54], input_vec[55], input_vec[56]};

   assign syn_vec[6] = ^{expected_check_bits[6], expected_check_bits[5:0], input_vec[56:0]};

   // Uncorrectable error can occur if
   // (1) One of the address bit has flipped OR
   // (2) if multiple bits has been flipped which cannot be detected by
   // total parity bit (XORing all the bits of code, also named syn_vec[6])

   assign err_uncorr = err_chk_disable ? 1'b0 : ((syn_vec[5:0] > 6'h26) || ((|syn_vec) & ~syn_vec[6]));

   // Error correction occurs if one of the bit is flipped which is caught by total parity bit
   // The value of syn_vec shows which data bit flipped

   assign err_corr = err_chk_disable ? 1'b0 : (syn_vec[6] && (~(syn_vec[5:0] > 6'h26)));

   always_comb begin
      corrected_data = data_in;
      case(syn_vec[5:0])
         6'h03: corrected_data[0] = ~data_in[0];
         6'h05: corrected_data[1] = ~data_in[1];
         6'h06: corrected_data[2] = ~data_in[2];
         6'h07: corrected_data[3] = ~data_in[3];
         6'h09: corrected_data[4] = ~data_in[4];
         6'h0A: corrected_data[5] = ~data_in[5];
         6'h0B: corrected_data[6] = ~data_in[6];
         6'h0C: corrected_data[7] = ~data_in[7];
         6'h0D: corrected_data[8] = ~data_in[8];
         6'h0E: corrected_data[9] = ~data_in[9];
         6'h0F: corrected_data[10] = ~data_in[10];
         6'h11: corrected_data[11] = ~data_in[11];
         6'h12: corrected_data[12] = ~data_in[12];
         6'h13: corrected_data[13] = ~data_in[13];
         6'h14: corrected_data[14] = ~data_in[14];
         6'h15: corrected_data[15] = ~data_in[15];
         6'h16: corrected_data[16] = ~data_in[16];
         6'h17: corrected_data[17] = ~data_in[17];
         6'h18: corrected_data[18] = ~data_in[18];
         6'h19: corrected_data[19] = ~data_in[19];
         6'h1A: corrected_data[20] = ~data_in[20];
         6'h1B: corrected_data[21] = ~data_in[21];
         6'h1C: corrected_data[22] = ~data_in[22];
         6'h1D: corrected_data[23] = ~data_in[23];
         6'h1E: corrected_data[24] = ~data_in[24];
         6'h1F: corrected_data[25] = ~data_in[25];
         6'h21: corrected_data[26] = ~data_in[26];
         6'h22: corrected_data[27] = ~data_in[27];
         6'h23: corrected_data[28] = ~data_in[28];
         6'h24: corrected_data[29] = ~data_in[29];
         6'h25: corrected_data[30] = ~data_in[30];
         6'h26: corrected_data[31] = ~data_in[31];
         default: corrected_data = data_in;
      endcase
   end

   // if err_chk_disable is set, send the input data as output (i.e. without correction)
   assign data_out = err_chk_disable ? data_in : (err_uncorr ? c_ERRDATA : corrected_data);

endmodule
