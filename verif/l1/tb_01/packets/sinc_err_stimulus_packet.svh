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
// File        : sinc_err_stimulus_packet.svh
// Description : This is the random packet controlling requests from interface's

`ifndef SINC_ERR_STIMULUS_PACKET
`define SINC_ERR_STIMULUS_PACKET

//---------------------------------
// HSP KSU Packet Class
//---------------------------------
class sinc_err_stimulus_packet extends sinc_stimulus_packet;

  typedef sinc_err_stimulus_packet this_t;

  `uvm_object_utils(sinc_err_stimulus_packet)

  //rand bits used to select between read and write in post randomize
  rand bit m_if_axi_do_read;
  rand bit m_if_cpu_do_read;

  // stimulus packet access violations
  rand logic [`SINC_STIMULUS_ERR_CASE_NUM-1: 0] m_stimuls_err_case_sel;

  // random dist var
  rand int m_override_w_cache_fail;
  rand int m_override_cpu_req_during_erase;
  rand bit m_erase_start_w_zero_delay;
    
  rand int m_custom_delay;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_err_stimulus_packet" );
    super.new(name);
  endfunction : new

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet(int iter_n = 0);

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint err_sel_c;
  extern constraint stimulus_type_c;
  extern constraint override_sel_c;
  extern constraint stimulus_packet_delay_c;

endclass : sinc_err_stimulus_packet

constraint sinc_err_stimulus_packet::err_sel_c {
  $countones(m_stimuls_err_case_sel) == 1;

  if((m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) || ((m_sys_cfg.m_sinc_tb_seq_w_cache_fail_ratio == 0))) {
    m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK] == 0;
  }

  if(m_sys_cfg.m_sinc_stimulus_always_erase_during) {
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] == 1) || (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] == 1);
  }

  if(m_sys_cfg.m_sinc_stimulus_always_cpu_during) {
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY] == 1);
  }
  

  if(m_sys_cfg.m_sinc_stimulus_always_axi_during) {
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME] == 1) || 
    (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY] == 1);
    
  }
}

constraint sinc_err_stimulus_packet::override_sel_c {
  m_override_w_cache_fail > 0;
  m_override_w_cache_fail <= 100;

  m_override_cpu_req_during_erase > 0;
  m_override_cpu_req_during_erase <= 100;
}



constraint sinc_err_stimulus_packet::stimulus_type_c {
  m_stimulus_sel dist {
    9'b000000001 := m_sys_cfg.m_sinc_tb_seq_axi_read_ratio, // AXI_RD
    9'b000000010 := m_sys_cfg.m_sinc_tb_seq_axi_write_ratio, // AXI_WR
    9'b000000100 := m_sys_cfg.m_sinc_tb_seq_cpu_read_ratio, // CPU_RD
    9'b000001000 := m_sys_cfg.m_sinc_tb_seq_cpu_write_ratio, // CPU_WR
    9'b000010000 := m_sys_cfg.m_sinc_tb_seq_erase_mem_ratio, // ERASE_MEM
    9'b000100000 := m_sys_cfg.m_sinc_tb_seq_mpu_read_ratio, // MPU_RD
    9'b001000000 := m_sys_cfg.m_sinc_tb_seq_mpu_write_ratio, // MPU_WR
    9'b010000000 := 0, // CLOCK_GATE
    9'b100000000 := m_sys_cfg.m_sinc_tb_seq_hw_reset_ratio, // RESET
    9'b000010001 := 0, // ERASE_MEM & AXI_RD handled in post randomize
    9'b000010010 := 0, // ERASE_MEM & AXI_WR handled in post randomize
    9'b000010100 := 0, // ERASE_MEM & CPU_RD handled in post randomize
    9'b000011000 := 0, // ERASE_MEM & CPU_WR handled in post randomize
    9'b000000110 := 0, // CPU_RD & AXI_WR, to get axi rd during cpu busy, handled in post randomize
    9'b000000101 := 0 // CPU_RD & AXI_RD, to get axi wr during cpu busy, handled in post randomize
  };
}

constraint sinc_err_stimulus_packet::stimulus_packet_delay_c {
  m_custom_delay dist { 0 := 20, [1:5] := 30, [5:50] := 50 };  
    
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS]) -> { (m_axi_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS]) -> { (m_axi_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS]) -> { m_erase_mem_pre_delay dist {[1:5]}; }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS]) -> { m_axi_rd_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS]) -> { m_axi_wr_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS]) -> { (m_erase_mem_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_axi_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_axi_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_erase_mem_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS]) -> { (m_cpu_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS]) -> { (m_cpu_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS]) -> { m_erase_mem_pre_delay dist {[1:15]}; }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK]) -> { (m_cpu_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK]) -> { (m_cpu_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK]) -> { (m_erase_mem_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS]) -> { m_cpu_rd_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS]) -> { m_cpu_wr_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS]) -> { (m_erase_mem_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_cpu_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_cpu_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME]) -> { (m_erase_mem_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS]) -> { (m_axi_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS]) -> { (m_axi_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS]) -> { m_cpu_rd_pre_delay dist {[1:5]}; }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS]) -> { m_axi_rd_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS]) -> { m_axi_wr_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS]) -> { (m_cpu_rd_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME]) -> { (m_axi_rd_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME]) -> { (m_axi_wr_pre_delay == 0); }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME]) -> { (m_cpu_rd_pre_delay == 0); }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY]) -> { m_axi_rd_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY]) -> { m_axi_wr_pre_delay dist {[1:5]}; }

  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY]) -> { m_cpu_rd_pre_delay dist {[1:5]}; }
  (m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY]) -> { m_cpu_wr_pre_delay dist {[1:5]}; }

}

function void sinc_err_stimulus_packet::print_packet(int iter_n = 0);
  string str;
  int    idx =1;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" AXI   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD])};
  str = {str, $sformatf(" AXI   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR])};
  str = {str, $sformatf(" CPU   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD])};
  str = {str, $sformatf(" CPU   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR])};
  str = {str, $sformatf(" ERASE                  : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM])};
  str = {str, $sformatf(" MPU   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD])};
  str = {str, $sformatf(" MPU   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR])};
  str = {str, $sformatf(" CLOCK GATE             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CLOCK_GATE])};
  str = {str, $sformatf(" RESET                  : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_HW_RESET])};
  str = {str, $sformatf(" m_stimuls_err_case_sel : ['b%0b]\n", m_stimuls_err_case_sel)};
  str = {str, $sformatf(" erase_mem_pre_delay    : [%0d]\n", m_erase_mem_pre_delay)};
  str = {str, $sformatf(" axi_rd_pre_delay       : [%0d]\n", m_axi_rd_pre_delay)};
  str = {str, $sformatf(" axi_wr_pre_delay       : [%0d]\n", m_axi_wr_pre_delay)};

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_SYS_CFG/COMPONENTS", str, UVM_NONE)
endfunction : print_packet

function void sinc_err_stimulus_packet::post_randomize ();

  m_wait_for_axi_sub  = 0;
  m_wait_for_erase    = 0;
  m_wait_for_cpu      = 0;
  m_wait_for_cmu_busy = 0;
  m_do_cmu_busy       = 0;
  m_two_axi_wr        = 0;

  if (m_sys_cfg.m_sinc_tb_seq_always_en_back_2_back) begin
    m_erase_mem_pre_delay = 0;
    m_axi_rd_pre_delay = 0;
    m_cpu_rd_pre_delay = 0;
    m_cpu_wr_pre_delay = 0;
    m_mpu_rd_pre_delay = 0;
    m_mpu_wr_pre_delay = 0;
  end

  if(m_sys_cfg.m_sinc_stimulus_always_cpu_erase_same) begin
    m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME] = 1;
    m_cpu_rd_pre_delay = 0;
    m_cpu_wr_pre_delay = 0;
    m_erase_mem_pre_delay = 0;
  end

  if ((m_sys_cfg.m_sinc_tb_seq_w_cache_fail_ratio > 0) &&
      (m_override_w_cache_fail > (100 - m_sys_cfg.m_sinc_tb_seq_w_cache_fail_ratio))) begin
    m_stimuls_err_case_sel                                                   = 0;
    m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK] = 1;
  end

  if ((m_sys_cfg.m_sinc_tb_seq_cpu_req_during_erase_ratio > 0) &&
      (m_override_cpu_req_during_erase > (100 - m_sys_cfg.m_sinc_tb_seq_cpu_req_during_erase_ratio))) begin
    m_stimuls_err_case_sel                                                   = 0;
    m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS] = 1;
  end

  if ((m_sys_cfg.m_sinc_tb_seq_erase_during_cpu_req_ratio > 0) &&
      (m_override_cpu_req_during_erase > (100 - m_sys_cfg.m_sinc_tb_seq_erase_during_cpu_req_ratio))) begin
    m_stimuls_err_case_sel                                                   = 0;
    m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] = 1;
          
    if (m_erase_start_w_zero_delay) begin
       m_erase_mem_pre_delay = 0;
    end else begin
       m_erase_mem_pre_delay = m_custom_delay;
    end
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME]) begin
    if(m_if_axi_do_read) begin
      m_stimulus_sel = 9'b000010001;
    end else begin
      m_stimulus_sel = 9'b000010010;
    end
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME]) begin
    if(m_if_cpu_do_read) begin
      m_stimulus_sel = 9'b000010100;
    end else begin
      m_stimulus_sel = 9'b000011000;
    end
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME]) begin
    if(m_if_axi_do_read) begin
      if(m_if_cpu_do_read) begin
        m_stimulus_sel = 9'b000000101;
      end else begin
        m_stimulus_sel = 9'b000001001;
      end
    end else begin
      if(m_if_cpu_do_read) begin
        m_stimulus_sel = 9'b000000110;
      end else begin
        m_stimulus_sel = 9'b000001010;
      end
    end
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS]) begin
    m_wait_for_axi_sub = 1;
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS]) begin
    m_wait_for_erase = 1;
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS]) begin
    m_wait_for_cpu = 1;
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY] ||
      m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY]) begin
    m_wait_for_cmu_busy = 1;
    m_do_cmu_busy       = 1;
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY]) begin
    if(m_if_axi_do_read) begin
      m_stimulus_sel = 9'b000000011;
    end else begin
      m_stimulus_sel = 9'b000000010;
      m_two_axi_wr   = 1;
    end
  end

  if(m_stimuls_err_case_sel[`SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY]) begin
    if(m_if_cpu_do_read) begin
      m_stimulus_sel = 9'b000000110;
    end else begin
      m_stimulus_sel = 9'b000001010;
    end
  end
endfunction : post_randomize

`endif // SINC_ERR_STIMULUS_PACKET
