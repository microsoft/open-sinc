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
// File        : sinc_resp_error_aes_test_directed_seq.svh
// Description : 

`ifndef SINC_RESP_ERROR_AES_TEST_DIRECTED_SEQ
`define SINC_RESP_ERROR_AES_TEST_DIRECTED_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_resp_error_aes_test_directed_seq
//------------------------------------------------------------------------------

typedef enum {
  FIRST_RNG_RESP_ERR  = 0,
  SECOND_RNG_RESP_ERR = 1,
  KEY_FETCH_RESP_ERR = 2
} sinc_aes_cmd_resp_err_e;

/**
 * SINC Sanity Test Sequence
 */
class sinc_resp_error_aes_test_directed_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_resp_error_aes_test_directed_seq)

  // count the iteration loop
  static int loop_count = 0;

  // copy of prior key for reuse key and bit to see if we have established an initial key
  sinc_key_t m_reuse_key_data;
  bit        m_initial_key_set          = 0;

  function new(string name="sinc_resp_error_aes_test_directed_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();
  endfunction : new

  extern virtual task sequential_run_body();
  extern virtual task start_erase_optional();
  extern virtual task body();
  extern virtual task aes_test_mode(input sinc_aes_test_mode_random_type_e use_directed_data=SINC_AES_TEST_MODE_RANDOM, input sinc_aes_cmd_resp_err_e err_type);
  extern virtual task warm_reset();
  extern virtual function void process_plusargs_and_populate_seq_item();

endclass : sinc_resp_error_aes_test_directed_seq

task sinc_resp_error_aes_test_directed_seq::start_erase_optional();
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

task sinc_resp_error_aes_test_directed_seq::sequential_run_body();
  string debug_str = "sequential_run_body";
  bit             timeout;
  uvm_reg_data_t  my_data;

  `uvm_info(get_name(), $sformatf("%s: Inside sinc_resp_error_aes_test_directed_seq", debug_str), UVM_LOW)

  `uvm_info(get_name(), $sformatf("##### Starting sinc_resp_error_aes_test_directed_seq at sequential run body, loop_count[%0d]", loop_count), UVM_LOW)

  for (loop_count = 0; loop_count < 3; ) begin
    if (loop_count==0) begin
      aes_test_mode(SINC_AES_TEST_MODE_DIRECTED, FIRST_RNG_RESP_ERR);
      warm_reset();
    end else if (loop_count==1) begin
      aes_test_mode(SINC_AES_TEST_MODE_DIRECTED, SECOND_RNG_RESP_ERR);
      warm_reset();
    end else if (loop_count==2) begin
      aes_test_mode(SINC_AES_TEST_MODE_DIRECTED, KEY_FETCH_RESP_ERR);
      warm_reset();
    end 
    
    loop_count ++;
  end

endtask : sequential_run_body


function void sinc_resp_error_aes_test_directed_seq:: process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_RESP_ERROR_AES_TEST_DIRECTED_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

endfunction : process_plusargs_and_populate_seq_item

task sinc_resp_error_aes_test_directed_seq::aes_test_mode(input sinc_aes_test_mode_random_type_e use_directed_data=SINC_AES_TEST_MODE_RANDOM, input sinc_aes_cmd_resp_err_e err_type);
  string          debug_str         = "DV::aes_test_mode";
  sinc_aes_packet aes_pkt;
  sinc_axi_data_t tmp_axi_data[];
  uvm_reg_data_t  uvm_reg_data[10];                       // reserved to save intermidia reg data
  bit             timeout;
  uvm_reg_data_t  my_data;
  bit             last_data_segment;
  int             num_data_segments;
  bit [1:0]  keylen;
  int   data_in_byte_cnt;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)
  
  // clear ongoing error table
  m_top_configuration.m_sys_cfg.m_pal_slv_err_injector.clear_errors();

  aes_pkt               = sinc_aes_packet::type_id::create("aes_pkt", , get_full_name());
  aes_pkt.m_aes_test_mode = 1;
 
  if (err_type == FIRST_RNG_RESP_ERR) begin
    m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_RNG_START_ADDR), .end_addr(32'h8f0a_0201), .err_read_write(READ_ONLY), .count(10), .chance(100));
  end else if (err_type == SECOND_RNG_RESP_ERR) begin
    m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(32'h8f0a_0228), .end_addr(32'h8f0a_0241), .err_read_write(READ_ONLY), .count(10), .chance(100));
  end else if (err_type == KEY_FETCH_RESP_ERR) begin
    m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_KSU_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_KSU_END_ADDR), .err_read_write(READ_ONLY), .count(10), .chance(100));
  end

  `uvm_info (get_name(), $sformatf("Error Type [%0s]", err_type.name()), UVM_LOW)

  if(use_directed_data == SINC_AES_TEST_MODE_DIRECTED) begin
    /// create sinc_aes_packet with direct test inputs
    aes_pkt.m_reuse_key          = 0;
    aes_pkt.m_aes_op             = sinc_parameters_pkg::ENCRYPT;
    aes_pkt.m_aes_mode           = sinc_parameters_pkg::GCM;
    aes_pkt.m_aes_unit_sz        = sinc_parameters_pkg::BYTES_16;
    aes_pkt.m_aes_key_len        = sinc_parameters_pkg::AES_256;
    aes_pkt.m_byte_count         = 16;
    aes_pkt.m_aes_message        = new[4];
    aes_pkt.m_aes_message[0]     = 'h7d01_1d98;
    aes_pkt.m_aes_message[1]     = 'h2206_9a08;
    aes_pkt.m_aes_message[2]     = 'hf856_2593;
    aes_pkt.m_aes_message[3]     = 'h8e16_b52d;
    aes_pkt.m_key_data           = {32'h8f0c_409c, 32'h8f0c_4098, 32'h8f0c_4094, 32'h8f0c_4090, 32'h8f0c_408c, 32'h8f0c_4088, 32'h8f0c_4084, 32'h8f0c_4080};
    aes_pkt.m_key_slot           = 1;
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
  wait_aes_status(.cfg_key_iv_rdy(1), .data_in_rdy(0), .data_out_vld(0), .tag_out(0), .counter(5000), .timeout(timeout) );
  `uvm_info (get_name(), $sformatf("%s: wait till cfg_key_iv_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

  if(timeout) begin
    `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
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
      if ((err_type == FIRST_RNG_RESP_ERR) || 
	  (err_type == SECOND_RNG_RESP_ERR) ||
	  (err_type == KEY_FETCH_RESP_ERR)) begin
	pull_status(my_data, timeout);
	if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
	  `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
	end
	if ((err_type == FIRST_RNG_RESP_ERR) || (err_type == SECOND_RNG_RESP_ERR)) begin
	  if (!my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE]) begin
	    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
	  end
	end
	if (err_type == KEY_FETCH_RESP_ERR) begin
	  if (!my_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE]) begin
	    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
	  end
	end
	return;
      end else begin
	`uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
	aes_test_disable();
	return;
      end
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
      if ((err_type == FIRST_RNG_RESP_ERR) || 
	  (err_type == SECOND_RNG_RESP_ERR)) begin
	pull_status(my_data, timeout);
	if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
	  `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
	end
	if ((err_type == FIRST_RNG_RESP_ERR) || (err_type == SECOND_RNG_RESP_ERR)) begin
	  if (!my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE]) begin
	    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
	  end
	end
	return;
      end else begin
	`uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
	aes_test_disable();
	return;
      end
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

task sinc_resp_error_aes_test_directed_seq::warm_reset();
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
      /*
      if (0 == m_top_configuration.m_rst_env_config.randomize()) begin
        `uvm_fatal(get_name(), $sformatf("Randomize failed!!!"))
      end
      m_top_configuration.m_rst_env_config.m_do_phase_jump            = 1;
      m_top_configuration.m_rst_env_config.m_reset_count              = 1;
      m_top_configuration.m_rst_env_config.m_reset_min_interval       = 10;
      m_top_configuration.m_rst_env_config.m_reset_max_interval       = 20;
      m_top_configuration.m_rst_env_config.m_reset_deassert_delay_min = 1;
      m_top_configuration.m_rst_env_config.m_reset_deassert_delay_max = 20;
      m_top_configuration.m_rst_env_config.print();
      
      // Perform reset.
      m_top_configuration.m_rst_env_config.do_dynamic_reset(uvm_root::get().m_current_phase);
      */
      my_reset_seq.start(m_rst_sequencer, this);
    end
    begin : monitor_reset
      wait(m_top_configuration.m_sinc_vif.mon_cb.resetn === 1'b0);
      wait(m_top_configuration.m_sinc_vif.mon_cb.resetn === 1'b1);
    end
  join

  ->m_axi_mst_seq.m_sp_con_seq.seq_done_e;
  wait_n_clks(10);

  fork: start_axi_seq          
    begin
      m_axi_mst_seq.start(null); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.4.2 */
    end
  join
  
  m_top_configuration.m_regmodel.reset();

  `uvm_info("WARM_RESET", "warm_reset sequnce completed", UVM_LOW)
endtask : warm_reset

task sinc_resp_error_aes_test_directed_seq::body();
  super.body();

  test_done();
  
  // time start_time;
  // `uvm_info(get_name(), "Starting Virtual Base Sequence", UVM_LOW)

  // if (!$cast(m_regmodel, m_top_configuration.m_regmodel)) begin
  //   `uvm_fatal("CAST", "Could not cast m_regmodel")
  // end

  // if (m_top_configuration.m_sys_cfg == null) begin
  //   `uvm_fatal(get_name(), "m_top_configuration.m_sys_cfg has not been created before usage")
  // end else begin
  //   m_sys_cfg     = m_top_configuration.m_sys_cfg;
  //   m_mpu_cfg     = m_top_configuration.ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
  //   m_dmb_sys_cfg = m_sys_cfg.get_comp_cfg(sinc_env_pkg::SINC_DMB);
  //   m_csd         = m_top_configuration.m_csd;
  // end

  // // fork pal, sideband, error injection sequences
  // fork: sinc_virtual_base_seq_fork
  //   begin
  //     fork: concurrent_behavior_fork
  //       begin
  //         m_axi_mst_seq.start(m_sequencer, this); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */
  //       end
  //       begin
  //         m_erase_rand_seq.start(m_sequencer, this); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */
  //       end
  //       begin
  //         m_cpu_rand_seq.start(m_sequencer, this); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */
  //       end
  //       begin
  //         m_mpu_rand_seq.start(m_sequencer, this); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */
  //       end
  //       begin
  //         m_ramwrap_inj_rand_seq.start(m_sequencer, this); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.4.2 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */
  //       end
  //       begin
  //         // leave for MEM Inject
  //       end
  //     join :concurrent_behavior_fork
  //   end
  //   //do_check_soc_reset();
  // join_any :sinc_virtual_base_seq_fork

  // start_erase_optional();

  // // sequencial transactions
  // sequential_run_body();

  // // random transactions
  // random_sequence_body();

  // start_time = $time();
  // while( ($time() - start_time) < 20us) begin
  //   wait_n_clks(1);
  // end

  // if (loop_count > 3)  begin
  //   ->m_axi_mst_seq.m_sp_con_seq.seq_done_e;
  //   ->m_erase_rand_seq.cache_erase_seq.seq_done_e;
  //   ->m_cpu_rand_seq.cpu_mem_seq.seq_done_e;
  //   ->m_mpu_rand_seq.mpu_seq.seq_done_e;

  //   `uvm_info (get_name(), $sformatf("Ending Virtual Base Sequence: loop_count[d%0d]", loop_count), UVM_LOW)
  //   test_done();
  // end

  
endtask : body


`endif // SINC_RESP_ERROR_AES_TEST_DIRECTED_SEQ

// @DVT_LINTER_WAIVER_END
