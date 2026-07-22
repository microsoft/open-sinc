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
// File        : sinc_random_base_seq.svh
// Description : 

`ifndef SINC_RANDOM_BASE_SEQ
`define SINC_RANDOM_BASE_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_random_base_seq
//------------------------------------------------------------------------------

class sinc_random_base_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_random_base_seq)

  int m_trans_count    =0;
  int m_erase_req_count=0;

  typedef sinc_stimulus_packet sinc_stimulus_packet_t;
  typedef sinc_transaction_packet sinc_transaction_packet_t;

  sinc_stimulus_packet_t    m_stimulus_packet;
  sinc_transaction_packet_t m_transaction_packet;
  rand sinc_mpu_packet      m_mpu_setup_wr_tran;
  sinc_key_t                m_reuse_key_data;
  bit                       m_initial_key_set      = 0;
  bit                       m_disable_constraints_cache_fail = 0;
  bit                       m_mpu_was_setup = 0;

  // count CPU RD transaction
  int m_cpu_rd_cnt = 0;

  function new(string name="sinc_random_base_seq");
    super.new(name);

    process_plusargs_and_populate_seq_item();
  endfunction : new

  extern virtual task sequential_run_body();
  extern virtual task start_erase_optional();
  extern virtual task body();
  extern virtual task random_sequence_body();

  // create stimulus packet
  extern virtual function void create_stimulus_packet_item();
  extern virtual function void randomize_stimulus_packet_item();
  extern virtual function void create_transaction_packet_item();
  extern virtual function void randomize_transaction_packet_item();
  extern virtual task send_packet(int iter_n);
  extern virtual task aes_test_mode(bit pull_status_after_fw_request);
  extern virtual task transition_init();
  extern virtual task transition_active();
  extern virtual task transition_failed();
  extern virtual task setup_mpu();

endclass : sinc_random_base_seq

task sinc_random_base_seq::start_erase_optional();
  string       debug_str        = "start_erase_optional_body";
  logic [31:0] erase_data_value;

  `uvm_info(get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

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

  // set sideband
  m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_set_sideband(m_sys_cfg.m_sinc_mpu_disable, m_sys_cfg.m_sinc_chkpt_spramnx);

endtask : start_erase_optional

task sinc_random_base_seq::sequential_run_body();
  string  debug_str  = "sequential_run_body";
  uvm_reg my_regs[$];
  `uvm_info (get_name(), $sformatf("%s: Inside sinc_random_base_seq, SKIP", debug_str), UVM_LOW)

endtask : sequential_run_body

task sinc_random_base_seq::body();
  super.body();

  test_done();
endtask : body

task sinc_random_base_seq::transition_init();
  string         debug_str = "DV::transition_init";
  uvm_reg_data_t reg_value;
  uvm_reg_data_t my_data;
  bit            timeout;

  // transition to init
  set_up_fw_operation(SINC_SET_INIT_STATE, 1);
  reg_value                                    = 32'h0;
  reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.set_init_state.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);
  pull_status(my_data, timeout);
  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)
  end
  // m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
endtask : transition_init

task sinc_random_base_seq::transition_failed();
  string         debug_str = "DV::transition_failed";
  uvm_reg_data_t reg_value;
  uvm_reg_data_t my_data;
  bit            timeout;

  // transition to init
  set_up_fw_operation(SINC_SET_INIT_STATE, 1);
  m_sys_cfg.m_pal_slv_err_injector.inject_error(.error(SLVERR), .start_addr(sinc_parameters_pkg::SINC_KSU_START_ADDR), .end_addr(sinc_parameters_pkg::SINC_KSU_END_ADDR), .err_read_write(READ_ONLY), .count(1), .chance(100));
  reg_value                                    = 32'h0;
  reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.set_init_state.get_name(), reg_value[`SINC_REGS_CMD_SET_INIT_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);
  pull_status(my_data, timeout);
  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)
  end
  // m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
endtask : transition_failed

task sinc_random_base_seq::transition_active();
  string         debug_str = "DV::transition_active";
  uvm_reg_data_t reg_value;
  uvm_reg_data_t my_data;
  bit            timeout;

  // transition to init
  set_up_fw_operation(SINC_SET_CACHE_ACTIVE_STATE, 1);
  reg_value                                            = 32'h0;
  reg_value[`SINC_REGS_CMD_SET_CACHE_ACTIVE_STATE_MSB] = 1;
  `uvm_info(get_name(), $sformatf("Set %s: [%0d]", m_regmodel.cmd.set_cache_active_state.get_name(), reg_value[`SINC_REGS_CMD_SET_CACHE_ACTIVE_STATE_MSB]), UVM_HIGH)
  write_reg_value(m_regmodel.cmd, reg_value);
  pull_status(my_data, timeout);
  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)
  end
  // m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;
endtask : transition_active

task sinc_random_base_seq::random_sequence_body();
  string debug_str = "DV::random_sequence_start";

  m_num_trans = m_sys_cfg.m_sinc_tb_seq_trans_num; // 200;

  `uvm_info (get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

  if(m_sys_cfg.m_sinc_tb_seq_dis_encr_auth_check) begin
    m_sys_cfg.m_sinc_vif.set_disable_encr_auth_check(1);
  end

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
      3: begin
        transition_failed();
      end
      default : begin /*empty*/

      end
    endcase
  end

  //do bunch of mpu attr writes at beginning and not later for some cases
  if(m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read && m_sys_cfg.m_sinc_tb_seq_always_en_back_2_back) begin
    setup_mpu();
  end

  // repeat (m_num_trans) begin
  for ( int iter_n = 0; iter_n < m_num_trans ; iter_n++) begin
    create_stimulus_packet_item();
    randomize_stimulus_packet_item();
    create_transaction_packet_item();
    randomize_transaction_packet_item();
    send_packet(iter_n);
    // erase request can take a long time, limit the test run time by limiting the number of erase transactions
    if (m_erase_req_count == 30) begin
      m_num_trans = 40;
    end
  end
  
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

task sinc_random_base_seq::setup_mpu();
  string debug_str = "setup_mpu";
  int reg_number;
  logic [1:0] mpu_resp;

  `uvm_info (get_name(), $sformatf("%s: Setting up mpu early", debug_str), UVM_LOW)

  for ( int iter_n = 0; iter_n < 30 ; iter_n++) begin
    m_mpu_setup_wr_tran            = sinc_mpu_packet::type_id::create("m_mpu_setup_wr_tran");
    m_mpu_setup_wr_tran.m_is_write = 1;
    if (!m_mpu_setup_wr_tran.randomize() with {
      m_mpu_cmd == SINC_MPU_ATTR_WRITE;
    }) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end
    reg_number = m_mpu_setup_wr_tran.m_page_num / 8;
    m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr     (m_mpu_setup_wr_tran.m_is_trn_user_reg),
                                                       .target_privilege_attr(m_mpu_setup_wr_tran.m_is_trn_priv_reg),
                                                       .attr_offset          (reg_number                           ),
                                                       .write_data           (m_mpu_setup_wr_tran.m_write_data     ),
                                                       .resp(mpu_resp));

    `uvm_info (get_name(), $sformatf("%s: MPU Attr Write Data['h%0h], Write Resp['h%0h]", debug_str, m_mpu_setup_wr_tran.m_write_data, mpu_resp), UVM_HIGH)
  end

  m_mpu_was_setup = 1;
endtask : setup_mpu

function void sinc_random_base_seq::create_stimulus_packet_item();
  string debug_str = "create_stimulus_packet_item";

  m_stimulus_packet = sinc_stimulus_packet_t::type_id::create("m_stimulus_packet", , get_full_name());
endfunction : create_stimulus_packet_item

function void sinc_random_base_seq::create_transaction_packet_item();
  string debug_str = "create_transaction_packet_item";

  m_transaction_packet                           = sinc_transaction_packet_t::type_id::create("m_transaction_packet", , get_full_name());
  m_transaction_packet.m_axi_rd_tran.m_regmodel  = m_regmodel;
  m_transaction_packet.m_axi_wr_tran.m_regmodel  = m_regmodel;
  m_transaction_packet.m_axi_wr_tran2.m_regmodel = m_regmodel;

endfunction : create_transaction_packet_item

function void sinc_random_base_seq::randomize_stimulus_packet_item();
  string debug_str      = "randomize_stimulus_packet_item";
  bit    is_mpu_allowed;

  if (!m_stimulus_packet.randomize() with {
        // yaml config can be used to control specific stimulus sequence
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
      end  

  `uvm_info(get_name(), $sformatf("%s: stimulus_packet_item randomized \n", debug_str), UVM_LOW)
  m_stimulus_packet.print_packet(m_trans_count);

endfunction : randomize_stimulus_packet_item

function void sinc_random_base_seq::randomize_transaction_packet_item();
  string debug_str       = "randomize_transaction_packet_item";
  bit    is_mpu_allowed;
  bit    r_acc_vio;
  bit    r_accvio_ex;
  bit    r_accvio_rd;
  bit    r_accvio_wr;
  int    num_rerandomize;

  // make sure each stimulus has correct preset on rand_mode
  m_transaction_packet.m_axi_rd_tran.rand_mode(1);
  m_transaction_packet.m_axi_wr_tran.rand_mode(1);
  m_transaction_packet.m_axi_wr_tran2.rand_mode(0);
  m_transaction_packet.m_cpu_rd_tran.m_num_trans = m_cpu_rd_cnt;
  m_transaction_packet.m_cpu_rd_tran.rand_mode(1);
  m_transaction_packet.m_cpu_wr_tran.rand_mode(1);
  m_transaction_packet.m_mpu_rd_tran.rand_mode(1);
  m_transaction_packet.m_mpu_wr_tran.rand_mode(1);

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD]) begin
    m_transaction_packet.m_axi_rd_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable axi_rd_tran random mode \n", debug_str), UVM_LOW)
  end

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR]) begin
    m_transaction_packet.m_axi_wr_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable axi_wr_tran random mode \n", debug_str), UVM_LOW)
  end

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD]) begin
    m_transaction_packet.m_cpu_rd_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable cpu_rd_tran random mode \n", debug_str), UVM_LOW)
  end

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
    m_transaction_packet.m_cpu_wr_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable cpu_wr_tran random mode \n", debug_str), UVM_LOW)
  end

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD]) begin
    m_transaction_packet.m_mpu_rd_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable mpu_rd_tran random mode \n", debug_str), UVM_LOW)
  end

  if (!m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR]) begin
    m_transaction_packet.m_mpu_wr_tran.rand_mode(0);
    `uvm_info(get_name(), $sformatf("%s: Disable mpu_wr_tran random mode \n", debug_str), UVM_LOW)
  end

  if(m_disable_constraints_cache_fail) begin
    m_transaction_packet.m_axi_wr_tran.valid_fw_cmd_c.constraint_mode(0);
    m_transaction_packet.m_axi_wr_tran.wr_dst_reg_c.constraint_mode(0);
  end

  if(m_stimulus_packet.m_do_cmu_busy) begin
    if(m_stimulus_packet.m_two_axi_wr) begin
      m_transaction_packet.m_axi_wr_tran2.rand_mode(1);
    end

    if (!m_transaction_packet.randomize() with {
          m_transaction_packet.m_axi_wr_tran.m_do_fw_request == 1;
          m_transaction_packet.m_axi_wr_tran.m_fw_cmd != SINC_AES_TEST_EN;
        }) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize with do_cmu_busy failed!!!", debug_str))
    end
  end else begin
    if (!m_transaction_packet.randomize() with {
          // yaml config can be used to control specific transaction sequence
        }) begin
      `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
    end
  end

  //rerandomize cpu address if mpu would block
  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD]) begin
    //check if address is valid for mpu
    num_rerandomize = 0;
    while((num_rerandomize < 25) && (m_mpu_cfg.is_mpu_allowed(.we(0), .loadstore(m_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore), .accsrc(0),
            .priv_mode(m_transaction_packet.m_cpu_rd_tran.m_cpu_privmode),
            .addr(m_transaction_packet.m_cpu_rd_tran.m_cpu_addr), .r_acc_vio(r_acc_vio),
            .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr)) == 0)) begin
      if( !std::randomize(m_transaction_packet.m_cpu_rd_tran.m_cpu_addr) with {
            if(m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) {
              m_transaction_packet.m_cpu_rd_tran.m_cpu_addr inside {[0:'h3FFFFF]};
            } else {
              m_transaction_packet.m_cpu_rd_tran.m_cpu_addr inside {[0:'hFFFF]};
            }
          }) begin
        `uvm_fatal("RAND", "std::randomize failed to randomize m_transaction_packet.cpu_rd_tran.cpu_addr")

      end
      num_rerandomize = num_rerandomize + 1;
    end
    // report error if not able to find a MPU page, stop report when spramnx is set high due to any ex transaction will be rejected
    if((num_rerandomize >= 25) && (!m_top_configuration.m_sinc_vif.sinc_chkpt_spramnx)) begin
      m_transaction_packet.m_cpu_rd_tran.print_packet();
      `uvm_error(get_name(), $sformatf("%s: Unable to find cpu add which mpu allows read please debug\n", debug_str))
    end

    // counting CPU RD transaction
    m_cpu_rd_cnt++;
  end

  if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
    //check if address is valid for mpu, writes never allowed in cache active so no need check in that case
    if(m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) begin
      num_rerandomize = 0;
      while((num_rerandomize < 25) &&
          ( m_mpu_cfg.is_mpu_allowed(.we(1), .loadstore(m_transaction_packet.m_cpu_wr_tran.m_cpu_loadstore),
              .accsrc(0), .priv_mode(m_transaction_packet.m_cpu_wr_tran.m_cpu_privmode),
              .addr(m_transaction_packet.m_cpu_wr_tran.m_cpu_addr), .r_acc_vio(r_acc_vio),
              .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd),
              .r_accvio_wr(r_accvio_wr)) == 0)) begin
        if(!std::randomize(m_transaction_packet.m_cpu_wr_tran.m_cpu_addr) with {
              m_transaction_packet.m_cpu_wr_tran.m_cpu_addr inside {[0:'hFFFF]};}) begin
          `uvm_fatal("RAND", "std::randomize failed to randomize 'm_transaction_packet.cpu_wr_tran.cpu_addr'")
        end
        num_rerandomize = num_rerandomize + 1;
      end
      if(num_rerandomize >= 25) begin
        m_transaction_packet.m_cpu_wr_tran.print_packet();
        `uvm_error(get_name(), $sformatf("%s: Unable to find cpu add which mpu allows write please debug\n", debug_str))
      end
    end
  end

  `uvm_info(get_name(), $sformatf("%s: transaction_packet_item randomized \n", debug_str), UVM_LOW)

  m_transaction_packet.print_stimulus_packet(m_trans_count, m_stimulus_packet.m_stimulus_sel);

endfunction : randomize_transaction_packet_item

//---------------------------
// send_packet ()
//---------------------------
task sinc_random_base_seq::send_packet (int iter_n);
  string debug_str               = "send_packet";
  bit    concurrent_stimulus_set = 0;

  //randomize dis encr auth check if param is set
  if(m_sys_cfg.m_sinc_tb_seq_rand_encr_auth_check) begin
    bit dis_auth_check;
    if(!std::randomize(dis_auth_check)) begin
      `uvm_fatal("RAND", "std::randomize failed to randomize dis_auth_check")
    end
    m_sys_cfg.m_sinc_vif.set_disable_encr_auth_check(dis_auth_check);
  end

  if ($countones(m_stimulus_packet.m_stimulus_sel) > 1) begin
    concurrent_stimulus_set = 1;
  end

  `uvm_info(get_name(), $sformatf("\nSend SINC Packet [%0d], concurrent_stimulus_set[%0d], stimulus_sel['h%0h], axi_rd[%0d], axi_wr[%0d], cpu_rd[%0d], cpu_wr[%0d], mpu_rd[%0d], mpu_wr[%0d], erase_mem[%0d]",
      iter_n, concurrent_stimulus_set, m_stimulus_packet.m_stimulus_sel, m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR], m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM]), UVM_NONE)

  //Send transactions depends on stimulus packet
  fork : transaction_fork
    begin : axi_rd
      bit timeout;
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD]) begin
        // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
        if(m_stimulus_packet.m_wait_for_erase) begin
          wait_erase_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[axi_rd] finished wait_erase_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_axi_rd_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cmu_busy) begin
          wait_cmu_busy_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[axi_rd] finished wait_cmu_busy_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_axi_rd_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cpu) begin
          wait_cpu_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[axi_rd] finished wait_cpu_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_axi_rd_pre_delay);
        end
        m_axi_mst_seq.sinc_axi_read_access_with (.addr(m_transaction_packet.m_axi_rd_tran.m_addr), .read_data(m_transaction_packet.m_axi_rd_tran.m_read_data), .burst_length(m_transaction_packet.m_axi_rd_tran.m_burst_length), .id(m_transaction_packet.m_axi_rd_tran.m_id), .response(m_transaction_packet.m_axi_rd_tran.m_response), .burst_size(m_transaction_packet.m_axi_rd_tran.m_burst_size),
          .prot(m_transaction_packet.m_axi_rd_tran.m_prot), .aruser(m_transaction_packet.m_axi_rd_tran.m_axuser), .lock(m_transaction_packet.m_axi_rd_tran.m_lock), .cache(m_transaction_packet.m_axi_rd_tran.m_cache), .burst_type(m_transaction_packet.m_axi_rd_tran.m_burst_type));
      end
    end : axi_rd

    begin : axi_wr
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR]) begin
        uvm_reg_data_t my_data;
        bit timeout;

        // wait_n_clks(m_transaction_packet.axi_wr_tran.pre_delay);
        if(m_stimulus_packet.m_wait_for_erase) begin
          wait_erase_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[axi_wr] finished wait_erase_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_axi_wr_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cpu) begin
          wait_cpu_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[axi_wr] finished wait_cpu_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_axi_wr_pre_delay);
        end

        // set up firmware command, for example fw_compare command needs to program COMP_BUFFER registers before start command
        if ((m_transaction_packet.m_axi_wr_tran.m_do_fw_request == 1) && (m_sys_cfg.m_skip_fw_cmd == 0)) begin

          //todo need to finish implementing this function in virtual base sequence
          set_up_fw_operation(m_transaction_packet.m_axi_wr_tran.m_fw_cmd,
            m_transaction_packet.m_axi_wr_tran.m_is_valid_req);

          //skip write for aes test en since do more elaborate sequence in aes_test_mode() task
          if((m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_AES_TEST_EN) && (m_sys_cfg.m_cur_cache_state == CACHE_DISABLE_STATE)) begin
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

          // fixme-hw: some of below code will be removed after scoreboard and monitor in place
          //for now update state based on command type
          //may need to keep clearing initial_key_set bit for aes test mode upon sinc reset if sb doesn't track that
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SET_INIT_STATE) begin
            // m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SET_CACHE_ACTIVE_STATE) begin
            // m_sys_cfg.m_cur_cache_state = CACHE_ACTIVE_STATE;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SINC_RESET) begin
            // m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;
            m_initial_key_set = 0;
          end
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_SINC_REINIT) begin
            // m_sys_cfg.m_cur_cache_state = CACHE_INIT_STATE;
          end

          //look for disable commands and set cfg
          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_DISABLE_RESET) begin
            // m_sys_cfg.m_sinc_reset_disabled = 1;
          end

          if(m_transaction_packet.m_axi_wr_tran.m_fw_cmd == SINC_DISABLE_REINIT) begin
            // m_sys_cfg.m_sinc_reinit_disabled = 1;
          end
        end

        //do write as long as skip fw cmd is 0 or it isn't a fw request
        if((m_sys_cfg.m_skip_fw_cmd == 0) || (m_transaction_packet.m_axi_wr_tran.m_do_fw_request == 0)) begin

          m_axi_mst_seq.sinc_axi_write_access_with (.addr(m_transaction_packet.m_axi_wr_tran.m_addr), .write_data(m_transaction_packet.m_axi_wr_tran.m_write_data), .wstrb(m_transaction_packet.m_axi_wr_tran.m_wstrb), .burst_length(m_transaction_packet.m_axi_wr_tran.m_burst_length), .id(m_transaction_packet.m_axi_wr_tran.m_id), .response(m_transaction_packet.m_axi_wr_tran.m_response), .burst_size(m_transaction_packet.m_axi_wr_tran.m_burst_size),
            .prot(m_transaction_packet.m_axi_wr_tran.m_prot), .awuser(m_transaction_packet.m_axi_wr_tran.m_axuser), .lock(m_transaction_packet.m_axi_wr_tran.m_lock), .cache(m_transaction_packet.m_axi_wr_tran.m_cache), .burst_type(m_transaction_packet.m_axi_wr_tran.m_burst_type));

          if (m_transaction_packet.m_axi_wr_tran.m_do_fw_request && m_transaction_packet.m_axi_wr_tran.m_pull_status_after_fw_request) begin

            //handle case where we try to do an axi write while cmu busy
            if(m_stimulus_packet.m_wait_for_cmu_busy && m_stimulus_packet.m_two_axi_wr) begin
              wait_cmu_busy_trn(timeout);
              `uvm_info(get_name(), $sformatf("%s:[axi_wr] finished wait_cmu_busy_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
              if(timeout == 0) begin
                wait_n_clks(m_stimulus_packet.m_axi_wr_pre_delay);
                m_axi_mst_seq.sinc_axi_write_access_with (.addr(m_transaction_packet.m_axi_wr_tran2.m_addr), .write_data(m_transaction_packet.m_axi_wr_tran2.m_write_data), .wstrb(m_transaction_packet.m_axi_wr_tran2.m_wstrb), .burst_length(m_transaction_packet.m_axi_wr_tran2.m_burst_length), .id(m_transaction_packet.m_axi_wr_tran2.m_id), .response(m_transaction_packet.m_axi_wr_tran2.m_response), .burst_size(m_transaction_packet.m_axi_wr_tran2.m_burst_size),
                  .prot(m_transaction_packet.m_axi_wr_tran2.m_prot), .awuser(m_transaction_packet.m_axi_wr_tran2.m_axuser), .lock(m_transaction_packet.m_axi_wr_tran2.m_lock), .cache(m_transaction_packet.m_axi_wr_tran2.m_cache), .burst_type(m_transaction_packet.m_axi_wr_tran2.m_burst_type));
              end
            end

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
        bit timeout;

        // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
        if(m_stimulus_packet.m_wait_for_erase) begin
          wait_erase_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[cpu_rd] finished wait_erase_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_cpu_rd_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cmu_busy) begin
          wait_cmu_busy_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[cpu_rd] finished wait_cmu_busy_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          // wait_n_clks(m_stimulus_packet.cpu_rd_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_axi_sub) begin
          wait_sub_axi_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[cpu_rd] finished wait_for_axi_sub with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_cpu_rd_pre_delay);
        end

        if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
          `uvm_info (get_name(), $sformatf("%s: Issue NON Blocking CPU Read addr['h%0h]", debug_str, m_transaction_packet.m_cpu_rd_tran.m_cpu_addr), UVM_LOW)
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read(.addr(m_transaction_packet.m_cpu_rd_tran.m_cpu_addr), 
                                                           .loadstore(m_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore), 
                                                           .privmode(m_transaction_packet.m_cpu_rd_tran.m_cpu_privmode));
        end else begin
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read( .addr     (m_transaction_packet.m_cpu_rd_tran.m_cpu_addr     ),
                                                         .loadstore(m_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore),
                                                         .privmode (m_transaction_packet.m_cpu_rd_tran.m_cpu_privmode ),
                                                         .read_data(m_transaction_packet.m_cpu_rd_tran.m_cpu_read_data));
          `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, m_transaction_packet.m_cpu_rd_tran.m_cpu_addr, m_transaction_packet.m_cpu_rd_tran.m_cpu_read_data), UVM_LOW)


        end // else: !if(m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read)

	if (m_stimulus_packet.m_wait_for_erase) begin
          sinc_transaction_packet_t m_repeat_transaction_packet;
          int packet_delay;
          bit is_read;
          repeat (m_stimulus_packet.m_repeat_cpu_req_cnt) begin
            m_repeat_transaction_packet  = sinc_transaction_packet_t::type_id::create("m_repeat_transaction_packet", , get_full_name());
            m_repeat_transaction_packet.m_axi_rd_tran.m_regmodel  = m_regmodel;
            m_repeat_transaction_packet.m_axi_wr_tran.m_regmodel  = m_regmodel;
            m_repeat_transaction_packet.m_axi_wr_tran2.m_regmodel = m_regmodel;
            m_repeat_transaction_packet.m_cpu_rd_tran.m_num_trans = m_cpu_rd_cnt;
            m_repeat_transaction_packet.m_axi_rd_tran.rand_mode(0);
            m_repeat_transaction_packet.m_axi_wr_tran.rand_mode(0);
            m_repeat_transaction_packet.m_cpu_rd_tran.rand_mode(1);
            m_repeat_transaction_packet.m_cpu_wr_tran.rand_mode(1);
            m_repeat_transaction_packet.m_mpu_rd_tran.rand_mode(0);
            m_repeat_transaction_packet.m_mpu_wr_tran.rand_mode(0);
            if (!m_repeat_transaction_packet.randomize() with {
              // yaml config can be used to control specific transaction sequence
            }) begin
              `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
            end

            if(!std::randomize(packet_delay) with { 
	      packet_delay dist { 0:/90, [1:20]:/10};
	    }) begin
              `uvm_fatal("RAND", "std::randomize failed to randomize 'packet_delay'")
            end

            if(!std::randomize(is_read) with { 
              is_read dist { 0:/20, 1:/80};
            }) begin
              `uvm_fatal("RAND", "std::randomize failed to randomize 'is_read'")
            end

            if (is_read) begin
              m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read(.addr(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_addr), 
                           .loadstore(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore), 
                           .privmode(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_privmode));
              
            end else begin
              m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write( .addr      (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_addr      ),
                       .loadstore (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_loadstore ),
                       .privmode  (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_privmode  ),
                       .write_data(m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_write_data),
                       .we(m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_we));
            end
            wait_n_clks(packet_delay);
          end // repeat (m_stimulus_packet.m_repeat_cpu_req_cnt)
        end // if (m_stimulus_packet.m_wait_for_erase)

      end
    end : cpu_rd

    begin : cpu_wr
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
        bit timeout;

        //don't do cpu writes in cache active state since not allowed
        if((m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) || (m_sys_cfg.m_allow_writes_cache_active == 1)) begin
          // wait_n_clks(m_transaction_packet.axi_rd_tran.pre_delay);
          if(m_stimulus_packet.m_wait_for_erase) begin
            wait_erase_trn(timeout);
            `uvm_info(get_name(), $sformatf("%s:[cpu_wr] finished wait_erase_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
            wait_n_clks(m_stimulus_packet.m_cpu_wr_pre_delay);
          end
          if(m_stimulus_packet.m_wait_for_cmu_busy) begin
            wait_cmu_busy_trn(timeout);
            `uvm_info(get_name(), $sformatf("%s:[cpu_wr] finished wait_cmu_busy_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
            wait_n_clks(m_stimulus_packet.m_cpu_wr_pre_delay);
          end
          if(m_stimulus_packet.m_wait_for_axi_sub) begin
            wait_sub_axi_trn(timeout);
            `uvm_info(get_name(), $sformatf("%s:[cpu_wr] finished wait_for_axi_sub with timeout(%0d)", debug_str, timeout), UVM_LOW)
            wait_n_clks(m_stimulus_packet.m_cpu_wr_pre_delay);
          end
          m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write( .addr      (m_transaction_packet.m_cpu_wr_tran.m_cpu_addr      ),
                                                          .loadstore (m_transaction_packet.m_cpu_wr_tran.m_cpu_loadstore ),
                                                          .privmode  (m_transaction_packet.m_cpu_wr_tran.m_cpu_privmode  ),
                                                          .write_data(m_transaction_packet.m_cpu_wr_tran.m_cpu_write_data),
            .we(m_transaction_packet.m_cpu_wr_tran.m_cpu_we));
          `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, m_transaction_packet.m_cpu_wr_tran.m_cpu_addr, m_transaction_packet.m_cpu_wr_tran.m_cpu_write_data), UVM_LOW)

	  if (m_stimulus_packet.m_wait_for_erase) begin
            sinc_transaction_packet_t m_repeat_transaction_packet;
            int packet_delay;
            bit is_read;
            repeat (m_stimulus_packet.m_repeat_cpu_req_cnt) begin
              m_repeat_transaction_packet  = sinc_transaction_packet_t::type_id::create("m_repeat_transaction_packet", , get_full_name());
              m_repeat_transaction_packet.m_axi_rd_tran.m_regmodel  = m_regmodel;
              m_repeat_transaction_packet.m_axi_wr_tran.m_regmodel  = m_regmodel;
              m_repeat_transaction_packet.m_axi_wr_tran2.m_regmodel = m_regmodel;
              m_repeat_transaction_packet.m_cpu_rd_tran.m_num_trans = m_cpu_rd_cnt;
              m_repeat_transaction_packet.m_axi_rd_tran.rand_mode(0);
              m_repeat_transaction_packet.m_axi_wr_tran.rand_mode(0);
              m_repeat_transaction_packet.m_cpu_rd_tran.rand_mode(1);
              m_repeat_transaction_packet.m_cpu_wr_tran.rand_mode(1);
              m_repeat_transaction_packet.m_mpu_rd_tran.rand_mode(0);
              m_repeat_transaction_packet.m_mpu_wr_tran.rand_mode(0);
              if (!m_repeat_transaction_packet.randomize() with {
                // yaml config can be used to control specific transaction sequence
              }) begin
                `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
              end

              if(!std::randomize(packet_delay) with { packet_delay dist { 0:/90, [1:20]:/10};}) begin
                `uvm_fatal("RAND", "std::randomize failed to randomize 'packet_delay'")
              end

              if(!std::randomize(is_read) with { 
                is_read dist { 0:/80, 1:/20};
              }) begin
                `uvm_fatal("RAND", "std::randomize failed to randomize 'is_read'")
              end

              if (is_read) begin
                m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_nb_read(.addr(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_addr), 
                             .loadstore(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_loadstore), 
                             .privmode(m_repeat_transaction_packet.m_cpu_rd_tran.m_cpu_privmode));
                
              end else begin
                m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write( .addr      (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_addr      ),
                         .loadstore (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_loadstore ),
                         .privmode  (m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_privmode  ),
                         .write_data(m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_write_data),
                         .we(m_repeat_transaction_packet.m_cpu_wr_tran.m_cpu_we));
              end
              wait_n_clks(packet_delay);
            end // repeat (m_stimulus_packet.m_repeat_cpu_req_cnt)
          end // if (m_stimulus_packet.m_wait_for_erase)
          // m_sys_cfg.m_allow_writes_cache_active=0;
        end else begin
          `uvm_info (get_name(), $sformatf("SKIP CPU Write in CACHE_ACTIVE_STATE"), UVM_LOW)
        end
      end
    end : cpu_wr

    begin : mpu_rd
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD]) begin
        int reg_number = m_transaction_packet.m_mpu_rd_tran.m_page_num / 8;
        logic [1:0] mpu_resp;
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
        int reg_number = m_transaction_packet.m_mpu_wr_tran.m_page_num / 8;
        logic [1:0] mpu_resp;
        if (concurrent_stimulus_set) begin
          wait_n_clks(m_stimulus_packet.m_mpu_wr_pre_delay);
        end
        if(m_transaction_packet.m_mpu_wr_tran.m_do_generic_access == 1) begin
          m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_generic_write(.addr_offset(m_transaction_packet.m_mpu_wr_tran.m_addr      ),
                                                           .write_data (m_transaction_packet.m_mpu_wr_tran.m_write_data),
                                                           .resp(mpu_resp));
          `uvm_info (get_name(), $sformatf("%s: MPU Generic Write Data['h%0h], Write Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_wr_tran.m_write_data, mpu_resp), UVM_HIGH)
        end else if(m_transaction_packet.m_mpu_wr_tran.m_mpu_cmd == SINC_MPU_ATTR_WRITE) begin
          //skip mpu attr writes if we already set it up at the beginning
          if(m_mpu_was_setup == 0) begin
            m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_attr_line_write(.target_user_attr     (m_transaction_packet.m_mpu_wr_tran.m_is_trn_user_reg),
                                                              .target_privilege_attr(m_transaction_packet.m_mpu_wr_tran.m_is_trn_priv_reg),
                                                              .attr_offset          (reg_number                                          ),
                                                              .write_data           (m_transaction_packet.m_mpu_wr_tran.m_write_data     ),
                                                              .resp(mpu_resp));

            `uvm_info (get_name(), $sformatf("%s: MPU Attr Write Data['h%0h], Write Resp['h%0h]", debug_str, m_transaction_packet.m_mpu_wr_tran.m_write_data, mpu_resp), UVM_HIGH)
          end
        end else if(m_transaction_packet.m_mpu_wr_tran.m_mpu_cmd == SINC_MPU_STATUS_WRITE) begin
          // Prevent concurrent MPU status write and CPU access
          if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
            wait_n_clks(5);
            `uvm_info (get_name(), $sformatf("%s: SKIP MPU Status Write when m_sinc_tb_seq_use_non_blocking_cpu_read['h%0h]", debug_str, m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read), UVM_HIGH)
          end else begin
            m_mpu_rand_seq.m_mpu_seq.ccpui_mpu_status_writeclear(mpu_resp);
            `uvm_info (get_name(), $sformatf("%s: MPU Status Write Clear Resp['h%0h]", debug_str, mpu_resp), UVM_HIGH)
          end          

        end else begin
          `uvm_error (get_name(), $sformatf("%s: MPU CMD[%0s] is not valid type for MPU MEM WR stimulus]", debug_str, m_transaction_packet.m_mpu_wr_tran.m_mpu_cmd.name()))
        end
      end
    end : mpu_wr

    begin : erase_mem
      bit timeout;
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM]) begin
        // wait_n_clks(m_transaction_packet.erase_mem_pre_delay);
        if(m_stimulus_packet.m_wait_for_axi_sub) begin
          wait_sub_axi_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[erase_mem] finished wait_for_axi_sub with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_erase_mem_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cmu_busy) begin
          wait_cmu_busy_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[erase_mem] finished wait_cmu_busy_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_erase_mem_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_cpu) begin
          wait_cpu_trn(timeout);
          `uvm_info(get_name(), $sformatf("%s:[erase_mem] finished wait_cpu_trn with timeout(%0d)", debug_str, timeout), UVM_LOW)
          wait_n_clks(m_stimulus_packet.m_erase_mem_pre_delay);
        end
        if(m_stimulus_packet.m_wait_for_w_cache) begin
          bit     success = 0;
          wait_w_cache(timeout, success);
          `uvm_info(get_name(), $sformatf("%s:[erase_mem] finished wait_w_cache with timeout(%0d), success(%0d)", debug_str, timeout, success), UVM_LOW)
          if (!timeout && success) begin
            m_erase_rand_seq.erase_cache();
            m_erase_req_count++;
          end
        end else begin
           m_erase_rand_seq.erase_cache();
           m_erase_req_count++;
        end
      end
    end : erase_mem

    begin : reset_dut
      if (m_stimulus_packet.m_stimulus_sel[`SINC_STIMULUS_SEL_HW_RESET]) begin
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
            wait(m_top_configuration.m_sinc_vif.resetn === 1'b0);
            wait(m_top_configuration.m_sinc_vif.resetn === 1'b1);
          end
        join

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


        m_sys_cfg.m_nonce0_is_set            =0;
        m_sys_cfg.m_nonce1_is_set            =0;
        m_sys_cfg.m_nonce2_is_set            =0;
        m_sys_cfg.m_key_slot_is_set          =0;
        m_sys_cfg.m_sinc_reset_disabled      = 0;
        m_sys_cfg.m_sinc_reinit_disabled     = 0;
        m_sys_cfg.m_ext_block_base_is_set    = 0;
        m_sys_cfg.m_ext_auth_tag_base_is_set = 0;
        m_sys_cfg.m_block_encr_addr_is_set   = 0;
        // m_sys_cfg.m_cur_cache_state = CACHE_DISABLE_STATE;
        m_initial_key_set                    = 0;

      end
    end : reset_dut

  join

  `uvm_info(get_name(), $sformatf("\nSend SINC Packet Done[%0d]", iter_n), UVM_HIGH)
  m_trans_count++;
endtask : send_packet// send_packet

task sinc_random_base_seq::aes_test_mode(bit pull_status_after_fw_request);
  string          debug_str         = "aes_test_mode";
  sinc_aes_packet aes_pkt;
  uvm_reg_data_t  my_data;
  bit             timeout;
  int             num_data_segments;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  aes_pkt                 = sinc_aes_packet::type_id::create("m_aes_pkt", , get_full_name());
  aes_pkt.m_aes_test_mode = 1;
  if(m_initial_key_set == 1) begin
    aes_pkt.m_reuse_key_data = m_reuse_key_data;
  end

  if (!aes_pkt.randomize() with {
        if(m_initial_key_set == 0) {
          m_reuse_key == 0;
        }
        //use different key than non aes test mode
        m_key_slot != m_sys_cfg.m_aes_cfg.m_key_slot;
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end
  `uvm_info (get_name(), $sformatf("RAND_INFO: aes_op: [%0s] aes_mode: [%0s] reuse_key: [%0d] byte_count: [%0d]", aes_pkt.m_aes_op.name(), aes_pkt.m_aes_mode.name(), aes_pkt.m_reuse_key, aes_pkt.m_byte_count), UVM_LOW)

  aes_pkt.print_packet();
  aes_pkt.cal_rslt_w_c_model();
  if(aes_pkt.m_reuse_key == 0) begin
    m_reuse_key_data  = aes_pkt.m_key_data;
    m_initial_key_set = 1;
  end

  // preload key data
  `uvm_info (get_name(), $sformatf("%s: do backdoor key load", debug_str), UVM_LOW)
  load_key_to_axi_mem(aes_pkt.m_key_axi_addr, aes_pkt.m_key_data);

  // 1. FW sets aes_test_en field to 1 in cmd register to enter AES test mode.
  aes_test_enable();
  `uvm_info (get_name(), $sformatf("%s: enable test mode", debug_str), UVM_LOW)

  // 2. FW loads block_encr_key and aes_iv_nonce* registers.
  aes_load_key_iv_nonce(aes_pkt.m_aes_iv_nonce_regs[0], aes_pkt.m_aes_iv_nonce_regs[1], aes_pkt.m_aes_iv_nonce_regs[2], aes_pkt.m_key_slot);
  `uvm_info (get_name(), $sformatf("%s: set aes_iv_nonce_* registers", debug_str), UVM_LOW)

  // 3. FW waits for cfg_key_iv_rdy = 1 in aes_test_status register.
  wait_aes_status(.cfg_key_iv_rdy(1), .data_in_rdy(0), .data_out_vld(0), .tag_out(0), .timeout(timeout));
  `uvm_info (get_name(), $sformatf("%s: wait till cfg_key_iv_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

  if(timeout) begin
    if (!m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
      `uvm_error(get_name(), $sformatf("wait_aes_status never saw cfg_key_iv_rdy go high"))
    end
    aes_test_disable();
    return;
  end

  // 4. FW loads mode, dir, key_len fields, set cfg_key_iv_vld = 1, and data_in_vld = 0 in the aes_test_ctrl register. FW can additionally set reuse_key = 1 if it wants to reuse previously loaded key.
  // aes_load_ctrl_mode_dir_keylen(.mode(sinc_parameters_pkg::GCM), .dir(sinc_parameters_pkg::ENCRYPT), .key_len(2), .reuse_key(0));
  aes_load_ctrl_mode_dir_keylen(.mode(aes_pkt.m_aes_mode), .dir(aes_pkt.m_aes_op), .key_len(2), .reuse_key(aes_pkt.m_reuse_key));
  `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_mode_dir_keylen", debug_str), UVM_LOW)

  num_data_segments = aes_pkt.m_byte_count / 16;
  for (int data_segment_num = 0; data_segment_num < num_data_segments; data_segment_num++) begin

    // 5. FW loads aes_test_data_in* registers.
    // aes_load_test_data_in(aes_test_data_in_0, aes_test_data_in_1, aes_test_data_in_2, aes_test_data_in_3);
    aes_load_test_data_in(aes_pkt.m_aes_message[0 + (data_segment_num * 4)], aes_pkt.m_aes_message[1 + (data_segment_num * 4)], aes_pkt.m_aes_message[2 + (data_segment_num * 4)], aes_pkt.m_aes_message[3 + (data_segment_num * 4)]);

    `uvm_info (get_name(), $sformatf("%s: set aes_load_test_data_in", debug_str), UVM_LOW)

    // 6. FW waits for data_in_rdy = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(1), .data_out_vld(0), .tag_out(0), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_in_rdy == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      if (!m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
        `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_in_rdy go high"))
      end
      aes_test_disable();
      return;
    end

    // 7. FW loads data_in_byte_cnt and data_in_last fields and set data_in_vld = 1 in the aes_test_ctrl register.
    if(data_segment_num == (num_data_segments - 1)) begin
      aes_load_ctrl_bytecnt_last(.aes_data_in_byte_cnt(16), .data_in_last(1));
    end else begin
      aes_load_ctrl_bytecnt_last(.aes_data_in_byte_cnt(16), .data_in_last(0));
    end

    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_bytecnt_last", debug_str), UVM_LOW)

    // 8. FW waits for data_out_vld = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(0), .data_out_vld(1), .tag_out(0), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      if (!m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
        `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high"))
      end
      aes_test_disable();
      return;
    end

    // 9. FW reads aes_test_data_out* registers to get the AES output block and then set data_out_ack field to 1 in cmd register.
    read_reg_value(m_regmodel.aes_test_data_out_0, aes_pkt.m_aes_test_data_out[0]);
    read_reg_value(m_regmodel.aes_test_data_out_1, aes_pkt.m_aes_test_data_out[1]);
    read_reg_value(m_regmodel.aes_test_data_out_2, aes_pkt.m_aes_test_data_out[2]);
    read_reg_value(m_regmodel.aes_test_data_out_3, aes_pkt.m_aes_test_data_out[3]);
    aes_load_ctrl_data_out_ack();
    `uvm_info (get_name(), $sformatf("%s: set aes_load_ctrl_data_out_ack", debug_str), UVM_LOW)

    aes_pkt.check_result_data(data_segment_num);

    //aes test mode chages nonce and key slot registers, so those need to be set again prior to next set init cmd
    m_sys_cfg.m_nonce0_is_set   = 0;
    m_sys_cfg.m_nonce1_is_set   = 0;
    m_sys_cfg.m_nonce2_is_set   = 0;
    m_sys_cfg.m_key_slot_is_set = 0;

  end

  if(aes_pkt.m_aes_mode == sinc_parameters_pkg::GCM) begin
    // 11. In AES in GCM mode, then FW waits for data_out_vld = 1 and tag_out = 1 in aes_test_status register.
    wait_aes_status(.cfg_key_iv_rdy(0), .data_in_rdy(0), .data_out_vld(1), .tag_out(1), .timeout(timeout));
    `uvm_info (get_name(), $sformatf("%s: wait till data_out_vld == 1, tag_out == 1, timeout[%0d]", debug_str, timeout), UVM_LOW)

    if(timeout) begin
      if (!m_sys_cfg.m_sinc_rand_seq_enable_err_inj) begin
        `uvm_error(get_name(), $sformatf("wait_aes_status never saw data_out_vld go high for tag"))
      end
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
  if(pull_status_after_fw_request) begin
    pull_status(my_data, timeout);
  end else begin
    m_sys_cfg.m_err_inj_prior_trns_no_status_clear = 1;
  end

endtask : aes_test_mode

`endif // SINC_RANDOM_BASE_SEQ
