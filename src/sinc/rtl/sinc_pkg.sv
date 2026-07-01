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
// File        : sinc_pkg.sv
// Description : SInC package. Defines enums for state machine states, command
//               types, DMA FSM states, and status update structures.


`ifndef SINC_PKG_SV
`define SINC_PKG_SV

package sinc_pkg;

	`include "hsp_axi.vh"
	`include "sinc_regs.vh"
	`include "hsp_subsystem_defines.vh"
	`include "mem_defines.vh"

	typedef enum logic [7:0]
	{
		DISABLED            = 8'h00,
		INITIALIZATION 	    = 8'h0F,
		CACHE_ACTIVE 		= 8'hF0,
		CACHE_FAILED 	    = 8'hFF
    } sinc_state_t;     // Implementing minimum hamming distance of 3 between FSM states
		
	typedef enum logic [6:0]
	{
		SINC_IDLE 		    = 7'h00, 
        FETCH_BLOCK         = 7'h07,
		SET_INIT 	        = 7'h19, 
		SET_CACHE_ACTIVE    = 7'h1E, 
		SINC_RESET 	        = 7'h2A, 
		SINC_REINIT 	    = 7'h2D,
        ENCR_BLOCK          = 7'h33,
        DIS_RESET           = 7'h34,
        DIS_REINIT          = 7'h4B,
        AES_TEST            = 7'h4C,
        AES_SEED            = 7'h55
        /*
        61
        66
        78
        7f
        181
        186
        198
        19f */
    } sinc_cmu_ctrl_fsm_t;     // Implementing minimum hamming distance of 3 between FSM states

    typedef enum logic [9:0]
	{
        CMD_NONE            = 10'h000,
        CMD_SET_INIT        = 10'h001,
        CMD_SET_CACHE_ACT   = 10'h002,
        CMD_SINC_RESET      = 10'h004,
        CMD_SINC_REINIT     = 10'h008,
        CMD_ENCR_BLOCK      = 10'h010,
        CMD_DIS_RESET       = 10'h020,
        CMD_DIS_REINIT      = 10'h040,
        CMD_AES_TEST        = 10'h080,
        CMD_FETCH_BLOCK     = 10'h100,
        CMD_AES_SEED        = 10'h200
    } sinc_cmu_cmd_t;             // Note: fetch block is not a fw cmd
	
    // sub-states within FSM states
    typedef enum logic [5:0]
	{
		SINC_SUB_STATE_1    = 6'h00, 
		SINC_SUB_STATE_2 	= 6'h07, 
		SINC_SUB_STATE_3 	= 6'h19, 
		SINC_SUB_STATE_4 	= 6'h1E,
        SINC_SUB_STATE_5    = 6'h2A
    } sinc_sub_state_fsm_t;

    // AES data control FSM states
    typedef enum logic [6:0]
	{
		AES_IDLE            = 7'h00, 
		AES_IN              = 7'h07, 
		AES_OUT 	        = 7'h19,
		AES_TAG_OUT 	    = 7'h1E,
        AES_TEST_IN         = 7'h2A,
        AES_TEST_OUT        = 7'h2D,
        AES_TEST_TAG_OUT    = 7'h33,
        AES_BYPASS          = 7'h34
    } sinc_aes_ctrl_fsm_t;

    // DMA read FSM
    typedef enum logic [5:0]
	{
		DMA_R_IDLE          = 6'h00, 
		DMA_R_REQ           = 6'h07, 
		DMA_R_DATA 	        = 6'h19,
		DMA_R_RESP 	        = 6'h1E,
        DMA_R_FLUSH         = 6'h2A
    } sinc_dma_r_fsm_t;

    // DMA write FSM
    typedef enum logic [5:0]
	{
		DMA_W_IDLE          = 6'h00, 
		DMA_W_REQ           = 6'h07, 
		DMA_W_DATA 	        = 6'h19,
		DMA_W_RESP 	        = 6'h1E,
        DMA_W_FLUSH         = 6'h2A
    } sinc_dma_w_fsm_t;

    typedef enum logic [12:0] 
    {
        STS_NONE                = 13'h0000,
        STS_CMD_IN_PROG         = 13'h0001,
        STS_CMD_SUC             = 13'h0002,
        STS_INV_CMD             = 13'h000C,
        STS_RNG_SEED_ERR        = 13'h0014,
        STS_KEY_FET_ERR         = 13'h0024,
        STS_CAC_BLK_R_ERR       = 13'h0044,
        STS_CAC_BLK_W_ENC_BLK_ERR = 13'h0084,
        STS_CAC_BLK_W_FET_BLK_ERR = 13'h0104,
        STS_AUTH_TAG_R_ERR      = 13'h0204,
        STS_AUTH_TAG_CHK_ERR    = 13'h0404,
        STS_AUTH_TAG_W_ERR      = 13'h0804,
        STS_AES_ERR             = 13'h1004
    } sts_update_t;         // Update status reg

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

    // Definitions for CIU


    typedef enum logic [5:0] {
        CIU_IDLE        = 6'b00_0000,
        CIU_MEM_READ    = 6'b00_0111,
        CIU_WAIT        = 6'b01_1001,
        CIU_CACHE_MISS  = 6'b01_1110,
        CIU_RREAD       = 6'b10_1010,
        CIU_MEM_WRITE   = 6'b10_1101,
        CIU_EXTRA       = 6'b11_0011,
        CIU_SM_FAULT    = 6'b11_0100
        } sinc_ciu_fsm_t;

    typedef enum logic  {
  	VTAG_ERASE_IDLE       = 1'b0,
  	VTAG_ERASE_WR         = 1'b1
	} sinc_vtag_erase_fsm_t;

endpackage: sinc_pkg

`endif
