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
// File        : sinc_transaction_packet.svh
// Description : This is the random packet includes each interfaces' stimulus per

`ifndef SINC_TRANSACTION_PACKET
`define SINC_TRANSACTION_PACKET

//---------------------------------
// HSP SINC Packet Class
//---------------------------------
class sinc_transaction_packet extends sinc_base_packet;

  typedef sinc_transaction_packet this_t;

  rand sinc_axi_packet m_axi_rd_tran;
  rand sinc_axi_packet m_axi_wr_tran;
  rand sinc_axi_packet m_axi_wr_tran2;
  rand sinc_cpu_packet m_cpu_rd_tran;
  rand sinc_cpu_packet m_cpu_wr_tran;
  rand sinc_mpu_packet m_mpu_rd_tran;
  rand sinc_mpu_packet m_mpu_wr_tran;

  // Erase operation only needs to define delay
  rand int m_erase_mem_pre_delay;
  rand int m_erase_mem_post_delay;

  // Reset operation only needs to define delay
  rand int m_reset_pre_delay;
  rand int m_reset_post_delay;

  `uvm_object_utils(sinc_transaction_packet)

  //---------------------------------
  // Constructor
  //---------------------------------
  extern function new(string name = "sinc_transaction_packet");

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_stimulus_packet(int iter_n = 0, sinc_stimulus_type_t stimulus_sel);

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint erase_packet_delay_c;

endclass : sinc_transaction_packet


constraint sinc_transaction_packet::erase_packet_delay_c {
  m_erase_mem_pre_delay dist {
    [1:100] := 20,
    0       := 80
  };

  m_erase_mem_post_delay dist {
    [1:100] := 20,
    0       := 80
  };
}


function sinc_transaction_packet::new(string name = "sinc_transaction_packet");
  super.new(name);
  m_axi_rd_tran           = sinc_axi_packet::type_id::create("m_axi_rd_tran");
  m_axi_rd_tran.m_axi_cmd = SINC_AXI_SUB_READ;

  m_axi_wr_tran           = sinc_axi_packet::type_id::create("m_axi_wr_tran");
  m_axi_wr_tran.m_axi_cmd = SINC_AXI_SUB_WRITE;

  m_axi_wr_tran2           = sinc_axi_packet::type_id::create("m_axi_wr_tran2");
  m_axi_wr_tran2.m_axi_cmd = SINC_AXI_SUB_WRITE;

  m_cpu_rd_tran         = sinc_cpu_packet::type_id::create("m_cpu_rd_tran");
  m_cpu_rd_tran.m_cpu_cmd = SINC_CPU_READ_TRN;

  m_cpu_wr_tran         = sinc_cpu_packet::type_id::create("m_cpu_wr_tran");
  m_cpu_wr_tran.m_cpu_cmd = SINC_CPU_WRITE_TRN;

  m_mpu_rd_tran            = sinc_mpu_packet::type_id::create("m_mpu_rd_tran");
  m_mpu_rd_tran.m_is_write = 0;

  m_mpu_wr_tran            = sinc_mpu_packet::type_id::create("m_mpu_wr_tran");
  m_mpu_wr_tran.m_is_write = 1;
endfunction : new

function void sinc_transaction_packet::print_stimulus_packet(int iter_n = 0, sinc_stimulus_type_t stimulus_sel);
  string str;

  `uvm_info(get_name(), $sformatf("SINC_TRANSACTION_PACKET [%0d], Stimulus_sel['b%0b] \n",
      iter_n, stimulus_sel), UVM_LOW)

  if (stimulus_sel[`SINC_STIMULUS_SEL_AXI_RD]) begin
    `uvm_info(get_name(), $sformatf("SINC_AXI_RD_PACKET [%0d] \n",
        iter_n), UVM_LOW)
    m_axi_rd_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_AXI_WR]) begin
    `uvm_info(get_name(), $sformatf("SINC_AXI_WR_PACKET[%0d] \n",
        iter_n), UVM_LOW)
    m_axi_wr_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_RD]) begin
    `uvm_info(get_name(), $sformatf("SINC_CPU_RD_PACKET [%0d] \n",
        iter_n), UVM_LOW)
    m_cpu_rd_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_CPU_MEM_WR]) begin
    `uvm_info(get_name(), $sformatf("SINC_CPU_WR_PACKET[%0d] \n",
        iter_n), UVM_LOW)
    m_cpu_wr_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_ERASE_MEM]) begin
    `uvm_info(get_name(), $sformatf("SINC_ERASE_MEM_PACKET [%0d], with pre_delay[%0d], post_delay[%0d]\n",
        iter_n, m_erase_mem_pre_delay, m_erase_mem_post_delay), UVM_LOW)
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_MPU_RD]) begin
    `uvm_info(get_name(), $sformatf("SINC_MPU_RD_PACKET [%0d] \n",
        iter_n), UVM_LOW)
    m_mpu_rd_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_MPU_WR]) begin
    `uvm_info(get_name(), $sformatf("SINC_MPU_WR_PACKET[%0d] \n",
        iter_n), UVM_LOW)
    m_mpu_wr_tran.print_packet(iter_n);
  end
  if (stimulus_sel[`SINC_STIMULUS_SEL_HW_RESET]) begin
    `uvm_info(get_name(), $sformatf("KV_RESET_PACKET [%0d], with pre_delay[%0d], post_delay[%0d]\n",
        iter_n, m_reset_pre_delay, m_reset_post_delay), UVM_LOW)
  end

endfunction : print_stimulus_packet

`endif // SINC_TRANSACTION_PACKET
