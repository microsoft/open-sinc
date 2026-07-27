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
// File        : sinc_sys_mem_comp_cfg.svh
// Description : 

`ifndef SINC_SYS_MEM_COMP_CFG_SVH
 `define SINC_SYS_MEM_COMP_CFG_SVH

//===========================================================================
// Class: sinc_sys_mem_comp_cfg
// 
//===========================================================================
class sinc_sys_mem_comp_cfg extends uvm_object;  // {
  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  address_t start_addr;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. KSU_SP, KSU_CCE, KSU_SHA, KSU_KEY)
  string type_instance_name;

  // Variable: comp_type_name
  // String version of comp type name (ex. KEY, LUT)
  string comp_type_name;

  // Variable: instance_id
  // Indicates this component's instanceID 
  int instance_id;

  // Variable: is_key_slot
  // Indicates this is a key slot
  bit is_key_slot;

  // Variable: is_lut_slot
  // Indicates this is a lut slot
  bit is_lut_slot;

  // Variable: slot_width
  // Width of this slot
  int slot_width;

  // Variable: key
  // Holds the data of this key slot
  key_data_t key;

  // Variable: lut
  // Holds the data of this lut slot
  // reserved[1:0], valid[0], VFID[5:0], Key_Index[6:0]
  bit [sinc_parameters_pkg::KEY_VAULT_LUT_SLOT_WIDTH-1:0] lut;

  `uvm_object_utils_begin(sinc_sys_mem_comp_cfg)
    `uvm_field_int ( start_addr,         UVM_ALL_ON)
    `uvm_field_int ( instance_id,        UVM_ALL_ON)
    `uvm_field_int ( is_key_slot,         UVM_ALL_ON)
    `uvm_field_int ( is_lut_slot,         UVM_ALL_ON)
    `uvm_field_int ( slot_width,         UVM_ALL_ON)
    `uvm_field_int ( lut,         UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_sys_mem_comp_cfg");
    super.new(name);
  endfunction : new

  extern function lut_index_t get_lut_index();
  extern function bit get_lut_valid();
  extern function sinc_lut_t get_lut_value();

endclass : sinc_sys_mem_comp_cfg // }

function lut_index_t sinc_sys_mem_comp_cfg::get_lut_index();
  return(lut[`SINC_LUT_INDEX_RANGE]);
endfunction : get_lut_index

function bit sinc_sys_mem_comp_cfg::get_lut_valid();
  return(lut[sinc_parameters_pkg::KEY_VAULT_LUT_VALID_SEL]);
endfunction : get_lut_valid

function sinc_lut_t sinc_sys_mem_comp_cfg::get_lut_value();
  return(lut);
endfunction : get_lut_value


`endif //  `ifndef SINC_SYS_MEM_COMP_CFG_SVH
