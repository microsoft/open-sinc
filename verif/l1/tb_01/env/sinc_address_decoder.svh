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
// File        : sinc_address_decoder.svh
// Description : This class is used for address decode.

`ifndef SINC_ADDRESS_DECODER
`define SINC_ADDRESS_DECODER
typedef sinc_comp_e compq_t[$];
typedef string stringq_t[$];
// typedef address_type_e  address_typeq_t[$];

// Handles decoding of address at SINC level
class sinc_address_decoder extends uvm_component;
  `uvm_component_utils_begin(sinc_address_decoder)
  `uvm_component_utils_end

  //`uvm_analysis_imp_decl(_reset_xp)
  //uvm_analysis_imp_reset_xp#(rst_pkg::rst_seq_item, sinc_address_decoder) reset_xp;

  //  Variables
  // sinc_address_range              addr_ranges[sinc_comp_e][$];
  local static sinc_address_decoder m_sinc_address_decoder_instance;
  sinc_comp_list_t                  m_comp_list[sinc_comp_e];          // list of component for a type
  sinc_sys_cfg                      m_sys_cfg;
  sinc_sys_comp_cfg                 m_cache_sys_cfg;
  sinc_sys_comp_cfg                 m_reg_sys_cfg;
  bit                               m_printed_address_ranges        =0;
  // int                            m_num_ranges[sinc_comp_e][address_type_e];
  // bit                            m_master_addr_types[address_type_e][sinc_comp_e];
  // int                            m_enabled_ranges[sinc_comp_e][address_type_e][$]; // Contains indices of addr_ranges which are enabled
  // address_type_e                 m_address_type_list[$];

  // Functions
  extern function new(string name="address_decoder", uvm_component parent);
  extern virtual task reset_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern static function sinc_address_decoder get_inst();

  // below are temporaty address decoder helper functions
  extern virtual function sinc_comp_e get_dst_type_hit_w_axi_addr(address_t address);
  // return the reg handler of TLB register
  extern virtual function uvm_reg get_reg_tlb_hit(address_t address);
  extern virtual function uvm_reg get_reg_tlb_hit_by_name(string reg_name);
  // return the reg handler of RAL register
  extern virtual function uvm_reg get_reg_ral_hit(address_t address);
  extern virtual function uvm_reg get_reg_ral_hit_by_name(string reg_name);

endclass : sinc_address_decoder

// Functions in sinc_address_decoder class
//  Constructor
//  Should only be called once in the entire simulation
function sinc_address_decoder::new(string name="address_decoder", uvm_component parent);
  super.new(name, parent);
  if(sinc_address_decoder::m_sinc_address_decoder_instance == null) begin
    sinc_address_decoder::m_sinc_address_decoder_instance = this;
    `uvm_info("sinc_address_decoder", "Inst:antiating sinc_address_decoder", UVM_HIGH)
  end
  //configure_num_ranges();
  //setup_address_type_list();
  //reset_xp = new("reset_xp", this);
endfunction : new

// Configure address_decoder in connect_phase
function void sinc_address_decoder::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info("sinc_address_decoder", "connect_phase", UVM_HIGH)
  m_sys_cfg       = sinc_sys_cfg::get_inst();
  m_cache_sys_cfg = m_sys_cfg.get_comp_cfg(sinc_env_pkg::SINC_CACHE);
  m_reg_sys_cfg   = m_sys_cfg.get_comp_cfg(sinc_env_pkg::SINC_REG);
  //set_comp_list();
endfunction : connect_phase

// Configure the address range as the initial address range
// Configure address_decoder in connect_phase
task sinc_address_decoder::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  `uvm_info("sinc_address_decoder", "Configure the address range for SINC", UVM_LOW)
  //initialize(); // Called for SINC TB
endtask : reset_phase

// A static function which returns instance of sinc_address_decoder
function sinc_address_decoder sinc_address_decoder::get_inst();
  if (m_sinc_address_decoder_instance != null) begin
    return (m_sinc_address_decoder_instance);
  end else begin
    // uvm_error can't be called from a static method, so call it from the root
    uvm_root::get().uvm_report_error("sinc_address_decoder", "Address Decoder must be created before get_inst() is called\n", UVM_NONE, `uvm_file, `uvm_line);
    return (null);
  end
endfunction : get_inst

// Returns the destination component type hit by the address
function sinc_comp_e sinc_address_decoder::get_dst_type_hit_w_axi_addr(address_t address);

  // `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf("", is_valid_dst, is_valid_cmd), UVM_HIGH)

  //if ((address >= reg_sys_cfg.m_start_addr) && (address <= reg_sys_cfg.m_end_addr)) begin
  //   return(SINC_REG);
  // end

  begin
    sinc_comp_e comp = comp.first();
    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf("check on comp:%0s", comp.name()), UVM_HIGH)
    while (comp != comp.last()) begin
      if (m_sys_cfg.m_comp_cfg.exists(comp)) begin
        `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf("comp[%0s], m_start_addr[`h%0h], m_end_addr[`h%0h]", comp.name(), m_sys_cfg.m_comp_cfg[comp].m_start_addr, m_sys_cfg.m_comp_cfg[comp].m_end_addr), UVM_HIGH)
        if ((address >= m_sys_cfg.m_comp_cfg[comp].m_start_addr) && (address <= m_sys_cfg.m_comp_cfg[comp].m_end_addr)) begin
          return(comp);
        end
      end
      comp = comp.next();
    end
  end
  return (SINC_NULL);

endfunction : get_dst_type_hit_w_axi_addr

// Returns register hit by an address
function uvm_reg sinc_address_decoder::get_reg_tlb_hit(address_t address);
  address_t      modified_address;
  address_t      slot_address;
  address_t      index_address;
  int            slot;
  int            index;
  uvm_reg_addr_t addr_min;
  uvm_reg_addr_t addr_max;
  uvm_reg        my_regs[$];

  if (!((address >= m_reg_sys_cfg.m_start_addr) && (address <= m_reg_sys_cfg.m_end_addr))) begin
    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": fail to get register, check on address[`h%0h], reg_start_addr[`h%0h], reg_end_addr[`h%0h]",
        address, m_reg_sys_cfg.m_start_addr, m_reg_sys_cfg.m_end_addr), UVM_HIGH)
    return(null);
  end

  // sys_cfg.m_regmodel.get_registers(my_regs);
  m_sys_cfg.m_sinc_reg_tlb.get_registers(my_regs);

  foreach (my_regs[i]) begin
    uvm_reg_addr_t curr_addr = uvm_reg_addr_t'(address);
    curr_addr[1:0]           = 0; // bit 1:0 are don't cares
    addr_min                 = my_regs[i].get_address();
    addr_max                 = addr_min + my_regs[i].get_n_bytes() - 1;

    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": check on reg[%0s], curr_addr[`h%0h], addr_min[`h%0h], addr_max[`h%0h]",
        my_regs[i].get_name(), curr_addr, addr_min, addr_max), UVM_DEBUG)
    if (curr_addr inside {[addr_min:addr_max]}) begin
      `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(":return register[%0s]", my_regs[i].get_name()), UVM_DEBUG)
      return (my_regs[i]);
    end
  end

  return(null);
endfunction : get_reg_tlb_hit

// Returns register hit by reg name
function uvm_reg sinc_address_decoder::get_reg_tlb_hit_by_name(string reg_name);
  string  debug_str  = "GET_REG_HIT_BY_NAME";
  uvm_reg my_regs[$];

  // sys_cfg.m_regmodel.get_registers(my_regs);
  m_sys_cfg.m_sinc_reg_tlb.get_registers(my_regs);

  foreach (my_regs[i]) begin
    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": check on reg[%0s], look up for reg name[%0s]",
        my_regs[i].get_name(), reg_name), UVM_DEBUG)
    if (my_regs[i].get_name() == reg_name) begin
      `uvm_info(debug_str, $sformatf(":return register[%0s]", my_regs[i].get_name()), UVM_DEBUG)
      return (my_regs[i]);
    end
  end

  return(null);
endfunction : get_reg_tlb_hit_by_name

// Returns register hit by an address
function uvm_reg sinc_address_decoder::get_reg_ral_hit(address_t address);
  address_t      modified_address;
  address_t      slot_address;
  address_t      index_address;
  int            slot;
  int            index;
  uvm_reg_addr_t addr_min;
  uvm_reg_addr_t addr_max;
  uvm_reg        my_regs[$];

  if (!((address >= m_reg_sys_cfg.m_start_addr) && (address <= m_reg_sys_cfg.m_end_addr))) begin
    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": fail to get register, check on address[`h%0h], reg_start_addr[`h%0h], reg_end_addr[`h%0h]",
        address, m_reg_sys_cfg.m_start_addr, m_reg_sys_cfg.m_end_addr), UVM_HIGH)
    return(null);
  end

  m_sys_cfg.m_regmodel.get_registers(my_regs);

  foreach (my_regs[i]) begin
    uvm_reg_addr_t curr_addr = uvm_reg_addr_t'(address);
    curr_addr[1:0]           = 0; // bit 1:0 are don't cares
    addr_min                 = my_regs[i].get_address();
    addr_max                 = addr_min + my_regs[i].get_n_bytes() - 1;

    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": check on reg[%0s], curr_addr[`h%0h], addr_min[`h%0h], addr_max[`h%0h]",
        my_regs[i].get_name(), curr_addr, addr_min, addr_max), UVM_DEBUG)
    if (curr_addr inside {[addr_min:addr_max]}) begin
      `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(":return register[%0s]", my_regs[i].get_name()), UVM_DEBUG)
      return (my_regs[i]);
    end
  end

  return(null);
endfunction : get_reg_ral_hit

// Returns register hit by reg name
function uvm_reg sinc_address_decoder::get_reg_ral_hit_by_name(string reg_name);
  string  debug_str  = "GET_REG_HIT_BY_NAME";
  uvm_reg my_regs[$];

  m_sys_cfg.m_regmodel.get_registers(my_regs);

  foreach (my_regs[i]) begin
    `uvm_info("ADDRESS_DECODER_DEBUG", $sformatf(": check on reg[%0s], look up for reg name[%0s]",
        my_regs[i].get_name(), reg_name), UVM_DEBUG)
    if (my_regs[i].get_name() == reg_name) begin
      `uvm_info(debug_str, $sformatf(":return register[%0s]", my_regs[i].get_name()), UVM_DEBUG)
      return (my_regs[i]);
    end
  end

  return(null);
endfunction : get_reg_ral_hit_by_name

`endif // SINC_ADDRESS_DECODER
