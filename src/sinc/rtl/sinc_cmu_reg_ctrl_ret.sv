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
// File        : sinc_cmu_reg_ctrl_ret.sv
// Description : SInC register control retention module. Holds AES IV/nonce,
//               base addresses, and command disable state across retention.

module sinc_cmu_reg_ctrl_ret 
(
    /* clock, reset, misc */
    input logic                     clk_i,
    input logic                     rstn_i,
    
    input logic                     set_sinc_reinit_dis,
    input logic                     set_sinc_reset_dis,
    input logic                     is_state_dis,
    input logic                     is_state_init,
    input logic                     aes_iv_nonce_0_wr,
    input logic [31:0]              aes_iv_nonce_0_wdata,
    input logic                     aes_iv_nonce_1_wr,
    input logic [31:0]              aes_iv_nonce_1_wdata,
    input logic                     aes_iv_nonce_2_wr,
    input logic [31:0]              aes_iv_nonce_2_wdata,
    input logic                     ext_block_base_addr_wr,
    input logic [31:0]              ext_block_base_addr_wdata,
    input logic                     ext_auth_tag_base_addr_wr,
    input logic [31:0]              ext_auth_tag_base_addr_wdata,
    input logic                     severe_err,

    /* Register inputs/outputs */
    output logic                    sinc_reinit_dis,
    output logic                    sinc_reset_dis,
    output logic [31:0]             aes_iv_nonce_0,
    output logic [31:0]             aes_iv_nonce_1,
    output logic [31:0]             aes_iv_nonce_2,
    output logic [31:0]             ext_block_base_addr,
    output logic [31:0]             ext_auth_tag_base_addr
    );


    /* flops to store command disabled sts */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            sinc_reinit_dis <= 1'h0;
            sinc_reset_dis <= 1'h0;
        end
        else begin
            if(set_sinc_reinit_dis) begin
                sinc_reinit_dis <= 1'h1;
            end

            if(set_sinc_reset_dis) begin
                sinc_reset_dis <= 1'h1;
            end
        end
    end

    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            aes_iv_nonce_0 <= 32'h0;
            aes_iv_nonce_1 <= 32'h0;
            aes_iv_nonce_2 <= 32'h0;
        end
        else begin
            if (severe_err) begin
                aes_iv_nonce_0 <= 32'h0;
                aes_iv_nonce_1 <= 32'h0;
                aes_iv_nonce_2 <= 32'h0;
            end
            else if(is_state_dis) begin
                if (aes_iv_nonce_0_wr) begin
                    aes_iv_nonce_0 <= aes_iv_nonce_0_wdata;
                end

                if (aes_iv_nonce_1_wr) begin
                    aes_iv_nonce_1 <= aes_iv_nonce_1_wdata;
                end

                if (aes_iv_nonce_2_wr) begin
                    aes_iv_nonce_2 <= aes_iv_nonce_2_wdata;
                end
            end
        end
    end

    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            ext_block_base_addr <= 32'h0;
            ext_auth_tag_base_addr <= 32'h0;
        end
        else begin
            if(is_state_dis | is_state_init) begin
                if (ext_block_base_addr_wr) begin
                    ext_block_base_addr <= ext_block_base_addr_wdata;
                end

                if (ext_auth_tag_base_addr_wr) begin
                    ext_auth_tag_base_addr <= ext_auth_tag_base_addr_wdata;
                end
            end
        end
    end


endmodule