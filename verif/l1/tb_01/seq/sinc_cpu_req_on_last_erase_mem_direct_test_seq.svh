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
// File        : sinc_cpu_req_on_last_erase_mem_direct_test_seq.svh
// Description : 

`ifndef SINC_CPU_REQ_ON_LAST_ERASE_MEM_DIRECT_TEST_SEQ
 `define SINC_CPU_REQ_ON_LAST_ERASE_MEM_DIRECT_TEST_SEQ

//##############################################################################
//<> SEQUENCE: sinc_cpu_req_on_last_erase_mem_direct_test_seq
//##############################################################################

/**
 * ECC Error Injection Test Sequence
 */
class sinc_cpu_req_on_last_erase_mem_direct_test_seq extends sinc_virtual_base_sequence;

  sinc_fault_err_packet m_fault_err_packet;
  
  `uvm_object_utils(sinc_cpu_req_on_last_erase_mem_direct_test_seq)

  rand ccpui_cpu_mem_addr_t       m_address[10];

  constraint address_c {
    foreach (m_address[i]) {
      m_address[i] dist {0:=1, [1:'h3F_FFFE]:/1, 'h3F_FFFF:=1}; //TODO use define for address ranges
    }
  }


  function new(string name="sinc_cpu_req_on_last_erase_mem_direct_test_seq");
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

  extern virtual task sinc_status_reg_err_check(input bit expect_hw_fault, input bit[7:0] expected_state);

  extern virtual task sequential_run_body();

endclass : sinc_cpu_req_on_last_erase_mem_direct_test_seq

//##############################################################################
//<> Test Specific Functions
//##############################################################################

function void sinc_cpu_req_on_last_erase_mem_direct_test_seq::process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

endfunction : process_plusargs_and_populate_seq_item

task sinc_cpu_req_on_last_erase_mem_direct_test_seq::sinc_status_reg_err_check(input bit expect_hw_fault, input bit [7:0] expected_state);
  string debug_str        = "DV::sinc_status_reg_err_chk";
  bit    neg_test;
  logic  mem_err_uncorr_o;

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)
 

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with { }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if(my_status != UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
  end

  if(!expect_hw_fault) begin
    if(my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])
      `uvm_error(get_name(), $sformatf("HW Fault error detected SINC_STATUS['h%h] but none error expected", 32'(my_data)))
  end else begin
    if(!my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])
      `uvm_error(get_name(), $sformatf("HW Fault error expected but not observed SINC_STATUS['h%h]", 32'(my_data)))
  end

  if(my_data[`SINC_REGS_STATUS_AES_ERR_MSB])
    `uvm_error(get_name(), $sformatf("AES error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag write  error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag check   error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag read   error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_MSB])
    `uvm_error(get_name(), $sformatf("Write cache block error during fetch block command  error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_MSB])
    `uvm_error(get_name(), $sformatf("Write cache block error during encrypt block command  error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Read cache block error   detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Key fetch failed error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("RNG seed read  error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Invalid command error detected 'h%h", my_data))
  if(my_data[`SINC_REGS_STATUS_CMD_FAILED_MSB])
    `uvm_error(get_name(), $sformatf("Command failed  error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] !== expected_state) begin
    `uvm_error(get_name(), $sformatf("Status Read: ['h%0h], Expected Cache State ['h%h]. Actual Cache State ['h%h]", my_data, expected_state, my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
  end

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)
endtask : sinc_status_reg_err_check

task sinc_cpu_req_on_last_erase_mem_direct_test_seq::sequential_run_body();
  string debug_str = "vtag_parity_error_inj_seq_body";
  ccpui_cpu_mem_data_t read_data;
  logic [1:0]          mpu_resp;
  bit                  wait_success;

  sinc_ciu_fsm_t m_force_on_ciu_cache_fsm_state = CIU_MEM_READ;

  if(!this.randomize(m_address) with { 
    // 
  } ) begin
    `uvm_fatal("RAND", "Unable to randomize m_address")
  end

 
  `uvm_info (get_name(), $sformatf("%s: test start erase, wait until the last erase mem happen before CPU RD with no MPU violation", debug_str), UVM_LOW)

  wait_n_clks(20);
  // start FSM error injection on the next state
  fork : CPU_RD_ON_LAST_ERASE_WITHOUT_MPU_VIOLATION
    begin
      m_erase_rand_seq.erase_cache();
    end
    begin
      m_top_configuration.m_sinc_vif.wait_till_last_erase_mem(wait_success);
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (0),
                                                       .loadstore(0),
                                                       .privmode (0),
                                                       .read_data(read_data));
    end
  join

  if (wait_success) begin
    if (read_data !== 0) begin
      `uvm_error(get_name(), $sformatf("Expected read data[0], actual[%0h] check with the sequence", read_data))
    end
  end else begin
    `uvm_error(get_name(), $sformatf("Stimulus had fail with wait_success[%0d], please check with the sequence", wait_success))
  end

  wait_n_clks(50);

  `uvm_info (get_name(), $sformatf("%s: test start erase, wait until the last erase mem happen before CPU RD with MPU violation", debug_str), UVM_LOW)

  //set mpu to disallow
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(1), .target_privilege_attr(0), .attr_offset(0), .write_data('h0), .resp(mpu_resp));
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr(0), .target_privilege_attr(1), .attr_offset(0), .write_data('h0), .resp(mpu_resp));
  
  wait_n_clks(20);
  // start FSM error injection on the next state
  fork : CPU_RD_ON_LAST_ERASE_WITH_MPU_VIOLATION
    begin
      m_erase_rand_seq.erase_cache();
    end
    begin
      m_top_configuration.m_sinc_vif.wait_till_last_erase_mem(wait_success);
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (0),
                                                       .loadstore(0),
                                                       .privmode (0),
                                                       .read_data(read_data));
    end
  join
  
  

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : sequential_run_body


//##############################################################################
//<> Extern Functions
//##############################################################################
task sinc_cpu_req_on_last_erase_mem_direct_test_seq::start_erase_optional();
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
endtask : start_erase_optional


task sinc_cpu_req_on_last_erase_mem_direct_test_seq::warm_reset();
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

`endif // SINC_CPU_REQ_ON_LAST_ERASE_MEM_DIRECT_TEST_SEQ
