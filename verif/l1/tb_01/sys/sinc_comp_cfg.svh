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
// File        : sinc_comp_cfg.svh
// Description : 

`ifndef SINC_COMP_CFG_SVH
`define SINC_COMP_CFG_SVH

class sinc_comp_cfg extends uvm_object;  // {

  typedef sinc_env_pkg::sinc_cmd_e comp_cmd_list_t[$];

  // Variable: comp_type
  // Indicates the component type
  sinc_comp_e comp_type;

  // Variable: local_name
  // String version of comp_nodie without the COMP_ prefix
  string local_name;

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_MP, SINC_CCS, SINC_SHA, SINC_KEY)
  string type_instance_name;

  // Variable: comp_type_name
  // String version of comp type name (ex. MP, CCS, SHA, KEY, PCR)
  string comp_type_name;

  // Variable: instance_id
  // Indicates this component's instanceID 
  int instance_id;

  // string representing XMR HDL path leading to this component's module instance
  string hdl_path;

  // Variable: is_axi_master
  // Indicates this is a AXI master interface
  bit is_axi_master;

  // Variable: is_mp
  // Indicates this is a Security Processor
  bit is_mp;

  // Variable: is_ccs
  // Indicates this is a Complex Command Engine 
  bit is_ccs;

  // Variable: is_sha
  // Indicates this is a Secure Hash Engine 
  bit is_sha;

  // Variable: is_upka
  // Indicates this is a Public Key Accelerator 
  bit is_upka;

  // Variable: is_aes
  // Indicates this is a Advanced Encryption Standard Engine 
  bit is_aes;

  // Variable: is_key
  // Indicates this component is belongs to SINC Key Memory
  bit is_key;

  // Variable: is_lut
  // Indicates this component is belongs to SINC Look Up Table
  bit is_lut;

  // Variable: is_reg
  // Indicates this component is belongs to SINC register
  bit is_reg;

  // port number for this component
  int port_num;
  int num_of_this_type;

  bit is_axi_intf;

  // Variable: len_width
  // Width of length port for this component's access
  int len_width;

  // Variable: user_width
  // Width of requser port for this component
  int user_width;
  
  // Variable: master_id_width
  // Width of master_id port for accessing this component
  int master_id_width;

  // Variable: start_addr
  // Start address for this component in the address map per the access interface
  int start_addr;

  // Variable: addr_width
  // Width of addr port for accessing this component
  int addr_width;

  // Variable: addr_mask
  // Address mask for accessing this component
  longint unsigned addr_mask;

  // Variable: addr_lsb
  // LSB of addr port for accessing this component
  int addr_lsb;

  // Variable: addr_msb
  // MSB of addr port for accessing this component
  int addr_msb;

  // Variable: data_width
  // Width of data port for accessing this component
  int data_width;

  // Variable: rd_rmp_data_width
  // Width of read response data port for accessing this component
  int rd_rsp_data_width;

  // Variable: num_key_ranges
  // Number of KEY ranges present in this KSB
  int num_key_ranges;

  // Variable: num_lut_ranges
  // Number of attr ranges present in this KSB
  int num_lut_ranges;

  // Variable: num_pcr_ranges
  // Number of pcr ranges present in this KSB
  int num_pcr_ranges;

  // Variable: valid_mstr_list
  // List of masters can access to this KSB region
  comp_type_list_t valid_mstr_list;
  
  // Variable: valid_master_cmd_list
  // List of commands from each master that can access to this KSB region
  //sinc_env_pkg::sinc_cmd_e valid_master_cmd_list[sinc_env_pkg::sinc_comp_e];
  comp_cmd_list_t valid_master_cmd_list[sinc_env_pkg::sinc_comp_e];

  // List of component types this.component can access
  comp_type_list_t valid_sinc_access_comp_list = {};

  // List of component types this.component can access
  comp_type_list_t valid_ksb_access_comp_list = {};
  
  // Variable: valid_kli_cmd_list
  // List of commands from KLI that can access to this KSB region
  comp_cmd_list_t valid_kli_cmd_list = {};

  // Variable: valid_sp_cmd_list
  // List of commands from SP that can access to this KSB region
  comp_cmd_list_t valid_sp_cmd_list;

  // Variable: valid_cce_cmd_list
  // List of commands from CCE that can access to this KSB region
  comp_cmd_list_t valid_cce_cmd_list;

  // Variable: valid_sha_cmd_list
  // List of commands from SHA that can access to this KSB region
  comp_cmd_list_t valid_sha_cmd_list;

  // Variable: valid_pka_cmd_list
  // List of commands from PKA that can access to this KSB region
  comp_cmd_list_t valid_pka_cmd_list;

  // Variable: valid_aes_cmd_list
  // List of commands from AES that can access to this KSB region
  comp_cmd_list_t valid_aes_cmd_list;

  // Subtypes for KEY/ATTR/PCR slots
  sinc_misc_comp_cfg slot_cfg[int];

  `uvm_object_utils_begin(sinc_comp_cfg)
    `uvm_field_enum(sinc_comp_e,       comp_type,            UVM_ALL_ON)
    `uvm_field_int (                  instance_id,          UVM_ALL_ON)
    `uvm_field_int (                  port_num,             UVM_ALL_ON)
    `uvm_field_int (                  is_axi_intf,          UVM_ALL_ON)
    `uvm_field_int (                  is_axi_master,        UVM_ALL_ON)
    `uvm_field_int (                  is_kli,               UVM_ALL_ON)
    `uvm_field_int (                  is_mp,                UVM_ALL_ON)
    `uvm_field_int (                  is_rp,                UVM_ALL_ON)
    `uvm_field_int (                  is_msb,               UVM_ALL_ON)
    `uvm_field_int (                  is_ccs,               UVM_ALL_ON)
    `uvm_field_int (                  is_sha,               UVM_ALL_ON)
    `uvm_field_int (                  is_upka,              UVM_ALL_ON)
    `uvm_field_int (                  is_aes,               UVM_ALL_ON)
    `uvm_field_int (                  is_ksb,               UVM_ALL_ON)
    `uvm_field_int (                  is_ksb_key,           UVM_ALL_ON)
    `uvm_field_int (                  is_lut,               UVM_ALL_ON)
    `uvm_field_int (                  is_ksb_pcr,           UVM_ALL_ON)
    `uvm_field_int (                  is_reg,               UVM_ALL_ON)
    `uvm_field_int (                  num_of_this_type,     UVM_ALL_ON)
    `uvm_field_int (                  len_width,            UVM_ALL_ON)
    `uvm_field_int (                  master_id_width,      UVM_ALL_ON)
    `uvm_field_int (                  start_addr,           UVM_ALL_ON)
    `uvm_field_int (                  addr_width,           UVM_ALL_ON)
    `uvm_field_int (                  addr_mask,            UVM_ALL_ON)
    `uvm_field_int (                  addr_lsb,             UVM_ALL_ON)
    `uvm_field_int (                  addr_msb,             UVM_ALL_ON)
    `uvm_field_int (                  num_key_ranges,       UVM_ALL_ON)
    `uvm_field_int (                  num_lut_ranges,       UVM_ALL_ON)
    `uvm_field_int (                  data_width,           UVM_ALL_ON)
    `uvm_field_int (                  rd_rsp_data_width,    UVM_ALL_ON)
    `uvm_field_int (                  user_width,           UVM_ALL_ON)
  `uvm_object_utils_end


  function new(string name="sinc_comp_cfg");
    super.new(name);
  endfunction : new

endclass : sinc_comp_cfg // }

`endif //  `ifndef SINC_COMP_CFG_SVH
