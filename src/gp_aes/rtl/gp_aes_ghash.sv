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
// File        : gp_aes_ghash.sv
// Description : GP AES GHASH module for AES-GCM mode. Calculates GHASH output.

module gp_aes_ghash
(
    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic                                 clear_i,
    output logic                                ghash_fault,

    //****************************************************************
    // GHASH inputs and outputs
    //****************************************************************
    input logic [127:0]                         ghash_in,
    input logic                                 ghash_in_last,
    input logic                                 ghash_in_vld,
    input logic                                 ghash_out_rdy,
    input logic [127:0]                         h,

    output logic                                ghash_in_rdy,
    output logic [127:0]                        ghash_out,
    output logic                                ghash_out_vld           // level signal. Continues to hold until next input is provided
);

    logic               gfm_fault;
    logic [127:0]       x_0;
    logic [127:0]       x_1;
    logic               x_vld;
    logic [127:0]       y_0;
    logic [127:0]       y_1;
    logic               y_vld;

    gp_aes_ghash_ctrl u_ghash_ctrl (
        // output
        .ghash_in_rdy       (ghash_in_rdy),
        .ghash_out          (ghash_out[127:0]),
        .ghash_out_vld      (ghash_out_vld),
        .x_0                (x_0[127:0]),
        .x_1                (x_1[127:0]),
        .x_vld              (x_vld),
        // input
        .clk_i              (clk_i),
        .rstn_i             (rstn_i),
        .clear_i            (clear_i),
        .ghash_in           (ghash_in[127:0]),
        .ghash_in_vld       (ghash_in_vld),
        .ghash_in_last      (ghash_in_last),
        .ghash_out_rdy      (ghash_out_rdy),
        .y_0                (y_0[127:0]),
        .y_1                (y_1[127:0]),
        .y_vld              (y_vld)
    );

    gp_aes_gfm_128_128 u_gfm_128_128 (
        // output
        .y_0                (y_0[127:0]),
        .y_1                (y_1[127:0]),
        .y_vld              (y_vld),
        .gfm_fault          (gfm_fault),
        // input
        .clk_i              (clk_i),
        .rstn_i             (rstn_i),
        .clear_i            (clear_i),
        .x_0                (x_0[127:0]),
        .x_1                (x_1[127:0]),
        .x_vld              (x_vld),
        .h                  (h[127:0])
    );

    assign ghash_fault = gfm_fault;

endmodule
