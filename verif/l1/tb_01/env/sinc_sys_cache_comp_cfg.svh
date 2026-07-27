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
// File        : sinc_sys_cache_comp_cfg.svh
// Description : 

`ifndef SINC_SYS_CACHE_COMP_CFG_SVH
 `define SINC_SYS_CACHE_COMP_CFG_SVH

//===========================================================================
// Class: sinc_sys_cache_comp_cfg
// 
//===========================================================================
class sinc_sys_cache_comp_cfg extends uvm_object;  // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  address_t start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE)
  string type_instance_name = "SINC_CACHE";;

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE)
  string comp_type_name = "CACHE";;

  // Variable: instance_id
  // Indicates this component's instanceID 
  int instance_id;

  // Variable: is_cache
  // Indicates this is a cache set
  bit is_cache;

  // Variable: cache
  // Holds the data of this cache
  sinc_sys_cache_set_comp_cfg cache[sinc_parameters_pkg::SINC_CACHE_SETS_NUM];

  `uvm_object_utils_begin(sinc_sys_cache_comp_cfg)
    `uvm_field_int ( start_addr,         UVM_ALL_ON)
    `uvm_field_int ( instance_id,        UVM_ALL_ON)
    `uvm_field_int ( is_cache,      UVM_ALL_ON)
    `uvm_field_int ( data_width,         UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_sys_cache_comp_cfg");
    super.new(name);
  endfunction : new

  // return the current cache set's data
  // extern function cache_t get_cache_by_id();

endclass : sinc_sys_cache_comp_cfg // }

// function cache_t sinc_sys_cache_comp_cfg::get_cache();
//   return(m_cache);
// endfunction : get_cache_data


`endif //  `ifndef SINC_SYS_CACHE_COMP_CFG_SVH
