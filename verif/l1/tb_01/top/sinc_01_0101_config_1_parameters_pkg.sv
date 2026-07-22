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
// File        : sinc_01_0101_config_1_parameters_pkg.sv
// Description : This package contains test level parameters

`ifndef SINC_PARAMETERS_PKG
`define SINC_PARAMETERS_PKG

package sinc_parameters_pkg;

  import uvmf_base_pkg_hdl::*;

  // pragma uvmf custom package_imports_additional begin
  //      as many things are done for HSP here
  //---------------------------------------------------
  `include "hsp_axi.vh"
  `include "hsp_memmap.vh"
  `include "hsp_subsystem_defines.vh"
  `include "mem_defines.vh"

  // pragma uvmf custom package_imports_additional end

  //  `define SINC_FAULT_INJECT_TEST 1

  `define SINC_TB_TOP hdl_top
  `define SINC_LUT_MEM hdl_top.lut_mem

  `define SINC_AXI_PARITY_PRESENTED_BY_AXUSER 1

  `define SINC_HW_LUT_INIT 1

  `define SINC_AXI_MID_USER_RANGE 11:8
  `define SINC_AXI_VFID_USER_RANGE 6:0
  `define SINC_AXI_VFID_CHECK_RANGE 4:0
  `define SINC_AXI_VFID_BYPASS_LOWER_RANGE_SEL 5
  `define SINC_AXI_VFID_BLOCK_ACCESS_SEL 6
  `define SINC_RAM_BACK_DOOR_ENABLE 0

  `define SINC_CMD_REG_RSVD_RANGE_SEL 31:8
  `define SINC_CMD_REG_SEL_CMD_RANGE_SEL 7:0

  // data return when slv_err asserted for CPU_READ
  parameter SINC_CPU_ERRDATA = 32'h0;

  // config_2-only knob. Drives sinc_top.NO_SEED_LOADING (only present on
  // 0101+ RTL). 1 = AES DRBG starts already-seeded; skip RNG seed DMA.
  parameter bit SINC_NO_SEED_LOADING = 1'b1;

  parameter SINC_CACHE_MEM_RAM_WIDTH         = 156;
  parameter SINC_CACHE_MEM_RAM_DEPTH         = 16384;
  parameter SINC_CACHE_MEM_DECODE_DATA_WIDTH = 128;
  parameter SINC_CACHE_VTAG_RAM_WIDTH        = 40;
  parameter SINC_CACHE_VTAG_RAM_DEPTH        = 128;

  parameter SINC_CACHE_BLOCK_TOTAL_NUM                     = 32768; // 16MB, 512B per block
  parameter SINC_CACHE_BLOCK_SIZE                          = 512; // Byte
  parameter SINC_CACHE_BLOCK_AUTH_TAG_SIZE                 = 16; // Byte
  parameter SINC_CACHE_BLOCK_FETCH_AXI_ADDRESS_OFFSET      = 'h200;
  parameter SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET      = 'h80;
  parameter SINC_CACHE_BLOCK_AUTH_TAG_FETCH_ADDRESS_OFFSET = 'h10;

  parameter SINC_CACHE_MEM_LINES_PER_CACHE = (SINC_CACHE_BLOCK_SIZE * 8) / SINC_CACHE_MEM_DECODE_DATA_WIDTH;

  parameter SINC_MEM_LINE_NUM_PER_CACHE_LINE = 128;
  parameter SINC_MEM_LINE_WIDTH              = 32;
  parameter SINC_N_WAY_ASSOCIATE_CACHE_LINE  = 4;
  parameter SINC_CACHE_SETS_NUM              = 128;
  parameter SINC_CACHE_LINE_NUM              = SINC_CACHE_SETS_NUM * SINC_N_WAY_ASSOCIATE_CACHE_LINE;

  parameter SINC_CACHE_START_ADDR = 0;
  parameter SINC_CACHE_END_ADDR   = 14'h3FFF;
  `define SINC_CACHE_ADDR_RANGE_SEL 15:0

  parameter SINC_CPU_MEM_ADDR_WIDTH = 22;
  parameter SINC_CPU_MEM_WE_WIDTH   = 4;
  parameter SINC_CPU_MEM_DATA_WIDTH = 32;

  parameter SINC_CACHE_MEM_ADDR_WIDTH = 14;
  parameter SINC_CACHE_MEM_DATA_WIDTH = 156;

  parameter SINC_CACHE_VTAG_ADDR_WIDTH = 7;
  parameter SINC_CACHE_VTAG_DATA_WIDTH = 40;

  parameter SINC_REG_START_ADDR = `SINC_REG_BASE_ADDR;
  parameter SINC_REG_END_ADDR   = `SINC_REG_END_ADDR;

  parameter SINC_KSU_START_ADDR       = `KSU_KEY_SLOT_BASE_ADDR;
  parameter SINC_KSU_KEY_PADDING_SIZE = 'h80;
  parameter SINC_KSU_END_ADDR         = `KSU_KEY_SLOT_BASE_ADDR + (SINC_KSU_KEY_PADDING_SIZE * `KSU_KEYS);

  parameter SINC_RNG_START_ADDR = `RNG_SEED_BASE_ADDR;
  // HSP_ADDR_MAP_RNG_OFFSET was defined in hsp_top.vh (prior subsystem), hardcoded here
  // Original value from a prior project: #define HSP_ADDR_MAP_RNG_OFFSET 0x8f0a0000ul
  parameter SINC_RNG_END_ADDR   = 32'h8F0A_0000 + (4 * 1024) - 'h1;

  // HSP_ADDR_MAP_SHAREDRAM_ADDRESS was defined in hsp_top.h (prior subsystem), hardcoded here
  // Original value from a prior project: #define HSP_ADDR_MAP_SHAREDRAM_ADDRESS 0x8f020000ul
  parameter SINC_SHAREDRAM_START_ADDR         = 32'h8F02_0000;
  parameter SINC_SHAREDRAM_BLOCK_PADDING_SIZE = 'h200;
  // HSP_ADDR_MAP_SHAREDRAM_ADDRESS was defined in hsp_top.h (prior subsystem), hardcoded here
  // Original value from a prior project: #define HSP_ADDR_MAP_SHAREDRAM_ADDRESS 0x8f020000ul
  parameter SINC_SHAREDRAM_END_ADDR           = 32'h8F02_0000 + 'h1_0000;

  parameter SINC_DMB_START_ADDR     = 32'h9000_0000;
  parameter SINC_DMB_END_ADDR       = 32'hFFFF_FFFF;
  parameter SINC_DMB_BLOCK_END_ADDR = 32'h9000_0000 + 32'h0100_0000;
  parameter SINC_DMB_TAG_START_ADDR = 32'h9000_0000 + 32'h0F00_0000;
  parameter SINC_DMB_TAG_END_ADDR   = 32'h9000_0000 + 32'h0F00_0000 + 32'h0100_0000;

  // parameter  SINC_DMB_START_ADDR = `HSP_DMB_BEGIN;
  // parameter  SINC_DMB_END_ADDR = `HSP_DMB_END;

  parameter SINC_MEM_NUM_PAGES      = 4096;
  parameter SINC_PAGE_SEL_WIDTH     = 12;
  parameter SINC_256_PAGE_SEL_WIDTH = 6;
  parameter SINC_CIRAM_END_ADDR     = 'hFFFF;
  parameter SINC_CPU_MEM_END_ADDR   = 'h3FFFFF;

  parameter string SINC_CONTROL_REG_NAME = "m_key_ramwrap_inject_agent_BFM"; /* [5] */
  parameter RESERVED_REGION_0_START_ADDR = 32'h8F0C_9000;
  parameter RESERVED_REGION_0_END_ADDR   = 32'h8F0E_0FFF;
  parameter RESERVED_REGION_1_START_ADDR = 32'h8F0E_1074;
  parameter RESERVED_REGION_1_END_ADDR   = 32'h8F0E_3FFF;
  parameter AXI_MST_ID_AXUSER_MSB        = 11;
  parameter AXI_MST_ID_AXUSER_LSB        = 8;

  parameter SP_MST_ID            = 0;
  parameter AES_MST_ID           = 1;
  parameter SHA_MST_ID           = 2;
  parameter UPKA_MST_ID          = 3;
  parameter CDED_MST_ID          = 4;
  parameter KEY_VAULT_KEY_SLOTS  = 8192;
  parameter KEY_VAULT_KEY_WIDTH  = 256;
  parameter KEY_VAULT_LUT_SLOTS  = 8192;
  parameter KEY_VAULT_LUT_WIDTH  = 39;
  parameter KEY_VAULT_VFID_WIDTH = 7;
  `define SINC_LUT_VFID_RANGE_SEL 13:7
  `define SINC_LUT_INDEX_SEL 6:0
  `define SINC_LUT_KEY_RANGE_SEL 6:0

  /* Word address
   *
   Address [31:22] = Base addr
   Address [21:14] = Tag
   Address [13:7]  = Set
   Address [6:0]   = Offset
   */

  `define SINC_CACHE_BASE_ADDR_RANGE_SEL 31:22
  `define SINC_CACHE_TAG_RANGE_SEL 21:14
  `define SINC_CACHE_SET_RANGE_SEL 13:7
  `define SINC_CACHE_OFFSET_RANGE_SEL 6:0
  `define SINC_CACHE_BLOCK_NUM_RANGE_SEL 31:7
  `define SINC_CACHE_BLOCK_DATA_RANGESEL 6:0
  `define SINC_CACHE_OFFSET_RANGE_BYTE_SEL 8:0

  parameter SINC_CACHE_BASE_ADDR_WIDTH          = 10;
  parameter SINC_CACHE_TAG_WIDTH                = 8;
  parameter SINC_CACHE_SET_WIDTH                = 7;
  parameter SINC_CACHE_BLOCK_NUM_CPU_ADDR_SHIFT = 7;
  parameter SINC_CACHE_BYTE_OFFSET_WIDTH        = 7;
  parameter SINC_CACHE_BLOCK_OFFSET             = 32'h200;
  parameter SINC_CACHE_AUTH_TAG_OFFSET          = 32'h10;

  // each line of Key has 32 bits data
  parameter KEY_VAULT_KEY_LINE_WIDTH          = 32;
  parameter KEY_VAULT_KEY_LINES               = KEY_VAULT_KEY_WIDTH / KEY_VAULT_KEY_LINE_WIDTH;
  // each lut slot has 16 bits
  // reserved[1:0], valid[0], VFID[5:0], Key_Index[6:0]
  parameter KEY_VAULT_LUT_SLOT_WIDTH          = 16;
  parameter KEY_VAULT_LUT_VALID_SEL           = 13;
  parameter KEY_VAULT_LUT_AXI_WR_RESERVED_LSB = 15; // fixme: check with MAS

  parameter KEY_VAULT_WORD_SIZE = KEY_VAULT_KEY_WIDTH / 32;

  // RAM WRAPPER
  parameter KEY_VAULT_RAM_WRAPPER_SUPPORT_RMW          = 1;
  parameter KEY_VAULT_LUT_RAM_WRAPPER_AWIDTH           = 12;
  parameter KEY_VAULT_LUT_RAM_WRAPPER_DWIDTH           = 39;
  parameter KEY_VAULT_LUT_RAM_WRAPPER_ERASE_START_ADDR = 0;
  parameter KEY_VAULT_LUT_RAM_WRAPPER_ERASE_END_ADDR   = 4095;
  parameter KEY_VAULT_LUT_RAM_WRAPPER_DATA_WIDTH       = 39;
  parameter KEY_VAULT_KEY_RAM_WRAPPER_AWIDTH           = 16;
  parameter KEY_VAULT_KEY_RAM_WRAPPER_DWIDTH           = 39;
  parameter KEY_VAULT_KEY_RAM_WRAPPER_ERASE_START_ADDR = 0;
  parameter KEY_VAULT_KEY_RAM_WRAPPER_ERASE_END_ADDR   = 65535;
  parameter KEY_VAULT_KEY_RAM_WRAPPER_DATA_WIDTH       = 39;
  parameter KEY_VAULT_KEY_RAM_DECODE_ADDR_WIDTH        = 18;
  parameter KEY_VAULT_LUT_RAM_DECODE_ADDR_WIDTH        = 14;
  parameter KEY_VAULT_KEY_RAM_AXI_SLOT_MASK            = 32'h3_FFFF;
  parameter KEY_VAULT_KEY_RAM_AXI_INDEX_MASK           = 32'hFFFC_0000;
  parameter KEY_VAULT_LUT_WIRITE_DATA_MASK             = 32'h3_FFFF;
  parameter KEY_VAULT_LUT_WORD_ADDR_WIDTH              = 32'hC;
  parameter KEY_VAULT_LUT_ENCODE_WIDTH                 = 32'hE;
  parameter KEY_VAULT_LUT_RESET_VALUE                  = 16'h0;

  // These parameters are used to uniquely identify each interface.  The monitor_bfm and
  // driver_bfm are placed into and retrieved from the uvm_config_db using these string
  // names as the field_name. The parameter is also used to enable transaction viewing
  // from the command line for selected interfaces using the UVM command line processing.
  parameter string M_LUT_RAMWRAP_ENGINE_AGENT_BFM = "m_lut_ramwrap_engine_agent_BFM"; /* [0] */
  parameter string M_LUT_RAMWRAP_ERASE_AGENT_BFM  = "m_lut_ramwrap_erase_agent_BFM"; /* [1] */
  parameter string M_LUT_RAMWRAP_INJECT_AGENT_BFM = "m_lut_ramwrap_inject_agent_BFM"; /* [2] */
  parameter string M_KEY_RAMWRAP_ENGINE_AGENT_BFM = "m_key_ramwrap_engine_agent_BFM"; /* [3] */
  parameter string M_KEY_RAMWRAP_ERASE_AGENT_BFM  = "m_key_ramwrap_erase_agent_BFM"; /* [4] */
  parameter string M_KEY_RAMWRAP_INJECT_AGENT_BFM = "m_key_ramwrap_inject_agent_BFM"; /* [5] */

  // pragma uvmf custom package_item_additional begin
  // pragma uvmf custom package_item_additional end

  // TB defines (depends on the subsystem SINC spec) begin
  `define SINC_LUT_INDEX_RANGE 6:0
  `define SINC_LUT_VFID_RANGE 11:7
  `define SINC_LUT_PFVF_RANGE 12

  // TB defines (depends on the subsystem SINC spec) end
  // parameters for access control: SINC MAS 0100 - 10.2.2.1 AXI Access Control

  `define MP_REG_RD_ACCESS_ALLOWED 1
  `define MP_REG_WR_ACCESS_ALLOWED 1
  `define MP_VALID_KEY_RD_ACCESS_ALLOWED 0
  `define MP_VALID_KEY_WR_ACCESS_ALLOWED 0
  `define MP_INVALID_KEY_RD_ACCESS_ALLOWED 0
  `define MP_INVALID_KEY_WR_ACCESS_ALLOWED 1
  `define MP_LUT_RD_ACCESS_ALLOWED 1
  `define MP_LUT_WR_ACCESS_ALLOWED 1

  `define AES_REG_RD_ACCESS_ALLOWED 0
  `define AES_REG_WR_ACCESS_ALLOWED 0
  `define AES_VALID_KEY_RD_ACCESS_ALLOWED 1
  `define AES_VALID_KEY_WR_ACCESS_ALLOWED 0
  `define AES_INVALID_KEY_RD_ACCESS_ALLOWED 1
  `define AES_INVALID_KEY_WR_ACCESS_ALLOWED 1
  `define AES_LUT_RD_ACCESS_ALLOWED 0
  `define AES_LUT_WR_ACCESS_ALLOWED 0

  `define SHA_REG_RD_ACCESS_ALLOWED 0
  `define SHA_REG_WR_ACCESS_ALLOWED 0
  `define SHA_VALID_KEY_RD_ACCESS_ALLOWED 1
  `define SHA_VALID_KEY_WR_ACCESS_ALLOWED 0
  `define SHA_INVALID_KEY_RD_ACCESS_ALLOWED 1
  `define SHA_INVALID_KEY_WR_ACCESS_ALLOWED 1
  `define SHA_LUT_RD_ACCESS_ALLOWED 0
  `define SHA_LUT_WR_ACCESS_ALLOWED 0

  `define UPKA_REG_RD_ACCESS_ALLOWED 0
  `define UPKA_REG_WR_ACCESS_ALLOWED 0
  `define UPKA_VALID_KEY_RD_ACCESS_ALLOWED 1
  `define UPKA_VALID_KEY_WR_ACCESS_ALLOWED 0
  `define UPKA_INVALID_KEY_RD_ACCESS_ALLOWED 1
  `define UPKA_INVALID_KEY_WR_ACCESS_ALLOWED 1
  `define UPKA_LUT_RD_ACCESS_ALLOWED 0
  `define UPKA_LUT_WR_ACCESS_ALLOWED 0

  `define CDED_REG_RD_ACCESS_ALLOWED 0
  `define CDED_REG_WR_ACCESS_ALLOWED 0
  `define CDED_VALID_KEY_RD_ACCESS_ALLOWED 1
  `define CDED_VALID_KEY_WR_ACCESS_ALLOWED 0
  `define CDED_INVALID_KEY_RD_ACCESS_ALLOWED 0
  `define CDED_INVALID_KEY_WR_ACCESS_ALLOWED 0
  `define CDED_LUT_RD_ACCESS_ALLOWED 0
  `define CDED_LUT_WR_ACCESS_ALLOWED 0

  // Fetch and store data size
  parameter SINC_RNG_SEED_IN_BITS          = 320 * 2;
  parameter SINC_KEY_IN_BITS               = 256;
  parameter SINC_PER_ENCRYPT_BLOCK_IN_BITS = 4096;
  parameter SINC_PER_AUTH_TAG_IN_BITS      = 128;

  // Registers

  // Enum: sinc_fw_op_e
  // Enumeration of SINC firmware operations
  typedef enum bit [7:0] {
    SINC_AES_TEST_DISABLE       = 'h0,
    SINC_SET_INIT_STATE         = 'h1,
    SINC_SET_CACHE_ACTIVE_STATE = 'h2,
    SINC_SINC_RESET             = 'h4,
    SINC_SINC_REINIT            = 'h8,
    SINC_ENCR_BLOCK             = 'h10,
    SINC_DISABLE_RESET          = 'h20,
    SINC_DISABLE_REINIT         = 'h40,
    SINC_AES_TEST_EN            = 'h80,
    SINC_FW_UNMAPPED            = 'hFF} sinc_fw_cmd_e;

  // Enum: sinc_cache_state_type_e
  // Enumeration of SInC CMU's cache state
  // used for scoreboard to log the system status about cache state, used by sb_cov
  typedef enum bit [7:0] {CACHE_DISABLE_STATE = 'h0,
    CACHE_INIT_STATE                          = 'h0F,
    CACHE_ACTIVE_STATE                        = 'hF0,
    CACHE_FAIL_STATE                          = 'hFF} sinc_cache_state_type_e;

  typedef enum {
    CMD,
    BLOCK_ENCR_NUM,
    NUM_OF_BLOCKS,
    BLOCK_ENCR_ADDR,
    BLOCK_ENCR_KEY,
    AES_IV_NONCE_0,
    AES_IV_NONCE_1,
    AES_IV_NONCE_2,
    EXT_BLOCK_BASE_ADDR,
    EXT_AUTH_TAG_BASE_ADDR,
    STATUS,
    HIT_CNTR_LOWER,
    HIT_CNTR_UPPER,
    MISS_CNTR_LOWER,
    MISS_CNTR_UPPER,
    LAT_CNTR_LOWER,
    LAT_CNTR_UPPER,
    PERF_CNTR_CTRL,
    AES_TEST_DATA_IN_0,
    AES_TEST_DATA_IN_1,
    AES_TEST_DATA_IN_2,
    AES_TEST_DATA_IN_3,
    AES_TEST_DATA_OUT_0,
    AES_TEST_DATA_OUT_1,
    AES_TEST_DATA_OUT_2,
    AES_TEST_DATA_OUT_3,
    AES_TEST_CTRL,
    AES_TEST_STATUS,
    ENCR_BLOCK_STATUS
  } sinc_reg_e;

  parameter string STATUS_REG_NAME              = "status";
  parameter string AES_TEST_STATUS_REG_NAME     = "aes_test_status";
  parameter string AES_TEST_CTRL_REG_NAME       = "aes_test_ctrl";
  parameter string CMD_REG_NAME                 = "cmd";
  parameter string AES_TEST_DATA_OUT_0_REG_NAME = "aes_test_data_out_0";
  parameter string AES_TEST_DATA_OUT_1_REG_NAME = "aes_test_data_out_1";
  parameter string AES_TEST_DATA_OUT_2_REG_NAME = "aes_test_data_out_2";
  parameter string AES_TEST_DATA_OUT_3_REG_NAME = "aes_test_data_out_3";
  parameter string AES_IV_NONCE_0_REG_NAME      = "aes_iv_nonce_0";
  parameter string AES_IV_NONCE_1_REG_NAME      = "aes_iv_nonce_1";
  parameter string AES_IV_NONCE_2_REG_NAME      = "aes_iv_nonce_2";
  parameter string ENCR_BLOCK_STATUS_REG_NAME   = "encr_block_status";

  `define SINC_DV_REGS_STATUS_BUSY_SEL `SINC_REGS_STATUS_BUSY_MSB
  `define SINC_DV_REGS_STATUS_COMPLETE_SEL `SINC_REGS_STATUS_COMPLETE_MSB
  `define SINC_DV_REGS_STATUS_ERROR_CMD_SEL `SINC_REGS_STATUS_ERROR_CMD_MSB
  `define SINC_DV_REGS_STATUS_ERROR_FAULT_SEL `SINC_REGS_STATUS_ERROR_FAULT_MSB
  `define SINC_DV_REGS_STATUS_MATCH_STS_SEL `SINC_REGS_STATUS_MATCH_STS_MSB

  // defines for CMD
  `define SINC_CMD_REG_EXIST 1
  `define SINC_CMD_REG_WRITE_ALLOWED 1
  `define SINC_CMD_REG_READ_ALLOWED 0
  `define SINC_CMD_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_CMD_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_CMD_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_CMD_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for BLOCK_ENCR_NUM
  `define SINC_BLOCK_ENCR_NUM_REG_EXIST 1
  `define SINC_BLOCK_ENCR_NUM_REG_WRITE_ALLOWED 1
  `define SINC_BLOCK_ENCR_NUM_REG_READ_ALLOWED 1
  `define SINC_BLOCK_ENCR_NUM_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_BLOCK_ENCR_NUM_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_BLOCK_ENCR_NUM_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_BLOCK_ENCR_NUM_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for NUM_OF_BLOCKS
  `define SINC_NUM_OF_BLOCKS_REG_EXIST 1
  `define SINC_NUM_OF_BLOCKS_REG_WRITE_ALLOWED 1
  `define SINC_NUM_OF_BLOCKS_REG_READ_ALLOWED 1
  `define SINC_NUM_OF_BLOCKS_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_NUM_OF_BLOCKS_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_NUM_OF_BLOCKS_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_NUM_OF_BLOCKS_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for BLOCK_ENCR_ADDR
  `define SINC_BLOCK_ENCR_ADDR_REG_EXIST 1
  `define SINC_BLOCK_ENCR_ADDR_REG_WRITE_ALLOWED 1
  `define SINC_BLOCK_ENCR_ADDR_REG_READ_ALLOWED 1
  `define SINC_BLOCK_ENCR_ADDR_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_BLOCK_ENCR_ADDR_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_BLOCK_ENCR_ADDR_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_BLOCK_ENCR_ADDR_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for BLOCK_ENCR_KEY
  `define SINC_BLOCK_ENCR_KEY_REG_EXIST 1
  `define SINC_BLOCK_ENCR_KEY_REG_WRITE_ALLOWED 1
  `define SINC_BLOCK_ENCR_KEY_REG_READ_ALLOWED 1
  `define SINC_BLOCK_ENCR_KEY_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_BLOCK_ENCR_KEY_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_BLOCK_ENCR_KEY_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_BLOCK_ENCR_KEY_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_IV_NONCE_0
  `define SINC_AES_IV_NONCE_0_REG_EXIST 1
  `define SINC_AES_IV_NONCE_0_REG_WRITE_ALLOWED 1
  `define SINC_AES_IV_NONCE_0_REG_READ_ALLOWED 1
  `define SINC_AES_IV_NONCE_0_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_IV_NONCE_0_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_IV_NONCE_0_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_IV_NONCE_0_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_IV_NONCE_1
  `define SINC_AES_IV_NONCE_1_REG_EXIST 1
  `define SINC_AES_IV_NONCE_1_REG_WRITE_ALLOWED 1
  `define SINC_AES_IV_NONCE_1_REG_READ_ALLOWED 1
  `define SINC_AES_IV_NONCE_1_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_IV_NONCE_1_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_IV_NONCE_1_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_IV_NONCE_1_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_IV_NONCE_2
  `define SINC_AES_IV_NONCE_2_REG_EXIST 1
  `define SINC_AES_IV_NONCE_2_REG_WRITE_ALLOWED 1
  `define SINC_AES_IV_NONCE_2_REG_READ_ALLOWED 1
  `define SINC_AES_IV_NONCE_2_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_IV_NONCE_2_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_IV_NONCE_2_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_IV_NONCE_2_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for EXT_BLOCK_BASE_ADDR
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_EXIST 1
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_WRITE_ALLOWED 1
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_READ_ALLOWED 1
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_EXT_BLOCK_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for EXT_AUTH_TAG_BASE_ADDR
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_EXIST 1
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_WRITE_ALLOWED 1
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_READ_ALLOWED 1
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_EXT_AUTH_TAG_BASE_ADDR_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for STATUS
  `define SINC_STATUS_REG_EXIST 1
  `define SINC_STATUS_REG_WRITE_ALLOWED 0
  `define SINC_STATUS_REG_READ_ALLOWED 1
  `define SINC_STATUS_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_STATUS_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_STATUS_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_STATUS_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for HIT_CNTR_LOWER
  `define SINC_HIT_CNTR_LOWER_REG_EXIST 1
  `define SINC_HIT_CNTR_LOWER_REG_WRITE_ALLOWED 0
  `define SINC_HIT_CNTR_LOWER_REG_READ_ALLOWED 1
  `define SINC_HIT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_HIT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_HIT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_HIT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for HIT_CNTR_UPPER
  `define SINC_HIT_CNTR_UPPER_REG_EXIST 1
  `define SINC_HIT_CNTR_UPPER_REG_WRITE_ALLOWED 0
  `define SINC_HIT_CNTR_UPPER_REG_READ_ALLOWED 1
  `define SINC_HIT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_HIT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_HIT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_HIT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for MISS_CNTR_LOWER
  `define SINC_MISS_CNTR_LOWER_REG_EXIST 1
  `define SINC_MISS_CNTR_LOWER_REG_WRITE_ALLOWED 0
  `define SINC_MISS_CNTR_LOWER_REG_READ_ALLOWED 1
  `define SINC_MISS_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_MISS_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_MISS_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_MISS_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for MISS_CNTR_UPPER
  `define SINC_MISS_CNTR_UPPER_REG_EXIST 1
  `define SINC_MISS_CNTR_UPPER_REG_WRITE_ALLOWED 0
  `define SINC_MISS_CNTR_UPPER_REG_READ_ALLOWED 1
  `define SINC_MISS_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_MISS_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_MISS_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_MISS_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for LAT_CNTR_LOWER
  `define SINC_LAT_CNTR_LOWER_REG_EXIST 1
  `define SINC_LAT_CNTR_LOWER_REG_WRITE_ALLOWED 0
  `define SINC_LAT_CNTR_LOWER_REG_READ_ALLOWED 1
  `define SINC_LAT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_LAT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_LAT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_LAT_CNTR_LOWER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for LAT_CNTR_UPPER
  `define SINC_LAT_CNTR_UPPER_REG_EXIST 1
  `define SINC_LAT_CNTR_UPPER_REG_WRITE_ALLOWED 0
  `define SINC_LAT_CNTR_UPPER_REG_READ_ALLOWED 1
  `define SINC_LAT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_LAT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_LAT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_LAT_CNTR_UPPER_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for PERF_CNTR_CTRL
  `define SINC_PERF_CNTR_CTRL_REG_EXIST 1
  `define SINC_PERF_CNTR_CTRL_REG_WRITE_ALLOWED 1
  `define SINC_PERF_CNTR_CTRL_REG_READ_ALLOWED 1
  `define SINC_PERF_CNTR_CTRL_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_PERF_CNTR_CTRL_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_PERF_CNTR_CTRL_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_PERF_CNTR_CTRL_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_DATA_IN_0
  `define SINC_AES_TEST_DATA_IN_0_REG_EXIST 1
  `define SINC_AES_TEST_DATA_IN_0_REG_WRITE_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_0_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_0_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_TEST_DATA_IN_0_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_AES_TEST_DATA_IN_0_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_AES_TEST_DATA_IN_0_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_DATA_IN_1
  `define SINC_AES_TEST_DATA_IN_1_REG_EXIST 1
  `define SINC_AES_TEST_DATA_IN_1_REG_WRITE_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_1_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_1_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_TEST_DATA_IN_1_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_AES_TEST_DATA_IN_1_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_AES_TEST_DATA_IN_1_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_DATA_IN_2
  `define SINC_AES_TEST_DATA_IN_2_REG_EXIST 1
  `define SINC_AES_TEST_DATA_IN_2_REG_WRITE_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_2_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_2_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_TEST_DATA_IN_2_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_AES_TEST_DATA_IN_2_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_AES_TEST_DATA_IN_2_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_DATA_IN_3
  `define SINC_AES_TEST_DATA_IN_3_REG_EXIST 1
  `define SINC_AES_TEST_DATA_IN_3_REG_WRITE_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_3_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_IN_3_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_TEST_DATA_IN_3_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_AES_TEST_DATA_IN_3_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_AES_TEST_DATA_IN_3_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_DATA_OUT_0
  `define SINC_AES_TEST_DATA_OUT_0_REG_EXIST 1
  `define SINC_AES_TEST_DATA_OUT_0_REG_WRITE_ALLOWED 0
  `define SINC_AES_TEST_DATA_OUT_0_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_OUT_0_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_AES_TEST_DATA_OUT_0_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_TEST_DATA_OUT_0_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_TEST_DATA_OUT_0_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_TEST_DATA_OUT_1
  `define SINC_AES_TEST_DATA_OUT_1_REG_EXIST 1
  `define SINC_AES_TEST_DATA_OUT_1_REG_WRITE_ALLOWED 0
  `define SINC_AES_TEST_DATA_OUT_1_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_OUT_1_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_AES_TEST_DATA_OUT_1_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_TEST_DATA_OUT_1_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_TEST_DATA_OUT_1_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_TEST_DATA_OUT_2
  `define SINC_AES_TEST_DATA_OUT_2_REG_EXIST 1
  `define SINC_AES_TEST_DATA_OUT_2_REG_WRITE_ALLOWED 0
  `define SINC_AES_TEST_DATA_OUT_2_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_OUT_2_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_AES_TEST_DATA_OUT_2_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_TEST_DATA_OUT_2_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_TEST_DATA_OUT_2_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_TEST_DATA_OUT_3
  `define SINC_AES_TEST_DATA_OUT_3_REG_EXIST 1
  `define SINC_AES_TEST_DATA_OUT_3_REG_WRITE_ALLOWED 0
  `define SINC_AES_TEST_DATA_OUT_3_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_DATA_OUT_3_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_AES_TEST_DATA_OUT_3_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_TEST_DATA_OUT_3_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_TEST_DATA_OUT_3_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for AES_TEST_CTRL
  `define SINC_AES_TEST_CTRL_REG_EXIST 1
  `define SINC_AES_TEST_CTRL_REG_WRITE_ALLOWED 1
  `define SINC_AES_TEST_CTRL_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_CTRL_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_AES_TEST_CTRL_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_AES_TEST_CTRL_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_AES_TEST_CTRL_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for AES_TEST_STATUS
  `define SINC_AES_TEST_STATUS_REG_EXIST 1
  `define SINC_AES_TEST_STATUS_REG_WRITE_ALLOWED 0
  `define SINC_AES_TEST_STATUS_REG_READ_ALLOWED 1
  `define SINC_AES_TEST_STATUS_REG_WRITE_DISCARD_IN_CACHE_DISABLE 1
  `define SINC_AES_TEST_STATUS_REG_WRITE_DISCARD_IN_CACHE_INIT 1
  `define SINC_AES_TEST_STATUS_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 1
  `define SINC_AES_TEST_STATUS_REG_WRITE_DISCARD_IN_CACHE_FAIL 1

  // defines for ENCR_BLOCK_STATUS
  `define SINC_ENCR_BLOCK_STATUS_REG_EXIST 1
  `define SINC_ENCR_BLOCK_STATUS_REG_WRITE_ALLOWED 0
  `define SINC_ENCR_BLOCK_STATUS_REG_READ_ALLOWED 1
  `define SINC_ENCR_BLOCK_STATUS_REG_WRITE_DISCARD_IN_CACHE_DISABLE 0
  `define SINC_ENCR_BLOCK_STATUS_REG_WRITE_DISCARD_IN_CACHE_INIT 0
  `define SINC_ENCR_BLOCK_STATUS_REG_WRITE_DISCARD_IN_CACHE_ACTIVE 0
  `define SINC_ENCR_BLOCK_STATUS_REG_WRITE_DISCARD_IN_CACHE_FAIL 0

  // defines for access permission
  `define SINC_CACHE_DISABLE_CPU_MEM_READ_ALLOWED 1
  `define SINC_CACHE_DISABLE_CPU_MEM_WRITE_ALLOWED 1
  `define SINC_CACHE_INIT_CPU_MEM_READ_ALLOWED 1
  `define SINC_CACHE_INIT_CPU_MEM_WRITE_ALLOWED 1
  `define SINC_CACHE_ACTIVE_CPU_MEM_READ_ALLOWED 1
  `define SINC_CACHE_ACTIVE_CPU_MEM_WRITE_ALLOWED 0
  `define SINC_CACHE_FAIL_CPU_MEM_READ_ALLOWED 0
  `define SINC_CACHE_FAIL_CPU_MEM_WRITE_ALLOWED 0

  // defines for FW access in states
  `define SINC_SINC_RESET_IN_CACHE_DISABLE_ALLOWED 0
  `define SINC_SINC_RESET_IN_CACHE_INIT_ALLOWED 1
  `define SINC_SINC_RESET_IN_CACHE_ACTIVE_ALLOWED 1
  `define SINC_SINC_RESET_IN_CACHE_FAIL_ALLOWED 1

  `define SINC_SET_INIT_STATE_IN_CACHE_DISABLE_ALLOWED 1
  `define SINC_SET_INIT_STATE_IN_CACHE_INIT_ALLOWED 0
  `define SINC_SET_INIT_STATE_IN_CACHE_ACTIVE_ALLOWED 0
  `define SINC_SET_INIT_STATE_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_ENCR_BLOCK_IN_CACHE_DISABLE_ALLOWED 0
  `define SINC_ENCR_BLOCK_IN_CACHE_INIT_ALLOWED 1
  `define SINC_ENCR_BLOCK_IN_CACHE_ACTIVE_ALLOWED 0
  `define SINC_ENCR_BLOCK_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_DISABLE_ALLOWED 0
  `define SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_INIT_ALLOWED 1
  `define SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_ACTIVE_ALLOWED 0
  `define SINC_SET_CACHE_ACTIVE_STATE_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_AES_TEST_EN_IN_CACHE_DISABLE_ALLOWED 1
  `define SINC_AES_TEST_EN_IN_CACHE_INIT_ALLOWED 0
  `define SINC_AES_TEST_EN_IN_CACHE_ACTIVE_ALLOWED 0
  `define SINC_AES_TEST_EN_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_AES_TEST_DISABLE_IN_CACHE_DISABLE_ALLOWED 1
  `define SINC_AES_TEST_DISABLE_IN_CACHE_INIT_ALLOWED 0
  `define SINC_AES_TEST_DISABLE_IN_CACHE_ACTIVE_ALLOWED 0
  `define SINC_AES_TEST_DISABLE_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_DISABLE_RESET_IN_CACHE_DISABLE_ALLOWED 1
  `define SINC_DISABLE_RESET_IN_CACHE_INIT_ALLOWED 1
  `define SINC_DISABLE_RESET_IN_CACHE_ACTIVE_ALLOWED 1
  `define SINC_DISABLE_RESET_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_DISABLE_REINIT_IN_CACHE_DISABLE_ALLOWED 1
  `define SINC_DISABLE_REINIT_IN_CACHE_INIT_ALLOWED 1
  `define SINC_DISABLE_REINIT_IN_CACHE_ACTIVE_ALLOWED 1
  `define SINC_DISABLE_REINIT_IN_CACHE_FAIL_ALLOWED 0

  `define SINC_SINC_REINIT_IN_CACHE_DISABLE_ALLOWED 0
  `define SINC_SINC_REINIT_IN_CACHE_INIT_ALLOWED 0
  `define SINC_SINC_REINIT_IN_CACHE_ACTIVE_ALLOWED 1
  `define SINC_SINC_REINIT_IN_CACHE_FAIL_ALLOWED 0

  // TB typedefs
  // AES parameters
  parameter SINC_AES_LITTLE_ENDIAN = 1;
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

  typedef logic [sinc_parameters_pkg::SINC_CACHE_MEM_RAM_WIDTH-1:0] cache_mem_w_ecc_t;
  typedef logic [sinc_parameters_pkg::SINC_CACHE_MEM_DECODE_DATA_WIDTH-1:0] cache_mem_decoded_t;

  typedef bit [31:0] reg_data_t;

  typedef bit [255:0] sinc_key_t;

  typedef bit [31:0] sinc_axi_data_t;
  typedef bit [31:0] sinc_axi_addr_t;

  typedef enum {
    FAULT_ERROR_TYPE_CIU_CACHE_FSM_ILLEGAL, // hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl.ciu_cache_sm_r
    FAULT_ERROR_TYPE_VTAG_FSM_ILLEGAL, // hdl_top.sinc.u_sinc_ciu.u_ciu_vtag.vtag_sm_r
    FAULT_ERROR_TYPE_CMU_CTRL_FSM_ILLEGAL, // hdl_top.sinc.u_sinc_cmu.u_cmu_ctrl.state
    FAULT_ERROR_TYPE_CACHE_STATE_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_SINC_SUB_STATE_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_AES_CTRL_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_DMA_R_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_DMA_W_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_AES_KEYEXP_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_GPAES_MODE_MAIN_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_GPAES_GHASH_MUL_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_GPAES_SUB_STATE_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_GPAES_MODE_SEC_FSM_ILLEGAL,
    FAULT_ERROR_TYPE_GPAES_MODE_GHASH_FSM_ILLEGAL
  } sinc_fault_error_type_e;

  typedef enum {
    FSM_FAULT_RECOVER_OP_FW_SINC_RESET,
    FSM_FAULT_RECOVER_OP_WARM_RESET
  } fsm_halt_recover_op_type_e;

  // typedef enum logic [5:0] {
  //                             CIU_IDLE        = 6'b00_0000,
  //                             CIU_MEM_READ    = 6'b00_0111,
  //                             CIU_WAIT        = 6'b01_1001,
  //                             CIU_CACHE_MISS  = 6'b01_1110,
  //                             CIU_RREAD       = 6'b10_1010,
  //                             CIU_MEM_WRITE   = 6'b10_1101,
  //                             CIU_EXTRA       = 6'b11_0011,
  //                             CIU_SM_FAULT    = 6'b11_0100
  //                             } sinc_ciu_cache_fsm_t;

  // MPU status sel
  `define SINC_MPU_STATUS_ACCVIO_ADDR_RANGE 23:0
  `define SINC_MPU_STATUS_ACCVIO_RD_RANGE 24
  `define SINC_MPU_STATUS_ACCVIO_WR_RANGE 25
  `define SINC_MPU_STATUS_ACCVIO_EX_RANGE 26
  `define SINC_MPU_STATUS_ACCVIO_ID_RANGE 30:27
  `define SINC_MPU_STATUS_ACCVIO_CLEAR_RANGE 31

  // Error injection stimulus defines

  //=============================================================================
  // SINC Stimulus types from interface view
  //
  // ex)  0, AXI - RD
  //      1, AXI - WR NON FW CMD
  //      2, AXI - WR FW CMD
  //      3, CPU - RD
  //      4, CPU - WR
  //      5, ERASE - MEM
  //      6, MPU - RD
  //      7, MPU - WR
  //      8, Clock Gate
  //=============================================================================
  typedef bit [8:0] sinc_stimulus_type_t;

  `define SINC_STIMULUS_SEL_AXI_RD 0
  `define SINC_STIMULUS_SEL_AXI_WR 1
  `define SINC_STIMULUS_SEL_CPU_MEM_RD 2
  `define SINC_STIMULUS_SEL_CPU_MEM_WR 3
  `define SINC_STIMULUS_SEL_ERASE_MEM 4
  `define SINC_STIMULUS_SEL_MPU_RD 5
  `define SINC_STIMULUS_SEL_MPU_WR 6
  `define SINC_STIMULUS_SEL_CLOCK_GATE 7
  `define SINC_STIMULUS_SEL_HW_RESET 8

  //---------------------------------
  // stimulus violations
  //---------------------------------
  `define SINC_STIMULUS_ERR_CASE_NUM                        12
  `define SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS      0
  `define SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS  1
  `define SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME  2 // code coverage, functional coverage can not cover this
  `define SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS      3
  `define SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS  4
  `define SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME  5 // code coverage, functional coverage can not cover this
  `define SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS        6
  `define SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS    7
  `define SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME    8 // code coverage, functional coverage can not cover this
  `define SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY           9
  `define SINC_STIMULUS_ERR_CPU_CMD_WHEN_CMU_BUSY           10
  `define SINC_STIMULUS_ERR_CACHE_BLOCK_W_ERR_FETCH_BLOCK   11 // start erase when block fetch in progress during write cache iram

  //---------------------------------
  // MPU RD
  //---------------------------------
  `define SINC_MPU_RD_ERR_CASE_NUM 3
  `define SINC_MPU_RD_ERR_RESERVED_BEFORE_ATTR_ADDR 0
  `define SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR 1
  `define SINC_MPU_RD_ERR_CRYPTO_ADDR 2

  //---------------------------------
  // MPU WR
  //---------------------------------
  `define SINC_MPU_WR_ERR_CASE_NUM 4
  `define SINC_MPU_WR_ERR_RESERVED_BEFORE_ATTR_ADDR 0
  `define SINC_MPU_WR_ERR_RESERVED_AFTER_ATTR_ADDR 1
  `define SINC_MPU_WR_ERR_CRYPTO_ADDR 2
  `define SINC_MPU_WR_ERR_STATUS_ADDR_RD_ONLY_BITS 3 // handled by MPU UVC

  //---------------------------------
  // CPU RD
  //---------------------------------
  `define SINC_CPU_RD_ERR_CASE_NUM 6
  `define SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION 0
  `define SINC_CPU_RD_ERR_ADDR_ABOVE_CIRAM_DIS_INIT 1 // SINC will ROUND this
  `define SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK 2 // covered in direct FSM error injection test
  `define SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG 3
  `define SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK 4
  `define SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH 5
  //`define SINC_CPU_RD_ERR_CORR_ECC  9   //covered in non random test
  //`define SINC_CPU_RD_ERR_UNCORR_ECC  10 //covered in non random test

  //---------------------------------
  // CPU WR
  //---------------------------------
  `define SINC_CPU_WR_ERR_CASE_NUM 3
  `define SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION 0
  `define SINC_CPU_WR_ERR_ADDR_ABOVE_CIRAM_DIS_INIT 1
  `define SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE 2

  //---------------------------------
  // AXI GLOBAL
  //---------------------------------
  `define SINC_AXI_GLOBAL_ERR_CASE_NUM 5
  `define SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE 0
  `define SINC_AXI_GLOBAL_ERR_NON_SP 1
  `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE 2
  `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE 3
  `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN 4

  //---------------------------------
  // AXI RD
  //---------------------------------
  `define SINC_AXI_RD_ERR_CASE_NUM 7
  `define SINC_AXI_RD_ERR_NON_SP 0
  `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE 1
  `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE 2
  `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN 3
  `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN 4
  `define SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE 5
  `define SINC_AXI_RD_ERR_WR_ONLY_REG 6

  //---------------------------------
  // AXI WR REG
  //---------------------------------
  `define SINC_AXI_WR_REG_ERR_CASE_NUM 10
  `define SINC_AXI_WR_ERR_NON_SP 0
  `define SINC_AXI_WR_ERR_DISALOWED_REG_IN_CUR_STATE 1
  `define SINC_AXI_WR_ERR_ILLEGAL_ADDR_RANGE 2
  `define SINC_AXI_WR_ERR_NON_ALIGNED_BYTE_ADDR 3
  `define SINC_AXI_WR_ERR_UNSUPPORTED_STROBE 4
  `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_TYPE 5
  `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE 6
  `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN 7
  `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN 8
  `define SINC_AXI_WR_ERR_RD_ONLY_REG 9

  //---------------------------------
  // AXI WR FW
  //---------------------------------
  `define SINC_AXI_WR_FW_CMD_ERR_CASE_NUM 15
  `define SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE 0
  `define SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP 1
  `define SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT 2
  `define SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE 3
  `define SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE 4
  `define SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR 5
  `define SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR 6
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID 7 // RTL will keep issue AXI MGR read, reflect as AXI MGR DECERR
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID 8
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID 9
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR 10
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR 11
  `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR 12
  `define SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR 13
  `define SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR 14

  //---------------------------------
  // AES
  //---------------------------------
  // these will be covered in directed testing
  // `define SINC_AES_ERR_CASE_NUM                   16
  // `define SINC_AES_ERR_KEY_SLOT_ABOVE_MAX         0
  // `define SINC_AES_ERR_DATA_IN_BYTE_CNT_INVALID    1
  // `define SINC_AES_ERR_AES_MODE_INVALID           2
  // `define SINC_AES_ERR_KEY_LEN_RESERVED           3
  // `define SINC_AES_ERR_DATA_IN_VLD_BEFORE_DATA_IN_RDY     4
  // `define SINC_AES_ERR_AAD_SELECTED                       5
  // `define SINC_AES_ERR_ENABLE_AES_TEST_INITIALIZED        6
  // `define SINC_AES_ERR_ENABLE_AES_TEST_CACHE_ACTIVE       7
  // `define SINC_AES_ERR_LOAD_TEST_DATA_INITIALIZED         8
  // `define SINC_AES_ERR_WRITE_AES_TEST_CTRL_VALID_INITIALIZED      9
  // `define SINC_AES_ERR_WRITE_AES_TEST_CTRL_INVALID_INITIALIZED    10
  // `define SINC_AES_ERR_CFG_KEY_IV_RDY_TIMEOUT_INITIALIZED         11
  // `define SINC_AES_ERR_LOAD_TEST_DATA_CACHE_ACTIVE                12
  // `define SINC_AES_ERR_WRITE_AES_TEST_CTRL_VALID_CACHE_ACTIVE     13
  // `define SINC_AES_ERR_WRITE_AES_TEST_CTRL_INVALID_CACHE_ACTIVE   14
  // `define SINC_AES_ERR_CFG_KEY_IV_RDY_TIMEOUT_CACHE_ACTIVE        15

  // typedefs for error scenarios
  typedef bit [`SINC_STIMULUS_ERR_CASE_NUM-1: 0] sinc_stimulus_err_types_t;
  typedef bit [`SINC_MPU_RD_ERR_CASE_NUM-1: 0] sinc_mpu_rd_err_types_t;
  typedef bit [`SINC_MPU_WR_ERR_CASE_NUM-1: 0] sinc_mpu_wr_err_types_t;
  typedef bit [`SINC_CPU_RD_ERR_CASE_NUM-1: 0] sinc_cpu_rd_err_types_t;
  typedef bit [`SINC_CPU_WR_ERR_CASE_NUM-1: 0] sinc_cpu_wr_err_types_t;
  typedef bit [`SINC_AXI_GLOBAL_ERR_CASE_NUM-1: 0] sinc_axi_global_err_types_t;
  typedef bit [`SINC_AXI_RD_ERR_CASE_NUM-1: 0] sinc_axi_rd_err_types_t;
  typedef bit [`SINC_AXI_WR_REG_ERR_CASE_NUM-1: 0] sinc_axi_wr_reg_err_types_t;
  typedef bit [`SINC_AXI_WR_FW_CMD_ERR_CASE_NUM-1: 0] sinc_axi_wr_fw_cmd_err_types_t;

  // GPAES parameter
  parameter string  SINC_GPAES_UVM_PATH_INST    = "*.gpaes_sys_env_sinc_gpaes_sys";
  parameter string  SINC_GPAES_SYS_NAME      = "sinc_gpaes_sys";

endpackage : sinc_parameters_pkg

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_PARAMETERS_PKG
