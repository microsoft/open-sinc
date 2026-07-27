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
// File        : sinc_packet_typedefs.svh
// Description : 

`ifndef SINC_PACKET_TYPEDEFS__SVH
`define SINC_PACKET_TYPEDEFS__SVH

/* moved to sinc_<subsystem>_parameters_pkg.sv
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
 `define SINC_STIMULUS_ERR_CASE_NUM                        10
 `define SINC_STIMULUS_ERR_ERASE_WHEN_AXI_IN_PROGRESS      0
 `define SINC_STIMULUS_ERR_AXI_REQ_WHEN_ERASE_IN_PROGRESS  1
 `define SINC_STIMULUS_ERR_AXI_REQ_AND_ERASE_AT_SAME_TIME  2
 `define SINC_STIMULUS_ERR_ERASE_WHEN_CPU_IN_PROGRESS      3
 `define SINC_STIMULUS_ERR_CPU_REQ_WHEN_ERASE_IN_PROGRESS  4
 `define SINC_STIMULUS_ERR_CPU_REQ_AND_ERASE_AT_SAME_TIME  5
 `define SINC_STIMULUS_ERR_CPU_WHEN_AXI_IN_PROGRESS        6
 `define SINC_STIMULUS_ERR_AXI_REQ_WHEN_CPU_IN_PROGRESS    7
 `define SINC_STIMULUS_ERR_AXI_REQ_AND_CPU_AT_SAME_TIME    8
 `define SINC_STIMULUS_ERR_AXI_CMD_WHEN_CMU_BUSY           9

 //---------------------------------
 // MPU RD
 //---------------------------------
 `define SINC_MPU_RD_ERR_CASE_NUM 3
 `define SINC_MPU_RD_ERR_RESERVED_BEFORE_ATTR_ADDR  0
 `define SINC_MPU_RD_ERR_RESERVED_AFTER_ATTR_ADDR  1
 `define SINC_MPU_RD_ERR_CRYPTO_ADDR  2

 //---------------------------------
 // MPU WR
 //---------------------------------
 `define SINC_MPU_WR_ERR_CASE_NUM 4
 `define SINC_MPU_WR_ERR_RESERVED_BEFORE_ATTR_ADDR  0
 `define SINC_MPU_WR_ERR_RESERVED_AFTER_ATTR_ADDR  1
 `define SINC_MPU_WR_ERR_CRYPTO_ADDR  2
 `define SINC_MPU_WR_ERR_STATUS_ADDR_RD_ONLY_BITS  3

 //---------------------------------
 // CPU RD
 //---------------------------------
 `define SINC_CPU_RD_ERR_CASE_NUM 5
 `define SINC_CPU_RD_ERR_ADDR_MPU_VIOLATION  0
 `define SINC_CPU_RD_ERR_MISS_FAIL_WR_CACHE_BLK 1
 `define SINC_CPU_RD_ERR_MISS_FAIL_RD_AUTH_TAG 2
 `define SINC_CPU_RD_ERR_MISS_FAIL_RD_CACHE_BLK 3
 `define SINC_CPU_RD_ERR_MISS_AUTH_TAG_MISMATCH 4
 //`define SINC_CPU_RD_ERR_CORR_ECC  9   //covered in non random test
 //`define SINC_CPU_RD_ERR_UNCORR_ECC  10 //covered in non random test


 //---------------------------------
 // CPU WR
 //---------------------------------
 `define SINC_CPU_WR_ERR_CASE_NUM 2
 `define SINC_CPU_WR_ERR_ADDR_MPU_VIOLATION  0
 `define SINC_CPU_WR_ERR_WR_DURING_CACHE_ACTIVE  1

 //---------------------------------
 // AXI GLOBAL
 //---------------------------------
 `define SINC_AXI_GLOBAL_ERR_CASE_NUM                5
 `define SINC_AXI_GLOBAL_ERR_ILLEGAL_ADDR_RANGE      0
 `define SINC_AXI_GLOBAL_ERR_NON_SP                  1
 `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_TYPE  2
 `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_SIZE  3
 `define SINC_AXI_GLOBAL_ERR_UNSUPPORTED_BURST_LEN   4

 //---------------------------------
 // AXI RD
 //---------------------------------
 `define SINC_AXI_RD_ERR_CASE_NUM                            6
 `define SINC_AXI_RD_ERR_NON_SP                              0
 `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_TYPE              1
 `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE              2
 `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_LEN               3
 `define SINC_AXI_RD_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN      4
 `define SINC_AXI_RD_ERR_ILLEGAL_ADDR_RANGE                  5


 //---------------------------------
 // AXI WR REG
 //---------------------------------
 `define SINC_AXI_WR_REG_ERR_CASE_NUM 9
 `define SINC_AXI_WR_ERR_NON_SP                              0
 `define SINC_AXI_WR_ERR_DISALOWED_REG_IN_CUR_STATE          1
 `define SINC_AXI_WR_ERR_ILLEGAL_ADDR_RANGE              2
 `define SINC_AXI_WR_ERR_NON_ALIGNED_BYTE_ADDR           3
 `define SINC_AXI_WR_ERR_UNSUPPORTED_STROBE              4
 `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_TYPE              5
 `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE              6
 `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_LEN               7
 `define SINC_AXI_WR_ERR_UNSUPPORTED_BURST_SIZE_AND_LEN      8



 //---------------------------------
 // AXI WR FW
 //---------------------------------
 `define SINC_AXI_WR_FW_CMD_ERR_CASE_NUM 15
 `define SINC_AXI_WR_ERR_INVALID_CMD_FOR_STATE               0
 `define SINC_AXI_WR_ERR_CMD_SEL_W_UNKNOWN_OP                1
 `define SINC_AXI_WR_ERR_READ_ONLY_CMD_BIT                   2
 `define SINC_AXI_WR_ERR_SET_INIT_RNG_SEED_FAILURE           3
 `define SINC_AXI_WR_ERR_SET_INIT_KEY_FETCH_FAILURE          4
 `define SINC_AXI_WR_ERR_SET_INIT_AES_TEST_EN_NOT_CLEAR      5
 `define SINC_AXI_WR_ERR_START_CMD_NO_STATUS_CLEAR           6
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_NUM_INVALID   7
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_NUM_OF_BLOCKS_INVALID    8
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_BLOCK_ENCR_ADDR_INVALID  9
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_RD_SHAREDRAM_ERR         10
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_CIPHER_ERR    11
 `define SINC_AXI_WR_ERR_ENCR_BLOCK_CMD_WR_EXT_MEM_TAG_ERR       12
 `define SINC_AXI_WR_ERR_SINC_RESET_WHILE_RESET_DISABLED_ERR     13
 `define SINC_AXI_WR_ERR_SINC_REINIT_WHILE_REINIT_DISABLED_ERR   14

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


 // typedefs
 typedef bit [`SINC_AXI_WR_REG_ERR_CASE_NUM-1: 0] sinc_axi_wr_reg_err_types_t;
 */

`endif
