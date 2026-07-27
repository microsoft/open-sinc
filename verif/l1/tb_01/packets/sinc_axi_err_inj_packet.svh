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
// File        : sinc_axi_err_inj_packet.svh
// Description : This is AXI packet used to randomize error injection for AXI requests to SINC.

`ifndef SINC_AXI_ERR_INJ_PACKET
`define SINC_AXI_ERR_INJ_PACKET

//---------------------------------
// SINC AXI Packet Class
//---------------------------------
class sinc_axi_err_inj_packet extends sinc_base_packet;

  typedef sinc_axi_err_inj_packet this_t;

  `uvm_object_utils(sinc_axi_err_inj_packet)

  // debug_str
  string          m_debug_str       = "SINC_AXI_ERR_INJ_PACKET";
  // original AXI packet
  sinc_axi_packet m_orig_axi_packet;

  // reg model
  sinc_regmodel m_regmodel;

  // digested request command type
  sinc_cmd_e m_req_cmd;

  // indicate error has been injected
  bit m_err_injected = 0;

  //flags to be used by sequence
  bit m_set_init_aes_test_en_not_clear         = 0;
  bit m_disable_reset_if_not_already_disabled  = 0;
  bit m_disable_reinit_if_not_already_disabled = 0;
  bit m_set_init_rng_seed_failure              = 0;
  bit m_set_init_key_fetch_failure             = 0;
  bit m_encr_block_rd_sharedram_err            = 0;
  bit m_encr_block_wr_ext_mem_cipher_err       = 0;
  bit m_encr_block_wr_ext_mem_tag_err          = 0;

  // Negative test scenarios refer to verification plan - "Key Vault Test Scenario Across TB Platform"

  // AXI access global violations
  rand logic [`SINC_AXI_GLOBAL_ERR_CASE_NUM-1: 0] m_axi_global_err_case_sel;

  // RD access violations
  rand logic [`SINC_AXI_RD_ERR_CASE_NUM-1: 0] m_axi_rd_err_case_sel;

  // WR access violations
  rand logic [`SINC_AXI_WR_REG_ERR_CASE_NUM-1: 0]    m_axi_wr_reg_err_case_sel;
  rand logic [`SINC_AXI_WR_FW_CMD_ERR_CASE_NUM-1: 0] m_axi_wr_fw_cmd_err_case_sel;

  rand bit m_is_global_err;

  // misc applications
  rand pal_addr_t m_addr;

  rand pal_axuser_t m_invalid_axuser;

  rand pal_burst_type_t                      m_bad_burst_type;
  rand pal_beat_size_t                       m_bad_burst_size;
  rand bit [8:0]                             m_burst_length;
  rand sinc_parameters_pkg::sinc_fw_cmd_e    m_invalid_fw_cmd;
  rand bit [`SINC_CMD_REG_SEL_CMD_RANGE_SEL] m_unknown_fw_op;

  rand sinc_parameters_pkg::sinc_reg_e m_invalid_wr_dst_reg;
  rand sinc_parameters_pkg::sinc_reg_e m_read_only_reg;
  rand sinc_parameters_pkg::sinc_reg_e m_write_only_reg;

  rand pal_slv_err_t m_pal_error;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_axi_err_inj_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // pre_randomize()
  //---------------------------------
  function void pre_randomize ();
    string debug_str = "sinc_axi_err_inj_packet_pre_randomize";
    if (m_orig_axi_packet == null) begin
      `uvm_fatal(get_name(), $sformatf("%s: Must set original AXI packet before error injection", debug_str))
    end

    // digest the request
  endfunction : pre_randomize

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // corrupt_axi_global()
  //---------------------------------
  extern virtual function void corrupt_axi_global();

  //---------------------------------
  // corrupt_axi_rd()
  //---------------------------------
  extern virtual function void corrupt_axi_rd();

  //---------------------------------
  // corrupt_axi_wr_reg()
  //---------------------------------
  extern virtual function void corrupt_axi_wr_reg();

  //---------------------------------
  // corrupt_axi_wr_fw_op()
  //---------------------------------
  extern virtual function void corrupt_axi_wr_fw_op();

  //---------------------------------
  // sub_corrupt_byte_addr
  //---------------------------------
  extern virtual function void sub_corrupt_byte_addr(ref string str);

  //---------------------------------
  // sub_corrupt_write_strobe
  //---------------------------------
  extern virtual function void sub_corrupt_write_strobe(ref string str);

  //---------------------------------
  // sub_corrupt_illegal_addr_range
  //---------------------------------
  extern virtual function void sub_corrupt_illegal_addr_range(ref string str);

  //---------------------------------
  // sub_corrupt_burst_type
  //---------------------------------
  extern virtual function void sub_corrupt_burst_type(ref string str);

  //---------------------------------
  // sub_corrupt_burst_type
  //---------------------------------
  extern virtual function void sub_corrupt_illegal_master_access(ref string str);

  //---------------------------------
  // sub_corrupt_burst_len
  //---------------------------------
  extern virtual function void sub_corrupt_burst_size_len(bit corrupt_size, bit corrupt_len, ref string str);

  //---------------------------------
  // sub_corrupt_write_disalowed_reg_in_cur_state
  //---------------------------------
  extern virtual function void sub_corrupt_write_disalowed_reg_in_cur_state(ref string str);

  //---------------------------------
  // sub_corrupt_read_to_write_only
  //---------------------------------
  extern virtual function void sub_corrupt_read_to_write_only(ref string str);

  //---------------------------------
  // sub_corrupt_write_to_read_only
  //---------------------------------
  extern virtual function void sub_corrupt_write_to_read_only(ref string str);

  //---------------------------------
  // sub_corrupt_invalid_cmd_for_state
  //---------------------------------
  extern virtual function void sub_corrupt_invalid_cmd_for_state(ref string str);

  //---------------------------------
  // sub_ovrd_fw_op
  //---------------------------------
  extern virtual function void sub_ovrd_fw_op(sinc_fw_cmd_e ovrd_fw_op, ref string str);

  //---------------------------------
  // sub_corrupt_cmd_rsvd_field
  //---------------------------------
  extern virtual function void sub_corrupt_cmd_rsvd_field(ref string str);

  //---------------------------------
  // sub_corrupt_cmd_sel_w_unknown_op
  //---------------------------------
  extern virtual function void sub_corrupt_cmd_sel_w_unknown_op(ref string str);

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint err_sel_c;

  extern constraint negative_burst_prop_c;

  extern constraint burst_length_c;

  extern constraint negative_addr_range_c;

  extern constraint invalid_axuser_c;

  extern constraint wr_invd_dst_reg_c;

  extern constraint read_only_reg_c;

  extern constraint write_only_reg_c;

  extern constraint invalid_fw_cmd_c;

  extern constraint unknown_fw_op_c;

  extern constraint pal_error_c;

endclass : sinc_axi_err_inj_packet

function void sinc_axi_err_inj_packet::post_randomize ();
  // don't inject error on AES command
  if (m_orig_axi_packet.m_do_fw_request && (m_sys_cfg.m_sinc_err_stimulus_invalid_cmd_for_state == 0) && ((m_orig_axi_packet.m_fw_cmd == SINC_AES_TEST_EN) || (m_orig_axi_packet.m_fw_cmd == SINC_AES_TEST_DISABLE))) begin
    return;
  end

  // override with sys_cfg
  // should consider the constraints as well, note: put in post randomize to decrease the constraint solver time
  // only focus on the specific error
  if (m_sys_cfg.m_sinc_err_stimulus_set_init_rng_seed_failure) begin
      m_axi_global_err_case_sel = 0;
      m_axi_rd_err_case_sel = 0;
      m_axi_wr_reg_err_case_sel    = 0;
    if (m_sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) begin
      m_axi_wr_fw_cmd_err_case_sel = 0;
    end else begin
      m_axi_wr_fw_cmd_err_case_sel                                             = 0;
      m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] = 1;
    end
  end
  else if (m_sys_cfg.m_sinc_err_stimulus_invalid_cmd_for_state) begin
    m_axi_global_err_case_sel = 0;
    m_axi_rd_err_case_sel = 0;
    m_axi_wr_reg_err_case_sel = 0;
    m_axi_wr_fw_cmd_err_case_sel = 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE] = 1;
  end

  if (m_orig_axi_packet.m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_READ) begin
    if (m_is_global_err == 1) begin
      corrupt_axi_global();
    end else begin
      corrupt_axi_rd();
    end
  end

  if (m_orig_axi_packet.m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
    if (m_is_global_err == 1) begin
      corrupt_axi_global();
    end else if (m_orig_axi_packet.m_do_fw_request == 1) begin
      corrupt_axi_wr_fw_op();
    end else begin
      corrupt_axi_wr_reg();
    end
  end

endfunction : post_randomize

function void sinc_axi_err_inj_packet::corrupt_axi_global();
  string str;
  bit    corrupt_size;
  bit    corrupt_len;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_axi_global_err_case_sel : 'h%0h \n", m_axi_global_err_case_sel)};
  if (m_axi_global_err_case_sel[`SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE] : 'h%0h \n", m_axi_global_err_case_sel)};
    sub_corrupt_illegal_addr_range (str);
  end
  if (m_axi_global_err_case_sel[`SINC_AXI_GLOBAL_ERR_NON_SP]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_GLOBAL_ERR_NON_SP] : 'h%0h \n", m_axi_global_err_case_sel)};
    sub_corrupt_illegal_master_access (str);
  end
  if (m_axi_global_err_case_sel[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE] : 'h%0h \n", m_axi_global_err_case_sel)};
    sub_corrupt_burst_type (str);
  end
  if (m_axi_global_err_case_sel[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE]) begin
    corrupt_size = 1;
    corrupt_len  = 0;
    str          = {str, $sformatf("error injected for [SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE] : 'h%0h \n", m_axi_global_err_case_sel)};
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_global_err_case_sel[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN] : 'h%0h \n", m_axi_global_err_case_sel)};
    corrupt_size = 0;
    corrupt_len  = 1;
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_AXI_GLOBAL", str, UVM_HIGH)

endfunction : corrupt_axi_global

function void sinc_axi_err_inj_packet::corrupt_axi_rd();
  string str;
  bit    corrupt_size;
  bit    corrupt_len;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_axi_rd_err_case_sel : 'h%0h \n", m_axi_rd_err_case_sel)};
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_NON_SP]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_NON_SP] : 'h%0h \n", m_axi_rd_err_case_sel)};
    sub_corrupt_illegal_master_access (str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE] : 'h%0h \n", m_axi_rd_err_case_sel)};
    sub_corrupt_burst_type (str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE]) begin
    corrupt_size = 1;
    corrupt_len  = 0;
    str          = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE] : 'h%0h \n", m_axi_rd_err_case_sel)};
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN] : 'h%0h \n", m_axi_rd_err_case_sel)};
    corrupt_size = 0;
    corrupt_len  = 1;
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] : 'h%0h \n", m_axi_rd_err_case_sel)};
    corrupt_size = 1;
    corrupt_len  = 1;
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE] : 'h%0h \n", m_axi_rd_err_case_sel)};
    sub_corrupt_illegal_addr_range (str);
  end
  if (m_axi_rd_err_case_sel[`SINC_AXI_RD_ERR_WR_ONLY_REG]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_WR_ONLY_REG] : 'h%0h \n", m_axi_rd_err_case_sel)};
    sub_corrupt_read_to_write_only (str);
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_AXI_RD", str, UVM_HIGH)

endfunction : corrupt_axi_rd

function void sinc_axi_err_inj_packet::corrupt_axi_wr_fw_op();
  string str;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_axi_wr_fw_cmd_err_case_sel : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};

  if(m_sys_cfg.m_err_inj_prior_trns_no_status_clear) begin
    str = {str, $sformatf("doing fw cmd after error injected for [SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR]\n")};
    //don't want to do another error type when status isn't clear
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_corrupt_invalid_cmd_for_state (str);
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_corrupt_cmd_sel_w_unknown_op (str);
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_corrupt_cmd_rsvd_field (str);
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_SET_INIT_STATE, str);
    m_set_init_rng_seed_failure = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_SET_INIT_STATE, str);
    m_set_init_key_fetch_failure = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_SET_INIT_STATE, str);
    m_set_init_aes_test_en_not_clear = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR]) begin
    str                                              = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    m_orig_axi_packet.m_pull_status_after_fw_request = 0;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID]) begin
    str = {str, $sformatf("SKIP error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    // From SINC perspective, there is no valid or invalid register program value, as long as the slave can be write or response with right data.
    // sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    // sys_cfg.m_err_inj_encr_block_reg_block_encr_num_invalid = 1;
    // m_orig_axi_packet.m_is_valid_req = 0;

  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    m_sys_cfg.m_err_inj_encr_block_reg_num_of_blocks_invalid = 1;
    m_orig_axi_packet.m_is_valid_req                         = 0;
  end
  // SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID shall not be tested, it is FW responsibility program it correctly
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    m_sys_cfg.m_err_inj_encr_block_reg_block_encr_addr_invalid = 1;
    m_orig_axi_packet.m_is_valid_req                           = 0;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    m_encr_block_rd_sharedram_err = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    m_encr_block_wr_ext_mem_cipher_err = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_ENCR_BLOCK, str);
    m_encr_block_wr_ext_mem_tag_err = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR]) begin
    //if reset is disabled override fw op to a reset, otherwise don't corrupt transaction
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_SINC_RESET, str);
    m_disable_reset_if_not_already_disabled = 1;
  end
  if (m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR]) begin
    //if reset is disabled override fw op to a reset, otherwise don't corrupt transaction
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR] : 'h%0h \n", m_axi_wr_fw_cmd_err_case_sel)};
    sub_ovrd_fw_op (SINC_SINC_REINIT, str);
    m_disable_reinit_if_not_already_disabled = 1;
  end

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_AXI_WR_FW_OP", str, UVM_HIGH)

endfunction : corrupt_axi_wr_fw_op

function void sinc_axi_err_inj_packet::corrupt_axi_wr_reg();
  string str;
  bit    corrupt_size;
  bit    corrupt_len;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_axi_wr_reg_err_case_sel : 'h%0h \n", m_axi_wr_reg_err_case_sel)};

  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_NON_SP]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_NON_SP] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_illegal_master_access (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_DISALOWED_REG_IN_CUR_STATE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_DISALOWED_REG_IN_CUR_STATE] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_write_disalowed_reg_in_cur_state (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_ILLEGAL_ADDR_RANGE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_ILLEGAL_ADDR_RANGE] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_illegal_addr_range (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_NON_ALIGNED_BYTE_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_NON_ALIGNED_BYTE_ADDR] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_byte_addr (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_UNSUPPORTED_STROBE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_UNSUPPORTED_STROBE] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_write_strobe (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_TYPE]) begin
    str = {str, $sformatf("error injected for [SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_burst_type (str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE]) begin
    corrupt_size = 1;
    corrupt_len  = 0;
    str          = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    corrupt_size = 0;
    corrupt_len  = 1;
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    corrupt_size = 1;
    corrupt_len  = 1;
    sub_corrupt_burst_size_len (corrupt_size, corrupt_len, str);
  end
  if (m_axi_wr_reg_err_case_sel[`SINC_AXI_WR_ERR_RD_ONLY_REG]) begin
    str          = {str, $sformatf("error injected for [SINC_AXI_WR_ERR_RD_ONLY_REG] : 'h%0h \n", m_axi_wr_reg_err_case_sel)};
    sub_corrupt_write_to_read_only (str);
  end


  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_AXI_WR_REG", str, UVM_HIGH)

endfunction : corrupt_axi_wr_reg

function void sinc_axi_err_inj_packet::sub_corrupt_byte_addr(ref string str);
  logic [1:0] byte_addr;

  m_err_injected = 1;

  if (!(std::randomize(byte_addr) with {
          byte_addr != 2'b00;
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", m_debug_str))
  end

  str                      = {str, $sformatf(" Corrupt request with [ERR_NON_ALIGNED_BYTE_ADDR], original: 'h%0h \n", m_orig_axi_packet.m_addr)};
  m_orig_axi_packet.m_addr = m_orig_axi_packet.m_addr | byte_addr;
  str                      = {str, $sformatf(" Corrupt request with [ERR_NON_ALIGNED_BYTE_ADDR], corrupted: 'h%0h \n", m_orig_axi_packet.m_addr)};

endfunction : sub_corrupt_byte_addr

function void sinc_axi_err_inj_packet::sub_corrupt_write_disalowed_reg_in_cur_state(ref string str);
  logic [1:0] byte_addr;
  uvm_reg     my_reg;

  //all regs can be written in disabled state so do nothing
  if(m_sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) begin
    m_err_injected = 1;

    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_write_disalowed_reg_in_cur_state], original: 'h%0h \n", m_orig_axi_packet.m_addr)};
    my_reg                   = m_regmodel.get_reg_by_name(m_invalid_wr_dst_reg.name().tolower());
    m_orig_axi_packet.m_addr = my_reg.get_address();
    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_write_disalowed_reg_in_cur_state], corrupted: 'h%0h \n", m_orig_axi_packet.m_addr)};
  end
endfunction : sub_corrupt_write_disalowed_reg_in_cur_state

function void sinc_axi_err_inj_packet::sub_corrupt_read_to_write_only(ref string str);
  logic [1:0] byte_addr;
  uvm_reg     my_reg;

  //all regs can be written in disabled state so do nothing
  if(m_sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) begin
    m_err_injected = 1;

    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_read_to_write_only], original: 'h%0h \n", m_orig_axi_packet.m_addr)};
    my_reg                   = m_regmodel.get_reg_by_name(m_write_only_reg.name().tolower());
    m_orig_axi_packet.m_addr = my_reg.get_address();
    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_read_to_write_only], corrupted: 'h%0h \n", m_orig_axi_packet.m_addr)};
  end
endfunction : sub_corrupt_read_to_write_only

function void sinc_axi_err_inj_packet::sub_corrupt_write_to_read_only(ref string str);
  logic [1:0] byte_addr;
  uvm_reg     my_reg;

  //all regs can be written in disabled state so do nothing
  if(m_sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) begin
    m_err_injected = 1;

    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_write_to_read_only], original: 'h%0h \n", m_orig_axi_packet.m_addr)};
    my_reg                   = m_regmodel.get_reg_by_name(m_read_only_reg.name().tolower());
    m_orig_axi_packet.m_addr = my_reg.get_address();
    str                      = {str, $sformatf(" Corrupt request with [sub_corrupt_write_to_read_only], corrupted: 'h%0h \n", m_orig_axi_packet.m_addr)};
  end
endfunction : sub_corrupt_write_to_read_only

function void sinc_axi_err_inj_packet::sub_corrupt_write_strobe(ref string str);
  bit currupt_en;

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_STROBE], original: %0p \n", m_orig_axi_packet.m_wstrb)};

  for (int di=0; di < m_orig_axi_packet.m_wstrb.size(); di++) begin
    if (!(std::randomize(currupt_en) with {
            //
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", m_debug_str))
    end

    if (currupt_en) begin
      m_orig_axi_packet.m_wstrb[di] = 0;
    end
  end

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_STROBE], corrupted: %0p \n", m_orig_axi_packet.m_wstrb)};

endfunction : sub_corrupt_write_strobe

function void sinc_axi_err_inj_packet::sub_corrupt_burst_size_len(bit corrupt_size, bit corrupt_len, ref string str);
  int data_size;
  // int data_beats;

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_BYTES], original size: 'h%0h, burst size: %0s, burst type: %0s \n", m_orig_axi_packet.m_read_data.size(), m_orig_axi_packet.m_burst_size.name(), m_orig_axi_packet.m_burst_type.name())};

  if((corrupt_size == 1)) begin
    m_orig_axi_packet.m_burst_size = m_bad_burst_size;
    //burst type needs to not be fixed for this to be valid
    m_orig_axi_packet.m_burst_type = PAL_BT_INCR;
    m_err_injected                 = 1;
  end

  if(corrupt_len) begin
    if (!(std::randomize(data_size) with {
            data_size inside {1, 2, 8, 12, 16, 20, 24, 28, 32};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", m_debug_str))
    end

    if (m_orig_axi_packet.m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
      m_orig_axi_packet.m_write_data.delete();
      m_orig_axi_packet.m_write_data = new[data_size];
      m_orig_axi_packet.m_wstrb.delete();
      m_orig_axi_packet.m_wstrb = new[m_orig_axi_packet.m_write_data.size()];
      for (int di=0; di < m_orig_axi_packet.m_write_data.size(); di++) begin
        m_orig_axi_packet.m_wstrb[di] = 1;
      end
      if (!std::randomize(m_orig_axi_packet.m_write_data)) begin
        `uvm_fatal(get_name(), "Unable to randomize wdata")
      end
    end else begin
      m_orig_axi_packet.m_read_data.delete();
      m_orig_axi_packet.m_read_data = new[data_size];
    end

    m_err_injected = 1;
  end

  // if(corrupt_len) begin
  //   if (!(std::randomize(data_beats) with {
  //     data_beats inside {1, 2, 8, 12, 16, 20, 24, 28, 32};
  //   })) begin
  //     `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  //   end
  // end begin
  //   data_beats = 1;
  // end

  // if(m_orig_axi_packet.r_burst_size == PAL_BYTES_1) begin
  //   data_size = data_beats;
  // end else if(m_orig_axi_packet.r_burst_size == PAL_BYTES_2) begin
  //   data_size = data_beats * 2;
  // end else begin
  //   data_size = data_beats * 4;
  // end

  // if (m_orig_axi_packet.m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
  //   m_orig_axi_packet.r_write_data.delete();
  //   m_orig_axi_packet.r_write_data = new[data_size];
  //   m_orig_axi_packet.r_wstrb.delete();
  //   m_orig_axi_packet.r_wstrb  = new[m_orig_axi_packet.r_write_data.size()];
  //   for (int di=0; di < m_orig_axi_packet.r_write_data.size(); di++) begin
  //     m_orig_axi_packet.r_wstrb[di] = 1;
  //   end
  // end else begin
  //   m_orig_axi_packet.r_read_data.delete();
  //   m_orig_axi_packet.r_read_data = new[data_size];
  // end

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_BYTES], corrupted size: 'h%0h, burst size: %0s, burst type: %0s  \n", m_orig_axi_packet.m_read_data.size(), m_orig_axi_packet.m_burst_size.name(), m_orig_axi_packet.m_burst_type.name())};

endfunction : sub_corrupt_burst_size_len

function void sinc_axi_err_inj_packet::sub_corrupt_illegal_addr_range(ref string str);
  str                      = {str, $sformatf(" Corrupt request with [ERR_ILLEGAL_ADDR_RANGE], original: 'h%0h \n", m_orig_axi_packet.m_addr)};
  m_orig_axi_packet.m_addr = m_addr;
  str                      = {str, $sformatf(" Corrupt request with [ERR_ILLEGAL_ADDR_RANGE], corrupted: 'h%0h \n", m_orig_axi_packet.m_addr)};
endfunction : sub_corrupt_illegal_addr_range

function void sinc_axi_err_inj_packet::sub_corrupt_illegal_master_access(ref string str);

  str = {str, $sformatf(" Corrupt request with [ERR_ILLEGAL_MASTER], original master ['h%0h] \n", m_orig_axi_packet.m_axuser[`SINC_AXI_MID_USER_RANGE])};

  str = {str, $sformatf(" Corrupt request with [ERR_ILLEGAL_MASTER], change master to : 'h%0h \n", m_invalid_axuser[`SINC_AXI_MID_USER_RANGE])};

  m_orig_axi_packet.m_axuser = m_invalid_axuser;

  str = {str, $sformatf(" Corrupt request with [ERR_ILLEGAL_MASTER], corrupted addr: 'h%0h \n", m_orig_axi_packet.m_addr)};
endfunction : sub_corrupt_illegal_master_access

function void sinc_axi_err_inj_packet::sub_corrupt_burst_type(ref string str);

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_BURST_TYPE], original size: 'h%0h, burst size: %0s, burst type: %0s \n", m_orig_axi_packet.m_read_data.size(), m_orig_axi_packet.m_burst_size.name(), m_orig_axi_packet.m_burst_type.name())};

  m_orig_axi_packet.m_burst_type = m_bad_burst_type;

  str = {str, $sformatf(" Corrupt request with [ERR_UNSUPPORTED_BURST_TYPE], corrupted size: 'h%0h, burst size: %0s, burst type: %0s  \n", m_orig_axi_packet.m_read_data.size(), m_orig_axi_packet.m_burst_size.name(), m_orig_axi_packet.m_burst_type.name())};

endfunction : sub_corrupt_burst_type

function void sinc_axi_err_inj_packet::sub_corrupt_cmd_rsvd_field(ref string str);
  uvm_reg_data_t rand_reg_value;

  m_err_injected = 1;

  if (!(std::randomize(rand_reg_value) with {
          //
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", m_debug_str))
  end

  str                                                         = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_RSVD_FIELD], original reg_value: 'h%0h, write_data: %0p \n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};
  m_orig_axi_packet.m_reg_value[`SINC_CMD_REG_RSVD_RANGE_SEL] = rand_reg_value[`SINC_CMD_REG_RSVD_RANGE_SEL];
  foreach(m_orig_axi_packet.m_write_data[i]) begin
    m_orig_axi_packet.m_write_data[i] = m_orig_axi_packet.m_reg_value[8*i +: 8];
  end
  str = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_RSVD_FIELD], corrupted: reg_value: 'h%0h, write_data: %0p\n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};

endfunction : sub_corrupt_cmd_rsvd_field

function void sinc_axi_err_inj_packet::sub_corrupt_cmd_sel_w_unknown_op(ref string str);
  m_err_injected = 1;

  str                                                            = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_SEL_W_UNKNOWN_OP], original reg_value: 'h%0h, write_data: %0p \n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};
  m_orig_axi_packet.m_reg_value[`SINC_CMD_REG_SEL_CMD_RANGE_SEL] = m_unknown_fw_op;
  foreach(m_orig_axi_packet.m_write_data[i]) begin
    m_orig_axi_packet.m_write_data[i] = m_orig_axi_packet.m_reg_value[8*i +: 8];
  end
  str = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_SEL_W_UNKNOWN_OP], corrupted: reg_value: 'h%0h, write_data: %0p\n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};

endfunction : sub_corrupt_cmd_sel_w_unknown_op

function void sinc_axi_err_inj_packet::sub_corrupt_invalid_cmd_for_state(ref string str);
  m_err_injected = 1;

  str                           = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_INVALID_FOR_STATE], original reg_value: 'h%0h, write_data: %0p \n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};
  m_orig_axi_packet.m_reg_value = m_invalid_fw_cmd;
  m_orig_axi_packet.m_fw_cmd = m_invalid_fw_cmd;
  foreach(m_orig_axi_packet.m_write_data[i]) begin
    m_orig_axi_packet.m_write_data[i] = m_orig_axi_packet.m_reg_value[8*i +: 8];
  end
  str = {str, $sformatf(" Corrupt request with [ERR_PROGRAM_CMD_INVALID_FOR_STATE], corrupted: reg_value: 'h%0h, write_data: %0p\n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};

endfunction : sub_corrupt_invalid_cmd_for_state

function void sinc_axi_err_inj_packet::sub_ovrd_fw_op(sinc_fw_cmd_e ovrd_fw_op, ref string str);
  m_err_injected = 1;

  str                           = {str, $sformatf(" override request fw op, original reg_value: 'h%0h, write_data: %0p \n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};
  m_orig_axi_packet.m_reg_value = ovrd_fw_op;
  m_orig_axi_packet.m_fw_cmd = ovrd_fw_op;
  foreach(m_orig_axi_packet.m_write_data[i]) begin
    m_orig_axi_packet.m_write_data[i] = m_orig_axi_packet.m_reg_value[8*i +: 8];
  end
  str = {str, $sformatf(" override request fw op, changed: reg_value: 'h%0h, write_data: %0p\n", m_orig_axi_packet.m_reg_value, m_orig_axi_packet.m_write_data)};

endfunction : sub_ovrd_fw_op

function void sinc_axi_err_inj_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Corrupt AXI Request on Iter_Num [%0d]: \n", iter_n)};

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_AXI_ERR_INJ_PACKET", str, UVM_HIGH)

endfunction : print_packet

constraint sinc_axi_err_inj_packet::err_sel_c {
  $countones(m_axi_global_err_case_sel) == 1;
  $countones(m_axi_rd_err_case_sel) == 1;
  $countones(m_axi_wr_reg_err_case_sel) == 1;
  $countones(m_axi_wr_fw_cmd_err_case_sel) == 1;

  // SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID shall not be tested, it is FW responsibility program it correctly
  m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] == 0;

  if ((m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) && m_sys_cfg.m_sinc_err_stimulus_set_encr_block_failure) {
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR] == 0;
  }

  if(m_sys_cfg.m_sinc_tb_seq_never_dis_cmds) {
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR] == 0;
  }

  if(m_sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) {
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR] == 0;
  }

  if(m_sys_cfg.m_cur_cache_state != CACHE_INIT_STATE) {
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR] == 0;
    m_axi_wr_fw_cmd_err_case_sel[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR] == 0;
  }

  m_is_global_err dist {
    0 := 95,
    1 := 5
  };
}

constraint sinc_axi_err_inj_packet::negative_burst_prop_c {
  // m_bad_burst_type inside {PAL_BT_WRAP, PAL_BT_RSVD};
  // Note: WRAP type is commented out due to VIP constraint issue
  m_bad_burst_type inside {PAL_BT_RSVD};
  m_bad_burst_size inside {PAL_BYTES_1, PAL_BYTES_2};
}

constraint sinc_axi_err_inj_packet::burst_length_c {
  m_burst_length inside {[1:16]};

  (m_bad_burst_type == PAL_BT_WRAP) -> { (m_burst_length inside {2, 4, 8, 16}); }
}

constraint sinc_axi_err_inj_packet::negative_addr_range_c {
  m_addr[1:0] == 'h0;

  m_addr inside {[RESERVED_REGION_0_START_ADDR : RESERVED_REGION_0_END_ADDR], [RESERVED_REGION_1_START_ADDR : RESERVED_REGION_1_END_ADDR]};
}

constraint sinc_axi_err_inj_packet::invalid_axuser_c {
  m_invalid_axuser[`SINC_AXI_MID_USER_RANGE] != sinc_parameters_pkg::SP_MST_ID;
}

constraint sinc_axi_err_inj_packet::wr_invd_dst_reg_c {

  if(m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) {
    m_invalid_wr_dst_reg inside {sinc_parameters_pkg::BLOCK_ENCR_KEY, sinc_parameters_pkg::AES_IV_NONCE_0, sinc_parameters_pkg::AES_IV_NONCE_1, sinc_parameters_pkg::AES_IV_NONCE_2};
  }

  if(m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) {
    m_invalid_wr_dst_reg inside {sinc_parameters_pkg::BLOCK_ENCR_NUM, sinc_parameters_pkg::NUM_OF_BLOCKS, sinc_parameters_pkg::BLOCK_ENCR_ADDR, sinc_parameters_pkg::BLOCK_ENCR_KEY, sinc_parameters_pkg::AES_IV_NONCE_0, sinc_parameters_pkg::AES_IV_NONCE_1, sinc_parameters_pkg::AES_IV_NONCE_2, sinc_parameters_pkg::EXT_BLOCK_BASE_ADDR, sinc_parameters_pkg::EXT_AUTH_TAG_BASE_ADDR};
  }

  if(m_sys_cfg.m_cur_cache_state == CACHE_FAIL_STATE) {
    m_invalid_wr_dst_reg inside {sinc_parameters_pkg::BLOCK_ENCR_NUM, sinc_parameters_pkg::NUM_OF_BLOCKS, sinc_parameters_pkg::BLOCK_ENCR_ADDR, sinc_parameters_pkg::BLOCK_ENCR_KEY, sinc_parameters_pkg::AES_IV_NONCE_0, sinc_parameters_pkg::AES_IV_NONCE_1, sinc_parameters_pkg::AES_IV_NONCE_2, sinc_parameters_pkg::EXT_BLOCK_BASE_ADDR, sinc_parameters_pkg::EXT_AUTH_TAG_BASE_ADDR};
  }

}

constraint sinc_axi_err_inj_packet::read_only_reg_c {
  m_read_only_reg inside {sinc_parameters_pkg::STATUS, sinc_parameters_pkg::HIT_CNTR_LOWER, sinc_parameters_pkg::HIT_CNTR_UPPER, sinc_parameters_pkg::MISS_CNTR_LOWER,sinc_parameters_pkg::MISS_CNTR_UPPER, sinc_parameters_pkg::LAT_CNTR_LOWER, sinc_parameters_pkg::LAT_CNTR_UPPER, sinc_parameters_pkg::AES_TEST_DATA_OUT_0,sinc_parameters_pkg::AES_TEST_DATA_OUT_1, sinc_parameters_pkg::AES_TEST_DATA_OUT_2, sinc_parameters_pkg::AES_TEST_DATA_OUT_3, sinc_parameters_pkg::AES_TEST_STATUS, sinc_parameters_pkg::ENCR_BLOCK_STATUS};
}

constraint sinc_axi_err_inj_packet::write_only_reg_c {
  m_write_only_reg  == sinc_parameters_pkg::CMD;
}

constraint sinc_axi_err_inj_packet::unknown_fw_op_c {

  $countones(m_unknown_fw_op) > 1;
}

constraint sinc_axi_err_inj_packet::invalid_fw_cmd_c {

  (m_sys_cfg.m_cur_cache_state == CACHE_DISABLE_STATE) -> {
    m_invalid_fw_cmd inside {SINC_SET_CACHE_ACTIVE_STATE, SINC_ENCR_BLOCK, SINC_SINC_RESET, SINC_SINC_REINIT};
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) -> {
    m_invalid_fw_cmd inside {SINC_SET_INIT_STATE, SINC_AES_TEST_EN, SINC_SINC_REINIT};
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) -> {
    m_invalid_fw_cmd inside {SINC_SET_INIT_STATE, SINC_AES_TEST_EN, SINC_SET_CACHE_ACTIVE_STATE, SINC_ENCR_BLOCK};
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_FAIL_STATE) -> {
    m_invalid_fw_cmd inside {SINC_SET_INIT_STATE, SINC_AES_TEST_EN, SINC_SINC_REINIT, SINC_SET_CACHE_ACTIVE_STATE, SINC_ENCR_BLOCK};
  }
}

constraint sinc_axi_err_inj_packet::pal_error_c {
  m_pal_error inside {SLVERR, DECERR};
}

`endif // SINC_AXI_ERR_INJ_PACKET
