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
// File        : sinc_sb_pkt_item.svh
// Description : 

`ifndef SINC_SB_PKT_ITEM
`define SINC_SB_PKT_ITEM

//---------------------------------
// HSP SINC Packet Class
//---------------------------------
class sinc_sb_pkt_item extends uvm_sequence_item;

  // Variable addr_dec_t
  // Address Decoder Type
  typedef sinc_env_pkg::sinc_address_decoder addr_dec_t;
  typedef reg_data_t reg_data_array_t [];

  // Variable: m_addr_dec
  // Address Decoder
  addr_dec_t m_addr_dec;

  // System Status
  bit m_is_exp_fatal;

  /**
   * The transaction ID for SInC requests.
   * set by create function.
   */
  int m_trans_id;

  /**
   * The transaction ID for SInC requests.
   * set by create function.
   */
  time m_req_tr_time;

  /**
   * The transaction ID for SInC requests.
   * set by check_complete function.
   */
  time m_req_done_time;

  /**
   * Indicator for completness of this item
   */
  bit m_is_completed = 0;

  /**
   * Indicator for Entry of Transaction.
   */
  sinc_sb_pkt_entry_e m_sinc_sb_pkt_entry;

  /**
   * General flag for condition checks
   */
  bit m_is_valid_req = 0;

  /**
   * Snapshot of Sys Config
   */
  sinc_sys_cfg            m_snapshot_sys_cfg;
  sinc_env_configuration  m_top_configuration;
  sinc_cache_state_type_e m_cur_cache_state;
  sinc_cache_state_type_e predicted_cur_cache_state;
  reg_data_t              m_snapshot_ext_block_base_addr;
  reg_data_t              m_snapshot_ext_auth_tag_base_addr;
  reg_data_t              m_snapshot_block_encr_num;
  reg_data_t              m_snapshot_num_of_blocks;
  reg_data_t              m_snapshot_block_encr_addr;
  reg_data_t              m_snapshot_block_encr_key;
  reg_data_t              m_snapshot_perf_cntr_ctrl;
  bit                     m_snapshot_hit_cntr_en;
  bit                     m_snapshot_miss_cntr_en;
  bit                     m_snapshot_lat_cntr_en;
  reg_data_t              m_snapshot_hit_cntr_lower;
  reg_data_t              m_snapshot_hit_cntr_upper;
  reg_data_t              m_snapshot_miss_cntr_lower;
  reg_data_t              m_snapshot_miss_cntr_upper;
  reg_data_t              m_snapshot_lat_cntr_lower;
  reg_data_t              m_snapshot_lat_cntr_upper;
  bit                     m_snapshot_is_key_fetched         = 0;
  bit                     m_snapshot_aes_test_mode_en       = 0;
  // From subsystem defines
  reg_data_t              m_snapshot_rng_base;
  reg_data_t              m_snapshot_ksu_base;
  reg_data_t              m_snapshot_sharedram_base;

  // MPU config
  bit m_snapshot_mpu_cfg_mpu_disable   = 0;
  bit m_snapshot_mpu_cfg_chkpt_spramnx = 0;

  /**
   * SINC SideBand Status
   */
  bit                               m_exp_sinc_done   = 0; // must check in self_check()
  sinc_monitor_pkg::sinc_sideband_e m_sinc_done_q[$];
  int                               m_sinc_done_num;
  bit                               m_exp_sinc_error  = 0; // must check in self_check()
  sinc_monitor_pkg::sinc_sideband_e m_sinc_error_q[$];
  int                               m_sinc_error_num;

  /**
   * SINC MPU Sideband
   */
  bit                   m_exp_mpu_err_accvio  = 0; // must check in self_check()
  ccpui_mpu_transaction m_mpu_err_accvio_q[$];

  /**
   * SInC Memory Activities
   */
  //  Memory Activities Dynamic Array is expected flag
  bit m_exp_cache_mem; // must check in self_check()

  // SINC fetch DMB block
  bit             m_exp_block_fetch           = 0;
  bit             m_exp_block_fetch_cancelled = 0;
  bit             m_is_update_csd;
  //  Memory Queue
  mem_transaction m_cache_mem_pkt_q[$];
  // Memory transaction num
  int             m_cache_mem_transaction_num;
  // Valid lines per set
  int             m_valid_lines_per_set;
  // set in cache active state if cache hit
  bit             m_is_cache_hit              = 0;

  /**
   * Access information
   */
  sinc_comp_e m_req_src;
  sinc_comp_e m_req_dst;
  sinc_cmd_e  m_req_cmd;
  bit         m_is_cpu_mem_req;
  bit         m_is_axi_sub_req;
  bit         m_is_axi_mgr_req;
  bit         m_is_mpu_req;
  bit         m_is_creg_erase_req;

  /**
   * AXI SUB request expectations Begin
   */

  // address phase req
  pal_axi_xaction m_sub_addr_p_tran;

  // expect AXI SUB slave error
  bit             m_exp_sub_slv_err;
  // expect read response
  bit             m_exp_axi_sub_rd_resp;      // must check in self_check()
  pal_axi_xaction m_axi_sub_rd_resp_tran_q[$];
  // expect write response
  bit             m_exp_axi_sub_wr_resp;      // must check in self_check()
  pal_axi_xaction m_axi_sub_wr_resp_tran_q[$];

  // registers
  sinc_axi_data_t m_exp_reg_data_addr_p[];
  sinc_axi_data_t m_exp_reg_data_resp_p[];
  sinc_axi_data_t m_act_reg_data_resp_p_data;
  uvm_reg         m_dst_reg;
  bit             m_is_status_read;
  bit             m_is_reg_write_discarded;
  sinc_reg_data_t m_write_reg_data;

  // flags for axi violations
  bit m_is_invalid_axi_attributes;
  /**
   * AXI SUB request expectations End
   */

  /**
   * AXI MGR request expectations Begin
   */

  // address phase requests
  // expect AXI MGR slave error
  bit m_exp_mgr_slv_err;

  // expect read request and response
  bit             m_exp_axi_mgr_rd_req;                             // must check in self_check()
  pal_axi_xaction m_axi_mgr_rd_req_tran_q[$];
  pal_axi_xaction m_axi_mgr_rd_resp_tran_q[$];
  int             m_exp_axi_mgr_rd_size;                            // in bytes
  int             m_act_axi_mgr_rd_size_received;                   // in bytes
  pal_axi_xaction m_act_rng_data_axi_mgr_rd_resp_tran_q[$];
  pal_axi_xaction m_act_ksu_data_axi_mgr_rd_resp_tran_q[$];
  pal_axi_xaction m_act_sharedram_data_axi_mgr_rd_resp_tran_q[$];
  pal_axi_xaction m_act_dmb_block_data_axi_mgr_rd_resp_tran_q[$];
  pal_axi_xaction m_act_dmb_auth_tag_data_axi_mgr_rd_resp_tran_q[$];
  bit [7:0]       m_act_ksu_r_data[$];
  bit [7:0]       m_act_rng_r_data[$];
  bit [7:0]       m_act_sharedram_r_data[$];
  bit [7:0]       m_act_dmb_block_r_data[$];
  bit [7:0]       m_act_dmb_auth_tag_r_data[$];
  bit [7:0]       m_exp_ksu_r_data[$];
  bit [7:0]       m_exp_rng_r_data[$];
  bit [7:0]       m_exp_sharedram_r_data[$];
  bit [7:0]       m_exp_dmb_block_r_data[$];
  bit [7:0]       m_exp_dmb_auth_tag_r_data[$];

  // expect write request and response
  bit             m_exp_axi_mgr_wr_req;                             // must check in self_check()
  pal_axi_xaction m_axi_mgr_wr_req_tran_q[$];
  pal_axi_xaction m_axi_mgr_wr_resp_tran_q[$];
  int             m_exp_axi_mgr_wr_size;                            // in bytes
  int             m_act_axi_mgr_wr_size_received;                   // in bytes
  pal_axi_xaction m_act_rng_data_axi_mgr_wr_resp_tran_q[$];
  pal_axi_xaction m_act_ksu_data_axi_mgr_wr_resp_tran_q[$];
  pal_axi_xaction m_act_sharedram_data_axi_mgr_wr_resp_tran_q[$];
  pal_axi_xaction m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[$];
  pal_axi_xaction m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[$];
  bit [7:0]       m_act_ksu_w_data[$];
  bit [7:0]       m_act_rng_w_data[$];
  bit [7:0]       m_act_sharedram_w_data[$];
  bit [7:0]       m_act_dmb_block_w_data[$];
  bit [7:0]       m_act_dmb_auth_tag_w_data[$];
  bit [7:0]       m_exp_ksu_w_data[$];
  bit [7:0]       m_exp_rng_w_data[$];
  bit [7:0]       m_exp_sharedram_w_data[$];
  bit [7:0]       m_exp_dmb_block_w_data[$];
  bit [7:0]       m_exp_dmb_auth_tag_w_data[$];

  // flags for axi violations: share with AXI SUB flag
  bit m_is_rng_fetch_error              = 0;
  bit m_is_dmb_write_error              = 0;
  bit m_is_dmb_auth_tag_write_error     = 0;
  bit m_is_dmb_encrypt_data_write_error = 0;
  bit m_is_ksu_rd_error                 = 0;
  bit m_is_sharedram_rd_error           = 0;
  bit m_is_dmb_read_error               = 0;
  bit m_is_dmb_auth_tag_read_error      = 0;
  bit m_is_dmb_encrypt_data_read_error  = 0;

  // flags for CPU read authentication tag missmatch
  bit m_is_auth_tag_mismatch_error = 0;
  bit m_is_fetch_block_fail        = 0;
  bit m_is_auth_tag_check_disabled = 0;

  // flag can only set by scoreboard
  bit m_has_pending_cpu_read_with_mpu_disallowed = 0;
  bit m_has_cpu_rd_exp_block_fetch = 0;
  /**
   * AXI MGR request expectations End
   */

  // CPU information
  ccpui_cpu_mem_transaction                         m_cpu_req_p_tran;
  bit                                               m_exp_cpu_rd_resp;
  bit                                               m_is_cpu_rd_err;
  ccpui_cpu_mem_transaction                         m_cpu_rd_resp_tran_q[$];
  bit                                               m_cpu_write;
  bit                                               m_is_write_performed;                                   // indicate whether the CPU write data should be store to phisical memory
  ccpui_cpu_mem_addr_t                              m_cpu_addr;
  logic [(`CCPUI_CPU_MEM_MAX_DATA_WIDTH / 8) - 1:0] m_cpu_we;
  bit                                               m_cpu_loadstore;
  bit                                               m_cpu_privmode;
  bit                                               m_is_mpu_status_update_expected                    = 1; // set 0 if the CPU access won't update MPU status
  bit                                               m_r_acc_vio;
  bit                                               m_r_accvio_ex;
  bit                                               m_r_accvio_rd;
  bit                                               m_r_accvio_wr;
  bit                                               m_is_mpu_allowed = 1;
  bit                                               m_erase_accepted_before_cache_mem_transaction_done = 0;

  // MPU inforamtion
  ccpui_mpu_transaction m_mpu_req_tran;
  ccpui_mpu_config      m_mpu_cfg;
  bit                   m_mpu_allow;         // set by MPU agent DPI .is_access_allow(addr, priv, loadstore), set 1 mean allowed
  bit                   m_exp_mpu_rd     =0; // must check in self_check()
  ccpui_mpu_data_t      m_exp_mpu_rd_data=0;
  logic [1:0]           m_exp_mpu_resp;

  /**
   * FW Command expectation Begin
   */
  bit               m_is_fw_cmd;
  bit               m_is_fw_tlb_updated                  = 0;
  sinc_fw_cmd_e     m_fw_cmd                             = SINC_FW_UNMAPPED;
  bit               m_is_fw_op_fail                      = 0;
  int               m_fw_cmd_in_int;
  bit               m_is_fw_blocked_due_to_unread_status = 0;
  csd_cache_block_t m_encr_block_plaintxt_array[];
  csd_cache_block_t m_encr_block_encrypted_array[];
  csd_auth_tag_t    m_encry_block_auth_tag_array[];
  //csd_cache_block_t act_encr_block_encrypted_array[];
  //csd_auth_tag_t   act_encry_block_auth_tag_array[];

  // status update value when transaction finished
  sinc_status_reg_struct_s m_exp_reg_status;
  bit                      m_exp_complete;
  bit                      m_exp_error_cmd;

  bit m_is_exp_single_bit_ecc_err;
  bit m_is_exp_uncorr_ecc_err;

  /**
   * FW Command expectation End
   */

  /**
   * CREG Erase expectations Begin
   */
  bit                       m_exp_erase_done;           // must check in self_check()
  ramwrap_erase_transaction m_erase_start_tran;
  ramwrap_erase_transaction m_erase_done_tran_q[$];
  bit                       m_is_erase_accepted    = 0; // indicate whether the erase will be accepted by SINC

  /**
   * CREG Erase expectations End
   */

  /**
   * Data check intermidia values Begin
   */

  // block fetch's encrypted data
  byte m_block_fetch_encrypted_data_in_bytes[];
  // block fetch's auth tag
  byte m_block_fetch_auth_tag_in_bytes[];
  // RNG data
  byte m_rng_fetch_data_in_bytes[];
  // KEY data
  byte m_key_fetch_data_in_bytes[];
  // Sharedram read data
  byte m_sharedram_fetch_data_in_bytes[];
  // block write's encrypted data to DMB
  byte m_dmb_encrypted_data_write_in_bytes[];
  // auth tag write's auth tag to DMB
  byte m_dmb_auth_tag_write_in_bytes[];

  /**
   * Data check intermidia values Begin
   */

  /**
   * Coverage Usage Begin
   */

  sinc_sb_pkt_entry_e m_pre_entry;
  sinc_sb_pkt_entry_e m_post_entry;
  bit                 m_rng_seed_is_fetched = 0;
  bit                 m_ksu_key_is_fetched  = 0;

  // error injection
  bit m_erase_during_req_inprogress                       = 0;
  bit m_access_while_cmu_busy                             = 0;
  bit m_access_while_erase_inprogress                     = 0;
  bit m_access_with_axuser_block_bit_set                  = 0;
  bit m_write_access_with_unsupported_strobe              = 0;
  bit m_write_cmd_reg_with_rsvd_field_programmed          = 0;
  bit m_write_cmd_reg_with_cmd_sel_w_unknown_op           = 0;
  bit m_write_fail_to_ciram_during_fetch                  = 0;
  bit m_external_mem_access_not_encrypted                 = 0;
  bit m_write_cmd_reg_when_aes_test_enabled               = 0;
  bit m_cpu_access_while_axi_inprogress                   = 0;
  bit m_cpu_access_while_cmu_busy                         = 0;
  bit m_axi_access_while_cpu_inprogress                   = 0;
  bit m_axi_access_while_cmu_busy                         = 0;
  bit m_cpu_access_when_non_cache_active_to_high_addr_map = 0;
  bit m_fw_op_invalid_due_to_adjacent_block_fetch         = 0;

  //aes obj for expected data
  sinc_aes_packet m_aes_obj;
  bit             m_is_exp_aes_test_en;

  // error injection types
  sinc_stimulus_err_types_t      m_sinc_stimulus_err_types      = 0;
  sinc_mpu_rd_err_types_t        m_sinc_mpu_rd_err_types        = 0;
  sinc_mpu_wr_err_types_t        m_sinc_mpu_wr_err_types        = 0;
  sinc_cpu_rd_err_types_t        m_sinc_cpu_rd_err_types        = 0;
  sinc_cpu_wr_err_types_t        m_sinc_cpu_wr_err_types        = 0;
  sinc_axi_global_err_types_t    m_sinc_axi_global_err_types    = 0;
  sinc_axi_rd_err_types_t        m_sinc_axi_rd_err_types        = 0;
  sinc_axi_wr_reg_err_types_t    m_sinc_axi_wr_reg_err_types    = 0;
  sinc_axi_wr_fw_cmd_err_types_t m_sinc_axi_wr_fw_cmd_err_types = 0;

  /**
   * Coverage Usage End
   */

  `uvm_object_utils_begin(sinc_sb_pkt_item)
    `uvm_field_object (m_addr_dec,                                       UVM_REFERENCE | UVM_NOPRINT)
    `uvm_field_int    (m_trans_id,                                       UVM_DEFAULT                )
    `uvm_field_int    (m_req_tr_time,                                    UVM_DEFAULT                )
    `uvm_field_int    (m_is_completed,                                   UVM_DEFAULT                )
    `uvm_field_enum   (sinc_sb_pkt_entry_e,         m_sinc_sb_pkt_entry, UVM_DEFAULT | UVM_STRING   )
    `uvm_field_object (m_snapshot_sys_cfg,                               UVM_REFERENCE | UVM_NOPRINT)
    `uvm_field_int    (m_exp_cache_mem,                                  UVM_DEFAULT                )
    `uvm_field_int    (m_cache_mem_transaction_num,                      UVM_DEFAULT                )
    `uvm_field_enum   (sinc_comp_e,                 m_req_src,           UVM_DEFAULT | UVM_STRING   )
    `uvm_field_enum   (sinc_comp_e,                 m_req_dst,           UVM_DEFAULT | UVM_STRING   )
    `uvm_field_enum   (sinc_cmd_e,                  m_req_cmd,           UVM_DEFAULT | UVM_STRING   )
    `uvm_field_object (m_sub_addr_p_tran,                                UVM_REFERENCE | UVM_NOPRINT)
    `uvm_field_int    (m_exp_axi_sub_rd_resp,                            UVM_DEFAULT                )
    `uvm_field_int    (m_exp_axi_sub_wr_resp,                            UVM_DEFAULT                )
    `uvm_field_int    (m_exp_sub_slv_err,                                UVM_DEFAULT                )
    `uvm_field_int    (m_is_status_read,                                 UVM_DEFAULT                )
  `uvm_object_utils_end

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_sb_pkt_item");
    super.new(name);
    m_addr_dec = addr_dec_t::get_inst();
    m_aes_obj  = sinc_aes_packet::type_id::create("m_aes_obj", , get_full_name());
  endfunction :new

  // FUNCTION: set_exp_pkt
  // Set the sinc_sb_pkt_entry base call
  extern virtual function void set_exp_pkt(sinc_sb_pkt_entry_e sinc_sb_pkt_entry, int trans_count);

  // FUNCTION: set_exp_pkt_erase_after_soft_reset
  // Reset erase : SINC will start erase cache mem on sinc_reset
  // Expecting Memory Interface activities on RamWrap Mem
  extern virtual function void set_exp_pkt_erase_after_soft_reset();

  // FUNCTION: set_exp_pkt_creg_erase
  // CREG Erase : SINC will start erase cache mem on CREG Erase
  // Expecting Memory Interface activities on cache mem
  extern virtual function void set_exp_pkt_creg_erase();

  // FUNCTION: set_exp_pkt_warm_reset
  // Warm reset : reset all the mirror values
  extern virtual function void set_exp_pkt_warm_reset();

  // FUNCTION: set_exp_pkt_axi_sub_rd
  // AXI Read : SINC receive AXI read request
  // Expecting behavior depends on dstination and current system status
  extern virtual function void set_exp_pkt_axi_sub_rd();

  // FUNCTION: set_exp_pkt_axi_sub_wr
  // AXI Write : SINC receive AXI write request
  // Expecting behavior depends on dstination and current system status
  extern virtual function void set_exp_pkt_axi_sub_wr();

  // FUNCTION: set_exp_pkt_cpu_rd
  // AXI Read : SINC receive CPU read request
  extern virtual function void set_exp_pkt_cpu_rd();

  // FUNCTION: set_exp_pkt_cpu_wr
  // AXI Read : SINC receive CPU write request
  extern virtual function void set_exp_pkt_cpu_wr();

  // FUNCTION: set_exp_fw_cmd
  // AXI Write Data: execute when SINC receive axi write data
  extern virtual function void set_exp_fw_cmd(pal_axi_xaction t);

  // FUNCTION: set_exp_fw_reset_cmd
  // Set expectations for FW SINC_RESET command
  extern virtual function void set_exp_fw_reset_cmd();

  // FUNCTION: set_exp_fw_reinit_cmd
  // Set expectations for FW SINC_REINIT command
  extern virtual function void set_exp_fw_reinit_cmd();

  // FUNCTION: set_exp_fw_set_init_state_cmd
  // Set expectations for FW SINC_SET_INIT_STATE command
  extern virtual function void set_exp_fw_set_init_state_cmd();

  // FUNCTION: set_exp_fw_encr_block_cmd
  // Set expectations for FW ENCR_BLOCK command
  extern virtual function void set_exp_fw_encr_block_cmd();

  // FUNCTION: set_exp_fw_set_cache_active_state_cmd
  // Set expectations for FW SINC_SET_CACHE_ACTIVE_STATE command
  extern virtual function void set_exp_fw_set_cache_active_state_cmd();

  // FUNCTION: set_exp_fw_aes_test_mode_en
  // Set expectations for behavior in AES test mode - enable
  extern virtual function void set_exp_fw_aes_test_mode_en();

  // FUNCTION: set_exp_fw_aes_test_mode_disable
  // Set expectations for FW command - AES Test Mode
  extern virtual function void set_exp_fw_aes_test_mode_disable();

  // FUNCTION: set_exp_fw_disable_reset
  // Set expectations for behavior in Disbale Reset
  extern virtual function void set_exp_fw_disable_reset();

  // FUNCTION: set_exp_fw_disable_reinit
  // Set expectations for behavior in Disbale Reinit
  extern virtual function void set_exp_fw_disable_reinit();

  // FUNCTION: set_exp_pkt_mpu_attr_rd
  // AXI Read : SINC receive MPU ATTR read request
  // Expecting behavior depends on current MPU config
  extern virtual function void set_exp_pkt_mpu_attr_rd();

  // FUNCTION: set_exp_pkt_mpu_status_rd
  // AXI Read : SINC receive MPU status read request
  // Expecting behavior depends on current MPU config
  extern virtual function void set_exp_pkt_mpu_status_rd();

  // FUNCTION: inject_cache_mem_tran
  // Push received LUT memory transaction into pending Q
  extern virtual function void inject_cache_mem_tran(mem_transaction t);

  // FUNCTION: inject_axi_sub_rd_resp
  // Push received AXI SUB read response into pending Q
  extern virtual function void inject_axi_sub_rd_resp(pal_axi_xaction t);

  // FUNCTION: inject_axi_sub_wr_resp
  // Push received AXI SUB write response into pending Q
  extern virtual function void inject_axi_sub_wr_resp(pal_axi_xaction t);

  // FUNCTION: inject_axi_mgr_rd_req
  // Push received AXI MGR read request into pending Q
  extern virtual function void inject_axi_mgr_rd_req(pal_axi_xaction t);

  // FUNCTION: inject_axi_mgr_rd_resp
  // Push received AXI MGR read response into pending Q
  extern virtual function void inject_axi_mgr_rd_resp(pal_axi_xaction t);

  // FUNCTION: inject_axi_mgr_wr_req
  // Push received AXI MGR read request into pending Q
  extern virtual function void inject_axi_mgr_wr_req(pal_axi_xaction t);

  // FUNCTION: inject_axi_mgr_wr_resp
  // Push received AXI MGR read response into pending Q
  extern virtual function void inject_axi_mgr_wr_resp(pal_axi_xaction t);

  // FUNCTION: inject_cpu_rd_resp
  // Push received CPU read response into pending Q
  extern virtual function void inject_cpu_rd_resp(ccpui_cpu_mem_transaction t);

  // FUNCTION: inject_erase_done
  // Push received Erase Done event into pending Q
  extern virtual function void inject_erase_done(ramwrap_erase_transaction t);

  // FUNCTION: inject_sinc_done
  // Push received SINC Done event into pending Q
  extern virtual function void inject_sinc_done(sinc_monitor_pkg::sinc_sideband_e t);

  // FUNCTION: inject_sinc_error
  // Push received SINC Error event into pending Q
  extern virtual function void inject_sinc_error(sinc_monitor_pkg::sinc_sideband_e t);

  // FUNCTION: inject_mpu_err_accvio
  // Push received SINC MPU access violation event into pending Q
  extern virtual function void inject_mpu_err_accvio(ccpui_mpu_transaction t);

  // FUNCTION: is_completed
  // return is_completed local variable
  extern virtual function bit is_completed(bit enable_report=0);

  // FUNCTION: self_check
  // return the check result. 0 for error found, 1 for no error.
  extern virtual function bit self_check();

  // FUNCTION: set_sys_mirror
  // call when self_check done or partially done(with success), perform system mirrored data structure update
  extern virtual function bit set_sys_mirror();

  // FUNCTION: update_tlb_when_op_finish
  // call when sinc_error or sinc_done
  extern virtual function bit update_tlb_when_op_finish();

  // FUNCTION: self_check_fw_command
  // return the check result. 0 for error found, 1 for no error.
  extern virtual function bit self_check_fw_command();

  // FUNCTION: check on axi response
  // return the check result. 0 for error found, 1 for no error.
  extern virtual function bit axi_resp_check(bit exp_slv_err, pal_axi_xaction t);

  // FUNCTION: check on axi data
  // return the check result. 0 for error found, 1 for no error.
  extern virtual function bit axi_data_check(const ref sinc_axi_data_t exp_data[], const ref byte unsigned resp_data[]);

  // TASK: check on register write result with backdoor access
  // return the check result. 0 for error found, 1 for no error.
  extern virtual task automatic reg_data_check(
    input uvm_reg_data_t exp_reg_data,
    input uvm_reg        reg_handler,
    input int            delay          =0,
    input time           req_start_time,
    input bit            exp_pass       =1
  );

  // TASK: update mirror register with backdoor reg value
  extern virtual task automatic update_reg_mirror_w_backdoor_value(input string reg_name);

  // FUNCTION: check_complete
  // Check if all the expected transactions are received
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit check_complete();

  // FUNCTION: is_cache_mem_match_exp
  // Check if collected CACHE mem transaction match with expectation
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_cache_mem_match_exp(int num);

  // FUNCTION: is_axi_mgr_rd_req_match_exp
  // Check if collected AXI mgr read requets match with expectations
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_axi_mgr_rd_req_match_exp();

  // FUNCTION: is_axi_mgr_wr_req_match_exp
  // Check if collected AXI mgr read requets match with expectations
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_axi_mgr_wr_req_match_exp();

  // FUNCTION: is_cpu_rd_resp_match_exp
  // Check if collected CPU read response match with expectations
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_cpu_rd_resp_match_exp();

  // FUNCTION: is_cpu_rd_data_match_exp
  // Check if collected CPU read response's data match with expectations
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_cpu_rd_data_match_exp();

  // FUNCTION: is_mpu_rd_match_exp
  // Check if collected MPU read response match with expectations
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_mpu_rd_match_exp();

  // FUNCTION: is_aes_test_mode_en_recently_toggled
  // Check if AES test mode has been enabled or disabled recently
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_aes_test_mode_en_recently_toggled();

  // FUNCTION: is_cpu_rd_auth_tag_match
  // Check if collected actual TAG match with scoreboard prediction tag on the corresponding data
  // If NOT, return 0;
  // If YES, return 1.
  extern virtual function bit is_cpu_rd_auth_tag_match();

  // FUNCTION: set_cache_fail
  // set cache state to fail with internal dut mirror updates
  extern virtual function void set_cache_fail();

  // FUNCTION: set_fw_in_progress
  // set expectation and status update when a FW is accepted
  extern virtual function void set_fw_in_progress();

  extern virtual function void do_copy(uvm_object rhs);

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet ();

endclass : sinc_sb_pkt_item

// FUNCTION: set_exp_pkt
// Set the sinc_sb_pkt_entry base call
function void sinc_sb_pkt_item::set_exp_pkt(sinc_sb_pkt_entry_e sinc_sb_pkt_entry, int trans_count);
  string report_str = "set_exp_pkt";
  m_sinc_sb_pkt_entry = sinc_sb_pkt_entry;
  m_req_tr_time       = $realtime;
  m_trans_id          = trans_count;
  m_cur_cache_state   = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  `uvm_info(report_str, $sformatf("set expectation for :%0s, transaction ID [%0d], cur_state[%0s]", sinc_sb_pkt_entry.name(), m_trans_id, m_cur_cache_state.name()), UVM_LOW)

  `uvm_info(report_str, $sformatf("AES_TEST_EN[%0d]", m_top_configuration.m_sys_cfg.m_aes_test_mode_en), UVM_HIGH)

  m_top_configuration.m_sys_cfg.m_aeb_sinc_dbg_mode_acc_en = m_top_configuration.m_sys_cfg.get_aeb_sinc_dbg_mode_acc_en();

  m_snapshot_ext_block_base_addr    = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("ext_block_base_addr").get_mirrored_value());
  m_snapshot_ext_auth_tag_base_addr = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("ext_auth_tag_base_addr").get_mirrored_value());
  m_snapshot_block_encr_num         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("block_encr_num").get_mirrored_value());
  m_snapshot_num_of_blocks          = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("num_of_blocks").get_mirrored_value());
  m_snapshot_block_encr_addr        = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("block_encr_addr").get_mirrored_value());
  m_snapshot_block_encr_key         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("block_encr_key").get_mirrored_value());
  m_snapshot_perf_cntr_ctrl         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("perf_cntr_ctrl").get_mirrored_value());
  m_snapshot_hit_cntr_en            = m_snapshot_perf_cntr_ctrl[`SINC_REGS_PERF_CNTR_CTRL_HIT_CNTR_EN_LSB];
  m_snapshot_miss_cntr_en           = m_snapshot_perf_cntr_ctrl[`SINC_REGS_PERF_CNTR_CTRL_MISS_CNTR_EN_LSB];
  m_snapshot_lat_cntr_en            = m_snapshot_perf_cntr_ctrl[`SINC_REGS_PERF_CNTR_CTRL_LAT_CNTR_EN_LSB];
  m_snapshot_hit_cntr_lower         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("hit_cntr_lower").get_mirrored_value());
  m_snapshot_hit_cntr_upper         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("hit_cntr_upper").get_mirrored_value());
  m_snapshot_miss_cntr_lower        = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("miss_cntr_lower").get_mirrored_value());
  m_snapshot_miss_cntr_upper        = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("miss_cntr_upper").get_mirrored_value());
  m_snapshot_lat_cntr_lower         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("lat_cntr_lower").get_mirrored_value());
  m_snapshot_lat_cntr_upper         = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("lat_cntr_upper").get_mirrored_value());
  m_snapshot_rng_base               = sinc_parameters_pkg::SINC_RNG_START_ADDR;
  m_snapshot_ksu_base               = sinc_parameters_pkg::SINC_KSU_START_ADDR;
  m_snapshot_sharedram_base         = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;

  m_snapshot_is_key_fetched   = m_top_configuration.m_sys_cfg.m_is_key_fetched;
  m_snapshot_aes_test_mode_en = m_top_configuration.m_sys_cfg.m_aes_test_mode_en;

  // MPU sideband
  m_snapshot_mpu_cfg_mpu_disable   = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_mpu_disable;
  m_snapshot_mpu_cfg_chkpt_spramnx = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_chkpt_spramnx;

  // m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cache_state;

  case (m_sinc_sb_pkt_entry)
    sinc_env_pkg::ENTRY_ERASE_AFTER_SOFT_RESET : begin
      set_exp_pkt_erase_after_soft_reset();
    end
    sinc_env_pkg::ENTRY_SINC_WARM_RESET : begin
      set_exp_pkt_warm_reset();
    end
    sinc_env_pkg::ENTRY_AXI_SUB_READ : begin
      m_is_axi_sub_req = 1;
      set_exp_pkt_axi_sub_rd();
    end
    sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
      m_is_axi_sub_req = 1;
      set_exp_pkt_axi_sub_wr();
    end
    sinc_env_pkg::ENTRY_CPU_READ : begin
      m_is_cpu_mem_req = 1;
      set_exp_pkt_cpu_rd();
    end
    sinc_env_pkg::ENTRY_CPU_WRITE : begin
      m_is_cpu_mem_req = 1;
      set_exp_pkt_cpu_wr();
    end
    sinc_env_pkg::ENTRY_CREG_ERASE : begin
      m_is_creg_erase_req = 1;
      set_exp_pkt_creg_erase();
    end
    sinc_env_pkg::ENTRY_MPU_ATTR_READ : begin
      m_is_mpu_req = 1;
      set_exp_pkt_mpu_attr_rd();
    end
    sinc_env_pkg::ENTRY_MPU_STATUS_READ : begin
      m_is_mpu_req = 1;
      set_exp_pkt_mpu_status_rd();
    end
    default: `uvm_error(report_str, $sformatf("received unexpected scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
  endcase // case (m_sinc_sb_pkt_entry)

  // collect stimulus information
  if (m_top_configuration.m_sys_cfg.get_sinc_erase_in_progress()) begin
    m_access_while_erase_inprogress = 1;
  end
  if (m_top_configuration.m_sinc_vif.sinc_cmu_active_cmd) begin
    m_access_while_cmu_busy     = 1;
  end
  print_packet();

endfunction : set_exp_pkt

// SB_PKT_ERASE_AFTER_SOFT_RESET
// Reset erase : SINC will start erase cache mem on FW soft reset
// Expecting Memory Interface activities on Cache Mem
function void sinc_sb_pkt_item::set_exp_pkt_erase_after_soft_reset();
  string report_str = "SB_PKT_ERASE_AFTER_SOFT_RESET";

  m_exp_cache_mem = 1;

  m_cache_mem_transaction_num = int'(sinc_parameters_pkg::SINC_CACHE_END_ADDR) + 1;

  m_exp_sinc_done = 1;
  m_sinc_done_num = 1;

  `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
endfunction : set_exp_pkt_erase_after_soft_reset

function void sinc_sb_pkt_item::set_exp_pkt_creg_erase();
  string report_str = "SB_PKT_CREG_ERASE";

  // fixme-hw: negative case not add yet
  m_is_erase_accepted = 1;

  m_exp_cache_mem  = 1;
  m_exp_erase_done = 1;

  m_cache_mem_transaction_num = int'(sinc_parameters_pkg::SINC_CACHE_END_ADDR) + 1;

  m_exp_sinc_done = 1;
  m_sinc_done_num = 1;
  `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
endfunction : set_exp_pkt_creg_erase

function void sinc_sb_pkt_item::set_exp_pkt_warm_reset();
  string report_str = "SB_PKT_WARM_RESET";

  // update peripherals
  // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
  // reset cache coherency, will also do preload of current memory
  m_top_configuration.m_csd.reset_csd();

  // reset MPU attributes and registers
  m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
  m_mpu_cfg.reset_mpu();

  // KEY should been wiped
  m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;

  // Seed should be removed
  m_top_configuration.m_sys_cfg.m_is_rng_fetched = 0;

  // register reset
  m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.reset();

  // cache state
  m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_DISABLE_STATE;

  // remove error flag
  m_top_configuration.m_sys_cfg.m_unmapped_axi_mgr_rd_when_block_fetch = 0;

  // remove waiver flag
  m_top_configuration.m_sys_cfg.m_observe_cpu_rd_during_erase_at_cache_active = 0;
  m_top_configuration.m_sys_cfg.m_perf_cntr_toggled_during_cpu_rd = 0;

  `uvm_info(report_str, $sformatf("set expectation: warm reset, m_cur_cache_state[%0s]",
      m_top_configuration.m_sys_cfg.m_cur_cache_state), UVM_LOW)

endfunction : set_exp_pkt_warm_reset

function void sinc_sb_pkt_item::set_exp_pkt_axi_sub_rd();
  string report_str = "SB_PKT_AXI_SUB_RD";

  bit ref_is_valid_src          = 0;
  bit ref_is_byte_allign        = 0;
  bit ref_is_access_reg_allowed = 0;
  bit ref_is_valid_burst        = 0;

  m_exp_axi_sub_rd_resp = 1;

  // for coverage
  if (m_req_src !== SINC_SP) begin
    m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_NON_SP] = 1;
  end

  if (m_req_dst == SINC_NULL) begin
    m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE] = 1;
    m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE]         = 1;
    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)
  end

  // check AXI attributes
  if (!m_top_configuration.m_sys_cfg.is_valid_axi_sub_attributes(.axi_tran(m_sub_addr_p_tran), .req_src(m_req_src), .req_dst(m_req_dst), .req_cmd(m_req_cmd),
                                                                 .dst_reg(m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr)),
                                                                 .ref_is_valid_src(ref_is_valid_src),
                                                                 .ref_is_byte_allign(ref_is_byte_allign),
                                                                 .ref_is_access_reg_allowed(ref_is_access_reg_allowed),
                                                                 .ref_is_valid_burst(ref_is_valid_burst)) ) begin

    m_exp_sub_slv_err           = 1;
    m_is_invalid_axi_attributes = 1;

    m_dst_reg = m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr);
    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)

    if (!ref_is_valid_src) begin
      m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_NON_SP] = 1;
      m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_NON_SP]         = 1;
    end

    if (!ref_is_valid_burst) begin

      //If the burst type isn't supported, then mark as invalid burst type
      if ((m_sub_addr_p_tran.burst_type !== PAL_BT_INCR) && (m_sub_addr_p_tran.burst_type !== PAL_BT_FIXED)) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE] = 1;
        m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE]         = 1;
      end

      //if size==4, then check that burst length is valid
      if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_4) begin
        if (m_sub_addr_p_tran.burst_length > 1) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN] = 1;
          m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN]         = 1;
        end

        //Otherwise if size is 2, then mark size invalid, and check if length is valid
      end else if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_2) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE] = 1;
        m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE]         = 1;
        if (m_sub_addr_p_tran.burst_length > 2) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]  = 1;
          m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN]          = 1;
          m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
        end

        //Otherwise if size is 2, then mark size invalid, and check if length is valid
      end else if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_1) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE] = 1;
        m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE]         = 1;
        if (m_sub_addr_p_tran.burst_length > 4) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]  = 1;
          m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN]          = 1;
          m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
        end
      end

    end

    return;
  end

  // check on register reads
  if (m_req_dst == SINC_REG ) begin
    m_dst_reg = m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr);
    if (m_top_configuration.m_sys_cfg.is_valid_reg_access(m_dst_reg, SINC_AXI_READ)) begin
      m_exp_reg_data_addr_p    = new [1];
      m_exp_reg_data_addr_p[0] = sinc_axi_data_t'(m_dst_reg.get_mirrored_value());//m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_data_by_name(m_dst_reg.get_name());
      `uvm_info(report_str, $sformatf("REG: m_req_src[%0s], m_req_dst[%0s], reg_name[%0s], reg_data['h%0h], EXP:SLV_ERR[%0d]",
          m_req_src.name(), m_req_dst.name(), m_dst_reg.get_name(), m_exp_reg_data_addr_p[0], m_exp_sub_slv_err), UVM_LOW)
    end else begin
      m_exp_sub_slv_err = 1;
      `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",  m_exp_sub_slv_err), UVM_LOW)
      m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_WR_ONLY_REG]=1;
    end
  end else begin
    m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE] = 1;
    m_sinc_axi_rd_err_types[`SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE]         = 1;
    m_exp_sub_slv_err                                                    = 1;
    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)
  end

endfunction : set_exp_pkt_axi_sub_rd

function void sinc_sb_pkt_item::set_exp_pkt_axi_sub_wr();
  string report_str                = "SB_PKT_AXI_SUB_WR";
  bit    ref_is_valid_src          = 0;
  bit    ref_is_byte_allign        = 0;
  bit    ref_is_access_reg_allowed = 0;
  bit    ref_is_valid_burst        = 0;
  m_exp_axi_sub_wr_resp = 1;

  // for coverage
  if (m_req_src !== SINC_SP) begin
    m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_NON_SP] = 1;
  end

  if (m_sub_addr_p_tran.addr[1:0] !== 2'b00) begin
    m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_NON_ALIGNED_BYTE_ADDR] = 1;
  end

  if (m_req_dst == SINC_NULL) begin
    m_exp_sub_slv_err                                                    = 1;
    m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE] = 1;
    m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_ILLEGAL_ADDR_RANGE]     = 1;
    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)
    return;
  end

  // if (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE) begin
  //   m_exp_sub_slv_err = 1;
  //   `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
  //                                   m_exp_sub_slv_err), UVM_HIGH)
  //   return;
  // end

  // check AXI attributes
  if (!m_top_configuration.m_sys_cfg.is_valid_axi_sub_attributes( .axi_tran(m_sub_addr_p_tran),
                                                                  .req_src(m_req_src),
                                                                  .req_dst(m_req_dst),
                                                                  .req_cmd(m_req_cmd),
                                                                  .dst_reg(m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr)),
                                                                  .ref_is_valid_src(ref_is_valid_src),
                                                                  .ref_is_byte_allign(ref_is_byte_allign),
                                                                  .ref_is_access_reg_allowed(ref_is_access_reg_allowed),
                                                                  .ref_is_valid_burst(ref_is_valid_burst))
  ) begin
    m_exp_sub_slv_err           = 1;
    m_is_invalid_axi_attributes = 1;

    m_dst_reg = m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr);

    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)

    if (!ref_is_valid_src) begin
      m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_NON_SP] = 1;
      m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_NON_SP]     = 1;
    end

    if (!ref_is_access_reg_allowed) begin
      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT] = 1;
    end

    if (!ref_is_valid_burst) begin

      if (m_sub_addr_p_tran.log2_beat_size !== PAL_BYTES_4) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE] = 1;
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE]     = 1;
      end

      if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_4) begin
        if (m_sub_addr_p_tran.burst_length > 1) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]      = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN]          = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
        end
      end else if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_2) begin
        if (m_sub_addr_p_tran.burst_length > 2) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]      = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN]          = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
        end
      end else if (m_sub_addr_p_tran.log2_beat_size == PAL_BYTES_1) begin
        if (m_sub_addr_p_tran.burst_length > 4) begin
          m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]      = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN]          = 1;
          m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
        end
      end

      if ((m_sub_addr_p_tran.burst_type !== PAL_BT_INCR) ||
          (m_sub_addr_p_tran.burst_type !== PAL_BT_FIXED)) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE] = 1;
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_TYPE]     = 1;
      end else if (m_sub_addr_p_tran.log2_beat_size !== PAL_BYTES_4) begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE] = 1;
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE]     = 1;
      end else begin
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE]     = 1;
        m_sinc_axi_global_err_types[`SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN]      = 1;
        // Below 3 err types are relevant, they can help constraint the stimulus but not able to show exact rule violated
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE]         = 1;
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN]          = 1;
        m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN] = 1;
      end
    end

    return;
  end // if (!m_top_configuration.m_sys_cfg.is_valid_axi_sub_attributes ...

  // register access expectation
  if (m_req_dst == SINC_REG ) begin
    m_dst_reg = m_addr_dec.get_reg_tlb_hit(m_sub_addr_p_tran.addr);

    if (m_dst_reg == null) begin
      m_exp_sub_slv_err = 1;
      `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
          m_exp_sub_slv_err), UVM_HIGH)
      return;
    end

    m_is_reg_write_discarded = m_top_configuration.m_sys_cfg.is_reg_write_discarded(m_dst_reg);

    // for coverage
    if (m_is_reg_write_discarded) begin
      m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_DISALOWED_REG_IN_CUR_STATE] = 1;
    end

    if (m_top_configuration.m_sys_cfg.is_valid_reg_access(m_dst_reg, SINC_AXI_WRITE)) begin
      m_exp_reg_data_addr_p    = new [1];
      m_exp_reg_data_addr_p[0] = sinc_axi_data_t'(m_dst_reg.get_mirrored_value());
    end else begin
      m_exp_sub_slv_err = 1;
      `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]", m_exp_sub_slv_err), UVM_LOW)
      m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_RD_ONLY_REG]=1;
    end
  end

  if (m_exp_sub_slv_err) begin
    `uvm_info(report_str, $sformatf("REG: m_req_src[%0s], m_req_dst[%0s], reg_name[%0s], reg_data['h%0h], EXP:SLV_ERR",
        m_req_src.name(), m_req_dst.name(), m_dst_reg.get_name(), m_exp_reg_data_addr_p[0]), UVM_HIGH)
  end else begin
    if ((m_dst_reg.get_name() == sinc_parameters_pkg::CMD_REG_NAME)) begin
      uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
      sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
      // FW must read the status register after each command completion, before initiating another command, otherwise will result SLVERR
      // Note: "Status Register Read" means cmd_in_progress[R]==0, cmd_success[RC]==0, cmd_fail[RC]==0, invalid_cmd_err[13]==0
      // Note: Below code has hard time do prediction if there is close back to back CPU READ with fetch block with FW command
      // if (cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] ||
      //     cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] ||
      //     cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] ||
      //     cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE]) begin
      if (m_top_configuration.m_sinc_vif.get_sts_unread()) begin
        m_is_fw_blocked_due_to_unread_status = 1;
        m_exp_sub_slv_err                    = 1;
        // m_exp_sinc_error = 1;
        // m_sinc_error_num = 1;
        `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
            m_exp_sub_slv_err), UVM_HIGH)

        `uvm_info(report_str, $sformatf("FW CMD blocked due to unread status register['h%0h]",
            cur_status_reg_data), UVM_HIGH)

        // for coverage
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR] = 1;

        // exception if AES TEST Mode is enabled
        // aes_test_en FW command can be issued
        if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en) begin
          // sinc_done might be asserted before AXI response
          m_is_fw_cmd          = 1;
          m_exp_sinc_done      = 1;
          m_sinc_done_num      = 1;
          m_is_exp_aes_test_en = 1;
          m_exp_sub_slv_err    = 0;
          `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
        end
      end else begin
        // sinc_done might be asserted before AXI response
        m_is_fw_cmd     = 1;
        m_exp_sinc_done = 1;
        m_sinc_done_num = 1;
        `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
      end
    end else begin
      uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
      sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
      if (!m_top_configuration.m_sys_cfg.m_aes_test_mode_en) begin
        // IN PROGRESS is not used as indicator inside RTL, DV have to pull the cmu_busy for precise prediction
        // if (cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]) begin
        if (m_top_configuration.m_sinc_vif.sinc_cmu_active_cmd) begin
          // register write will be aborted if it is to non AES test mode
          m_exp_sub_slv_err           = 1;
          m_axi_access_while_cmu_busy = 1;
          `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
              m_exp_sub_slv_err), UVM_HIGH)
          return;
        end
      end

    end
  end // else: !if(m_exp_sub_slv_err)

endfunction : set_exp_pkt_axi_sub_wr

function void sinc_sb_pkt_item::set_exp_pkt_cpu_rd();
  string                  report_str                = "SB_PKT_CPU_RD";
  logic [7:0]             sinc_cmu_state            = m_top_configuration.m_sys_cfg.m_sinc_vif.sinc_cmu_state;
  m_cpu_write     = (m_cpu_req_p_tran.m_rw == ccpui_cpu_mem_pkg::WRITE) ? 1 : 0;
  m_cpu_we        = m_cpu_req_p_tran.m_we;
  m_cpu_addr      = m_cpu_req_p_tran.m_addr;
  m_cpu_loadstore = m_cpu_req_p_tran.m_loadstore;
  m_cpu_privmode  = m_cpu_req_p_tran.m_privmode;
  m_mpu_cfg       = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];

  m_is_valid_req = m_top_configuration.m_sys_cfg.is_valid_req(SINC_SP, SINC_CPU_READ);

  m_exp_cpu_rd_resp = 1;

  if (m_top_configuration.m_sys_cfg.m_unpredicatable_state) begin
    predicted_cur_cache_state = sinc_cache_state_type_e'(sinc_cmu_state);
    m_cur_cache_state = predicted_cur_cache_state;
    `uvm_info(report_str, $sformatf("Current state is unpredicatable_state[%0d], use RTL state[%0s]",
        m_top_configuration.m_sys_cfg.m_unpredicatable_state, predicted_cur_cache_state), UVM_LOW)
  end else begin
    // The status read can confirm the state, due to write response phase can be late [The current AXI UVC does not have data phase]
    predicted_cur_cache_state = m_cur_cache_state;
    //predicted_cur_cache_state = sinc_cache_state_type_e'(sinc_cmu_state);
  end

  // erase busy error has highest priority
  if (m_top_configuration.m_sys_cfg.get_sinc_erase_in_progress()) begin
    // not accepted at SINC TOP
    m_exp_cache_mem                 = 0;
    m_cache_mem_transaction_num     = 0;
    m_is_cpu_rd_err                 = 1;
    m_access_while_erase_inprogress = 1;
    m_is_mpu_status_update_expected = 0;
    if (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE) begin
      m_exp_mpu_err_accvio            = 1;
      m_is_mpu_status_update_expected = 1;
    end
    if (m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
       m_top_configuration.m_sys_cfg.m_observe_cpu_rd_during_erase_at_cache_active  = 1;
    end
    return;
  end

  if (m_is_valid_req) begin
    // check if MPU allowed
    m_is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(m_cpu_write), .loadstore(m_cpu_loadstore), .accsrc(0), .priv_mode(m_cpu_privmode), .addr(m_cpu_addr), .r_acc_vio(m_r_acc_vio),
      .r_accvio_ex(m_r_accvio_ex), .r_accvio_rd(m_r_accvio_rd), .r_accvio_wr(m_r_accvio_wr));

    // set expectation if in Cache Disable State
    if ((predicted_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) ||
        (predicted_cur_cache_state == sinc_parameters_pkg::CACHE_INIT_STATE)) begin
      if (m_is_mpu_allowed) begin
        m_exp_cache_mem             = 1;
        m_cache_mem_transaction_num = 1;
      end else begin
        // Even when MPU not allowed, SINC will simutaneous issue mem fetch
        m_exp_cache_mem             = 1;
        m_cache_mem_transaction_num = 1;
        m_is_cpu_rd_err             = 1;
        m_exp_mpu_err_accvio        = 1;
      end // if (m_is_mpu_allowed) begin
    end else if (predicted_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
      // DUT pulses ciu_cache_hit on vtag-match in CIU_MEM_READ regardless of mpu_acc_vio,
      // so evaluate cache hit before MPU branching to keep hit_cntr prediction aligned with RTL.
      m_is_cache_hit = (m_top_configuration.m_csd.is_cache_hit(csd_address_t'(m_cpu_addr)));
      if (m_is_mpu_allowed) begin
        if (m_is_cache_hit) begin // cache hit
          m_exp_cache_mem             = 1;
          m_cache_mem_transaction_num = 1;
        end else begin // cache miss
          // check if authentication tag check disabled
          // when disabled, SINC always return the local cache mem data as CPU RD response
          if (m_top_configuration.m_sinc_vif.disable_encr_auth_check) begin
            m_is_auth_tag_check_disabled = 1;
          end

          m_exp_block_fetch           = 1;
          m_exp_cache_mem             = 1;
          m_cache_mem_transaction_num = 1 + (128 * 2) + 1; // prefetch(1) + fetch_block(128*2 as RMW) + 1(fetch valid)

          // DMB encrypted data and auth tag fetch
          m_exp_axi_mgr_rd_req = 1;
          m_exp_axi_mgr_rd_size += sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8; // encrypted data fetch
          m_exp_axi_mgr_rd_size += sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8; // auth tag fetch

          // for coverage
          m_valid_lines_per_set = m_top_configuration.m_csd.get_num_cache_lines_per_set(csd_address_t'(m_cpu_addr));

          // Note: found at design behavior, the CMD_SUCCESS/INVALID/CMDFAIL will be set 0 whenever a fetch_block issued
          begin
            uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
            sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 1;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b0;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end

            m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time = $realtime;
          end
        end
      end else begin
        // Even when MPU not allowed, SINC will simutaneous issue mem fetch
        m_exp_cache_mem             = 1;
        m_cache_mem_transaction_num = 1;
        m_is_cpu_rd_err             = 1;
        m_exp_mpu_err_accvio        = 1;
      end
    end else begin // if (m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE)
      // When cache failure state, Even when MPU not allowed, SINC will simutaneous issue mem fetch
      m_exp_cache_mem             = 0;
      m_cache_mem_transaction_num = 0;
      m_is_cpu_rd_err             = 1;
      m_exp_mpu_err_accvio        = 1;
      m_is_mpu_allowed            = 0;
      // `uvm_error(report_str, $sformatf("Not Implemented yet for CPU_MEM expectation in [%0s]", m_cur_cache_state.name()))
    end

  end else begin // if (m_is_valid_req)
    // not accepted at SINC TOP
    bit xe_reg                  = !m_cpu_loadstore;
    m_exp_cache_mem             = 0;
    m_cache_mem_transaction_num = 0;
    m_is_cpu_rd_err             = 1;
    m_exp_mpu_err_accvio        = 1;
    m_is_mpu_allowed            = 0;

    m_r_acc_vio = 0;
    if (xe_reg) begin
      m_r_accvio_ex = 1;
      m_r_accvio_rd = 0;
    end else begin
      m_r_accvio_ex = 0;
      m_r_accvio_rd = 1;
    end
    m_r_accvio_wr = 0;
  end

  // update performance counter
  // it will be late if update when CPU RD Response received, the AXI SUB RD of counter register can be response at same cycle
  // update performance counter if CPU RD performed, and counter enabled
  if (predicted_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
    // hit_cntr: DUT increments on vtag-match even when MPU denies access (RTL has no error gate).
    if (m_snapshot_hit_cntr_en && m_is_cache_hit) begin
      `uvm_info(report_str, $sformatf("Update hit_cntr register, m_is_cpu_rd_err[%0d], m_snapshot_hit_cntr_en[%0d], m_is_cache_hit[%0d], m_snapshot_hit_cntr_lower['h%0h], m_snapshot_hit_cntr_upper['h%0h]",
                                      m_is_cpu_rd_err, m_snapshot_hit_cntr_en, m_is_cache_hit, m_snapshot_hit_cntr_lower, m_snapshot_hit_cntr_upper), UVM_HIGH)

      if (m_snapshot_hit_cntr_lower < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("hit_cntr_lower", m_snapshot_hit_cntr_lower + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "hit_cntr_lower", (m_snapshot_hit_cntr_lower+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "hit_cntr_lower"))
        end
      end else if (m_snapshot_hit_cntr_upper < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("hit_cntr_upper", m_snapshot_hit_cntr_upper + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "hit_cntr_upper", (m_snapshot_hit_cntr_upper+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "hit_cntr_upper"))
        end
      end

    end // if (m_snapshot_hit_cntr_en && m_is_cache_hit) begin

    // miss_cntr
    if (!m_is_cpu_rd_err && m_snapshot_miss_cntr_en && !m_is_cache_hit) begin
      // if ((m_axi_mgr_rd_req_tran_q.size() && m_exp_block_fetch) && m_snapshot_miss_cntr_en && !m_is_cache_hit) begin
      `uvm_info(report_str, $sformatf("Update miss_cntr register, m_is_cpu_rd_err[%0d], m_snapshot_miss_cntr_en[%0d], m_is_cache_hit[%0d], m_snapshot_miss_cntr_lower['h%0h], m_snapshot_miss_cntr_upper['h%0h]",
                                      m_is_cpu_rd_err, m_snapshot_miss_cntr_en, m_is_cache_hit, m_snapshot_miss_cntr_lower, m_snapshot_miss_cntr_upper), UVM_HIGH)

      if (m_snapshot_miss_cntr_lower < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("miss_cntr_lower", m_snapshot_miss_cntr_lower + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "miss_cntr_lower", (m_snapshot_miss_cntr_lower+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "miss_cntr_lower"))
        end
      end else if (m_snapshot_miss_cntr_upper < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("miss_cntr_upper", m_snapshot_miss_cntr_upper + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "miss_cntr_upper", (m_snapshot_miss_cntr_upper+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "miss_cntr_upper"))
        end
      end

    end // if (!m_is_cpu_rd_err && m_snapshot_miss_cntr_en && !m_is_cache_hit) begin

    // lat_cntr
    if (!m_is_cpu_rd_err && m_snapshot_lat_cntr_en && !m_is_cache_hit) begin
      `uvm_info(report_str, $sformatf("Update lat_cntr register, m_is_cpu_rd_err[%0d], m_snapshot_lat_cntr_en[%0d], m_is_cache_hit[%0d], m_snapshot_lat_cntr_lower['h%0h], m_snapshot_lat_cntr_upper['h%0h]",
                                      m_is_cpu_rd_err, m_snapshot_lat_cntr_en, m_is_cache_hit, m_snapshot_lat_cntr_lower, m_snapshot_lat_cntr_upper), UVM_HIGH)

      // Scoreboard don't have a way to mesure the increasement yet, below incremental is just indication SB predict it will be changed
      if (m_snapshot_lat_cntr_lower < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("lat_cntr_lower", m_snapshot_lat_cntr_lower + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "lat_cntr_lower", (m_snapshot_lat_cntr_lower+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "lat_cntr_lower"))
        end
      end else if (m_snapshot_lat_cntr_upper < 32'hFFFF_FFFF) begin
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("lat_cntr_upper", m_snapshot_lat_cntr_upper + 1)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "lat_cntr_upper", (m_snapshot_lat_cntr_upper+1)), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "lat_cntr_upper"))
        end
      end

    end // if (!m_is_cpu_rd_err && m_snapshot_lat_cntr_en && !m_is_cache_hit) begin
  end // if (predicted_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE)



endfunction : set_exp_pkt_cpu_rd

function void sinc_sb_pkt_item::set_exp_pkt_cpu_wr();
  string report_str = "SB_PKT_CPU_WR";
  m_cpu_write     = (m_cpu_req_p_tran.m_rw == ccpui_cpu_mem_pkg::WRITE) ? 1 : 0;
  m_cpu_we        = m_cpu_req_p_tran.m_we;
  m_cpu_addr      = m_cpu_req_p_tran.m_addr;
  m_cpu_loadstore = m_cpu_req_p_tran.m_loadstore;
  m_cpu_privmode  = m_cpu_req_p_tran.m_privmode;
  m_mpu_cfg       = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];

  m_is_valid_req = m_top_configuration.m_sys_cfg.is_valid_req(SINC_SP, SINC_CPU_WRITE);

  // Cache-state race resolution (mirror of set_exp_pkt_cpu_rd's m_unpredicatable_state handling).
  // A concurrent FW SET_CACHE_ACTIVE command can finish (sinc_done) before its AXI write
  // response is processed, leaving the cmd register undecodable (SINC_FW_UNMAPPED) and
  // m_cur_cache_state stale at CACHE_INIT while update_tlb_when_op_finish sets
  // m_unpredicatable_state. If the live RTL cmu state has already moved to CACHE_ACTIVE, a
  // CPU write actually lands in Cache Active. Per MAS 10.7.1 item (1) all CPU writes in Cache
  // Active raise an MPU access violation (SINC_CACHE_ACTIVE_CPU_MEM_WRITE_ALLOWED == 0), so
  // resolve to the live RTL state and treat the request as not-valid. Fully gated: when the
  // state is predictable this block is a no-op and behavior is unchanged.
  if (m_top_configuration.m_sys_cfg.m_unpredicatable_state &&
      (sinc_cache_state_type_e'(m_top_configuration.m_sys_cfg.m_sinc_vif.sinc_cmu_state) == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
      (m_cur_cache_state == sinc_parameters_pkg::CACHE_INIT_STATE)) begin
    `uvm_info(report_str, $sformatf("Unpredictable cache state[%0d]: live RTL cmu state is CACHE_ACTIVE while TB tracked CACHE_INIT; resolving CPU write to Cache Active (MPU violation per MAS 10.7.1 item 1)",
        m_top_configuration.m_sys_cfg.m_unpredicatable_state), UVM_LOW)
    m_cur_cache_state = sinc_parameters_pkg::CACHE_ACTIVE_STATE;
    m_is_valid_req    = 0;
  end

  // erase busy error has highest priority
  if (m_top_configuration.m_sys_cfg.get_sinc_erase_in_progress()) begin
    // not accepted at SINC TOP
    m_exp_cache_mem                 = 0;
    m_cache_mem_transaction_num     = 0;
    m_access_while_erase_inprogress = 1;
    if (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE) begin
       // CPU_WE also checked, that if cpu_we == 0, it does not count as valid CPU WR
       if (m_cpu_we !== 0) begin
          m_exp_mpu_err_accvio            = 1;
       end else begin
          m_exp_mpu_err_accvio            = 0;
          m_is_mpu_status_update_expected = 0;
       end
    end
    return;
  end

  if (m_is_valid_req) begin
    // check if MPU allowed
    m_is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(m_cpu_write), .loadstore(m_cpu_loadstore), .accsrc(0), .priv_mode(m_cpu_privmode), .addr(m_cpu_addr), .r_acc_vio(m_r_acc_vio), .r_accvio_ex(m_r_accvio_ex), .r_accvio_rd(m_r_accvio_rd), .r_accvio_wr(m_r_accvio_wr));

    if (m_is_mpu_allowed) begin
      m_exp_cache_mem             = 1;
      m_cache_mem_transaction_num = 2; // read modify write
      m_is_write_performed        = 1;

      // additional check on the byte_en on write
      if (m_cpu_req_p_tran.m_we === 0) begin
        // no cache mem shall be written
        m_exp_cache_mem             = 0;
        m_cache_mem_transaction_num = 0; // read modify write
        m_is_write_performed        = 0;
      end
    end else begin
      // set expectation for MPU access violation after self check is done
      // Note: MPU only set violation if we is not 0
      if (m_cpu_we !== 0) begin
        m_exp_mpu_err_accvio = 1;
      end else begin
        if (m_cur_cache_state !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
          m_is_mpu_status_update_expected = 0;
        end
      end
    end

  end else begin
    // not accepted at SINC TOP
    m_exp_cache_mem = 0;

    // MPU write is not allowed
    m_r_acc_vio   = 0;
    m_r_accvio_ex = 0;
    m_r_accvio_rd = 0;
    m_r_accvio_wr = 1;

    m_exp_mpu_err_accvio = 1;
    m_is_mpu_allowed = 0;

    if (m_cpu_we == 0) begin
      m_exp_mpu_err_accvio = 0;
      m_is_mpu_status_update_expected = 0;
    end

    // // MPU violation is handler differently by cache fail state
    // if (m_cur_cache_state !== sinc_parameters_pkg::CACHE_FAIL_STATE) begin
    //   if (m_cpu_we == 0) begin
    //         m_exp_mpu_err_accvio = 0;
    //         m_is_mpu_status_update_expected = 0;
    //   end
    // end else begin
    //   // log the violation
    // end

  end

  `uvm_info(report_str, $sformatf("is_valid_req[%0d], m_is_mpu_allowed[%0d], m_exp_cache_mem[%0d], m_cache_mem_transaction_num[%0d], m_is_mpu_status_update_expected[%0d]",
      m_is_valid_req, m_is_mpu_allowed, m_exp_cache_mem, m_cache_mem_transaction_num, m_is_mpu_status_update_expected), UVM_LOW)

endfunction : set_exp_pkt_cpu_wr

function bit sinc_sb_pkt_item::check_complete();
  string report_str = "CHECK_COMPLETE";

  bit cache_mem_complete       = !m_exp_cache_mem;
  bit axi_sub_rd_resp_complete = !m_exp_axi_sub_rd_resp;
  bit axi_sub_wr_resp_complete = !m_exp_axi_sub_wr_resp;
  bit cpu_rd_resp_complete     = !m_exp_cpu_rd_resp;
  bit erase_done_complete      = !m_exp_erase_done;
  bit sinc_done_complete       = !m_exp_sinc_done;
  bit sinc_error_complete      = !m_exp_sinc_error;
  bit mpu_err_accvio_complete  = !m_exp_mpu_err_accvio;

  if (m_exp_cache_mem) begin
    cache_mem_complete = (m_cache_mem_pkt_q.size() >= m_cache_mem_transaction_num) ? 1 : 0;
    if (!cache_mem_complete) begin
      `uvm_info("Uncompleted packet:", $sformatf("cache_mem_complete:%0d", cache_mem_complete), UVM_HIGH)

      if (m_exp_sinc_error && (m_sinc_error_q.size() == 1)) begin
        cache_mem_complete = 1;
        `uvm_info("Adjust Uncompleted packet:", $sformatf("cache_mem_complete:%0d", cache_mem_complete), UVM_HIGH)
      end
    end
  end

  if (m_exp_erase_done) begin
    if (m_erase_done_tran_q.size() == 1) begin
      erase_done_complete = 1;
    end else if (m_erase_done_tran_q.size() > 1) begin
      `uvm_error(report_str, $sformatf("received more Erase Done Event than expected, exp[1], act [%0d]", m_erase_done_tran_q.size()))
    end
  end

  if (m_exp_sinc_done) begin
    sinc_done_complete = (m_sinc_done_q.size() == m_sinc_done_num) ? 1 : 0;
  end

  if (m_exp_sinc_error) begin
    sinc_error_complete = (m_sinc_error_q.size() == m_sinc_error_num) ? 1 : 0;
  end

  if (m_exp_mpu_err_accvio) begin
    mpu_err_accvio_complete = (m_mpu_err_accvio_q.size() == 1) ? 1 : 0;
  end

  if (m_exp_axi_sub_rd_resp) begin
    if (m_axi_sub_rd_resp_tran_q.size() == 1) begin
      axi_sub_rd_resp_complete = 1;
    end else if (m_axi_sub_rd_resp_tran_q.size() > 1) begin
      `uvm_error(report_str, $sformatf("received more AXI SUB response than expected, exp[1], act [%0d]", m_axi_sub_rd_resp_tran_q.size()))
    end
  end

  if (m_exp_axi_sub_wr_resp) begin
    if (m_axi_sub_wr_resp_tran_q.size() == 1) begin
      axi_sub_wr_resp_complete = 1;
    end else if (m_axi_sub_wr_resp_tran_q.size() > 1) begin
      `uvm_error(report_str, $sformatf("received more AXI SUB response than expected, exp[1], act [%0d]", m_axi_sub_wr_resp_tran_q.size()))
    end
  end

  if (m_exp_cpu_rd_resp) begin
    if (m_cpu_rd_resp_tran_q.size() == 1) begin
      cpu_rd_resp_complete = 1;
    end else if (m_cpu_rd_resp_tran_q.size() > 1) begin
      `uvm_error(report_str, $sformatf("received more CPU READ response than expected, exp[1], act [%0d]", m_cpu_rd_resp_tran_q.size()))
    end
  end

  if (cache_mem_complete && axi_sub_rd_resp_complete && axi_sub_wr_resp_complete && cpu_rd_resp_complete && erase_done_complete && sinc_done_complete && sinc_error_complete && mpu_err_accvio_complete) begin
    m_is_completed  = 1;
    m_req_done_time = $realtime;
    `uvm_info("Completed packet:", $sformatf("m_exp_cache_mem[%0d] - cache_mem_complete[%0d], m_exp_axi_sub_rd_resp[%0d] - axi_sub_rd_resp_complete[%0d], m_exp_axi_sub_wr_resp[%0d] - axi_sub_wr_resp_complete[%0d], m_exp_cpu_rd_resp[%0d] - cpu_rd_resp_complete[%0d], m_exp_erase_done[%0d] - erase_done_complete[%0d], m_exp_sinc_done[%0d] - sinc_done_complete[%0d], m_exp_sinc_error[%0d] - sinc_error_complete[%0d], m_exp_mpu_err_accvio[%0d] - mpu_err_accvio_complete[%0d]",
        m_exp_cache_mem, cache_mem_complete,
        m_exp_axi_sub_rd_resp, axi_sub_rd_resp_complete,
        m_exp_axi_sub_wr_resp, axi_sub_wr_resp_complete,
        m_exp_cpu_rd_resp, cpu_rd_resp_complete,
        m_exp_erase_done, erase_done_complete,
        m_exp_sinc_done, sinc_done_complete,
        m_exp_sinc_error, sinc_error_complete,
        m_exp_mpu_err_accvio, mpu_err_accvio_complete), UVM_HIGH)
    print_packet();
  end else begin
    `uvm_info("Not completed packet:", $sformatf("m_exp_cache_mem[%0d] - cache_mem_complete[%0d], m_exp_axi_sub_rd_resp[%0d] - axi_sub_rd_resp_complete[%0d], m_exp_axi_sub_wr_resp[%0d] - axi_sub_wr_resp_complete[%0d], m_exp_cpu_rd_resp[%0d] - cpu_rd_resp_complete[%0d], m_exp_erase_done[%0d] - erase_done_complete[%0d], m_exp_sinc_done[%0d] - sinc_done_complete[%0d], m_exp_mpu_err_accvio[%0d] - mpu_err_accvio_complete[%0d]",
        m_exp_cache_mem, cache_mem_complete,
        m_exp_axi_sub_rd_resp, axi_sub_rd_resp_complete,
        m_exp_axi_sub_wr_resp, axi_sub_wr_resp_complete,
        m_exp_cpu_rd_resp, cpu_rd_resp_complete,
        m_exp_erase_done, erase_done_complete,
        m_exp_sinc_done, sinc_done_complete,
        m_exp_mpu_err_accvio, mpu_err_accvio_complete), UVM_HIGH)
  end

  // NOTE: Below if is a trickey situation that if a status register read is waiting for FW operation finished, it will be too late to update TLB when receive SINC_DONE, thus update it earlier before the SINC_DONE asserted
  if (m_is_fw_cmd) begin
    if (cache_mem_complete && axi_sub_rd_resp_complete && axi_sub_wr_resp_complete && cpu_rd_resp_complete && erase_done_complete && !sinc_done_complete) begin
      // m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "busy", 0);
      // if (!m_top_configuration.m_sys_cfg.m_reg_tlb.get_complete()) begin
      //   m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "complete", m_exp_reg_status.complete);
      // end
      // if (!m_top_configuration.m_sys_cfg.m_reg_tlb.get_error_cmd()) begin
      //   m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "error_cmd", m_exp_reg_status.error_cmd);
      // end
      // m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "error_fault", m_exp_reg_status.error_fault);
      // if (!m_top_configuration.m_sys_cfg.m_reg_tlb.get_match_sts()) begin
      //   m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "match_sts", m_exp_reg_status.match_sts);
      // end
    end
  end // if (m_is_fw_cmd) begin

  // update system status on complete
  if (m_is_completed) begin
    // SINC Storage directory doesn't know when reset erase is done, leave the storage update here
    if (m_sinc_sb_pkt_entry == ENTRY_ERASE_AFTER_SOFT_RESET) begin
      // for (int i=0; i<sinc_parameters_pkg::CACHE_MEM_PHYSICAL_LINES; i++) begin
      //  m_top_configuration.m_sys_cfg.m_comp_cfg[SINC_CACHE_MEM].update_cache_mem(i, backdoor_value);
      // end
    end

    // set busy -> 0 for certain entries
    if ((m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_ERASE_AFTER_SOFT_RESET) ||
        (m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CREG_ERASE) ||
        m_is_fw_cmd) begin
      // m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "busy", 0);
      // predict busy -> 0
    end

    if ((m_req_dst == SINC_REG) &&
        (m_req_cmd == SINC_AXI_READ)) begin
      if (m_is_status_read) begin

      end else begin
        // m_exp_reg_data_resp_p[0] = m_top_configuration.m_sys_cfg.m_reg_tlb.get_reg_data_by_name(m_dst_reg.get_name());
        // `uvm_info(report_str, $sformatf("Set Response Phase Reg data:['h%0h]", m_exp_reg_data_resp_p[0]), UVM_HIGH);
      end
    end

    if (m_is_fw_cmd) begin

    end
  end

  return (m_is_completed);

endfunction : check_complete

function void sinc_sb_pkt_item::inject_cache_mem_tran(mem_transaction t);
  string report_str = "INJECT_CACHE_MEM_TRAN";

  `uvm_info(report_str, $sformatf("inject cache_mem_tran for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_cache_mem_pkt_q.push_back(t);

  if ((m_sinc_sb_pkt_entry == ENTRY_ERASE_AFTER_SOFT_RESET) ||
      (m_sinc_sb_pkt_entry == ENTRY_CREG_ERASE)) begin
    // m_top_configuration.m_sys_cfg.m_reg_tlb.set_reg_field_by_name("status", "busy", 1);
    // set busy
  end

  void'(check_complete());
endfunction : inject_cache_mem_tran

function void sinc_sb_pkt_item::inject_axi_sub_rd_resp(pal_axi_xaction t);
  string report_str = "INJECT_AXI_SUB_RD_RESP";

  `uvm_info(report_str, $sformatf("inject axi_sub_rd_resp for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_axi_sub_rd_resp_tran_q.push_back(t);

  if (m_req_dst == SINC_REG) begin
    if (m_dst_reg !== null) begin
      // response phase data of the register
      m_exp_reg_data_resp_p    = new [1];
      m_exp_reg_data_resp_p[0] = sinc_axi_data_t'(m_dst_reg.get_mirrored_value());//m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_data_by_name(m_dst_reg.get_name());
      `uvm_info(report_str, $sformatf("REG: m_req_src[%0s], m_req_dst[%0s], reg_name[%0s], reg_data['h%0h], EXP:SLV_ERR[%0d]",
          m_req_src.name(), m_req_dst.name(), m_dst_reg.get_name(), m_exp_reg_data_resp_p[0], m_exp_sub_slv_err), UVM_LOW)
    end else begin
      // response phase data of the register
      m_exp_reg_data_resp_p    = new [1];
      m_exp_reg_data_resp_p[0] = 0;
    end
  end

  void'(check_complete());
endfunction : inject_axi_sub_rd_resp

function void sinc_sb_pkt_item::inject_axi_mgr_rd_req(pal_axi_xaction t);
  string report_str   = "INJECT_AXI_MGR_RD_REQ";
  bit    slv_err_seen;
  `uvm_info(report_str, $sformatf("inject axi_mgr_rd_req for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  // at first block fetch, clear ongoing status register again (this is due to concurrent transaction corner case for example, FW command and CPU at same time, FW command set cmd invalid, but cpu remove it instantly)
  // only do it at first AXI MGR read
  if ((m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
      m_exp_block_fetch &&
      (m_axi_mgr_rd_req_tran_q.size() == 0)
    ) begin
    // Note: found at design behavior, the CMD_SUCCESS/INVALID/CMDFAIL will be set 0 whenever a fetch_block issued
    // Changed with recent RTL: (internal link removed)
    uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
    sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

    cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 0;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b0;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b0;
    // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    //   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    // end else begin
    //   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    // end

    m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time = $realtime;
  end

  m_axi_mgr_rd_req_tran_q.push_back(t);

  void'(check_complete());
endfunction : inject_axi_mgr_rd_req

function void sinc_sb_pkt_item::inject_axi_mgr_rd_resp(pal_axi_xaction t);
  string      report_str              = "INJECT_AXI_MGR_RD_RESP";
  int         last_axi_mgr_rd_req_idx = m_axi_mgr_rd_req_tran_q.size() - 1;
  sinc_comp_e req_dst;
  bit         slv_err_seen;

  `uvm_info(report_str, $sformatf("inject axi_mgr_rd_resp for entry [%0s], size[%0d]", m_sinc_sb_pkt_entry.name(), t.data.size()), UVM_HIGH)

  print_packet();

  m_axi_mgr_rd_resp_tran_q.push_back(t);

  // match the resp with req
  if ((m_axi_mgr_rd_req_tran_q.size() == 0)) begin
    `uvm_error(report_str, $sformatf("Fail to locate right match, m_axi_mgr_rd_req_tran_q.size[%0d]",
                                     m_axi_mgr_rd_req_tran_q.size()))
  end else begin
    bit found_req_match = 0;
    foreach (m_axi_mgr_rd_req_tran_q[i]) begin
      if ((m_axi_mgr_rd_req_tran_q[i].addr == t.addr) ||
          (m_axi_mgr_rd_req_tran_q[i].tag_id == t.tag_id)) begin
        // SINC can issue back to back RD, as long as it match with pending req found in scoreboard
        found_req_match = 1;
      end
    end

    if (!found_req_match) begin
      `uvm_error(report_str, $sformatf("Fail to locate right match, exp_addr['h%0h], exp_tag['h%0h]",
                                       t.addr, t.tag_id))
    end
  end

  // triage the response data
  req_dst = m_addr_dec.get_dst_type_hit_w_axi_addr(t.addr);

  if ((t.cmd == PAL_READ) || (t.cmd == PAL_EXRD) || (t.cmd == PAL_LOCKRD)) begin
    foreach (t.rdresp[i]) begin
      `uvm_info(report_str, $sformatf("t.rdresp[%0d][%0s]", i, t.rdresp[i].name()), UVM_HIGH)
      if ((t.rdresp[i] !== PAL_RESP_OKAY) &&
          (t.rdresp[i] !== PAL_RESP_EXOKAY)) begin
        slv_err_seen = 1;
        `uvm_info(report_str, $sformatf("slv_err_seen[%0s], for sb_pkg_entry[%0s]", t.rdresp[i].name(), m_sinc_sb_pkt_entry.name()), UVM_HIGH)
        if (t.rdresp[i] == PAL_RESP_DECERR) begin
          if (m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK) begin
            m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID] = 1;
          end
        end
      end
    end
  end

  // - triage transaction
  case (req_dst)
    sinc_env_pkg::SINC_KSU : begin
      m_act_ksu_data_axi_mgr_rd_resp_tran_q.push_back(t);
      if (slv_err_seen) begin
        m_is_ksu_rd_error                            = 1;
        m_is_fw_op_fail                              = 1;
        m_exp_sinc_done                              = 0;
        m_sinc_done_num                              = 0;
        m_exp_sinc_error                             = 1;
        m_sinc_error_num                             = 1;
        m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;

        // for coverage
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE] = 1;
      end
    end
    sinc_env_pkg::SINC_RNG : begin
      m_act_rng_data_axi_mgr_rd_resp_tran_q.push_back(t);
      if (slv_err_seen) begin
        m_is_rng_fetch_error = 1;
        if (m_is_fw_cmd &&
            (m_fw_cmd == sinc_parameters_pkg::SINC_SET_INIT_STATE)) begin
          m_is_fw_op_fail       = 1;
          m_exp_sinc_done       = 0;
          m_sinc_done_num       = 0;
          m_exp_sinc_error      = 1;
          m_sinc_error_num      = 1;
          m_rng_seed_is_fetched = 0;

          // for coverage
          m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE] = 1;
        end
      end
    end
    sinc_env_pkg::SINC_SHAREDRAM : begin
      m_act_sharedram_data_axi_mgr_rd_resp_tran_q.push_back(t);
      if (slv_err_seen) begin
        m_is_sharedram_rd_error = 1;
        m_is_fw_op_fail         = 1;
        m_exp_sinc_done         = 0;
        m_sinc_done_num         = 0;
        m_exp_sinc_error        = 1;
        m_sinc_error_num        = 1;

        // for coverage
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR] = 1;
      end
    end
    sinc_env_pkg::SINC_DMB : begin
      if (slv_err_seen) begin
        m_is_dmb_read_error = 1;
      end
      if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
        if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
          m_act_dmb_block_data_axi_mgr_rd_resp_tran_q.push_back(t);
          if (slv_err_seen) begin
            m_is_dmb_encrypt_data_read_error = 1;
          end
        end else begin
          m_act_dmb_auth_tag_data_axi_mgr_rd_resp_tran_q.push_back(t);
          if (slv_err_seen) begin
            m_is_dmb_auth_tag_read_error = 1;
          end
        end
      end else begin
        if (t.addr < m_snapshot_ext_block_base_addr) begin
          m_act_dmb_auth_tag_data_axi_mgr_rd_resp_tran_q.push_back(t);
          if (slv_err_seen) begin
            m_is_dmb_auth_tag_read_error = 1;
          end
        end else begin
          m_act_dmb_block_data_axi_mgr_rd_resp_tran_q.push_back(t);
          if (slv_err_seen) begin
            m_is_dmb_encrypt_data_read_error = 1;
          end
        end
      end // if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
    end // sinc_env_pkg::SINC_DMB : begin

    default: begin
      if (m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) begin
        m_is_dmb_read_error = 1;
        m_top_configuration.m_sys_cfg.m_unmapped_axi_mgr_rd_when_block_fetch = 1;
        if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
          if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
            m_act_dmb_block_data_axi_mgr_rd_resp_tran_q.push_back(t);
            if (slv_err_seen) begin
              m_is_dmb_encrypt_data_read_error = 1;
            end
          end else begin
            m_act_dmb_auth_tag_data_axi_mgr_rd_resp_tran_q.push_back(t);
            if (slv_err_seen) begin
              m_is_dmb_auth_tag_read_error = 1;
            end
          end
        end else begin
          if (t.addr < m_snapshot_ext_block_base_addr) begin
            m_act_dmb_auth_tag_data_axi_mgr_rd_resp_tran_q.push_back(t);
            if (slv_err_seen) begin
              m_is_dmb_auth_tag_read_error = 1;
            end
          end else begin
            m_act_dmb_block_data_axi_mgr_rd_resp_tran_q.push_back(t);
            if (slv_err_seen) begin
              m_is_dmb_encrypt_data_read_error = 1;
            end
          end
        end // if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
      end else if ((m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK) ||
          (m_fw_cmd == sinc_parameters_pkg::SINC_SET_INIT_STATE)) begin
        if (slv_err_seen) begin
          m_is_sharedram_rd_error = 1;
          m_is_fw_op_fail         = 1;
          m_exp_sinc_done         = 0;
          m_sinc_done_num         = 0;
          m_exp_sinc_error        = 1;
          m_sinc_error_num        = 1;

          // for coverage
          m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR] = 1;
        end
      end else begin

        `uvm_error(report_str, $sformatf("received unexpected rd_resp, m_req_dst[%0s], SB_ENTRY[%0s]", req_dst.name(), m_sinc_sb_pkt_entry.name()))
      end

    end
  endcase // case (m_req_dst)

  if ((m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
      (m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
      m_exp_axi_mgr_rd_req &&
      slv_err_seen) begin
    m_is_fw_op_fail       = 1;
    m_is_fetch_block_fail = 1;
    m_exp_sinc_error      = 1;
    m_sinc_error_num      = 1;
    m_is_cpu_rd_err       = 1;
    `uvm_info(report_str, $sformatf("Found CPU REQ fail with m_is_cpu_rd_err[%0d], m_is_dmb_auth_tag_read_error[%0d], m_is_dmb_encrypt_data_read_error[%0d]",
        m_is_cpu_rd_err, m_is_dmb_auth_tag_read_error, m_is_dmb_encrypt_data_read_error), UVM_LOW)
  end

  // - triage data bytes
  foreach (t.data[i]) begin
    case (req_dst)
      sinc_env_pkg::SINC_KSU : begin
        m_act_ksu_r_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_RNG : begin
        m_act_rng_r_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_SHAREDRAM : begin
        m_act_sharedram_r_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_DMB : begin
        if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
          if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
            m_act_dmb_block_r_data.push_back(t.data[i]);
          end else begin
            m_act_dmb_auth_tag_r_data.push_back(t.data[i]);
          end
        end else begin
          if (t.addr < m_snapshot_ext_block_base_addr) begin
            m_act_dmb_auth_tag_r_data.push_back(t.data[i]);
          end else begin
            m_act_dmb_block_r_data.push_back(t.data[i]);
          end
        end // if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
      end // sinc_env_pkg::SINC_DMB : begin

      default: begin
        // `uvm_error(report_str, $sformatf("received unexpected rd_resp, m_req_dst[%0s], SB_ENTRY[%0s]", m_req_dst.name(), m_sinc_sb_pkt_entry.name()))
      end
    endcase // case (m_req_dst)
  end

  m_act_axi_mgr_rd_size_received = m_act_ksu_r_data.size() + m_act_rng_r_data.size() + m_act_sharedram_r_data.size() + m_act_dmb_block_r_data.size() + m_act_dmb_auth_tag_r_data.size();

  void'(check_complete());

  // check the tag if CPU read miss in cache active state
  if (m_is_cpu_mem_req &&
      !m_is_cache_hit &&
      m_exp_block_fetch) begin
    if (m_exp_axi_mgr_rd_size == m_act_axi_mgr_rd_size_received) begin
      if (is_cpu_rd_auth_tag_match()) begin
        // proceed current prediction
      end else begin
        m_is_auth_tag_mismatch_error = 1;
        m_exp_sinc_error             = 1;
        m_sinc_error_num             = 1;
        m_is_cpu_rd_err              = 1;
        m_is_fetch_block_fail        = 1;
      end
      // remove in progress
      begin
        uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
        sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

        cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
        cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 0;
        // Note: found at design behavior, the CMD_SUCCESS/INVALID/CMDFAIL will be set 0 whenever a fetch_block issued
        cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b0;
        cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b0;

        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
        end

        // set the flag for concurrent transaction check
        m_top_configuration.m_sys_cfg.m_block_fetch_finished = $realtime;
      end
    end
  end
endfunction : inject_axi_mgr_rd_resp

function void sinc_sb_pkt_item::inject_axi_mgr_wr_req(pal_axi_xaction t);
  string report_str = "INJECT_AXI_MGR_WR_REQ";

  `uvm_info(report_str, $sformatf("inject axi_mgr_wr_req for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_axi_mgr_wr_req_tran_q.push_back(t);

  void'(check_complete());
endfunction : inject_axi_mgr_wr_req

function void sinc_sb_pkt_item::inject_axi_mgr_wr_resp(pal_axi_xaction t);
  string      report_str              = "INJECT_AXI_MGR_WR_RESP";
  int         last_axi_mgr_wr_req_idx = m_axi_mgr_wr_req_tran_q.size() - 1;
  sinc_comp_e req_dst;
  bit         slv_err_seen;

  `uvm_info(report_str, $sformatf("inject axi_mgr_wr_resp for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_axi_mgr_wr_resp_tran_q.push_back(t);

  // match the resp with req
  if ((m_axi_mgr_wr_req_tran_q.size() == 0)) begin
    `uvm_error(report_str, $sformatf("Fail to locate right match, m_axi_mgr_wr_req_tran_q.size[%0d]",
        m_axi_mgr_wr_req_tran_q.size()))
  end else begin
    if ((m_axi_mgr_wr_req_tran_q[last_axi_mgr_wr_req_idx].addr !== t.addr) ||
        (m_axi_mgr_wr_req_tran_q[last_axi_mgr_wr_req_idx].tag_id !== t.tag_id)) begin
      `uvm_error(report_str, $sformatf("Fail to locate right match, last_axi_mgr_wr_req_idx[%0d], exp_addr['h%0h], act_addr['h%0h], exp_tag['h%0h], act_tag['h%0h]",
          last_axi_mgr_wr_req_idx, m_axi_mgr_wr_req_tran_q[last_axi_mgr_wr_req_idx].addr, t.addr, m_axi_mgr_wr_req_tran_q[last_axi_mgr_wr_req_idx].tag_id, t.tag_id))
    end
  end

  if ((t.cmd == PAL_WRITE) || (t.cmd == PAL_EXWR) || (t.cmd == PAL_LOCKWR)) begin
    `uvm_info(report_str, $sformatf("t.t.wrresp[%0s]", t.wrresp.name()), UVM_HIGH)
    if ((t.wrresp !== PAL_RESP_OKAY) &&
        (t.wrresp !== PAL_RESP_EXOKAY)) begin
      slv_err_seen = 1;
      if (t.wrresp == PAL_RESP_DECERR) begin
        if (m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK) begin
          m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] = 1;
        end
      end
    end
  end

  // triage the response data
  req_dst = m_addr_dec.get_dst_type_hit_w_axi_addr(t.addr);
  // - triage transaction
  case (req_dst)
    sinc_env_pkg::SINC_KSU : begin
      m_act_ksu_data_axi_mgr_wr_resp_tran_q.push_back(t);
    end
    sinc_env_pkg::SINC_RNG : begin
      m_act_rng_data_axi_mgr_wr_resp_tran_q.push_back(t);
    end
    sinc_env_pkg::SINC_SHAREDRAM : begin
      m_act_sharedram_data_axi_mgr_wr_resp_tran_q.push_back(t);
    end
    sinc_env_pkg::SINC_DMB : begin
      if (slv_err_seen) begin
        m_is_dmb_write_error                                                                    = 1;
        m_is_fw_op_fail                                                                         = 1;
        m_exp_sinc_done                                                                         = 0;
        m_sinc_done_num                                                                         = 0;
        m_exp_sinc_error                                                                        = 1;
        m_sinc_error_num                                                                        = 1;
        // note: below error secnarios are relevant, all converting to DMB write response error
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID]  = 1;
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] = 1;

        `uvm_info(report_str, $sformatf("Found AXI MGR error m_is_dmb_write_error[%0d]", m_is_dmb_write_error), UVM_HIGH)

        if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
          if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
            m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR] = 1;
            m_is_dmb_encrypt_data_write_error                                                     = 1;
            // m_act_dmb_block_data_axi_mgr_wr_resp_tran_q.push_back(t);
          end else begin
            m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR] = 1;
            m_is_dmb_auth_tag_write_error                                                      = 1;
            // m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q.push_back(t);
          end
        end else begin
          if (t.addr < m_snapshot_ext_block_base_addr) begin
            m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR] = 1;
            // m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q.push_back(t);
            m_is_dmb_auth_tag_write_error                                                      = 1;
          end else begin
            m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR] = 1;
            // m_act_dmb_block_data_axi_mgr_wr_resp_tran_q.push_back(t);
            m_is_dmb_encrypt_data_write_error                                                     = 1;
          end
        end // if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
      end

      if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
        if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
          m_act_dmb_block_data_axi_mgr_wr_resp_tran_q.push_back(t);
        end else begin
          m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q.push_back(t);
        end
      end else begin
        if (t.addr < m_snapshot_ext_block_base_addr) begin
          m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q.push_back(t);
        end else begin
          m_act_dmb_block_data_axi_mgr_wr_resp_tran_q.push_back(t);
        end
      end // if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
    end // sinc_env_pkg::SINC_DMB : begin

    default: begin
      // `uvm_error(report_str, $sformatf("received unexpected wr_resp, m_req_dst[%0s], SB_ENTRY[%0s]", m_req_dst.name(), m_sinc_sb_pkt_entry.name()))
      if ((m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK)) begin
        m_is_dmb_write_error                                                                    = 1;
        m_is_fw_op_fail                                                                         = 1;
        m_exp_sinc_done                                                                         = 0;
        m_sinc_done_num                                                                         = 0;
        m_exp_sinc_error                                                                        = 1;
        m_sinc_error_num                                                                        = 1;
        // note: below error secnarios are relevant, all converting to DMB write response error
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID]  = 1;
        m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID] = 1;

        `uvm_info(report_str, $sformatf("Found AXI MGR error m_is_dmb_write_error[%0d]", m_is_dmb_write_error), UVM_HIGH)

      end
    end
  endcase // case (m_req_dst)

  // - triage data bytes
  foreach (t.data[i]) begin
    case (req_dst)
      sinc_env_pkg::SINC_KSU : begin
        m_act_ksu_w_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_RNG : begin
        m_act_rng_w_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_SHAREDRAM : begin
        m_act_sharedram_w_data.push_back(t.data[i]);
      end
      sinc_env_pkg::SINC_DMB : begin
        if (m_snapshot_ext_block_base_addr <= m_snapshot_ext_auth_tag_base_addr) begin
          if (t.addr < m_snapshot_ext_auth_tag_base_addr) begin
            m_act_dmb_block_w_data.push_back(t.data[i]);
          end else begin
            m_act_dmb_auth_tag_w_data.push_back(t.data[i]);
          end
        end else begin
          if (t.addr < m_snapshot_ext_block_base_addr) begin
            m_act_dmb_auth_tag_w_data.push_back(t.data[i]);
          end else begin
            m_act_dmb_block_w_data.push_back(t.data[i]);
          end
        end
      end

      default: begin
        // `uvm_error(report_str, $sformatf("received unexpected wr_resp[%0s]", m_sinc_sb_pkt_entry.name()))
      end
    endcase // case (m_req_dst)
  end

  m_act_axi_mgr_wr_size_received = m_act_ksu_w_data.size() + m_act_rng_w_data.size() + m_act_sharedram_w_data.size() + m_act_dmb_block_w_data.size() + m_act_dmb_auth_tag_w_data.size();

  void'(check_complete());
endfunction : inject_axi_mgr_wr_resp

function void sinc_sb_pkt_item::inject_cpu_rd_resp(ccpui_cpu_mem_transaction t);
  string report_str = "INJECT_CPU_RD_RESP";

  `uvm_info(report_str, $sformatf("inject cpu_rd_resp for entry [%0s], addr['h%0h], data['h%0h]", m_sinc_sb_pkt_entry.name(), t.m_addr, t.m_rdata), UVM_HIGH)

  m_cpu_rd_resp_tran_q.push_back(t);

  // update CSD if cache miss, only update when valid response
  if (m_exp_block_fetch && !t.m_rd_err) begin
    m_is_update_csd = 1;
    // if(!m_top_configuration.m_csd.update_cache_line(csd_address_t'(m_cpu_addr))) begin
    //      `uvm_error(report_str, $sformatf("Fail to update cache line with m_CPU_ADDR['h%0h]", m_cpu_addr))
    // end
  end else if (m_exp_block_fetch && t.m_rd_err) begin
    m_is_update_csd = 0;
    `uvm_info(report_str, $sformatf("Skip CSD update due to read e-r-r-o-r: %0s", m_sinc_sb_pkt_entry.name()), UVM_HIGH)
    print_packet();

    if (m_exp_block_fetch_cancelled) begin
      m_exp_cache_mem                 = 0;
      m_cache_mem_transaction_num     = 0;
      m_is_mpu_status_update_expected = 0;
      m_exp_axi_mgr_rd_req            = 0;
      m_exp_axi_mgr_rd_size           = 0;
    end
  end

  // update expectation when cpu_rd_resp is error
  if (!m_is_cpu_rd_err && t.m_rd_err) begin
    if (m_cur_cache_state !== sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
      // check if erase is inprogress
      if (m_top_configuration.m_sinc_vif.sinc_start_erase) begin
        m_erase_during_req_inprogress = 1;
        m_is_cpu_rd_err               = 1;
        `uvm_info(report_str, $sformatf("Adjust entry [%0s], m_erase_during_req_inprogress[%0h], m_is_cpu_rd_err[%0d]",
                                        m_sinc_sb_pkt_entry.name(), m_erase_during_req_inprogress, m_is_cpu_rd_err), UVM_HIGH)
      end
    end

    if (m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) begin
      // check if CMU is busy
      if (m_top_configuration.m_sinc_vif.sinc_flopped_cmu_busy) begin
        m_exp_cache_mem                 = 0;
        m_cache_mem_transaction_num     = 0;
        m_is_mpu_status_update_expected = 0;
        m_exp_axi_mgr_rd_req            = 0;
        m_exp_axi_mgr_rd_size           = 0;
        m_is_cpu_rd_err                 = 1;
        m_exp_block_fetch               = 0;

        `uvm_info(report_str, $sformatf("Adjust entry [%0s], sinc_flopped_cmu_busy[%0h], m_is_cpu_rd_err[%0d]",
                                        m_sinc_sb_pkt_entry.name(), m_top_configuration.m_sinc_vif.sinc_flopped_cmu_busy, m_is_cpu_rd_err), UVM_HIGH)
      end
    end
  end

  void'(check_complete());
endfunction : inject_cpu_rd_resp

function void sinc_sb_pkt_item::inject_axi_sub_wr_resp(pal_axi_xaction t);
  string report_str           = "INJECT_AXI_SUB_WR_RESP";
  bit    is_fw_prediction_set = 0;
  bit    is_strobe_match_exp  = 1;

  `uvm_info(report_str, $sformatf("inject axi_sub_wr_resp for entry [%0s], m_exp_sub_slv_err[%0d]", m_sinc_sb_pkt_entry.name(), m_exp_sub_slv_err), UVM_HIGH)

  m_axi_sub_wr_resp_tran_q.push_back(t);

  // check on the strobe size
  if (t.wstrb.size() < 4) begin
    is_strobe_match_exp = 0;
    `uvm_info(report_str, $sformatf("is_strobe_match_exp [%0d]", is_strobe_match_exp), UVM_HIGH)
  end

  // check on the write strobe enable
  foreach (t.wstrb[idx]) begin
    if (!t.wstrb[idx]) begin
      is_strobe_match_exp = 0;
      `uvm_info(report_str, $sformatf("is_strobe_match_exp [%0d]", is_strobe_match_exp), UVM_HIGH)

      // for coverage
      m_sinc_axi_wr_reg_err_types[`SINC_AXI_WR_ERR_UNSUPPORTED_STROBE] = 1;
      break;
    end
  end

  if (!is_strobe_match_exp) begin
    m_write_access_with_unsupported_strobe = 1;
    m_exp_sub_slv_err                      = 1;
    m_exp_sinc_done = 0;
    `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
        m_exp_sub_slv_err), UVM_HIGH)
    m_exp_cache_mem = 0;
    `uvm_info(report_str, $sformatf("Write Access with unsupported wstrb[size:%0d] : [%0p]",
        t.wstrb.size(), t.wstrb), UVM_LOW)
  end

  // Update prediction on FW CMD with aes_test_mode_en
  if (m_is_exp_aes_test_en) begin
    sinc_reg_data_t wr_reg_data;
    sinc_reg_data_t my_reg_data[];
    my_reg_data = new [1];

    for (int i=0; i < (m_axi_sub_wr_resp_tran_q[0].data.size() / 4); i++) begin
      my_reg_data[i] = {m_axi_sub_wr_resp_tran_q[0].data[3 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[2 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[1 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[0 + (i * 4)]};
    end

    wr_reg_data = my_reg_data[0];

    if (wr_reg_data == 0) begin
      // previous prediction is right
    end else begin
      // previous prediction is wrong
      m_is_fw_blocked_due_to_unread_status = 1;
      m_exp_sub_slv_err                    = 1;
      `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
          m_exp_sub_slv_err), UVM_HIGH)
    end
  end

  // check slv_err for correction of prediction at address phase
  if (m_exp_sub_slv_err && (t.wrresp == PAL_RESP_OKAY)) begin
    uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
    sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
    bit response_phase_match            = 0;
    print_packet();
    // check if the response phase has cleared read status
    if (m_is_fw_blocked_due_to_unread_status) begin
      if (cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] ||
          cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] ||
          cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] ||
          cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE]) begin
        // address phase prediction is right
      end else begin
        response_phase_match                 = 1;
        m_is_fw_blocked_due_to_unread_status = 0;
        m_exp_sub_slv_err                    = 0;
        m_is_fw_cmd                          = 1;
        m_exp_sinc_done                      = 1;
        m_sinc_done_num                      = 1;
        `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
      end
    end

    if (!response_phase_match) begin
      bit match_case_found = 0;
      // exception case: when address phase has determine slv_error due to CMU busy, the ongoing CMU command can be short enough that finished in one or two cycles before the data phase arrived
      if (m_axi_access_while_cmu_busy && !m_top_configuration.m_sinc_vif.sinc_cmu_active_cmd) begin
        m_exp_sub_slv_err = 0;
        match_case_found  = 1;
        `uvm_info(report_str, $sformatf("Adjust pkt's m_exp_sub_slv_err to ['h%0h] from 1",
                                        m_exp_sub_slv_err), UVM_HIGH)
      end

      if (!match_case_found) begin
        `uvm_error(report_str, $sformatf("Expect SLV_ERR[%0d], Actual Response[%0s]", m_exp_sub_slv_err, t.wrresp.name()))
      end
    end
  end

  // additional check on write to CMD register, only able to set expectation when acknowledged write data
  // 1. write reserved region of CMD register will result AXI SLV Error
  // 2. write reserved CMD type will result command fail -> SINC will not issue the FW command
  // 3. if above are not true, then FW command will be issued, set corresponding expectation
  if (!m_exp_sub_slv_err && (t.wrresp == PAL_RESP_OKAY)) begin
    if (m_dst_reg !== null ) begin
      bit skip_reg_predict = 0;
      // set predict value of register
      sinc_reg_data_t my_reg_data[];
      my_reg_data = new [1];

      for (int i=0; i < (m_axi_sub_wr_resp_tran_q[0].data.size() / 4); i++) begin
        my_reg_data[i] = {m_axi_sub_wr_resp_tran_q[0].data[3 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[2 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[1 + (i * 4)], m_axi_sub_wr_resp_tran_q[0].data[0 + (i * 4)]};
      end

      m_write_reg_data = my_reg_data[0];

      if ((m_req_dst == SINC_REG) &&
          (m_dst_reg.get_name() == sinc_parameters_pkg::CMD_REG_NAME)) begin
        if (t.wrresp == PAL_RESP_SLVERR) begin
          // clear expected prefetch
          // prefetch is always 1 transaction
          m_exp_cache_mem             = 0;
          m_cache_mem_transaction_num = 0;
        end

        // set the prediction precisely
        set_exp_fw_cmd(t);

        // certain FW commands register filed will be clear after a cycle
        // : disable_reset, disable_reinit
        if ((m_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_RESET) ||
            (m_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_REINIT)) begin
          skip_reg_predict = 1;
        end
      end else begin
        // reserved statement
      end

      // set register mirror
      if (!m_is_reg_write_discarded && !skip_reg_predict) begin
        `uvm_info(report_str, $sformatf("update tlb reg[%0s], data['h%0h]", m_dst_reg.get_name(), my_reg_data[0]), UVM_HIGH)
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(m_dst_reg.get_name(), my_reg_data[0])) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", m_dst_reg.get_name(), my_reg_data[0]), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", m_dst_reg.get_name()))
        end
      end else begin
        `uvm_info(report_str, $sformatf("skip update tlb due to write discard[%0d], skip_reg_predict[%0d], reg[%0s], data['h%0h]", m_is_reg_write_discarded, skip_reg_predict, m_dst_reg.get_name(), my_reg_data[0]), UVM_HIGH)
      end

    end
  end begin
    if (!m_exp_sub_slv_err && (t.wrresp !== PAL_RESP_OKAY)) begin
      print_packet();
      // when CPU RD and AXI write at same time, Fetch Block can invalid the AXI write
      if ((m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
          (m_top_configuration.m_sinc_vif.sinc_cmu_active_cmd) &&
          // (m_top_configuration.m_sinc_vif.sinc_cmu_ctrl_state == FETCH_BLOCK)) begin // 7'h07
          (m_top_configuration.m_sinc_vif.sinc_cmu_ctrl_state == 7'h07)) begin // 7'h07
        m_exp_sub_slv_err = 1;
        m_is_fw_cmd     = 0;
        m_exp_sinc_done = 0;
        m_sinc_done_num = 0;
        `uvm_info(report_str, $sformatf("Found FETCH_BLOCK, set m_exp_sub_slv_err[%0d]", m_exp_sub_slv_err), UVM_HIGH)

      end else begin
        `uvm_error(report_str, $sformatf("Expect SLV_ERR[%0d], Actual Response[%0s]", m_exp_sub_slv_err, t.wrresp.name()))
      end
    end

    if (m_exp_sub_slv_err && (t.wrresp == PAL_RESP_OKAY)) begin
      uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
      sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
      bit response_phase_match            = 0;
      print_packet();
      // check if the response phase has cleared read status
      if (m_is_fw_blocked_due_to_unread_status) begin
        if (cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] ||
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] ||
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] ||
            cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE]) begin
          // address phase prediction is right
        end else begin
          response_phase_match                 = 1;
          m_is_fw_blocked_due_to_unread_status = 0;
          m_exp_sub_slv_err                    = 0;
          m_is_fw_cmd                          = 1;
          m_exp_sinc_done                      = 1;
          m_sinc_done_num                      = 1;
          `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
        end
      end

      if (!response_phase_match) begin
        `uvm_error(report_str, $sformatf("Expect SLV_ERR[%0d], Actual Response[%0s]", m_exp_sub_slv_err, t.wrresp.name()))
      end
    end

  end


  print_packet();
  void'(check_complete());
endfunction : inject_axi_sub_wr_resp

function void sinc_sb_pkt_item::inject_erase_done(ramwrap_erase_transaction t);
  string report_str = "INJECT_ERASE_DONE";

  `uvm_info(report_str, $sformatf("inject erase_done for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_erase_done_tran_q.push_back(t);

  void'(check_complete());
endfunction : inject_erase_done

function void sinc_sb_pkt_item::inject_sinc_done(sinc_monitor_pkg::sinc_sideband_e t);
  string report_str = "INJECT_SINC_DONE";

  `uvm_info(report_str, $sformatf("inject sinc_done for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_sinc_done_q.push_back(t);

  if (m_is_fw_cmd) begin
    // set_sys_mirror();
    void'(update_tlb_when_op_finish());
  end

  void'(check_complete());
endfunction : inject_sinc_done

function void sinc_sb_pkt_item::inject_sinc_error(sinc_monitor_pkg::sinc_sideband_e t);
  string report_str = "INJECT_SINC_ERROR";

  `uvm_info(report_str, $sformatf("inject sinc_error for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  m_top_configuration.m_sys_cfg.m_recent_sinc_error_time = $realtime;

  m_sinc_error_q.push_back(t);

  if (m_exp_sinc_done && m_fw_op_invalid_due_to_adjacent_block_fetch) begin
    uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
    sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;

    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end
  end

  if (m_is_fw_cmd) begin
    // set_sys_mirror();
    void'(update_tlb_when_op_finish());
  end
  void'(check_complete());
endfunction : inject_sinc_error

function void sinc_sb_pkt_item::inject_mpu_err_accvio(ccpui_mpu_transaction t);
  string report_str = "INJECT_MPU_ERR_ACCVIO";
  time diff_time;
  int diff_cycles;

  diff_time = $realtime - m_req_tr_time;
  diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);

  `uvm_info(report_str, $sformatf("inject mpu_err_accvio for entry [%0s]", m_sinc_sb_pkt_entry.name()), UVM_HIGH)

  if (diff_cycles > 10) begin
    `uvm_error(report_str, $sformatf("Found suspicious MPU Violation assosiated with transaction, m_req_tr_time[%0t], diff_cycles[%0d]", m_req_tr_time, diff_cycles))
  end

  m_mpu_err_accvio_q.push_back(t);

  void'(check_complete());
endfunction : inject_mpu_err_accvio

function bit sinc_sb_pkt_item::is_completed(bit enable_report=0);
  string report_str               = "IS_COMPLETED";
  bit    cache_mem_complete       = !m_exp_cache_mem;
  bit    axi_sub_rd_resp_complete = !m_exp_axi_sub_rd_resp;
  bit    axi_sub_wr_resp_complete = !m_exp_axi_sub_wr_resp;
  bit    erase_done_complete      = !m_exp_erase_done;
  bit    sinc_done_complete       = !m_exp_sinc_done;
  bit    sinc_error_complete      = !m_exp_sinc_error;
  bit    mpu_err_accvio_complete  = !m_exp_mpu_err_accvio;

  if (enable_report) begin
    if (m_exp_cache_mem) begin
      cache_mem_complete = (m_cache_mem_pkt_q.size() == m_cache_mem_transaction_num) ? 1 : 0;

      report_str = {report_str, ":\n"};
      report_str = {report_str, $sformatf("expecting Cache MEM Transactions: exp[%0d], recieved[%0d] ", m_cache_mem_transaction_num, m_cache_mem_pkt_q.size())};

      if (!cache_mem_complete) begin
        `uvm_info("Uncompleted packet:", $sformatf("cache_mem_complete:%0d", cache_mem_complete), UVM_HIGH)

        if (m_exp_sinc_error && (m_sinc_error_q.size() == 1)) begin
          cache_mem_complete = 1;
          `uvm_info("Adjust Uncompleted packet:", $sformatf("cache_mem_complete:%0d", cache_mem_complete), UVM_HIGH)
        end
      end
    end

    if (m_exp_axi_sub_rd_resp) begin
      if (m_axi_sub_rd_resp_tran_q.size() == 1) begin
        axi_sub_rd_resp_complete = 1;
      end else if (m_axi_sub_rd_resp_tran_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more AXI SUB RD response than expected, exp[1], act [%0d]", m_axi_sub_rd_resp_tran_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting AXI SUB RD Response: exp[%0d], recieved[%0d] ", 1, m_axi_sub_rd_resp_tran_q.size())};
      end
    end

    if (m_exp_axi_sub_wr_resp) begin
      if (m_axi_sub_wr_resp_tran_q.size() == 1) begin
        axi_sub_wr_resp_complete = 1;
      end else if (m_axi_sub_wr_resp_tran_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more AXI SUB WR response than expected, exp[1], act [%0d]", m_axi_sub_wr_resp_tran_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting AXI SUB WR Response: exp[%0d], recieved[%0d] ", 1, m_axi_sub_wr_resp_tran_q.size())};
      end
    end

    if (m_exp_erase_done) begin
      if (m_erase_done_tran_q.size() == 1) begin
        erase_done_complete = 1;
      end else if (m_erase_done_tran_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more Erase Done than expected, exp[1], act [%0d]", m_erase_done_tran_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting Erase Done: exp[%0d], recieved[%0d] ", 1, m_erase_done_tran_q.size())};
      end
    end

    if (m_exp_sinc_done) begin
      if (m_sinc_done_q.size() == 1) begin
        sinc_done_complete = 1;
      end else if (m_sinc_done_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more SINC Done than expected, exp[1], act [%0d]", m_sinc_done_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting SINC Done: exp[%0d], recieved[%0d] ", 1, m_sinc_done_q.size())};
      end
    end

    if (m_exp_sinc_error) begin
      if (m_sinc_error_q.size() == 1) begin
        sinc_error_complete = 1;
      end else if (m_sinc_error_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more SINC Error than expected, exp[1], act [%0d]", m_sinc_error_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting SINC E-r-r-o-r: exp[%0d], recieved[%0d] ", 1, m_sinc_error_q.size())};
      end
    end

    if (m_exp_mpu_err_accvio) begin
      if (m_mpu_err_accvio_q.size() == 1) begin
        mpu_err_accvio_complete = 1;
      end else if (m_mpu_err_accvio_q.size() > 1) begin
        `uvm_error(report_str, $sformatf("received more SINC MPU violation than expected, exp[1], act [%0d]", m_mpu_err_accvio_q.size()))
      end else begin
        report_str = {report_str, ":\n"};
        report_str = {report_str, $sformatf("expecting SINC MPU violation: exp[%0d], recieved[%0d] ", 1, m_mpu_err_accvio_q.size())};
      end
    end

  end

  if (cache_mem_complete && axi_sub_rd_resp_complete && axi_sub_wr_resp_complete && erase_done_complete && sinc_done_complete && sinc_error_complete && mpu_err_accvio_complete) begin
    `uvm_info("IS_COMPLETED:", $sformatf("%0d, %0s", m_is_completed, report_str), UVM_HIGH)
  end else begin
    `uvm_info("IS_NOT_COMPLETED:", $sformatf("%0d, %0s", m_is_completed, report_str), UVM_HIGH)
    `uvm_info("IS_NOT_COMPLETED:", $sformatf("cache_mem_complete[%0d], axi_sub_rd_resp_complete[%0d], axi_sub_wr_resp_complete[%0d], erase_done_complete[%0d], sinc_done_complete[%0d], sinc_error_complete[%0d], mpu_err_accvio_complete[%0d]",
        cache_mem_complete, axi_sub_rd_resp_complete, axi_sub_wr_resp_complete, erase_done_complete, sinc_done_complete, sinc_error_complete, mpu_err_accvio_complete), UVM_HIGH)
  end

  return (m_is_completed);
endfunction : is_completed

// FUNCTION: self_check
// return the check result. 0 for error found, 1 for no error.
function bit sinc_sb_pkt_item::self_check();
  string report_str               = "sb_pkt_item_self_check";
  bit    result_pass              = 0;
  bit    is_match_sinc_done       = !m_exp_sinc_done;
  bit    is_match_mpu_err_accvio  = !m_exp_mpu_err_accvio;
  bit    is_match_cache_mem       = !m_exp_cache_mem;
  bit    is_match_axi_sub_rd_resp = !m_exp_axi_sub_rd_resp;
  bit    is_match_axi_sub_wr_resp = !m_exp_axi_sub_wr_resp;
  bit    is_match_cpu_rd_resp     = !m_exp_cpu_rd_resp;
  bit    is_match_axi_mgr_rd_req  = !m_exp_axi_mgr_rd_req;
  bit    is_match_axi_mgr_wr_req  = !m_exp_axi_mgr_wr_req;
  bit    is_match_erase_done      = !m_exp_erase_done;
  bit    is_match_mpu_rd          = !m_exp_mpu_rd;

  if (!m_is_completed) begin
    `uvm_error(report_str, $sformatf("[Signature] Self check can only be performed when packet is complete: req_dest[%0s]", m_req_dst.name()))
    return (0);
  end

  if (m_exp_sinc_done) begin
    is_match_sinc_done = (m_sinc_done_num == m_sinc_done_q.size())? 1:0;
  end

  if (m_exp_mpu_err_accvio) begin
    is_match_mpu_err_accvio = (1 == m_mpu_err_accvio_q.size())? 1:0;
  end

  if (m_exp_axi_mgr_rd_req) begin
    is_match_axi_mgr_rd_req = is_axi_mgr_rd_req_match_exp();
  end

  if (m_exp_axi_mgr_wr_req) begin
    is_match_axi_mgr_wr_req = is_axi_mgr_wr_req_match_exp();
  end

  if (m_exp_cache_mem) begin
    is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
  end

  // additional check if above not apply
  case (m_sinc_sb_pkt_entry)
    /* check on cache memory access after HW erase*/
    sinc_env_pkg::ENTRY_ERASE_AFTER_SOFT_RESET : begin
      // if (m_exp_cache_mem) begin
      //   is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
      // end
    end

    /* check on CACHE memory access after erase*/
    sinc_env_pkg::ENTRY_CREG_ERASE : begin
      // 1. CACHE MEM total item collected should be ?
      // 2. The address should start with 0, each increment by 1
      // 3. Write value should be random
      // if (m_exp_cache_mem) begin
      //   is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
      // end

      if (m_exp_erase_done) begin
        if (m_erase_done_tran_q.size() == 1) begin
          is_match_erase_done = 1;
        end else if (m_erase_done_tran_q.size() > 1) begin
          // report error instead of return result, like to stop stimulus at this point
          `uvm_error(report_str, $sformatf("received more Erase Done Event than expected, exp[1], act [%0d]", m_erase_done_tran_q.size()))
        end
      end
    end

    // Check AXI SUB Read
    // Common checks: AXI Address phase vs. Response phase;
    sinc_env_pkg::ENTRY_AXI_SUB_READ : begin
      bit is_sub_response_match;
      bit is_sub_data_match;

      if (m_exp_axi_sub_rd_resp) begin
        // check on response
        is_sub_response_match = axi_resp_check(m_exp_sub_slv_err, m_axi_sub_rd_resp_tran_q[0]);
      end

      // check on AXI data
      if (m_req_dst == SINC_REG) begin
        bit is_addr_p_match;
        bit is_resp_p_match;
        sinc_axi_data_t act_data[];
        sinc_reg_data_t act_reg_data;
        byte unsigned resp_data[]           = m_axi_sub_rd_resp_tran_q[0].data;
        uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
        sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

        // pack data
        act_data = new [resp_data.size() / 4];
        foreach (resp_data[i]) begin
          act_data[i / 4][(i%4)*8 +:8] = resp_data[i];
        end

        act_reg_data = sinc_reg_data_t'(act_data[0]);

        `uvm_info(report_str, $sformatf("Address Phase Reg data:['h%0h]", m_exp_reg_data_addr_p[0]), UVM_HIGH)
        `uvm_info(report_str, $sformatf("Response Phase Reg data:['h%0h]", m_exp_reg_data_resp_p[0]), UVM_HIGH)

        is_addr_p_match = axi_data_check(m_exp_reg_data_addr_p, m_axi_sub_rd_resp_tran_q[0].data);
        is_resp_p_match = axi_data_check(m_exp_reg_data_resp_p, m_axi_sub_rd_resp_tran_q[0].data);

        is_sub_data_match = is_addr_p_match | is_resp_p_match;

        // hard to predict case waiver on dmb write error
        if (m_dst_reg !== null) begin
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] ||
                cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE])) begin
            sinc_reg_data_t masked_cur_status;
            sinc_reg_data_t masked_rddata;
            sinc_reg_data_t mask = 32'hFFFF_FFFF_FFFF_FFFF;

            act_reg_data = sinc_reg_data_t'(act_data[0]);

            // if just due to the missmatch on auth_tag_write_error or dmb_encrypt_data_write_error, waive it
            mask[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]               = 0;
            mask[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 0;

            masked_cur_status = cur_status_reg_data & mask;
            masked_rddata     = act_reg_data & mask;
            if (masked_cur_status == masked_rddata) begin
              is_sub_data_match = 1;
            end

            `uvm_info(report_str, $sformatf("Check on status when observe dmb write e-r-r-o-r: cur_status_reg_data['h%0h], act_reg_data['h%0h], masked_cur_status['h%0h], masked_rddata['h%0h]", cur_status_reg_data, act_reg_data, masked_cur_status, masked_rddata), UVM_HIGH)
          end

          // waive concurrent transaction that when ARVALID assert at same time of STATUS INPROGRESS
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (!cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] &&
                act_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE])) begin
            time diff_time;
            int diff_cycles;

            if (m_req_tr_time >= m_top_configuration.m_sys_cfg.m_block_fetch_finished) begin
              diff_time = m_req_tr_time - m_top_configuration.m_sys_cfg.m_block_fetch_finished;
            end else begin
              diff_time = m_top_configuration.m_sys_cfg.m_block_fetch_finished - m_req_tr_time;
            end
            // this happen when ARVALID status reg read at same time of INPROGRESS deasserted at SYS Mirror
            // the status read will have inprogress set, but it is ok
            diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);

            if ((diff_cycles <= 30) || (m_top_configuration.m_sinc_vif.sinc_fetch_block_in_progress)) begin
              is_sub_data_match = 1;
            end
            `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], m_req_tr_time[%0t], block_fetch_finished[%0t], diff_cycles[%0d]", cur_status_reg_data, act_reg_data, m_req_tr_time, m_top_configuration.m_sys_cfg.m_block_fetch_finished, diff_cycles), UVM_HIGH)
          end

          // waive in progress missmatch when AES in progress
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              m_snapshot_aes_test_mode_en &&
              (!cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] &&
                act_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE])) begin
            sinc_reg_data_t masked_cur_status;
            sinc_reg_data_t masked_rddata;
            sinc_reg_data_t mask = 32'hFFFF_FFFF_FFFF_FFFF;

            act_reg_data = sinc_reg_data_t'(act_data[0]);
            mask[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;

            masked_cur_status = cur_status_reg_data & mask;
            masked_rddata     = act_reg_data & mask;
            if (masked_cur_status == masked_rddata) begin
              is_sub_data_match = 1;
            end

            `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], m_req_tr_time[%0t], m_snapshot_aes_test_mode_en[%0t]", cur_status_reg_data, act_reg_data, m_req_tr_time, m_snapshot_aes_test_mode_en), UVM_HIGH)
          end

          // waive concurrent transaction that when recent invalid FW command happen at near time of CPU RD that cause fetch block
          // this is due to AXI write request's response phase (which has write data information) arrive later than CPU RD
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (!cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] &&
                act_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]) &&
              (cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] &&
                !act_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]) &&
              m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_fail) begin
            time diff_time;
            int diff_cycles;

            if (m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time >= m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time) begin
              diff_time = m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time - m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time;
            end else begin
              diff_time = m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time - m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time;
            end
            // this happen when ARVALID status reg read at same time of INPROGRESS deasserted at SYS Mirror
            // the status read will have inprogress set, but it is ok
            diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
            `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], most_recent_fw_cmd_done_time[%0t], most_recent_block_fetch_start_time[%0t], diff_cycles[%0d], most_recent_fw_cmd_fail[%0d]", cur_status_reg_data, act_reg_data, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time, m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time, diff_cycles, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_fail), UVM_HIGH)

            if (diff_cycles <= 10) begin
              is_sub_data_match = 1;
            end

          end

          // waive extreme condition when previous FW command write response phase for AXI WRITE is too late, so CPU read's fetch block already started
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (!cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] &&
                act_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]) &&
              (m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time > m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time)) begin
            time diff_time;
            int diff_cycles;

            // make sure this read is during block fetch (not done yet)
            if (m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time > m_top_configuration.m_sys_cfg.m_block_fetch_finished) begin
              is_sub_data_match = 1;
              `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], m_req_tr_time[%0t], most_recent_fw_cmd_done_time[%0t], most_recent_block_fetch_start_time[%0t], block_fetch_finished[%0t]",
                  cur_status_reg_data, act_reg_data, m_req_tr_time, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time, m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time, m_top_configuration.m_sys_cfg.m_block_fetch_finished), UVM_HIGH)

           
            end
          end

          // waive extreme condition when CPU RD happen in betweeen BLOCK FETCH
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] &&
                !act_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE])
              ) begin
            time diff_time;
            int diff_cycles;

            // make sure this read is during block fetch (not done yet)
            if (m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time < $realtime) begin
              diff_time = $realtime - m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time;
              diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
              if (diff_cycles < 10) begin
                is_sub_data_match = 1;
                `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], m_req_tr_time[%0t], most_recent_fw_cmd_done_time[%0t], most_recent_block_fetch_start_time[%0t], block_fetch_finished[%0t]",
                                                cur_status_reg_data, act_reg_data, m_req_tr_time, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time, m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time, m_top_configuration.m_sys_cfg.m_block_fetch_finished), UVM_HIGH)
              end
            end
          end


          // waive concurrenttransaction when ARVALID assert at same time of sinc_error, for state transitioning
          // the state transition happend after set error status
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              (act_reg_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] ||
                act_reg_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE] ||
                act_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] ||
                act_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]) &&
              (act_reg_data[`SINC_REGS_STATUS_STATE_RANGE] !== sinc_parameters_pkg::CACHE_FAIL_STATE)
            ) begin
            time diff_time;
            int diff_cycles;

            if (m_req_tr_time >= m_top_configuration.m_sys_cfg.m_recent_sinc_error_time) begin
              diff_time = m_req_tr_time - m_top_configuration.m_sys_cfg.m_recent_sinc_error_time;
            end else begin
              diff_time = m_top_configuration.m_sys_cfg.m_recent_sinc_error_time - m_req_tr_time;
            end
            // this happen when ARVALID status reg read at same time of INPROGRESS deasserted at SYS Mirror
            // the status read will have inprogress set, but it is ok
            diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);

            if (diff_cycles <= 5) begin
              is_sub_data_match = 1;
            end
            `uvm_info(report_str, $sformatf("Check on status when missmatch: cur_status_reg_data['h%0h], act_reg_data['h%0h], m_req_tr_time[%0t], recent_sinc_error_time[%0t], diff_cycles[%0d]", cur_status_reg_data, act_reg_data, m_req_tr_time, m_top_configuration.m_sys_cfg.m_recent_sinc_error_time, diff_cycles), UVM_HIGH)
          end

          `uvm_info(report_str, $sformatf("Check on status when missmatch: most_recent_fw_cmd[%0s], most_recent_fw_cmd_done_time[%0t], most_recent_block_fetch_start_time[%0t], recent_sinc_error_time[%0t], block_fetch[%0t]",
              m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time, m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time, m_top_configuration.m_sys_cfg.m_recent_sinc_error_time, m_top_configuration.m_sys_cfg.m_block_fetch_finished), UVM_HIGH)

        end // if (m_dst_reg !== null)

        // waive for case when FW command write response is too slow, this only apply to short FW commands like DISABLE_INIT and DISABLE_RESET
        if (!is_sub_data_match &&
            ((m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_RESET) ||
              (m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_REINIT) ||
              (m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd == sinc_parameters_pkg::SINC_FW_UNMAPPED))) begin
          // check if the FW command finished near the fetch block start
          time diff_time;
          int diff_cycles;
          bit timing_match;
          bit data_match;
          sinc_reg_data_t masked_cur_status;
          sinc_reg_data_t masked_rddata;
          sinc_reg_data_t mask = 32'hFFFF_FFFF_FFFF_FFFF;

          act_reg_data = sinc_reg_data_t'(act_data[0]);

          // if just due to the missmatch on INPROGRESS and CMDSUCCESS
          mask[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
          mask[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 0;

          masked_cur_status = cur_status_reg_data & mask;
          masked_rddata     = act_reg_data & mask;
          if (masked_cur_status == masked_rddata) begin
            data_match = 1;
          end

          `uvm_info(report_str, $sformatf("Check on status when observe : cur_status_reg_data['h%0h], act_reg_data['h%0h], masked_cur_status['h%0h], masked_rddata['h%0h]", cur_status_reg_data, act_reg_data, masked_cur_status, masked_rddata), UVM_HIGH)

          if (m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time >= m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time) begin
            diff_time = m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time - m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time;
          end else begin
            diff_time = m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time - m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time;
          end

          diff_cycles = (diff_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
          if (diff_cycles <= 10) begin
            timing_match = 1;
          end
          `uvm_info(report_str, $sformatf("Check on status when missmatch: most_recent_fw_cmd[%0s], most_recent_fw_cmd_done_time[%0t], most_recent_block_fetch_start_time[%0t], diff_cycles[%0d]",
              m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd, m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time, m_top_configuration.m_sys_cfg.m_most_recent_block_fetch_start_time, diff_cycles), UVM_HIGH)

          if (data_match && timing_match) begin
            is_sub_data_match = 1;
          end

        end // if (!is_sub_data_match &&...

        // waive when block fetch fail with AXI MGR read error with unmapped request
        // The prediction on SB can be not precise
        if (!is_sub_data_match &&
            ((m_top_configuration.m_sys_cfg.m_unmapped_axi_mgr_rd_when_block_fetch == 1) &&
             (cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] && act_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]) &&
             (cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] || cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_RANGE] || cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_RANGE] || cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE])
              )) begin
          // check if the FW command finished near the fetch block start
          time diff_time;
          int diff_cycles;
          bit timing_match;
          bit data_match;
          sinc_reg_data_t masked_cur_status;
          sinc_reg_data_t masked_rddata;
          sinc_reg_data_t mask = 32'hFFFF_FFFF_FFFF_FFFF;

          act_reg_data = sinc_reg_data_t'(act_data[0]);

          mask[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] = 0;
          mask[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_RANGE] = 0;
          mask[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_RANGE]    = 0;
          mask[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]    = 0;

          masked_cur_status = cur_status_reg_data & mask;
          masked_rddata     = act_reg_data & mask;
          if (masked_cur_status == masked_rddata) begin
            data_match = 1;
          end

          // make sure at least one of the error is set at act_reg_data
          if ((act_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] || act_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_RANGE] || act_reg_data[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_RANGE] || act_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE])) begin
            //
          end else begin
            data_match = 0;
          end


          `uvm_info(report_str, $sformatf("Check on status when observe : cur_status_reg_data['h%0h], act_reg_data['h%0h], masked_cur_status['h%0h], masked_rddata['h%0h]", cur_status_reg_data, act_reg_data, masked_cur_status, masked_rddata), UVM_HIGH)


          if (data_match) begin
            is_sub_data_match = 1;
            // update mirror
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, act_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, act_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end

        end

        // special care on AES mode
        // below is the case that when AES command finish, the first status register read data mismatch as reg mirror has not predicted on status for AES command
        if (m_dst_reg !== null) begin
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&
              !is_sub_data_match &&
              m_top_configuration.m_sys_cfg.m_aes_test_mode_done) begin
            sinc_axi_data_t exp_data = m_exp_reg_data_addr_p[0];
            sinc_axi_data_t act_data;
            sinc_reg_data_t my_reg_data[];
            sinc_reg_data_t processed_data;
            my_reg_data = new [1];

            for (int i=0; i < (m_axi_sub_rd_resp_tran_q[0].data.size() / 4); i++) begin
              my_reg_data[i] = {m_axi_sub_rd_resp_tran_q[0].data[3 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[2 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[1 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[0 + (i * 4)]};
            end

            act_data = my_reg_data[0];

            `uvm_info(report_str, $sformatf("act status['h%0h], exp status['h%0h] ", act_data, exp_data), UVM_HIGH)
            // xor the act and exp data
            processed_data = exp_data ^ act_data;
            `uvm_info(report_str, $sformatf("xor result ['h%0h] ", processed_data), UVM_HIGH)

            // if cmd success has difference, flip
            if (processed_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]) begin
              processed_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 0;
            end

            // if cmd inprogress has difference, flip
            if (processed_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]) begin
              processed_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            end

            // if cmd inprogress has difference, flip
            if (processed_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]) begin
              processed_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 0;
            end

            if (!(|processed_data)) begin
              is_sub_data_match = 1;
            end

            m_top_configuration.m_sys_cfg.m_aes_test_mode_done = 0;
          end // if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME) &&...

          if (m_dst_reg.get_rights() == "WO") begin
            sinc_axi_data_t temp_reg_data_q[];
            temp_reg_data_q    = new [1];
            temp_reg_data_q[0] = 0;
            is_sub_data_match  = axi_data_check(temp_reg_data_q, m_axi_sub_rd_resp_tran_q[0].data);
          end
        end // if (m_dst_reg !== null)

        if (m_is_status_read) begin
          int consumed_cycles = (m_req_done_time - m_req_tr_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
          `uvm_info(report_str, $sformatf("Status read consumed [%0d] cycles ",
              consumed_cycles), UVM_HIGH)
          if (consumed_cycles > 5000) begin
            print_packet();
            `uvm_error(report_str, $sformatf("[Signature] Status Read Consumed [%0d] cycles, please check with wave to make sure it match with performance expectation", consumed_cycles))
          end
        end
      end else begin // if (m_req_dst == SINC_REG)
        // read data
        sinc_axi_data_t temp_reg_data_q[];
        temp_reg_data_q    = new [1];
        temp_reg_data_q[0] = 0;
        is_sub_data_match  = axi_data_check(temp_reg_data_q, m_axi_sub_rd_resp_tran_q[0].data);
        // `uvm_error(report_str, $sformatf("Not implemented self check on request to [%0s]", m_req_dst.name()))
      end

      // if error response expected, the read data should be 0
      if (m_exp_sub_slv_err) begin
        sinc_axi_data_t temp_reg_data_q[];
        temp_reg_data_q    = new [1];
        temp_reg_data_q[0] = 0;
        is_sub_data_match  = 1;
        foreach (m_axi_sub_rd_resp_tran_q[0].data[i]) begin
          if (m_axi_sub_rd_resp_tran_q[0].data[i] !== 0) begin
            is_sub_data_match = 0;
          end
        end
        `uvm_info(report_str, $sformatf("is_sub_data_match[%0d] updated for slv_err", is_sub_data_match), UVM_HIGH)
      end

      is_match_axi_sub_rd_resp = is_sub_response_match && is_sub_data_match;
      `uvm_info(report_str, $sformatf("is_match_axi_sub_rd_resp[%0d], is_sub_response_match[%0d], is_sub_data_match[%0d] ", is_match_axi_sub_rd_resp, is_sub_response_match, is_sub_data_match), UVM_HIGH)

      if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en ||
          (!m_top_configuration.m_sys_cfg.m_aes_test_mode_en && is_aes_test_mode_en_recently_toggled() &&
            (m_dst_reg !== null))) begin
        if ((m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_STATUS_REG_NAME) ||
            (m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_CTRL_REG_NAME) ||
            (m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_DATA_OUT_0_REG_NAME) ||
            (m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_DATA_OUT_1_REG_NAME) ||
            (m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_DATA_OUT_2_REG_NAME) ||
            (m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_DATA_OUT_3_REG_NAME)
          ) begin
          // set predict value of register
          sinc_reg_data_t my_reg_data[];
          my_reg_data = new [1];

          for (int i=0; i < (m_axi_sub_rd_resp_tran_q[0].data.size() / 4); i++) begin
            my_reg_data[i] = {m_axi_sub_rd_resp_tran_q[0].data[3 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[2 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[1 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[0 + (i * 4)]};
          end

          is_match_axi_sub_rd_resp = 1;

          // Note: AES_TEST_CTRL will not be cleared by HW
          //       AES_TEST_DATA_OUT* will be cleared by HW when data_out_ack is set.
          if ((m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_CTRL_REG_NAME)) begin
            if (!m_exp_sub_slv_err) begin
              // set mirror with read data
              if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(m_dst_reg.get_name(), my_reg_data[0])) begin
                `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", m_dst_reg.get_name(), my_reg_data[0]), UVM_HIGH)
              end else begin
                `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", m_dst_reg.get_name()))
              end
            end
          end
          `uvm_info(report_str, $sformatf("scoreboard offload AES_TEST_STATUS_REG check to stimulus sequence: is_match_axi_sub_rd_resp[%0d], is_sub_response_match[%0d], is_sub_data_match[%0d] ", is_match_axi_sub_rd_resp, is_sub_response_match, is_sub_data_match), UVM_HIGH)
        end
      end
    end

    // Check AXI SUB Write
    // Common checks: AXI Address phase vs. Response phase;
    sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
      bit is_sub_response_match;
      bit is_sub_data_match;

      if (m_exp_axi_sub_wr_resp) begin
        // check on response
        is_sub_response_match = axi_resp_check(m_exp_sub_slv_err, m_axi_sub_wr_resp_tran_q[0]);
      end

      // check on AXI data
      if (m_req_dst == SINC_REG) begin
        bit is_addr_p_match;
        bit is_resp_p_match;
        sinc_reg_data_t my_reg_data[];
        int consumed_cycles;

        if (m_exp_cache_mem) begin
          is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
        end

        if (!m_is_fw_cmd) begin
          is_sub_data_match = 1;

          // UVM REG Read with Backdoor
          `uvm_info(report_str, $sformatf("Check on register write data [%0p] ",
              my_reg_data), UVM_HIGH)
          if (!m_exp_sub_slv_err) begin
            fork : check_reg_data
              begin
                automatic uvm_reg_data_t exp_reg_data;
                exp_reg_data = m_dst_reg.get_mirrored_value();
                reg_data_check(.exp_reg_data(exp_reg_data), .reg_handler(m_addr_dec.get_reg_ral_hit_by_name(m_dst_reg.get_name())), .req_start_time(m_req_tr_time), .exp_pass(1));
              end
            join_none
          end

          consumed_cycles = (m_req_done_time - m_req_tr_time) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
          `uvm_info(report_str, $sformatf("Register write consumed [%0d] cycles ",
              consumed_cycles), UVM_HIGH)
          if (consumed_cycles > 5000) begin
            print_packet();
            `uvm_error(report_str, $sformatf("[Signature] Register Write Consumed [%0d] cycles, please check with wave to make sure it match with performance expectation", consumed_cycles))
          end
        end else begin // if (!m_is_fw_cmd) begin
          is_sub_data_match = self_check_fw_command();
        end
      end else if (m_req_dst == SINC_NULL) begin
        // no furhter check need to be done
        is_sub_data_match = 1;
      end else begin
        `uvm_error(report_str, $sformatf("Not implemented self check on request to [%0s]", m_req_dst.name()))
      end

      is_match_axi_sub_wr_resp = is_sub_response_match && is_sub_data_match;

      `uvm_info(report_str, $sformatf("is_match_axi_sub_wr_resp[%0d], is_sub_esponse_match[%0d], is_sub_data_match[%0d] ",
          is_match_axi_sub_wr_resp, is_sub_response_match, is_sub_data_match), UVM_HIGH)
    end // case: sinc_env_pkg::ENTRY_AXI_SUB_WRITE

    /* check on CPU READ */
    sinc_env_pkg::ENTRY_CPU_READ : begin
      // if (m_exp_cache_mem) begin
      //   is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
      // end

      if (m_exp_cpu_rd_resp) begin
        is_match_cpu_rd_resp = is_cpu_rd_resp_match_exp() && is_cpu_rd_data_match_exp();
      end
    end

    /* check on CPU WRITE */
    sinc_env_pkg::ENTRY_CPU_WRITE : begin
      // if (m_exp_cache_mem) begin
      //   is_match_cache_mem = is_cache_mem_match_exp(.num(m_cache_mem_transaction_num));
      // end
    end

    /* check on MPU ATTR READ */
    sinc_env_pkg::ENTRY_MPU_ATTR_READ : begin
      is_match_mpu_rd = is_mpu_rd_match_exp();
    end

    /* check on MPU STATUS READ */
    sinc_env_pkg::ENTRY_MPU_STATUS_READ : begin
      is_match_mpu_rd = is_mpu_rd_match_exp();

      /*
      if (!is_match_mpu_rd) begin
        // when non block CPU enabled, the MPU write and CPU access can happen at same time, DV can not predict the result
        if (m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) begin
          is_match_mpu_rd = 1;
        end
      end
       */
    end

    default: `uvm_error(report_str, $sformatf("received unexpected scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
  endcase // case (m_sinc_sb_pkt_entry)

  result_pass = is_match_sinc_done && is_match_mpu_err_accvio && is_match_cache_mem && is_match_axi_sub_rd_resp && is_match_axi_sub_wr_resp && is_match_cpu_rd_resp &&
    is_match_axi_mgr_rd_req && is_match_erase_done && is_match_mpu_rd;

  if (!result_pass) begin
    print_packet();
    `uvm_error(report_str, $sformatf("self check fail on scoreboard entry: [%0s], is_match_sinc_done[%0d], is_match_mpu_err_accvio[%0d], is_match_cache_mem[%0d], is_match_axi_sub_rd_resp[%0d], is_match_axi_sub_wr_resp[%0d], is_match_cpu_rd_resp[%0d], is_match_axi_mgr_rd_req[%0d], is_match_axi_mgr_wr_req[%0d],is_match_erase_done[%0d], is_match_mpu_rd[%0d], please check the reported signature",
        m_sinc_sb_pkt_entry.name(),
        is_match_sinc_done,
        is_match_mpu_err_accvio,
        is_match_cache_mem,
        is_match_axi_sub_rd_resp,
        is_match_axi_sub_wr_resp,
        is_match_cpu_rd_resp,
        is_match_axi_mgr_rd_req,
        is_match_axi_mgr_wr_req,
        is_match_erase_done,
        is_match_mpu_rd))
  end

  if (result_pass) begin
    // perform set mirror update for non fw command
    void'(set_sys_mirror());
  end

  return (result_pass);

endfunction : self_check

// FUNCTION: set_sys_mirror
// call when self_check done or partially done(with success), perform system mirrored data structure update
function bit sinc_sb_pkt_item::set_sys_mirror();
  string report_str = "sb_pkt_item_set_sys_mirror";

  `uvm_info(report_str, $sformatf("Started on [%0s]", m_sinc_sb_pkt_entry), UVM_HIGH)

  if (m_is_fw_cmd && !m_is_fw_tlb_updated) begin
    void'(update_tlb_when_op_finish());
  end

  case (m_sinc_sb_pkt_entry)
    sinc_env_pkg::ENTRY_ERASE_AFTER_SOFT_RESET : begin
    end

    sinc_env_pkg::ENTRY_CREG_ERASE : begin
      if (m_is_erase_accepted) begin
        // update peripherals
        // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
        // reset cache coherency, will also do preload of current memory
        m_top_configuration.m_csd.reset_csd();

        // do preload again to grab random value in physical cache mem
        m_top_configuration.m_csd.init_csd(.en_bkdoor_load(1));
      end
    end

    sinc_env_pkg::ENTRY_CPU_READ : begin
      if (m_is_update_csd) begin
        if(!m_top_configuration.m_csd.update_cache_line(csd_address_t'(m_cpu_addr))) begin
          `uvm_error(report_str, $sformatf("Fail to update cache line with m_CPU_ADDR['h%0h]", m_cpu_addr))
        end
      end

      if (m_is_mpu_status_update_expected) begin
        // if (!m_is_mpu_allowed) begin
        // if (!m_is_mpu_allowed && (m_r_accvio_rd || m_r_accvio_wr || m_r_accvio_ex)) begin
        if (!m_is_mpu_allowed) begin
          m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
          `uvm_info(report_str, $sformatf("Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
              m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
          void'(m_mpu_cfg.set_mpu_status(m_cpu_req_p_tran.m_addr, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex, 0));
        end else if (m_is_mpu_status_update_expected && (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE)) begin
          bit xe_reg                  = !m_cpu_req_p_tran.m_loadstore;
          m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];

          m_r_accvio_wr = 0;
          if (xe_reg) begin
            m_r_accvio_ex = 1;
            m_r_accvio_rd = 0;
          end else begin
            m_r_accvio_ex = 0;
            m_r_accvio_rd = 1;
          end
          `uvm_info(report_str, $sformatf("Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
                                          m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
          void'(m_mpu_cfg.set_mpu_status(m_cpu_req_p_tran.m_addr, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex, 0));
        end
      end // if (m_is_mpu_status_update_expected) begin

      if (m_is_auth_tag_mismatch_error) begin
        // move to Failure state
        `uvm_info(report_str, $sformatf("Set cache fail due to m_is_auth_tag_mismatch_error[%0d]", m_is_auth_tag_mismatch_error), UVM_HIGH)
        set_cache_fail();
      end

      if (m_is_dmb_read_error) begin
        // move to Failure state
        `uvm_info(report_str, $sformatf("Set cache fail due to m_is_dmb_read_error[%0d]", m_is_dmb_read_error), UVM_HIGH)
        set_cache_fail();
      end

      // check if erase interrupt the block fetch during write to CIRAM
      if (m_erase_accepted_before_cache_mem_transaction_done) begin
        // it is hard for scoreboard to predict on this case, so use interface
        if (m_top_configuration.m_sinc_vif.sinc_err_erase_during_w_cache_block) begin
          set_cache_fail();
         end
      end

      // remove in progress
      if ((m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
          m_exp_block_fetch) begin
        uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
        sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

        cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
        end
      end

    end // case: sinc_env_pkg::ENTRY_CPU_READ

    sinc_env_pkg::ENTRY_CPU_WRITE : begin
      if (m_is_write_performed) begin
        void'(m_top_configuration.m_sys_cfg.m_csd.set_cpu_word_data(csd_address_t'(m_cpu_req_p_tran.m_addr), m_cpu_req_p_tran.m_wdata, m_cpu_req_p_tran.m_we));
        `uvm_info(report_str, $sformatf("CPU Write update Cache memory, m_cpu_addr[%0d], wdata[%0d] ",
                                        m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_wdata), UVM_HIGH)
      end

      if (m_is_mpu_status_update_expected && !m_is_mpu_allowed) begin
        m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
        `uvm_info(report_str, $sformatf("Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
                                        m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
        void'(m_mpu_cfg.set_mpu_status(m_cpu_req_p_tran.m_addr, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex, 0));
      end else if (m_is_mpu_status_update_expected && (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE) && (m_cpu_req_p_tran.m_we !== 0)) begin
        m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
        m_r_accvio_rd = 0;
        m_r_accvio_wr = 1;
        m_r_accvio_ex = 0;
        `uvm_info(report_str, $sformatf("Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
                                        m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
        void'(m_mpu_cfg.set_mpu_status(m_cpu_req_p_tran.m_addr, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex, 0));
      end else begin
        `uvm_info(report_str, $sformatf("Skip Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
                                        m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
      end

      // if (m_is_mpu_status_update_expected) begin
      //   if (!m_is_mpu_allowed) begin
      //     //if ((m_cur_cache_state !== sinc_parameters_pkg::CACHE_FAIL_STATE) && (m_cpu_req_p_tran.m_we !== 0)))
      //     m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
      //     `uvm_info(report_str, $sformatf("Set MPU Status reg with m_cpu_req_p_tran.m_addr['h%0h](full address['h%0h]), m_r_accvio_rd[%0d], m_r_accvio_wr[%0d], m_r_accvio_ex[%0d] ",
      //                                           m_cpu_req_p_tran.m_addr, m_cpu_req_p_tran.m_addr << 2, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex), UVM_HIGH)
      //     void'(m_mpu_cfg.set_mpu_status(m_cpu_req_p_tran.m_addr, m_r_accvio_rd, m_r_accvio_wr, m_r_accvio_ex, 0));
      //   end
      // end // if (m_is_mpu_status_update_expected) begin

    end

    sinc_env_pkg::ENTRY_AXI_SUB_READ : begin
      if ((m_req_dst == SINC_REG) && (m_dst_reg !== null) ) begin
        if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME)) begin
          uvm_reg status_reg = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
          // sinc_reg_data_t orig_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
          sinc_reg_data_t cur_status_reg_data;
          sinc_reg_data_t response_status_reg_data = m_exp_reg_data_addr_p[0];
          uvm_reg_field fields[$];
          uvm_reg_data_t update_value;
          bit observe_rc = 0;
          sinc_reg_data_t act_reg_data[];
          sinc_reg_data_t act_status_reg_data;
          act_reg_data = new [1];

          for (int i=0; i < (m_axi_sub_rd_resp_tran_q[0].data.size() / 4); i++) begin
            act_reg_data[i] = {m_axi_sub_rd_resp_tran_q[0].data[3 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[2 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[1 + (i * 4)], m_axi_sub_rd_resp_tran_q[0].data[0 + (i * 4)]};
          end

          `uvm_info(report_str, $sformatf("Set RC register fields for register [%0s], Responsed ['h%0h] ",
              sinc_parameters_pkg::STATUS_REG_NAME, response_status_reg_data), UVM_HIGH)

          `uvm_info(report_str, $sformatf("Set RC register fields for register [%0s], Act ['h%0h] ",
              sinc_parameters_pkg::STATUS_REG_NAME, act_reg_data[0]), UVM_HIGH)

          act_status_reg_data = act_reg_data[0];

          // Note: Prediction on W_ENCR_DATA and W_AUTH_TAG with DECERROR would lead to uncertainty on the expected status update
          //       thus, clear predicted mirror on both if one of them is set
          if (act_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] || act_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]) begin
            act_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 1;
            act_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 1;
          end

          // clear RC register fields
          status_reg.get_fields(fields);
          foreach(fields[i]) begin
            if (fields[i].get_access() == "RC") begin
              // if (response_status_reg_data[fields[i].get_lsb_pos()]) begin // only reset if responsed data is set
              if (act_status_reg_data[fields[i].get_lsb_pos()]) begin // only reset if responsed data is set
                update_value = 0;
                observe_rc   = 1;
                void'(fields[i].predict(update_value));
              end


            end
          end
          cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
          // if (response_status_reg_data !== cur_status_reg_data) begin
          if (observe_rc) begin
            `uvm_info(report_str, $sformatf("Set RC register (updated) fields for register [%0s], Current ['h%0h] ",
                sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
          end
        end // if ((m_dst_reg.get_name() == sinc_parameters_pkg::STATUS_REG_NAME))

        if ((m_dst_reg.get_name() == sinc_parameters_pkg::ENCR_BLOCK_STATUS_REG_NAME) &&
            !m_exp_sub_slv_err) begin
          uvm_reg dst_reg                     = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::ENCR_BLOCK_STATUS_REG_NAME);
          sinc_reg_data_t cur_dst_reg_data    = sinc_reg_data_t'(dst_reg.get_mirrored_value());
          cur_dst_reg_data = 0;

          if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::ENCR_BLOCK_STATUS_REG_NAME, cur_dst_reg_data)) begin
            `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h], RC register", sinc_parameters_pkg::ENCR_BLOCK_STATUS, cur_dst_reg_data), UVM_HIGH)
          end else begin
            `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::ENCR_BLOCK_STATUS))
          end

        end
      end // if (m_req_dst == SINC_REG) begin
    end // sinc_env_pkg::ENTRY_AXI_SUB_READ : begin

    sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
      if (m_req_dst == SINC_REG) begin
        uvm_reg cmd_reg                     = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME);
        uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
        sinc_reg_data_t cur_cmd_reg_data    = sinc_reg_data_t'(cmd_reg.get_mirrored_value());
        sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

        // checkout write to clear registers
        // check on perf_cnrl
        if (m_dst_reg !== null) begin
          if ((m_dst_reg.get_name() == "perf_cntr_ctrl")) begin
            if (m_write_reg_data[`SINC_REGS_PERF_CNTR_CTRL_HIT_CNTR_CLR_LSB]) begin
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("hit_cntr_lower", 0));
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("hit_cntr_upper", 0));
            end
            if (m_write_reg_data[`SINC_REGS_PERF_CNTR_CTRL_MISS_CNTR_CLR_LSB]) begin
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("miss_cntr_lower", 0));
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("miss_cntr_upper", 0));
            end
            if (m_write_reg_data[`SINC_REGS_PERF_CNTR_CTRL_LAT_CNTR_CLR_LSB]) begin
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("lat_cntr_lower", 0));
              void'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("lat_cntr_upper", 0));
            end
            if (m_has_cpu_rd_exp_block_fetch) begin
              m_top_configuration.m_sys_cfg.m_perf_cntr_toggled_during_cpu_rd = 1;
            end
          end
        end

        // clear CMD register when the FW command is complete/failed
        // if (m_is_fw_cmd) begin
        //   cur_cmd_reg_data[`SINC_REGS_CMD_ENCR_BLOCK_RANGE] = 0;
        //   cur_cmd_reg_data[`SINC_REGS_CMD_SINC_REINIT_RANGE] = 0;
        //   cur_cmd_reg_data[`SINC_REGS_CMD_SINC_RESET_RANGE] = 0;
        //   cur_cmd_reg_data[`SINC_REGS_CMD_SET_CACHE_ACTIVE_STATE_RANGE] = 0;
        //   cur_cmd_reg_data[`SINC_REGS_CMD_SET_INIT_STATE_RANGE] = 0;

        //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data)) begin
        //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data), UVM_HIGH)
        //   end else begin
        //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::CMD_REG_NAME))
        //   end

        //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;
        //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
        //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
        //   end else begin
        //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
        //   end
        // end

        case (m_fw_cmd)
          sinc_parameters_pkg::SINC_SET_INIT_STATE : begin
            // if (!m_is_fw_op_fail && !m_top_configuration.m_sys_cfg.m_is_rng_fetched) begin
            if (!m_is_rng_fetch_error && !m_top_configuration.m_sys_cfg.m_is_rng_fetched &&
                m_act_rng_data_axi_mgr_rd_resp_tran_q.size()) begin
              m_top_configuration.m_sys_cfg.m_is_rng_fetched = 1;
            end

            // below moved to update_tlb_when_op_finish
            // if (m_is_fw_op_fail) begin
            //   if (m_is_rng_fetch_error || m_is_ksu_rd_error || m_is_sharedram_rd_error || m_is_dmb_write_error) begin
            //     if (m_is_rng_fetch_error) begin
            //       cur_status_reg_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 'b1;
            //     end

            //     if (m_is_ksu_rd_error) begin
            //       cur_status_reg_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE] = 'b1;
            //     end

            //     if (m_is_sharedram_rd_error) begin
            //       cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] = 'b1;
            //     end

            //     if (m_is_dmb_write_error) begin
            //       if (m_is_dmb_auth_tag_write_error) begin
            //         cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
            //       end else if (m_is_dmb_encrypt_data_write_error) begin
            //         cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
            //       end else begin
            //         // program num_of_blocks could lead to unpredicted decode error, SB has hard time figuring out which exact error will be, so set both but waive one when status read
            //         cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
            //         cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
            //       end
            //     end

            //     // move to Failure state
            //     // set update on cache state
            //     cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
            //     `uvm_info(report_str, $sformatf("Set cache fail due to m_is_rng_fetch_error[%0d]", m_is_rng_fetch_error), UVM_HIGH)
            //     set_cache_fail();
            //   end

            //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 'b1;
            //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;

            //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
            //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            //   end else begin
            //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            //   end
            // end // if (m_is_fw_op_fail)
          end // case: sinc_parameters_pkg::SINC_SET_INIT_STATE

          sinc_parameters_pkg::SINC_AES_TEST_DISABLE : begin
            if (m_exp_sinc_done && (m_sinc_done_num == 1)) begin
              // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
              m_top_configuration.m_sys_cfg.m_aes_test_mode_en      = 0;
              m_top_configuration.m_sys_cfg.m_aes_test_mode_done    = 1;
              m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled = $realtime;

              // update status
              cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
              cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
              if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
                `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
              end else begin
                `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
              end
            end

            // update AES register values with backdoor
            fork : update_backdoor
              begin
                update_reg_mirror_w_backdoor_value(sinc_parameters_pkg::AES_TEST_CTRL_REG_NAME);
              end
            join_none
          end
          sinc_parameters_pkg::SINC_SINC_RESET : begin
            // init cache directory to avoid data inconsistancy:
            // due to error injection with authentication fail on CPU read, the cache mem will be corrupted with unpredictable result, thus DV has to do a preload again when fw reset command issued
            if (m_cur_cache_state == sinc_parameters_pkg::CACHE_FAIL_STATE) begin
              // do preload again to grab random value in physical cache mem
              m_top_configuration.m_csd.init_csd(.en_bkdoor_load(1));
            end

            if (!m_is_fw_op_fail) begin
              uvm_reg_data_t write_to_clear_wdata = 32'h8000_0000;
              m_mpu_cfg.clear_mpu_status(write_to_clear_wdata);
            end
          end
          sinc_parameters_pkg::SINC_DISABLE_RESET : begin

          end
          sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
            // below moved to update_tlb_when_op_finish
            // if (m_is_fw_op_fail) begin
            //   if (m_is_dmb_write_error) begin
            //     if (m_is_dmb_auth_tag_write_error) begin
            //       cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
            //     end else if (m_is_dmb_encrypt_data_write_error) begin
            //       cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
            //     end else begin
            //       // program num_of_blocks could lead to unpredicted decode error, SB has hard time figuring out which exact error will be, so set both but waive one when status read
            //       cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
            //       cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
            //     end
            //   end

            //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE] = 'b1;
            //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;

            //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
            //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            //   end else begin
            //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            //   end
            // end // if (m_is_fw_op_fail) begin
          end // sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
          default: begin
            //do nothing
          end
        endcase // case (m_fw_cmd)

      end // if (m_req_dst == SINC_REG ) begin

    end // case: sinc_env_pkg::ENTRY_AXI_SUB_WRITE

    default : begin
        // do nothing
    end
  endcase // case (m_sinc_sb_pkt_entry)
endfunction : set_sys_mirror

function bit sinc_sb_pkt_item::axi_resp_check(bit exp_slv_err, pal_axi_xaction t);
  string report_str   = "AXI_RESP_CHECK";
  bit    slv_err_seen;

  `uvm_info(report_str, $sformatf("exp_slv_err[%0d]", exp_slv_err), UVM_HIGH)
  if ((t.cmd == PAL_READ) || (t.cmd == PAL_EXRD) || (t.cmd == PAL_LOCKRD)) begin
    foreach (t.rdresp[i]) begin
      `uvm_info(report_str, $sformatf("t.rdresp[%0d][%0s]", i, t.rdresp[i].name()), UVM_HIGH)
      if ((t.rdresp[i] !== PAL_RESP_OKAY) &&
          (t.rdresp[i] !== PAL_RESP_EXOKAY)) begin
        slv_err_seen = 1;
      end
    end
  end else if ((t.cmd == PAL_WRITE) || (t.cmd == PAL_EXWR) || (t.cmd == PAL_LOCKWR)) begin
    `uvm_info(report_str, $sformatf("t.t.wrresp[%0s]", t.wrresp.name()), UVM_HIGH)
    // if (t.wrresp == PAL_RESP_SLVERR) begin
    if ((t.wrresp !== PAL_RESP_OKAY) &&
        (t.wrresp !== PAL_RESP_EXOKAY)) begin
      slv_err_seen = 1;
    end
  end

  return ((exp_slv_err && slv_err_seen) || (!exp_slv_err && !slv_err_seen));

endfunction : axi_resp_check

function bit sinc_sb_pkt_item::axi_data_check(const ref sinc_axi_data_t exp_data[], const ref byte unsigned resp_data[]);
  string          report_str    = "AXI_DATA_CHECK";
  sinc_axi_data_t act_data[];
  int             beat_cnt      = 0;
  bit             is_size_match;
  bit             is_data_match;

  `uvm_info(report_str, $sformatf("exp_data[%0p], resp_data[%0p]", exp_data, resp_data), UVM_HIGH)

  // pack data
  act_data = new [resp_data.size() / 4];
  foreach (resp_data[i]) begin
    act_data[i / 4][(i%4)*8 +:8] = resp_data[i];
  end

  // check data size
  is_size_match = (exp_data.size() == act_data.size())? 1:0;

  foreach (exp_data[i]) begin
    `uvm_info(report_str, $sformatf("exp_data[%0d]['h%0h] : act_data[%0d]['h%0h]", i, exp_data[i], i, act_data[i]), UVM_HIGH)
    if (exp_data[i] == act_data[i]) begin
      is_data_match = 1;
    end else begin
      is_data_match = 0;
      break;
    end
  end

  // Note: latency performance register check is offloaded outside of scoreboard for now
  if (m_req_dst == SINC_REG ) begin
    if (m_dst_reg !== null) begin
      if ((m_dst_reg.get_name() == "lat_cntr_lower")) begin
        if (((exp_data[0] > 0) && (act_data[0] == 0)) || // lat cnt should increased but act is not
            ((exp_data[0] == 0) && (act_data[0] > 0))) begin // lat cnt should not increased but act is
          is_data_match = 0;
        end else begin
          is_data_match = 1;
        end

        `uvm_info(report_str, $sformatf("data check for [lat_cntr_lower] reg is_data_match[%0d] ", is_data_match), UVM_HIGH)
      end

      if ((m_dst_reg.get_name() == "lat_cntr_upper")) begin
        if (((exp_data[0] > 0) && (act_data[0] == 0)) || // lat cnt should increased but act is not
            ((exp_data[0] == 0) && (act_data[0] > 0))) begin // lat cnt should not increased but act is
          is_data_match = 0;
        end else begin
          is_data_match = 1;
        end
        `uvm_info(report_str, $sformatf("data check for [lat_cntr_upper] reg is_data_match[%0d] ", is_data_match), UVM_HIGH)
      end

      if ((m_dst_reg.get_name() == "hit_cntr_lower")) begin
        if (!is_data_match) begin
          if (m_top_configuration.m_sys_cfg.m_observe_cpu_rd_during_erase_at_cache_active) begin
            is_data_match = 1;
          end else begin
            is_data_match = 0;
          end
          `uvm_info(report_str, $sformatf("data check for [lat_cntr_upper] reg is_data_match[%0d] ", is_data_match), UVM_HIGH)
        end
      end

      if ((m_dst_reg.get_name() == "miss_cntr_lower")) begin
        if (!is_data_match) begin
          if (m_top_configuration.m_sys_cfg.m_perf_cntr_toggled_during_cpu_rd) begin
            is_data_match = 1;
          end
        end
      end

    end
  end

  `uvm_info(report_str, $sformatf("axi_data_check[%0d], is_size_match[%0d], is_data_match[%0d] ", is_size_match && is_data_match, is_size_match, is_data_match), UVM_HIGH)
  return (is_size_match && is_data_match);

endfunction : axi_data_check

task automatic sinc_sb_pkt_item::reg_data_check(
    input uvm_reg_data_t exp_reg_data,
    input uvm_reg        reg_handler,
    input int            delay          =0,
    input time           req_start_time,
    input bit            exp_pass       =1
  );
  string           report_str       = "reg_data_check";
  uvm_status_e     my_status;
  uvm_reg_data_t   my_data;
  bit              missmatch        = 0;
  bit              r_result_pass;
  uvm_reg_backdoor bkdr             = reg_handler.get_backdoor();

  `uvm_info(report_str, $sformatf("Start on Reg[%0s][full_name:%0s], EXP['h%0h], delay[%0d], bkdr_is_null[%0d], has_hdl_path[%0d]",
      reg_handler.get_name(), reg_handler.get_full_name(), exp_reg_data, delay,
      (bkdr == null), reg_handler.has_hdl_path()), UVM_HIGH)

  repeat(delay) begin
    @(m_top_configuration.m_sinc_vif.mon_cb);
  end

  if (!reg_handler.has_hdl_path()) begin
    `uvm_info(report_str, $sformatf("Skip backdoor peek due to register is manually changed (RAL peek not work) Reg[%0s], EXP['h%0h]", reg_handler.get_name(), exp_reg_data), UVM_HIGH)
    return;
  end

  reg_handler.peek(my_status, my_data);
  if(my_status !== UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("reg_handler.peek returned status %s", my_status.name()))
  end
  `uvm_info(report_str, $sformatf("Reg[%0s], EXP['h%0h], ACT['h%0h] ", reg_handler.get_name(), exp_reg_data, my_data), UVM_HIGH)

  /*
   foreach (exp_reg_data[i]) begin
   // check 32 bits a time
   if (my_data[i*32 +:32] !== exp_reg_data[i]) begin
   missmatch = 1;
   `uvm_info(report_str, $sformatf("[Signature] Found missmatched Reg data EXP['h%0h], ACT['h%0h] on 4 byte sel [%0d] ",
   exp_reg_data[i], my_data[i*32 +:32], i), UVM_HIGH);
   break;
   end
   end
   */
  if (exp_reg_data !== my_data) begin
    missmatch = 1;
  end

  // waive if back to back write to the same register, the first write's check time could happen when second write finished
  if (missmatch) begin
    time cur_time = $realtime;
    `uvm_info(report_str, $sformatf("Reg_handler_addr['h%0h], most_recent_write_dst_reg_addr['h%0h], req_start_time[%0t], most_recent_write_dst_reg_start_time[%0t], cur_time[%0t]",
        reg_handler.get_address(), m_top_configuration.m_sys_cfg.m_most_recent_write_dst_reg.get_address(), req_start_time, m_top_configuration.m_sys_cfg.m_most_recent_write_dst_reg_start_time, cur_time), UVM_HIGH)

    if (reg_handler.get_address() == m_top_configuration.m_sys_cfg.m_most_recent_write_dst_reg.get_address()) begin
      if ((req_start_time < m_top_configuration.m_sys_cfg.m_most_recent_write_dst_reg_start_time) &&
          (cur_time > m_top_configuration.m_sys_cfg.m_most_recent_write_dst_reg_start_time)) begin
        missmatch = 0;
      end
    end
  end

  // exception on AES CTRL CMD register write
  // scoreboard offload AES REG check to stimulus sequence
  if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en) begin
    if (missmatch &&
        ((m_dst_reg.get_name() == sinc_parameters_pkg::AES_TEST_CTRL_REG_NAME))) begin
      // set predict value of register
      sinc_reg_data_t my_reg_data[];
      my_reg_data = new [1];
      // set mirror with actual data
      // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(m_dst_reg.get_name(), my_datamy_reg_data[0])) begin
      if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(m_dst_reg.get_name(), my_data)) begin
        `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", m_dst_reg.get_name(), my_data), UVM_HIGH)
      end else begin
        `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", m_dst_reg.get_name()))
      end
      missmatch = 0;
    end
  end

  r_result_pass = exp_pass ? !missmatch : missmatch;

  if (!r_result_pass) begin
    print_packet();
    `uvm_error(report_str, $sformatf("self check fail on register [%0s] with data, check signature for more information",
        reg_handler.get_name()))
  end

endtask : reg_data_check

task automatic sinc_sb_pkt_item::update_reg_mirror_w_backdoor_value(input string reg_name);
  string           report_str   = "update_reg_mirror_w_backdoor_value";
  uvm_status_e     my_status;
  uvm_reg_data_t   my_data;
  uvm_reg          reg_handler  = m_addr_dec.get_reg_ral_hit_by_name(reg_name);
  uvm_reg_backdoor bkdr         = reg_handler.get_backdoor();
  uvm_reg          dst_reg    = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(reg_name);
  sinc_reg_data_t  cur_reg_data = sinc_reg_data_t'(dst_reg.get_mirrored_value());

  `uvm_info(report_str, $sformatf("Start on Reg[%0s][full_name:%0s], bkdr_is_null[%0d], has_hdl_path[%0d]",
      reg_handler.get_name(), reg_handler.get_full_name(),
      (bkdr == null), reg_handler.has_hdl_path()), UVM_HIGH)

  if (!reg_handler.has_hdl_path()) begin
    `uvm_info(report_str, $sformatf("Skip backdoor peek due to register is manually changed (RAL peek not work) Reg[%0s]", reg_handler.get_name()), UVM_HIGH)
    return;
  end

  reg_handler.peek(my_status, my_data);
  if(my_status !== UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("reg_handler.peek returned status %s", my_status.name()))
  end

  `uvm_info(report_str, $sformatf("Reg[%0s], Mirror['h%0h], ACT['h%0h] ", reg_handler.get_name(), cur_reg_data, sinc_reg_data_t'(my_data)), UVM_HIGH)

  /*
   foreach (exp_reg_data[i]) begin
   // check 32 bits a time
   if (my_data[i*32 +:32] !== exp_reg_data[i]) begin
   missmatch = 1;
   `uvm_info(report_str, $sformatf("[Signature] Found missmatched Reg data EXP['h%0h], ACT['h%0h] on 4 byte sel [%0d] ",
   exp_reg_data[i], my_data[i*32 +:32], i), UVM_HIGH);
   break;
   end
   end
   */
  if (cur_reg_data !== sinc_reg_data_t'(my_data)) begin
    `uvm_info(report_str, $sformatf("Update Reg [%0s] from ['h%0h] to ['h%0h]",
        reg_handler.get_name(), cur_reg_data, sinc_reg_data_t'(my_data)), UVM_HIGH)
    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(reg_name, sinc_reg_data_t'(my_data))) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", reg_handler.get_name(), sinc_reg_data_t'(my_data)), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", reg_name))
    end
  end

endtask : update_reg_mirror_w_backdoor_value

function void sinc_sb_pkt_item::set_exp_fw_cmd(pal_axi_xaction t);
  string          report_str     = "SET_EXP_FW_CMD";
  // int m_fw_cmd_in_int;
  sinc_reg_data_t my_reg_data[1];                   // only expect 32 bits write data, otherwise should report Null access

  if (m_exp_sub_slv_err) begin
    return;
  end

  // pack register write data
  for (int i=0; i < (m_axi_sub_wr_resp_tran_q[0].data.size() / 4); i++) begin
    my_reg_data[i] = {t.data[3 + (i * 4)], t.data[2 + (i * 4)], t.data[1 + (i * 4)], t.data[0 + (i * 4)]};
  end

  // 1. write reserved region of CMD register will result AXI SLV Error
  // 2. write reserved CMD type will result command fail -> SINC will not issue the FW command
  // 3. if above are not true, then FW command will be issued, set corresponding expectation

  // write reserved region of CMD register will result AXI SLV Error - Design changed, write to reserved field will not result SLVERR.
  if (|my_reg_data[0][`SINC_CMD_REG_RSVD_RANGE_SEL] == 1'b1) begin
    m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT] = 1;
    // uvm_reg status_reg = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
    // sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
    // cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    // m_exp_sub_slv_err = 1;

    // `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
    //                                 m_exp_sub_slv_err), UVM_HIGH)

    // // predict command fail
    // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    //   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, my_reg_data[0]), UVM_HIGH)
    // end else begin
    //   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    // end
    // return;
  end

  m_fw_cmd_in_int = int'(my_reg_data[0][`SINC_CMD_REG_SEL_CMD_RANGE_SEL]);

  if (!m_top_configuration.m_sys_cfg.is_valid_fw_cmd(m_fw_cmd_in_int)) begin
    uvm_reg status_reg                                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
    sinc_reg_data_t cur_status_reg_data                          = sinc_reg_data_t'(status_reg.get_mirrored_value());
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
    // m_exp_sub_slv_err = 1;
    // `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
    //                                m_exp_sub_slv_err), UVM_HIGH)
    m_write_cmd_reg_with_cmd_sel_w_unknown_op                    = 1;
    m_is_reg_write_discarded                                     = 1;
    m_is_fw_cmd                                                  = 0;
    m_exp_sinc_done                                              = 0;
    m_sinc_done_num                                              = 0;
    `uvm_info(report_str, $sformatf("Found cmd error when write cmd register with CMD field UNKNOW CMD[%0d], m_write_cmd_reg_with_cmd_sel_w_unknown_op[%0d]",
        m_fw_cmd_in_int, m_write_cmd_reg_with_cmd_sel_w_unknown_op), UVM_HIGH)
    // predict command fail
    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, my_reg_data[0]), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    // for coverage
    m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE] = 1;
    m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP]  = 1;
    return;
  end

  // if above are not true, then FW command will be issued, set corresponding expectation
  m_fw_cmd = m_top_configuration.m_sys_cfg.get_fw_cmd_type(m_fw_cmd_in_int);
  `uvm_info(report_str, $sformatf("set expectation for FW command[%0s]",
      m_fw_cmd.name()), UVM_HIGH)

  // register expectation is already done
  // only set expectation for FW command related
  if (m_fw_cmd !== sinc_parameters_pkg::SINC_FW_UNMAPPED) begin
    // Other FW commands are not allowed when AES command in progress
    if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en &&
        (m_fw_cmd !== sinc_parameters_pkg::SINC_AES_TEST_DISABLE)) begin
      uvm_reg status_reg                                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
      sinc_reg_data_t cur_status_reg_data                          = sinc_reg_data_t'(status_reg.get_mirrored_value());
      cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
      cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
      m_is_fw_cmd                                                  = 0;
      m_exp_sinc_done                                              = 0;
      m_sinc_done_num                                              = 0;
      m_write_cmd_reg_when_aes_test_enabled                        = 1; // write data will be discarded
      m_is_reg_write_discarded                                     = 1;

      // for coverage
      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR] = 1;

      // predict command fail
      if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
        `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, my_reg_data[0]), UVM_HIGH)
      end else begin
        `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      end

      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR] = 1;

      // clear AES test en
      // if (my_reg_data[0][`SINC_REGS_CMD_AES_TEST_EN_RANGE] == 0) begin
      begin
        uvm_reg cmd_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME);
        sinc_reg_data_t cur_cmd_reg_data = sinc_reg_data_t'(cmd_reg.get_mirrored_value());

        cur_cmd_reg_data[`SINC_REGS_CMD_AES_TEST_EN_RANGE] = 0;

        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::CMD_REG_NAME))
        end

        m_top_configuration.m_sys_cfg.m_aes_test_mode_en      = 0;
        m_top_configuration.m_sys_cfg.m_aes_test_mode_done    = 1;
        m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled = $realtime;
      end

      return;
    end else begin // if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en &&...
      /*
       uvm_reg status_reg = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
       sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
       cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b1;
       m_is_fw_cmd = 1;
       m_exp_sinc_done = 1;
       m_sinc_done_num = 1;
       if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
       `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, my_reg_data[0]), UVM_HIGH)
       end else begin
       `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
       end
       */
    end // else: !if(m_top_configuration.m_sys_cfg.m_aes_test_mode_en &&...

    // when sinc_error has been injected before write response arrived, there is no further need to set the expectation
    // only limit the case to observed scenarios
    // 1. m_fw_op_invalid_due_to_adjacent_block_fetch
    if (m_exp_sinc_error && m_sinc_error_q.size() && m_fw_op_invalid_due_to_adjacent_block_fetch) begin
      return;
    end

    if (m_fw_cmd == sinc_parameters_pkg::SINC_SINC_RESET) begin
      set_exp_fw_reset_cmd();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_SET_INIT_STATE) begin
      set_exp_fw_set_init_state_cmd();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK) begin
      set_exp_fw_encr_block_cmd();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE) begin
      set_exp_fw_set_cache_active_state_cmd();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_AES_TEST_EN) begin
      set_exp_fw_aes_test_mode_en();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_AES_TEST_DISABLE) begin
      set_exp_fw_aes_test_mode_disable();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_RESET) begin
      set_exp_fw_disable_reset();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_DISABLE_REINIT) begin
      set_exp_fw_disable_reinit();
    end else if (m_fw_cmd == sinc_parameters_pkg::SINC_SINC_REINIT) begin
      set_exp_fw_reinit_cmd();
    end else begin
      `uvm_error(report_str, $sformatf("Not implemented expectation on FW request [%0s]", m_fw_cmd.name()))
    end

  end else begin // if (m_fw_cmd !== sinc_parameters_pkg::SINC_FW_UNMAPPED)

    // for coverage
    m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP] = 1;

    // clear AES test en as long as write data has filed 'aes_test_en' set 0
    if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en &&
        (my_reg_data[0][`SINC_REGS_CMD_AES_TEST_EN_RANGE] == 0)) begin
      uvm_reg cmd_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME);
      sinc_reg_data_t cur_cmd_reg_data = sinc_reg_data_t'(cmd_reg.get_mirrored_value());

      cur_cmd_reg_data[`SINC_REGS_CMD_AES_TEST_EN_RANGE] = 0;

      if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data)) begin
        `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data), UVM_HIGH)
      end else begin
        `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::CMD_REG_NAME))
      end

      m_top_configuration.m_sys_cfg.m_aes_test_mode_en      = 0;
      m_top_configuration.m_sys_cfg.m_aes_test_mode_done    = 1;
      m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled = $realtime;
    end
  end

endfunction : set_exp_fw_cmd

function bit sinc_sb_pkt_item::self_check_fw_command();
  string          report_str          = "SELF_CHECK_FW_COMMAND";
  bit             result_pass         = 0;
  bit             is_match_sinc_done  = !m_exp_sinc_done;
  bit             is_match_axi_mgr_rd = !m_exp_axi_mgr_rd_req;
  bit             is_match_axi_mgr_wr = !m_exp_axi_mgr_wr_req;
  uvm_reg         status_reg          = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

  if (m_exp_axi_mgr_rd_req) begin
    is_match_axi_mgr_rd = is_axi_mgr_rd_req_match_exp();
  end

  if (m_exp_axi_mgr_wr_req) begin
    is_match_axi_mgr_wr = is_axi_mgr_wr_req_match_exp();
  end

  if (m_exp_sinc_done) begin
    is_match_sinc_done = (m_sinc_done_num == m_sinc_done_q.size())? 1:0;
  end

  case (m_fw_cmd)
    sinc_parameters_pkg::SINC_SET_INIT_STATE : begin

      // fixme-hw: add check needed
      // 1. Fetch RNG Seed if not yet
      //    Check the RNG address, AXI word in total
      // 2. Fetch the KEY if not yet
      //    Check the KSU's KEY address, AXI word in total
      // 3. Check original state, whether transition is allowed

      // set the current state
      // update status register
      // if (!m_is_fw_op_fail) begin
      //   m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;
      //   // set update on cache state
      //   cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_INIT_STATE;
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end
      //   `uvm_info(report_str, $sformatf("Update status register for FW CMD [%0s]", m_fw_cmd.name()), UVM_HIGH)
      // end else begin // if (!m_is_fw_op_fail) begin
      //   `uvm_info(report_str, $sformatf("Not Update status register for FW CMD [%0s] due to m_is_fw_op_fail[%0d]", m_fw_cmd.name(), m_is_fw_op_fail), UVM_HIGH)
      // end

      // fixme
      // return 1;
    end
    sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE : begin
      // fixme-hw: add check needed
      // 1. set status register
      // if (!m_is_fw_op_fail) begin
      //   m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_ACTIVE_STATE;
      //   cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_ACTIVE_STATE;
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end
      // end
    end
    sinc_parameters_pkg::SINC_SINC_RESET : begin
      // if (!m_is_fw_op_fail) begin
      //   m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_DISABLE_STATE;
      //   cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_DISABLE_STATE;
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end

      //   // update peripherals
      //   // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
      //   // reset cache coherency, will also do preload of current memory
      //   m_top_configuration.m_csd.reset_csd();

      //   // reset MPU attributes and registers
      //   m_mpu_cfg = m_top_configuration.ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
      //   m_mpu_cfg.reset_mpu();

      //   // KEY should been wiped
      //   m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;
      // end // if (!m_is_fw_op_fail) begin
    end
    sinc_parameters_pkg::SINC_SINC_REINIT : begin
      // if (!m_is_fw_op_fail) begin
      //   m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;
      //   cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_INIT_STATE;
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end

      //   // update peripherals
      //   // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
      //   // reset cache coherency, will also do preload of current memory
      //   m_top_configuration.m_csd.reset_csd();

      //   // sinc_reinit will not reset MPU attributes and registers
      //   // m_mpu_cfg = m_top_configuration.ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
      //   // m_mpu_cfg.reset_mpu();

      //   // KEY should been wiped
      //   m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;
      // end // if (!m_is_fw_op_fail) begin
    end
    sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
      // if (!m_is_fw_op_fail) begin
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end
      // end // if (!m_is_fw_op_fail) begin
    end
    sinc_parameters_pkg::SINC_AES_TEST_DISABLE : begin

    end
    sinc_parameters_pkg::SINC_AES_TEST_EN : begin

    end
    sinc_parameters_pkg::SINC_DISABLE_RESET: begin
      // // no further check
      // if (!m_is_fw_op_fail) begin
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end
      // end // if (!m_is_fw_op_fail) begin
    end
    sinc_parameters_pkg::SINC_DISABLE_REINIT: begin
      // // no further check
      // if (!m_is_fw_op_fail) begin
      //   // set update on success and in_progress
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
      //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
      //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      //   end else begin
      //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      //   end
      // end // if (!m_is_fw_op_fail) begin
    end
    default: begin
      bit waive_error_report = 0;

      // 1. only happen if an FW OP got interrupted by ERASE
      //    there is no sinc_error or sinc_done interrupt, so self_check on FW command can be trigger when retiring this pkt
      // 2. exp_sub_slv_err
      if (m_erase_during_req_inprogress || m_exp_sub_slv_err) begin
        waive_error_report = 1;
      end
      if (!waive_error_report) begin
        `uvm_error(report_str, $sformatf("received unexpected m_fw_cmd entry[%0s]", m_fw_cmd.name()))
      end
    end
  endcase // case (m_fw_cmd)

  result_pass = is_match_sinc_done && is_match_axi_mgr_rd && is_match_axi_mgr_wr;

  if (!result_pass) begin
    print_packet();
    `uvm_error(report_str, $sformatf("self check fail on current scoreboard item with entry [%0s], is_match_sinc_done[%0d], is_match_axi_mgr_rd[%0d], is_match_axi_mgr_wr[%0d], please check the reported signature",
        m_fw_cmd.name(),
        is_match_sinc_done,
        is_match_axi_mgr_rd,
        is_match_axi_mgr_wr))
  end
  return (result_pass);

endfunction : self_check_fw_command

// FUNCTION: is_cache_mem_match_exp
// Check if collected CACHE mem transaction match with expectation
// If NOT, return 0;
// If YES, return 1.
function bit sinc_sb_pkt_item::is_cache_mem_match_exp(int num); // when is_mem_erase set 1, check for full address range erase with 'h0

  logic [1:0]  iedc_addr_lsbs    = 0;
  logic [13:0] encode_addr;
  // logic [sinc_parameters_pkg::CACHE_MEM_WORD_ADDR_WIDTH-1:0] iedc_addr;
  bit [38:0]   edc_data;
  bit [31:0]   scrubed_line_data;
  string       report_str        = "is_cache_mem_match_exp:\n";
  int          result            = 1;

  if (m_erase_accepted_before_cache_mem_transaction_done) begin
    return (1);
  end
  // check on total number
  if (num !== m_cache_mem_pkt_q.size()) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] expecting CACHE MEM Transactions: exp[%0d], recieved[%0d] \n", num, m_cache_mem_pkt_q.size())};
  end

  // if expectation is 0, then skip the rest of check
  if (num == 0) begin
    return (1);
  end

  // when sinc error expected, cache mem behavior is not predictable
  if (m_exp_sinc_error && (m_sinc_error_q.size() == 1)) begin
    return (1);
  end

  // check on operation
  if (result) begin
    case (m_sinc_sb_pkt_entry)
      sinc_env_pkg::ENTRY_CPU_READ : begin
        if (m_is_cache_hit) begin
          // only expect read
          foreach (m_cache_mem_pkt_q[i]) begin
            if (m_cache_mem_pkt_q[i].m_rw !== memory_pkg::READ) begin
              result = 0;
              `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[READ], actual[%0s]", m_cache_mem_pkt_q[i].m_rw.name()), UVM_HIGH)
              break;
            end
          end
        end else begin
          // first read for prefetch
          if (m_cache_mem_pkt_q[0].m_rw !== memory_pkg::READ) begin
            result = 0;
            `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[READ], actual[%0s]", m_cache_mem_pkt_q[0].m_rw.name()), UVM_HIGH)
          end
          // last read for fetch loaded cache mem
          if (m_cache_mem_pkt_q[m_cache_mem_pkt_q.size() - 1].m_rw !== memory_pkg::READ) begin
            result = 0;
            `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[READ], actual[%0s]", m_cache_mem_pkt_q[m_cache_mem_pkt_q.size() - 1].m_rw.name()), UVM_HIGH)
          end
        end
      end
      sinc_env_pkg::ENTRY_CPU_WRITE : begin
        // expect read -> write with same address
        if (m_cache_mem_pkt_q[0].m_rw !== memory_pkg::READ) begin
          result = 0;
          `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[READ], actual[%0s]", m_cache_mem_pkt_q[0].m_rw.name()), UVM_HIGH)
        end
        if (m_cache_mem_pkt_q[m_cache_mem_pkt_q.size() - 1].m_rw !== memory_pkg::WRITE) begin
          result = 0;
          `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[WRITE], actual[%0s]", m_cache_mem_pkt_q[m_cache_mem_pkt_q.size() - 1].m_rw.name()), UVM_HIGH)
        end
      end
      sinc_env_pkg::ENTRY_CREG_ERASE : begin
        // expect all writes, address is from 0 to mem depth
        for (int i=0; i < num; i++) begin
          if (m_cache_mem_pkt_q[i].m_rw !== memory_pkg::WRITE) begin
            result = 0;
            `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[WRITE], actual[%0s]", m_cache_mem_pkt_q[i].m_rw.name()), UVM_HIGH)
            break;
          end
          if (m_cache_mem_pkt_q[i].m_address !== i) begin
            result = 0;
            `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched address, exp[%0d], actual[%0d], data['h%0h]", i, m_cache_mem_pkt_q[i].m_address, m_cache_mem_pkt_q[i].m_wdata), UVM_HIGH)
            break;
          end
        end
      end
      sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
        if (m_is_fw_cmd && ((m_fw_cmd == sinc_parameters_pkg::SINC_SINC_RESET) ||
              (m_fw_cmd == sinc_parameters_pkg::SINC_SINC_REINIT))) begin
          // expect all writes, address is from 0 to mem depth
          for (int i=0; i < num; i++) begin
            if (m_cache_mem_pkt_q[i].m_rw !== memory_pkg::WRITE) begin
              result = 0;
              `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched operation, exp[WRITE], actual[%0s]", m_cache_mem_pkt_q[i].m_rw.name()), UVM_HIGH)
              break;
            end
            if (m_cache_mem_pkt_q[i].m_address !== i) begin
              result = 0;
              `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("Found mismatched address, exp[%0d], actual[%0d]", i, m_cache_mem_pkt_q[i].m_address), UVM_HIGH)
              break;
            end
          end
        end else begin
          `uvm_error(report_str, $sformatf("check on unexpected scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
        end
      end
      default: `uvm_error(report_str, $sformatf("check on unexpected scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
    endcase
  end

  `uvm_info("Report on IS_CACHE_MEM_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_cache_mem_match_exp

function void sinc_sb_pkt_item::set_exp_fw_reset_cmd();
  string          report_str                           = "SET_EXP_FW_RESET_CMD";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_reset_disabled                    = cur_status_reg_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_RANGE];
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);

  if (is_reset_disabled || !is_allowed_fw_cmd_in_cur_cache_state) begin
    // the reset command will be discarded, resulting invalid command
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;

    if (is_reset_disabled) begin
      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR] = 1;
    end
  end else begin
    set_fw_in_progress();
    // Reset involves with
    // 1. erase the cache IRAM,
    // 2. erase the BEK,
    // 3. reset the MPU permissions and
    // 4. move to Disabled state.

    // set expectations
    // 1. erase the cache IRAM
    m_exp_cache_mem             = 1;
    // Note: erase done only asserted at CREG Erase
    // m_exp_erase_done = 1;
    m_cache_mem_transaction_num = int'(sinc_parameters_pkg::SINC_CACHE_END_ADDR) + 1;
    m_exp_sinc_done             = 1;
    m_sinc_done_num             = 1;

    // 2. erase the BEK
    // fixme-hw: won't have direct impact to black box level DV verification

    // 3. reset the MPU permissions
    m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].reset_mpu();

    // 4. move to Disabled state
    // below has been moved to update_tlb_when_op_finish()
    // m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_DISABLE_STATE;

    // remove error flag
    m_top_configuration.m_sys_cfg.m_unmapped_axi_mgr_rd_when_block_fetch = 0;

    // remove waiver flag
    m_top_configuration.m_sys_cfg.m_observe_cpu_rd_during_erase_at_cache_active = 0;
    m_top_configuration.m_sys_cfg.m_perf_cntr_toggled_during_cpu_rd = 0;

    `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)

  end

endfunction : set_exp_fw_reset_cmd

function void sinc_sb_pkt_item::set_exp_fw_reinit_cmd();
  string          report_str                           = "SET_EXP_FW_REINIT_CMD";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_reinit_disabled                   = cur_status_reg_data[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_RANGE];
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);

  if (is_reinit_disabled || !is_allowed_fw_cmd_in_cur_cache_state) begin
    // the reinit command will be discarded, resulting invalid command
    m_is_fw_op_fail = 1;

    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;

    if (is_reinit_disabled) begin
      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR] = 1;
    end
  end else begin
    set_fw_in_progress();
    // Reinit involves with
    // CMU asserts cmu_busy signal and indicates busy in status register.
    // CIU wipes the cache IRAM and reset the VTAG. MPU permissions are preserved.
    // SInC transitions to Initialization state, CMU de-asserts cmu_busy and indicates completion in status register.
    // 1. erase the cache IRAM,
    // 2. erase the BEK,
    // 3. move to Init state.

    // set expectations
    // 1. erase the cache IRAM
    m_exp_cache_mem             = 1;
    // Note: erase done only asserted at CREG Erase
    // m_exp_erase_done = 1;
    m_cache_mem_transaction_num = int'(sinc_parameters_pkg::SINC_CACHE_END_ADDR) + 1;
    m_exp_sinc_done             = 1;
    m_sinc_done_num             = 1;

    // 2. erase the BEK
    // done when it's complete

    // 4. move to Disabled state
    // below has been moved to update_tlb_when_op_finish()
    //m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;
    `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
  end

endfunction : set_exp_fw_reinit_cmd

function void sinc_sb_pkt_item::set_exp_fw_set_init_state_cmd();
  string          report_str                           = "SET_EXP_FW_SET_INIT_STATE_CMD";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_reinit_disabled                   = cur_status_reg_data[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_RANGE];
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);

  if (!is_allowed_fw_cmd_in_cur_cache_state) begin // reinit_disabled should not affect set_init_state_cmd
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;
  end else begin
    // set expectations entering init state
    // fixme-hw: add expectation
    // 0. Check original state, whether transition is allowed
    if (m_cur_cache_state !== sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
      m_is_fw_op_fail                                              = 1;
      m_exp_sinc_done                                              = 0;
      m_sinc_done_num                                              = 0;
      m_exp_sinc_error                                             = 1;
      m_sinc_error_num                                             = 1;
      cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
      cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
      if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
        `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      end else begin
        `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      end

      return;
    end
    set_fw_in_progress();
    // 1. Fetch RNG Seed if not yet
    //    Check the RNG address, AXI word in total
    // SINC_NO_SEED_LOADING bypasses the DRBG seed-read sub-states in SET_INIT (MAS 14.2)
    if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING &&
        !m_top_configuration.m_sys_cfg.m_is_rng_fetched) begin
      m_rng_seed_is_fetched = 0; // for coverage
      m_exp_axi_mgr_rd_req  = 1;
      m_exp_axi_mgr_rd_size += sinc_parameters_pkg::SINC_RNG_SEED_IN_BITS / 8;
    end else begin
      m_rng_seed_is_fetched = 1; // for coverage
    end
    // 2. Fetch the KEY if not yet
    //    Check the KSU's KEY address, AXI word in total
    if (!m_top_configuration.m_sys_cfg.m_is_key_fetched) begin
      m_ksu_key_is_fetched = 0;
      m_exp_axi_mgr_rd_req = 1;
      m_exp_axi_mgr_rd_size += sinc_parameters_pkg::SINC_KEY_IN_BITS / 8;
    end else begin
      m_ksu_key_is_fetched = 1;
    end

    // 3. move to init state, set expectation when cmd is done
    // 4. cmd should success, set expectation when cmd is done

    // 5. sinc done
    m_exp_sinc_done = 1;
    m_sinc_done_num = 1;

    `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)

  end

endfunction : set_exp_fw_set_init_state_cmd

function void sinc_sb_pkt_item::set_exp_fw_set_cache_active_state_cmd();
  string          report_str                           = "SET_EXP_FW_SET_CACHE_ACTIVE_STATE_CMD";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  // set expectations entering cache_active state

  // 1. Check original state, whether transition is allowed
  if (m_cur_cache_state == sinc_parameters_pkg::CACHE_INIT_STATE) begin
    set_fw_in_progress();
    // 2. move to init state, set expectation when cmd is done
    // 3. cmd should success, set expectation when cmd is done
    // 4. sinc done
    m_exp_sinc_done = 1;
    m_sinc_done_num = 1;
    `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
  end else begin
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;
  end

endfunction : set_exp_fw_set_cache_active_state_cmd

function void sinc_sb_pkt_item::set_exp_fw_encr_block_cmd();
  string          report_str                           = "SET_EXP_FW_ENCR_BLOCK_CMD";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  // set expectations entering cache_active state

  // 1. Check original state, whether transition is allowed
  if (m_cur_cache_state == sinc_parameters_pkg::CACHE_INIT_STATE) begin
    set_fw_in_progress();

    if (m_top_configuration.m_sys_cfg.is_valid_encr_block_cmd(m_snapshot_num_of_blocks, m_snapshot_block_encr_num)) begin
      // 2. set expectation for AXI MGR to SHAREDRAM // fixme-hw: not add yet
      m_exp_axi_mgr_rd_req = 1;
      m_exp_axi_mgr_rd_size += (sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
      // 3. set expectation for AXI MGR to DMB Encrypted data // fixme-hw: not add yet
      m_exp_axi_mgr_wr_req = 1;
      m_exp_axi_mgr_wr_size += (sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
      // 4. set expectation for AXI MGR to DMB Authentication Tag // fixme-hw: not add yet
      m_exp_axi_mgr_wr_size += (sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
      // 5. cmd should success, set expectation when cmd is done
      // 6. sinc done
      m_exp_sinc_done = 1;
      m_sinc_done_num = 1;
      `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
    end else begin
      `uvm_info(report_str, $sformatf("Found invalid FW Command[%0s]", m_fw_cmd.name()), UVM_HIGH)
      m_is_fw_op_fail                                              = 1;
      m_exp_sinc_done                                              = 0;
      m_sinc_done_num                                              = 0;
      m_exp_sinc_error                                             = 1;
      m_sinc_error_num                                             = 1;
      // the set_cache_active command will be discarded, resulting invalid command
      cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
      cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

      // for coverage
      m_sinc_axi_wr_fw_cmd_err_types[`SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID] = 1;

      if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
        `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
      end else begin
        `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
      end
    end
  end else begin
    m_is_fw_op_fail                                              = 1;
    m_exp_sinc_done                                              = 0;
    m_sinc_done_num                                              = 0;
    m_exp_sinc_error                                             = 1;
    m_sinc_error_num                                             = 1;
    // the set_cache_active command will be discarded, resulting invalid command
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end
  end

endfunction : set_exp_fw_encr_block_cmd

// FUNCTION: is_axi_mgr_rd_req_match_exp
function bit sinc_sb_pkt_item::is_axi_mgr_rd_req_match_exp();
  string report_str = "is_axi_mgr_rd_req_match_exp:\n";
  bit    result     = 1;



  // when erase accepted when CPU READ in progress
  if (m_erase_accepted_before_cache_mem_transaction_done) begin
    return (1);
  end

  // check on total data transfer
  if (m_is_fw_op_fail &&
      (m_is_rng_fetch_error || m_is_sharedram_rd_error || m_is_ksu_rd_error || m_is_dmb_read_error || m_is_dmb_write_error)) begin
    if (m_act_axi_mgr_rd_size_received > m_exp_axi_mgr_rd_size) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] m_is_fw_op_fail, expecting AXI MGR RD transfer data size (bytes): exp[%0d], recieved[%0d] \n",
          m_exp_axi_mgr_rd_size, m_act_axi_mgr_rd_size_received)};
    end else begin
      return (1);
    end
  end else if (m_is_cpu_mem_req && m_exp_block_fetch && (m_is_auth_tag_mismatch_error || m_is_dmb_read_error)) begin
    if (m_act_axi_mgr_rd_size_received > m_exp_axi_mgr_rd_size) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] m_is_auth_tag_mismatch_error expecting AXI MGR RD transfer data size (bytes): exp[%0d], recieved[%0d] \n",
          m_exp_axi_mgr_rd_size, m_act_axi_mgr_rd_size_received)};
    end else begin
      return (1);
    end
  end else begin
    if (m_exp_axi_mgr_rd_size !== m_act_axi_mgr_rd_size_received) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] expecting AXI MGR RD transfer data size (bytes): exp[%0d], recieved[%0d] \n",
          m_exp_axi_mgr_rd_size, m_act_axi_mgr_rd_size_received)};
    end
  end

  // when m_is_auth_tag_check_disabled is set, the data fetch could stop once desired data is fetched
  if (m_is_auth_tag_check_disabled) begin
    if ((m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
        !m_is_cache_hit) begin
      int cache_block_idx;
      csd_cache_block_t preloaded_cache_block;
      address_t block_fetch_start_address;
      address_t auth_tag_fetch_start_address;
      csd_cache_block_t set_cache_block; // used to update CSD
      pal_axi_xaction encrypted_data_axi_mgr_rd_resp_tran_q[$];
      pal_axi_xaction auth_tag_axi_mgr_rd_resp_tran_q[$];
      int exp_encrypted_data_bytes = sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8;
      int exp_auth_tag_bytes       = sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8;
      int act_encrypted_data_bytes = 0;
      int act_auth_tag_bytes       = 0;
      int data_size_byte_cnt       = 0;

      report_str = "is_axi_mgr_rd_req_match_exp:\n";
      result     = 1;

      // digest the read transactions to encrypted data and auth tag region
      for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
        data_size_byte_cnt += m_axi_mgr_rd_resp_tran_q[i].data.size();
        if (data_size_byte_cnt <= exp_encrypted_data_bytes) begin
          encrypted_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
          act_encrypted_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
        end else begin
          auth_tag_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
          act_auth_tag_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
        end
      end

      // check on encrypted data fetch
      // - check on data size
      if (act_encrypted_data_bytes !== exp_encrypted_data_bytes) begin
        result = 0;
        `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of encrypted data for Entry[%0s]. exp[%0d], act[%0d]",
                                        m_sinc_sb_pkt_entry.name(), exp_encrypted_data_bytes, act_encrypted_data_bytes), UVM_HIGH)

        return (result);
      end
      // - check on starting address
      cache_block_idx              = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
      preloaded_cache_block        = m_top_configuration.m_sys_cfg.m_csd.m_cache_blocks[cache_block_idx];
      block_fetch_start_address    = m_snapshot_ext_block_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_BLOCK_OFFSET);
      auth_tag_fetch_start_address = m_snapshot_ext_auth_tag_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_AUTH_TAG_OFFSET);

      if (block_fetch_start_address !== address_t'(encrypted_data_axi_mgr_rd_resp_tran_q[0].addr)) begin // check on the first AXI MGR entrypt data read address
        result = 0;
        `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [Entrypted Data] starting address for encrypted data for Entry[%0s]. exp['h%0h], act['h%0h]",
                                        m_sinc_sb_pkt_entry.name(), encrypted_data_axi_mgr_rd_resp_tran_q[0].addr, block_fetch_start_address), UVM_HIGH)
        return (result);
      end

      // - check on data
      begin
        // byte m_block_fetch_encrypted_data_in_bytes[];
        string str; // debug string
        int indx=0;
        csd_cache_block_t exp_cache_block; // result of AES model

        csd_auth_tag_t exp_auth_tag;
        csd_auth_tag_t act_auth_tag;
        str = "\n ****************************************** \n";

        // check critical path from AXI Stub to AXI MGR Read
        m_block_fetch_encrypted_data_in_bytes = new[exp_encrypted_data_bytes];
        void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(block_fetch_start_address, m_block_fetch_encrypted_data_in_bytes));
        // for debug
        str = {str, $sformatf(" Print Encrypted data in bytes total[%0d]-[%0d], block_fetch_start_address['h%0h]: \n", exp_encrypted_data_bytes, m_block_fetch_encrypted_data_in_bytes.size(), block_fetch_start_address)};
        for (int i=0; i < exp_encrypted_data_bytes; i++) begin
          str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_encrypted_data_in_bytes[i])};
        end

        // m_block_fetch_auth_tag_in_bytes = new[exp_auth_tag_bytes];
        // void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(auth_tag_fetch_start_address, m_block_fetch_auth_tag_in_bytes));
        // str = {str, $sformatf(" Print Auth Tag in bytes total[%0d]-[%0d] \n", exp_auth_tag_bytes, act_auth_tag_bytes)};
        // for (int i=0; i < exp_auth_tag_bytes; i++) begin
        //   str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_auth_tag_in_bytes[i])};
        // end
        `uvm_info(report_str, str, UVM_DEBUG)
        str  = "\n ****************************************** \n";
        str  = {str, $sformatf(" Print AXI MGR read data in bytes total[%0d]: \n", act_encrypted_data_bytes)};
        indx = 0;
        for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
          for (int j=0; j < m_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
            str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_axi_mgr_rd_resp_tran_q[i].data[j])};
            indx++;
          end
        end
        `uvm_info(report_str, str, UVM_DEBUG)

        indx = 0;
        for (int i=0; i < encrypted_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
          for (int j=0; j < encrypted_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
            str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j])};
            if (encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_block_fetch_encrypted_data_in_bytes[indx]) begin
              `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                                              indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j], m_block_fetch_encrypted_data_in_bytes[indx]), UVM_HIGH)
              result = 0;
              return (result);
            end
            indx++;
          end
        end

        // check critical path from AXI Stub to CPU Read, by decrypt encrypted data
        begin // check auth tag
          int word_sel               = int'(m_cpu_addr % sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET);
          int little_endian_word_sel = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4) - word_sel - 1;
          int words_in_total         = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4);
          // use m_block_fetch_encrypted_data_in_bytes, sys_cfg's sys_active_key(monitored key), tlb's iv
          // Use monitored value instead of aes_cfg's, cross check & incase the preload is not done intentionally
          // create AES packet's object m_aes_obj

          // prepare m_aes_obj
          m_aes_obj.m_aes_op   = sinc_parameters_pkg::DECRYPT;
          m_aes_obj.m_key_data = m_top_configuration.m_sys_cfg.m_sys_active_key;
          `uvm_info(report_str, $sformatf("Debug: sys_active_key with ['h%0h], aes_cfg.key['h%0h]",
                                          m_top_configuration.m_sys_cfg.m_sys_active_key, m_top_configuration.m_sys_cfg.m_aes_cfg.m_key_data), UVM_HIGH)
          // m_aes_obj.m_aes_iv_nonce_regs[0] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]; // reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
          m_aes_obj.m_aes_iv_nonce_regs[0] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
          `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_0: ['h%0h]",
                                          m_aes_obj.m_aes_iv_nonce_regs[0]), UVM_HIGH)
          // m_aes_obj.m_aes_iv_nonce_regs[1] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
          m_aes_obj.m_aes_iv_nonce_regs[1] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
          `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_1: ['h%0h]",
                                          m_aes_obj.m_aes_iv_nonce_regs[1]), UVM_HIGH)
          // m_aes_obj.m_aes_iv_nonce_regs[2] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
          m_aes_obj.m_aes_iv_nonce_regs[2] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
          `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_2: ['h%0h]",
                                          m_aes_obj.m_aes_iv_nonce_regs[2]), UVM_HIGH)
          m_aes_obj.m_byte_count   = 512;
          m_aes_obj.m_aes_message  = new[128];
          m_aes_obj.m_aes_mode     = sinc_parameters_pkg::GCM;
          m_aes_obj.m_aes_unit_sz  = sinc_parameters_pkg::BYTES_16;
          m_aes_obj.m_aes_key_len  = sinc_parameters_pkg::AES_256;
          m_aes_obj.m_aes_test_mode  = 0;
          m_aes_obj.m_block_encr_num = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);

          if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
            //this has endianess reversed from expectation, so using foreach loop below instead
            //m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);

            foreach (m_aes_obj.m_aes_message[i]) begin
              m_aes_obj.m_aes_message[i][0 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4)];
              m_aes_obj.m_aes_message[i][8 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 1];
              m_aes_obj.m_aes_message[i][16 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 2];
              m_aes_obj.m_aes_message[i][24 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 3];
            end
          end else begin
            m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);
          end

          m_aes_obj.construct_aes_item();
          m_aes_obj.cal_rslt_w_c_model();

          // exp_cache_block = csd_cache_block_t'(m_aes_obj.m_aes_result); // this cast fail with latest change
          exp_cache_block = csd_cache_block_t'(m_aes_obj.m_aes_message);
          //foreach (m_aes_obj.m_aes_result[i]) begin
          //  exp_cache_block[i*32 +:32] = m_aes_obj.m_aes_result[i];
          //end
          //tag is in m_aes_obj.m_aes_tag which is a reg_data_t[4]
          foreach (m_aes_obj.m_aes_tag[i]) begin
            exp_auth_tag[i*32 +: 32] = m_aes_obj.m_aes_tag[i];
            `uvm_info(get_name(), $sformatf("assign exp auth tag, i[%0d]. aes_tag['h%0h], exp_auth_tag['h%0h]",
                                            indx, m_aes_obj.m_aes_tag[i], exp_auth_tag), UVM_HIGH)

          end

          indx = 0;
          // m_block_fetch_auth_tag_in_bytes
          // for (int i=0; i < auth_tag_axi_mgr_rd_resp_tran_q.size(); i++) begin
          //   for (int j=0; j < auth_tag_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
          //     act_auth_tag[indx*8 +: 8] = auth_tag_axi_mgr_rd_resp_tran_q[i].data[j];
          //     `uvm_info(get_name(), $sformatf("assign auth tag, indx[%0d]. data['h%0h], act['h%0h]",
          //                                       indx, auth_tag_axi_mgr_rd_resp_tran_q[i].data[j], act_auth_tag), UVM_HIGH)
          //     indx++;
          //   end
          // end

          // `uvm_info(get_name(), $sformatf("Print auth tag. exp['h%0h], act['h%0h]",
          //                                   exp_auth_tag, act_auth_tag), UVM_HIGH)

          `uvm_info(report_str, $sformatf("print cpu_rd_resp for entry [%0s], m_cpu_rd_resp_tran_q.size[%0d], addr['h%0h], data['h%0h]", m_sinc_sb_pkt_entry.name(), m_cpu_rd_resp_tran_q.size(), m_cpu_rd_resp_tran_q[0].m_addr, m_cpu_rd_resp_tran_q[0].m_rdata), UVM_HIGH)

          if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
            // reverse the result data
            for (int i=0; i < words_in_total; i++) begin
              set_cache_block[i*32 +: 32] = exp_cache_block[(words_in_total - i - 1)*32 +: 32];
            end

            // // if (exp_cache_block[little_endian_word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
            // if (set_cache_block[word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
            //   result = 0;
            //   `uvm_info(get_name(), $sformatf("Found missmatch encrypted data for Entry[%0s]. exp['h%0h], act['h%0h], decrypted_block['h%0h], preloaded_cache_block['h%0h]",
            //                                       m_sinc_sb_pkt_entry.name(), exp_cache_block[word_sel*32 +: 32], m_cpu_rd_resp_tran_q[0].m_rdata, exp_cache_block, preloaded_cache_block), UVM_HIGH)

            //   return (result);
            // end
          end else begin
            set_cache_block = exp_cache_block;
            if (exp_cache_block[word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
              result = 0;
              `uvm_info(get_name(), $sformatf("Found missmatch encrypted data for Entry[%0s]. exp['h%0h], act['h%0h], decrypted_block['h%0h], preloaded_cache_block['h%0h]",
                                              m_sinc_sb_pkt_entry.name(), exp_cache_block[word_sel*32 +: 32], m_cpu_rd_resp_tran_q[0].m_rdata, exp_cache_block, preloaded_cache_block), UVM_HIGH)

              return (result);
            end
          end

          // if (exp_auth_tag !== act_auth_tag) begin
          //   result = 0;
          //   `uvm_info(get_name(), $sformatf("Found missmatch auth tag for Entry[%0s]. exp['h%0h], act['h%0h]",
          //                                     m_sinc_sb_pkt_entry.name(), exp_auth_tag, act_auth_tag), UVM_HIGH)

          //   return (result);
          // end
        end
      end // begin // check auth tag
      // update cache line
      if(!m_top_configuration.m_csd.update_cache_block(csd_address_t'(m_cpu_addr), set_cache_block)) begin
        `uvm_error(report_str, $sformatf("Fail to update cache line with m_CPU_ADDR['h%0h]", m_cpu_addr))
      end

      return (result);
    end
  end // if (m_is_auth_tag_check_disabled)

  // if expectation is 0, then skip the rest of check
  if (m_exp_axi_mgr_rd_size == 0) begin
    return (1);
  end

  // check on operation
  if (result) begin
    case (m_sinc_sb_pkt_entry)
      sinc_env_pkg::ENTRY_CPU_READ : begin
        pal_axi_xaction encrypted_data_axi_mgr_rd_resp_tran_q[$];
        pal_axi_xaction auth_tag_axi_mgr_rd_resp_tran_q[$];
        int exp_encrypted_data_bytes = sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8;
        int exp_auth_tag_bytes       = sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8;
        int act_encrypted_data_bytes = 0;
        int act_auth_tag_bytes       = 0;
        int data_size_byte_cnt       = 0;
        // digest the read transactions to encrypted data and auth tag region
        for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
          data_size_byte_cnt += m_axi_mgr_rd_resp_tran_q[i].data.size();
          if (data_size_byte_cnt <= exp_encrypted_data_bytes) begin
            encrypted_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
            act_encrypted_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
          end else begin
            auth_tag_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
            act_auth_tag_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
          end
        end

        // block fetch when cache miss
        if (!m_is_cache_hit) begin
          int cache_block_idx;
          csd_cache_block_t preloaded_cache_block;
          address_t block_fetch_start_address;
          address_t auth_tag_fetch_start_address;
          csd_cache_block_t set_cache_block; // used to update CSD

          // check on encrypted data fetch
          // - check on data size
          if (act_encrypted_data_bytes !== exp_encrypted_data_bytes) begin
            result = 0;
            `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of encrypted data for Entry[%0s]. exp[%0d], act[%0d]",
                m_sinc_sb_pkt_entry.name(), exp_encrypted_data_bytes, act_encrypted_data_bytes), UVM_HIGH)

            return (result);
          end
          // - check on starting address
          cache_block_idx              = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
          preloaded_cache_block        = m_top_configuration.m_sys_cfg.m_csd.m_cache_blocks[cache_block_idx];
          block_fetch_start_address    = m_snapshot_ext_block_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_BLOCK_OFFSET);
          auth_tag_fetch_start_address = m_snapshot_ext_auth_tag_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_AUTH_TAG_OFFSET);

          if (block_fetch_start_address !== address_t'(encrypted_data_axi_mgr_rd_resp_tran_q[0].addr)) begin // check on the first AXI MGR entrypt data read address
            result = 0;
            `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [Entrypted Data] starting address for encrypted data for Entry[%0s]. exp['h%0h], act['h%0h]",
                m_sinc_sb_pkt_entry.name(), encrypted_data_axi_mgr_rd_resp_tran_q[0].addr, block_fetch_start_address), UVM_HIGH)
            return (result);
          end

          if (auth_tag_fetch_start_address !== address_t'(auth_tag_axi_mgr_rd_resp_tran_q[0].addr)) begin // check on the first AXI MGR auth tag read address
            result = 0;
            `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [Auth Tag] starting address for encrypted data for Entry[%0s]. exp['h%0h], act['h%0h]",
                m_sinc_sb_pkt_entry.name(), auth_tag_axi_mgr_rd_resp_tran_q[0].addr, auth_tag_fetch_start_address), UVM_HIGH)
            return (result);
          end
          // - check on data
          begin
            // byte m_block_fetch_encrypted_data_in_bytes[];
            string str; // debug string
            int indx=0;
            csd_cache_block_t exp_cache_block; // result of AES model

            csd_auth_tag_t exp_auth_tag;
            csd_auth_tag_t act_auth_tag;
            str = "\n ****************************************** \n";

            // check critical path from AXI Stub to AXI MGR Read
            m_block_fetch_encrypted_data_in_bytes = new[exp_encrypted_data_bytes];
            void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(block_fetch_start_address, m_block_fetch_encrypted_data_in_bytes));
            // for debug
            str = {str, $sformatf(" Print Encrypted data in bytes total[%0d]-[%0d], block_fetch_start_address['h%0h]: \n", exp_encrypted_data_bytes, m_block_fetch_encrypted_data_in_bytes.size(), block_fetch_start_address)};
            for (int i=0; i < exp_encrypted_data_bytes; i++) begin
              str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_encrypted_data_in_bytes[i])};
            end

            m_block_fetch_auth_tag_in_bytes = new[exp_auth_tag_bytes];
            void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(auth_tag_fetch_start_address, m_block_fetch_auth_tag_in_bytes));
            str = {str, $sformatf(" Print Auth Tag in bytes total[%0d]-[%0d] \n", exp_auth_tag_bytes, act_auth_tag_bytes)};
            for (int i=0; i < exp_auth_tag_bytes; i++) begin
              str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_auth_tag_in_bytes[i])};
            end
            `uvm_info(report_str, str, UVM_DEBUG)
            str  = "\n ****************************************** \n";
            str  = {str, $sformatf(" Print AXI MGR read data in bytes total[%0d]: \n", act_encrypted_data_bytes)};
            indx = 0;
            for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
              for (int j=0; j < m_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_axi_mgr_rd_resp_tran_q[i].data[j])};
                indx++;
              end
            end
            `uvm_info(report_str, str, UVM_DEBUG)

            indx = 0;
            for (int i=0; i < encrypted_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
              for (int j=0; j < encrypted_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                if (encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_block_fetch_encrypted_data_in_bytes[indx]) begin
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                      indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j], m_block_fetch_encrypted_data_in_bytes[indx]), UVM_HIGH)
                  result = 0;
                  return (result);
                end
                indx++;
              end
            end

            // check critical path from AXI Stub to CPU Read, by decrypt encrypted data
            begin // check auth tag
              int word_sel               = int'(m_cpu_addr % sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET);
              int little_endian_word_sel = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4) - word_sel - 1;
              int words_in_total         = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4);
              // use m_block_fetch_encrypted_data_in_bytes, sys_cfg's sys_active_key(monitored key), tlb's iv
              // Use monitored value instead of aes_cfg's, cross check & incase the preload is not done intentionally
              // create AES packet's object m_aes_obj

              // prepare m_aes_obj
              m_aes_obj.m_aes_op   = sinc_parameters_pkg::DECRYPT;
              m_aes_obj.m_key_data = m_top_configuration.m_sys_cfg.m_sys_active_key;
              `uvm_info(report_str, $sformatf("Debug: sys_active_key with ['h%0h], aes_cfg.key['h%0h]",
              m_top_configuration.m_sys_cfg.m_sys_active_key, m_top_configuration.m_sys_cfg.m_aes_cfg.m_key_data), UVM_HIGH)
              // m_aes_obj.m_aes_iv_nonce_regs[0] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]; // reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
              m_aes_obj.m_aes_iv_nonce_regs[0] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
              `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_0: ['h%0h]",
                  m_aes_obj.m_aes_iv_nonce_regs[0]), UVM_HIGH)
              // m_aes_obj.m_aes_iv_nonce_regs[1] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
              m_aes_obj.m_aes_iv_nonce_regs[1] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
              `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_1: ['h%0h]",
                  m_aes_obj.m_aes_iv_nonce_regs[1]), UVM_HIGH)
              // m_aes_obj.m_aes_iv_nonce_regs[2] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
              m_aes_obj.m_aes_iv_nonce_regs[2] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
              `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_2: ['h%0h]",
                  m_aes_obj.m_aes_iv_nonce_regs[2]), UVM_HIGH)
              m_aes_obj.m_byte_count   = 512;
              m_aes_obj.m_aes_message  = new[128];
              m_aes_obj.m_aes_mode     = sinc_parameters_pkg::GCM;
              m_aes_obj.m_aes_unit_sz  = sinc_parameters_pkg::BYTES_16;
              m_aes_obj.m_aes_key_len  = sinc_parameters_pkg::AES_256;
              m_aes_obj.m_aes_test_mode  = 0;
              m_aes_obj.m_block_encr_num = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);

              if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
                //this has endianess reversed from expectation, so using foreach loop below instead
                //m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);

                foreach (m_aes_obj.m_aes_message[i]) begin
                  m_aes_obj.m_aes_message[i][0 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4)];
                  m_aes_obj.m_aes_message[i][8 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 1];
                  m_aes_obj.m_aes_message[i][16 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 2];
                  m_aes_obj.m_aes_message[i][24 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 3];
                end
              end else begin
                m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);
              end

              m_aes_obj.construct_aes_item();
              m_aes_obj.cal_rslt_w_c_model();

              exp_cache_block = csd_cache_block_t'(m_aes_obj.m_aes_result); // this cast fail with latest change
              //foreach (m_aes_obj.m_aes_result[i]) begin
              //  exp_cache_block[i*32 +:32] = m_aes_obj.m_aes_result[i];
              //end
              //tag is in m_aes_obj.m_aes_tag which is a reg_data_t[4]
              foreach (m_aes_obj.m_aes_tag[i]) begin
                exp_auth_tag[i*32 +: 32] = m_aes_obj.m_aes_tag[i];
                `uvm_info(get_name(), $sformatf("assign exp auth tag, i[%0d]. aes_tag['h%0h], exp_auth_tag['h%0h]",
                    indx, m_aes_obj.m_aes_tag[i], exp_auth_tag), UVM_HIGH)

              end

              indx = 0;
              // m_block_fetch_auth_tag_in_bytes
              for (int i=0; i < auth_tag_axi_mgr_rd_resp_tran_q.size(); i++) begin
                for (int j=0; j < auth_tag_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                  act_auth_tag[indx*8 +: 8] = auth_tag_axi_mgr_rd_resp_tran_q[i].data[j];
                  `uvm_info(get_name(), $sformatf("assign auth tag, indx[%0d]. data['h%0h], act['h%0h]",
                      indx, auth_tag_axi_mgr_rd_resp_tran_q[i].data[j], act_auth_tag), UVM_HIGH)
                  indx++;
                end
              end

              `uvm_info(get_name(), $sformatf("Print auth tag. exp['h%0h], act['h%0h]",
                  exp_auth_tag, act_auth_tag), UVM_HIGH)

              `uvm_info(report_str, $sformatf("print cpu_rd_resp for entry [%0s], m_cpu_rd_resp_tran_q.size[%0d], addr['h%0h], data['h%0h]", m_sinc_sb_pkt_entry.name(), m_cpu_rd_resp_tran_q.size(), m_cpu_rd_resp_tran_q[0].m_addr, m_cpu_rd_resp_tran_q[0].m_rdata), UVM_HIGH)

              if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
                // reverse the result data
                for (int i=0; i < words_in_total; i++) begin
                  set_cache_block[i*32 +: 32] = exp_cache_block[(words_in_total - i - 1)*32 +: 32];
                end

                // if (exp_cache_block[little_endian_word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
                if (set_cache_block[word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch encrypted data for Entry[%0s]. exp['h%0h], act['h%0h], decrypted_block['h%0h], preloaded_cache_block['h%0h]",
                      m_sinc_sb_pkt_entry.name(), exp_cache_block[word_sel*32 +: 32], m_cpu_rd_resp_tran_q[0].m_rdata, exp_cache_block, preloaded_cache_block), UVM_HIGH)

                  return (result);
                end
              end else begin
                set_cache_block = exp_cache_block;
                if (exp_cache_block[word_sel*32 +: 32] !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch encrypted data for Entry[%0s]. exp['h%0h], act['h%0h], decrypted_block['h%0h], preloaded_cache_block['h%0h]",
                      m_sinc_sb_pkt_entry.name(), exp_cache_block[word_sel*32 +: 32], m_cpu_rd_resp_tran_q[0].m_rdata, exp_cache_block, preloaded_cache_block), UVM_HIGH)

                  return (result);
                end
              end

              if (exp_auth_tag !== act_auth_tag) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch auth tag for Entry[%0s]. exp['h%0h], act['h%0h]",
                    m_sinc_sb_pkt_entry.name(), exp_auth_tag, act_auth_tag), UVM_HIGH)

                return (result);
              end
            end
          end // begin // check auth tag

          // update cache line
          if(!m_top_configuration.m_csd.update_cache_block(csd_address_t'(m_cpu_addr), set_cache_block)) begin
            `uvm_error(report_str, $sformatf("Fail to update cache line with m_CPU_ADDR['h%0h]", m_cpu_addr))
          end
        end // if (!m_is_cache_hit)
      end

      sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
        pal_axi_xaction rng_data_axi_mgr_rd_resp_tran_q[$];
        pal_axi_xaction key_data_axi_mgr_rd_resp_tran_q[$];
        int data_size_byte_cnt = 0;
        int act_rng_data_bytes;
        int act_key_data_bytes;
        int exp_rng_data_bytes = sinc_parameters_pkg::SINC_RNG_SEED_IN_BITS / 8;
        int exp_key_data_bytes = sinc_parameters_pkg::SINC_KEY_IN_BITS / 8;

        int indx=0;
        string str; // debug string
        str = "\n ****************************************** \n";

        if (m_is_fw_cmd) begin
          case (m_fw_cmd)
            sinc_parameters_pkg::SINC_SINC_RESET : begin
              if (m_axi_mgr_rd_resp_tran_q.size()) begin
                return (0);
              end else begin
                return (1);
              end
            end
            sinc_parameters_pkg::SINC_SINC_REINIT : begin
              if (m_axi_mgr_rd_resp_tran_q.size()) begin
                return (0);
              end else begin
                return (1);
              end
            end
            sinc_parameters_pkg::SINC_SET_INIT_STATE : begin
              int indx                          = 0;
              address_t rng_fetch_start_address = sinc_parameters_pkg::SINC_RNG_START_ADDR;
              address_t key_fetch_start_address = sinc_parameters_pkg::SINC_KSU_START_ADDR + (int'(m_snapshot_block_encr_key) * sinc_parameters_pkg::SINC_KSU_KEY_PADDING_SIZE);
              m_rng_fetch_data_in_bytes         = new[exp_rng_data_bytes];
              m_key_fetch_data_in_bytes         = new[exp_key_data_bytes];

              `uvm_info(get_name(), $sformatf("Entry[%0s]: is_rng_fetched[%0d], is_key_fetched[%0d]",
                  m_sinc_sb_pkt_entry.name(), m_top_configuration.m_sys_cfg.m_is_rng_fetched, m_top_configuration.m_sys_cfg.m_is_key_fetched), UVM_HIGH)
              // when both RNG and KEY have been fetched, there should not be AXI MGR reads in SET_INIT_STATE CMD
              if (m_top_configuration.m_sys_cfg.m_is_rng_fetched && m_top_configuration.m_sys_cfg.m_is_key_fetched) begin
                if (m_axi_mgr_rd_resp_tran_q.size()) begin
                  return (0);
                end else begin
                  return (1);
                end
              end
              // digest the read transactions to RNG and KEY
              for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
                data_size_byte_cnt += m_axi_mgr_rd_resp_tran_q[i].data.size();
                // put to RNG Q if RNG fetch needed
                // SINC_NO_SEED_LOADING bypasses the DRBG seed read in SET_INIT (MAS 14.2)
                if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING &&
                    !m_top_configuration.m_sys_cfg.m_is_rng_fetched) begin
                  if (act_rng_data_bytes < (sinc_parameters_pkg::SINC_RNG_SEED_IN_BITS / 8)) begin
                    rng_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
                    act_rng_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
                    continue;
                  end
                end

                // put to KEY Q if KEY fetch needed
                if (!m_top_configuration.m_sys_cfg.m_is_key_fetched) begin
                  if (act_key_data_bytes < (sinc_parameters_pkg::SINC_KEY_IN_BITS / 8)) begin
                    key_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
                    act_key_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
                  end
                end
              end

              // check on RNG data size, start address
              // SINC_NO_SEED_LOADING bypasses the DRBG seed read in SET_INIT (MAS 14.2)
              if (!sinc_parameters_pkg::SINC_NO_SEED_LOADING &&
                  !m_top_configuration.m_sys_cfg.m_is_rng_fetched) begin
                if (act_rng_data_bytes !== exp_rng_data_bytes) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of RNG data for Entry[%0s]. exp[%0d], act[%0d]",
                      m_sinc_sb_pkt_entry.name(), exp_rng_data_bytes, act_rng_data_bytes), UVM_HIGH)

                  return (result);
                end else begin
                  // for debug
                  indx= 0;
                  str = {str, $sformatf(" Print monitored RNG data in bytes total[%0d]\n", exp_rng_data_bytes)};
                  for (int i=0; i < rng_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                    for (int j=0; j < rng_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                      str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, rng_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                      indx++;
                    end
                  end
                  `uvm_info(report_str, str, UVM_HIGH)
                end

                if (rng_fetch_start_address !== address_t'(rng_data_axi_mgr_rd_resp_tran_q[0].addr)) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [RNG] starting address for RNG data for Entry[%0s]. exp['h%0h], act['h%0h]",
                      m_sinc_sb_pkt_entry.name(), rng_data_axi_mgr_rd_resp_tran_q[0].addr, rng_fetch_start_address), UVM_HIGH)
                  return (result);
                end

                void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(rng_fetch_start_address, m_rng_fetch_data_in_bytes));
                indx = 0;
                for (int i=0; i < rng_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                  for (int j=0; j < rng_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                    str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, rng_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                    if (rng_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_rng_fetch_data_in_bytes[indx]) begin
                      `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                          indx, rng_data_axi_mgr_rd_resp_tran_q[i].data[j], m_rng_fetch_data_in_bytes[indx]), UVM_HIGH)
                      result = 0;
                      return (result);
                    end
                    indx++;
                  end
                end
              end // if (!m_top_configuration.m_sys_cfg.m_is_rng_fetched)

              // check on KEY data size, start address
              // if (!m_top_configuration.m_sys_cfg.m_is_key_fetched) begin
              if (!m_snapshot_is_key_fetched) begin
                if (act_key_data_bytes !== exp_key_data_bytes) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of KEY data for Entry[%0s]. exp[%0d], act[%0d]",
                      m_sinc_sb_pkt_entry.name(), exp_key_data_bytes, act_key_data_bytes), UVM_HIGH)

                  return (result);
                end else begin
                  // for debug
                  indx= 0;
                  str = {str, $sformatf(" Print monitored KEY data in bytes total[%0d]\n", exp_key_data_bytes)};
                  for (int i=0; i < key_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                    for (int j=0; j < key_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                      str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, key_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                      indx++;
                    end
                  end
                  `uvm_info(report_str, str, UVM_HIGH)
                end

                if (key_fetch_start_address !== address_t'(key_data_axi_mgr_rd_resp_tran_q[0].addr)) begin
                  result = 0;
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [KEY] starting address for KEY data for Entry[%0s]. exp['h%0h], act['h%0h]",
                      m_sinc_sb_pkt_entry.name(), key_data_axi_mgr_rd_resp_tran_q[0].addr, key_fetch_start_address), UVM_HIGH)
                  return (result);
                end

                void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(key_fetch_start_address, m_key_fetch_data_in_bytes));
                indx = 0;
                for (int i=0; i < key_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                  for (int j=0; j < key_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                    str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, key_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                    if (key_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_key_fetch_data_in_bytes[indx]) begin
                      `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                          indx, key_data_axi_mgr_rd_resp_tran_q[i].data[j], m_key_fetch_data_in_bytes[indx]), UVM_HIGH)
                      result = 0;
                      return (result);
                    end
                    indx++;
                  end
                end

                indx= 0;
                for (int i=0; i < key_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                  for (int j=0; j < key_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                    m_top_configuration.m_sys_cfg.m_sys_active_key[indx*8 +:8] = key_data_axi_mgr_rd_resp_tran_q[i].data[j];
                    indx++;
                  end
                end

                `uvm_info(report_str, $sformatf("Update sys_active_key with ['h%0h], aes_cfg.key['h%0h]",
                    m_top_configuration.m_sys_cfg.m_sys_active_key, m_top_configuration.m_sys_cfg.m_aes_cfg.m_key_data), UVM_HIGH)

              end // if (!m_top_configuration.m_sys_cfg.m_is_key_fetched)
            end // case: sinc_parameters_pkg::SINC_SET_INIT_STATE

            sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
              // check on Sharedram AXI MGR reads
              int indx                                = 0;
              int block_num                           = 0;
              int exp_sharedram_fetch_bytes           = (sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
              address_t sharedram_fetch_start_address = m_snapshot_block_encr_addr;

              m_sharedram_fetch_data_in_bytes = new[exp_sharedram_fetch_bytes];
              m_encr_block_plaintxt_array     = new[m_snapshot_num_of_blocks];
              m_encr_block_encrypted_array    = new[m_snapshot_num_of_blocks];
              m_encry_block_auth_tag_array    = new[m_snapshot_num_of_blocks];
              // below are not used, can be remove after debug is done
              // act_encr_block_encrypted_array = new[m_snapshot_num_of_blocks];
              // act_encry_block_auth_tag_array = new[m_snapshot_num_of_blocks];

              for (int i=0; i < exp_sharedram_fetch_bytes; i++) begin
                m_sharedram_fetch_data_in_bytes[i] = m_act_sharedram_r_data[i];
              end

              // check data size
              if (m_act_sharedram_r_data.size() !== exp_sharedram_fetch_bytes) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of Sharedram data for Entry[%0s]. exp[%0d], act[%0d], block_encr_num[%0d], num_of_blocks[%0d]",
                    m_sinc_sb_pkt_entry.name(), exp_sharedram_fetch_bytes, m_act_sharedram_r_data.size(), m_snapshot_block_encr_num, m_snapshot_num_of_blocks), UVM_HIGH)

                return (result);
              end

              // check starting address
              // - check sharedram read starting address
              if (m_act_sharedram_data_axi_mgr_rd_resp_tran_q[0].addr !== sharedram_fetch_start_address) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [SHAREDRAM] starting address for Sharedram data for Entry[%0s]. exp['h%0h], act['h%0h], m_snapshot_sharedram_base['h%0h], m_snapshot_block_encr_num[%0d]",
                    m_sinc_sb_pkt_entry.name(), sharedram_fetch_start_address, m_act_sharedram_data_axi_mgr_rd_resp_tran_q[0].addr, m_snapshot_sharedram_base, m_snapshot_block_encr_num), UVM_HIGH)
                return (result);
              end

              // check backdoor data (this also prove the AXI MGR address issued are continous address)
              // - check sharedram
              void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(sharedram_fetch_start_address, m_sharedram_fetch_data_in_bytes));
              indx = 0;
              for (int i=0; i < m_act_sharedram_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
                for (int j=0; j < m_act_sharedram_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
                  str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_act_sharedram_data_axi_mgr_rd_resp_tran_q[i].data[j])};
                  if (m_act_sharedram_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_sharedram_fetch_data_in_bytes[indx]) begin
                    `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                        indx, m_act_sharedram_data_axi_mgr_rd_resp_tran_q[i].data[j], m_sharedram_fetch_data_in_bytes[indx]), UVM_HIGH)
                    result = 0;
                    return (result);
                  end
                  indx++;
                end
              end

              // Prepare AES Model expectation for each block encryption to check with AXI MGR writes
              // prepare encrypted data and authentication tag for comparison
              for (int block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin
                csd_cache_block_t cache_block_plaintxt; // plaintxt in big-endian
                int byte_start_sel = (block_indx * sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE);
                block_num          = block_indx + m_snapshot_block_encr_num;
                for (int i=0; i < (sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE); i++) begin
                  cache_block_plaintxt[i*8 +: 8] = m_sharedram_fetch_data_in_bytes[i + byte_start_sel];
                end
                m_encr_block_plaintxt_array[block_indx] = cache_block_plaintxt;
                `uvm_info(get_name(), $sformatf("ENCR_BLOCK: block[%0d], plaintxt['h%0h]",
                    block_num, m_encr_block_plaintxt_array[block_indx]), UVM_HIGH)

                m_aes_obj.m_byte_count   = 512;
                m_aes_obj.m_aes_message  = new[128];
                m_aes_obj.m_aes_op       = sinc_parameters_pkg::ENCRYPT;
                m_aes_obj.m_aes_mode     = sinc_parameters_pkg::GCM;
                m_aes_obj.m_aes_unit_sz  = sinc_parameters_pkg::BYTES_16;
                m_aes_obj.m_aes_key_len  = sinc_parameters_pkg::AES_256;
                //m_aes_obj.m_aes_message = reg_data_array_t'(cache_block_plaintxt);
                m_aes_obj.m_aes_test_mode  = 0;
                m_aes_obj.m_block_encr_num = block_num;
                m_aes_obj.m_key_data     = m_top_configuration.m_sys_cfg.m_sys_active_key;
                `uvm_info(report_str, $sformatf("Debug: sys_active_key with ['h%0h], aes_cfg.key['h%0h]",
                    m_top_configuration.m_sys_cfg.m_sys_active_key, m_top_configuration.m_sys_cfg.m_aes_cfg.m_key_data), UVM_HIGH)
                // m_aes_obj.m_aes_iv_nonce_regs[0] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]; // reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
                m_aes_obj.m_aes_iv_nonce_regs[0] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
                `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_0: ['h%0h]",
                    m_aes_obj.m_aes_iv_nonce_regs[0]), UVM_HIGH)
                // m_aes_obj.m_aes_iv_nonce_regs[1] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
                m_aes_obj.m_aes_iv_nonce_regs[1] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
                `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_1: ['h%0h]",
                    m_aes_obj.m_aes_iv_nonce_regs[1]), UVM_HIGH)
                // m_aes_obj.m_aes_iv_nonce_regs[2] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
                m_aes_obj.m_aes_iv_nonce_regs[2] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
                `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_2: ['h%0h]",
                    m_aes_obj.m_aes_iv_nonce_regs[2]), UVM_HIGH)

                `uvm_info(get_name(), $sformatf("cache_block_plaintxt byte: ['h%0h]",
                    cache_block_plaintxt), UVM_LOW)

                //get ciphertext from m_aes_result
                for (int word_index = 0; word_index < 128; word_index++) begin
                  m_aes_obj.m_aes_message[word_index] = cache_block_plaintxt[word_index*32 +: 32];
                end

                //foreach(m_sys_cfg.m_aes_cfg.m_aes_message[i]) begin
                //  `uvm_info(get_name(), $sformatf("debug: m_aes_message[%0d] is 'h%0h",i,m_sys_cfg.m_aes_cfg.m_aes_message[i]), UVM_LOW)
                //end

                m_aes_obj.construct_aes_item();
                //m_sys_cfg.m_aes_cfg.print_packet();
                m_aes_obj.cal_rslt_w_c_model();

                //get ciphertext from m_aes_result
                for (int word_index = 0; word_index < 128; word_index++) begin
                  m_encr_block_encrypted_array[block_indx][word_index*32 +: 32] = m_aes_obj.m_aes_result[word_index];
                end

                //get tag from m_aes_tag
                for (int word_index = 0; word_index < 4; word_index++) begin
                  m_encry_block_auth_tag_array[block_indx][word_index*32 +: 32] = m_aes_obj.m_aes_tag[word_index];
                end

                // m_encr_block_encrypted_array[block_indx] = convert to csd_cache_block_t with m_aes_obj.rslt_of_encrypted_data;
                // m_encry_block_auth_tag_array[block_indx] = convert to csd_auth_tag_t with m_aes_obj.rslt_of_auth_tag;
              end // for (block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin

            end // sinc_parameters_pkg::SINC_SET_INIT_STATE

            default: `uvm_error(report_str, $sformatf("not implemented scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
          endcase // case (m_fw_cmd)

        end // if (m_is_fw_cmd)
      end // case: sinc_env_pkg::ENTRY_AXI_SUB_WRITE
      default: `uvm_error(report_str, $sformatf("check on unexpected scoreboard entry to check AXI MGR Read[%0s]", m_sinc_sb_pkt_entry.name()))
    endcase // case (m_sinc_sb_pkt_entry)
  end // if (result)

  `uvm_info("Report on IS_AXI_MGR_RD_REQ_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_axi_mgr_rd_req_match_exp

// FUNCTION: is_axi_mgr_wr_req_match_exp
function bit sinc_sb_pkt_item::is_axi_mgr_wr_req_match_exp();
  string report_str = "is_axi_mgr_wr_req_match_exp:\n";
  int    result     = 1;

  // if expectation is 0, then skip the rest of check
  if (m_exp_axi_mgr_wr_size == 0) begin
    return (1);
  end

  // when set encr_block is disabled
  if (m_top_configuration.m_sinc_vif.disable_encr_auth_check &&
      m_is_fw_cmd &&
      (m_fw_cmd == sinc_parameters_pkg::SINC_ENCR_BLOCK) &&
      !m_is_fw_op_fail) begin
    if (m_exp_axi_mgr_wr_size == m_act_axi_mgr_wr_size_received) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] expecting encr_block disabled, AXI MGR WR transfer data size (bytes): exp[%0d], recieved[%0d] \n",
                                          m_exp_axi_mgr_wr_size, m_act_axi_mgr_wr_size_received)};
      return (0);
    end else begin
      return (1);
    end
  end

  // skip check when observe errors
  if (m_is_fw_op_fail && (m_is_dmb_write_error || m_is_sharedram_rd_error)) begin
    return (1);
  end

  // check on total data transfer
  if (m_exp_axi_mgr_wr_size !== m_act_axi_mgr_wr_size_received) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] expecting AXI MGR WR transfer data size (bytes): exp[%0d], recieved[%0d] \n",
        m_exp_axi_mgr_wr_size, m_act_axi_mgr_wr_size_received)};
  end

  // check on operation
  if (result) begin
    case (m_sinc_sb_pkt_entry)
      sinc_env_pkg::ENTRY_CPU_READ : begin
        // CPU RD won't have axi_mgr_wr
      end

      sinc_env_pkg::ENTRY_AXI_SUB_WRITE : begin
        pal_axi_xaction rng_data_axi_mgr_rd_resp_tran_q[$];
        pal_axi_xaction key_data_axi_mgr_rd_resp_tran_q[$];
        int data_size_byte_cnt = 0;
        int act_rng_data_bytes;
        int act_key_data_bytes;
        int exp_rng_data_bytes = sinc_parameters_pkg::SINC_RNG_SEED_IN_BITS / 8;
        int exp_key_data_bytes = sinc_parameters_pkg::SINC_KEY_IN_BITS / 8;

        int indx=0;
        string str; // debug string
        str = "\n ****************************************** \n";

        if (m_is_fw_cmd) begin
          case (m_fw_cmd)
            sinc_parameters_pkg::SINC_SINC_RESET : begin
              // SINC_RESET won't have axi_mgr_wr
            end
            sinc_parameters_pkg::SINC_SINC_REINIT : begin
              // SINC_REINIT won't have axi_mgr_wr
            end
            sinc_parameters_pkg::SINC_SET_INIT_STATE : begin
              // SET_INIT won't have axi_mgr_wr
            end // case: sinc_parameters_pkg::SINC_SET_INIT_STATE

            sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
              // check on DMB AXI MGR writes
              int indx                                   = 0;
              int exp_dmb_encrypted_data_write_bytes     = (sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
              int exp_dmb_auth_tag_wrtie_bytes           = (sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8) * (int'(m_snapshot_num_of_blocks));
              address_t dmb_block_write_start_address    = m_snapshot_ext_block_base_addr + (int'(m_snapshot_block_encr_num) * sinc_parameters_pkg::SINC_CACHE_BLOCK_OFFSET);
              address_t dmb_auth_tag_write_start_address = m_snapshot_ext_auth_tag_base_addr + (int'(m_snapshot_block_encr_num) * sinc_parameters_pkg::SINC_CACHE_AUTH_TAG_OFFSET);

              m_dmb_encrypted_data_write_in_bytes = new[exp_dmb_encrypted_data_write_bytes];
              m_dmb_auth_tag_write_in_bytes       = new[exp_dmb_auth_tag_wrtie_bytes];

              for (int i=0; i < exp_dmb_encrypted_data_write_bytes; i++) begin
                m_dmb_encrypted_data_write_in_bytes[i] = m_act_dmb_block_w_data[i];
              end

              for (int i=0; i < exp_dmb_auth_tag_wrtie_bytes; i++) begin
                m_dmb_auth_tag_write_in_bytes[i] = m_act_dmb_auth_tag_w_data[i];
              end

              // check data size
              if (m_act_dmb_block_w_data.size() !== exp_dmb_encrypted_data_write_bytes) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of DMB Block writes for Entry[%0s]. exp[%0d], act[%0d], block_encr_num[%0d], num_of_blocks[%0d]",
                    m_sinc_sb_pkt_entry.name(), exp_dmb_encrypted_data_write_bytes, m_act_dmb_block_w_data.size(), m_snapshot_block_encr_num, m_snapshot_num_of_blocks), UVM_HIGH)

                return (result);
              end
              if (m_act_dmb_auth_tag_w_data.size() !== exp_dmb_auth_tag_wrtie_bytes) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of DMB Auth Tag writes for Entry[%0s]. exp[%0d], act[%0d], block_encr_num[%0d], num_of_blocks[%0d]",
                    m_sinc_sb_pkt_entry.name(), exp_dmb_auth_tag_wrtie_bytes, m_act_dmb_auth_tag_w_data.size(), m_snapshot_block_encr_num, m_snapshot_num_of_blocks), UVM_HIGH)

                return (result);
              end

              // check starting address
              // - check sharedram read starting address
              // - check dmb block write starting address
              if (m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[0].addr !== dmb_block_write_start_address) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR write [DRAM-block] starting address for DMB for Entry[%0s]. exp['h%0h], act['h%0h]",
                    m_sinc_sb_pkt_entry.name(), dmb_block_write_start_address, m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[0].addr), UVM_HIGH)
                return (result);
              end
              // - check dmb auth tag write starting address
              if (m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[0].addr !== dmb_auth_tag_write_start_address) begin
                result = 0;
                `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR write [DRAM-auth_tag] starting address for DMB for Entry[%0s]. exp['h%0h], act['h%0h]",
                    m_sinc_sb_pkt_entry.name(), dmb_auth_tag_write_start_address, m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[0].addr), UVM_HIGH)
                return (result);
              end

              // check backdoor data (this also prove the AXI MGR address issued are continous address)
              // - check DMB - block write
              void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(dmb_block_write_start_address, m_dmb_encrypted_data_write_in_bytes));
              indx = 0;
              for (int i=0; i < m_act_dmb_block_data_axi_mgr_wr_resp_tran_q.size(); i++) begin
                for (int j=0; j < m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[i].data.size(); j++) begin
                  str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[i].data[j])};
                  if (m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[i].data[j] !== m_dmb_encrypted_data_write_in_bytes[indx]) begin
                    `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                        indx, m_act_dmb_block_data_axi_mgr_wr_resp_tran_q[i].data[j], m_dmb_encrypted_data_write_in_bytes[indx]), UVM_HIGH)
                    result = 0;
                    return (result);
                  end
                  indx++;
                end
              end
              // - check DMB - auth tag write
              void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(dmb_auth_tag_write_start_address, m_dmb_auth_tag_write_in_bytes));
              indx = 0;
              for (int i=0; i < m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q.size(); i++) begin
                for (int j=0; j < m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[i].data.size(); j++) begin
                  str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[i].data[j])};
                  if (m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[i].data[j] !== m_dmb_auth_tag_write_in_bytes[indx]) begin
                    `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                        indx, m_act_dmb_auth_tag_data_axi_mgr_wr_resp_tran_q[i].data[j], m_dmb_auth_tag_write_in_bytes[indx]), UVM_HIGH)
                    result = 0;
                    return (result);
                  end
                  indx++;
                end
              end

              // check AXI MGR writes with AES Model expectation for each block encryption
              for (int block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin // check on encrypted data
                csd_cache_block_t cache_block_encrypted_data;
                // csd_auth_tag_t    auth_tag_data;
                int byte_start_sel = (block_indx * sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE);
                for (int i=0; i < (sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE); i++) begin
                  cache_block_encrypted_data[i*8 +: 8] = m_dmb_encrypted_data_write_in_bytes[i + byte_start_sel];
                end

                `uvm_info(get_name(), $sformatf("ENCR_BLOCK: block[%0d], encrypted_data['h%0h]",
                    block_indx + m_snapshot_block_encr_num, cache_block_encrypted_data), UVM_HIGH)

                if (cache_block_encrypted_data !== m_encr_block_encrypted_array[block_indx]) begin
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR write on Encrypted data. exp['h%0h], act['h%0h]",
                      m_encr_block_encrypted_array[block_indx], cache_block_encrypted_data), UVM_HIGH)
                  result = 0;
                  return (result);

                end
              end // for (block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin // check on encrypted data

              for (int block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin // check on auth tag
                csd_auth_tag_t cache_block_auth_tag_data;
                int byte_start_sel = (block_indx * sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_SIZE);
                for (int i=0; i < (sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_SIZE); i++) begin
                  cache_block_auth_tag_data[i*8 +: 8] = m_dmb_auth_tag_write_in_bytes[i + byte_start_sel];
                end
                `uvm_info(get_name(), $sformatf("ENCR_BLOCK: block[%0d], auth_tag_data['h%0h]",
                    block_indx + m_snapshot_block_encr_num, cache_block_auth_tag_data), UVM_HIGH)
                if (cache_block_auth_tag_data !== m_encry_block_auth_tag_array[block_indx]) begin
                  `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR write on Encrypted data. exp['h%0h], act['h%0h]",
                      m_encry_block_auth_tag_array[block_indx], cache_block_auth_tag_data), UVM_HIGH)
                  result = 0;
                  return (result);
                end
              end // for (block_indx=0; block_indx < m_snapshot_num_of_blocks; block_indx++) begin // check on auth tag

            end // sinc_parameters_pkg::SINC_SET_INIT_STATE

            default: `uvm_error(report_str, $sformatf("not implemented scoreboard entry[%0s]", m_sinc_sb_pkt_entry.name()))
          endcase // case (m_fw_cmd)

        end // if (m_is_fw_cmd)
      end // case: sinc_env_pkg::ENTRY_AXI_SUB_WRITE
      default: `uvm_error(report_str, $sformatf("check on unexpected scoreboard entry to check AXI MGR Read[%0s]", m_sinc_sb_pkt_entry.name()))
    endcase // case (m_sinc_sb_pkt_entry)
  end // if (result)

  `uvm_info("Report on IS_AXI_MGR_WR_REQ_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_axi_mgr_wr_req_match_exp

// FUNCTION: is_cpu_rd_resp_match_exp
function bit sinc_sb_pkt_item::is_cpu_rd_resp_match_exp();
  string report_str = "is_cpu_rd_resp_match_exp:\n";
  bit    result     = 1;

  // check on total data transfer
  if (m_cpu_rd_resp_tran_q.size() > 1) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] expecting 1 CPU read response, recieved[%0d] \n",
        m_cpu_rd_resp_tran_q.size())};
  end

  if (m_is_cpu_rd_err) begin
    if (!m_cpu_rd_resp_tran_q[0].m_rd_err) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] expecting RDERR(1), recieved[%0d] \n",
          m_cpu_rd_resp_tran_q[0].m_rd_err)};
    end
  end else begin
    if (m_cpu_rd_resp_tran_q[0].m_rd_err) begin
      result     = 0;
      report_str = {report_str, $sformatf("[Signature] expecting OKAY(0), recieved[%0d] \n",
          m_cpu_rd_resp_tran_q[0].m_rd_err)};

      // very corner case that erase start at response
      if (m_top_configuration.m_sinc_vif.sinc_start_erase) begin
        result     = 1;
        m_erase_during_req_inprogress = 1;
        m_is_cpu_rd_err               = 1;
        report_str = {report_str, $sformatf("[Signature removed] RDERR(1), recieved[%0d] \n",
                                            m_cpu_rd_resp_tran_q[0].m_rd_err)};
      end
    end
  end

  `uvm_info("Report on IS_CPU_RD_RESP_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_cpu_rd_resp_match_exp

// FUNCTION: is_cpu_rd_data_match_exp
function bit sinc_sb_pkt_item::is_cpu_rd_data_match_exp();
  string     report_str      = "is_cpu_rd_data_match_exp:\n";
  bit        result          = 1;
  // bit        is_cache_active = (m_top_configuration.m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE)? 1: 0;
  bit        is_cache_active = (m_cur_cache_state == CACHE_ACTIVE_STATE)? 1: 0;
  cpu_data_t exp_cpu_data;

  // for coverage
  if (!is_cache_active) begin
    if (m_cpu_req_p_tran.m_addr > 32'hFFFF) begin
      m_cpu_access_when_non_cache_active_to_high_addr_map = 1;
    end
  end

  if (!m_is_cpu_rd_err) begin
    if (!m_is_auth_tag_check_disabled) begin
      exp_cpu_data = m_top_configuration.m_sys_cfg.m_csd.get_cpu_word_data(csd_address_t'(m_cpu_req_p_tran.m_addr), is_cache_active);
      `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("Use CSD: expected data['h%0h], is_cache_active[%0d]", exp_cpu_data, is_cache_active), UVM_HIGH)
    end else begin
      int data_sel_idx;
      int exp_encrypted_data_bytes = sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8;
      int exp_auth_tag_bytes       = sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8;
      int act_encrypted_data_bytes = 0;
      int act_auth_tag_bytes       = 0;
      csd_cache_block_t preloaded_cache_block;
      address_t block_fetch_start_address;
      address_t auth_tag_fetch_start_address;
      pal_axi_xaction encrypted_data_axi_mgr_rd_resp_tran_q[$];
      pal_axi_xaction auth_tag_axi_mgr_rd_resp_tran_q[$];
      bit [7:0] byte_packed_encrypted_data[$];
      bit [31:0] word_encrypted_data;
      int data_size_byte_cnt = 0;
      int cnt                = 0;

      data_sel_idx = int'(m_cpu_addr[`SINC_CACHE_BLOCK_DATA_RANGESEL]);

      // digest the read transactions to encrypted data and auth tag region
      for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
        data_size_byte_cnt += m_axi_mgr_rd_resp_tran_q[i].data.size();
        if (data_size_byte_cnt <= exp_encrypted_data_bytes) begin
          encrypted_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
          act_encrypted_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
        end else begin
          auth_tag_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
          act_auth_tag_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
        end
      end

      for(int i=0; i < encrypted_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
        for (int j=0; j < encrypted_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
          byte_packed_encrypted_data.push_back(encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j]);
          `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("byte_packed_encrypted_data.push_back[%0d]: ['h%0h]", cnt, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j]), UVM_HIGH)
          cnt++;
        end
      end

      for (int i=data_sel_idx * 4; i < ((data_sel_idx * 4) + 4); i++) begin
        word_encrypted_data[(i%4)*8 +:8] = byte_packed_encrypted_data[i];
        `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("data_sel_idx[%0d], start_bit[%0d], sel[%0d] : data['h%0h]", data_sel_idx, i, i%4, byte_packed_encrypted_data[i]), UVM_HIGH)
      end

      exp_cpu_data = word_encrypted_data;

      `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("Use AXI MGR RD data: expected data['h%0h]", exp_cpu_data), UVM_HIGH)

    end
  end else begin
    exp_cpu_data = sinc_parameters_pkg::SINC_CPU_ERRDATA;
    `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("Use CPU_ERRDATA: expected data['h%0h]", exp_cpu_data), UVM_HIGH)
  end

  if (exp_cpu_data !== m_cpu_rd_resp_tran_q[0].m_rdata) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] CPU Read data missmatch, exp['h%0h], act['h%0h] \n",
        exp_cpu_data, m_cpu_rd_resp_tran_q[0].m_rdata)};
  end

  `uvm_info("Report on IS_CPU_RD_DATA_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_cpu_rd_data_match_exp

function void sinc_sb_pkt_item::set_exp_fw_aes_test_mode_en();
  string          report_str                           = "SET_EXP_FW_AES_TEST_MODE_EN";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  if (!is_allowed_fw_cmd_in_cur_cache_state) begin // reinit_disabled should not affect set_init_state_cmd
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;
    m_is_reg_write_discarded = 1;
  end else begin
    set_fw_in_progress();
    m_exp_sinc_done                                = 0;
    m_sinc_done_num                                = 0;
    // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
    m_top_configuration.m_sys_cfg.m_aes_test_mode_en = 1;
  end

  /*
   // 1. Check original state, whether transition is allowed
   if (m_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
   m_exp_sinc_done = 0;
   m_sinc_done_num = 0;
   // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
   m_top_configuration.m_sys_cfg.m_aes_test_mode_en = 1;
   end

   /*
   // 1. Check original state, whether transition is allowed
   if (m_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
   m_exp_sinc_done = 0;
   m_sinc_done_num = 0;
   // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
   m_top_configuration.m_sys_cfg.m_aes_test_mode_en = 1;
   end else begin
   // the set_aes_test_mode command will be discarded, resulting invalid command
   cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;

   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
   end else begin
   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
   end
   end
   */

endfunction : set_exp_fw_aes_test_mode_en

function void sinc_sb_pkt_item::set_exp_fw_aes_test_mode_disable();
  string          report_str          = "SET_EXP_FW_AES_TEST_MODE_DISABLE";
  uvm_reg         status_reg          = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  // 1. Check original state, whether transition is allowed
  if (m_cur_cache_state == sinc_parameters_pkg::CACHE_DISABLE_STATE) begin
    m_is_fw_cmd = 1;
    if (m_top_configuration.m_sys_cfg.m_aes_test_mode_en) begin
      m_exp_sinc_done = 1;
      m_sinc_done_num = 1;
      `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
    end else begin
      m_exp_sinc_done = 0;
      m_sinc_done_num = 0;
    end
    // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
    // below is moved to set_sys_mirror
    // m_top_configuration.m_sys_cfg.m_aes_test_mode_en = 0;
    // m_top_configuration.m_sys_cfg.m_aes_test_mode_done = 1;

  end else begin
    // the set_aes_test_mode command will be discarded, resulting invalid command
    m_is_fw_op_fail                                              = 1;
    m_exp_sinc_done                                              = 0;
    m_sinc_done_num                                              = 0;
    m_exp_sinc_error                                             = 1;
    m_sinc_error_num                                             = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end
  end

endfunction : set_exp_fw_aes_test_mode_disable

function void sinc_sb_pkt_item::set_exp_fw_disable_reset();
  string          report_str                           = "SET_EXP_FW_DISABLE_RESET";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  // if m_fw_op_invalid_due_to_adjacent_block_fetch, when AXI write response came late
  if (m_fw_op_invalid_due_to_adjacent_block_fetch &&
      m_exp_sinc_error &&
      m_sinc_error_q.size())  begin
    // prediction has already been set in function inject_sinc_error
    `uvm_info(report_str, $sformatf("prediction skipped when sinc_e-r-r seen on FW_OP[%0s]", m_fw_cmd), UVM_HIGH)
    return;
  end

  if (!is_allowed_fw_cmd_in_cur_cache_state) begin
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;
  end else begin
    set_fw_in_progress();
    // // DISABLE RESET command will set disable reset status bit
    // cur_status_reg_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_RANGE] = 'b1;

    // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    //   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    // end else begin
    //   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    // end
  end

endfunction : set_exp_fw_disable_reset

function void sinc_sb_pkt_item::set_exp_fw_disable_reinit();
  string          report_str                           = "SET_EXP_FW_DISABLE_REINIT";
  uvm_reg         status_reg                           = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data                  = sinc_reg_data_t'(status_reg.get_mirrored_value());
  bit             is_allowed_fw_cmd_in_cur_cache_state = m_top_configuration.m_sys_cfg.is_allowed_fw_cmd_in_cur_cache_state(m_fw_cmd);
  m_cur_cache_state = m_top_configuration.m_sys_cfg.m_cur_cache_state;

  if (!is_allowed_fw_cmd_in_cur_cache_state) begin
    m_is_fw_op_fail                                              = 1;
    cur_status_reg_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_RANGE] = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;

    if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
      `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    end else begin
      `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    end

    m_exp_sinc_done  = 0;
    m_sinc_done_num  = 0;
    m_exp_sinc_error = 1;
    m_sinc_error_num = 1;
  end else begin
    set_fw_in_progress();
    // // DISABLE REINIT command will set disable reinit status bit
    // cur_status_reg_data[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_RANGE] = 'b1;

    // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    //   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
    // end else begin
    //   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
    // end
  end

endfunction : set_exp_fw_disable_reinit

function void sinc_sb_pkt_item::set_exp_pkt_mpu_attr_rd();
  string report_str = "SB_PKT_MPU_ATTR_RD";

  m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];

  // nothing shall be expected on bus (transaction level)

  // set response
  m_exp_mpu_resp = 2'b00; // indicating OKAY

  // set expectation on read data
  m_exp_mpu_rd_data = m_mpu_cfg.mpu_attribs_comp_cfg.get_attributes(m_mpu_req_tran.m_addr);

endfunction : set_exp_pkt_mpu_attr_rd

function void sinc_sb_pkt_item::set_exp_pkt_mpu_status_rd();
  string report_str = "SB_PKT_MPU_STATUS_RD";

  m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];

  // nothing shall be expected on bus (transaction level)

  // set response
  m_exp_mpu_resp = 2'b00; // indicating OKAY

  // set expectation on read data
  m_exp_mpu_rd_data = ccpui_mpu_data_t'(m_mpu_cfg.mpu_reg_tlb.get_reg_by_name("mpu_status").get_mirrored_value());

endfunction : set_exp_pkt_mpu_status_rd

// FUNCTION: is_mpu_rd_match_exp
function bit sinc_sb_pkt_item::is_mpu_rd_match_exp();
  string report_str = "is_mpu_rd_match_exp:\n";
  bit    result     = 1;

  // check on response
  if (m_exp_mpu_resp !== m_mpu_req_tran.m_resp) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] expecting MPU RD response['b%0b], recieved['b%00b] \n",
        m_exp_mpu_resp, m_mpu_req_tran.m_resp)};
  end

  // check on data
  if (m_exp_mpu_rd_data !== m_mpu_req_tran.m_rdata) begin
    result     = 0;
    report_str = {report_str, $sformatf("[Signature] expecting MPU RD data['h%0h], recieved['h%0h] \n",
        m_exp_mpu_rd_data, m_mpu_req_tran.m_rdata)};
  end

  // waive the condition if there is a CPU access pending with MPU Violation, it indicate the MPU status read before CPU violation access set MPU violation register
  // only check if non blocking transaction is enabled
  if ((m_top_configuration.m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read) &&
      (m_exp_mpu_rd_data !== m_mpu_req_tran.m_rdata) &&
      (m_sinc_sb_pkt_entry == ENTRY_MPU_STATUS_READ)) begin
      if (m_has_pending_cpu_read_with_mpu_disallowed) begin
          result     = 1;
          report_str = {report_str, $sformatf("[Waived] data violation is waived due to m_has_pending_cpu_read_with_mpu_disallowed[%0d] \n",
        m_has_pending_cpu_read_with_mpu_disallowed)};
      end
  end

  `uvm_info("Report on IS_MPU_RD_MATCH_EXP", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);
endfunction : is_mpu_rd_match_exp

// FUNCTION: is_aes_test_mode_en_recently_toggled
function bit sinc_sb_pkt_item::is_aes_test_mode_en_recently_toggled();
  string report_str = "is_aes_test_mode_en_recently_toggled:\n";
  bit    result     = 0;
  time   cur_time   = $realtime;

  `uvm_info(report_str, $sformatf("aes_test_mode_en is recently toggled at [%0t]", m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled), UVM_HIGH)

  // check on response
  if (cur_time > m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled) begin
    int consumed_cycles = (cur_time - m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled) / (m_top_configuration.m_clk_env_config.m_hspclk_half_period * 2);
    if (consumed_cycles < 50) begin
      result = 1;
      `uvm_info(report_str, $sformatf("consumed_cycles[%0d]", consumed_cycles), UVM_HIGH)
    end
  end
  return (result);
endfunction : is_aes_test_mode_en_recently_toggled

// FUNCTION: is_cpu_rd_auth_tag_match
function bit sinc_sb_pkt_item::is_cpu_rd_auth_tag_match();
  string          report_str                               = "is_cpu_rd_auth_tag_match:\n";
  bit             result                                   = 1;
  pal_axi_xaction encrypted_data_axi_mgr_rd_resp_tran_q[$];
  pal_axi_xaction auth_tag_axi_mgr_rd_resp_tran_q[$];
  int             exp_encrypted_data_bytes                 = sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8;
  int             exp_auth_tag_bytes                       = sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8;
  int             act_encrypted_data_bytes                 = 0;
  int             act_auth_tag_bytes                       = 0;
  int             data_size_byte_cnt                       = 0;

  // digest the read transactions to encrypted data and auth tag region
  for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
    data_size_byte_cnt += m_axi_mgr_rd_resp_tran_q[i].data.size();
    if (data_size_byte_cnt <= exp_encrypted_data_bytes) begin
      encrypted_data_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
      act_encrypted_data_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
    end else begin
      auth_tag_axi_mgr_rd_resp_tran_q.push_back(m_axi_mgr_rd_resp_tran_q[i]);
      act_auth_tag_bytes += m_axi_mgr_rd_resp_tran_q[i].data.size();
    end
  end

  // block fetch when cache miss
  if (!m_is_cache_hit) begin
    int cache_block_idx;
    csd_cache_block_t preloaded_cache_block;
    address_t block_fetch_start_address;
    address_t auth_tag_fetch_start_address;
    csd_cache_block_t set_cache_block; // used to update CSD

    // check on encrypted data fetch
    // - check on data size
    if (act_encrypted_data_bytes !== exp_encrypted_data_bytes) begin
      result = 0;
      `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read size of encrypted data for Entry[%0s]. exp[%0d], act[%0d]",
          m_sinc_sb_pkt_entry.name(), exp_encrypted_data_bytes, act_encrypted_data_bytes), UVM_HIGH)

      return (result);
    end
    // - check on starting address
    cache_block_idx              = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
    preloaded_cache_block        = m_top_configuration.m_sys_cfg.m_csd.m_cache_blocks[cache_block_idx];
    block_fetch_start_address    = m_snapshot_ext_block_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_BLOCK_OFFSET);
    auth_tag_fetch_start_address = m_snapshot_ext_auth_tag_base_addr + (cache_block_idx * sinc_parameters_pkg::SINC_CACHE_AUTH_TAG_OFFSET);

    if (block_fetch_start_address !== address_t'(encrypted_data_axi_mgr_rd_resp_tran_q[0].addr)) begin // check on the first AXI MGR entrypt data read address
      result = 0;
      `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [Entrypted Data] starting address for encrypted data for Entry[%0s]. exp['h%0h], act['h%0h]",
          m_sinc_sb_pkt_entry.name(), encrypted_data_axi_mgr_rd_resp_tran_q[0].addr, block_fetch_start_address), UVM_HIGH)
      return (result);
    end

    if (auth_tag_fetch_start_address !== address_t'(auth_tag_axi_mgr_rd_resp_tran_q[0].addr)) begin // check on the first AXI MGR auth tag read address
      result = 0;
      `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read [Auth Tag] starting address for encrypted data for Entry[%0s]. exp['h%0h], act['h%0h]",
          m_sinc_sb_pkt_entry.name(), auth_tag_axi_mgr_rd_resp_tran_q[0].addr, auth_tag_fetch_start_address), UVM_HIGH)
      return (result);
    end
    // - check on data
    begin
      // byte m_block_fetch_encrypted_data_in_bytes[];
      string str; // debug string
      int indx=0;
      csd_cache_block_t exp_cache_block; // result of AES model

      csd_auth_tag_t exp_auth_tag;
      csd_auth_tag_t act_auth_tag;
      str = "\n ****************************************** \n";

      // check critical path from AXI Stub to AXI MGR Read
      m_block_fetch_encrypted_data_in_bytes = new[exp_encrypted_data_bytes];
      void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(block_fetch_start_address, m_block_fetch_encrypted_data_in_bytes));
      // for debug
      str = {str, $sformatf(" Print Encrypted data in bytes total[%0d]-[%0d], block_fetch_start_address['h%0h]: \n", exp_encrypted_data_bytes, m_block_fetch_encrypted_data_in_bytes.size(), block_fetch_start_address)};
      for (int i=0; i < exp_encrypted_data_bytes; i++) begin
        str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_encrypted_data_in_bytes[i])};
      end

      m_block_fetch_auth_tag_in_bytes = new[exp_auth_tag_bytes];
      void'(m_top_configuration.m_vseqr.m_tb_vseqr.peek_poke.read_mem_bytes(auth_tag_fetch_start_address, m_block_fetch_auth_tag_in_bytes));
      str = {str, $sformatf(" Print Auth Tag in bytes total[%0d]-[%0d] \n", exp_auth_tag_bytes, act_auth_tag_bytes)};
      for (int i=0; i < exp_auth_tag_bytes; i++) begin
        str = {str, $sformatf(" indx[%0d], ['h%0h] \n", i, m_block_fetch_auth_tag_in_bytes[i])};
      end
      `uvm_info(report_str, str, UVM_DEBUG)
      str  = "\n ****************************************** \n";
      str  = {str, $sformatf(" Print AXI MGR read data in bytes total[%0d]: \n", act_encrypted_data_bytes)};
      indx = 0;
      for (int i=0; i < m_axi_mgr_rd_resp_tran_q.size(); i++) begin
        for (int j=0; j < m_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
          str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, m_axi_mgr_rd_resp_tran_q[i].data[j])};
          indx++;
        end
      end
      `uvm_info(report_str, str, UVM_DEBUG)

      indx = 0;
      for (int i=0; i < encrypted_data_axi_mgr_rd_resp_tran_q.size(); i++) begin
        for (int j=0; j < encrypted_data_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
          str = {str, $sformatf(" indx[%0d], ['h%0h] \n", indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j])};
          if (encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j] !== m_block_fetch_encrypted_data_in_bytes[indx]) begin
            `uvm_info(get_name(), $sformatf("Found missmatch AXI MGR read with Actual AXI Stub memory indx[%0d]. exp['h%0h], act['h%0h]",
                indx, encrypted_data_axi_mgr_rd_resp_tran_q[i].data[j], m_block_fetch_encrypted_data_in_bytes[indx]), UVM_HIGH)
            result = 0;
            return (result);
          end
          indx++;
        end
      end

      // check critical path from AXI Stub to CPU Read, by decrypt encrypted data
      begin // check auth tag
        int word_sel               = int'(m_cpu_addr % sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET);
        int little_endian_word_sel = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4) - word_sel - 1;
        int words_in_total         = int'(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE / 4);
        // use m_block_fetch_encrypted_data_in_bytes, sys_cfg's sys_active_key(monitored key), tlb's iv
        // Use monitored value instead of aes_cfg's, cross check & incase the preload is not done intentionally
        // create AES packet's object m_aes_obj

        // prepare m_aes_obj
        m_aes_obj.m_aes_op   = sinc_parameters_pkg::DECRYPT;
        m_aes_obj.m_key_data = m_top_configuration.m_sys_cfg.m_sys_active_key;
        `uvm_info(report_str, $sformatf("Debug: sys_active_key with ['h%0h], aes_cfg.key['h%0h]",
            m_top_configuration.m_sys_cfg.m_sys_active_key, m_top_configuration.m_sys_cfg.m_aes_cfg.m_key_data), UVM_HIGH)
        // m_aes_obj.m_aes_iv_nonce_regs[0] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]; // reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
        m_aes_obj.m_aes_iv_nonce_regs[0] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_0").get_mirrored_value());
        `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_0: ['h%0h]",
            m_aes_obj.m_aes_iv_nonce_regs[0]), UVM_HIGH)
        // m_aes_obj.m_aes_iv_nonce_regs[1] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
        m_aes_obj.m_aes_iv_nonce_regs[1] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_1").get_mirrored_value());
        `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_1: ['h%0h]",
            m_aes_obj.m_aes_iv_nonce_regs[1]), UVM_HIGH)
        // m_aes_obj.m_aes_iv_nonce_regs[2] = m_top_configuration.m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]; //reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
        m_aes_obj.m_aes_iv_nonce_regs[2] = reg_data_t'(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("aes_iv_nonce_2").get_mirrored_value());
        `uvm_info(report_str, $sformatf("Debug: aes_iv_nonce_2: ['h%0h]",
            m_aes_obj.m_aes_iv_nonce_regs[2]), UVM_HIGH)
        m_aes_obj.m_byte_count   = 512;
        m_aes_obj.m_aes_message  = new[128];
        m_aes_obj.m_aes_mode     = sinc_parameters_pkg::GCM;
        m_aes_obj.m_aes_unit_sz  = sinc_parameters_pkg::BYTES_16;
        m_aes_obj.m_aes_key_len  = sinc_parameters_pkg::AES_256;
        m_aes_obj.m_aes_test_mode  = 0;
        m_aes_obj.m_block_encr_num = int'(m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);

        if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
          //this has endianess reversed from expectation, so using foreach loop below instead
          //m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);

          foreach (m_aes_obj.m_aes_message[i]) begin
            m_aes_obj.m_aes_message[i][0 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4)];
            m_aes_obj.m_aes_message[i][8 +: 8]  = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 1];
            m_aes_obj.m_aes_message[i][16 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 2];
            m_aes_obj.m_aes_message[i][24 +: 8] = m_block_fetch_encrypted_data_in_bytes[(i * 4) + 3];
          end
        end else begin
          m_aes_obj.m_aes_message = reg_data_array_t'(m_block_fetch_encrypted_data_in_bytes);
        end

        m_aes_obj.construct_aes_item();
        m_aes_obj.cal_rslt_w_c_model();

        exp_cache_block = csd_cache_block_t'(m_aes_obj.m_aes_result); // this cast fail with latest change
        //foreach (m_aes_obj.m_aes_result[i]) begin
        //  exp_cache_block[i*32 +:32] = m_aes_obj.m_aes_result[i];
        //end
        //tag is in m_aes_obj.m_aes_tag which is a reg_data_t[4]
        foreach (m_aes_obj.m_aes_tag[i]) begin
          exp_auth_tag[i*32 +: 32] = m_aes_obj.m_aes_tag[i];
          `uvm_info(get_name(), $sformatf("assign exp auth tag, i[%0d]. aes_tag['h%0h], exp_auth_tag['h%0h]",
              indx, m_aes_obj.m_aes_tag[i], exp_auth_tag), UVM_HIGH)

        end

        indx = 0;
        // m_block_fetch_auth_tag_in_bytes
        for (int i=0; i < auth_tag_axi_mgr_rd_resp_tran_q.size(); i++) begin
          for (int j=0; j < auth_tag_axi_mgr_rd_resp_tran_q[i].data.size(); j++) begin
            act_auth_tag[indx*8 +: 8] = auth_tag_axi_mgr_rd_resp_tran_q[i].data[j];
            `uvm_info(get_name(), $sformatf("assign auth tag, indx[%0d]. data['h%0h], act['h%0h]",
                indx, auth_tag_axi_mgr_rd_resp_tran_q[i].data[j], act_auth_tag), UVM_HIGH)
            indx++;
          end
        end

        `uvm_info(get_name(), $sformatf("Print auth tag. exp['h%0h], act['h%0h]",
            exp_auth_tag, act_auth_tag), UVM_HIGH)

        if (sinc_parameters_pkg::SINC_AES_LITTLE_ENDIAN) begin
          // reverse the result data
          for (int i=0; i < words_in_total; i++) begin
            set_cache_block[i*32 +: 32] = exp_cache_block[(words_in_total - i - 1)*32 +: 32];
          end

        end else begin
          set_cache_block = exp_cache_block;
        end

        if (exp_auth_tag !== act_auth_tag) begin
          result = 0;
          `uvm_info(get_name(), $sformatf("Found missmatch auth tag for Entry[%0s]. exp['h%0h], act['h%0h]",
              m_sinc_sb_pkt_entry.name(), exp_auth_tag, act_auth_tag), UVM_HIGH)

          return (result);
        end
      end
    end // begin // check auth tag
  end // if (!m_is_cache_hit)

  `uvm_info("Report on IS_CPU_RD_AUTH_TAG_MATCH", $sformatf("[%0d], %0s", result, report_str), UVM_HIGH)
  return (result);

endfunction : is_cpu_rd_auth_tag_match

// FUNCTION: set_cache_fail
function void sinc_sb_pkt_item::set_cache_fail();
  string          report_str          = "set_cache_fail:\n";
  uvm_reg         status_reg          = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
  sinc_reg_data_t clear_zero_data     = sinc_reg_data_t'(0);

  cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE]           = sinc_parameters_pkg::CACHE_FAIL_STATE;
  cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;

  if (m_is_fetch_block_fail) begin
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
    cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;
  end
  if (m_is_auth_tag_mismatch_error) begin
    cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_RANGE] = 'b1;
  end

  if (m_is_dmb_auth_tag_read_error) begin
    cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_RANGE] = 'b1;
  end

  if (m_is_dmb_encrypt_data_read_error || m_is_sharedram_rd_error) begin
    cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] = 'b1;
  end

  if (m_top_configuration.m_sinc_vif.sinc_err_erase_during_w_cache_block) begin
    cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_RANGE] = 'b1;
  end

  m_top_configuration.m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_FAIL_STATE;
  if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
  end else begin
    `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
  end

  // clear IV registers
  if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::AES_IV_NONCE_0_REG_NAME, clear_zero_data)) begin
    `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::AES_IV_NONCE_0_REG_NAME, clear_zero_data), UVM_HIGH)
  end else begin
    `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::AES_IV_NONCE_0_REG_NAME))
  end

  if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::AES_IV_NONCE_1_REG_NAME, clear_zero_data)) begin
    `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::AES_IV_NONCE_1_REG_NAME, clear_zero_data), UVM_HIGH)
  end else begin
    `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::AES_IV_NONCE_1_REG_NAME))
  end

  if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::AES_IV_NONCE_2_REG_NAME, clear_zero_data)) begin
    `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::AES_IV_NONCE_2_REG_NAME, clear_zero_data), UVM_HIGH)
  end else begin
    `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::AES_IV_NONCE_2_REG_NAME))
  end

  // flag if AXI MGR response is pending
  `uvm_info("Report on SET_CACHE_FAIL", $sformatf("m_axi_mgr_rd_req_tran_q.size[%0d], m_axi_mgr_rd_resp_tran_q.size[%0d], m_axi_mgr_wr_req_tran_q.size[%0d], m_axi_mgr_wr_resp_tran_q.size[%0d]",
                                                  m_axi_mgr_rd_req_tran_q.size(), m_axi_mgr_rd_resp_tran_q.size(), m_axi_mgr_wr_req_tran_q.size(), m_axi_mgr_wr_resp_tran_q.size()), UVM_HIGH)

  `uvm_info("Report on SET_CACHE_FAIL", $sformatf("[%0s], %0s", report_str, "success"), UVM_HIGH)
endfunction : set_cache_fail

// FUNCTION: set_fw_in_progress
function void sinc_sb_pkt_item::set_fw_in_progress();
  string          report_str          = "set_fw_in_progress:";
  uvm_reg         status_reg          = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
  sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());
  cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b1;
  m_is_fw_cmd                                                  = 1;
  m_exp_sinc_done                                              = 1;
  m_sinc_done_num                                              = 1;
  if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
    `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
  end else begin
    `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
  end
  `uvm_info(report_str, $sformatf("[%0s] set expectation: mem_transaction[%0d], sinc_done[%0d]", m_sinc_sb_pkt_entry.name(), m_cache_mem_transaction_num, m_sinc_done_num), UVM_LOW)
endfunction : set_fw_in_progress

// FUNCTION: update_tlb_when_op_finish
// call when self_check done or partially done(with success), perform system mirrored data structure update
function bit sinc_sb_pkt_item::update_tlb_when_op_finish();
  string report_str = "sb_pkt_item_update_tlb_when_op_finish";

  print_packet();

  if (m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_WRITE )begin
    if (m_req_dst == SINC_REG) begin
      uvm_reg cmd_reg                     = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME);
      uvm_reg status_reg                  = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME);
      sinc_reg_data_t cur_cmd_reg_data    = sinc_reg_data_t'(cmd_reg.get_mirrored_value());
      sinc_reg_data_t cur_status_reg_data = sinc_reg_data_t'(status_reg.get_mirrored_value());

      // clear CMD register when the FW command is complete/failed
      if (m_is_fw_cmd) begin
        cur_cmd_reg_data[`SINC_REGS_CMD_ENCR_BLOCK_RANGE]             = 0;
        cur_cmd_reg_data[`SINC_REGS_CMD_SINC_REINIT_RANGE]            = 0;
        cur_cmd_reg_data[`SINC_REGS_CMD_SINC_RESET_RANGE]             = 0;
        cur_cmd_reg_data[`SINC_REGS_CMD_SET_CACHE_ACTIVE_STATE_RANGE] = 0;
        cur_cmd_reg_data[`SINC_REGS_CMD_SET_INIT_STATE_RANGE]         = 0;

        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::CMD_REG_NAME, cur_cmd_reg_data), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::CMD_REG_NAME))
        end

        if (m_fw_cmd !== sinc_parameters_pkg::SINC_AES_TEST_EN) begin
          cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;
        end
        if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
          `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
        end else begin
          `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
        end
      end

      // below would capture two critical information
      // 1. If the FW command is UNMAPPED, then it is indicating the write response is too late after sinc_done or error
      // 2. If the FW command is not UNMAPPED, then FW operation is long enough to updated after AXI write
      if (!m_is_fw_tlb_updated) begin
        m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd           = m_fw_cmd;
        m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_done_time = $realtime;
        m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_fail      = m_is_fw_op_fail;
        `uvm_info(report_str, $sformatf("Update m_most_recent_fw_cmd [%0s], m_most_recent_fw_cmd_fail [%0d], m_cur_cache_state [%0s]",
                                        m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd.name(), m_top_configuration.m_sys_cfg.m_most_recent_fw_cmd_fail, m_top_configuration.m_sys_cfg.m_cur_cache_state.name()), UVM_HIGH)
      end

      if (m_fw_cmd !== sinc_parameters_pkg::SINC_FW_UNMAPPED) begin
        m_is_fw_tlb_updated                                = 1;
        m_top_configuration.m_sys_cfg.m_unpredicatable_state = 0;
        `uvm_info(report_str, $sformatf("set unpredicatable_state['h%0h]", m_top_configuration.m_sys_cfg.m_unpredicatable_state), UVM_HIGH)
      end

      // special case to help back to back prediction
      if ((m_fw_cmd == sinc_parameters_pkg::SINC_FW_UNMAPPED) && !m_is_fw_tlb_updated) begin
        m_top_configuration.m_sys_cfg.m_uncertain_fw_done_time = $realtime;
        m_top_configuration.m_sys_cfg.m_unpredicatable_state   = 1;
        `uvm_info(report_str, $sformatf("set unpredicatable_state['h%0h]", m_top_configuration.m_sys_cfg.m_unpredicatable_state), UVM_HIGH)
      end

      case (m_fw_cmd)
        sinc_parameters_pkg::SINC_SET_INIT_STATE : begin
          if (m_is_fw_op_fail) begin
            if (m_is_rng_fetch_error || m_is_ksu_rd_error || m_is_sharedram_rd_error || m_is_dmb_write_error) begin
              if (m_is_rng_fetch_error) begin
                cur_status_reg_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_RANGE] = 'b1;
              end

              if (m_is_ksu_rd_error) begin
                cur_status_reg_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_RANGE] = 'b1;
              end

              if (m_is_sharedram_rd_error) begin
                cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] = 'b1;
              end

              if (m_is_dmb_write_error) begin
                if (m_is_dmb_auth_tag_write_error) begin
                  cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
                end else if (m_is_dmb_encrypt_data_write_error) begin
                  cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
                end else begin
                  // program num_of_blocks could lead to unpredicted decode error, SB has hard time figuring out which exact error will be, so set both but waive one when status read
                  cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]               = 'b1;
                  cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
                end
              end

              // move to Failure state
              // set update on cache state
              cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
              `uvm_info(report_str, $sformatf("Set cache fail due to m_is_rng_fetch_error[%0d]", m_is_rng_fetch_error), UVM_HIGH)
              set_cache_fail();
            end

            cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;

            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end else begin // if (m_is_fw_op_fail)
            m_top_configuration.m_sys_cfg.m_cur_cache_state                = sinc_parameters_pkg::CACHE_INIT_STATE;
            // set update on cache state
            cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE]           = sinc_parameters_pkg::CACHE_INIT_STATE;
            // set update on success and in_progress
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
            `uvm_info(report_str, $sformatf("Update status register for FW CMD [%0s]", m_fw_cmd.name()), UVM_HIGH)
          end
        end // case: sinc_parameters_pkg::SINC_SET_INIT_STATE

        sinc_parameters_pkg::SINC_SET_CACHE_ACTIVE_STATE : begin
          // 1. set status register
          if (!m_is_fw_op_fail) begin
            m_top_configuration.m_sys_cfg.m_cur_cache_state                = sinc_parameters_pkg::CACHE_ACTIVE_STATE;
            cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE]           = sinc_parameters_pkg::CACHE_ACTIVE_STATE;
            // set update on success and in_progress
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end
        end

        sinc_parameters_pkg::SINC_AES_TEST_DISABLE : begin
          // if (m_exp_sinc_done && (m_sinc_done_num == 1)) begin
          //   // Note: scoreboard doesn't check AES command results, the sequence has self-implemented checks
          //   m_top_configuration.m_sys_cfg.m_aes_test_mode_en = 0;
          //   m_top_configuration.m_sys_cfg.m_aes_test_mode_done = 1;
          //   m_top_configuration.m_sys_cfg.m_aes_test_mode_toggled = $realtime;

          //   // update status
          //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
          //   cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE] = 1;
          //   if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
          //     `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
          //   end else begin
          //     `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
          //   end
          // end

          // // update AES register values with backdoor
          // fork
          //   update_reg_mirror_w_backdoor_value(sinc_parameters_pkg::AES_TEST_CTRL_REG_NAME);
          // join_none
        end
        sinc_parameters_pkg::SINC_SINC_RESET : begin
          if (!m_is_fw_op_fail) begin
            m_top_configuration.m_sys_cfg.m_cur_cache_state                = sinc_parameters_pkg::CACHE_DISABLE_STATE;
            cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE]           = sinc_parameters_pkg::CACHE_DISABLE_STATE;
            // set update on success and in_progress
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end

            // update peripherals
            // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
            // reset cache coherency, will also do preload of current memory
            m_top_configuration.m_csd.reset_csd();

            // reset MPU attributes and registers
            m_mpu_cfg = m_top_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
            m_mpu_cfg.reset_mpu();

            // KEY should been wiped
            m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;

          end // if (!m_is_fw_op_fail) begin
        end
        sinc_parameters_pkg::SINC_DISABLE_RESET : begin
          if (!m_is_fw_op_fail) begin
            // set update on success and in_progress
            // DISABLE RESET command will set disable reset status bit
            cur_status_reg_data[`SINC_REGS_STATUS_SINC_RESET_DISABLED_RANGE] = 'b1;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE]     = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]         = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end // if (!m_is_fw_op_fail) begin
        end
        sinc_parameters_pkg::SINC_DISABLE_REINIT: begin
          // no further check
          if (!m_is_fw_op_fail) begin
            // set update on success and in_progress
            // DISABLE REINIT command will set disable reinit status bit
            cur_status_reg_data[`SINC_REGS_STATUS_SINC_REINIT_DISABLED_RANGE] = 'b1;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end // if (!m_is_fw_op_fail) begin
        end
        sinc_parameters_pkg::SINC_ENCR_BLOCK : begin
          if (m_is_fw_op_fail) begin
            // update encr_block_status prediction, it can only be rough predict
            int encrypted_blocks;
            int dmb_write_size;
            bit [7:0] act_dmb_w_data[$];
            int data_and_tag_size_per_block = (sinc_parameters_pkg::SINC_PER_ENCRYPT_BLOCK_IN_BITS / 8) + (sinc_parameters_pkg::SINC_PER_AUTH_TAG_IN_BITS / 8);

            if (m_axi_mgr_wr_resp_tran_q.size() > 0) begin
              foreach (m_axi_mgr_wr_resp_tran_q[i]) begin
                foreach (m_axi_mgr_wr_resp_tran_q[i].data[j]) begin
                  act_dmb_w_data.push_back(m_axi_mgr_wr_resp_tran_q[i].data[j]);
                end
              end
            end

            dmb_write_size   = act_dmb_w_data.size();
            encrypted_blocks = (dmb_write_size - 1) / data_and_tag_size_per_block;
            if (encrypted_blocks > 0) begin
              uvm_reg encr_block_status_reg             = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("encr_block_status");
              sinc_reg_data_t cur_encr_block_status_reg = sinc_reg_data_t'(encr_block_status_reg.get_mirrored_value());

              cur_encr_block_status_reg = encrypted_blocks;
              if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("encr_block_status", cur_encr_block_status_reg)) begin
                `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h], dmb_write_size[%0d], data_and_tag_size_per_block[%0d]", "encr_block_status",
                    cur_encr_block_status_reg, dmb_write_size, data_and_tag_size_per_block), UVM_HIGH)
              end else begin
                `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "encr_block_status"))
              end
            end else begin
              uvm_reg encr_block_status_reg             = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("encr_block_status");
              sinc_reg_data_t cur_encr_block_status_reg = sinc_reg_data_t'(encr_block_status_reg.get_mirrored_value());

              // set to current value
              if ((cur_encr_block_status_reg > 0) &&
                  m_top_configuration.m_sys_cfg.is_valid_encr_block_cmd(m_snapshot_num_of_blocks, m_snapshot_block_encr_num)) begin
                cur_encr_block_status_reg = encrypted_blocks;
                if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("encr_block_status", cur_encr_block_status_reg)) begin
                  `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h], dmb_write_size[%0d], data_and_tag_size_per_block[%0d]", "encr_block_status",
                                                  cur_encr_block_status_reg, dmb_write_size, data_and_tag_size_per_block), UVM_HIGH)
                end else begin
                  `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "encr_block_status"))
                end
              end


              `uvm_info(report_str, $sformatf("ENCR_BLOCK fail, with ['h%0h] written, data_and_tag_size_per_block[%0d], dmb_write_size[%0d]",
                  encrypted_blocks, data_and_tag_size_per_block, dmb_write_size), UVM_HIGH)
            end

            if (m_is_dmb_write_error || m_is_sharedram_rd_error) begin
              if (m_is_dmb_write_error) begin
                if (m_is_dmb_auth_tag_write_error) begin
                  cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE] = 'b1;
                end else if (m_is_dmb_encrypt_data_write_error) begin
                  cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
                end else begin
                  // program num_of_blocks could lead to unpredicted decode error, SB has hard time figuring out which exact error will be, so set both but waive one when status read
                  cur_status_reg_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_RANGE]               = 'b1;
                  cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_RANGE] = 'b1;
                end
              end

              if (m_is_sharedram_rd_error) begin
                cur_status_reg_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_RANGE] = 'b1;
              end

              if (m_is_sharedram_rd_error) begin
                // move to Failure state
                // set update on cache state
                cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE] = sinc_parameters_pkg::CACHE_FAIL_STATE;
                `uvm_info(report_str, $sformatf("Set cache fail due to m_is_dmb_write_error[%0d], m_is_sharedram_rd_error[%0d]",
                    m_is_dmb_write_error, m_is_sharedram_rd_error), UVM_HIGH)
                set_cache_fail();
              end
            end

            cur_status_reg_data[`SINC_REGS_STATUS_CMD_FAILED_RANGE]      = 'b1;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 'b0;

            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end
          end else begin // if (m_is_fw_op_fail) begin
            // set update on success and in_progress
            uvm_reg encr_block_status_reg             = m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.get_reg_by_name("encr_block_status");
            sinc_reg_data_t cur_encr_block_status_reg = sinc_reg_data_t'(encr_block_status_reg.get_mirrored_value());

            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end

            // Note: CSR description changed to encr_block_status remain unchanged if encr_block cmd success
            // cur_encr_block_status_reg = 0;
            // if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name("encr_block_status", cur_encr_block_status_reg)) begin
            //   `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", "encr_block_status", cur_encr_block_status_reg), UVM_HIGH)
            // end else begin
            //   `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", "encr_block_status"))
            // end
          end

        end // sinc_parameters_pkg::SINC_ENCR_BLOCK : begin

        sinc_parameters_pkg::SINC_SINC_REINIT : begin
          if (!m_is_fw_op_fail) begin
            m_top_configuration.m_sys_cfg.m_cur_cache_state              = sinc_parameters_pkg::CACHE_INIT_STATE;
            cur_status_reg_data[`SINC_REGS_STATUS_STATE_RANGE]           = sinc_parameters_pkg::CACHE_INIT_STATE;
            // set update on success and in_progress
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_IN_PROGRESS_RANGE] = 0;
            cur_status_reg_data[`SINC_REGS_STATUS_CMD_SUCCESS_RANGE]     = 1;
            if(m_top_configuration.m_sys_cfg.m_sinc_reg_tlb.set_reg_by_name(sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data)) begin
              `uvm_info(report_str, $sformatf("tlb reg[%0s] updated data['h%0h]", sinc_parameters_pkg::STATUS_REG_NAME, cur_status_reg_data), UVM_HIGH)
            end else begin
              `uvm_error(report_str, $sformatf("Unable to update tlb reg[%0s]", sinc_parameters_pkg::STATUS_REG_NAME))
            end

            // update peripherals
            // cache IRAM, erase VTAG, clear the locally stored key, reset the MPU permissions and move to Disabled state.
            // reset cache coherency, will also do preload of current memory
            m_top_configuration.m_csd.reset_csd();

            // sinc_reinit will not reset MPU attributes and registers
            // m_mpu_cfg = m_top_configuration.ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
            // m_mpu_cfg.reset_mpu();

            // KEY should been wiped
            m_top_configuration.m_sys_cfg.m_is_key_fetched = 0;
          end // if (!m_is_fw_op_fail) begin
        end
        default : begin
          //do nothing
        end

      endcase // case (m_fw_cmd)

    end // if (m_req_dst == SINC_REG ) begin
  end // case: sinc_env_pkg::ENTRY_AXI_SUB_WRITE

endfunction : update_tlb_when_op_finish


function void sinc_sb_pkt_item::do_copy(uvm_object rhs);
  sinc_sb_pkt_item tr;
  if (!$cast(tr, rhs)) begin
    `uvm_fatal("sinc_sb_pkt_item", "do_copy cast failure")
    return;
  end
  super.do_copy(rhs);

  m_cache_mem_pkt_q        = tr.m_cache_mem_pkt_q;
  m_axi_sub_rd_resp_tran_q = tr.m_axi_sub_rd_resp_tran_q;
  m_dst_reg                = tr.m_dst_reg;

  if (tr.m_exp_reg_data_addr_p.size() != 0) begin
    m_exp_reg_data_addr_p = new[tr.m_exp_reg_data_addr_p.size()];
    m_exp_reg_data_addr_p = tr.m_exp_reg_data_addr_p;
  end

  if (tr.m_exp_reg_data_resp_p.size() != 0) begin
    m_exp_reg_data_resp_p = new[tr.m_exp_reg_data_resp_p.size()];
    m_exp_reg_data_resp_p = tr.m_exp_reg_data_resp_p;
  end
endfunction: do_copy


function void sinc_sb_pkt_item::print_packet ();
  string report_str = "SINC_SB_PKT_ITEM/PRINT_PACKET";
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Print Scoreboard Packet Item[%0d] witn entry [%0s], accepted at [%0t] \n", m_trans_id, m_sinc_sb_pkt_entry.name(), m_req_tr_time)};
  str = {str, $sformatf(" Current Cache State [%0s] \n", m_cur_cache_state.name())};
  if ((m_sinc_sb_pkt_entry == ENTRY_AXI_SUB_READ) ||
      (m_sinc_sb_pkt_entry == ENTRY_AXI_SUB_WRITE)) begin
    str = {str, $sformatf(" m_req_src[%0s], m_req_dst[%0s], m_req_cmd[%0s], address['h%0h]\n",
        m_req_src.name(), m_req_dst.name(), m_req_cmd.name(), m_sub_addr_p_tran.addr)};
    str = {str, $sformatf(" m_exp_sub_slv_err['h%0h]\n",
        m_exp_sub_slv_err)};
    if ((m_req_dst == SINC_REG) && (m_dst_reg !== null)) begin
      str = {str, $sformatf(" m_dst_reg name : [%0s] \n", m_dst_reg.get_name())};
      str = {str, $sformatf(" m_is_fw_blocked_due_to_unread_status : [%0d] \n", m_is_fw_blocked_due_to_unread_status)};
    end

    if (m_is_fw_cmd) begin
      str = {str, $sformatf(" FW Command : %0s \n", m_fw_cmd.name())};
      str = {str, $sformatf(" m_is_fw_op_fail : %0d \n", m_is_fw_op_fail)};
      str = {str, $sformatf(" m_exp_cache_mem[%0d], m_cache_mem_transaction_num[%0d]\n",
          m_exp_cache_mem, m_cache_mem_transaction_num)};
      str = {str, $sformatf(" m_rng_seed_is_fetched[%0d], m_ksu_key_is_fetched[%0d]\n",
          m_rng_seed_is_fetched, m_ksu_key_is_fetched)};
    end
  end
  if (m_sinc_sb_pkt_entry == ENTRY_CPU_READ) begin
    str = {str, $sformatf(" m_cpu_write[%0d], m_cpu_addr['h%0h], m_cpu_loadstore['h%0h], m_cpu_privmode['h%0h], m_is_mpu_allowed[%0d]\n",
        m_cpu_write, m_cpu_addr, m_cpu_loadstore, m_cpu_privmode, m_is_mpu_allowed)};
    str = {str, $sformatf(" m_exp_cpu_rd_resp[%0d], m_is_cpu_rd_err[%0d], m_exp_cache_mem[%0d], m_cache_mem_transaction_num[%0d]\n",
        m_exp_cpu_rd_resp, m_is_cpu_rd_err, m_exp_cache_mem, m_cache_mem_transaction_num)};
    str = {str, $sformatf(" received_cpu_rd_resp[%0d]\n",
                          m_cpu_rd_resp_tran_q.size())};
    str = {str, $sformatf(" m_is_cache_hit[%0d], m_cache_mem_pkt_q(received)[%0d]\n",
        m_is_cache_hit, m_cache_mem_pkt_q.size())};
    str = {str, $sformatf(" m_erase_accepted_before_cache_mem_transaction_done[%0d]\n",
        m_erase_accepted_before_cache_mem_transaction_done)};
    str = {str, $sformatf(" m_exp_block_fetch[%0d]\n",
        m_exp_block_fetch)};
    str = {str, $sformatf(" m_is_auth_tag_mismatch_error[%0d]\n",
        m_is_auth_tag_mismatch_error)};
    str = {str, $sformatf(" m_is_dmb_read_error[%0d]\n",
        m_is_dmb_read_error)};

  end
  if (m_sinc_sb_pkt_entry == ENTRY_CPU_WRITE) begin
    str = {str, $sformatf(" m_cpu_write[%0d], m_cpu_we['h%0h], m_cpu_addr['h%0h], m_cpu_loadstore['h%0h], m_cpu_privmode['h%0h], m_is_mpu_allowed[%0d]\n",
        m_cpu_write, m_cpu_we, m_cpu_addr, m_cpu_loadstore, m_cpu_privmode, m_is_mpu_allowed)};
    str = {str, $sformatf(" m_exp_cache_mem[%0d], m_cache_mem_transaction_num[%0d]\n",
        m_exp_cache_mem, m_cache_mem_transaction_num)};
    str = {str, $sformatf(" m_cache_mem_pkt_q(received)[%0d]\n",
        m_cache_mem_pkt_q.size())};

  end
  if ((m_sinc_sb_pkt_entry == ENTRY_MPU_ATTR_READ) || (m_sinc_sb_pkt_entry == ENTRY_MPU_STATUS_READ)) begin
    str = {str, $sformatf(" m_exp_mpu_resp['b%0b], m_exp_mpu_rd_data['h%0h]",
        m_exp_mpu_resp, m_exp_mpu_rd_data)};
  end
  if (m_exp_axi_mgr_rd_req) begin
    str = {str, $sformatf(" m_exp_axi_mgr_rd_req[%0d], m_exp_axi_mgr_rd_size[%0d], m_act_axi_mgr_rd_size_received[%0d]\n",
        m_exp_axi_mgr_rd_req, m_exp_axi_mgr_rd_size, m_act_axi_mgr_rd_size_received)};
  end
  if (m_exp_axi_mgr_wr_req) begin
    str = {str, $sformatf(" m_exp_axi_mgr_wr_req[%0d], m_exp_axi_mgr_wr_size[%0d], m_act_axi_mgr_wr_size_received[%0d]\n",
        m_exp_axi_mgr_wr_req, m_exp_axi_mgr_wr_size, m_act_axi_mgr_wr_size_received)};
  end
  str = {str, $sformatf(" m_exp_sinc_done['h%0h], received[%0d]\n",
      m_exp_sinc_done, m_sinc_done_q.size())};
  str = {str, $sformatf(" m_exp_sinc_error['h%0h], received[%0d]\n",
      m_exp_sinc_error, m_sinc_error_q.size())};
  if (m_is_rng_fetch_error) begin
    str = {str, $sformatf(" m_is_rng_fetch_error[%0d]\n",
        m_is_rng_fetch_error)};
  end
  if (m_access_while_erase_inprogress) begin
    str = {str, $sformatf(" m_access_while_erase_inprogress[%0d]\n",
        m_access_while_erase_inprogress)};
  end
  if (m_exp_mpu_err_accvio) begin
    str = {str, $sformatf(" m_exp_mpu_err_accvio[%0d], received[%0d]\n",
        m_exp_mpu_err_accvio, m_mpu_err_accvio_q.size())};
  end
  str = {str, $sformatf(" m_is_mpu_status_update_expected[%0d], m_is_mpu_allowed[%0d]\n",
      m_is_mpu_status_update_expected, m_is_mpu_allowed)};

  str = {str, $sformatf(" m_snapshot_aes_test_mode_en[%0d]\n",
      m_snapshot_aes_test_mode_en)};
  str = {str, $sformatf(" m_erase_during_req_inprogress[%0d]\n",
                        m_erase_during_req_inprogress)};
  str = {str, $sformatf(" is_completed[%0d]\n",
      m_is_completed)};
  str = {str, "\n ****************************************** \n"};
  `uvm_info(report_str, str, UVM_HIGH)
endfunction :print_packet

`endif // SINC_SB_PKT_ITEM
