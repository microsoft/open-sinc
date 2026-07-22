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
// File        : sinc_csd_cache_line_comp_w_cfg.svh
// Description : 

`ifndef SINC_CSD_CACHE_LINE_COMP_W_CFG
`define SINC_CSD_CACHE_LINE_COMP_W_CFG

//===========================================================================
// Class: sinc_csd_cache_line_comp_w_cfg
//
//===========================================================================
class sinc_csd_cache_line_comp_w_cfg extends uvm_object; // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  csd_address_t m_start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE_LINE)
  string m_type_instance_name = "SINC_CACHE_LINE";;

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE_LINE)
  string m_comp_type_name = "CACHE_LINE";;

  // Variable: cache_set_idx
  // Indicates this cache line's cache set
  int m_cache_set_idx;

  // Variable: cache_line_indx
  // Indicates this cache line's index
  int m_cache_line_idx;

  // Variable: cache_line_offset_in_set
  // Indicates this cache line's offset in its set
  int m_cache_line_offset_in_set;

  // Variable: is_cache_line
  // Indicates this is a cache line
  bit m_is_cache_line;

  // Variable: is_valid
  // Indicates this is cache is valid
  bit m_is_valid = 0;

  // Variable: mem_lines
  // Holds the data of this cache_line's data in mem lines format
  sinc_csd_mem_line_comp_w_cfg m_mem_lines[sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE]; // mem_lines

  // Cache Set
  sinc_cache_set_t m_cache_set;

  // Cache Tag
  sinc_cache_tag_t m_cache_tag;

  // Cache FIFO Index
  sinc_cache_fifo_idx_t m_cache_fifo_idx;

  `uvm_object_utils_begin(sinc_csd_cache_line_comp_w_cfg)
    `uvm_field_int ( m_start_addr, UVM_ALL_ON)
    `uvm_field_int ( m_cache_line_idx, UVM_ALL_ON)
    `uvm_field_int ( m_is_cache_line, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_csd_cache_line_comp_w_cfg");
    super.new(name);
  endfunction : new

  // return the current cache line's data
  extern virtual function cache_line_data_t get_cache_line_data();

  // initiate cache lines
  // default option: backdoor load the cache line
  extern virtual function void initiate_csd_mem_lines();

  // rturn true if success
  extern virtual function bit set_cache_line_data(csd_cache_block_t cache_block_data);

endclass : sinc_csd_cache_line_comp_w_cfg // }

function cache_line_data_t sinc_csd_cache_line_comp_w_cfg::get_cache_line_data();
  cache_line_data_t cache_line_data;
  for (int i=0; i < sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE; i++) begin
    cache_line_data[i] = m_mem_lines[i].get_mem_line_data();
  end
  return(cache_line_data);
endfunction : get_cache_line_data

function void sinc_csd_cache_line_comp_w_cfg::initiate_csd_mem_lines();
  // create mem lines
  for (int line_offset=0; line_offset < sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE; line_offset++) begin
    m_mem_lines[line_offset]                                      = new($sformatf("SINC_CACHE_MEM_LINE_%0d", line_offset));
    m_mem_lines[line_offset].m_cache_mem_line_offset_per_cache_line = line_offset;
    m_mem_lines[line_offset].m_cache_line_idx                       = m_cache_line_idx;
    m_mem_lines[line_offset].m_cache_set_idx                        = m_cache_set_idx;
    m_mem_lines[line_offset].m_cache_set                          = sinc_cache_set_t'(m_cache_set_idx);
    m_mem_lines[line_offset].m_cache_line_offset_per_set            = m_cache_line_offset_in_set;
    //`uvm_info("initiate_csd_cache_lines", $sformatf("cache_mem_line_offset_per_cache_line[%0d], cache_line_idx[%0d], cache_set_idx[%0h], m_cache_set[%0h], cache_line_offset_per_set[%0d]",
    // mem_lines[line_offset].cache_mem_line_offset_per_cache_line, mem_lines[line_offset].cache_line_idx, mem_lines[line_offset].cache_set_idx, mem_lines[line_offset].m_cache_set,
    // mem_lines[line_offset].cache_line_offset_per_set), UVM_DEBUG)
  end

endfunction : initiate_csd_mem_lines

function bit sinc_csd_cache_line_comp_w_cfg::set_cache_line_data(csd_cache_block_t cache_block_data);
  for (int mem_idx = 0; mem_idx < sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE; mem_idx++) begin
    m_mem_lines[mem_idx].m_mem_line_data = cache_block_data[sinc_parameters_pkg::SINC_MEM_LINE_WIDTH * mem_idx +: sinc_parameters_pkg::SINC_MEM_LINE_WIDTH];
  end
endfunction : set_cache_line_data

`endif // SINC_CSD_CACHE_LINE_COMP_W_CFG
