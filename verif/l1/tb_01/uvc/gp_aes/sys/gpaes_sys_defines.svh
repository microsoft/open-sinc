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
// File        : gpaes_sys_defines.svh
// Description : Protocol Abstraction Layer Defines

`ifndef GPAES_SYS_DEFINES__SV
`define GPAES_SYS_DEFINES__SV

//GPAES_SYS Version: 1.0.0
`define GPAES_SYS_VERSION "1.0.0"

`ifndef GPAES_IF_OUTPUT_DLY
`define GPAES_IF_OUTPUT_DLY 100ps
`endif

typedef logic [31:0] uint32_t;

  typedef struct packed unsigned{
    uint32_t command_code;
    uint32_t result_ptr;
    uint32_t byte_count;
    uint32_t message_ptr;
    uint32_t key_ptr;
    uint32_t init_vector_ptr;
  } cmd_struct_s;

  typedef enum bit {
    DECRYPT = 0,
    ENCRYPT = 1
  } aes_cmd_operation_e;

  typedef enum bit [3:0] {
    AES_128 = 4'h1,
    AES_192 = 4'h2,
    AES_256 = 4'h3
  } aes_cmd_key_len_e;

  typedef enum{
    ANY,
    CMD_STRUCT_READ,
    RNG_READ,
    IV_READ,
    MSG_READ,
    KEY_READ,
    RESULT_WRITE,
    IV_WRITE
  } aes_axi_mst_trans_type_e;

  typedef enum {
    AES_CMD_DECODER,
    AES_MODE,
    AES_KEYEXP
  } aes_module_e;

  typedef int hash_by_key_len_t[aes_cmd_key_len_e];

  const static hash_by_key_len_t BYTES_IN_KEY_LEN = '{
    AES_128: (128 / 8),
    AES_192: (192 / 8),
    AES_256: (256 / 8)
  };

  typedef enum bit [3:0] {
    ECB = 4'h1,
    CBC = 4'h2,
    CTR = 4'h3,
    CFB = 4'h4,
    OFB = 4'h5,
    XTS = 4'h6,
    GCM = 4'h7
  } aes_cmd_mode_e;

  typedef enum bit [3:0] {
    BYTES_16   = 4'h1,
    BYTES_512  = 4'h2,
    BYTES_1024 = 4'h3,
    BYTES_2048 = 4'h4,
    BYTES_4096 = 4'h5
  } aes_cmd_unit_sz_e;

  typedef int hash_by_unit_sz_t[aes_cmd_unit_sz_e];

  const static hash_by_unit_sz_t BYTES_IN_UNIT = '{
    BYTES_16 : 16,
    BYTES_512 : 512,
    BYTES_1024 : 1024,
    BYTES_2048 : 2048,
    BYTES_4096 : 4096
  };

  typedef enum {
    BUSY = 0,
    COMPLETE,
    ERROR_CMD,
    ERROR_BUS,
    ERROR_FAULT,
    NOT_OWNER
  } aes_status_bit_e;


`endif //GPAES_SYS_DEFINES__SV

