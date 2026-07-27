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
// File        : sinc_sys_cfg.svh
// Description : This class defines System Configurations for Key Vault TB.

`ifndef SINC_SYS_CFG
`define SINC_SYS_CFG

class sinc_sys_cfg extends uvm_object; // {

  //-----------------------------------------------------------------
  // VARIABLES
  //-----------------------------------------------------------------

  // Variable: m__singleton
  // static member that points to singleton
  protected static sinc_sys_cfg m__singleton;

  // Variable: m_comp_cfg
  // Associative array of component config objects
  sinc_sys_comp_cfg m_comp_cfg[sinc_comp_e];

  // SInC MPU config
  ccpui_mpu_config m_mpu_cfg;

  // MEM config handler
  mem_hamming_code m_ham;

  // PAL error injector
  pal_slave_error_injector m_pal_slv_err_injector;

  // Cache Storage Directory
  // sinc_csd_cache_comp_w_cfg m_csd;
  sinc_csd m_csd;

  // Variable: number of SINCs available in this sim
  protected int m_num_sinc = 0;

  // current CMU cache state
  sinc_parameters_pkg::sinc_cache_state_type_e m_cur_cache_state = sinc_parameters_pkg::CACHE_DISABLE_STATE;

  //flag for if sinc reset has been disabled, should be set by TB when reset disable bit is written to cmd register
  bit m_sinc_reset_disabled = 0;

  //flag for if sinc reinit has been disabled, should be set by TB when reinit disable bit is written to cmd register
  bit m_sinc_reinit_disabled = 0;

  //flag for if each nonce register has been set to the randomized value in sys_cfg aes packet
  //value is randomized when init_aes_cfg() calls randomize on the aes packet
  //should be set to 0 when it has not, e.g. after hw reset or sinc reset, and set to 1 when register has been written to
  //separate flag for each register
  bit m_nonce0_is_set = 0;
  bit m_nonce1_is_set = 0;
  bit m_nonce2_is_set = 0;

  //flag for if key slot register has been set to the randomized value in sys_cfg aes packet
  //value is randomized when init_aes_cfg() calls randomize on the aes packet
  //should be set to 0 when it has not, e.g. after hw reset, and set to 1 when register has been written to
  bit m_key_slot_is_set = 0;

  //flag for if ext_block_base register has been set to expected value for external memory
  //should be set to 0 when it has not, e.g. after hw reset, and set to 1 when register has been written to
  bit m_ext_block_base_is_set = 0;

  //flag for if ext_auth_tag_base register has been set to expected value for external tag memory
  //should be set to 0 when it has not, e.g. after hw reset, and set to 1 when register has been written to
  bit m_ext_auth_tag_base_is_set = 0;

  //flag for if block_encr_addr register has been set to expected value for internal hsp memory
  //should be set to 0 when it has not, e.g. after hw reset, and set to 1 when register has been written to
  bit m_block_encr_addr_is_set = 0;

  //used to skip the current fw command
  //meant for post randomize should set this if the randomization resulted in undesired command
  //lets code avoid making the constraints overly complex
  bit m_skip_fw_cmd;

  // flag indicate AES test mode is enabled
  bit  m_aes_test_mode_en      = 0;
  // flag indicate AES test mode is done, set when disable_aes_en, clear after status register read
  bit  m_aes_test_mode_done    = 0;
  time m_aes_test_mode_toggled = 0;

  // flag to waive scoreboard missprediction when hit counter, RTL has unpredictable behavior when erase and CPU RD at same time
  // Per discussion with designer, this register is for debug, it is waiver-able.
  bit m_observe_cpu_rd_during_erase_at_cache_active;

  // flag to waive scoreboard missprediction when perf_cntr_reg is changed during CPU RD
  bit m_perf_cntr_toggled_during_cpu_rd = 0;

  // flag for most recent fw command
  sinc_fw_cmd_e m_most_recent_fw_cmd                 = SINC_FW_UNMAPPED;
  time          m_most_recent_fw_cmd_done_time       = 0;
  bit           m_most_recent_fw_cmd_fail            = 0;
  time          m_most_recent_block_fetch_start_time;
  // flag when a block fetch cmd is done
  time          m_block_fetch_finished               = 0;
 

  // flag for most recent reg write
  uvm_reg m_most_recent_write_dst_reg;
  time    m_most_recent_write_dst_reg_start_time;

  // flag for most recent reason of cache fail
  bit m_unmapped_axi_mgr_rd_when_block_fetch = 0;

  // flag for most recent sinc_error
  time m_recent_sinc_error_time;

  // flag for time when FW operation is done but the AXI write response has not arrived
  time m_uncertain_fw_done_time;
  bit  m_unpredicatable_state   = 0;

  //flags for err inj sequence to set to alter behavior of send packet
  bit m_err_inj_encr_block_reg_block_encr_num_invalid  = 0;
  bit m_err_inj_encr_block_reg_num_of_blocks_invalid   = 0;
  bit m_err_inj_encr_block_reg_block_encr_addr_invalid = 0;
  bit m_err_inj_prior_trns_no_status_clear             = 0;
  bit m_allow_writes_cache_active                      = 0;

  // flag for ongoing erase
  bit m_sinc_erase_in_progress;

  // Variable: list of components available in this sim. This is a function of the m_num_sinc.
  protected sinc_comp_e m__comp_list[$];
  protected bit         m__comp_hash[sinc_comp_e];

  protected sinc_fw_cmd_e m__fw_cmd_list[$];
  protected bit           m__fw_cmd_hash[sinc_comp_e];

  sinc_fw_cmd_list_t m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::sinc_cache_state_type_e];

  protected sinc_mstr_type_e m__comp_master_list[$];

  // register handler
  sinc_regmodel m_regmodel;

  // register TLB
  sinc_regmodel m_sinc_reg_tlb;

  // Encryption related setup config, use aes_packet for data abstraction
  typedef sinc_aes_packet sinc_aes_packet_t;
  sinc_aes_packet_t m_aes_cfg;
  sinc_key_t        m_sys_active_key;              // monitored version of KEY used in current reset, it should match with aes_cfg if preload key is done
  reg_data_t        m_ext_block_base_addr    = 'h0;
  reg_data_t        m_ext_auth_tag_base_addr = 'h0;

  string                  m_random_data_type_str;
  sinc_random_data_type_e m_random_data_type;
  int                     m_skip_preload_blocks[$];
  int                     m_skip_preload_blocks_map[int];
  bit                     m_skipped_preload_for_some_blocks = 0;

  // register transaction lookasize buffer
  // sinc_tlb_reg  m_reg_tlb;

  sinc_comp_list_t m_axi_master_comp_list;

  typedef virtual interface sinc_v_if sinc_v_if_t;
  sinc_v_if_t m_sinc_vif;

  // sideband input
  bit m_sinc_mpu_disable   = 0;
  bit m_sinc_chkpt_spramnx = 0;

  // flag for testing
  bit m_is_rng_fetched   = 0; // set when RNG seed been fetched, it could be fetch by AES test command and SET_INIT_STATE command.
  bit m_is_key_fetched   = 0; // set when RNG seed been fetched, it could be fetch by AES test command and SET_INIT_STATE command.
  bit m_reset_reg_tested = 0; // used by sanity test to indicate whether reset value is tested in test register sequence

  // sinc_dbg_mode_acc_en_i
  bit m_aeb_sinc_dbg_mode_acc_en;

  // Variable: control whether the random reset is enabled
  bit m_enable_rand_reset      = 0;
  // Variable: control whether the random clock gate is enabled
  bit m_enable_rand_clock_gate = 0;

  // Variable: control whether the the test should always send legal requests
  bit m_disable_illegal_req = 0;

  // Variable: transaction number per test
  int m_sinc_tb_seq_trans_num              = 200;
  // Variable: control the sequence requests dist ratio
  int m_sinc_tb_seq_axi_read_ratio;
  int m_sinc_tb_seq_axi_write_ratio;
  int m_sinc_tb_seq_cpu_read_ratio;
  int m_sinc_tb_seq_cache_hit_ratio;
  int m_sinc_tb_seq_cpu_write_ratio;
  int m_sinc_tb_seq_erase_mem_ratio;
  int m_sinc_tb_seq_mpu_read_ratio;
  int m_sinc_tb_seq_mpu_write_ratio;
  int m_sinc_tb_seq_fw_operation_req_ratio;
  int m_sinc_tb_seq_hw_reset_ratio;
  int m_sinc_tb_seq_w_cache_fail_ratio;
  int m_sinc_tb_seq_cpu_req_during_erase_ratio;
  int m_sinc_tb_seq_erase_during_cpu_req_ratio;

  int m_sinc_tb_seq_cmd_set_init_state_ratio;
  int m_sinc_tb_seq_cmd_set_cache_active_state;
  int m_sinc_tb_seq_cmd_aes_test_ratio;
  int m_sinc_tb_seq_cmd_disable_reset_disabled_ratio;
  int m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio;
  int m_sinc_tb_seq_use_non_blocking_cpu_read     = 0;
  int m_sinc_tb_seq_always_en_back_2_back         = 0;
  int m_sinc_tb_seq_cmd_disable_reset_init_ratio;
  int m_sinc_tb_seq_cmd_disable_reinit_init_ratio;
  int m_sinc_tb_seq_cmd_disable_reset_active_ratio;
  int m_sinc_tb_seq_cmd_disable_reinit_active_ratio;
  int m_sinc_tb_seq_cmd_disable_reset_failed_ratio;
  int m_sinc_tb_seq_cmd_disable_reinit_failed_ratio;
  int m_sinc_tb_seq_cmd_sinc_reset_init_ratio;
  int m_sinc_tb_seq_cmd_sinc_reset_active_ratio;
  int m_sinc_tb_seq_cmd_sinc_reset_fail_ratio;
  int m_sinc_tb_seq_cmd_sinc_reinit_ratio;
  int m_sinc_tb_seq_cmd_encr_block_ratio;

  int m_sinc_stimulus_always_cpu_erase_same = 0;
  int m_sinc_stimulus_always_erase_during = 0;
  int m_sinc_stimulus_always_cpu_during = 0;
  int m_sinc_stimulus_always_axi_during = 0;
  int m_sinc_tb_seq_never_dis_cmds         = 0;
  int m_sinc_tb_seq_never_do_aes_test_cmds = 0;
  int m_sinc_tb_seq_only_do_aes_test_cmds  = 0;
  int m_sinc_tb_seq_dis_encr_auth_check  = 0;
  int m_sinc_tb_seq_rand_encr_auth_check = 0;
  // desired cache state
  // 0: disable, 1: init, 2: active
  int m_sinc_tb_seq_use_des_cache_state    = 0;

  //used to enable backdoor preloading of memory
  int m_sinc_tb_seq_backdoor_preload_mem         = 0;
  int m_sinc_tb_seq_backdoor_preload_mem_not_all = 0;

  //todo use sinc_cache_state_type_e enum, not sure how to do this with plusarg
  int m_sinc_tb_seq_des_cache_state = 0;

  // Variable: control fault error test
  bit                            m_sinc_enable_specific_fault_err                     = 0;
  bit                            m_sinc_tb_axi_err_injection_en                       = 0;
  bit                            m_sinc_fault_error_type_ciu_cache_fsm_illegal;
  bit                            m_sinc_fault_error_type_cmu_ctrl_fsm_illegal;
  bit                            m_sinc_fault_error_type_cache_state_fsm_illegal;
  bit                            m_sinc_fault_error_type_sinc_sub_state_fsm_illegal;
  bit                            m_sinc_fault_error_type_aes_ctrl_fsm_illegal;
  bit                            m_sinc_fault_error_type_dma_r_fsm_illegal;
  bit                            m_sinc_fault_error_type_dma_w_fsm_illegal;
  bit                            m_sinc_fault_error_type_aes_keyexp_fsm_illegal;
  bit                            m_sinc_fault_error_type_gpaes_mode_main_fsm_illegal;
  bit                            m_sinc_fault_error_type_gpaes_ghash_mul_fsm_illegal;
  bit                            m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal;
  bit                            m_sinc_fault_error_type_gpaes_mode_sec_fsm_illegal;
  bit                            m_sinc_fault_error_type_gpaes_mode_ghash_fsm_illegal;
  // Variable: cache line pool size, used to constraint the CPU packet
  bit                            m_access_within_cache_pool                           = 0;
  int                            m_cache_line_pool_size                               = 0;
  sinc_csd_cache_line_comp_w_cfg m_cache_line_pool[];

  //variables for random error injection
  bit m_sinc_rand_seq_enable_err_inj                   = 0; // indicate the test will allow random error injection on generated requests
  bit m_sinc_rand_seq_disable_severe_err_inj           = 0; // indicate the test will allow random error injection on severe errors
  int m_sinc_rand_seq_enable_transaction_err_inj_ratio;     // percentage of error injection
  int m_sinc_rand_seq_enable_stimulus_err_inj_ratio;        // percentage of error injection
  bit m_sinc_rand_seq_enable_err_inj_on_rd_axi_req     = 0; // indicate error injection will be done for read (AXI) request
  bit m_sinc_rand_seq_enable_err_inj_on_wr_axi_req     = 0; // indicate error injection will be done for write (AXI) request
  bit m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req     = 0; // indicate error injection will be done for read (CPU) request
  bit m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req     = 0; // indicate error injection will be done for write (CPU) request
  bit m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req     = 0; // indicate error injection will be done for read (MPU) request
  bit m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req     = 0; // indicate error injection will be done for write (MPU) request

  // debug temporary flags
  bit m_sinc_err_stimulus_set_init_rng_seed_failure = 0; // inject error for set init command RNG read
  bit m_sinc_err_stimulus_invalid_cmd_for_state = 0; // inject error for invalif command for state
  bit m_sinc_err_stimulus_set_encr_block_failure    = 0; // inject error for encr_block_command

  `uvm_object_utils(sinc_sys_cfg)

  //-----------------------------------------------------------------
  // FUNCTIONS
  //-----------------------------------------------------------------

  //-----------------------------------------------------------------
  //
  extern function new(string name = "sinc_sys_cfg");

  //-----------------------------------------------------------------
  // Function: get_inst
  // A static function which returns the singleton instance of this class.
  static function sinc_sys_cfg get_inst();
    if (m__singleton != null) begin
      return (m__singleton);
    end else begin
      //`uvm_error("sinc_sys_cfg::get_inst: not created", "This singleton must first be created using sinc_env_pkg::sinc_sys_cfg::create()")
      return (null);
    end
  endfunction : get_inst

  //-----------------------------------------------------------------
  // Function: init
  // A function to initialize sinc_sys_cfg
  // CS TB initializes after setting the values of m_num_sincs in cs_tb_env
  extern virtual function void init();

  virtual function void prepare_sys_cfg();
    `uvm_info("SINC_SYS_CFG/new", $sformatf("Preparing sinc_sys_cfg before next stimulus \n"), UVM_HIGH)
    // randomize the cache line pool
    if (m_cache_line_pool_size > 0) begin
      m_cache_line_pool = new[m_cache_line_pool_size];
      for (int i=0; i < m_cache_line_pool_size; i++) begin
        m_cache_line_pool[i] = m_csd.get_random_cache_line();
      end
    end
  endfunction : prepare_sys_cfg

  virtual function void reset_default_cfg ();
    m_reset_reg_tested = 0;
  endfunction : reset_default_cfg

  //-----------------------------------------------------------------
  // Function: get_instance_id
  //   Returns instanceID associated with supplied component.
  //
  virtual function int get_instance_id (sinc_comp_e comp);
    validate_comp (comp);
    return (m_comp_cfg[comp].m_instance_id);
  endfunction : get_instance_id

  //-----------------------------------------------------------------
  // Function: get_type_instance_name
  //   Returns component type instance name (ex. )
  //
  virtual function string get_type_instance_name (sinc_comp_e comp);
    validate_comp (comp);
    return (m_comp_cfg[comp].m_type_instance_name);
  endfunction : get_type_instance_name

  //-----------------------------------------------------------------
  // Function: get_comp_type_name
  //   Returns component type name (ex. )
  //
  virtual function string get_comp_type_name (sinc_comp_e comp);
    validate_comp (comp);
    return (m_comp_cfg[comp].m_comp_type_name);
  endfunction : get_comp_type_name

  //-----------------------------------------------------------------
  // Function: get_comp_id
  //  Returns comp_type for specified instance_id
  virtual function sinc_env_pkg::sinc_comp_e get_comp_id (int inst_id);
    foreach(m_comp_cfg[comp_type]) begin
      if(m_comp_cfg[comp_type].m_instance_id == inst_id) begin
        return (comp_type);
      end
    end

    return (sinc_env_pkg::SINC_NULL);

  endfunction : get_comp_id

  extern virtual function void validate_comp (sinc_comp_e comp);
  extern virtual function bit is_valid_comp (sinc_comp_e comp);

  extern virtual function void dump_sys_cfg();

  extern virtual function void init_comp_cfgs ();
  extern virtual function void init_aes_cfg();
  extern virtual function void reinit_aes_cfg();
  extern virtual function void rand_sideband_cfg();

  extern virtual function int get_comp_index (sinc_comp_e comp);
  extern virtual function int get_comp_addr_width (sinc_comp_e comp);
  extern virtual function longint unsigned get_comp_addr_mask (sinc_comp_e comp);
  extern virtual function sinc_sys_comp_cfg get_comp_cfg (sinc_comp_e comp);
  extern virtual function req_cmd_list_t get_valid_cmd_types (sinc_comp_e src_comp);
  extern virtual function sinc_comp_list_t get_valid_access_comp_types (sinc_comp_e src_comp);
  extern virtual function sinc_comp_e get_valid_access_comp_type(sinc_comp_e src_comp);
  extern virtual function sinc_comp_list_t get_valid_src_comp (sinc_comp_e dst_comp);
  extern virtual function sinc_comp_list_t get_all_valid_access_comp_types (sinc_comp_e src_comp);
  extern virtual function sinc_cmd_e get_valid_cmd_type (sinc_comp_e src_comp, sinc_comp_e dst_comp_type);
  extern virtual function sinc_reg_e get_reg_enum_from_string (string name);
  extern virtual function sinc_fw_cmd_e get_fw_cmd_enum_from_string (string name);
  extern virtual function sinc_comp_e get_comp_from_string (string name);
  extern virtual function string get_hdl_path (sinc_comp_e comp);

  extern virtual function sinc_comp_list_t get_full_comp_list ();
  extern virtual function sinc_comp_list_t get_comp_list (sinc_comp_e comp_type=SINC_NULL);
  extern virtual function sinc_comp_list_t get_key_comp_list ();
  //  extern virtual function sinc_comp_list_t  get_key_slot_comp_list ();

  extern virtual function sinc_comp_e get_compe_by_axi_id (int axi_id);
  extern virtual function int get_axi_id_by_compe (sinc_comp_e axi_comp);

  extern virtual function int get_addr_msb (sinc_comp_e comp);
  extern virtual function int get_addr_lsb (sinc_comp_e comp);
  extern virtual function int convert_axuser_to_axiid (pal_axuser_t axuser);

  extern virtual function bit is_axi_intf_comp (sinc_comp_e comp);

  // ********************************************************************************
  // Function: is_valid_reg_access
  // return true if given access to register is allowed
  extern virtual function bit is_valid_reg_access (uvm_reg item, sinc_cmd_e cmd);

  // ********************************************************************************
  // Function: is_valid_encr_block_cmd
  // return true if given encr_block cmd is valid
  extern virtual function bit is_valid_encr_block_cmd (reg_data_t num_of_blocks, reg_data_t block_encr_num);

  // ********************************************************************************
  // Function: is_reg_write_discarded
  // return true if given register's write will be discarded in current cache state
  extern virtual function bit is_reg_write_discarded (uvm_reg item);

  // ********************************************************************************
  // Function: is_valid_axi_attributes
  // return true if given request has all the attributes be valid
  extern virtual function bit is_valid_axi_sub_attributes(
        pal_axi_xaction axi_tran,
        sinc_comp_e     req_src,
        sinc_comp_e     req_dst,
        sinc_cmd_e      req_cmd,
        uvm_reg         dst_reg                   =null,
    ref bit             ref_is_valid_src,
    ref bit             ref_is_byte_allign,
    ref bit             ref_is_access_reg_allowed,
    ref bit             ref_is_valid_burst
  );

  // ********************************************************************************
  // Function: is_aligned_addr
  // return true if given address is aligned
  extern virtual function bit is_aligned_addr(address_t addr, bit is_pcr=0);

  // ********************************************************************************
  // Function: is_valid_req
  // check if the request will be accept at SINC TOP
  // input with initiator, cmd
  // return true if given request is valid
  extern virtual function bit is_valid_req(sinc_comp_e req_src, sinc_cmd_e req_cmd);

  // ********************************************************************************
  // Function: is_allowed_fw_cmd_in_cur_cache_state
  // check if the fw command is allowed to proceed in current cache state
  // result in invalid command if not allowed.
  // return true if given request is allowed
  extern virtual function bit is_allowed_fw_cmd_in_cur_cache_state(sinc_fw_cmd_e fw_cmd);

  // ********************************************************************************
  // Function: is_valid_fw_cmd
  // return true if given integer mapped with one of the FW commands
  extern virtual function bit is_valid_fw_cmd(int fw_cmd_in_int);

  // ********************************************************************************
  // Function: is_lut_check_pass
  // return true if given ARUSER check with LUT pass
  extern virtual function bit is_lut_check_pass(sinc_lut_t lut, sinc_lut_t aruser, int index, bit is_internal_access);

  // ********************************************************************************
  // Function: is_internal_access
  // return true if given AXI Originator is KMP internal Master
  extern virtual function bit is_internal_access(sinc_comp_e axi_comp);

  // ********************************************************************************
  // Function: get_aeb_sinc_dbg_mode_acc_en
  // snap shot current AEB bus value for: aeb_sinc_dbg_mode_acc_en
  extern virtual function bit get_aeb_sinc_dbg_mode_acc_en();

  // ********************************************************************************
  // Function: get_fw_cmd
  // return the mapped FW commands
  extern virtual function sinc_parameters_pkg::sinc_fw_cmd_e get_fw_cmd_type(int fw_cmd_in_int);;

  // ********************************************************************************
  // Function: get_valid_rand_src_comp
  // return sinc_comp_e as initiator, for valid access
  // input (access destination component, command, extra input for key 'is_valid_slot', extra input for register access)
  extern virtual function sinc_comp_e get_valid_rand_src_comp (sinc_comp_e dst_comp, sinc_axi_cmd_e axi_cmd, bit is_valid_slot=0, uvm_reg reg_handler = null);

  extern virtual function sinc_comp_e get_valid_rand_src_comp_test (sinc_comp_e dst_comp, sinc_axi_cmd_e axi_cmd, bit is_valid_slot=0, uvm_reg reg_handler = null);

  // call by sinc_environment to construct the register list that allowed to access in different states
  extern virtual function void construct_reg_list_with_reg_name(string reg_name);

  // call by init to construct the FW operations that allowed in different states
  extern virtual function void construct_fw_operation_list_with_cmd_name(string cmd_name);

  // grab and pars run time options from yaml config
  extern virtual function void process_plusargs_and_populate_tb_cfg();

  // ********************************************************************************
  // Function: get_sinc_erase_in_progress
  // get m_SINC_ERASE_IN_PROGRESS
  extern virtual function bit get_sinc_erase_in_progress();

  // ********************************************************************************
  // Function: set_sinc_erase_in_progress
  // set m_SINC_ERASE_IN_PROGRESS
  extern virtual function void set_sinc_erase_in_progress(logic a_value);

  // ********************************************************************************
  // Function: get_is_fsm_fault_err_injected
  // get m_IS_FSM_FAULT_ERR_INJECTED
  extern virtual function bit get_is_fsm_fault_err_injected();

  // ********************************************************************************
  // Function: set_is_fsm_fault_err_injected
  // set m_IS_FSM_FAULT_ERR_INJECTED
  extern virtual task set_is_fsm_fault_err_injected(logic a_value);

endclass : sinc_sys_cfg // }

function sinc_sys_cfg::new(string name = "sinc_sys_cfg");
  super.new(name);

  if (sinc_sys_cfg::m__singleton != null) begin
    `uvm_fatal("sinc_sys_cfg::new: illegal instance of singleton", "Can't instance a singleton more than once. Use sinc_env_pkg::sinc_sys_cfg::get_inst() instead")
  end
  sinc_sys_cfg::m__singleton = this;

  `uvm_info("SINC_SYS_CFG/new", $sformatf("Initializing sinc_sys_cfg\n"), UVM_HIGH)

  process_plusargs_and_populate_tb_cfg();

  if (m_random_data_type_str == "RAND") begin
    m_random_data_type = sinc_env_pkg::SINC_RANDOM_RAND;
  end else if (m_random_data_type_str == "ZERO") begin
    m_random_data_type = sinc_env_pkg::SINC_RANDOM_ZERO;
  end else if (m_random_data_type_str == "ONE") begin
    m_random_data_type = sinc_env_pkg::SINC_RANDOM_ONE;
  end else begin
    m_random_data_type = sinc_env_pkg::SINC_RANDOM_RAND;
  end

  init();
endfunction : new

function void sinc_sys_cfg::init();
  // // register tlb
  // m_reg_tlb  = sinc_tlb_reg::type_id::create("m_reg_tlb");
  // // set TLB mirror addresses
  // m_reg_tlb.initialize();
  // // reset TLB mirror registers
  // m_reg_tlb.reset();

  // register config to external memory
  m_ext_block_base_addr    = sinc_parameters_pkg::SINC_DMB_START_ADDR; // use starting address DMB for m_ext_block_base_addr 'h9000_0000
  m_ext_auth_tag_base_addr = sinc_parameters_pkg::SINC_DMB_START_ADDR + 32'h0F00_0000; // END at FFFF_FFFF, last 4 bits must be 0

  init_comp_cfgs();
  init_aes_cfg();
  rand_sideband_cfg();

  // determine available components
  begin
    sinc_comp_e comp = comp.first();
    while (comp != comp.last()) begin
      if (m_comp_cfg.exists(comp)) begin
        m__comp_list.push_back(comp);
        m__comp_hash[comp] = 1;
        `uvm_info("sinc_sys_config:", $sformatf("Add %0s as m__comp_list", comp.name()), UVM_LOW)
      end
      comp = comp.next();
    end
  end

  dump_sys_cfg();
  // m_reg_tlb.print_tlb_reg();

endfunction : init

//-----------------------------------------------------------------
// Function: dump_sys_cfg
//   Dumps to stdout system config info
//
function void sinc_sys_cfg::dump_sys_cfg ();
  string str;
  int    idx =1;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Print SInC TB System Config[%0d] \n", m__comp_list.size() + 1)};
  foreach (m__comp_list[i]) begin
    sinc_comp_e comp = m__comp_list[i];
    if (m_comp_cfg[comp] !== null) begin
      if (m_comp_cfg[comp].m_is_initiator) begin

        str = $sformatf("%0s Initiator[%0d] : %-9s  |", str, idx, comp.name());

      end
    end

    idx++;
  end // foreach (m__comp_list[i])

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_SYS_CFG/COMPONENTS", str, UVM_NONE)

endfunction : dump_sys_cfg

//-----------------------------------------------------------------
// Function: validate_comp
//   Errors out if supplied component is not legal in this build
//
function void sinc_sys_cfg::validate_comp (sinc_comp_e comp);
  if (!is_valid_comp(comp)) begin
    $stacktrace();
    `uvm_error("validate_comp: illegal component name",
      $sformatf("sinc_sys_cfg::validate_comp() does not recognize component '%0s' [0x%0d]. Maybe this resides outside enabled %0d SINCs. Search this log file for [SINC_SYS_CFG/COMPONENTS] for a list of all present SINC components",
        comp.name(), comp, m_num_sinc))
  end
endfunction : validate_comp

//-----------------------------------------------------------------
// Function: is_valid_comp
//  returns true if this component is present in this config
//
function bit sinc_sys_cfg::is_valid_comp (sinc_comp_e comp);
  return (m_comp_cfg.exists(comp));
endfunction : is_valid_comp

//-----------------------------------------------------------------
// Function: get_comp_index
//  returns the component's index.
//
function int sinc_sys_cfg::get_comp_index (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_port_num);
endfunction : get_comp_index

//-----------------------------------------------------------------
// Function: get_comp_addr_width
//  returns the component's address width
//
function int sinc_sys_cfg::get_comp_addr_width (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_addr_width);
endfunction : get_comp_addr_width

//-----------------------------------------------------------------
// Function: get_comp_addr_mask
//  returns the component's address bit mask
//
function longint unsigned sinc_sys_cfg::get_comp_addr_mask (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_addr_mask);
endfunction : get_comp_addr_mask

//-----------------------------------------------------------------
// Function: get_comp_cfg
//  returns the component's config object which contains all the attributes
//  about the specified component.
//
function sinc_sys_comp_cfg sinc_sys_cfg::get_comp_cfg (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp]);
endfunction : get_comp_cfg

//-----------------------------------------------------------------
// Function: get_comp_from_string
//  Returns comp_type from a string
function sinc_comp_e sinc_sys_cfg::get_comp_from_string (string name);
  foreach(m_comp_cfg[comp_type]) begin
    if(comp_type.name() == name) begin
      return(comp_type);
    end
  end
  return (sinc_env_pkg::SINC_NULL);
endfunction : get_comp_from_string

//-----------------------------------------------------------------
// Function: get_comp_from_string
//  Returns comp_type from a string
function sinc_reg_e sinc_sys_cfg::get_reg_enum_from_string (string name);
  sinc_parameters_pkg::sinc_reg_e reg_dst = reg_dst.first();

  while (reg_dst != reg_dst.last()) begin
    if(reg_dst.name() == name) begin
      return(reg_dst);
    end
    reg_dst = reg_dst.next();
  end

  return (reg_dst);
endfunction : get_reg_enum_from_string

//-----------------------------------------------------------------
// Function: get_fw_cmd_enum_from_string
//  Returns fw_cmd_enum from a string
function sinc_fw_cmd_e sinc_sys_cfg::get_fw_cmd_enum_from_string (string name);
  sinc_parameters_pkg::sinc_fw_cmd_e fw_cmd_dst = fw_cmd_dst.first();

  while (fw_cmd_dst != fw_cmd_dst.last()) begin
    if(fw_cmd_dst.name() == name) begin
      return(fw_cmd_dst);
    end
    fw_cmd_dst = fw_cmd_dst.next();
  end

  return (fw_cmd_dst);
endfunction : get_fw_cmd_enum_from_string

//-----------------------------------------------------------------
// Function: get_hdl_path
//  returns the HDL verilog path to this component instance
//
function string sinc_sys_cfg::get_hdl_path (sinc_comp_e comp);
  validate_comp (comp);

  if (m_comp_cfg[comp].m_hdl_path == "") begin
    $stacktrace();
    `uvm_error("get_hdl_path: NULL_PATH",
      $sformatf("get_hdl_path::comp %0s has NULL hdl_path", comp.name()))
  end
  return (m_comp_cfg[comp].m_hdl_path);
endfunction : get_hdl_path

//-----------------------------------------------------------------
// Function: get_valid_cmd_type
//  Returns a single component present on the test unit.
//
function sinc_cmd_e sinc_sys_cfg::get_valid_cmd_type (sinc_comp_e src_comp, sinc_comp_e dst_comp_type);
  /*
   req_cmd_list_t valid_cmd_type_list;
   sinc_sys_comp_cfg dst_comp_cfg;
   sinc_cmd_e sinc_cmd;

   //`uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s ", src_comp.name(), dst_comp_type.name()), UVM_DEBUG);

   dst_comp_cfg = get_comp_cfg(dst_comp_type);
   valid_cmd_type_list = dst_comp_cfg.valid_master_cmd_list[src_comp];
   if (valid_cmd_type_list.size() == 0) begin
   //`uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s has no access cmd type", src_comp.name(), dst_comp_type.name()), UVM_LOW);
   end else begin
   int rand_index = $urandom_range(valid_cmd_type_list.size()-1, 0);

   sinc_cmd = valid_cmd_type_list[rand_index];

   foreach (valid_cmd_type_list[i]) begin
   //`uvm_info("sinc_sys_config:", $sformatf("has access cmd type %0s", valid_cmd_type_list[i].name()), UVM_DEBUG);
   end
   end

   return sinc_cmd;
   */
endfunction : get_valid_cmd_type

//-----------------------------------------------------------------
// Function: get_valid_cmd_types
//  Returns a list of components present on the test unit.
//
function req_cmd_list_t sinc_sys_cfg::get_valid_cmd_types (sinc_comp_e src_comp);
  req_cmd_list_t    valid_cmd_type_list;
  sinc_sys_comp_cfg src_comp_cfg;

  // `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s ", src_comp.name(), dst_comp_type.name()), UVM_DEBUG);
  `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s ", src_comp.name()), UVM_HIGH)

  src_comp_cfg = get_comp_cfg(src_comp);

  valid_cmd_type_list = src_comp_cfg.m_valid_cmd_at_cache_state[m_cur_cache_state];

  if (valid_cmd_type_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no validaccess cmd type", src_comp.name()), UVM_LOW)
  end else begin
    foreach (valid_cmd_type_list[i]) begin
      `uvm_info("sinc_sys_config:", $sformatf("has access cmd type %0s", valid_cmd_type_list[i].name()), UVM_HIGH)
    end
  end

  return (valid_cmd_type_list);

endfunction : get_valid_cmd_types

//-----------------------------------------------------------------
// Function: get_valid_access_comp_types
//  Returns single component present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_valid_access_comp_types(sinc_comp_e src_comp);
  /*
   sinc_comp_list_t valid_comp_type_list;
   req_cmd_list_t valid_cmd_type_list;
   sinc_sys_comp_cfg src_cfg;

   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_DEBUG);

   src_cfg = get_comp_cfg(src_comp);
   valid_comp_type_list = src_cfg.valid_ksb_access_comp_list;
   if (valid_comp_type_list.size() == 0) begin
   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_LOW);
   end else begin
   foreach (valid_comp_type_list[i]) begin
   `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_DEBUG);
   end
   end

   return valid_comp_type_list;
   */
endfunction : get_valid_access_comp_types

//-----------------------------------------------------------------
// Function: get_valid_access_comp_types
//  Returns a list of SINC components present on the test unit.
//
function sinc_comp_e sinc_sys_cfg::get_valid_access_comp_type(sinc_comp_e src_comp);
  /*
   sinc_comp_list_t valid_comp_type_list;
   req_cmd_list_t valid_cmd_type_list;
   sinc_sys_comp_cfg src_cfg;
   sinc_comp_e comp_type = SINC_NULL;

   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_HIGH);

   src_cfg = m_comp_cfg[src_comp];;
   valid_comp_type_list = src_cfg.valid_ksb_access_comp_list;
   if (valid_comp_type_list.size() == 0) begin
   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_HIGH);
   end else begin
   int rand_index = $urandom_range(valid_comp_type_list.size()-1, 0);
   comp_type = valid_comp_type_list[rand_index];
   foreach (valid_comp_type_list[i]) begin
   `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_HIGH);
   end
   end

   return comp_type;
   */
endfunction : get_valid_access_comp_type

//-----------------------------------------------------------------
// Function: get_valid_src_comp
//  Returns a list of KSB components present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_valid_src_comp(sinc_comp_e dst_comp);
  /*
   sinc_comp_list_t valid_src_list;
   sinc_sys_comp_cfg dst_cfg;
   sinc_comp_list_t valid_comp_e_list;

   `uvm_info("sinc_sys_config:", $sformatf("dst_comp :%0s", dst_comp.name()), UVM_DEBUG);

   dst_cfg = get_comp_cfg(dst_comp);
   valid_src_list = dst_cfg.valid_mstr_list;

   if (valid_src_list.size() == 0) begin
   `uvm_info("sinc_sys_config:", $sformatf("dst_comp :%0s, can not be accessed by any src", dst_comp.name()), UVM_LOW);
   end else begin
   foreach (valid_src_list[i]) begin
   sinc_comp_list_t comp_list;
   `uvm_info("sinc_sys_config:", $sformatf("%0s has access component to %0s ", valid_src_list[i].name(), dst_comp.name()), UVM_DEBUG);
   comp_list = get_comp_list(valid_src_list[i]);
   foreach (comp_list[j]) begin
   valid_comp_e_list.push_back(comp_list[j]);
   end
   end
   end

   return valid_comp_e_list;
   */
endfunction : get_valid_src_comp

//-----------------------------------------------------------------
// Function: get_all_valid_access_comp_types
//  Returns a list of all components present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_all_valid_access_comp_types(sinc_comp_e src_comp);
  /*
   sinc_comp_list_t valid_comp_type_list;
   req_cmd_list_t valid_cmd_type_list;
   sinc_sys_comp_cfg src_cfg;

   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_DEBUG);

   src_cfg = get_comp_cfg(src_comp);
   valid_comp_type_list = src_cfg.valid_sinc_access_comp_list;
   if (valid_comp_type_list.size() == 0) begin
   `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_LOW);
   end else begin
   foreach (valid_comp_type_list[i]) begin
   `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_DEBUG);
   end
   end

   return valid_comp_type_list;
   */
endfunction : get_all_valid_access_comp_types

//-----------------------------------------------------------------
// Function: get_full_comp_list
//  Returns a list of components present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_full_comp_list ();
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  return (m__comp_list);
endfunction : get_full_comp_list

//-----------------------------------------------------------------
// Function: get_comp_list
//  Returns a list of components present on SINC.
//

function sinc_comp_list_t sinc_sys_cfg::get_comp_list (sinc_comp_e comp_type=SINC_NULL);
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  `uvm_info("sinc_sys_config:", $sformatf("get_comp_list for comp_type:%0s ", comp_type.name()), UVM_HIGH)
  foreach (m__comp_list[i]) begin
    comp = m__comp_list[i];
    if(comp_type !== SINC_NULL) begin
      `uvm_info("sinc_sys_config:", $sformatf("push comp_e:%0s ", comp.name()), UVM_HIGH)
      comp_list.push_back(comp);
    end
  end

  return (comp_list);
endfunction : get_comp_list

//-----------------------------------------------------------------
// Function: get_key_comp_list
//  returns a list of key components present.
//
function sinc_comp_list_t sinc_sys_cfg::get_key_comp_list ();
  /*
   sinc_comp_e      comp;
   sinc_comp_list_t comp_list;

   foreach (m__comp_list[i]) begin
   comp = m__comp_list[i];
   if (m_comp_cfg[comp].m_is_key) begin
   comp_list.push_back(comp);
   end
   end
   return comp_list;
   */
endfunction : get_key_comp_list

//-----------------------------------------------------------------
// Function: is_axi_intf_comp
//  returns true if supplied comp is using AXI interface.
//
function bit sinc_sys_cfg::is_axi_intf_comp (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_is_axi_intf);
endfunction : is_axi_intf_comp

//-----------------------------------------------------------------
// Function: is_aligned_addr
//
function bit sinc_sys_cfg::is_aligned_addr(address_t addr, bit is_pcr = 0);
  address_t byte_addr;
  if (is_pcr) begin
    byte_addr = addr % 8'h20;
    `uvm_info("SYS_CFG_DEBUG", $sformatf("add:'h%0h, byte_addr:%0d", addr, byte_addr), UVM_DEBUG)
    if ((addr % 8'h4) == 0) begin
      return (1);
    end else begin
      return (0);
    end
  end else begin
    if ((addr % 8'h20) == 0) begin
      return (1);
    end else begin
      return (0);
    end
  end

endfunction : is_aligned_addr

//-----------------------------------------------------------------
// Function: is_valid_req
//
function bit sinc_sys_cfg::is_valid_req(sinc_comp_e req_src, sinc_cmd_e req_cmd);
  string debug_str    = "IS_VALID_REQ";
  bit    is_valid_cmd = 0;

  req_cmd_list_t valid_cmd_type_list;

  if (!is_valid_comp (req_src)) begin
    return (0);
  end

  if (req_cmd == SINC_CMD_UNKNOWN) begin
    return (0);
  end

  valid_cmd_type_list = get_valid_cmd_types(req_src);

  foreach (valid_cmd_type_list[i]) begin
    if (valid_cmd_type_list[i] == req_cmd) begin
      is_valid_cmd = 1;
    end
  end

  // return result
  `uvm_info(debug_str, $sformatf("is_valid_cmd[%0d]", is_valid_cmd), UVM_HIGH)

  if (is_valid_cmd) begin
    foreach (valid_cmd_type_list[i]) begin
      `uvm_info(debug_str, $sformatf("valid_cmd[%0d]: %0s", i, valid_cmd_type_list[i]), UVM_HIGH)
    end
  end

  return (is_valid_cmd);

endfunction : is_valid_req

//-----------------------------------------------------------------
// Function: is_allowed_fw_cmd_in_cur_cache_state
//
function bit sinc_sys_cfg::is_allowed_fw_cmd_in_cur_cache_state(sinc_fw_cmd_e fw_cmd);
  string debug_str         = "IS_ALLOWED_FW_CMD_IN_CUR_CACHE_STATE";
  bit    is_allowed_fw_cmd = 0;

  foreach (m_valid_fw_cmd_at_cache_state[m_cur_cache_state][i]) begin
    if (m_valid_fw_cmd_at_cache_state[m_cur_cache_state][i] == fw_cmd) begin
      is_allowed_fw_cmd = 1;
    end
  end

  `uvm_info(debug_str, $sformatf("is_allowed_fw_cmd[%0d] - FW_CMD[%0s] : State[%0s]", is_allowed_fw_cmd, fw_cmd.name(), m_cur_cache_state.name()), UVM_HIGH)

  return (is_allowed_fw_cmd);

endfunction : is_allowed_fw_cmd_in_cur_cache_state

//-----------------------------------------------------------------
// Function: is_valid_axi_attributes
//
function bit sinc_sys_cfg::is_valid_axi_sub_attributes(
        pal_axi_xaction axi_tran,
        sinc_comp_e     req_src,
        sinc_comp_e     req_dst,
        sinc_cmd_e      req_cmd,
        uvm_reg         dst_reg                   =null,
    ref bit             ref_is_valid_src,
    ref bit             ref_is_byte_allign,
    ref bit             ref_is_access_reg_allowed,
    ref bit             ref_is_valid_burst
  );
  string debug_str = "IS_VALID_AXI_ATTRIBUTES";

  bit is_valid_src          = 1;
  bit is_byte_allign        = 1;
  bit is_access_reg_allowed = 1;
  bit is_valid_burst        = 1;

  if (req_src !== SINC_SP) begin
    is_valid_src = 0;
  end

  if (axi_tran.addr[1:0] !== 2'b00) begin
    is_byte_allign = 0;
  end

  if (axi_tran.burst_length == 1) begin
    if ((axi_tran.burst_type == PAL_BT_RSVD) || (axi_tran.burst_type == PAL_BT_WRAP)) begin
      `uvm_info(debug_str, $sformatf("burst_length[%0d], burst_size[%0s], beat_size_in_bytes[%0d], burst type:[%0s]",
          axi_tran.burst_length, axi_tran.log2_beat_size.name(), axi_tran.beat_size_in_bytes, axi_tran.burst_type.name()), UVM_HIGH)

      is_valid_burst = 0;
    end
  end else if (axi_tran.burst_length > 1) begin
    if ((axi_tran.burst_type == PAL_BT_RSVD) || (axi_tran.burst_type == PAL_BT_WRAP) || (axi_tran.burst_type == PAL_BT_FIXED)) begin
      `uvm_info(debug_str, $sformatf("burst_length[%0d], burst_size[%0s], beat_size_in_bytes[%0d], burst type:[%0s]",
          axi_tran.burst_length, axi_tran.log2_beat_size.name(), axi_tran.beat_size_in_bytes, axi_tran.burst_type.name()), UVM_HIGH)

      is_valid_burst = 0;
    end
  end

  if (req_dst == SINC_REG) begin
    `uvm_info(debug_str, $sformatf("burst_length[%0d], burst_size[%0s], beat_size_in_bytes[%0d]",
        axi_tran.burst_length, axi_tran.log2_beat_size.name(), axi_tran.beat_size_in_bytes), UVM_HIGH)

    if (dst_reg !== null) begin
      if (axi_tran.log2_beat_size !== PAL_BYTES_4) begin
        is_access_reg_allowed = 0;
      end

      if (axi_tran.beat_size_in_bytes !== 4) begin
        is_access_reg_allowed = 0;
      end

      if (axi_tran.burst_length !== 1) begin
        is_access_reg_allowed = 0;
      end
    end
  end

  // return result
  `uvm_info(debug_str, $sformatf("is_valid_src[%0d], is_byte_allign[%0d], is_access_reg_allowed[%0d], is_valid_burst[%0d]",
      is_valid_src, is_byte_allign, is_access_reg_allowed, is_valid_burst), UVM_HIGH)

  return (is_valid_src && is_byte_allign && is_access_reg_allowed && is_valid_burst);

endfunction : is_valid_axi_sub_attributes

//-----------------------------------------------------------------
// Function: is_valid_fw_cmd
//
function bit sinc_sys_cfg::is_valid_fw_cmd(int fw_cmd_in_int);

  bit result = 0;

  if (fw_cmd_in_int inside {m__fw_cmd_list}) begin
    result = 1;
  end

  `uvm_info("SYS_CFG_DEBUG", $sformatf("is_valid_fw_cmd[%0d]", result), UVM_HIGH)

  return (result);

endfunction : is_valid_fw_cmd

//-----------------------------------------------------------------
// Function: get_fw_cmd_type
//
function sinc_parameters_pkg::sinc_fw_cmd_e sinc_sys_cfg::get_fw_cmd_type(int fw_cmd_in_int);

  if (is_valid_fw_cmd(fw_cmd_in_int)) begin
    case (fw_cmd_in_int)
      int'(sinc_parameters_pkg::SINC_SET_INIT_STATE): begin
        return (sinc_parameters_pkg::SINC_SET_INIT_STATE);
      end
      int'(sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE): begin
        return (sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE);
      end
      int'(sinc_parameters_pkg::SINC_SINC_RESET): begin
        return (sinc_parameters_pkg::SINC_SINC_RESET);
      end
      int'(sinc_parameters_pkg::SINC_SINC_REINIT): begin
        return (sinc_parameters_pkg::SINC_SINC_REINIT);
      end
      int'(sinc_parameters_pkg::SINC_ENCR_BLOCK): begin
        return (sinc_parameters_pkg::SINC_ENCR_BLOCK);
      end
      int'(sinc_parameters_pkg::SINC_DISABLE_RESET): begin
        return (sinc_parameters_pkg::SINC_DISABLE_RESET);
      end
      int'(sinc_parameters_pkg::SINC_DISABLE_REINIT): begin
        return (sinc_parameters_pkg::SINC_DISABLE_REINIT);
      end
      int'(sinc_parameters_pkg::SINC_AES_TEST_EN): begin
        return (sinc_parameters_pkg::SINC_AES_TEST_EN);
      end
      int'(sinc_parameters_pkg::SINC_AES_TEST_DISABLE): begin
        return (sinc_parameters_pkg::SINC_AES_TEST_DISABLE);
      end
      default : return (sinc_parameters_pkg::SINC_FW_UNMAPPED);
    endcase
  end

  return (sinc_parameters_pkg::SINC_FW_UNMAPPED);

endfunction : get_fw_cmd_type

//-----------------------------------------------------------------
// Function: get_valid_rand_src_comp
//
// NOTE: As function used by constraint, there can not be any print message construct, commented print messages are used for debug purpose
function sinc_comp_e sinc_sys_cfg::get_valid_rand_src_comp(sinc_comp_e dst_comp, sinc_axi_cmd_e axi_cmd, bit is_valid_slot=0, uvm_reg reg_handler = null);
  /*
   int rand_index;
   sinc_comp_list_t r_comp_list;
   sinc_comp_e r_src_comp;

   // `uvm_info("SINC_SYS_CFG:", $sformatf("Get valid random source component for accessing %0s, %0s, is_valid_slot[%0d] ", dst_comp, axi_cmd, is_valid_slot), UVM_HIGH);

   case (dst_comp)
   sinc_env_pkg::SINC_MPU: begin
   if (axi_cmd == SINC_AXI_READ) begin
   if (is_valid_slot) begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_valid_key_rd_access_comp_list;
   end else begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_invalid_key_rd_access_comp_list;
   end
   end else if (axi_cmd == SINC_AXI_WRITE) begin
   if (is_valid_slot) begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_valid_key_wr_access_comp_list;
   end else begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_invalid_key_wr_access_comp_list;
   end
   end
   end

   sinc_env_pkg::SINC_LUT: begin
   // LUT access has no limitation on command/slot attribute
   r_comp_list = m_comp_cfg[SINC_LUT].m_valid_mstr_list;
   end

   sinc_env_pkg::SINC_REG: begin
   // Reg access has no limitation on command/slot attribute
   r_comp_list = m_comp_cfg[SINC_REG].m_valid_mstr_list;
   end

   default : begin
   return sinc_env_pkg::SINC_NULL;
   //`uvm_error("get_comp_type", $sformatf("Unknown axi id %s\n", axi_id))
   end
   endcase

   // In VCS, random constraint need to pass specific value instead of array for assignment, thus we need to do the randomization here
   if (r_comp_list.size()) begin
   rand_index = $urandom_range(r_comp_list.size()-1, 0);
   end else begin
   //`uvm_info("SINC_SYS_CFG:", $sformatf("No valid source component found"), UVM_HIGH);
   end

   // return legal initiator source component
   r_src_comp = r_comp_list[rand_index];

   //`uvm_info("SINC_SYS_CFG:", $sformatf("Return valid random source component [%0s], from list [%0p]", r_src_comp, r_comp_list), UVM_HIGH);

   return r_src_comp;
   */

endfunction : get_valid_rand_src_comp

//-----------------------------------------------------------------
// Function: get_valid_rand_src_comp_test
//
// function sinc_comp_e sinc_sys_cfg::get_valid_rand_src_comp_test(sinc_comp_e dst_comp, sinc_axi_cmd_e axi_cmd, bit is_valid_slot=0, int reg_handler_index=0);
function sinc_comp_e sinc_sys_cfg::get_valid_rand_src_comp_test(sinc_comp_e dst_comp, sinc_axi_cmd_e axi_cmd, bit is_valid_slot=0, uvm_reg reg_handler = null);
  /*
   // sinc_comp_e r_src_comp;

   // r_src_comp = SINC_AES;
   // return r_src_comp;
   int rand_index;
   sinc_comp_list_t r_comp_list;
   sinc_comp_e r_src_comp;

   `uvm_info("SINC_SYS_CFG:", $sformatf("Get valid random source component for accessing %0s, %0s, is_valid_slot[%0d] ", dst_comp, axi_cmd, is_valid_slot), UVM_HIGH);

   case (dst_comp)
   sinc_env_pkg::SINC_KEY: begin
   if (axi_cmd == SINC_AXI_READ) begin
   if (is_valid_slot) begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_valid_key_rd_access_comp_list;
   end else begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_invalid_key_rd_access_comp_list;
   end
   end else if (axi_cmd == SINC_AXI_WRITE) begin
   if (is_valid_slot) begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_valid_key_wr_access_comp_list;
   end else begin
   r_comp_list = m_comp_cfg[SINC_KEY].m_invalid_key_wr_access_comp_list;
   end
   end
   end

   sinc_env_pkg::SINC_LUT: begin
   // LUT access has no limitation on command/slot attribute
   r_comp_list = m_comp_cfg[SINC_LUT].m_valid_mstr_list;
   end

   default : begin
   return sinc_env_pkg::SINC_NULL;
   //`uvm_error("get_comp_type", $sformatf("Unknown axi id %s\n", axi_id))
   end
   endcase

   // In VCS, random constraint need to pass specific value instead of array for assignment, thus we need to do the randomization here
   if (r_comp_list.size()) begin
   rand_index = $urandom_range(r_comp_list.size()-1, 0);
   end else begin
   `uvm_info("SINC_SYS_CFG:", $sformatf("No valid source component found"), UVM_HIGH);
   end

   // return legal initiator source component
   r_src_comp = r_comp_list[rand_index];

   `uvm_info("SINC_SYS_CFG:", $sformatf("Return valid random source component [%0s], from list [%0p]", r_src_comp, r_comp_list), UVM_HIGH);

   return r_src_comp;
   */
endfunction : get_valid_rand_src_comp_test

//-----------------------------------------------------------------
// Function: get_compe_by_axi_id_type
// Returns component type of enum. This should go to sys cfg
// Component types should be leaf level without subtypes
function sinc_comp_e sinc_sys_cfg::get_compe_by_axi_id(int axi_id);
  case (axi_id)
    sinc_parameters_pkg::SP_MST_ID : begin
      return (sinc_env_pkg::SINC_SP);
    end

    default : begin
      return (sinc_env_pkg::SINC_NULL);
      //`uvm_error("get_comp_type", $sformatf("Unknown axi id %s\n", axi_id))
    end
  endcase

endfunction : get_compe_by_axi_id

//-----------------------------------------------------------------
// Function: get_compe_by_axi_id_type
// Returns component type of enum. This should go to sys cfg
// Component types should be leaf level without subtypes
function int sinc_sys_cfg::get_axi_id_by_compe(sinc_comp_e axi_comp);
  case (axi_comp)
    sinc_env_pkg::SINC_SP : begin
      return (sinc_parameters_pkg::SP_MST_ID);
    end

    default : `uvm_error("get_axi_id_by_compe", $sformatf("Unknown axi comp %s\n", axi_comp.name()))
  endcase
endfunction : get_axi_id_by_compe

//-----------------------------------------------------------------
// Function: get_addr_msb
//
function int sinc_sys_cfg::get_addr_msb (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_addr_msb);
endfunction : get_addr_msb

//-----------------------------------------------------------------
// Function: get_addr_lsb
//
function int sinc_sys_cfg::get_addr_lsb (sinc_comp_e comp);
  validate_comp (comp);
  return (m_comp_cfg[comp].m_addr_lsb);
endfunction : get_addr_lsb

//-----------------------------------------------------------------
// Function: init_comp_cfgs
//  Initializes config for each SINC component.
//
function void sinc_sys_cfg::init_comp_cfgs ();
  // int key_num = sinc_parameters_pkg::KEY_VAULT_KEY_SLOTS;
  // int lut_num = sinc_parameters_pkg::KEY_VAULT_LUT_SLOTS;
  sinc_env_pkg::sinc_comp_e comp_type;
  sinc_env_pkg::sinc_cmd_e  cmd;
  // sinc_env_pkg::sinc_cpu_cmd_e  cpu_cmd;

  // determine available fw commands
  begin
    sinc_fw_cmd_e fw_cmd = fw_cmd.first();
    while (fw_cmd != fw_cmd.last()) begin
      m__fw_cmd_list.push_back(fw_cmd);
      m__fw_cmd_hash[fw_cmd] = 1;
      `uvm_info("sinc_sys_config:", $sformatf("Add %0s as m__fw_cmd_list", fw_cmd.name()), UVM_LOW)
      fw_cmd = fw_cmd.next();
    end
  end

  begin
    // cache_state_e _cache_state = _cache_state.first();
    // sinc_mstr_type_e mstr_comp = mstr_comp.first();
    //  while (mstr_comp != mstr_comp.last()) begin
    //    m__comp_master_list.push_back(mstr_comp);
    //    mstr_comp = mstr_comp.next();
    // end
  end

  // start configuring components from Initiator's perspective

  // config SINC
  m_comp_cfg[SINC_SINC]                      = new("SINC_MPU_comp_cfg");
  m_comp_cfg[SINC_SINC].m_comp_type          = sinc_env_pkg::SINC_SINC;
  m_comp_cfg[SINC_SINC].m_comp_type_name     = "SINC";
  m_comp_cfg[SINC_SINC].m_type_instance_name = "SINC_SINC";
  m_comp_cfg[SINC_SINC].m_instance_id        = 0;
  foreach (m__fw_cmd_list[i]) begin
    sinc_fw_cmd_e cmd = m__fw_cmd_list[i];
    construct_fw_operation_list_with_cmd_name(cmd.name());
  end

  // config MPU - CREG MPU request can access MPU R/W
  // fixme-hw: MPU config need to be reviewed after MPU UVC is ready
  m_comp_cfg[SINC_MPU]                      = new("SINC_MPU_comp_cfg");
  m_comp_cfg[SINC_MPU].m_comp_type          = sinc_env_pkg::SINC_MPU;
  m_comp_cfg[SINC_MPU].m_comp_type_name     = "MPU";
  m_comp_cfg[SINC_MPU].m_type_instance_name = "SINC_MPU";
  m_comp_cfg[SINC_MPU].m_instance_id        = 0;
  m_comp_cfg[SINC_MPU].m_is_subordinate     = 1;
  m_comp_cfg[SINC_MPU].m_start_addr         = 0;
  m_comp_cfg[SINC_MPU].m_end_addr           = 13'h1FFF;

  // config CACHE - SP CPU MEM request can access CACHE region
  m_comp_cfg[SINC_CACHE]                      = new("SINC_CACHE_comp_cfg");
  m_comp_cfg[SINC_CACHE].m_comp_type          = sinc_env_pkg::SINC_CACHE;
  m_comp_cfg[SINC_CACHE].m_comp_type_name     = "CACHE";
  m_comp_cfg[SINC_CACHE].m_type_instance_name = "SINC_CACHE";
  m_comp_cfg[SINC_CACHE].m_instance_id        = 0;
  m_comp_cfg[SINC_CACHE].m_is_subordinate     = 1;
  m_comp_cfg[SINC_CACHE].m_num_cache_lines    = sinc_parameters_pkg::SINC_CACHE_LINE_NUM;
  m_comp_cfg[SINC_CACHE].m_base_addr          = 0; // from CPU's perspective
  m_comp_cfg[SINC_CACHE].m_start_addr         = sinc_parameters_pkg::SINC_CACHE_START_ADDR; // from CPU's perspective
  m_comp_cfg[SINC_CACHE].m_end_addr           = sinc_parameters_pkg::SINC_CACHE_END_ADDR; // from CPU's perspective

  // config VTAG
  // Skip. Due to VTAG is not accessible directly from outside of SINC, managed by hardware.

  // config KSU - SINC AXI MGR request can access KSU
  m_comp_cfg[SINC_KSU]                      = new("SINC_KSU_comp_cfg");
  m_comp_cfg[SINC_KSU].m_comp_type          = sinc_env_pkg::SINC_KSU;
  m_comp_cfg[SINC_KSU].m_comp_type_name     = "KSU";
  m_comp_cfg[SINC_KSU].m_type_instance_name = "SINC_KSU";
  m_comp_cfg[SINC_KSU].m_instance_id        = 0;
  m_comp_cfg[SINC_KSU].m_is_subordinate     = 1;
  m_comp_cfg[SINC_KSU].m_start_addr         = sinc_parameters_pkg::SINC_KSU_START_ADDR; // from SINC's perspective
  m_comp_cfg[SINC_KSU].m_end_addr           = sinc_parameters_pkg::SINC_KSU_END_ADDR; // from SINC's perspective

  // config RNG - SINC AXI MGR request can access RNG
  m_comp_cfg[SINC_RNG]                      = new("SINC_RNG_comp_cfg");
  m_comp_cfg[SINC_RNG].m_comp_type          = sinc_env_pkg::SINC_RNG;
  m_comp_cfg[SINC_RNG].m_comp_type_name     = "RNG";
  m_comp_cfg[SINC_RNG].m_type_instance_name = "SINC_RNG";
  m_comp_cfg[SINC_RNG].m_instance_id        = 0;
  m_comp_cfg[SINC_RNG].m_is_subordinate     = 1;
  m_comp_cfg[SINC_RNG].m_start_addr         = sinc_parameters_pkg::SINC_RNG_START_ADDR; // from SINC's perspective
  m_comp_cfg[SINC_RNG].m_end_addr           = sinc_parameters_pkg::SINC_RNG_END_ADDR; // fixme: not mentioned in MAS

  // config SHAREDRAM - SINC AXI MGR request can access SHAREDRAM
  m_comp_cfg[SINC_SHAREDRAM]                      = new("SINC_SHAREDRAM_comp_cfg");
  m_comp_cfg[SINC_SHAREDRAM].m_comp_type          = sinc_env_pkg::SINC_SHAREDRAM;
  m_comp_cfg[SINC_SHAREDRAM].m_comp_type_name     = "SHAREDRAM";
  m_comp_cfg[SINC_SHAREDRAM].m_type_instance_name = "SINC_SHAREDRAM";
  m_comp_cfg[SINC_SHAREDRAM].m_instance_id        = 0;
  m_comp_cfg[SINC_SHAREDRAM].m_is_subordinate     = 1;
  m_comp_cfg[SINC_SHAREDRAM].m_start_addr         = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR; // from SINC's perspective
  m_comp_cfg[SINC_SHAREDRAM].m_end_addr           = sinc_parameters_pkg::SINC_SHAREDRAM_END_ADDR; // fixme: not mentioned in MAS

  // config DMB - SINC AXI MGR request can access DMB
  m_comp_cfg[SINC_DMB]                      = new("SINC_DMB_comp_cfg");
  m_comp_cfg[SINC_DMB].m_comp_type          = sinc_env_pkg::SINC_DMB;
  m_comp_cfg[SINC_DMB].m_comp_type_name     = "DMB";
  m_comp_cfg[SINC_DMB].m_type_instance_name = "SINC_DMB";
  m_comp_cfg[SINC_DMB].m_instance_id        = 0;
  m_comp_cfg[SINC_DMB].m_is_subordinate     = 1;
  m_comp_cfg[SINC_DMB].m_start_addr         = sinc_parameters_pkg::SINC_DMB_START_ADDR; // from SINC's perspective
  m_comp_cfg[SINC_DMB].m_end_addr           = sinc_parameters_pkg::SINC_DMB_END_ADDR; //

  // config REG
  m_comp_cfg[SINC_REG]                      = new("SINC_REG_comp_cfg");
  m_comp_cfg[SINC_REG].m_comp_type          = sinc_env_pkg::SINC_REG;
  m_comp_cfg[SINC_REG].m_comp_type_name     = "REG";
  m_comp_cfg[SINC_REG].m_type_instance_name = "SINC_REG";
  m_comp_cfg[SINC_REG].m_instance_id        = 0;
  m_comp_cfg[SINC_REG].m_is_subordinate     = 1;
  m_comp_cfg[SINC_REG].m_start_addr         = sinc_parameters_pkg::SINC_REG_START_ADDR;
  m_comp_cfg[SINC_REG].m_end_addr           = sinc_parameters_pkg::SINC_REG_END_ADDR;

  /********************** Config Cache Slots End **********************/
  /*
   for (int id=0; id < sinc_parameters_pkg::SINC_CACHE_LINE_NUM; id++) begin
   string cache_line_id = $sformatf("CACHE_LINE_%0d", id);
   m_comp_cfg[SINC_CACHE].m_line_cfg[id] = new({"SINC", cache_line_id, "m_comp_cfg"});
   m_comp_cfg[SINC_CACHE].m_line_cfg[id].comp_type_name = "CACHE_LINE";
   m_comp_cfg[SINC_CACHE].m_line_cfg[id].type_instance_name = cache_line_id;
   m_comp_cfg[SINC_CACHE].m_line_cfg[id].instance_id = id;
   m_comp_cfg[SINC_CACHE].m_line_cfg[id].start_addr = m_comp_cfg[SINC_CACHE].m_start_addr + (id * 'h200); // each memory line addr incre by 'h4

   m_comp_cfg[SINC_CACHE].m_line_cfg[id].init(m_random_data_type);
   `uvm_info("sinc_sys_config:", $sformatf("Configure %0s[%0s], with start address: 'h%0h ", m_comp_cfg[SINC_CACHE].m_line_cfg[id].comp_type_name,
   m_comp_cfg[SINC_CACHE].m_line_cfg[id].type_instance_name, m_comp_cfg[SINC_CACHE].m_slot_cfg[id].start_addr), UVM_DEBUG);
   end
   */

  `uvm_info("SINC_SYS_CFG:", $sformatf("CACHE m_COMP_CFG = \n%s ", m_comp_cfg[SINC_CACHE].sprint()), UVM_HIGH)

  /********************** Config SINC Register Begin **********************/
  m_comp_cfg[SINC_REG].m_is_reg = 1;

  `uvm_info("SINC_SYS_CFG:", $sformatf("REG m_COMP_CFG = \n%s ", m_comp_cfg[SINC_REG].sprint()), UVM_HIGH)

  /********************** Config SP Start **********************/
  m_comp_cfg[SINC_SP]                      = new("SINC_SP_comp_cfg");
  m_comp_cfg[SINC_SP].m_comp_type          = SINC_SP;
  m_comp_cfg[SINC_SP].m_comp_type_name     = "SP";
  m_comp_cfg[SINC_SP].m_type_instance_name = "SINC_SP";
  m_comp_cfg[SINC_SP].m_is_initiator       = 1;
  m_comp_cfg[SINC_SP].m_is_axi_master      = 1;
  m_comp_cfg[SINC_SP].m_is_axi_intf        = 1;
  m_comp_cfg[SINC_SP].m_is_sp              = 1;

  // interface parameters
  m_comp_cfg[SINC_SP].m_addr_width = 32;

  // set up allowed cmd
  if (`SINC_CACHE_DISABLE_CPU_MEM_READ_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_CPU_READ);
  end
  if (`SINC_CACHE_DISABLE_CPU_MEM_WRITE_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_CPU_WRITE);
  end
  if (`SINC_CACHE_INIT_CPU_MEM_READ_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_CPU_READ);
  end
  if (`SINC_CACHE_INIT_CPU_MEM_WRITE_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_CPU_WRITE);
  end
  if (`SINC_CACHE_ACTIVE_CPU_MEM_READ_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_CPU_READ);
  end
  if (`SINC_CACHE_ACTIVE_CPU_MEM_WRITE_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_CPU_WRITE);
  end
  if (`SINC_CACHE_FAIL_CPU_MEM_READ_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_CPU_READ);
  end
  if (`SINC_CACHE_FAIL_CPU_MEM_WRITE_ALLOWED) begin
    m_comp_cfg[SINC_SP].m_valid_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_CPU_WRITE);
  end

  `uvm_info("SP cfg", $sformatf("SP m_COMP_CFG = \n%s ", m_comp_cfg[SINC_SP].sprint()), UVM_HIGH)
  /********************** Config SP End **********************/

  // set up allowed fw_cmd
  if (`SINC_SINC_RESET_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_SINC_RESET);
  end
  if (`SINC_SINC_RESET_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_SINC_RESET);
  end
  if (`SINC_SINC_RESET_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_SINC_RESET);
  end
  if (`SINC_SINC_RESET_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_SINC_RESET);
  end

  if (`SINC_SET_INIT_STATE_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_SET_INIT_STATE);
  end
  if (`SINC_SET_INIT_STATE_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_SET_INIT_STATE);
  end
  if (`SINC_SET_INIT_STATE_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_SET_INIT_STATE);
  end
  if (`SINC_SET_INIT_STATE_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_SET_INIT_STATE);
  end

  if (`SINC_ENCR_BLOCK_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_ENCR_BLOCK);
  end
  if (`SINC_ENCR_BLOCK_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_ENCR_BLOCK);
  end
  if (`SINC_ENCR_BLOCK_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_ENCR_BLOCK);
  end
  if (`SINC_ENCR_BLOCK_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_ENCR_BLOCK);
  end

  if (`SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_SET_CACHE_ACTIVE_STATE);
  end
  if (`SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_SET_CACHE_ACTIVE_STATE);
  end
  if (`SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_SET_CACHE_ACTIVE_STATE);
  end
  if (`SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_SET_CACHE_ACTIVE_STATE);
  end

  if (`SINC_AES_TEST_EN_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_AES_TEST_EN);
  end
  if (`SINC_AES_TEST_EN_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_AES_TEST_EN);
  end
  if (`SINC_AES_TEST_EN_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_AES_TEST_EN);
  end
  if (`SINC_AES_TEST_EN_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_AES_TEST_EN);
  end

  if (`SINC_AES_TEST_DISABLE_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_AES_TEST_DISABLE);
  end
  if (`SINC_AES_TEST_DISABLE_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_AES_TEST_DISABLE);
  end
  if (`SINC_AES_TEST_DISABLE_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_AES_TEST_DISABLE);
  end
  if (`SINC_AES_TEST_DISABLE_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_AES_TEST_DISABLE);
  end

  if (`SINC_DISABLE_RESET_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_DISABLE_RESET);
  end
  if (`SINC_DISABLE_RESET_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_DISABLE_RESET);
  end
  if (`SINC_DISABLE_RESET_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_DISABLE_RESET);
  end
  if (`SINC_DISABLE_RESET_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_DISABLE_RESET);
  end

  if (`SINC_DISABLE_REINIT_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_DISABLE_REINIT);
  end
  if (`SINC_DISABLE_REINIT_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_DISABLE_REINIT);
  end
  if (`SINC_DISABLE_REINIT_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_DISABLE_REINIT);
  end
  if (`SINC_DISABLE_REINIT_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_DISABLE_REINIT);
  end

  if (`SINC_SINC_REINIT_IN_CACHE_DISABLE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE].push_back(SINC_SINC_REINIT);
  end
  if (`SINC_SINC_REINIT_IN_CACHE_INIT_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE].push_back(SINC_SINC_REINIT);
  end
  if (`SINC_SINC_REINIT_IN_CACHE_ACTIVE_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE].push_back(SINC_SINC_REINIT);
  end
  if (`SINC_SINC_REINIT_IN_CACHE_FAIL_ALLOWED) begin
    m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE].push_back(SINC_SINC_REINIT);
  end

  begin
    string str;
    str = "\n ****************************************** \n";
    str = {str, $sformatf(" Print FW commands that allowed in cache states [%0s] \n", "DISABLE, INIT, ACTIVE, FAIL")};

    str = {str, $sformatf(" FW commands that allowed in cache states [%0s] \n", "DISABLE")};
    foreach (m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE][i]) begin
      str = {str, $sformatf(" [%0s] \n", m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_DISABLE_STATE][i].name())};
    end

    str = {str, $sformatf(" FW commands that allowed in cache states [%0s] \n", "INIT")};
    foreach (m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE][i]) begin
      str = {str, $sformatf(" [%0s] \n", m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_INIT_STATE][i].name())};
    end

    str = {str, $sformatf(" FW commands that allowed in cache states [%0s] \n", "ACTIVE")};
    foreach (m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE][i]) begin
      str = {str, $sformatf(" [%0s] \n", m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_ACTIVE_STATE][i].name())};
    end

    str = {str, $sformatf(" FW commands that allowed in cache states [%0s] \n", "FAIL")};
    foreach (m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE][i]) begin
      str = {str, $sformatf(" [%0s] \n", m_valid_fw_cmd_at_cache_state[sinc_parameters_pkg::CACHE_FAIL_STATE][i].name())};
    end

    str = {str, "\n ****************************************** \n"};
    `uvm_info("sinc_sys_config:", str, UVM_HIGH)
  end

endfunction : init_comp_cfgs

//-----------------------------------------------------------------
// Function: init_aes_cfg
//  Initializes AES config for using SINC
//
function void sinc_sys_cfg::init_aes_cfg ();
  string debug_str = "init_aes_cfg";
  m_aes_cfg = sinc_aes_packet::type_id::create("m_aes_cfg", , get_full_name());

  // randomize IVs(aes_iv_nonce_regs[3]), KEY data(m_key_data), key_slot(m_key_slot) -> key_address(m_key_axi_addr)
  if (!m_aes_cfg.randomize() with {
        m_aes_test_mode == 0;
        m_byte_count == 512;
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  `uvm_info("AES CFG", $sformatf("\nPrint AES CFG:\naes_iv_nonce_regs[0] = 'h%0h\naes_iv_nonce_regs[1] = 'h%0h\naes_iv_nonce_regs[2] = 'h%0h\nkey[%0d] = 'h%0h\nkey_address = 'h%0h ",
      m_aes_cfg.m_aes_iv_nonce_regs[0], m_aes_cfg.m_aes_iv_nonce_regs[1], m_aes_cfg.m_aes_iv_nonce_regs[2], m_aes_cfg.m_key_slot, m_aes_cfg.m_key_data, m_aes_cfg.m_key_axi_addr), UVM_HIGH)

endfunction : init_aes_cfg

//-----------------------------------------------------------------
// Function: Reinit_aes_cfg
//  Reinitializes AES config for using SINC
//
function void sinc_sys_cfg::reinit_aes_cfg ();
  string debug_str = "reinit_aes_cfg";

  // randomize IVs(aes_iv_nonce_regs[3]), KEY data(m_key_data), key_slot(m_key_slot) -> key_address(m_key_axi_addr)
  if (!m_aes_cfg.randomize() with {
        m_aes_test_mode == 0;
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", debug_str))
  end

  `uvm_info("AES CFG", $sformatf("\nPrint AES CFG after reinit:\naes_iv_nonce_regs[0] = 'h%0h\naes_iv_nonce_regs[1] = 'h%0h\naes_iv_nonce_regs[2] = 'h%0h\nkey[%0d] = 'h%0h\nkey_address = 'h%0h ",
      m_aes_cfg.m_aes_iv_nonce_regs[0], m_aes_cfg.m_aes_iv_nonce_regs[1], m_aes_cfg.m_aes_iv_nonce_regs[2], m_aes_cfg.m_key_slot, m_aes_cfg.m_key_data, m_aes_cfg.m_key_axi_addr), UVM_HIGH)

endfunction : reinit_aes_cfg

//-----------------------------------------------------------------
// Function: rand_sideband_cfg
//  Reinitializes sideband input config CINC
//
function void sinc_sys_cfg::rand_sideband_cfg ();
  string debug_str = "rand_sideband_cfg";

  if (!(std::randomize(m_sinc_mpu_disable) with {
          m_sinc_mpu_disable dist {
            0 := 90,
            1 := 10
          };
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize m_sinc_mpu_disable")
  end

  if (!(std::randomize(m_sinc_chkpt_spramnx) with {
          m_sinc_chkpt_spramnx dist {
            0 := 95,
            1 := 5
          };
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize m_sinc_chkpt_spramnx")
  end

  `uvm_info(debug_str, $sformatf("\n Side Band CFG: sinc_mpu_disable = 'h%0h, m_sinc_chkpt_spramnx = 'h%0h",
      m_sinc_mpu_disable, m_sinc_chkpt_spramnx ), UVM_HIGH)

endfunction : rand_sideband_cfg

function void sinc_sys_cfg::process_plusargs_and_populate_tb_cfg();
  string debug_str = "SINC_SYS_CFG_PROCESS_PLUSARGS";
  string tmp_str;

  tmp_str = "SINC_TB_CFG_DISABLE_ILLEGAL_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_disable_illegal_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_disable_illegal_req), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_NEVER_DIS_CMDS";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_never_dis_cmds)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_never_dis_cmds), UVM_LOW)
  end

  tmp_str = "SINC_STIMULUS_ALWAYS_CPU_ERASE_SAME";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_stimulus_always_cpu_erase_same)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_stimulus_always_cpu_erase_same), UVM_LOW)
  end
  
  tmp_str = "SINC_STIMULUS_ALWAYS_ERASE_DURING";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_stimulus_always_erase_during)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_stimulus_always_erase_during), UVM_LOW)
  end

  tmp_str = "SINC_STIMULUS_ALWAYS_CPU_DURING";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_stimulus_always_cpu_during)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_stimulus_always_cpu_during), UVM_LOW)
  end

  tmp_str = "SINC_STIMULUS_ALWAYS_AXI_DURING";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_stimulus_always_axi_during)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_stimulus_always_axi_during), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_USE_DES_CACHE_STATE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_use_des_cache_state)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_use_des_cache_state), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_BACKDOOR_PRELOAD_MEM";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_backdoor_preload_mem)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_backdoor_preload_mem), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_BACKDOOR_PRELOAD_MEM_NOT_ALL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_backdoor_preload_mem_not_all)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_backdoor_preload_mem_not_all), UVM_LOW)
  end


  tmp_str = "SINC_TB_SEQ_DES_CACHE_STATE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_des_cache_state)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_des_cache_state), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_NEVER_DO_AES_TEST_CMDS";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_never_do_aes_test_cmds)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_never_do_aes_test_cmds), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_ONLY_DO_AES_TEST_CMDS";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_only_do_aes_test_cmds)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_only_do_aes_test_cmds), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_DIS_ENCR_AUTH_CHECK";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_dis_encr_auth_check)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_dis_encr_auth_check), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_RAND_ENCR_AUTH_CHECK";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_rand_encr_auth_check)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_rand_encr_auth_check), UVM_LOW)
  end

  if((m_sinc_tb_seq_never_do_aes_test_cmds == 1) && (m_sinc_tb_seq_only_do_aes_test_cmds == 1)) begin
    `uvm_fatal(get_name(), $sformatf("m_SINC_TB_SEQ_ONLY_DO_AES_TEST_CMDS = %d and m_SINC_TB_SEQ_NEVER_DO_AES_TEST_CMDS = %d should not be set at the same time", m_sinc_tb_seq_only_do_aes_test_cmds, m_sinc_tb_seq_never_do_aes_test_cmds))
  end

  tmp_str = "SINC_TB_RANDOM_DATA_TYPE";
  if($value$plusargs({tmp_str, "=%s"}, m_random_data_type_str)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %s", tmp_str, m_random_data_type_str), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_AXI_READ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_axi_read_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_axi_read_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_axi_read_ratio) with {
            m_sinc_tb_seq_axi_read_ratio > 0;
            m_sinc_tb_seq_axi_read_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_AXI_READ_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_AXI_READ_RATIO = %d", tmp_str, m_sinc_tb_seq_axi_read_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_AXI_WRITE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_axi_write_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_axi_write_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_axi_write_ratio) with {
            m_sinc_tb_seq_axi_write_ratio > 0;
            m_sinc_tb_seq_axi_write_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_AXI_WRITE_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_AXI_WRITE_RATIO = %d", tmp_str, m_sinc_tb_seq_axi_write_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CPU_READ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cpu_read_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cpu_read_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_cpu_read_ratio) with {
            m_sinc_tb_seq_cpu_read_ratio > 0;
            m_sinc_tb_seq_cpu_read_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_CPU_READ_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CPU_READ_RATIO = %d", tmp_str, m_sinc_tb_seq_cpu_read_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CACHE_HIT_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cache_hit_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cache_hit_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_cache_hit_ratio) with {
            m_sinc_tb_seq_cache_hit_ratio > 0;
            m_sinc_tb_seq_cache_hit_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_CACHE_HIT_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CACHE_HIT_RATIO = %d", tmp_str, m_sinc_tb_seq_cache_hit_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CPU_WRITE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cpu_write_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cpu_write_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_cpu_write_ratio) with {
            m_sinc_tb_seq_cpu_write_ratio > 0;
            m_sinc_tb_seq_cpu_write_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_CPU_WRITE_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CPU_WRITE_RATIO = %d", tmp_str, m_sinc_tb_seq_cpu_write_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_ERASE_MEM_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_erase_mem_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_erase_mem_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_erase_mem_ratio) with {
            m_sinc_tb_seq_erase_mem_ratio > 0;
            m_sinc_tb_seq_erase_mem_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_ERASE_MEM_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_ERASE_MEM_RATIO = %d", tmp_str, m_sinc_tb_seq_erase_mem_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_MPU_READ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_mpu_read_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_mpu_read_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_mpu_read_ratio) with {
            m_sinc_tb_seq_mpu_read_ratio > 0;
            m_sinc_tb_seq_mpu_read_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_MPU_READ_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_MPU_READ_RATIO = %d", tmp_str, m_sinc_tb_seq_mpu_read_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_MPU_WRITE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_mpu_write_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_mpu_write_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_mpu_write_ratio) with {
            m_sinc_tb_seq_mpu_write_ratio > 0;
            m_sinc_tb_seq_mpu_write_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_MPU_WRITE_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_MPU_WRITE_RATIO = %d", tmp_str, m_sinc_tb_seq_mpu_write_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_FW_OPERATION_REQ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_fw_operation_req_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_fw_operation_req_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_fw_operation_req_ratio) with {
            m_sinc_tb_seq_fw_operation_req_ratio > 0;
            m_sinc_tb_seq_fw_operation_req_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_FW_OPERATION_REQ_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_FW_OPERATION_REQ_RATIO = %d", tmp_str, m_sinc_tb_seq_fw_operation_req_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_HW_RESET_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_hw_reset_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_hw_reset_ratio), UVM_LOW)
  end else begin
    if (!(std::randomize(m_sinc_tb_seq_hw_reset_ratio) with {
            m_sinc_tb_seq_hw_reset_ratio > 0;
            m_sinc_tb_seq_hw_reset_ratio < 100;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize m_SINC_TB_SEQ_HW_RESET_RATIO")
    end

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_HW_RESET_RATIO = %d", tmp_str, m_sinc_tb_seq_hw_reset_ratio), UVM_LOW)
  end  
  
  tmp_str = "SINC_TB_SEQ_W_CACHE_FAIL_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_w_cache_fail_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_w_cache_fail_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_w_cache_fail_ratio = 0;    

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_W_CACHE_FAIL_RATIO = %d", tmp_str, m_sinc_tb_seq_w_cache_fail_ratio), UVM_LOW)
  end  

  tmp_str = "SINC_TB_SEQ_CPU_REQ_DURING_ERASE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cpu_req_during_erase_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cpu_req_during_erase_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cpu_req_during_erase_ratio = 0;    

    `uvm_info(get_name(), $sformatf("%s set m_sinc_tb_seq_cpu_req_during_erase_ratio = %d", tmp_str, m_sinc_tb_seq_cpu_req_during_erase_ratio), UVM_LOW)
  end 

  tmp_str = "SINC_TB_SEQ_ERASE_DURING_CPU_REQ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_erase_during_cpu_req_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_erase_during_cpu_req_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_erase_during_cpu_req_ratio = 0;    

    `uvm_info(get_name(), $sformatf("%s set m_sinc_tb_seq_erase_during_cpu_req_ratio = %d", tmp_str, m_sinc_tb_seq_erase_during_cpu_req_ratio), UVM_LOW)
  end  

  tmp_str = "SINC_TB_SEQ_CMD_SET_INIT_STATE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_set_init_state_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_set_init_state_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_set_init_state_ratio = 30;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SET_INIT_STATE_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_set_init_state_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_SET_CACHE_ACTIVE_STATE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_set_cache_active_state)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_set_cache_active_state), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_set_cache_active_state = 30;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SET_CACHE_ACTIVE_STATE = %d", tmp_str, m_sinc_tb_seq_cmd_set_cache_active_state), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_AES_TEST_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_aes_test_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_aes_test_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_aes_test_ratio = 60;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_AES_TEST_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_aes_test_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_RESET_DISABLED_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reset_disabled_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_disabled_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reset_disabled_ratio = 5;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_RESET_DISABLED_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_disabled_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_REINIT_DISABLED_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio = 5;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_REINIT_DISABLED_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_USE_NON_BLOCKING_CPU_READ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_use_non_blocking_cpu_read)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_use_non_blocking_cpu_read), UVM_LOW)
  end else begin
    // use default value
  end

  tmp_str = "SINC_TB_SEQ_ALWAYS_EN_BACK_2_BACK";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_always_en_back_2_back)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_always_en_back_2_back), UVM_LOW)
  end else begin
    // use default value
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_RESET_INIT_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reset_init_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_init_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reset_init_ratio = 5;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_RESET_INIT_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_init_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_REINIT_INIT_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reinit_init_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_init_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reinit_init_ratio = 5;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_REINIT_INIT_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_init_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_RESET_ACTIVE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reset_active_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_active_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reset_active_ratio = 25;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_RESET_ACTIVE_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_active_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_REINIT_ACTIVE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reinit_active_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_active_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reinit_active_ratio = 25;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_REINIT_ACTIVE_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_active_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_RESET_FAILED_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reset_failed_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_failed_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reset_failed_ratio = 10;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_RESET_FAILED_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reset_failed_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_DISABLE_REINIT_FAILED_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_disable_reinit_failed_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_failed_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_disable_reinit_failed_ratio = 10;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_DISABLE_REINIT_FAILED_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_disable_reinit_failed_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_SINC_RESET_INIT_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_sinc_reset_init_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_init_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_sinc_reset_init_ratio = 10;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SINC_RESET_INIT_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_init_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_SINC_RESET_ACTIVE_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_sinc_reset_active_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_active_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_sinc_reset_active_ratio = 25;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SINC_RESET_ACTIVE_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_active_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_SINC_RESET_FAIL_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_sinc_reset_fail_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_fail_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_sinc_reset_fail_ratio = 80;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SINC_RESET_FAIL_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reset_fail_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_SINC_REINIT_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_sinc_reinit_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reinit_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_sinc_reinit_ratio = 25;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_SINC_REINIT_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_sinc_reinit_ratio), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_CMD_ENCR_BLOCK_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_cmd_encr_block_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_cmd_encr_block_ratio), UVM_LOW)
  end else begin
    m_sinc_tb_seq_cmd_encr_block_ratio = 50;

    `uvm_info(get_name(), $sformatf("%s set m_SINC_TB_SEQ_CMD_ENCR_BLOCK_RATIO = %d", tmp_str, m_sinc_tb_seq_cmd_encr_block_ratio), UVM_LOW)
  end

  tmp_str = "SINC_ENABLE_SPECIFIC_FAULT_ERR";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_enable_specific_fault_err)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_enable_specific_fault_err), UVM_LOW)
  end

  tmp_str = "SINC_TB_AXI_ERR_INJECTION_EN";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_axi_err_injection_en)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_axi_err_injection_en), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_ciu_cache_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_ciu_cache_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_cmu_ctrl_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_cmu_ctrl_fsm_illegal), UVM_LOW)
  end
  tmp_str = "SINC_FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_cache_state_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_cache_state_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_sinc_sub_state_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_sinc_sub_state_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_aes_ctrl_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_aes_ctrl_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_dma_r_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_dma_r_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_dma_w_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_dma_w_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_aes_keyexp_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_aes_keyexp_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_gpaes_mode_main_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_gpaes_mode_main_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_gpaes_ghash_mul_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_gpaes_ghash_mul_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_gpaes_mode_ghash_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_gpaes_mode_ghash_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_fault_error_type_gpaes_mode_sec_fsm_illegal)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_fault_error_type_gpaes_mode_sec_fsm_illegal), UVM_LOW)
  end

  tmp_str = "SINC_TB_SEQ_TRANS_NUM";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_tb_seq_trans_num)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_tb_seq_trans_num), UVM_LOW)
  end

  tmp_str = "SINC_TB_CACHE_LINE_POOL_SIZE";
  if($value$plusargs({tmp_str, "=%d"}, m_cache_line_pool_size)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_cache_line_pool_size), UVM_LOW)
  end

  tmp_str = "SINC_TB_ACCESS_WITHIN_CACHE_POOL";
  if($value$plusargs({tmp_str, "=%d"}, m_access_within_cache_pool)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_access_within_cache_pool), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_DISABLE_SEVERE_ERR_INJ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_disable_severe_err_inj)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_disable_severe_err_inj), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_AXI_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_rd_axi_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_rd_axi_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_AXI_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_wr_axi_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_wr_axi_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_CPU_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_rd_cpu_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_CPU_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_wr_cpu_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_MPU_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_wr_mpu_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_RD_MPU_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_rd_mpu_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_ERR_INJ_ON_WR_AXI_REQ";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_err_inj_on_wr_axi_req)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_err_inj_on_wr_axi_req), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_TRANSACTION_ERR_INJ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_transaction_err_inj_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_transaction_err_inj_ratio), UVM_LOW)
    if (m_sinc_rand_seq_enable_transaction_err_inj_ratio > 100) begin
      `uvm_fatal(get_name(), $sformatf("try to set m_SINC_RAND_SEQ_ENABLE_TRANSACTION_ERR_INJ_RATIO above 100: [%0d], please set the ratio under 100", m_sinc_rand_seq_enable_transaction_err_inj_ratio))
    end
  end else begin
    m_sinc_rand_seq_enable_transaction_err_inj_ratio = 50;
    `uvm_info(get_name(), $sformatf("%s without plusarg = %d", tmp_str, m_sinc_rand_seq_enable_transaction_err_inj_ratio), UVM_LOW)
  end

  tmp_str = "SINC_RAND_SEQ_ENABLE_STIMULUS_ERR_INJ_RATIO";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_rand_seq_enable_stimulus_err_inj_ratio)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_rand_seq_enable_stimulus_err_inj_ratio), UVM_LOW)
    if (m_sinc_rand_seq_enable_stimulus_err_inj_ratio > 100) begin
      `uvm_fatal(get_name(), $sformatf("try to set m_SINC_RAND_SEQ_ENABLE_STIMULUS_ERR_INJ_RATIO above 100: [%0d], please set the ratio under 100", m_sinc_rand_seq_enable_stimulus_err_inj_ratio))
    end
  end else begin
    m_sinc_rand_seq_enable_stimulus_err_inj_ratio = 0;
    `uvm_info(get_name(), $sformatf("%s without plusarg = %d", tmp_str, m_sinc_rand_seq_enable_stimulus_err_inj_ratio), UVM_LOW)

  end

  tmp_str = "SINC_ERR_STIMULUS_SET_INIT_RNG_SEED_FAILURE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_err_stimulus_set_init_rng_seed_failure)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_err_stimulus_set_init_rng_seed_failure), UVM_LOW)
  end else begin
    m_sinc_err_stimulus_set_init_rng_seed_failure = 0;
    `uvm_info(get_name(), $sformatf("%s without plusarg = %d", tmp_str, m_sinc_err_stimulus_set_init_rng_seed_failure), UVM_LOW)

  end

  tmp_str = "SINC_ERR_STIMULUS_INVALID_CMD_FOR_STATE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_err_stimulus_invalid_cmd_for_state)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_err_stimulus_invalid_cmd_for_state), UVM_LOW)
  end else begin
    m_sinc_err_stimulus_invalid_cmd_for_state = 0;
    `uvm_info(get_name(), $sformatf("%s without plusarg = %d", tmp_str, m_sinc_err_stimulus_invalid_cmd_for_state), UVM_LOW)
  end

  tmp_str = "SINC_ERR_STIMULUS_SET_ENCR_BLOCK_FAILURE";
  if($value$plusargs({tmp_str, "=%d"}, m_sinc_err_stimulus_set_encr_block_failure)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sinc_err_stimulus_set_encr_block_failure), UVM_LOW)
  end else begin
    m_sinc_err_stimulus_set_encr_block_failure = 0;
    `uvm_info(get_name(), $sformatf("%s without plusarg = %d", tmp_str, m_sinc_err_stimulus_set_encr_block_failure), UVM_LOW)

  end

endfunction : process_plusargs_and_populate_tb_cfg

//-----------------------------------------------------------------
// Function: construct_reg_list_with_reg_name
//   update register attribute list
//
function void sinc_sys_cfg::construct_reg_list_with_reg_name(string reg_name);
  string exist_string;
  string write_allow_string;
  string read_allow_string;
  string write_discard_in_cache_disable_string;
  string write_discard_in_cache_init_string;
  string write_discard_in_cache_active_string;
  string write_discard_in_cache_fail_string;

  reg_name                              = reg_name.toupper();
  exist_string                          = {reg_name, "_REG_EXIST"};
  write_allow_string                    = {reg_name, "_REG_WR"};
  read_allow_string                     = {reg_name, "_REG_RD"};
  write_discard_in_cache_disable_string = {reg_name, "_REG_WRITE_DISCARD_IN_CACHE_DISABLE"};
  write_discard_in_cache_init_string    = {reg_name, "_REG_WRITE_DISCARD_IN_CACHE_INIT"};
  write_discard_in_cache_active_string  = {reg_name, "_REG_WRITE_DISCARD_IN_CACHE_ACTIVE"};
  write_discard_in_cache_fail_string    = {reg_name, "_REG_WRITE_DISCARD_IN_CACHE_FAIL"};

  `uvm_info("SINC_SYS_CFG:", $sformatf("Check on register [%0s], exist_string[%0s]", reg_name, exist_string), UVM_HIGH)

  // R/W permission
  if (sinc_features_pkg::has_feature(exist_string)) begin
    // `uvm_info("SINC_SYS_CFG:", $sformatf("has exist_string [%0s] ", exist_string), UVM_HIGH);
    if ((sinc_features_pkg::get_feature(exist_string))) begin
      // `uvm_info("SINC_SYS_CFG:", $sformatf("get exist_string [%0s] ", exist_string), UVM_HIGH);
      if ((sinc_features_pkg::has_feature(write_allow_string))) begin
        // `uvm_info("SINC_SYS_CFG:", $sformatf("has [%0s] write_allow_string", write_allow_string), UVM_HIGH);
        if ((sinc_features_pkg::get_feature(write_allow_string))) begin
          // `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to writeable_reg_list list ", reg_name), UVM_HIGH);
          m_comp_cfg[SINC_REG].m_writeable_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
      if ((sinc_features_pkg::has_feature(read_allow_string))) begin
        if ((sinc_features_pkg::get_feature(read_allow_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to readable_reg_list list ", reg_name), UVM_HIGH)
          m_comp_cfg[SINC_REG].m_readable_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
    end
  end
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated readable_reg_list: %0p ", m_comp_cfg[SINC_REG].m_readable_reg_list), UVM_HIGH);
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated writable_reg_list: %0p ", m_comp_cfg[SINC_REG].m_writeable_reg_list), UVM_HIGH);

  // Write discard
  if (sinc_features_pkg::has_feature(exist_string)) begin
    if ((sinc_features_pkg::get_feature(exist_string))) begin
      if ((sinc_features_pkg::has_feature(write_discard_in_cache_disable_string))) begin
        if ((sinc_features_pkg::get_feature(write_discard_in_cache_disable_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to writeable_reg_list list ", reg_name), UVM_HIGH)
          m_comp_cfg[SINC_REG].m_write_discard_in_cache_disable_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
      if ((sinc_features_pkg::has_feature(write_discard_in_cache_init_string))) begin
        if ((sinc_features_pkg::get_feature(write_discard_in_cache_init_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to writeable_reg_list list ", reg_name), UVM_HIGH)
          m_comp_cfg[SINC_REG].m_write_discard_in_cache_init_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
      if ((sinc_features_pkg::has_feature(write_discard_in_cache_active_string))) begin
        if ((sinc_features_pkg::get_feature(write_discard_in_cache_active_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to writeable_reg_list list ", reg_name), UVM_HIGH)
          m_comp_cfg[SINC_REG].m_write_discard_in_cache_active_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
      if ((sinc_features_pkg::has_feature(write_discard_in_cache_fail_string))) begin
        if ((sinc_features_pkg::get_feature(write_discard_in_cache_fail_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Reg[%0s] to writeable_reg_list list ", reg_name), UVM_HIGH)
          m_comp_cfg[SINC_REG].m_write_discard_in_cache_fail_reg_list.push_back(get_reg_enum_from_string(reg_name));
        end
      end
    end
  end
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_disable_reg_list: %0p ", m_comp_cfg[SINC_REG].m_write_discard_in_cache_disable_reg_list), UVM_HIGH);
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_init_reg_list: %0p ", m_comp_cfg[SINC_REG].m_write_discard_in_cache_init_reg_list), UVM_HIGH);
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_active_reg_list: %0p ", m_comp_cfg[SINC_REG].m_write_discard_in_cache_active_reg_list), UVM_HIGH);
  // `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_fail_reg_list: %0p ", m_comp_cfg[SINC_REG].m_write_discard_in_cache_fail_reg_list), UVM_HIGH);

endfunction : construct_reg_list_with_reg_name

//-----------------------------------------------------------------
// Function: construct_fw_operation_with_cmd_name
//   update register attribute list
//
function void sinc_sys_cfg::construct_fw_operation_list_with_cmd_name(string cmd_name);
  string exist_string;
  string cmd_allow_string;
  string cmd_allow_in_cache_disable_string;
  string cmd_allow_in_cache_init_string;
  string cmd_allow_in_cache_active_string;
  string cmd_allow_in_cache_fail_string;

  cmd_name                          = cmd_name.toupper();
  exist_string                      = {cmd_name, "_FW_CMD_EXIST"};
  cmd_allow_in_cache_disable_string = {cmd_name, "_FW_CMD_ALLOWED_IN_CACHE_DISABLE"};
  cmd_allow_in_cache_init_string    = {cmd_name, "_FW_CMD_ALLOWED_IN_CACHE_INIT"};
  cmd_allow_in_cache_active_string  = {cmd_name, "_FW_CMD_ALLOWED_IN_CACHE_ACTIVE"};
  cmd_allow_in_cache_fail_string    = {cmd_name, "_FW_CMD_ALLOWED_IN_CACHE_FAIL"};

  `uvm_info("SINC_SYS_CFG:", $sformatf("Check on cmd [%0s], exist_string[%0s]", cmd_name, exist_string), UVM_HIGH)

  // FW cmd allowed list
  if (sinc_features_pkg::has_feature(exist_string)) begin
    if ((sinc_features_pkg::get_feature(exist_string))) begin
      if ((sinc_features_pkg::has_feature(cmd_allow_in_cache_disable_string))) begin
        if ((sinc_features_pkg::get_feature(cmd_allow_in_cache_disable_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Cmd[%0s] to fw_cmd_allow_in_cache_disable_cmd_list", cmd_name), UVM_HIGH)
          m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_disable_cmd_list.push_back(get_fw_cmd_enum_from_string(cmd_name));
        end
      end
      if ((sinc_features_pkg::has_feature(cmd_allow_in_cache_init_string))) begin
        if ((sinc_features_pkg::get_feature(cmd_allow_in_cache_init_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Cmd[%0s] to fw_cmd_allow_in_cache_init_cmd_list", cmd_name), UVM_HIGH)
          m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_init_cmd_list.push_back(get_fw_cmd_enum_from_string(cmd_name));
        end
      end
      if ((sinc_features_pkg::has_feature(cmd_allow_in_cache_active_string))) begin
        if ((sinc_features_pkg::get_feature(cmd_allow_in_cache_active_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Cmd[%0s] to fw_cmd_allow_in_cache_active_cmd_list", cmd_name), UVM_HIGH)
          m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_active_cmd_list.push_back(get_fw_cmd_enum_from_string(cmd_name));
        end
      end
      if ((sinc_features_pkg::has_feature(cmd_allow_in_cache_fail_string))) begin
        if ((sinc_features_pkg::get_feature(cmd_allow_in_cache_fail_string))) begin
          `uvm_info("SINC_SYS_CFG:", $sformatf("Push Cmd[%0s] to fw_cmd_allow_in_cache_fail_cmd_list", cmd_name), UVM_HIGH)
          m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_fail_cmd_list.push_back(get_fw_cmd_enum_from_string(cmd_name));
        end
      end
    end
  end

  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated fw_cmd_allow_in_cache_disable_cmd_list: %0p ", m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_disable_cmd_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated fw_cmd_allow_in_cache_init_cmd_list: %0p ", m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_init_cmd_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated fw_cmd_allow_in_cache_active_cmd_list: %0p ", m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_active_cmd_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated fw_cmd_allow_in_cache_fail_cmd_list: %0p ", m_comp_cfg[SINC_SINC].m_fw_cmd_allow_in_cache_fail_cmd_list), UVM_HIGH)

endfunction : construct_fw_operation_list_with_cmd_name

function int sinc_sys_cfg::convert_axuser_to_axiid (pal_axuser_t axuser);
  string debug_str = "CONVERT_AXUSER_TO_AXIID";

  return (axuser[`SINC_AXI_MID_USER_RANGE]);

endfunction : convert_axuser_to_axiid

function bit sinc_sys_cfg::get_aeb_sinc_dbg_mode_acc_en ();
  string debug_str = "GET_AEB_SINC_DBG_MODE_ACC_EN";

  // m_AEB_SINC_DBG_MODE_ACC_EN = m_sinc_vif.sinc_dbg_mode_acc_en_o;

  return (m_aeb_sinc_dbg_mode_acc_en);

endfunction : get_aeb_sinc_dbg_mode_acc_en

//-----------------------------------------------------------------
// Function: is_lut_check_pass
//
// fixme - not apply to sinc
function bit sinc_sys_cfg::is_lut_check_pass(sinc_lut_t lut, sinc_lut_t aruser, int index, bit is_internal_access);
  /*
   string debug_str = "IS_LUT_CHECK_PASS";

   // reference to SINC MAS 10.1 Functional Description
   bit t_sel = aruser[5];

   // LUT check won't perform for invalid key
   if (!lut[sinc_parameters_pkg::KEY_VAULT_LUT_VALID_SEL]) begin
   return 1;
   end

   // check on index
   if (lut[`SINC_LUT_INDEX_RANGE] !== index) begin
   return 0;
   end

   if (is_internal_access) begin
   // if ((aruser[5] !== 1) &&
   //         (lut[`SINC_LUT_VFID_RANGE] !== aruser[4:0])) begin
   //   `uvm_info(debug_str, $sformatf("Check fail for internal access due to missmatched VFID['h%0h] and AxUSER['h%0h].", lut, aruser), UVM_HIGH);
   //   return 0;
   // end
   case (t_sel)
   1'b0: begin
   // VFID[5] is 0 and match VFID[4:0].
   if ((lut[`SINC_LUT_PFVF_RANGE] !== 0) ||
   (lut[`SINC_LUT_VFID_RANGE] !== aruser[4:0])) begin
   `uvm_info(debug_str, $sformatf("Check fail (AXUSER[5]==0) due to missmatched VFID['h%0h] and AxUSER['h%0h].", lut, aruser), UVM_HIGH);
   return 0;
   end
   end
   1'b1: begin
   // VFID[5] is 1 but will not check other bits.
   if (lut[`SINC_LUT_PFVF_RANGE] !== 1) begin
   `uvm_info(debug_str, $sformatf("Check fail (AXUSER[5]==1) due to missmatched VFID['h%0h] and AxUSER['h%0h].", lut, aruser), UVM_HIGH);
   return 0;
   end
   end

   default : `uvm_error(debug_str, "Unplanned Case")
   endcase // case (t_sel)

   end else begin
   case (t_sel)
   1'b0: begin
   // VFID[5] is 0 and match VFID[4:0].
   if ((lut[`SINC_LUT_PFVF_RANGE] !== 0) ||
   (lut[`SINC_LUT_VFID_RANGE] !== aruser[4:0])) begin
   `uvm_info(debug_str, $sformatf("Check fail (AXUSER[5]==0) due to missmatched VFID['h%0h] and AxUSER['h%0h].", lut, aruser), UVM_HIGH);
   return 0;
   end
   end
   1'b1: begin
   // VFID[5] is 1 but will not check other bits.
   if (lut[`SINC_LUT_PFVF_RANGE] !== 1) begin
   `uvm_info(debug_str, $sformatf("Check fail (AXUSER[5]==1) due to missmatched VFID['h%0h] and AxUSER['h%0h].", lut, aruser), UVM_HIGH);
   return 0;
   end
   end

   default : `uvm_error(debug_str, "Unplanned Case")
   endcase // case (t_sel)
   end

   return 1;
   */

endfunction : is_lut_check_pass

//-----------------------------------------------------------------
// Function: is_internal_access
// fixme: not apply
function bit sinc_sys_cfg::is_internal_access(sinc_comp_e axi_comp);
  /*
   case (axi_comp)
   sinc_env_pkg::SINC_MP : begin
   return 1;
   end
   sinc_env_pkg::SINC_AES : begin
   return 1;
   end
   sinc_env_pkg::SINC_SHA : begin
   return 1;
   end
   sinc_env_pkg::SINC_UPKA : begin
   return 1;
   end
   sinc_env_pkg::SINC_CDED : begin
   return 0;
   end
   default : begin
   return 0;
   end
   endcase
   */
endfunction : is_internal_access

//-----------------------------------------------------------------
// Function: is_valid_reg_access
//
function bit sinc_sys_cfg::is_valid_reg_access (uvm_reg item, sinc_cmd_e cmd);
  string reg_name;

  if (item == null) begin
    return (0);
  end

  reg_name = item.get_name();

  // all Register features are using upper case
  reg_name = reg_name.toupper();

  // check on sinc cmu register that can only be accessed by AXI requests
  if ((cmd == sinc_env_pkg::SINC_AXI_READ) || (cmd == sinc_env_pkg::SINC_AXI_WRITE)) begin
    if (cmd == sinc_env_pkg::SINC_AXI_READ) begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_readable_reg_list}) begin
        return (1);
      end else begin
        return (0);
      end
    end
    if (cmd == sinc_env_pkg::SINC_AXI_WRITE) begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_writeable_reg_list}) begin
        return (1);
      end else begin
        return (0);
      end
    end
  end

endfunction : is_valid_reg_access

//-----------------------------------------------------------------
// Function: is_valid_encr_block_cmd
//
function bit sinc_sys_cfg::is_valid_encr_block_cmd (reg_data_t num_of_blocks, reg_data_t block_encr_num);
  if (num_of_blocks == 0) begin
    return (0);
  end

  return (1);

endfunction : is_valid_encr_block_cmd

//-----------------------------------------------------------------
// Function: is_reg_write_discarded
//
function bit sinc_sys_cfg::is_reg_write_discarded (uvm_reg item);

  string reg_name = item.get_name();

  // all Register features are using upper case
  reg_name = reg_name.toupper();

  case (m_cur_cache_state)
    sinc_parameters_pkg::CACHE_DISABLE_STATE: begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_write_discard_in_cache_disable_reg_list}) begin
        return (1);
      end
    end
    sinc_parameters_pkg::CACHE_INIT_STATE: begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_write_discard_in_cache_init_reg_list}) begin
        return (1);
      end
    end
    sinc_parameters_pkg::CACHE_ACTIVE_STATE: begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_write_discard_in_cache_active_reg_list}) begin
        return (1);
      end
    end
    sinc_parameters_pkg::CACHE_FAIL_STATE: begin
      if (get_reg_enum_from_string(reg_name) inside {m_comp_cfg[SINC_REG].m_write_discard_in_cache_fail_reg_list}) begin
        return (1);
      end
    end

    default : return (0);
  endcase

  return (0);

endfunction : is_reg_write_discarded

function bit sinc_sys_cfg::get_sinc_erase_in_progress ();
  string debug_str = "GET_SINC_ERASE_IN_PROGRESS";

  return (m_sinc_erase_in_progress);

endfunction : get_sinc_erase_in_progress

function void sinc_sys_cfg::set_sinc_erase_in_progress (logic a_value);
  string debug_str = "GET_SINC_ERASE_IN_PROGRESS";

  m_sinc_erase_in_progress = a_value;

  `uvm_info(debug_str, $sformatf("Set m_SINC_ERASE_IN_PROGRESS ['h%0h].", m_sinc_erase_in_progress), UVM_HIGH)
endfunction : set_sinc_erase_in_progress

function bit sinc_sys_cfg::get_is_fsm_fault_err_injected ();
  string debug_str = "GET_IS_FSM_FAULT_ERR_INJECTED";

  return (m_sinc_vif.is_fsm_fault_err_injected);

endfunction : get_is_fsm_fault_err_injected

task sinc_sys_cfg::set_is_fsm_fault_err_injected (logic a_value);
  string debug_str = "GET_IS_FSM_FAULT_ERR_INJECTED";

  m_sinc_vif.is_fsm_fault_err_injected = a_value;

  `uvm_info(debug_str, $sformatf("Set m_IS_FSM_FAULT_ERR_INJECTED ['h%0h].", m_sinc_vif.is_fsm_fault_err_injected), UVM_HIGH)
endtask : set_is_fsm_fault_err_injected

`endif // SINC_SYS_CFG
