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
// File        : sinc_sys_mem_line_comp_cfg.svh
// Description : 

`ifndef SINC_SYS_MEM_LINE_COMP_CFG_SVH
 `define SINC_SYS_MEM_LINE_COMP_CFG_SVH

//===========================================================================
// Class: sinc_sys_mem_line_comp_cfg
// 
//===========================================================================
class sinc_sys_mem_line_comp_cfg extends uvm_object;  // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  address_t start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_MEM_LINE)
  string type_instance_name = "SINC_MEM_LINE";

  // Variable: comp_type_name
  // String version of comp type name (ex. MEM_LINE)
  string comp_type_name = "MEM_LINE";;

  // Variable: instance_id
  // Indicates this component's instanceID 
  int instance_id;

  // Variable: is_mem_line
  // Indicates this is a mem line
  bit is_mem_line;

  // Variable: data_width
  // Width of this data type
  int data_width;

  // Variable: mem_line
  // Holds the data of this mem_line
  mem_line_data_t mem_line_data;

  `uvm_object_utils_begin(sinc_sys_mem_line_comp_cfg)
    `uvm_field_int ( start_addr,         UVM_ALL_ON)
    `uvm_field_int ( instance_id,        UVM_ALL_ON)
    `uvm_field_int ( is_mem_line,        UVM_ALL_ON)
    `uvm_field_int ( data_width,         UVM_ALL_ON)
    `uvm_field_int ( mem_line_data,           UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_sys_mem_line_comp_cfg");
    super.new(name);
  endfunction : new

  // return the current mem line's offset address
  extern function address_t  get_mem_line_offset_addr();

  // return the current mem line's data
  extern function mem_line_t get_mem_line_data();

endclass : sinc_sys_mem_line_comp_cfg // }

function address_t sinc_sys_mem_line_comp_cfg::get_mem_line_offset_addr();
  return(start_addr);
endfunction : get_mem_line_offset_addr

function mem_line_t sinc_sys_mem_line_comp_cfg::get_mem_line_data();
  return(mem_line_data);
endfunction : get_mem_line_data


`endif //  `ifndef SINC_SYS_MEM_LINE_COMP_CFG_SVH
