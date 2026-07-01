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
// File        : gp_aes_ghash_ctrl.sv
// Description : AES GHASH control. Sequences inputs and outputs through
//               gfm_128_128 to form the GHASH circuit for AES-GCM mode.

module gp_aes_ghash_ctrl
(
    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic                                 clear_i,

    //****************************************************************
    // GHASH inputs and outputs
    //****************************************************************
    input logic [127:0]                         ghash_in,
    input logic                                 ghash_in_vld,
    input logic                                 ghash_in_last,
    output logic                                ghash_in_rdy,

    input logic                                 ghash_out_rdy,
    output logic [127:0]                        ghash_out,          // The user of ghash_out must 
    output logic                                ghash_out_vld,

    //****************************************************************
    // Individual multiplier inputs and outputs
    //****************************************************************
    input logic [127:0]                         y_0,
    input logic [127:0]                         y_1,
    input logic                                 y_vld,              // pulse when y_0 and y_1 are valid

    output logic [127:0]                        x_0,
    output logic [127:0]                        x_1,
    output logic                                x_vld               // start the operation once x_vld goes high
    );

    logic [127:0]           in_block;                   // Latch ghash input
    logic [127:0]           y_0_q;                      // Latch multiplication output from gfmac instance 0
    logic [127:0]           y_1_q;                      // Latch multiplication output from gfmac instance 1
    logic                   eom;

    // Capture input data on ghash_in_vld & ghash_in_rdy handshake
    // Also drive those inputs to multiplier
    // Reset the inputs when multiplier output valid goes high and wait for next handshake

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            in_block <= 128'h0;
            x_vld <= 1'h0;
            eom <= 1'h0;
        end
        else begin
            if(clear_i | y_vld) begin
                in_block <= 128'h0;
                x_vld <= 1'h0;
                eom <= 1'h0;
            end
            else if(ghash_in_vld & ghash_in_rdy) begin
                in_block <= ghash_in;
                x_vld <= 1'h1;
                eom <= ghash_in_last;
            end
        end
    end

    /*
    Continue to hold previous outputs of multiplier if not EOM
    */

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            y_0_q <= 128'h0;
            y_1_q <= 128'h0;
        end
        else begin
            if(clear_i | (ghash_out_vld & ghash_out_rdy)) begin
                y_0_q <= 128'h0;
                y_1_q <= 128'h0;
            end
            else if(y_vld) begin
                y_0_q <= y_0;           
                y_1_q <= y_1;
            end
        end
    end

    /* 
    Drive ghash output only when last input block is processed
    Dont unmask the multiplier output until last output block is generated
    */

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            ghash_out_vld <= 1'h0;
        end
        else begin
            if(clear_i | (ghash_out_vld & ghash_out_rdy)) begin
                ghash_out_vld <= 1'h0;              // De-assert out valid once output is captured
            end
            else if(y_vld & eom) begin
                ghash_out_vld <= 1'h1;
            end
        end
    end

    /*
    Drive input rdy high once drbg is ready and de-assert on input vld-rdy handshake
    Drive input rdy high once multiplier generates output to get ready to capture next input
    Except when multiplier generates the last output. In that case, only drive it high once 
    output is captured by external logic.
    */

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            ghash_in_rdy <= 1'h1;
        end
        else begin
            if(clear_i | (y_vld & (~eom)) | (ghash_out_vld & ghash_out_rdy)) begin
                ghash_in_rdy <= 1'h1;
            end
            else if (ghash_in_rdy & ghash_in_vld) begin
                ghash_in_rdy <= 1'h0;
            end
        end
    end

    assign x_0              = in_block ^ y_0_q;     // XOR input block with previous output only
    assign x_1              = 128'h0;               // Not used

    assign ghash_out        = ghash_out_vld ? (y_0_q) : 128'h0;

    
endmodule