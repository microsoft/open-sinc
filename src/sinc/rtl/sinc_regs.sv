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
//
// Addressmap: sinc_regs
//
//   Bus Protocol: basic
//   Bus Address Units: bytes
//
//   Access: read-write
//   Offset Units: bytes
//   Word size: 4 bytes
//
module sinc_regs (
    output wire [7:0] cmd,
    output wire cmd_written,
    output wire [23:0] block_encr_num,
    output wire [11:0] num_of_blocks,
    output wire [31:0] block_encr_addr,
    output wire [15:0] block_encr_key,
    output wire aes_iv_nonce_0_write_access,
    output wire [31:0] aes_iv_nonce_0_write_data,
    output wire aes_iv_nonce_1_write_access,
    output wire [31:0] aes_iv_nonce_1_write_data,
    output wire aes_iv_nonce_2_write_access,
    output wire [31:0] aes_iv_nonce_2_write_data,
    output wire ext_block_base_addr_write_access,
    output wire [31:0] ext_block_base_addr_write_data,
    output wire ext_auth_tag_base_addr_write_access,
    output wire [31:0] ext_auth_tag_base_addr_write_data,
    output wire [23:0] status,
    output wire [15:0] perf_cntr_ctrl,
    output wire perf_cntr_ctrl_written,
    output wire [31:0] aes_test_data_in_0,
    output wire [31:0] aes_test_data_in_1,
    output wire [31:0] aes_test_data_in_2,
    output wire [31:0] aes_test_data_in_3,
    output wire [17:0] aes_test_ctrl,
    output wire [3:0] aes_test_status,
    output wire csr_rdy,
    output wire csr_err,
    output wire [31:0] csr_rdata,
    input  wire cmd_aes_test_en_clear,
    input  wire cmd_disable_reinit_clear,
    input  wire cmd_disable_reset_clear,
    input  wire cmd_encr_block_clear,
    input  wire cmd_sinc_reinit_clear,
    input  wire cmd_sinc_reset_clear,
    input  wire cmd_set_cache_active_state_clear,
    input  wire cmd_set_init_state_clear,
    input  wire block_encr_num_block_encr_num_write_enable,
    input  wire num_of_blocks_num_of_blocks_write_enable,
    input  wire block_encr_addr_block_encr_addr_write_enable,
    input  wire block_encr_key_block_encr_key_write_enable,
    input  wire [31:0] aes_iv_nonce_0_read_data,
    input  wire [31:0] aes_iv_nonce_1_read_data,
    input  wire [31:0] aes_iv_nonce_2_read_data,
    input  wire [31:0] ext_block_base_addr_read_data,
    input  wire [31:0] ext_auth_tag_base_addr_read_data,
    input  wire status_sinc_hw_fault_load_enable,
    input  wire status_sinc_hw_fault_input,
    input  wire status_aes_err_load_enable,
    input  wire status_aes_err_input,
    input  wire status_auth_tag_w_err_load_enable,
    input  wire status_auth_tag_w_err_input,
    input  wire status_auth_tag_chk_err_load_enable,
    input  wire status_auth_tag_chk_err_input,
    input  wire status_auth_tag_r_err_load_enable,
    input  wire status_auth_tag_r_err_input,
    input  wire status_cache_block_w_err_fetch_block_load_enable,
    input  wire status_cache_block_w_err_fetch_block_input,
    input  wire status_cache_block_w_err_encr_block_load_enable,
    input  wire status_cache_block_w_err_encr_block_input,
    input  wire status_cache_block_r_err_load_enable,
    input  wire status_cache_block_r_err_input,
    input  wire status_key_fetch_err_load_enable,
    input  wire status_key_fetch_err_input,
    input  wire status_rng_seed_r_err_load_enable,
    input  wire status_rng_seed_r_err_input,
    input  wire status_invalid_cmd_err_load_enable,
    input  wire status_invalid_cmd_err_input,
    input  wire status_cmd_failed_load_enable,
    input  wire status_cmd_failed_input,
    input  wire status_cmd_success_load_enable,
    input  wire status_cmd_success_input,
    input  wire status_cmd_in_progress_load_enable,
    input  wire status_cmd_in_progress_input,
    input  wire status_sinc_reinit_disabled,
    input  wire status_sinc_reset_disabled,
    input  wire [7:0] status_state,
    input  wire [31:0] hit_cntr_lower_hit_cntr_lower,
    input  wire [15:0] hit_cntr_upper_hit_cntr_upper,
    input  wire [31:0] miss_cntr_lower_miss_cntr_lower,
    input  wire [15:0] miss_cntr_upper_miss_cntr_upper,
    input  wire [31:0] lat_cntr_lower_lat_cntr_lower,
    input  wire [15:0] lat_cntr_upper_lat_cntr_upper,
    input  wire aes_test_data_out_0_aes_test_data_out_0_clear,
    input  wire aes_test_data_out_0_aes_test_data_out_0_load_enable,
    input  wire [31:0] aes_test_data_out_0_aes_test_data_out_0_input,
    input  wire aes_test_data_out_1_aes_test_data_out_1_clear,
    input  wire aes_test_data_out_1_aes_test_data_out_1_load_enable,
    input  wire [31:0] aes_test_data_out_1_aes_test_data_out_1_input,
    input  wire aes_test_data_out_2_aes_test_data_out_2_clear,
    input  wire aes_test_data_out_2_aes_test_data_out_2_load_enable,
    input  wire [31:0] aes_test_data_out_2_aes_test_data_out_2_input,
    input  wire aes_test_data_out_3_aes_test_data_out_3_clear,
    input  wire aes_test_data_out_3_aes_test_data_out_3_load_enable,
    input  wire [31:0] aes_test_data_out_3_aes_test_data_out_3_input,
    input  wire aes_test_ctrl_data_out_ack_write_enable,
    input  wire aes_test_ctrl_data_out_ack_clear,
    input  wire aes_test_ctrl_data_in_aad_sel_write_enable,
    input  wire aes_test_ctrl_data_in_last_write_enable,
    input  wire aes_test_ctrl_data_in_byte_cnt_write_enable,
    input  wire aes_test_ctrl_data_in_vld_write_enable,
    input  wire aes_test_ctrl_data_in_vld_load_enable,
    input  wire aes_test_ctrl_data_in_vld_input,
    input  wire aes_test_ctrl_cfg_key_iv_vld_write_enable,
    input  wire aes_test_ctrl_cfg_key_iv_vld_load_enable,
    input  wire aes_test_ctrl_cfg_key_iv_vld_input,
    input  wire aes_test_ctrl_reuse_key_write_enable,
    input  wire aes_test_ctrl_key_len_write_enable,
    input  wire aes_test_ctrl_dir_write_enable,
    input  wire aes_test_ctrl_mode_write_enable,
    input  wire aes_test_status_tag_out_clear,
    input  wire aes_test_status_tag_out_load_enable,
    input  wire aes_test_status_tag_out_input,
    input  wire aes_test_status_data_out_vld_clear,
    input  wire aes_test_status_data_out_vld_load_enable,
    input  wire aes_test_status_data_out_vld_input,
    input  wire aes_test_status_data_in_rdy,
    input  wire aes_test_status_cfg_key_iv_rdy,
    input  wire encr_block_status_num_of_blocks_encr_load_enable,
    input  wire [11:0] encr_block_status_num_of_blocks_encr_input,
    input  wire csr_wr_en,
    input  wire csr_rd_en,
    input  wire [9:0] csr_addr,
    input  wire [31:0] csr_wdata,
    input  wire reset,
    input  wire clock
    );

    // internal net declarations
    reg    csr_internal_field_cmd_aes_test_en;
    reg    csr_internal_field_cmd_disable_reinit;
    reg    csr_internal_field_cmd_disable_reset;
    reg    csr_internal_field_cmd_encr_block;
    reg    csr_internal_field_cmd_sinc_reinit;
    reg    csr_internal_field_cmd_sinc_reset;
    reg    csr_internal_field_cmd_set_cache_active_state;
    reg    csr_internal_field_cmd_set_init_state;
    reg    csr_internal_written_cmd;
    reg    [23:0] csr_internal_field_block_encr_num_block_encr_num;
    reg    [11:0] csr_internal_field_num_of_blocks_num_of_blocks;
    reg    [31:0] csr_internal_field_block_encr_addr_block_encr_addr;
    reg    [15:0] csr_internal_field_block_encr_key_block_encr_key;
    reg    csr_internal_field_status_sinc_hw_fault;
    reg    csr_internal_field_status_aes_err;
    reg    csr_internal_field_status_auth_tag_w_err;
    reg    csr_internal_field_status_auth_tag_chk_err;
    reg    csr_internal_field_status_auth_tag_r_err;
    reg    csr_internal_field_status_cache_block_w_err_fetch_block;
    reg    csr_internal_field_status_cache_block_w_err_encr_block;
    reg    csr_internal_field_status_cache_block_r_err;
    reg    csr_internal_field_status_key_fetch_err;
    reg    csr_internal_field_status_rng_seed_r_err;
    reg    csr_internal_field_status_invalid_cmd_err;
    reg    csr_internal_field_status_cmd_failed;
    reg    csr_internal_field_status_cmd_success;
    reg    csr_internal_field_status_cmd_in_progress;
    reg    csr_internal_field_perf_cntr_ctrl_lat_cntr_clr;
    reg    csr_internal_field_perf_cntr_ctrl_lat_cntr_en;
    reg    csr_internal_field_perf_cntr_ctrl_miss_cntr_clr;
    reg    csr_internal_field_perf_cntr_ctrl_miss_cntr_en;
    reg    csr_internal_field_perf_cntr_ctrl_hit_cntr_clr;
    reg    csr_internal_field_perf_cntr_ctrl_hit_cntr_en;
    reg    csr_internal_written_perf_cntr_ctrl;
    reg    [31:0] csr_internal_field_aes_test_data_in_0_aes_test_data_in_0;
    reg    [31:0] csr_internal_field_aes_test_data_in_1_aes_test_data_in_1;
    reg    [31:0] csr_internal_field_aes_test_data_in_2_aes_test_data_in_2;
    reg    [31:0] csr_internal_field_aes_test_data_in_3_aes_test_data_in_3;
    reg    [31:0] csr_internal_field_aes_test_data_out_0_aes_test_data_out_0;
    reg    [31:0] csr_internal_field_aes_test_data_out_1_aes_test_data_out_1;
    reg    [31:0] csr_internal_field_aes_test_data_out_2_aes_test_data_out_2;
    reg    [31:0] csr_internal_field_aes_test_data_out_3_aes_test_data_out_3;
    reg    csr_internal_field_aes_test_ctrl_data_out_ack;
    reg    csr_internal_field_aes_test_ctrl_data_in_aad_sel;
    reg    csr_internal_field_aes_test_ctrl_data_in_last;
    reg    [4:0] csr_internal_field_aes_test_ctrl_data_in_byte_cnt;
    reg    csr_internal_field_aes_test_ctrl_data_in_vld;
    reg    csr_internal_field_aes_test_ctrl_cfg_key_iv_vld;
    reg    csr_internal_field_aes_test_ctrl_reuse_key;
    reg    [1:0] csr_internal_field_aes_test_ctrl_key_len;
    reg    csr_internal_field_aes_test_ctrl_dir;
    reg    [3:0] csr_internal_field_aes_test_ctrl_mode;
    reg    csr_internal_field_aes_test_status_tag_out;
    reg    csr_internal_field_aes_test_status_data_out_vld;
    reg    [11:0] csr_internal_field_encr_block_status_num_of_blocks_encr;

    wire   csr_internal_next_field_cmd_aes_test_en;
    wire   csr_internal_write_access_cmd_aes_test_en;
    wire   csr_internal_clear_cmd_aes_test_en;
    wire   csr_internal_next_field_cmd_disable_reinit;
    wire   csr_internal_write_access_cmd_disable_reinit;
    wire   csr_internal_clear_cmd_disable_reinit;
    wire   csr_internal_next_field_cmd_disable_reset;
    wire   csr_internal_write_access_cmd_disable_reset;
    wire   csr_internal_clear_cmd_disable_reset;
    wire   csr_internal_next_field_cmd_encr_block;
    wire   csr_internal_write_access_cmd_encr_block;
    wire   csr_internal_clear_cmd_encr_block;
    wire   csr_internal_next_field_cmd_sinc_reinit;
    wire   csr_internal_write_access_cmd_sinc_reinit;
    wire   csr_internal_clear_cmd_sinc_reinit;
    wire   csr_internal_next_field_cmd_sinc_reset;
    wire   csr_internal_write_access_cmd_sinc_reset;
    wire   csr_internal_clear_cmd_sinc_reset;
    wire   csr_internal_next_field_cmd_set_cache_active_state;
    wire   csr_internal_write_access_cmd_set_cache_active_state;
    wire   csr_internal_clear_cmd_set_cache_active_state;
    wire   csr_internal_next_field_cmd_set_init_state;
    wire   csr_internal_write_access_cmd_set_init_state;
    wire   csr_internal_clear_cmd_set_init_state;
    wire   csr_internal_decode_cmd;
    wire   csr_internal_access_error_cmd;
    wire   csr_internal_write_access_cmd;
    wire   csr_internal_next_written_cmd;
    wire   [23:0] csr_internal_next_field_block_encr_num_block_encr_num;
    wire   csr_internal_write_access_block_encr_num_block_encr_num;
    wire   csr_internal_write_enable_block_encr_num_block_encr_num;
    wire   csr_internal_decode_block_encr_num;
    wire   [31:0] csr_internal_read_value_block_encr_num;
    wire   [31:0] csr_internal_read_bus_block_encr_num;
    wire   [11:0] csr_internal_next_field_num_of_blocks_num_of_blocks;
    wire   csr_internal_write_access_num_of_blocks_num_of_blocks;
    wire   csr_internal_write_enable_num_of_blocks_num_of_blocks;
    wire   csr_internal_decode_num_of_blocks;
    wire   [31:0] csr_internal_read_value_num_of_blocks;
    wire   [31:0] csr_internal_read_bus_num_of_blocks;
    wire   [31:0] csr_internal_next_field_block_encr_addr_block_encr_addr;
    wire   csr_internal_write_access_block_encr_addr_block_encr_addr;
    wire   csr_internal_write_enable_block_encr_addr_block_encr_addr;
    wire   csr_internal_decode_block_encr_addr;
    wire   [31:0] csr_internal_read_value_block_encr_addr;
    wire   [31:0] csr_internal_read_bus_block_encr_addr;
    wire   [15:0] csr_internal_next_field_block_encr_key_block_encr_key;
    wire   csr_internal_write_access_block_encr_key_block_encr_key;
    wire   csr_internal_write_enable_block_encr_key_block_encr_key;
    wire   csr_internal_decode_block_encr_key;
    wire   [31:0] csr_internal_read_value_block_encr_key;
    wire   [31:0] csr_internal_read_bus_block_encr_key;
    wire   csr_internal_decode_aes_iv_nonce_0;
    wire   csr_internal_bus_write_access_aes_iv_nonce_0;
    wire   [31:0] csr_internal_read_value_aes_iv_nonce_0;
    wire   [31:0] csr_internal_read_bus_aes_iv_nonce_0;
    wire   [31:0] csr_internal_bus_read_data_aes_iv_nonce_0;
    wire   csr_internal_write_access_aes_iv_nonce_0;
    wire   [31:0] csr_internal_bus_write_data_aes_iv_nonce_0;
    wire   csr_internal_decode_aes_iv_nonce_1;
    wire   csr_internal_bus_write_access_aes_iv_nonce_1;
    wire   [31:0] csr_internal_read_value_aes_iv_nonce_1;
    wire   [31:0] csr_internal_read_bus_aes_iv_nonce_1;
    wire   [31:0] csr_internal_bus_read_data_aes_iv_nonce_1;
    wire   csr_internal_write_access_aes_iv_nonce_1;
    wire   [31:0] csr_internal_bus_write_data_aes_iv_nonce_1;
    wire   csr_internal_decode_aes_iv_nonce_2;
    wire   csr_internal_bus_write_access_aes_iv_nonce_2;
    wire   [31:0] csr_internal_read_value_aes_iv_nonce_2;
    wire   [31:0] csr_internal_read_bus_aes_iv_nonce_2;
    wire   [31:0] csr_internal_bus_read_data_aes_iv_nonce_2;
    wire   csr_internal_write_access_aes_iv_nonce_2;
    wire   [31:0] csr_internal_bus_write_data_aes_iv_nonce_2;
    wire   csr_internal_decode_ext_block_base_addr;
    wire   csr_internal_bus_write_access_ext_block_base_addr;
    wire   [31:0] csr_internal_read_value_ext_block_base_addr;
    wire   [31:0] csr_internal_read_bus_ext_block_base_addr;
    wire   [31:0] csr_internal_bus_read_data_ext_block_base_addr;
    wire   csr_internal_write_access_ext_block_base_addr;
    wire   [31:0] csr_internal_bus_write_data_ext_block_base_addr;
    wire   csr_internal_decode_ext_auth_tag_base_addr;
    wire   csr_internal_bus_write_access_ext_auth_tag_base_addr;
    wire   [31:0] csr_internal_read_value_ext_auth_tag_base_addr;
    wire   [31:0] csr_internal_read_bus_ext_auth_tag_base_addr;
    wire   [31:0] csr_internal_bus_read_data_ext_auth_tag_base_addr;
    wire   csr_internal_write_access_ext_auth_tag_base_addr;
    wire   [31:0] csr_internal_bus_write_data_ext_auth_tag_base_addr;
    wire   csr_internal_next_field_status_sinc_hw_fault;
    wire   csr_internal_read_access_status_sinc_hw_fault;
    wire   csr_internal_read_effect_status_sinc_hw_fault;
    wire   csr_internal_input_status_sinc_hw_fault;
    wire   csr_internal_next_field_status_aes_err;
    wire   csr_internal_read_access_status_aes_err;
    wire   csr_internal_read_effect_status_aes_err;
    wire   csr_internal_input_status_aes_err;
    wire   csr_internal_next_field_status_auth_tag_w_err;
    wire   csr_internal_read_access_status_auth_tag_w_err;
    wire   csr_internal_read_effect_status_auth_tag_w_err;
    wire   csr_internal_input_status_auth_tag_w_err;
    wire   csr_internal_next_field_status_auth_tag_chk_err;
    wire   csr_internal_read_access_status_auth_tag_chk_err;
    wire   csr_internal_read_effect_status_auth_tag_chk_err;
    wire   csr_internal_input_status_auth_tag_chk_err;
    wire   csr_internal_next_field_status_auth_tag_r_err;
    wire   csr_internal_read_access_status_auth_tag_r_err;
    wire   csr_internal_read_effect_status_auth_tag_r_err;
    wire   csr_internal_input_status_auth_tag_r_err;
    wire   csr_internal_next_field_status_cache_block_w_err_fetch_block;
    wire   csr_internal_read_access_status_cache_block_w_err_fetch_block;
    wire   csr_internal_read_effect_status_cache_block_w_err_fetch_block;
    wire   csr_internal_input_status_cache_block_w_err_fetch_block;
    wire   csr_internal_next_field_status_cache_block_w_err_encr_block;
    wire   csr_internal_read_access_status_cache_block_w_err_encr_block;
    wire   csr_internal_read_effect_status_cache_block_w_err_encr_block;
    wire   csr_internal_input_status_cache_block_w_err_encr_block;
    wire   csr_internal_next_field_status_cache_block_r_err;
    wire   csr_internal_read_access_status_cache_block_r_err;
    wire   csr_internal_read_effect_status_cache_block_r_err;
    wire   csr_internal_input_status_cache_block_r_err;
    wire   csr_internal_next_field_status_key_fetch_err;
    wire   csr_internal_read_access_status_key_fetch_err;
    wire   csr_internal_read_effect_status_key_fetch_err;
    wire   csr_internal_input_status_key_fetch_err;
    wire   csr_internal_next_field_status_rng_seed_r_err;
    wire   csr_internal_read_access_status_rng_seed_r_err;
    wire   csr_internal_read_effect_status_rng_seed_r_err;
    wire   csr_internal_input_status_rng_seed_r_err;
    wire   csr_internal_next_field_status_invalid_cmd_err;
    wire   csr_internal_read_access_status_invalid_cmd_err;
    wire   csr_internal_read_effect_status_invalid_cmd_err;
    wire   csr_internal_input_status_invalid_cmd_err;
    wire   csr_internal_next_field_status_cmd_failed;
    wire   csr_internal_read_access_status_cmd_failed;
    wire   csr_internal_read_effect_status_cmd_failed;
    wire   csr_internal_input_status_cmd_failed;
    wire   csr_internal_next_field_status_cmd_success;
    wire   csr_internal_read_access_status_cmd_success;
    wire   csr_internal_read_effect_status_cmd_success;
    wire   csr_internal_input_status_cmd_success;
    wire   csr_internal_next_field_status_cmd_in_progress;
    wire   csr_internal_input_status_cmd_in_progress;
    wire   csr_internal_field_status_sinc_reinit_disabled;
    wire   csr_internal_input_status_sinc_reinit_disabled;
    wire   csr_internal_field_status_sinc_reset_disabled;
    wire   csr_internal_input_status_sinc_reset_disabled;
    wire   [7:0] csr_internal_field_status_state;
    wire   [7:0] csr_internal_input_status_state;
    wire   csr_internal_decode_status;
    wire   csr_internal_access_error_status;
    wire   [31:0] csr_internal_read_value_status;
    wire   [31:0] csr_internal_read_bus_status;
    wire   [31:0] csr_internal_field_hit_cntr_lower_hit_cntr_lower;
    wire   [31:0] csr_internal_input_hit_cntr_lower_hit_cntr_lower;
    wire   csr_internal_decode_hit_cntr_lower;
    wire   csr_internal_access_error_hit_cntr_lower;
    wire   [31:0] csr_internal_read_value_hit_cntr_lower;
    wire   [31:0] csr_internal_read_bus_hit_cntr_lower;
    wire   [15:0] csr_internal_field_hit_cntr_upper_hit_cntr_upper;
    wire   [15:0] csr_internal_input_hit_cntr_upper_hit_cntr_upper;
    wire   csr_internal_decode_hit_cntr_upper;
    wire   csr_internal_access_error_hit_cntr_upper;
    wire   [31:0] csr_internal_read_value_hit_cntr_upper;
    wire   [31:0] csr_internal_read_bus_hit_cntr_upper;
    wire   [31:0] csr_internal_field_miss_cntr_lower_miss_cntr_lower;
    wire   [31:0] csr_internal_input_miss_cntr_lower_miss_cntr_lower;
    wire   csr_internal_decode_miss_cntr_lower;
    wire   csr_internal_access_error_miss_cntr_lower;
    wire   [31:0] csr_internal_read_value_miss_cntr_lower;
    wire   [31:0] csr_internal_read_bus_miss_cntr_lower;
    wire   [15:0] csr_internal_field_miss_cntr_upper_miss_cntr_upper;
    wire   [15:0] csr_internal_input_miss_cntr_upper_miss_cntr_upper;
    wire   csr_internal_decode_miss_cntr_upper;
    wire   csr_internal_access_error_miss_cntr_upper;
    wire   [31:0] csr_internal_read_value_miss_cntr_upper;
    wire   [31:0] csr_internal_read_bus_miss_cntr_upper;
    wire   [31:0] csr_internal_field_lat_cntr_lower_lat_cntr_lower;
    wire   [31:0] csr_internal_input_lat_cntr_lower_lat_cntr_lower;
    wire   csr_internal_decode_lat_cntr_lower;
    wire   csr_internal_access_error_lat_cntr_lower;
    wire   [31:0] csr_internal_read_value_lat_cntr_lower;
    wire   [31:0] csr_internal_read_bus_lat_cntr_lower;
    wire   [15:0] csr_internal_field_lat_cntr_upper_lat_cntr_upper;
    wire   [15:0] csr_internal_input_lat_cntr_upper_lat_cntr_upper;
    wire   csr_internal_decode_lat_cntr_upper;
    wire   csr_internal_access_error_lat_cntr_upper;
    wire   [31:0] csr_internal_read_value_lat_cntr_upper;
    wire   [31:0] csr_internal_read_bus_lat_cntr_upper;
    wire   csr_internal_next_field_perf_cntr_ctrl_lat_cntr_clr;
    wire   csr_internal_write_access_perf_cntr_ctrl_lat_cntr_clr;
    wire   csr_internal_next_field_perf_cntr_ctrl_lat_cntr_en;
    wire   csr_internal_write_access_perf_cntr_ctrl_lat_cntr_en;
    wire   csr_internal_next_field_perf_cntr_ctrl_miss_cntr_clr;
    wire   csr_internal_write_access_perf_cntr_ctrl_miss_cntr_clr;
    wire   csr_internal_next_field_perf_cntr_ctrl_miss_cntr_en;
    wire   csr_internal_write_access_perf_cntr_ctrl_miss_cntr_en;
    wire   csr_internal_next_field_perf_cntr_ctrl_hit_cntr_clr;
    wire   csr_internal_write_access_perf_cntr_ctrl_hit_cntr_clr;
    wire   csr_internal_next_field_perf_cntr_ctrl_hit_cntr_en;
    wire   csr_internal_write_access_perf_cntr_ctrl_hit_cntr_en;
    wire   csr_internal_decode_perf_cntr_ctrl;
    wire   [31:0] csr_internal_read_value_perf_cntr_ctrl;
    wire   [31:0] csr_internal_read_bus_perf_cntr_ctrl;
    wire   csr_internal_write_access_perf_cntr_ctrl;
    wire   csr_internal_next_written_perf_cntr_ctrl;
    wire   [31:0] csr_internal_next_field_aes_test_data_in_0_aes_test_data_in_0;
    wire   csr_internal_write_access_aes_test_data_in_0_aes_test_data_in_0;
    wire   csr_internal_decode_aes_test_data_in_0;
    wire   [31:0] csr_internal_read_value_aes_test_data_in_0;
    wire   [31:0] csr_internal_read_bus_aes_test_data_in_0;
    wire   [31:0] csr_internal_next_field_aes_test_data_in_1_aes_test_data_in_1;
    wire   csr_internal_write_access_aes_test_data_in_1_aes_test_data_in_1;
    wire   csr_internal_decode_aes_test_data_in_1;
    wire   [31:0] csr_internal_read_value_aes_test_data_in_1;
    wire   [31:0] csr_internal_read_bus_aes_test_data_in_1;
    wire   [31:0] csr_internal_next_field_aes_test_data_in_2_aes_test_data_in_2;
    wire   csr_internal_write_access_aes_test_data_in_2_aes_test_data_in_2;
    wire   csr_internal_decode_aes_test_data_in_2;
    wire   [31:0] csr_internal_read_value_aes_test_data_in_2;
    wire   [31:0] csr_internal_read_bus_aes_test_data_in_2;
    wire   [31:0] csr_internal_next_field_aes_test_data_in_3_aes_test_data_in_3;
    wire   csr_internal_write_access_aes_test_data_in_3_aes_test_data_in_3;
    wire   csr_internal_decode_aes_test_data_in_3;
    wire   [31:0] csr_internal_read_value_aes_test_data_in_3;
    wire   [31:0] csr_internal_read_bus_aes_test_data_in_3;
    wire   [31:0] csr_internal_next_field_aes_test_data_out_0_aes_test_data_out_0;
    wire   csr_internal_clear_aes_test_data_out_0_aes_test_data_out_0;
    wire   [31:0] csr_internal_input_aes_test_data_out_0_aes_test_data_out_0;
    wire   csr_internal_decode_aes_test_data_out_0;
    wire   csr_internal_access_error_aes_test_data_out_0;
    wire   [31:0] csr_internal_read_value_aes_test_data_out_0;
    wire   [31:0] csr_internal_read_bus_aes_test_data_out_0;
    wire   [31:0] csr_internal_next_field_aes_test_data_out_1_aes_test_data_out_1;
    wire   csr_internal_clear_aes_test_data_out_1_aes_test_data_out_1;
    wire   [31:0] csr_internal_input_aes_test_data_out_1_aes_test_data_out_1;
    wire   csr_internal_decode_aes_test_data_out_1;
    wire   csr_internal_access_error_aes_test_data_out_1;
    wire   [31:0] csr_internal_read_value_aes_test_data_out_1;
    wire   [31:0] csr_internal_read_bus_aes_test_data_out_1;
    wire   [31:0] csr_internal_next_field_aes_test_data_out_2_aes_test_data_out_2;
    wire   csr_internal_clear_aes_test_data_out_2_aes_test_data_out_2;
    wire   [31:0] csr_internal_input_aes_test_data_out_2_aes_test_data_out_2;
    wire   csr_internal_decode_aes_test_data_out_2;
    wire   csr_internal_access_error_aes_test_data_out_2;
    wire   [31:0] csr_internal_read_value_aes_test_data_out_2;
    wire   [31:0] csr_internal_read_bus_aes_test_data_out_2;
    wire   [31:0] csr_internal_next_field_aes_test_data_out_3_aes_test_data_out_3;
    wire   csr_internal_clear_aes_test_data_out_3_aes_test_data_out_3;
    wire   [31:0] csr_internal_input_aes_test_data_out_3_aes_test_data_out_3;
    wire   csr_internal_decode_aes_test_data_out_3;
    wire   csr_internal_access_error_aes_test_data_out_3;
    wire   [31:0] csr_internal_read_value_aes_test_data_out_3;
    wire   [31:0] csr_internal_read_bus_aes_test_data_out_3;
    wire   csr_internal_next_field_aes_test_ctrl_data_out_ack;
    wire   csr_internal_write_access_aes_test_ctrl_data_out_ack;
    wire   csr_internal_write_enable_aes_test_ctrl_data_out_ack;
    wire   csr_internal_clear_aes_test_ctrl_data_out_ack;
    wire   csr_internal_next_field_aes_test_ctrl_data_in_aad_sel;
    wire   csr_internal_write_access_aes_test_ctrl_data_in_aad_sel;
    wire   csr_internal_write_enable_aes_test_ctrl_data_in_aad_sel;
    wire   csr_internal_next_field_aes_test_ctrl_data_in_last;
    wire   csr_internal_write_access_aes_test_ctrl_data_in_last;
    wire   csr_internal_write_enable_aes_test_ctrl_data_in_last;
    wire   [4:0] csr_internal_next_field_aes_test_ctrl_data_in_byte_cnt;
    wire   csr_internal_write_access_aes_test_ctrl_data_in_byte_cnt;
    wire   csr_internal_write_enable_aes_test_ctrl_data_in_byte_cnt;
    wire   csr_internal_next_field_aes_test_ctrl_data_in_vld;
    wire   csr_internal_write_access_aes_test_ctrl_data_in_vld;
    wire   csr_internal_write_enable_aes_test_ctrl_data_in_vld;
    wire   csr_internal_input_aes_test_ctrl_data_in_vld;
    wire   csr_internal_next_field_aes_test_ctrl_cfg_key_iv_vld;
    wire   csr_internal_write_access_aes_test_ctrl_cfg_key_iv_vld;
    wire   csr_internal_write_enable_aes_test_ctrl_cfg_key_iv_vld;
    wire   csr_internal_input_aes_test_ctrl_cfg_key_iv_vld;
    wire   csr_internal_next_field_aes_test_ctrl_reuse_key;
    wire   csr_internal_write_access_aes_test_ctrl_reuse_key;
    wire   csr_internal_write_enable_aes_test_ctrl_reuse_key;
    wire   [1:0] csr_internal_next_field_aes_test_ctrl_key_len;
    wire   csr_internal_write_access_aes_test_ctrl_key_len;
    wire   csr_internal_write_enable_aes_test_ctrl_key_len;
    wire   csr_internal_next_field_aes_test_ctrl_dir;
    wire   csr_internal_write_access_aes_test_ctrl_dir;
    wire   csr_internal_write_enable_aes_test_ctrl_dir;
    wire   [3:0] csr_internal_next_field_aes_test_ctrl_mode;
    wire   csr_internal_write_access_aes_test_ctrl_mode;
    wire   csr_internal_write_enable_aes_test_ctrl_mode;
    wire   csr_internal_decode_aes_test_ctrl;
    wire   [31:0] csr_internal_read_value_aes_test_ctrl;
    wire   [31:0] csr_internal_read_bus_aes_test_ctrl;
    wire   csr_internal_next_field_aes_test_status_tag_out;
    wire   csr_internal_clear_aes_test_status_tag_out;
    wire   csr_internal_input_aes_test_status_tag_out;
    wire   csr_internal_next_field_aes_test_status_data_out_vld;
    wire   csr_internal_clear_aes_test_status_data_out_vld;
    wire   csr_internal_input_aes_test_status_data_out_vld;
    wire   csr_internal_field_aes_test_status_data_in_rdy;
    wire   csr_internal_input_aes_test_status_data_in_rdy;
    wire   csr_internal_field_aes_test_status_cfg_key_iv_rdy;
    wire   csr_internal_input_aes_test_status_cfg_key_iv_rdy;
    wire   csr_internal_decode_aes_test_status;
    wire   csr_internal_access_error_aes_test_status;
    wire   [31:0] csr_internal_read_value_aes_test_status;
    wire   [31:0] csr_internal_read_bus_aes_test_status;
    wire   [11:0] csr_internal_next_field_encr_block_status_num_of_blocks_encr;
    wire   csr_internal_read_access_encr_block_status_num_of_blocks_encr;
    wire   [11:0] csr_internal_read_effect_encr_block_status_num_of_blocks_encr;
    wire   [11:0] csr_internal_input_encr_block_status_num_of_blocks_encr;
    wire   csr_internal_decode_encr_block_status;
    wire   csr_internal_access_error_encr_block_status;
    wire   [31:0] csr_internal_read_value_encr_block_status;
    wire   [31:0] csr_internal_read_bus_encr_block_status;
    wire   csr_internal_bus_write_access;
    wire   csr_internal_bus_read_access;
    wire   csr_internal_bus_ready;
    wire   csr_internal_bus_error;
    wire   csr_internal_error;
    wire   csr_internal_valid_address;
    wire   [9:0] csr_internal_bus_address;
    wire   [31:0] csr_internal_bus_read_data;
    wire   [31:0] csr_internal_read_data;
    wire   csr_internal_read_access;
    wire   [31:0] csr_internal_bus_write_data;
    wire   csr_internal_write_access;

    //   Bus Protocol: basic
    //   Bus Address Units: bytes

    assign csr_internal_bus_address = csr_addr;
    assign csr_internal_bus_write_access = csr_wr_en;
    assign csr_internal_bus_write_data = csr_wdata;
    assign csr_internal_bus_read_access = csr_rd_en;

    assign csr_rdy = csr_internal_bus_ready;

    assign csr_err = csr_internal_bus_error;

    assign csr_rdata = csr_internal_bus_read_data;

    assign csr_internal_read_access =
        csr_internal_bus_read_access;

    assign csr_internal_bus_read_data =
        (csr_internal_read_access) ?
            csr_internal_read_data:
            32'b0;

    assign csr_internal_write_access =
        csr_internal_bus_write_access;

    assign csr_internal_bus_ready =
        (csr_internal_bus_read_access | csr_internal_bus_write_access);

    assign csr_internal_bus_error =
        (csr_internal_bus_read_access | csr_internal_bus_write_access) &
        csr_internal_error;

    // Address Decode
    assign csr_internal_decode_cmd =
        (csr_internal_bus_address[9:0] == 10'h0);
    assign csr_internal_decode_block_encr_num =
        (csr_internal_bus_address[9:0] == 10'h4);
    assign csr_internal_decode_num_of_blocks =
        (csr_internal_bus_address[9:0] == 10'h8);
    assign csr_internal_decode_block_encr_addr =
        (csr_internal_bus_address[9:0] == 10'hc);
    assign csr_internal_decode_block_encr_key =
        (csr_internal_bus_address[9:0] == 10'h10);
    assign csr_internal_decode_aes_iv_nonce_0 =
        (csr_internal_bus_address[9:0] == 10'h14);
    assign csr_internal_decode_aes_iv_nonce_1 =
        (csr_internal_bus_address[9:0] == 10'h18);
    assign csr_internal_decode_aes_iv_nonce_2 =
        (csr_internal_bus_address[9:0] == 10'h1c);
    assign csr_internal_decode_ext_block_base_addr =
        (csr_internal_bus_address[9:0] == 10'h20);
    assign csr_internal_decode_ext_auth_tag_base_addr =
        (csr_internal_bus_address[9:0] == 10'h24);
    assign csr_internal_decode_status =
        (csr_internal_bus_address[9:0] == 10'h28);
    assign csr_internal_decode_hit_cntr_lower =
        (csr_internal_bus_address[9:0] == 10'h2c);
    assign csr_internal_decode_hit_cntr_upper =
        (csr_internal_bus_address[9:0] == 10'h30);
    assign csr_internal_decode_miss_cntr_lower =
        (csr_internal_bus_address[9:0] == 10'h34);
    assign csr_internal_decode_miss_cntr_upper =
        (csr_internal_bus_address[9:0] == 10'h38);
    assign csr_internal_decode_lat_cntr_lower =
        (csr_internal_bus_address[9:0] == 10'h3c);
    assign csr_internal_decode_lat_cntr_upper =
        (csr_internal_bus_address[9:0] == 10'h40);
    assign csr_internal_decode_perf_cntr_ctrl =
        (csr_internal_bus_address[9:0] == 10'h44);
    assign csr_internal_decode_aes_test_data_in_0 =
        (csr_internal_bus_address[9:0] == 10'h48);
    assign csr_internal_decode_aes_test_data_in_1 =
        (csr_internal_bus_address[9:0] == 10'h4c);
    assign csr_internal_decode_aes_test_data_in_2 =
        (csr_internal_bus_address[9:0] == 10'h50);
    assign csr_internal_decode_aes_test_data_in_3 =
        (csr_internal_bus_address[9:0] == 10'h54);
    assign csr_internal_decode_aes_test_data_out_0 =
        (csr_internal_bus_address[9:0] == 10'h58);
    assign csr_internal_decode_aes_test_data_out_1 =
        (csr_internal_bus_address[9:0] == 10'h5c);
    assign csr_internal_decode_aes_test_data_out_2 =
        (csr_internal_bus_address[9:0] == 10'h60);
    assign csr_internal_decode_aes_test_data_out_3 =
        (csr_internal_bus_address[9:0] == 10'h64);
    assign csr_internal_decode_aes_test_ctrl =
        (csr_internal_bus_address[9:0] == 10'h68);
    assign csr_internal_decode_aes_test_status =
        (csr_internal_bus_address[9:0] == 10'h6c);
    assign csr_internal_decode_encr_block_status =
        (csr_internal_bus_address[9:0] == 10'h70);

    assign csr_internal_valid_address =
        csr_internal_decode_cmd |
        csr_internal_decode_block_encr_num |
        csr_internal_decode_num_of_blocks |
        csr_internal_decode_block_encr_addr |
        csr_internal_decode_block_encr_key |
        csr_internal_decode_aes_iv_nonce_0 |
        csr_internal_decode_aes_iv_nonce_1 |
        csr_internal_decode_aes_iv_nonce_2 |
        csr_internal_decode_ext_block_base_addr |
        csr_internal_decode_ext_auth_tag_base_addr |
        csr_internal_decode_status |
        csr_internal_decode_hit_cntr_lower |
        csr_internal_decode_hit_cntr_upper |
        csr_internal_decode_miss_cntr_lower |
        csr_internal_decode_miss_cntr_upper |
        csr_internal_decode_lat_cntr_lower |
        csr_internal_decode_lat_cntr_upper |
        csr_internal_decode_perf_cntr_ctrl |
        csr_internal_decode_aes_test_data_in_0 |
        csr_internal_decode_aes_test_data_in_1 |
        csr_internal_decode_aes_test_data_in_2 |
        csr_internal_decode_aes_test_data_in_3 |
        csr_internal_decode_aes_test_data_out_0 |
        csr_internal_decode_aes_test_data_out_1 |
        csr_internal_decode_aes_test_data_out_2 |
        csr_internal_decode_aes_test_data_out_3 |
        csr_internal_decode_aes_test_ctrl |
        csr_internal_decode_aes_test_status |
        csr_internal_decode_encr_block_status;


    //
    // Register: cmd
    // Addressmap Byte Offset: 0x0
    // Access: write-only
    //
    assign csr_internal_write_access_cmd =
        csr_internal_decode_cmd &
        csr_internal_write_access;

    assign cmd = 
        {
            csr_internal_field_cmd_aes_test_en,
            csr_internal_field_cmd_disable_reinit,
            csr_internal_field_cmd_disable_reset,
            csr_internal_field_cmd_encr_block,
            csr_internal_field_cmd_sinc_reinit,
            csr_internal_field_cmd_sinc_reset,
            csr_internal_field_cmd_set_cache_active_state,
            csr_internal_field_cmd_set_init_state
        };

    assign csr_internal_next_written_cmd =
        csr_internal_write_access_cmd;

    always_ff @(posedge clock)
        csr_internal_written_cmd <=
            csr_internal_next_written_cmd;

    assign cmd_written =
        csr_internal_written_cmd;

    assign csr_internal_access_error_cmd =
        csr_internal_decode_cmd &
        csr_internal_read_access;

        // Field: cmd.aes_test_en
        // Position: [7]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_aes_test_en =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_aes_test_en =
            cmd_aes_test_en_clear;

        assign csr_internal_next_field_cmd_aes_test_en =
            (csr_internal_write_access_cmd_aes_test_en) ?
                csr_internal_bus_write_data[7]:
                (csr_internal_clear_cmd_aes_test_en) ?
                    1'b0:
                    csr_internal_field_cmd_aes_test_en;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_aes_test_en <=
                    1'h0;
            else
                csr_internal_field_cmd_aes_test_en <=
                    csr_internal_next_field_cmd_aes_test_en;

        // Field: cmd.disable_reinit
        // Position: [6]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_disable_reinit =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_disable_reinit =
            cmd_disable_reinit_clear;

        assign csr_internal_next_field_cmd_disable_reinit =
            (csr_internal_write_access_cmd_disable_reinit) ?
                csr_internal_bus_write_data[6]:
                (csr_internal_clear_cmd_disable_reinit) ?
                    1'b0:
                    csr_internal_field_cmd_disable_reinit;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_disable_reinit <=
                    1'h0;
            else
                csr_internal_field_cmd_disable_reinit <=
                    csr_internal_next_field_cmd_disable_reinit;

        // Field: cmd.disable_reset
        // Position: [5]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_disable_reset =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_disable_reset =
            cmd_disable_reset_clear;

        assign csr_internal_next_field_cmd_disable_reset =
            (csr_internal_write_access_cmd_disable_reset) ?
                csr_internal_bus_write_data[5]:
                (csr_internal_clear_cmd_disable_reset) ?
                    1'b0:
                    csr_internal_field_cmd_disable_reset;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_disable_reset <=
                    1'h0;
            else
                csr_internal_field_cmd_disable_reset <=
                    csr_internal_next_field_cmd_disable_reset;

        // Field: cmd.encr_block
        // Position: [4]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_encr_block =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_encr_block =
            cmd_encr_block_clear;

        assign csr_internal_next_field_cmd_encr_block =
            (csr_internal_write_access_cmd_encr_block) ?
                csr_internal_bus_write_data[4]:
                (csr_internal_clear_cmd_encr_block) ?
                    1'b0:
                    csr_internal_field_cmd_encr_block;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_encr_block <=
                    1'h0;
            else
                csr_internal_field_cmd_encr_block <=
                    csr_internal_next_field_cmd_encr_block;

        // Field: cmd.sinc_reinit
        // Position: [3]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_sinc_reinit =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_sinc_reinit =
            cmd_sinc_reinit_clear;

        assign csr_internal_next_field_cmd_sinc_reinit =
            (csr_internal_write_access_cmd_sinc_reinit) ?
                csr_internal_bus_write_data[3]:
                (csr_internal_clear_cmd_sinc_reinit) ?
                    1'b0:
                    csr_internal_field_cmd_sinc_reinit;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_sinc_reinit <=
                    1'h0;
            else
                csr_internal_field_cmd_sinc_reinit <=
                    csr_internal_next_field_cmd_sinc_reinit;

        // Field: cmd.sinc_reset
        // Position: [2]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_sinc_reset =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_sinc_reset =
            cmd_sinc_reset_clear;

        assign csr_internal_next_field_cmd_sinc_reset =
            (csr_internal_write_access_cmd_sinc_reset) ?
                csr_internal_bus_write_data[2]:
                (csr_internal_clear_cmd_sinc_reset) ?
                    1'b0:
                    csr_internal_field_cmd_sinc_reset;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_sinc_reset <=
                    1'h0;
            else
                csr_internal_field_cmd_sinc_reset <=
                    csr_internal_next_field_cmd_sinc_reset;

        // Field: cmd.set_cache_active_state
        // Position: [1]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_set_cache_active_state =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_set_cache_active_state =
            cmd_set_cache_active_state_clear;

        assign csr_internal_next_field_cmd_set_cache_active_state =
            (csr_internal_write_access_cmd_set_cache_active_state) ?
                csr_internal_bus_write_data[1]:
                (csr_internal_clear_cmd_set_cache_active_state) ?
                    1'b0:
                    csr_internal_field_cmd_set_cache_active_state;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_set_cache_active_state <=
                    1'h0;
            else
                csr_internal_field_cmd_set_cache_active_state <=
                    csr_internal_next_field_cmd_set_cache_active_state;

        // Field: cmd.set_init_state
        // Position: [0]
        // Access: write-only
        // Type: configuration
        // Clear
        assign csr_internal_write_access_cmd_set_init_state =
            csr_internal_decode_cmd &
            csr_internal_write_access;

        assign csr_internal_clear_cmd_set_init_state =
            cmd_set_init_state_clear;

        assign csr_internal_next_field_cmd_set_init_state =
            (csr_internal_write_access_cmd_set_init_state) ?
                csr_internal_bus_write_data[0]:
                (csr_internal_clear_cmd_set_init_state) ?
                    1'b0:
                    csr_internal_field_cmd_set_init_state;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_cmd_set_init_state <=
                    1'h0;
            else
                csr_internal_field_cmd_set_init_state <=
                    csr_internal_next_field_cmd_set_init_state;


    //
    // Register: block_encr_num
    // Addressmap Byte Offset: 0x4
    // Access: read-write
    //
    assign csr_internal_read_value_block_encr_num =
        {
            8'h0,
            csr_internal_field_block_encr_num_block_encr_num
        };
    assign csr_internal_read_bus_block_encr_num =
        csr_internal_read_value_block_encr_num &
        {32{csr_internal_decode_block_encr_num}};

    assign block_encr_num = 
        csr_internal_field_block_encr_num_block_encr_num;

        // Field: block_encr_num.block_encr_num
        // Position: [23:0]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_block_encr_num_block_encr_num =
            csr_internal_decode_block_encr_num &
            csr_internal_write_enable_block_encr_num_block_encr_num &
            csr_internal_write_access;

        assign csr_internal_write_enable_block_encr_num_block_encr_num =
            block_encr_num_block_encr_num_write_enable;

        assign csr_internal_next_field_block_encr_num_block_encr_num =
            (csr_internal_write_access_block_encr_num_block_encr_num) ?
                csr_internal_bus_write_data[23:0]:
                csr_internal_field_block_encr_num_block_encr_num;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_block_encr_num_block_encr_num <=
                    24'h0;
            else
                csr_internal_field_block_encr_num_block_encr_num <=
                    csr_internal_next_field_block_encr_num_block_encr_num;


    //
    // Register: num_of_blocks
    // Addressmap Byte Offset: 0x8
    // Access: read-write
    //
    assign csr_internal_read_value_num_of_blocks =
        {
            20'h0,
            csr_internal_field_num_of_blocks_num_of_blocks
        };
    assign csr_internal_read_bus_num_of_blocks =
        csr_internal_read_value_num_of_blocks &
        {32{csr_internal_decode_num_of_blocks}};

    assign num_of_blocks = 
        csr_internal_field_num_of_blocks_num_of_blocks;

        // Field: num_of_blocks.num_of_blocks
        // Position: [11:0]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_num_of_blocks_num_of_blocks =
            csr_internal_decode_num_of_blocks &
            csr_internal_write_enable_num_of_blocks_num_of_blocks &
            csr_internal_write_access;

        assign csr_internal_write_enable_num_of_blocks_num_of_blocks =
            num_of_blocks_num_of_blocks_write_enable;

        assign csr_internal_next_field_num_of_blocks_num_of_blocks =
            (csr_internal_write_access_num_of_blocks_num_of_blocks) ?
                csr_internal_bus_write_data[11:0]:
                csr_internal_field_num_of_blocks_num_of_blocks;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_num_of_blocks_num_of_blocks <=
                    12'h0;
            else
                csr_internal_field_num_of_blocks_num_of_blocks <=
                    csr_internal_next_field_num_of_blocks_num_of_blocks;


    //
    // Register: block_encr_addr
    // Addressmap Byte Offset: 0xc
    // Access: read-write
    //
    assign csr_internal_read_value_block_encr_addr =
        csr_internal_field_block_encr_addr_block_encr_addr;
    assign csr_internal_read_bus_block_encr_addr =
        csr_internal_read_value_block_encr_addr &
        {32{csr_internal_decode_block_encr_addr}};

    assign block_encr_addr = 
        csr_internal_field_block_encr_addr_block_encr_addr;

        // Field: block_encr_addr.block_encr_addr
        // Position: [31:0]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_block_encr_addr_block_encr_addr =
            csr_internal_decode_block_encr_addr &
            csr_internal_write_enable_block_encr_addr_block_encr_addr &
            csr_internal_write_access;

        assign csr_internal_write_enable_block_encr_addr_block_encr_addr =
            block_encr_addr_block_encr_addr_write_enable;

        assign csr_internal_next_field_block_encr_addr_block_encr_addr =
            (csr_internal_write_access_block_encr_addr_block_encr_addr) ?
                csr_internal_bus_write_data:
                csr_internal_field_block_encr_addr_block_encr_addr;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_block_encr_addr_block_encr_addr <=
                    32'h0;
            else
                csr_internal_field_block_encr_addr_block_encr_addr <=
                    csr_internal_next_field_block_encr_addr_block_encr_addr;


    //
    // Register: block_encr_key
    // Addressmap Byte Offset: 0x10
    // Access: read-write
    //
    assign csr_internal_read_value_block_encr_key =
        {
            16'h0,
            csr_internal_field_block_encr_key_block_encr_key
        };
    assign csr_internal_read_bus_block_encr_key =
        csr_internal_read_value_block_encr_key &
        {32{csr_internal_decode_block_encr_key}};

    assign block_encr_key = 
        csr_internal_field_block_encr_key_block_encr_key;

        // Field: block_encr_key.block_encr_key
        // Position: [15:0]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_block_encr_key_block_encr_key =
            csr_internal_decode_block_encr_key &
            csr_internal_write_enable_block_encr_key_block_encr_key &
            csr_internal_write_access;

        assign csr_internal_write_enable_block_encr_key_block_encr_key =
            block_encr_key_block_encr_key_write_enable;

        assign csr_internal_next_field_block_encr_key_block_encr_key =
            (csr_internal_write_access_block_encr_key_block_encr_key) ?
                csr_internal_bus_write_data[15:0]:
                csr_internal_field_block_encr_key_block_encr_key;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_block_encr_key_block_encr_key <=
                    16'h0;
            else
                csr_internal_field_block_encr_key_block_encr_key <=
                    csr_internal_next_field_block_encr_key_block_encr_key;


    //
    // External Register: aes_iv_nonce_0
    // Addressmap Byte Offset: 0x14
    // Access: read-write
    // Bus Protocol: basic
    //
    assign csr_internal_read_value_aes_iv_nonce_0 =
        csr_internal_bus_read_data_aes_iv_nonce_0;
    assign csr_internal_read_bus_aes_iv_nonce_0 =
        csr_internal_read_value_aes_iv_nonce_0 &
        {32{csr_internal_decode_aes_iv_nonce_0}};
    assign csr_internal_write_access_aes_iv_nonce_0 =
        csr_internal_decode_aes_iv_nonce_0 &
        csr_internal_write_access;

    assign aes_iv_nonce_0_write_access =
        csr_internal_bus_write_access_aes_iv_nonce_0;
    assign aes_iv_nonce_0_write_data =
        csr_internal_bus_write_data_aes_iv_nonce_0;
    assign csr_internal_bus_read_data_aes_iv_nonce_0 =
        aes_iv_nonce_0_read_data;

    assign csr_internal_bus_write_access_aes_iv_nonce_0 =
        csr_internal_write_access_aes_iv_nonce_0;
    assign csr_internal_bus_write_data_aes_iv_nonce_0 =
        csr_internal_bus_write_data;

    //
    // External Register: aes_iv_nonce_1
    // Addressmap Byte Offset: 0x18
    // Access: read-write
    // Bus Protocol: basic
    //
    assign csr_internal_read_value_aes_iv_nonce_1 =
        csr_internal_bus_read_data_aes_iv_nonce_1;
    assign csr_internal_read_bus_aes_iv_nonce_1 =
        csr_internal_read_value_aes_iv_nonce_1 &
        {32{csr_internal_decode_aes_iv_nonce_1}};
    assign csr_internal_write_access_aes_iv_nonce_1 =
        csr_internal_decode_aes_iv_nonce_1 &
        csr_internal_write_access;

    assign aes_iv_nonce_1_write_access =
        csr_internal_bus_write_access_aes_iv_nonce_1;
    assign aes_iv_nonce_1_write_data =
        csr_internal_bus_write_data_aes_iv_nonce_1;
    assign csr_internal_bus_read_data_aes_iv_nonce_1 =
        aes_iv_nonce_1_read_data;

    assign csr_internal_bus_write_access_aes_iv_nonce_1 =
        csr_internal_write_access_aes_iv_nonce_1;
    assign csr_internal_bus_write_data_aes_iv_nonce_1 =
        csr_internal_bus_write_data;

    //
    // External Register: aes_iv_nonce_2
    // Addressmap Byte Offset: 0x1c
    // Access: read-write
    // Bus Protocol: basic
    //
    assign csr_internal_read_value_aes_iv_nonce_2 =
        csr_internal_bus_read_data_aes_iv_nonce_2;
    assign csr_internal_read_bus_aes_iv_nonce_2 =
        csr_internal_read_value_aes_iv_nonce_2 &
        {32{csr_internal_decode_aes_iv_nonce_2}};
    assign csr_internal_write_access_aes_iv_nonce_2 =
        csr_internal_decode_aes_iv_nonce_2 &
        csr_internal_write_access;

    assign aes_iv_nonce_2_write_access =
        csr_internal_bus_write_access_aes_iv_nonce_2;
    assign aes_iv_nonce_2_write_data =
        csr_internal_bus_write_data_aes_iv_nonce_2;
    assign csr_internal_bus_read_data_aes_iv_nonce_2 =
        aes_iv_nonce_2_read_data;

    assign csr_internal_bus_write_access_aes_iv_nonce_2 =
        csr_internal_write_access_aes_iv_nonce_2;
    assign csr_internal_bus_write_data_aes_iv_nonce_2 =
        csr_internal_bus_write_data;

    //
    // External Register: ext_block_base_addr
    // Addressmap Byte Offset: 0x20
    // Access: read-write
    // Bus Protocol: basic
    //
    assign csr_internal_read_value_ext_block_base_addr =
        csr_internal_bus_read_data_ext_block_base_addr;
    assign csr_internal_read_bus_ext_block_base_addr =
        csr_internal_read_value_ext_block_base_addr &
        {32{csr_internal_decode_ext_block_base_addr}};
    assign csr_internal_write_access_ext_block_base_addr =
        csr_internal_decode_ext_block_base_addr &
        csr_internal_write_access;

    assign ext_block_base_addr_write_access =
        csr_internal_bus_write_access_ext_block_base_addr;
    assign ext_block_base_addr_write_data =
        csr_internal_bus_write_data_ext_block_base_addr;
    assign csr_internal_bus_read_data_ext_block_base_addr =
        ext_block_base_addr_read_data;

    assign csr_internal_bus_write_access_ext_block_base_addr =
        csr_internal_write_access_ext_block_base_addr;
    assign csr_internal_bus_write_data_ext_block_base_addr =
        csr_internal_bus_write_data;

    //
    // External Register: ext_auth_tag_base_addr
    // Addressmap Byte Offset: 0x24
    // Access: read-write
    // Bus Protocol: basic
    //
    assign csr_internal_read_value_ext_auth_tag_base_addr =
        csr_internal_bus_read_data_ext_auth_tag_base_addr;
    assign csr_internal_read_bus_ext_auth_tag_base_addr =
        csr_internal_read_value_ext_auth_tag_base_addr &
        {32{csr_internal_decode_ext_auth_tag_base_addr}};
    assign csr_internal_write_access_ext_auth_tag_base_addr =
        csr_internal_decode_ext_auth_tag_base_addr &
        csr_internal_write_access;

    assign ext_auth_tag_base_addr_write_access =
        csr_internal_bus_write_access_ext_auth_tag_base_addr;
    assign ext_auth_tag_base_addr_write_data =
        csr_internal_bus_write_data_ext_auth_tag_base_addr;
    assign csr_internal_bus_read_data_ext_auth_tag_base_addr =
        ext_auth_tag_base_addr_read_data;

    assign csr_internal_bus_write_access_ext_auth_tag_base_addr =
        csr_internal_write_access_ext_auth_tag_base_addr;
    assign csr_internal_bus_write_data_ext_auth_tag_base_addr =
        csr_internal_bus_write_data;

    //
    // Register: status
    // Addressmap Byte Offset: 0x28
    // Access: read-only
    //
    assign csr_internal_read_value_status =
        {
            8'h0,
            csr_internal_field_status_sinc_hw_fault,
            csr_internal_field_status_aes_err,
            csr_internal_field_status_auth_tag_w_err,
            csr_internal_field_status_auth_tag_chk_err,
            csr_internal_field_status_auth_tag_r_err,
            csr_internal_field_status_cache_block_w_err_fetch_block,
            csr_internal_field_status_cache_block_w_err_encr_block,
            csr_internal_field_status_cache_block_r_err,
            csr_internal_field_status_key_fetch_err,
            csr_internal_field_status_rng_seed_r_err,
            csr_internal_field_status_invalid_cmd_err,
            csr_internal_field_status_cmd_failed,
            csr_internal_field_status_cmd_success,
            csr_internal_field_status_cmd_in_progress,
            csr_internal_field_status_sinc_reinit_disabled,
            csr_internal_field_status_sinc_reset_disabled,
            csr_internal_field_status_state
        };
    assign csr_internal_read_bus_status =
        csr_internal_read_value_status &
        {32{csr_internal_decode_status}};

    assign status = 
        {
            csr_internal_field_status_sinc_hw_fault,
            csr_internal_field_status_aes_err,
            csr_internal_field_status_auth_tag_w_err,
            csr_internal_field_status_auth_tag_chk_err,
            csr_internal_field_status_auth_tag_r_err,
            csr_internal_field_status_cache_block_w_err_fetch_block,
            csr_internal_field_status_cache_block_w_err_encr_block,
            csr_internal_field_status_cache_block_r_err,
            csr_internal_field_status_key_fetch_err,
            csr_internal_field_status_rng_seed_r_err,
            csr_internal_field_status_invalid_cmd_err,
            csr_internal_field_status_cmd_failed,
            csr_internal_field_status_cmd_success,
            csr_internal_field_status_cmd_in_progress,
            csr_internal_field_status_sinc_reinit_disabled,
            csr_internal_field_status_sinc_reset_disabled,
            csr_internal_field_status_state
        };

    assign csr_internal_access_error_status =
        csr_internal_decode_status &
        csr_internal_write_access;

        // Field: status.sinc_hw_fault
        // Position: [23]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_sinc_hw_fault =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_sinc_hw_fault =
            status_sinc_hw_fault_input;

        assign csr_internal_next_field_status_sinc_hw_fault =
            (status_sinc_hw_fault_load_enable) ?
                csr_internal_input_status_sinc_hw_fault:
                csr_internal_read_effect_status_sinc_hw_fault;

        assign csr_internal_read_effect_status_sinc_hw_fault =
            (csr_internal_read_access_status_sinc_hw_fault) ?
                1'b0:
                csr_internal_field_status_sinc_hw_fault;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_sinc_hw_fault <=
                    1'h0;
            else
                csr_internal_field_status_sinc_hw_fault <=
                    csr_internal_next_field_status_sinc_hw_fault;

        // Field: status.aes_err
        // Position: [22]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_aes_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_aes_err =
            status_aes_err_input;

        assign csr_internal_next_field_status_aes_err =
            (status_aes_err_load_enable) ?
                csr_internal_input_status_aes_err:
                csr_internal_read_effect_status_aes_err;

        assign csr_internal_read_effect_status_aes_err =
            (csr_internal_read_access_status_aes_err) ?
                1'b0:
                csr_internal_field_status_aes_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_aes_err <=
                    1'h0;
            else
                csr_internal_field_status_aes_err <=
                    csr_internal_next_field_status_aes_err;

        // Field: status.auth_tag_w_err
        // Position: [21]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_auth_tag_w_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_auth_tag_w_err =
            status_auth_tag_w_err_input;

        assign csr_internal_next_field_status_auth_tag_w_err =
            (status_auth_tag_w_err_load_enable) ?
                csr_internal_input_status_auth_tag_w_err:
                csr_internal_read_effect_status_auth_tag_w_err;

        assign csr_internal_read_effect_status_auth_tag_w_err =
            (csr_internal_read_access_status_auth_tag_w_err) ?
                1'b0:
                csr_internal_field_status_auth_tag_w_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_auth_tag_w_err <=
                    1'h0;
            else
                csr_internal_field_status_auth_tag_w_err <=
                    csr_internal_next_field_status_auth_tag_w_err;

        // Field: status.auth_tag_chk_err
        // Position: [20]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_auth_tag_chk_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_auth_tag_chk_err =
            status_auth_tag_chk_err_input;

        assign csr_internal_next_field_status_auth_tag_chk_err =
            (status_auth_tag_chk_err_load_enable) ?
                csr_internal_input_status_auth_tag_chk_err:
                csr_internal_read_effect_status_auth_tag_chk_err;

        assign csr_internal_read_effect_status_auth_tag_chk_err =
            (csr_internal_read_access_status_auth_tag_chk_err) ?
                1'b0:
                csr_internal_field_status_auth_tag_chk_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_auth_tag_chk_err <=
                    1'h0;
            else
                csr_internal_field_status_auth_tag_chk_err <=
                    csr_internal_next_field_status_auth_tag_chk_err;

        // Field: status.auth_tag_r_err
        // Position: [19]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_auth_tag_r_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_auth_tag_r_err =
            status_auth_tag_r_err_input;

        assign csr_internal_next_field_status_auth_tag_r_err =
            (status_auth_tag_r_err_load_enable) ?
                csr_internal_input_status_auth_tag_r_err:
                csr_internal_read_effect_status_auth_tag_r_err;

        assign csr_internal_read_effect_status_auth_tag_r_err =
            (csr_internal_read_access_status_auth_tag_r_err) ?
                1'b0:
                csr_internal_field_status_auth_tag_r_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_auth_tag_r_err <=
                    1'h0;
            else
                csr_internal_field_status_auth_tag_r_err <=
                    csr_internal_next_field_status_auth_tag_r_err;

        // Field: status.cache_block_w_err_fetch_block
        // Position: [18]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_cache_block_w_err_fetch_block =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_cache_block_w_err_fetch_block =
            status_cache_block_w_err_fetch_block_input;

        assign csr_internal_next_field_status_cache_block_w_err_fetch_block =
            (status_cache_block_w_err_fetch_block_load_enable) ?
                csr_internal_input_status_cache_block_w_err_fetch_block:
                csr_internal_read_effect_status_cache_block_w_err_fetch_block;

        assign csr_internal_read_effect_status_cache_block_w_err_fetch_block =
            (csr_internal_read_access_status_cache_block_w_err_fetch_block) ?
                1'b0:
                csr_internal_field_status_cache_block_w_err_fetch_block;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cache_block_w_err_fetch_block <=
                    1'h0;
            else
                csr_internal_field_status_cache_block_w_err_fetch_block <=
                    csr_internal_next_field_status_cache_block_w_err_fetch_block;

        // Field: status.cache_block_w_err_encr_block
        // Position: [17]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_cache_block_w_err_encr_block =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_cache_block_w_err_encr_block =
            status_cache_block_w_err_encr_block_input;

        assign csr_internal_next_field_status_cache_block_w_err_encr_block =
            (status_cache_block_w_err_encr_block_load_enable) ?
                csr_internal_input_status_cache_block_w_err_encr_block:
                csr_internal_read_effect_status_cache_block_w_err_encr_block;

        assign csr_internal_read_effect_status_cache_block_w_err_encr_block =
            (csr_internal_read_access_status_cache_block_w_err_encr_block) ?
                1'b0:
                csr_internal_field_status_cache_block_w_err_encr_block;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cache_block_w_err_encr_block <=
                    1'h0;
            else
                csr_internal_field_status_cache_block_w_err_encr_block <=
                    csr_internal_next_field_status_cache_block_w_err_encr_block;

        // Field: status.cache_block_r_err
        // Position: [16]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_cache_block_r_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_cache_block_r_err =
            status_cache_block_r_err_input;

        assign csr_internal_next_field_status_cache_block_r_err =
            (status_cache_block_r_err_load_enable) ?
                csr_internal_input_status_cache_block_r_err:
                csr_internal_read_effect_status_cache_block_r_err;

        assign csr_internal_read_effect_status_cache_block_r_err =
            (csr_internal_read_access_status_cache_block_r_err) ?
                1'b0:
                csr_internal_field_status_cache_block_r_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cache_block_r_err <=
                    1'h0;
            else
                csr_internal_field_status_cache_block_r_err <=
                    csr_internal_next_field_status_cache_block_r_err;

        // Field: status.key_fetch_err
        // Position: [15]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_key_fetch_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_key_fetch_err =
            status_key_fetch_err_input;

        assign csr_internal_next_field_status_key_fetch_err =
            (status_key_fetch_err_load_enable) ?
                csr_internal_input_status_key_fetch_err:
                csr_internal_read_effect_status_key_fetch_err;

        assign csr_internal_read_effect_status_key_fetch_err =
            (csr_internal_read_access_status_key_fetch_err) ?
                1'b0:
                csr_internal_field_status_key_fetch_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_key_fetch_err <=
                    1'h0;
            else
                csr_internal_field_status_key_fetch_err <=
                    csr_internal_next_field_status_key_fetch_err;

        // Field: status.rng_seed_r_err
        // Position: [14]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_rng_seed_r_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_rng_seed_r_err =
            status_rng_seed_r_err_input;

        assign csr_internal_next_field_status_rng_seed_r_err =
            (status_rng_seed_r_err_load_enable) ?
                csr_internal_input_status_rng_seed_r_err:
                csr_internal_read_effect_status_rng_seed_r_err;

        assign csr_internal_read_effect_status_rng_seed_r_err =
            (csr_internal_read_access_status_rng_seed_r_err) ?
                1'b0:
                csr_internal_field_status_rng_seed_r_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_rng_seed_r_err <=
                    1'h0;
            else
                csr_internal_field_status_rng_seed_r_err <=
                    csr_internal_next_field_status_rng_seed_r_err;

        // Field: status.invalid_cmd_err
        // Position: [13]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_invalid_cmd_err =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_invalid_cmd_err =
            status_invalid_cmd_err_input;

        assign csr_internal_next_field_status_invalid_cmd_err =
            (status_invalid_cmd_err_load_enable) ?
                csr_internal_input_status_invalid_cmd_err:
                csr_internal_read_effect_status_invalid_cmd_err;

        assign csr_internal_read_effect_status_invalid_cmd_err =
            (csr_internal_read_access_status_invalid_cmd_err) ?
                1'b0:
                csr_internal_field_status_invalid_cmd_err;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_invalid_cmd_err <=
                    1'h0;
            else
                csr_internal_field_status_invalid_cmd_err <=
                    csr_internal_next_field_status_invalid_cmd_err;

        // Field: status.cmd_failed
        // Position: [12]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_cmd_failed =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_cmd_failed =
            status_cmd_failed_input;

        assign csr_internal_next_field_status_cmd_failed =
            (status_cmd_failed_load_enable) ?
                csr_internal_input_status_cmd_failed:
                csr_internal_read_effect_status_cmd_failed;

        assign csr_internal_read_effect_status_cmd_failed =
            (csr_internal_read_access_status_cmd_failed) ?
                1'b0:
                csr_internal_field_status_cmd_failed;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cmd_failed <=
                    1'h0;
            else
                csr_internal_field_status_cmd_failed <=
                    csr_internal_next_field_status_cmd_failed;

        // Field: status.cmd_success
        // Position: [11]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_status_cmd_success =
            csr_internal_decode_status &
            csr_internal_read_access;

        assign csr_internal_input_status_cmd_success =
            status_cmd_success_input;

        assign csr_internal_next_field_status_cmd_success =
            (status_cmd_success_load_enable) ?
                csr_internal_input_status_cmd_success:
                csr_internal_read_effect_status_cmd_success;

        assign csr_internal_read_effect_status_cmd_success =
            (csr_internal_read_access_status_cmd_success) ?
                1'b0:
                csr_internal_field_status_cmd_success;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cmd_success <=
                    1'h0;
            else
                csr_internal_field_status_cmd_success <=
                    csr_internal_next_field_status_cmd_success;

        // Field: status.cmd_in_progress
        // Position: [10]
        // Access: read-only
        // Type: configuration

        assign csr_internal_input_status_cmd_in_progress =
            status_cmd_in_progress_input;

        assign csr_internal_next_field_status_cmd_in_progress =
            (status_cmd_in_progress_load_enable) ?
                csr_internal_input_status_cmd_in_progress:
                csr_internal_field_status_cmd_in_progress;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_status_cmd_in_progress <=
                    1'h0;
            else
                csr_internal_field_status_cmd_in_progress <=
                    csr_internal_next_field_status_cmd_in_progress;

        // Field: status.sinc_reinit_disabled
        // Position: [9]
        // Access: read-only
        // Type: status
        //    Reset Value: 1'b0

        assign csr_internal_input_status_sinc_reinit_disabled =
            status_sinc_reinit_disabled;

        assign csr_internal_field_status_sinc_reinit_disabled =
            csr_internal_input_status_sinc_reinit_disabled;

        // Field: status.sinc_reset_disabled
        // Position: [8]
        // Access: read-only
        // Type: status
        //    Reset Value: 1'b0

        assign csr_internal_input_status_sinc_reset_disabled =
            status_sinc_reset_disabled;

        assign csr_internal_field_status_sinc_reset_disabled =
            csr_internal_input_status_sinc_reset_disabled;

        // Field: status.state
        // Position: [7:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 8'h0

        assign csr_internal_input_status_state =
            status_state;

        assign csr_internal_field_status_state =
            csr_internal_input_status_state;


    //
    // Register: hit_cntr_lower
    // Addressmap Byte Offset: 0x2c
    // Access: read-only
    //
    assign csr_internal_read_value_hit_cntr_lower =
        csr_internal_field_hit_cntr_lower_hit_cntr_lower;
    assign csr_internal_read_bus_hit_cntr_lower =
        csr_internal_read_value_hit_cntr_lower &
        {32{csr_internal_decode_hit_cntr_lower}};

    assign csr_internal_access_error_hit_cntr_lower =
        csr_internal_decode_hit_cntr_lower &
        csr_internal_write_access;

        // Field: hit_cntr_lower.hit_cntr_lower
        // Position: [31:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 32'h0

        assign csr_internal_input_hit_cntr_lower_hit_cntr_lower =
            hit_cntr_lower_hit_cntr_lower;

        assign csr_internal_field_hit_cntr_lower_hit_cntr_lower =
            csr_internal_input_hit_cntr_lower_hit_cntr_lower;


    //
    // Register: hit_cntr_upper
    // Addressmap Byte Offset: 0x30
    // Access: read-only
    //
    assign csr_internal_read_value_hit_cntr_upper =
        {
            16'h0,
            csr_internal_field_hit_cntr_upper_hit_cntr_upper
        };
    assign csr_internal_read_bus_hit_cntr_upper =
        csr_internal_read_value_hit_cntr_upper &
        {32{csr_internal_decode_hit_cntr_upper}};

    assign csr_internal_access_error_hit_cntr_upper =
        csr_internal_decode_hit_cntr_upper &
        csr_internal_write_access;

        // Field: hit_cntr_upper.hit_cntr_upper
        // Position: [15:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 16'h0

        assign csr_internal_input_hit_cntr_upper_hit_cntr_upper =
            hit_cntr_upper_hit_cntr_upper;

        assign csr_internal_field_hit_cntr_upper_hit_cntr_upper =
            csr_internal_input_hit_cntr_upper_hit_cntr_upper;


    //
    // Register: miss_cntr_lower
    // Addressmap Byte Offset: 0x34
    // Access: read-only
    //
    assign csr_internal_read_value_miss_cntr_lower =
        csr_internal_field_miss_cntr_lower_miss_cntr_lower;
    assign csr_internal_read_bus_miss_cntr_lower =
        csr_internal_read_value_miss_cntr_lower &
        {32{csr_internal_decode_miss_cntr_lower}};

    assign csr_internal_access_error_miss_cntr_lower =
        csr_internal_decode_miss_cntr_lower &
        csr_internal_write_access;

        // Field: miss_cntr_lower.miss_cntr_lower
        // Position: [31:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 32'h0

        assign csr_internal_input_miss_cntr_lower_miss_cntr_lower =
            miss_cntr_lower_miss_cntr_lower;

        assign csr_internal_field_miss_cntr_lower_miss_cntr_lower =
            csr_internal_input_miss_cntr_lower_miss_cntr_lower;


    //
    // Register: miss_cntr_upper
    // Addressmap Byte Offset: 0x38
    // Access: read-only
    //
    assign csr_internal_read_value_miss_cntr_upper =
        {
            16'h0,
            csr_internal_field_miss_cntr_upper_miss_cntr_upper
        };
    assign csr_internal_read_bus_miss_cntr_upper =
        csr_internal_read_value_miss_cntr_upper &
        {32{csr_internal_decode_miss_cntr_upper}};

    assign csr_internal_access_error_miss_cntr_upper =
        csr_internal_decode_miss_cntr_upper &
        csr_internal_write_access;

        // Field: miss_cntr_upper.miss_cntr_upper
        // Position: [15:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 16'h0

        assign csr_internal_input_miss_cntr_upper_miss_cntr_upper =
            miss_cntr_upper_miss_cntr_upper;

        assign csr_internal_field_miss_cntr_upper_miss_cntr_upper =
            csr_internal_input_miss_cntr_upper_miss_cntr_upper;


    //
    // Register: lat_cntr_lower
    // Addressmap Byte Offset: 0x3c
    // Access: read-only
    //
    assign csr_internal_read_value_lat_cntr_lower =
        csr_internal_field_lat_cntr_lower_lat_cntr_lower;
    assign csr_internal_read_bus_lat_cntr_lower =
        csr_internal_read_value_lat_cntr_lower &
        {32{csr_internal_decode_lat_cntr_lower}};

    assign csr_internal_access_error_lat_cntr_lower =
        csr_internal_decode_lat_cntr_lower &
        csr_internal_write_access;

        // Field: lat_cntr_lower.lat_cntr_lower
        // Position: [31:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 32'h0

        assign csr_internal_input_lat_cntr_lower_lat_cntr_lower =
            lat_cntr_lower_lat_cntr_lower;

        assign csr_internal_field_lat_cntr_lower_lat_cntr_lower =
            csr_internal_input_lat_cntr_lower_lat_cntr_lower;


    //
    // Register: lat_cntr_upper
    // Addressmap Byte Offset: 0x40
    // Access: read-only
    //
    assign csr_internal_read_value_lat_cntr_upper =
        {
            16'h0,
            csr_internal_field_lat_cntr_upper_lat_cntr_upper
        };
    assign csr_internal_read_bus_lat_cntr_upper =
        csr_internal_read_value_lat_cntr_upper &
        {32{csr_internal_decode_lat_cntr_upper}};

    assign csr_internal_access_error_lat_cntr_upper =
        csr_internal_decode_lat_cntr_upper &
        csr_internal_write_access;

        // Field: lat_cntr_upper.lat_cntr_upper
        // Position: [15:0]
        // Access: read-only
        // Type: status
        //    Reset Value: 16'h0

        assign csr_internal_input_lat_cntr_upper_lat_cntr_upper =
            lat_cntr_upper_lat_cntr_upper;

        assign csr_internal_field_lat_cntr_upper_lat_cntr_upper =
            csr_internal_input_lat_cntr_upper_lat_cntr_upper;


    //
    // Register: perf_cntr_ctrl
    // Addressmap Byte Offset: 0x44
    // Access: read-write
    //
    assign csr_internal_read_value_perf_cntr_ctrl =
        {
            16'h0,
            csr_internal_field_perf_cntr_ctrl_lat_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_lat_cntr_en,
            5'h0,
            csr_internal_field_perf_cntr_ctrl_miss_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_miss_cntr_en,
            5'h0,
            csr_internal_field_perf_cntr_ctrl_hit_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_hit_cntr_en
        };
    assign csr_internal_read_bus_perf_cntr_ctrl =
        csr_internal_read_value_perf_cntr_ctrl &
        {32{csr_internal_decode_perf_cntr_ctrl}};
    assign csr_internal_write_access_perf_cntr_ctrl =
        csr_internal_decode_perf_cntr_ctrl &
        csr_internal_write_access;

    assign perf_cntr_ctrl = 
        {
            csr_internal_field_perf_cntr_ctrl_lat_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_lat_cntr_en,
            5'h0,
            csr_internal_field_perf_cntr_ctrl_miss_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_miss_cntr_en,
            5'h0,
            csr_internal_field_perf_cntr_ctrl_hit_cntr_clr,
            csr_internal_field_perf_cntr_ctrl_hit_cntr_en
        };

    assign csr_internal_next_written_perf_cntr_ctrl =
        csr_internal_write_access_perf_cntr_ctrl;

    always_ff @(posedge clock)
        csr_internal_written_perf_cntr_ctrl <=
            csr_internal_next_written_perf_cntr_ctrl;

    assign perf_cntr_ctrl_written =
        csr_internal_written_perf_cntr_ctrl;

        // Field: perf_cntr_ctrl.lat_cntr_clr
        // Position: [15]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_lat_cntr_clr =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_lat_cntr_clr =
            (csr_internal_write_access_perf_cntr_ctrl_lat_cntr_clr) ?
                csr_internal_bus_write_data[15]:
                csr_internal_field_perf_cntr_ctrl_lat_cntr_clr;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_lat_cntr_clr <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_lat_cntr_clr <=
                    csr_internal_next_field_perf_cntr_ctrl_lat_cntr_clr;

        // Field: perf_cntr_ctrl.lat_cntr_en
        // Position: [14]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_lat_cntr_en =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_lat_cntr_en =
            (csr_internal_write_access_perf_cntr_ctrl_lat_cntr_en) ?
                csr_internal_bus_write_data[14]:
                csr_internal_field_perf_cntr_ctrl_lat_cntr_en;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_lat_cntr_en <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_lat_cntr_en <=
                    csr_internal_next_field_perf_cntr_ctrl_lat_cntr_en;

        // Field: perf_cntr_ctrl.miss_cntr_clr
        // Position: [8]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_miss_cntr_clr =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_miss_cntr_clr =
            (csr_internal_write_access_perf_cntr_ctrl_miss_cntr_clr) ?
                csr_internal_bus_write_data[8]:
                csr_internal_field_perf_cntr_ctrl_miss_cntr_clr;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_miss_cntr_clr <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_miss_cntr_clr <=
                    csr_internal_next_field_perf_cntr_ctrl_miss_cntr_clr;

        // Field: perf_cntr_ctrl.miss_cntr_en
        // Position: [7]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_miss_cntr_en =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_miss_cntr_en =
            (csr_internal_write_access_perf_cntr_ctrl_miss_cntr_en) ?
                csr_internal_bus_write_data[7]:
                csr_internal_field_perf_cntr_ctrl_miss_cntr_en;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_miss_cntr_en <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_miss_cntr_en <=
                    csr_internal_next_field_perf_cntr_ctrl_miss_cntr_en;

        // Field: perf_cntr_ctrl.hit_cntr_clr
        // Position: [1]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_hit_cntr_clr =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_hit_cntr_clr =
            (csr_internal_write_access_perf_cntr_ctrl_hit_cntr_clr) ?
                csr_internal_bus_write_data[1]:
                csr_internal_field_perf_cntr_ctrl_hit_cntr_clr;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_hit_cntr_clr <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_hit_cntr_clr <=
                    csr_internal_next_field_perf_cntr_ctrl_hit_cntr_clr;

        // Field: perf_cntr_ctrl.hit_cntr_en
        // Position: [0]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_perf_cntr_ctrl_hit_cntr_en =
            csr_internal_decode_perf_cntr_ctrl &
            csr_internal_write_access;

        assign csr_internal_next_field_perf_cntr_ctrl_hit_cntr_en =
            (csr_internal_write_access_perf_cntr_ctrl_hit_cntr_en) ?
                csr_internal_bus_write_data[0]:
                csr_internal_field_perf_cntr_ctrl_hit_cntr_en;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_perf_cntr_ctrl_hit_cntr_en <=
                    1'h0;
            else
                csr_internal_field_perf_cntr_ctrl_hit_cntr_en <=
                    csr_internal_next_field_perf_cntr_ctrl_hit_cntr_en;


    //
    // Register: aes_test_data_in_0
    // Addressmap Byte Offset: 0x48
    // Access: read-write
    //
    assign csr_internal_read_value_aes_test_data_in_0 =
        csr_internal_field_aes_test_data_in_0_aes_test_data_in_0;
    assign csr_internal_read_bus_aes_test_data_in_0 =
        csr_internal_read_value_aes_test_data_in_0 &
        {32{csr_internal_decode_aes_test_data_in_0}};

    assign aes_test_data_in_0 = 
        csr_internal_field_aes_test_data_in_0_aes_test_data_in_0;

        // Field: aes_test_data_in_0.aes_test_data_in_0
        // Position: [31:0]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_aes_test_data_in_0_aes_test_data_in_0 =
            csr_internal_decode_aes_test_data_in_0 &
            csr_internal_write_access;

        assign csr_internal_next_field_aes_test_data_in_0_aes_test_data_in_0 =
            (csr_internal_write_access_aes_test_data_in_0_aes_test_data_in_0) ?
                csr_internal_bus_write_data:
                csr_internal_field_aes_test_data_in_0_aes_test_data_in_0;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_in_0_aes_test_data_in_0 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_in_0_aes_test_data_in_0 <=
                    csr_internal_next_field_aes_test_data_in_0_aes_test_data_in_0;


    //
    // Register: aes_test_data_in_1
    // Addressmap Byte Offset: 0x4c
    // Access: read-write
    //
    assign csr_internal_read_value_aes_test_data_in_1 =
        csr_internal_field_aes_test_data_in_1_aes_test_data_in_1;
    assign csr_internal_read_bus_aes_test_data_in_1 =
        csr_internal_read_value_aes_test_data_in_1 &
        {32{csr_internal_decode_aes_test_data_in_1}};

    assign aes_test_data_in_1 = 
        csr_internal_field_aes_test_data_in_1_aes_test_data_in_1;

        // Field: aes_test_data_in_1.aes_test_data_in_1
        // Position: [31:0]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_aes_test_data_in_1_aes_test_data_in_1 =
            csr_internal_decode_aes_test_data_in_1 &
            csr_internal_write_access;

        assign csr_internal_next_field_aes_test_data_in_1_aes_test_data_in_1 =
            (csr_internal_write_access_aes_test_data_in_1_aes_test_data_in_1) ?
                csr_internal_bus_write_data:
                csr_internal_field_aes_test_data_in_1_aes_test_data_in_1;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_in_1_aes_test_data_in_1 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_in_1_aes_test_data_in_1 <=
                    csr_internal_next_field_aes_test_data_in_1_aes_test_data_in_1;


    //
    // Register: aes_test_data_in_2
    // Addressmap Byte Offset: 0x50
    // Access: read-write
    //
    assign csr_internal_read_value_aes_test_data_in_2 =
        csr_internal_field_aes_test_data_in_2_aes_test_data_in_2;
    assign csr_internal_read_bus_aes_test_data_in_2 =
        csr_internal_read_value_aes_test_data_in_2 &
        {32{csr_internal_decode_aes_test_data_in_2}};

    assign aes_test_data_in_2 = 
        csr_internal_field_aes_test_data_in_2_aes_test_data_in_2;

        // Field: aes_test_data_in_2.aes_test_data_in_2
        // Position: [31:0]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_aes_test_data_in_2_aes_test_data_in_2 =
            csr_internal_decode_aes_test_data_in_2 &
            csr_internal_write_access;

        assign csr_internal_next_field_aes_test_data_in_2_aes_test_data_in_2 =
            (csr_internal_write_access_aes_test_data_in_2_aes_test_data_in_2) ?
                csr_internal_bus_write_data:
                csr_internal_field_aes_test_data_in_2_aes_test_data_in_2;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_in_2_aes_test_data_in_2 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_in_2_aes_test_data_in_2 <=
                    csr_internal_next_field_aes_test_data_in_2_aes_test_data_in_2;


    //
    // Register: aes_test_data_in_3
    // Addressmap Byte Offset: 0x54
    // Access: read-write
    //
    assign csr_internal_read_value_aes_test_data_in_3 =
        csr_internal_field_aes_test_data_in_3_aes_test_data_in_3;
    assign csr_internal_read_bus_aes_test_data_in_3 =
        csr_internal_read_value_aes_test_data_in_3 &
        {32{csr_internal_decode_aes_test_data_in_3}};

    assign aes_test_data_in_3 = 
        csr_internal_field_aes_test_data_in_3_aes_test_data_in_3;

        // Field: aes_test_data_in_3.aes_test_data_in_3
        // Position: [31:0]
        // Access: read-write
        // Type: configuration
        assign csr_internal_write_access_aes_test_data_in_3_aes_test_data_in_3 =
            csr_internal_decode_aes_test_data_in_3 &
            csr_internal_write_access;

        assign csr_internal_next_field_aes_test_data_in_3_aes_test_data_in_3 =
            (csr_internal_write_access_aes_test_data_in_3_aes_test_data_in_3) ?
                csr_internal_bus_write_data:
                csr_internal_field_aes_test_data_in_3_aes_test_data_in_3;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_in_3_aes_test_data_in_3 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_in_3_aes_test_data_in_3 <=
                    csr_internal_next_field_aes_test_data_in_3_aes_test_data_in_3;


    //
    // Register: aes_test_data_out_0
    // Addressmap Byte Offset: 0x58
    // Access: read-only
    //
    assign csr_internal_read_value_aes_test_data_out_0 =
        csr_internal_field_aes_test_data_out_0_aes_test_data_out_0;
    assign csr_internal_read_bus_aes_test_data_out_0 =
        csr_internal_read_value_aes_test_data_out_0 &
        {32{csr_internal_decode_aes_test_data_out_0}};

    assign csr_internal_access_error_aes_test_data_out_0 =
        csr_internal_decode_aes_test_data_out_0 &
        csr_internal_write_access;

        // Field: aes_test_data_out_0.aes_test_data_out_0
        // Position: [31:0]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_data_out_0_aes_test_data_out_0 =
            aes_test_data_out_0_aes_test_data_out_0_input;

        assign csr_internal_clear_aes_test_data_out_0_aes_test_data_out_0 =
            aes_test_data_out_0_aes_test_data_out_0_clear;

        assign csr_internal_next_field_aes_test_data_out_0_aes_test_data_out_0 =
            (csr_internal_clear_aes_test_data_out_0_aes_test_data_out_0) ?
                32'b0:
                (aes_test_data_out_0_aes_test_data_out_0_load_enable) ?
                    csr_internal_input_aes_test_data_out_0_aes_test_data_out_0:
                    csr_internal_field_aes_test_data_out_0_aes_test_data_out_0;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_out_0_aes_test_data_out_0 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_out_0_aes_test_data_out_0 <=
                    csr_internal_next_field_aes_test_data_out_0_aes_test_data_out_0;


    //
    // Register: aes_test_data_out_1
    // Addressmap Byte Offset: 0x5c
    // Access: read-only
    //
    assign csr_internal_read_value_aes_test_data_out_1 =
        csr_internal_field_aes_test_data_out_1_aes_test_data_out_1;
    assign csr_internal_read_bus_aes_test_data_out_1 =
        csr_internal_read_value_aes_test_data_out_1 &
        {32{csr_internal_decode_aes_test_data_out_1}};

    assign csr_internal_access_error_aes_test_data_out_1 =
        csr_internal_decode_aes_test_data_out_1 &
        csr_internal_write_access;

        // Field: aes_test_data_out_1.aes_test_data_out_1
        // Position: [31:0]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_data_out_1_aes_test_data_out_1 =
            aes_test_data_out_1_aes_test_data_out_1_input;

        assign csr_internal_clear_aes_test_data_out_1_aes_test_data_out_1 =
            aes_test_data_out_1_aes_test_data_out_1_clear;

        assign csr_internal_next_field_aes_test_data_out_1_aes_test_data_out_1 =
            (csr_internal_clear_aes_test_data_out_1_aes_test_data_out_1) ?
                32'b0:
                (aes_test_data_out_1_aes_test_data_out_1_load_enable) ?
                    csr_internal_input_aes_test_data_out_1_aes_test_data_out_1:
                    csr_internal_field_aes_test_data_out_1_aes_test_data_out_1;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_out_1_aes_test_data_out_1 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_out_1_aes_test_data_out_1 <=
                    csr_internal_next_field_aes_test_data_out_1_aes_test_data_out_1;


    //
    // Register: aes_test_data_out_2
    // Addressmap Byte Offset: 0x60
    // Access: read-only
    //
    assign csr_internal_read_value_aes_test_data_out_2 =
        csr_internal_field_aes_test_data_out_2_aes_test_data_out_2;
    assign csr_internal_read_bus_aes_test_data_out_2 =
        csr_internal_read_value_aes_test_data_out_2 &
        {32{csr_internal_decode_aes_test_data_out_2}};

    assign csr_internal_access_error_aes_test_data_out_2 =
        csr_internal_decode_aes_test_data_out_2 &
        csr_internal_write_access;

        // Field: aes_test_data_out_2.aes_test_data_out_2
        // Position: [31:0]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_data_out_2_aes_test_data_out_2 =
            aes_test_data_out_2_aes_test_data_out_2_input;

        assign csr_internal_clear_aes_test_data_out_2_aes_test_data_out_2 =
            aes_test_data_out_2_aes_test_data_out_2_clear;

        assign csr_internal_next_field_aes_test_data_out_2_aes_test_data_out_2 =
            (csr_internal_clear_aes_test_data_out_2_aes_test_data_out_2) ?
                32'b0:
                (aes_test_data_out_2_aes_test_data_out_2_load_enable) ?
                    csr_internal_input_aes_test_data_out_2_aes_test_data_out_2:
                    csr_internal_field_aes_test_data_out_2_aes_test_data_out_2;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_out_2_aes_test_data_out_2 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_out_2_aes_test_data_out_2 <=
                    csr_internal_next_field_aes_test_data_out_2_aes_test_data_out_2;


    //
    // Register: aes_test_data_out_3
    // Addressmap Byte Offset: 0x64
    // Access: read-only
    //
    assign csr_internal_read_value_aes_test_data_out_3 =
        csr_internal_field_aes_test_data_out_3_aes_test_data_out_3;
    assign csr_internal_read_bus_aes_test_data_out_3 =
        csr_internal_read_value_aes_test_data_out_3 &
        {32{csr_internal_decode_aes_test_data_out_3}};

    assign csr_internal_access_error_aes_test_data_out_3 =
        csr_internal_decode_aes_test_data_out_3 &
        csr_internal_write_access;

        // Field: aes_test_data_out_3.aes_test_data_out_3
        // Position: [31:0]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_data_out_3_aes_test_data_out_3 =
            aes_test_data_out_3_aes_test_data_out_3_input;

        assign csr_internal_clear_aes_test_data_out_3_aes_test_data_out_3 =
            aes_test_data_out_3_aes_test_data_out_3_clear;

        assign csr_internal_next_field_aes_test_data_out_3_aes_test_data_out_3 =
            (csr_internal_clear_aes_test_data_out_3_aes_test_data_out_3) ?
                32'b0:
                (aes_test_data_out_3_aes_test_data_out_3_load_enable) ?
                    csr_internal_input_aes_test_data_out_3_aes_test_data_out_3:
                    csr_internal_field_aes_test_data_out_3_aes_test_data_out_3;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_data_out_3_aes_test_data_out_3 <=
                    32'h0;
            else
                csr_internal_field_aes_test_data_out_3_aes_test_data_out_3 <=
                    csr_internal_next_field_aes_test_data_out_3_aes_test_data_out_3;


    //
    // Register: aes_test_ctrl
    // Addressmap Byte Offset: 0x68
    // Access: read-write
    //
    assign csr_internal_read_value_aes_test_ctrl =
        {
            14'h0,
            csr_internal_field_aes_test_ctrl_data_out_ack,
            csr_internal_field_aes_test_ctrl_data_in_aad_sel,
            csr_internal_field_aes_test_ctrl_data_in_last,
            csr_internal_field_aes_test_ctrl_data_in_byte_cnt,
            csr_internal_field_aes_test_ctrl_data_in_vld,
            csr_internal_field_aes_test_ctrl_cfg_key_iv_vld,
            csr_internal_field_aes_test_ctrl_reuse_key,
            csr_internal_field_aes_test_ctrl_key_len,
            csr_internal_field_aes_test_ctrl_dir,
            csr_internal_field_aes_test_ctrl_mode
        };
    assign csr_internal_read_bus_aes_test_ctrl =
        csr_internal_read_value_aes_test_ctrl &
        {32{csr_internal_decode_aes_test_ctrl}};

    assign aes_test_ctrl = 
        {
            csr_internal_field_aes_test_ctrl_data_out_ack,
            csr_internal_field_aes_test_ctrl_data_in_aad_sel,
            csr_internal_field_aes_test_ctrl_data_in_last,
            csr_internal_field_aes_test_ctrl_data_in_byte_cnt,
            csr_internal_field_aes_test_ctrl_data_in_vld,
            csr_internal_field_aes_test_ctrl_cfg_key_iv_vld,
            csr_internal_field_aes_test_ctrl_reuse_key,
            csr_internal_field_aes_test_ctrl_key_len,
            csr_internal_field_aes_test_ctrl_dir,
            csr_internal_field_aes_test_ctrl_mode
        };

        // Field: aes_test_ctrl.data_out_ack
        // Position: [17]
        // Access: read-write
        // Type: configuration
        // Clear
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_data_out_ack =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_data_out_ack &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_data_out_ack =
            aes_test_ctrl_data_out_ack_write_enable;

        assign csr_internal_clear_aes_test_ctrl_data_out_ack =
            aes_test_ctrl_data_out_ack_clear;

        assign csr_internal_next_field_aes_test_ctrl_data_out_ack =
            (csr_internal_write_access_aes_test_ctrl_data_out_ack) ?
                csr_internal_bus_write_data[17]:
                (csr_internal_clear_aes_test_ctrl_data_out_ack) ?
                    1'b0:
                    csr_internal_field_aes_test_ctrl_data_out_ack;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_data_out_ack <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_data_out_ack <=
                    csr_internal_next_field_aes_test_ctrl_data_out_ack;

        // Field: aes_test_ctrl.data_in_aad_sel
        // Position: [16]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_data_in_aad_sel =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_data_in_aad_sel &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_data_in_aad_sel =
            aes_test_ctrl_data_in_aad_sel_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_data_in_aad_sel =
            (csr_internal_write_access_aes_test_ctrl_data_in_aad_sel) ?
                csr_internal_bus_write_data[16]:
                csr_internal_field_aes_test_ctrl_data_in_aad_sel;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_data_in_aad_sel <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_data_in_aad_sel <=
                    csr_internal_next_field_aes_test_ctrl_data_in_aad_sel;

        // Field: aes_test_ctrl.data_in_last
        // Position: [15]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_data_in_last =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_data_in_last &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_data_in_last =
            aes_test_ctrl_data_in_last_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_data_in_last =
            (csr_internal_write_access_aes_test_ctrl_data_in_last) ?
                csr_internal_bus_write_data[15]:
                csr_internal_field_aes_test_ctrl_data_in_last;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_data_in_last <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_data_in_last <=
                    csr_internal_next_field_aes_test_ctrl_data_in_last;

        // Field: aes_test_ctrl.data_in_byte_cnt
        // Position: [14:10]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_data_in_byte_cnt =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_data_in_byte_cnt &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_data_in_byte_cnt =
            aes_test_ctrl_data_in_byte_cnt_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_data_in_byte_cnt =
            (csr_internal_write_access_aes_test_ctrl_data_in_byte_cnt) ?
                csr_internal_bus_write_data[14:10]:
                csr_internal_field_aes_test_ctrl_data_in_byte_cnt;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_data_in_byte_cnt <=
                    5'h0;
            else
                csr_internal_field_aes_test_ctrl_data_in_byte_cnt <=
                    csr_internal_next_field_aes_test_ctrl_data_in_byte_cnt;

        // Field: aes_test_ctrl.data_in_vld
        // Position: [9]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_data_in_vld =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_data_in_vld &
            csr_internal_write_access;

        assign csr_internal_input_aes_test_ctrl_data_in_vld =
            aes_test_ctrl_data_in_vld_input;

        assign csr_internal_write_enable_aes_test_ctrl_data_in_vld =
            aes_test_ctrl_data_in_vld_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_data_in_vld =
            (csr_internal_write_access_aes_test_ctrl_data_in_vld) ?
                csr_internal_bus_write_data[9]:
                (aes_test_ctrl_data_in_vld_load_enable) ?
                    csr_internal_input_aes_test_ctrl_data_in_vld:
                    csr_internal_field_aes_test_ctrl_data_in_vld;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_data_in_vld <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_data_in_vld <=
                    csr_internal_next_field_aes_test_ctrl_data_in_vld;

        // Field: aes_test_ctrl.cfg_key_iv_vld
        // Position: [8]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_cfg_key_iv_vld =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_cfg_key_iv_vld &
            csr_internal_write_access;

        assign csr_internal_input_aes_test_ctrl_cfg_key_iv_vld =
            aes_test_ctrl_cfg_key_iv_vld_input;

        assign csr_internal_write_enable_aes_test_ctrl_cfg_key_iv_vld =
            aes_test_ctrl_cfg_key_iv_vld_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_cfg_key_iv_vld =
            (csr_internal_write_access_aes_test_ctrl_cfg_key_iv_vld) ?
                csr_internal_bus_write_data[8]:
                (aes_test_ctrl_cfg_key_iv_vld_load_enable) ?
                    csr_internal_input_aes_test_ctrl_cfg_key_iv_vld:
                    csr_internal_field_aes_test_ctrl_cfg_key_iv_vld;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_cfg_key_iv_vld <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_cfg_key_iv_vld <=
                    csr_internal_next_field_aes_test_ctrl_cfg_key_iv_vld;

        // Field: aes_test_ctrl.reuse_key
        // Position: [7]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_reuse_key =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_reuse_key &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_reuse_key =
            aes_test_ctrl_reuse_key_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_reuse_key =
            (csr_internal_write_access_aes_test_ctrl_reuse_key) ?
                csr_internal_bus_write_data[7]:
                csr_internal_field_aes_test_ctrl_reuse_key;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_reuse_key <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_reuse_key <=
                    csr_internal_next_field_aes_test_ctrl_reuse_key;

        // Field: aes_test_ctrl.key_len
        // Position: [6:5]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_key_len =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_key_len &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_key_len =
            aes_test_ctrl_key_len_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_key_len =
            (csr_internal_write_access_aes_test_ctrl_key_len) ?
                csr_internal_bus_write_data[6:5]:
                csr_internal_field_aes_test_ctrl_key_len;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_key_len <=
                    2'h0;
            else
                csr_internal_field_aes_test_ctrl_key_len <=
                    csr_internal_next_field_aes_test_ctrl_key_len;

        // Field: aes_test_ctrl.dir
        // Position: [4]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_dir =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_dir &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_dir =
            aes_test_ctrl_dir_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_dir =
            (csr_internal_write_access_aes_test_ctrl_dir) ?
                csr_internal_bus_write_data[4]:
                csr_internal_field_aes_test_ctrl_dir;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_dir <=
                    1'h0;
            else
                csr_internal_field_aes_test_ctrl_dir <=
                    csr_internal_next_field_aes_test_ctrl_dir;

        // Field: aes_test_ctrl.mode
        // Position: [3:0]
        // Access: read-write
        // Type: configuration
        // Write Enable
        assign csr_internal_write_access_aes_test_ctrl_mode =
            csr_internal_decode_aes_test_ctrl &
            csr_internal_write_enable_aes_test_ctrl_mode &
            csr_internal_write_access;

        assign csr_internal_write_enable_aes_test_ctrl_mode =
            aes_test_ctrl_mode_write_enable;

        assign csr_internal_next_field_aes_test_ctrl_mode =
            (csr_internal_write_access_aes_test_ctrl_mode) ?
                csr_internal_bus_write_data[3:0]:
                csr_internal_field_aes_test_ctrl_mode;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_ctrl_mode <=
                    4'h0;
            else
                csr_internal_field_aes_test_ctrl_mode <=
                    csr_internal_next_field_aes_test_ctrl_mode;


    //
    // Register: aes_test_status
    // Addressmap Byte Offset: 0x6c
    // Access: read-only
    //
    assign csr_internal_read_value_aes_test_status =
        {
            28'h0,
            csr_internal_field_aes_test_status_tag_out,
            csr_internal_field_aes_test_status_data_out_vld,
            csr_internal_field_aes_test_status_data_in_rdy,
            csr_internal_field_aes_test_status_cfg_key_iv_rdy
        };
    assign csr_internal_read_bus_aes_test_status =
        csr_internal_read_value_aes_test_status &
        {32{csr_internal_decode_aes_test_status}};

    assign aes_test_status = 
        {
            csr_internal_field_aes_test_status_tag_out,
            csr_internal_field_aes_test_status_data_out_vld,
            csr_internal_field_aes_test_status_data_in_rdy,
            csr_internal_field_aes_test_status_cfg_key_iv_rdy
        };

    assign csr_internal_access_error_aes_test_status =
        csr_internal_decode_aes_test_status &
        csr_internal_write_access;

        // Field: aes_test_status.tag_out
        // Position: [3]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_status_tag_out =
            aes_test_status_tag_out_input;

        assign csr_internal_clear_aes_test_status_tag_out =
            aes_test_status_tag_out_clear;

        assign csr_internal_next_field_aes_test_status_tag_out =
            (csr_internal_clear_aes_test_status_tag_out) ?
                1'b0:
                (aes_test_status_tag_out_load_enable) ?
                    csr_internal_input_aes_test_status_tag_out:
                    csr_internal_field_aes_test_status_tag_out;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_status_tag_out <=
                    1'h0;
            else
                csr_internal_field_aes_test_status_tag_out <=
                    csr_internal_next_field_aes_test_status_tag_out;

        // Field: aes_test_status.data_out_vld
        // Position: [2]
        // Access: read-only
        // Type: configuration
        // Clear

        assign csr_internal_input_aes_test_status_data_out_vld =
            aes_test_status_data_out_vld_input;

        assign csr_internal_clear_aes_test_status_data_out_vld =
            aes_test_status_data_out_vld_clear;

        assign csr_internal_next_field_aes_test_status_data_out_vld =
            (csr_internal_clear_aes_test_status_data_out_vld) ?
                1'b0:
                (aes_test_status_data_out_vld_load_enable) ?
                    csr_internal_input_aes_test_status_data_out_vld:
                    csr_internal_field_aes_test_status_data_out_vld;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_aes_test_status_data_out_vld <=
                    1'h0;
            else
                csr_internal_field_aes_test_status_data_out_vld <=
                    csr_internal_next_field_aes_test_status_data_out_vld;

        // Field: aes_test_status.data_in_rdy
        // Position: [1]
        // Access: read-only
        // Type: status
        //    Reset Value: 1'h0

        assign csr_internal_input_aes_test_status_data_in_rdy =
            aes_test_status_data_in_rdy;

        assign csr_internal_field_aes_test_status_data_in_rdy =
            csr_internal_input_aes_test_status_data_in_rdy;

        // Field: aes_test_status.cfg_key_iv_rdy
        // Position: [0]
        // Access: read-only
        // Type: status
        //    Reset Value: 1'h0

        assign csr_internal_input_aes_test_status_cfg_key_iv_rdy =
            aes_test_status_cfg_key_iv_rdy;

        assign csr_internal_field_aes_test_status_cfg_key_iv_rdy =
            csr_internal_input_aes_test_status_cfg_key_iv_rdy;


    //
    // Register: encr_block_status
    // Addressmap Byte Offset: 0x70
    // Access: read-only
    //
    assign csr_internal_read_value_encr_block_status =
        {
            20'h0,
            csr_internal_field_encr_block_status_num_of_blocks_encr
        };
    assign csr_internal_read_bus_encr_block_status =
        csr_internal_read_value_encr_block_status &
        {32{csr_internal_decode_encr_block_status}};

    assign csr_internal_access_error_encr_block_status =
        csr_internal_decode_encr_block_status &
        csr_internal_write_access;

        // Field: encr_block_status.num_of_blocks_encr
        // Position: [11:0]
        // Access: read-only
        // Read Effect: clear
        // Type: configuration
        assign csr_internal_read_access_encr_block_status_num_of_blocks_encr =
            csr_internal_decode_encr_block_status &
            csr_internal_read_access;

        assign csr_internal_input_encr_block_status_num_of_blocks_encr =
            encr_block_status_num_of_blocks_encr_input;

        assign csr_internal_next_field_encr_block_status_num_of_blocks_encr =
            (encr_block_status_num_of_blocks_encr_load_enable) ?
                csr_internal_input_encr_block_status_num_of_blocks_encr:
                csr_internal_read_effect_encr_block_status_num_of_blocks_encr;

        assign csr_internal_read_effect_encr_block_status_num_of_blocks_encr =
            (csr_internal_read_access_encr_block_status_num_of_blocks_encr) ?
                12'b0:
                csr_internal_field_encr_block_status_num_of_blocks_encr;

        always_ff @(posedge clock or negedge reset)
            if (!reset)
                csr_internal_field_encr_block_status_num_of_blocks_encr <=
                    12'h0;
            else
                csr_internal_field_encr_block_status_num_of_blocks_encr <=
                    csr_internal_next_field_encr_block_status_num_of_blocks_encr;


    assign csr_internal_read_data =
        csr_internal_read_bus_block_encr_num |
        csr_internal_read_bus_num_of_blocks |
        csr_internal_read_bus_block_encr_addr |
        csr_internal_read_bus_block_encr_key |
        csr_internal_read_bus_aes_iv_nonce_0 |
        csr_internal_read_bus_aes_iv_nonce_1 |
        csr_internal_read_bus_aes_iv_nonce_2 |
        csr_internal_read_bus_ext_block_base_addr |
        csr_internal_read_bus_ext_auth_tag_base_addr |
        csr_internal_read_bus_status |
        csr_internal_read_bus_hit_cntr_lower |
        csr_internal_read_bus_hit_cntr_upper |
        csr_internal_read_bus_miss_cntr_lower |
        csr_internal_read_bus_miss_cntr_upper |
        csr_internal_read_bus_lat_cntr_lower |
        csr_internal_read_bus_lat_cntr_upper |
        csr_internal_read_bus_perf_cntr_ctrl |
        csr_internal_read_bus_aes_test_data_in_0 |
        csr_internal_read_bus_aes_test_data_in_1 |
        csr_internal_read_bus_aes_test_data_in_2 |
        csr_internal_read_bus_aes_test_data_in_3 |
        csr_internal_read_bus_aes_test_data_out_0 |
        csr_internal_read_bus_aes_test_data_out_1 |
        csr_internal_read_bus_aes_test_data_out_2 |
        csr_internal_read_bus_aes_test_data_out_3 |
        csr_internal_read_bus_aes_test_ctrl |
        csr_internal_read_bus_aes_test_status |
        csr_internal_read_bus_encr_block_status;

    assign csr_internal_error =
        (~csr_internal_valid_address) |
        csr_internal_access_error_cmd |
        csr_internal_access_error_status |
        csr_internal_access_error_hit_cntr_lower |
        csr_internal_access_error_hit_cntr_upper |
        csr_internal_access_error_miss_cntr_lower |
        csr_internal_access_error_miss_cntr_upper |
        csr_internal_access_error_lat_cntr_lower |
        csr_internal_access_error_lat_cntr_upper |
        csr_internal_access_error_aes_test_data_out_0 |
        csr_internal_access_error_aes_test_data_out_1 |
        csr_internal_access_error_aes_test_data_out_2 |
        csr_internal_access_error_aes_test_data_out_3 |
        csr_internal_access_error_aes_test_status |
        csr_internal_access_error_encr_block_status;

endmodule
