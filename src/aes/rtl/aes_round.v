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
// File          : aes_round.v
// Description   : one round of AES process
//               : duplicate the addroundkey in order to avoid fake loops

`include "aes.vh"

module aes_round (
    // inputs
    clk_i,
    reset_nai,
    a_i,
    key_i,
    dir_i,
    round_i,
    nr_i,
    en_i,
    // outputs
    b_o,
    error_o
);

input            clk_i;
input            reset_nai;
input [3:0][3:0]   [7:0]  a_i;              // data input
input [3:0][3:0]   [7:0]  key_i;            // round key
input            dir_i;                     // enc (1) or dec (0)
input  [3:0]     round_i;                   // round index (0 - nr)
input  [3:0]     nr_i;                      // number of rounds
input            en_i;                      // enable calculation
output [3:0][3:0]  [7:0]     b_o;           // data output
output           error_o;                   // error indicator (fault attack)

wire [3:0][3:0]    [7:0]     subbytesi;
wire [3:0][3:0]    [7:0]     shiftrowsi;
wire [3:0][3:0]    [7:0]     addroundkeyi0;
wire [3:0][3:0]    [7:0]     addroundkeyi1;
wire [3:0][3:0]    [7:0]     mixcolumnsi;
wire [3:0][3:0]    [7:0]     subbyteso;
wire [3:0][3:0]    [7:0]     shiftrowso;
wire [3:0][3:0]    [7:0]     addroundkeyo0;
wire [3:0][3:0]    [7:0]     addroundkeyo1;
wire [3:0][3:0]    [7:0]     mixcolumnso;
wire [3:0][3:0]    [7:0]     key0;
wire [3:0][3:0]    [7:0]     key1;
wire [3:0][3:0]    [7:0]     zero;

genvar gj, gk;
generate
    for (gj=0; gj<4; gj=gj+1) begin
        for (gk=0; gk<4; gk=gk+1) begin
            assign zero[gj][gk] = 8'h00;
        end
    end
endgenerate

// instantiate 4 different components
aes_mixcolumns aes_mixcolumns0 (
    .a_i     (mixcolumnsi),
    .dir_i   (dir_i),
    .b_o     (mixcolumnso)
);

aes_subbytes aes_subbytes0 (
    .clk_i      (clk_i),
    .reset_nai  (reset_nai),
    .a_i        (subbytesi),
    .dir_i      (dir_i),
    .en_i       (en_i),
    .b_o        (subbyteso),
    .error_o    (error_o)
);

aes_shiftrows aes_shiftrows0 (
    .a_i     (shiftrowsi),
    .dir_i   (dir_i),
    .b_o     (shiftrowso)
);

aes_addroundkey aes_addroundkey0 (
    .a_i     (addroundkeyi0),
    .key_i   (key0),
    .b_o     (addroundkeyo0)
);

// a second addroundkey to avoid the fake combinational loop
aes_addroundkey aes_addroundkey1 (
    .a_i     (addroundkeyi1),
    .key_i   (key1),
    .b_o     (addroundkeyo1)
);

// connect different components according to round_i and dir_i
assign key0 = dir_i ? zero : key_i;
assign key1 = (dir_i || (round_i == 0)) ? key_i : zero;
assign subbytesi     = (!dir_i && (round_i == nr_i)) ? addroundkeyo0 : addroundkeyo1;
assign shiftrowsi    = subbyteso;
assign addroundkeyi0 = shiftrowso;
//assign mixcolumnsi   = dir_i ? shiftrowso : addroundkeyo0;
assign mixcolumnsi   = addroundkeyo0;
assign addroundkeyi1 = (round_i == 0)              ? a_i : 
                       (dir_i && (round_i == nr_i))  ? shiftrowso : mixcolumnso;
assign b_o           = subbytesi;

endmodule

