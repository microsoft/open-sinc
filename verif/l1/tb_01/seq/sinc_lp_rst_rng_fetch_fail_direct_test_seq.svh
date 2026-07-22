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
// File        : sinc_lp_rst_rng_fetch_fail_direct_test_seq.svh
// Description : 

`ifndef SINC_LP_RST_RNG_FETCH_FAIL_DIRECT_TEST_SEQ
 `define SINC_LP_RST_RNG_FETCH_FAIL_DIRECT_TEST_SEQ

//##############################################################################
//<> SEQUENCE: sinc_lp_rst_rng_fetch_fail_direct_test_seq
//##############################################################################

/**
 * ECC Error Injection Test Sequence
 */

typedef enum {
  LP_W_FIRST_RNG_RESP_ERR  = 0,
  LP_W_SECOND_RNG_RESP_ERR = 1
} sinc_rng_resp_err_e;

class sinc_lp_rst_rng_fetch_fail_direct_test_seq extends sinc_virtual_base_sequence;

  sinc_fault_err_packet m_fault_err_packet;
  bit [6:0]  m_set_for_encrypt;
  bit [7:0]  m_tags_for_encrypt[5];

  `uvm_object_utils(sinc_lp_rst_rng_fetch_fail_direct_test_seq)

  function new(string name="sinc_lp_rst_rng_fetch_fail_direct_test_seq");
    super.new(name);
    process_plusargs_and_populate_seq_item();
  endfunction : new

  virtual task body();
    super.body();
    test_done();
  endtask : body


  extern virtual task start_erase_optional();
  extern virtual task low_power_reset();
  extern virtual function void process_plusargs_and_populate_seq_item();
  extern virtual function void inject_pal_rng_error(sinc_rng_resp_err_e err_type);


  extern virtual task sequential_run_body();
  extern virtual task warm_reset();

endclass : sinc_lp_rst_rng_fetch_fail_direct_test_seq

//##############################################################################
//<> Test Specific Functions
//##############################################################################

function void sinc_lp_rst_rng_fetch_fail_direct_test_seq::process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

endfunction : process_plusargs_and_populate_seq_item

task sinc_lp_rst_rng_fetch_fail_direct_test_seq::sequential_run_body();
  string debug_str = "sinc_lp_rst_rng_fetch_fail_direct_test_seq_body";
  ccpui_cpu_mem_data_t read_data;
  logic [1:0]          mpu_resp;
  bit                  wait_success;
  sinc_rng_resp_err_e  sinc_rng_resp_err_type;
  bit                  timeout;
  uvm_reg_data_t       my_data = 0;
  uvm_reg_data_t       exp_status = 0;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  reg_data_t                    block_encr_num  = 'h0;
  reg_data_t                    block_encr_addr = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;
  reg_data_t                    num_of_blocks   = 'h1;

  sinc_ciu_fsm_t m_force_on_ciu_cache_fsm_state = CIU_MEM_READ;

  m_tags_for_encrypt[0] = 'h0;
  m_tags_for_encrypt[1] = 'h18;
  m_tags_for_encrypt[2] = 'h31;
  m_tags_for_encrypt[3] = 'h3c;
  m_tags_for_encrypt[4] = 'had;

  m_set_for_encrypt     = 'h0;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  /*
  if(!this.randomize(m_address) with {
    //
  } ) begin
    `uvm_fatal("RAND", "Unable to randomize m_address")
  end
  */

  // clear ongoing error table
  m_top_configuration.m_sys_cfg.m_pal_slv_err_injector.clear_errors();

  // transition to init state
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


  `uvm_info (get_name(), $sformatf("%s: test start: low power reset, assert 1st RNG fail", debug_str), UVM_LOW)
  sinc_rng_resp_err_type = LP_W_FIRST_RNG_RESP_ERR;
  inject_pal_rng_error(sinc_rng_resp_err_type);
  low_power_reset();

  block_encr_num[6:0]  = m_set_for_encrypt;
  block_encr_num[14:7] = m_tags_for_encrypt[0];
  fw_block_encr(.program_misc_reg(1), .block_encr_num(block_encr_num), .block_encr_addr(block_encr_addr), .num_of_blocks(num_of_blocks));

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING) begin
    // Note the cache state sometimes won't be set at same time of RNG_SEED_R_ERR
    exp_status = 0;
    exp_status[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
    if (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] !== 1) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
    if (my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] !== 1) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
    // if (exp_status !== my_data) begin
    //   `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    // end
  end else begin
    // SINC_NO_SEED_LOADING bypasses the DRBG seed-read on lp_rstn exit (MAS 14.2);
    // PAL RNG SLVERR cannot fire, so fw_block_encr completes normally.
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF))) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: expected cmd_success[1]+state[F], got status['h%0h]", my_data))
    end
    if (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] !== 0) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: unexpected RNG_SEED_R_ERR, status['h%0h]", my_data))
    end
    if (my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] !== 0) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: unexpected CMD_FAILED, status['h%0h]", my_data))
    end
  end

  wait_n_clks(20);
  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING) begin
    exp_status = 0;
    exp_status[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
    if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
  end else begin
    // SINC_NO_SEED_LOADING=1: no seed re-fetch -> stays in INIT, not CACHE_FAIL (MAS 14.2)
    if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_INIT_STATE) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: expected state[INIT], got status['h%0h]", my_data))
    end
  end

  // warm reset
  `uvm_info (get_name(), $sformatf("%s: Warm Reset", debug_str), UVM_LOW)
  warm_reset();
  pull_status(my_data, timeout);
  if (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE]) begin
    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
  end

  if (my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]) begin
    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
  end

  if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
    `uvm_error(get_name(), $sformatf("unexpected status reg[%0h]", my_data))
  end


  // clear ongoing error table
  m_top_configuration.m_sys_cfg.m_pal_slv_err_injector.clear_errors();

  // transition to init state
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

  `uvm_info (get_name(), $sformatf("%s: test start: low power reset, assert 2nd RNG fail", debug_str), UVM_LOW)
  sinc_rng_resp_err_type = LP_W_SECOND_RNG_RESP_ERR;
  inject_pal_rng_error(sinc_rng_resp_err_type);
  low_power_reset();

  block_encr_num[6:0]  = m_set_for_encrypt;
  block_encr_num[14:7] = m_tags_for_encrypt[0];
  fw_block_encr(.program_misc_reg(1), .block_encr_num(block_encr_num), .block_encr_addr(block_encr_addr), .num_of_blocks(num_of_blocks));

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING) begin
    // Note the cache state sometimes won't be set at same time of RNG_SEED_R_ERR
    exp_status = 0;
    exp_status[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
    if (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] !== 1) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
    if (my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] !== 1) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
    // if (exp_status !== my_data) begin
    //   `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    // end
  end else begin
    // SINC_NO_SEED_LOADING bypasses the DRBG seed-read on lp_rstn exit (MAS 14.2);
    // PAL RNG SLVERR cannot fire, so fw_block_encr completes normally.
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF))) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: expected cmd_success[1]+state[F], got status['h%0h]", my_data))
    end
    if (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] !== 0) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: unexpected RNG_SEED_R_ERR, status['h%0h]", my_data))
    end
    if (my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] !== 0) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: unexpected CMD_FAILED, status['h%0h]", my_data))
    end
  end

  wait_n_clks(20);
  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING) begin
    exp_status = 0;
    exp_status[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 1;
    exp_status[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
    if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
      `uvm_error(get_name(), $sformatf("unexpected status reg[%0h], exp[%0h]", my_data, exp_status))
    end
  end else begin
    // SINC_NO_SEED_LOADING=1: no seed re-fetch -> stays in INIT, not CACHE_FAIL (MAS 14.2)
    if (my_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_INIT_STATE) begin
      `uvm_error(get_name(), $sformatf("NO_SEED_LOADING=1: expected state[INIT], got status['h%0h]", my_data))
    end
  end

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : sequential_run_body


//##############################################################################
//<> Extern Functions
//##############################################################################
task sinc_lp_rst_rng_fetch_fail_direct_test_seq::start_erase_optional();
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


task sinc_lp_rst_rng_fetch_fail_direct_test_seq::low_power_reset();
  `uvm_info("LOW_POWER_RESET", "low power reset started", UVM_LOW)

  m_top_configuration.m_sinc_vif.low_power_reset();

  `uvm_info("LOW_POWER_RESET", "low power reset completed", UVM_LOW)
endtask : low_power_reset

function void sinc_lp_rst_rng_fetch_fail_direct_test_seq::inject_pal_rng_error(sinc_rng_resp_err_e err_type);
  string debug_str = "inject_pal_rng_error";

  if (err_type == LP_W_FIRST_RNG_RESP_ERR) begin
    m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_RNG_START_ADDR), .end_addr(32'h8f0a_0201), .err_read_write(READ_ONLY), .count(10), .chance(100));
  end else if (err_type == LP_W_SECOND_RNG_RESP_ERR) begin
    m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(32'h8f0a_0228), .end_addr(32'h8f0a_0241), .err_read_write(READ_ONLY), .count(10), .chance(100));
  end

endfunction : inject_pal_rng_error

task sinc_lp_rst_rng_fetch_fail_direct_test_seq::warm_reset();
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
`endif // SINC_LP_RST_RNG_FETCH_FAIL_DIRECT_TEST_SEQ
