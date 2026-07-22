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
// File        : sinc_virtual_base_sequence.svh
// Description : 

`ifndef SINC_VIRTUAL_BASE_SEQUENCE
`define SINC_VIRTUAL_BASE_SEQUENCE

//------------------------------------------------------------------------------
// SEQUENCE: sinc_virtual_base_seq
//------------------------------------------------------------------------------
// Virtual base sequence for all stimulus generation.
// Includes all the common functions for SINC TB sequences.
//------------------------------------------------------------------------------

class sinc_virtual_base_sequence extends sinc_bench_sequence_base;
  //While injecting error need to skip parity bit location 5,10,16,21,27,32,38 details in ADO28618
  localparam int PARITY_BIT_LOCATIONS [] = {5, 10, 16, 21, 27, 32, 38};

  `uvm_object_utils(sinc_virtual_base_sequence)

  `uvm_declare_p_sequencer(sinc_virtual_sequencer)

  uvm_phase m_starting_phase;

  `ifndef PAL_DONT_INC_SLAVE_CODE
  pal_peek_poke_base m_peek_poke;
  `endif //!PAL_DONT_INC_SLAVE_CODE

  sinc_axi_rand_seq         m_axi_mst_seq;         // fixme: change original class from _seq to sequence
  sinc_erase_rand_seq       m_erase_rand_seq;      // fixme: change original class from _seq to sequence
  sinc_cpu_rand_sequence    m_cpu_rand_seq;
  sinc_mpu_rand_sequence    m_mpu_rand_seq;
  sinc_ramwrap_inj_rand_seq m_ramwrap_inj_rand_seq;

  sinc_regmodel m_regmodel;

  sinc_sys_cfg      m_sys_cfg;
  sinc_sys_comp_cfg m_dmb_sys_cfg;
  ccpui_mpu_config  m_mpu_cfg;
  sinc_csd          m_csd;

  int m_num_trans = 200;

  typedef byte byte_array_t [];
  typedef reg_data_t reg_data_array_t [];

  function new(string name="sinc_virtual_base_sequence");
    super.new(name);
    m_axi_mst_seq          = sinc_axi_rand_seq::type_id::create("m_axi_mst_seq", , get_full_name());
    m_erase_rand_seq       = sinc_erase_rand_seq::type_id::create("m_erase_rand_seq", , get_full_name());
    m_cpu_rand_seq         = sinc_cpu_rand_sequence::type_id::create("m_cpu_rand_seq", , get_full_name());
    m_mpu_rand_seq         = sinc_mpu_rand_sequence::type_id::create("m_mpu_rand_seq", , get_full_name());
    m_ramwrap_inj_rand_seq = sinc_ramwrap_inj_rand_seq::type_id::create("m_ramwrap_inj_rand_seq", , get_full_name());
  endfunction : new

  extern virtual task pre_body();
  extern virtual task body();
  extern virtual task post_body();
  extern virtual task test_done();
  extern virtual task sequential_run_body();
  extern virtual task start_erase_optional();
  extern virtual task random_sequence_body();
  extern virtual task test_register(uvm_reg item);
  extern virtual task write_reg_value(uvm_reg item, uvm_reg_data_t value, bit is_ro=0);
  extern virtual task read_reg_value(uvm_reg item, ref uvm_reg_data_t reg_rdata);
  extern virtual task wait_clock_ticks(int unsigned num_cycles);
  extern virtual task set_up_fw_operation(sinc_fw_cmd_e fw_cmd, bit is_valid_req);
  extern virtual task pull_status(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);
  extern virtual task pull_status_until_cmd_fail(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);
  extern virtual task wait_sub_axi_trn(ref bit timeout, input int counter = 20000);
  extern virtual task wait_erase_trn(ref bit timeout, input int counter = 20000);
  extern virtual task wait_cpu_trn(ref bit timeout, input int counter = 20000);
  extern virtual task wait_w_cache(ref bit timeout, ref bit success, input int counter = 20000);
  extern virtual task wait_cmu_busy_trn(ref bit timeout, input int counter = 20000);

  extern virtual function void process_plusargs_and_populate_seq_item();

  // fixme-hw: add preload tasks

  // helper functions/tasks specific for SINC
  extern virtual task enable_performance_counters();
  extern virtual task clear_performance_counters();

  extern virtual task fw_set_init_state(
    bit        program_misc_reg       = 0,
    reg_data_t aes_iv_nonce_0         = 'h0,
    reg_data_t aes_iv_nonce_1         = 'h0,
    reg_data_t aes_iv_nonce_2         = 'h0,
    reg_data_t block_encr_key         = 'h0,
    address_t  ext_block_base_addr    = 'h0,
    address_t  ext_auth_tag_base_addr = 'h0
  );

  extern virtual task fw_block_encr(bit program_misc_reg = 0, reg_data_t block_encr_num = 'h0, reg_data_t block_encr_addr = 'h0, reg_data_t num_of_blocks = 'h0);

  extern virtual task fw_set_active_state();
  extern virtual task fw_sinc_reset_cmd();
  extern virtual task fw_sinc_disable_reset_cmd();
  extern virtual task fw_sinc_reinit_cmd();
  extern virtual task fw_sinc_disable_reinit_cmd();

  // set AES test mode
  extern virtual task aes_test_enable(bit enable_status_check = 0);

  // exit AES test mode
  extern virtual task aes_test_disable();

  // load block_entr_key and aes_iv_nonce*
  extern virtual task aes_load_key_iv_nonce(reg_data_t aes_iv_nonce_0 = 'h0, reg_data_t aes_iv_nonce_1 = 'h0, reg_data_t aes_iv_nonce_2 = 'h0, reg_data_t block_encr_key = 'h0);

  // FW loads mode, dir, key_len fields, set cfg_key_iv_vld = 1, and data_in_vld = 0 in the aes_test_ctrl register. FW can additionally set reuse_key = 1 if it wants to reuse previously loaded key.
  extern virtual task aes_load_ctrl_mode_dir_keylen(aes_cmd_mode_e mode = 'h0, aes_cmd_operation_e dir = 'h0, logic [1:0] key_len = 'h0, bit reuse_key = 'h0);

  // FW set data_out_ack in cmd register
  extern virtual task aes_load_ctrl_data_out_ack();

  // load aes_test_data_in*
  extern virtual task aes_load_test_data_in(reg_data_t aes_test_data_in_0 = 'h0, reg_data_t aes_test_data_in_1 = 'h0, reg_data_t aes_test_data_in_2 = 'h0, reg_data_t aes_test_data_in_3 = 'h0);

  // FW loads data_in_byte_cnt and data_in_last fields and set data_in_vld = 1 in the aes_test_ctrl register.
  extern virtual task aes_load_ctrl_bytecnt_last(int aes_data_in_byte_cnt = 'h0, bit data_in_last = 'h0, bit aad = 'h0);

  // wait for aes_test_status.
  extern virtual task wait_aes_status(
                                      input bit cfg_key_iv_rdy,
                                      input bit data_in_rdy,
                                      input bit data_out_vld,
                                      input bit tag_out,
                                      input int counter        = 20000,
                                      ref   bit timeout
                                      );

  // load key data to AXI stub memory
  extern virtual task load_key_to_axi_mem(sinc_axi_addr_t key_axi_addr, sinc_key_t key_data);

  // preload external DMB region with random cache block's data
  // user can choose to preload all, or randomly preload by setting prog_all
  extern virtual task preload_encrypted_blocks(bit prog_all);

  // load encrypted data and corresponding authentication tag to AXI stub memory
  extern virtual task load_encrypted_block_and_auth_tag_to_axi_mem(int block_num, sinc_cache_block_t block_data, bit corrupt_tag=0);

  // fetch data from to AXI stub memory
  extern virtual task fetch_data_from_axi_mem(sinc_axi_addr_t axi_addr, int num_bytes, ref sinc_axi_data_t axi_data[]);

  // ramwrap ecc error injecj interface helper task
  extern virtual task ramwrap_ecc_error_inj_w_addr(logic [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] inj_address, bit correctable, bit active_state);
  extern virtual function cache_mem_w_ecc_t inject_error_2bit_per_39bit(cache_mem_w_ecc_t data_in, bit is_1st_39_bit);
  extern virtual function cache_mem_w_ecc_t inject_error_1bit_in_first_39bit(cache_mem_w_ecc_t data_in);
  extern virtual function cache_mem_w_ecc_t inject_error_1bit_except_parity_bit(cache_mem_w_ecc_t data_in);

endclass : sinc_virtual_base_sequence

// Raise in pre_body so the objection is only raised for root sequences.
// There is no need to raise for sub-sequences since the root sequence
// will encapsulate the sub-sequence.
task sinc_virtual_base_sequence::pre_body();
  super.pre_body();

  m_starting_phase = get_starting_phase();

  if (m_starting_phase != null) begin
    `uvm_info( get_type_name(),
      $sformatf("%s pre_body() raising %s objection",
        get_sequence_path(),
        m_starting_phase.get_name()), UVM_MEDIUM)
    m_starting_phase.raise_objection(this, "sinc_virtual_base_sequence"); // no description - Legacy code

  end

  `ifndef PAL_DONT_INC_SLAVE_CODE
  m_peek_poke = m_tb_vseqr.peek_poke;
  `endif //!PAL_DONT_INC_SLAVE_CODE
endtask : pre_body

// Drop the objection in the post_body so the objection is removed when
// the root sequence is complete.
task sinc_virtual_base_sequence::post_body();
  super.post_body();
  m_starting_phase = get_starting_phase();
  if (m_starting_phase != null) begin
    `uvm_info( get_type_name(),
      $sformatf("%s post_body() dropping %s objection",
        get_sequence_path(),
        m_starting_phase.get_name()), UVM_MEDIUM)
    m_starting_phase.drop_objection(this, "sinc_virtual_base_sequence"); // no description - Legacy code
  end
endtask : post_body

// Communicate test_done status to TB Interface
task sinc_virtual_base_sequence::test_done();
  // Communicate PAL test_done status to TB Interface
  m_tb_vseqr.tb_if.test_done = 1;
endtask : test_done

task sinc_virtual_base_sequence::body();
  time start_time;
  uvm_reg_data_t my_data;
  bit            timeout;
  super.body();
  `uvm_info(get_name(), "Starting Virtual Base Sequence", UVM_LOW)

  if (!$cast(m_regmodel, m_top_configuration.m_regmodel)) begin
    `uvm_fatal("CAST", "Could not cast m_regmodel")
  end

  if (m_top_configuration.m_sys_cfg == null) begin
    `uvm_fatal(get_name(), "top_configuration.m_sys_cfg has not been created before usage")
  end else begin
    m_sys_cfg     = m_top_configuration.m_sys_cfg;
    m_mpu_cfg     = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
    m_dmb_sys_cfg = m_sys_cfg.get_comp_cfg(sinc_env_pkg::SINC_DMB);
    m_csd         = m_top_configuration.m_csd;
  end

  // fork pal, sideband, error injection sequences
  fork: sinc_virtual_base_seq_fork
    begin
      fork: concurrent_behavior_fork
        begin
          m_axi_mst_seq.start(m_sequencer, this);
        end
        begin
          m_erase_rand_seq.start(m_sequencer, this);
        end
        begin
          m_cpu_rand_seq.start(m_sequencer, this);
        end
        begin
          m_mpu_rand_seq.start(m_sequencer, this);
        end
        begin
          m_ramwrap_inj_rand_seq.start(m_sequencer, this);
        end
        begin
          // leave for MEM Inject
        end
      join :concurrent_behavior_fork
    end
    //do_check_soc_reset();
  join_any :sinc_virtual_base_seq_fork

  start_erase_optional();

  // sequencial transactions
  sequential_run_body();

  // random transactions
  random_sequence_body();

  // check status at end of the test
  pull_status(my_data, timeout);

  start_time = $time();
  while( ($time() - start_time) < 20us) begin
    wait_n_clks(1);
  end

  ->m_axi_mst_seq.m_sp_con_seq.seq_done_e;
  ->m_erase_rand_seq.m_cache_erase_seq.seq_done_e;
  ->m_cpu_rand_seq.m_cpu_mem_seq.seq_done_e;
  ->m_mpu_rand_seq.m_mpu_seq.seq_done_e;

  test_done();
  `uvm_info(get_name(), "Ending Virtual Base Sequence", UVM_LOW)
endtask : body

// main run body
task sinc_virtual_base_sequence::sequential_run_body();
  time start_time = $time();
  `uvm_info(get_name(), "Empty Sequential Sequence", UVM_NONE)
  while( ($time() - start_time) < 20ns) begin
    wait_n_clks(1);
  end
endtask : sequential_run_body

task sinc_virtual_base_sequence::start_erase_optional();
  time start_time = $time();
  `uvm_info(get_name(), "Empty Erase Sequence", UVM_NONE)
  while( ($time() - start_time) < 20ns) begin
    wait_n_clks(1);
  end
endtask : start_erase_optional

task sinc_virtual_base_sequence::random_sequence_body();
  time start_time = $time();
  `uvm_info(get_name(), "Empty Random Sequence", UVM_NONE)
  while( ($time() - start_time) < 20ns) begin
    wait_n_clks(1);
  end
endtask : random_sequence_body

/**
 * Write 0s, 1s and random data, then read back.
 * If item is RO, expect slave error.
 *
 */
task sinc_virtual_base_sequence::test_register(uvm_reg item);
  uvm_status_e                  my_status;
  bit                           is_ro                             = 1;
  bit                           is_wo                             = 1;
  int                           my_upper_bound;
  uvm_reg_field                 my_fields[$];
  uvm_reg_data_t                my_value;
  sinc_axi_reg_access_extension ext_obj;
  uvm_reg_data_t                mirror_val_before_discarded_write;
  uvm_reg_data_t                val_before_reg_walk               = item.get_mirrored_value();

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  item.get_fields(my_fields);

  foreach(my_fields[x]) begin
    is_ro = (my_fields[x].get_access() != "RO") ? 0 : is_ro;
  end

  foreach(my_fields[x]) begin
    is_wo = (my_fields[x].get_access() != "WO") ? 0 : is_wo;
  end

  `uvm_info(get_name(), $sformatf("Start register check on %s, is_ro[%0d], is_wo[%0d]", item.get_full_name(), is_ro, is_wo), UVM_LOW)

  /*
   * Check after reset value
   */
  if (!m_sys_cfg.m_reset_reg_tested) begin
    `uvm_info(get_name(), $sformatf("Checking that default value from UVM regmodel matches RTL out of reset for %s", item.get_full_name()), UVM_LOW)

    item.mirror(.status(my_status), .check(UVM_CHECK), .extension(ext_obj));

    if (m_sys_cfg.is_valid_reg_access(item, SINC_AXI_READ)) begin
      if (my_status != UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
      end
    end else begin
      if (my_status == UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
      end
    end
  end

  // Skip write for control register
  if ((item.get_name() == "cmd") | (item.get_name() == "aes_test_ctrl")) begin
    return;
  end

  /*
   * Write all 1s
   */
  `uvm_info(get_name(), $sformatf("Writing all 1s to %s. It currently has mirrored value 0x%x.", item.get_full_name(), item.get_mirrored_value()), UVM_LOW)
  my_value = 0;
  repeat(item.get_n_bits()) my_value = (my_value << 1) | 1'b1;
  mirror_val_before_discarded_write = item.get_mirrored_value();
  write_reg_value(item, my_value, is_ro);
  if (m_sys_cfg.is_reg_write_discarded(item)) begin // this register can't be written in this state
    void'(item.predict(mirror_val_before_discarded_write));
  end
  wait_n_clks(20);
  item.mirror(.status(my_status), .check(UVM_CHECK), .extension(ext_obj));

  if (m_sys_cfg.is_valid_reg_access(item, SINC_AXI_READ)) begin
    if (my_status != UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end else begin
    if (my_status == UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end

  wait_n_clks(20);

  /*
   * Write random value
   */
  `uvm_info(get_name(), $sformatf("Writing random value to %s", item.get_full_name()), UVM_LOW)
  my_upper_bound = (2 ** item.get_n_bits()) - 1;
  if (!(std::randomize(my_value) with {my_value inside {[1 : my_upper_bound]};})) begin
    `uvm_error("RAND", "Could not randomize my_value")
  end
  mirror_val_before_discarded_write = item.get_mirrored_value();
  write_reg_value(item, my_value, is_ro);
  if (m_sys_cfg.is_reg_write_discarded(item)) begin // this register can't be written in this state
    void'(item.predict(mirror_val_before_discarded_write));
  end
  wait_n_clks(20);
  item.mirror(.status(my_status), .check(UVM_CHECK), .extension(ext_obj));
  if (m_sys_cfg.is_valid_reg_access(item, SINC_AXI_READ)) begin
    if (my_status != UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end else begin
    if (my_status == UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end

  wait_n_clks(20);

  /*
   * Write all 0s
   */
  `uvm_info(get_name(), $sformatf("Writing all 0s to %s", item.get_full_name()), UVM_LOW)
  mirror_val_before_discarded_write = item.get_mirrored_value();
  write_reg_value(item, 0, is_ro);
  if (m_sys_cfg.is_reg_write_discarded(item)) begin // this register can't be written in this state
    void'(item.predict(mirror_val_before_discarded_write));
  end

  wait_n_clks(20);
  item.mirror(.status(my_status), .check(UVM_CHECK), .extension(ext_obj));

  if (m_sys_cfg.is_valid_reg_access(item, SINC_AXI_READ)) begin
    if (my_status != UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end else begin
    if (my_status == UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
    end
  end

  if (!is_ro & !m_sys_cfg.is_reg_write_discarded(item) & m_sys_cfg.is_valid_reg_access(item, SINC_AXI_WRITE)) begin
    write_reg_value(item, val_before_reg_walk, is_ro); // writing the original value
  end

  wait_n_clks(20);
endtask : test_register

task sinc_virtual_base_sequence::write_reg_value(uvm_reg item, uvm_reg_data_t value, bit is_ro = 0);
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_readback_value;
  sinc_axi_reg_access_extension ext_obj;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  item.write(my_status, value, .extension(ext_obj));

  //Do real checks in scoreboard
  if(my_status !== UVM_IS_OK) begin
    `uvm_info(get_name(), $sformatf("item.write (%s @ 'h%h) returned status %s", item.get_name(), item.get_address(), my_status.name()), UVM_DEBUG)
  end
  // scoreboard will replace below checks
  // if (!m_sys_cfg.is_valid_reg_access(item, SINC_AXI_WRITE)) begin
  //   if (my_status == UVM_IS_OK) begin
  //     `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
  //   end
  // end else begin
  //   if (m_sys_cfg.m_sinc_enable_specific_fault_err) begin // fixme-hw: implement waiver in DV 0.8
  //     // don't report error
  //   end else begin
  //     if (my_status != UVM_IS_OK) begin
  //       `uvm_error(get_name(), $sformatf("Received error response %s when reading %s", my_status.name(), item.get_full_name()))
  //     end
  //   end
  // end

endtask : write_reg_value

// read register reg_data_t
task sinc_virtual_base_sequence::read_reg_value(uvm_reg item, ref uvm_reg_data_t reg_rdata);
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_readback_value;
  sinc_axi_reg_access_extension ext_obj;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  item.read(my_status, my_readback_value, .extension(ext_obj));
  //Do real checks in scoreboard
  if(my_status !== UVM_IS_OK) begin
    `uvm_info(get_name(), $sformatf("item.read (%s @ 'h%h) returned status %s", item.get_name(), item.get_address(), my_status.name()), UVM_DEBUG)
  end
  reg_rdata = my_readback_value;
endtask : read_reg_value

//------------------------------------------------------------------------//
// Wait for the specified number of clocks                                //
//------------------------------------------------------------------------//
task sinc_virtual_base_sequence::wait_clock_ticks(int unsigned num_cycles);
  repeat (num_cycles) @(posedge p_sequencer.m_pal_sequencer.clkrst_if.ACLK);
endtask : wait_clock_ticks

//------------------------------------------------------------------------//
// Set up FW Operation                                                    //
//------------------------------------------------------------------------//
task sinc_virtual_base_sequence::set_up_fw_operation(sinc_fw_cmd_e fw_cmd, bit is_valid_req);
  string debug_str = "set_up_fw_operation";

  `uvm_info(get_name(), $sformatf("fw_cmd is 0x%0x", fw_cmd), UVM_LOW)

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

task sinc_virtual_base_sequence::pull_status(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       proc[$];
  bit                           local_timeout;
  uvm_reg_data_t                local_status_rdata;

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
      //Do real checks in scoreboard
      if(my_status !== UVM_IS_OK) begin
        `uvm_info(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()), UVM_DEBUG)
      end

      // SINC is in BUSY status
      while (my_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_MSB]) begin
        wait_n_clks(50);
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        //Do real checks in scoreboard
        if(my_status !== UVM_IS_OK) begin
          `uvm_info(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()), UVM_DEBUG)
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
  timeout=local_timeout;
  if(!local_timeout) begin
    status_rdata = local_status_rdata;
  end else begin
    // note: not sure why the code set return data differently relying on timeout, keep this condition for further investigation and monitor the regression
    status_rdata = my_data;
  end

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : pull_status

task sinc_virtual_base_sequence::pull_status_until_cmd_fail(ref uvm_reg_data_t status_rdata, ref bit timeout, input int counter = 500000);

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       proc[$];
  bit                           local_timeout;
  uvm_reg_data_t                local_status_rdata;

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
      //Do real checks in scoreboard
      if(my_status !== UVM_IS_OK) begin
        `uvm_info(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()), UVM_DEBUG)
      end

      // SINC is in BUSY status
      while ((my_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] == 0) &&
             (my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] == 0) &&
             (my_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE] == 0) &&
             (my_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] == 0) &&
             (my_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] == 0) &&
             (my_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] == 0)
             ) begin
        wait_n_clks(50);
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        //Do real checks in scoreboard
        if(my_status !== UVM_IS_OK) begin
          `uvm_info(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()), UVM_DEBUG)
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
  timeout=local_timeout;
  if(!local_timeout) begin
    status_rdata = local_status_rdata;
  end else begin
    // note: not sure why the code set return data differently relying on timeout, keep this condition for further investigation and monitor the regression
    status_rdata = my_data;
  end

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : pull_status_until_cmd_fail


task sinc_virtual_base_sequence::wait_sub_axi_trn(ref bit timeout, input int counter = 20000);

  process proc[$];
  bit     local_timeout;
  //Wait for sub axi trn
  fork : check_for_sub_axi_trn
    begin
      proc.push_back(process::self());
      wait(m_top_configuration.m_sinc_vif.sinc_sub_start_axi_trn === 1'b1);
      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout=local_timeout;

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : wait_sub_axi_trn

task sinc_virtual_base_sequence::wait_erase_trn(ref bit timeout, input int counter = 20000);

  process proc[$];
  bit     local_timeout;
  //Wait for sub axi trn
  fork : check_for_erase
    begin
      proc.push_back(process::self());
      wait(m_top_configuration.m_sinc_vif.sinc_start_erase === 1'b1);
      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout=local_timeout;

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : wait_erase_trn

task sinc_virtual_base_sequence::wait_cpu_trn(ref bit timeout, input int counter = 20000);

  process proc[$];
  bit     local_timeout;
  //Wait for sub axi trn
  fork : check_for_cpu_trn
    begin
      proc.push_back(process::self());
      wait(m_top_configuration.m_sinc_vif.sinc_start_cpu_trn === 1'b1);
      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout = local_timeout;

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

endtask : wait_cpu_trn

task sinc_virtual_base_sequence::wait_w_cache(ref bit timeout, ref bit success, input int counter = 20000);

  process proc[$];
  bit     local_timeout;
  bit     local_success;

  //Wait for write cache
  fork : check_for_w_cache
    begin
      proc.push_back(process::self());
      m_top_configuration.m_sinc_vif.wait_ciram_write(local_success);
      // wait(top_configuration.m_sinc_vif.sinc_start_cpu_trn === 1'b1);
      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout = local_timeout;
  success = local_success;

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end
  end

endtask : wait_w_cache

task sinc_virtual_base_sequence::wait_cmu_busy_trn(ref bit timeout, input int counter = 20000);

  process proc[$];
  bit     local_timeout;
  //Wait for sub axi trn
  fork : check_for_cmu_busy
    begin
      proc.push_back(process::self());
      wait(m_top_configuration.m_sinc_vif.sinc_start_cmu_busy === 1'b1);
      //wait(top_configuration.m_sinc_vif.sinc_start_cmu_active === 1'b1);
      local_timeout = 0;
    end
    begin
      proc.push_back(process::self());
      wait_n_clks(counter);
      local_timeout = 1;
    end
  join_any
  timeout = local_timeout;

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end
  end

endtask : wait_cmu_busy_trn

function void sinc_virtual_base_sequence:: process_plusargs_and_populate_seq_item();
  string debug_str = "SINC_SEQ_PROCESS_PLUSARGS";
  string tmp_str;

  /*
   tmp_str = "SINC_FW_ERASE";
   if($value$plusargs({tmp_str, "=%d"}, m_EN_FW_ERASE_CMD)) begin
   `uvm_info(get_name(),  $sformatf("%s from plusarg = %d", tmp_str, m_EN_FW_ERASE_CMD), UVM_LOW)
   end
   */

endfunction : process_plusargs_and_populate_seq_item

// SINC specific task/functions

task sinc_virtual_base_sequence::enable_performance_counters();

  string         debug_str  = "enable_performance_counters";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // Enable the perf counters
  reg_value                                             = 32'h0;
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_HIT_CNTR_EN_MSB]  = 1;
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_MISS_CNTR_EN_MSB] = 1;
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_LAT_CNTR_EN_MSB]  = 1;
  write_reg_value(m_regmodel.perf_cntr_ctrl, reg_value);

endtask : enable_performance_counters

task sinc_virtual_base_sequence::clear_performance_counters();

  string         debug_str  = "clear_performance_counters";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // Read the initial value of the perf register
  read_reg_value(m_regmodel.perf_cntr_ctrl, reg_value);
  // Enable the perf counters
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_HIT_CNTR_CLR_MSB]  = 1;
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_MISS_CNTR_CLR_MSB] = 1;
  reg_value[`SINC_REGS_PERF_CNTR_CTRL_LAT_CNTR_CLR_MSB]  = 1;
  write_reg_value(m_regmodel.perf_cntr_ctrl, reg_value);

endtask : clear_performance_counters

task sinc_virtual_base_sequence::fw_set_init_state(
    bit        program_misc_reg       = 0,
    reg_data_t aes_iv_nonce_0         = 'h0,
    reg_data_t aes_iv_nonce_1         = 'h0,
    reg_data_t aes_iv_nonce_2         = 'h0,
    reg_data_t block_encr_key         = 'h0,
    address_t  ext_block_base_addr    = 'h0,
    address_t  ext_auth_tag_base_addr = 'h0
  );

  string         debug_str  = "fw_set_init_state";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  if (program_misc_reg) begin
    uvm_reg_data_t reg_value_aes_iv_nonce_0         = uvm_reg_data_t'(aes_iv_nonce_0);
    uvm_reg_data_t reg_value_aes_iv_nonce_1         = uvm_reg_data_t'(aes_iv_nonce_1);
    uvm_reg_data_t reg_value_aes_iv_nonce_2         = uvm_reg_data_t'(aes_iv_nonce_2);
    uvm_reg_data_t reg_value_block_encr_key         = uvm_reg_data_t'(block_encr_key);
    uvm_reg_data_t reg_value_ext_block_base_addr    = uvm_reg_data_t'(ext_block_base_addr);
    uvm_reg_data_t reg_value_ext_auth_tag_base_addr = uvm_reg_data_t'(ext_auth_tag_base_addr);

    write_reg_value(m_regmodel.aes_iv_nonce_0, reg_value_aes_iv_nonce_0);
    write_reg_value(m_regmodel.aes_iv_nonce_1, reg_value_aes_iv_nonce_1);
    write_reg_value(m_regmodel.aes_iv_nonce_2, reg_value_aes_iv_nonce_2);
    write_reg_value(m_regmodel.block_encr_key, reg_value_block_encr_key);
    write_reg_value(m_regmodel.ext_block_base_addr, reg_value_ext_block_base_addr);
    write_reg_value(m_regmodel.ext_auth_tag_base_addr, reg_value_ext_auth_tag_base_addr);
  end

  // construct cmd: set_init_state
  reg_value                                    = 32'h0;
  reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.set_init_state.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)

  write_reg_value(m_regmodel.cmd, reg_value);

endtask : fw_set_init_state

task sinc_virtual_base_sequence::fw_block_encr(bit program_misc_reg = 0, reg_data_t block_encr_num = 'h0, reg_data_t block_encr_addr = 'h0, reg_data_t num_of_blocks = 'h0);

  string         debug_str  = "fw_block_encr";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  if (program_misc_reg) begin
    uvm_reg_data_t reg_block_encr_num  = uvm_reg_data_t'(block_encr_num);
    uvm_reg_data_t reg_block_encr_addr = uvm_reg_data_t'(block_encr_addr);
    uvm_reg_data_t reg_num_of_blocks   = uvm_reg_data_t'(num_of_blocks);

    write_reg_value(m_regmodel.block_encr_num, reg_block_encr_num);
    write_reg_value(m_regmodel.block_encr_addr, reg_block_encr_addr);
    write_reg_value(m_regmodel.num_of_blocks, reg_num_of_blocks);
  end

  // construct cmd: set_init_state
  reg_value                                = 32'h0;
  reg_value[`SINC_REGS_CMD_ENCR_BLOCK_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.encr_block.get_name(), reg_value[`SINC_REGS_CMD_ENCR_BLOCK_MSB]), UVM_HIGH)

  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("Starting %0s ENCR_BLOCK command",
      debug_str), UVM_MEDIUM)

endtask : fw_block_encr

// transition into ACTIVE state
task sinc_virtual_base_sequence::fw_set_active_state();
  uvm_reg_data_t reg_value;
  string         debug_str = "fw_set_active_state";

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct cmd: set_active_state
  reg_value                                            = 32'h0;
  reg_value[`SINC_REGS_CMD_SET_CACHE_ACTIVE_STATE_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.set_cache_active_state.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("End %0s operation",
      debug_str), UVM_MEDIUM)

endtask : fw_set_active_state

task sinc_virtual_base_sequence::fw_sinc_reset_cmd();
  uvm_reg_data_t reg_value;
  string         debug_str = "fw_sinc_reset_cmd";

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct cmd: set_reset_state
  reg_value                                = 32'h0;
  reg_value[`SINC_REGS_CMD_SINC_RESET_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.sinc_reset.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("End %0s operation",
      debug_str), UVM_MEDIUM)

endtask : fw_sinc_reset_cmd

task sinc_virtual_base_sequence::fw_sinc_disable_reset_cmd();
  uvm_reg_data_t reg_value;
  string         debug_str = "fw_sinc_disable_reset_cmd";

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct cmd: set_reset_state
  reg_value                                   = 32'h0;
  reg_value[`SINC_REGS_CMD_DISABLE_RESET_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.disable_reset.get_name(), reg_value[`SINC_REGS_CMD_DISABLE_RESET_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("End %0s operation",
      debug_str), UVM_MEDIUM)

endtask : fw_sinc_disable_reset_cmd

task sinc_virtual_base_sequence::fw_sinc_reinit_cmd();
  uvm_reg_data_t reg_value;
  string         debug_str = "fw_sinc_reinit_cmd";

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct cmd: set_reset_state
  reg_value                                 = 32'h0;
  reg_value[`SINC_REGS_CMD_SINC_REINIT_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.sinc_reinit.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("End %0s operation",
      debug_str), UVM_MEDIUM)

endtask : fw_sinc_reinit_cmd

task sinc_virtual_base_sequence::fw_sinc_disable_reinit_cmd();
  uvm_reg_data_t reg_value;
  string         debug_str = "fw_sinc_disable_reinit_cmd";

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct cmd: set_reset_state
  reg_value                                    = 32'h0;
  reg_value[`SINC_REGS_CMD_DISABLE_REINIT_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.disable_reinit.get_name(), reg_value[`SINC_REGS_CMD_DISABLE_REINIT_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(),
    $sformatf("End %0s operation",
      debug_str), UVM_MEDIUM)

endtask : fw_sinc_disable_reinit_cmd

// enable AES Test mode
task sinc_virtual_base_sequence::aes_test_enable(bit enable_status_check = 0);

  string         debug_str  = "aes_test_enable";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  reg_value                                 = 32'h0;
  reg_value[`SINC_REGS_CMD_AES_TEST_EN_LSB] = 1;

  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(), $sformatf("Try Set %0s: [%0d] to enable AES test mode", m_regmodel.cmd.get_name(), reg_value), UVM_HIGH)

  if (enable_status_check) begin
    if (m_sys_cfg.m_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
      read_reg_value(m_regmodel.cmd, reg_value);

      if (!reg_value[`SINC_REGS_CMD_AES_TEST_EN_LSB]) begin
        `uvm_error(get_name(), $sformatf("SINC not in AES Test Mode yet, check your stimulus 'h%h", reg_value))
      end
    end
  end

endtask : aes_test_enable

task sinc_virtual_base_sequence::aes_test_disable();

  string         debug_str  = "aes_test_disable";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  reg_value                                 = 32'h0;
  reg_value[`SINC_REGS_CMD_AES_TEST_EN_LSB] = 0;

  write_reg_value(m_regmodel.cmd, reg_value);

  `uvm_info(get_name(), $sformatf("Try Set %0s: [%0d] to disable AES test mode", m_regmodel.cmd.get_name(), reg_value), UVM_HIGH)

  if (m_sys_cfg.m_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
    read_reg_value(m_regmodel.cmd, reg_value);

    if (reg_value[`SINC_REGS_CMD_AES_TEST_EN_LSB]) begin
      `uvm_error(get_name(), $sformatf("SINC not in AES Test Mode yet, check your stimulus 'h%h", reg_value))
    end
  end

endtask : aes_test_disable

task sinc_virtual_base_sequence::aes_load_key_iv_nonce(reg_data_t aes_iv_nonce_0 = 'h0, reg_data_t aes_iv_nonce_1 = 'h0, reg_data_t aes_iv_nonce_2 = 'h0, reg_data_t block_encr_key = 'h0);

  string         debug_str                = "aes_load_key_iv_nonce";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;
  uvm_reg_data_t reg_value_aes_iv_nonce_0 = uvm_reg_data_t'(aes_iv_nonce_0);
  uvm_reg_data_t reg_value_aes_iv_nonce_1 = uvm_reg_data_t'(aes_iv_nonce_1);
  uvm_reg_data_t reg_value_aes_iv_nonce_2 = uvm_reg_data_t'(aes_iv_nonce_2);
  uvm_reg_data_t reg_value_block_encr_key = uvm_reg_data_t'(block_encr_key);

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  write_reg_value(m_regmodel.aes_iv_nonce_0, reg_value_aes_iv_nonce_0);
  write_reg_value(m_regmodel.aes_iv_nonce_1, reg_value_aes_iv_nonce_1);
  write_reg_value(m_regmodel.aes_iv_nonce_2, reg_value_aes_iv_nonce_2);
  write_reg_value(m_regmodel.block_encr_key, reg_value_block_encr_key);

endtask : aes_load_key_iv_nonce

task sinc_virtual_base_sequence::aes_load_ctrl_mode_dir_keylen(aes_cmd_mode_e mode = 'h0, aes_cmd_operation_e dir = 'h0, logic [1:0] key_len = 'h0, bit reuse_key = 'h0);

  string         debug_str  = "aes_load_ctrl_mode_dir_keylen";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct aes_test_ctrl reg data
  reg_value                                                = 'h0;
  reg_value[`SINC_REGS_AES_TEST_CTRL_MODE_RANGE]           = mode;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DIR_RANGE]            = dir;
  reg_value[`SINC_REGS_AES_TEST_CTRL_KEY_LEN_RANGE]        = key_len;
  reg_value[`SINC_REGS_AES_TEST_CTRL_REUSE_KEY_RANGE]      = reuse_key;
  reg_value[`SINC_REGS_AES_TEST_CTRL_CFG_KEY_IV_VLD_RANGE] = 1;

  write_reg_value(m_regmodel.aes_test_ctrl, reg_value);

endtask : aes_load_ctrl_mode_dir_keylen

// fixme
task sinc_virtual_base_sequence::aes_load_ctrl_data_out_ack();

  string         debug_str  = "aes_load_ctrl_data_out_ack";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct aes_test_ctrl reg data
  reg_value                                              = 'h0;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DATA_OUT_ACK_RANGE] = 1;

  write_reg_value(m_regmodel.aes_test_ctrl, reg_value);

endtask : aes_load_ctrl_data_out_ack

task sinc_virtual_base_sequence::aes_load_test_data_in(reg_data_t aes_test_data_in_0 = 'h0, reg_data_t aes_test_data_in_1 = 'h0, reg_data_t aes_test_data_in_2 = 'h0, reg_data_t aes_test_data_in_3 = 'h0);

  string         debug_str  = "aes_load_test_data_in";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  write_reg_value(m_regmodel.aes_test_data_in_0, aes_test_data_in_0);
  write_reg_value(m_regmodel.aes_test_data_in_1, aes_test_data_in_1);
  write_reg_value(m_regmodel.aes_test_data_in_2, aes_test_data_in_2);
  write_reg_value(m_regmodel.aes_test_data_in_3, aes_test_data_in_3);

endtask : aes_load_test_data_in

task sinc_virtual_base_sequence::aes_load_ctrl_bytecnt_last(int aes_data_in_byte_cnt = 'h0, bit data_in_last = 'h0, bit aad = 'h0);

  string         debug_str  = "aes_load_ctrl_bytecnt_last";
  uvm_status_e   reg_status;
  uvm_reg_data_t reg_value;

  `uvm_info(get_name(),
    $sformatf("Starting %0s operation",
      debug_str), UVM_MEDIUM)

  // construct aes_test_ctrl reg data
  reg_value                                                  = 'h0;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DATA_IN_BYTE_CNT_RANGE] = aes_data_in_byte_cnt;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DATA_IN_LAST_RANGE]     = data_in_last;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DATA_IN_AAD_SEL_RANGE] = aad;
  reg_value[`SINC_REGS_AES_TEST_CTRL_DATA_IN_VLD_RANGE]      = 1;

  write_reg_value(m_regmodel.aes_test_ctrl, reg_value);

endtask : aes_load_ctrl_bytecnt_last

task sinc_virtual_base_sequence::wait_aes_status(
                                                 input bit cfg_key_iv_rdy,
                                                 input bit data_in_rdy,
                                                 input bit data_out_vld,
                                                 input bit tag_out,
                                                 input int counter        = 20000,
                                                 ref   bit timeout
                                                 );

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       proc[$];
  bit                           local_timeout=1'b0;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end
  `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status,  cfg_key_iv_rdy[%0d], data_in_rdy[%0d], data_out_vld[%0d], tag_out[%0d], [%0d]",
                                  cfg_key_iv_rdy, data_in_rdy, data_out_vld, tag_out, counter), UVM_HIGH)
  //Wait for aes status register
  fork : check_for_given_aes_status
    begin
      proc.push_back(process::self());
      m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
      //Do real checks in scoreboard
      if(my_status !== UVM_IS_OK) begin
        `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()), UVM_DEBUG)
      end
      if (cfg_key_iv_rdy) begin
        `uvm_info(get_name(), $sformatf("debug: cfg_key_iv_rdy set %0d, my_data['h%0h]", cfg_key_iv_rdy, my_data), UVM_LOW)
        while (my_data[`SINC_REGS_AES_TEST_STATUS_CFG_KEY_IV_RDY_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          //Do real checks in scoreboard
          if(my_status !== UVM_IS_OK) begin
            `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()), UVM_DEBUG)
          end
        end
      end

      if (data_in_rdy) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_DATA_IN_RDY_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          //Do real checks in scoreboard
          if(my_status !== UVM_IS_OK) begin
            `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()), UVM_DEBUG)
          end
        end
      end

      if (data_out_vld) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_DATA_OUT_VLD_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          //Do real checks in scoreboard
          if(my_status !== UVM_IS_OK) begin
            `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()), UVM_DEBUG)
          end
        end
      end

      if (tag_out) begin
        while (my_data[`SINC_REGS_AES_TEST_STATUS_TAG_OUT_LSB] !== 1) begin
          wait_n_clks(20);
          m_regmodel.aes_test_status.read(my_status, my_data, .extension(ext_obj));
          //Do real checks in scoreboard
          if(my_status !== UVM_IS_OK) begin
            `uvm_info(get_name(), $sformatf("m_regmodel.aes_test_status.read returned status %s", my_status.name()), UVM_DEBUG)
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

  // Kill any outstanding processes
  foreach(proc[i]) begin
    if ((proc[i] != null) && (proc[i].status() != process::FINISHED)) begin
      proc[i].kill();
    end

  end

  disable check_for_given_aes_status;

endtask : wait_aes_status

task sinc_virtual_base_sequence::load_key_to_axi_mem(sinc_axi_addr_t key_axi_addr, sinc_key_t key_data);

  string debug_str         = "load_key_to_axi_mem";
  int    num_bytes         = 32;                   // 256 bits Key data
  byte   key_in_bytes[];
  byte   key_rd_in_bytes[];

  key_in_bytes    = new[32];
  key_rd_in_bytes = new[32];
  `uvm_info(get_name(), $sformatf("debug: Back door loading key to the memory, address['h%0h], key_data['h%0h]",
      key_axi_addr, key_data), UVM_LOW)

  for (int byte_index=0; byte_index < 32; byte_index++) begin
    key_in_bytes[byte_index] = key_data[8*byte_index +:8];
  end
  void'(m_peek_poke.write_mem_bytes(key_axi_addr, key_in_bytes));

  void'(m_peek_poke.read_mem_bytes(key_axi_addr, key_rd_in_bytes));

endtask : load_key_to_axi_mem

task sinc_virtual_base_sequence::preload_encrypted_blocks(bit prog_all);
  string             debug_str    = "preload_encrypted_blocks";
  sinc_cache_block_t block_data;
  bit                skip_preload = 0;

  if (!prog_all) begin
    m_sys_cfg.m_skipped_preload_for_some_blocks = 1;
    if (!std::randomize(m_sys_cfg.m_skip_preload_blocks) with {
          unique {m_sys_cfg.m_skip_preload_blocks};
          m_sys_cfg.m_skip_preload_blocks.size() == 10;
          foreach(m_sys_cfg.m_skip_preload_blocks[i])
          {
            m_sys_cfg.m_skip_preload_blocks[i] inside {[0:sinc_parameters_pkg::SINC_CACHE_BLOCK_TOTAL_NUM-1]};
          }
        }) begin
      `uvm_fatal(get_name(), $sformatf("%s: skip_preload_blocks randomize failed!!!", debug_str))
    end

    //copy to hash map for quick check of if we are skipping the block or not
    foreach(m_sys_cfg.m_skip_preload_blocks[i]) begin
      `uvm_info(get_name(), $sformatf("%s: skipping preload for block [%0d]", debug_str, m_sys_cfg.m_skip_preload_blocks[i]), UVM_HIGH)
      m_sys_cfg.m_skip_preload_blocks_map[m_sys_cfg.m_skip_preload_blocks[i]] = 1;
    end
  end else begin
    m_sys_cfg.m_skipped_preload_for_some_blocks = 0;
  end

  for (int block_num=0; block_num < sinc_parameters_pkg::SINC_CACHE_BLOCK_TOTAL_NUM; block_num++) begin
    if (!prog_all) begin
      /*if (!(std::randomize(skip_preload) with {skip_preload dist {0 := 50, 1 := 50};})) begin // this distribution could be controlled by PLUSARG if needed
       `uvm_error("RAND", "Could not randomize my_value")
       end*/
      if(m_sys_cfg.m_skip_preload_blocks_map.exists(block_num)) begin
        `uvm_info(get_name(), $sformatf("%s: skipping preload for block [%0d]", debug_str, block_num), UVM_LOW)
        skip_preload = 1;
      end else begin
        skip_preload = 0;
      end
    end

    if (!skip_preload) begin
      if (!std::randomize(block_data)) begin
        `uvm_fatal(get_name(), "Unable to randomize block_data")
      end
      `uvm_info(get_name(), $sformatf("%0s: Preload encrypted_block [%0d]",
          debug_str, block_num), UVM_HIGH)
      load_encrypted_block_and_auth_tag_to_axi_mem(block_num, block_data);
    end
  end

endtask : preload_encrypted_blocks

task sinc_virtual_base_sequence::load_encrypted_block_and_auth_tag_to_axi_mem(int block_num, sinc_cache_block_t block_data, bit corrupt_tag=0);

  string                      debug_str                = "load_encrypted_block_and_auth_tag_to_axi_mem";
  sinc_axi_addr_t             ext_block_base_addr      = m_sys_cfg.m_ext_block_base_addr;
  sinc_axi_addr_t             ext_auth_tag_base_addr   = m_sys_cfg.m_ext_auth_tag_base_addr;
  sinc_axi_addr_t             ext_block_dst_addr       = ext_block_base_addr + (block_num * sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_AXI_ADDRESS_OFFSET);
  sinc_axi_addr_t             ext_auth_tag_dst_addr    = ext_auth_tag_base_addr + (block_num * sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_FETCH_ADDRESS_OFFSET);
  sinc_cache_block_auth_tag_t gen_auth_tag;
  byte                        block_data_in_bytes[];                                                                                                                // size: sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE
  byte                        auth_tag_data_in_bytes[];                                                                                                             // size: sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_SIZE

  // update CSD
  m_sys_cfg.m_csd.m_cache_blocks[block_num] = block_data;

  block_data_in_bytes                  = new[512];
  auth_tag_data_in_bytes               = new[16];
  m_sys_cfg.m_aes_cfg.m_byte_count     = 512;
  m_sys_cfg.m_aes_cfg.m_aes_message    = new[128];
  m_sys_cfg.m_aes_cfg.m_aes_op         = sinc_parameters_pkg::ENCRYPT;
  m_sys_cfg.m_aes_cfg.m_aes_mode       = sinc_parameters_pkg::GCM;
  m_sys_cfg.m_aes_cfg.m_aes_unit_sz    = sinc_parameters_pkg::BYTES_16;
  m_sys_cfg.m_aes_cfg.m_aes_key_len    = sinc_parameters_pkg::AES_256;
  m_sys_cfg.m_aes_cfg.m_aes_message    = reg_data_array_t'(block_data);
  m_sys_cfg.m_aes_cfg.m_aes_test_mode  = 0;
  m_sys_cfg.m_aes_cfg.m_block_encr_num = block_num;

  //`uvm_info(get_name(), $sformatf("preload_debug: ext_block_dst_addr is 'h%0h", ext_block_dst_addr), UVM_LOW)
  //`uvm_info(get_name(), $sformatf("preload_debug: ext_auth_tag_dst_addr is 'h%0h", ext_auth_tag_dst_addr), UVM_LOW)

  //foreach(m_sys_cfg.m_aes_cfg.m_aes_message[i]) begin
  //  `uvm_info(get_name(), $sformatf("debug: m_aes_message[%0d] is 'h%0h", i, m_sys_cfg.m_aes_cfg.m_aes_message[i]), UVM_LOW)
  //end

  m_sys_cfg.m_aes_cfg.construct_aes_item();
  //m_sys_cfg.m_aes_cfg.print_packet();
  m_sys_cfg.m_aes_cfg.cal_rslt_w_c_model();

  //get ciphertext from m_aes_result
  for (int word_index = 0; word_index < 128; word_index++) begin
    block_data_in_bytes[(word_index * 4) + 0] = m_sys_cfg.m_aes_cfg.m_aes_result[word_index][0 +: 8];
    block_data_in_bytes[(word_index * 4) + 1] = m_sys_cfg.m_aes_cfg.m_aes_result[word_index][8 +: 8];
    block_data_in_bytes[(word_index * 4) + 2] = m_sys_cfg.m_aes_cfg.m_aes_result[word_index][16 +: 8];
    block_data_in_bytes[(word_index * 4) + 3] = m_sys_cfg.m_aes_cfg.m_aes_result[word_index][24 +: 8];
  end

  //get tag from m_aes_tag
  for (int word_index = 0; word_index < 4; word_index++) begin
    auth_tag_data_in_bytes[(word_index * 4) + 0] = m_sys_cfg.m_aes_cfg.m_aes_tag[word_index][0 +: 8];
    auth_tag_data_in_bytes[(word_index * 4) + 1] = m_sys_cfg.m_aes_cfg.m_aes_tag[word_index][8 +: 8];
    auth_tag_data_in_bytes[(word_index * 4) + 2] = m_sys_cfg.m_aes_cfg.m_aes_tag[word_index][16 +: 8];
    auth_tag_data_in_bytes[(word_index * 4) + 3] = m_sys_cfg.m_aes_cfg.m_aes_tag[word_index][24 +: 8];
  end

  if(corrupt_tag) begin
    int corrupt_byte;
    int corrupt_bit;
    bit corrupt_single_bit;

    if (!(std::randomize(corrupt_single_bit))) begin
      `uvm_fatal(get_name(), "Unable to randomize corrupt_single_bit")
    end

    if(corrupt_single_bit) begin
      if (!(std::randomize(corrupt_byte) with {
              corrupt_byte < 16;
            })) begin
        `uvm_fatal(get_name(), "Unable to randomize corrupt_byte")
      end

      if (!(std::randomize(corrupt_bit) with {
              corrupt_bit < 8;
            })) begin
        `uvm_fatal(get_name(), "Unable to randomize corrupt_bit")
      end

      auth_tag_data_in_bytes[corrupt_byte][corrupt_bit] = auth_tag_data_in_bytes[corrupt_byte][corrupt_bit] ^ 1'b1;
    end else begin
      foreach(auth_tag_data_in_bytes[i]) begin
        byte cor_data;
        if (!(std::randomize(corrupt_byte) with {
                cor_data != auth_tag_data_in_bytes[i];
              })) begin
          `uvm_fatal(get_name(), "Unable to randomize corrupt_byte")
        end
        auth_tag_data_in_bytes[i] = cor_data;
      end
    end

  end

  gen_auth_tag = sinc_cache_block_auth_tag_t'(auth_tag_data_in_bytes);

  `uvm_info(get_name(), $sformatf("debug: Backdoor load encrypted block [%0d], block_address['h%0h], tag_address['h%0h], block_data['h%0h], authentication_tag['h%0h], corrupt_tag[%0d]",
      block_num, ext_block_dst_addr, ext_auth_tag_dst_addr, block_data, gen_auth_tag, corrupt_tag), UVM_DEBUG)

  //foreach(block_data_in_bytes[i]) begin
  //  `uvm_info(get_name(), $sformatf("debug: block_data_in_bytes[%0d] is 'h%0h", i, block_data_in_bytes[i]), UVM_LOW)
  //end

  //foreach(auth_tag_data_in_bytes[i]) begin
  //  `uvm_info(get_name(), $sformatf("debug: auth_tag_data_in_bytes[%0d] is 'h%0h", i, auth_tag_data_in_bytes[i]), UVM_LOW) // fixme- raise verbosity to UVM_DEBUG
  //end

  void'(m_peek_poke.write_mem_bytes(ext_block_dst_addr, block_data_in_bytes));
  void'(m_peek_poke.write_mem_bytes(ext_auth_tag_dst_addr, auth_tag_data_in_bytes));

endtask : load_encrypted_block_and_auth_tag_to_axi_mem

task sinc_virtual_base_sequence::fetch_data_from_axi_mem(sinc_axi_addr_t axi_addr, int num_bytes, ref sinc_axi_data_t axi_data[]);

  string debug_str        = "fetch_data_from_axi_mem";
  int    num_axi_data;
  byte   rdata_in_bytes[];

  if (num_bytes < 4) begin
    num_axi_data = 1;
  end else begin
    num_axi_data = num_bytes / 4;

    if ((num_bytes % 4) !== 0) begin
      // padd rest with 0
      num_axi_data = num_axi_data + 1;
    end
  end

  axi_data       = new[num_axi_data];
  rdata_in_bytes = new[num_bytes];
  `uvm_info(get_name(), $sformatf("debug: Back door fetch data from memory, address['h%0h], num_bytes[%0d], num_axi_data[%0d]",
      axi_addr, num_bytes, num_axi_data), UVM_HIGH)

  void'(m_peek_poke.read_mem_bytes(axi_addr, rdata_in_bytes));

  for (int byte_index=0; byte_index < num_bytes; byte_index++) begin
    // key_in_bytes[byte_index] = key_data[8*byte_index +:8];
    axi_data[byte_index / 4][8*(byte_index%4) +:8] = rdata_in_bytes[byte_index];
  end

  for (int byte_index=0; byte_index < num_bytes; byte_index++) begin
    `uvm_info(get_name(), $sformatf("debug: bytes_data[%0d] : ['h%0h]",
        byte_index, rdata_in_bytes[byte_index]), UVM_HIGH)
  end

  for (int index=0; index < num_axi_data; index++) begin
    `uvm_info(get_name(), $sformatf("debug: axi_data[%0d] : ['h%0h]",
        index, axi_data[index]), UVM_HIGH)
  end

endtask : fetch_data_from_axi_mem

task sinc_virtual_base_sequence::ramwrap_ecc_error_inj_w_addr(logic [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] inj_address, bit correctable, bit active_state);
  string            debug_str     = "ramwrap_ecc_error_inj_w_addr";
  cache_mem_w_ecc_t inj_data_orig;
  cache_mem_w_ecc_t inj_data;
  cache_mem_w_ecc_t flip_idx;

  wait_n_clks(50);

  m_top_configuration.m_mem_err_inj_event.trigger();

  inj_data_orig = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(inj_address));
  `uvm_info(debug_str, $sformatf("inj_address['h%0h] Original inj_data ['h%0h]", inj_address, inj_data_orig), UVM_LOW)

  if (correctable) begin
    //correctbale error
    if(!active_state) begin
      inj_data = inject_error_1bit_except_parity_bit(inj_data_orig);
    end else begin
      //Inject 1 bit correctable error in LSB 39 bit of 156it error data in active state
      inj_data = inject_error_1bit_in_first_39bit(inj_data_orig);
    end
  end else begin
    // uncorrectable error
    if(!active_state) begin
      inj_data = inject_error_2bit_per_39bit(inj_data_orig, 0);
    end else begin
      //Inject 2 bit correctable error in LSB 39 bit of 156it error data in active state
      inj_data = inject_error_2bit_per_39bit(inj_data_orig, 1);
    end

  end

  `uvm_info(debug_str, $sformatf("Flipped inj_data_orig ['h%0h] inj_data ['h%0h], flip_idx['h%h]", inj_data_orig, inj_data, flip_idx), UVM_LOW)

  m_ramwrap_inj_rand_seq.ramwrap_inj_cache_mem(inj_address, inj_data);

  wait_n_clks(5);
  m_top_configuration.m_mem_err_inj_event.reset();
  wait_n_clks(50);
endtask : ramwrap_ecc_error_inj_w_addr

function cache_mem_w_ecc_t sinc_virtual_base_sequence::inject_error_2bit_per_39bit(cache_mem_w_ecc_t data_in, bit is_1st_39_bit);
  int data_chuck;
  int chunk_start;
  int chunk_end;
  int bit_index1;
  int bit_index2;
  //Each data blk consists of 32b data + 7b parity
  int cpu_data_blk_size =39;

  string            debug_str = "inject_error_1bit_except_parity_bit";
  cache_mem_w_ecc_t data_out;
  data_out = data_in;
  //In RTL 0100, the physical memory is 156 bits, with 4 * 32bits data plus 4 * 7bits ECC. The data_chuck is 4
  if (!(std::randomize(data_chuck) with {data_chuck inside {[0:3]};})) begin
    `uvm_error("RAND", "Could not randomize data_chuck")
  end

  if(is_1st_39_bit) begin
    data_chuck = 0;
  end

  chunk_start = data_chuck * cpu_data_blk_size;
  chunk_end   = chunk_start + (cpu_data_blk_size - 1);

  if (!(std::randomize(bit_index1) with {
          bit_index1 inside {[chunk_start:chunk_end]};
          foreach(PARITY_BIT_LOCATIONS[i]) {{bit_index1 != (chunk_start + PARITY_BIT_LOCATIONS[i])};}
        })) begin
    `uvm_error("RAND", "Could not randomize bit_index1")
  end

  if (!(std::randomize(bit_index2) with {
          bit_index2 inside {[chunk_start:chunk_end]};
          bit_index2 != bit_index1;
          foreach(PARITY_BIT_LOCATIONS[i]) {{ bit_index2 != (chunk_start + PARITY_BIT_LOCATIONS[i])};}
        })) begin
    `uvm_error("RAND", "Could not randomize bit_index2")
  end

  data_out[bit_index1] = data_in[bit_index1] ^ 1'b1; // Flip the first bit
  data_out[bit_index2] = data_in[bit_index2] ^ 1'b1; // Flip the second bit

  `uvm_info(debug_str, $sformatf(": inj_data_orig ['h%0h] inj_data ['h%0h], index1=%0d, index2=%0d, data_chuck='h%h", data_in, data_out, bit_index1 , bit_index2 , data_chuck), UVM_LOW)
  return (data_out);
endfunction : inject_error_2bit_per_39bit

function cache_mem_w_ecc_t sinc_virtual_base_sequence::inject_error_1bit_in_first_39bit(cache_mem_w_ecc_t data_in);
  string debug_str         = "inject_error_1bit_in_first_39bit";
  int    data_chuck;
  int    chunk_start;
  int    chunk_end;
  int    bit_index;
  //Each data blk consists of 32b data + 7b parity
  int    cpu_data_blk_size =39;

  cache_mem_w_ecc_t data_out = data_in;
  //In RTL 0100, the physical memory is 156 bits, with 4 * 32bits data plus 4 * 7bits ECC. The total data_chuck is 4
  data_chuck  = 0; //for first 39 bits
  chunk_start = data_chuck * cpu_data_blk_size;
  chunk_end   = chunk_start + (cpu_data_blk_size - 1);

  if (!(std::randomize(bit_index) with {
          bit_index inside {[chunk_start:chunk_end]};
          foreach(PARITY_BIT_LOCATIONS[i]) {{bit_index != (chunk_start + PARITY_BIT_LOCATIONS[i])};}
        })) begin
    `uvm_error("RAND", "Could not randomize bit_index")
  end

  data_out[bit_index] = data_in[bit_index] ^ 1'b1;
  `uvm_info(debug_str, $sformatf(": inj_data_orig ['h%0h] inj_data ['h%0h] , index=%0d", data_in, data_out, bit_index ), UVM_LOW)
  return (data_out);
endfunction : inject_error_1bit_in_first_39bit

function cache_mem_w_ecc_t sinc_virtual_base_sequence::inject_error_1bit_except_parity_bit(cache_mem_w_ecc_t data_in);
  int data_chuck;
  int chunk_start;
  int chunk_end;
  int bit_index;
  //Each data blk consists of 32b data + 7b parity
  int cpu_data_blk_size =39;

  string            debug_str = "inject_error_1bit_except_parity_bit";
  cache_mem_w_ecc_t data_out;
  data_out = data_in;
  //In RTL 0100, the physical memory is 156 bits, with 4 * 32bits data plus 4 * 7bits ECC. The data_chuck is 4

  if (!(std::randomize(data_chuck) with { data_chuck inside {[0:3]}; })) begin
    `uvm_error("RAND", "Could not randomize data_chuck")
  end
  chunk_start = data_chuck * cpu_data_blk_size;
  chunk_end   = chunk_start + (cpu_data_blk_size - 1);
  if (!(std::randomize(bit_index) with {
          bit_index inside {[chunk_start:chunk_end]};
          foreach(PARITY_BIT_LOCATIONS[i]) {{bit_index != (chunk_start + PARITY_BIT_LOCATIONS[i])};}
        })) begin
    `uvm_error("RAND", "Could not randomize bit_index")
  end

  data_out[bit_index] = data_in[bit_index] ^ 1'b1;
  `uvm_info(debug_str, $sformatf(": inj_data_orig ['h%0h] inj_data ['h%0h] , index=%0d, data_chuck='h%h", data_in, data_out, bit_index , data_chuck), UVM_LOW)
  return (data_out);
endfunction : inject_error_1bit_except_parity_bit

`endif // SINC_VIRTUAL_BASE_SEQUENCE
