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
// File        : sinc_env_typedefs.svh
// Description : 

`ifndef SINC_ENV_TYPEDEFS__SVH
`define SINC_ENV_TYPEDEFS__SVH

// Enum: sinc_cache_state_type_e
// Enumeration of SInC CMU's cache state
// used for scoreboard to log the system status about cache state, used by sb_cov
// typedef enum {CACHE_DISABLE_STATE, CACHE_INIT_STATE, CACHE_ACTIVE_STATE, CACHE_FAIL_STATE}  sinc_cache_state_type_e;

// SINC MEM Type
typedef enum bit [1:0] {
  SINC_CACHE_MEM,
  SINC_CACHE_VTAG,
  SINC_EXTERNAL_MEM
} sinc_mem_type_e;

// HSP Master type accessing SINC AXI SUB
typedef enum bit [3:0] {
  SINC_AXI_MID_SP    = 0,
  SINC_AXI_MID_SINC  = 1,
  SINC_AXI_MID_OTHER = 2
} sinc_axi_mid_e;

// Enum for sinc_done_o
typedef enum {SINC_DONE_LOW = 0,
  SINC_DONE_POSEDGE         = 1} sinc_done_e;

parameter SP_MST_ID   = 1;
parameter SINC_MST_ID = 4;

//=============================================================================
// SINC components enumeration
//
// ex)  SP Processor
//      SINC, Representing SINC itself
//      MPU, MPU in SINC
//      CACHE, Cache Memory in SINC
//      VTAG, Cache VTAG in SINC
//      KSU, KSU in SINC DUT
//      RNG, RNG in SINC DUT
//      SHAREDRAM, SHAREDRAM in SINC DUT
//      DMB, DMB in SINC DUT
//      REG, Register in SINC
//      NULL, Represent a null access to SINC
//=============================================================================
typedef enum { SINC_SP=0, SINC_SINC, SINC_MPU, SINC_CACHE, SINC_VTAG, SINC_KSU, SINC_RNG, SINC_SHAREDRAM,
  SINC_DMB, SINC_REG, SINC_NULL} sinc_comp_e;

typedef sinc_comp_e sinc_comp_list_t[$];

// Enum: sinc_mstr_type_e
// Enumeration of initiator type that can access SINC
typedef enum {SINC_MSTR_SP, SINC_MSTR_NULL} sinc_mstr_type_e;

// Enum: sinc_mstr_type_e
// Enumeration of SINC subodinate types SINC can access
typedef enum {SINC_SLV_KSU, SINC_SLV_RNG, SINC_SLV_SHAREDRAM, SINC_SLV_DMB, SINC_SLV_NULL} sinc_slave_type_e;

typedef enum {SINC_CPU_WRITE, SINC_CPU_READ, SINC_AXI_WRITE, SINC_AXI_READ, SINC_MPU_WRITE, SINC_MPU_READ, SINC_CMD_UNKNOWN} sinc_cmd_e;

typedef enum {SINC_CPU_WRITE_TRN, SINC_CPU_READ_TRN} sinc_cpu_cmd_e;

typedef enum {SINC_MPU_ATTR_WRITE, SINC_MPU_ATTR_READ, SINC_MPU_STATUS_WRITE, SINC_MPU_STATUS_READ} sinc_mpu_cmd_e;

typedef enum {SINC_AXI_SUB_WRITE, SINC_AXI_SUB_READ} sinc_axi_cmd_e;

typedef sinc_cpu_cmd_e sinc_cpu_cmd_list_t[$];
typedef sinc_axi_cmd_e sinc_axi_cmd_list_t[$];
typedef sinc_cmd_e req_cmd_list_t[$];
typedef sinc_fw_cmd_e sinc_fw_cmd_list_t[$];

// Enum: sinc_random_data_type_e
typedef enum {SINC_RANDOM_RAND,
  SINC_RANDOM_ZERO,
  SINC_RANDOM_ONE} sinc_random_data_type_e;

typedef enum {SINC_AES_TEST_MODE_RANDOM = 0,
  SINC_AES_TEST_MODE_DIRECTED           = 1
} sinc_aes_test_mode_random_type_e;

// Enum: sinc_erase_e
// Enumeration of SINC side band 'erase_enable_sinc and erase_done_sinc' status
//
// SINC_ERASE_ENABLE - Enable for RAM erase is asserted
// SINC_ERASE_DONE - Erase is done
typedef enum {SINC_ERASE_INACTIVE,
  SINC_ERASE_ENABLE,
  SINC_ERASE_DONE} sinc_erase_e;

// Enum: address_type_e
// Enumeration of SINC regions that can be accessed by interfaces
typedef enum {
  ADDR_MPU       = 0, //  MPU
  ADDR_CACHE     = 1, //  Cache
  ADDR_KSU       = 2, //  KSU
  ADDR_RNG       = 3, //  RNG
  ADDR_SHAREDRAM = 4, //  SHAREDRAM
  ADDR_DMB       = 5, //  DMB
  ADDR_NULL      = 6 //  NULL
} sinc_address_type_e;

// Enum: sinc_sb_pkt_entry_e
// Enumeration of SINC scoreboard packet's entries.
typedef enum {
  ENTRY_CREG_ERASE             = 0, // CREG_ERASE
  ENTRY_CPU_READ               = 1, // CPU_READ       : SP to cache
  ENTRY_CPU_WRITE              = 2, // CPU_WRITE      : SP to cache
  ENTRY_AXI_SUB_READ           = 3, // AXI_SUB_READ   : SP to register
  ENTRY_AXI_SUB_WRITE          = 4, // AXI_SUB_WRITE  : SP to register
  ENTRY_AXI_MGR_READ           = 5, // AXI_MGR_READ   : SINC to KSU/RNG/SHAREDRAM/DMB
  ENTRY_AXI_MGR_WRITE          = 6, // AXI_MGR_WRITE  : SINC to KSU/RNG/SHAREDRAM/DMB
  ENTRY_ERASE_AFTER_SOFT_RESET = 7, // HW ERASE Cache MEM when FW SInC Reset comamnd
  ENTRY_SINC_WARM_RESET        = 8, // WARM RESET
  ENTRY_MPU_ATTR_READ          = 9, // MPU ATTR_READ  : CREG MPU operation
  ENTRY_MPU_ATTR_WRITE         = 10, // MPU WRITE      : CREG MPU operation
  ENTRY_MPU_STATUS_READ        = 11, // MPU ATTR_READ  : CREG MPU operation
  ENTRY_MPU_STATUS_WRITE       = 12, // MPU WRITE      : CREG MPU operation
  ENTRY_MPU_UNDEFINED_OP       = 13, // MPU operation that leads to access fail
  ENTRY_NULL // reserved
} sinc_sb_pkt_entry_e;

// Enum: sinc_req_type_e
// Enumeration of SINC request types
typedef enum {
  SINC_CREG_ERASE_REQ       = 0,  // CREG_ERASE
  SINC_CPU_READ_REQ         = 1,  // CPU_READ       : SP to cache
  SINC_CPU_WRITE_REQ        = 2,  // CPU_WRITE      : SP to cache
  SINC_AXI_SUB_READ_REQ     = 3,  // AXI_SUB_READ   : SP to register
  SINC_AXI_SUB_WRITE_REQ    = 4,  // AXI_SUB_WRITE  : SP to register
  SINC_FW_OP_REQ            = 5,  // AXI_SUB_WRITE  : SP to cmd register
  SINC_SINC_WARM_RESET_REQ  = 6,  // WARM RESET
  SINC_MPU_ATTR_READ_REQ    = 7,  // MPU ATTR_READ  : CREG MPU operation
  SINC_MPU_ATTR_WRITE_REQ   = 8,  // MPU WRITE      : CREG MPU operation
  SINC_MPU_STATUS_READ_REQ  = 9,  // MPU ATTR_READ  : CREG MPU operation
  SINC_MPU_STATUS_WRITE_REQ = 10, // MPU WRITE      : CREG MPU operation
  SINC_REQ_NULL // reserved
} sinc_req_type_e;

typedef bit [31:0] address_t;

typedef bit [sinc_parameters_pkg::SINC_CPU_MEM_ADDR_WIDTH - 1:0] cpu_address_t;
typedef bit [sinc_parameters_pkg::SINC_CPU_MEM_WE_WIDTH - 1:0] cpu_we_t;
typedef bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH - 1:0] cpu_data_t;
typedef bit [sinc_parameters_pkg::SINC_CPU_MEM_ADDR_WIDTH + 2 - 1:0] cpu_byte_address_t;

typedef bit [(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE * 8) - 1:0] sinc_cache_block_t;
typedef bit [(sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_SIZE * 8) - 1:0] sinc_cache_block_auth_tag_t;

// typedef logic [sinc_parameters_pkg::SINC_CACHE_MEM_RAM_WIDTH-1:0] cache_mem_w_ecc_t;
// typedef logic [sinc_parameters_pkg::SINC_CACHE_MEM_DECODE_DATA_WIDTH-1:0] cache_mem_decoded_t;

// below are left overs
typedef bit [sinc_parameters_pkg::KEY_VAULT_LUT_SLOT_WIDTH-1:0] sinc_lut_t;

typedef bit [sinc_parameters_pkg::SINC_CPU_MEM_ADDR_WIDTH-1:0] key_data_t[8];

typedef bit [sinc_parameters_pkg::KEY_VAULT_KEY_RAM_WRAPPER_DWIDTH-1:0] key_mem_data_t;

typedef bit [31:0] sinc_addr_t;

// Queue of integers type used as return for functions
typedef sinc_addr_t sinc_q_addr_t [$];
typedef bit [31:0] sinc_data_t;

`endif
