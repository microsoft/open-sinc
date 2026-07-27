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
// File        : sinc_csd_cache_set_comp_w_cfg.svh
// Description : 

`ifndef SINC_CSD_CACHE_SET_COMP_W_CFG
`define SINC_CSD_CACHE_SET_COMP_W_CFG

//===========================================================================
// Class: sinc_csd_cache_set_comp_w_cfg
//
//===========================================================================
class sinc_csd_cache_set_comp_w_cfg extends uvm_object; // {

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE_SET)
  string m_type_instance_name = "SINC_CACHE_SET";;

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE_SET)
  string m_comp_type_name = "CACHE_SET";;

  // Variable: cache_set_idx
  // Indicates this cache set's index
  int m_cache_set_idx;

  // Variable: is_cache_set
  // Indicates this is a cache set
  bit m_is_cache_set = 1;

  // Variable: cache_set
  // Holds the data of this cache_set
  sinc_csd_cache_line_comp_w_cfg m_cache_lines[sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE];

  // Cache Set
  sinc_cache_set_t m_cache_set;

  // Cache FIFO Index
  // indicating which set should be updated when miss
  sinc_cache_fifo_idx_t m_cache_fifo_idx = 0;

  `uvm_object_utils_begin(sinc_csd_cache_set_comp_w_cfg)
    `uvm_field_int ( m_cache_set_idx, UVM_ALL_ON)
    `uvm_field_int ( m_is_cache_set, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_csd_cache_set_comp_w_cfg");
    super.new(name);
  endfunction : new

  // initiate cache lines
  // default option: backdoor load the cache line
  extern virtual function void initiate_csd_cache_lines();

  // return the current cache set's data
  extern virtual function sinc_cache_set_t get_cache_set();

endclass : sinc_csd_cache_set_comp_w_cfg // }

function sinc_cache_set_t sinc_csd_cache_set_comp_w_cfg::get_cache_set();
  return(m_cache_set);
endfunction : get_cache_set

function void sinc_csd_cache_set_comp_w_cfg::initiate_csd_cache_lines();
  // create cache lines
  for (int line_offset=0; line_offset < sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE; line_offset++) begin
    m_cache_lines[line_offset]                          = new($sformatf("SINC_CACHE_LINE_%0d", line_offset + m_cache_set_idx));
    m_cache_lines[line_offset].m_cache_set_idx            = m_cache_set_idx;
    m_cache_lines[line_offset].m_cache_set              = sinc_cache_set_t'(m_cache_set_idx);
    m_cache_lines[line_offset].m_cache_line_offset_in_set = line_offset;
    m_cache_lines[line_offset].m_cache_line_idx           = (m_cache_set_idx * sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE) + line_offset;
    `uvm_info("initiate_csd_cache_lines", $sformatf("line[%0d], cache_set_idx['h%0h], m_cache_set['h%0h], cache_line_offset_in_set[%0d]",
        m_cache_lines[line_offset].m_cache_line_idx, m_cache_lines[line_offset].m_cache_set_idx, m_cache_lines[line_offset].m_cache_set, m_cache_lines[line_offset].m_cache_line_offset_in_set), UVM_HIGH)
    m_cache_lines[line_offset].initiate_csd_mem_lines();
  end

endfunction : initiate_csd_cache_lines

`endif // SINC_CSD_CACHE_SET_COMP_W_CFG
