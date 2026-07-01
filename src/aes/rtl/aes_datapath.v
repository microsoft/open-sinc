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
// File          : aes_datapath.v
// Description   : Datapath of AES in composite field

`include "aes.vh"

module aes_datapath (
    // inputs
    clk_i,
    reset_nai,
    a_i,
    key_i,
    round_i,
    dir_i,
    nr_i,
    dp_en_i,
    last_round_i,
    // outputs
    b_o,
    a_req_o,
    error_o
);

input                        clk_i;
input                        reset_nai;
input  [3:0][3:0][7:0]       a_i;           // data input
input  [3:0][3:0][7:0]       key_i;         // round key
input  [3:0]                 round_i;       // round index
input                        last_round_i;  // last round indicator
input                        dir_i;         // enc (1) or dec (0)
input  [3:0]                 nr_i;          // number of rounds
input                        dp_en_i;       // enable datapath
output [3:0][3:0][7:0]       b_o;           // data output
output                       a_req_o;       // require new input data
output                       error_o;       // error indicator (fault attack)

wire [3:0][3:0]    [7:0]     roundi;
wire [3:0][3:0]    [7:0]     roundo;
wire [3:0][3:0]    [7:0]     ti;
wire [3:0][3:0]    [7:0]     to;
wire [3:0][3:0]    [7:0]     invti;
wire [3:0][3:0]    [7:0]     invto;
wire [3:0][3:0]    [7:0]     state;
reg  [3:0][3:0]    [7:0]     b_r;


// first convert data from binary to composite
// get a transpose of the input compatible with the round process
genvar i, j;
generate
    for (i=0; i<4; i=i+1) begin : aes_affine_mul_t_outer_for
        for (j=0; j<4; j=j+1) begin : aes_affine_mul_t_inner_for
            aes_affine_mul_t aes_affine_mul_tx (.a(ti[j][i]), .b(to[i][j]));
        end
    end
endgenerate

aes_round aes_round0 (
    .clk_i      (clk_i),
    .reset_nai  (reset_nai),
    .a_i        (roundi),
    .key_i      (key_i),
    .dir_i      (dir_i),
    .round_i    (round_i),
    .nr_i       (nr_i),
    .en_i       (dp_en_i),
    .b_o        (roundo),
    .error_o    (error_o)
);


// b_r register to store the result
// and to block unwanted data from output logic
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        b_r <= '0;
    end
    else if (last_round_i) begin
        b_r <= roundo;
    end
end

// convert back when final data generated
generate
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            //assign state[i][j] = b_r[0][i][j];
            assign state[i][j] = b_r[i][j];
        end
    end
endgenerate

// convert back to binary field
// transpose again, compatible with the outside data format
generate
    for (i=0; i<4; i=i+1) begin : aes_affine_mul_ti_outer_for
        for (j=0; j<4; j=j+1) begin : aes_affine_mul_ti_inner_for
            aes_affine_mul_ti aes_affine_mul_tix (.a(invti[j][i]), .b(invto[i][j]));
        end
    end
endgenerate


// connect different modules together
assign ti = a_i;
assign roundi = to;
// guarantee intermediate data integrity
assign invti = state;
// output result at the least round and keep it afterwards
assign b_o = invto;

// a_req_o cannot be given too quickly due to the full prediction hazard
// see *keyexp.v for more details
assign a_req_o = (round_i == 4'b11);
endmodule

