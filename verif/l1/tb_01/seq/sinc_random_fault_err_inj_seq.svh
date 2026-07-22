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
// File        : sinc_random_fault_err_inj_seq.svh
// Description : 

`ifndef SINC_RANDOM_FAULT_ERR_INJ_SEQ
`define SINC_RANDOM_FAULT_ERR_INJ_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_random_fault_err_inj_seq
//------------------------------------------------------------------------------

class sinc_random_fault_err_inj_seq extends sinc_random_base_seq;

  `uvm_object_utils(sinc_random_fault_err_inj_seq)

  // indicate fault error type of this test
  sinc_fault_error_type_e m_fault_err_type;

  sinc_fault_err_packet m_fault_err_packet;

  int m_iter_n                = 0;
  bit m_is_hw_or_aes_fault_set= 0;
  bit m_is_hw_fault_set       = 0;
  bit m_is_aes_fault_set      = 0;

  int m_fsm_error_state_hit_cnt = 0;

  // Variable: control the AXI stimulus generating parity on AxUSER
  // default 1, only set by fault error injection sequence
  bit m_enable_axuser_parity = 1;

  function new(string name="sinc_random_fault_err_inj_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();

  endfunction : new

  extern virtual task random_sequence_body();

  // create error injection corruption functions
  extern virtual task inj_random_fault_error_on_incoming_transaction(int trans_iter);
  extern virtual task monitor_random_fault_error_on_incoming_transaction(int trans_iter);

  extern virtual task test_dut_behavior_after_halt();

  extern virtual task dut_recovery();
  extern virtual task warm_reset();
  extern virtual task dut_recovery_check();
  extern virtual task cpu_mem_access(input ccpui_cpu_mem_addr_t addr, bit is_wr_rd, bit is_err_injected);
  extern virtual task send_packet(int iter_n);
  extern virtual task pull_status(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);
  extern virtual task fw_set_init_state(
    bit        program_misc_reg       = 0,
    reg_data_t aes_iv_nonce_0         = 'h0,
    reg_data_t aes_iv_nonce_1         = 'h0,
    reg_data_t aes_iv_nonce_2         = 'h0,
    reg_data_t block_encr_key         = 'h0,
    address_t  ext_block_base_addr    = 'h0,
    address_t  ext_auth_tag_base_addr = 'h0
  );

  extern virtual task fw_set_active_state();
  extern virtual task update_sinc_state();
  extern virtual task update_sinc_faults(uvm_reg_data_t my_data);
  extern virtual task wait_aes_status(
                                      input bit cfg_key_iv_rdy,
                                      input bit data_in_rdy,
                                      input bit data_out_vld,
                                      input bit tag_out,
                                      input int counter        = 5000,
                                      ref   bit timeout
                                      );

  extern virtual task write_reg_value(input uvm_reg item, uvm_reg_data_t value, bit is_ro=0);
  extern virtual task read_reg_value(input uvm_reg item, ref uvm_reg_data_t reg_rdata);
  extern virtual task set_up_fw_operation(input sinc_fw_cmd_e fw_cmd, bit is_valid_req);

endclass : sinc_random_fault_err_inj_seq

task sinc_random_fault_err_inj_seq::random_sequence_body();
  string                        debug_str          = "DV::random_sequence_start";
  string                        tmp_str;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  sinc_axi_reg_access_extension ext_obj;
  int                           tmp;
  int                           txn_cnt            =0;
  bit                           skip_the_cur_iter_n=0;
  process                       proc[$];
  process                       txn_proc[$];
  bit                           err_inj_done;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  m_num_trans = m_sys_cfg.m_sinc_tb_seq_trans_num; // 200;

  `uvm_info (get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

  //fixme sequence currently does not handle case where this is not set
  //would need to keep track of which blocks were encrypted during init state
  //and only read those curing cache actitve if we want to ensure valid accesses
  if(m_sys_cfg.m_sinc_tb_seq_backdoor_preload_mem) begin
    preload_encrypted_blocks(.prog_all(1));
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
      default: begin
        //empty
      end
    endcase
  end

  if (!(std::randomize(m_fault_err_type) with {
          if (m_top_configuration.m_sys_cfg.m_sinc_enable_specific_fault_err) {
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_ciu_cache_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_cmu_ctrl_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_cache_state_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_sinc_sub_state_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_aes_ctrl_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_dma_r_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_dma_w_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_aes_keyexp_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_main_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_gpaes_ghash_mul_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_sec_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL ; }
            m_top_configuration.m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_ghash_fsm_illegal -> { m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL; }
            // reserve for other fault error
          }
        })) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  `uvm_info (get_name(), $sformatf("%s: started with m_fault_err_type=%s", debug_str, m_fault_err_type.name()), UVM_LOW)

  for ( m_iter_n = 0; m_iter_n < m_num_trans ; m_iter_n++) begin
    begin : fault_inj
      inj_random_fault_error_on_incoming_transaction(m_iter_n);
    end

    begin : monitor_fault_inj
      monitor_random_fault_error_on_incoming_transaction(m_iter_n);
    end

    begin : stimulus
      if ((m_fault_err_type == FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_VTAG_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL)
        ) begin

        // keep sending stimulus until fault error has been injected
        while (!m_top_configuration.m_sys_cfg.get_is_fsm_fault_err_injected()) begin
          `uvm_info(get_name(), $sformatf(" Random txn sent started: txn number=%d iteration =%d\n", txn_cnt, m_iter_n), UVM_HIGH)
          txn_proc.push_back(process::self());
          create_stimulus_packet_item();
          update_sinc_state();
          randomize_stimulus_packet_item();
          create_transaction_packet_item();
          randomize_transaction_packet_item();
          send_packet(m_iter_n);
          txn_cnt++;
          `uvm_info(get_name(), $sformatf(" Random txn sent done: txn number=%d iteration =%d\n", txn_cnt, m_iter_n), UVM_HIGH)
          //After 40 transaction skipping wait for current FSM state and
          //move to nect state
          if(txn_cnt == 40) begin
            skip_the_cur_iter_n = 1;
            `uvm_info (get_name(), $sformatf("%s:iter:%d skipping txn generation for %s . txn_cnt=%d", debug_str, m_iter_n, m_fault_err_type.name(), txn_cnt), UVM_LOW)
            break;
          end
        end
      end
    end

    begin : recovery
      `uvm_info(get_name(), $sformatf(" iter:%d waiting for fault_err_injection done\n", m_iter_n), UVM_LOW)
      if ((m_fault_err_type == FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_VTAG_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL) ||
          (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL)
        ) begin
        `uvm_info(get_name(), $sformatf("fault_err_injection done: %d \n", tmp), UVM_HIGH)
        if ( (m_top_configuration.m_sys_cfg.get_is_fsm_fault_err_injected()) && (!skip_the_cur_iter_n) ) begin
          test_dut_behavior_after_halt();

          dut_recovery();
          m_fsm_error_state_hit_cnt++;
        end
      end
    end
    //reset it for next iteration
    skip_the_cur_iter_n = 0;
    //resetting txn cnt for next transaction
    txn_cnt             =0;
    `uvm_info(get_name(), $sformatf("iter:%d DUT recovery task completed\n", m_iter_n), UVM_HIGH)

  end
  //Check at least 1 fsm error covered in random scenario
  //Changing it to info as it is not a design issue
  if(m_fsm_error_state_hit_cnt == 0)
    `uvm_info(get_name(), $sformatf("%s: No error FSM state hit, check the stimulus", debug_str), UVM_LOW)

  `uvm_info (get_name(), $sformatf("%s: task ended", debug_str), UVM_HIGH)
endtask : random_sequence_body

task sinc_random_fault_err_inj_seq::monitor_random_fault_error_on_incoming_transaction(int trans_iter);
  string                        debug_str = "monitor_random_fault_error_on_incoming_transaction";
  sinc_axi_reg_access_extension ext_obj;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  bit                           timeout;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  fork : mon_sinc_err_triggered
    begin
      wait(m_top_configuration.m_sinc_vif.sinc_err_triggered && m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected);
      m_sys_cfg.m_cur_cache_state = CACHE_FAIL_STATE;
      `uvm_info(get_name(), $sformatf("%s :sinc_err_triggered, is_fsm_fault_err_injected=%d", debug_str, m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected), UVM_LOW)
      if(m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected) begin
        `uvm_info(get_name(), $sformatf("%s :sinc_err_triggered, checking status register", debug_str), UVM_LOW)
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        if(my_status !== UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end

        `uvm_info(get_name(), $sformatf("%s :STATUS='h%h HW_FAULT :%d AES_ERR: %d", debug_str, my_data, my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB], my_data[`SINC_REGS_STATUS_AES_ERR_LSB] ), UVM_LOW)
        update_sinc_faults(my_data);
      end
    end
  join_none
endtask :monitor_random_fault_error_on_incoming_transaction

task sinc_random_fault_err_inj_seq::inj_random_fault_error_on_incoming_transaction(int trans_iter);
  string                        debug_str = "inj_random_fault_error_on_incoming_transaction";
  sinc_axi_reg_access_extension ext_obj;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  bit                           timeout;

  m_fault_err_packet = sinc_fault_err_packet::type_id::create("m_fault_err_packet", , get_full_name());
  ext_obj            = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  if (!m_fault_err_packet.randomize() with {
        // yaml config can be used to control specific stimulus sequence
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  `uvm_info(get_name(), $sformatf("%s: fault_err_packet randomized \n", debug_str), UVM_HIGH)
  m_fault_err_packet.print_packet(trans_iter);

  if (m_fault_err_type == FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL) begin
    fork : inject_fault_error_ciu_cache
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_ciu_cache_fsm_state_illegal(m_fault_err_packet.m_force_on_ciu_cache_fsm_state, m_fault_err_packet.m_illegal_ciu_cache_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL) begin
    fork : inject_fault_error_cmu_ctrl
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_cmu_ctrl_fsm_state_illegal(m_fault_err_packet.m_force_on_cmu_ctrl_fsm_state, m_fault_err_packet.m_illegal_cmu_ctrl_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL) begin
    fork : inject_fault_error_cmu_sinc_cache
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_cmu_sinc_cache_fsm_state_illegal(m_fault_err_packet.m_force_on_cmu_sinc_cache_fsm_state, m_fault_err_packet.m_illegal_cmu_sinc_cache_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL) begin
    fork : inject_fault_error_sinc_sub
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_sinc_sub_fsm_state_illegal(m_fault_err_packet.m_force_on_cmu_ctrl_fsm_state, m_fault_err_packet.m_illegal_sinc_sub_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL) begin
    fork : inject_fault_error_aes_ctrl
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_aes_ctrl_fsm_state_illegal(m_fault_err_packet.m_force_on_aes_ctrl_fsm_state, m_fault_err_packet.m_illegal_aes_ctrl_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL) begin
    fork : inject_fault_error_dma_r
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_dma_r_fsm_state_illegal(m_fault_err_packet.m_force_on_dma_r_fsm_state, m_fault_err_packet.m_illegal_dma_r_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL) begin
    fork : inject_fault_error_dma_w
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_dma_w_fsm_state_illegal(m_fault_err_packet.m_force_on_dma_w_fsm_state, m_fault_err_packet.m_illegal_dma_w_fsm_state);
      end

    join_none
  end

  //if (m_fault_err_type == FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL) begin
  //  fork : inject_fault_error_aes_keyexp
  //    begin
  //      top_configuration.m_sinc_vif.inject_fault_error_aes_keyexp_fsm_state_illegal(m_fault_err_packet.m_force_on_aes_keyexp_fsm_state, m_fault_err_packet.m_illegal_aes_keyexp_fsm_state);
  //    end

  //  join_none
  //end

  if (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL) begin
    fork : inject_fault_error_gpaes_mode_main
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_gpaes_mode_main_fsm_state_illegal(m_fault_err_packet.m_force_on_cmu_ctrl_fsm_state, m_fault_err_packet.m_illegal_gpaes_mode_main_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL) begin
    fork : inject_fault_error_ghash_mul
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_ghash_mul_fsm_state_illegal(m_fault_err_packet.m_force_on_cmu_ctrl_fsm_state, m_fault_err_packet.m_illegal_ghash_mul_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL) begin
    fork : inject_fault_error_gpaes_sub
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_gpaes_sub_state_fsm_state_illegal(m_fault_err_packet.m_force_on_gpaes_mode_ghash_fsm_state, m_fault_err_packet.m_illegal_gpaes_sub_state_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL) begin
    fork : inject_fault_error_gpaes_mode_ghash
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_gpaes_mode_ghash_fsm_state_illegal(m_fault_err_packet.m_force_on_gpaes_mode_ghash_fsm_state, m_fault_err_packet.m_illegal_gpaes_mode_ghash_fsm_state);
      end

    join_none
  end

  if (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL) begin
    fork : inject_fault_error_gpaes_mode_sec
      begin
        m_top_configuration.m_sinc_vif.inject_fault_error_gpaes_mode_sec_fsm_state_illegal(m_fault_err_packet.m_force_on_gpaes_mode_sec_fsm_state, m_fault_err_packet.m_illegal_gpaes_mode_sec_fsm_state);
      end

    join_none
  end

  fork : inject_cur_cache_state
    begin
      wait(m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected === 1'b1);
      wait_n_clks(10);
      //m_regmodel.cmd.read(my_status, my_data, .extension(ext_obj));
      //if(my_data[] == 1)
      m_sys_cfg.m_cur_cache_state = CACHE_FAIL_STATE;
    end
  join_none

  `uvm_info(get_name(), $sformatf("%s: fault error injection done: \n", debug_str), UVM_LOW)

endtask : inj_random_fault_error_on_incoming_transaction

task sinc_random_fault_err_inj_seq::test_dut_behavior_after_halt();
  string                        debug_str = "test_dut_behavior_after_halt";
  sinc_axi_reg_access_extension ext_obj;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  bit                           timeout;
  process                       proc[$];

  `uvm_info (debug_str, $sformatf("start %0s", get_name()), UVM_LOW)

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  //Adding a delay to mimic err inj to fault
  wait_n_clks(50);
  m_is_hw_fault_set  = m_top_configuration.m_sinc_vif.hw_fault_set;
  m_is_aes_fault_set = m_top_configuration.m_sinc_vif.aes_fault_set;

  `uvm_info (debug_str, $sformatf("%0s is_hw_fault_set=%d is_aes_fault_set=%d ", get_name(), m_is_hw_fault_set, m_is_aes_fault_set), UVM_LOW)
  //FOR GPAES FSM AES_ERR will be set in STATUS register in case of fsm fault.
  //For remaining FSM, HW_FAULT will be set in case of fsm fault.
  if (
      (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL) ||
      (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL) ||
      (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL) ||
      (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL) ||
      (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL)
    ) begin
    if(m_is_aes_fault_set) begin
      m_is_hw_or_aes_fault_set = 1;
    end
  end else begin
    if(m_is_hw_fault_set) begin
      m_is_hw_or_aes_fault_set = 1;
    end
  end

  if(!m_is_hw_or_aes_fault_set ) begin
    fork : check_for_busy_fork
      begin
        proc.push_back(process::self());
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        if(my_status !== UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end
        if (
            (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL) ||
            (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL) ||
            (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL) ||
            (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL) ||
            (m_fault_err_type == FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL)
          ) begin
          //For GPAES FSM FAULT AES_ERR will be set in status register
          while (!my_data[`SINC_REGS_STATUS_AES_ERR_LSB]) begin
            if(timeout) begin
              break;
            end

            wait_n_clks(10);
            m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
            if(my_status !== UVM_IS_OK) begin
              `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
            end
          end
        end else begin
          while (!my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB]) begin
            if(timeout) begin
              break;
            end

            wait_n_clks(10);
            m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
            if(my_status !== UVM_IS_OK) begin
              `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
            end
          end
        end
        timeout=0;
        `uvm_info(get_name(), $sformatf("Observed HW_FAULT error, STATUS_REG[%d] ='h%h", `SINC_REGS_STATUS_SINC_HW_FAULT_LSB, my_data), UVM_LOW)
      end
      begin
        proc.push_back(process::self());
        `uvm_info(get_name(), "check_error_status : timeout loop started", UVM_HIGH)
        wait_n_clks(500);
        timeout=1;
        `uvm_info(get_name(), "check_error_status : timeout loop ended", UVM_HIGH)
      end
    join_any

    // Kill any outstanding processes
    foreach(proc[i]) begin
      if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
        proc[i].kill();
      end

    end
  end else begin
    timeout=0;
  end

  if(!m_top_configuration.m_sinc_vif.sinc_err_triggered)
    `uvm_error(get_name(), $sformatf("expected sinc_err_o to be triggered due to fsm fault ['h%h]", m_top_configuration.m_sinc_vif.sinc_err_triggered))

  if(timeout)
    `uvm_error(get_name(), $sformatf("expected HW_FAULT/AES_ERR error but not triggered. SINC STATUS ['h%h]", my_data))
  //Check CPU access during error injection, error data should be returned
  //16: addr 1: write 1: access during error injection`
  cpu_mem_access(16, 1, 1);

  //Clear sinc_err flag
  m_top_configuration.m_sinc_vif.clear_sinc_err();
  `uvm_info (debug_str, $sformatf("finished at %0s", get_name()), UVM_LOW)
endtask : test_dut_behavior_after_halt

task sinc_random_fault_err_inj_seq::dut_recovery();
  string                        debug_str = "dut_recovery";
  sinc_axi_reg_access_extension ext_obj;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  uvm_reg_data_t                reg_value;
  bit                           timeout;

  `uvm_info (debug_str, $sformatf("start %0s", get_name()), UVM_LOW)

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  `uvm_info (get_name(), $sformatf("%s:m_fsm_halt_recover_by_op [%0s]", debug_str, m_fault_err_packet.m_fsm_halt_recover_by_op.name()), UVM_LOW)

  if (m_fault_err_packet.m_fsm_halt_recover_by_op == sinc_parameters_pkg::FSM_FAULT_RECOVER_OP_FW_SINC_RESET) begin
    fw_sinc_reset_cmd();
    m_initial_key_set = 0;
  end

  if (m_fault_err_packet.m_fsm_halt_recover_by_op == sinc_parameters_pkg::FSM_FAULT_RECOVER_OP_WARM_RESET) begin
    warm_reset();
    m_sys_cfg.m_nonce0_is_set            = 0;
    m_sys_cfg.m_nonce1_is_set            = 0;
    m_sys_cfg.m_nonce2_is_set            = 0;
    m_sys_cfg.m_key_slot_is_set          = 0;
    m_sys_cfg.m_sinc_reset_disabled      = 0;
    m_sys_cfg.m_sinc_reinit_disabled     = 0;
    m_sys_cfg.m_ext_block_base_is_set    = 0;
    m_sys_cfg.m_ext_auth_tag_base_is_set = 0;
    m_sys_cfg.m_block_encr_addr_is_set   = 0;
    m_initial_key_set                    = 0;
    //Reseting RAL beacuse of warm reset
    m_regmodel.reset();
  end
  m_top_configuration.m_sys_cfg.set_is_fsm_fault_err_injected(0);

  m_is_hw_or_aes_fault_set =0;
  pull_status(my_data, timeout);
  m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;
  `uvm_info (get_name(), $sformatf("%s: Reset operation completed", debug_str), UVM_LOW)

  m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if(my_status !== UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
  end
  if( (my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB]) || (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hFF) || (m_is_hw_or_aes_fault_set) )
    `uvm_fatal(get_name(), $sformatf("unexpected HW_FAULT/CACHE FAILED state after %s. SINC STATUS ='h%0h", m_fault_err_packet.m_fsm_halt_recover_by_op.name(), my_data))

  `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation started. iter:%d", debug_str, m_iter_n), UVM_LOW)
  // preload_encrypted_blocks
  preload_encrypted_blocks(.prog_all(1));
  `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation completed. iter:%d", debug_str, m_iter_n), UVM_LOW)

  dut_recovery_check();

  m_is_hw_or_aes_fault_set =0;
  m_is_hw_fault_set        = 0;
  m_is_aes_fault_set       = 0;
  m_top_configuration.m_sinc_vif.set_fault_value(0, 0);
  m_top_configuration.m_sinc_vif.set_fault_value(0, 0);

endtask : dut_recovery

task sinc_random_fault_err_inj_seq::dut_recovery_check();
  uvm_reg my_reg;
  uvm_reg my_regs[$];
  int     reg_size;
  int     reg_sel;

  `uvm_info (get_name(), $sformatf("dut_recovery_check: cpu access check started. iter:%d ", m_iter_n), UVM_HIGH)
  cpu_mem_access(16, 1, 0);
  `uvm_info (get_name(), $sformatf("dut_recovery_check: cpu access check completed. iter:%d ", m_iter_n), UVM_HIGH)
  my_reg=m_regmodel.get_reg_by_name("status");
  m_regmodel.get_registers(my_regs);
  reg_size = my_regs.size();
  //FIXME-As some register like nonce registers gets cleared during cache_failed state and test_registers task does not have the prediction logic
  //So checking read write access only no reset value
  m_sys_cfg.m_reset_reg_tested = 1;
  if(!std::randomize(reg_sel) with {reg_sel inside {[0:reg_size]};}) begin
    `uvm_fatal("RAND", "std::randomize failed to randomize 'reg_sel'")
  end
  `uvm_info (get_name(), $sformatf("dut_recovery_check: reg access check started:%d ", m_iter_n), UVM_HIGH)
  test_register(my_reg);

  `uvm_info (get_name(), $sformatf("dut_recovery_check: reg access check completed. iter:%d ", m_iter_n), UVM_HIGH)
endtask : dut_recovery_check

task sinc_random_fault_err_inj_seq::warm_reset();
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

task sinc_random_fault_err_inj_seq::cpu_mem_access(input ccpui_cpu_mem_addr_t addr, bit is_wr_rd, bit is_err_injected);
  string                        debug_str      = "DV::sinc_cpu_mem_access_check";
  ccpui_cpu_mem_addr_t          cpu_addr;
  ccpui_cpu_mem_addr_t          addr_m;
  bit                           cpu_write;
  ccpui_cpu_mem_we_t            cpu_we;
  ccpui_cpu_mem_data_t          cpu_write_data = 0;
  logic                         cpu_loadstore;                                   // must be 1 for CPU WRITE
  logic                         cpu_privmode;
  bit                           is_mpu_allowed;
  bit                           r_acc_vio;
  bit                           r_accvio_ex;
  bit                           r_accvio_rd;
  bit                           r_accvio_wr;
  ccpui_cpu_mem_data_t          cpu_read_data;
  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  cpu_addr = addr;
  `uvm_info (get_name(), $sformatf("%s:cpu access on address 'h%h write_read:%d started", debug_str, cpu_addr, is_wr_rd), UVM_LOW)
  if(!is_wr_rd) begin
    // test read - addr[0]
    cpu_write     = 0;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode));
    end else begin
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    end
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_LOW)
    is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
      .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));

    if (!m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
      if (!is_mpu_allowed) begin
        if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
          `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
        end
      end else begin
        if(is_err_injected && (cpu_read_data != sinc_parameters_pkg::SINC_CPU_ERRDATA)) begin
          `uvm_error(get_name(), $sformatf("%s:Expected error response during fsm error. SINC_STATUS['h%0h], CPU_READ_DATA ['h%0h]", debug_str, my_data, cpu_read_data))
        end else if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
          m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
          if(my_status !== UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
          end

          if((my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])) begin
            `uvm_error(get_name(), $sformatf("%s:unexpected HW_FAULT. SINC_STATUS['h%0h], CPU_READ_DATA ['h%0h]", debug_str, my_data, cpu_read_data))
            update_sinc_faults(my_data);
          end
        end
      end
    end
  end else begin
    cpu_write      = 1;
    cpu_we         = 'hF;
    cpu_loadstore  = 1;
    cpu_privmode   = 1;
    cpu_write_data = 'hFFFF_FFFF;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
    `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

    // test read after write
    cpu_write     = 0;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode));
      `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    end else begin
      m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
      `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
      if(!is_err_injected) begin
        if (cpu_read_data !== cpu_write_data) begin
          `uvm_error(get_name(), $sformatf("%s: Expect  READ Data['h%0h], Actual Write ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
        end
      end else begin
        if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
          `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
        end
      end
    end
  end

  `uvm_info (get_name(), $sformatf("%s:cpu access on address 'h%s - done", cpu_addr, debug_str), UVM_LOW)

endtask : cpu_mem_access

//---------------------------
// send_packet ()
//---------------------------
task sinc_random_fault_err_inj_seq::send_packet (int iter_n);
  string                        debug_str               = "send_packet";
  bit                           concurrent_stimulus_set = 0;
  process                       aes_proc[$];
  sinc_axi_reg_access_extension ext_obj;
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  if ($countones(m_stimulus_packet.m_stimulus_sel) > 1) begin
    concurrent_stimulus_set = 1;
  end

  `uvm_info(get_name(), $sformatf("\nSend SINC Packet [%0d], concurrent_stimulus_set[%0d] stimulus_sel[%d] SINC STATE = %s", iter_n, concurrent_stimulus_set, m_stimulus_packet.m_stimulus_sel, m_sys_cfg.m_cur_cache_state.name()), UVM_NONE)
  // Exit the task if the current cache state is CACHE_FAIL_STATE
  if (m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected) begin
    `uvm_info(get_name(), "Exiting send_packet task due to Error injection", UVM_LOW)
    return;
  end

  //Send transactions depends on stimulus packet
  fork : send_stimulus_fork
    begin : axi_rd
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD]) begin
        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_AXI_RD  started\n"), UVM_LOW)
        // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_axi_rd_pre_delay);
        end
        m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_transaction_packet.m_axi_rd_tran.m_addr), .read_data(m_transaction_packet.m_axi_rd_tran.m_read_data), .burst_length(m_transaction_packet.m_axi_rd_tran.m_burst_length), .id(m_transaction_packet.m_axi_rd_tran.m_id), .response(m_transaction_packet.m_axi_rd_tran.m_response), .burst_size(m_transaction_packet.m_axi_rd_tran.m_burst_size),
          .prot(m_transaction_packet.m_axi_rd_tran.m_prot), .aruser(m_transaction_packet.m_axi_rd_tran.m_axuser), .lock(0), .cache(m_transaction_packet.m_axi_rd_tran.m_cache), .burst_type(m_transaction_packet.m_axi_rd_tran.m_burst_type));
      end
      `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_AXI_RD  done\n"), UVM_LOW)
    end : axi_rd

    begin : axi_wr
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR]) begin
        bit timeout;

        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_AXI_WR  started\n"), UVM_LOW)

        // wait_n_clks(m_transaction_packet.axi_wr_tran.pre_delay);
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_axi_wr_pre_delay);
        end

        // set up firmware command, for example fw_compare command needs to program COMP_BUFFER registers before start command
        if ((m_transaction_packet.m_axi_wr_tran.m_do_fw_request == 1) && (m_sys_cfg.m_skip_fw_cmd == 0)) begin
          //todo need to finish implementing this function in virtual base sequence
          set_up_fw_operation(m_transaction_packet.m_axi_wr_tran.m_fw_cmd,
            m_transaction_packet.m_axi_wr_tran.m_is_valid_req);

          //skip write for aes test en since do more elaborate sequence in aes_test_mode() task
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_AES_TEST_EN) begin
            fork : aes_proc_fork
              begin
                aes_proc.push_back(process::self());
                if(m_sys_cfg.m_err_inj_prior_trns_no_status_clear == 0) begin
                  aes_test_mode(m_transaction_packet.m_axi_wr_tran.m_pull_status_after_fw_request);
                end else begin
                  //since status isn't clear, setting aes test enable should result in bus error and not entering aes
                  //test mode so don't need to do full sequence
                  aes_test_enable();
                  //now do status clear
                  wait_n_clks(10);
                  pull_status(my_data, timeout);
                  m_sys_cfg.m_err_inj_prior_trns_no_status_clear = 0;
                end
                //since we did aes test mode, no need to write cmd reg after this so set skip
                m_sys_cfg.m_skip_fw_cmd = 1;
              end
              begin
                while (!m_top_configuration.m_sys_cfg.get_is_fsm_fault_err_injected()) begin
                  aes_proc.push_back(process::self());
                  wait_n_clks(5);
                end
                m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
                if(my_status !== UVM_IS_OK) begin
                  `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
                end

                update_sinc_faults(my_data);
              end
            join_any
            // Kill any outstanding processes
            foreach(aes_proc[i]) begin
              if ((aes_proc[i] != null) && (aes_proc[i].status() != process::FINISHED)) begin
                aes_proc[i].kill();
              end

            end
          end
          `uvm_info(get_name(), $sformatf("aes_test_mode task completed STATUS_REG ='h%h", my_data), UVM_HIGH)

          // fixme-hw: some of below code will be removed after scoreboard and monitor in place
          //for now update state based on command type
          //may need to keep clearing initial_key_set bit for aes test mode upon sinc reset if sb doesn't track that
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SET_INIT_STATE) begin
            m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SET_CACHE_ACTIVE_STATE) begin
            m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SINC_RESET) begin
            m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;
            m_initial_key_set           = 0;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SINC_REINIT) begin
            m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
          end

          //look for disable commands and set cfg
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_DISABLE_RESET) begin
            m_sys_cfg.m_sinc_reset_disabled = 1;
          end

          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_DISABLE_REINIT) begin
            m_sys_cfg.m_sinc_reinit_disabled = 1;
          end
        end

        `uvm_info(get_name(), $sformatf("DEBUG: do write as long as skip fw cmd is 0 or it isn't a fw request"), UVM_HIGH)
        //do write as long as skip fw cmd is 0 or it isn't a fw request
        if((m_sys_cfg.m_skip_fw_cmd == 0) || (m_transaction_packet.m_axi_wr_tran.m_do_fw_request == 0)) begin

          m_axi_mst_seq.sinc_axi_write_access_with (.addr(m_transaction_packet.m_axi_wr_tran.m_addr), .write_data(m_transaction_packet.m_axi_wr_tran.m_write_data), .wstrb(m_transaction_packet.m_axi_wr_tran.m_wstrb), .burst_length(m_transaction_packet.m_axi_wr_tran.m_burst_length), .id(m_transaction_packet.m_axi_wr_tran.m_id), .response(m_transaction_packet.m_axi_wr_tran.m_response), .burst_size(m_transaction_packet.m_axi_wr_tran.m_burst_size),
            .prot(m_transaction_packet.m_axi_wr_tran.m_prot), .awuser(m_transaction_packet.m_axi_wr_tran.m_axuser), .lock(0), .cache(m_transaction_packet.m_axi_wr_tran.m_cache), .burst_type(m_transaction_packet.m_axi_wr_tran.m_burst_type));

          `uvm_info(get_name(), $sformatf("DEBUG: AXI write completed"), UVM_HIGH)

          if (m_transaction_packet.m_axi_wr_tran.m_do_fw_request && m_transaction_packet.m_axi_wr_tran.m_pull_status_after_fw_request) begin
            wait_n_clks(10);
            pull_status(my_data, timeout);
            m_sys_cfg.m_err_inj_prior_trns_no_status_clear = 0;

            if (timeout) begin
              `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
            end else begin
              `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)
            end

          end else if(m_transaction_packet.m_axi_wr_tran.m_do_fw_request && (m_transaction_packet.m_axi_wr_tran.m_pull_status_after_fw_request == 0)) begin
            m_sys_cfg.m_err_inj_prior_trns_no_status_clear = 1;
          end
        end
      end
    end : axi_wr

    begin : cpu_rd
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD]) begin

        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_CPU_MEM_RD  started\n"), UVM_LOW)
        // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_cpu_rd_pre_delay);
        end

        if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read( .addr     (m_transaction_packet.m_cpu_rd_tran.m_cpu_addr     ),
                                                            .loadstore(m_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore),
            .privmode(m_transaction_packet.m_cpu_rd_tran.m_cpu_privmode));
        end else begin
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (m_transaction_packet.m_cpu_rd_tran.m_cpu_addr     ),
                                                         .loadstore(m_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore),
                                                         .privmode (m_transaction_packet.m_cpu_rd_tran.m_cpu_privmode ),
            .read_data(m_transaction_packet.m_cpu_rd_tran.m_cpu_read_data));
        end
        `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, m_transaction_packet.m_cpu_rd_tran.m_cpu_addr, m_transaction_packet.m_cpu_rd_tran.m_cpu_read_data), UVM_LOW)

      end
    end : cpu_rd

    begin : cpu_wr
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_CPU_MEM_WR  started\n"), UVM_LOW)
        //don't do cpu writes in cache active state since not allowed
        if(m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) begin
          // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
          if (concurrent_stimulus_set) begin
            wait_n_clks(m_stimulus_packet.m_cpu_wr_pre_delay);
          end
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write( .addr      (m_transaction_packet.m_cpu_wr_tran.m_cpu_addr      ),
                                                          .loadstore (m_transaction_packet.m_cpu_wr_tran.m_cpu_loadstore ),
                                                          .privmode  (m_transaction_packet.m_cpu_wr_tran.m_cpu_privmode  ),
                                                          .write_data(m_transaction_packet.m_cpu_wr_tran.m_cpu_write_data),
            .we(m_transaction_packet.m_cpu_wr_tran.m_cpu_we));
          `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, m_transaction_packet.m_cpu_wr_tran.m_cpu_addr, m_transaction_packet.m_cpu_wr_tran.m_cpu_write_data), UVM_LOW)
        end else begin
          `uvm_info (get_name(), $sformatf("SKIP CPU Write in CACHE_ACTIVE_STATE"), UVM_LOW)
        end
      end
    end : cpu_wr

    begin : mpu_rd
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD]) begin
        int reg_number = m_transaction_packet.m_mpu_rd_tran.m_page_num / 8;
        logic [1:0] mpu_resp;
        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_MPU_RD  started\n"), UVM_LOW)
        // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_mpu_rd_pre_delay);
        end

        if(m_transaction_packet.m_mpu_rd_tran.m_do_generic_access == 1) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_generic_read(.addr_offset(m_transaction_packet.m_mpu_rd_tran.m_addr     ),
                                                        .read_data  (m_transaction_packet.m_mpu_rd_tran.m_read_data),
            .resp(mpu_resp));
          `uvm_info (get_name(), $sformatf("%s: MPU Generic Read Data['h%0h], Read Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_rd_tran.m_read_data, mpu_resp), UVM_HIGH)
        end else if(m_transaction_packet.m_mpu_rd_tran.m_mpu_cmd == SINC_MPU_ATTR_READ) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_read(.target_user_attr     (m_transaction_packet.m_mpu_rd_tran.m_is_trn_user_reg),
                                                          .target_privilege_attr(m_transaction_packet.m_mpu_rd_tran.m_is_trn_priv_reg),
                                                          .attr_offset          (reg_number                                          ),
                                                          .read_data            (m_transaction_packet.m_mpu_rd_tran.m_read_data      ),
            .resp(mpu_resp));
          `uvm_info (get_name(), $sformatf("%s: MPU Attr Read Data['h%0h], Read Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_rd_tran.m_read_data, mpu_resp), UVM_HIGH)
        end else if(m_transaction_packet.m_mpu_rd_tran.m_mpu_cmd == SINC_MPU_STATUS_READ) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_reg_read(m_transaction_packet.m_mpu_rd_tran.m_read_data, mpu_resp);
          `uvm_info (get_name(), $sformatf("%s: MPU Status Read Data['h%0h], Read Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_rd_tran.m_read_data, mpu_resp), UVM_HIGH)
        end else begin
          `uvm_error (get_name(), $sformatf("%s: MPU CMD[%0s] is not valid type for MPU MEM RD stimulus]", debug_str, m_transaction_packet.m_mpu_rd_tran.m_mpu_cmd.name()))
        end
      end
    end : mpu_rd

    begin : mpu_wr
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR]) begin
        int reg_number = m_transaction_packet.m_mpu_rd_tran.m_page_num / 8;
        logic [1:0] mpu_resp;
        `uvm_info(get_name(), $sformatf("SINC_STIMULUS_SEL_MPU_WR  started\n"), UVM_LOW)
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_mpu_wr_pre_delay);
        end
        if(m_transaction_packet.m_mpu_wr_tran.m_do_generic_access == 1) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_generic_write(.addr_offset(m_transaction_packet.m_mpu_wr_tran.m_addr      ),
                                                         .write_data (m_transaction_packet.m_mpu_wr_tran.m_write_data),
            .resp(mpu_resp));
          `uvm_info (get_name(), $sformatf("%s: MPU Generic Write Data['h%0h], Write Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_wr_tran.m_write_data, mpu_resp), UVM_HIGH)
        end else if(m_transaction_packet.m_mpu_wr_tran.m_mpu_cmd == SINC_MPU_ATTR_WRITE) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr     (m_transaction_packet.m_mpu_wr_tran.m_is_trn_user_reg),
                                                           .target_privilege_attr(m_transaction_packet.m_mpu_wr_tran.m_is_trn_priv_reg),
                                                           .attr_offset          (reg_number                                          ),
                                                           .write_data           (m_transaction_packet.m_mpu_wr_tran.m_write_data     ),
            .resp(mpu_resp));
          `uvm_info (get_name(), $sformatf("%s: MPU Attr Write Data['h%0h], Write Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_wr_tran.m_write_data, mpu_resp), UVM_HIGH)
        end else if(m_transaction_packet.m_mpu_wr_tran.m_mpu_cmd == SINC_MPU_STATUS_WRITE) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_writeclear(mpu_resp);
          `uvm_info (get_name(), $sformatf("%s: MPU Status Write Clear Resp['h%0h]", debug_str, mpu_resp), UVM_HIGH)
        end else begin
          `uvm_error (get_name(), $sformatf("%s: MPU CMD[%0s] is not valid type for MPU MEM WR stimulus]", debug_str, m_transaction_packet.m_mpu_rd_tran.m_mpu_cmd.name()))
        end
      end
    end : mpu_wr

    begin : erase_mem
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM]) begin
        `uvm_info (get_name(), $sformatf("SINC_STIMULUS_SEL_ERASE_MEM seq started"), UVM_LOW)
        // wait_n_clks(m_transaction_packet.erase_mem_pre_delay);
        if (concurrent_stimulus_set) begin
          //skip erase packet if concurrent stimulus is set since that isn't a valid scenario, will be covered in error testing
        end else begin
          `uvm_info (get_name(), $sformatf("erase_cache seq called"), UVM_LOW)
          m_erase_rand_seq.erase_cache();
          m_erase_req_count++;
          `uvm_info (get_name(), $sformatf("erase_cache completed"), UVM_LOW)
        end
      end
    end : erase_mem

    begin : reset_dut
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_HW_RESET]) begin
        rst_base_sequence my_reset_seq;

        my_reset_seq       = rst_base_sequence::type_id::create("m_reset_seq", , get_full_name());
        my_reset_seq.m_cfg = m_top_configuration.m_rst_env_config;

        `uvm_info (get_name(), $sformatf("SINC_STIMULUS_SEL_HW_RESET seq started"), UVM_LOW)
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


        m_sys_cfg.m_nonce0_is_set            = 0;
        m_sys_cfg.m_nonce1_is_set            = 0;
        m_sys_cfg.m_nonce2_is_set            = 0;
        m_sys_cfg.m_key_slot_is_set          = 0;
        m_sys_cfg.m_sinc_reset_disabled      = 0;
        m_sys_cfg.m_sinc_reinit_disabled     = 0;
        m_sys_cfg.m_ext_block_base_is_set    = 0;
        m_sys_cfg.m_ext_auth_tag_base_is_set = 0;
        m_sys_cfg.m_block_encr_addr_is_set   = 0;
        m_sys_cfg.m_cur_cache_state          = CACHE_DISABLE_STATE;
        m_initial_key_set                    = 0;

      end
    end : reset_dut

  join

  `uvm_info(get_name(), $sformatf("\nSend SINC Packet Done[%0d]", iter_n), UVM_HIGH)
  m_trans_count++;

endtask : send_packet// send_packet

task sinc_random_fault_err_inj_seq::pull_status(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       proc[$];
  uvm_reg_data_t                local_status_rdata;
  bit                           local_timeout;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  //Wait for status register
  fork : check_for_busy_fork
    begin
      proc.push_back(process::self());
      m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
      update_sinc_faults(my_data);
      if(my_status !== UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
      end

      // SINC is in BUSY status
      while (my_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_MSB]) begin
        wait_n_clks(50);
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        update_sinc_faults(my_data);
        if(my_status !== UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end
      end

      local_status_rdata = my_data;
      local_timeout      = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  status_rdata = local_status_rdata;
  timeout      = local_timeout;


  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : pull_status
// transition into ACTIVE state

task sinc_random_fault_err_inj_seq::fw_set_active_state();
  super.fw_set_active_state();
  m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;
endtask : fw_set_active_state
//Updating state as SB not enabled for error scenario

task sinc_random_fault_err_inj_seq::fw_set_init_state(
    bit        program_misc_reg       = 0,
    reg_data_t aes_iv_nonce_0         = 'h0,
    reg_data_t aes_iv_nonce_1         = 'h0,
    reg_data_t aes_iv_nonce_2         = 'h0,
    reg_data_t block_encr_key         = 'h0,
    address_t  ext_block_base_addr    = 'h0,
    address_t  ext_auth_tag_base_addr = 'h0
  );
  super.fw_set_init_state (
    .program_misc_reg   (program_misc_reg   ),
    .aes_iv_nonce_0     (aes_iv_nonce_0     ),
    .aes_iv_nonce_1     (aes_iv_nonce_1     ),
    .aes_iv_nonce_2     (aes_iv_nonce_2     ),
    .block_encr_key     (block_encr_key     ),
    .ext_block_base_addr(ext_block_base_addr),
    .ext_auth_tag_base_addr(ext_auth_tag_base_addr) );

  m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
endtask : fw_set_init_state

task sinc_random_fault_err_inj_seq::update_sinc_state();
  string debug_str = "update_sinc_state";

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if(my_status !== UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
  end
  if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'h00) begin
    m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;
  end else if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'h0F) begin
    m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
  end else if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0) begin
    m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;
  end else if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hFF) begin
    m_sys_cfg.m_cur_cache_state = CACHE_FAIL_STATE;
  end else begin
    `uvm_info (get_name(), $sformatf("%s: Invalid SINC cache state", debug_str), UVM_LOW)
  end
  //Error injection can happen while generating random stimulus so checking
  //Fault status also.
  update_sinc_faults(my_data);

endtask : update_sinc_state

task sinc_random_fault_err_inj_seq::wait_aes_status(
                                                    input bit cfg_key_iv_rdy,
                                                    input bit data_in_rdy,
                                                    input bit data_out_vld,
                                                    input bit tag_out,
                                                    input int counter        = 5000,
                                                    ref   bit timeout
                                                    );

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       proc[$];
  bit                           local_timeout;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (!ext_obj.randomize()) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  //Wait for aes status register
  fork : check_for_given_status
    begin
      proc.push_back(process::self());
      m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
      if(my_status !== UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()))
      end

      if (cfg_key_iv_rdy) begin
        // `uvm_info(get_name(), $sformatf("debug: cfg_key_iv_rdy set %0d, SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_LSB[%0d], my_data['h%0h]", cfg_key_iv_rdy, SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_LSB, my_data), UVM_LOW)
        while (my_data[`SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          if(my_status !== UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()))
          end
        end
      end

      if (data_in_rdy) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_DATA_IN_RDY_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          if(my_status !== UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()))
          end
        end
      end

      if (data_out_vld) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          if(my_status !== UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()))
          end
        end
      end

      if (tag_out) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_TAG_OUT_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          if(my_status !== UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()))
          end
        end
      end

      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout=local_timeout;

  update_sinc_faults(my_data);

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end
  end

endtask : wait_aes_status

task sinc_random_fault_err_inj_seq::update_sinc_faults(uvm_reg_data_t my_data);
  if(m_top_configuration.m_sinc_vif.is_fsm_fault_err_injected) begin
    if(my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB]) begin
      m_top_configuration.m_sinc_vif.set_fault_value(1, 0);
      `uvm_info(get_name(), $sformatf("aes_test_mode :HW_FAULT SET, STATUS_REG ='h%h", my_data), UVM_LOW)
    end
    if (my_data[`SINC_REGS_STATUS_AES_ERR_LSB] )begin
      m_top_configuration.m_sinc_vif.set_fault_value(0, 1);
      `uvm_info(get_name(), $sformatf("aes_test_mode :AES_ERR SET, STATUS_REG ='h%h", my_data), UVM_LOW)
    end
  end
endtask : update_sinc_faults

task sinc_random_fault_err_inj_seq::write_reg_value(input uvm_reg item, uvm_reg_data_t value, bit is_ro = 0);
  bit             local_timeout;
  process         proc[$];
  // Drive the register write directly on the AXI bus rather than via uvm_reg::write,
  // so a kill on timeout cannot strand the per-register atomic semaphore (UVM/REG/ZOMBIE).
  pal_addr_t      reg_addr;
  bit [7:0]       write_data[];
  bit             wstrb[];
  pal_resp_type_t resp;

  reg_addr      = item.get_address();
  write_data    = new[4];
  write_data[0] = value[ 7: 0];
  write_data[1] = value[15: 8];
  write_data[2] = value[23:16];
  write_data[3] = value[31:24];
  wstrb         = new[4];
  wstrb[0]      = 1'b1;
  wstrb[1]      = 1'b1;
  wstrb[2]      = 1'b1;
  wstrb[3]      = 1'b1;

  fork : check_for_busy_fork
    begin
      proc.push_back(process::self());
      `uvm_info(get_name(), $sformatf(" calling AXI write to reg %s @ 'h%0h data 'h%0h", item.get_name(), reg_addr, value), UVM_HIGH)
      m_axi_mst_seq.sinc_axi_write_access_with(
        .addr        (reg_addr   ),
        .write_data  (write_data ),
        .wstrb       (wstrb      ),
        .burst_length(1          ),
        .id          (0          ),
        .burst_size  (PAL_BYTES_4),
        .response    (resp       ));
      `uvm_info(get_name(), $sformatf(" completed AXI write method\n"), UVM_HIGH)
      // Keep RAL mirror in sync; scoreboard reads get_mirrored_value() of these regs.
      void'(item.predict(value));
      local_timeout      = 0;
    end
    begin
      proc.push_back(process::self());
      `uvm_info(get_name(), $sformatf(" timeout cnt stated reg write method\n"), UVM_HIGH)
      wait_n_clks(500);
      local_timeout = 1;
      `uvm_info(get_name(), $sformatf(" timeout reg write method\n"), UVM_HIGH)
    end
  join_any

  // Kill any outstanding processes - safe now that we are not inside uvm_reg::write().
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end
  end

  if(local_timeout) begin
    `uvm_info(get_name(), $sformatf("write_reg_value method timeout issuing warm reset\n"), UVM_HIGH)
    warm_reset();
    ->m_axi_mst_seq.m_sp_con_seq.seq_done_e;
    wait_n_clks(10);

    fork: start_axi_seq
      begin
        m_axi_mst_seq.start(null); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.4.2 */
      end
    join

    // set sideband
    m_sys_cfg.rand_sideband_cfg();
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_set_sideband(m_sys_cfg.m_sinc_mpu_disable, m_sys_cfg.m_sinc_chkpt_spramnx);
  end


endtask : write_reg_value


//------------------------------------------------------------------------//
// Set up FW Operation                                                    //
//------------------------------------------------------------------------//
task sinc_random_fault_err_inj_seq::set_up_fw_operation(input sinc_fw_cmd_e fw_cmd, bit is_valid_req);
  string debug_str = "set_up_fw_operation";

  `uvm_info(get_name(), $sformatf("fw_cmd is %0s", fw_cmd.name()), UVM_LOW)

  if (is_valid_req) begin

    case(fw_cmd)
      SINC_ENCR_BLOCK: begin
        //todo see if we can get around needing to do this every time
        //need to ensure that encrypt doesn't go beond memory
        uvm_reg_data_t reg_num_of_blocks;
        uvm_reg_data_t reg_block_encr_num;

        if(!std::randomize(reg_num_of_blocks) with {reg_num_of_blocks inside {[1:16]};}) begin
          `uvm_error("RAND", "std::randomize failed to randomize reg_num_of_blocks")
        end
        if(!std::randomize(reg_block_encr_num) with {reg_block_encr_num inside {[0:SINC_CACHE_BLOCK_TOTAL_NUM - 1 - reg_num_of_blocks]};}) begin
          `uvm_error("RAND", "std::randomize failed to randomize reg_block_encr_num")
        end

        write_reg_value(m_regmodel.num_of_blocks, reg_num_of_blocks);
        write_reg_value(m_regmodel.block_encr_num, reg_block_encr_num);

        //these need to be set prior to encrypt block
        //todo see if there is a better way of ensuring this
        if(m_sys_cfg.m_block_encr_addr_is_set == 0) begin
          write_reg_value(m_regmodel.block_encr_addr, sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR);
          m_sys_cfg.m_block_encr_addr_is_set=1;
        end
        if(m_sys_cfg.m_ext_block_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_block_base_addr, m_sys_cfg.m_ext_block_base_addr);
          m_sys_cfg.m_ext_block_base_is_set=1;
        end
        if(m_sys_cfg.m_ext_auth_tag_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_auth_tag_base_addr, m_sys_cfg.m_ext_auth_tag_base_addr);
          m_sys_cfg.m_ext_auth_tag_base_is_set=1;
        end

        `uvm_info(get_name(), $sformatf("wrote num_of_blocks to 0x%0x", reg_num_of_blocks), UVM_LOW)
      end
      SINC_SET_INIT_STATE: begin
        //load key into memory
        load_key_to_axi_mem(m_sys_cfg.m_aes_cfg.m_key_axi_addr, m_sys_cfg.m_aes_cfg.m_key_data);
        // these need to be set prior to set init
        // Always set IV registers
        //if(m_sys_cfg.m_nonce0_is_set == 0) begin
        write_reg_value(m_regmodel.aes_iv_nonce_0, m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]);
        m_sys_cfg.m_nonce0_is_set=1;
        //end
        //if(m_sys_cfg.m_nonce1_is_set == 0) begin
        write_reg_value(m_regmodel.aes_iv_nonce_1, m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]);
        m_sys_cfg.m_nonce1_is_set=1;
        //end
        //if(m_sys_cfg.m_nonce2_is_set == 0) begin
        write_reg_value(m_regmodel.aes_iv_nonce_2, m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]);
        m_sys_cfg.m_nonce2_is_set=1;
        //end
        //if(m_sys_cfg.m_key_slot_is_set == 0) begin
        write_reg_value(m_regmodel.block_encr_key, m_sys_cfg.m_aes_cfg.m_key_slot);
        m_sys_cfg.m_key_slot_is_set=1;
        //end
      end
      SINC_SET_CACHE_ACTIVE_STATE: begin
        //these need to be set prior to set cache active
        //todo see if there is a better way of ensuring this
        if(m_sys_cfg.m_ext_block_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_block_base_addr, m_sys_cfg.m_ext_block_base_addr);
          m_sys_cfg.m_ext_block_base_is_set=1;
        end
        if(m_sys_cfg.m_ext_auth_tag_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_auth_tag_base_addr, m_sys_cfg.m_ext_auth_tag_base_addr);
          m_sys_cfg.m_ext_auth_tag_base_is_set=1;
        end
      end
      default : begin
        // empty
      end
    endcase
  end else begin
    case(fw_cmd)
      SINC_ENCR_BLOCK: begin
        uvm_reg_data_t reg_num_of_blocks;
        uvm_reg_data_t reg_block_encr_num;
        uvm_reg_data_t reg_block_encr_addr = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;

        if(!std::randomize(reg_num_of_blocks) with {reg_num_of_blocks inside {[1:16]};}) begin
          `uvm_error("RAND", "std::randomize failed to randomize reg_num_of_blocks")
        end
        if(!std::randomize(reg_block_encr_num) with {reg_block_encr_num inside {[0:SINC_CACHE_BLOCK_TOTAL_NUM - 1 - reg_num_of_blocks]};}) begin
          `uvm_error("RAND", "std::randomize failed to randomize reg_block_encr_num")
        end

        //corrupt block encr num to be greater than max block
        if(m_sys_cfg.m_err_inj_encr_block_reg_block_encr_num_invalid == 1) begin
          if(!std::randomize(reg_block_encr_num) with {reg_block_encr_num inside {[SINC_CACHE_BLOCK_TOTAL_NUM:32'h1000000]};}) begin
            `uvm_error("RAND", "std::randomize failed to randomize reg_block_encr_num")
          end

          m_sys_cfg.m_err_inj_encr_block_reg_block_encr_num_invalid = 0;
        end

        //corrupt num_of_blocks to be 0
        if(m_sys_cfg.m_err_inj_encr_block_reg_num_of_blocks_invalid == 1) begin
          reg_num_of_blocks                                        = 0;
          m_sys_cfg.m_err_inj_encr_block_reg_num_of_blocks_invalid = 0;
        end

        //corrupt block_encr_addr to not be block aligned
        if(m_sys_cfg.m_err_inj_encr_block_reg_block_encr_addr_invalid == 1) begin
          bit [`SINC_CACHE_OFFSET_RANGE_BYTE_SEL] tmp_block_encr_addr;
          if(!std::randomize(tmp_block_encr_addr) with { tmp_block_encr_addr inside {[1:SINC_CACHE_BLOCK_OFFSET]};}) begin
            `uvm_error("RAND", "std::randomize failed to randomize tmp_block_encr_addr")
          end
          reg_block_encr_addr[`SINC_CACHE_OFFSET_RANGE_BYTE_SEL] = tmp_block_encr_addr;

          write_reg_value(m_regmodel.block_encr_addr, reg_block_encr_addr);
          m_sys_cfg.m_block_encr_addr_is_set                         = 0;
          m_sys_cfg.m_err_inj_encr_block_reg_block_encr_addr_invalid = 0;
        end else begin
          if(m_sys_cfg.m_block_encr_addr_is_set == 0) begin
            write_reg_value(m_regmodel.block_encr_addr, reg_block_encr_addr);
            m_sys_cfg.m_block_encr_addr_is_set = 1;
          end
        end

        write_reg_value(m_regmodel.num_of_blocks, reg_num_of_blocks);
        write_reg_value(m_regmodel.block_encr_num, reg_block_encr_num);

        //these need to be set prior to encrypt block
        if(m_sys_cfg.m_ext_block_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_block_base_addr, m_sys_cfg.m_ext_block_base_addr);
          m_sys_cfg.m_ext_block_base_is_set=1;
        end
        if(m_sys_cfg.m_ext_auth_tag_base_is_set == 0) begin
          write_reg_value(m_regmodel.ext_auth_tag_base_addr, m_sys_cfg.m_ext_auth_tag_base_addr);
          m_sys_cfg.m_ext_auth_tag_base_is_set=1;
        end
      end
      default: begin
        //empty
      end
    endcase
  end

endtask : set_up_fw_operation
// read register reg_data_t
task sinc_random_fault_err_inj_seq::read_reg_value(input uvm_reg item, ref uvm_reg_data_t reg_rdata);
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_readback_value;
  sinc_axi_reg_access_extension ext_obj;
  process                       rd_proc[$];
  bit                           local_timeout;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  fork : check_for_busy_fork
  begin
    rd_proc.push_back(process::self());
    `uvm_info(get_name(), $sformatf(" calling reg read method\n"), UVM_HIGH)
    item.read(my_status, my_readback_value, .extension(ext_obj));
    `uvm_info(get_name(), $sformatf(" completed reg read method\n"), UVM_HIGH)
    //Do real checks in scoreboard
    if(my_status !== UVM_IS_OK) begin
      `uvm_info(get_name(), $sformatf("item.read (%s @ 'h%h) returned status %s", item.get_name(), item.get_address(), my_status.name()), UVM_DEBUG)
    end
    local_timeout      = 0;
  end
  begin
    rd_proc.push_back(process::self());
    `uvm_info(get_name(), $sformatf(" timeout cnt stated reg read method\n"), UVM_HIGH)
    wait_n_clks(500);
    local_timeout = 1;
    `uvm_info(get_name(), $sformatf(" timeout reg read method\n"), UVM_HIGH)
  end
  join_any
  reg_rdata = my_readback_value;

  // Kill any outstanding processes
  foreach(rd_proc[i]) begin
    if ((rd_proc[i] != null) && (rd_proc[i].status() != process::FINISHED)) begin
      rd_proc[i].kill();
    end
  end
  if(local_timeout) begin
    `uvm_info(get_name(), $sformatf("write_reg_value method timeout issuing warm reset\n"), UVM_HIGH)
    warm_reset();
    ->m_axi_mst_seq.m_sp_con_seq.seq_done_e;
    wait_n_clks(10);

    fork: start_axi_seq
      begin
        m_axi_mst_seq.start(null); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.6 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.4.2 */
      end
    join

    // set sideband
    m_sys_cfg.rand_sideband_cfg();
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_set_sideband(m_sys_cfg.m_sinc_mpu_disable, m_sys_cfg.m_sinc_chkpt_spramnx);
  end

endtask : read_reg_value


`endif // SINC_RANDOM_FAULT_ERR_INJ_SEQ
