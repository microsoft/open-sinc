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
// File        : sinc_register.svh
// Description : 

`ifndef SINC_REGISTER
`define SINC_REGISTER

// ---------------------------------------------- //
// class sinc_register
//
// Base class for all SINC registers
// ---------------------------------------------- //
class sinc_register extends uvm_object;

  sinc_reg_addr_t      m_addr;      // Address field
  sinc_register_field  m_fields[$]; // Data fields
  rand sinc_reg_data_t m_data;
  string               m_name;
  string               m_access;
  bit [31:0]           m_reset;

  `uvm_object_utils_begin(sinc_register)
    `uvm_field_int          (m_addr,   UVM_DEFAULT | UVM_HEX)
    `uvm_field_sarray_object(m_fields, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int          (m_data,   UVM_DEFAULT | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "");
    super.new(name);
    m_name = name;
  endfunction : new

  extern virtual function void pack_data();

  virtual function void unpack_data();
    if (m_fields.size() == 0) begin
      `uvm_error("SINC_REGISTER", $sformatf("Register[%0s] with zero fields created", m_name))
    end
    foreach (m_fields[i]) begin
      m_fields[i].set_field_data(  (m_data >> m_fields[i].m_lsb) & ((1 << m_fields[i].m_size) - 1));
    end
  endfunction : unpack_data

  // Get addr
  virtual function sinc_reg_addr_t get_addr();
    return (m_addr);
  endfunction : get_addr

  // Set addr
  virtual function void set_addr(sinc_reg_addr_t addr);
    m_addr = addr;
  endfunction : set_addr

  // Get data
  virtual function sinc_reg_data_t get_data();
    pack_data();
    return (m_data);
  endfunction : get_data

  // Set data
  virtual function void set_data(sinc_reg_data_t data);
    m_data = data;
    unpack_data();
  endfunction : set_data

  // Clear "RC" register fields
  virtual function void set_rc();
    if (m_fields.size() == 0) begin
      `uvm_error("SINC_REGISTER", $sformatf("Register[%0s] with zero fields created", m_name))
    end

    foreach (m_fields[i]) begin
      m_fields[i].set_rc();
    end
    pack_data();
  endfunction : set_rc

  // default reset function
  virtual function void reset();
    if (m_fields.size() == 0) begin
      `uvm_error("SINC_REGISTER", $sformatf("Register[%0s] with zero fields created", m_name))
    end

    foreach (m_fields[i]) begin
      m_fields[i].reset();
    end
  endfunction : reset

  // pack data in function post_randomize
  function void post_randomize();
    super.post_randomize();
    pack_data();
  endfunction : post_randomize
endclass : sinc_register


function void sinc_register::pack_data();
  sinc_reg_data_t tmp_data;
  if (m_fields.size() == 0) begin
    `uvm_error("SINC_REGISTER", $sformatf("Register[%0s] with zero fields created", m_name))
  end
  foreach (m_fields[i]) begin
    sinc_register_field temp_field = m_fields[i];
    tmp_data |= temp_field.get_field_data() << temp_field.m_lsb;
  end
  m_data = tmp_data;
endfunction : pack_data


`endif // SINC_REGISTER
