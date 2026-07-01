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
// File        : gp_aes.sv
// Description : General Purpose (GP) AES top-level module.

module gp_aes
(
    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic                                 clear_i,
    input logic                                 clkg_test_mode_i,
    input logic                                 clkg_override_i,

    //****************************************************************
    // Seed interface
    //****************************************************************
    input logic [31:0]                          seed_i,
    input logic                                 seed_vld_i,
    output logic                                seed_rdy_o,

    //****************************************************************
    // Configuration
    //****************************************************************
    input logic [3:0]                           mode_i,
    input logic                                 dir_i,
    input logic                                 cfg_vld_i,
    output logic                                cfg_rdy_o,

    //****************************************************************
    // Key interface
    //****************************************************************
    input logic [255:0]                         key_i,
    input logic [1:0]                           key_size_i,
    input logic                                 key_vld_i,
    input logic                                 skip_key_i,
    output logic                                key_rdy_o,

    //****************************************************************
    // IV/Input context interface
    //****************************************************************
    input logic [127:0]                         iv_i,
    input logic [383:0]                         ctx_in_i,
    input logic                                 iv_ctx_sel_i,
    input logic                                 iv_ctx_vld_i,
    output logic                                iv_ctx_rdy_o,

    //****************************************************************
    // Input data interface
    //****************************************************************
    input logic [127:0]                         din_i,
    input logic [4:0]                           din_bytecnt_i,
    input logic                                 din_last_i,
    input logic                                 din_aad_sel_i,
    input logic                                 din_vld_i,
    output logic                                din_rdy_o,

    //****************************************************************
    // Output data/Output context interface
    //****************************************************************
    output logic [127:0]                        dout_o,
    output logic [4:0]                          dout_bytecnt_o,
    output logic                                dout_last_o,
    output logic [383:0]                        ctx_out_o,
    output logic                                ctx_dout_vld_o,
    input logic                                 ctx_dout_rdy_i,

    //****************************************************************
    // Authentication tag interface
    //****************************************************************
    output logic [127:0]                        tag_o,
    output logic                                tag_vld_o,
    input logic                                 tag_rdy_i,

    //****************************************************************
    // Status interface
    //****************************************************************
    output logic                                cmd_err_o,
    output logic [1:0]                          fault_err_o,
    output logic                                busy_o

    );

    logic               a_req;
    logic               a_valid;
    logic               b_req;
    logic               b_valid;
    logic               core_fault_i;
    logic               dir;
    logic               ghash_en;
    logic               ghash_fault;
    logic [127:0]       ghash_in;
    logic               ghash_in_last;
    logic               ghash_in_rdy;
    logic               ghash_in_vld;
    logic [127:0]       ghash_out;
    logic               ghash_out_rdy;
    logic               ghash_out_vld;
    logic [127:0]       h;
    logic               key_valid;
    logic [3:0]         nk;
    logic [3:0]         nr;
    logic               unused_key_req;


    logic [3:0][3:0][7:0]       a;
    logic [3:0][3:0][7:0]       b;
    logic [7:0][3:0][7:0]       key;
    logic                       clk_ig_enable;
    logic                       gclk;
    logic                       clear_i_f;


    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
           clear_i_f <= 'b0;
        end
        else begin 
           clear_i_f <= clear_i;
        end     
    end

    gp_aes_mode u_gp_aes_mode (
        // output
        .cfg_rdy_o          (cfg_rdy_o),
        .key_rdy_o          (key_rdy_o),
        .iv_ctx_rdy_o       (iv_ctx_rdy_o),
        .din_rdy_o          (din_rdy_o),
        .dout_o             (dout_o[127:0]),
        .dout_bytecnt_o     (dout_bytecnt_o[4:0]),
        .dout_last_o        (dout_last_o),
        .ctx_out_o          (ctx_out_o[383:0]),
        .ctx_dout_vld_o     (ctx_dout_vld_o),
        .tag_o              (tag_o[127:0]),
        .tag_vld_o          (tag_vld_o),
        .cmd_err_o          (cmd_err_o),
        .fault_err_o        (fault_err_o[1:0]),
        .busy_o             (busy_o),
        .a_o                (a),
        .a_valid_o          (a_valid),
        .b_req_o            (b_req),
        .key_valid_o        (key_valid),
        .key_o              (key),
        .dir_o              (dir),
        .nr_o               (nr[3:0]),
        .nk_o               (nk[3:0]),
        .ghash_en_o         (ghash_en),
        .ghash_in           (ghash_in[127:0]),
        .ghash_in_last      (ghash_in_last),
        .ghash_in_vld       (ghash_in_vld),
        .ghash_out_rdy      (ghash_out_rdy),
        .h                  (h[127:0]),
        // input
        .clk_i              (clk_i),
        .rstn_i             (rstn_i),
        .clear_i            (clear_i_f),
        .unit_size_i        (9'h0),
        .mode_i             (mode_i[3:0]),
        .dir_i              (dir_i),
        .cfg_vld_i          (cfg_vld_i),
        .key_i              (key_i[255:0]),
        .key_size_i         (key_size_i[1:0]),
        .key_vld_i          (key_vld_i),
        .skip_key_i         (skip_key_i),
        .iv_i               (iv_i[127:0]),
        .ctx_in_i           (ctx_in_i[383:0]),
        .iv_ctx_sel_i       (iv_ctx_sel_i),
        .iv_ctx_vld_i       (iv_ctx_vld_i),
        .din_i              (din_i[127:0]),
        .din_bytecnt_i      (din_bytecnt_i[4:0]),
        .din_last_i         (din_last_i),
        .din_aad_sel_i      (din_aad_sel_i),
        .din_vld_i          (din_vld_i),
        .ctx_dout_rdy_i     (ctx_dout_rdy_i),
        .tag_rdy_i          (tag_rdy_i),
        .a_req_i            (a_req),
        .b_valid_i          (b_valid),
        .b_i                (b),
        .core_fault_i       (core_fault_i),
        .ghash_in_rdy       (ghash_in_rdy),
        .ghash_out          (ghash_out[127:0]),
        .ghash_out_vld      (ghash_out_vld),
        .ghash_fault        (ghash_fault)
    );

    gp_aes_core aes_core0 (
        // output
        .b_o                (b),
        .b_valid_o          (b_valid),
        .a_req_o            (a_req),
        .key_req_o          (unused_key_req),
        .fault_o            (core_fault_i),
        // input
        .clk_i              (gclk),
        .reset_nai          (rstn_i),
        .dir_i              (dir),
        .a_valid_i          (a_valid),
        .key_valid_i        (key_valid),
        .b_req_i            (b_req),
        .a_i                (a),
        .key_i              (key),
        .nr_i               (nr[3:0]),
        .nk_i               (nk[3:0]),
        .clear_i            (clear_i_f)
    );

    gp_aes_ghash u_gp_aes_ghash (
        // output
        .ghash_fault        (ghash_fault),
        .ghash_in_rdy       (ghash_in_rdy),
        .ghash_out          (ghash_out[127:0]),
        .ghash_out_vld      (ghash_out_vld),
        // input
        .clk_i              (gclk),
        .rstn_i             (rstn_i),
        .clear_i            (clear_i_f),
        .ghash_in           (ghash_in[127:0]),
        .ghash_in_last      (ghash_in_last),
        .ghash_in_vld       (ghash_in_vld),
        .ghash_out_rdy      (ghash_out_rdy),
        .h                  (h[127:0])
    );

    c_clock_gate_ovr u_clock_gate_ovr (
        .clk                (clk_i),
        .enable             (clk_ig_enable),
        .ovr_en             (clkg_override_i),
        .rst_en             (1'b0),
        .test_mode          (clkg_test_mode_i),
        .gated_clk          (gclk)
    );

    assign clk_ig_enable    = busy_o;

    // Seed interface tied off — no DPA/DRBG
    assign seed_rdy_o = 1'b1;

endmodule

