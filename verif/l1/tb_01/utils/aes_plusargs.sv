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
// File        : aes_plusargs.sv
// Description : This files contains a child implementation of the

`ifndef AES_PLUSARGS
`define AES_PLUSARGS

/**
 * @class AES plusargs which processes the inputs from the test YML
 *
 */
class aes_plusargs extends plusargs::object;

  /**
   * AES Comand Plusargs
   */
  class aes_command extends plusargs::object;

    pal_addr_t m_cmd_struct_addr;

    uint32_t            m_command_code;
    aes_cmd_mode_e      m_aes_mode;
    aes_cmd_operation_e m_aes_op;
    bit                 m_wiv;
    aes_cmd_unit_sz_e   m_aes_unit_sz;
    aes_cmd_key_len_e   m_aes_key_len;

    pal_addr_t m_result_addr;

    uint32_t m_byte_count;

    byte       m_message[];
    pal_addr_t m_message_addr;

    byte       m_key[];
    pal_addr_t m_key_addr;

    byte       m_iv[];
    pal_addr_t m_iv_addr;

    byte m_ref_rslt[];

    int    m_iterations;
    string m_kat_file_name;

    //!Error related plusargs
    int                      m_bus_err_weight;
    pal_slv_err_t            m_bus_err_type;
    aes_axi_mst_trans_type_e m_bus_err_target;

    int m_cmd_err_weight;
    int m_fault_err_weight;
    int m_reg_parity_err_weight;
    int m_no_err_weight;

    //Enable cross of reset and a state in a specific module
    aes_module_e m_reset_x_module;

    /// @cond
    `uvm_object_utils_begin( aes_command )
      `uvm_field_int      (m_cmd_struct_addr,                         UVM_DEFAULT | UVM_HEX)
      `uvm_field_int      (m_command_code,                            UVM_DEFAULT | UVM_HEX)
      `uvm_field_enum     (aes_cmd_mode_e,          m_aes_mode,       UVM_DEFAULT          )
      `uvm_field_enum     (aes_cmd_operation_e,     m_aes_op,         UVM_DEFAULT          )
      `uvm_field_int      (m_wiv,                                     UVM_DEFAULT | UVM_BIN)
      `uvm_field_enum     (aes_cmd_unit_sz_e,       m_aes_unit_sz,    UVM_DEFAULT          )
      `uvm_field_enum     (aes_cmd_key_len_e,       m_aes_key_len,    UVM_DEFAULT          )
      `uvm_field_int      (m_result_addr,                             UVM_DEFAULT | UVM_HEX)
      `uvm_field_int      (m_byte_count,                              UVM_DEFAULT | UVM_DEC)
      `uvm_field_array_int(m_message,                                 UVM_DEFAULT          )
      `uvm_field_int      (m_message_addr,                            UVM_DEFAULT | UVM_HEX)
      `uvm_field_array_int(m_key,                                     UVM_DEFAULT          )
      `uvm_field_int      (m_key_addr,                                UVM_DEFAULT | UVM_HEX)
      `uvm_field_array_int(m_iv,                                      UVM_DEFAULT          )
      `uvm_field_int      (m_iv_addr,                                 UVM_DEFAULT | UVM_HEX)
      `uvm_field_array_int(m_ref_rslt,                                UVM_DEFAULT          )
      `uvm_field_int      (m_bus_err_weight,                          UVM_DEFAULT | UVM_BIN)
      `uvm_field_enum     (pal_slv_err_t,           m_bus_err_type,   UVM_DEFAULT          )
      `uvm_field_int      (m_cmd_err_weight,                          UVM_DEFAULT | UVM_BIN)
      `uvm_field_int      (m_fault_err_weight,                        UVM_DEFAULT | UVM_BIN)
      `uvm_field_int      (m_reg_parity_err_weight,                   UVM_DEFAULT | UVM_BIN)
      `uvm_field_int      (m_no_err_weight,                           UVM_DEFAULT | UVM_BIN)
      `uvm_field_int      (m_iterations,                              UVM_DEFAULT | UVM_DEC)
      `uvm_field_string   (m_kat_file_name,                             UVM_DEFAULT          )
      `uvm_field_enum     (aes_module_e,            m_reset_x_module, UVM_DEFAULT          )
    `uvm_object_utils_end
    /// @endcond

    function new(string name="aes_command");
      super.new(name);
    endfunction : new

    extern virtual function void validate();

    extern virtual function void parse();

    extern virtual function shortint get_aes_unit_size(aes_cmd_unit_sz_e unit_sz);

  endclass : aes_command

function void aes_command::validate();
    bit has_member[$];

    super.validate();

    if (has("AES_CMD_WIV") && !(m_wiv inside {0, 1})) begin
      plusargs::error(get_type_name(), "aes.yml: AES_CMD_WIV needs to be equal to 0/1");
    end

    if ( has("AES_CMD_STRUCT_PTR") && ((m_cmd_struct_addr % (`PAL_MAX_DATA_WIDTH / 8)) != 0) && (m_cmd_err_weight == 0) ) begin
      plusargs::error(get_type_name(), "aes.yml: AES_CMD_STRUCT_PTR not aligned to data bus");
    end
    if (has("AES_INITIAL_VECTOR") && (m_iv.size() != 16)) begin
      plusargs::error(get_type_name(), "aes.yml: AES_INITIAL_VECTOR size not equal to `TB_AES_BLK_SIZE");
    end
    if (has("AES_MESSAGE") && has("AES_BYTE_COUNT") && (m_message.size() !== m_byte_count)) begin
      plusargs::error(get_type_name(), "aes.yml: AES_MESSAGE size should be equal to AES_BYTE_COUNT");
    end

    if (has("AES_CMD_MODE") && has("AES_CMD_KEY_LEN") && (m_cmd_err_weight == 0)) begin
      if ((m_aes_mode == XTS) && (m_aes_key_len != AES_128) ) begin
        plusargs::error(get_type_name(), "aes.yml: AES_CMD_MODE = XTS -> AES_CMD_KEY_LEN = AES_128");
      end
    end

    if (has("AES_CMD_MODE") && has("AES_CMD_UNIT_SIZE") && has("AES_BYTE_COUNT") && (m_cmd_err_weight == 0)) begin
      if ((m_aes_mode == XTS) && ((m_byte_count % get_aes_unit_size(m_aes_unit_sz)) != 0)) begin
        plusargs::error(get_type_name(), "aes.yml: AES_CMD_MODE = XTS -> AES_BYTE_COUNT % AES_CMD_UNIT_SIZE == 0");
      end
    end

    if (has("AES_CMD_CODE") && (has("AES_CMD_MODE") || has("AES_CMD_OPERATION") || has("AES_CMD_UNIT_SIZE") || has("AES_CMD_KEY_LEN") || has("AES_CMD_WIV"))) begin
      plusargs::error(get_type_name(), "aes.yml: AES_CMD_MODE cannot be provided with an input of its fields");
    end

    has_member = m_has.find_first() with ( item == 1 );
    if (has("KAT_TEST_VECTOR_FILE")) begin
      if (has_member.size() > 2) begin
        plusargs::error(get_type_name(), "aes.yml: Only KAT_TEST_VECTOR_FILE and ITERATIONS are allowed for KAT tests");
      end else if ((has_member.size() == 2) && !has("ITERATIONS")) begin
        plusargs::error(get_type_name(), "aes.yml: Only KAT_TEST_VECTOR_FILE and ITERATIONS are allowed for KAT tests");
      end
    end

    //The address_c constraints in aes_cmd_item will fail if the addresses input are out of bounds or possess overlap

  endfunction : validate

function void aes_command::parse();
    super.parse();

    m_iterations = get_int("ITERATIONS", .default_value(1));

    m_cmd_struct_addr = {>> {get_byte_array("AES_CMD_STRUCT_PTR")}};

    m_iv_addr = {>> {get_byte_array("AES_INITIAL_VECTOR_PTR")}};

    m_iv = get_byte_array("AES_INITIAL_VECTOR");

    m_message_addr = {>> {get_byte_array("AES_MESSAGE_PTR")}};

    m_message = get_byte_array("AES_MESSAGE");

    m_key_addr = {>> {get_byte_array("AES_KEY_PTR")}};

    m_key = get_byte_array("AES_KEY");

    m_result_addr = {>> {get_byte_array("AES_RESULT_PTR")}};

    m_ref_rslt = {>> {get_byte_array("AES_REF_RESULT")}};

    m_byte_count = get_int("AES_BYTE_COUNT");

    m_command_code = {>> {get_byte_array("AES_CMD_CODE")}};

    m_aes_mode    = plusargs::enumeration::parser#(aes_cmd_mode_e)::get("AES_CMD_MODE", this);
    m_aes_op      = plusargs::enumeration::parser#(aes_cmd_operation_e)::get("AES_CMD_OPERATION", this);
    m_aes_unit_sz = plusargs::enumeration::parser#(aes_cmd_unit_sz_e)::get("AES_CMD_UNIT_SIZE", this);
    m_aes_key_len = plusargs::enumeration::parser#(aes_cmd_key_len_e)::get("AES_CMD_KEY_LEN", this);
    m_wiv         = get_int("AES_CMD_WIV");

    m_kat_file_name = get_string("AES_KAT_TEST_VECTOR_FILE");

    m_cmd_err_weight = get_int("AES_CMD_ERR_WEIGHT");

    m_bus_err_weight = get_int("AES_BUS_ERR_WEIGHT");
    m_bus_err_type   = plusargs::enumeration::parser#(pal_slv_err_t)::get("AES_BUS_ERR_TYPE", this);
    m_bus_err_target = plusargs::enumeration::parser#(aes_axi_mst_trans_type_e)::get("AES_BUS_ERR_TARGET", this);

    m_fault_err_weight = get_int("AES_FAULT_ERR_WEIGHT");

    m_reg_parity_err_weight = get_int("AES_REG_PARITY_ERR_WEIGHT");

    m_no_err_weight = get_int("AES_NO_ERR_WEIGHT");

    m_reset_x_module = plusargs::enumeration::parser#(aes_module_e)::get("AES_RESET_MODULE", this);

  endfunction : parse

function shortint aes_command::get_aes_unit_size(aes_cmd_unit_sz_e unit_sz);
    case(unit_sz)
      BYTES_16: return (16);
      BYTES_512: return (512);
      BYTES_1024: return (1024);
      BYTES_2048: return (2048);
      BYTES_4096: return (4096);
      default: return (-1);
    endcase

  endfunction : get_aes_unit_size

  aes_command m_aes_commands[$];
  string      m_kat_directory;

  `uvm_object_utils_begin(aes_plusargs)
    `uvm_field_queue_object(m_aes_commands, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="aes_plusargs");
    super.new(name);
  endfunction : new

  virtual function void parse();
    super.parse();
    m_kat_directory  = get_string("KAT_DIRECTORY");
    m_aes_commands = plusargs::array::parser#(aes_command)::get("AES_COMMANDS", this);
  endfunction : parse

  virtual function void validate();
    super.validate();
  endfunction : validate

endclass : aes_plusargs

`endif // AES_PLUSARGS
