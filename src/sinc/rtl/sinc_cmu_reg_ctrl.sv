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
// File        : sinc_cmu_reg_ctrl.sv
// Description : SInC register control module. Instantiates CSR registers and
//               manages FW command decoding and status/configuration values.

module sinc_cmu_reg_ctrl 
import sinc_pkg::*;
(
    /* clock, reset, misc */
    input logic                     clk_i,
    input logic                     rstn_i,
    input logic                     lp_rstn_i,
    output logic                    reg_ctrl_active,

    /* perf cntr ctrl interface */
    input logic                     ciu_cache_hit,
    input logic                     ciu_block_fetch_req,
    input logic                     cmu_block_fetch_comp,
    
    /* Reg basic interface */
    input logic                     csr_rd_en,
    input logic                     csr_wr_en,
    input logic [9:0]               csr_addr,
    input logic [31:0]              csr_wdata,
    output logic [31:0]             csr_rdata,
    output logic                    csr_rdy,
    output logic                    csr_err,

    /* CMU control */
    output logic                    reg_ctrl_cmd_vld,
    output sinc_cmu_cmd_t           reg_ctrl_cmd,
    output logic                    sinc_reset_dis,
    output logic                    sinc_reinit_dis,
    output logic                    reg_ctrl_invld_cmd_err,

    input sinc_state_t              cmu_sinc_state,
    input logic                     cmu_ctrl_sts_upd,
    input sts_update_t              cmu_ctrl_sts,
    input logic                     set_sinc_reset_dis,
    input logic                     set_sinc_reinit_dis,
    input logic                     cmu_ctrl_fw_cmd_done,
    input logic                     cmu_ctrl_active_cmd,
    input logic                     aes_test_busy,
    input logic                     sinc_fault_err_pulse,
    input logic                     severe_err,

    /* Register inputs/outputs */
    output logic [23:0]             block_encr_num,
    output logic [11:0]             num_of_blocks,
    output logic [31:0]             block_encr_addr,
    output logic [15:0]             block_encr_key,
    output logic [95:0]             aes_iv_nonce,
    output logic [31:0]             ext_block_base_addr,
    output logic [31:0]             ext_auth_tag_base_addr,
    output logic [127:0]            aes_test_din,
    output logic [17:0]             aes_test_ctrl,
    output logic                    sts_unread,

    input logic [127:0]             aes_test_dout,
    input logic                     aes_test_sts_tag_out,
    input logic                     set_aes_test_sts_dout_vld,
    input logic                     clr_aes_test_sts_dout_vld,
    input logic                     aes_test_sts_din_rdy,
    input logic                     aes_test_sts_cfg_key_iv_rdy,
    input logic                     clr_cfg_key_iv_vld,
    input logic                     clr_aes_test_din_vld,
    input logic                     encr_block_sts_upd,
    input logic [11:0]              encr_block_sts
    );

    logic [31:0]            aes_iv_nonce_0;
    logic                   aes_iv_nonce_0_write_access;
    logic [31:0]            aes_iv_nonce_0_write_data;
    logic [31:0]            aes_iv_nonce_1;
    logic                   aes_iv_nonce_1_write_access;
    logic [31:0]            aes_iv_nonce_1_write_data;
    logic [31:0]            aes_iv_nonce_2;
    logic                   aes_iv_nonce_2_write_access;
    logic [31:0]            aes_iv_nonce_2_write_data;
    logic [31:0]            aes_test_data_in_0;
    logic [31:0]            aes_test_data_in_1;
    logic [31:0]            aes_test_data_in_2;
    logic [31:0]            aes_test_data_in_3;
    logic [3:0]             aes_test_status;
    logic [7:0]             cmd;
    logic                   cmd_written;
    logic [31:0]            ext_auth_tag_base_addr_wdata;
    logic                   ext_auth_tag_base_addr_wr;
    logic [31:0]            ext_block_base_addr_wdata;
    logic                   ext_block_base_addr_wr;
    logic [15:0]            perf_cntr_ctrl;
    logic                   perf_cntr_ctrl_written;
    logic [23:0]            sts;

    logic                   sts_sinc_reinit_disabled;
    logic                   sts_sinc_reset_disabled;
    logic                   cmd_state_ok, cmd_vld;
    logic                   aes_test_data_out_0_aes_test_data_out_0_load_enable;
    logic [31:0]            aes_test_data_out_0_aes_test_data_out_0_input;
    logic                   aes_test_data_out_1_aes_test_data_out_1_load_enable;
    logic [31:0]            aes_test_data_out_1_aes_test_data_out_1_input;
    logic                   aes_test_data_out_2_aes_test_data_out_2_load_enable;
    logic [31:0]            aes_test_data_out_2_aes_test_data_out_2_input;
    logic                   aes_test_data_out_3_aes_test_data_out_3_load_enable;
    logic [31:0]            aes_test_data_out_3_aes_test_data_out_3_input;
    logic                   sts_load_enable;
    logic                   sts_sinc_hw_fault_load_enable;
    logic                   sts_sinc_hw_fault_input;
    logic                   sts_aes_err_input;
    logic                   aes_test_ctrl_data_in_vld_input;
    logic                   aes_test_ctrl_cfg_key_iv_vld_input;
    logic                   status_sinc_hw_fault_load_enable;
    logic                   status_sinc_hw_fault_input;
    logic                   status_aes_err_input;
    logic                   status_auth_tag_w_err_input;
    logic                   status_auth_tag_chk_err_input;
    logic                   status_auth_tag_r_err_input;
    logic                   status_cache_block_w_err_fetch_block_input;
    logic                   status_cache_block_w_err_encr_block_input;
    logic                   status_cache_block_r_err_input;
    logic                   status_key_fetch_err_input;
    logic                   status_rng_seed_r_err_input;
    logic                   status_invalid_cmd_err_input, status_invalid_cmd_err_load_enable;
    logic                   status_cmd_failed_input, status_cmd_failed_load_enable;
    logic                   status_cmd_success_input;
    logic                   status_cmd_in_progress_input;
    logic                   status_cmd_in_progress_load_enable;
    logic                   valid_cmd_enc;
    logic [9:0]             unused_perf_cntr_ctrl;
    logic [47:0]            hit_cntr;
    logic [47:0]            miss_cntr;
    logic [47:0]            lat_cntr;
    logic                   lat_cntr_run;
    logic                   hit_cntr_en;
    logic                   hit_cntr_clr;
    logic                   hit_cntr_max;
    logic                   miss_cntr_en;
    logic                   miss_cntr_clr;
    logic                   miss_cntr_max;
    logic                   lat_cntr_en;
    logic                   lat_cntr_clr;
    logic                   lat_cntr_max;
    logic                   aes_test_sts_dout_vld_q;
    logic                   aes_test_dout_ack;
    logic                   aes_test_sts_tag_out_load_enable;
    logic                   aes_test_sts_tag_out_input;
    logic                   aes_test_sts_data_out_vld_load_enable;
    logic                   aes_test_sts_data_out_vld_input;
    logic                   is_state_dis;
    logic                   is_state_init;
    logic                   is_state_dis_or_init;
    logic [2:0]             aes_test_sts_unused;
    logic                   aes_test_sts_dout_vld;
    logic                   cmd_clear, cmd_vld_pass_1, invld_cmd_err_pass_1, invld_cmd_err_pass_2;


    

    sinc_regs u_sinc_regs (
        // Outputs
        .cmd                                                    (cmd[7:0]),
        .cmd_written                                            (cmd_written),
        .block_encr_num                                         (block_encr_num[23:0]),
        .num_of_blocks                                          (num_of_blocks[11:0]),
        .block_encr_addr                                        (block_encr_addr[31:0]),
        .block_encr_key                                         (block_encr_key[15:0]),
        .aes_iv_nonce_0_write_access                            (aes_iv_nonce_0_write_access),
        .aes_iv_nonce_0_write_data                              (aes_iv_nonce_0_write_data[31:0]),
        .aes_iv_nonce_1_write_access                            (aes_iv_nonce_1_write_access),
        .aes_iv_nonce_1_write_data                              (aes_iv_nonce_1_write_data[31:0]),
        .aes_iv_nonce_2_write_access                            (aes_iv_nonce_2_write_access),
        .aes_iv_nonce_2_write_data                              (aes_iv_nonce_2_write_data[31:0]),
        .ext_block_base_addr_write_access                       (ext_block_base_addr_wr),
        .ext_block_base_addr_write_data                         (ext_block_base_addr_wdata[31:0]),
        .ext_auth_tag_base_addr_write_access                    (ext_auth_tag_base_addr_wr),
        .ext_auth_tag_base_addr_write_data                      (ext_auth_tag_base_addr_wdata[31:0]),
        .status                                                 (sts[23:0]),
        .perf_cntr_ctrl                                         (perf_cntr_ctrl[15:0]),
        .perf_cntr_ctrl_written                                 (perf_cntr_ctrl_written),
        .aes_test_data_in_0                                     (aes_test_data_in_0[31:0]),
        .aes_test_data_in_1                                     (aes_test_data_in_1[31:0]),
        .aes_test_data_in_2                                     (aes_test_data_in_2[31:0]),
        .aes_test_data_in_3                                     (aes_test_data_in_3[31:0]),
        .aes_test_ctrl                                          (aes_test_ctrl[17:0]),
        .aes_test_status                                        (aes_test_status[3:0]),
        .csr_rdy                                                (csr_rdy),
        .csr_err                                                (csr_err),
        .csr_rdata                                              (csr_rdata[31:0]),

        // Inputs
        .cmd_aes_test_en_clear                                  (cmd_clear),
        .cmd_disable_reinit_clear                               (cmd_clear),
        .cmd_disable_reset_clear                                (cmd_clear),
        .cmd_encr_block_clear                                   (cmd_clear),
        .cmd_sinc_reinit_clear                                  (cmd_clear),
        .cmd_sinc_reset_clear                                   (cmd_clear),
        .cmd_set_cache_active_state_clear                       (cmd_clear),
        .cmd_set_init_state_clear                               (cmd_clear),
        .block_encr_num_block_encr_num_write_enable             (is_state_dis_or_init),
        .num_of_blocks_num_of_blocks_write_enable               (is_state_dis_or_init),
        .block_encr_addr_block_encr_addr_write_enable           (is_state_dis_or_init),
        .block_encr_key_block_encr_key_write_enable             (is_state_dis),
        .aes_iv_nonce_0_read_data                               (aes_iv_nonce_0),
        .aes_iv_nonce_1_read_data                               (aes_iv_nonce_1),
        .aes_iv_nonce_2_read_data                               (aes_iv_nonce_2),
        .ext_block_base_addr_read_data                          (ext_block_base_addr[31:0]),
        .ext_auth_tag_base_addr_read_data                       (ext_auth_tag_base_addr[31:0]),
        .status_sinc_hw_fault_load_enable                       (status_sinc_hw_fault_load_enable),
        .status_sinc_hw_fault_input                             (status_sinc_hw_fault_input),
        .status_aes_err_load_enable                             (sts_load_enable),
        .status_aes_err_input                                   (status_aes_err_input),
        .status_auth_tag_w_err_load_enable                      (sts_load_enable),
        .status_auth_tag_w_err_input                            (status_auth_tag_w_err_input),
        .status_auth_tag_chk_err_load_enable                    (sts_load_enable),
        .status_auth_tag_chk_err_input                          (status_auth_tag_chk_err_input),
        .status_auth_tag_r_err_load_enable                      (sts_load_enable),
        .status_auth_tag_r_err_input                            (status_auth_tag_r_err_input),
        .status_cache_block_w_err_fetch_block_load_enable       (sts_load_enable),
        .status_cache_block_w_err_fetch_block_input             (status_cache_block_w_err_fetch_block_input),
        .status_cache_block_w_err_encr_block_load_enable        (sts_load_enable),
        .status_cache_block_w_err_encr_block_input              (status_cache_block_w_err_encr_block_input),
        .status_cache_block_r_err_load_enable                   (sts_load_enable),
        .status_cache_block_r_err_input                         (status_cache_block_r_err_input),
        .status_key_fetch_err_load_enable                       (sts_load_enable),
        .status_key_fetch_err_input                             (status_key_fetch_err_input),
        .status_rng_seed_r_err_load_enable                      (sts_load_enable),
        .status_rng_seed_r_err_input                            (status_rng_seed_r_err_input),
        .status_invalid_cmd_err_load_enable                     (status_invalid_cmd_err_load_enable),
        .status_invalid_cmd_err_input                           (status_invalid_cmd_err_input),
        .status_cmd_failed_load_enable                          (status_cmd_failed_load_enable),
        .status_cmd_failed_input                                (status_cmd_failed_input),
        .status_cmd_success_load_enable                         (sts_load_enable),
        .status_cmd_success_input                               (status_cmd_success_input),
        .status_cmd_in_progress_load_enable                     (status_cmd_in_progress_load_enable),
        .status_cmd_in_progress_input                           (status_cmd_in_progress_input),
        .status_sinc_reinit_disabled                            (sinc_reinit_dis),
        .status_sinc_reset_disabled                             (sinc_reset_dis),
        .status_state                                           (cmu_sinc_state),
        .hit_cntr_lower_hit_cntr_lower                          (hit_cntr[31:0]),
        .hit_cntr_upper_hit_cntr_upper                          (hit_cntr[47:32]),
        .miss_cntr_lower_miss_cntr_lower                        (miss_cntr[31:0]),
        .miss_cntr_upper_miss_cntr_upper                        (miss_cntr[47:32]),
        .lat_cntr_lower_lat_cntr_lower                          (lat_cntr[31:0]),
        .lat_cntr_upper_lat_cntr_upper                          (lat_cntr[47:32]),
        .aes_test_data_out_0_aes_test_data_out_0_clear          (aes_test_dout_ack),
        .aes_test_data_out_0_aes_test_data_out_0_load_enable    (aes_test_sts_data_out_vld_load_enable),
        .aes_test_data_out_0_aes_test_data_out_0_input          (aes_test_data_out_0_aes_test_data_out_0_input[31:0]),
        .aes_test_data_out_1_aes_test_data_out_1_clear          (aes_test_dout_ack),
        .aes_test_data_out_1_aes_test_data_out_1_load_enable    (aes_test_sts_data_out_vld_load_enable),
        .aes_test_data_out_1_aes_test_data_out_1_input          (aes_test_data_out_1_aes_test_data_out_1_input[31:0]),
        .aes_test_data_out_2_aes_test_data_out_2_clear          (aes_test_dout_ack),
        .aes_test_data_out_2_aes_test_data_out_2_load_enable    (aes_test_sts_data_out_vld_load_enable),
        .aes_test_data_out_2_aes_test_data_out_2_input          (aes_test_data_out_2_aes_test_data_out_2_input[31:0]),
        .aes_test_data_out_3_aes_test_data_out_3_clear          (aes_test_dout_ack),
        .aes_test_data_out_3_aes_test_data_out_3_load_enable    (aes_test_sts_data_out_vld_load_enable),
        .aes_test_data_out_3_aes_test_data_out_3_input          (aes_test_data_out_3_aes_test_data_out_3_input[31:0]),
        .aes_test_ctrl_data_out_ack_write_enable                (aes_test_sts_dout_vld),
        .aes_test_ctrl_data_out_ack_clear                       (aes_test_dout_ack),
        .aes_test_ctrl_data_in_aad_sel_write_enable             (aes_test_sts_din_rdy),
        .aes_test_ctrl_data_in_last_write_enable                (aes_test_sts_din_rdy),
        .aes_test_ctrl_data_in_byte_cnt_write_enable            (aes_test_sts_din_rdy),
        .aes_test_ctrl_data_in_vld_write_enable                 (aes_test_sts_din_rdy),
        .aes_test_ctrl_data_in_vld_load_enable                  (clr_aes_test_din_vld),
        .aes_test_ctrl_data_in_vld_input                        (aes_test_ctrl_data_in_vld_input),
        .aes_test_ctrl_cfg_key_iv_vld_write_enable              (aes_test_sts_cfg_key_iv_rdy),
        .aes_test_ctrl_cfg_key_iv_vld_load_enable               (clr_cfg_key_iv_vld),
        .aes_test_ctrl_cfg_key_iv_vld_input                     (aes_test_ctrl_cfg_key_iv_vld_input),
        .aes_test_ctrl_reuse_key_write_enable                   (aes_test_sts_cfg_key_iv_rdy),
        .aes_test_ctrl_key_len_write_enable                     (aes_test_sts_cfg_key_iv_rdy),
        .aes_test_ctrl_dir_write_enable                         (aes_test_sts_cfg_key_iv_rdy),
        .aes_test_ctrl_mode_write_enable                        (aes_test_sts_cfg_key_iv_rdy),
        .aes_test_status_tag_out_clear                          (aes_test_dout_ack),
        .aes_test_status_tag_out_load_enable                    (aes_test_sts_tag_out_load_enable),
        .aes_test_status_tag_out_input                          (aes_test_sts_tag_out_input),
        .aes_test_status_data_out_vld_clear                     (aes_test_dout_ack),
        .aes_test_status_data_out_vld_load_enable               (aes_test_sts_data_out_vld_load_enable),
        .aes_test_status_data_out_vld_input                     (aes_test_sts_data_out_vld_input),
        .aes_test_status_data_in_rdy                            (aes_test_sts_din_rdy),
        .aes_test_status_cfg_key_iv_rdy                         (aes_test_sts_cfg_key_iv_rdy),
        .encr_block_status_num_of_blocks_encr_load_enable       (encr_block_sts_upd),
        .encr_block_status_num_of_blocks_encr_input             (encr_block_sts[11:0]),
        .csr_wr_en                                              (csr_wr_en),
        .csr_rd_en                                              (csr_rd_en),
        .csr_addr                                               (csr_addr[9:0]),
        .csr_wdata                                              (csr_wdata[31:0]),
        .reset                                                  (lp_rstn_i),
        .clock                                                  (clk_i)
    );
    

    sinc_cmu_reg_ctrl_ret u_sinc_cmu_reg_ctrl_ret (
                                                   // Outputs
                                                   .sinc_reinit_dis     (sinc_reinit_dis),
                                                   .sinc_reset_dis      (sinc_reset_dis),
                                                   .aes_iv_nonce_0      (aes_iv_nonce_0[31:0]),
                                                   .aes_iv_nonce_1      (aes_iv_nonce_1[31:0]),
                                                   .aes_iv_nonce_2      (aes_iv_nonce_2[31:0]),
                                                   .ext_block_base_addr (ext_block_base_addr[31:0]),
                                                   .ext_auth_tag_base_addr(ext_auth_tag_base_addr[31:0]),
                                                   // Inputs
                                                   .clk_i               (clk_i),
                                                   .rstn_i              (rstn_i),
                                                   .set_sinc_reinit_dis (set_sinc_reinit_dis),
                                                   .set_sinc_reset_dis  (set_sinc_reset_dis),
                                                   .is_state_dis        (is_state_dis),
                                                   .is_state_init       (is_state_init),
                                                   .aes_iv_nonce_0_wr   (aes_iv_nonce_0_write_access),
                                                   .aes_iv_nonce_0_wdata(aes_iv_nonce_0_write_data[31:0]),
                                                   .aes_iv_nonce_1_wr   (aes_iv_nonce_1_write_access),
                                                   .aes_iv_nonce_1_wdata(aes_iv_nonce_1_write_data[31:0]),
                                                   .aes_iv_nonce_2_wr   (aes_iv_nonce_2_write_access),
                                                   .aes_iv_nonce_2_wdata(aes_iv_nonce_2_write_data[31:0]),
                                                   .ext_block_base_addr_wr(ext_block_base_addr_wr),
                                                   .ext_block_base_addr_wdata(ext_block_base_addr_wdata[31:0]),
                                                   .ext_auth_tag_base_addr_wr(ext_auth_tag_base_addr_wr),
                                                   .ext_auth_tag_base_addr_wdata(ext_auth_tag_base_addr_wdata[31:0]),
                                                   .severe_err          (severe_err));

    /* perf counters */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            hit_cntr <= 48'h0;
            miss_cntr <= 48'h0;
            lat_cntr <= 48'h0;
            lat_cntr_run <= 1'h0;
        end
        else begin
            if(perf_cntr_ctrl_written & hit_cntr_clr) begin
                hit_cntr <= 48'h0;
            end
            else if(hit_cntr_en & ciu_cache_hit) begin
                if (~hit_cntr_max) begin
                    hit_cntr <= hit_cntr + 1'h1;
                end
            end

            if(perf_cntr_ctrl_written & miss_cntr_clr) begin
                miss_cntr <= 48'h0;
            end
            else if(miss_cntr_en & ciu_block_fetch_req) begin
                if (~miss_cntr_max) begin
                    miss_cntr <= miss_cntr + 1'h1;
                end
            end

            if(perf_cntr_ctrl_written & lat_cntr_clr) begin
                lat_cntr <= 48'h0;
            end
            else if(lat_cntr_en & lat_cntr_run) begin       // keep incrementing cntr when it is enabled
                if (~lat_cntr_max) begin                    // and running flag is set
                    lat_cntr <= lat_cntr + 1'h1;
                end
            end

            if (ciu_block_fetch_req) begin          // resume lat cnt on getting fetch block req
                lat_cntr_run <= 1'h1;
            end
            else if (cmu_block_fetch_comp) begin    // pause lat cnt on fetch block comp
                lat_cntr_run <= 1'h0;
            end
        end
    end

    /* flop cmd_written to avoid X-prop during PAV */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            cmd_vld_pass_1 <= 1'h0;
            invld_cmd_err_pass_1 <= 1'h0;
        end
        else begin
            cmd_vld_pass_1 <= cmd_written & cmd_vld;
            invld_cmd_err_pass_1 <= cmd_written & (~cmd_vld);         // cmd won't be initiated if this is flagged
        end
    end

    /* checks new cmd in cmd and aes test ctrl registers against sinc state */
    always_comb begin
        cmd_state_ok = 1'h0;

        if(sinc_state_t'(cmu_sinc_state) == DISABLED) begin
            cmd_state_ok = (cmd[7] | cmd[0] | cmd[5] | cmd[6]) | (cmd == 8'h0);     // cmd == 0 is to exit out of test mode
        end
        else if (sinc_state_t'(cmu_sinc_state) == INITIALIZATION) begin
            cmd_state_ok = (cmd[1] | cmd[2] | cmd[4] | cmd[5] | cmd[6]);
        end
        else if (sinc_state_t'(cmu_sinc_state) == CACHE_ACTIVE) begin
            cmd_state_ok = (cmd[2] | cmd[3] | cmd[5] | cmd[6]);
        end
        else if (sinc_state_t'(cmu_sinc_state) == CACHE_FAILED) begin
            cmd_state_ok = cmd[2];
        end
    end

    assign valid_cmd_enc            = ((cmd == 8'h00) | (cmd == 8'h01) | (cmd == 8'h02) | (cmd == 8'h04) |
                                        (cmd == 8'h08) | (cmd == 8'h10) | (cmd == 8'h20) | (cmd == 8'h40) | (cmd == 8'h80));

    assign cmd_vld                  = (cmd_state_ok & valid_cmd_enc) & ((~cmu_ctrl_active_cmd) | aes_test_busy);
    assign reg_ctrl_cmd_vld         = cmd_vld_pass_1 & (~ciu_block_fetch_req);
    assign invld_cmd_err_pass_2     = cmd_vld_pass_1 & ciu_block_fetch_req;
    assign reg_ctrl_invld_cmd_err   = invld_cmd_err_pass_1 | invld_cmd_err_pass_2;

    // Send out new command to CMU ctrl.
    // padded by 1 zero bit to reserve for fetch block and use the same typedef enum across diff sub-modules. See cmu ctrl
    assign reg_ctrl_cmd             = {2'h0, cmd[7:0]};
    assign sts_unread               = |sts[23:10];
    assign cmd_clear                = cmu_ctrl_fw_cmd_done | reg_ctrl_invld_cmd_err;// clear cmd reg on fw cmd completion (success or error)

    assign sts_load_enable                              = cmu_ctrl_sts_upd;
    assign status_cmd_in_progress_load_enable           = sinc_fault_err_pulse | sts_load_enable; 
    assign status_cmd_in_progress_input                 = sinc_fault_err_pulse ? 1'h0 : cmu_ctrl_sts[0];
    assign status_cmd_success_input                     = cmu_ctrl_sts[1];
    assign status_cmd_failed_load_enable                = reg_ctrl_invld_cmd_err | sts_load_enable;
    assign status_cmd_failed_input                      = reg_ctrl_invld_cmd_err | cmu_ctrl_sts[2];
    assign status_invalid_cmd_err_load_enable           = reg_ctrl_invld_cmd_err | sts_load_enable;
    assign status_invalid_cmd_err_input                 = reg_ctrl_invld_cmd_err | cmu_ctrl_sts[3];
    assign status_rng_seed_r_err_input                  = cmu_ctrl_sts[4];
    assign status_key_fetch_err_input                   = cmu_ctrl_sts[5];
    assign status_cache_block_r_err_input               = cmu_ctrl_sts[6];
    assign status_cache_block_w_err_encr_block_input    = cmu_ctrl_sts[7];
    assign status_cache_block_w_err_fetch_block_input   = cmu_ctrl_sts[8];
    assign status_auth_tag_r_err_input                  = cmu_ctrl_sts[9];
    assign status_auth_tag_chk_err_input                = cmu_ctrl_sts[10];
    assign status_auth_tag_w_err_input                  = cmu_ctrl_sts[11];
    assign status_aes_err_input                         = cmu_ctrl_sts[12];
    assign status_sinc_hw_fault_input                   = sinc_fault_err_pulse;
    assign status_sinc_hw_fault_load_enable             = sinc_fault_err_pulse;

    assign hit_cntr_en               = perf_cntr_ctrl[0];
    assign hit_cntr_clr              = perf_cntr_ctrl[1];
    assign miss_cntr_en              = perf_cntr_ctrl[7];
    assign miss_cntr_clr             = perf_cntr_ctrl[8];
    assign lat_cntr_en               = perf_cntr_ctrl[14];
    assign lat_cntr_clr              = perf_cntr_ctrl[15];
    assign unused_perf_cntr_ctrl     = {perf_cntr_ctrl[13:9], perf_cntr_ctrl[6:2]};

    assign hit_cntr_max              = &hit_cntr[47:0];
    assign miss_cntr_max             = &miss_cntr[47:0];
    assign lat_cntr_max              = &lat_cntr[47:0];

    assign aes_test_ctrl_data_in_vld_input                      = 1'h0;         // Used together with load_enable to clear these fields in regs
    assign aes_test_ctrl_cfg_key_iv_vld_input                   = 1'h0;         // Used together with load_enable to clear these fields in regs
    assign aes_test_data_out_0_aes_test_data_out_0_input        = aes_test_dout[31:0];
    assign aes_test_data_out_1_aes_test_data_out_1_input        = aes_test_dout[63:32];
    assign aes_test_data_out_2_aes_test_data_out_2_input        = aes_test_dout[95:64];
    assign aes_test_data_out_3_aes_test_data_out_3_input        = aes_test_dout[127:96];
    assign aes_test_sts_data_out_vld_load_enable                = set_aes_test_sts_dout_vld;
    assign aes_test_sts_data_out_vld_input                      = set_aes_test_sts_dout_vld;
    assign aes_test_sts_tag_out_load_enable                     = aes_test_sts_tag_out;
    assign aes_test_sts_tag_out_input                           = 1'h1;

    assign aes_test_din                     = {aes_test_data_in_3, aes_test_data_in_2, aes_test_data_in_1, aes_test_data_in_0};
    assign aes_iv_nonce                     = {aes_iv_nonce_2, aes_iv_nonce_1, aes_iv_nonce_0};
    assign aes_test_dout_ack                = aes_test_ctrl[17] | clr_aes_test_sts_dout_vld;

    assign aes_test_sts_dout_vld            = aes_test_status[2];
    assign aes_test_sts_unused              = {aes_test_status[3], aes_test_status[1:0]};

    assign is_state_dis                     = (cmu_sinc_state == DISABLED);
    assign is_state_init                    = (cmu_sinc_state == INITIALIZATION);
    assign is_state_dis_or_init             = is_state_dis | is_state_init;

    assign reg_ctrl_active                  = csr_rd_en | csr_wr_en | ciu_cache_hit | 
                                                cmu_ctrl_sts_upd | encr_block_sts_upd;

endmodule