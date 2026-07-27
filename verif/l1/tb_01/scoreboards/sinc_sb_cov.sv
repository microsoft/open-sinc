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
// File        : sinc_sb_cov.sv
// Description : 

`ifndef SINC_SB_COV
`define SINC_SB_COV

covergroup sinc_erase_cg with function sample(sinc_sb_pkt_item sb_item);

  access_while_state_cp : coverpoint sb_item.m_cur_cache_state {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  erase_accepted_before_cache_mem_transaction_done_cp : coverpoint sb_item.m_erase_accepted_before_cache_mem_transaction_done {
    bins one  = {1};
    bins zero = {0};
  }

  // negative test case not added
  // fixme

  // cross_coverage

endgroup: sinc_erase_cg

covergroup sinc_status_cg with function sample(sinc_reg_data_t status_rd, sinc_sb_pkt_item sb_item);

  access_while_state_cp : coverpoint sb_item.m_cur_cache_state {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  sinc_reset_disabled_cp : coverpoint (status_rd[`SINC_REGS_STATUS_SINC_RESET_DISABLED_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  sinc_reinit_disabled_cp : coverpoint (status_rd[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cmd_in_progress_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cmd_success_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cmd_failed_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CMD_FAILED_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  invalid_cmd_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  rng_seed_r_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  key_fetch_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cache_block_r_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cache_block_w_err_encr_block_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  cache_block_w_err_fetch_block_cp : coverpoint (status_rd[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  auth_tag_r_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  auth_tag_chk_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  auth_tag_w_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  aes_err_cp : coverpoint (status_rd[`SINC_REGS_STATUS_AES_ERR_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

  sinc_hw_fault_cp : coverpoint (status_rd[`SINC_REGS_STATUS_SINC_HW_FAULT_RANGE]) {
    bins b_one  = {1};
    bins b_zero = {0};
  }

endgroup : sinc_status_cg

covergroup sinc_fw_op_cg with function sample(sinc_fw_cmd_e fw_cmd, sinc_sb_pkt_item sb_item);

  sinc_fw_op_type_cp : coverpoint fw_cmd {
    bins b_set_init_state         = {sinc_parameters_pkg::SINC_SET_INIT_STATE};
    bins b_set_cache_active_state = {sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE};
    bins b_sinc_reset             = {sinc_parameters_pkg::SINC_SINC_RESET};
    bins b_sinc_reinit            = {sinc_parameters_pkg::SINC_SINC_REINIT};
    bins b_encrypt_block          = {sinc_parameters_pkg::SINC_ENCR_BLOCK};
    bins b_disable_reset          = {sinc_parameters_pkg::SINC_DISABLE_RESET};
    bins b_disable_reinit         = {sinc_parameters_pkg::SINC_DISABLE_REINIT};
    bins b_aes_test_en            = {sinc_parameters_pkg::SINC_AES_TEST_EN};
  }

  access_while_state_cp : coverpoint sb_item.m_cur_cache_state {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  // fixme: negative case not added

  // cross_coverage
  sinc_fw_op_type_cp_x_cache_state : cross sinc_fw_op_type_cp, access_while_state_cp;

endgroup : sinc_fw_op_cg

covergroup cache_behavior_cg with function sample(ccpui_cpu_mem_transaction cpu_tran, sinc_sb_pkt_item sb_item);

  pos_case_rd_cache_miss_vld_0_cp : coverpoint (sb_item.m_valid_lines_per_set) iff (sb_item.m_is_cache_hit == 0) {
    bins b_cache_miss_vld_lines_per_set_0 = {0};
    bins b_cache_miss_vld_lines_per_set_1 = {1};
    bins b_cache_miss_vld_lines_per_set_2 = {2};
    bins b_cache_miss_vld_lines_per_set_3 = {3};
    bins b_cache_miss_vld_lines_per_set_4 = {4};
  }

  pos_case_cache_hit_cp : coverpoint sb_item.m_is_cache_hit {
    bins b_cache_hit = { 0 };
  }

  // this is same case as erase during cache fetch
  // neg_case_mpuallow_rd_cmiss_ciram_fail_cp : coverpoint (sb_item.m_write_fail_to_ciram_during_fetch) {
  //   bins b_wr_fail_to_ciram_in_fetch = { 1 };
  // }

  neg_case_mpuallow_rd_cmiss_auth_read_tag_fail_cp : coverpoint (sb_item.m_is_dmb_auth_tag_read_error) {
    bins b_aut_tag_fetch_fail = { 1 };
  }

  neg_case_mpuallow_rd_cmiss_auth_read_tag_mismatch_cp : coverpoint (sb_item.m_is_auth_tag_mismatch_error) {
    bins b_aut_tag_fetch_mismatch = { 1 };
  }

endgroup : cache_behavior_cg

covergroup cpu_mem_tran_cg with function sample(ccpui_cpu_mem_transaction cpu_tran, sinc_sb_pkt_item sb_item);

  config_address_cp : coverpoint (cpu_tran.m_addr) {
    bins b_zero           = {0};
    bins b_max            = {22'h3F_FFFF};
    bins b_low_ranges[8]  = {[22'h1 : 22'hFFFF]};
    bins b_mid_ranges[8]  = {[22'h1_0000 : 22'h2FFF]};
    bins b_high_ranges[8] = {[22'h2_FFFF : 22'h3F_FFFF]};
  }

  rw_cp : coverpoint cpu_tran.m_rw {
    bins b_read  = {ccpui_cpu_mem_pkg::READ};
    bins b_write = {ccpui_cpu_mem_pkg::WRITE};
  }

  rdata_cp : coverpoint ( cpu_tran.m_rdata ) iff (cpu_tran.m_rw == ccpui_cpu_mem_pkg::READ )
  {
    bins b_zero_detected = {0};
  }

  wdata_cp : coverpoint ( cpu_tran.m_wdata ) iff (cpu_tran.m_rw == ccpui_cpu_mem_pkg::WRITE )
  {
    bins b_allone_detected = {32'hFFFF_FFFF_FFFF_FFFF};
  }

  we_cp : coverpoint {cpu_tran.m_we[3], cpu_tran.m_we[2], cpu_tran.m_we[1], cpu_tran.m_we[0]}
  iff (cpu_tran.m_rw == ccpui_cpu_mem_pkg::WRITE) {
    bins b_we[] = {[4'h1:4'hf]};
  }

  loadstore_cp : coverpoint cpu_tran.m_loadstore {
    bins b_asserted   = {1};
    bins b_deasserted = {0};
  }

  privmode_cp : coverpoint cpu_tran.m_privmode {
    bins b_asserted   = {1};
    bins b_deasserted = {0};
  }

  rd_err_cp : coverpoint (cpu_tran.m_rd_err) iff (cpu_tran.m_rw == ccpui_cpu_mem_pkg::READ) {
    bins b_okay  = {0};
    bins b_error = {1};
  }

  access_while_state_cp : coverpoint (sb_item.m_cur_cache_state) {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  sideband_mpu_disable_cp : coverpoint (sb_item.m_snapshot_mpu_cfg_mpu_disable) {
    bins b_disable     = {1};
    bins b_not_disable = {0};
  }

  sideband_mpu_chkpt_spramnx_cp : coverpoint (sb_item.m_snapshot_mpu_cfg_chkpt_spramnx) {
    bins b_chkpt     = {1};
    bins b_not_chkpt = {0};
  }

  is_mpu_allowed_cp : coverpoint (sb_item.m_is_mpu_allowed) {
    bins b_allow    = {1};
    bins b_disallow = {0};
  }

  // scoreboard is not checking ECC, demote to direct ECC testing
  // is_ecc_corr_cp : coverpoint (is_ecc_corr) {
  //   bins b_SET    = {1};
  //   bins b_NOTSET = {0};
  // }

  // is_ecc_uncorr_cp : coverpoint (is_ecc_uncorr) {
  //   bins b_SET    = {1};
  //   bins b_NOTSET = {0};
  // }

  access_while_cmu_busy_cp : coverpoint (sb_item.m_access_while_cmu_busy) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  access_while_erase_cp : coverpoint (sb_item.m_access_while_erase_inprogress) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  erase_while_transaction_in_progress_cp : coverpoint (sb_item.m_erase_during_req_inprogress) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  // cross coverage
  config_address_x_cachestate : cross config_address_cp, access_while_state_cp;

  cmd_x_mpuallowed_x_cachestate: cross rw_cp, is_mpu_allowed_cp, access_while_state_cp;

  cmd_x_loadstore_x_privmode: cross rw_cp, loadstore_cp, privmode_cp;

  cmd_x_cmubusy: cross rw_cp, access_while_cmu_busy_cp;

  cmd_x_erase: cross rw_cp, access_while_erase_cp;

  erase_x_cmd: cross rw_cp, erase_while_transaction_in_progress_cp;

endgroup : cpu_mem_tran_cg

covergroup mpu_mem_tran_cg with function sample(ccpui_mpu_transaction mpu_tran, sinc_sb_pkt_item sb_item);

  config_address_cp : coverpoint (mpu_tran.m_addr) {
    bins b_reg          = {13'h0};
    bins b_user_attr[8] = {[13'h1000 : 13'h17FC]};
    bins b_priv_attr[8] = {[13'h1800 : 13'h1FFC]};
  }

  // ATTR_READ, ATTR_WRITE, REG_READ, REG_WRITE, SET_SIDEBAND, MPU_ERR_ACCVIO
  rw_cp : coverpoint (mpu_tran.m_op) {
    bins b_attr_read  = {ccpui_mpu_pkg::ATTR_READ};
    bins b_attr_write = {ccpui_mpu_pkg::ATTR_WRITE};
    bins b_reg_read   = {ccpui_mpu_pkg::REG_READ};
    bins b_reg_write  = {ccpui_mpu_pkg::REG_WRITE};
  }

  mpu_disable_cp : coverpoint (mpu_tran.m_mpu_disable )
  {
    bins b_mpu_enable  = {0};
    bins b_mpu_disable = {1};
  }

  access_while_state_cp : coverpoint (sb_item.m_cur_cache_state) {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  mpu_reg_resp_cp : coverpoint ( mpu_tran.m_resp ) {
    bins b_rd_okay = {0};
    bins b_wr_okay = {1};
    bins b_rd_err  = {2};
    bins b_wr_err  = {3};
  }

  // cross cov
  rw_x_state: cross rw_cp, access_while_state_cp;

endgroup : mpu_mem_tran_cg

covergroup sinc_axi_sub_interface_cg with function sample(pal_axi_xaction axi_tran, pal_resp_type_t resp, sinc_sb_pkt_item sb_item);
  // base address need to be added here
  sinc_csr_address_cp : coverpoint (axi_tran.addr) {
    bins b_cmd                    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_CMD_ADDRESS};
    bins b_block_encr_num         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_BLOCK_ENCR_NUM_ADDRESS};
    bins b_num_of_blocks_num      = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_NUM_OF_BLOCKS_ADDRESS};
    bins b_block_encr_addr        = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_BLOCK_ENCR_ADDR_ADDRESS};
    bins b_block_encr_key         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_BLOCK_ENCR_KEY_ADDRESS};
    bins b_aes_iv_nonce_0         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_IV_NONCE_0_ADDRESS};
    bins b_aes_iv_nonce_1         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_IV_NONCE_1_ADDRESS};
    bins b_aes_iv_nonce_2         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_IV_NONCE_2_ADDRESS};
    bins b_ext_block_base_addr    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_EXT_BLOCK_BASE_ADDR_ADDRESS};
    bins b_ext_auth_tag_base_addr = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_EXT_AUTH_TAG_BASE_ADDR_ADDRESS};
    bins b_status                 = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_STATUS_ADDRESS};
    bins b_hit_cntr_upper         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_HIT_CNTR_UPPER_ADDRESS};
    bins b_hit_cntr_lower         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_HIT_CNTR_LOWER_ADDRESS};
    bins b_miss_cntr_upper        = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_MISS_CNTR_UPPER_ADDRESS};
    bins b_lat_cntr_lower         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_LAT_CNTR_LOWER_ADDRESS};
    bins b_lat_cntr_upper         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_LAT_CNTR_UPPER_ADDRESS};
    bins b_perf_cntr_ctrl         = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_PERF_CNTR_CTRL_ADDRESS};
    bins b_aes_test_data_in_0     = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_IN_0_ADDRESS};
    bins b_aes_test_data_in_1     = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_IN_1_ADDRESS};
    bins b_aes_test_data_in_2     = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_IN_2_ADDRESS};
    bins b_aes_test_data_in_3     = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_IN_3_ADDRESS};
    bins b_aes_test_data_out_0    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_OUT_0_ADDRESS};
    bins b_aes_test_data_out_1    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_OUT_1_ADDRESS};
    bins b_aes_test_data_out_2    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_OUT_2_ADDRESS};
    bins b_aes_test_data_out_3    = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_DATA_OUT_3_ADDRESS};
    bins b_aes_test_ctrl          = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_AES_TEST_CTRL_ADDRESS};
    bins b_encr_block_status      = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_ENCR_BLOCK_STATUS_ADDRESS};
    bins others                   = default;
  }

  sinc_status_read_cp : coverpoint (axi_tran.addr) iff (axi_tran.cmd == PAL_READ) {
    bins b_status = {sinc_parameters_pkg::SINC_REG_START_ADDR + `SINC_REGS_STATUS_ADDRESS};
  }

  burst_size_cp : coverpoint (axi_tran.log2_beat_size) {
    bins bytes_1 = {PAL_BYTES_1};
    bins bytes_2 = {PAL_BYTES_2};
    bins bytes_4 = {PAL_BYTES_4};
  }

  burst_type_cp : coverpoint (axi_tran.burst_type) {
    bins fixed = {PAL_BT_FIXED};
    bins incr  = {PAL_BT_INCR};
    bins wrap  = {PAL_BT_WRAP};
    bins rsvd  = {PAL_BT_RSVD};
  }

  burst_length_cp : coverpoint (axi_tran.burst_length) {
    bins length_1 = {1};
    bins others   = default;
  }

  cmd_cp : coverpoint (axi_tran.cmd) {
    bins read  = {PAL_READ};
    bins write = {PAL_WRITE};
  }

  prot_cp : coverpoint axi_tran.axprot {
    bins norm_sec_data    = {PAL_NORM_SEC_DATA};
    bins priv_sec_data    = {PAL_PRIV_SEC_DATA};
    bins norm_nonsec_data = {PAL_NORM_NONSEC_DATA};
    bins priv_nonsec_data = {PAL_PRIV_NONSEC_DATA};
    bins norm_sec_inst    = {PAL_NORM_SEC_INST};
    bins priv_sec_inst    = {PAL_PRIV_SEC_INST};
    bins norm_nonsec_inst = {PAL_NORM_NONSEC_INST};
    bins priv_nonsec_inst = {PAL_PRIV_NONSEC_INST};
  }

  axid_cp : coverpoint (sb_item.m_sub_addr_p_tran.tag_id) {
    bins axid[16] = {[0:15]};
  }

  resp_cp : coverpoint resp {
    bins okay   = {PAL_RESP_OKAY};
    bins slverr = {PAL_RESP_SLVERR};
  }

  access_while_state_cp : coverpoint (sb_item.m_cur_cache_state) {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  access_while_cmu_busy_cp : coverpoint (sb_item.m_access_while_cmu_busy) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  access_while_erase_cp : coverpoint (sb_item.m_access_while_erase_inprogress) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  erase_while_transaction_in_progress_cp : coverpoint (sb_item.m_erase_during_req_inprogress) {
    bins b_set    = {1};
    bins b_notset = {0};
  }

  // Cross coverage
  cmd_cp_x_sinc_csr_address_cp_x_state_cp : cross cmd_cp, sinc_csr_address_cp, access_while_state_cp;

  // Add status register read with erase ongoing
  sinc_status_read_cp_x_access_while_erase_cp : cross sinc_status_read_cp, access_while_erase_cp;

endgroup : sinc_axi_sub_interface_cg

covergroup sb_pkt_item_entry_cg with function sample(sinc_sb_pkt_item pkt);

  sb_pkt_item_entry_cp : coverpoint pkt.m_sinc_sb_pkt_entry {
    bins b_entry_creg_erase       = {sinc_env_pkg::ENTRY_CREG_ERASE};
    bins b_entry_mpu_attr_read    = {sinc_env_pkg::ENTRY_MPU_ATTR_READ};
    bins b_entry_mpu_attr_write   = {sinc_env_pkg::ENTRY_MPU_ATTR_WRITE};
    bins b_entry_mpu_status_read  = {sinc_env_pkg::ENTRY_MPU_STATUS_READ};
    bins b_entry_mpu_status_write = {sinc_env_pkg::ENTRY_MPU_STATUS_WRITE};
    bins b_entry_cpu_read         = {sinc_env_pkg::ENTRY_CPU_READ};
    bins b_entry_cpu_write        = {sinc_env_pkg::ENTRY_CPU_WRITE};
    bins b_entry_axi_sub_read     = {sinc_env_pkg::ENTRY_AXI_SUB_READ};
    bins b_entry_axi_sub_write    = {sinc_env_pkg::ENTRY_AXI_SUB_WRITE};
    bins b_entry_warm_reset       = {sinc_env_pkg::ENTRY_SINC_WARM_RESET};
  }

  access_while_state_cp : coverpoint pkt.m_cur_cache_state {
    bins b_cache_disable_state = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
    bins b_cache_init_state    = {sinc_parameters_pkg::CACHE_INIT_STATE};
    bins b_cache_active_state  = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
    bins b_cache_fail_state    = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  }

  // cross_coverage
  entry_x_cache_state : cross sb_pkt_item_entry_cp, access_while_state_cp;

endgroup : sb_pkt_item_entry_cg

covergroup back_to_back_req_cg with function sample(sinc_req_type_e cur_req, sinc_req_type_e prev_req);

  cur_req_cp : coverpoint cur_req {
    bins b_req_creg_erase       = {sinc_env_pkg::SINC_CREG_ERASE_REQ};
    bins b_req_cpu_read         = {sinc_env_pkg::SINC_CPU_READ_REQ};
    bins b_req_cpu_write        = {sinc_env_pkg::SINC_CPU_WRITE_REQ};
    bins b_req_axi_sub_read     = {sinc_env_pkg::SINC_AXI_SUB_READ_REQ};
    bins b_req_axi_sub_write    = {sinc_env_pkg::SINC_AXI_SUB_WRITE_REQ};
    bins b_req_fw_op            = {sinc_env_pkg::SINC_FW_OP_REQ};
    bins b_req_warm_reset       = {sinc_env_pkg::SINC_SINC_WARM_RESET_REQ};
    bins b_req_mpu_attr_read    = {sinc_env_pkg::SINC_MPU_ATTR_READ_REQ};
    bins b_req_mpu_attr_write   = {sinc_env_pkg::SINC_MPU_ATTR_WRITE_REQ};
    bins b_req_mpu_status_read  = {sinc_env_pkg::SINC_MPU_STATUS_READ_REQ};
    bins b_req_mpu_status_write = {sinc_env_pkg::SINC_MPU_STATUS_WRITE_REQ};
  }

  prev_req_cp : coverpoint prev_req {
    bins b_req_creg_erase       = {sinc_env_pkg::SINC_CREG_ERASE_REQ};
    bins b_req_cpu_read         = {sinc_env_pkg::SINC_CPU_READ_REQ};
    bins b_req_cpu_write        = {sinc_env_pkg::SINC_CPU_WRITE_REQ};
    bins b_req_axi_sub_read     = {sinc_env_pkg::SINC_AXI_SUB_READ_REQ};
    bins b_req_axi_sub_write    = {sinc_env_pkg::SINC_AXI_SUB_WRITE_REQ};
    bins b_req_fw_op            = {sinc_env_pkg::SINC_FW_OP_REQ};
    bins b_req_warm_reset       = {sinc_env_pkg::SINC_SINC_WARM_RESET_REQ};
    bins b_req_mpu_attr_read    = {sinc_env_pkg::SINC_MPU_ATTR_READ_REQ};
    bins b_req_mpu_attr_write   = {sinc_env_pkg::SINC_MPU_ATTR_WRITE_REQ};
    bins b_req_mpu_status_read  = {sinc_env_pkg::SINC_MPU_STATUS_READ_REQ};
    bins b_req_mpu_status_write = {sinc_env_pkg::SINC_MPU_STATUS_WRITE_REQ};
  }

  // cross_coverage
  prev_x_cur : cross prev_req_cp, cur_req_cp;

endgroup : back_to_back_req_cg

// Error scenarios captured by scoreboard
covergroup sinc_error_scenario_cluster_cg (string name="sinc_error_scenario_cluster_cg") with function sample(bit error_bit, sinc_cache_state_type_e cur_cache_state);

  option.per_instance = 1;

  // Note: sample during cache state shall be done if enough time remaining
  // access_while_state_cp : coverpoint cur_cache_state {
  //   bins b_cache_disable_state  = {sinc_parameters_pkg::CACHE_DISABLE_STATE};
  //   bins b_cache_init_state     = {sinc_parameters_pkg::CACHE_INIT_STATE};
  //   bins b_cache_active_state   = {sinc_parameters_pkg::CACHE_ACTIVE_STATE};
  //   // bins b_cache_fail_state     = {sinc_parameters_pkg::CACHE_FAIL_STATE};
  // }

  error_bit_cp : coverpoint error_bit {
    bins b_hit = {1};
  }

  // cross_coverage
  // error_x_cache_state : cross error_bit_cp, access_while_state_cp;

endgroup : sinc_error_scenario_cluster_cg

/**
 * SINC Scoreboard Coverage
 */
class sinc_sb_cov extends uvm_component;

  `uvm_component_utils_begin(sinc_sb_cov)
    `uvm_field_int(m_sinc_cov_enable, UVM_DEFAULT)
  `uvm_component_utils_end

  bit m_sinc_cov_enable = 1;

  sb_pkt_item_entry_cg      m_sb_pkt_item_entry_cg_inst;
  back_to_back_req_cg       m_back_to_back_req_cg_inst;
  cpu_mem_tran_cg           m_cpu_mem_tran_cg_inst;
  cache_behavior_cg         m_cache_behavior_cg_inst;
  mpu_mem_tran_cg           m_mpu_mem_tran_cg_inst;
  sinc_axi_sub_interface_cg m_sinc_axi_sub_tran_cg_inst;
  sinc_fw_op_cg             m_sinc_fw_op_cg_inst;
  sinc_erase_cg             m_sinc_erase_cg_inst;
  sinc_status_cg            m_sinc_status_cg_inst;

  // generic error coverage groups
  sinc_error_scenario_cluster_cg m_sinc_stimulus_err_cg_insts[`SINC_STIMULUS_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_mpu_rd_err_cg_insts[`SINC_MPU_RD_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_mpu_wr_err_cg_insts[`SINC_MPU_WR_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_cpu_rd_err_cg_insts[`SINC_CPU_RD_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_cpu_wr_err_cg_insts[`SINC_CPU_WR_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_axi_global_err_cg_insts[`SINC_AXI_GLOBAL_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_axi_rd_err_cg_insts[`SINC_AXI_RD_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_axi_wr_reg_err_cg_insts[`SINC_AXI_WR_REG_ERR_CASE_NUM];
  sinc_error_scenario_cluster_cg m_sinc_axi_wr_fw_cmd_err_cg_insts[`SINC_AXI_WR_FW_CMD_ERR_CASE_NUM];

  /**
   * Constructor.
   */
  extern function new(string name="sinc_sb_coverage", uvm_component parent);

  /**
   * UVM connect phase. Set the sub-module enable bit from command-line argument
   */
  extern virtual function void connect_phase(uvm_phase phase);

  extern virtual function void report_phase(uvm_phase phase);
  extern virtual function string get_report_id(string tag);
  extern virtual function pal_resp_type_t xact_resp(pal_axi_xaction t);
  extern virtual function void sample_sb_pkt(sinc_sb_pkt_item sb_item, sinc_sb_pkt_item prev_sb_item);

  extern protected virtual function sinc_req_type_e get_req_type(sinc_sb_pkt_item sb_item);
  extern protected virtual function void sample_packet_entry(sinc_sb_pkt_item sb_item);
  extern protected virtual function void sample_b2b_entries(sinc_sb_pkt_item sb_item, sinc_sb_pkt_item prev_sb_item);
  extern protected virtual function void sample_error_scenarios(sinc_sb_pkt_item sb_item);
endclass : sinc_sb_cov

function sinc_sb_cov::new(string name="sinc_sb_coverage", uvm_component parent);
  super.new(name, parent);

  m_sb_pkt_item_entry_cg_inst = new();
  m_back_to_back_req_cg_inst  = new();
  m_cpu_mem_tran_cg_inst      = new();
  m_cache_behavior_cg_inst    = new();
  m_mpu_mem_tran_cg_inst      = new();
  m_sinc_axi_sub_tran_cg_inst = new();
  m_sinc_fw_op_cg_inst        = new();
  m_sinc_erase_cg_inst        = new();
  m_sinc_status_cg_inst       = new();

  foreach(m_sinc_stimulus_err_cg_insts[i]) begin
    m_sinc_stimulus_err_cg_insts[i] = new($sformatf("sinc_stimulus_err_cg_inst%d", i));
  end

  foreach(m_sinc_mpu_rd_err_cg_insts[i]) begin
    m_sinc_mpu_rd_err_cg_insts[i] = new($sformatf("sinc_mpu_rd_err_cg_inst%d", i));
  end

  foreach(m_sinc_mpu_wr_err_cg_insts[i]) begin
    m_sinc_mpu_wr_err_cg_insts[i] = new($sformatf("sinc_mpu_wr_err_cg_inst%d", i));
  end

  foreach(m_sinc_cpu_rd_err_cg_insts[i]) begin
    m_sinc_cpu_rd_err_cg_insts[i] = new($sformatf("sinc_cpu_rd_err_cg_inst%d", i));
  end

  foreach(m_sinc_cpu_wr_err_cg_insts[i]) begin
    m_sinc_cpu_wr_err_cg_insts[i] = new($sformatf("sinc_cpu_wr_err_cg_inst%d", i));
  end

  foreach(m_sinc_axi_global_err_cg_insts[i]) begin
    m_sinc_axi_global_err_cg_insts[i] = new($sformatf("sinc_axi_global_err_cg_inst%d", i));
  end

  foreach(m_sinc_axi_rd_err_cg_insts[i]) begin
    m_sinc_axi_rd_err_cg_insts[i] = new($sformatf("sinc_axi_rd_err_cg_inst%d", i));
  end

  foreach(m_sinc_axi_wr_reg_err_cg_insts[i]) begin
    m_sinc_axi_wr_reg_err_cg_insts[i] = new($sformatf("sinc_axi_wr_reg_err_cg_inst%d", i));
  end

  foreach(m_sinc_axi_wr_fw_cmd_err_cg_insts[i]) begin
    m_sinc_axi_wr_fw_cmd_err_cg_insts[i] = new($sformatf("sinc_axi_wr_fw_cmd_err_cg_inst%d", i));
  end
endfunction : new

function void sinc_sb_cov::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\n Constructing sinc_sb_cov......."), UVM_LOW)
endfunction : connect_phase

function void sinc_sb_cov::report_phase(uvm_phase phase);
  super.report_phase(phase);
endfunction: report_phase

function string sinc_sb_cov::get_report_id(string tag);
  return ({"SINC_COV/", tag});
endfunction : get_report_id

function pal_resp_type_t sinc_sb_cov::xact_resp(pal_axi_xaction t);
  if ((t.cmd == PAL_WRITE) ||
      (t.cmd == PAL_EXWR) ||
      (t.cmd == PAL_LOCKWR)) begin
    return (pal_resp_type_t'(t.wrresp));
  end else if ((t.cmd == PAL_READ) ||
      (t.cmd == PAL_EXRD) ||
      (t.cmd == PAL_LOCKRD)) begin
    bit [1:0] rdresp;
    foreach (t.rdresp[i]) begin
      rdresp |= t.rdresp[i];
    end

    return(pal_resp_type_t'(rdresp));
  end
endfunction : xact_resp

function void sinc_sb_cov::sample_sb_pkt(sinc_sb_pkt_item sb_item, sinc_sb_pkt_item prev_sb_item);
  if (m_sinc_cov_enable) begin

    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample sinc_sb_pkt_item"), UVM_HIGH)
    sb_item.print_packet();

    // sample on this item's entry
    m_sb_pkt_item_entry_cg_inst.sample(sb_item);

    // sample coverage under different entry
    sample_packet_entry(sb_item);
    sample_b2b_entries(sb_item, prev_sb_item);
    sample_error_scenarios(sb_item);

  end // if (m_sinc_cov_enable)
endfunction : sample_sb_pkt

function sinc_req_type_e sinc_sb_cov::get_req_type(sinc_sb_pkt_item sb_item);
  sinc_req_type_e req = sinc_env_pkg::SINC_REQ_NULL;

  if (sb_item !== null) begin
    case (sb_item.m_sinc_sb_pkt_entry)
      sinc_env_pkg::ENTRY_SINC_WARM_RESET : begin
        // warm reset should be sampled with system status and previous transaction
        req = sinc_env_pkg::SINC_SINC_WARM_RESET_REQ;
      end
      sinc_env_pkg::ENTRY_AXI_SUB_READ : begin
        req = sinc_env_pkg::SINC_AXI_SUB_READ_REQ;
      end
      sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
        if (sb_item.m_is_fw_cmd) begin
          req = sinc_env_pkg::SINC_FW_OP_REQ;
        end else begin
          req = sinc_env_pkg::SINC_AXI_SUB_WRITE_REQ;
        end
      end
      sinc_env_pkg::ENTRY_CPU_READ : begin
        req = sinc_env_pkg::SINC_CPU_READ_REQ;
      end
      sinc_env_pkg::ENTRY_CPU_WRITE : begin
        req = sinc_env_pkg::SINC_CPU_WRITE_REQ;
      end
      sinc_env_pkg::ENTRY_CREG_ERASE : begin
        req = sinc_env_pkg::SINC_CREG_ERASE_REQ;
      end
      sinc_env_pkg::ENTRY_MPU_ATTR_READ : begin
        req = sinc_env_pkg::SINC_MPU_ATTR_READ_REQ;
      end
      sinc_env_pkg::ENTRY_MPU_STATUS_READ : begin
        req = sinc_env_pkg::SINC_MPU_STATUS_READ_REQ;
      end
      sinc_env_pkg::ENTRY_MPU_ATTR_WRITE : begin
        req = sinc_env_pkg::SINC_MPU_ATTR_WRITE_REQ;
      end
      sinc_env_pkg::ENTRY_MPU_STATUS_WRITE : begin
        req = sinc_env_pkg::SINC_MPU_STATUS_WRITE_REQ;
      end
      default: begin
        req = sinc_env_pkg::SINC_REQ_NULL;
      end
    endcase
  end
  return (req);
endfunction : get_req_type

function void sinc_sb_cov::sample_packet_entry(sinc_sb_pkt_item sb_item);
  case (sb_item.m_sinc_sb_pkt_entry)
    sinc_env_pkg::ENTRY_AXI_SUB_READ : begin // sample on axi sub group
      if (sb_item.m_axi_sub_rd_resp_tran_q.size()) begin
        m_sinc_axi_sub_tran_cg_inst.sample(sb_item.m_sub_addr_p_tran, xact_resp(sb_item.m_axi_sub_rd_resp_tran_q[0]), sb_item);

        if (sb_item.m_dst_reg !== null) begin
          if ((sb_item.m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) && !sb_item.m_exp_sub_slv_err) begin
            sinc_reg_data_t my_reg_data[];
            my_reg_data = new [1];

            for (int i=0; i < (sb_item.m_axi_sub_rd_resp_tran_q[0].data.size() / 4); i++) begin
              my_reg_data[i] = {sb_item.m_axi_sub_rd_resp_tran_q[0].data[3 + (i * 4)], sb_item.m_axi_sub_rd_resp_tran_q[0].data[2 + (i * 4)], sb_item.m_axi_sub_rd_resp_tran_q[0].data[1 + (i * 4)], sb_item.m_axi_sub_rd_resp_tran_q[0].data[0 + (i * 4)]};
            end
            m_sinc_status_cg_inst.sample(my_reg_data[0], sb_item);
          end
        end
      end
    end
    sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin // sample on axi sub write group
      if (sb_item.m_axi_sub_wr_resp_tran_q.size()) begin
        m_sinc_axi_sub_tran_cg_inst.sample(sb_item.m_sub_addr_p_tran, xact_resp(sb_item.m_axi_sub_wr_resp_tran_q[0]), sb_item);
      end
      if (sb_item.m_is_fw_cmd) begin
        m_sinc_fw_op_cg_inst.sample(sb_item.m_fw_cmd, sb_item);
      end
    end
    sinc_env_pkg::ENTRY_CPU_READ : begin // sample on cpu read group
      if (sb_item.m_cpu_rd_resp_tran_q.size()) begin

        m_cpu_mem_tran_cg_inst.sample(sb_item.m_cpu_rd_resp_tran_q[0], sb_item);

        // sample on cache behavior when cache active state
        if (sb_item.m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
          m_cache_behavior_cg_inst.sample(sb_item.m_cpu_req_p_tran, sb_item);
        end
      end
    end
    sinc_env_pkg::ENTRY_CPU_WRITE : begin // sample on cpu write group
      m_cpu_mem_tran_cg_inst.sample(sb_item.m_cpu_req_p_tran, sb_item);
    end
    sinc_env_pkg::ENTRY_CREG_ERASE : begin // sample on creg erase group with system status
      m_sinc_erase_cg_inst.sample(sb_item);
    end
    sinc_env_pkg::ENTRY_MPU_ATTR_READ : begin // sample on mpu group
      m_mpu_mem_tran_cg_inst.sample(sb_item.m_mpu_req_tran, sb_item);
    end
    sinc_env_pkg::ENTRY_MPU_STATUS_READ : begin // sample on mpu group
      m_mpu_mem_tran_cg_inst.sample(sb_item.m_mpu_req_tran, sb_item);
    end
    sinc_env_pkg::ENTRY_MPU_ATTR_WRITE : begin // sample on mpu group
      m_mpu_mem_tran_cg_inst.sample(sb_item.m_mpu_req_tran, sb_item);
    end
    sinc_env_pkg::ENTRY_MPU_STATUS_WRITE : begin // sample on mpu group
      m_mpu_mem_tran_cg_inst.sample(sb_item.m_mpu_req_tran, sb_item);
    end
    sinc_env_pkg::ENTRY_MPU_UNDEFINED_OP : begin // sample on mpu group
      m_mpu_mem_tran_cg_inst.sample(sb_item.m_mpu_req_tran, sb_item);
    end
    default: begin
      // `uvm_error(get_name(), $sformatf("received unexpected scoreboard entry[%0s]", sb_item.m_sinc_sb_pkt_entry.name()))
    end
  endcase // case (m_sinc_sb_pkt_entry)
endfunction : sample_packet_entry

function void sinc_sb_cov::sample_b2b_entries(sinc_sb_pkt_item sb_item, sinc_sb_pkt_item prev_sb_item);

  if (prev_sb_item !== null) begin
    sinc_req_type_e cur_req;
    sinc_req_type_e prev_req;
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample back to back operation"), UVM_HIGH)

    cur_req  = get_req_type(sb_item);
    prev_req = get_req_type(prev_sb_item);

    m_back_to_back_req_cg_inst.sample(cur_req, prev_req);
  end // if (prev_sb_item !== null)
endfunction : sample_b2b_entries

function void sinc_sb_cov::sample_error_scenarios(sinc_sb_pkt_item sb_item);
  // sample on error injection scenarios
  if (|sb_item.m_sinc_stimulus_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_stimulus_err_types), UVM_HIGH)
    foreach (m_sinc_stimulus_err_cg_insts[i]) begin
      if (sb_item.m_sinc_stimulus_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_stimulus_err_cg_insts[i].sample(sb_item.m_sinc_stimulus_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_mpu_rd_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_mpu_rd_err_types), UVM_HIGH)
    foreach (m_sinc_mpu_rd_err_cg_insts[i]) begin
      if (sb_item.m_sinc_mpu_rd_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_mpu_rd_err_cg_insts[i].sample(sb_item.m_sinc_mpu_rd_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_mpu_wr_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_mpu_wr_err_types), UVM_HIGH)
    foreach (m_sinc_mpu_wr_err_cg_insts[i]) begin
      if (sb_item.m_sinc_mpu_wr_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_mpu_wr_err_cg_insts[i].sample(sb_item.m_sinc_mpu_wr_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_cpu_rd_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_cpu_rd_err_types), UVM_HIGH)
    foreach (m_sinc_cpu_rd_err_cg_insts[i]) begin
      if (sb_item.m_sinc_cpu_rd_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_cpu_rd_err_cg_insts[i].sample(sb_item.m_sinc_cpu_rd_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_cpu_wr_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_cpu_wr_err_types), UVM_HIGH)
    foreach (m_sinc_cpu_wr_err_cg_insts[i]) begin
      if (sb_item.m_sinc_cpu_wr_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_cpu_wr_err_cg_insts[i].sample(sb_item.m_sinc_cpu_wr_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_axi_global_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_axi_global_err_types), UVM_HIGH)
    foreach (m_sinc_axi_global_err_cg_insts[i]) begin
      if (sb_item.m_sinc_axi_global_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_axi_global_err_cg_insts[i].sample(sb_item.m_sinc_axi_global_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_axi_rd_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_axi_rd_err_types), UVM_HIGH)
    foreach (m_sinc_axi_rd_err_cg_insts[i]) begin
      if (sb_item.m_sinc_axi_rd_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_axi_rd_err_cg_insts[i].sample(sb_item.m_sinc_axi_rd_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_axi_wr_reg_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_axi_wr_reg_err_types), UVM_HIGH)
    foreach (m_sinc_axi_wr_reg_err_cg_insts[i]) begin
      if (sb_item.m_sinc_axi_wr_reg_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_axi_wr_reg_err_cg_insts[i].sample(sb_item.m_sinc_axi_wr_reg_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end

  if (|sb_item.m_sinc_axi_wr_fw_cmd_err_types) begin
    `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types [0b%0b]", sb_item.m_sinc_axi_wr_fw_cmd_err_types), UVM_HIGH)
    foreach (m_sinc_axi_wr_fw_cmd_err_cg_insts[i]) begin
      if (sb_item.m_sinc_axi_wr_fw_cmd_err_types[i]) begin
        `uvm_info(get_report_id("sinc_sb_cov"), $sformatf("\nSINC sample on mpu_wr_err_types - [0d%0d]", i), UVM_HIGH)
        m_sinc_axi_wr_fw_cmd_err_cg_insts[i].sample(sb_item.m_sinc_axi_wr_fw_cmd_err_types[i], sb_item.m_cur_cache_state);
      end
    end
  end
endfunction : sample_error_scenarios

`endif // SINC_SB_COV
