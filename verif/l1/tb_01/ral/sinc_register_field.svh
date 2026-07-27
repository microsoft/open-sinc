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
// File        : sinc_register_field.svh
// Description : 

`ifndef SINC_REGISTER_FIELD
`define SINC_REGISTER_FIELD

// ---------------------------------------------- //
// class sinc_register_field
//
// Base class for register field
// ---------------------------------------------- //
class sinc_register_field extends uvm_object;

  rand sinc_reg_data_t m_data;
  int                  m_lsb;
  int                  m_size;
  sinc_reg_data_t      m_reset;
  string               m_name;
  string               m_access;
  string               m_lsb_str = "SINC_REGS_CMD_KEY_SLOT_LSB";

  `uvm_object_utils_begin(sinc_register_field)
    `uvm_field_int   (m_data,   UVM_DEFAULT | UVM_HEX)
    `uvm_field_int   (m_lsb,    UVM_DEFAULT          )
    `uvm_field_int   (m_size,   UVM_DEFAULT          )
    `uvm_field_string(m_name,   UVM_DEFAULT          )
    `uvm_field_string(m_access, UVM_DEFAULT          )
  `uvm_object_utils_end

  function new(string name = "");
    super.new(name);
    m_name = name;
  endfunction : new

  virtual function void pack_data();
  endfunction : pack_data

  virtual function void unpack_data();
  endfunction : unpack_data

  // Get data
  virtual function sinc_reg_data_t get_field_data();
    sinc_reg_data_t g_data;
    pack_data();

    g_data = (m_data >> m_lsb) & ((1 << m_size) - 1);

    `uvm_info(get_name(), $sformatf("Get register Field [%0s] value ['h%0h], m_lsb[%0d], m_size[%0d]",
        m_name, g_data, m_lsb, m_size), UVM_HIGH)
    return (g_data);
  endfunction : get_field_data

  // Set data
  virtual function void set_field_data(sinc_reg_data_t data);
    unpack_data();
    m_data = data << m_lsb;
    `uvm_info(get_name(), $sformatf("Set register Field [%0s] to ['h%0h], m_lsb[%0d], m_size[%0d]",
        m_name, m_data, m_lsb, m_size), UVM_HIGH)
  endfunction : set_field_data

  // Set RC register field
  virtual function void set_rc();
    if (m_access == "RC") begin
      m_data = 0;
      `uvm_info(get_name(), $sformatf("Set register RC Field [%0s] to ['h%0h]",
          m_name, m_data), UVM_HIGH)
    end
  endfunction : set_rc

  // default reset function
  virtual function void reset();
    m_data = m_reset;
    unpack_data();
  endfunction : reset

  // pack data in function post_randomize
  function void post_randomize();
    super.post_randomize();
    pack_data();
  endfunction : post_randomize
endclass : sinc_register_field

`endif // SINC_REGISTER_FIELD