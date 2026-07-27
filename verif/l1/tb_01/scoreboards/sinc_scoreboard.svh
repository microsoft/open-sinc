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
// File        : sinc_scoreboard.svh
// Description : This analysis component contains analysis_exports for receiving

`ifndef SINC_SCOREBOARD
`define SINC_SCOREBOARD

/**
 * SINC Scoreboard
 */
class sinc_scoreboard #(type CONFIG_T) extends uvm_component;

  `uvm_component_param_utils( sinc_scoreboard #(CONFIG_T ))

  // Variable: m_trans_count;
  // The counter of SINC request with set expectation in scoreboard packet item.
  int m_trans_count;

  // Variable: m_sb_enable
  // Flag used to enable/disable SB. The default is enabled.
  bit m_sb_enable = 1;

  // Variable: m_cov_enable
  // Flag used to enable/disable function coverage. The default is enabled.
  bit m_cov_enable = 1;

  // Instantiate a handle to the m_configuration of the environment in which this component resides
  CONFIG_T m_configuration;

  // Variable addr_dec_t
  // Address Decoder Type
  typedef sinc_env_pkg::sinc_address_decoder addr_dec_t;

  // Variable: m_addr_dec
  // Address Decoder
  addr_dec_t m_addr_dec;

  // Handler to sinc_sys_cfg
  sinc_sys_cfg m_sys_cfg;

  // Handler to sinc_cov
  sinc_sb_cov m_sb_cov;

  // Instantiate the analysis exports
  uvm_analysis_imp_sinc_reset_ae #(rst_pkg::rst_seq_item , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))               m_sinc_reset_ae;
  uvm_analysis_imp_sinc_axi_sub_ae #(pal_xaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))                       m_sinc_axi_sub_ae;
  uvm_analysis_imp_sinc_axi_mgr_ae #(pal_xaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))                       m_sinc_axi_mgr_ae;
  uvm_analysis_imp_sinc_cache_mem_mem_ae #(mem_transaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))             m_sinc_cache_mem_mem_ae;
  uvm_analysis_imp_sinc_cache_mem_erase_ae #(ramwrap_erase_transaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T))) m_sinc_cache_mem_erase_ae;
  uvm_analysis_imp_sinc_cpu_mem_ae #(ccpui_cpu_mem_transaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))         m_sinc_cpu_mem_ae;
  uvm_analysis_imp_sinc_mpu_ae #(ccpui_mpu_transaction , sinc_scoreboard#(.CONFIG_T(CONFIG_T)))                 m_sinc_mpu_ae;
  uvm_analysis_imp_sinc_sideband_ae #(sinc_monitor_pkg::sinc_sideband_e, sinc_scoreboard#(.CONFIG_T(CONFIG_T))) m_sinc_sideband_ae;

  // Variable: m_reset_done
  // Flag that is controlled by reset_xp, and indicates that SB is in reset if asserted
  bit m_reset_done = 0;

  // Variable: sinc_inflight_q
  // Queue of ongoing transactions (ie. have not seen all expected responses yet)
  sinc_sb_pkt_item m_inflight_q[$];

  // Variable: sinc_completed_q
  // Queue of completed transactions
  sinc_sb_pkt_item m_completed_q[$];

  // FUNCTION: new
  function new(string name, uvm_component parent);
    super.new(name, parent);
    m_addr_dec = addr_dec_t::get_inst();
  endfunction : new

  // FUNCTION: build_phase
  extern virtual function void build_phase (uvm_phase phase);

  // TLM implementations
  extern virtual function void write_sinc_reset_ae(rst_pkg::rst_seq_item reset_state);
  extern virtual function void write_sinc_axi_sub_ae(pal_xaction t);
  extern virtual function void write_sinc_axi_mgr_ae(pal_xaction t);
  extern virtual function void write_sinc_cache_mem_mem_ae(mem_transaction t);
  extern virtual function void write_sinc_cache_mem_erase_ae(ramwrap_erase_transaction t);
  extern virtual function void write_sinc_cpu_mem_ae(ccpui_cpu_mem_transaction t);
  extern virtual function void write_sinc_mpu_ae(ccpui_mpu_transaction t);

  // fixme-hw: unconnected yet
  extern virtual function void write_sinc_sideband_ae(sinc_monitor_pkg::sinc_sideband_e t);

  extern virtual function void process_plusargs();
  // function check_phase
  extern virtual function void check_phase(uvm_phase phase);

endclass : sinc_scoreboard

function void sinc_scoreboard::build_phase (uvm_phase phase);
  super.build_phase(phase);
  m_sinc_axi_sub_ae         = new("m_sinc_axi_sub_ae", this);
  m_sinc_axi_mgr_ae         = new("m_sinc_axi_mgr_ae", this);
  m_sinc_cache_mem_erase_ae = new("m_sinc_cache_mem_erase_ae", this);
  m_sinc_cache_mem_mem_ae   = new("m_sinc_cache_mem_mem_ae", this);
  m_sinc_cpu_mem_ae         = new("m_sinc_cpu_mem_ae", this);
  m_sinc_mpu_ae             = new("m_sinc_mpu_ae", this);
  m_sinc_reset_ae           = new("m_sinc_reset_ae", this);
  m_sinc_sideband_ae        = new("m_sinc_sideband_ae", this);
  m_sb_cov                  = sinc_sb_cov::type_id::create("m_sb_cov", this);
  process_plusargs();
endfunction : build_phase

// FUNCTION: write_sinc_reset_ae
// Transactions received through m_sinc_reset_ae initiate the execution of this function.
// This function set initial state of the scoreboard
function void sinc_scoreboard::write_sinc_reset_ae(rst_pkg::rst_seq_item reset_state);
  string report_str = "SINC_RESET";

  sinc_sb_pkt_entry_e sinc_sb_pkt_entry = ENTRY_SINC_WARM_RESET;

  if (!m_sb_enable) begin
    return;
  end

  if (reset_state.m_rstn === 1'b0) begin
    sinc_sb_pkt_item sinc_sb_pkt;
    m_reset_done = 0;
    `uvm_info(report_str, "Reset inactive detected", UVM_LOW)

    sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
    sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
    sinc_sb_pkt.m_top_configuration = m_configuration;
    sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);

    // remove all the m_inflight_q
    m_inflight_q.delete();

    m_completed_q.push_back(sinc_sb_pkt);
  end

  if (reset_state.m_rstn === 1'b1) begin
    `uvm_info(report_str, "Reset active detected", UVM_LOW)
    if (m_reset_done == 0) begin
      sinc_sb_pkt_item sinc_sb_pkt;
      m_reset_done = 1;

      // m_sinc_sb_pkt = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
      // m_sinc_sb_pkt.m_snapshot_sys_cfg = new m_configuration.m_sys_cfg;
      // m_sinc_sb_pkt.m_top_configuration = m_configuration;
      // sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_HW_RESET;
      // m_sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);

      // m_inflight_q.push_back(m_sinc_sb_pkt);
    end
  end
endfunction : write_sinc_reset_ae

// FUNCTION: write_sinc_axi_sub_ae
// Transactions received through m_sinc_axi_sub_ae initiate the execution of this function.
// AXI Manager initiate the requests to SInC DUT are monitored.
function void sinc_scoreboard::write_sinc_axi_sub_ae(pal_xaction t);
  string              report_str        = "WRITE_SINC_AXI_SUB_AE";
  sinc_comp_e         req_src;
  sinc_comp_e         req_dst;
  sinc_cmd_e          req_cmd;
  sinc_sb_pkt_entry_e sinc_sb_pkt_entry;
  bit                 match_found       = 0;
  bit                 self_check_result;
  pal_axi_xaction     xact;
  // downcast pal transaction
  if (!$cast(xact, t)) begin
    `uvm_fatal(report_str, "Failed to cast pal_axi_xaction type!")
  end

  `uvm_info("PRED", "Transaction Received through m_sinc_axi_sub_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"Data: ", t.convert2string()}, UVM_MEDIUM)
  if (!m_sb_enable) begin
    return;
  end

  req_src = m_configuration.m_sys_cfg.get_compe_by_axi_id(m_configuration.m_sys_cfg.convert_axuser_to_axiid(t.axuser));

  req_dst = m_addr_dec.get_dst_type_hit_w_axi_addr(xact.addr);

  if ((xact.cmd == PAL_READ) || (xact.cmd == PAL_EXRD) || (xact.cmd == PAL_LOCKRD)) begin
    req_cmd = sinc_env_pkg::SINC_AXI_READ;
  end else if ((xact.cmd == PAL_WRITE) || (xact.cmd == PAL_EXWR) || (xact.cmd == PAL_LOCKWR)) begin
    req_cmd = sinc_env_pkg::SINC_AXI_WRITE;
  end

  // Address phase:
  // 1. Capture AXI transaction address phase information
  // 2. Snapshot the current system status
  // 3. Set expectations

  // AXI READ - ADDR PHASE
  if (req_cmd == sinc_env_pkg::SINC_AXI_READ) begin
    if (xact.xaction_phase == PAL_PH_ADDR) begin
      sinc_sb_pkt_item sinc_sb_pkt;
      // AXI READ - ADDR PHASE
      sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
      sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
      sinc_sb_pkt.m_top_configuration = m_configuration;

      sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_AXI_SUB_READ;

      sinc_sb_pkt.m_sub_addr_p_tran = xact;
      sinc_sb_pkt.m_req_src         = req_src;
      sinc_sb_pkt.m_req_dst         = req_dst;
      sinc_sb_pkt.m_req_cmd         = req_cmd;

      `uvm_info(report_str, $sformatf("set_exp_pkt for : AXI [%0s] request from [%0s] to [%0s]", req_cmd, req_src, req_dst), UVM_HIGH)
      sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
      m_inflight_q.push_back(sinc_sb_pkt);
    end else begin
      // AXI READ - RESP PHASE
      // check if m_inflight_q is expecting AXI Read Response

      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_axi_sub_rd_resp && (m_inflight_q[i].m_axi_sub_rd_resp_tran_q.size() == 0) &&
            // check on the address and transaction ID
            (m_inflight_q[i].m_sub_addr_p_tran.addr == xact.addr) &&
            (m_inflight_q[i].m_sub_addr_p_tran.tag_id == xact.tag_id)
          ) begin
          match_found = 1;
          m_inflight_q[i].inject_axi_sub_rd_resp(xact);

          // If the m_inflight_q has completed
          // 1. Perform check on the packet;
          // 2. Create shallow copy of it for report phase in m_completed_q.
          if (m_inflight_q[i].is_completed(1)) begin
            sinc_sb_pkt_item completed_sb_pkt_item;

            // perform check on transaction itself
            self_check_result = m_inflight_q[i].self_check();

            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);
          end
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end
        `uvm_error(report_str, $sformatf("received unexpected AXI SUB Response: %0s", xact.convert2string()))
      end
    end // else: !if(xact.xaction_phase == PAL_PH_ADDR)
  end // if (req_cmd == sinc_env_pkg::AXI_READ)
  else if (req_cmd == sinc_env_pkg::SINC_AXI_WRITE) begin
    if (xact.xaction_phase == PAL_PH_ADDR) begin
      sinc_sb_pkt_item sinc_sb_pkt;
      // AXI WRITE - ADDR PHASE
      sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
      sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
      sinc_sb_pkt.m_top_configuration = m_configuration;

      sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_AXI_SUB_WRITE;

      sinc_sb_pkt.m_sub_addr_p_tran = xact;
      sinc_sb_pkt.m_req_src         = req_src;
      sinc_sb_pkt.m_req_dst         = req_dst;
      sinc_sb_pkt.m_req_cmd         = req_cmd;

      // check if there is ongoing CPU request has exp_block_fetch
      foreach (m_inflight_q[i]) begin
        if ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
            (!m_inflight_q[i].is_completed(0)) &&
            m_inflight_q[i].m_exp_block_fetch) begin
          `uvm_info(report_str, $sformatf("Found m_inflight_q[%0d] with CPU MEM RD starting block fetch",
                                          i), UVM_HIGH)
          sinc_sb_pkt.m_has_cpu_rd_exp_block_fetch = 1;
        end
      end
      

      `uvm_info(report_str, $sformatf("set_exp_pkt for : AXI [%0s] request from [%0s] to [%0s]", req_cmd, req_src, req_dst), UVM_HIGH)
      sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);

      if (!sinc_sb_pkt.m_exp_sub_slv_err &&
          !sinc_sb_pkt.m_is_reg_write_discarded &&
          (sinc_sb_pkt.m_req_dst == SINC_REG) &&
          (sinc_sb_pkt.m_dst_reg !== null)) begin
        m_configuration.m_sys_cfg.m_most_recent_write_dst_reg            = sinc_sb_pkt.m_dst_reg;
        m_configuration.m_sys_cfg.m_most_recent_write_dst_reg_start_time = $realtime;
      end
      void'(sinc_sb_pkt.is_completed(1));
      m_inflight_q.push_back(sinc_sb_pkt);

    end else begin
      bit has_cpu_rd_exp_block_fetch = 0;
      // AXI WRITE - RESP PHASE
      // sb_cov.sample_axi_interface(xact, outstanding_rd_cnt, outstanding_wr_cnt);

      foreach (m_inflight_q[i]) begin
        if ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
            (!m_inflight_q[i].is_completed(0)) &&
            m_inflight_q[i].m_exp_block_fetch) begin
          `uvm_info(report_str, $sformatf("Found m_inflight_q[%0d] with CPU MEM RD starting block fetch",
                                          i), UVM_HIGH)
          has_cpu_rd_exp_block_fetch = 1;
        end
      end

      // check if m_inflight_q is expecting AXI Write Response
      foreach (m_inflight_q[i]) begin        
        if (m_inflight_q[i].m_exp_axi_sub_wr_resp && (m_inflight_q[i].m_axi_sub_wr_resp_tran_q.size() == 0) &&
            // check on the address and transaction ID
            (m_inflight_q[i].m_sub_addr_p_tran.addr == xact.addr) &&
            (m_inflight_q[i].m_sub_addr_p_tran.tag_id == xact.tag_id)
          ) begin
          match_found = 1;
          m_inflight_q[i].m_has_cpu_rd_exp_block_fetch = has_cpu_rd_exp_block_fetch;
          m_inflight_q[i].inject_axi_sub_wr_resp(xact);

          // If the m_inflight_q has completed
          // 1. Perform check on the packet;
          // 2. Create shallow copy of it for report phase in m_completed_q.
          if (m_inflight_q[i].is_completed(1)) begin
            sinc_sb_pkt_item completed_sb_pkt_item;

            // perform check on transaction itself
            self_check_result = m_inflight_q[i].self_check();

            // completed_sb_pkt_item = m_inflight_q[i].clone();
            // completed_sb_pkt_item.copy(m_inflight_q[i]);
            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);

            // report error if previous write pkt not finished
            for (int j=0; j < i; j++) begin
              if (m_inflight_q[j].m_exp_axi_sub_wr_resp &&
                  !(m_inflight_q[j].m_is_fw_cmd && (m_inflight_q[j].m_exp_sinc_done && (m_inflight_q[j].m_sinc_done_q.size() == 0)))) begin
                m_inflight_q[j].print_packet();
                // below message was used for debug, it will not apply if a introduce random delay on FW commands with interaction of AXI SLV.
                // `uvm_error(report_str, $sformatf("Complete AXI SUB write while previous AXI SUB write not finished unfinished_index[%0d], finished_index[%0d]", j, i))
              end
            end
          end
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end
        `uvm_error(report_str, $sformatf("received unexpected AXI SUB Response: %0s", xact.convert2string()))
      end

    end // else: !if(xact.xaction_phase == PAL_PH_ADDR)
  end // if (req_cmd == sinc_env_pkg::AXI_WRITE) begin

endfunction : write_sinc_axi_sub_ae

// FUNCTION: write_sinc_axi_mgr_ae
// Transactions received through m_sinc_axi_mgr_ae initiate the execution of this function.
// SInC HW initiate AXI requests are monitored.
function void sinc_scoreboard::write_sinc_axi_mgr_ae(pal_xaction t);
  string              report_str        = "WRITE_SINC_AXI_MGR_AE";
  sinc_comp_e         req_src;
  sinc_comp_e         req_dst;
  sinc_cmd_e          req_cmd;
  sinc_sb_pkt_entry_e sinc_sb_pkt_entry;
  bit                 match_found       = 0;
  bit                 self_check_result;
  pal_axi_xaction     xact;
  // downcast pal transaction
  if (!$cast(xact, t)) begin
    `uvm_fatal(report_str, "Failed to cast pal_axi_xaction type!")
  end

  `uvm_info("PRED", "Transaction Received through m_sinc_axi_mgr_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"Data: ", t.convert2string()}, UVM_MEDIUM)
  if (!m_sb_enable) begin
    return;
  end

  req_src = m_configuration.m_sys_cfg.get_compe_by_axi_id(m_configuration.m_sys_cfg.convert_axuser_to_axiid(t.axuser));

  req_dst = m_addr_dec.get_dst_type_hit_w_axi_addr(xact.addr);

  if ((xact.cmd == PAL_READ) || (xact.cmd == PAL_EXRD) || (xact.cmd == PAL_LOCKRD)) begin
    req_cmd = sinc_env_pkg::SINC_AXI_READ;
  end else if ((xact.cmd == PAL_WRITE) || (xact.cmd == PAL_EXWR) || (xact.cmd == PAL_LOCKWR)) begin
    req_cmd = sinc_env_pkg::SINC_AXI_WRITE;
  end

  // Address phase:
  // 1. Capture AXI transaction address phase information
  // 2. inject monitored transaction to pending scoreboard packet

  // NOTE:intentionally seperate the line of code for easier debug experience, with sacrifise of more lines of code

  // AXI READ - ADDR PHASE
  if (req_cmd == sinc_env_pkg::SINC_AXI_READ) begin
    if (xact.xaction_phase == PAL_PH_ADDR) begin
      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_axi_mgr_rd_req && (m_inflight_q[i].m_act_axi_mgr_rd_size_received < m_inflight_q[i].m_exp_axi_mgr_rd_size)) begin
          match_found = 1;
          m_inflight_q[i].inject_axi_mgr_rd_req(xact);
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        bit found_uncompleted_fw_cmd = 0;
        if (m_configuration.m_sys_cfg.m_aes_test_mode_en) begin
          if (req_dst == sinc_env_pkg::SINC_RNG) begin
            m_configuration.m_sys_cfg.m_is_rng_fetched = 1;

            `uvm_info(report_str, $sformatf("Found RNG seed fetch transaction during aes_test_mode[%0d]",
                m_configuration.m_sys_cfg.m_aes_test_mode_en), UVM_HIGH)
          end
          if (req_dst == sinc_env_pkg::SINC_KSU) begin
            // fetch the KEY, scoreboard offload the check to sequence
            `uvm_info(report_str, $sformatf("Found KEY fetch transaction during aes_test_mode[%0d]",
                m_configuration.m_sys_cfg.m_aes_test_mode_en), UVM_HIGH)
          end
        end else begin
          foreach (m_inflight_q[i]) begin
            `uvm_info(report_str, $sformatf("Print m_inflight_q[%0d] for debug:",
                i), UVM_HIGH)
            m_inflight_q[i].print_packet();
            void'(m_inflight_q[i].is_completed(1));

            if (m_inflight_q[i].m_is_fw_cmd && !m_inflight_q[i].is_completed(0)) begin
              found_uncompleted_fw_cmd = 1;
              match_found              = 1;
              m_inflight_q[i].inject_axi_mgr_rd_req(xact);
              break;
            end
          end

          // check if finished item is pending request, only apply to recent FW failure commands
          // This happens if AXI MGR WR/RD with one of channel seen error,
          // Once an error is seen by sinc, it requests axi mgr to stop the txn. But axi mgr needs to still send out remaining reads otherwise the fabric will hang
          // foreach (m_completed_q[i]) begin
          if (m_completed_q.size()) begin
            for (int i=(m_completed_q.size() - 1); i > (m_completed_q.size() - 10) ; i--) begin
              if (m_completed_q[i].m_is_fw_op_fail && m_completed_q[i].m_exp_axi_mgr_rd_req &&
                  (m_completed_q[i].m_act_axi_mgr_rd_size_received < m_completed_q[i].m_exp_axi_mgr_rd_size)) begin
                found_uncompleted_fw_cmd = 1;
                match_found              = 1;
              end

              if (i == 0) begin
                break;
              end
            end
          end

          if (!found_uncompleted_fw_cmd) begin
            `uvm_error(report_str, $sformatf("received unexpected AXI MGR Req: %0s", xact.convert2string()))
          end
        end
      end
    end else begin
      // AXI READ - RESP PHASE
      // check if m_inflight_q is expecting AXI Read Response

      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_axi_mgr_rd_req && (m_inflight_q[i].m_act_axi_mgr_rd_size_received < m_inflight_q[i].m_exp_axi_mgr_rd_size)) begin
          // additional check for corner case that previous FW cmd has pending AXI MGR response
          // the first req must be start address
          if (m_inflight_q[i].m_axi_mgr_rd_req_tran_q.size() > m_inflight_q[i].m_axi_mgr_rd_resp_tran_q.size()) begin
            match_found = 1;
          end

          if (match_found) begin
            m_inflight_q[i].inject_axi_mgr_rd_resp(xact);

            // If the m_inflight_q has completed
            // 1. Perform check on the packet;
            // 2. Create shallow copy of it for report phase in m_completed_q.
            if (m_inflight_q[i].is_completed(1)) begin
              sinc_sb_pkt_item completed_sb_pkt_item;

              // perform check on transaction itself
              self_check_result = m_inflight_q[i].self_check();

              completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
              if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
                `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
              end

              `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                  self_check_result? "PASS":"FAIL"), UVM_HIGH)
              m_inflight_q[i].print_packet();
              // m_completed_q.push_back(completed_sb_pkt_item);
              m_completed_q.push_back(m_inflight_q[i]);

              m_inflight_q.delete(i);
            end

            break;
          end // if (match_found) begin
        end // if (m_inflight_q[i].m_exp_axi_mgr_rd_req && (m_inflight_q[i].m_act_axi_mgr_rd_size_received < m_inflight_q[i].m_exp_axi_mgr_rd_size)) begin
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        if (m_configuration.m_sys_cfg.m_aes_test_mode_en) begin
          if (req_dst == sinc_env_pkg::SINC_RNG) begin
            m_configuration.m_sys_cfg.m_is_rng_fetched = 1;

            `uvm_info(report_str, $sformatf("Found RNG seed fetch transaction during aes_test_mode[%0d]",
                m_configuration.m_sys_cfg.m_aes_test_mode_en), UVM_HIGH)
          end
          if (req_dst == sinc_env_pkg::SINC_KSU) begin
            // fetch the KEY, scoreboard offload the check to sequence
            `uvm_info(report_str, $sformatf("Found KEY fetch transaction during aes_test_mode[%0d]",
                m_configuration.m_sys_cfg.m_aes_test_mode_en), UVM_HIGH)
          end
        end else begin
          bit found_item_at_completed_q = 0;
          foreach (m_inflight_q[i]) begin
            m_inflight_q[i].print_packet();
            void'(m_inflight_q[i].is_completed(1));
          end
          // check if finished item is pending response, only apply to recent FW failure commands
          // This happens if AXI MGR WR/RD with one of channel seen error, the item will be retired once see sinc_error
          foreach (m_completed_q[i]) begin
            // for (int i=(m_completed_q.size() - 1); i > (m_completed_q.size() - 10) ; i--) begin
            m_completed_q[i].print_packet();
            if (m_completed_q[i].m_is_fw_op_fail && m_completed_q[i].m_exp_axi_mgr_rd_req) begin
              int last_axi_mgr_rd_req_idx = m_completed_q[i].m_axi_mgr_rd_req_tran_q.size() - 1;
              // if (m_completed_q[i].m_axi_mgr_rd_req_tran_q.size() > m_completed_q[i].m_axi_mgr_rd_resp_tran_q.size()) begin
              if (m_completed_q[i].m_exp_axi_mgr_rd_size > m_completed_q[i].m_act_axi_mgr_rd_size_received) begin
                found_item_at_completed_q = 1;
                m_completed_q[i].m_axi_mgr_rd_resp_tran_q.push_back(xact);
              end
            end
          end

          if (!found_item_at_completed_q) begin
            `uvm_error(report_str, $sformatf("received unexpected AXI MGR Response: %0s", xact.convert2string()))
          end
        end
      end
    end // else: !if(xact.xaction_phase == PAL_PH_ADDR)
  end // if (req_cmd == sinc_env_pkg::AXI_READ)
  else if (req_cmd == sinc_env_pkg::SINC_AXI_WRITE) begin
    if (xact.xaction_phase == PAL_PH_ADDR) begin
      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_axi_mgr_wr_req && (m_inflight_q[i].m_act_axi_mgr_wr_size_received < m_inflight_q[i].m_exp_axi_mgr_wr_size)) begin
          match_found = 1;
          m_inflight_q[i].inject_axi_mgr_wr_req(xact);
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end
        `uvm_error(report_str, $sformatf("received unexpected AXI MGR Req: %0s", xact.convert2string()))
      end
    end else begin
      // AXI WRITE - RESP PHASE
      // sb_cov.sample_axi_interface(xact, outstanding_rd_cnt, outstanding_wr_cnt);

      // check if m_inflight_q is expecting AXI Read Response
      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_axi_mgr_wr_req && (m_inflight_q[i].m_act_axi_mgr_wr_size_received < m_inflight_q[i].m_exp_axi_mgr_wr_size)) begin
          match_found = 1;
          m_inflight_q[i].inject_axi_mgr_wr_resp(xact);

          // If the m_inflight_q has completed
          // 1. Perform check on the packet;
          // 2. Create shallow copy of it for report phase in m_completed_q.
          if (m_inflight_q[i].is_completed(1)) begin
            sinc_sb_pkt_item completed_sb_pkt_item;

            // perform check on transaction itself
            self_check_result = m_inflight_q[i].self_check();

            // completed_sb_pkt_item = m_inflight_q[i].clone();
            // completed_sb_pkt_item.copy(m_inflight_q[i]);
            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);
          end
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        bit waive_error_report = 0;
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end

        // Corner case: when encr_block cmd had severe error(encrypt data fetch fail), there could be AXI MGR Write in progress, SB generally look for any transaction that finished but not seen all the resp
        foreach (m_completed_q[j]) begin
          if (xact.xaction_phase == PAL_PH_ADDR) begin
            // there shouldn't be request phase miss item injection
          end else begin
            if (req_cmd == sinc_env_pkg::SINC_AXI_READ) begin
              if (m_completed_q[j].m_axi_mgr_rd_req_tran_q.size() > m_completed_q[j].m_axi_mgr_rd_resp_tran_q.size()) begin
                m_completed_q[j].m_axi_mgr_rd_resp_tran_q.push_back(xact);
                waive_error_report = 1;
                break;
              end
            end else begin
              if (m_completed_q[j].m_axi_mgr_wr_req_tran_q.size() > m_completed_q[j].m_axi_mgr_wr_resp_tran_q.size()) begin
                m_completed_q[j].m_axi_mgr_wr_resp_tran_q.push_back(xact);
                waive_error_report = 1;
                break;
              end
            end
          end
        end

        if (!waive_error_report) begin
          `uvm_error(report_str, $sformatf("received unexpected AXI MGR Response: %0s", xact.convert2string()))
        end
      end
    end // else: !if(xact.xaction_phase == PAL_PH_ADDR)
  end // if (req_cmd == sinc_env_pkg::AXI_WRITE) begin

endfunction : write_sinc_axi_mgr_ae

// Function: write_sinc_cache_mem_mem_ae
// Transactions received through sinc_cache_mem_ae initiate the execution of this function.
// HW initiate RamWrapper requests to memory, the RamWrapper to memory interface activity is monitored.
function void sinc_scoreboard::write_sinc_cache_mem_mem_ae(mem_transaction t);
  string report_str        = "m_sinc_cache_mem_mem_ae";
  bit    match_found       = 0;
  bit    self_check_result;


  `uvm_info("PRED", "Transaction Received through m_sinc_cache_mem_mem_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"Data: ", t.convert2string()}, UVM_MEDIUM)

  if (!m_sb_enable) begin
    return;
  end

  // RamWrapper Error Injection is firmware mech, Design does not triaging it
  if (m_configuration.m_mem_err_inj_event.is_on()) begin
    `uvm_info("PRED", "This Transaction is for error injection", UVM_DEBUG)
    return;
  end

  // check if m_inflight_q is expecting cache_mem transaction
  foreach (m_inflight_q[i]) begin
    begin
      // debug infor
      `uvm_info(report_str, $sformatf("Check on index [%0d]",
          i), UVM_HIGH)
      m_inflight_q[i].print_packet();
    end

    if (m_inflight_q[i].m_exp_cache_mem && (m_inflight_q[i].m_cache_mem_pkt_q.size() < m_inflight_q[i].m_cache_mem_transaction_num)) begin
      match_found = 1;
      m_inflight_q[i].inject_cache_mem_tran(t);
      `uvm_info(report_str, $sformatf("Found m_inflight_q with entry [%0s]",
          m_inflight_q[i].m_sinc_sb_pkt_entry.name()), UVM_HIGH)
      // If the m_inflight_q has completed
      // 1. Perform check on the packet;
      // 2. Create shallow copy of it for report phase in m_completed_q.
      if (m_inflight_q[i].is_completed(1)) begin
        sinc_sb_pkt_item completed_sb_pkt_item;
        // perform check on transaction itself
        self_check_result = m_inflight_q[i].self_check();

        completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
        if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
          `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
        end

        `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
            self_check_result? "PASS":"FAIL"), UVM_HIGH)
        m_inflight_q[i].print_packet();

        // m_completed_q.push_back(completed_sb_pkt_item);
        m_completed_q.push_back(m_inflight_q[i]);

        m_inflight_q.delete(i);
      end
      break;
    end
  end // foreach (m_inflight_q[i]) begin

  if (!match_found) begin
    // reserved waiver for special cases
    bit uncertainty_req_found  = 0;
    bit uncertainty_creg_erase = 0;

    foreach (m_inflight_q[i]) begin
      m_inflight_q[i].print_packet();
      void'(m_inflight_q[i].is_completed(1));

      // below case happen when CMD register write response phase been delayed by waiting for bready asserted from AXI Manager
      if (m_inflight_q[i].m_req_dst == SINC_REG) begin
        if (m_inflight_q[i].m_is_fw_cmd && (m_inflight_q[i].m_axi_sub_wr_resp_tran_q.size() == 0)) begin
          m_inflight_q[i].inject_cache_mem_tran(t);
          uncertainty_req_found = 1;
        end
      end

      // if CREG erase interrupt previous requests that require cache mem
      if ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CREG_ERASE) &&
          (m_inflight_q[i].m_cache_mem_pkt_q.size() >= m_inflight_q[i].m_cache_mem_transaction_num) &&
          (m_inflight_q[i].m_erase_accepted_before_cache_mem_transaction_done)) begin
        m_inflight_q[i].inject_cache_mem_tran(t);
        uncertainty_req_found = 1;
      end
    end

    if (!uncertainty_req_found && !uncertainty_creg_erase) begin
      `uvm_error(report_str, $sformatf("received unexpected mem_transaction[%0s], m_inflight_q.size[%0d]", t.convert2string(), m_inflight_q.size()))
    end
  end

endfunction : write_sinc_cache_mem_mem_ae

// FUNCTION: write_sinc_cache_mem_erase_ae
// Transactions received through m_sinc_cache_mem_erase_ae initiate the execution of this function.
// CREG Erase to SInC Top requests and data are monitored.
function void sinc_scoreboard::write_sinc_cache_mem_erase_ae(ramwrap_erase_transaction t);
  string              report_str        = "WRITE_SINC_CACHE_MEM_ERASE_AE";
  sinc_sb_pkt_entry_e sinc_sb_pkt_entry;
  bit                 match_found       = 0;
  bit                 found_ongoing_req = 0;
  bit                 self_check_result;


  `uvm_info("PRED", "Transaction Received through m_sinc_cache_mem_erase_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"            Data: ", t.convert2string()}, UVM_MEDIUM)
  `uvm_info(report_str, $sformatf("Erase Event[%0s]",
      t.m_event.name()), UVM_HIGH)

  if (!m_sb_enable) begin
    return;
  end

  // create SB Entry when observe erase start
  if (t.m_event == ramwrap_erase_pkg::START) begin
    sinc_sb_pkt_item sinc_sb_pkt;
    sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
    sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
    sinc_sb_pkt.m_top_configuration = m_configuration;

    m_configuration.m_sys_cfg.set_sinc_erase_in_progress(1);
    foreach (m_inflight_q[i]) begin
      begin
        // debug infor
        `uvm_info(report_str, $sformatf("Check on index [%0d]",
            i), UVM_HIGH)
        m_inflight_q[i].print_packet();
      end

      // when Erase started, invalidate any ongoing AXI requests
      if ((!m_inflight_q[i].is_completed(0)) &&
          // fixme-hw: there are more entry need attention
          ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_READ) ||
            (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_WRITE)) &&
          ((m_inflight_q[i].m_exp_cache_mem && (m_inflight_q[i].m_cache_mem_pkt_q.size() <= m_inflight_q[i].m_cache_mem_transaction_num))
          )
        ) begin
        `uvm_info(report_str, $sformatf("Found m_inflight_q with entry during erase[%0s]",
                                        m_inflight_q[i].m_sinc_sb_pkt_entry.name()), UVM_HIGH)
        found_ongoing_req                                                                        = 1;
        m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] = 1;

        if (m_inflight_q[i].m_is_fw_cmd && !m_inflight_q[i].m_is_fw_op_fail && !m_inflight_q[i].m_exp_sub_slv_err) begin
          // fixme: should abort? check on VPlan
          // m_inflight_q[i].m_set_exp_aborted_fw_cmd_status();
        end

        m_inflight_q[i].m_exp_sub_slv_err             = 1;
        m_inflight_q[i].m_exp_cache_mem               = 0;
        m_inflight_q[i].m_erase_during_req_inprogress = 1;
        `uvm_info(report_str, $sformatf("Set m_exp_sub_slv_err['h%0h]",
            m_inflight_q[i].m_exp_sub_slv_err), UVM_HIGH)
      end

      // for coverage
      if (!m_inflight_q[i].is_completed(0)) begin
        m_inflight_q[i].m_erase_during_req_inprogress = 1;
      end

      // when Erase started, any ongoing CPU READ cache miss in cache active should result response error
      if ((!m_inflight_q[i].is_completed(0)) &&
          ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
            (m_inflight_q[i].m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
            m_inflight_q[i].m_exp_axi_mgr_rd_req)
        ) begin

        `uvm_info(report_str, $sformatf("Found m_inflight_q with entry during erase[%0s], snap_shot_sinc_cmu_ctrl_state_when_erase_start[%0h], snap_shot_sinc_ciu_cache_sm_r_when_erase_start[%0h]",
            m_inflight_q[i].m_sinc_sb_pkt_entry.name(), m_configuration.m_sinc_vif.snap_shot_sinc_cmu_ctrl_state_when_erase_start, m_configuration.m_sinc_vif.snap_shot_sinc_ciu_cache_sm_r_when_erase_start), UVM_HIGH)
        
        // if fetch block is ongoing, will result in severe error
        if ((m_configuration.m_sinc_vif.snap_shot_sinc_cmu_ctrl_state_when_erase_start === sinc_pkg::FETCH_BLOCK) ||   // FETCH_BLOCK  = 7'h07,
            (m_configuration.m_sinc_vif.snap_shot_sinc_ciu_cache_sm_r_when_erase_start === 6'b01_1110) // CIU_CACHE_MISS  = 6'b01_1110
            ) begin // hard coded in a prior project for FETCH_BLOCK state
            found_ongoing_req                                                                        = 1;
            m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;
            `uvm_info(report_str, $sformatf("Found SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK"), UVM_MEDIUM)
            m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK] = 1;
            m_inflight_q[i].m_erase_during_req_inprogress = 1;
            m_inflight_q[i].m_is_fw_op_fail               = 1;
            m_inflight_q[i].m_is_fetch_block_fail         = 1;
            m_inflight_q[i].m_exp_sinc_error              = 1;
            m_inflight_q[i].m_sinc_error_num              = 1;
            m_inflight_q[i].m_is_cpu_rd_err               = 1;
        end else begin
            found_ongoing_req                                                                        = 1;
            m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;

            m_inflight_q[i].m_erase_during_req_inprogress = 1;
            m_inflight_q[i].m_is_cpu_rd_err               = 1;
            m_inflight_q[i].m_exp_block_fetch_cancelled   = 1;
        end
      end

      // when Erase started, any ongoing CPU READ in cache active should result response error
      // below condition can be combined with !CACHE_ACTIVE_STATE condtion, leave them seperate as design is unstable, the behavior might change
      if ((!m_inflight_q[i].is_completed(0)) &&
          ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
            (m_inflight_q[i].m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) &&
            m_inflight_q[i].m_is_cache_hit)
        ) begin

        `uvm_info(report_str, $sformatf("Found m_inflight_q with entry during erase[%0s], snap_shot_sinc_cmu_ctrl_state_when_erase_start[%0h], snap_shot_sinc_ciu_cache_sm_r_when_erase_start[%0h]",
            m_inflight_q[i].m_sinc_sb_pkt_entry.name(), m_configuration.m_sinc_vif.snap_shot_sinc_cmu_ctrl_state_when_erase_start, m_configuration.m_sinc_vif.snap_shot_sinc_ciu_cache_sm_r_when_erase_start), UVM_HIGH)

        found_ongoing_req                                                                        = 1;
        m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;

        m_inflight_q[i].m_erase_during_req_inprogress = 1;
        m_inflight_q[i].m_is_cpu_rd_err               = 1;        
      end

      // when Erase started, any ongoing CPU READ in non cache active should result response error
      if ((!m_inflight_q[i].is_completed(0)) &&
          ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
           (m_inflight_q[i].m_cur_cache_state !== sinc_parameters_pkg::CACHE_ACTIVE_STATE))
          ) begin
        `uvm_info(report_str, $sformatf("Found m_inflight_q with entry during erase[%0s], snap_shot_sinc_cmu_ctrl_state_when_erase_start[%0h]",
                                        m_inflight_q[i].m_sinc_sb_pkt_entry.name(), m_configuration.m_sinc_vif.snap_shot_sinc_cmu_ctrl_state_when_erase_start), UVM_HIGH)
        found_ongoing_req                                                                        = 1;
        m_inflight_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;

        m_inflight_q[i].m_erase_during_req_inprogress = 1;
        m_inflight_q[i].m_is_cpu_rd_err               = 1;
      end
    end // foreach (m_inflight_q[i])

    sinc_sb_pkt_entry                         = sinc_env_pkg::ENTRY_CREG_ERASE;
    sinc_sb_pkt.m_erase_start_tran            = t;
    sinc_sb_pkt.m_erase_during_req_inprogress = found_ongoing_req;
    sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
    m_inflight_q.push_back(sinc_sb_pkt);

    // ongoing CPU transactions if remains CACHE MEM transactions - will be aborted
    if (sinc_sb_pkt.m_is_erase_accepted) begin
      int i =0;

      //loop through the queue, only increment index if item is NOT deleted.
      repeat(m_inflight_q.size()) begin
        if ( ( (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_WRITE) || (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ)) && m_inflight_q[i].m_exp_cache_mem) begin
          m_inflight_q[i].m_exp_cache_mem                                    = 0;
          m_inflight_q[i].m_erase_accepted_before_cache_mem_transaction_done = 1;
          // also mark this erase
          sinc_sb_pkt.m_erase_accepted_before_cache_mem_transaction_done     = 1;

          if (m_inflight_q[i].check_complete()) begin
            sinc_sb_pkt_item completed_sb_pkt_item;
            void'(m_inflight_q[i].self_check());
            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);
          end else begin
            i++;
          end
        end else begin
          i++;
        end
      end
    end
  end else if (t.m_event == ramwrap_erase_pkg::DONE) begin
    foreach (m_inflight_q[i]) begin
      if (m_inflight_q[i].m_exp_erase_done &&
          (m_inflight_q[i].m_erase_done_tran_q.size() == 0)) begin
        match_found = 1;
        m_inflight_q[i].inject_erase_done(t);
        m_configuration.m_sys_cfg.set_sinc_erase_in_progress(0);

        // If the m_inflight_q has completed
        // 1. Perform check on the packet;
        // 2. Create shallow copy of it for report phase in m_completed_q.
        if (m_inflight_q[i].is_completed(1)) begin
          sinc_sb_pkt_item completed_sb_pkt_item;

          // perform check on transaction itself
          self_check_result = m_inflight_q[i].self_check();

          completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
          if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
            `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
          end

          `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
              self_check_result? "PASS":"FAIL"), UVM_HIGH)
          m_inflight_q[i].print_packet();
          // m_completed_q.push_back(completed_sb_pkt_item);
          m_completed_q.push_back(m_inflight_q[i]);

          m_inflight_q.delete(i);
          m_configuration.m_sys_cfg.set_sinc_erase_in_progress(0);

          // remove ongoing requests that have been marked during erase
          // when Erase end, invalidate any ongoing AXI requests
          for (int idx = 0; idx < m_inflight_q.size(); ) begin
            begin
              // debug infor
              `uvm_info(report_str, $sformatf("Check on index [%0d]",
                  idx), UVM_HIGH)
              m_inflight_q[idx].print_packet();
            end

            if (m_inflight_q[idx].m_exp_sub_slv_err && m_inflight_q[idx].m_erase_during_req_inprogress) begin
              `uvm_info(report_str, $sformatf("Found m_inflight_q with entry during erase for retire[%0s]",
                  m_inflight_q[idx].m_sinc_sb_pkt_entry.name()), UVM_HIGH)

              m_inflight_q.delete(idx);
            end else begin
              idx++;
            end
          end

        end
        break;
      end
    end

    if (!match_found) begin
      foreach (m_inflight_q[i]) begin
        m_inflight_q[i].print_packet();
        void'(m_inflight_q[i].is_completed(1));
      end
      `uvm_error(report_str, $sformatf("received unexpected erase done: %0s", t.convert2string()))
    end

  end

endfunction : write_sinc_cache_mem_erase_ae

// Function: write_sinc_cpu_mem_ae
// Transactions received through m_sinc_cpu_mem_ae initiate the execution of this function.
// TB initiates CPU_MEM request to SINC
function void sinc_scoreboard::write_sinc_cpu_mem_ae(ccpui_cpu_mem_transaction t);
  string              report_str            = "m_sinc_cpu_mem_ae";
  sinc_comp_e         req_src;
  sinc_comp_e         req_dst;
  sinc_cmd_e          req_cmd;
  sinc_sb_pkt_entry_e sinc_sb_pkt_entry;
  bit                 match_found           = 0;
  bit                 self_check_result;
  bit                 found_inflight_axi    = 0;
  bit                 found_inflight_fw_cmd = 0;

  `uvm_info("PRED", "Transaction Received through m_sinc_cpu_mem_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"Data: ", t.convert2string()}, UVM_MEDIUM)

  if (!m_sb_enable) begin
    return;
  end

  req_src = SINC_SP;
  req_dst = SINC_CACHE;

  if (t.m_rw == ccpui_cpu_mem_pkg::READ) begin
    req_cmd = sinc_env_pkg::SINC_CPU_READ;
  end else if (t.m_rw == ccpui_cpu_mem_pkg::WRITE) begin
    req_cmd = sinc_env_pkg::SINC_CPU_WRITE;
  end else begin
    req_cmd = sinc_env_pkg::SINC_CMD_UNKNOWN;
  end

  foreach (m_inflight_q[i]) begin
    if ((m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_READ) ||
        (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_WRITE)) begin
      found_inflight_axi = 1;
    end
  end

  foreach (m_inflight_q[i]) begin
    if ((m_inflight_q[i].m_is_fw_cmd) &&
        (!m_inflight_q[i].m_is_fw_op_fail)) begin
      found_inflight_fw_cmd = 1;
    end
  end

  if (req_cmd == sinc_env_pkg::SINC_CPU_READ) begin
    // CPU READ has two phases
    if (t.m_phase == ccpui_cpu_mem_pkg::READ_REQ_PHASE) begin
      sinc_sb_pkt_item sinc_sb_pkt;

      // Check if previou CPU transactions have finished
      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_is_cpu_mem_req) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
          // `uvm_error(report_str, $sformatf("received new CPU request while there is outstanding CPU request, m_inflight_q[%0d]", i))
          `uvm_info(report_str, $sformatf("received new CPU request while there is outstanding CPU request, m_inflight_q[%0d]", i), UVM_HIGH)
        end
      end

      // CPU READ - REQ PHASE
      sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
      sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
      sinc_sb_pkt.m_top_configuration = m_configuration;

      sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_CPU_READ;

      sinc_sb_pkt.m_cpu_req_p_tran = t;
      sinc_sb_pkt.m_req_src        = req_src;
      sinc_sb_pkt.m_req_dst        = req_dst;
      sinc_sb_pkt.m_req_cmd        = req_cmd;

      `uvm_info(report_str, $sformatf("set_exp_pkt for : CPU [%0s] request from [%0s] to [%0s]", req_cmd, req_src, req_dst), UVM_HIGH)
      sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
      if (found_inflight_axi) begin
        sinc_sb_pkt.m_cpu_access_while_axi_inprogress = 1;
      end
      // when CMU_BUSY, the cpu_busy will also be asserted, this functional coverage is for whether CPU issue CPU request back to abck at very close time
      if (found_inflight_fw_cmd) begin
        sinc_sb_pkt.m_cpu_access_while_cmu_busy = 1;
      end
      m_inflight_q.push_back(sinc_sb_pkt);
    end else if (t.m_phase == ccpui_cpu_mem_pkg::READ_RESP_PHASE) begin
      // look for matched CPU read req
      foreach (m_inflight_q[i]) begin
        if (m_inflight_q[i].m_exp_cpu_rd_resp && (m_inflight_q[i].m_cpu_rd_resp_tran_q.size() == 0) &&
            // check on the address and transaction ID
            (m_inflight_q[i].m_cpu_req_p_tran.m_addr === t.m_addr)
          ) begin
          match_found = 1;
          m_inflight_q[i].inject_cpu_rd_resp(t);
          if (found_inflight_axi) begin
            m_inflight_q[i].m_axi_access_while_cpu_inprogress = 1;
          end

          // If the m_inflight_q has completed
          // 1. Perform check on the packet;
          // 2. Create shallow copy of it for report phase in m_completed_q.
          if (m_inflight_q[i].is_completed(1)) begin
            sinc_sb_pkt_item completed_sb_pkt_item;

            // perform check on transaction itself
            self_check_result = m_inflight_q[i].self_check();

            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);
          end
          break;
        end
      end // foreach (m_inflight_q[i]) begin
      if (!match_found) begin
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end
        `uvm_error(report_str, $sformatf("received unexpected CPU RESP: %0s", t.convert2string()))
      end
    end
  end else begin
    sinc_sb_pkt_item sinc_sb_pkt;
    // Check if previou CPU transactions have finished
    foreach (m_inflight_q[i]) begin
      if (m_inflight_q[i].m_is_cpu_mem_req) begin
        m_inflight_q[i].print_packet();
        void'(m_inflight_q[i].is_completed(1));
        // `uvm_error(report_str, $sformatf("received new CPU request while there is outstanding CPU request, m_inflight_q[%0d]", i))
        `uvm_info(report_str, $sformatf("received new CPU request while there is outstanding CPU request, m_inflight_q[%0d]", i), UVM_HIGH)
      end
    end

    // CPU WRITE - REQ PHASE
    sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
    sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
    sinc_sb_pkt.m_top_configuration = m_configuration;

    sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_CPU_WRITE;

    sinc_sb_pkt.m_cpu_req_p_tran = t;
    sinc_sb_pkt.m_req_src        = req_src;
    sinc_sb_pkt.m_req_dst        = req_dst;
    sinc_sb_pkt.m_req_cmd        = req_cmd;

    `uvm_info(report_str, $sformatf("set_exp_pkt for : CPU [%0s] request from [%0s] to [%0s]", req_cmd, req_src, req_dst), UVM_HIGH)
    sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
    if (found_inflight_axi) begin
      sinc_sb_pkt.m_cpu_access_while_axi_inprogress = 1;
    end

    // check if write is completed - this can happen if MPU violation
    if (sinc_sb_pkt.check_complete()) begin
      sinc_sb_pkt_item completed_sb_pkt_item;

      // perform check on transaction itself
      self_check_result = sinc_sb_pkt.self_check();

      completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
      if (!$cast(completed_sb_pkt_item, sinc_sb_pkt.clone())) begin
        `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
      end

      `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
          self_check_result? "PASS":"FAIL"), UVM_HIGH)
      sinc_sb_pkt.print_packet();
      // m_completed_q.push_back(completed_sb_pkt_item);
      m_completed_q.push_back(sinc_sb_pkt);
    end else begin
      m_inflight_q.push_back(sinc_sb_pkt);
    end

  end
endfunction : write_sinc_cpu_mem_ae

// Function: write_sinc_mpu_ae
// Transactions received through m_sinc_mpu_ae initiate the execution of this function.
// TB initiates MPU request to SINC
function void sinc_scoreboard::write_sinc_mpu_ae(ccpui_mpu_transaction t);
  string              report_str        = "m_sinc_mpu_ae";
  sinc_sb_pkt_entry_e sinc_sb_pkt_entry;
  bit                 match_found       = 0;
  bit                 self_check_result;
  sinc_sb_pkt_item    sinc_sb_pkt;


  `uvm_info("PRED", "Transaction Received through m_sinc_mpu_ae", UVM_MEDIUM)
  `uvm_info("PRED", {"Data: ", t.convert2string()}, UVM_MEDIUM)

  if (!m_sb_enable) begin
    return;
  end

  sinc_sb_pkt                     = sinc_sb_pkt_item::type_id::create("m_sinc_sb_pkt");
  sinc_sb_pkt.m_snapshot_sys_cfg  = new m_configuration.m_sys_cfg;
  sinc_sb_pkt.m_top_configuration = m_configuration;

  // typedef enum { ATTR_READ, ATTR_WRITE, REG_READ, REG_WRITE, SET_SIDEBAND, MPU_ERR_ACCVIO, INVALID} operation_e;
  if (t.m_op == ATTR_READ) begin
    sinc_sb_pkt_entry          = sinc_env_pkg::ENTRY_MPU_ATTR_READ;
    sinc_sb_pkt.m_mpu_req_tran = t;
    sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
    void'(sinc_sb_pkt.check_complete());

    // ATTR_READ won't sit in the inflight queue
    if (sinc_sb_pkt.is_completed(1)) begin

      // perform check on transaction itself
      self_check_result = sinc_sb_pkt.self_check();
      `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
          self_check_result? "PASS":"FAIL"), UVM_HIGH)
      sinc_sb_pkt.print_packet();
      m_completed_q.push_back(sinc_sb_pkt);
    end else begin
      `uvm_error(report_str, $sformatf("Entry [%0s] should be completed already", sinc_sb_pkt.m_sinc_sb_pkt_entry.name()))
    end
  end // if (t.m_op == ATTR_READ) begin

  if (t.m_op == ATTR_WRITE) begin
    sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_MPU_ATTR_WRITE;
    sinc_sb_pkt.m_mpu_req_tran      = t;
    sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_sb_pkt_entry;
    sinc_sb_pkt.m_cur_cache_state   = sinc_sb_pkt.m_top_configuration.m_sys_cfg.m_cur_cache_state;
    // m_sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);

    // ATTR_WRITE is digested by MPU UVC
    m_completed_q.push_back(sinc_sb_pkt);
  end // if (t.m_op == ATTR_WRITE) begin

  if (t.m_op == REG_READ) begin
    sinc_sb_pkt_entry          = sinc_env_pkg::ENTRY_MPU_STATUS_READ;
    sinc_sb_pkt.m_mpu_req_tran = t;

    // look for pending CPU transaction that has MPU violation when received MPU status READ
    foreach (m_inflight_q[i]) begin
        if ((m_inflight_q[i].m_sinc_sb_pkt_entry == ENTRY_CPU_READ) &&
            (!m_inflight_q[i].m_is_mpu_allowed)) begin
            sinc_sb_pkt.m_has_pending_cpu_read_with_mpu_disallowed = 1;
        end
    end

    sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);
    void'(sinc_sb_pkt.check_complete());

    // ATTR_READ won't sit in the inflight queue
    if (sinc_sb_pkt.is_completed(1)) begin

      // perform check on transaction itself
      self_check_result = sinc_sb_pkt.self_check();
      `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
          self_check_result? "PASS":"FAIL"), UVM_HIGH)
      sinc_sb_pkt.print_packet();
      m_completed_q.push_back(sinc_sb_pkt);
    end else begin
      `uvm_error(report_str, $sformatf("Entry [%0s] should be completed already", sinc_sb_pkt.m_sinc_sb_pkt_entry.name()))
    end
  end // if (t.m_op == REG_READ) begin

  if (t.m_op == REG_WRITE) begin
    sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_MPU_STATUS_WRITE;
    sinc_sb_pkt.m_mpu_req_tran      = t;
    sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_sb_pkt_entry;
    sinc_sb_pkt.m_cur_cache_state   = sinc_sb_pkt.m_top_configuration.m_sys_cfg.m_cur_cache_state;
    // m_sinc_sb_pkt.set_exp_pkt(sinc_sb_pkt_entry, m_trans_count++);

    // REG_WRITE is digested by MPU UVC
    m_completed_q.push_back(sinc_sb_pkt);
  end // if (t.m_op == REG_WRITE) begin

  if (t.m_op == MPU_ERR_ACCVIO) begin

    foreach (m_inflight_q[i]) begin
      if (m_inflight_q[i].m_exp_mpu_err_accvio &&
          (m_inflight_q[i].m_mpu_err_accvio_q.size() == 0)) begin
        match_found = 1;
        `uvm_info(report_str, $sformatf("Found match m_inflight_q for MPU_OP[%0s]",
            t.m_op.name()), UVM_HIGH)
        m_inflight_q[i].print_packet();
        m_inflight_q[i].inject_mpu_err_accvio(t);

        // If the m_inflight_q has completed
        // 1. Perform check on the packet;
        // 2. Create shallow copy of it for report phase in m_completed_q.
        if (m_inflight_q[i].is_completed(1)) begin
          sinc_sb_pkt_item completed_sb_pkt_item;

          // perform check on transaction itself
          self_check_result = m_inflight_q[i].self_check();

          // perform end to end check
          // check on the KEY memory by backdoor reads
          if (self_check_result) begin
            // leave for report info
          end

          completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
          if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
            `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
          end

          `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
              self_check_result? "PASS":"FAIL"), UVM_HIGH)
          m_inflight_q[i].print_packet();
          // m_completed_q.push_back(completed_sb_pkt_item);
          m_completed_q.push_back(m_inflight_q[i]);

          m_inflight_q.delete(i);
        end
        break;
      end
    end // foreach (m_inflight_q[i])

    if (!match_found) begin
      foreach (m_inflight_q[i]) begin
        m_inflight_q[i].print_packet();
        void'(m_inflight_q[i].is_completed(1));
      end
      `uvm_error(report_str, $sformatf("received unexpected MPU_ERR_ACCVIO, m_inflight_q.size[%0d]", m_inflight_q.size()))
    end
  end // if (t.m_op == MPU_ERR_ACCVIO) begin

  if (t.m_op == UNDEFINED) begin
    if (t.m_wr &&
        (t.m_addr > m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_reg_base_addr) &&
        (t.m_addr < m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_user_attr_base_addr)) begin
      sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_NULL;
      sinc_sb_pkt.m_mpu_req_tran      = t;
      sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_MPU_UNDEFINED_OP;

      // MPU UVC handles this error check
      sinc_sb_pkt.m_sinc_mpu_wr_err_types[`SINC_MPU_WR_ERR_RESERVED_BEFORE_ATTR_ADDR] = 1;
      `uvm_info(report_str, $sformatf("Sample finished MPU transaction with WR error type ['h%0h]",
          sinc_sb_pkt.m_sinc_mpu_wr_err_types), UVM_HIGH)
      m_completed_q.push_back(sinc_sb_pkt);
    end

    if (t.m_wr &&
        (t.m_addr > m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_user_attr_base_addr)) begin
      sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_NULL;
      sinc_sb_pkt.m_mpu_req_tran      = t;
      sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_MPU_UNDEFINED_OP;

      // MPU UVC handles this error check
      sinc_sb_pkt.m_sinc_mpu_wr_err_types[`SINC_MPU_WR_ERR_RESERVED_AFTER_ATTR_ADDR] = 1;
      sinc_sb_pkt.m_sinc_mpu_wr_err_types[`SINC_MPU_WR_ERR_CRYPTO_ADDR]              = 1;
      `uvm_info(report_str, $sformatf("Sample finished MPU transaction with WR error type ['h%0h]",
          sinc_sb_pkt.m_sinc_mpu_wr_err_types), UVM_HIGH)
      m_completed_q.push_back(sinc_sb_pkt);
    end

    if (!t.m_wr &&
        (t.m_addr > m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_reg_base_addr) &&
        (t.m_addr < m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_user_attr_base_addr)) begin
      sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_NULL;
      sinc_sb_pkt.m_mpu_req_tran      = t;
      sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_MPU_UNDEFINED_OP;

      // MPU UVC handles this error check
      sinc_sb_pkt.m_sinc_mpu_rd_err_types[`SINC_MPU_RD_ERR_RESERVED_BEFORE_ATTR_ADDR] = 1;
      `uvm_info(report_str, $sformatf("Sample finished MPU transaction with RD error type ['h%0h]",
          sinc_sb_pkt.m_sinc_mpu_rd_err_types), UVM_HIGH)
      m_completed_q.push_back(sinc_sb_pkt);
    end

    if (!t.m_wr &&
        (t.m_addr > m_configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0].m_user_attr_base_addr)) begin
      sinc_sb_pkt_entry               = sinc_env_pkg::ENTRY_NULL;
      sinc_sb_pkt.m_mpu_req_tran      = t;
      sinc_sb_pkt.m_sinc_sb_pkt_entry = sinc_env_pkg::ENTRY_MPU_UNDEFINED_OP;

      // MPU UVC handles this error check
      sinc_sb_pkt.m_sinc_mpu_rd_err_types[`SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR] = 1;
      sinc_sb_pkt.m_sinc_mpu_rd_err_types[`SINC_MPU_RD_ERR_CRYPTO_ADDR]              = 1;
      `uvm_info(report_str, $sformatf("Sample finished MPU transaction with RD error type ['h%0h]",
          sinc_sb_pkt.m_sinc_mpu_rd_err_types), UVM_HIGH)
      m_completed_q.push_back(sinc_sb_pkt);
    end
  end // if (t.m_op == REG_WRITE) begin

endfunction : write_sinc_mpu_ae

// FUNCTION: write_sinc_sideband_ae
// Transactions received through m_sinc_sideband_ae initiate the execution of this function.
// This function performs prediction of DUT output values based on DUT input, m_configuration and state
function void sinc_scoreboard::write_sinc_sideband_ae(sinc_monitor_pkg::sinc_sideband_e t);
  string report_str        = "WRITE_SINC_SIDEBAND_AE";
  bit    match_found       = 0;
  bit    self_check_result;

  `uvm_info("PRED", "Transaction Received through m_sinc_sideband_ae", UVM_MEDIUM)
  `uvm_info(report_str, $sformatf("Observe [%0s]",
      t.name()), UVM_HIGH)

  if (!m_sb_enable) begin
    return;
  end

  if (t == sinc_monitor_pkg::SINC_DONE_POSEDGE) begin
    foreach (m_inflight_q[i]) begin
      if (m_inflight_q[i].m_exp_sinc_done &&
          (m_inflight_q[i].m_sinc_done_q.size() == 0)) begin
        // don't count the sinc_done for erase when not most of the ram write seen
        // this is cause confusing when FW started while erase
        if (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CREG_ERASE) begin
          if (m_inflight_q[i].m_cache_mem_pkt_q.size() < (m_inflight_q[i].m_cache_mem_transaction_num - 10)) begin
            continue;
          end
        end
        match_found = 1;
        `uvm_info(report_str, $sformatf("Found match m_inflight_q for [%0s]",
            t.name()), UVM_HIGH)
        m_inflight_q[i].print_packet();
        m_inflight_q[i].inject_sinc_done(t);

        // If the m_inflight_q has completed
        // 1. Perform check on the packet;
        // 2. Create shallow copy of it for report phase in m_completed_q.
        if (m_inflight_q[i].is_completed(1)) begin
          sinc_sb_pkt_item completed_sb_pkt_item;

          // perform check on transaction itself
          self_check_result = m_inflight_q[i].self_check();

          // perform end to end check
          // check on the KEY memory by backdoor reads
          if (self_check_result) begin
            // leave for report info
          end

          completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
          if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
            `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
          end

          `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
              self_check_result? "PASS":"FAIL"), UVM_HIGH)
          m_inflight_q[i].print_packet();
          // m_completed_q.push_back(completed_sb_pkt_item);
          m_completed_q.push_back(m_inflight_q[i]);

          m_inflight_q.delete(i);
        end else begin
          if (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CREG_ERASE) begin
            // `uvm_error(report_str, $sformatf("received sinc done for SB entry[%0s], but the request is not completed", m_inflight_q[i].m_sinc_sb_pkt_entry.name()))
          end
        end
        break;
      end
    end

    if (!match_found) begin
      foreach (m_inflight_q[i]) begin
        m_inflight_q[i].print_packet();
        void'(m_inflight_q[i].is_completed(1));
      end
      `uvm_error(report_str, $sformatf("received unexpected sinc done [%0s], m_inflight_q.size[%0d]", t.name(), m_inflight_q.size()))
    end

  end // if (t == sinc_monitor_pkg::SINC_DONE_POSEDGE) begin

  if (t == sinc_monitor_pkg::SINC_ERROR_POSEDGE) begin
    foreach (m_inflight_q[i]) begin
      if (m_inflight_q[i].m_exp_sinc_error &&
          (m_inflight_q[i].m_sinc_error_q.size() < m_inflight_q[i].m_sinc_error_num)) begin
        match_found = 1;
        `uvm_info(report_str, $sformatf("Found match m_inflight_q for [%0s]",
            t.name()), UVM_HIGH)
        m_inflight_q[i].print_packet();
        m_inflight_q[i].inject_sinc_error(t);

        // If the m_inflight_q has completed
        // 1. Perform check on the packet;
        // 2. Create shallow copy of it for report phase in m_completed_q.
        if (m_inflight_q[i].is_completed(1)) begin
          sinc_sb_pkt_item completed_sb_pkt_item;

          // perform check on transaction itself
          self_check_result = m_inflight_q[i].self_check();

          // perform end to end check
          // check on the KEY memory by backdoor reads
          if (self_check_result) begin
            // leave for report info
          end

          completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
          if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
            `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
          end

          `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
              self_check_result? "PASS":"FAIL"), UVM_HIGH)
          m_inflight_q[i].print_packet();
          // m_completed_q.push_back(completed_sb_pkt_item);
          m_completed_q.push_back(m_inflight_q[i]);

          m_inflight_q.delete(i);
        end else begin
          if (m_inflight_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CREG_ERASE) begin
            // `uvm_error(report_str, $sformatf("received sinc error for SB entry[%0s], but the request is not completed", m_inflight_q[i].m_sinc_sb_pkt_entry.name()))
          end
        end
        break;
      end
    end

    if (!match_found) begin
      bit found_uncompleted_fw_cmd = 0;

      // look for fw commands when AXI error injection enabled
      if (m_configuration.m_sys_cfg.m_sinc_tb_axi_err_injection_en) begin
        `uvm_info(report_str, $sformatf("Look for m_inflight_q for match due to SINC_TB_AXI_ERR_INJECTION_EN[%0d]",
            m_configuration.m_sys_cfg.m_sinc_tb_axi_err_injection_en), UVM_HIGH)
        foreach (m_inflight_q[i]) begin
          `uvm_info(report_str, $sformatf("Print m_inflight_q[%0d] for debug:",
              i), UVM_HIGH)
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));

          if (m_inflight_q[i].m_is_fw_cmd && !m_inflight_q[i].is_completed(0) &&
              (m_inflight_q[i].m_exp_axi_mgr_rd_req || m_inflight_q[i].m_exp_axi_mgr_wr_req)) begin
            found_uncompleted_fw_cmd = 1;
            m_inflight_q[i].inject_sinc_error(t);

            if (m_inflight_q[i].is_completed(1)) begin
              sinc_sb_pkt_item completed_sb_pkt_item;

              // perform check on transaction itself
              self_check_result = m_inflight_q[i].self_check();

              // perform end to end check
              // check on the KEY memory by backdoor reads
              if (self_check_result) begin
                // leave for report info
              end

              completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
              if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
                `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
              end

              `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                                              self_check_result? "PASS":"FAIL"), UVM_HIGH)
              m_inflight_q[i].print_packet();
              // m_completed_q.push_back(completed_sb_pkt_item);
              m_completed_q.push_back(m_inflight_q[i]);

              m_inflight_q.delete(i);
            end
            break;
          end
        end
      end

      // look for fw commands when AXI write response phase not been seen
      foreach (m_inflight_q[i]) begin
        `uvm_info(report_str, $sformatf("Print m_inflight_q[%0d] for debug:",
            i), UVM_HIGH)
        m_inflight_q[i].print_packet();
        void'(m_inflight_q[i].is_completed(1));

        if (m_inflight_q[i].m_is_fw_cmd && !m_inflight_q[i].is_completed(0) &&
            (m_inflight_q[i].m_axi_sub_wr_resp_tran_q.size() == 0)) begin
          bit found_match_cpu_rd = 0;
          found_uncompleted_fw_cmd = 1;
          `uvm_info(report_str, $sformatf("Found m_inflight_q[%0d] to inject SINC_E-R-R-O-R:",
                                          i), UVM_HIGH)

          // corner case that a FW OP was rejected due to adjacent CPU MEM RD start block fetch
          if (m_inflight_q[i].m_exp_sinc_done) begin
            foreach (m_inflight_q[j]) begin
              `uvm_info(report_str, $sformatf("Print m_inflight_q[%0d]/totoal of [%0d] for debug: corner case that a FW OP was rejected due to adjacent CPU MEM RD start block fetch",
                                              j, m_inflight_q.size()), UVM_HIGH)
              m_inflight_q[j].print_packet();
              if ((m_inflight_q[j].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) &&
                  (!m_inflight_q[j].is_completed(0)) &&
                  m_inflight_q[j].m_exp_block_fetch) begin
                `uvm_info(report_str, $sformatf("Found m_inflight_q[%0d] matching : a FW OP was rejected due to adjacent CPU MEM RD start block fetch",
                                          i), UVM_HIGH)
                found_match_cpu_rd = 1;
              end
            end
          end
          if (found_match_cpu_rd) begin
            m_inflight_q[i].m_fw_op_invalid_due_to_adjacent_block_fetch = 1;
          end
          m_inflight_q[i].inject_sinc_error(t);

          if (m_inflight_q[i].is_completed(1)) begin
            sinc_sb_pkt_item completed_sb_pkt_item;

            // perform check on transaction itself
            self_check_result = m_inflight_q[i].self_check();

            // perform end to end check
            // check on the KEY memory by backdoor reads
            if (self_check_result) begin
              // leave for report info
            end

            completed_sb_pkt_item = sinc_sb_pkt_item::type_id::create("completed_sb_pkt_item");
            if (!$cast(completed_sb_pkt_item, m_inflight_q[i].clone())) begin
              `uvm_fatal("CAST", "Could not cast completed_sb_pkt_item")
            end

            `uvm_info(report_str, $sformatf("Print finished transaction with its SB_PKT_ITEM, the check result is [%0s]",
                                            self_check_result? "PASS":"FAIL"), UVM_HIGH)
            m_inflight_q[i].print_packet();
            // m_completed_q.push_back(completed_sb_pkt_item);
            m_completed_q.push_back(m_inflight_q[i]);

            m_inflight_q.delete(i);
          end
          break;
        end
      end

      if (!found_uncompleted_fw_cmd) begin
        foreach (m_inflight_q[i]) begin
          m_inflight_q[i].print_packet();
          void'(m_inflight_q[i].is_completed(1));
        end
        `uvm_error(report_str, $sformatf("received unexpected sinc error [%0s], m_inflight_q.size[%0d]", t.name(), m_inflight_q.size()))
      end
    end

  end // if (t == sinc_monitor_pkg::SINC_ERROR_POSEDGE) begin

endfunction : write_sinc_sideband_ae

function void sinc_scoreboard::process_plusargs();
  string debug_str = "SINC_SB_PROCESS_PLUSARGS";
  string tmp_str;

  tmp_str = "SINC_SB_ENABLE";
  if($value$plusargs({tmp_str, "=%d"}, m_sb_enable)) begin
    `uvm_info(get_name(), $sformatf("%s from plusarg = %d", tmp_str, m_sb_enable), UVM_LOW)
  end

endfunction : process_plusargs

function void sinc_scoreboard::check_phase(uvm_phase phase);
  string report_str = "SINC_SB_CHECK_PHASE";
  super.check_phase(phase);

  if (m_inflight_q.size()) begin
    int is_ignored_cnt = 0;
    `uvm_info(report_str, $sformatf("[%0d] transactions pending in the m_inflight_q when reaching check phase.",
                                    m_inflight_q.size()), UVM_HIGH)
    foreach (m_inflight_q[i]) begin
      m_inflight_q[i].print_packet();
      // void'(m_inflight_q[i].is_completed(1));

      if (!m_inflight_q[i].is_completed(1)) begin
        `uvm_error(report_str, $sformatf("[%0d] transactions pending in the m_inflight_q when reaching check phase, please make sure all the pending requests are completed", m_inflight_q.size()))
      end
      // only ignore CPU transaction with MPU violation pending, under non blocking CPU config
      if (m_configuration.m_sys_cfg.m_sinc_tb_seq_use_non_blocking_cpu_read &&
          ((m_inflight_q[i].m_sinc_sb_pkt_entry == ENTRY_CPU_READ) || (m_inflight_q[i].m_sinc_sb_pkt_entry == ENTRY_CPU_WRITE)) ||
          (m_inflight_q[i].m_exp_mpu_err_accvio && (m_inflight_q[i].m_mpu_err_accvio_q.size() == 0))
          ) begin
        // is_ignored_cnt ++;
      end else begin
        //
      end
    end

    if (is_ignored_cnt !== m_inflight_q.size()) begin
      // `uvm_error(report_str, $sformatf("[%0d] transactions pending in the m_inflight_q when reaching check phase, please make sure all the pending requests are completed", m_inflight_q.size()))
    end
  end

  if (m_cov_enable) begin
    foreach (m_completed_q[i]) begin
      `uvm_info(report_str, $sformatf("Sample function coverage on transaction [%0d].",
          i), UVM_HIGH)

      // collecting error conditions into error injection types
      // AXI READ
      if (m_completed_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_READ) begin
        // SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS
        if (m_completed_q[i].m_erase_during_req_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS
        if (m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS] = 1;
        end

        // code coverage, functional coverage can not cover this
        if (m_completed_q[i].m_erase_during_req_inprogress || m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME] = 1;
        end

      end

      // AXI WRITE
      if (m_completed_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_AXI_SUB_WRITE) begin
        // SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS
        if (m_completed_q[i].m_erase_during_req_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS
        if (m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS] = 1;
        end

        // code coverage, functional coverage can not cover this
        if (m_completed_q[i].m_erase_during_req_inprogress || m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY
        if (m_completed_q[i].m_axi_access_while_cmu_busy) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY] = 1;
        end

      end

      // CPU READ
      if (m_completed_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_READ) begin
        // SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS
        if (m_completed_q[i].m_erase_during_req_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS
        if (m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS] = 1;
        end

        // code coverage, functional coverage can not cover this
        if (m_completed_q[i].m_erase_during_req_inprogress || m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS
        if (m_completed_q[i].m_cpu_access_while_axi_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS
        if (m_completed_q[i].m_axi_access_while_cpu_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME
        if (m_completed_q[i].m_cpu_access_while_axi_inprogress || m_completed_q[i].m_axi_access_while_cpu_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY
        if (m_completed_q[i].m_cpu_access_while_cmu_busy) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY] = 1;
        end





        // SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION
        if (!m_completed_q[i].m_is_mpu_allowed) begin
          m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION] = 1;
        end

        // SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT
        if (m_completed_q[i].m_cpu_access_when_non_cache_active_to_high_addr_map) begin
          m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] = 1;
        end

        //TODO DDC:  Not sure if this is the correct m_completed_q[i].m_* flag to base the coverage on.
        // if (m_completed_q[i].m_is_dmb_encrypt_data_write_error) begin
        //   m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK] =1
        // end

        // SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG
        if (m_completed_q[i].m_is_dmb_auth_tag_read_error) begin
          m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG] = 1;
        end

        // SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK
        if (m_completed_q[i].m_is_dmb_encrypt_data_read_error) begin
          m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] = 1;
        end

        // SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH
        if (m_completed_q[i].m_is_auth_tag_mismatch_error) begin
          m_completed_q[i].m_sinc_cpu_rd_err_types[`SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH] = 1;
        end

      end // CPU READ

      // CPU WRITE
      if (m_completed_q[i].m_sinc_sb_pkt_entry == sinc_env_pkg::ENTRY_CPU_WRITE) begin
        // SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS
        if (m_completed_q[i].m_erase_during_req_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS
        if (m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS] = 1;
        end

        // code coverage, functional coverage can not cover this
        if (m_completed_q[i].m_erase_during_req_inprogress || m_completed_q[i].m_access_while_erase_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS
        if (m_completed_q[i].m_cpu_access_while_axi_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS
        if (m_completed_q[i].m_axi_access_while_cpu_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS] = 1;
        end

        // SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME
        if (m_completed_q[i].m_cpu_access_while_axi_inprogress || m_completed_q[i].m_axi_access_while_cpu_inprogress) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME] = 1;
        end

        // SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY
        if (m_completed_q[i].m_cpu_access_while_cmu_busy) begin
          m_completed_q[i].m_sinc_stimulus_err_types[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY] = 1;
        end

        // SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION
        if (!m_completed_q[i].m_is_mpu_allowed) begin
          m_completed_q[i].m_sinc_cpu_wr_err_types[`SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION] = 1;
        end

        // SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT
        if (m_completed_q[i].m_cpu_access_when_non_cache_active_to_high_addr_map) begin
          m_completed_q[i].m_sinc_cpu_wr_err_types[`SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] = 1;
        end

        // SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE
        if (m_completed_q[i].m_exp_mpu_err_accvio && (m_completed_q[i].m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE)) begin
          m_completed_q[i].m_sinc_cpu_wr_err_types[`SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE] = 1;
        end
      end // CPU WRITE

      // m_completed_q[i].print_packet();
      if (i !== 0) begin
        m_sb_cov.sample_sb_pkt(m_completed_q[i], m_completed_q[i - 1]);
      end else begin
        m_sb_cov.sample_sb_pkt(m_completed_q[i], null);
      end
    end
  end

endfunction : check_phase

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_SCOREBOARD
