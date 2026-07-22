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
// File        : sinc_stimulus_packet.svh
// Description : This is the random packet controlling requests from interface's

`ifndef SINC_STIMULUS_PACKET
`define SINC_STIMULUS_PACKET

//---------------------------------
// HSP KSU Packet Class
//---------------------------------
class sinc_stimulus_packet extends sinc_base_packet;

  rand sinc_stimulus_type_t m_stimulus_sel;

  // Erase operation only needs to define delay
  rand int m_erase_mem_pre_delay;
  // AXI operation delays
  rand int m_axi_rd_pre_delay;
  rand int m_axi_wr_pre_delay;
  rand int m_cpu_rd_pre_delay;
  rand int m_cpu_wr_pre_delay;
  rand int m_mpu_rd_pre_delay;
  rand int m_mpu_wr_pre_delay;

  // decide AXI or CPU start first when concurrent transaction
  rand bit m_axi_before_cpu;

  //bits used to wait cause transactions to wait
  bit m_wait_for_axi_sub;
  bit m_wait_for_erase;
  bit m_wait_for_cpu;
  bit m_wait_for_w_cache = 0;
  bit m_wait_for_cmu_busy;
  bit m_do_cmu_busy;
  bit m_two_axi_wr;

  // rand variable control how many transaction sent repeatly
  rand int m_repeat_cpu_req_cnt;

  `uvm_object_utils(sinc_stimulus_packet)

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_stimulus_packet" );
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

  extern constraint stimulus_type_c;

  extern constraint packet_delay_c;

  extern constraint repeat_req_cnt_c;

endclass : sinc_stimulus_packet

constraint sinc_stimulus_packet::stimulus_type_c {
  // $countones(stimulus_sel) == 1;
  m_stimulus_sel dist {
    9'b000000001 := m_sys_cfg.m_sinc_tb_seq_axi_read_ratio, // AXI_RD
    9'b000000010 := m_sys_cfg.m_sinc_tb_seq_axi_write_ratio, // AXI_WR
    9'b000000100 := m_sys_cfg.m_sinc_tb_seq_cpu_read_ratio, // CPU_RD
    9'b000001000 := m_sys_cfg.m_sinc_tb_seq_cpu_write_ratio, // CPU_WR
    9'b000010000 := m_sys_cfg.m_sinc_tb_seq_erase_mem_ratio, // ERASE_MEM
    9'b000100000 := m_sys_cfg.m_sinc_tb_seq_mpu_read_ratio, // MPU_RD
    9'b001000000 := m_sys_cfg.m_sinc_tb_seq_mpu_write_ratio, // MPU_WR
    9'b010000000 := 0, // CLOCK_GATE
    9'b100000000 := m_sys_cfg.m_sinc_tb_seq_hw_reset_ratio // RESET
  };
}

constraint sinc_stimulus_packet::packet_delay_c {
  m_erase_mem_pre_delay dist { [1:100] := 50, 0 := 50 };

  m_axi_rd_pre_delay dist { [1:100] := 20, 0 := 80};

  m_axi_wr_pre_delay dist { [1:100] := 20, 0 := 80};

  m_cpu_rd_pre_delay dist { [1:100] := 20, 0 := 80};

  m_cpu_wr_pre_delay dist { [1:100] := 20, 0 := 80};

  m_mpu_rd_pre_delay dist { [1:100] := 20, 0 := 80};

  m_mpu_wr_pre_delay dist { [1:100] := 20, 0 := 80};
}

constraint sinc_stimulus_packet::repeat_req_cnt_c {
  m_repeat_cpu_req_cnt >= 0;
  m_repeat_cpu_req_cnt <= 20;
}


function void sinc_stimulus_packet::print_packet(int iter_n = 0);
  string str;
  int    idx =1;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Stimulus incoming[%0d]: \n", iter_n)};
  str = {str, $sformatf(" AXI   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD])};
  str = {str, $sformatf(" AXI   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR])};
  str = {str, $sformatf(" CPU   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD])};
  str = {str, $sformatf(" CPU   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR])};
  str = {str, $sformatf(" ERASE                  : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM])};
  str = {str, $sformatf(" MPU   - RD             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD])};
  str = {str, $sformatf(" MPU   - WR             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR])};
  str = {str, $sformatf(" CLOCK GATE             : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_CLOCK_GATE])};
  str = {str, $sformatf(" RESET                  : [%0d]\n", m_stimulus_sel[`SINC_STIMULUS_SEL_HW_RESET])};
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_SYS_CFG/COMPONENTS", str, UVM_NONE)
endfunction : print_packet

function void sinc_stimulus_packet::post_randomize ();

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

  // AXI UVC doesn't have data phase broadcast TLM, RTL can act on AXI Write's data phase, but scoreboard can only act on response phase
  // Limit the concurrent stimulus delay if it is AXI write and CPU R/W
  if (m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR] && m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD]) begin
    if (m_axi_before_cpu) begin
      m_axi_wr_pre_delay = 0;
      m_cpu_rd_pre_delay = m_cpu_rd_pre_delay + 8; // with zero delay config, it takes 8 cycles from AXI address phase to resp phase
    end else begin
      // m_axi_wr_pre_delay remain the same
      m_cpu_rd_pre_delay = 0;
    end
  end

  if (m_stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR] && m_stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
    if (m_axi_before_cpu) begin
      m_axi_wr_pre_delay = 0;
      m_cpu_wr_pre_delay = m_cpu_wr_pre_delay + 8; // with zero delay config, it takes 8 cycles from AXI address phase to resp phase
    end else begin
      // m_axi_wr_pre_delay remain the same
      m_cpu_rd_pre_delay = 0;
    end
  end
  
endfunction : post_randomize

`endif // SINC_STIMULUS_PACKET

