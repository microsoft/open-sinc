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
// File          : aes_sbox.v
// Description   : Sbox in composite field
//               : parameterized
//               : for test chip: register in Sbox can be bypassed

`include "aes.vh"

module aes_sbox (
    // inputs
    clk_i,
    reset_nai,
    sbox_i,
    dir_i,
    en_i,
    // outputs
    sbox_o,
    error_o
);

parameter BYPASS = 0;

input                               clk_i;
input                               reset_nai;
input   [7:0]                       sbox_i;
input                               dir_i;
input                               en_i;
output  [7:0]                       sbox_o;
output                              error_o;

reg                                 sel0;
reg     [7:0]                       invi_mdpl_r;

wire    [7:0]                       invi;
wire    [7:0]                       invi_mdpl;
wire    [7:0]                       invi_mdpl_mux;
wire    [7:0]                       invi_r_dr;
wire    [7:0]                       invo;
wire    [7:0]                       invo_mdpl;
wire    [7:0]                       invo_muxo;
wire    [7:0]                       afm;
wire    [7:0]                       afmi;
wire    [7:0]                       invo_m;
wire    [7:0]                       invo_mt;


assign error_o = 1'b0;

generate
    always @ (posedge clk_i or negedge reset_nai) begin
        if (!reset_nai) begin
            sel0   <= 0;
        end
        else begin
            if (en_i)
                sel0   <= ~sel0; // alternates sel0
        end
    end
endgenerate


generate
    if (BYPASS == 0) begin : gen_invi_mdpl_reg
        always @ (posedge clk_i or negedge reset_nai) begin
            if (!reset_nai) begin
                invi_mdpl_r <= '0;
            end
            else if (en_i) begin
                invi_mdpl_r <= invi_mdpl;
            end
        end
    end
endgenerate


generate
    genvar gi;
    for (gi=0; gi<8; gi=gi+1) begin
        assign invi_r_dr[gi]   = invi[gi];
        assign invo[gi]     = invo_mdpl[gi];
    end
endgenerate

assign invi_mdpl    = invi_r_dr;

generate
        for (gi=0; gi<8; gi=gi+1) begin
            assign invo_muxo[gi] = invo[gi];
        end
endgenerate

genvar i;
generate

    for (i=0; i<8; i=i+1) begin
        assign invo_mt[i] = invo_muxo[i];
        assign invo_m[i] = invo_mt[i];
    end

endgenerate

// instantiate affine mul+add and two alternating GF8 inversion modules
aes_affine_mul_mi aes_affine_mul_mi0 (
    .a (sbox_i),
    .b (afmi)
);

aes_affine_mul_m aes_affine_mul_m0 (
    .a (invo_m),
    .b (afm)
);

genvar gj;
generate
        for (gj=0; gj<8; gj=gj+1) begin
            if (BYPASS == 0) begin
                assign invi_mdpl_mux[gj] = invi_mdpl_r[gj];
            end
            else begin
                assign invi_mdpl_mux[gj] = invi_mdpl[gj];
            end
        end
endgenerate

aes_gf8_inv aes_gf8_inv0 (
    .a      (invi_mdpl_mux),
    .b      (invo_mdpl)
);

assign invi   = dir_i ? sbox_i : afmi;
assign sbox_o = dir_i ? afm : invo_m;

endmodule


