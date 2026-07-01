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
// File          : aes_core.v
// Description   : AES core, connects datapath and key expansion

`include "aes.vh"

module aes_core (
    // inputs
    clk_i,
    reset_nai,
    dir_i,              // dir = 1 -> encryption; dir = 0 -> decryption
    a_valid_i,          // input a is valid
    key_valid_i,        // input key is valid (need new key expansion)
    b_req_i,            // output message request
    a_i,                // input message a
    key_i,              // input key
    nr_i,               // number of rounds
    nk_i,               // number of key words
    clear_i,            // clear internal states
    
    // outputs
    b_o,                // message b after process
    b_valid_o,          // message b is valid
    a_req_o,            // message request
    key_req_o,          // key request
    fault_o             // fault error
);

input                                                   clk_i;
input                                                   reset_nai;
input                                                   dir_i;
input                                                   a_valid_i;
input                                                   key_valid_i;
input                                                   b_req_i;
input  [3:0][3:0][7:0]                                  a_i;
input  [7:0][3:0][7:0]                                  key_i;
input  [3:0]                                            nr_i;
input  [3:0]                                            nk_i;
input                                                   clear_i;

output [3:0][3:0][7:0]                                  b_o;
output                                                  b_valid_o;
output                                                  a_req_o;
output                                                  key_req_o;
output                                                  fault_o;

wire                                                    dp_en;
wire   [3:0]                                            round_dp;
wire   [3:0][3:0][7:0]                                  rkeyo;
wire   [3:0][3:0][7:0]                                  rkeyi;
wire                                                    error_dp;
wire                                                    error_kexp;
wire                                                    clear;
wire                                                    last_round;

assign clear = clear_i;
assign fault_o = error_dp | error_kexp;

genvar i, j, k;
generate
    for (j=0; j<4; j=j+1) begin
        for (k=0; k<4; k=k+1) begin
            assign rkeyi[j][k] = rkeyo[j][k];
        end
    end
endgenerate

aes_keyexp aes_keyexp0 (
    .clk_i          (clk_i),
    .reset_nai      (reset_nai),
    .key_i          (key_i),
    .nk_i           (nk_i),
    .nr_i           (nr_i),
    .start_i        (key_valid_i),
    .clear_i        (clear),
    .dir_i          (dir_i),
    .a_valid_i      (a_valid_i),
    .b_req_i        (b_req_i),
    .rkey_o         (rkeyo),
    .rkey_idx_o     (round_dp),
    .dp_en_o        (dp_en),
    .key_req_o      (key_req_o),
    .last_round_o   (last_round),
    .b_valid_o      (b_valid_o),
    .error_o        (error_kexp)
);

aes_datapath aes_datapath0 (
    .clk_i          (clk_i),
    .reset_nai      (reset_nai),
    .a_i            (a_i),
    .key_i          (rkeyi),
    .round_i        (round_dp),
    .dir_i          (dir_i),
    .nr_i           (nr_i),
    .dp_en_i        (dp_en),
    .last_round_i   (last_round),
    .b_o            (b_o),
    .a_req_o        (a_req_o),
    .error_o        (error_dp)
);

endmodule

