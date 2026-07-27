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
// File        : aes_ref_rslt_utils.sv
// Description : This files contains a child implementation of the

`ifndef AES_REF_RSLT_UTILS
`define AES_REF_RSLT_UTILS

/**
 * @brief AES reference result utils helps with reference status and reference result calculations.
 *
 */
class aes_ref_rslt_utils;

  static byte_array_t                      m_kat_ref_rslt;
  static bit [`PAL_MAX_DATA_WIDTH - 1 : 0] m_expected_status = 0;

  static function void store_kat_ref_rslt_data(const ref byte_array_t ref_result);
    m_kat_ref_rslt = ref_result;
  endfunction : store_kat_ref_rslt_data

  /**
   * @brief When an error is injected, the static member - expected_status stores the expected status.
   *
   * This expected status is then compared in the predictor with the actual status read. If not error is expected, expect command completion.
   *
   * @param expect_cmd_err Expect current command to end with command error
   * @param expect_bus_err Expect current command to end with bus error
   * @param expect_fault_err Expect current command to end with fault error
   */
  extern static function void store_status_expectation(bit expect_cmd_err = 0, bit expect_bus_err = 0, bit expect_fault_err = 0);

  static function int check_error_expected();

    if ((m_expected_status[ERROR_CMD] || m_expected_status[ERROR_BUS] || m_expected_status[ERROR_FAULT])) begin
      return (1);
    end else begin
      return (0);
    end

  endfunction : check_error_expected

  static function int check_cmd_error_expected();
    return (m_expected_status[ERROR_CMD]);
  endfunction : check_cmd_error_expected

  static function int check_bus_error_expected();
    return (m_expected_status[ERROR_BUS]);
  endfunction : check_bus_error_expected

  static function int check_fault_error_expected();
    return (m_expected_status[ERROR_FAULT]);
  endfunction : check_fault_error_expected

  /**
   * @brief Compute expected results from the OpenSSL C reference model using DPI-C calls.
   *
   * If KAT results are available, compare them with them with the OpenSSL C reference model.
   */
  extern static function byte_array_t get_ref_rslt(
              aes_cmd_operation_e aes_op,
              aes_cmd_mode_e      aes_mode,
              aes_cmd_unit_sz_e   aes_unit_sz,
              aes_cmd_key_len_e   aes_key_len,
              int                 byte_count,
    const ref byte_array_t        message,
    const ref byte_array_t        key,
    const ref byte_array_t        iv
  );

endclass : aes_ref_rslt_utils

function void aes_ref_rslt_utils::store_status_expectation(bit expect_cmd_err = 0, bit expect_bus_err = 0, bit expect_fault_err = 0);
  m_expected_status[ERROR_CMD]   = expect_cmd_err;
  m_expected_status[ERROR_BUS]   = expect_bus_err;
  m_expected_status[ERROR_FAULT] = expect_fault_err;

  if (!(m_expected_status[ERROR_CMD] || m_expected_status[ERROR_BUS] || m_expected_status[ERROR_FAULT])) begin
    m_expected_status[COMPLETE] = 1;
  end else begin
    m_expected_status[COMPLETE] = 0;
  end

  `uvm_info("aes_ref_rslt_utils", $sformatf("Expected status set to = 'h%0h", m_expected_status ), UVM_DEBUG)
endfunction : store_status_expectation

function byte_array_t aes_ref_rslt_utils::get_ref_rslt(
              aes_cmd_operation_e aes_op,
              aes_cmd_mode_e      aes_mode,
              aes_cmd_unit_sz_e   aes_unit_sz,
              aes_cmd_key_len_e   aes_key_len,
              int                 byte_count,
    const ref byte_array_t        message,
    const ref byte_array_t        key,
    const ref byte_array_t        iv
  );
  byte_array_t result;

  `uvm_info("get_ref_rslt", $sformatf("Calling OpenSSL model: operation = %0s, aes_mode = %0s, message = %0s, key = %0s, key length = %0s \n", aes_op.name(), aes_mode.name(), convert_byte_array_to_string(message), convert_byte_array_to_string(key), aes_key_len.name() ), UVM_DEBUG)

  result = new[byte_count + 16];

  //DPI-C function call to the OpenSSL C reference model
  dpi_sv_aes_evp_ref_model(
    .msg_h            (message                          ),
    .ed_h             (aes_op                           ),
    .key_length_h     (BYTES_IN_KEY_LEN[aes_key_len] * 8),
    .key_h            (key                              ),
    .iv_h             (iv                               ),
    .mode_h           (aes_mode                         ),
    .unit_sz_h        (aes_unit_sz                      ),
    // .a_print_debug_msg(uvm_report_enabled(UVM_HIGH)),
    .a_print_debug_msg(1                                ),
    .ossl_rslt_h      (result                           )
  );

  //Compare KAT result with OpenSSL C reference model result.
  if (m_kat_ref_rslt.size() > 0) begin
    `uvm_info("get_ref_rslt", $sformatf("KAT result = %s", convert_byte_array_to_string(m_kat_ref_rslt)), UVM_DEBUG)

    foreach(m_kat_ref_rslt[i]) begin
      if (m_kat_ref_rslt[i] != result[i]) begin
        `uvm_error("get_ref_rslt", $sformatf("KAT data does not match OpenSSL. kat=%s openssl=%s", convert_byte_array_to_string(m_kat_ref_rslt), convert_byte_array_to_string(result)))
      end
    end
    m_kat_ref_rslt.delete();
  end

  return (result);
endfunction : get_ref_rslt

`endif // AES_REF_RSLT_UTILS
