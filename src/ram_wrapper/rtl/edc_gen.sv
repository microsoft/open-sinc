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
// File         : edc_gen.sv
// Description  : Takes in 32 bits of data and up to 23 bits of address, and produces 6 bits
//                of check bits based on a Hamming code. All done combinatorially.

module edc_gen (/*AUTOARG*/
   // Outputs
   code_out, check, err_uncorr, data_out,
   // Inputs
   data_in, addr, code_in, err_chk_disable
   );

    
  //-------------------------------------------
  // Parameters
  //-------------------------------------------
  parameter ADDR_WIDTH = 23;                        // up to 23 bits of address
	parameter EDC_GEN = 1;														// 1: EDC Generator block, 0: EDC Checker block
  
  localparam c_ERRDATA = 32'hDEADBEEF; // this is what is returned as rdata if there is an EDC error
  
//-------------------------------------------
  // Inputs for EDC Gen
  //-------------------------------------------
  input [31:0] data_in;
  input [ADDR_WIDTH-1:0] addr;

	// Inputs for EDC Check
	input [37:0] code_in;
  input err_chk_disable;

  //-------------------------------------------
  // Outputs
  //-------------------------------------------
  output [37:0] code_out;                                  //  code includes the check bits
  output [5:0] check;

	// Outputs for EDC Check
	output err_uncorr;
	output [31:0] data_out;

  // data size is fixed to 32,
  // total nubmer of input bits this code can consider is fixed to 56,
  // so the remainder will be used to consider the address
  wire [23:0] padded_addr;
  wire [55:0] input_vec;
  wire [5:0] check_bits;
	wire [5:0] expected_check_bits;
  wire [31:0] check_data_in;


  // to ensure the all '0' and all '1' codes at the output are impossible, pad to 24
  // bits with the negation of the MSB of address

  // e.g.: 
  // if address = 01111, take the MSB, which in this case is a '0', invert it, and
  // use that to pad out to 24 bits, ending up with 0xFFFFEF

  assign padded_addr = {{(24-ADDR_WIDTH){~addr[ADDR_WIDTH-1]}},
                        addr};

 
	generate
	if (EDC_GEN == 1) begin: edc_gen_input

  // concatenate the padded address with data
  assign input_vec = {padded_addr, data_in};
	
	end //edc_gen_input
	
	else begin: edc_check_input

  assign expected_check_bits[5:0] = {code_in[37],
                                     code_in[31],
                                     code_in[24],
																		 code_in[18],
																		 code_in[12],
																		 code_in[5]};


	assign check_data_in = {code_in[36:32],
                          code_in[30:25],
                          code_in[23:19],
                          code_in[17:13],
                          code_in[11:6],
                          code_in[4:0]};

  // concatenate the padded address with data
  assign input_vec = {padded_addr, check_data_in};

	end //edc_check_input
	endgenerate

  // calculate the 6 parity check bits

  assign check_bits[0] = ^{input_vec[0], input_vec[1], input_vec[3], input_vec[4],
                           input_vec[6], input_vec[8], input_vec[10], input_vec[11],
                           input_vec[13], input_vec[15], input_vec[17], input_vec[19],
                           input_vec[21], input_vec[23], input_vec[25], input_vec[26],
                           input_vec[28], input_vec[30], input_vec[32], input_vec[34],
                           input_vec[36], input_vec[38], input_vec[40], input_vec[42],
                           input_vec[44], input_vec[46], input_vec[48], input_vec[50],
                           input_vec[52], input_vec[54]};


  assign check_bits[1] = ^{input_vec[0], input_vec[2], input_vec[3], input_vec[5],
                           input_vec[6], input_vec[9], input_vec[10], input_vec[12],
                           input_vec[13], input_vec[16], input_vec[17], input_vec[20],
                           input_vec[21], input_vec[24], input_vec[25], input_vec[27],
                           input_vec[28], input_vec[31], input_vec[32], input_vec[35],
                           input_vec[36], input_vec[39], input_vec[40], input_vec[43],
                           input_vec[44], input_vec[47], input_vec[48], input_vec[51],
                           input_vec[52], input_vec[55]};

  assign check_bits[2] = ^{input_vec[1], input_vec[2], input_vec[3], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[29],
                           input_vec[30], input_vec[31], input_vec[32], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[53],
                           input_vec[54], input_vec[55]};

  assign check_bits[3] = ^{input_vec[4], input_vec[5], input_vec[6], input_vec[7],
                           input_vec[8], input_vec[9], input_vec[10], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[33],
                           input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55]};
  
  assign check_bits[4] = ^{input_vec[11], input_vec[12], input_vec[13], input_vec[14],
                           input_vec[15], input_vec[16], input_vec[17], input_vec[18],
                           input_vec[19], input_vec[20], input_vec[21], input_vec[22],
                           input_vec[23], input_vec[24], input_vec[25], input_vec[41],
                           input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55]};


  assign check_bits[5] = ^{input_vec[26], input_vec[27], input_vec[28], input_vec[29],
                           input_vec[30], input_vec[31], input_vec[32], input_vec[33],
                           input_vec[34], input_vec[35], input_vec[36], input_vec[37],
                           input_vec[38], input_vec[39], input_vec[40], input_vec[41],
                           input_vec[42], input_vec[43], input_vec[44], input_vec[45],
                           input_vec[46], input_vec[47], input_vec[48], input_vec[49],
                           input_vec[50], input_vec[51], input_vec[52], input_vec[53],
                           input_vec[54], input_vec[55]};


	generate
	if (EDC_GEN == 1) begin: edc_gen_out

  //interleave check bits within data to create the code word which is the output
  // check bits are code[36, 30, 24, 18, 12, 5]
  assign code_out = {check_bits[5], data_in[31:27],
                 check_bits[4], data_in[26:21],
                 check_bits[3], data_in[20:16],
                 check_bits[2], data_in[15:11],
                 check_bits[1], data_in[10:5], 
                 check_bits[0], data_in[4:0]
                 };

  assign check = check_bits;
	assign err_uncorr = 1'b0;
	assign data_out = 32'b0;
	
	end //edc_gen_out

	else begin: edc_check_out

	assign err_uncorr = err_chk_disable ? 1'b0 : (expected_check_bits != check_bits);
	assign data_out[31:0] = err_chk_disable ? check_data_in : (err_uncorr ? c_ERRDATA : check_data_in);
	assign check = 6'b0;
	assign code_out = 38'b0;

	end //edc_check_out
	endgenerate

endmodule // edc_gen
