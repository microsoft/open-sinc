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
// File        : sinc_random_err_inj_seq.svh
// Description : 

`ifndef SINC_RANDOM_ERR_INJ_SEQ
`define SINC_RANDOM_ERR_INJ_SEQ

//------------------------------------------------------------------------------
// SEQUENCE: sinc_random_err_inj_seq
//------------------------------------------------------------------------------
class sinc_random_err_inj_seq extends sinc_random_base_seq;

  `uvm_object_utils(sinc_random_err_inj_seq)

  // indicate whether inject error on
  bit m_inj_err_on_stimulus_packet;
  bit m_inj_err_on_rd_req;
  bit m_inj_err_on_wr_req;
  bit m_set_aes_test_en              = 0;
  bit m_disable_reset                = 0;
  bit m_disable_reinit               = 0;
  // bit force_auth_tag_mismatch = 0;

  // error injection variable packets
  sinc_err_stimulus_packet m_err_stimulus_packet;

  function new(string name="sinc_random_err_inj_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();

  endfunction : new

  extern virtual task random_sequence_body();

  // create error injection corruption functions
  extern virtual function void inj_random_error_on_packet_item();
  extern virtual function void inj_random_error_on_stimulus_packet_item();

endclass : sinc_random_err_inj_seq

task sinc_random_err_inj_seq::random_sequence_body();
  string debug_str = "DV::random_sequence_start";

  `uvm_info (get_name(), $sformatf("%s: started: subscribe configuration", debug_str), UVM_LOW)

  m_sys_cfg.m_allow_writes_cache_active = 1;

  // when SINC_RAND_SEQ_ENABLE_ERR_INJ enabled, but not specific individual error injection, set all enable
  if (m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
    if ((m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_axi_req == 0) && (m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_axi_req == 0) &&
        (m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req == 0) && (m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req == 0) &&
        (m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req == 0) && (m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req == 0) &&
        (m_sys_cfg.m_sinc_rand_seq_enable_stimulus_err_inj_ratio == 0) ) begin
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_axi_req = 1;
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_axi_req = 1;
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req = 1;
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req = 1;
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req = 1;
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req = 1;
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_AXI_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_axi_req), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_AXI_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_axi_req), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_CPU_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_CPU_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_MPU_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Enable [SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_MPU_REQ][%0d]", m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req), UVM_LOW)
    end
  end

  m_num_trans = m_sys_cfg.m_sinc_tb_seq_trans_num; // 200;

  `uvm_info (get_name(), $sformatf("%s: started: set up seq", debug_str), UVM_LOW)

  if(m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem) begin
    if(m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem_not_all) begin
      preload_encrypted_blocks(.prog_all(0));
    end else begin
      preload_encrypted_blocks(.prog_all(1));
    end
  end

  //check if there is a desired state
  if(m_sys_cfg.m_sinc_tb_seq_use_des_cache_state) begin
    case(m_sys_cfg.m_sinc_tb_seq_des_cache_state)
      //desired state is disabled
      0: begin
        //do nothing since we start in disabled
      end
      //desired state is initialized
      1: begin
        transition_init();
      end
      //desired state is active
      2: begin
        transition_init();
        transition_active();
      end
      3: begin
        transition_failed();
        m_disable_constraints_cache_fail = 1;
      end
      default: begin
        //empty
      end
    endcase
  end

  //do bunch of mpu attr writes at beginning and not later for some cases
  if(m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read && m_sys_cfg.m_sinc_tb_seq_always_en_back_2_back) begin
    setup_mpu();
  end

  `uvm_info (get_name(), $sformatf("%s: started: begin iterations", debug_str), UVM_LOW)

  for ( int iter_n = 0; iter_n < m_num_trans ; iter_n++) begin
    m_sys_cfg.m_pal_slv_err_injector.clear_errors();
    create_stimulus_packet_item();
    randomize_stimulus_packet_item();
    if (m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
      inj_random_error_on_stimulus_packet_item();
    end else begin
      m_inj_err_on_stimulus_packet = 0;
    end
    create_transaction_packet_item();
    randomize_transaction_packet_item();
    if (m_sys_cfg.m_sinc_rand_seq_enable_err_inj && !m_inj_err_on_stimulus_packet) begin
      inj_random_error_on_packet_item();
    end
    if(m_set_aes_test_en) begin
      aes_test_enable();
    end
    if(m_disable_reset) begin
      fw_sinc_disable_reset_cmd();
      m_disable_reset = 0;
    end
    if(m_disable_reinit) begin
      fw_sinc_disable_reinit_cmd();
      m_disable_reinit = 0;
    end
    // if(force_auth_tag_mismatch) begin
    //   sinc_cache_block_t block_data;
    //   int block_num;
    //   if (!std::randomize(block_data)) begin
    //     `uvm_fatal(get_name(), "Unable to randomize block_data")
    //   end
    //   block_num = (m_transaction_packet.cpu_rd_tran.cpu_addr >> SINC_CACHE_BLOCK_NUM_CPU_ADDR_SHIFT);
    //   `uvm_info(get_name(), $sformatf("%0s: corrupting encrypted_block [%0d]",
    //                               debug_str, block_num), UVM_HIGH)
    //    load_encrypted_block_and_auth_tag_to_axi_mem(block_num, block_data, 1);
    // end
    send_packet(iter_n);
    //uncorrupt previously corrupted block
    // if(force_auth_tag_mismatch) begin
    //   sinc_cache_block_t block_data;
    //   int block_num;
    //   if (!std::randomize(block_data)) begin
    //     `uvm_fatal(get_name(), "Unable to randomize block_data")
    //   end
    //   block_num = (m_transaction_packet.cpu_rd_tran.cpu_addr >> SINC_CACHE_BLOCK_NUM_CPU_ADDR_SHIFT);
    //   `uvm_info(get_name(), $sformatf("%0s: uncorrupting encrypted_block [%0d]",
    //                               debug_str, block_num), UVM_HIGH)
    //    load_encrypted_block_and_auth_tag_to_axi_mem(block_num, block_data);
    //    force_auth_tag_mismatch = 0;
    // end
    if(m_set_aes_test_en) begin
      aes_test_disable();
      m_set_aes_test_en = 0;
    end
    // erase request can take a long time, limit the test run time by limiting the number of erase transactions
    if (m_erase_req_count == 30) begin
      m_num_trans = 40;
    end
  end // for ( int iter_n = 0; iter_n < m_num_trans ; iter_n++)

  // issue a blocking CPU read to prevent non blocking read not end before end of the test
  if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
      ccpui_cpu_mem_addr_t cpu_addr;
      ccpui_cpu_mem_we_t   cpu_we;
      ccpui_cpu_mem_data_t cpu_read_data;
      logic                cpu_loadstore;
      logic                cpu_privmode;
      
      cpu_addr      = 'h128;
      cpu_we        = 'h0;
      cpu_loadstore = 1;
      cpu_privmode  = 1;
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
      `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
      
      wait_n_clks(1000);
  end

  `uvm_info (get_name(), $sformatf("%s: task ended", debug_str), UVM_LOW)
endtask : random_sequence_body

function void sinc_random_err_inj_seq::inj_random_error_on_packet_item();
  string debug_str = "inj_random_error_on_packet_item";

  // clear ongoing error table
  m_sys_cfg.m_pal_slv_err_injector.clear_errors();
  // Inject error on AXI RD
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_axi_req) begin
    if (!(std::randomize(m_inj_err_on_rd_req) with {
            m_inj_err_on_rd_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    if (m_inj_err_on_rd_req) begin
      sinc_axi_err_inj_packet axi_err_inj_rd_packet;
      axi_err_inj_rd_packet                   = sinc_axi_err_inj_packet::type_id::create("m_axi_err_inj_rd_packet", , get_full_name());
      axi_err_inj_rd_packet.m_orig_axi_packet = m_transaction_packet.m_axi_rd_tran;
      axi_err_inj_rd_packet.m_regmodel        = m_regmodel;

      if (!axi_err_inj_rd_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      `uvm_info (get_name(), $sformatf("%s: Start error injection on AXI RD", debug_str), UVM_HIGH)

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_axi_rd_tran.print_packet();

      m_transaction_packet.m_axi_rd_tran = axi_err_inj_rd_packet.m_orig_axi_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_axi_rd_tran.print_packet();
    end
  end

  // Inject error on AXI WR
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_axi_req) begin
    if (!(std::randomize(m_inj_err_on_wr_req) with {
            m_inj_err_on_wr_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    if (m_inj_err_on_wr_req) begin
      sinc_axi_err_inj_packet axi_err_inj_wr_packet;
      int count;
      int chance;
      if (!(std::randomize(count) with { count inside {[1:50]}; })) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end
      if (!(std::randomize(chance) with { chance inside {[1:100]}; })) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      axi_err_inj_wr_packet                   = sinc_axi_err_inj_packet::type_id::create("axi_err_inj_wr_packet", , get_full_name());
      axi_err_inj_wr_packet.m_orig_axi_packet = m_transaction_packet.m_axi_wr_tran;
      axi_err_inj_wr_packet.m_regmodel        = m_regmodel;

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_axi_wr_tran.print_packet();

      `uvm_info (get_name(), $sformatf("%s: Start error injection on AXI WR", debug_str), UVM_HIGH)

      if (!axi_err_inj_wr_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      m_transaction_packet.m_axi_wr_tran = axi_err_inj_wr_packet.m_orig_axi_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_axi_wr_tran.print_packet();

      if(axi_err_inj_wr_packet.m_set_init_aes_test_en_not_clear == 1) begin
        m_set_aes_test_en = 1;
      end

      if(axi_err_inj_wr_packet.m_disable_reset_if_not_already_disabled && (m_sys_cfg.m_sinc_reset_disabled == 0)) begin
        m_disable_reset = 1;
      end

      if(axi_err_inj_wr_packet.m_disable_reinit_if_not_already_disabled && (m_sys_cfg.m_sinc_reinit_disabled == 0)) begin
        m_disable_reinit = 1;
      end

      if (axi_err_inj_wr_packet.m_set_init_rng_seed_failure) begin
        // m_sys_cfg.m_sinc_vif.set_axi_err_resp_on_rng(0);
        m_sys_cfg.m_sinc_vif.set_rng_axi_resp_err_o = 1;
        // m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(32'h8f0a0200), .end_addr(32'h8f0a0fff), .err_read_write(READ_ONLY), .count(10), .chance(90));
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(axi_err_inj_wr_packet.m_pal_error), .start_addr(sinc_parameters_pkg::SINC_RNG_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_RNG_END_ADDR), .err_read_write(READ_ONLY), .count(count), .chance(chance));

        `uvm_info(get_name(), $sformatf("Set set_rng_axi_resp_err_o %d\n", m_sys_cfg.m_sinc_vif.set_rng_axi_resp_err_o), UVM_LOW)
      end

      if (axi_err_inj_wr_packet.m_set_init_key_fetch_failure && (axi_err_inj_wr_packet.m_orig_axi_packet.m_fw_cmd == SINC_SET_INIT_STATE)) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(axi_err_inj_wr_packet.m_pal_error), .start_addr(sinc_parameters_pkg::SINC_KSU_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_KSU_END_ADDR), .err_read_write(READ_ONLY), .count(count), .chance(chance));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for key fetch\n"), UVM_LOW)
      end

      if (axi_err_inj_wr_packet.m_encr_block_rd_sharedram_err) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(axi_err_inj_wr_packet.m_pal_error), .start_addr(sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_SHAREDRAM_END_ADDR), .err_read_write(READ_ONLY), .count(count), .chance(chance));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for sharedram\n"), UVM_LOW)
      end

      if (axi_err_inj_wr_packet.m_encr_block_wr_ext_mem_cipher_err) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(axi_err_inj_wr_packet.m_pal_error), .start_addr(sinc_parameters_pkg::SINC_DMB_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_DMB_BLOCK_END_ADDR), .err_read_write(WRITE_ONLY), .count(count), .chance(chance));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for ext_mem_ciphertext\n"), UVM_LOW)
      end

      if (axi_err_inj_wr_packet.m_encr_block_wr_ext_mem_tag_err) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(axi_err_inj_wr_packet.m_pal_error), .start_addr(sinc_parameters_pkg::SINC_DMB_TAG_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_DMB_TAG_END_ADDR), .err_read_write(WRITE_ONLY), .count(count), .chance(chance));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for ext_mem_tag\n"), UVM_LOW)
      end

    end
  end

  // Inject error on MPU RD
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req) begin
    if (!(std::randomize(m_inj_err_on_rd_req) with {
            m_inj_err_on_rd_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    `uvm_info(get_name(), $sformatf("MPU_ERR_DEBUG: m_inj_err_on_rd_req is %d\n", m_inj_err_on_rd_req), UVM_LOW)

    if (m_inj_err_on_rd_req) begin
      sinc_mpu_err_inj_packet mpu_err_inj_rd_packet;
      mpu_err_inj_rd_packet                   = sinc_mpu_err_inj_packet::type_id::create("m_mpu_err_inj_rd_packet", , get_full_name());
      mpu_err_inj_rd_packet.m_orig_mpu_packet = m_transaction_packet.m_mpu_rd_tran;

      if (!mpu_err_inj_rd_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      `uvm_info (get_name(), $sformatf("%s: Start error injection on MPU RD", debug_str), UVM_HIGH)

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_mpu_rd_tran.print_packet();

      m_transaction_packet.m_mpu_rd_tran = mpu_err_inj_rd_packet.m_orig_mpu_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_mpu_rd_tran.print_packet();
    end
  end

  //make MPU WRs more likely to hit within ciram space in disabled and initiaization states, should be within 75% of the time
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR]) begin
    bit [1:0] force_page_num_below_256k;

    if((m_sys_cfg.m_cur_cache_state == CACHE_DISABLE_STATE) || (m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE)) begin
      if (!(std::randomize(force_page_num_below_256k))) begin
        `uvm_fatal(get_name(), "Unable to randomize use_page_num_256k")
      end
      if(force_page_num_below_256k != 0) begin
        m_transaction_packet.m_mpu_wr_tran.m_page_num[SINC_PAGE_SEL_WIDTH-1:SINC_256_PAGE_SEL_WIDTH] = 0;
      end
    end
  end

  // Inject error on MPU WR
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req) begin
    if (!(std::randomize(m_inj_err_on_wr_req) with {
            m_inj_err_on_wr_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    `uvm_info(get_name(), $sformatf("MPU_ERR_DEBUG: m_inj_err_on_wr_req is %d\n", m_inj_err_on_wr_req), UVM_LOW)

    if (m_inj_err_on_wr_req) begin
      sinc_mpu_err_inj_packet mpu_err_inj_wr_packet;
      mpu_err_inj_wr_packet                   = sinc_mpu_err_inj_packet::type_id::create("m_mpu_err_inj_wr_packet", , get_full_name());
      mpu_err_inj_wr_packet.m_orig_mpu_packet = m_transaction_packet.m_mpu_wr_tran;

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_mpu_wr_tran.print_packet();

      `uvm_info (get_name(), $sformatf("%s: Start error injection on MPU WR", debug_str), UVM_HIGH)

      if (!mpu_err_inj_wr_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      m_transaction_packet.m_mpu_wr_tran = mpu_err_inj_wr_packet.m_orig_mpu_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_mpu_wr_tran.print_packet();
    end
  end

  // Inject error on CPU RD
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req) begin
    if (!(std::randomize(m_inj_err_on_rd_req) with {
            m_inj_err_on_rd_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    if (m_inj_err_on_rd_req) begin
      sinc_cpu_err_inj_packet cpu_err_inj_rd_packet;
      cpu_err_inj_rd_packet                   = sinc_cpu_err_inj_packet::type_id::create("m_cpu_err_inj_rd_packet", , get_full_name());
      cpu_err_inj_rd_packet.m_orig_cpu_packet = m_transaction_packet.m_cpu_rd_tran;

      if (!cpu_err_inj_rd_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      //handle flags in sinc_cpu_err_inj_packet that need to be handled in sequence rather than by packet itself
      // tag missmatch should be done in prelaod, should not do it during the simulation
      // if(m_cpu_err_inj_rd_packet.force_auth_tag_mismatch) begin
      //   force_auth_tag_mismatch = 1;
      // end

      `uvm_info (get_name(), $sformatf("%s: Start error injection on CPU RD", debug_str), UVM_HIGH)

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_cpu_rd_tran.print_packet();

      m_transaction_packet.m_cpu_rd_tran = cpu_err_inj_rd_packet.m_orig_cpu_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_cpu_rd_tran.print_packet();

      if (cpu_err_inj_rd_packet.m_force_cache_blk_rd_failure) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_DMB_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_DMB_BLOCK_END_ADDR), .err_read_write(READ_ONLY), .count(10), .chance(90));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for cache block read\n"), UVM_LOW)
      end

      if (cpu_err_inj_rd_packet.m_force_auth_tag_rd_failure) begin
        m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_DMB_TAG_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_DMB_TAG_END_ADDR), .err_read_write(READ_ONLY), .count(10), .chance(90));
        `uvm_info(get_name(), $sformatf("Set pal_slv_err_injector for tag read\n"), UVM_LOW)
      end
    end
  end

  // Inject error on CPU WR
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR] &&
      m_sys_cfg.m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req) begin
    if (!(std::randomize(m_inj_err_on_wr_req) with {
            m_inj_err_on_wr_req dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_transaction_err_inj_ratio)};
          })) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    if (m_inj_err_on_wr_req) begin
      sinc_cpu_err_inj_packet cpu_err_inj_wr_packet;
      cpu_err_inj_wr_packet                   = sinc_cpu_err_inj_packet::type_id::create("m_cpu_err_inj_wr_packet", , get_full_name());
      cpu_err_inj_wr_packet.m_orig_cpu_packet = m_transaction_packet.m_cpu_wr_tran;

      `uvm_info(get_name(), $sformatf("%s: Before error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_cpu_wr_tran.print_packet();

      `uvm_info (get_name(), $sformatf("%s: Start error injection on CPU WR", debug_str), UVM_HIGH)

      if (!cpu_err_inj_wr_packet.randomize() with {
            // yaml config can be used to control specific stimulus sequence
          }) begin
        `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end

      m_transaction_packet.m_cpu_wr_tran = cpu_err_inj_wr_packet.m_orig_cpu_packet;

      `uvm_info(get_name(), $sformatf("%s: After error injection: \n", debug_str), UVM_LOW)
      m_transaction_packet.m_cpu_wr_tran.print_packet();
    end
  end

endfunction : inj_random_error_on_packet_item

function void sinc_random_err_inj_seq::inj_random_error_on_stimulus_packet_item();
  string debug_str = "inj_random_error_on_stimulus_packet_item";

  if (!(std::randomize(m_inj_err_on_stimulus_packet) with {
          m_inj_err_on_stimulus_packet dist {1 := m_sys_cfg.m_sinc_rand_seq_enable_stimulus_err_inj_ratio, 0 := (100 - m_sys_cfg.m_sinc_rand_seq_enable_stimulus_err_inj_ratio)};
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  if (m_inj_err_on_stimulus_packet && !m_sys_cfg.m_sinc_vif.aes_test_en) begin
    m_err_stimulus_packet = sinc_err_stimulus_packet::type_id::create("m_err_stimulus_packet", , get_full_name());
    if (!m_err_stimulus_packet.randomize() with {
          // yaml config can be used to control specific stimulus sequence
        }) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end

    `uvm_info(get_name(), $sformatf("%s: err_stimulus_packet_item randomized \n", debug_str), UVM_LOW)
    m_err_stimulus_packet.print_packet(m_trans_count);

    // manually cast new variable values to stimulus_packet
    m_stimulus_packet.m_stimulus_sel        = m_err_stimulus_packet.m_stimulus_sel;
    m_stimulus_packet.m_erase_mem_pre_delay = m_err_stimulus_packet.m_erase_mem_pre_delay;
    m_stimulus_packet.m_axi_rd_pre_delay    = m_err_stimulus_packet.m_axi_rd_pre_delay;
    m_stimulus_packet.m_axi_wr_pre_delay    = m_err_stimulus_packet.m_axi_wr_pre_delay;
    m_stimulus_packet.m_cpu_rd_pre_delay    = m_err_stimulus_packet.m_cpu_rd_pre_delay;
    m_stimulus_packet.m_cpu_wr_pre_delay    = m_err_stimulus_packet.m_cpu_wr_pre_delay;
    m_stimulus_packet.m_wait_for_axi_sub    = m_err_stimulus_packet.m_wait_for_axi_sub;
    m_stimulus_packet.m_wait_for_erase      = m_err_stimulus_packet.m_wait_for_erase;
    m_stimulus_packet.m_wait_for_cpu        = m_err_stimulus_packet.m_wait_for_cpu;
    m_stimulus_packet.m_wait_for_cmu_busy   = m_err_stimulus_packet.m_wait_for_cmu_busy;
    m_stimulus_packet.m_do_cmu_busy         = m_err_stimulus_packet.m_do_cmu_busy;
    m_stimulus_packet.m_two_axi_wr          = m_err_stimulus_packet.m_two_axi_wr;
  end else if (m_inj_err_on_stimulus_packet && m_sys_cfg.m_sinc_vif.aes_test_en) begin
    `uvm_info(get_name(), $sformatf("%s: err_stimulus_packet_item skipped when aes_test_en \n", debug_str), UVM_LOW)
  end

endfunction : inj_random_error_on_stimulus_packet_item

`endif // SINC_RANDOM_ERR_INJ_SEQ
