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
// File        : gpaes_packet_config.svh
// Description : Protocol Abstraction Layer Packettem Configuration

`ifndef GPAES_PACKET_CONFIG__SV
`define GPAES_PACKET_CONFIG__SV

class gpaes_packet_config extends uvm_transaction;

  //Register with factory
  `uvm_object_utils(gpaes_packet_config)

  // Set when current GPAES request packet is active, automatic set 1 when a AES request sequence item is sent to AES command driver, set 0 when the AES request is done.
  // When active is set, the reactive components response with preset input to GPAES module
  // When active is not set, the reactive components response with random input to GPAES module
  bit           m_is_gpaes_req_packet_active = 0;

  // wrapper config pass by
  int           packet_wrapper_id = 0;

  // GPAES parameter config per packet
  // ENCRYPT, DECRYPT
  gpaes_cmd_operation_e m_aes_op;

  // SInC support ECB and GCM mode. Other test mode result in Invalid Command Error
  gpaes_cmd_mode_e m_aes_mode;

  // input iv size
  gpaes_cmd_unit_sz_e m_aes_unit_sz;

  // KEY length
  gpaes_cmd_key_len_e m_aes_key_len;

  // output size in bytes
  uint32_t m_byte_count;

  // message for operation
  byte m_message[];

  // KEY data
  byte m_key[];

  // IV data
  byte m_iv[];
    
  // seed;
  max_seed_data_t seed[];


  extern function new(string name = "gpaes_packet_cfg");
  extern function string convert2string();

endclass : gpaes_packet_config

function gpaes_packet_config::new(string name = "gpaes_packet_cfg");
  super.new(name);
endfunction : new

function string gpaes_packet_config::convert2string();
  string printStr = "";
  printStr = $sformatf("%sGPAES_PACKET_WRAPPER_ID         = %d\n", printStr, packet_wrapper_id);
  
  // Seed agent
  printStr = $sformatf("%s-------------------------------------------------------------------------------------------\n", printStr);
  printStr = $sformatf("%s Seed Packet Config: \n", printStr);
    
  printStr = $sformatf("%s m_aes_op        = %0s\n", printStr, m_aes_op.name());
  printStr = $sformatf("%s-------------------------------------------------------------------------------------------\n", printStr);

  return printStr;
endfunction : convert2string

`endif //GPAES_PACKET_CONFIG__SV

