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
// File        : sinc_ciu_mpu_ret.sv
// Description : MPU retention wrapper under CIU. Instantiates the MPU wrapper
//               and holds power-domain-retained MPU configuration and state.
module sinc_ciu_mpu_ret
    #(

    EIRAM_SIZE = 16384,							// in KB
    ADDR_WIDTH = $clog2(EIRAM_SIZE) + 8,        // $clog2(EIRAM_SIZE) + 8: aligned to 4 Bytes
    NUM_PAGES = (EIRAM_SIZE / 4),
    ATTRIB_RESET = 4'b0111,
    ATTRIB_WMASK = 4'b1111,
    MPU_REG_ADDR_WIDTH = ((EIRAM_SIZE*1024) > (1024*1024)) ? 13 : 9,
    MPU_REG_DATA_WIDTH = 32,
    CRYPTOS_ACC = 0,
    MPU_SINGLE_CYCLE = 0                        // default: MPU violation indicator available at next cycle
    ) (

    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input						                clk,
    input 	       				                rstn,
    input                                       soft_rst,
    input						                clkg_override,
    input						                clkg_test_mode,

    //****************************************************************
    // Global control signals (affect all pages)
    //****************************************************************
    input  	                                    mpu_disable,
    input						                priv_mode,
    input 		                                override_nx,

    //****************************************************************
    // MPU Interface with SINC CIU
    //****************************************************************
    output logic				                mpu_busy,
    output logic				                acc_vio,
    input						                ext_acc_vio,
    input						                mpu_top_page_acc_en,
    input						                req_accsrc,
    input [4 - 1 : 0]			                req_id,
    input						                req_en,
    input						                req_we,
    input						                req_xe,
    input [ADDR_WIDTH - 1 : 0]                  req_addr,

    //****************************************************************
    // MPU Interface with CREG
    //****************************************************************
    input  		             			        mpu_reg_wr,
    input [MPU_REG_ADDR_WIDTH - 1 : 0] 			mpu_reg_addr,
    input  		                                mpu_reg_rd,
    input [MPU_REG_DATA_WIDTH - 1 : 0]			mpu_reg_wdata,
    output logic [MPU_REG_DATA_WIDTH - 1 : 0]	mpu_reg_rdata,
    output logic [1:0]                          mpu_reg_resp,
    output logic                                mpu_reg_resp_vld);


mpu_wrapper #(
    .ADDR_WIDTH      (ADDR_WIDTH + 2),
    .NUM_PAGES       (NUM_PAGES),
    .CRYPTOS_ACC     (CRYPTOS_ACC),
    .ATTRIB_RESET    (ATTRIB_RESET),
    .ATTRIB_WMASK    (ATTRIB_WMASK),
    .REG_ADDR_WIDTH  (MPU_REG_ADDR_WIDTH),
    .REG_DATA_WIDTH  (MPU_REG_DATA_WIDTH),
    .SINGLE_CYCLE    (MPU_SINGLE_CYCLE)
) u_mpu_wrapper (
    //// Pervasive
    .clk                  (clk),
    .reset_na             (rstn),
    .soft_rst             (soft_rst),
    .clkg_override        (clkg_override),
    .clkg_test_mode       (clkg_test_mode),

    //// Global control signals (affect all pages)
    .priv_mode            (priv_mode),
    .mpu_disable          (mpu_disable),
    .override_nx          (override_nx),

    //// Access information
    .mpu_top_page_acc_en  (mpu_top_page_acc_en),
    .ext_acc_vio          (ext_acc_vio),
    .accsrc               (req_accsrc),
    .addr                 ({req_addr[ADDR_WIDTH - 1 : 0], 2'h0}),
    .id                   (req_id[4 - 1 : 0]),
    .en                   (req_en),
    .we                   (req_we),
    .xe                   (req_xe),

    //// Violation information
    // output
    .acc_vio              (acc_vio),
    .busy                 (mpu_busy),

    //// Register interface
    // output
    .mpu_reg_rdata        (mpu_reg_rdata[MPU_REG_DATA_WIDTH - 1 : 0]),
    .mpu_reg_resp         (mpu_reg_resp[2 - 1 : 0]),
    .mpu_reg_respvalid    (mpu_reg_resp_vld),
    // input
    .mpu_reg_addr         (mpu_reg_addr[MPU_REG_ADDR_WIDTH - 1 : 0]),
    .mpu_reg_wdata        (mpu_reg_wdata[MPU_REG_DATA_WIDTH - 1 : 0]),
    .mpu_reg_wr_en        (mpu_reg_wr),
    .mpu_reg_rd_en        (mpu_reg_rd)
);

////
//// Assertions
////

`ifdef _USE_SINC_ASSERT_
////      `include "../assert/sinc_ciu_assert.sv"
`endif
	
endmodule
