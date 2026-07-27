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
// File        : sinc_v_if.svh
// Description : 

`ifndef SINC_V_IF
`define SINC_V_IF

interface sinc_v_if
  import uvm_pkg::*;
  import sinc_env_pkg::*;
  import sinc_pkg::*;
  (
    input  logic clk,
    input  logic resetn,
    output logic set_rng_axi_resp_err_o
    //input  logic sinc_axi_mgr_rvalid,
    //input  logic
  );

  logic       sinc_done;
  logic       sinc_err;
  bit         sinc_err_chk_disabled;
  bit         sinc_err_triggered;
  bit         sinc_err_erase_during_w_cache_block;
  logic       disable_encr_auth_check   = 0;
  logic       sinc_start_axi_trn;
  logic       sinc_start_erase;
  logic       sinc_start_cpu_trn;
  logic       sinc_start_w_cache;
  logic       sinc_start_cmu_busy;
  logic       sinc_flopped_cmu_busy;
  logic       sinc_fetch_block_in_progress;

  logic       sinc_cmu_active_cmd;
  logic [7:0] sinc_cmu_state;               // hdl_top.sinc.u_sinc_cmu.u_cmu_ctrl.cmu_sinc_state
  logic [6:0] sinc_cmu_ctrl_state;
  logic [6:0] snap_shot_sinc_cmu_ctrl_state_when_erase_start;
  logic [5:0] snap_shot_sinc_ciu_cache_sm_r_when_erase_start;

  bit         aes_test_en;
  logic       hw_fault_set= 0;
  logic       aes_fault_set= 0;
  // flags
  bit         is_fsm_fault_err_injected = 0;

  logic       sinc_chkpt_spramnx;

   //Fixme: need to add in rtl pkg istead of here
  localparam STATE_WIDTH = 4;

  //Fixme: fsm not part of rtl pkg , declared inside code
  typedef enum bit [STATE_WIDTH-1:0]
  {
    S_IDLE    = 4'h0,
    S_LOAD0   = 4'h1,
    S_LOAD1   = 4'h2,
    S_ADJUST  = 4'h3,
    S_ACTIVE  = 4'h4,
    S_LASTKEY = 4'h5,
    S_RELOAD0 = 4'h6,
    S_RELOAD1 = 4'h7,
    S_WRITE   = 4'h8,
    S_WAIT    = 4'h9
  } aes_keyexp_fsm_e;

  // monitor block
  clocking mon_cb @(posedge clk);
    input resetn;
    input sinc_done;
    input sinc_err;
  endclocking : mon_cb

  always @(posedge mon_cb.sinc_err) begin
    sinc_err_triggered <= 1;
  end

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      sinc_err_erase_during_w_cache_block <= 0;
    end else begin
      if ((hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r === CIU_CACHE_MISS) &&
          `SINC_TB_TOP.sinc.sinc_erase_start_i) begin
        sinc_err_erase_during_w_cache_block <= 1;
      end
      if (hdl_top.sinc.u_sinc_cmu.u_cmu_ctrl.state === sinc_pkg::SINC_RESET) begin
         sinc_err_erase_during_w_cache_block <= 0;
      end
      if (hdl_top.sinc.sinc_erase_start_i) begin
         snap_shot_sinc_cmu_ctrl_state_when_erase_start <= `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state;
      end
      if (hdl_top.sinc.sinc_erase_start_i) begin
         snap_shot_sinc_ciu_cache_sm_r_when_erase_start <= `SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r; //hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r[5:0]
      end
      if (`SINC_TB_TOP.sinc.u_sinc_cmu.cmu_busy) begin
          sinc_flopped_cmu_busy <= 1;
      end else begin
          sinc_flopped_cmu_busy <= 0;
      end

      if (hdl_top.sinc.u_sinc_cmu.u_cmu_ctrl.state === FETCH_BLOCK) begin
         sinc_fetch_block_in_progress <= 1;
      end else begin
         sinc_fetch_block_in_progress <= 0;
      end
    end
  end

  assign set_rng_axi_resp_err_o = 0;
  assign sinc_sub_start_axi_trn = (`SINC_TB_TOP.sinc.sinc_axi_sub_arvalid & `SINC_TB_TOP.sinc.sinc_axi_sub_arready) | (`SINC_TB_TOP.sinc.sinc_axi_sub_awvalid & `SINC_TB_TOP.sinc.sinc_axi_sub_awready);
  assign sinc_start_erase       = `SINC_TB_TOP.sinc.sinc_erase_busy_o; // hdl_top.sinc.sinc_erase_busy_o
  // assign sinc_start_cpu_trn     = `SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.mem_cpu_busy; // change to en and cpu rd/wr
  assign sinc_start_cpu_trn     = `SINC_TB_TOP.sinc.cpu_sinc_en_i;
  assign sinc_start_cmu_busy    = `SINC_TB_TOP.sinc.u_sinc_cmu.cmu_busy;
  assign sinc_start_w_cache     = `SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.mem_cpu_busy;

  assign sinc_cmu_active_cmd = `SINC_TB_TOP.sinc.u_sinc_cmu.cmu_ctrl_active_cmd;
  assign sinc_cmu_state      = `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.cmu_sinc_state;
  assign sinc_cmu_ctrl_state = `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state; // hdl_top.sinc.u_sinc_cmu.u_cmu_ctrl.state[6:0]
  assign aes_test_en         = `SINC_TB_TOP.sinc.u_sinc_cmu.u_reg_ctrl.u_sinc_regs.csr_internal_field_cmd_aes_test_en;
  assign sinc_chkpt_spramnx  = `SINC_TB_TOP.sinc.sinc_chkpt_spramnx_i;

  // Task to drive disable_encr_auth_check
  task static set_disable_encr_auth_check(logic a_value);
    `uvm_info("DEBUG", $sformatf(" set_disable_encr_auth_check [%0d]", a_value), UVM_LOW)
    disable_encr_auth_check = a_value;
  endtask : set_disable_encr_auth_check

  // Task to drive sinc_err_chk_disable_i in ecc error scenario
  task static force_or_release_sinc_err_chk_disabled(bit a_force, logic a_value);
    if (a_force) begin
      sinc_err_chk_disabled = a_value;
      //force   `SINC_TB_TOP.sinc.sinc_err_chk_disable_i = a_value;
    end else begin
      //release `SINC_TB_TOP.sinc.sinc_err_chk_disable_i;
    end
  endtask : force_or_release_sinc_err_chk_disabled
  // ********************************************
  // inject fault into the CIU_CACHE_FSM state machine
  // ********************************************
  // task static inject_fault_error_ciu_cache_fsm_state_illegal(kv_pkg::ciu_cache_fsm_t m_force_on_ciu_cache_fsm_state, logic [6:0] m_illegal_ciu_cache_fsm_state);
  task static inject_fault_error_ciu_cache_fsm_state_illegal(sinc_pkg::sinc_ciu_fsm_t force_on_ciu_cache_fsm_state, logic [5:0] illegal_ciu_cache_fsm_state);
    sinc_pkg::sinc_ciu_fsm_t force_to_ciu_cache_fsm_state;

    `uvm_info("DEBUG", $sformatf(" waiting for  ciu_ctrl_fsm_state [%0s]", force_on_ciu_cache_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r !== force_on_ciu_cache_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced ciu_cache_fsm_state from [%0s], to ['h%0h].", force_on_ciu_cache_fsm_state, illegal_ciu_cache_fsm_state), UVM_LOW)
    force_ciu_cache_fsm_state(illegal_ciu_cache_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_ciu_cache_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_ciu_cache_fsm_state();
  endtask : inject_fault_error_ciu_cache_fsm_state_illegal

  // Task to force ciu_cache_fsm_state
  task static force_ciu_cache_fsm_state(logic [5:0] illegal_ciu_cache_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r = illegal_ciu_cache_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced ciu_cache_fsm_state to ['h%0h].", illegal_ciu_cache_fsm_state), UVM_LOW)

  endtask : force_ciu_cache_fsm_state

  // Task to release ciu_cache_fsm_state
  task static release_ciu_cache_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r;
    `uvm_info("sinc_v_if", "Released ciu_cache_fsm_state.", UVM_LOW)
  endtask : release_ciu_cache_fsm_state

  // ********************************************
  // inject fault into the CMU_CTRL_FSM state machine
  // ********************************************
  task static inject_fault_error_cmu_ctrl_fsm_state_illegal(sinc_pkg::sinc_cmu_ctrl_fsm_t force_on_cmu_ctrl_fsm_state, logic [6:0] illegal_cmu_ctrl_fsm_state);
    // task static inject_fault_error_cmu_ctrl_fsm_state_illegal(sinc_parameters_pkg::sinc_cmu_ctrl_fsm_t m_force_on_cmu_ctrl_fsm_state, logic [5:0] m_illegal_cmu_ctrl_fsm_state);
    sinc_cmu_ctrl_fsm_t force_to_cmu_ctrl_fsm_state;

    `uvm_info("DEBUG", $sformatf(" waiting for  cmu_ctrl_fsm_state [%0s]", force_on_cmu_ctrl_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== force_on_cmu_ctrl_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced cmu_ctrl_fsm_state from [%0s], to ['h%0h].", force_on_cmu_ctrl_fsm_state, illegal_cmu_ctrl_fsm_state), UVM_LOW)
    force_cmu_ctrl_fsm_state(illegal_cmu_ctrl_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_cmu_ctrl_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_cmu_ctrl_fsm_state();
  endtask : inject_fault_error_cmu_ctrl_fsm_state_illegal

  // Task to force cmu_ctrl_fsm_state
  task static force_cmu_ctrl_fsm_state(logic [6:0] illegal_cmu_ctrl_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state = illegal_cmu_ctrl_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced cmu_ctrl_fsm_state to ['h%0h].", illegal_cmu_ctrl_fsm_state), UVM_LOW)
  endtask : force_cmu_ctrl_fsm_state

  // Task to release cmu_ctrl_fsm_state
  task static release_cmu_ctrl_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state;
    `uvm_info("sinc_v_if", "Released cmu_ctrl_fsm_state.", UVM_LOW)
  endtask : release_cmu_ctrl_fsm_state

  // ********************************************
  // inject fault into the CMU_CTRL_FSM state machine during CIU state
  // ********************************************
  task static inject_fault_error_on_cmu_ctrl_fsm_state_illegal_on_ciu_state(sinc_pkg::sinc_ciu_fsm_t force_on_ciu_cache_fsm_state, logic [6:0] illegal_cmu_ctrl_fsm_state);
    sinc_cmu_ctrl_fsm_t force_to_cmu_ctrl_fsm_state;

    /*
    `uvm_info("DEBUG", $sformatf(" waiting for ciu_ctrl_fsm_state [%0s]", force_on_ciu_cache_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r !== force_on_ciu_cache_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);
    */

    wait (`SINC_TB_TOP.sinc.cpu_sinc_en_i == 1);

    `uvm_info("DEBUG", $sformatf(" Forced cmu_ctrl_fsm_state to ['h%0h].", illegal_cmu_ctrl_fsm_state), UVM_LOW)
    force_cmu_ctrl_fsm_state(illegal_cmu_ctrl_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_cmu_ctrl_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_cmu_ctrl_fsm_state();
  endtask : inject_fault_error_on_cmu_ctrl_fsm_state_illegal_on_ciu_state

  // ********************************************
  // inject fault into the CMU_CTRL_FSM state machine during CIU state
  // ********************************************
  task static inject_fault_error_on_cmu_ctrl_fsm_state_illegal(logic [6:0] illegal_cmu_ctrl_fsm_state);
    sinc_cmu_ctrl_fsm_t force_to_cmu_ctrl_fsm_state;

    `uvm_info("DEBUG", $sformatf(" Forced cmu_ctrl_fsm_state to ['h%0h].", illegal_cmu_ctrl_fsm_state), UVM_LOW)
    force_cmu_ctrl_fsm_state(illegal_cmu_ctrl_fsm_state);

    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_cmu_ctrl_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_cmu_ctrl_fsm_state();

  endtask : inject_fault_error_on_cmu_ctrl_fsm_state_illegal

  // ********************************************
  // inject fault into the SINC CACHE state machine
  // ********************************************
  task static inject_fault_error_cmu_sinc_cache_fsm_state_illegal(sinc_pkg::sinc_state_t force_on_cmu_sinc_cache_fsm_state, logic [7:0] illegal_cmu_sinc_cache_fsm_state);
    sinc_state_t force_to_cmu_sinc_cache_fsm_state;

    `uvm_info("DEBUG", $sformatf(" waiting for  cmu_sinc_cache_fsm_state [%0s]", force_on_cmu_sinc_cache_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.cmu_sinc_state !== force_on_cmu_sinc_cache_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced cmu_sinc_cache_fsm_state from [%0s], to ['h%0h].", force_on_cmu_sinc_cache_fsm_state, illegal_cmu_sinc_cache_fsm_state), UVM_LOW)
    force_cmu_sinc_cache_fsm_state(illegal_cmu_sinc_cache_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_cmu_sinc_cache_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_cmu_sinc_cache_fsm_state();
  endtask : inject_fault_error_cmu_sinc_cache_fsm_state_illegal

  // Task to force cmu_sinc_cache_fsm_state
  task static force_cmu_sinc_cache_fsm_state(logic [7:0] illegal_cmu_sinc_cache_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.cmu_sinc_state = illegal_cmu_sinc_cache_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced cmu_sinc_cache_fsm_state to ['h%0h].", illegal_cmu_sinc_cache_fsm_state), UVM_LOW)
  endtask : force_cmu_sinc_cache_fsm_state

  // Task to release cmu_sinc_cache_fsm_state
  task static release_cmu_sinc_cache_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.cmu_sinc_state;
    `uvm_info("sinc_v_if", "Released cmu_sinc_cache_fsm_state.", UVM_LOW)
  endtask : release_cmu_sinc_cache_fsm_state

  // ********************************************
  // inject fault into the SINC SUB STATE state machine
  // ********************************************
  task static inject_fault_error_sinc_sub_fsm_state_illegal(sinc_pkg::sinc_cmu_ctrl_fsm_t force_on_cmu_ctrl_fsm_state, logic [5:0] illegal_sinc_sub_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for u_cmu_ctrl state[%0s]",  force_on_cmu_ctrl_fsm_state), UVM_LOW)

    //Substate is specific to one of the cmu ctrl fsm state and error will
    //captured if it is in that state only
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== force_on_cmu_ctrl_fsm_state) begin
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== sinc_pkg::SET_INIT) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced sinc_sub_fsm_state  to ['h%0h].", illegal_sinc_sub_fsm_state), UVM_LOW)
    force_sinc_sub_fsm_state(illegal_sinc_sub_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_sinc_sub_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_sinc_sub_fsm_state();
  endtask : inject_fault_error_sinc_sub_fsm_state_illegal

  // Task to force sinc_sub_fsm_state
  task static force_sinc_sub_fsm_state(logic [6:0] illegal_sinc_sub_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_crypto_wrap_ctrl.sub_state = illegal_sinc_sub_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced sinc_sub_fsm_state to ['h%0h].", illegal_sinc_sub_fsm_state), UVM_LOW)
  endtask : force_sinc_sub_fsm_state

  // Task to release sinc_sub_fsm_state
  task static release_sinc_sub_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_crypto_wrap_ctrl.sub_state;
    `uvm_info("sinc_v_if", "Released sinc_sub_fsm_state.", UVM_LOW)
  endtask : release_sinc_sub_fsm_state

  // ********************************************
  // inject fault into the CRYPTO AES CTRL STATE state machine
  // ********************************************
  task static inject_fault_error_aes_ctrl_fsm_state_illegal(sinc_pkg::sinc_aes_ctrl_fsm_t force_on_aes_ctrl_fsm_state, logic [5:0] illegal_aes_ctrl_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  aes_ctrl_fsm_state [%0s]", force_on_aes_ctrl_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_crypto_wrap_ctrl.aes_ctrl_state !== force_on_aes_ctrl_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced aes_ctrl_fsm_state from [%0s], to ['h%0h].", force_on_aes_ctrl_fsm_state, illegal_aes_ctrl_fsm_state), UVM_LOW)
    force_aes_ctrl_fsm_state(illegal_aes_ctrl_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_aes_ctrl_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_aes_ctrl_fsm_state();
  endtask : inject_fault_error_aes_ctrl_fsm_state_illegal

  // Task to force aes_ctrl_fsm_state
  task static force_aes_ctrl_fsm_state(logic [6:0] illegal_aes_ctrl_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_crypto_wrap_ctrl.aes_ctrl_state = illegal_aes_ctrl_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced aes_ctrl_fsm_state to ['h%0h].", illegal_aes_ctrl_fsm_state), UVM_LOW)
  endtask : force_aes_ctrl_fsm_state

  // Task to release aes_ctrl_fsm_state
  task static release_aes_ctrl_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_crypto_wrap_ctrl.aes_ctrl_state;
    `uvm_info("sinc_v_if", "Released aes_ctrl_fsm_state.", UVM_LOW)
  endtask : release_aes_ctrl_fsm_state

  // ********************************************
  // inject fault into the CMU DMA_R STATE state machine
  // ********************************************
  task static inject_fault_error_dma_r_fsm_state_illegal(sinc_pkg::sinc_dma_r_fsm_t force_on_dma_r_fsm_state, logic [5:0] illegal_dma_r_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  dma_r_fsm_state [%0s]", force_on_dma_r_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_r_state !== force_on_dma_r_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced dma_r_fsm_state from [%0s], to ['h%0h].", force_on_dma_r_fsm_state, illegal_dma_r_fsm_state), UVM_LOW)
    force_dma_r_fsm_state(illegal_dma_r_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_dma_r_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_dma_r_fsm_state();
  endtask : inject_fault_error_dma_r_fsm_state_illegal

  // Task to force dma_r_fsm_state
  task static force_dma_r_fsm_state(logic [6:0] illegal_dma_r_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_r_state = illegal_dma_r_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced dma_r_fsm_state to ['h%0h].", illegal_dma_r_fsm_state), UVM_LOW)
  endtask : force_dma_r_fsm_state

  // Task to release dma_r_fsm_state
  task static release_dma_r_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_r_state;
    `uvm_info("sinc_v_if", "Released dma_r_fsm_state.", UVM_LOW)
  endtask : release_dma_r_fsm_state

  // ********************************************
  // inject fault into the CMU DMA_W state machine
  // ********************************************
  task static inject_fault_error_dma_w_fsm_state_illegal(sinc_pkg::sinc_dma_w_fsm_t force_on_dma_w_fsm_state, logic [5:0] illegal_dma_w_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  dma_w_fsm_state [%0s]", force_on_dma_w_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_w_state !== force_on_dma_w_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced dma_w_fsm_state from [%0s], to ['h%0h].", force_on_dma_w_fsm_state, illegal_dma_w_fsm_state), UVM_LOW)
    force_dma_w_fsm_state(illegal_dma_w_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_dma_w_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_dma_w_fsm_state();
  endtask : inject_fault_error_dma_w_fsm_state_illegal

  // Task to force dma_w_fsm_state
  task static force_dma_w_fsm_state(logic [6:0] illegal_dma_w_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_w_state = illegal_dma_w_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced dma_w_fsm_state to ['h%0h].", illegal_dma_w_fsm_state), UVM_LOW)
  endtask : force_dma_w_fsm_state

  // Task to release dma_w_fsm_state
  task static release_dma_w_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_dma.dma_w_state;
    `uvm_info("sinc_v_if", "Released dma_w_fsm_state.", UVM_LOW)
  endtask : release_dma_w_fsm_state

  // ********************************************
  // inject fault into the AES KEYEXP STATE state machine
  // ********************************************
  task static inject_fault_error_aes_keyexp_fsm_state_illegal(aes_keyexp_fsm_e force_on_aes_keyexp_fsm_state, logic [3:0] illegal_aes_keyexp_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  aes_keyexp_fsm_state [%0s]", force_on_aes_keyexp_fsm_state), UVM_LOW)
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.aes_core0.aes_keyexp0.current_state !== force_on_aes_keyexp_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced aes_keyexp_fsm_state from [%0s], to ['h%0h].", force_on_aes_keyexp_fsm_state, illegal_aes_keyexp_fsm_state), UVM_LOW)
    force_aes_keyexp_fsm_state(illegal_aes_keyexp_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_aes_keyexp_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_aes_keyexp_fsm_state();
  endtask : inject_fault_error_aes_keyexp_fsm_state_illegal

  // Task to force aes_keyexp_fsm_state
  task static force_aes_keyexp_fsm_state(logic [6:0] illegal_aes_keyexp_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.aes_core0.aes_keyexp0.current_state = illegal_aes_keyexp_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced aes_keyexp_fsm_state to ['h%0h].", illegal_aes_keyexp_fsm_state), UVM_LOW)
  endtask : force_aes_keyexp_fsm_state

  // Task to release aes_keyexp_fsm_state
  task static release_aes_keyexp_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.aes_core0.aes_keyexp0.current_state;
    `uvm_info("sinc_v_if", "Released aes_keyexp_fsm_state.", UVM_LOW)
  endtask : release_aes_keyexp_fsm_state

  // ********************************************
  // inject fault into the GPAES mode main STATE state machine
  // ********************************************
  task static inject_fault_error_gpaes_mode_main_fsm_state_illegal(sinc_pkg::sinc_cmu_ctrl_fsm_t force_on_cmu_ctrl_fsm_state, logic [6:0] illegal_gpaes_mode_main_fsm_state);

    `uvm_info("DEBUG", $sformatf("GPAES FSM waiting for u_cmu_ctrl state[%0s]",  force_on_cmu_ctrl_fsm_state), UVM_LOW)
    //FOR GPAES FSM , fsm fault error will be detected only during AES mode
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== sinc_pkg::ENCR_BLOCK ) begin
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== force_on_cmu_ctrl_fsm_state) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced gpaes_mode_main_fsm_state  to ['h%0h].", illegal_gpaes_mode_main_fsm_state), UVM_LOW)
    force_gpaes_mode_main_fsm_state(illegal_gpaes_mode_main_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_gpaes_mode_main_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_gpaes_mode_main_fsm_state();
  endtask : inject_fault_error_gpaes_mode_main_fsm_state_illegal

  // Task to force gpaes_mode_main_fsm_state
  task static force_gpaes_mode_main_fsm_state(logic [6:0] illegal_gpaes_mode_main_fsm_state);
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.mode_state = illegal_gpaes_mode_main_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced gpaes_mode_main_fsm_state to ['h%0h].", illegal_gpaes_mode_main_fsm_state), UVM_LOW)
  endtask : force_gpaes_mode_main_fsm_state

  // Task to release gpaes_mode_main_fsm_state
  task static release_gpaes_mode_main_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.mode_state;
    `uvm_info("sinc_v_if", "Released gpaes_mode_main_fsm_state.", UVM_LOW)
  endtask : release_gpaes_mode_main_fsm_state

  // ********************************************
  // inject fault into the GPAES GHASH MUL STATE state machine
  // ********************************************
  task static inject_fault_error_ghash_mul_fsm_state_illegal(sinc_pkg::sinc_cmu_ctrl_fsm_t force_on_cmu_ctrl_fsm_state, logic [6:0] illegal_ghash_mul_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  force_on_ghash_mul_fsm_state [%0s]", force_on_cmu_ctrl_fsm_state), UVM_LOW)
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_ghash.u_gfm_128_128.state !== m_force_on_ghash_mul_fsm_state) begin
    //FSM fault is capture in GPAES FSM if SINC is executing AES CMD
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== sinc_pkg:: ENCR_BLOCK) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced ghash_mul_fsm_state from  to ['h%0h].", illegal_ghash_mul_fsm_state), UVM_LOW)
    force_ghash_mul_fsm_state(illegal_ghash_mul_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_ghash_mul_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_ghash_mul_fsm_state();
  endtask : inject_fault_error_ghash_mul_fsm_state_illegal

  // Task to force ghash_mul_fsm_state
  task static force_ghash_mul_fsm_state(logic [6:0] illegal_ghash_mul_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_ghash.u_gfm_128_128.state = illegal_ghash_mul_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced ghash_mul_fsm_state to ['h%0h].", illegal_ghash_mul_fsm_state), UVM_LOW)
  endtask : force_ghash_mul_fsm_state

  // Task to release ghash_mul_fsm_state
  task static release_ghash_mul_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_ghash.u_gfm_128_128.state;
    `uvm_info("sinc_v_if", "Released ghash_mul_fsm_state.", UVM_LOW)
  endtask : release_ghash_mul_fsm_state

  // ********************************************
  // inject fault into the GPAES GHASH MUL STATE state machine
  // ********************************************
  task static inject_fault_error_gpaes_mode_ghash_fsm_state_illegal(gp_aes_pkg::mode_ghash_fsm_t force_on_gpaes_mode_ghash_fsm_state, logic [6:0] illegal_gpaes_mode_ghash_fsm_state);

    `uvm_info("DEBUG", $sformatf(" waiting for  gpaes_mode_ghash_fsm_state [%0s]", force_on_gpaes_mode_ghash_fsm_state), UVM_LOW)
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_state !== m_force_on_gpaes_mode_ghash_fsm_state) begin
    //FOR GPAES FSM , fsm fault error will be detected only during AES mode
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== sinc_pkg::AES_TEST ) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced gpaes_mode_ghash_fsm_state from [%0s], to ['h%0h].", force_on_gpaes_mode_ghash_fsm_state, illegal_gpaes_mode_ghash_fsm_state), UVM_LOW)
    force_gpaes_mode_ghash_fsm_state(illegal_gpaes_mode_ghash_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_gpaes_mode_ghash_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_gpaes_mode_ghash_fsm_state();
  endtask : inject_fault_error_gpaes_mode_ghash_fsm_state_illegal

  // Task to force gpaes_mode_ghash_fsm_state
  task static force_gpaes_mode_ghash_fsm_state(logic [6:0] illegal_gpaes_mode_ghash_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_state = illegal_gpaes_mode_ghash_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced gpaes_mode_ghash_fsm_state to ['h%0h].", illegal_gpaes_mode_ghash_fsm_state), UVM_LOW)
  endtask : force_gpaes_mode_ghash_fsm_state

  // Task to release gpaes_mode_ghash_fsm_state
  task static release_gpaes_mode_ghash_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_state;
    `uvm_info("sinc_v_if", "Released gpaes_mode_ghash_fsm_state.", UVM_LOW)
  endtask : release_gpaes_mode_ghash_fsm_state

  // ********************************************
  // inject fault into the GPAES SUB STATE state machine
  // ********************************************
  task static inject_fault_error_gpaes_sub_state_fsm_state_illegal(gp_aes_pkg::mode_ghash_fsm_t force_on_gpaes_mode_ghash_fsm_state, logic [6:0] illegal_gpaes_sub_state_fsm_state);
    `uvm_info("DEBUG", $sformatf("GPAES SUBSTATE FSM waiting for  gpaes_mode_ghash_fsm_state [%0s]", force_on_gpaes_mode_ghash_fsm_state), UVM_LOW)
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_sub_state !== m_force_on_gpaes_sub_state_fsm_state) begin
    //FOR GPAES FSM , fsm fault error will be detected only during AES mode
    //Substate valid is in MODE_GHASH_ENC/MODE_GHASH_DEC state only
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_state !== gp_aes_pkg::MODE_GHASH_ENC ) begin
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_state !== force_on_gpaes_mode_ghash_fsm_state ) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced gpaes_sub_state_fsm_state from  to ['h%0h].", illegal_gpaes_sub_state_fsm_state), UVM_LOW)
    force_gpaes_sub_state_fsm_state(illegal_gpaes_sub_state_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_gpaes_sub_state_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_gpaes_sub_state_fsm_state();
  endtask : inject_fault_error_gpaes_sub_state_fsm_state_illegal

  // Task to force gpaes_sub_state_fsm_state
  task static force_gpaes_sub_state_fsm_state(logic [6:0] illegal_gpaes_sub_state_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_sub_state = illegal_gpaes_sub_state_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced gpaes_sub_state_fsm_state to ['h%0h].", illegal_gpaes_sub_state_fsm_state), UVM_LOW)
  endtask : force_gpaes_sub_state_fsm_state

  // Task to release gpaes_sub_state_fsm_state
  task static release_gpaes_sub_state_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.ghash_sub_state;
    `uvm_info("sinc_v_if", "Released gpaes_sub_state_fsm_state.", UVM_LOW)
  endtask : release_gpaes_sub_state_fsm_state

  // ********************************************
  // inject fault into the GPAES_MODE_SEC state machine
  // ********************************************
  task static inject_fault_error_gpaes_mode_sec_fsm_state_illegal(gp_aes_pkg::mode_sec_fsm_t force_on_gpaes_mode_sec_fsm_state, logic [6:0] illegal_gpaes_mode_sec_fsm_state);
    `uvm_info("DEBUG", $sformatf(" waiting for  gpaes_mode_sec_fsm_state [%0s]", force_on_gpaes_mode_sec_fsm_state), UVM_LOW)
    //while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.cur_state !== m_force_on_gpaes_mode_sec_fsm_state) begin
    //FSM fault is capture in GPAES FSM if SINC is executing AES CMD
    while (`SINC_TB_TOP.sinc.u_sinc_cmu.u_cmu_ctrl.state !== sinc_pkg::AES_TEST ) begin
      @(posedge clk);
    end

    @(posedge clk);

    `uvm_info("DEBUG", $sformatf(" Forced gpaes_mode_sec_fsm_state from [%0s], to ['h%0h].", force_on_gpaes_mode_sec_fsm_state, illegal_gpaes_mode_sec_fsm_state), UVM_LOW)
    force_gpaes_mode_sec_fsm_state(illegal_gpaes_mode_sec_fsm_state);
    @(posedge clk);

    is_fsm_fault_err_injected = 1;
    `uvm_info("DEBUG", $sformatf(" Post inject_fault_error_gpaes_mode_sec_fsm_state_illegal"), UVM_NONE)

    @(posedge clk);

    release_gpaes_mode_sec_fsm_state();
  endtask : inject_fault_error_gpaes_mode_sec_fsm_state_illegal

  // Task to force gpaes_mode_sec_fsm_state
  task static force_gpaes_mode_sec_fsm_state(logic [6:0] illegal_gpaes_mode_sec_fsm_state);
    // fixme: below force won't pass PB build unless: add "- 'ENUMASSIGN[\s\S]*sinc_v_if'" in common/test_config/config/parse_build_log_config.yml
    force `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.cur_state = illegal_gpaes_mode_sec_fsm_state;
    `uvm_info("sinc_v_if", $sformatf("Forced gpaes_mode_sec_fsm_state to ['h%0h].", illegal_gpaes_mode_sec_fsm_state), UVM_LOW)
  endtask : force_gpaes_mode_sec_fsm_state

  // Task to release gpaes_mode_sec_fsm_state
  task static release_gpaes_mode_sec_fsm_state();
    release `SINC_TB_TOP.sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.u_gp_aes_mode.cur_state;
    `uvm_info("sinc_v_if", "Released gpaes_mode_sec_fsm_state.", UVM_LOW)
  endtask : release_gpaes_mode_sec_fsm_state


  // ********************************************
  // inject VTAG parity Error
  // ********************************************

  // Task to force gpaes_mode_sec_fsm_state
  task static force_vtag_parity_error(logic [`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH-1:0] error_mask);
      force `SINC_TB_TOP.hsp_wrap_vtag.rd_data = {`SINC_TB_TOP.hsp_wrap_vtag.rd_data3, `SINC_TB_TOP.hsp_wrap_vtag.rd_data2, `SINC_TB_TOP.hsp_wrap_vtag.rd_data1, `SINC_TB_TOP.hsp_wrap_vtag.rd_data0} ^ error_mask;
      `uvm_info("sinc_v_if", $sformatf("Forcing VTAG Parity Err Mask = 'h%h.",error_mask), UVM_LOW)
  endtask : force_vtag_parity_error

  // Task to release gpaes_mode_sec_fsm_state
  task static release_vtag_parity_error();
    release `SINC_TB_TOP.hsp_wrap_vtag.rd_data;
    `uvm_info("sinc_v_if", "Released VTAG Parity Err Mask.", UVM_LOW)
  endtask : release_vtag_parity_error





  // ********************************************
  // Other stuff
  // ********************************************


  // virtual interface interaction with AXI peekpoke
  // Task to drive sinc_err_chk_disable_i in ecc error scenario
  task static set_axi_err_resp_on_rng(bit a_value);
    set_rng_axi_resp_err_o <= a_value;
    `uvm_info ("sinc_v_if", $sformatf("Set set_rng_axi_resp_err_o ['h%0h]", set_rng_axi_resp_err_o), UVM_HIGH)
  endtask : set_axi_err_resp_on_rng

  // return sts_unread
  function static bit get_sts_unread();
    return (hdl_top.sinc.u_sinc_cmu.u_reg_ctrl.sts_unread);
  endfunction : get_sts_unread

  task static set_fault_value(bit hw_fault, bit aes_fault);
    hw_fault_set = hw_fault;
    aes_fault_set= aes_fault;
  endtask : set_fault_value

  function static bit get_sinc_err_val();
    return (sinc_err_triggered);
  endfunction : get_sinc_err_val

  task static clear_sinc_err();
    sinc_err_triggered <= 0;
    `uvm_info ("sinc_v_if", $sformatf("cleared sinc_err_triggered ['h%0h]", sinc_err_triggered), UVM_HIGH)
  endtask : clear_sinc_err

  task static wait_ciram_write(ref bit success, input int timeoutcount = 20000);
    bit timeout;
    bit local_success;
    process proc[$];

    fork : wait_for_w_ciram
      begin
        proc.push_back(process::self());
        `uvm_info ("wait_ciram_write", $sformatf("start wait [%0s]", "CIU_CACHE_MISS"), UVM_HIGH)
        wait (hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r === CIU_CACHE_MISS);
        `uvm_info ("wait_ciram_write", $sformatf("start wait [%0s]", "IRAM Write"), UVM_HIGH)
        wait ((hdl_top.sinc.sinc_ciram_we_o === 1) && (hdl_top.sinc.sinc_ciram_en_o === 1));
        `uvm_info ("wait_ciram_write", $sformatf("finish wait [%0s], timeout[0]", "IRAM Write"), UVM_HIGH)
        local_success = 1;
        timeout = 0;
      end
      begin
        proc.push_back(process::self());
        `uvm_info ("wait_ciram_write", $sformatf("start wait [%0s]", "CIU_WAIT"), UVM_HIGH)
        wait (hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r === CIU_WAIT);
        `uvm_info ("wait_ciram_write", $sformatf("finish wait [%0s], timeout[1]", "IRAM Write"), UVM_HIGH)
        timeout = 1;
      end
      begin
        proc.push_back(process::self());
        repeat(timeoutcount) begin
          @(posedge clk);
        end
        timeout = 1;
        `uvm_info ("wait_ciram_write", $sformatf("finish wait [%0s], timeout[1]", "IRAM Write"), UVM_HIGH)
      end
    join_any

    // Kill any outstanding processes
    foreach(proc[i]) begin

      if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
        proc[i].kill();
      end
    end

    if (timeout) begin
      `uvm_info ("wait_ciram_write", $sformatf("Timeout waiting for IEvent %0s", "IRAM Write"), UVM_HIGH)
    end
    success = local_success;
  endtask : wait_ciram_write

  task static wait_till_last_erase_mem(ref bit success, input int timeoutcount = 20000);
    bit timeout;
    bit local_success;
    process proc[$];
    logic [sinc_parameters_pkg::SINC_CACHE_MEM_ADDR_WIDTH - 1:0] mem_address;

    mem_address  =  {sinc_parameters_pkg::SINC_CACHE_MEM_ADDR_WIDTH{1'b1}};; // hdl_top.sinc.sinc_ciram_addr_o[13:0]

    fork : wait_for_last_erase_mem
      begin
        proc.push_back(process::self());
        `uvm_info ("wait_for_last_erase_mem", $sformatf("start wait [ERASE on address: %0h]", mem_address), UVM_HIGH)
        wait (hdl_top.sinc.sinc_ciram_en_o && (hdl_top.sinc.sinc_ciram_addr_o === mem_address));
       `uvm_info ("wait_for_last_erase_mem", $sformatf("start wait [ERASE on address: %0h]", mem_address), UVM_HIGH)

        local_success = 1;
        timeout = 0;
      end
      begin
        proc.push_back(process::self());
        repeat(timeoutcount) begin
          @(posedge clk);
        end
        timeout = 1;
        `uvm_info ("wait_for_last_erase_mem", $sformatf("start wait [ERASE on address: %0h]", mem_address), UVM_HIGH)
      end
    join_any

    // Kill any outstanding processes
    foreach(proc[i]) begin

      if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
        proc[i].kill();
      end
    end

    if (timeout) begin
      `uvm_info ("wait_for_last_erase_mem", $sformatf("Timeout waiting for IEvent %0s", "wait_for_last_erase_mem"), UVM_HIGH)
    end
    success = local_success;
  endtask : wait_till_last_erase_mem

  // Task to enforce low power reset
  task static low_power_reset();
      force hdl_top.sinc.lp_rstn_i = 0;
      repeat(50) begin
          @(posedge clk);
      end
      release hdl_top.sinc.lp_rstn_i;
      `uvm_info("sinc_v_if", $sformatf("Forcing low power reset ['h%h].", hdl_top.sinc.lp_rstn_i), UVM_LOW)
  endtask : low_power_reset

  task static wait_axi_sub_wr(ref bit success, input int timeoutcount = 20000);
    bit timeout;
    bit local_success;
    process proc[$];

    fork : wait_for_axi_sub_wr
      begin
        proc.push_back(process::self());

        wait (hdl_top.sinc.sinc_axi_sub_awvalid && hdl_top.sinc.sinc_axi_sub_awready);


        local_success = 1;
        timeout = 0;
      end
      begin
        proc.push_back(process::self());
        repeat(timeoutcount) begin
          @(posedge clk);
        end
        timeout = 1;
        `uvm_info ("wait_for_axi_sub_wr", $sformatf("end wait [wait_for_axi_sub_wr: success %0h]", local_success), UVM_HIGH)
      end
    join_any

    // Kill any outstanding processes
    foreach(proc[i]) begin

      if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
        proc[i].kill();
      end
    end

    if (timeout) begin
      `uvm_info ("wait_for_axi_sub_wr", $sformatf("Timeout waiting for IEvent %0s", "wait_for_axi_sub_wr"), UVM_HIGH)
    end
    success = local_success;
  endtask : wait_axi_sub_wr

endinterface: sinc_v_if

`endif // SINC_V_IF
