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
// File        : sinc_mpu_err_inj_packet.svh
// Description : This is MPU packet used to randomize error injection for MPU requests to SINC.

`ifndef SINC_MPU_ERR_INJ_PACKET
`define SINC_MPU_ERR_INJ_PACKET

//---------------------------------
// SINC MPU Packet Class
//---------------------------------
class sinc_mpu_err_inj_packet extends sinc_base_packet;

  typedef sinc_mpu_err_inj_packet this_t;

  `uvm_object_utils(sinc_mpu_err_inj_packet)

  // debug_str
  string          m_debug_str       = "SINC_MPU_ERR_INJ_PACKET";
  // original AXI packet
  sinc_mpu_packet m_orig_mpu_packet;

  // indicate error has been injected
  bit m_err_injected = 0;

  // Negative test scenarios refer to verification plan - "Key Vault Test Scenario Across TB Platform"

  // RD mpu violations
  rand logic [`SINC_MPU_RD_ERR_CASE_NUM-1: 0] m_mpu_rd_err_case_sel;

  // WR mpu violations
  rand logic [`SINC_MPU_WR_ERR_CASE_NUM-1: 0] m_mpu_wr_err_case_sel;

  rand ccpui_mpu_addr_t m_invalid_before_attr_addr_offset;
  rand logic [31:0] m_invalid_crypto_attr_addr_offset;
  rand logic [31:0] m_invalid_after_attr_addr_offset;
  
  // rand ccpui_mpu_addr_t m_invalid_crypto_attr_addr_offset;
  // rand ccpui_mpu_addr_t m_invalid_after_attr_addr_offset;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_mpu_err_inj_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // pre_randomize()
  //---------------------------------
  function void pre_randomize ();
    string debug_str = "sinc_mpu_err_inj_packet_pre_randomize";
    if (m_orig_mpu_packet == null) begin
      `uvm_fatal(get_name(), $sformatf("%s: Must set original MPU packet before error injection", debug_str))
    end

    // digest the request
  endfunction : pre_randomize

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // corrupt_mpu_rd()
  //---------------------------------
  extern virtual function void corrupt_mpu_rd();

  //---------------------------------
  // corrupt_mpu_wr()
  //---------------------------------
  extern virtual function void corrupt_mpu_wr();

  //---------------------------------
  // mpu_corrupt_reserved_before_attr_addr
  //---------------------------------
  extern virtual function void mpu_corrupt_reserved_before_attr_addr(ref string str);

  //---------------------------------
  // mpu_corrupt_reserved_after_attr_addr
  //---------------------------------
  extern virtual function void mpu_corrupt_reserved_after_attr_addr(ref string str);

  //---------------------------------
  // mpu_corrupt_cryto_attr_addr
  //---------------------------------
  extern virtual function void mpu_corrupt_cryto_attr_addr(ref string str);

  //---------------------------------
  // mpu_corrupt_write_mpu_status_read_only_bits
  //---------------------------------
  extern virtual function void mpu_corrupt_write_mpu_status_read_only_bits(ref string str);

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint err_sel_c;

  extern constraint invalid_addr_offset_c;

endclass : sinc_mpu_err_inj_packet

function void sinc_mpu_err_inj_packet::post_randomize ();

  if (m_orig_mpu_packet.m_is_write == 'h0) begin
    corrupt_mpu_rd();
  end

  if (m_orig_mpu_packet.m_is_write == 'h1) begin
    corrupt_mpu_wr();
  end

endfunction : post_randomize

function void sinc_mpu_err_inj_packet::corrupt_mpu_rd();
  string str;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_mpu_rd_err_case_sel : `h'h%0h \n", m_mpu_rd_err_case_sel)};
  if (m_mpu_rd_err_case_sel[`SINC_MPU_RD_ERR_RESERVED_BEFORE_ATTR_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_RD_ERR_RESERVED_BEFORE_ATTR_ADDR] : `h'h%0h \n", m_mpu_rd_err_case_sel)};
    mpu_corrupt_reserved_before_attr_addr (str);
  end
  if (m_mpu_rd_err_case_sel[`SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR] : `h'h%0h \n", m_mpu_rd_err_case_sel)};
    mpu_corrupt_reserved_after_attr_addr (str);
  end
  if (m_mpu_rd_err_case_sel[`SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR] : `h'h%0h \n", m_mpu_rd_err_case_sel)};
    mpu_corrupt_cryto_attr_addr (str);
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_MPU_RD", str, UVM_HIGH)

endfunction : corrupt_mpu_rd

function void sinc_mpu_err_inj_packet::corrupt_mpu_wr();
  string str;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_mpu_wr_err_case_sel : `h'h%0h \n", m_mpu_wr_err_case_sel)};

  if (m_mpu_wr_err_case_sel[`SINC_MPU_WR_ERR_RESERVED_BEFORE_ATTR_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_WR_ERR_RESERVED_BEFORE_ATTR_ADDR] : `h'h%0h \n", m_mpu_wr_err_case_sel)};
    mpu_corrupt_reserved_before_attr_addr (str);
  end
  if (m_mpu_wr_err_case_sel[`SINC_MPU_WR_ERR_RESERVED_AFTER_ATTR_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_WR_ERR_RESERVED_AFTER_ATTR_ADDR] : `h'h%0h \n", m_mpu_wr_err_case_sel)};
    mpu_corrupt_reserved_after_attr_addr (str);
  end
  if (m_mpu_wr_err_case_sel[`SINC_MPU_WR_ERR_CRYPTO_ADDR]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_WR_ERR_CRYPTO_ADDR] : `h'h%0h \n", m_mpu_wr_err_case_sel)};
    mpu_corrupt_cryto_attr_addr (str);
  end
  if (m_mpu_wr_err_case_sel[`SINC_MPU_WR_ERR_STATUS_ADDR_RD_ONLY_BITS]) begin
    str = {str, $sformatf("error injected for [SINC_MPU_WR_ERR_STATUS_ADDR_RD_ONLY_BITS] : `h'h%0h \n", m_mpu_wr_err_case_sel)};
    mpu_corrupt_write_mpu_status_read_only_bits (str);
  end

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_MPU_WR", str, UVM_HIGH)

endfunction : corrupt_mpu_wr

function void sinc_mpu_err_inj_packet::mpu_corrupt_reserved_before_attr_addr(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [ACCESS_BEFORE_ATTR_BASE_ADDR], original: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

  m_orig_mpu_packet.m_do_generic_access = 1;
  m_orig_mpu_packet.m_addr              = m_invalid_before_attr_addr_offset;

  str = {str, $sformatf(" Corrupt request with [ACCESS_BEFORE_ATTR_BASE_ADDR], corrupted: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

endfunction : mpu_corrupt_reserved_before_attr_addr

function void sinc_mpu_err_inj_packet::mpu_corrupt_reserved_after_attr_addr(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [ACCESS_BEFORE_ATTR_BASE_ADDR], original: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

  m_orig_mpu_packet.m_do_generic_access = 1;
  m_orig_mpu_packet.m_addr              = m_invalid_after_attr_addr_offset;

  str = {str, $sformatf(" Corrupt request with [ACCESS_BEFORE_ATTR_BASE_ADDR], corrupted: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

endfunction : mpu_corrupt_reserved_after_attr_addr

function void sinc_mpu_err_inj_packet::mpu_corrupt_cryto_attr_addr(ref string str);

  m_err_injected = 1;

  m_orig_mpu_packet.m_do_generic_access = 1;
  m_orig_mpu_packet.m_addr              = m_invalid_crypto_attr_addr_offset;

  str = {str, $sformatf(" Corrupt request with [ACCESS_CRYPTO_ATTR_BASE_ADDR], corrupted: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

endfunction : mpu_corrupt_cryto_attr_addr

function void sinc_mpu_err_inj_packet::mpu_corrupt_write_mpu_status_read_only_bits(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [ACCESS_CRYPTO_ATTR_BASE_ADDR], original: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

  m_orig_mpu_packet.m_do_generic_access = 1;
  m_orig_mpu_packet.m_addr              = 0;

  str = {str, $sformatf(" Corrupt request with [ACCESS_BEFORE_ATTR_BASE_ADDR], corrupted: %s \n", m_orig_mpu_packet.m_mpu_cmd.name())};

endfunction : mpu_corrupt_write_mpu_status_read_only_bits

function void sinc_mpu_err_inj_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Corrupt MPU Request on Iter_Num [%0d]: \n", iter_n)};

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_MPU_ERR_INJ_PACKET", str, UVM_HIGH)

endfunction : print_packet

constraint sinc_mpu_err_inj_packet::err_sel_c {
  $countones(m_mpu_wr_err_case_sel) == 1;
  $countones(m_mpu_rd_err_case_sel) == 1;
}

constraint sinc_mpu_err_inj_packet::invalid_addr_offset_c {
  m_invalid_before_attr_addr_offset[1:0] == 2'b0;
  m_invalid_crypto_attr_addr_offset[1:0] == 2'b0;
  m_invalid_after_attr_addr_offset[1:0] == 2'b0;

  m_invalid_before_attr_addr_offset != 0;
  m_invalid_before_attr_addr_offset < 'h1000;

  // the MAX MPU address given IRAM size in a prior project is 1FFF
  m_invalid_crypto_attr_addr_offset >= ('h1000 + ((SINC_MEM_NUM_PAGES / 8) * 4 * 2));
  m_invalid_crypto_attr_addr_offset < ('h1000 + ((SINC_MEM_NUM_PAGES / 8) * 4 * 3));
  m_invalid_after_attr_addr_offset >= ('h1000 + ((SINC_MEM_NUM_PAGES / 8) * 4 * 3));
  m_invalid_after_attr_addr_offset < ('h1000 + ((SINC_MEM_NUM_PAGES / 8) * 4 * 4));
}

`endif // SINC_MPU_ERR_INJ_PACKET
