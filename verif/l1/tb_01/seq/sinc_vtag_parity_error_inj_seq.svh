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
// File        : sinc_vtag_parity_error_inj_seq.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_VTAG_PARITY_ERROR_INJ_TEST_SEQ
`define SINC_VTAG_PARITY_ERROR_INJ_TEST_SEQ

//##############################################################################
//<> SEQUENCE: sinc_vtag_parity_error_inj_test_seq
//##############################################################################

/**
 * ECC Error Injection Test Sequence
 */
class sinc_vtag_parity_error_inj_test_seq extends sinc_virtual_base_sequence;
  localparam int ADDR_WIDTH          = 22;
  localparam int TAG_WIDTH           = 7;
  localparam int VTAG_PARITY_BITS[4] = '{39, 29, 19, 9};
  localparam int VTAG_VALID_BITS[4]  = '{38, 28, 18, 8};

  `uvm_object_utils(sinc_vtag_parity_error_inj_test_seq)

  int                     m_num_randomized_tests;  //If >0 run a number of randomized scenarios, otherwise run deterministically
  int                     m_use_fixed_address;     // If True use the fixed address
  ccpui_cpu_mem_addr_t    m_fixed_address;
  int                     m_use_fixed_cache_state; // If True use the fixed address
  sinc_cache_state_type_e m_fixed_cache_state;     // Only used if num_randomized_tests >0

  rand bit                        m_sinc_error_chk_disabled; // Controls if sinc_error_check disable is asserted (should have no affect)
  rand fsm_halt_recover_op_type_e m_recover_type;            // Controls how the recover operation is performed
  rand ccpui_cpu_mem_addr_t       m_address;                 // Controls which address to perform the accesses.
  rand sinc_cache_state_type_e    m_cache_state;             // Controls which cache state to perform test in
  rand bit                        m_cache_hit;               // Controls if one of the warmup entries will match the tested address (regardless of cache state)
  rand int                        m_cache_warmups;           // Controls number of warmup accesses to perform.
  rand bit [TAG_WIDTH-1:0]        m_cache_warmup_tags[];     // List of tags to use for warmup accesses
  rand bit                        m_parity_error_inject_vld; // Controls if parity error will be injected on a vld VTAG entry
  rand int                        m_parity_error_num_blocks; // Controls the number of blocks that have a parity error injected (regardless of validity)
  rand bit [39:0]                 m_parity_error_mask;       // Controls the parity error mask to use

  constraint address_c {
    m_address dist {0:=1, [1:'h3F_FFFE]:/1, 'h3F_FFFF:=1}; //TODO use define for address ranges
  }

  constraint cache_state_c {
    m_cache_state != CACHE_FAIL_STATE;
    m_cache_state dist {CACHE_DISABLE_STATE:=1, CACHE_INIT_STATE:=1, CACHE_ACTIVE_STATE:=2};
  }

  constraint cache_hit_c {
    solve m_cache_warmups before m_cache_hit;
    (m_cache_warmups == 0) -> {(m_cache_hit==1'b0)}; // not possible to cache hit without any warmups
  }

  constraint cache_warmups_c {
    solve m_address,m_cache_warmups,m_cache_hit before m_cache_warmup_tags;
    solve m_parity_error_inject_vld before m_cache_warmups;

    m_parity_error_inject_vld -> (m_cache_warmups > 0);

    m_cache_warmups inside {[0:4]}; //0 to N-Ways
    m_cache_warmup_tags.size() == m_cache_warmups;

    foreach(m_cache_warmup_tags[I]){
      if(I==0 && m_cache_hit){
        m_cache_warmup_tags[I] == m_address[ADDR_WIDTH-1 -: TAG_WIDTH]; // if we want a hit make the first block match the tested address
      } else {
        m_cache_warmup_tags[I] != m_address[ADDR_WIDTH-1 -: TAG_WIDTH]; //otherwise ensure all warmup addresses are a different tag
      }
    }
    unique {m_cache_warmup_tags};
  }

  constraint parity_error_inject_vld_c {
    solve m_cache_state before m_parity_error_inject_vld;
    (m_cache_state != CACHE_ACTIVE_STATE) -> soft m_parity_error_inject_vld == 0;
  }

  constraint parity_error_mask_base_c {
    solve m_parity_error_inject_vld before m_parity_error_num_blocks;

    m_parity_error_num_blocks inside {[0:4]};
    m_parity_error_inject_vld -> (m_parity_error_num_blocks > 0);

    $countones(m_parity_error_mask) == m_parity_error_num_blocks; // total number of parity errors
    $countones(m_parity_error_mask[ 9:0 ]) <= 1; //at most one parity error in block 0
    $countones(m_parity_error_mask[19:10]) <= 1; //at most one parity error in block 1
    $countones(m_parity_error_mask[29:20]) <= 1; //at most one parity error in block 2
    $countones(m_parity_error_mask[39:30]) <= 1; //at most one parity error in block 3

    foreach(VTAG_VALID_BITS[I]){ m_parity_error_mask[VTAG_VALID_BITS[I]] == 1'b0; } //don't flip valid bit
  }

  constraint parity_error_mask_c {
    solve m_parity_error_inject_vld before m_parity_error_mask;
    solve m_cache_state before m_parity_error_mask;
    solve m_cache_warmups before m_parity_error_mask;

    if(m_cache_state == CACHE_ACTIVE_STATE){
      if(m_parity_error_inject_vld){
        // inject into at least 1 valid block (see above)
        if(m_cache_warmups==1) {$countones(m_parity_error_mask[ 9:0]) > 0;}
        if(m_cache_warmups==2) {$countones(m_parity_error_mask[19:0]) > 0;}
        if(m_cache_warmups==3) {$countones(m_parity_error_mask[29:0]) > 0;}
        if(m_cache_warmups==4) {$countones(m_parity_error_mask[39:0]) > 0;}
      } else {
        //Prevent injecting into valid blocks
        if(m_cache_warmups==1) {$countones(m_parity_error_mask[ 9:0]) == 0;}
        if(m_cache_warmups==2) {$countones(m_parity_error_mask[19:0]) == 0;}
        if(m_cache_warmups==3) {$countones(m_parity_error_mask[29:0]) == 0;}
        if(m_cache_warmups==4) {$countones(m_parity_error_mask[39:0]) == 0;}
      }
    }
  }

  function new(string name="sinc_vtag_parity_error_inj_test_seq");
    super.new(name);
    process_plusargs_and_populate_seq_item();
  endfunction : new

  virtual task body();
    uvm_report_object report_obj;
    report_obj = this.uvm_get_report_object();

    uvm_root::get().set_report_verbosity_level_hier(UVM_NONE);
    report_obj.set_report_verbosity_level(UVM_MEDIUM);

    super.body();
    test_done();
  endtask : body

  function void post_randomize();
    super.post_randomize();
    m_cache_warmup_tags.shuffle(); // shuffle the warmup tags so that cahce hit isn't always in entry 0
  endfunction : post_randomize

  extern virtual task start_erase_optional();
  extern virtual task disable_state_fw_operations();
  extern virtual task init_state_fw_operations();
  extern virtual task warm_reset();
  extern virtual function void process_plusargs_and_populate_seq_item();
  //Test Specific

  extern virtual task sinc_cpu_read_access_check(
    input  ccpui_cpu_mem_addr_t addr,
    output ccpui_cpu_mem_data_t read_data,
    input  bit                  expect_error     =1'b0,
    input  bit                  expect_data_valid=1'b0,
    input  ccpui_cpu_mem_data_t expect_data      = '0
  );

  extern virtual task sinc_status_reg_err_check(input bit expect_hw_fault, input bit[7:0] expected_state);

  extern virtual task sequential_run_body();

  extern virtual task run_single_parity_error_injection();

endclass : sinc_vtag_parity_error_inj_test_seq

//##############################################################################
//<> Test Specific Functions
//##############################################################################

function void sinc_vtag_parity_error_inj_test_seq::process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

  if ($value$plusargs("SINC_TB_CACHE_STATE=%0s", tmp_str)) begin
    m_use_fixed_cache_state=1;
    if (tmp_str == "DISABLED") begin
      m_fixed_cache_state = CACHE_DISABLE_STATE;
    end else if (tmp_str == "INIT") begin
      m_fixed_cache_state = CACHE_INIT_STATE;
    end else if (tmp_str == "ACTIVE") begin
      m_fixed_cache_state = CACHE_ACTIVE_STATE;
    end else begin
      `uvm_fatal(get_name(),$sformatf("Unrecognized +SINC_TB_CACHE_STATE=%s",tmp_str))
    end
    `uvm_info(get_name(), $sformatf("Plusarg Override m_fixed_cache_state is set to %0s", m_fixed_cache_state.name()), UVM_LOW)
  end

  if($value$plusargs("SINC_TB_ADDRESS=%0h", m_fixed_address)) begin
    m_use_fixed_address=1;
    `uvm_info(get_name(), $sformatf("Plusarg Override m_fixed_address=%0h",m_fixed_address), UVM_NONE)
  end

  if($value$plusargs("SINC_TB_RANDOMIZED_RUNS=%0d", m_num_randomized_tests)) begin
    `uvm_info(get_name(), $sformatf("Plusarg Override m_num_randomized_tests=%0d",m_num_randomized_tests), UVM_NONE)
  end
endfunction : process_plusargs_and_populate_seq_item

task sinc_vtag_parity_error_inj_test_seq::sinc_status_reg_err_check(input bit expect_hw_fault, input bit [7:0] expected_state);
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

task sinc_vtag_parity_error_inj_test_seq::sinc_cpu_read_access_check(
    input  ccpui_cpu_mem_addr_t addr,
    output ccpui_cpu_mem_data_t read_data,
    input  bit                  expect_error     =1'b0,
    input  bit                  expect_data_valid=1'b0,
    input  ccpui_cpu_mem_data_t expect_data      ='0
  );

  string               debug_str     = "DV::sinc_cpu_read_access_check";
  ccpui_cpu_mem_data_t cpu_read_data;
  logic                cpu_read_err;

  bit is_mpu_allowed;
  bit r_acc_vio;
  bit r_accvio_ex;
  bit r_accvio_rd;
  bit r_accvio_wr;

  uvm_reg_data_t my_data;
  uvm_status_e   my_status;

  `uvm_info (get_name(), $sformatf("%s: cpu_addr 'h%h", debug_str, addr), UVM_MEDIUM)

  m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(addr), .loadstore(1'b1), .privmode(1'b1), .read_data(cpu_read_data));
  read_data = cpu_read_data;
  `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, addr, cpu_read_data), UVM_MEDIUM)

  is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(
    .we         (1'b0       ),
    .loadstore  (1'b1       ),
    .accsrc     (1'b0       ),
    .priv_mode  (1'b1       ),
    .addr       (addr       ),
    .r_acc_vio  (r_acc_vio  ),
    .r_accvio_ex(r_accvio_ex),
    .r_accvio_rd(r_accvio_rd),
    .r_accvio_wr(r_accvio_wr)
  );

  if (!is_mpu_allowed) begin //IF MPU is not allowed then expect CPU ERRDATA response
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h] (mpu not allowed) , Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else if (expect_error) begin
    if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h] (parity error) , Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
  end else begin // Otherwise Expect actual data
    if (expect_data_valid) begin
      if(cpu_read_data !== expect_data) begin
        `uvm_error(get_name(), $sformatf("%s:Addr['h%h] Expect Data['h%h], Actual ['h%0h]", debug_str, addr, expect_data, read_data))
      end
    end else begin

      //If we happened to get ERRDATA check the status register to ensure it was just coincidence
      if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA && !expect_error) begin

        m_regmodel.status.read(my_status, my_data, .extension(null));
        if(my_status != UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end

        if((my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])) begin
          `uvm_error(get_name(), $sformatf("%s:unexpected HW_FAULT. SINC_STATUS['h%0h], CPU_READ_DATA ['h%0h]", debug_str, my_data, cpu_read_data))
        end
      end
    end
  end

  `uvm_info (get_name(), $sformatf("%s:DEBUG : CPU READ access complete cpu_addr:'h%h data: 'h%h", debug_str, addr, cpu_read_data), UVM_MEDIUM)
  `uvm_info (get_name(), $sformatf("%s: test on address 'h%h - done", debug_str, addr), UVM_MEDIUM)
endtask : sinc_cpu_read_access_check

task sinc_vtag_parity_error_inj_test_seq::sequential_run_body();
  string debug_str = "vtag_parity_error_inj_seq_body";

  `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation started.", debug_str), UVM_LOW)
  preload_encrypted_blocks(.prog_all(1));
  `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation completed.", debug_str), UVM_LOW)

  if(m_num_randomized_tests==0) begin
    `uvm_info(get_name(),"Starting Test With Deterministic Scenario loop\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n", UVM_MEDIUM)

    m_cache_state.rand_mode(0);
    m_parity_error_num_blocks.rand_mode(0);
    m_parity_error_inject_vld.rand_mode(0);
    m_cache_warmups.rand_mode(0);

    if(!this.randomize(m_address) with { m_use_fixed_address -> (m_address == m_fixed_address); } ) begin
      `uvm_fatal("RAND", "Unable to randomize m_address")
    end
    m_address.rand_mode(0); // keep address fixed for rest of test

    //Run all possible combos:
    // - CACHE_DISABLED/CACHE_ACTIVE,
    // - With/Without Parity Erropr
    for(int cache_active=0; cache_active<=1; cache_active++) begin
      m_cache_state = (cache_active ? CACHE_ACTIVE_STATE : CACHE_DISABLE_STATE);
      for(int inject = 0; inject <= 1; inject++) begin
        m_parity_error_inject_vld=(cache_active ? inject : 1'b0);
        m_parity_error_num_blocks=inject;
        m_cache_warmups = (cache_active&&inject ? 4 : 1);
        if(!randomize()) begin
          `uvm_fatal("RAND","Unable to randomize configuration")
        end
        run_single_parity_error_injection( );
        wait_n_clks(50);// Arbitrary delay
      end
    end
  end else begin
    `uvm_info(get_name(),$sformatf("Starting Test With %0d Randomized Scenerios\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",m_num_randomized_tests), UVM_MEDIUM)
    repeat(m_num_randomized_tests) begin
      if(!randomize() with {
        m_use_fixed_address -> (m_address == m_fixed_address);
        m_use_fixed_cache_state -> (m_cache_state == m_fixed_cache_state);
      }) begin
        `uvm_fatal("RAND","Unable to randomize configuration")
      end
      run_single_parity_error_injection( );
      wait_n_clks(50);// Arbitrary delay
    end
  end

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)
endtask : sequential_run_body

task sinc_vtag_parity_error_inj_test_seq::run_single_parity_error_injection( );

  string debug_str = "run_single_parity_error_injection";

  ccpui_cpu_mem_data_t initial_read_data;
  ccpui_cpu_mem_data_t read_data;
  uvm_reg_data_t       status_reg_data;
  bit                  timeout;

  `uvm_info (get_name(), $sformatf("%s: task started\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", debug_str), UVM_LOW)

  `uvm_info(get_name(), $sformatf("Scenario Configuration: \n\
            m_sinc_error_chk_disabled = %b \n\
            m_cache_state = %s \n\
            m_address = 'h%h \n\
            m_cache_hit = %b \n\
            m_cache_warmups = %0d \n\
            m_cache_warmup_tags[] = %p \n\
            m_parity_error_inject_vld = %b \n\
            m_parity_error_num_blocks = %0d \n\
            m_parity_error_mask = 'h%h \n\
            m_recover_type = %s\n",
      m_sinc_error_chk_disabled, m_cache_state.name(), m_address,
      m_cache_hit, m_cache_warmups, m_cache_warmup_tags,
      m_parity_error_inject_vld, m_parity_error_num_blocks,
      m_parity_error_mask, m_recover_type.name())
    , UVM_MEDIUM)

  `uvm_info(get_name,$sformatf("Begining Iteration m_address='h%0h   cache_state=%s    error_mask='h%h",m_address,m_cache_state.name(),m_parity_error_mask), UVM_MEDIUM)

  m_top_configuration.m_sinc_vif.force_or_release_sinc_err_chk_disabled(1, m_sinc_error_chk_disabled);

  //1. Erase Cache / VTAG
  //TODO Erase VTAG HERE... fw_reset copmmand takes care of it not sure about warm_reset

  //2. Enter desired State
  `uvm_info(get_name(), "In DISABLED State after cache erase", UVM_MEDIUM)
  if(m_cache_state == CACHE_INIT_STATE || m_cache_state == CACHE_ACTIVE_STATE) begin
    `uvm_info(get_name(), "Entering INIT state", UVM_HIGH)
    disable_state_fw_operations();
  end

  if(m_cache_state==CACHE_ACTIVE_STATE) begin
    `uvm_info(get_name(), "Entering  ACTIVE state", UVM_HIGH)
    init_state_fw_operations();
    wait_n_clks(15);
  end

  //3. Perform a Successful Read to warm up cache
  `uvm_info(get_name(), "Performing initial reads to warm up cache", UVM_MEDIUM)
  foreach(m_cache_warmup_tags[I]) begin
    ccpui_cpu_mem_addr_t warmup_addr;
    ccpui_cpu_mem_data_t warmup_read_data;
    warmup_addr                            = m_address;
    warmup_addr[ADDR_WIDTH-1 -: TAG_WIDTH] = m_cache_warmup_tags[I];
    sinc_cpu_read_access_check(.addr(warmup_addr), .read_data(warmup_read_data), .expect_error(1'b0), .expect_data_valid(1'b0)); // Check Result  data !== '0 response=OK
    if(m_address==warmup_addr) initial_read_data = warmup_read_data;
  end
  sinc_status_reg_err_check(.expect_hw_fault(1'b0), .expected_state(m_cache_state)); // check no hw fault set
  wait_n_clks(2);

  //4. Inject Parity Error
  if(|m_parity_error_mask) begin
    `uvm_info(get_name(), "Starting parity err injection", UVM_MEDIUM)
    m_top_configuration.m_sinc_vif.force_vtag_parity_error(m_parity_error_mask);
  end

  //5. Perform a read and Check outcome

  `uvm_info(get_name(), "Performing read to test parity err injection",UVM_MEDIUM)
  if(m_cache_state == CACHE_ACTIVE_STATE && m_parity_error_inject_vld) begin
    // This case is hit when a parity error is injected onto one of the warmed up banks.
    sinc_cpu_read_access_check(.addr(m_address), .read_data(read_data), .expect_error(1'b1));
    sinc_status_reg_err_check(.expect_hw_fault(1'b1), .expected_state(CACHE_FAIL_STATE));
  end else if(m_cache_state==CACHE_ACTIVE_STATE &&             //In the active stte
              m_parity_error_num_blocks>0 &&                   //Injecting at least 1 parity error
              !m_cache_hit &&                                  //This read will "warmup" a new block
              |m_parity_error_mask[10*(m_cache_warmups%4)+9 -: 10]  //Error is being injected in the next available bank
  ) begin
    //This state is hit when a parity error is being injected into the bank that this cpu read will eventually fill.
    sinc_cpu_read_access_check(.addr(m_address), .read_data(read_data), .expect_error(1'b1));
    sinc_status_reg_err_check(.expect_hw_fault(1'b1), .expected_state(CACHE_FAIL_STATE));
  end else begin
    // Check Result  data == initial_raed_data,  response=OK
    sinc_cpu_read_access_check(.addr(m_address), .read_data(read_data), .expect_error(1'b0), .expect_data_valid(m_cache_hit), .expect_data(initial_read_data));
    sinc_status_reg_err_check(.expect_hw_fault(1'b0), .expected_state(m_cache_state)); // check no hw fault
  end

  //6. Release Parity Error
  if(|m_parity_error_mask) begin
    `uvm_info(get_name(), "Releasing parity err injection", UVM_MEDIUM)
    m_top_configuration.m_sinc_vif.release_vtag_parity_error();
  end

  //7.  Recover
  if(m_cache_state == CACHE_DISABLE_STATE) begin
    `uvm_info(get_name(), "Skipping Recovery From Disabled State Operation", UVM_MEDIUM)
  end else begin
    `uvm_info(get_name(), "Starting Recovery Operation", UVM_MEDIUM)
    if(m_recover_type == FSM_FAULT_RECOVER_OP_FW_SINC_RESET) begin
      fw_sinc_reset_cmd();
    end else begin
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
      //Reseting RAL beacuse of warm reset
      m_regmodel.reset();
    end


    `uvm_info(get_name(), "Waiting for Reset command completion", UVM_MEDIUM)
    pull_status(status_reg_data, timeout);
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, 32'(status_reg_data), timeout), UVM_MEDIUM)
    m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;

    if (timeout) begin
      `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
    end else begin
      uvm_status_e my_status;
      m_regmodel.status.read(my_status, status_reg_data);
      if(my_status !== UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
      end
      if ((status_reg_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB] || (status_reg_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] !== CACHE_DISABLE_STATE))) begin
        `uvm_error(get_name(), $sformatf("%s: Unexpected HW Fault/CACHE_STATE !=DISABLE", debug_str))
      end
    end
    `uvm_info(get_name(), "Reset Command Completed", UVM_MEDIUM)

    if(m_recover_type == FSM_FAULT_RECOVER_OP_WARM_RESET) begin
      // need to erase cache after warm reset but not after fw reset.
      //since it is automatic in that case.
      start_erase_optional();
    end


    `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation started.", debug_str), UVM_LOW)
    preload_encrypted_blocks(.prog_all(1));
    `uvm_info (get_name(), $sformatf("%s: preload_encrypted_blocks operation completed.", debug_str), UVM_LOW)
  end

  `uvm_info (get_name(), $sformatf("%s: task ended\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", debug_str), UVM_LOW)
endtask

//##############################################################################
//<> Extern Functions
//##############################################################################
task sinc_vtag_parity_error_inj_test_seq::start_erase_optional();
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


task sinc_vtag_parity_error_inj_test_seq::disable_state_fw_operations();
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

task sinc_vtag_parity_error_inj_test_seq::init_state_fw_operations();
  string         debug_str       = "DV::init_state_fw_operations";
  bit            timeout;
  uvm_reg_data_t my_data;
  reg_data_t     block_encr_num  = 'h0;
  reg_data_t     block_encr_addr = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;
  reg_data_t     num_of_blocks   = 'h1;
  int            num_encrypts;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  //256kb Iram with 512 byte block size, and 4 way set associative means 128 sets (256*1024)/(512*4), so 7 bits for set
  //16MB external memory with 512 byte block size means 32, 768 blocks, so block num is 14:0 with 14:7 being the tag
  block_encr_num[6:0]  = 'h0;
  block_encr_num[14:7] = 'h0;
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

  m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_ACTIVE_STATE;

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)
endtask : init_state_fw_operations

task sinc_vtag_parity_error_inj_test_seq::warm_reset();
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

`endif // SINC_VTAG_PARITY_ERROR_INJ_TEST_SEQ
