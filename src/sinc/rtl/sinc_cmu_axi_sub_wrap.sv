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
// File        : sinc_cmu_axi_sub_wrap.sv
// Description : CMU AXI subordinate wrapper. Instantiates AXI sub IP, transaction
//               checker, and CSR bridge for register access.

module sinc_cmu_axi_sub_wrap
import sinc_pkg::*;
#(
    parameter ENGN_PARITY_EN        = 0,                        // Enables AXI subordinate to generate and check parity on the engine interface signals
    parameter AXI_PARITY_EN         = 0,                        // Enables AXI subordinate to generate and check parity on the AXI interface signals
    parameter AXI_SUB_DFD           = 1,                        // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter AXI_SUB_CFD           = 1,                        // Control fifo depth
    parameter AXI_SUB_BLEN          = 16,                       // Maximum burst length (must be <=256)
    parameter unsigned REG_BASE_ADDR   = 32'h8000_0000,
    parameter unsigned REG_END_ADDR     = 32'h8000_0400,

    // AXI Sub/Mgr parameters
    localparam PCHKW = (`MSFT_AXI_PARITY_EN | ENGN_PARITY_EN) ? ((`MSFT_AXI_SLV_ARU_WIDTH-`MSFT_AXI_SLV_ENGNU_WIDTH) + (`MSFT_AXI_SLV_AWU_WIDTH-`MSFT_AXI_SLV_ENGNU_WIDTH) + `MSFT_AXI_SLV_WU_WIDTH + `MSFT_AXI_SLV_RU_WIDTH + `MSFT_AXI_SLV_BU_WIDTH) : (16-0), // (16-0) is (ERR_CHK_BRESPCHK - ERR_CHK_AWIDCHK_LSB)
    localparam LENW = $clog2(AXI_SUB_BLEN)
)
(
    /* clock, reset, misc */
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic 		       					clkg_override_i, 
    input logic 		       					clkg_test_mode_i,
    input logic                                 cmu_ctrl_active_cmd,
    input logic                                 aes_test_busy,
    input logic                                 sts_unread,
    output logic                                axi_sub_clock_gate_en_o,

    /* AXI Subordinate Interface */
    // Read Address channel
    input logic [`HSP_AXI_SLV_AWIDTH-1:0]       sinc_axi_sub_araddr, 
    input logic [`MSFT_AXI_SLV_ARU_WIDTH-1:0]   sinc_axi_sub_aruser,
    input logic [1:0]                     		sinc_axi_sub_arburst,
    input logic [`HSP_AXI_SLV_ID_WIDTH-1:0] 	sinc_axi_sub_arid,
    input logic [`AXI_ALEN_WIDTH-1:0]     		sinc_axi_sub_arlen,
    input logic [`HSP_AXI_LOCK_BITS-1:0]  		sinc_axi_sub_arlock,
    input logic [2:0]                     		sinc_axi_sub_arprot,
    input logic [2:0]                     		sinc_axi_sub_arsize,
    input logic                           		sinc_axi_sub_arvalid,
    output logic                          		sinc_axi_sub_arready,
    // Read Data channel
    input logic                           		sinc_axi_sub_rready,
    output logic [`HSP_AXI_SLV_DWIDTH-1:0]      sinc_axi_sub_rdata,
    output logic [`MSFT_AXI_SLV_RU_WIDTH-1:0]   sinc_axi_sub_ruser,
    output logic [`HSP_AXI_SLV_ID_WIDTH-1:0]	sinc_axi_sub_rid,
    output logic                          		sinc_axi_sub_rlast,
    output logic [1:0]                    		sinc_axi_sub_rresp,
    output logic                          		sinc_axi_sub_rvalid,
  
    // Write Address channel
    input logic [`HSP_AXI_SLV_AWIDTH-1:0]       sinc_axi_sub_awaddr,
    input logic [`MSFT_AXI_SLV_AWU_WIDTH-1:0]   sinc_axi_sub_awuser,
    input logic [1:0]                     		sinc_axi_sub_awburst,
    input logic [`HSP_AXI_SLV_ID_WIDTH-1:0]     sinc_axi_sub_awid,
    input logic [`AXI_ALEN_WIDTH-1:0]     		sinc_axi_sub_awlen,
    input logic [`HSP_AXI_LOCK_BITS-1:0]  		sinc_axi_sub_awlock,
    input logic [2:0]                     		sinc_axi_sub_awprot,
    input logic [2:0]                     		sinc_axi_sub_awsize,
    input logic                           		sinc_axi_sub_awvalid,
    output logic                          		sinc_axi_sub_awready,

    // Write Data channel
    input logic [`HSP_AXI_SLV_DWIDTH-1:0]       sinc_axi_sub_wdata,
    input logic                           		sinc_axi_sub_wlast,
    input logic [3:0]                     		sinc_axi_sub_wstrb,
    input logic                           		sinc_axi_sub_wvalid,
    output logic                          		sinc_axi_sub_wready,

    // Write Response channel
    input logic                           		sinc_axi_sub_bready,
    output logic [`MSFT_AXI_SLV_BU_WIDTH-1:0]   sinc_axi_sub_buser,
    output logic [`HSP_AXI_SLV_ID_WIDTH-1:0] 	sinc_axi_sub_bid,
    output logic [1:0]                    		sinc_axi_sub_bresp,
    output logic                          		sinc_axi_sub_bvalid,

    /* Reg basic interface */
    output logic                                csr_rd_en,
    output logic                                csr_wr_en,
    output logic [9:0]                          csr_addr,
    output logic [31:0]                         csr_wdata,
    input logic [31:0]                          csr_rdata,
    input logic                                 csr_rdy,
    input logic                                 csr_err
);
    logic [31:0]                                chk_addr_o;
    logic [1:0]                                 chk_burst_o;
    logic                                       chk_invalid_r_i;
    logic                                       chk_invalid_w_i;
    logic [LENW-1:0]                            chk_len_o;
    logic                                       chk_r_rdy_i;
    logic                                       chk_read_o;
    logic [2:0]                                 chk_size_o;
    logic [`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]       chk_user_o;
    logic                                       chk_valid_r_i;
    logic                                       chk_valid_w_i;
    logic                                       chk_w_rdy_i;
    logic                                       chk_write_o;
    logic [`HSP_AXI_SLV_WSTRB_WIDTH-1:0]        chk_wstrb_o;
    logic [31:0]                                sub_engn_addr_o;
    logic                                       unused_sub_engn_addrchk_o;
    logic                                       sub_engn_ren_o;
    logic [`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]       unused_sub_engn_user_o;
    logic                                       unused_sub_engn_userchk_o;
    logic [`HSP_AXI_SLV_DWIDTH-1:0]             sub_engn_wdata_o;
    logic [(`HSP_AXI_SLV_DWIDTH/32)-1:0]        unused_sub_engn_wdatachk_o;
    logic                                       sub_engn_wen_o;
    logic                                       unused_chk_addrchk_o;
    logic                                       unused_chk_burstchk_o;
    logic                                       unused_chk_en_o;
    logic [`HSP_AXI_SLV_ID_WIDTH-1:0]           unused_chk_id_o;
    logic                                       unused_chk_idchk_o;
    logic                                       unused_chk_last_o;
    logic                                       unused_chk_lastchk_o;
    logic                                       unused_chk_lenchk_o;
    logic [2:0]                                 unused_chk_prot_o;
    logic                                       unused_chk_protchk_o;
    logic                                       unused_chk_sizechk_o;
    logic                                       unused_chk_userchk_o;
    logic [`HSP_AXI_SLV_DWIDTH-1:0]             unused_chk_wdata_o;
    logic                                       unused_chk_wdatachk_o;
    logic                                       unused_chk_wstrbchk_o;
    logic [`HSP_AXI_SLV_ID_WIDTH-1:0]           unused_engn_id_o;
    logic                                       unused_engn_idchk_o;
    logic [`HSP_AXI_SLV_WSTRB_WIDTH-1:0]        unused_engn_wstrb_o;
    logic                                       unused_engn_wstrbchk_o;
    logic [PCHKW-1:0]                           unused_sub_err_chk_o;
    logic                                       unused_sub_err_parity;
    logic [31:0]                                unused_sub_err_r_addr_o;
    logic                                       unused_sub_err_r_parity_o;
    logic [31:0]                                unused_sub_err_w_addr_o;
    logic                                       unused_sub_err_w_parity_o;
    logic                                       unused_engn_rdatachk_i;
    logic [`MSFT_AXI_SLV_WU_WIDTH-1:0]          unused_wuser_i;
    logic                                       sub_engn_r_rdy_i;
    logic                                       sub_engn_w_rdy_i;
    logic [`HSP_AXI_SLV_DWIDTH-1:0]             sub_engn_rdata_i;
    logic                                       sub_engn_r_err_i;
    logic                                       sub_engn_w_err_i;
    logic                                       err_parity_chk_disable_i;

    
	    
	axi_sub #(
		.DFD	(AXI_SUB_DFD),
		.CFD	(AXI_SUB_CFD),
        .BLEN   (AXI_SUB_BLEN),
        .ENGN_PARITY_EN(ENGN_PARITY_EN),
        .AXI_PARITY_EN(AXI_PARITY_EN)
    ) u_axi_sub(
              // Outputs
              .awready_o                          (sinc_axi_sub_awready),
              .wready_o                           (sinc_axi_sub_wready),
              .bid_o                              (sinc_axi_sub_bid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .bresp_o                            (sinc_axi_sub_bresp[1:0]),
              .buser_o                            (sinc_axi_sub_buser[`MSFT_AXI_SLV_BU_WIDTH-1:0]),
              .bvalid_o                           (sinc_axi_sub_bvalid),
              .arready_o                          (sinc_axi_sub_arready),
              .rid_o                              (sinc_axi_sub_rid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .rdata_o                            (sinc_axi_sub_rdata[`HSP_AXI_SLV_DWIDTH-1:0]),
              .rresp_o                            (sinc_axi_sub_rresp[1:0]),
              .rlast_o                            (sinc_axi_sub_rlast),
              .ruser_o                            (sinc_axi_sub_ruser[`MSFT_AXI_SLV_RU_WIDTH-1:0]),
              .rvalid_o                           (sinc_axi_sub_rvalid),
              .engn_ren_o                         (sub_engn_ren_o),
              .engn_wen_o                         (sub_engn_wen_o),
              .engn_addr_o                        (sub_engn_addr_o[31:0]),
              .engn_wdata_o                       (sub_engn_wdata_o[`HSP_AXI_SLV_DWIDTH-1:0]),
              .engn_wstrb_o                       (unused_engn_wstrb_o[`HSP_AXI_SLV_WSTRB_WIDTH-1:0]),
              .engn_id_o                          (unused_engn_id_o[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .engn_user_o                        (unused_sub_engn_user_o[`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]),
              .engn_idchk_o                       (unused_engn_idchk_o),
              .engn_addrchk_o                     (unused_sub_engn_addrchk_o),
              .engn_wdatachk_o                    (unused_sub_engn_wdatachk_o[(`HSP_AXI_SLV_DWIDTH/32)-1:0]),
              .engn_wstrbchk_o                    (unused_engn_wstrbchk_o),
              .engn_userchk_o                     (unused_sub_engn_userchk_o),
              .chk_addr_o                         (chk_addr_o[31:0]),
              .chk_id_o                           (unused_chk_id_o[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .chk_user_o                         (chk_user_o[`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]),
              .chk_read_o                         (chk_read_o),
              .chk_write_o                        (chk_write_o),
              .chk_en_o                           (unused_chk_en_o),
              .chk_size_o                         (chk_size_o[2:0]),
              .chk_prot_o                         (unused_chk_prot_o[2:0]),
              .chk_len_o                          (chk_len_o[LENW-1:0]),
              .chk_burst_o                        (chk_burst_o[1:0]),
              .chk_wdata_o                        (unused_chk_wdata_o[`HSP_AXI_SLV_DWIDTH-1:0]),
              .chk_wstrb_o                        (chk_wstrb_o[`HSP_AXI_SLV_WSTRB_WIDTH-1:0]),
              .chk_last_o                         (unused_chk_last_o),
              .chk_idchk_o                        (unused_chk_idchk_o),
              .chk_addrchk_o                      (unused_chk_addrchk_o),
              .chk_lenchk_o                       (unused_chk_lenchk_o),
              .chk_sizechk_o                      (unused_chk_sizechk_o),
              .chk_burstchk_o                     (unused_chk_burstchk_o),
              .chk_protchk_o                      (unused_chk_protchk_o),
              .chk_wdatachk_o                     (unused_chk_wdatachk_o),
              .chk_wstrbchk_o                     (unused_chk_wstrbchk_o),
              .chk_lastchk_o                      (unused_chk_lastchk_o),
              .chk_userchk_o                      (unused_chk_userchk_o),
              .err_parity_o                       (unused_sub_err_parity),
              .err_r_parity_o                     (unused_sub_err_r_parity_o),
              .err_w_parity_o                     (unused_sub_err_w_parity_o),
              .err_r_addr_o                       (unused_sub_err_r_addr_o[31:0]),
              .err_w_addr_o                       (unused_sub_err_w_addr_o[31:0]),
              .err_chk_o                          (unused_sub_err_chk_o[PCHKW-1:0]),
              .clock_gate_en_o                    (axi_sub_clock_gate_en_o),
              // Inputs
              .clk_i                              (clk_i),
              .reset_nai                          (rstn_i),
              .awid_i                             (sinc_axi_sub_awid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .awuser_i                           (sinc_axi_sub_awuser[`MSFT_AXI_SLV_AWU_WIDTH-1:0]),
              .awaddr_i                           (sinc_axi_sub_awaddr[31:0]),
              .awlen_i                            (sinc_axi_sub_awlen[7:0]),
              .awsize_i                           (sinc_axi_sub_awsize[2:0]),
              .awprot_i                           (sinc_axi_sub_awprot[2:0]),
              .awburst_i                          (sinc_axi_sub_awburst[1:0]),
              .awlock_i                           (sinc_axi_sub_awlock[`HSP_AXI_LOCK_BITS-1:0]),
              .awvalid_i                          (sinc_axi_sub_awvalid),
              .wdata_i                            (sinc_axi_sub_wdata[`HSP_AXI_SLV_DWIDTH-1:0]),
              .wstrb_i                            (sinc_axi_sub_wstrb[`HSP_AXI_SLV_WSTRB_WIDTH-1:0]),
              .wlast_i                            (sinc_axi_sub_wlast),
              .wuser_i                            (unused_wuser_i[`MSFT_AXI_SLV_WU_WIDTH-1:0]),
              .wvalid_i                           (sinc_axi_sub_wvalid),
              .bready_i                           (sinc_axi_sub_bready),
              .arid_i                             (sinc_axi_sub_arid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
              .aruser_i                           (sinc_axi_sub_aruser[`MSFT_AXI_SLV_ARU_WIDTH-1:0]),
              .araddr_i                           (sinc_axi_sub_araddr[31:0]),
              .arlen_i                            (sinc_axi_sub_arlen[7:0]),
              .arsize_i                           (sinc_axi_sub_arsize[2:0]),
              .arprot_i                           (sinc_axi_sub_arprot[2:0]),
              .arburst_i                          (sinc_axi_sub_arburst[1:0]),
              .arlock_i                           (sinc_axi_sub_arlock[`HSP_AXI_LOCK_BITS-1:0]),
              .arvalid_i                          (sinc_axi_sub_arvalid),
              .rready_i                           (sinc_axi_sub_rready),
              .engn_r_rdy_i                       (sub_engn_r_rdy_i),
              .engn_w_rdy_i                       (sub_engn_w_rdy_i),
              .engn_rdata_i                       (sub_engn_rdata_i[`HSP_AXI_SLV_DWIDTH-1:0]),
              .engn_r_err_i                       (sub_engn_r_err_i),
              .engn_w_err_i                       (sub_engn_w_err_i),
              .engn_rdatachk_i                    (unused_engn_rdatachk_i),
              .chk_r_rdy_i                        (chk_r_rdy_i),
              .chk_w_rdy_i                        (chk_w_rdy_i),
              .chk_valid_r_i                      (chk_valid_r_i),
              .chk_invalid_r_i                    (chk_invalid_r_i),
              .chk_valid_w_i                      (chk_valid_w_i),
              .chk_invalid_w_i                    (chk_invalid_w_i),
              .clkg_test_mode_i                   (clkg_test_mode_i),
              .clkg_override_i                    (clkg_override_i),
              .err_parity_chk_disable_i           (err_parity_chk_disable_i));

    

    sinc_cmu_axi_sub_checker #(
		.REG_BASE_ADDR(REG_BASE_ADDR),
		.REG_END_ADDR(REG_END_ADDR),
		.LENW(LENW)
    ) u_axi_sub_checker (
                         // Outputs
                         .chk_r_rdy_i             (chk_r_rdy_i),
                         .chk_w_rdy_i             (chk_w_rdy_i),
                         .chk_valid_r_i           (chk_valid_r_i),
                         .chk_invalid_r_i         (chk_invalid_r_i),
                         .chk_valid_w_i           (chk_valid_w_i),
                         .chk_invalid_w_i         (chk_invalid_w_i),
                         // Inputs
                         .cmu_ctrl_active_cmd                (cmu_ctrl_active_cmd),
                         .aes_test_busy           (aes_test_busy),
                         .sts_unread              (sts_unread),
                         .chk_addr_o              (chk_addr_o[`HSP_AXI_SLV_AWIDTH-1:0]),
                         .chk_user_o              (chk_user_o[`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]),
                         .chk_read_o              (chk_read_o),
                         .chk_write_o             (chk_write_o),
                         .chk_size_o              (chk_size_o[2:0]),
                         .chk_len_o               (chk_len_o[LENW-1:0]),
                         .chk_burst_o             (chk_burst_o[1:0]),
                         .chk_wstrb_o             (chk_wstrb_o[3:0]));

    assign err_parity_chk_disable_i = 1'h0;
    assign unused_engn_rdatachk_i   = 1'h0;
    assign unused_wuser_i           = {`MSFT_AXI_SLV_WU_WIDTH{1'h0}};

    assign csr_rd_en                = sub_engn_ren_o;               // okay because CSR resp always comes on the same cycle
    assign csr_wr_en                = sub_engn_wen_o;
    assign csr_addr                 = sub_engn_addr_o - REG_BASE_ADDR;
    assign csr_wdata                = sub_engn_wdata_o;
    assign sub_engn_rdata_i         = csr_rdata;
    assign sub_engn_r_rdy_i         = csr_rdy & sub_engn_ren_o;
    assign sub_engn_w_rdy_i         = csr_rdy & sub_engn_wen_o;
    assign sub_engn_r_err_i         = csr_err;
    assign sub_engn_w_err_i         = csr_err;

endmodule

