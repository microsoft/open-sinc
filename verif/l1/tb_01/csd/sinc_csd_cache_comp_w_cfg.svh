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
// File        : sinc_csd_cache_comp_w_cfg.svh
// Description : 

`ifndef SINC_CSD_CACHE_COMP_W_CFG
`define SINC_CSD_CACHE_COMP_W_CFG

//===========================================================================
// Class: sinc_csd_cache_comp_w_cfg
//
//===========================================================================
class sinc_csd_cache_comp_w_cfg extends uvm_object; // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  csd_address_t m_start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE)
  string m_type_instance_name = "SINC_CACHE_COMP";

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE)
  string m_comp_type_name = "CACHE";

  // Variable: instance_id
  // Indicates this component's instanceID
  int m_instance_id;

  // Variable: is_cache
  // Indicates this is a cache set
  bit m_is_cache;

  // Variable: cache
  // Holds the data of this cache
  sinc_csd_cache_set_comp_w_cfg m_cache_sets[sinc_parameters_pkg::SINC_CACHE_SETS_NUM];

  `uvm_object_utils_begin(sinc_csd_cache_comp_w_cfg)
    `uvm_field_int ( m_start_addr, UVM_ALL_ON)
    `uvm_field_int ( m_instance_id, UVM_ALL_ON)
    `uvm_field_int ( m_is_cache, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_csd_cache_comp_w_cfg");
    super.new(name);
  endfunction : new

  // return the current cache set's data
  // extern function cache_t get_cache_by_id();

  // create cache sets
  extern virtual function void initiate_csd_sets();

endclass : sinc_csd_cache_comp_w_cfg // }

// function cache_t sinc_csd_cache_comp_w_cfg::get_cache();
//   return(m_cache);
// endfunction : get_cache_data

function void sinc_csd_cache_comp_w_cfg::initiate_csd_sets();
  // create cache sets
  for (int set_idx=0; set_idx < sinc_parameters_pkg::SINC_CACHE_SETS_NUM; set_idx++) begin
    m_cache_sets[set_idx]                  = new($sformatf("SINC_CACHE_SET_%0d", set_idx));
    m_cache_sets[set_idx].m_cache_set_idx    = set_idx;
    m_cache_sets[set_idx].m_cache_set      = sinc_cache_set_t'(set_idx);
    m_cache_sets[set_idx].m_cache_fifo_idx = 0;
    `uvm_info("initiate_csd_sets", $sformatf("set[%0d], cache_set_idx['h%0h], m_cache_set['h%0h], m_cache_fifo_idx[%0d]",
        set_idx, m_cache_sets[set_idx].m_cache_set_idx, m_cache_sets[set_idx].m_cache_set, m_cache_sets[set_idx].m_cache_fifo_idx), UVM_DEBUG)
    m_cache_sets[set_idx].initiate_csd_cache_lines();
  end

endfunction : initiate_csd_sets

`endif // SINC_CSD_CACHE_COMP_W_CFG
