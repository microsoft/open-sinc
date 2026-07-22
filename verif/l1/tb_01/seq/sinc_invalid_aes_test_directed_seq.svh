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
// File        : sinc_invalid_aes_test_directed_seq.svh
// Description : 

`ifndef SINC_INVALID_AES_TEST_DIRECTED_SEQ
`define SINC_INVALID_AES_TEST_DIRECTED_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_invalid_aes_test_directed_seq
//------------------------------------------------------------------------------

typedef enum {
  INVALID_MODE     = 0,
  INVALID_KEY_LEN_ECB  = 1,
  INVALID_KEY_LEN_GCM  = 2,
  INVALID_BYTE_CNT_ECB = 3,
  INVALID_BYTE_CNT_GCM = 4,
  INVALID_AAD          = 5,
  INVALID_EXIT_BEFORE_TAG_ACK1          = 6,
  INVALID_EXIT_BEFORE_DOUT_ACK1          = 7,
  INVALID_EXIT_BEFORE_DIN_VLD1          = 8,
  INVALID_EXIT_BEFORE_TAG_ACK2          = 9,
  INVALID_EXIT_BEFORE_DOUT_ACK2          = 10,
  INVALID_EXIT_BEFORE_DIN_VLD2          = 11,
  VALID_AES_TEST                        = 12
} sinc_aes_err_e;

/**
 * SINC Sanity Test Sequence
 */
class sinc_invalid_aes_test_directed_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_invalid_aes_test_directed_seq)

  // copy of prior key for reuse key and bit to see if we have established an initial key
  sinc_key_t m_reuse_key_data;
  bit        m_initial_key_set = 0;
  uvm_reg_data_t status_reg;

  function new(string name="sinc_invalid_aes_test_directed_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();
  endfunction : new

  extern virtual task sequential_run_body();
  extern virtual task start_erase_optional();
  extern virtual task body();
  extern virtual task aes_test_mode(sinc_aes_err_e err_type);
  extern virtual function void process_plusargs_and_populate_seq_item();
  extern virtual task print_status(uvm_reg_data_t status_reg_i, string str);

endclass : sinc_invalid_aes_test_directed_seq

task sinc_invalid_aes_test_directed_seq::start_erase_optional();
  string       debug_str        = "start_erase_optional_body";
  logic [31:0] erase_data_value;

  `uvm_info(get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

  // ramwrap_ecc_error_inj_w_addr (1, 0, 0);

  // start erase
  if (!std::randomize(erase_data_value)) begin
    `uvm_fatal(get_name(), "Unable to randomize erase_data_value")
  end

  // start cache erase
  fork: sinc_sanity_erase_fork
    begin
      m_erase_rand_seq.erase_cache();
    end
  join: sinc_sanity_erase_fork

  `uvm_info(get_name(), $sformatf("%s: ended", debug_str), UVM_LOW)

  // re-initialize Cache Storage Directory as the cache mem has been wiped
  m_csd.init_csd(.en_bkdoor_load(1));
  m_sys_cfg.prepare_sys_cfg();

  // preload_encrypted_blocks
  //preload_encrypted_blocks(.prog_all(1));

endtask : start_erase_optional

task sinc_invalid_aes_test_directed_seq::sequential_run_body();
  string         debug_str = "sequential_run_body";
  bit            timeout;

  `uvm_info(get_name(), $sformatf("%s: Inside sinc_invalid_aes_test_directed_seq", debug_str), UVM_LOW)

  aes_test_mode(INVALID_MODE);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_KEY_LEN_ECB);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_KEY_LEN_GCM);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_AAD);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_BYTE_CNT_ECB);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_BYTE_CNT_GCM);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_TAG_ACK1);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_DOUT_ACK1);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_DIN_VLD1);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_TAG_ACK2);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_DOUT_ACK2);
  aes_test_mode(VALID_AES_TEST);
  aes_test_mode(INVALID_EXIT_BEFORE_DIN_VLD2);
  aes_test_mode(VALID_AES_TEST);


endtask : sequential_run_body

task sinc_invalid_aes_test_directed_seq::body();
  super.body();

  test_done();
endtask : body

function void sinc_invalid_aes_test_directed_seq:: process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_INVALID_AES_TEST_DIRECTED_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

endfunction : process_plusargs_and_populate_seq_item

task sinc_invalid_aes_test_directed_seq::print_status(uvm_reg_data_t status_reg_i, string str);
  if (status_reg_i[`SINC_REGS_STATUS_CMD_SUCCESS_MSB] === 'h1) begin
    `uvm_info(get_name(), $sformatf("aes_test_mode %s finished with cmd success",str), UVM_LOW)
  end
  else if(status_reg_i[`SINC_REGS_STATUS_CMD_FAILED_MSB] === 'h1) begin
    if (status_reg_i[`SINC_REGS_STATUS_INVALID_CMD_ERR_MSB] === 'h1) begin
      `uvm_info(get_name(), $sformatf("aes_test_mode %s finished with cmd failed and invalid cmd err",str), UVM_LOW)
    end
    else begin
      `uvm_info(get_name(), $sformatf("aes_test_mode %s finished with cmd failed, status reg is 'h%0h",str,status_reg_i), UVM_LOW)
    end
  end
  else begin
      `uvm_info(get_name(), $sformatf("aes_test_mode %s finished with unknown status reg 'h%0h",str,status_reg_i), UVM_LOW)
    end
endtask : print_status

task sinc_invalid_aes_test_directed_seq::aes_test_mode(sinc_aes_err_e err_type);
  string          debug_str                = "DV::aes_test_mode";
  sinc_aes_packet aes_pkt;
  sinc_axi_data_t tmp_axi_data[];
  uvm_reg_data_t  uvm_reg_data[10];                              // reserved to save intermidia reg data
  bit             timeout;
  bit             last_data_segment;
  int             num_data_segments;
  aes_cmd_mode_e  aes_mode_invalid;
  bit [1:0]       keylen_invalid;
  bit [4:0]       data_in_byte_cnt_invalid;
  bit [1:0]       keylen;
  int             data_in_byte_cnt;
  bit aad;
  uvm_reg my_reg;
  sinc_parameters_pkg::sinc_reg_e m_reg;
  pal_addr_t       m_addr_aes_test_status;
  pal_addr_t       m_addr_sinc_status;
  bit [7:0]        m_rd_data_aes_test_status[];
  bit [31:0]       m_rd_data_sinc_status_32;
  pal_resp_type_t  m_response;
  int read_count;

  m_rd_data_aes_test_status = new[4];

  m_reg = sinc_parameters_pkg::AES_TEST_STATUS;
  my_reg = m_regmodel.get_reg_by_name(m_reg.name().tolower());
  m_addr_aes_test_status = my_reg.get_address();

  m_reg = sinc_parameters_pkg::STATUS;
  my_reg = m_regmodel.get_reg_by_name(m_reg.name().tolower());
  m_addr_sinc_status = my_reg.get_address();

  `uvm_info(get_name(), $sformatf("Starting aes_test_mode %s", err_type.name()), UVM_LOW)

  if (!(std::randomize(aes_mode_invalid) with {
          !(aes_mode_invalid inside {sinc_parameters_pkg::ECB,
              sinc_parameters_pkg::GCM});
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  if (!(std::randomize(keylen_invalid) with {
          keylen_invalid != 2;
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  if (!(std::randomize(data_in_byte_cnt_invalid) with {
          data_in_byte_cnt_invalid < 16;
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  aes_pkt                 = sinc_aes_packet::type_id::create("aes_pkt", , get_full_name());
  aes_pkt.m_aes_test_mode = 1;
  if(m_initial_key_set == 1) begin
    aes_pkt.m_reuse_key_data = m_reuse_key_data;
  end

  if (!aes_pkt.randomize() with {
        m_reuse_key == 0;
        m_byte_count == 16;
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  if(err_type == INVALID_MODE) begin
    aes_pkt.m_aes_mode = aes_mode_invalid;
  end else if((err_type == INVALID_BYTE_CNT_ECB)||(err_type == INVALID_KEY_LEN_ECB)) begin
    aes_pkt.m_aes_mode = sinc_parameters_pkg::ECB;
  end else if((err_type == INVALID_BYTE_CNT_GCM)||(err_type == INVALID_KEY_LEN_GCM)||
              (err_type == INVALID_EXIT_BEFORE_TAG_ACK1)||(err_type == INVALID_EXIT_BEFORE_TAG_ACK2)) begin
    aes_pkt.m_aes_mode = sinc_parameters_pkg::GCM;
  end

  if((err_type == INVALID_KEY_LEN_ECB)||(err_type == INVALID_KEY_LEN_GCM)) begin
    keylen = keylen_invalid;
  end else begin
    keylen = 2;
  end

  if((err_type == INVALID_BYTE_CNT_ECB)||(err_type == INVALID_BYTE_CNT_GCM)) begin
    data_in_byte_cnt = data_in_byte_cnt_invalid;
  end else begin
    data_in_byte_cnt = 16;
  end

  if(err_type == INVALID_AAD) begin
    aad = 1;
  end else begin
    aad = 0;
  end

  `uvm_info (get_name(), $sformatf("RAND_INFO: err_type[%0s] aes_op: [%0s] aes_mode: [%0s] reuse_key: [%0d] byte_count: [%0d] keylen: [%0d]", err_type.name(), aes_pkt.m_aes_op.name(), aes_pkt.m_aes_mode.name(), aes_pkt.m_reuse_key, aes_pkt.m_byte_count, keylen), UVM_LOW)

  aes_pkt.print_packet();
  aes_pkt.cal_rslt_w_c_model();
  if(aes_pkt.m_reuse_key == 0) begin
    m_reuse_key_data  = aes_pkt.m_key_data;
    m_initial_key_set = 1;
  end

  // preload key data
  `uvm_info (get_name(), $sformatf("%s: do backdoor key load", debug_str), UVM_LOW)
  load_key_to_axi_mem(aes_pkt.m_key_axi_addr, aes_pkt.m_key_data);
  fetch_data_from_axi_mem(aes_pkt.m_key_axi_addr, 32, tmp_axi_data);

  // Recover from a prior CACHE_FAIL before (re)entering AES test mode.
  // An invalid AES test input (e.g. an out-of-range GCM data_in_byte_cnt) makes
  // the GP-AES core signal an error; SINC classifies this as a severe AES error
  // and moves to the Cache-failed state (MAS 10.1 / Table 4 severe errors).
  // AES test mode can only be entered from the Disabled state, and the only way
  // out of Cache-failed is a SINC reset command (MAS 10.1). Without this
  // recovery the next AES test command is rejected and cfg_key_iv_rdy never
  // asserts, hanging the following (valid) iteration.
  pull_status(status_reg, timeout);
  if (status_reg[`SINC_REGS_STATUS_STATE_RANGE] == sinc_parameters_pkg::CACHE_FAIL_STATE) begin
    `uvm_info(get_name(), $sformatf("%s: SINC in CACHE_FAIL, issuing SINC reset to recover to DISABLED before %s", debug_str, err_type.name()), UVM_LOW)
    fw_sinc_reset_cmd();
    pull_status(status_reg, timeout);
    if (status_reg[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
      `uvm_error(get_name(), $sformatf("%s: SINC reset did not return to DISABLED, status['h%0h] -- skipping AES test enable for %s", debug_str, status_reg, err_type.name()))
      return;
    end
  end

  // 1.        FW sets aes_test_en field to 1 in cmd register to enter AES test mode.
  aes_test_enable();
  `uvm_info (get_name(), $sformatf("%s: enable test mode", debug_str), UVM_LOW)

  // 2.        FW loads block_encr_key and aes_iv_nonce* registers.
  aes_load_key_iv_nonce(aes_pkt.m_aes_iv_nonce_regs[0], aes_pkt.m_aes_iv_nonce_regs[1], aes_pkt.m_aes_iv_nonce_regs[2], aes_pkt.m_key_slot);
  `uvm_info (get_name(), $sformatf("%s: set aes_iv_nonce_* registers", debug_str), UVM_LOW)

  // 3.        FW waits for cfg_key_iv_rdy = 1 in aes_test_status register.
  `uvm_info (get_name(), $sformatf("%s: about to wait till cfg_key_iv_rdy == 1", debug_str), UVM_LOW)
  //wait_aes_status(.cfg_key_iv_rdy(1), .data_in_rdy(0), .data_out_vld(0), .tag_out(0), .timeout(timeout));
  //`uvm_info (get_name(), $sformatf("%s: wait till cfg_key_iv_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

  /*
  m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
  m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_sinc_status), .read_data(m_rd_data_sinc_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
  m_rd_data_sinc_status_32 = {m_rd_data_sinc_status[3],m_rd_data_sinc_status[2],m_rd_data_sinc_status[1],m_rd_data_sinc_status[0]};
  read_count = 0;
  while((m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_RANGE] == 0) &&
        (m_rd_data_sinc_status_32[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] == 0) &&
        (read_count < 100)) begin
    m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
    m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_sinc_status), .read_data(m_rd_data_sinc_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
    m_rd_data_sinc_status_32 = {m_rd_data_sinc_status[3],m_rd_data_sinc_status[2],m_rd_data_sinc_status[1],m_rd_data_sinc_status[0]};
    read_count = read_count + 1;
  end
  */

  m_rd_data_aes_test_status[0] = 0;
  read_count = 0;
  while((m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_IN_RDY_RANGE] == 0) && (read_count < 100)) begin
    m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
    read_count = read_count + 1;
  end
  `uvm_info (get_name(), $sformatf("%s: wait till cfg_key_iv_rdy == 1, read_count[%0d], m_rd_data_aes_test_status[x%0h], m_rd_data_sinc_status_32[x%0h]", debug_str, read_count, m_rd_data_aes_test_status[0], m_rd_data_sinc_status_32), UVM_LOW)


  if(m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_RANGE] == 0) begin
  //if(timeout) begin
    `uvm_error(get_name(), $sformatf("wait_aes_status never saw cfg_key_iv_rdy go high"))
    aes_test_disable();
    wait_n_clks(5);
    pull_status(status_reg, timeout);
    wait_n_clks(10);
    print_status(status_reg, err_type.name());
    return;
  end

  // 4.        FW loads mode, dir, key_len fields, set cfg_key_iv_vld = 1, and data_in_vld = 0 in the aes_test_ctrl register. FW can additionally set reuse_key = 1 if it wants to reuse previously loaded key.
  // aes_load_ctrl_mode_dir_keylen(.mode(sinc_parameters_pkg::GCM), .dir(sinc_parameters_pkg::ENCRYPT), .key_len(2), .reuse_key(0));
  aes_load_ctrl_mode_dir_keylen(.mode(aes_pkt.m_aes_mode), .dir(aes_pkt.m_aes_op), .key_len(keylen), .reuse_key(aes_pkt.m_reuse_key));
  `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_mode_dir_keylen", debug_str), UVM_LOW)

  if((err_type == INVALID_MODE)||(err_type == INVALID_KEY_LEN_ECB)||(err_type == INVALID_KEY_LEN_GCM)) begin
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    if (!(status_reg[`SINC_REGS_STATUS_INVALID_CMD_ERR_MSB] === 'h1)) begin
      `uvm_error(get_name(), $sformatf("%s: Expected invalid cmd error but didn't see one status reg['h%0h]", debug_str, status_reg))
      aes_test_disable();
      pull_status(status_reg, timeout);
    end
    print_status(status_reg, err_type.name());
    return;
  end

  if(err_type==INVALID_EXIT_BEFORE_DIN_VLD1) begin
    aes_test_disable();
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    return;
  end

  // 5.        FW loads aes_test_data_in* registers.
  // aes_load_test_data_in(aes_test_data_in_0, aes_test_data_in_1, aes_test_data_in_2, aes_test_data_in_3);
  aes_load_test_data_in(aes_pkt.m_aes_message[0], aes_pkt.m_aes_message[1], aes_pkt.m_aes_message[2], aes_pkt.m_aes_message[3]);

  `uvm_info (get_name(), $sformatf("%s: set aes_load_test_data_in", debug_str), UVM_LOW)

  // 6.        FW waits for data_in_rdy = 1 in aes_test_status register.
  //wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(1), .data_out_vld(0), .tag_out(0), .timeout(timeout));
  //`uvm_info (get_name(), $sformatf("%s: wait till data_in_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)
  m_rd_data_aes_test_status[0] = 0;
  read_count = 0;
  while((m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_IN_RDY_RANGE] == 0) && (read_count < 100)) begin
    m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
    read_count = read_count + 1;
  end
  `uvm_info (get_name(), $sformatf("%s: wait till data_in_rdy == 1, read_count[%0d], m_rd_data_aes_test_status[x%0h]", debug_str, read_count, m_rd_data_aes_test_status[0]), UVM_LOW)
  if(m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_IN_RDY_RANGE] == 0) begin
  //if(timeout) begin
    `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_in_rdy go high"))
    aes_test_disable();
    wait_n_clks(5);
    pull_status(status_reg, timeout);
    wait_n_clks(10);
    print_status(status_reg, err_type.name());
    return;
  end

  if(err_type==INVALID_EXIT_BEFORE_DIN_VLD2) begin
    aes_test_disable();
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    return;
  end

  // 7.        FW loads data_in_byte_cnt and data_in_last fields and set data_in_vld = 1 in the aes_test_ctrl register.
  aes_load_ctrl_bytecnt_last(.aes_data_in_byte_cnt(data_in_byte_cnt), .data_in_last(1), .aad(aad));
  `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_bytecnt_last", debug_str), UVM_LOW)

  if(err_type == INVALID_AAD) begin
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    if (!(status_reg[`SINC_REGS_STATUS_INVALID_CMD_ERR_MSB] === 'h1)) begin
      `uvm_error(get_name(), $sformatf("%s: Expected invalid cmd error but didn't see one status reg['h%0h]", debug_str, status_reg))
      aes_test_disable();
      pull_status(status_reg, timeout);
    end
    print_status(status_reg, err_type.name());
    return;
  end

  if(err_type==INVALID_EXIT_BEFORE_DOUT_ACK1) begin
    aes_test_disable();
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    return;
  end

  // 8.        FW waits for data_out_vld = 1 in aes_test_status register.
  //wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(0), .data_out_vld(1), .tag_out(0), .timeout(timeout));
  //`uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

  m_rd_data_aes_test_status[0] = 0;
  read_count = 0;
  while((m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_RANGE] == 0) && (read_count < 100)) begin
    m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
            .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
    read_count = read_count + 1;
  end
  `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, read_count[%0d], m_rd_data_aes_test_status[x%0h]", debug_str, read_count, m_rd_data_aes_test_status[0]), UVM_LOW)

  if(m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_RANGE] == 0) begin

  //if(timeout) begin
    if((err_type != INVALID_BYTE_CNT_ECB)&&(err_type != INVALID_BYTE_CNT_GCM)) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
    end
    aes_test_disable();
    wait_n_clks(5);
    pull_status(status_reg, timeout);
    wait_n_clks(10);
    print_status(status_reg, err_type.name());
    return;
  end

  if(err_type==INVALID_EXIT_BEFORE_DOUT_ACK2) begin
    aes_test_disable();
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    return;
  end

  aes_load_ctrl_data_out_ack();
  `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_data_out_ack", debug_str), UVM_LOW)

  if(err_type==INVALID_EXIT_BEFORE_TAG_ACK2) begin
    aes_test_disable();
    pull_status(status_reg, timeout);
    print_status(status_reg, err_type.name());
    return;
  end

  // 11. In AES in GCM mode, then FW waits for data_out_vld = 1 and tag_out = 1 in aes_test_status register.
  if(aes_pkt.m_aes_mode == sinc_parameters_pkg::GCM) begin
    m_rd_data_aes_test_status[0] = 0;
    read_count = 0;
    while((m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_RANGE] == 0) && (read_count < 100)) begin
      m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_addr_aes_test_status), .read_data(m_rd_data_aes_test_status), .burst_length('h1), .id('h0), .response(m_response), .burst_size(PAL_BYTES_4),
              .prot(PAL_NORM_SEC_DATA), .aruser('h0), .lock(PAL_NORMAL), .cache(PAL_NONMODIFIABLE_NONBUF), .burst_type(PAL_BT_INCR));
      read_count = read_count + 1;
    end
    `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, read_count[%0d], m_rd_data_aes_test_status[x%0h]", debug_str, read_count, m_rd_data_aes_test_status[0]), UVM_LOW)

    if(m_rd_data_aes_test_status[0][`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_RANGE] == 0) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
      aes_test_disable();
      print_status(status_reg, err_type.name());
      return;
    end

    if(err_type==INVALID_EXIT_BEFORE_TAG_ACK2) begin
      aes_test_disable();
      pull_status(status_reg, timeout);
      print_status(status_reg, err_type.name());
      return;
    end

    // 12. FW reads aes_test_data_out* registers to get the authentication tag and then set data_out_ack = 1 in aes_test_ctrl register.
    aes_load_ctrl_data_out_ack();
    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_data_out_ack", debug_str), UVM_LOW)
  end

  // 13. exiting out of AES test mode is a command completion and will set cmd_success bit.
  aes_test_disable();

  // intentioally do status read after aes_test_disable
  pull_status(status_reg, timeout);
  print_status(status_reg, err_type.name());

  if(err_type==VALID_AES_TEST) begin
    if (!(status_reg[`SINC_REGS_STATUS_CMD_SUCCESS_MSB] === 'h1)) begin
        `uvm_error(get_name(), $sformatf("%s: Expected invalid cmd error but didn't see one status reg['h%0h]", debug_str, status_reg))
    end
  end

endtask : aes_test_mode

`endif // SINC_INVALID_AES_TEST_DIRECTED_SEQ
