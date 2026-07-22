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
// File        : sinc_aes_item.svh
// Description : This is AES packet used to randomize AES requests to SINC.

`ifndef SINC_AES_ITEM
`define SINC_AES_ITEM

//-----------------------------------------------------------------------
// SINC AES item, used by aes_utils_pkg::aes_ref_rslt_utils::get_ref_rslt
//-----------------------------------------------------------------------
class sinc_aes_item extends uvm_sequence_item;

  `uvm_object_utils(sinc_aes_item)

  // ENCRYPT, DECRYPT
  aes_cmd_operation_e m_aes_op;

  // SInC support ECB and GCM mode. Other test mode result in Invalid Command Error
  aes_cmd_mode_e m_aes_mode;

  // input iv size
  aes_cmd_unit_sz_e m_aes_unit_sz;

  // KEY length
  aes_cmd_key_len_e m_aes_key_len;

  // output size in bytes
  uint32_t m_byte_count;

  // message for operation
  byte m_message[];

  // KEY data
  byte m_key[];

  // IV data
  byte m_iv[];

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_aes_item" );
    super.new(name);
  endfunction :new

  extern virtual function void print_item ();

endclass : sinc_aes_item


function void sinc_aes_item::print_item ();
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" AES Item for aes_ref_rslt_utils::get_ref_rslt \n")};
  str = {str, $sformatf(" AES OP : [%0s]\n", m_aes_op.name())};
  str = {str, $sformatf(" AES MODE : [%0s]\n", m_aes_mode.name())};
  str = {str, $sformatf(" AES UNIT SIZE : [%0s]\n", m_aes_unit_sz.name())};
  str = {str, $sformatf(" AES Key length : [%0s]\n", m_aes_key_len.name())};
  str = {str, $sformatf(" AES byte count : [%0d]\n", m_byte_count)};
  str = {str, $sformatf(" AES message in bytes : \n")};
  for (int i=0; i < m_message.size(); i++) begin
    str = {str, $sformatf(" message[%0d] : 'h%0h,", i, m_message[i])};
  end
  str = {str, "\n"};
  str = {str, $sformatf(" AES key in bytes : \n")};
  for (int i=0; i < m_key.size(); i++) begin
    str = {str, $sformatf(" key[%0d] : 'h%0h,", i, m_key[i])};
  end
  str = {str, "\n"};
  str = {str, $sformatf(" AES iv in bytes : \n")};
  for (int i=0; i < m_iv.size(); i++) begin
    str = {str, $sformatf(" iv[%0d] : 'h%0h,", i, m_iv[i])};
  end
  str = {str, "\n"};

  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_AES_ITEM", str, UVM_HIGH)

endfunction :print_item

`endif //SINC_AES_ITEM