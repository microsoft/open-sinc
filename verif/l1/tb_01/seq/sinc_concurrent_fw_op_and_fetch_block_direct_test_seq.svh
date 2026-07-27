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
// File        : sinc_concurrent_fw_op_and_fetch_block_direct_test_seq.svh
// Description : 

`ifndef SINC_CONCURRENT_FW_OP_AND_FETCH_BLOCK_DIRECT_TEST_SEQ
 `define SINC_CONCURRENT_FW_OP_AND_FETCH_BLOCK_DIRECT_TEST_SEQ

//##############################################################################
//<> SEQUENCE: sinc_concurrent_fw_op_and_fetch_block_direct_test_seq
//##############################################################################

/**
 * Concurrent error direct test seq: FW_OP and Fetch Block at same time
 */
class sinc_concurrent_fw_op_and_fetch_block_direct_test_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_concurrent_fw_op_and_fetch_block_direct_test_seq)

  rand ccpui_cpu_mem_addr_t       m_address[10];

  constraint address_c {
    foreach (m_address[i]) {
      m_address[i] dist {0:=1, [1:'h3F_FFFE]:/1, 'h3F_FFFF:=1}; //TODO use define for address ranges
    }
  }


  function new(string name="sinc_concurrent_fw_op_and_fetch_block_direct_test_seq");
    super.new(name);
    process_plusargs_and_populate_seq_item();
  endfunction : new

  virtual task body();
    super.body();
    test_done();
  endtask : body
 

  extern virtual task start_erase_optional();
  extern virtual task warm_reset();
  extern virtual function void process_plusargs_and_populate_seq_item();

  extern virtual task sequential_run_body();

  extern virtual task cpu_wait_for_fw_op();
  extern virtual task fw_op_wait_for_cpu();

endclass : sinc_concurrent_fw_op_and_fetch_block_direct_test_seq

//##############################################################################
//<> Test Specific Functions
//##############################################################################

function void sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

endfunction : process_plusargs_and_populate_seq_item

task sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::sequential_run_body();
  string debug_str = "sequential_run_body";

  if(!this.randomize(m_address) with { 
    // 
  } ) begin
    `uvm_fatal("RAND", "Unable to randomize m_address")
  end

  cpu_wait_for_fw_op();
  warm_reset();
  fw_op_wait_for_cpu();
  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : sequential_run_body

task sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::cpu_wait_for_fw_op();
  string debug_str = "cpu_wait_for_fw_op";
  ccpui_cpu_mem_data_t read_data;
  logic [1:0]          mpu_resp;
  bit                  wait_success;
  uvm_reg_data_t       my_data;
  bit                  timeout;

  sinc_ciu_fsm_t m_force_on_ciu_cache_fsm_state = CIU_MEM_READ;

  

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

 
  `uvm_info (get_name(), $sformatf("%s: test start erase, wait until the Fetch Block about to start then issue FW CMD(DIS_RESET)", debug_str), UVM_LOW)

  // start FW CMD (DIS_RESET)
  fork : DIS_RESET_ON_FETCH_BLOCK
    begin      
      fw_sinc_disable_reset_cmd();
    end
    begin
      m_top_configuration.m_sinc_vif.wait_axi_sub_wr(wait_success);
      wait_n_clks(1);
      // read miss      
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (0),
                                                       .loadstore(0),
                                                       .privmode (0),
                                                       .read_data(read_data));
    end
  join

  if (wait_success) begin
    if (read_data == 0) begin
      `uvm_error(get_name(), $sformatf("Expected read data[0], actual[%0h] check with the sequence", read_data))
    end
  end else begin
    `uvm_error(get_name(), $sformatf("Stimulus had fail with wait_success[%0d], please check with the sequence", wait_success))
  end

  wait_n_clks(50);

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : cpu_wait_for_fw_op

task sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::fw_op_wait_for_cpu();
  string debug_str = "fw_op_wait_for_cpu";
  ccpui_cpu_mem_data_t read_data;
  logic [1:0]          mpu_resp;
  bit                  wait_success;
  uvm_reg_data_t       my_data;
  bit                  timeout;

  sinc_ciu_fsm_t m_force_on_ciu_cache_fsm_state = CIU_MEM_READ;


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

  //set mpu to disallow
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(0), .write_data('h0), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(0), .write_data('h0), .resp(mpu_resp));

 
  `uvm_info (get_name(), $sformatf("%s: test start, Fetch Block overlap with FW CMD(DIS_RESET)", debug_str), UVM_LOW)

  // start FW CMD (DIS_RESET)
  fork : DIS_RESET_ON_FETCH_BLOCK
    begin
      wait_n_clks(1); 
      fw_sinc_disable_reset_cmd();
    end
    begin
      // read that MPU disallowed
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read( .addr     (0),
							  .loadstore(0),
							  .privmode (0)
							  );
      // read that MPU allowed, should result blockfetch
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read( .addr     ('hFFFF),
							  .loadstore(0),
							  .privmode (0)
							  );
    end
  join

  

  wait_n_clks(50);

  // block read at the end prevent test finish before all checks done
  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (0),
                                                   .loadstore(0),
                                                   .privmode (0),
                                                   .read_data(read_data));

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : fw_op_wait_for_cpu


//##############################################################################
//<> Extern Functions
//##############################################################################
task sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::start_erase_optional();
  string debug_str = "start_erase_optional_body";
  `uvm_info(get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

  // start cache erase
  fork: sinc_sanity_erase_fork
    begin
      m_erase_rand_seq.erase_cache();
    end
  join: sinc_sanity_erase_fork

  `uvm_info(get_name(), $sformatf("%s: ended", debug_str), UVM_LOW)

  // re-initialize Cache Storage Directory as the cache mem has been wiped
  m_csd.init_csd(.en_bkdoor_load(1));

  preload_encrypted_blocks(.prog_all(1));
endtask : start_erase_optional


task sinc_concurrent_fw_op_and_fetch_block_direct_test_seq::warm_reset();
  rst_base_sequence my_reset_seq;

  my_reset_seq       = rst_base_sequence::type_id::create("m_reset_seq", , get_full_name());
  my_reset_seq.m_cfg = m_top_configuration.m_rst_env_config;

  fork: reset_and_wait
    begin : reset
      `uvm_info("RESET", "Asserting reset", UVM_LOW)
      if(!(my_reset_seq.randomize())) begin
        `uvm_error("RAND", "Could not randomize my_reset_seq")
      end
      wait_n_clks(20);
      my_reset_seq.start(m_rst_sequencer, this);
    end
    begin : monitor_reset
      wait(m_top_configuration.m_sinc_vif.mon_cb.resetn === 1'b0);
      wait(m_top_configuration.m_sinc_vif.mon_cb.resetn === 1'b1);
    end
  join



  `uvm_info("WARM_RESET", "warm_reset sequnce completed", UVM_LOW)
endtask : warm_reset

`endif // SINC_CONCURRENT_FW_OP_AND_FETCH_BLOCK_DIRECT_TEST_SEQ
