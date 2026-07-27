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
// File        : sinc_sys_comp_cfg.svh
// Description : 

`ifndef SINC_SYS_COMP_CFG
`define SINC_SYS_COMP_CFG

class sinc_sys_comp_cfg extends uvm_object; // {

  // Variable: m_comp_type
  // Indicates the component type
  sinc_comp_e m_comp_type;

  // Variable: m_local_name
  // String version of comp_nodie without the COMP_ prefix
  string m_local_name;

  // Variable: m_type_instance_name
  // String version of comp type instance name (ex. SINC_SP, SINC_CACHE, SINC_REG)
  string m_type_instance_name;

  // Variable: m_comp_type_name
  // String version of comp type name (ex. SP, CACHE, VTAG, RNG ...)
  string m_comp_type_name;

  // Variable: m_instance_id
  // Indicates this component's instanceID
  int m_instance_id;

  // string representing XMR HDL path leading to this component's module instance
  string m_hdl_path;

  // Variable: m_is_initiator
  // Indicates this is a request component
  bit m_is_initiator;

  // Variable: m_is_subordinate
  // Indicates this is a request component
  bit m_is_subordinate;

  // Variable: m_is_axi_master
  // Indicates this is a AXI master interface
  bit m_is_axi_master;

  // Variable: m_is_sp
  // Indicates this is a Security Processor
  bit m_is_sp;

  // Variable: m_is_reg
  // Indicates this component is belongs to SINC register
  bit m_is_reg;

  // port number for this component
  int m_port_num;
  int m_num_of_this_type;

  bit m_is_axi_intf;

  // Variable: m_base_addr
  // Base address for this component in the address map per the access interface
  logic [31:0] m_base_addr;

  // Variable: m_start_addr
  // Start address for this component in the address map per the access interface
  logic [31:0] m_start_addr;

  // Variable: m_index_width
  // axi addr = KEY_MEM_BEGIN_ADDRESS + key_slot*'h20 + key_index*'h4_0000;
  int m_index_width;

  // Variable: m_end_addr
  // End address for this component in the address map per the access interface
  logic [31:0] m_end_addr;

  // Variable: m_addr_width
  // Width of addr port for accessing this component
  int m_addr_width;

  // Variable: m_addr_mask
  // Address mask for accessing this component
  longint unsigned m_addr_mask;

  // Variable: m_addr_lsb
  // LSB of addr port for accessing this component
  int m_addr_lsb;

  // Variable: m_addr_msb
  // MSB of addr port for accessing this component
  int m_addr_msb;

  // Variable: m_data_width
  // Width of data port for accessing this component
  int m_data_width;

  // Variable: m_num_cache_lines
  int m_num_cache_lines;

  // Variable: m_num_key_ranges
  // Number of KEY ranges present in this SINC_COMP
  int m_num_key_ranges;

  // Variable: m_num_lut_ranges
  // Number of attr ranges present in this SINC_COMP
  int m_num_lut_ranges;

  // Variable: m_valid_mstr_list
  // List of masters can access to this SINC_COMP region
  sinc_comp_list_t m_valid_mstr_list;

  // Variable: m_cmd_to_dst_list
  // List of commands that can access to this SINC_COMP
  req_cmd_list_t m_cmd_to_dst_list[sinc_env_pkg::sinc_comp_e];

  // Variable: m_valid_cmd_at_cache_state
  // List of commands that will not be blocked in cache states
  req_cmd_list_t m_valid_cmd_at_cache_state[sinc_parameters_pkg::sinc_cache_state_type_e];

  // keep track of valid slots
  // this is apply to LUT
  int m_valid_slot_list[$];

  // register cfg specific
  sinc_parameters_pkg::sinc_reg_e m_readable_reg_list[$];
  sinc_parameters_pkg::sinc_reg_e m_writeable_reg_list[$];
  sinc_parameters_pkg::sinc_reg_e m_write_discard_in_cache_disable_reg_list[$];
  sinc_parameters_pkg::sinc_reg_e m_write_discard_in_cache_init_reg_list[$];
  sinc_parameters_pkg::sinc_reg_e m_write_discard_in_cache_active_reg_list[$];
  sinc_parameters_pkg::sinc_reg_e m_write_discard_in_cache_fail_reg_list[$];

  // fw cmd specific
  sinc_parameters_pkg::sinc_fw_cmd_e m_fw_cmd_allow_in_cache_disable_cmd_list[$];
  sinc_parameters_pkg::sinc_fw_cmd_e m_fw_cmd_allow_in_cache_init_cmd_list[$];
  sinc_parameters_pkg::sinc_fw_cmd_e m_fw_cmd_allow_in_cache_active_cmd_list[$];
  sinc_parameters_pkg::sinc_fw_cmd_e m_fw_cmd_allow_in_cache_fail_cmd_list[$];

  `uvm_object_utils_begin(sinc_sys_comp_cfg)
      // FIXME: Rename usage of field 'tb.sinc_env_pkg::sinc_sys_comp_cfg.comp_type' to 'm_comp_type' inside the macro call below
    `uvm_field_enum(sinc_comp_e, m_comp_type,       UVM_ALL_ON)
    `uvm_field_int ( m_instance_id,                 UVM_ALL_ON)
    `uvm_field_int ( m_port_num,                    UVM_ALL_ON)
    `uvm_field_int ( m_is_axi_intf,                 UVM_ALL_ON)
    `uvm_field_int ( m_is_axi_master,               UVM_ALL_ON)
    `uvm_field_int ( m_is_sp,                       UVM_ALL_ON)
    `uvm_field_int ( m_is_reg,                      UVM_ALL_ON)
    `uvm_field_int ( m_num_of_this_type,            UVM_ALL_ON)
    `uvm_field_int ( m_start_addr,                  UVM_ALL_ON)
    `uvm_field_int ( m_end_addr,                    UVM_ALL_ON)
    `uvm_field_int ( m_addr_width,                  UVM_ALL_ON)
    `uvm_field_int ( m_addr_mask,                   UVM_ALL_ON)
    `uvm_field_int ( m_addr_lsb,                    UVM_ALL_ON)
    `uvm_field_int ( m_addr_msb,                    UVM_ALL_ON)
    `uvm_field_int ( m_data_width,                  UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_sys_comp_cfg");
    super.new(name);
  endfunction : new

  extern virtual function void update_lut(int slot, sinc_lut_t value, uvm_verbosity verbosity = UVM_DEBUG);
  extern virtual function void update_key(int slot, const ref key_data_t value, input uvm_verbosity verbosity = UVM_DEBUG);
  extern virtual function bit is_valid_list_empty();
  extern virtual function int get_a_rand_valid_slot();

endclass : sinc_sys_comp_cfg // }

//-----------------------------------------------------------------
// Function: update_lut
//   update lut slot by it's slot number
//   this method will also update valid slot list
//
function void sinc_sys_comp_cfg::update_lut(int slot, sinc_lut_t value, uvm_verbosity verbosity = UVM_DEBUG);
  /*
   int result_q_index[$];
   bit [31:0] lut_reserve_bits_mask = (1 << (sinc_parameters_pkg::KEY_VAULT_LUT_AXI_WR_RESERVED_LSB + 1)) - 1;

   // update lut value
   value &= lut_reserve_bits_mask;
   `uvm_info("sinc_sys_comp_cfg:", $sformatf("Update LUT[%0d] from [%0h] to [%0h]", slot, slot_cfg[slot].lut, value), verbosity);

   slot_cfg[slot].lut = value;


   // update valid slot list
   m_valid_slot_list.unique();
   result_q_index = m_valid_slot_list.find_first_index with (item == slot);

   // for existing valid slot, remove it from list if lut is updated with invalid (lut[KEY_VAULT_LUT_VALID_SEL])
   if (result_q_index.size()==1) begin
   if (!slot_cfg[slot].lut[sinc_parameters_pkg::KEY_VAULT_LUT_VALID_SEL]) begin
   m_valid_slot_list.delete(result_q_index[0]);
   `uvm_info("sinc_sys_comp_cfg:", $sformatf("Remove slot[%0d] from m_valid_slot_list", slot), UVM_LOW);
   end
   end

   // for non existing valid slot, add it to the m_valid_slot_list
   if (result_q_index.size()==0) begin
   if (slot_cfg[slot].lut[sinc_parameters_pkg::KEY_VAULT_LUT_VALID_SEL]) begin
   m_valid_slot_list.push_back(slot);
   `uvm_info("sinc_sys_comp_cfg:", $sformatf("Add slot[%0d] to m_valid_slot_list", slot), UVM_LOW);
   end
   end
   */

endfunction : update_lut

//-----------------------------------------------------------------
// Function: update_lut
//   update lut slot by it's slot number
//   this method will also update valid slot list
//
function bit sinc_sys_comp_cfg::is_valid_list_empty();
  /*
   return (m_valid_slot_list.size()? 1'b0: 1'b1);
   */
endfunction : is_valid_list_empty

//-----------------------------------------------------------------
// Function: update_key
//   update key slot by it's slot number
//   this method will also update valid slot list
//
function void sinc_sys_comp_cfg::update_key(int slot, const ref key_data_t value, input uvm_verbosity verbosity = UVM_DEBUG);
  /*
   // update key value
   `uvm_info("sinc_sys_comp_cfg:", $sformatf("Update KEY[%0d] from [%0p] to [%0p]", slot, slot_cfg[slot].key, value), verbosity);
   slot_cfg[slot].key = value;
   */
endfunction : update_key

//-----------------------------------------------------------------
// Function: get_a_rand_valid_slot
//   update key slot by it's slot number
//   this method will also update valid slot list
//
function int sinc_sys_comp_cfg::get_a_rand_valid_slot();
  /*
   int rand_index;

   m_valid_slot_list.unique();

   if (m_valid_slot_list.size()) begin
   // In VCS, random constraint need to pass specific value instead of array for assignment, thus we need to do the randomization here
   rand_index = $urandom_range(m_valid_slot_list.size()-1, 0);
   return m_valid_slot_list[rand_index];
   end else begin
   return -1;
   end
   */
endfunction : get_a_rand_valid_slot

`endif // SINC_SYS_COMP_CFG
