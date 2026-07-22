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
// File        : sinc_cpu_err_inj_packet.svh
// Description : This is CPU packet used to randomize error injection for CPU requests to SINC.

`ifndef SINC_CPU_ERR_INJ_PACKET
`define SINC_CPU_ERR_INJ_PACKET

//---------------------------------
// SINC CPU Packet Class
//---------------------------------
class sinc_cpu_err_inj_packet extends sinc_base_packet;

  typedef sinc_cpu_err_inj_packet this_t;

  `uvm_object_utils(sinc_cpu_err_inj_packet)

  // debug_str
  string          m_debug_str       = "SINC_CPU_ERR_INJ_PACKET";
  // original AXI packet
  sinc_cpu_packet m_orig_cpu_packet;

  // indicate error has been injected
  bit m_err_injected = 0;

  //flags to be used by sequence

  bit m_force_cache_blk_rd_failure = 0;
  bit m_force_auth_tag_rd_failure  = 0;

  //todo is this one actually possible? writing to sram doesn't have obvious error signal, possible covered by erase during fetch block
  bit m_force_cache_blk_wr_failure = 0;

  int m_disallowed_page_num;

  // Negative test scenarios refer to verification plan - "Key Vault Test Scenario Across TB Platform"

  // RD cpu violations
  rand logic [`SINC_CPU_RD_ERR_CASE_NUM-1: 0] m_cpu_rd_err_case_sel;

  // WR cpu violations
  rand logic [`SINC_CPU_WR_ERR_CASE_NUM-1: 0] m_cpu_wr_err_case_sel;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_cpu_err_inj_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // pre_randomize()
  //---------------------------------
  function void pre_randomize ();
    string debug_str = "sinc_cpu_err_inj_packet_pre_randomize";
    if (m_orig_cpu_packet == null) begin
      `uvm_fatal(get_name(), $sformatf("%s: Must set original CPU packet before error injection", debug_str))
    end

    // digest the request
  endfunction : pre_randomize

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // corrupt_cpu_rd()
  //---------------------------------
  extern virtual function void corrupt_cpu_rd();

  //---------------------------------
  // corrupt_cpu_wr()
  //---------------------------------
  extern virtual function void corrupt_cpu_wr();

  //---------------------------------
  // cpu_corrupt_addr_mpu_violation
  //---------------------------------
  extern virtual function void cpu_corrupt_addr_mpu_violation(ref string str);

  //---------------------------------
  // cpu_corrupt_addr_above_ciram
  //---------------------------------
  extern virtual function void cpu_corrupt_addr_above_ciram(ref string str);

  //---------------------------------
  // cpu_miss_fail_wr_cache_blk
  //---------------------------------
  extern virtual function void cpu_miss_fail_wr_cache_blk(ref string str);

  //---------------------------------
  // cpu_miss_fail_rd_auth_tag
  //---------------------------------
  extern virtual function void cpu_miss_fail_rd_auth_tag(ref string str);

  //---------------------------------
  // cpu_miss_fail_rd_cache_blk
  //---------------------------------
  extern virtual function void cpu_miss_fail_rd_cache_blk(ref string str);

  //---------------------------------
  // cpu_miss_fail_auth_tag_mismatch
  //---------------------------------
  extern virtual function void cpu_miss_fail_auth_tag_mismatch(ref string str);

  //---------------------------------
  // cpu_wr_access_during_cache_active
  //---------------------------------
  extern virtual function void cpu_wr_access_during_cache_active(ref string str);

  //---------------------------------
  // cpu_addr_cache_miss
  //---------------------------------
  extern virtual function void cpu_addr_cache_miss(ref string str);

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint err_sel_c;

endclass : sinc_cpu_err_inj_packet

function void sinc_cpu_err_inj_packet::post_randomize ();
  if (m_orig_cpu_packet.m_cpu_cmd == SINC_CPU_READ_TRN) begin
    int block_num = m_orig_cpu_packet.m_cpu_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL];
    //check if we are reading a not preloaded block an do not do additional corruption if so
    if((m_sys_cfg.m_skip_preload_blocks_map.exists(block_num)) && (m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE)) begin
      m_cpu_rd_err_case_sel = (1 << `SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH);
      `uvm_info(get_name(), $sformatf("found skipped block [%0d] so not injection another error", block_num), UVM_HIGH)
    end else begin
      corrupt_cpu_rd();
    end
  end

  if (m_orig_cpu_packet.m_cpu_cmd == SINC_CPU_WRITE_TRN) begin
    corrupt_cpu_wr();
  end

endfunction : post_randomize

function void sinc_cpu_err_inj_packet::corrupt_cpu_rd();
  string str;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_cpu_rd_err_case_sel : 'h%0h \n", m_cpu_rd_err_case_sel)};
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION]) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_corrupt_addr_mpu_violation (str);
  end
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT]) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_corrupt_addr_above_ciram (str);
  end
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_miss_fail_wr_cache_blk (str);
  end
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_miss_fail_rd_auth_tag (str);
  end
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_miss_fail_rd_cache_blk (str);
  end
  if (m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH] && !m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) begin
    str = {str, $sformatf("error injected for [SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH] : 'h%0h \n", m_cpu_rd_err_case_sel)};
    cpu_miss_fail_auth_tag_mismatch (str);
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_CPU_RD", str, UVM_HIGH)

endfunction : corrupt_cpu_rd

function void sinc_cpu_err_inj_packet::corrupt_cpu_wr();
  string str;

  str = "\n ****************************************** \n";
  str = {str, $sformatf("m_cpu_wr_err_case_sel : 'h%0h \n", m_cpu_wr_err_case_sel)};

  if (m_cpu_wr_err_case_sel[`SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION]) begin
    str = {str, $sformatf("error injected for [SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION] : 'h%0h \n", m_cpu_wr_err_case_sel)};
    cpu_corrupt_addr_mpu_violation (str);
  end
  if (m_cpu_wr_err_case_sel[`SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT]) begin
    str = {str, $sformatf("error injected for [SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] : 'h%0h \n", m_cpu_wr_err_case_sel)};
    cpu_corrupt_addr_above_ciram (str);
  end
  if (m_cpu_wr_err_case_sel[`SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE]) begin
    str = {str, $sformatf("error injected for [SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE] : 'h%0h \n", m_cpu_wr_err_case_sel)};
    cpu_wr_access_during_cache_active (str);
  end

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CORRUPT_CPU_WR", str, UVM_HIGH)

endfunction : corrupt_cpu_wr

function void sinc_cpu_err_inj_packet::cpu_corrupt_addr_above_ciram(ref string str);

  ccpui_cpu_mem_addr_t new_cpu_addr;

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [MPU_VIOLATION], original: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

  if (!(std::randomize(new_cpu_addr) with {
          new_cpu_addr > SINC_CIRAM_END_ADDR;
          new_cpu_addr <= SINC_CPU_MEM_END_ADDR;
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize cpu_addr")
  end
  m_orig_cpu_packet.m_cpu_addr = new_cpu_addr;

  str = {str, $sformatf(" Corrupt request with [MPU_VIOLATION], corrupted: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

endfunction : cpu_corrupt_addr_above_ciram

function void sinc_cpu_err_inj_packet::cpu_corrupt_addr_mpu_violation(ref string str);

  bit                  read;
  bit                  write;
  bit                  execute;
  bit                  user_access;
  bit                  found_dissalowed_page;
  ccpui_cpu_mem_addr_t new_cpu_addr;

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [MPU_VIOLATION], original: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

  user_access           = ~m_orig_cpu_packet.m_cpu_privmode;
  read                  = (m_orig_cpu_packet.m_cpu_cmd == SINC_CPU_READ_TRN) ? 1 : 0;
  write                 = (~read) & m_orig_cpu_packet.m_cpu_loadstore;
  execute               = (~read) & ~m_orig_cpu_packet.m_cpu_loadstore;
  found_dissalowed_page = 0;

  if (m_sys_cfg.m_mpu_cfg.get_rand_page_disallowed_by(.is_user_access(user_access), .by_rd(read), .by_wr(write), .by_ex(execute), .rand_page_num(m_disallowed_page_num))) begin
    `uvm_info(get_name(), $sformatf("get a random page with disallow for user_access %0d rd %0d wr %0d ex %0d: [%0d] \n", user_access, read, write, execute, m_disallowed_page_num), UVM_HIGH)
    found_dissalowed_page = 1;
  end else begin
    user_access = ~user_access;
    if (m_sys_cfg.m_mpu_cfg.get_rand_page_disallowed_by(.is_user_access(user_access), .by_rd(read), .by_wr(write), .by_ex(execute), .rand_page_num(m_disallowed_page_num))) begin
      `uvm_info(get_name(), $sformatf("get a random page with disallow for user_access %0d rd %0d wr %0d ex %0d: [%0d] \n", user_access, read, write, execute, m_disallowed_page_num), UVM_HIGH)
      m_orig_cpu_packet.m_cpu_privmode = ~m_orig_cpu_packet.m_cpu_privmode;
      found_dissalowed_page          = 1;
    end
  end

  if(found_dissalowed_page == 1) begin
    if (!(std::randomize(new_cpu_addr) with {
            new_cpu_addr >= (m_disallowed_page_num * 1024);
            new_cpu_addr < ((m_disallowed_page_num + 1) * 1024);
          })) begin
      `uvm_fatal(get_name(), $sformatf("Unable to randomize cpu_addr disallowed_page_num is %0d", m_disallowed_page_num))
    end
    m_orig_cpu_packet.m_cpu_addr = new_cpu_addr;
  end

  str = {str, $sformatf(" Corrupt request with [MPU_VIOLATION], corrupted: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

endfunction : cpu_corrupt_addr_mpu_violation

function void sinc_cpu_err_inj_packet::cpu_miss_fail_wr_cache_blk(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [CPU_MISS_WR_CACHE_BLK_FAIL]\n")};

  cpu_addr_cache_miss(str);

  m_force_cache_blk_wr_failure = 1;

endfunction : cpu_miss_fail_wr_cache_blk

function void sinc_cpu_err_inj_packet::cpu_miss_fail_rd_auth_tag(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [CPU_MISS_RD_AUTH_TAG_FAIL]\n")};

  cpu_addr_cache_miss(str);

  m_force_cache_blk_rd_failure = 1;

endfunction : cpu_miss_fail_rd_auth_tag

function void sinc_cpu_err_inj_packet::cpu_miss_fail_rd_cache_blk(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [CPU_MISS_RD_CACHE_BLK_FAIL]\n")};

  cpu_addr_cache_miss(str);

  m_force_auth_tag_rd_failure = 1;

endfunction : cpu_miss_fail_rd_cache_blk

function void sinc_cpu_err_inj_packet::cpu_miss_fail_auth_tag_mismatch(ref string str);

  int                  bad_block;
  ccpui_cpu_mem_addr_t new_cpu_addr;
  ccpui_cpu_mem_addr_t bad_block_base_addr;
  ccpui_cpu_mem_addr_t next_block_base_addr;
  m_err_injected = 1;

  if (!std::randomize(bad_block) with {
        bad_block inside {m_sys_cfg.m_skip_preload_blocks};
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: skip_preload_blocks randomize failed!!!", m_debug_str))
  end

  str = {str, $sformatf(" Corrupt request with [CPU_MISS_AUTH_TAG_MISMATCH], original addr: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

  bad_block_base_addr                                   = 0;
  bad_block_base_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]  = bad_block;
  next_block_base_addr                                  = 0;
  next_block_base_addr[`SINC_CACHE_BLOCK_NUM_RANGE_SEL] = bad_block + 1;

  if (!(std::randomize(new_cpu_addr) with {
          new_cpu_addr >= bad_block_base_addr;
          new_cpu_addr < next_block_base_addr;
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize cpu_addr")
  end
  m_orig_cpu_packet.m_cpu_addr = new_cpu_addr;

  `uvm_info(get_name(), $sformatf("skip_preload_debug3 new addr: 'h%0h bad_block [%0d]", m_orig_cpu_packet.m_cpu_addr, bad_block), UVM_LOW)

  str = {str, $sformatf(" Corrupt request with [CPU_MISS_AUTH_TAG_MISMATCH], new addr: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

endfunction : cpu_miss_fail_auth_tag_mismatch

function void sinc_cpu_err_inj_packet::cpu_addr_cache_miss(ref string str);
  int                           first_set_type;
  sinc_csd_cache_set_comp_w_cfg cache_set;

  str = {str, $sformatf(" Change request to cache miss, original addr: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

  //pick random order for checks
  if (!(std::randomize(first_set_type) with {
          first_set_type < 3;
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize first_set_type")
  end

  if(first_set_type == 0) begin
    if (!m_sys_cfg.m_csd.get_rand_cache_set_full_valid(cache_set)) begin
      if (!m_sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
        if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
          `uvm_error(get_name(), $sformatf("Not able to find a cache set that would cause a miss"))
        end
      end
    end
  end else if(first_set_type == 1) begin
    if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
      if (!m_sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
        if (!m_sys_cfg.m_csd.get_rand_cache_set_full_valid(cache_set)) begin
          `uvm_error(get_name(), $sformatf("Not able to find a cache set that would cause a miss"))
        end
      end
    end
  end else begin
    if (!m_sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
      if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
        if (!m_sys_cfg.m_csd.get_rand_cache_set_full_valid(cache_set)) begin
          `uvm_error(get_name(), $sformatf("Not able to find a cache set that would cause a miss"))
        end
      end
    end
  end

  if (cache_set !== null) begin
    m_orig_cpu_packet.m_cpu_addr[`SINC_CACHE_SET_RANGE_SEL] = cache_set.m_cache_set;
  end

  str = {str, $sformatf(" Change request to cache miss, new addr: 'h%0h \n", m_orig_cpu_packet.m_cpu_addr)};

endfunction : cpu_addr_cache_miss

function void sinc_cpu_err_inj_packet::cpu_wr_access_during_cache_active(ref string str);

  m_err_injected = 1;

  str = {str, $sformatf(" Corrupt request with [CPU_WR_DURING_CACHE_ACTIVE]\n")};

  m_sys_cfg.m_allow_writes_cache_active = 1;

endfunction : cpu_wr_access_during_cache_active

function void sinc_cpu_err_inj_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Corrupt CPU Request on Iter_Num [%0d]: \n", iter_n)};

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_CPU_ERR_INJ_PACKET", str, UVM_HIGH)

endfunction : print_packet

constraint sinc_cpu_err_inj_packet::err_sel_c {
  $countones(m_cpu_wr_err_case_sel) == 1;
  $countones(m_cpu_rd_err_case_sel) == 1;

  if(m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) {
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] == 0;
    m_cpu_wr_err_case_sel[`SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT] == 0;
  }

  if(m_sys_cfg.m_cur_cache_state != CACHE_ACTIVE_STATE) {
    m_cpu_wr_err_case_sel[`SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH] == 0;
  }

  if(m_sys_cfg.m_skipped_preload_for_some_blocks == 0) {
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH] == 0;
  }

  if(m_sys_cfg.m_sinc_rand_seq_disable_severe_err_inj) {
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] == 0;
    m_cpu_rd_err_case_sel[`SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK] == 0;


  }
}

`endif // SINC_CPU_ERR_INJ_PACKET
