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
// File        : sinc_csd_mem_line_comp_w_cfg.svh
// Description : 

`ifndef SINC_CSD_MEM_LINE_COMP_W_CFG
`define SINC_CSD_MEM_LINE_COMP_W_CFG

//===========================================================================
// Class: sinc_csd_mem_line_comp_w_cfg
//
//===========================================================================
class sinc_csd_mem_line_comp_w_cfg extends uvm_object; // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  csd_address_t m_start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_MEM_LINE)
  string m_type_instance_name = "SINC_MEM_LINE";

  // Variable: comp_type_name
  // String version of comp type name (ex. MEM_LINE)
  string m_comp_type_name = "MEM_LINE";

  // Variable: cache_set_idx
  // Indicates this mem_line's  cache set's index
  int m_cache_set_idx;

  // Cache Set
  sinc_cache_set_t m_cache_set;

  // Variable: cache_line_idx
  // Indicates this mem_line's cache line's index
  int m_cache_line_idx;

  // Variable: cache_line_offset_per_set
  // Indicates this mem line's cache line offset per set
  int m_cache_line_offset_per_set;

  int m_cache_mem_line_offset_per_cache_line;

  // Variable: is_mem_line
  // Indicates this is a mem line
  bit m_is_mem_line = 1;

  // Variable: data_width
  // Width of this data type
  int m_data_width;

  // Variable: mem_line
  // Holds the data of this mem_line
  mem_line_data_t m_mem_line_data;

  `uvm_object_utils_begin(sinc_csd_mem_line_comp_w_cfg)
    `uvm_field_int ( m_start_addr, UVM_ALL_ON)
    `uvm_field_int ( m_cache_line_idx, UVM_ALL_ON)
    `uvm_field_int ( m_is_mem_line, UVM_ALL_ON)
    `uvm_field_int ( m_data_width, UVM_ALL_ON)
    `uvm_field_int ( m_mem_line_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_csd_mem_line_comp_w_cfg");
    super.new(name);
  endfunction : new

  // return the current mem line's offset address
  extern virtual function csd_address_t get_mem_line_offset_addr();

  // return the current mem line's data
  extern virtual function mem_line_data_t get_mem_line_data();

endclass : sinc_csd_mem_line_comp_w_cfg // }

function csd_address_t sinc_csd_mem_line_comp_w_cfg::get_mem_line_offset_addr();
  return(m_start_addr);
endfunction : get_mem_line_offset_addr

function mem_line_data_t sinc_csd_mem_line_comp_w_cfg::get_mem_line_data();
  return(m_mem_line_data);
endfunction : get_mem_line_data

`endif // SINC_CSD_MEM_LINE_COMP_W_CFG
