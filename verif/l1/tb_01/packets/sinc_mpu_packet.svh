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
// File        : sinc_mpu_packet.svh
// Description : This is MPU packet used to randomize MPU requests to SINC.

`ifndef SINC_MPU_PACKET
`define SINC_MPU_PACKET

//---------------------------------
// SINC MPU Packet Class
//---------------------------------
class sinc_mpu_packet extends sinc_base_packet;

  typedef sinc_mpu_packet this_t;

  `uvm_object_utils(sinc_mpu_packet)

  // MPU Page Address - between 0 and 4096 => 12 bits
  rand bit [SINC_PAGE_SEL_WIDTH-1:0] m_page_num;

  // whether the transaction is a write,  default as read
  bit m_is_write = 0;

  bit              m_do_generic_access = 0;
  ccpui_mpu_addr_t m_addr              = 0;

  // MPU page_is_valid : 0-Invalid, 1-Valid
  rand bit m_is_valid_req;

  // write data for attribute write
  rand ccpui_mpu_data_t m_write_data;

  // read data for attribute and status reads
  ccpui_mpu_data_t m_read_data;

  //selects whether attr read/write is to user register, ignored during status trn
  rand bit m_is_trn_user_reg;

  //selects whether attr read/write is to priv register, ignored during status trn
  //should be 1 if user is 0 and 0 if user is 1, set in post random
  bit m_is_trn_priv_reg;

  // the mpu_cmd should preset by the sequence, default as attr read
  rand sinc_mpu_cmd_e m_mpu_cmd = sinc_env_pkg::SINC_MPU_ATTR_READ;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_mpu_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // print_packet()
  //---------------------------------
  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint req_is_valid_c;

  extern constraint cmd_type_c;

endclass : sinc_mpu_packet

function void sinc_mpu_packet::post_randomize ();

  if(m_is_trn_user_reg) begin
    m_is_trn_priv_reg = 0;
  end else begin
    m_is_trn_priv_reg = 1;
  end

  `uvm_info(get_name(), $sformatf("post_randomize\n"), UVM_LOW)
endfunction : post_randomize

function void sinc_mpu_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" MPU Request on Iter_Num [%0d]: \n", iter_n)};
  str = {str, $sformatf(" MPU CMD               : [%0s]\n", m_mpu_cmd.name())};
  str = {str, $sformatf(" MPU PAGE NUM          : ['h%0h]\n", m_page_num)};
  str = {str, $sformatf(" MPU IS WRITE          : ['h%0h]\n", m_is_write)};
  str = {str, $sformatf(" MPU IS_VALID_REQ      : [%0d]\n", m_is_valid_req)};
  if (m_is_write == 'h1) begin
    str = {str, $sformatf(" MPU ATTR WRITE DATA   : [%0d]\n", m_write_data )};
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_MPU_PACKET", str, UVM_HIGH)

endfunction : print_packet

// always valid
constraint sinc_mpu_packet::req_is_valid_c {
  m_is_valid_req == 1;
}

constraint sinc_mpu_packet::cmd_type_c {
  if(m_is_write) {
    m_mpu_cmd inside {SINC_MPU_ATTR_WRITE, SINC_MPU_STATUS_WRITE};
  } else {
    m_mpu_cmd inside {SINC_MPU_ATTR_READ, SINC_MPU_STATUS_READ};
  }
}

`endif // SINC_MPU_PACKET
