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
// File        : sinc_cmu_axi_sub_checker.sv
// Description : CMU AXI subordinate transaction checker. Validates incoming AXI
//               address, burst, size, and master ID against allowed ranges.

module sinc_cmu_axi_sub_checker
import sinc_pkg::*;
#(
    parameter unsigned REG_BASE_ADDR        = 32'h8000_0000,      // This is the REG base address
    parameter unsigned REG_END_ADDR         = 32'h8000_0400,
    // AXI Sub/Mgr parameters
    parameter LENW 							= 4
)
(

    input logic                                     aes_test_busy,
    input logic                                     cmu_ctrl_active_cmd,
    input logic                                     sts_unread,

    /* AXI sub checker interface */
    input logic [`HSP_AXI_SLV_AWIDTH-1:0]           chk_addr_o,
	input logic [`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]     chk_user_o,
	input logic 							        chk_read_o,
	input logic 							        chk_write_o,
	input logic [2:0] 						        chk_size_o,
	input logic [LENW-1:0] 		                    chk_len_o,
    input logic [1:0]                               chk_burst_o,
	input logic [3:0] 						        chk_wstrb_o,
	
	output logic 							        chk_r_rdy_i,
	output logic 							        chk_w_rdy_i,
	output logic 							        chk_valid_r_i,
	output logic 							        chk_invalid_r_i,
	output logic 							        chk_valid_w_i,
	output logic 							        chk_invalid_w_i
);

    logic [`HSP_AXI_MID_WIDTH-1:0]                  mst_id;
    logic [`HSP_AXI_SLV_AWIDTH-1:0]                 chk_addr_offset;

    always_comb begin

        chk_valid_r_i 	= 1'b0;
	    chk_invalid_r_i = 1'b1;
	    chk_valid_w_i 	= 1'b0;
	    chk_invalid_w_i = 1'b1;

        if(
            (chk_size_o == 3'h2) &
			(chk_addr_o[1:0] == 2'b0) &
            (chk_len_o == {LENW{1'h0}}) &
            (
                (chk_burst_o == `AXI_ABURST_INCR) |
                (chk_burst_o == `AXI_ABURST_FIXED)
            )
        ) begin: chk_generic_cond_block

            /* AXI read checker logic */
            if(chk_read_o) begin: chk_read_block
                if (
                    (chk_addr_o >= REG_BASE_ADDR) &
                    (chk_addr_o < REG_END_ADDR) &
                    (mst_id == `AXI_MST_ID_SP)
                ) begin: chk_reg_read_block
                    chk_valid_r_i 	= 1'b1;
                    chk_invalid_r_i = 1'b0;
                end
            end

            /* AXI write checker logic */
            /* only allow writes if cmu is not busy or busy processing AES test mode */
            else if(chk_write_o & (chk_wstrb_o == 4'hf)) begin: chk_write_block
                if (
                    (chk_addr_o >= REG_BASE_ADDR) &
                    (chk_addr_o < REG_END_ADDR) &
                    (mst_id == `AXI_MST_ID_SP) &
                    ((~cmu_ctrl_active_cmd) | aes_test_busy)
                ) begin: chk_reg_write_block
                    if(chk_addr_offset == `SINC_REGS_CMD_BYTE_OFFSET) begin     // cmd register write
                        if((~sts_unread) | aes_test_busy) begin                 // only allow if status is read or busy processing AES test mode (to exit out of it)
                            chk_valid_w_i 	= 1'b1;
                            chk_invalid_w_i = 1'b0;
                        end
                    end
                    else begin
                        chk_valid_w_i 	= 1'b1;
                        chk_invalid_w_i = 1'b0;
                    end
                end
            end
        end
    end

    assign mst_id                   = chk_user_o[`AXI_USER_MID_LOCATION];
    assign chk_addr_offset          = (chk_addr_o - REG_BASE_ADDR);
    assign chk_r_rdy_i              = 1'h1;
    assign chk_w_rdy_i              = 1'h1;

endmodule
