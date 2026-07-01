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
// File        : gp_aes_pkg.sv
// Description : GP AES package file for defining enums.

package gp_aes_pkg;

    `include "hsp_axi.vh"
    `include "hsp_subsystem_defines.vh"
    `include "mem_defines.vh"
    `include "aes.vh"


    // Main FSM states in GP AES mode
    typedef enum logic [6:0]
    {
        MODE_IDLE           = 7'h00,
        MODE_CFG            = 7'h07,
        MODE_IV             = 7'h19,
        MODE_KEY            = 7'h1E,
        MODE_WAIT_DRBG      = 7'h2A,
        MODE_HASH_SUBKEY    = 7'h2D,
        MODE_AAD            = 7'h33,
        MODE_DATA           = 7'h34,
        MODE_TAG            = 7'h4B,
        MODE_ERR            = 7'h4C
        // HALT        = 7'h4C
    } mode_main_fsm_t;      // Implementing minimum hamming distance of 3 between FSM states

    // GHASH FSM states in GP AES mode
    typedef enum logic [5:0]
    {
        MODE_GHASH_IDLE         = 6'h00,
        MODE_GHASH_AAD          = 6'h07,
        MODE_GHASH_ENC          = 6'h19,
        MODE_GHASH_DEC          = 6'h1E,
        MODE_GHASH_LAST         = 6'h2A
    } mode_ghash_fsm_t;     // Implementing minimum hamming distance of 3 between FSM states

    // Substates in GP AES Mode
    typedef enum logic [4:0]
    {
        AES_SUB_STATE_1         = 5'h00,
        AES_SUB_STATE_2         = 5'h07,
        AES_SUB_STATE_3         = 5'h19,
        AES_SUB_STATE_4         = 5'h1E
    } sub_state_fsm_t;     // Implementing minimum hamming distance of 3 between FSM states

    typedef enum logic [2:0]
    {
        WAIT_FOR_INPUT_DRIVE    = 3'h0,
        WAIT_FOR_INPUT_ACCEPT   = 3'h7
    } core_in_fsm_t;     // Implementing minimum hamming distance of 3 between FSM states

    // AES modes
    typedef enum logic [3:0]
    {
        AES_RSVD0       = 4'h0,
        AES_ECB         = 4'h1,
        AES_CBC         = 4'h2,
        AES_CTR         = 4'h3,
        AES_CFB         = 4'h4,
        AES_OFB         = 4'h5,
        AES_XTS         = 4'h6,
        AES_GCM         = 4'h7
    } aes_modes_t;

    // Key sizes
    typedef enum logic [1:0]
    {
        KEY_SIZE_128    = 2'h0,
        KEY_SIZE_192    = 2'h1,
        KEY_SIZE_256    = 2'h2,
        KEY_SIZE_RSVD   = 2'h3
    } key_sizes_t;

    // Mode secondary FSM
    typedef enum logic [5:0]
    {
        MODE_SEC_IDLE           = 6'h00,
        MODE_SEC_KEY0           = 6'h07,
        MODE_SEC_DATA0          = 6'h19,
        MODE_SEC_KEY1           = 6'h1E,
        MODE_SEC_DATA1          = 6'h2A
    } mode_sec_fsm_t;

    // GHASH multiplier counter
    typedef enum logic [5:0]
    {
        CNT0            = 6'h00,
        CNT1            = 6'h07,
        CNT2            = 6'h19,
        CNT3            = 6'h1E,
        CNT4            = 6'h2A,
        CNT5            = 6'h2D,
        CNT6            = 6'h33,
        CNT7            = 6'h34
    } ghash_mul_fsm_t;

    // typedef enum logic [1:0]
    // {
    // } cmd_sel_cmd_t;

endpackage: gp_aes_pkg