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
// File        : sinc_cpu_packet.svh
// Description : This is AXI packet used to randomize AXI requests to SINC.

`ifndef SINC_CPU_PACKET
`define SINC_CPU_PACKET

//---------------------------------
// SINC AXI Packet Class
//---------------------------------
class sinc_cpu_packet extends sinc_base_packet;

  typedef sinc_cpu_packet this_t;

  `uvm_object_utils(sinc_cpu_packet)

  // Indicating the number of transaction per this packet
  int m_num_trans;

  // Rand CPU Access Attributes
  rand ccpui_cpu_mem_addr_t m_cpu_addr;
  rand ccpui_cpu_mem_we_t   m_cpu_we;

  rand ccpui_cpu_mem_data_t m_cpu_write_data;
  rand logic                m_cpu_loadstore;
  rand logic                m_cpu_privmode;

  // Rand whether this CPU transaction should be a hit or miss in cache active
  rand bit m_is_cache_hit;

  // Below variable has priority in postrandom: is_full_set > is_partial_set > is_empty_set
  // Request to a CACHE set that is full of valid lines
  rand bit m_is_full_set;

  // Request to a CACHE set that has partial of lines valid
  rand bit m_is_partial_set;

  // Request to a CACHE set that has non of lines valid
  rand bit m_is_empty_set;

  // CPU Access Attributes used by sequence
  ccpui_cpu_mem_data_t m_cpu_read_data;

  // when is_valid_req is set, the constraint will try to find request with attributes that result a valid transaction (response with OKAY)
  rand bit m_is_valid_req;

  // the axi_cmd should preset by the sequence, default as read
  sinc_cpu_cmd_e m_cpu_cmd = sinc_env_pkg::SINC_CPU_READ_TRN;

  // cache line pool's index
  rand int m_cache_line_pool_idx;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_cpu_packet" );
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

  extern constraint order_c;

  extern constraint we_c;

  extern constraint valid_req_c;

  extern constraint valid_addr_c;

  extern constraint loadstore_c;

  extern constraint is_cache_hit_c;

  extern constraint valid_cache_pool_index_c;

endclass : sinc_cpu_packet

function void sinc_cpu_packet::post_randomize ();

  if (m_num_trans > 20) begin // when num_trans < 20, cache is still being warming up
    if ((m_sys_cfg.m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) && m_is_cache_hit) begin
      sinc_csd_cache_line_comp_w_cfg valid_cache_line = m_sys_cfg.m_csd.get_random_valid_cache_line();

      if (valid_cache_line !== null) begin
        `uvm_info(get_name(), $sformatf("post_randomize: debug - when cache_state[%0s], is_cache_hit[%0d], override original cpu_addr['h%0h] \n", m_sys_cfg.m_cur_cache_state, m_is_cache_hit, m_cpu_addr), UVM_HIGH)
        m_cpu_addr[`SINC_CACHE_SET_RANGE_SEL] = valid_cache_line.m_cache_set;
        m_cpu_addr[`SINC_CACHE_TAG_RANGE_SEL] = valid_cache_line.m_cache_tag;
        `uvm_info(get_name(), $sformatf("post_randomize: debug - when cache_state[%0s], is_cache_hit[%0d], to original cpu_addr['h%0h] \n", m_sys_cfg.m_cur_cache_state, m_is_cache_hit, m_cpu_addr), UVM_HIGH)
      end
    end else if ((m_sys_cfg.m_cur_cache_state == sinc_parameters_pkg::CACHE_ACTIVE_STATE) && !m_is_cache_hit) begin
      sinc_csd_cache_set_comp_w_cfg cache_set;

      if (m_is_full_set) begin // Request to a CACHE set that is full of valid lines
        if (!m_sys_cfg.m_csd.get_rand_cache_set_full_valid(cache_set)) begin
          if (!m_sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
            if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
              `uvm_error(get_name(),
                $sformatf("Not able to find a cache set matching expectation: is_full_set[%0d], ",
                  m_is_full_set))
            end // if (!sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
          end // if (!sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
        end // if (!sys_cfg.m_csd.get_rand_cache_set_full_valid(cache_set)) begin
      end // if (is_full_set) begin
      else if (m_is_partial_set) begin
        if (!m_sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
          if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
            `uvm_error(get_name(),
              $sformatf("Not able to find a cache set matching expectation: is_partial_set[%0d], ",
                m_is_partial_set))
          end // if (!sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
        end // if (!sys_cfg.m_csd.get_rand_cache_set_partial_valid(cache_set)) begin
      end // else if (is_partial_set) begin
      else if (m_is_empty_set) begin
        if (!m_sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
          `uvm_error(get_name(),
            $sformatf("Not able to find a cache set matching expectation: is_empty_set[%0d], ",
              m_is_empty_set))
        end // if (!sys_cfg.m_csd.get_rand_cache_set_non_valid(cache_set)) begin
      end // else if (is_empty_set) begin

      if (cache_set !== null) begin
        m_cpu_addr[`SINC_CACHE_SET_RANGE_SEL] = cache_set.m_cache_set;
        `uvm_info(get_name(), $sformatf("post_randomize: debug - when cache_state[%0s], is_cache_hit[%0d], to original cpu_addr['h%0h] \n", m_sys_cfg.m_cur_cache_state, m_is_cache_hit, m_cpu_addr), UVM_HIGH)
      end
    end
  end

  // only issue access within the cache line pool
  // intentionally overwrite cpu address
  if (m_sys_cfg.m_access_within_cache_pool) begin
    `uvm_info(get_name(), $sformatf("post_randomize: overwrite CPU address with cache_line_pool_idx['h%0h] \n", m_cache_line_pool_idx), UVM_HIGH)
    m_cpu_addr[`SINC_CACHE_SET_RANGE_SEL] = m_sys_cfg.m_cache_line_pool[m_cache_line_pool_idx].m_cache_set;
    m_cpu_addr[`SINC_CACHE_TAG_RANGE_SEL] = m_sys_cfg.m_cache_line_pool[m_cache_line_pool_idx].m_cache_tag;
  end

  //nothing in post randomize so no need for two debug prints, remove if post randomize complexity is added
  //`uvm_info(get_name(), $sformatf("post_randomize: debug - end\n"), UVM_LOW)
endfunction : post_randomize

function void sinc_cpu_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" CPU Request on Iter_Num [%0d]: \n", iter_n)};
  str = {str, $sformatf(" CPU CMD            : [%0s]\n", m_cpu_cmd.name())};
  str = {str, $sformatf(" CPU Address        : ['h%0h]\n", m_cpu_addr)};
  str = {str, $sformatf(" CPU WE             : [%0d]\n", m_cpu_we)};
  str = {str, $sformatf(" CPU LOADSTORE      : [%0d]\n", m_cpu_loadstore)};
  str = {str, $sformatf(" CPU PRIVMODE       : [%0d]\n", m_cpu_privmode)};
  str = {str, $sformatf(" CPU IS_VALID_REQ   : [%0d]\n", m_is_valid_req)};
  if (m_cpu_we === 'h1) begin
    str = {str, $sformatf(" CPU Write data   : ['h%0h] \n", m_cpu_write_data)};
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_AXI_PACKET", str, UVM_HIGH)

endfunction : print_packet

constraint sinc_cpu_packet::order_c {

}

constraint sinc_cpu_packet::we_c {
  if(m_cpu_cmd == SINC_CPU_WRITE_TRN) {
    m_cpu_we dist { 'hf :/ 70, [0:'hf] :/ 30 };
  }
  else {
    m_cpu_we == 'h0;
  }
}

//can't do an execute on a write so loadstore needs to be set
constraint sinc_cpu_packet::loadstore_c {
  if(m_cpu_cmd == SINC_CPU_WRITE_TRN) {
    m_cpu_loadstore == 'h1;
  }
}

constraint sinc_cpu_packet::is_cache_hit_c {
  m_is_cache_hit dist {
    1 := m_sys_cfg.m_sinc_tb_seq_cache_hit_ratio,
    0 := 100 - m_sys_cfg.m_sinc_tb_seq_cache_hit_ratio
  };
}

constraint sinc_cpu_packet::valid_req_c {
  // if (sys_cfg.m_disable_illegal_req)
  if (1) {
    m_is_valid_req == 1;
    // for debug usage
    // dst_comp == SINC_REG;
  } else {
    // there shouldn't be further constraint
  }
}

constraint sinc_cpu_packet::valid_addr_c {

  m_cpu_addr dist { 0 :/ 5, SINC_CPU_MEM_END_ADDR :/5, [1: SINC_CPU_MEM_END_ADDR-1] :/90};

}

constraint sinc_cpu_packet::valid_cache_pool_index_c {

  if (m_sys_cfg.m_cache_line_pool_size > 0) {
    m_cache_line_pool_idx >= 0;
    m_cache_line_pool_idx < m_sys_cfg.m_cache_line_pool_size;
  } else {
    m_cache_line_pool_idx == 0;
  }

}

`endif // SINC_CPU_PACKET
