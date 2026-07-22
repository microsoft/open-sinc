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
// File        : sinc_sanity_seq.svh
// Description : 

`ifndef SINC_SANITY_SEQ
`define SINC_SANITY_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_sanity_seq
//------------------------------------------------------------------------------

typedef enum {
  SINC_SANITY_ACTIVE_FW_OP_RESET  = 0,
  SINC_SANITY_ACTIVE_FW_OP_REINIT = 1
} sinc_sanity_active_fw_op_e;

/**
 * SINC Sanity Test Sequence
 */
class sinc_sanity_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_sanity_seq)

  // copy of prior key for reuse key and bit to see if we have established an initial key
  sinc_key_t m_reuse_key_data;
  bit        m_initial_key_set          = 0;
  bit        m_sinc_reset_triggerred    = 0;
  bit        m_disable_reset_triggerred = 0;
  bit [6:0]  m_set_for_encrypt;
  bit [7:0]  m_tags_for_encrypt[5];

  // Flags passed by yml
  // enable specific test sequence in sanity test
  bit m_sanity_seq_disable_test_register   = 0;
  bit m_sanity_seq_disable_perf_cntrs      = 0;
  bit m_sanity_seq_disable_cpu_mem         = 0;
  bit m_sanity_seq_disable_mpu_config      = 0;
  bit m_sanity_seq_disable_fw_op           = 0;
  bit m_sanity_seq_disable_aes             = 0;
  bit m_sanity_seq_active_fw_op_type       = SINC_SANITY_ACTIVE_FW_OP_RESET;
  bit m_sanity_seq_set_disable_reset_bit   = 0;
  bit m_sanity_seq_set_disable_reinit_bit  = 0;
  bit m_sanity_seq_set_dis_encr_auth_check = 0;

  bit m_cpu_mem_test_only;
  bit m_aes_test_only;

  int m_exp_cpu_hit_count     = 0;
  int m_exp_cpu_miss_count    = 0;
  int m_exp_cpu_lat_count_min = 0;

  function new(string name="sinc_sanity_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();
  endfunction : new

  extern virtual task sequential_run_body();
  extern virtual task start_erase_optional();
  extern virtual task body();
  extern virtual task test_registers();
  extern virtual task cpu_mem_access();
  extern virtual task cpu_mem_access_non_active_state();
  extern virtual task cpu_mem_access_active_state();
  extern virtual task mpu_config_and_cpu_mem_access(ccpui_cpu_mem_addr_t cpu_addr = 0);
  extern virtual task disable_state_fw_operations();
  extern virtual task init_state_fw_operations();
  extern virtual task active_state_fw_operations();
  extern virtual task aes_test_mode(input bit use_directed_data=SINC_AES_TEST_MODE_RANDOM);
  extern virtual task cpu_sinc_access_with_different_options(
    ccpui_cpu_mem_addr_t cpu_addr,
    bit                  cpu_write,
    ccpui_cpu_mem_data_t cpu_write_data                   = 0,
    bit                  check_expected_read_data,
    ccpui_cpu_mem_data_t expected_read_data               = 0,
    logic                cpu_loadstore,
    logic                cpu_privmode,
    bit                  expected_to_be_allowed_by_dv_ref
  );
  extern virtual task cpu_sinc_default_attr_check(ccpui_cpu_mem_addr_t cpu_addr);
  extern virtual task mpu_set_reg_and_check(int step = 1, bit check_wr = 1'b1);
  extern virtual task mpu_reset_reg_check(int step = 1);
  extern virtual task mpu_check_regs_written(int step=1);

  extern virtual task check_perf_cntrs_at_default();
  extern virtual task read_and_check_performance_counters();
  extern virtual task cpu_mem_unpreloaded_block();
  extern virtual task recover_severe();

  extern virtual function void process_plusargs_and_populate_seq_item();

endclass : sinc_sanity_seq

task sinc_sanity_seq::start_erase_optional();
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

task sinc_sanity_seq::sequential_run_body();
  string debug_str = "sequential_run_body";

  `uvm_info(get_name(), $sformatf("%s: Inside sinc_sanity_seq", debug_str), UVM_LOW)

  `uvm_info(get_name(), "##### Starting register test for DISABLE STATE", UVM_LOW)

  // below tasks run under cache_disable
  test_registers(); // test register with read and write operations

  if (!m_sanity_seq_disable_perf_cntrs) begin
    enable_performance_counters(); // enable performance counters when cache is still disabled
  end

  cpu_mem_access(); // use cpu_mem interface do mem read and write depends on the cache state

  mpu_config_and_cpu_mem_access(0); // change MPU config, read MPU status, test MPU permission on cpu mem access
  mpu_config_and_cpu_mem_access('hFFFF);
  // do AES test mode tests
  // direct data
  aes_test_mode(SINC_AES_TEST_MODE_DIRECTED);
  wait_n_clks(50);
  // random data check if we are onlt doing AES or doing others too
  if (m_aes_test_only == 0) begin
    repeat(5) begin
      aes_test_mode(SINC_AES_TEST_MODE_RANDOM);
    end
  end else begin
    repeat(15) begin
      aes_test_mode(SINC_AES_TEST_MODE_RANDOM);
    end
  end

  disable_state_fw_operations();

  wait_n_clks(20);
  `uvm_info(get_name(), "###### Starting register test for INIT STATE", UVM_LOW)
  // cache_initialization state
  test_registers();
  cpu_mem_access();
  mpu_config_and_cpu_mem_access(0);
  mpu_config_and_cpu_mem_access('hFFFF);
  init_state_fw_operations();

  wait_n_clks(20);
  `uvm_info(get_name(), "##### Starting register test for ACTIVE STATE", UVM_LOW)
  // cache_active state
  if(m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem) begin
    //do preload if param is selected
    preload_encrypted_blocks(.prog_all(1));
  end
  test_registers();
  cpu_mem_access();
  if(!m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem) begin
    //do preload if param is selected
    cpu_mem_unpreloaded_block();
  end
  mpu_config_and_cpu_mem_access(0);
  mpu_set_reg_and_check(64, 0);

  active_state_fw_operations();
  // mpu_reset_reg_check needs a sinc_reset
  // to be executed so that default_attr_checks pass
  // We need to run mpu_reset_reg_check for tests that
  // set the flag that sinc_reset has been triggerred.
  if ( m_sinc_reset_triggerred ) begin
    mpu_reset_reg_check(64);
  end else begin
    mpu_check_regs_written(64);
  end // else: !if( m_sinc_reset_triggerred )

endtask : sequential_run_body

task sinc_sanity_seq::body();
  super.body();

  test_done();
endtask : body

function void sinc_sanity_seq:: process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SANITY_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

  tmp_str = "SANITY_SEQ_DISABLE_TEST_REGISTER";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_test_register)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_test_register), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_DISABLE_PERF_CNTRS";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_perf_cntrs)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_perf_cntrs), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_DISABLE_CPU_MEM";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_cpu_mem)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_cpu_mem), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_SET_DIS_ENCR_AUTH_CHECK";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_set_dis_encr_auth_check)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_set_dis_encr_auth_check), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_DISABLE_MPU_CONFIG";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_mpu_config)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_mpu_config), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_DISABLE_FW_OP";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_fw_op)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_fw_op), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_DISABLE_AES";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_disable_aes)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_disable_aes), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_ACTIVE_FW_OP_TYPE";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_active_fw_op_type)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_active_fw_op_type), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_SET_DISABLE_RESET_BIT";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_set_disable_reset_bit)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_set_disable_reset_bit), UVM_LOW)
  end

  tmp_str = "SANITY_SEQ_SET_DISABLE_REINIT_BIT";
  if($value$plusargs({tmp_str, "=%d"}, m_sanity_seq_set_disable_reinit_bit)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sanity_seq_set_disable_reinit_bit), UVM_LOW)
  end

  if (m_sanity_seq_disable_test_register &&
      m_sanity_seq_disable_cpu_mem &&
      m_sanity_seq_disable_mpu_config &&
      m_sanity_seq_disable_fw_op &&
      m_sanity_seq_disable_aes) begin
    `uvm_error(get_name(), $sformatf("%s: Sanity test should not have all the tasks disabled, m_sanity_seq_disable_test_register:%0d, m_sanity_seq_disable_cpu_mem:%0d, m_sanity_seq_disable_mpu_config:%0d, m_sanity_seq_disable_fw_op:%0d, m_sanity_seq_disable_aes:%0d", debug_str, m_sanity_seq_disable_test_register, m_sanity_seq_disable_cpu_mem, m_sanity_seq_disable_mpu_config, m_sanity_seq_disable_fw_op, m_sanity_seq_disable_aes))
  end

  if ((m_sanity_seq_disable_cpu_mem == 0) && m_sanity_seq_disable_test_register && m_sanity_seq_disable_mpu_config && m_sanity_seq_disable_fw_op && m_sanity_seq_disable_aes) begin
    m_cpu_mem_test_only = 1;
  end else begin
    m_cpu_mem_test_only = 0;
  end

  if ((m_sanity_seq_disable_aes == 0) && m_sanity_seq_disable_test_register && m_sanity_seq_disable_mpu_config && m_sanity_seq_disable_fw_op && m_sanity_seq_disable_cpu_mem) begin
    m_aes_test_only = 1;
  end else begin
    m_aes_test_only = 0;
  end

endfunction : process_plusargs_and_populate_seq_item

task sinc_sanity_seq::cpu_mem_unpreloaded_block();
  string               debug_str     = "DV::cpu_mem_unpreloaded_block";
  ccpui_cpu_mem_addr_t cpu_addr;
  ccpui_cpu_mem_we_t   cpu_we;
  ccpui_cpu_mem_data_t cpu_read_data;
  logic                cpu_loadstore;
  logic                cpu_privmode;
  uvm_reg_data_t       my_data;
  bit                  timeout;
  ccpui_mpu_data_t     mpu_read_data;
  logic [1:0]          mpu_resp;

  if (m_sanity_seq_disable_cpu_mem) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_cpu_mem is set ['h%0h], skip cpu_mem_access", debug_str, m_sanity_seq_disable_cpu_mem), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  if(m_sanity_seq_set_dis_encr_auth_check) begin
    m_sys_cfg.m_sinc_vif.set_disable_encr_auth_check(1);
  end

  //set mpu to allow
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(0), .write_data('h7777_7777), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(0), .write_data('h7777_7777), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(0), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== 'h7777_7777) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(0), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== 'h7777_7777) begin
    `uvm_error(get_name(), $sformatf("%s: target_privilege_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end

  //read address 128 which we didn't preload, first address of block 1
  cpu_addr      = 'h128;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if(m_sanity_seq_set_dis_encr_auth_check) begin
      if (!(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0)) begin
        `uvm_error(get_name(), $sformatf("%s: Cache_state[F0]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end else begin
      if (!(my_data[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hFF))) begin
        `uvm_error(get_name(), $sformatf("%s: expected auth_tag_chk_err[1]vs.[%0d], Cache_state[FF]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
      recover_severe();
    end

  end

endtask : cpu_mem_unpreloaded_block

task sinc_sanity_seq::test_registers();
  string  debug_str  = "DV::test_registers";
  uvm_reg my_regs[$];

  if (m_sanity_seq_disable_test_register) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_test_register is set ['h%0h], skip test_registers", debug_str, m_sanity_seq_disable_test_register), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  m_regmodel.get_registers(my_regs);
  foreach(my_regs[i]) begin
    test_register(my_regs[i]);
  end

  m_sys_cfg.m_reset_reg_tested = 1;
endtask : test_registers

task sinc_sanity_seq::cpu_mem_access();
  string debug_str = "DV::sinc_cpu_mem_access";

  if (m_sanity_seq_disable_cpu_mem) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_cpu_mem is set ['h%0h], skip cpu_mem_access", debug_str, m_sanity_seq_disable_cpu_mem), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  if (m_sys_cfg.m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
    // positive test relying on whether the destination memory has been encrypted
    cpu_mem_access_active_state();
  end else begin
    // cache is treated as local memory
    cpu_mem_access_non_active_state();
  end

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)

endtask : cpu_mem_access

task sinc_sanity_seq::cpu_mem_access_non_active_state();
  string               debug_str      = "DV::sinc_cpu_mem_access_non_active_state";
  ccpui_cpu_mem_addr_t cpu_addr;
  bit                  cpu_write;
  ccpui_cpu_mem_we_t   cpu_we;
  ccpui_cpu_mem_data_t cpu_read_data;
  ccpui_cpu_mem_data_t cpu_write_data = 0;
  logic                cpu_loadstore;                                              // must be 1 for CPU WRITE
  logic                cpu_privmode;
  bit                  is_mpu_allowed;
  bit                  r_acc_vio;
  bit                  r_accvio_ex;
  bit                  r_accvio_rd;
  bit                  r_accvio_wr;

  if (m_sanity_seq_disable_cpu_mem) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_cpu_mem is set ['h%0h], skip cpu_mem_access", debug_str, m_sanity_seq_disable_cpu_mem), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  // task 1, test on address 0
  `uvm_info (get_name(), $sformatf("%s: task 1, test on address 0", debug_str), UVM_LOW)
  // test read - addr[0]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
  if (!is_mpu_allowed) begin
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else begin
    if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end

  // test write - addr[0], write data ['hFFFF_FFFF]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['h0000_0000]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'h0;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['h0000_0000]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['hFFFF_FFFF], WE['b0001]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'h1; // 'b0001
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF], WE['b0001]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'h0000_00FF) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['hFFFF_FFFF], WE['b0010]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'h2; // 'b0010
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF], WE['b0010]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'h0000_FFFF) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['hFFFF_FFFF], WE['b0100]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'h4; // 'b0100
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF], WE['b0010]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'h00FF_FFFF) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['hFFFF_FFFF], WE['b1000]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'h8; // 'b1000
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF], WE['b0010]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'hFFFF_FFFF) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['h1111_1111], WE['b1111]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'h1111_1111;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['h1111_1111], WE['b1111]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'h1111_1111) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // below code is comment out, uncomment when bug resolved: (internal link removed)

  // test write - addr[0], write data ['hFFFF_FFFF], WE['b0000]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'h0;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['h1111_1111], WE['b1111]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== 32'h1111_1111) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  // test write - addr[0], write data ['hFFFF_FFFF]
  cpu_write      = 1;
  cpu_addr       = 'h0;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[0], write data ['hFFFF_FFFF]
  cpu_write     = 0;
  cpu_addr      = 'h0;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: task 1, test on address 0 - done", debug_str), UVM_LOW)

  // task 2, test on address 1
  `uvm_info (get_name(), $sformatf("%s: task 2, test on address 1", debug_str), UVM_LOW)
  // test read - addr[1]
  cpu_write     = 0;
  cpu_addr      = 'h1;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
  if (!is_mpu_allowed) begin
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else begin
    if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end

  // test write - addr[1]
  cpu_write      = 1;
  cpu_addr       = 'h1;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_0000;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[1]
  cpu_write     = 0;
  cpu_addr      = 'h1;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: task 2, test on address 1 - done", debug_str), UVM_LOW)

  // task 3, test on address FFFF (the MAX address in cache disable state, refer to verification plan 8.4.3 CPU MEM R/W Access, 8.4.3.1 Positive test cases)
  `uvm_info (get_name(), $sformatf("%s: task 3, test on address FFFF", debug_str), UVM_LOW)
  // test read - addr[FFFF]
  cpu_write     = 0;
  cpu_addr      = 'hFFFF;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
  if (!is_mpu_allowed) begin
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else begin
    if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end

  // test write - addr[FFFF]
  cpu_write      = 1;
  cpu_addr       = 'hFFFF;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_1111;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[FFFF]
  cpu_write     = 0;
  cpu_addr      = 'hFFFF;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: task 3, test on address FFFF - done", debug_str), UVM_LOW)

  // task 4, test on address FFFE
  `uvm_info (get_name(), $sformatf("%s: task 4, test on address FFFE", debug_str), UVM_LOW)
  // test read - addr[FFFE]
  cpu_write     = 0;
  cpu_addr      = 'hFFFE;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
  if (!is_mpu_allowed) begin
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else begin
    if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end

  // test write - addr[FFFE]
  cpu_write      = 1;
  cpu_addr       = 'hFFFE;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_2222;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[FFFE]
  cpu_write     = 0;
  cpu_addr      = 'hFFFE;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: task 4, test on address FFFE - done", debug_str), UVM_LOW)

  // task 5, test on address 1FFFF (the MAX address in cache disable state, refer to verification plan 8.4.3 CPU MEM R/W Access, 8.4.3.1 Positive test cases)
  // address 1FFFF equals to address FFFF from DUT perspective
  // address FFFF was write with (cpu_write_data = 'hFFFF_1111)
  `uvm_info (get_name(), $sformatf("%s: task 5, test on address 1FFFF", debug_str), UVM_LOW)
  // test read - addr[1FFFF]
  cpu_write     = 0;
  cpu_addr      = 'h1FFFF;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
  if (cpu_read_data !== 32'hFFFF_1111) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data[FFFF_1111], Actual ['h%0h]", debug_str, cpu_read_data))
  end

  // test write - addr[1FFFF]
  cpu_write      = 1;
  cpu_addr       = 'h1FFFF;
  cpu_we         = 'hF;
  cpu_loadstore  = 1;
  cpu_privmode   = 1;
  cpu_write_data = 'hFFFF_FFFF;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
  `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

  // test read after write - addr[1FFFF]
  cpu_write     = 0;
  cpu_addr      = 'h1FFFF;
  cpu_we        = 'h0;
  cpu_loadstore = 1;
  cpu_privmode  = 1;
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  if (cpu_read_data !== cpu_write_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
  end

  check_perf_cntrs_at_default();

  `uvm_info (get_name(), $sformatf("%s: task 5, test on address 1FFFF - done", debug_str), UVM_LOW)

endtask : cpu_mem_access_non_active_state

task sinc_sanity_seq::cpu_mem_access_active_state();
  string               debug_str          = "DV::cpu_mem_access_active_state";
  ccpui_cpu_mem_addr_t cpu_addr;
  ccpui_cpu_mem_we_t   cpu_we;
  ccpui_cpu_mem_data_t cpu_read_data;
  ccpui_cpu_mem_data_t prev_cpu_read_data;
  ccpui_cpu_mem_data_t cpu_write_data     = 0;
  logic                cpu_loadstore;
  logic                cpu_privmode;
  int                  num_reads;
  int                  tag_num;

  if (m_sanity_seq_disable_cpu_mem) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_cpu_mem is set ['h%0h], skip cpu_mem_access", debug_str, m_sanity_seq_disable_cpu_mem), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  //For CPU MEM only case we are testing cache eviction
  //But when other tests are present we only test hits and misses with one block due to sanity test time constraints
  //For cache eviction case 4 read transactions with same set and different tags will fill in the cache set (4-way associated cache)
  //5th read transaction with same set and different tag will evict the first line of the cache set that introduced by 1st transaction
  //Then we read the first transacion address again to check that it was evicted, should be a miss not a hit, so 6 total reads
  if(m_cpu_mem_test_only) begin
    num_reads = 6;
  end else begin
    num_reads = 1;
  end

  for (int i=0; i < num_reads; i++) begin
    `uvm_info (get_name(), $sformatf("%s: num_reads[%0d]", debug_str, i), UVM_HIGH)
    //for cache eviction 6th read needs to repeat first block
    tag_num = i % 5;

    // test read - addr[0]
    // read miss
    //cpu_addr is word address not byte address
    //Each block is 512 bytes or 128 words so lower 7 bits of address determines which word within block, not used for set or tag
    //Next 7 bits are used for set, 256kb iram with 512 byte block size, and 4 way set associative means 128 sets (256*1024)/(512*4)
    //Rest of address used for tag, 16MB external memory converted to word address has 22 bits, word addresses from 0 to 3F_FFFF
    cpu_addr        = 'h0;
    cpu_addr[13:7]  = m_set_for_encrypt;
    cpu_addr[21:14] = m_tags_for_encrypt[tag_num];
    cpu_we          = 'h0;
    cpu_loadstore   = 1;
    cpu_privmode    = 1;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    prev_cpu_read_data = cpu_read_data;

    //this read is a miss so incrementing expected miss count and latency
    m_exp_cpu_miss_count += 1;
    m_exp_cpu_lat_count_min += 100;
    read_and_check_performance_counters();

    // test read - addr[0]
    // read hit
    //cpu addr doesn't need to change
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;

    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    if (cpu_read_data !== prev_cpu_read_data) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, prev_cpu_read_data, cpu_read_data))
    end

    //this read is a hit so incrementing hit count
    m_exp_cpu_hit_count += 1;
    read_and_check_performance_counters();

    // test write - addr[0]
    // write denied
    //cpu addr doesn't need to change
    cpu_we         = 'hF;
    cpu_loadstore  = 1;
    cpu_privmode   = 1;
    cpu_write_data = 'hFFFF_FFFF;

    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
    `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

    //write shouldn't change perf counters
    read_and_check_performance_counters();

    // test read after write - addr[0]
    // read hit
    //cpu addr doesn't need to changes
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;

    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    if (cpu_read_data !== prev_cpu_read_data) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, prev_cpu_read_data, cpu_read_data))
    end

    //this read is a hit so incrementing hit count
    m_exp_cpu_hit_count += 1;
    read_and_check_performance_counters();

    // clear counters before next iteration
    clear_performance_counters();
    m_exp_cpu_miss_count    = 0;
    m_exp_cpu_hit_count     = 0;
    m_exp_cpu_lat_count_min = 0;

    // make sure counters are cleared
    check_perf_cntrs_at_default();

  end // for (int i=0; i < num_reads; i++)

endtask : cpu_mem_access_active_state

task sinc_sanity_seq::mpu_set_reg_and_check(int step=1, bit check_wr=1'b1);

  logic [1:0]      mpu_resp;
  ccpui_mpu_data_t mpu_read_data;
  bit [31:0]       permissions_data_allow = 32'h8888_8888;
  string           debug_str              = "DV::mpu_set_reg_and_check";
  //FIXME: fixme-hw: make generic on page number, more skip with larger number, first and last attribute must be tested
  int              page_size              = 512;

  // Write all Attribute registers to inverse of reset
  `uvm_info (get_name(), $sformatf("%s: Writing attributes for %d pages state 'h%h \n", debug_str, page_size/step, permissions_data_allow), UVM_HIGH)
  for (int reg_number = 0; reg_number < page_size; reg_number+=step) begin
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
  end

  // Verify all Attribute registers are set properly
  if(check_wr) begin
    for (int reg_number = 0; reg_number < page_size; reg_number+=step) begin
      m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
      if (mpu_read_data !== permissions_data_allow) begin
        `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
      end
      m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
      if (mpu_read_data !== permissions_data_allow) begin
        `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
      end
    end
  end
endtask : mpu_set_reg_and_check

task sinc_sanity_seq::mpu_check_regs_written(int step=1);

  logic [1:0]      mpu_resp;
  ccpui_mpu_data_t mpu_read_data;
  bit [31:0]       permissions_data_allow = 32'h8888_8888;
  string           debug_str              = "DV::mpu_check_regs_written";
  //FIXME: fixme-hw: make generic on page number, more skip with larger number, first and last attribute must be tested
  int              page_size              = 512;

  // Verify all Attribute registers are set properly
  for (int reg_number = 0; reg_number < page_size; reg_number+=step) begin
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
    if (mpu_read_data !== permissions_data_allow) begin
      `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
    end
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
    if (mpu_read_data !== permissions_data_allow) begin
      `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
    end
  end
endtask : mpu_check_regs_written

task sinc_sanity_seq::mpu_reset_reg_check(int step=1);

  //FIXME: fixme-hw: make generic on page number, more skip with larger number, first and last attribute must be tested
  int page_size = 512;
  //disable_state_fw_operations();
  //fw_sinc_reset_cmd();

  // Verify all Attribute registers are default
  for (int reg_number = 0; reg_number < page_size; reg_number+=step) begin
    cpu_sinc_default_attr_check(reg_number << 13);
  end

endtask : mpu_reset_reg_check

task sinc_sanity_seq::cpu_sinc_default_attr_check(ccpui_cpu_mem_addr_t cpu_addr);
  int              page_number               = cpu_addr / 1024;
  int              reg_number                = page_number / 8;
  ccpui_mpu_data_t mpu_read_data;
  bit [31:0]       permissions_data_allow    = 'h7777_7777;
  bit [31:0]       permissions_data_disallow = 'h0;
  logic [1:0]      mpu_resp;
  string           debug_str                 = "DV::cpu_sinc_default_attr_check";

  `uvm_info (get_name(), $sformatf("%s: checking default attributes for page %0d, state %s \n", debug_str, page_number, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_privilege_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
endtask : cpu_sinc_default_attr_check

task sinc_sanity_seq::cpu_sinc_access_with_different_options(
    ccpui_cpu_mem_addr_t cpu_addr,
    bit                  cpu_write,
    ccpui_cpu_mem_data_t cpu_write_data                   = 0,
    bit                  check_expected_read_data,
    ccpui_cpu_mem_data_t expected_read_data               = 0,
    logic                cpu_loadstore,
    logic                cpu_privmode,
    bit                  expected_to_be_allowed_by_dv_ref
  );
  // cpu_addr - the address, which will be used
  // cpu_write - read or write
  // cpu_loadstore - loadstore command
  // cpu_privmode - privelege mode or not
  // expected_to_be_allowed_by_dv_ref - compares the is_mpu_allowed() output with what we expect it to be

  bit is_mpu_allowed;
  bit r_acc_vio;
  bit r_accvio_ex;
  bit r_accvio_rd;
  bit r_accvio_wr;

  ccpui_cpu_mem_data_t cpu_read_data;
  ccpui_mpu_data_t     mpu_reg_data;
  ccpui_mpu_data_t     mpu_read_data;
  ccpui_mpu_data_t     mpu_write_data;
  logic [1:0]          mpu_resp;
  string               debug_str      = "DV::cpu_sinc_access_with_different_options";

  // check if allowed with DV reference
  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
    .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));

  if (is_mpu_allowed != expected_to_be_allowed_by_dv_ref) begin
    `uvm_error(get_name(), $sformatf("DV reference: is_mpu_allowed = 'h%0h, expected_to_be_allowed_by_dv_ref = 'h%0h", is_mpu_allowed, expected_to_be_allowed_by_dv_ref))
  end

  // CPU->SINC
  if (!cpu_write) begin
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
  end else begin
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we('hf));
    `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h], blocked by MPU", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)
  end

  if (!is_mpu_allowed) begin
    if (!cpu_write & (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA)) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", sinc_parameters_pkg::SINC_CPU_ERRDATA, debug_str, cpu_read_data))
    end
  end

  if (check_expected_read_data & (cpu_read_data !== expected_read_data)) begin
    `uvm_error(get_name(), $sformatf("%s: Expected read data ['h%0h], Actual ['h%0h]", debug_str, expected_read_data, cpu_read_data))
  end

  // check the MPU status
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_reg_read(mpu_read_data, mpu_resp);
  mpu_reg_data = 0;
  if ( !is_mpu_allowed & !cpu_write & cpu_loadstore) begin
    mpu_reg_data = 1 << `MPU_REGS_MPU_STATUS_ACCVIO_RD_LSB;
  end // read violation bit
  if ( !is_mpu_allowed & !cpu_write & !cpu_loadstore) begin
    mpu_reg_data = 1 << `MPU_REGS_MPU_STATUS_ACCVIO_EX_LSB;
  end // execute violation bit
  if (!is_mpu_allowed & cpu_write) begin
    mpu_reg_data = 1 << `MPU_REGS_MPU_STATUS_ACCVIO_WR_LSB;
  end // write violation bit
  if ((m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) & cpu_write) begin
    mpu_reg_data = 1 << `MPU_REGS_MPU_STATUS_ACCVIO_WR_LSB;
  end // SP doesn’t have write access to cache IRAM in ACTIVE state and results in an error

  if (!is_mpu_allowed) begin
    mpu_reg_data[`MPU_REGS_MPU_STATUS_ACCVIO_ADDR_RANGE] = (int'(cpu_addr)) * 4;
  end // the address specified in the register concatenates two zeros at the end

  if (mpu_reg_data !== mpu_read_data) begin
    `uvm_error(get_name(), $sformatf("%s: Expect MPU status['h%0h], actual['h%0h]", debug_str, mpu_reg_data, mpu_read_data))
  end

  if (mpu_read_data !== 0) begin // if the status contained violations
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_writeclear(mpu_resp); // clear the status
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_reg_read(mpu_read_data, mpu_resp);
    if (mpu_read_data !== 0) begin // if the status violations haven't been cleared
      `uvm_error(get_name(), $sformatf("%s: violations haven't been cleared, read data is 'h%0h\n", debug_str, mpu_read_data))
    end
  end
endtask : cpu_sinc_access_with_different_options

task sinc_sanity_seq::mpu_config_and_cpu_mem_access( ccpui_cpu_mem_addr_t cpu_addr = 0);
  string               debug_str          = "DV::mpu_config_and_cpu_mem_access";
  bit                  cpu_write;
  ccpui_cpu_mem_we_t   cpu_we;
  ccpui_cpu_mem_data_t cpu_read_data;
  ccpui_cpu_mem_data_t temp_cpu_read_data = 0;
  ccpui_cpu_mem_data_t cpu_write_data     = 0;
  logic                cpu_loadstore;
  logic                cpu_privmode;
  ccpui_mpu_data_t     mpu_read_data;
  ccpui_mpu_data_t     mpu_reg_data;
  ccpui_mpu_data_t     mpu_write_data;
  logic [1:0]          mpu_resp;
  bit                  is_mpu_allowed;
  bit                  r_acc_vio;
  bit                  r_accvio_ex;
  bit                  r_accvio_rd;
  bit                  r_accvio_wr;
  int                  page_num;
  int                  attr_offset;
  cpu_byte_address_t   cpu_byte_addr;

  // every page is 4K bytes -> 1024 addresses of 4 bytes each
  // page number = address divided by 1024
  // page number divided by 8 is the register number
  // the residue is the offset within the register
  int        page_number               = cpu_addr / 1024;
  int        reg_number                = page_number / 8;
  bit [31:0] permissions_data_allow    = 'h7777_7777;
  bit [31:0] permissions_data_disallow = 'h0;

  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_writeclear(mpu_resp); // clear the status from the previous call of the function

  if (m_sanity_seq_disable_mpu_config) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_mpu_config is set ['h%0h], skip mpu_config_and_cpu_mem_access", debug_str, m_sanity_seq_disable_mpu_config), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_HIGH)

  `uvm_info (get_name(), $sformatf("%s: ############ 0. cpu write data allowed by MPU (default setup), state %s. This data is read in the next steps. \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .cpu_write_data('hCCCC_CCCC), .expected_to_be_allowed_by_dv_ref(1));

  if (m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) begin
    cpu_read_data = 'hCCCC_CCCC;
  end else begin
    // cpu_read_data = 'h8f020000;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(1), .privmode(0), .read_data(temp_cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, temp_cpu_read_data), UVM_HIGH)
    cpu_read_data = temp_cpu_read_data;
  end

  `uvm_info (get_name(), $sformatf("%s: ################## 1. The default mpu setup is to allow all access, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  for (int i = 0; i < 5; i++) begin
    ccpui_cpu_mem_addr_t cpu_addr;
    if(!std::randomize(cpu_addr) with { cpu_addr inside {[0:'hFFFF]};}) begin
      `uvm_fatal("RAND", "std::randomize failed to randomize 'cpu_addr'")
    end
    cpu_sinc_default_attr_check(cpu_addr);
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 2. cpu does user read allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(1), .expected_read_data(cpu_read_data), .expected_to_be_allowed_by_dv_ref(1));

  `uvm_info (get_name(), $sformatf("%s: ############ 3. cpu does user write allowed (record wdata), state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .cpu_write_data('hDDDD_DDDD), .expected_to_be_allowed_by_dv_ref(1));

  if (m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) begin
    cpu_read_data = 'hDDDD_DDDD;
  end else begin
    // cpu_read_data = 'h8f020000;
    cpu_read_data = temp_cpu_read_data;
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 4. cpu does user execute allowed (read with loadstore set to 0), state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(0), .cpu_privmode(1), .check_expected_read_data(1), .expected_read_data(cpu_read_data), .expected_to_be_allowed_by_dv_ref(1));

  `uvm_info (get_name(), $sformatf("%s: ################## 5. configure mpu to block priv access and allow user access, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .write_data(permissions_data_disallow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_disallow) begin
    `uvm_error(get_name(), $sformatf("%s: target_privilege_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 6. cpu does priv read not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(1), .expected_read_data(sinc_parameters_pkg::SINC_CPU_ERRDATA), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 7. cpu does priv write not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .cpu_write_data('hDDDD_DDDD), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 8. cpu does priv execute not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(0), .check_expected_read_data(1), .expected_read_data(sinc_parameters_pkg::SINC_CPU_ERRDATA), .cpu_privmode(0), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 9. cpu does user read not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .check_expected_read_data(1), .expected_read_data(sinc_parameters_pkg::SINC_CPU_ERRDATA), .cpu_privmode(0), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 10. cpu does user write not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .cpu_write_data('hEEEE_EEEE), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 11. cpu does user execute not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(0), .cpu_privmode(0), .check_expected_read_data(1), .expected_read_data(sinc_parameters_pkg::SINC_CPU_ERRDATA), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ################## 12. mpu allow priv access, block user access, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .write_data(permissions_data_disallow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_disallow) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_privilege_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 13. cpu does priv read allowed, check that read data is wdata from step 3, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .cpu_privmode(1), .check_expected_read_data(1), .expected_read_data(cpu_read_data), .expected_to_be_allowed_by_dv_ref(1));

  `uvm_info (get_name(), $sformatf("%s: ############ 14. cpu does priv write allowed (record wdata), state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(1), .check_expected_read_data(0), .cpu_write_data('hFFFF_FFFF), .expected_to_be_allowed_by_dv_ref(1));

  if (m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) begin
    cpu_read_data = 'hFFFF_FFFF;
  end else begin
    // cpu_read_data = 'h8f020000;
    cpu_read_data = temp_cpu_read_data;
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 15. cpu does priv execute allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(0), .cpu_privmode(1), .check_expected_read_data(1), .expected_read_data(cpu_read_data), .expected_to_be_allowed_by_dv_ref(1));

  `uvm_info (get_name(), $sformatf("%s: ############ 16. cpu does user read not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 17. cpu does user write not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(1), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(0), .cpu_write_data('hAAAA_AAAAA), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ############ 18. cpu does user execute not allowed, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(0), .cpu_privmode(0), .check_expected_read_data(1), .expected_read_data(sinc_parameters_pkg::SINC_CPU_ERRDATA), .expected_to_be_allowed_by_dv_ref(0));

  `uvm_info (get_name(), $sformatf("%s: ################## 19. mpu allow all access, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .write_data(permissions_data_allow), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(reg_number), .read_data(mpu_read_data), .resp(mpu_resp));
  if (mpu_read_data !== permissions_data_allow) begin
    `uvm_error(get_name(), $sformatf("%s: target_user_attr wasn't set, mpu_read_data = 'h%0h", debug_str, mpu_read_data))
  end

  `uvm_info (get_name(), $sformatf("%s: ############ 20. cpu does user read allowed again, check that read data is wdata from step 15, state %s \n", debug_str, m_sys_cfg.m_cur_cache_state), UVM_HIGH)
  cpu_sinc_access_with_different_options(.cpu_addr(cpu_addr), .cpu_write(0), .cpu_loadstore(1), .cpu_privmode(0), .check_expected_read_data(1), .expected_read_data(cpu_read_data), .expected_to_be_allowed_by_dv_ref(1));

endtask : mpu_config_and_cpu_mem_access

task sinc_sanity_seq::disable_state_fw_operations();
  string         debug_str              = "DV::disable_state_fw_operations";
  reg_data_t     aes_iv_nonce_0         = 'h0;
  reg_data_t     aes_iv_nonce_1         = 'h0;
  reg_data_t     aes_iv_nonce_2         = 'h0;
  reg_data_t     block_encr_key         = 'h0;
  reg_data_t     ext_block_base_addr    = 'h0;
  reg_data_t     ext_auth_tag_base_addr = 'h0;
  uvm_reg_data_t my_data;
  bit            timeout;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  // below code has been moved to sys_cfg, remove anytime
  /*
   // randomize/set misc register value before do set_init_state command
   if (!std::randomize(aes_iv_nonce_0)) begin
   `uvm_fatal(get_name(), "Unable to randomize aes_iv_nonce_0")
   end
   if (!std::randomize(aes_iv_nonce_1)) begin
   `uvm_fatal(get_name(), "Unable to randomize aes_iv_nonce_0")
   end
   if (!std::randomize(aes_iv_nonce_2)) begin
   `uvm_fatal(get_name(), "Unable to randomize aes_iv_nonce_0")
   end
   block_encr_key = 1; // use key 1
   ext_block_base_addr = sinc_parameters_pkg::SINC_DMB_START_ADDR; // use starting address DMB for ext_block_base_addr 'h9000_0000
   ext_auth_tag_base_addr = sinc_parameters_pkg::SINC_DMB_START_ADDR + 32'h0F00_0000; // END at FFFF_FFFF, last 4 bits must be 0
   */

  load_key_to_axi_mem(m_sys_cfg.m_aes_cfg.m_key_axi_addr, m_sys_cfg.m_aes_cfg.m_key_data);
  fw_set_init_state (.program_misc_reg(1), .aes_iv_nonce_0(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]), .aes_iv_nonce_1(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]), .aes_iv_nonce_2(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]), .block_encr_key(m_sys_cfg.m_aes_cfg.m_key_slot), .ext_block_base_addr(m_sys_cfg.m_ext_block_base_addr), .ext_auth_tag_base_addr(m_sys_cfg.m_ext_auth_tag_base_addr));

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  // fixme-hw: below code will be removed after scoreboard and monitor in place
  m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;

endtask : disable_state_fw_operations

task sinc_sanity_seq::active_state_fw_operations();
  string         debug_str = "DV::active_state_fw_operations";
  uvm_reg_data_t my_data;
  bit            timeout;

  `uvm_info (get_name(), $sformatf("active_state_fw_operations: switching to RESET\n"), UVM_HIGH)

  if(m_sanity_seq_active_fw_op_type == SINC_SANITY_ACTIVE_FW_OP_RESET) begin

    if(m_sanity_seq_set_disable_reset_bit) begin
      fw_sinc_disable_reset_cmd();
      m_disable_reset_triggerred = 1;

      pull_status(my_data, timeout);
      `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

      if (timeout) begin
        `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
      end else begin
        if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_MSB] === 'h1))) begin // in disable state when reset is done
          `uvm_error(get_name(), $sformatf("%s: expected cmd_success[0]vs.[%0d], reset_disabled[1]vs.['h%0h]", debug_str,
              my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_MSB]))
        end
      end
    end

    fw_sinc_reset_cmd();
    // Setting the flag to indicate that the sinc reset has been
    // triggerred. If sinc reset is triggered, we should allow
    // the checking of the default_attr in mpu_reset_reg_check.
    // Check if disable_reset has been triggered.
    if ( !m_disable_reset_triggerred ) begin
      m_sinc_reset_triggerred = 1;
    end

    /*
     for (int i = 0; i < 5; i++) begin
     cpu_sinc_default_attr_check($urandom_range('hFFFF, 'h0));
     end
     */
    pull_status(my_data, timeout);
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

    if (timeout) begin
      `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
    end else if(m_sanity_seq_set_disable_reset_bit) begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_FAILED_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0))) begin // in disable state when reset is done
        `uvm_error(get_name(), $sformatf("%s: expected failed[1]vs.[%0d], Cache_state[F0]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_FAILED_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end else begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'h00))) begin // in disable state when reset is done
        `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[0]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end
  end else begin
    if(m_sanity_seq_set_disable_reinit_bit) begin
      fw_sinc_disable_reinit_cmd();

      pull_status(my_data, timeout);
      `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

      if (timeout) begin
        `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
      end else begin
        if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_MSB] === 'h1))) begin // in disable state when reset is done
          `uvm_error(get_name(), $sformatf("%s: expected cmd_success[0]vs.[%0d], reinit_disabled[1]vs.['h%0h]", debug_str,
              my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_MSB]))
        end
      end
    end

    fw_sinc_reinit_cmd();

    pull_status(my_data, timeout);
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

    if (timeout) begin
      `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
    end else if(m_sanity_seq_set_disable_reinit_bit) begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_FAILED_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0))) begin // in disable state when reset is done
        `uvm_error(get_name(), $sformatf("%s: expected failed[1]vs.[%0d], Cache_state[F0]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_FAILED_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end else begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'h0F))) begin // in disable state when reset is done
        `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end
  end

endtask : active_state_fw_operations

task sinc_sanity_seq::init_state_fw_operations();
  string         debug_str       = "DV::init_state_fw_operations";
  bit            timeout;
  uvm_reg_data_t my_data;
  reg_data_t     block_encr_num  = 'h0;
  reg_data_t     block_encr_addr = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;
  reg_data_t     num_of_blocks   = 'h1;
  int            num_encrypts;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  if(m_sanity_seq_set_dis_encr_auth_check) begin
    m_sys_cfg.m_sinc_vif.set_disable_encr_auth_check(1);
  end

  m_set_for_encrypt     = 'h0;
  m_tags_for_encrypt[0] = 'h0;

  //For CPU MEM only case we are testing cache evicition
  //when other tests are present we only test hits and misses with one block due to sanity test time constraints
  //For cache eviction case 4 we need to encrypt 4 blocks with same set and different tags will fill in the cache set (4-way associated cache)
  //Then need to encrypt 5th block with same set and different tag to use to trigger an evict of the first block with
  //Since each block needs to have same set and different tag, they aren't contiguous
  //so need to do 5 encrypt block commands with num_of_blocks set to 1
  //for backdoor preload case no need to encrypt
  if(m_cpu_mem_test_only) begin
    num_encrypts          = 5;
    m_tags_for_encrypt[1] = 'h18;
    m_tags_for_encrypt[2] = 'h31;
    m_tags_for_encrypt[3] = 'h3c;
    m_tags_for_encrypt[4] = 'had;
  end else begin
    num_encrypts = 1;
  end

  //if we preload we don't need to do any encrypts
  //we still needed to se the tags_for_encrypt values though since those are used later during the access
  if(m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem) begin
    num_encrypts = 0;
  end

  for (int i=0; i < num_encrypts; i++) begin
    //256kb Iram with 512 byte block size, and 4 way set associative means 128 sets (256*1024)/(512*4), so 7 bits for set
    //16MB external memory with 512 byte block size means 32, 768 blocks, so block num is 14:0 with 14:7 being the tag
    block_encr_num[6:0]  = m_set_for_encrypt;
    block_encr_num[14:7] = m_tags_for_encrypt[i];
    fw_block_encr(.program_misc_reg(1), .block_encr_num(block_encr_num), .block_encr_addr(block_encr_addr), .num_of_blocks(num_of_blocks));

    pull_status(my_data, timeout);
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

    if (timeout) begin
      `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
    end else begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB])) begin
        `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end
  end

  // encrypting the last block - not doing the encryption of the last block for now
  /*  fw_block_encr(.program_misc_reg(1), .block_encr_num(32767), .block_encr_addr(block_encr_addr), .num_of_blocks(1)); // encrypting the block for 3F_FFFF
   pull_status(my_data, timeout);
   if (timeout) begin
   `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
   end else begin
   if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB])) begin
   `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
   my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
   end
   end
   */
  // change cache state from init to active
  fw_set_active_state();

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)
endtask : init_state_fw_operations

task sinc_sanity_seq::recover_severe();
  string         debug_str = "DV::recover_severe";
  bit            timeout;
  uvm_reg_data_t my_data;

  fw_sinc_reset_cmd();
  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'h00))) begin // in disable state when reset is done
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[0]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  fw_set_init_state (.program_misc_reg(1), .aes_iv_nonce_0(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]), .aes_iv_nonce_1(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]), .aes_iv_nonce_2(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]), .block_encr_key(m_sys_cfg.m_aes_cfg.m_key_slot), .ext_block_base_addr(m_sys_cfg.m_ext_block_base_addr), .ext_auth_tag_base_addr(m_sys_cfg.m_ext_auth_tag_base_addr));

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;

  fw_set_active_state();

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)
endtask : recover_severe

task sinc_sanity_seq::aes_test_mode(input bit use_directed_data=SINC_AES_TEST_MODE_RANDOM);
  string          debug_str         = "DV::aes_test_mode";
  sinc_aes_packet aes_pkt;
  sinc_axi_data_t tmp_axi_data[];
  uvm_reg_data_t  uvm_reg_data[10];                       // reserved to save intermidia reg data
  bit             timeout;
  uvm_reg_data_t  my_data;
  bit             last_data_segment;
  int             num_data_segments;

  if (m_sanity_seq_disable_aes) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_aes is set ['h%0h], skip aes_test_mode", debug_str, m_sanity_seq_disable_aes), UVM_HIGH)
    return;
  end

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  aes_pkt                 = sinc_aes_packet::type_id::create("aes_pkt", , get_full_name());
  aes_pkt.m_aes_test_mode = 1;
  if(m_initial_key_set == 1) begin
    aes_pkt.m_reuse_key_data = m_reuse_key_data;
  end

  if(use_directed_data == SINC_AES_TEST_MODE_DIRECTED) begin
    /// create sinc_aes_packet with direct test inputs
    aes_pkt.m_reuse_key            = 0;
    aes_pkt.m_aes_op               = sinc_parameters_pkg::ENCRYPT;
    // aes_pkt.m_aes_mode             = sinc_parameters_pkg::GCM;
    aes_pkt.m_aes_mode             = sinc_parameters_pkg::ECB;
    aes_pkt.m_aes_unit_sz          = sinc_parameters_pkg::BYTES_16;
    aes_pkt.m_aes_key_len          = sinc_parameters_pkg::AES_256;
    aes_pkt.m_byte_count           = 16;
    aes_pkt.m_aes_message          = new[4];
    aes_pkt.m_aes_message[0]       = 'h7d01_1d98;
    aes_pkt.m_aes_message[1]       = 'h2206_9a08;
    aes_pkt.m_aes_message[2]       = 'hf856_2593;
    aes_pkt.m_aes_message[3]       = 'h8e16_b52d;
    aes_pkt.m_key_data             = {32'h8f0c_409c, 32'h8f0c_4098, 32'h8f0c_4094, 32'h8f0c_4090, 32'h8f0c_408c, 32'h8f0c_4088, 32'h8f0c_4084, 32'h8f0c_4080};
    aes_pkt.m_key_slot             = 1;
    aes_pkt.m_aes_iv_nonce_regs[0] = 'hcee1_62e3;
    aes_pkt.m_aes_iv_nonce_regs[1] = 'hc95a_727c;
    aes_pkt.m_aes_iv_nonce_regs[2] = 'h6ce0_180d;
    aes_pkt.construct_aes_item();
  end else begin
    if (!aes_pkt.randomize() with {
          if(m_initial_key_set == 0) {
            m_reuse_key == 0;
          }
        }) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end
    `uvm_info (get_name(), $sformatf("RAND_INFO: aes_op: [%0s] aes_mode: [%0s] reuse_key: [%0d] byte_count: [%0d]", aes_pkt.m_aes_op.name(), aes_pkt.m_aes_mode.name(), aes_pkt.m_reuse_key, aes_pkt.m_byte_count), UVM_LOW)
  end

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

  // 1.        FW sets aes_test_en field to 1 in cmd register to enter AES test mode.
  aes_test_enable();
  `uvm_info (get_name(), $sformatf("%s: enable test mode", debug_str), UVM_LOW)

  // 2.        FW loads block_encr_key and aes_iv_nonce* registers.
  aes_load_key_iv_nonce(aes_pkt.m_aes_iv_nonce_regs[0], aes_pkt.m_aes_iv_nonce_regs[1], aes_pkt.m_aes_iv_nonce_regs[2], aes_pkt.m_key_slot);
  `uvm_info (get_name(), $sformatf("%s: set aes_iv_nonce_* registers", debug_str), UVM_LOW)

  // 3.        FW waits for cfg_key_iv_rdy = 1 in aes_test_status register.
  wait_aes_status(.cfg_key_iv_rdy(1), .data_in_rdy(0), .data_out_vld(0), .tag_out(0), .timeout(timeout));
  `uvm_info (get_name(), $sformatf("%s: wait till cfg_key_iv_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

  if(timeout) begin
    `uvm_error(get_name(), $sformatf("wait_aes_status never saw cfg_key_iv_rdy go high"))
    aes_test_disable();
    return;
  end

  // 4.        FW loads mode, dir, key_len fields, set cfg_key_iv_vld = 1, and data_in_vld = 0 in the aes_test_ctrl register. FW can additionally set reuse_key = 1 if it wants to reuse previously loaded key.
  // aes_load_ctrl_mode_dir_keylen(.mode(sinc_parameters_pkg::GCM), .dir(sinc_parameters_pkg::ENCRYPT), .key_len(2), .reuse_key(0));
  aes_load_ctrl_mode_dir_keylen(.mode(aes_pkt.m_aes_mode), .dir(aes_pkt.m_aes_op), .key_len(2), .reuse_key(aes_pkt.m_reuse_key));
  `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_mode_dir_keylen", debug_str), UVM_LOW)

  num_data_segments = aes_pkt.m_byte_count / 16;
  for (int data_segment_num = 0; data_segment_num < num_data_segments; data_segment_num++) begin

    // 5.        FW loads aes_test_data_in* registers.
    // aes_load_test_data_in(aes_test_data_in_0, aes_test_data_in_1, aes_test_data_in_2, aes_test_data_in_3);
    aes_load_test_data_in(aes_pkt.m_aes_message[0 + (data_segment_num * 4)], aes_pkt.m_aes_message[1 + (data_segment_num * 4)], aes_pkt.m_aes_message[2 + (data_segment_num * 4)], aes_pkt.m_aes_message[3 + (data_segment_num * 4)]);

    `uvm_info (get_name(), $sformatf("%s: set aes_load_test_data_in", debug_str), UVM_LOW)

    // 6.        FW waits for data_in_rdy = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(1), .data_out_vld(0), .tag_out(0), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_in_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_in_rdy go high"))
      aes_test_disable();
      return;
    end

    // 7.        FW loads data_in_byte_cnt and data_in_last fields and set data_in_vld = 1 in the aes_test_ctrl register.
    if(data_segment_num == (num_data_segments - 1)) begin
      aes_load_ctrl_bytecnt_last(.aes_data_in_byte_cnt(16), .data_in_last(1));
    end else begin
      aes_load_ctrl_bytecnt_last(.aes_data_in_byte_cnt(16), .data_in_last(0));
    end

    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_bytecnt_last", debug_str), UVM_LOW)

    // 8.        FW waits for data_out_vld = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(0), .data_out_vld(1), .tag_out(0), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
      aes_test_disable();
      return;
    end

    // 9.        FW reads aes_test_data_out* registers to get the AES output block and then set data_out_ack field to 1 in cmd register.
    read_reg_value(m_regmodel.aes_test_data_out_0, aes_pkt.m_aes_test_data_out[0]);
    read_reg_value(m_regmodel.aes_test_data_out_1, aes_pkt.m_aes_test_data_out[1]);
    read_reg_value(m_regmodel.aes_test_data_out_2, aes_pkt.m_aes_test_data_out[2]);
    read_reg_value(m_regmodel.aes_test_data_out_3, aes_pkt.m_aes_test_data_out[3]);
    aes_load_ctrl_data_out_ack();
    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_data_out_ack", debug_str), UVM_LOW)

    aes_pkt.check_result_data(data_segment_num);

  end

  if(aes_pkt.m_aes_mode == sinc_parameters_pkg::GCM) begin
    // 11. In AES in GCM mode, then FW waits for data_out_vld = 1 and tag_out = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(0), .data_out_vld(1), .tag_out(1), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, tag_out == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high for tag"))
      aes_test_disable();
      return;
    end

    // 12. FW reads aes_test_data_out* registers to get the authentication tag and then set data_out_ack = 1 in aes_test_ctrl register.
    read_reg_value(m_regmodel.aes_test_data_out_0, aes_pkt.m_aes_test_data_out[0]);
    read_reg_value(m_regmodel.aes_test_data_out_1, aes_pkt.m_aes_test_data_out[1]);
    read_reg_value(m_regmodel.aes_test_data_out_2, aes_pkt.m_aes_test_data_out[2]);
    read_reg_value(m_regmodel.aes_test_data_out_3, aes_pkt.m_aes_test_data_out[3]);
    `uvm_info (get_name(), $sformatf("%s: read aes_test_data_out_*", debug_str), UVM_LOW)

    aes_load_ctrl_data_out_ack();
    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_data_out_ack", debug_str), UVM_LOW)

    aes_pkt.check_tag_data();
  end

  // 13. exiting out of AES test mode is a command completion and will set cmd_success bit.
  aes_test_disable();

  // intentioally do status read after aes_test_disable
  pull_status(my_data, timeout);

endtask : aes_test_mode

task sinc_sanity_seq::check_perf_cntrs_at_default();

  string         debug_str  = "check_perf_cntrs_at_default";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  uvm_reg_data_t reg_value_hit_cntr_upper;
  uvm_reg_data_t reg_value_hit_cntr_lower;
  uvm_reg_data_t reg_value_miss_cntr_upper;
  uvm_reg_data_t reg_value_miss_cntr_lower;
  uvm_reg_data_t reg_value_lat_cntr_upper;
  uvm_reg_data_t reg_value_lat_cntr_lower;

  bit [63:0] hit_counter_complete;
  bit [63:0] miss_counter_complete;
  bit [63:0] lat_counter_complete;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  read_reg_value(m_regmodel.hit_cntr_lower, reg_value_hit_cntr_lower);
  read_reg_value(m_regmodel.hit_cntr_upper, reg_value_hit_cntr_upper);

  read_reg_value(m_regmodel.miss_cntr_lower, reg_value_miss_cntr_lower);
  read_reg_value(m_regmodel.miss_cntr_upper, reg_value_miss_cntr_upper);

  read_reg_value(m_regmodel.lat_cntr_lower, reg_value_lat_cntr_lower);
  read_reg_value(m_regmodel.lat_cntr_upper, reg_value_lat_cntr_upper);

  hit_counter_complete  = ( reg_value_hit_cntr_upper << 32 ) || reg_value_hit_cntr_lower;
  miss_counter_complete = ( reg_value_miss_cntr_upper << 32 ) || reg_value_miss_cntr_lower;
  lat_counter_complete  = ( reg_value_lat_cntr_upper << 32 ) || reg_value_lat_cntr_lower;

  `uvm_info(get_name(), $sformatf("hit counter  = 'h%0h", hit_counter_complete), UVM_HIGH)
  `uvm_info(get_name(), $sformatf("miss counter = 'h%0h", miss_counter_complete), UVM_HIGH)
  `uvm_info(get_name(), $sformatf("lat counter  = 'h%0h", lat_counter_complete), UVM_HIGH)

  if ( hit_counter_complete != 0 ) begin
    `uvm_error(get_name(), $sformatf("Performance Hit Counter is non-zero when expected to be zero.") )
  end
  if ( miss_counter_complete != 0 ) begin
    `uvm_error(get_name(), $sformatf("Performance Miss Counter is non-zero when expected to be zero.") )
  end
  if ( lat_counter_complete != 0 ) begin
    `uvm_error(get_name(), $sformatf("Performance Latency Counter is non-zero when expected to be zero.") )
  end

endtask : check_perf_cntrs_at_default

task sinc_sanity_seq::read_and_check_performance_counters();

  string         debug_str  = "read_and_check_performance_counters";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  uvm_reg_data_t reg_value_hit_cntr_upper;
  uvm_reg_data_t reg_value_hit_cntr_lower;
  uvm_reg_data_t reg_value_miss_cntr_upper;
  uvm_reg_data_t reg_value_miss_cntr_lower;
  uvm_reg_data_t reg_value_lat_cntr_upper;
  uvm_reg_data_t reg_value_lat_cntr_lower;

  bit [63:0] hit_counter_complete;
  bit [63:0] miss_counter_complete;
  bit [63:0] lat_counter_complete;

  if (m_sanity_seq_disable_perf_cntrs) begin
    `uvm_info (get_name(), $sformatf("%s: m_sanity_seq_disable_perf_cntrs is set ['h%0h], skip perf counter check", debug_str, m_sanity_seq_disable_perf_cntrs), UVM_HIGH)
    return;
  end

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  read_reg_value(m_regmodel.hit_cntr_lower, reg_value_hit_cntr_lower);
  read_reg_value(m_regmodel.hit_cntr_upper, reg_value_hit_cntr_upper);

  read_reg_value(m_regmodel.miss_cntr_lower, reg_value_miss_cntr_lower);
  read_reg_value(m_regmodel.miss_cntr_upper, reg_value_miss_cntr_upper);

  read_reg_value(m_regmodel.lat_cntr_lower, reg_value_lat_cntr_lower);
  read_reg_value(m_regmodel.lat_cntr_upper, reg_value_lat_cntr_upper);

  hit_counter_complete  = ( reg_value_hit_cntr_upper << 32 ) + reg_value_hit_cntr_lower;
  miss_counter_complete = ( reg_value_miss_cntr_upper << 32 ) + reg_value_miss_cntr_lower;
  lat_counter_complete  = ( reg_value_lat_cntr_upper << 32 ) + reg_value_lat_cntr_lower;

  `uvm_info(get_name(), $sformatf("hit counter  = 'h%0h", hit_counter_complete), UVM_HIGH)
  `uvm_info(get_name(), $sformatf("miss counter = 'h%0h", miss_counter_complete), UVM_HIGH)
  `uvm_info(get_name(), $sformatf("lat counter  = 'h%0h", lat_counter_complete), UVM_HIGH)

  if ( hit_counter_complete != m_exp_cpu_hit_count ) begin
    `uvm_error(get_name(), $sformatf("Performance Hit Counter mismatch : expected=%0d actual=%0d.",
        m_exp_cpu_hit_count, hit_counter_complete ) )
  end
  if ( miss_counter_complete != m_exp_cpu_miss_count ) begin
    `uvm_error(get_name(), $sformatf("Performance Miss Counter mismatch : expected=%0d actual=%0d.",
        m_exp_cpu_miss_count, miss_counter_complete ) )
  end
  if ( lat_counter_complete < m_exp_cpu_lat_count_min ) begin
    `uvm_error(get_name(), $sformatf("Performance Latency Counter is too low : expected=%0d actual=%0d.",
        m_exp_cpu_lat_count_min, lat_counter_complete ) )
  end

endtask : read_and_check_performance_counters

`endif // SINC_SANITY_SEQ
