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
// File        : sinc_sys_cache_line_comp_cfg.svh
// Description : 

`ifndef SINC_SYS_CACHE_LINE_COMP_CFG_SVH
 `define SINC_SYS_CACHE_LINE_COMP_CFG_SVH

//===========================================================================
// Class: sinc_sys_cache_line_comp_cfg
// 
//===========================================================================
class sinc_sys_cache_line_comp_cfg extends uvm_object;  // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  address_t start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE_LINE)
  string type_instance_name = "SINC_CACHE_LINE";;

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE_LINE)
  string comp_type_name = "CACHE_LINE";;

  // Variable: instance_id
  // Indicates this component's instanceID 
  int instance_id;

  // Variable: is_cache_line
  // Indicates this is a cache line
  bit is_cache_line;

  // Variable: cache_line
  // Holds the data of this cache_line
  sinc_sys_mem_line_comp_cfg mem_line[sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE];

  // Cache Set
  sinc_cache_set_t m_cache_set;

  // Cache Tag
  sinc_cache_set_t m_cache_tag;

  // Cache FIFO Index
  sinc_cache_fifo_idx_t m_cache_fifo_idx;
  

  `uvm_object_utils_begin(sinc_sys_cache_line_comp_cfg)
    `uvm_field_int ( start_addr,         UVM_ALL_ON)
    `uvm_field_int ( instance_id,        UVM_ALL_ON)
    `uvm_field_int ( is_cache_line,      UVM_ALL_ON)
    `uvm_field_int ( data_width,         UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_sys_cache_line_comp_cfg");
    super.new(name);
  endfunction : new

  // return the current cache line's data
  extern function cache_line_t get_cache_line_data_by_id(int id);

endclass : sinc_sys_cache_line_comp_cfg // }

function cache_line_data_t sinc_sys_cache_line_comp_cfg::get_cache_line_data();
  cache_line_data_t cache_line_data;
  for (int i=0; i < sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE; i++) begin
    cache_line_data[i] = mem_line[i].get_mem_line_data();
  end
  return(cache_line_data);
endfunction : get_cache_line_data


`endif //  `ifndef SINC_SYS_CACHE_LINE_COMP_CFG_SVH
