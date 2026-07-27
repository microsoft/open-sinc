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
// File        : sinc_aes_packet.svh
// Description : This is AES packet used to randomize AES requests to SINC.

`ifndef SINC_AES_PACKET
`define SINC_AES_PACKET

//---------------------------------
// SINC AES Packet Class
//---------------------------------
class sinc_aes_packet extends uvm_sequence_item;

  rand int m_pre_delay;
  rand int m_post_delay;

  `uvm_object_utils(sinc_aes_packet)

  // indicate if this generated packet will be used on m_aes_test_mode
  bit      m_aes_test_mode  = 0;
  uint32_t m_block_encr_num = 0;

  // pack test information into aes_item
  sinc_aes_item m_aes_item;

  // AES Attributes will be randomized without constraints, will be parsed at post_random
  // ENCRYPT, DECRYPT
  rand aes_cmd_operation_e m_aes_op;

  // SInC support ECB and GCM mode. Other test mode result in Invalid Command Error
  rand aes_cmd_mode_e m_aes_mode;

  // input iv size
  rand aes_cmd_unit_sz_e m_aes_unit_sz;

  // KEY length
  rand aes_cmd_key_len_e m_aes_key_len;

  // output size in bytes
  rand uint32_t m_byte_count;

  // message for operation
  // the message can be 1. test_data_in registers in AES Test Mode, 2. Sharedram data to model encrypt block or DMB external data to model fetch block
  // in order to construct "byte m_message[]" in sinc_aes_item.
  // data is randomized for aes test mode, overwritten with actual axi data during cpu mem access or encrypt block
  // during encrypt this is the plaintext, during decrypt this is the ciphertext
  rand reg_data_t m_aes_message[];

  reg_data_t m_aes_result[]; // c model result, ciphertext if encrypt, plaintext if decrypt
  reg_data_t m_aes_tag[4];   // tag result

  // random KEY value, and key address
  rand bit        m_reuse_key;
  rand sinc_key_t m_key_data;
  rand int        m_key_slot;
  sinc_axi_addr_t m_key_axi_addr;
  sinc_key_t      m_reuse_key_data;

  // original KEY data (256 bits)
  sinc_key_t m_orig_key;

  // IV data register
  rand reg_data_t m_aes_iv_nonce_regs[3];
  reg_data_t      m_preset_aes_iv_nonce_regs[3];

  // result data calculated by AES C model
  byte m_ref_rslt_byte[];

  uvm_reg_data_t m_aes_test_data_out[4];

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_aes_packet" );
    super.new(name);
    // sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // post_randomize()
  //---------------------------------
  function void post_randomize ();
    `uvm_info(get_name(), $sformatf("post_randomize: debug"), UVM_HIGH)
    construct_aes_item ();
  endfunction : post_randomize

  //---------------------------------
  // check_result_data()
  //---------------------------------
  extern virtual function void check_result_data(int data_segment_num);

  //---------------------------------
  // check_tag_data()
  //---------------------------------
  extern virtual function void check_tag_data();

  //---------------------------------
  // construct_aes_item()
  //---------------------------------
  extern virtual function void construct_aes_item();

  //---------------------------------
  // cal_rslt_w_c_model()
  //---------------------------------
  extern virtual function void cal_rslt_w_c_model();

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet(int i = 0);

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint order_c;
  extern constraint aes_byte_count_c;
  extern constraint aes_op_c;
  extern constraint aes_mode_c;
  extern constraint aes_unit_sz_c;
  extern constraint aes_key_len_c;
  extern constraint aes_test_data_c;
  extern constraint aes_m_key_slot_c;
  extern constraint packet_pre_delay_c;
  extern constraint packet_post_delay_c;

endclass : sinc_aes_packet

constraint sinc_aes_packet::order_c {
  // solve m_aes_mode before m_byte_count;
}

constraint sinc_aes_packet::aes_byte_count_c{
  (m_byte_count % 16) == 0;
  m_byte_count != 0;
  m_byte_count <= 768;
}

constraint sinc_aes_packet::aes_op_c {
  m_aes_op inside {sinc_parameters_pkg::ENCRYPT,
    sinc_parameters_pkg::DECRYPT};
}

constraint sinc_aes_packet::aes_mode_c {
  m_aes_mode inside {sinc_parameters_pkg::ECB,
    sinc_parameters_pkg::GCM};
}

constraint sinc_aes_packet::aes_unit_sz_c {
  // technically other size should still work, but it is not SInC TB response to test it
  m_aes_unit_sz inside {sinc_parameters_pkg::BYTES_16};
}

constraint sinc_aes_packet::aes_key_len_c {
  m_aes_key_len inside {sinc_parameters_pkg::AES_256};
}

constraint sinc_aes_packet::aes_test_data_c {
  m_aes_message.size() == (m_byte_count / 4);
  solve m_byte_count before m_aes_message;
}

constraint sinc_aes_packet::aes_m_key_slot_c{
  m_key_slot >= 0;
  m_key_slot < `KSU_KEYS;
}

//---------------------------------
// Constraints for packet delay
//---------------------------------
constraint sinc_aes_packet::packet_pre_delay_c {
  // fixme-hw: introduce delay
  m_pre_delay == 0;
}

constraint sinc_aes_packet::packet_post_delay_c {
  // fixme-hw: introduce delay
  m_post_delay == 0;
}

function void sinc_aes_packet::check_result_data(int data_segment_num);
  //check data
  for (int word_index = 0; word_index < 4; word_index++) begin
    if(m_aes_result[word_index + (data_segment_num * 4)] !== m_aes_test_data_out[word_index]) begin
      `uvm_error(get_name(), $sformatf("check_result_data: aes_op: [%0s] Expect Result Word %0d ['h%0h], Actual ['h%0h]", m_aes_op.name(), word_index, m_aes_result[word_index+data_segment_num*4], m_aes_test_data_out[word_index]))
    end else begin
      `uvm_info(get_name(), $sformatf("check_result_data: aes_op: [%0s] Actual Result Word %0d ['h%0h] matched Expected ['h%0h]", m_aes_op.name(), word_index, m_aes_test_data_out[word_index], m_aes_result[word_index+data_segment_num*4]), UVM_DEBUG)
    end
  end

endfunction : check_result_data

function void sinc_aes_packet::check_tag_data();
  foreach (m_aes_tag[i]) begin
    `uvm_info (get_name(), $sformatf("cmodel result: 'h%0h", m_aes_tag[i]), UVM_DEBUG)
  end

  //check tag
  for (int word_index = 0; word_index < 4; word_index++) begin
    if(m_aes_tag[word_index] !== m_aes_test_data_out[word_index]) begin
      `uvm_error(get_name(), $sformatf("check_tag_data: Expect Tag Word %0d ['h%0h], Actual ['h%0h]", word_index, m_aes_tag[word_index], m_aes_test_data_out[word_index]))
    end else begin
      `uvm_info(get_name(), $sformatf("check_tag_data: Actual Tag Word %0d ['h%0h] matched Expected ['h%0h]", word_index, m_aes_test_data_out[word_index], m_aes_tag[word_index]), UVM_DEBUG)
    end
  end

endfunction : check_tag_data

function void sinc_aes_packet::construct_aes_item();
  byte          little_endian_data[];
  byte          orig_data[];
  int           num_bytes;
  byte          key[];
  byte          iv[];
  logic [127:0] temp_iv;

  if (m_aes_item == null) begin
    m_aes_item = sinc_aes_item::type_id::create("m_aes_item", , get_full_name());
  end

  `uvm_info(get_name(), $sformatf("post_randomize: debug"), UVM_HIGH)
  m_aes_item.m_aes_op      = m_aes_op;
  m_aes_item.m_aes_mode    = m_aes_mode;
  m_aes_item.m_aes_unit_sz = m_aes_unit_sz;
  m_aes_item.m_aes_key_len = m_aes_key_len;
  m_aes_item.m_byte_count  = m_byte_count;

  // construct message
  // message needs to be set before call this function
  if (m_aes_message.size() == 0) begin
    `uvm_error(get_name(), $sformatf("construct_sinc_aes_item called before set mdssage, size[%0d]", m_aes_message.size()))
  end

  // construct m_meesage for AES C model
  m_aes_item.m_message = new[m_byte_count];
  for (int word_index = 0; word_index < (m_byte_count / 4); word_index++) begin
    m_aes_item.m_message[(word_index * 4)]     = m_aes_message[word_index][0 +: 8];
    m_aes_item.m_message[(word_index * 4) + 1] = m_aes_message[word_index][8 +: 8];
    m_aes_item.m_message[(word_index * 4) + 2] = m_aes_message[word_index][16 +: 8];
    m_aes_item.m_message[(word_index * 4) + 3] = m_aes_message[word_index][24 +: 8];
  end

  foreach (m_aes_item.m_message[i]) begin
    `uvm_info (get_name(), $sformatf("message (aes_test_data_in_*) in little endian [%0d]: 'h%0h", i, m_aes_item.m_message[i]), UVM_DEBUG)
  end

  // construct 256 bits of key data
  orig_data          = {};
  little_endian_data = {};
  num_bytes          = 32;

  if((m_reuse_key == 0) || (m_aes_test_mode == 0)) begin
    for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
      key = {key, m_key_data[8*byte_index +: 8]};
      `uvm_info (get_name(), $sformatf("key[%0d]: 'h%0h, temp['h%0h]", byte_index, key[byte_index], m_key_data[8*byte_index +: 8]), UVM_DEBUG)
    end
  end else begin
    for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
      key = {key, m_reuse_key_data[8*byte_index +: 8]};
      `uvm_info (get_name(), $sformatf("key[%0d]: 'h%0h, temp['h%0h]", byte_index, key[byte_index], m_reuse_key_data[8*byte_index +: 8]), UVM_DEBUG)
    end
  end

  for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
    orig_data = {orig_data, key[byte_index]};
  end

  for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
    little_endian_data = {little_endian_data, orig_data[byte_index]};
  end
  m_aes_item.m_key = little_endian_data;

  // set key start address with key_slot
  m_key_axi_addr = `KSU_KEY_SLOT_BASE_ADDR + ('h80 * m_key_slot);

  // construct IV
  if(m_aes_test_mode) begin
    temp_iv[31:0]   = m_aes_iv_nonce_regs[0];
    temp_iv[63:32]  = m_aes_iv_nonce_regs[1];
    temp_iv[95:64]  = m_aes_iv_nonce_regs[2];
    temp_iv[127:96] = 32'h100_0000;
  end else begin
    temp_iv[23:0]   = m_block_encr_num[23:0];
    temp_iv[31:24]  = m_aes_iv_nonce_regs[0][7:0];
    temp_iv[65:32]  = m_aes_iv_nonce_regs[0][31:8];
    temp_iv[63:56]  = m_aes_iv_nonce_regs[1][7:0];
    temp_iv[87:64]  = m_aes_iv_nonce_regs[1][31:8];
    temp_iv[95:88]  = m_aes_iv_nonce_regs[2][7:0];
    temp_iv[127:96] = 32'h100_0000;
  end

  orig_data          = {};
  little_endian_data = {};
  num_bytes          = 16;

  for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
    iv = {iv, temp_iv[8*byte_index +: 8]};
  end
  for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
    orig_data = {orig_data, iv[byte_index]};
  end

  for (int byte_index = 0; byte_index < num_bytes; byte_index++) begin
    little_endian_data = {little_endian_data, orig_data[byte_index]};
  end

  m_aes_item.m_iv = little_endian_data;

endfunction : construct_aes_item

function void sinc_aes_packet::cal_rslt_w_c_model();
  `uvm_info (get_name(), $sformatf("Calculate result base on sinc_aes_item and AES C model, MODE[%0s], OP[%0s]",
      m_aes_item.m_aes_mode, m_aes_item.m_aes_op), UVM_HIGH)

  m_ref_rslt_byte = aes_utils_pkg::aes_ref_rslt_utils::get_ref_rslt(
    .aes_op     (m_aes_item.m_aes_op     ),
    .aes_mode   (m_aes_item.m_aes_mode   ),
    .aes_unit_sz(m_aes_item.m_aes_unit_sz),
    .aes_key_len(m_aes_item.m_aes_key_len),
    .byte_count (m_aes_item.m_byte_count ),
    .message    (m_aes_item.m_message    ),
    .key        (m_aes_item.m_key        ),
    .iv         (m_aes_item.m_iv         )
  );

  //the -4 is because get_ref_rslt always includes space for the tag in m_ref_rslt_byte
  m_aes_result = new[(m_ref_rslt_byte.size() / 4) - 4];

  if(m_aes_op == sinc_parameters_pkg::ENCRYPT) begin

    for (int word_index = 0; word_index < ((m_ref_rslt_byte.size() / 4) - 4); word_index++) begin
      m_aes_result[word_index] = {m_ref_rslt_byte[(word_index * 4) + 3], m_ref_rslt_byte[(word_index * 4) + 2], m_ref_rslt_byte[(word_index * 4) + 1], m_ref_rslt_byte[(word_index * 4)]};
    end

    for (int word_index = 0; word_index < 4; word_index++) begin
      m_aes_tag[word_index] = {m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 3], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 2], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 1], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count]};
    end

    foreach (m_aes_result[i]) begin
      `uvm_info (get_name(), $sformatf("cmodel cipher result: 'h%0h", m_aes_result[i]), UVM_DEBUG)
    end

    foreach (m_aes_tag[i]) begin
      `uvm_info (get_name(), $sformatf("cmodel tag result: 'h%0h", m_aes_tag[i]), UVM_DEBUG)
    end
  end else begin

    for (int word_index = 0; word_index < (m_ref_rslt_byte.size() / 4); word_index++) begin
      m_aes_result[word_index] = {m_ref_rslt_byte[(word_index * 4) + 3], m_ref_rslt_byte[(word_index * 4) + 2], m_ref_rslt_byte[(word_index * 4) + 1], m_ref_rslt_byte[(word_index * 4)]};
    end

    //on decrypt case need to encrypt result of decrypt to get tag
    foreach (m_aes_item.m_message[i]) begin
      m_aes_item.m_message[i] = m_ref_rslt_byte[i];
    end

    m_ref_rslt_byte = aes_utils_pkg::aes_ref_rslt_utils::get_ref_rslt(
      .aes_op     (sinc_parameters_pkg::ENCRYPT),
      .aes_mode   (m_aes_item.m_aes_mode       ),
      .aes_unit_sz(m_aes_item.m_aes_unit_sz    ),
      .aes_key_len(m_aes_item.m_aes_key_len    ),
      .byte_count (m_aes_item.m_byte_count     ),
      .message    (m_aes_item.m_message        ),
      .key        (m_aes_item.m_key            ),
      .iv         (m_aes_item.m_iv             )
    );

    for (int word_index = 0; word_index < 4; word_index++) begin
      m_aes_tag[word_index] = {m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 3], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 2], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count + 1], m_ref_rslt_byte[(word_index * 4) + m_aes_item.m_byte_count]};
    end

    foreach (m_aes_result[i]) begin
      `uvm_info (get_name(), $sformatf("cmodel plaintext result: 'h%0h", m_aes_result[i]), UVM_HIGH)
    end

    foreach (m_aes_tag[i]) begin
      `uvm_info (get_name(), $sformatf("cmodel tag result: 'h%0h", m_aes_tag[i]), UVM_HIGH)
    end
  end

endfunction : cal_rslt_w_c_model

function void sinc_aes_packet::print_packet(int i = 0);
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" AES Packet\n")};
  str = {str, $sformatf(" m_aes_test_mode:  ['h%0h]\n", m_aes_test_mode)};
  str = {str, $sformatf(" byte_cnt : [%0d]\n", m_byte_count)};
  str = {str, $sformatf(" aes_op: [%0s]\n", m_aes_op.name())};
  str = {str, $sformatf(" aes_mode: [%0s]\n", m_aes_mode.name())};
  str = {str, $sformatf(" aes_unit_sz: [%0s]\n", m_aes_unit_sz.name())};
  str = {str, $sformatf(" aes_key_len: [%0s]\n", m_aes_key_len.name())};
  str = {str, $sformatf(" byte_count: [%0d]\n", m_byte_count)};
  for (int i=0; i < m_aes_message.size(); i++) begin
    str = {str, $sformatf(" m_aes_message[%0d]: ['h%0h]\n", i, m_aes_message[i])};
  end
  str = {str, $sformatf(" key_data: ['h%0h]\n", m_key_data)};
  str = {str, $sformatf(" key_slot: [%0d]\n", m_key_slot)};
  str = {str, $sformatf(" key_axi_addr:  ['h%0h]\n", m_key_axi_addr)};
  str = {str, $sformatf(" orig_key:    ['h%0h]\n", m_orig_key)};
  for (int i=0; i < 3; i++) begin
    str = {str, $sformatf(" aes_iv_nonce_[%0d]: ['h%0h]\n", i, m_aes_iv_nonce_regs[i])};
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_AES_PACKET", str, UVM_HIGH)

  m_aes_item.print_item();

endfunction : print_packet

`endif // SINC_AES_PACKET
