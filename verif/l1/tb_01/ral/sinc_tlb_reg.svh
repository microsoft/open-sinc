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
// File        : sinc_tlb_reg.svh
// Description : 

`ifndef SINC_TLB_REG
 `define SINC_TLB_REG

// below registers class are just for comparison, they can be deleted afterwards
// NOTE: use get_path to set register fields, check example code below
/*
uvm_hdl_path_concat my_paths[$];

dst_reg.get_hdl_path(my_paths);
`uvm_info(report_str, $sformatf("print paths of register [%0s] ", 
				dst_reg.get_name()), UVM_HIGH);
foreach (my_paths[i]) begin
  `uvm_info(report_str, $sformatf("path [%0d] ", 
				  i), UVM_HIGH);
  foreach (my_paths[i].slices[j]) begin
    `uvm_info(report_str, $sformatf("path [%0d] - path[%0s], offset[%0d], size[%0d]", 
				    i, my_paths[i].slices[j].path, my_paths[i].slices[j].offset, my_paths[i].slices[j].size), UVM_HIGH);
  end   
end  
*/
// ---------------------------------------------- //
// class sinc_cmd_reg
//
// CMD Register implementation class
// ---------------------------------------------- //
class sinc_cmd_reg extends sinc_register;

  // sinc_regs::cmd.key_slot
  sinc_register_field key_slot;
  
  // sinc_regs::cmd.rsvd
  sinc_register_field rsvd;
  
  // sinc_regs::cmd.sel_cmd
  sinc_register_field sel_cmd;
  
  `uvm_object_utils_begin(sinc_cmd_reg)
    `uvm_field_object(key_slot, UVM_DEFAULT)
    `uvm_field_object(rsvd,     UVM_DEFAULT)
    `uvm_field_object(sel_cmd,  UVM_DEFAULT)
  `uvm_object_utils_end

  // function new()
  function new(string name = "sinc_seg_reg");
    super.new(name);

    key_slot = sinc_register_field::type_id::create("key_slot");
    key_slot.m_access = "RW";
    key_slot.m_lsb = `SINC_REGS_CMD_KEY_SLOT_LSB;
    key_slot.m_size = `SINC_REGS_CMD_KEY_SLOT_WIDTH;
    key_slot.m_reset  = `SINC_REGS_CMD_KEY_SLOT_RESET;
    m_fields.push_back(key_slot);

    rsvd = sinc_register_field::type_id::create("rsvd");
    rsvd.m_access = "RW";
    rsvd.m_lsb = `SINC_REGS_CMD_RSVD_LSB;
    rsvd.m_size = `SINC_REGS_CMD_RSVD_WIDTH;
    rsvd.m_reset  = `SINC_REGS_CMD_RSVD_RESET;
    m_fields.push_back(rsvd);

    sel_cmd = sinc_register_field::type_id::create("sel_cmd");
    sel_cmd.m_access = "RW";
    sel_cmd.m_lsb = `SINC_REGS_CMD_SEL_CMD_LSB;
    sel_cmd.m_size = `SINC_REGS_CMD_SEL_CMD_WIDTH;
    sel_cmd.m_reset  = `SINC_REGS_CMD_SEL_CMD_RESET;
    m_fields.push_back(sel_cmd);
  endfunction : new

endclass : sinc_cmd_reg

// ---------------------------------------------- //
// class sinc_cmd_reg
//
// Status Register implementation class
// ---------------------------------------------- //
class sinc_status_reg extends sinc_register;

  // sinc_regs::status.busy
  sinc_register_field busy;
  // sinc_regs::status.complete
  sinc_register_field complete;
  // sinc_regs::status.error_cmd
  sinc_register_field error_cmd;
  // sinc_regs::status.error_fault
  sinc_register_field error_fault;
  // sinc_regs::status.match_sts
  sinc_register_field match_sts;
  
  `uvm_object_utils_begin(sinc_status_reg)
    `uvm_field_object(busy, UVM_DEFAULT)
    `uvm_field_object(complete, UVM_DEFAULT)
    `uvm_field_object(error_cmd, UVM_DEFAULT)
    `uvm_field_object(error_fault, UVM_DEFAULT)
    `uvm_field_object(match_sts, UVM_DEFAULT)
  `uvm_object_utils_end

  // function new()
  function new(string name = "sinc_status_reg");
    super.new(name);

    busy = sinc_register_field::type_id::create("busy");
    busy.m_access = "RO";
    busy.m_lsb = `SINC_REGS_STATUS_BUSY_LSB;
    busy.m_size = `SINC_REGS_STATUS_BUSY_WIDTH;
    busy.m_reset  = `SINC_REGS_STATUS_BUSY_RESET;
    m_fields.push_back(busy);

    complete = sinc_register_field::type_id::create("complete");
    complete.m_access = "RC";
    complete.m_lsb = `SINC_REGS_STATUS_COMPLETE_LSB;
    complete.m_size = `SINC_REGS_STATUS_COMPLETE_WIDTH;
    complete.m_reset  = `SINC_REGS_STATUS_COMPLETE_RESET;
    m_fields.push_back(complete);

    error_cmd = sinc_register_field::type_id::create("error_cmd");
    error_cmd.m_access = "RC";
    error_cmd.m_lsb = `SINC_REGS_STATUS_ERROR_CMD_LSB;
    error_cmd.m_size = `SINC_REGS_STATUS_ERROR_CMD_WIDTH;
    error_cmd.m_reset  = `SINC_REGS_STATUS_ERROR_CMD_RESET;
    m_fields.push_back(error_cmd);

    error_fault = sinc_register_field::type_id::create("error_fault");
    error_fault.m_access = "RO";
    error_fault.m_lsb = `SINC_REGS_STATUS_ERROR_FAULT_LSB;
    error_fault.m_size = `SINC_REGS_STATUS_ERROR_FAULT_WIDTH;
    error_fault.m_reset  = `SINC_REGS_STATUS_ERROR_FAULT_RESET;
    m_fields.push_back(error_fault);

    match_sts = sinc_register_field::type_id::create("match_sts");
    match_sts.m_access = "RC";
    match_sts.m_lsb = `SINC_REGS_STATUS_MATCH_STS_LSB;
    match_sts.m_size = `SINC_REGS_STATUS_MATCH_STS_WIDTH;
    match_sts.m_reset  = `SINC_REGS_STATUS_MATCH_STS_RESET;
    m_fields.push_back(match_sts);

  endfunction : new

endclass : sinc_status_reg

// ---------------------------------------------- //
// class sinc_comp_buffer_reg
//
// Comp Buffer Register implementation class
// ---------------------------------------------- //
class sinc_comp_buffer_reg extends sinc_register;

  // sinc_regs::comp_buffer<*num>
  sinc_register_field comp_buffer;
  
  `uvm_object_utils_begin(sinc_comp_buffer_reg)
    `uvm_field_object(comp_buffer, UVM_DEFAULT)
  `uvm_object_utils_end

  // function new()
  function new(string name = "sinc_comp_buffer_reg");
    super.new(name);

    comp_buffer = sinc_register_field::type_id::create(name);
    comp_buffer.m_access = "WO";
    comp_buffer.m_lsb = `SINC_REGS_COMP_BUFFER0_COMP_BUFFER0_LSB;
    comp_buffer.m_size = `SINC_REGS_COMP_BUFFER0_COMP_BUFFER0_WIDTH;
    comp_buffer.m_reset  = `SINC_REGS_COMP_BUFFER0_COMP_BUFFER0_RESET;
    m_fields.push_back(comp_buffer);
    
  endfunction : new

endclass : sinc_comp_buffer_reg

// ----------------------------------------------------------- //
// class sinc_tlb_reg
//
// Key Vault registers instances
// ----------------------------------------------------------- //
class sinc_tlb_reg extends uvm_object;

  // SINC configuration registers base address
  bit [31:0]                  base_addr;
  
  // CMD registers
  rand sinc_cmd_reg             cmd;
  
  // STATUS registers
  rand sinc_status_reg          status;
  
  // COMP_BUFFER[0-KEY_VAULT_KEY_WIDTH/32-1] registers
  rand sinc_comp_buffer_reg     comp_buffers[sinc_parameters_pkg::KEY_VAULT_KEY_WIDTH/32];

  // array of registers within TLB
  sinc_register                 regs[];

  `uvm_object_utils_begin(sinc_tlb_reg)
    `uvm_field_int          (base_addr,           UVM_DEFAULT | UVM_HEX      )
    `uvm_field_sarray_object(comp_buffers,        UVM_DEFAULT                )
    `uvm_field_object       (cmd,                 UVM_DEFAULT                )
    `uvm_field_object       (status,              UVM_DEFAULT                )
  `uvm_object_utils_end

  // function new()
  function new (string name = "sinc_tlb_reg");
    super.new(name);

    cmd           = sinc_cmd_reg::type_id::create("cmd");
    status        = sinc_status_reg::type_id::create("status");
    
    for (int i = 0; i < sinc_parameters_pkg::KEY_VAULT_KEY_WIDTH/32; i++) begin
      comp_buffers[i]    = sinc_comp_buffer_reg::type_id::create($sformatf("comp_buffer%0d", i));
    end

    regs                 = {cmd, status, comp_buffers};
    initialize();
  endfunction : new

  // reset TLB
  virtual function void reset();
    foreach (comp_buffers[idx]) begin
      comp_buffers[idx].reset();
    end

    cmd.reset();
    status.reset();
  endfunction : reset

  virtual function void initialize();
    base_addr               = sinc_parameters_pkg::KEY_VAULT_REG_START_ADDR;

    cmd.set_addr(base_addr + `SINC_REGS_CMD_ADDRESS);
    cmd.m_reset = `SINC_REGS_CMD_RESET_VALUE;

    status.set_addr(base_addr + `SINC_REGS_STATUS_ADDRESS);
    status.m_reset = `SINC_REGS_STATUS_RESET_VALUE;
    
    foreach (comp_buffers[idx]) begin
      comp_buffers[idx].set_addr(base_addr + `SINC_REGS_COMP_BUFFER0_ADDRESS + idx*'h4);
      comp_buffers[idx].m_reset = `SINC_REGS_COMP_BUFFER0_RESET_VALUE;
    end

  endfunction : initialize

  //  initialize content of configuration registers
  function void pre_randomize();
    //
  endfunction: pre_randomize

  // Get all addresses of the registers
  virtual function sinc_reg_q_addr_t get_all_regs_addrs();
    sinc_reg_addr_t addrs_q[$];
    foreach (regs[i])
      addrs_q.push_back(regs[i].m_addr);
    return (addrs_q);
  endfunction : get_all_regs_addrs

  // Get register by address (returns reference to the register)
  // if register found - reference returned, otherwise null
  virtual function sinc_register get_reg_by_addr(sinc_reg_addr_t addr);
    sinc_register qf[$] = regs.find_first with (item.m_addr == addr);
    return (qf.pop_front());
  endfunction : get_reg_by_addr

  // Get register by name (returns reference to the register)
  // if register found - reference returned, otherwise null
  virtual function sinc_register get_reg_by_name(string r_name);
    sinc_register qf[$] = regs.find_first with (item.m_name == r_name);
    return (qf.pop_front());
  endfunction : get_reg_by_name

  // Get reg data by name
  // return register value
  virtual function sinc_reg_data_t get_reg_data_by_name(string r_name);
    sinc_register my_reg_handler;
    sinc_register qf[$] = regs.find_first with (item.m_name == r_name);
    my_reg_handler = qf.pop_front();
    return my_reg_handler.get_data();
  endfunction : get_reg_data_by_name

  // Get busy
  // return busy state
  virtual function sinc_reg_data_t get_busy();
    return status.busy.get_field_data();
  endfunction : get_busy

  // Get complete
  // return complete state
  virtual function sinc_reg_data_t get_complete();
    return status.complete.get_field_data();
  endfunction : get_complete

  // Get error_cmd
  // return error_cmd state
  virtual function sinc_reg_data_t get_error_cmd();
    return status.error_cmd.get_field_data();
  endfunction : get_error_cmd

  // Get error_fault
  // return error_fault state
  virtual function sinc_reg_data_t get_error_fault();
    return status.error_fault.get_field_data();
  endfunction : get_error_fault

  // Get match_sts
  // return match_sts state
  virtual function sinc_reg_data_t get_match_sts();
    return status.match_sts.get_field_data();
  endfunction : get_match_sts

  // Set register by name 
  // if register found - return 1
  // else - return 0
  virtual function bit set_reg_by_name(string r_name, sinc_reg_data_t r_data);
    string report_str = "SET_REG_BY_NAME";
    sinc_register match_reg;    
    sinc_register qf[$] = regs.find_first with (item.m_name == r_name);

    
    `uvm_info(report_str, $sformatf("[%0s] -set Data [%0h]", 
				    r_name, r_data), UVM_HIGH);

    if (qf.size()) begin
      match_reg = qf.pop_front();
      match_reg.set_data(r_data);
      return 1;
    end else begin
      return 0;
    end
  endfunction : set_reg_by_name

  // Set register RC by name 
  // if register found - set RC registers
  virtual function void set_reg_rc_by_name(string r_name);
    string report_str = "SET_REG_RC_BY_NAME";
    sinc_register match_reg;   
    sinc_register qf[$] = regs.find_first with (item.m_name == r_name);

    `uvm_info(report_str, $sformatf("[%0s]", 
				    r_name), UVM_HIGH);

    if (qf.size()) begin
      match_reg = qf.pop_front();
      match_reg.set_rc();
    end else begin
      // do nothing
    end
  endfunction : set_reg_rc_by_name

  // Set register by name 
  // if register found - return 1
  // else - return 0
  virtual function bit set_reg_field_by_name(string r_reg_name, string r_field_name, sinc_reg_data_t r_data);
    string report_str = "SET_REG_FIELD_BY_NAME";
    sinc_register match_reg;
    bit found = 0;
    sinc_register qf[$] = regs.find_first with (item.m_name == r_reg_name);

    `uvm_info(report_str, $sformatf("[%0s] - [%0s] set Field Data [%0h]", 
				    r_reg_name, r_field_name, r_data), UVM_HIGH);
    
    if (qf.size()) begin
      match_reg = qf.pop_front();
      `uvm_info(get_name(), $sformatf("Found register [%0s]", 
					match_reg.m_name), UVM_HIGH);
      foreach (match_reg.m_fields[i]) begin
	if (match_reg.m_fields[i].m_name == r_field_name) begin
	  `uvm_info(get_name(), $sformatf("Found register Field [%0s], set Field Data[%0h]", 
					  match_reg.m_fields[i].m_name, r_data), UVM_HIGH);
	  match_reg.m_fields[i].set_field_data(r_data);
	  found = 1;
	end
      end
    end

    return found;

  endfunction : set_reg_field_by_name

  // Does the register w/ given address exist?
  virtual function bit reg_exists(sinc_reg_addr_t addr);
    return (addr inside {get_all_regs_addrs()});
  endfunction : reg_exists

  //-----------------------------------------------------------------
  // Function: print_tlb_reg
  //   Print register TLB status
  //
  virtual function void print_tlb_reg ();
    string  str;
    str = "\n ****************************************** \n";
    str = {str, "\n Print Key Vault TB Register TLB Status \n"};
    foreach (regs[i]) begin
      str = {str, $sformatf(" Register [%0s] : start_addr[%0h], value[%0h]\n", regs[i].m_name, regs[i].m_addr, regs[i].get_data())};
      foreach (regs[i].m_fields[f_idx]) begin
	str = {str, $sformatf(" - [%0s]:[%0h] ", regs[i].m_fields[f_idx].m_name, regs[i].m_fields[f_idx].get_field_data())};
      end
      str = {str, "\n"};
    end // foreach (_comp_list[i])
    str = {str, "\n ****************************************** \n"};
    `uvm_info("SINC_TLB_REG/PRINT_TLB_REG", str, UVM_NONE);

  endfunction : print_tlb_reg
  
endclass: sinc_tlb_reg


`endif //SINC_TLB_REG
