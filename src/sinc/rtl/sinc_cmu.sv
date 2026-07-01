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
// File        : sinc_cmu.sv
// Description : Cache Management Unit (CMU) top-level. Integrates AXI sub/mgr
//               wrappers, control FSM, crypto wrapper, DMA, and register control.

module sinc_cmu
import sinc_pkg::*;
#(
	/* Parameters */

    parameter bit NO_SEED_LOADING   = 1'b0,                     // 1: skip RNG seed DMA reads (AES DRBG starts already-seeded)
    parameter CACHE_SIZE            = 256,                      // IRAM Cache size in KB
    parameter BLOCK_SIZE            = 512,                      // Cache block size in B
    parameter ADDR_WIDTH            = 24,                       // Address width from CPU
    parameter ENGN_PARITY_EN        = 0,                        // Enables AXI subordinate to generate and check parity on the engine interface signals
    parameter AXI_PARITY_EN         = 0,                        // Enables AXI subordinate to generate and check parity on the AXI interface signals
    parameter AXI_SUB_DFD           = 1,                        // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter AXI_SUB_CFD           = 1,                        // Control fifo depth
    parameter AXI_SUB_BLEN          = 16,                       // Maximum burst length (must be <=256)
    parameter AXI_MGR_DFD           = 1,                        // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter AXI_MGR_BLEN          = 16,                       // Maximum burst length (must be <=256)
    parameter AXI_MGR_ANUM          = 0,
    parameter unsigned KSU_KEY_SLOT_BASE_ADDR = 32'h8F0C_4000,  // 32b KSU key slot base address
    parameter unsigned RNG_SEED_BASE_ADDR = 32'h8F0A_0200,      // 32b RNG seed base address
    parameter unsigned REG_BASE_ADDR   = 32'h8000_0000,
    parameter unsigned REG_END_ADDR     = 32'h8000_0400,
    parameter CACHE_MEM_ADDR_WIDTH  = 14,

    /* Derived parameter, don't set manually*/
    parameter BLOCK_SIZEW           = $clog2(BLOCK_SIZE),
    parameter BLOCK_LEN             = BLOCK_SIZE/4,             // Represent AXI len for a block (i.e. no. of 32b beats in a block)
    parameter BLOCK_LENW            = $clog2(BLOCK_LEN),
    parameter unsigned NUM_AES_BLOCKS = BLOCK_SIZE/16,           // Each AES block consist of 16B or 128b
    parameter NUM_SETS              = ((CACHE_SIZE * 1024) / BLOCK_SIZE) / 4,
    parameter NUM_SETSW             = $clog2(NUM_SETS)

)
(

	//****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
	input logic									clk_i,
    input logic 		       					rstn_i,
    input logic                                 lp_rstn_i,
    input logic 		       					clkg_override_i, 
    input logic 		       					clkg_test_mode_i,
    input logic                                 disable_encr_auth_check_i,
    output logic                                cmu_active,
    output logic                                sinc_done_o,
    output logic                                sinc_err_o,
    output logic                                sinc_cpu_non_active_state,

    //****************************************************************
    // AXI Manager Interface
    //****************************************************************
    // Read Address channel
    output logic [`HSP_AXI_SLV_AWIDTH-1:0]      sinc_axi_mgr_araddr, 
    output logic [`MSFT_AXI_SLV_ARU_WIDTH-1:0]  sinc_axi_mgr_aruser,
    output logic [1:0]                     		sinc_axi_mgr_arburst,
    output logic [3:0]                     		sinc_axi_mgr_arcache,
    output logic [`HSP_AXI_MST_ID_WIDTH-1:0] 	sinc_axi_mgr_arid,
    output logic [`AXI_ALEN_WIDTH-1:0]     		sinc_axi_mgr_arlen,
    output logic [`HSP_AXI_LOCK_BITS-1:0]  		sinc_axi_mgr_arlock,
    output logic [2:0]                     		sinc_axi_mgr_arprot,
    output logic [2:0]                     		sinc_axi_mgr_arsize,
    output logic                           		sinc_axi_mgr_arvalid,
    input logic                          		sinc_axi_mgr_arready,
    // Read Data channel
    output logic                           		sinc_axi_mgr_rready,
    input logic [`HSP_AXI_SLV_DWIDTH-1:0]       sinc_axi_mgr_rdata,
    input logic [`MSFT_AXI_SLV_RU_WIDTH-1:0]    sinc_axi_mgr_ruser,
    input logic [`HSP_AXI_MST_ID_WIDTH-1:0]	    sinc_axi_mgr_rid,
    input logic                          		sinc_axi_mgr_rlast,
    input logic [1:0]                    		sinc_axi_mgr_rresp,
    input logic                          		sinc_axi_mgr_rvalid,
  
    // Write Address channel
    output logic [`HSP_AXI_SLV_AWIDTH-1:0]      sinc_axi_mgr_awaddr,
    output logic [`MSFT_AXI_SLV_AWU_WIDTH-1:0]  sinc_axi_mgr_awuser,
    output logic [1:0]                     		sinc_axi_mgr_awburst,
    output logic [3:0]                     		sinc_axi_mgr_awcache,
    output logic [`HSP_AXI_MST_ID_WIDTH-1:0]    sinc_axi_mgr_awid,
    output logic [`AXI_ALEN_WIDTH-1:0]     		sinc_axi_mgr_awlen,
    output logic [`HSP_AXI_LOCK_BITS-1:0]  		sinc_axi_mgr_awlock,
    output logic [2:0]                     		sinc_axi_mgr_awprot,
    output logic [2:0]                     		sinc_axi_mgr_awsize,
    output logic                           		sinc_axi_mgr_awvalid,
    input logic                          		sinc_axi_mgr_awready,

    // Write Data channel
    output logic [`HSP_AXI_SLV_DWIDTH-1:0]      sinc_axi_mgr_wdata,
    output logic                           		sinc_axi_mgr_wlast,
    output logic [3:0]                     		sinc_axi_mgr_wstrb,
    output logic                           		sinc_axi_mgr_wvalid,
    input logic                          		sinc_axi_mgr_wready,

    // Write Response channel
    output logic                           		sinc_axi_mgr_bready,
    input logic [`MSFT_AXI_SLV_BU_WIDTH-1:0]    sinc_axi_mgr_buser,
    input logic [`HSP_AXI_MST_ID_WIDTH-1:0] 	sinc_axi_mgr_bid,
    input logic [1:0]                    		sinc_axi_mgr_bresp,
    input logic                          		sinc_axi_mgr_bvalid,

    //****************************************************************
    // AXI Subordinate Interface
    //****************************************************************
    // Read Address channel
    input logic [`HSP_AXI_SLV_AWIDTH-1:0]       sinc_axi_sub_araddr, 
    input logic [`MSFT_AXI_SLV_ARU_WIDTH-1:0]   sinc_axi_sub_aruser,
    input logic [1:0]                     		sinc_axi_sub_arburst,
    input logic [3:0]                     		sinc_axi_sub_arcache,
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
    input logic [3:0]                     		sinc_axi_sub_awcache,
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

    //****************************************************************
    // Memory Erase Interface
    //****************************************************************
    input logic 				                sinc_erase_busy_o,
    input logic                                 sinc_erase_done_o,

    //****************************************************************
    // CIU Interface
    //****************************************************************
    input logic                                 ciu_block_fetch_req,
    input logic [ADDR_WIDTH-1:0]                ciu_addr,
    input logic                                 ciu_cache_hit,
    input logic                                 ciu_reset_reinit_completed,
    input logic                                 ciu_mem_busy,
    input logic                                 ciu_fault_err,

    output logic                                cmu_block_fetch_comp,
    output logic                                cmu_block_fetch_err,
    output logic                                cmu_busy,
    output sinc_state_t                         cmu_sinc_state,
    output logic                                cmu_sinc_reset,
    output logic                                cmu_sinc_reinit,
    output logic [CACHE_MEM_ADDR_WIDTH-1:0]     cmu_mem_addr,
    output logic 		             			cmu_mem_wr,
    output logic [31:0]                         cmu_mem_wdata
	);

    localparam PCHKW =(`MSFT_AXI_PARITY_EN | ENGN_PARITY_EN) ? ((`MSFT_AXI_SLV_ARU_WIDTH-`MSFT_AXI_SLV_ENGNU_WIDTH) + (`MSFT_AXI_SLV_AWU_WIDTH-`MSFT_AXI_SLV_ENGNU_WIDTH) + `MSFT_AXI_SLV_WU_WIDTH + `MSFT_AXI_SLV_RU_WIDTH + `MSFT_AXI_SLV_BU_WIDTH) : (16-0);

    logic [95:0]        aes_iv_nonce;
    logic               aes_seeded;
    logic               aes_test_busy;
    logic [17:0]        aes_test_ctrl;
    logic [127:0]       aes_test_din;
    logic [127:0]       aes_test_dout;
    logic               aes_test_sts_cfg_key_iv_rdy;
    logic               aes_test_sts_din_rdy;
    logic               aes_test_sts_tag_out;
    logic               axi_sub_clock_gate_en_o;
    logic [31:0]        block_encr_addr;
    logic [15:0]        block_encr_key;
    logic [23:0]        block_encr_num;
    logic               c_wrap_cmd_comp;
    logic               c_wrap_cmd_err;
    logic [31:0]        c_wrap_dma_caddr;
    logic [BLOCK_LENW-1:0] c_wrap_dma_clen;
    logic               c_wrap_dma_cread;
    logic               c_wrap_dma_cwrite;
    logic               c_wrap_dma_w_vld;
    logic [31:0]        c_wrap_dma_wdata;
    logic               c_wrap_fault_err;
    logic               c_wrap_sts_upd;
    logic               clr_aes_test_din_vld;
    logic               clr_cfg_key_iv_vld;
    logic               cmu_ctrl_active_cmd;
    logic               cmu_ctrl_cmd_vld;
    logic [23:0]        cmu_ctrl_fetch_block_num;
    logic               cmu_ctrl_fw_cmd_done;
    logic               cmu_ctrl_sts_upd;
    logic               csr_err;
    logic               csr_rd_en;
    logic [31:0]        csr_rdata;
    logic               csr_rdy;
    logic               csr_wr_en;
    logic               dma_c_wrap_cr_comp;
    logic               dma_c_wrap_cr_err;
    logic               dma_c_wrap_craccept;
    logic               dma_c_wrap_cw_comp;
    logic               dma_c_wrap_cw_err;
    logic               dma_c_wrap_cwaccept;
    logic               dma_c_wrap_r_vld;
    logic [31:0]        dma_c_wrap_rdata;
    logic               dma_c_wrap_w_accept;
    logic               dma_fault_err;
    logic [11:0]        encr_block_sts;
    logic               encr_block_sts_upd;
    logic [31:0]        ext_auth_tag_base_addr;
    logic [31:0]        ext_block_base_addr;
    logic               mgr_engn_craccept_o;
    logic [3:0]         mgr_engn_crresp_o;
    logic               mgr_engn_crvalid_o;
    logic               mgr_engn_cwaccept_o;
    logic [3:0]         mgr_engn_cwresp_o;
    logic               mgr_engn_cwvalid_o;
    logic [`HSP_AXI_MST_DWIDTH-1:0] mgr_engn_rdata_o;
    logic               mgr_engn_rvalid_o;
    logic               mgr_engn_waccept_o;
    logic [11:0]        num_of_blocks;
    logic               reg_ctrl_active;
    logic               reg_ctrl_cmd_vld;
    logic               reg_ctrl_invld_cmd_err;
    logic               set_aes_test_sts_dout_vld;
    logic               set_sinc_reinit_dis;
    logic               set_sinc_reset_dis;
    logic               severe_err;
    logic [3:0]         sinc_axi_mgr_arqos_unused;
    logic [3:0]         sinc_axi_mgr_arregion_unused;
    logic [3:0]         sinc_axi_mgr_awqos_unused;
    logic [3:0]         sinc_axi_mgr_awregion_unused;
    logic               sinc_fault_err_pulse;
    logic               sinc_reinit_dis;
    logic               sinc_reset_dis;
    logic               stop_dma_txn;
    logic               sts_unread;
    logic               unused_mgr_engn_rdatachk_o;
    logic [PCHKW-1:0]   unused_mgr_err_chk_o;
    logic               unused_mgr_err_parity;
    logic [31:0]        unused_mgr_err_r_addr_o;
    logic               unused_mgr_err_r_parity_o;
    logic [31:0]        unused_mgr_err_w_addr_o;
    logic               unused_mgr_err_w_parity_o;
    logic [`MSFT_AXI_MST_WU_WIDTH-1:0] unused_sinc_axi_mgr_wuser;

    sinc_state_t state;
    sts_update_t c_wrap_sts;
    sts_update_t cmu_ctrl_sts;
    sinc_cmu_cmd_t cmu_ctrl_cmd;
    sinc_cmu_cmd_t reg_ctrl_cmd;

    logic                       mgr_engn_cread_i;
    logic                       mgr_engn_cwrite_i;
    logic                       mgr_engn_crstop_i;
    logic [31:0]                mgr_engn_craddr_i;
    logic [31:0]                mgr_engn_crlen_i;
    logic [`HSP_AXI_MST_ID_WIDTH-1:0]         mgr_engn_crid_i;
    logic [`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]          mgr_engn_cruser_i;
    logic [2:0]                 mgr_engn_crprot_i;
    logic                       mgr_engn_cwstop_i;
    logic [31:0]                mgr_engn_cwaddr_i;
    logic [31:0]                mgr_engn_cwlen_i;
    logic [`HSP_AXI_MST_ID_WIDTH-1:0]         mgr_engn_cwid_i;
    logic [`MSFT_AXI_SLV_ENGNU_WIDTH-1:0]          mgr_engn_cwuser_i;
    logic [2:0]                 mgr_engn_cwprot_i;
    logic                       mgr_engn_raccept_i;
    logic [`HSP_AXI_SLV_DWIDTH-1:0]              mgr_engn_wdata_i;
    logic                       mgr_engn_wvalid_i;
    logic                       unused_mgr_engn_aridchk_i;
    logic                       unused_mgr_engn_araddrchk_i;
    logic                       unused_mgr_engn_arlenchk_i;
    logic                       unused_mgr_engn_arprotchk_i;
    logic                       unused_mgr_engn_aruserchk_i;
    logic                       unused_mgr_engn_awidchk_i;
    logic                       unused_mgr_engn_awaddrchk_i;
    logic                       unused_mgr_engn_awlenchk_i;
    logic                       unused_mgr_engn_awprotchk_i;
    logic                       unused_mgr_engn_awuserchk_i;
    logic                       unused_mgr_engn_wdatachk_i;
    logic [3:0]                 sinc_axi_sub_arcache_unused;
    logic [3:0]                 sinc_axi_sub_awcache_unused;

    logic                       sub_engn_r_rdy_i;
    logic                       sub_engn_w_rdy_i;
    logic [`HSP_AXI_SLV_DWIDTH-1:0]              sub_engn_rdata_i;
    logic                       sub_engn_r_err_i;
    logic                       sub_engn_w_err_i;
    logic                       chk_r_rdy_i;
    logic                       chk_w_rdy_i;
    logic                       chk_valid_r_i;
    logic                       chk_invalid_r_i;
    logic                       chk_valid_w_i;
    logic                       chk_invalid_w_i;

    logic                       wr_en;    
    logic                       rd_en;   
    logic [9:0]                 csr_addr;
    logic [31:0]                csr_wdata;
    logic                       status_sinc_reinit_disabled;
    logic                       status_sinc_reset_disabled;
    logic                       status_state_load_enable;
    logic [7:0]                 status_state_input;
    logic                       status_cmd_status_load_enable;
    logic [3:0]                 status_cmd_status_input;
    logic                       aes_test_ctrl_data_out_ack_load_enable;
    logic                       aes_test_ctrl_data_out_ack_input;
    logic                       aes_test_ctrl_data_in_valid_load_enable;
    logic                       aes_test_ctrl_data_in_valid_input;
    logic                       aes_test_ctrl_set_key_and_iv_load_enable;
    logic                       aes_test_ctrl_set_key_and_iv_input;
    logic                       aes_test_ctrl_test_en_load_enable;
    logic                       aes_test_ctrl_test_en_input;
    logic                       intsts_err_state_load_enable;
    logic                       intsts_err_state_input;
    logic                       err_parity_chk_disable_i;
    logic                       gclk;
    logic                       clk_ig_enable, clr_aes_test_sts_dout_vld;


    sinc_cmu_axi_sub_wrap #(
        .ENGN_PARITY_EN       (ENGN_PARITY_EN),
        .AXI_PARITY_EN        (AXI_PARITY_EN),
        .AXI_SUB_DFD          (AXI_SUB_DFD),
        .AXI_SUB_CFD          (AXI_SUB_CFD),
        .AXI_SUB_BLEN         (AXI_SUB_BLEN),
        .REG_BASE_ADDR        (REG_BASE_ADDR),
        .REG_END_ADDR         (REG_END_ADDR)
    ) u_axi_sub_wrap (
        // Outputs
        .axi_sub_clock_gate_en_o(axi_sub_clock_gate_en_o),
        .sinc_axi_sub_arready (sinc_axi_sub_arready),
        .sinc_axi_sub_rdata   (sinc_axi_sub_rdata[`HSP_AXI_SLV_DWIDTH-1:0]),
        .sinc_axi_sub_ruser   (sinc_axi_sub_ruser[`MSFT_AXI_SLV_RU_WIDTH-1:0]),
        .sinc_axi_sub_rid     (sinc_axi_sub_rid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
        .sinc_axi_sub_rlast   (sinc_axi_sub_rlast),
        .sinc_axi_sub_rresp   (sinc_axi_sub_rresp[1:0]),
        .sinc_axi_sub_rvalid  (sinc_axi_sub_rvalid),
        .sinc_axi_sub_awready (sinc_axi_sub_awready),
        .sinc_axi_sub_wready  (sinc_axi_sub_wready),
        .sinc_axi_sub_buser   (sinc_axi_sub_buser[`MSFT_AXI_SLV_BU_WIDTH-1:0]),
        .sinc_axi_sub_bid     (sinc_axi_sub_bid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
        .sinc_axi_sub_bresp   (sinc_axi_sub_bresp[1:0]),
        .sinc_axi_sub_bvalid  (sinc_axi_sub_bvalid),
        .csr_rd_en            (csr_rd_en),
        .csr_wr_en            (csr_wr_en),
        .csr_addr             (csr_addr[9:0]),
        .csr_wdata            (csr_wdata[31:0]),
        // Inputs
        .clk_i                (clk_i),
        .rstn_i               (lp_rstn_i),   
        .clkg_override_i      (clkg_override_i),
        .clkg_test_mode_i     (clkg_test_mode_i),
        .cmu_ctrl_active_cmd  (cmu_ctrl_active_cmd),
        .aes_test_busy        (aes_test_busy),
        .sts_unread           (sts_unread),
        .sinc_axi_sub_araddr  (sinc_axi_sub_araddr[`HSP_AXI_SLV_AWIDTH-1:0]),
        .sinc_axi_sub_aruser  (sinc_axi_sub_aruser[`MSFT_AXI_SLV_ARU_WIDTH-1:0]),
        .sinc_axi_sub_arburst (sinc_axi_sub_arburst[1:0]),
        .sinc_axi_sub_arid    (sinc_axi_sub_arid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
        .sinc_axi_sub_arlen   (sinc_axi_sub_arlen[`AXI_ALEN_WIDTH-1:0]),
        .sinc_axi_sub_arlock  (sinc_axi_sub_arlock[`HSP_AXI_LOCK_BITS-1:0]),
        .sinc_axi_sub_arprot  (sinc_axi_sub_arprot[2:0]),
        .sinc_axi_sub_arsize  (sinc_axi_sub_arsize[2:0]),
        .sinc_axi_sub_arvalid (sinc_axi_sub_arvalid),
        .sinc_axi_sub_rready  (sinc_axi_sub_rready),
        .sinc_axi_sub_awaddr  (sinc_axi_sub_awaddr[`HSP_AXI_SLV_AWIDTH-1:0]),
        .sinc_axi_sub_awuser  (sinc_axi_sub_awuser[`MSFT_AXI_SLV_AWU_WIDTH-1:0]),
        .sinc_axi_sub_awburst (sinc_axi_sub_awburst[1:0]),
        .sinc_axi_sub_awid    (sinc_axi_sub_awid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
        .sinc_axi_sub_awlen   (sinc_axi_sub_awlen[`AXI_ALEN_WIDTH-1:0]),
        .sinc_axi_sub_awlock  (sinc_axi_sub_awlock[`HSP_AXI_LOCK_BITS-1:0]),
        .sinc_axi_sub_awprot  (sinc_axi_sub_awprot[2:0]),
        .sinc_axi_sub_awsize  (sinc_axi_sub_awsize[2:0]),
        .sinc_axi_sub_awvalid (sinc_axi_sub_awvalid),
        .sinc_axi_sub_wdata   (sinc_axi_sub_wdata[`HSP_AXI_SLV_DWIDTH-1:0]),
        .sinc_axi_sub_wlast   (sinc_axi_sub_wlast),
        .sinc_axi_sub_wstrb   (sinc_axi_sub_wstrb[3:0]),
        .sinc_axi_sub_wvalid  (sinc_axi_sub_wvalid),
        .sinc_axi_sub_bready  (sinc_axi_sub_bready),
        .csr_rdata            (csr_rdata[31:0]),
        .csr_rdy              (csr_rdy),
        .csr_err              (csr_err));


    sinc_cmu_reg_ctrl u_reg_ctrl (
        .reg_ctrl_cmd                  (reg_ctrl_cmd),
        .cmu_sinc_state                (cmu_sinc_state),
        .cmu_ctrl_sts                  (cmu_ctrl_sts),

        // Outputs
        .reg_ctrl_active               (reg_ctrl_active),
        .csr_rdata                     (csr_rdata[31:0]),
        .csr_rdy                       (csr_rdy),
        .csr_err                       (csr_err),
        .reg_ctrl_cmd_vld              (reg_ctrl_cmd_vld),
        .sinc_reset_dis                (sinc_reset_dis),
        .sinc_reinit_dis               (sinc_reinit_dis),
        .reg_ctrl_invld_cmd_err        (reg_ctrl_invld_cmd_err),
        .block_encr_num                (block_encr_num[23:0]),
        .num_of_blocks                 (num_of_blocks[11:0]),
        .block_encr_addr               (block_encr_addr[31:0]),
        .block_encr_key                (block_encr_key[15:0]),
        .aes_iv_nonce                  (aes_iv_nonce[95:0]),
        .ext_block_base_addr           (ext_block_base_addr[31:0]),
        .ext_auth_tag_base_addr        (ext_auth_tag_base_addr[31:0]),
        .aes_test_din                  (aes_test_din[127:0]),
        .aes_test_ctrl                 (aes_test_ctrl[17:0]),
        .sts_unread                    (sts_unread),

        // Inputs
        .clk_i                         (clk_i),
        .rstn_i                        (rstn_i),
        .lp_rstn_i                     (lp_rstn_i),
        .ciu_cache_hit                 (ciu_cache_hit),
        .ciu_block_fetch_req           (ciu_block_fetch_req),
        .cmu_block_fetch_comp          (cmu_block_fetch_comp),
        .csr_rd_en                     (csr_rd_en),
        .csr_wr_en                     (csr_wr_en),
        .csr_addr                      (csr_addr[9:0]),
        .csr_wdata                     (csr_wdata[31:0]),
        .cmu_ctrl_sts_upd              (cmu_ctrl_sts_upd),
        .set_sinc_reset_dis            (set_sinc_reset_dis),
        .set_sinc_reinit_dis           (set_sinc_reinit_dis),
        .cmu_ctrl_fw_cmd_done          (cmu_ctrl_fw_cmd_done),
        .cmu_ctrl_active_cmd           (cmu_ctrl_active_cmd),
        .aes_test_busy                 (aes_test_busy),
        .sinc_fault_err_pulse          (sinc_fault_err_pulse),
        .severe_err                    (severe_err),
        .aes_test_dout                 (aes_test_dout[127:0]),
        .aes_test_sts_tag_out          (aes_test_sts_tag_out),
        .set_aes_test_sts_dout_vld     (set_aes_test_sts_dout_vld),
        .clr_aes_test_sts_dout_vld     (clr_aes_test_sts_dout_vld),
        .aes_test_sts_din_rdy          (aes_test_sts_din_rdy),
        .aes_test_sts_cfg_key_iv_rdy   (aes_test_sts_cfg_key_iv_rdy),
        .clr_cfg_key_iv_vld            (clr_cfg_key_iv_vld),
        .clr_aes_test_din_vld          (clr_aes_test_din_vld),
        .encr_block_sts_upd            (encr_block_sts_upd),
        .encr_block_sts                (encr_block_sts[11:0])
    );
    

    sinc_cmu_ctrl #(
        .BLOCK_SIZE  (BLOCK_SIZE),
        .ADDR_WIDTH  (ADDR_WIDTH)
    ) u_cmu_ctrl (
        .reg_ctrl_cmd                  (reg_ctrl_cmd),
        .cmu_ctrl_sts                  (cmu_ctrl_sts),
        .cmu_sinc_state                (cmu_sinc_state),
        .cmu_ctrl_cmd                  (cmu_ctrl_cmd),
        .c_wrap_sts                    (c_wrap_sts),

        // Outputs
        .aes_test_busy                 (aes_test_busy),
        .cmu_ctrl_active_cmd           (cmu_ctrl_active_cmd),
        .cmu_active                    (cmu_active),
        .sinc_done_o                   (sinc_done_o),
        .sinc_err_o                    (sinc_err_o),
        .sinc_fault_err_pulse          (sinc_fault_err_pulse),
        .severe_err                    (severe_err),
        .sinc_cpu_non_active_state     (sinc_cpu_non_active_state),
        .cmu_ctrl_sts_upd              (cmu_ctrl_sts_upd),
        .set_sinc_reset_dis            (set_sinc_reset_dis),
        .set_sinc_reinit_dis           (set_sinc_reinit_dis),
        .cmu_ctrl_fw_cmd_done          (cmu_ctrl_fw_cmd_done),
        .cmu_block_fetch_comp          (cmu_block_fetch_comp),
        .cmu_block_fetch_err           (cmu_block_fetch_err),
        .cmu_sinc_reset                (cmu_sinc_reset),
        .cmu_sinc_reinit               (cmu_sinc_reinit),
        .cmu_busy                      (cmu_busy),
        .cmu_ctrl_cmd_vld              (cmu_ctrl_cmd_vld),
        .cmu_ctrl_fetch_block_num      (cmu_ctrl_fetch_block_num[23:0]),

        // Inputs
        .clk_i                         (clk_i),
        .rstn_i                        (rstn_i),
        .lp_rstn_i                     (lp_rstn_i),
        .ciu_fault_err                 (ciu_fault_err),
        .axi_sub_clock_gate_en_o       (axi_sub_clock_gate_en_o),
        .reg_ctrl_cmd_vld              (reg_ctrl_cmd_vld),
        .sinc_reset_dis                (sinc_reset_dis),
        .sinc_reinit_dis               (sinc_reinit_dis),
        .reg_ctrl_invld_cmd_err        (reg_ctrl_invld_cmd_err),
        .reg_ctrl_active               (reg_ctrl_active),
        .ciu_block_fetch_req           (ciu_block_fetch_req),
        .ciu_addr                      (ciu_addr[ADDR_WIDTH-1:0]),
        .ciu_reset_reinit_completed    (ciu_reset_reinit_completed),
        .aes_seeded                    (aes_seeded),
        .c_wrap_sts_upd                (c_wrap_sts_upd),
        .c_wrap_cmd_comp               (c_wrap_cmd_comp),
        .c_wrap_cmd_err                (c_wrap_cmd_err),
        .c_wrap_fault_err              (c_wrap_fault_err),
        .dma_fault_err                 (dma_fault_err),
        .sinc_erase_done_o             (sinc_erase_done_o)
    );

    sinc_cmu_crypto_wrap #(
        .NO_SEED_LOADING        (NO_SEED_LOADING),
        .BLOCK_SIZE             (BLOCK_SIZE),
        .CACHE_MEM_ADDR_WIDTH   (CACHE_MEM_ADDR_WIDTH),
        .CACHE_SIZE             (CACHE_SIZE),
        .KSU_KEY_SLOT_BASE_ADDR (KSU_KEY_SLOT_BASE_ADDR),
        .RNG_SEED_BASE_ADDR     (RNG_SEED_BASE_ADDR),
        .BLOCK_SIZEW            (BLOCK_SIZEW),
        .BLOCK_LEN              (BLOCK_LEN),
        .BLOCK_LENW             (BLOCK_LENW),
        .NUM_AES_BLOCKS         (NUM_AES_BLOCKS),
        .NUM_SETS               (NUM_SETS),
        .NUM_SETSW              (NUM_SETSW)
    ) u_crypto_wrap (
        .cmu_ctrl_cmd                  (cmu_ctrl_cmd),
        .c_wrap_sts                    (c_wrap_sts),

        // Outputs
        .aes_seeded                    (aes_seeded),
        .c_wrap_cmd_comp               (c_wrap_cmd_comp),
        .c_wrap_cmd_err                (c_wrap_cmd_err),
        .c_wrap_sts_upd                (c_wrap_sts_upd),
        .c_wrap_fault_err              (c_wrap_fault_err),
        .cmu_mem_wr                    (cmu_mem_wr),
        .cmu_mem_addr                  (cmu_mem_addr[CACHE_MEM_ADDR_WIDTH-1:0]),
        .cmu_mem_wdata                 (cmu_mem_wdata[31:0]),
        .c_wrap_dma_cread              (c_wrap_dma_cread),
        .c_wrap_dma_cwrite             (c_wrap_dma_cwrite),
        .c_wrap_dma_caddr              (c_wrap_dma_caddr[31:0]),
        .c_wrap_dma_clen               (c_wrap_dma_clen[BLOCK_LENW-1:0]),
        .stop_dma_txn                  (stop_dma_txn),
        .c_wrap_dma_wdata              (c_wrap_dma_wdata[31:0]),
        .c_wrap_dma_w_vld              (c_wrap_dma_w_vld),
        .aes_test_dout                 (aes_test_dout[127:0]),
        .aes_test_sts_tag_out          (aes_test_sts_tag_out),
        .set_aes_test_sts_dout_vld     (set_aes_test_sts_dout_vld),
        .clr_aes_test_sts_dout_vld     (clr_aes_test_sts_dout_vld),
        .aes_test_sts_din_rdy          (aes_test_sts_din_rdy),
        .aes_test_sts_cfg_key_iv_rdy   (aes_test_sts_cfg_key_iv_rdy),
        .clr_cfg_key_iv_vld            (clr_cfg_key_iv_vld),
        .clr_aes_test_din_vld          (clr_aes_test_din_vld),
        .encr_block_sts_upd            (encr_block_sts_upd),
        .encr_block_sts                (encr_block_sts[11:0]),

        // Inputs
        .clk_i                         (clk_i),
        .gclk                          (gclk),
        .rstn_i                        (rstn_i),
        .lp_rstn_i                     (lp_rstn_i),
        .clkg_test_mode_i              (clkg_test_mode_i),
        .clkg_override_i               (clkg_override_i),
        .sinc_erase_busy_o             (sinc_erase_busy_o),
        .disable_encr_auth_check_i     (disable_encr_auth_check_i),
        .cmu_ctrl_cmd_vld              (cmu_ctrl_cmd_vld),
        .cmu_ctrl_fetch_block_num      (cmu_ctrl_fetch_block_num[23:0]),
        .severe_err                    (severe_err),
        .ciu_mem_busy                  (ciu_mem_busy),
        .dma_c_wrap_craccept           (dma_c_wrap_craccept),
        .dma_c_wrap_cwaccept           (dma_c_wrap_cwaccept),
        .dma_c_wrap_w_accept           (dma_c_wrap_w_accept),
        .dma_c_wrap_cw_comp            (dma_c_wrap_cw_comp),
        .dma_c_wrap_cw_err             (dma_c_wrap_cw_err),
        .dma_c_wrap_rdata              (dma_c_wrap_rdata[31:0]),
        .dma_c_wrap_r_vld              (dma_c_wrap_r_vld),
        .dma_c_wrap_cr_comp            (dma_c_wrap_cr_comp),
        .dma_c_wrap_cr_err             (dma_c_wrap_cr_err),
        .block_encr_num                (block_encr_num[23:0]),
        .num_of_blocks                 (num_of_blocks[11:0]),
        .block_encr_addr               (block_encr_addr[31:0]),
        .block_encr_key                (block_encr_key[15:0]),
        .aes_iv_nonce                  (aes_iv_nonce[95:0]),
        .ext_block_base_addr           (ext_block_base_addr[31:0]),
        .ext_auth_tag_base_addr        (ext_auth_tag_base_addr[31:0]),
        .aes_test_din                  (aes_test_din[127:0]),
        .aes_test_ctrl                 (aes_test_ctrl[17:0])
    );


    

    sinc_cmu_dma #(
        .BLOCK_LENW  (BLOCK_LENW)
    ) u_dma (
        // Outputs
        .dma_fault_err          (dma_fault_err),
        .dma_c_wrap_craccept    (dma_c_wrap_craccept),
        .dma_c_wrap_cwaccept    (dma_c_wrap_cwaccept),
        .dma_c_wrap_w_accept    (dma_c_wrap_w_accept),
        .dma_c_wrap_cw_comp     (dma_c_wrap_cw_comp),
        .dma_c_wrap_cw_err      (dma_c_wrap_cw_err),
        .dma_c_wrap_rdata       (dma_c_wrap_rdata[31:0]),
        .dma_c_wrap_r_vld       (dma_c_wrap_r_vld),
        .dma_c_wrap_cr_comp     (dma_c_wrap_cr_comp),
        .dma_c_wrap_cr_err      (dma_c_wrap_cr_err),
        .mgr_engn_cread_i       (mgr_engn_cread_i),
        .mgr_engn_crstop_i      (mgr_engn_crstop_i),
        .mgr_engn_craddr_i      (mgr_engn_craddr_i[31:0]),
        .mgr_engn_crlen_i       (mgr_engn_crlen_i[31:0]),
        .mgr_engn_crid_i        (mgr_engn_crid_i[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .mgr_engn_cruser_i      (mgr_engn_cruser_i[`MSFT_AXI_MST_ENGNU_WIDTH-1:0]),
        .mgr_engn_crprot_i      (mgr_engn_crprot_i[2:0]),
        .mgr_engn_raccept_i     (mgr_engn_raccept_i),
        .mgr_engn_cwrite_i      (mgr_engn_cwrite_i),
        .mgr_engn_cwstop_i      (mgr_engn_cwstop_i),
        .mgr_engn_cwaddr_i      (mgr_engn_cwaddr_i[31:0]),
        .mgr_engn_cwlen_i       (mgr_engn_cwlen_i[31:0]),
        .mgr_engn_cwid_i        (mgr_engn_cwid_i[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .mgr_engn_cwuser_i      (mgr_engn_cwuser_i[`MSFT_AXI_MST_ENGNU_WIDTH-1:0]),
        .mgr_engn_cwprot_i      (mgr_engn_cwprot_i[2:0]),
        .mgr_engn_wdata_i       (mgr_engn_wdata_i[`HSP_AXI_MST_DWIDTH-1:0]),
        .mgr_engn_wvalid_i      (mgr_engn_wvalid_i),

        // Inputs
        .clk_i                  (clk_i),
        .rstn_i                 (lp_rstn_i),
        .severe_err             (severe_err),
        .c_wrap_dma_cread       (c_wrap_dma_cread),
        .c_wrap_dma_cwrite      (c_wrap_dma_cwrite),
        .c_wrap_dma_caddr       (c_wrap_dma_caddr[31:0]),
        .c_wrap_dma_clen        (c_wrap_dma_clen[BLOCK_LENW-1:0]),
        .stop_dma_txn           (stop_dma_txn),
        .c_wrap_dma_wdata       (c_wrap_dma_wdata[31:0]),
        .c_wrap_dma_w_vld       (c_wrap_dma_w_vld),
        .mgr_engn_craccept_o    (mgr_engn_craccept_o),
        .mgr_engn_rdata_o       (mgr_engn_rdata_o[`HSP_AXI_MST_DWIDTH-1:0]),
        .mgr_engn_rvalid_o      (mgr_engn_rvalid_o),
        .mgr_engn_crvalid_o     (mgr_engn_crvalid_o),
        .mgr_engn_crresp_o      (mgr_engn_crresp_o[3:0]),
        .mgr_engn_cwaccept_o    (mgr_engn_cwaccept_o),
        .mgr_engn_cwvalid_o     (mgr_engn_cwvalid_o),
        .mgr_engn_cwresp_o      (mgr_engn_cwresp_o[3:0]),
        .mgr_engn_waccept_o     (mgr_engn_waccept_o)
    );

    axi_mgr #(
		.DFD	(AXI_MGR_DFD),
        .BLEN   (AXI_MGR_BLEN),
        .ANUM   (AXI_MGR_ANUM),
        .ENGN_PARITY_EN(ENGN_PARITY_EN),
        .AXI_PARITY_EN(AXI_PARITY_EN)
    ) u_axi_mgr (
        .awid_o                    (sinc_axi_mgr_awid[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .awuser_o                  (sinc_axi_mgr_awuser[`MSFT_AXI_MST_AWU_WIDTH-1:0]),
        .awaddr_o                  (sinc_axi_mgr_awaddr[31:0]),
        .awlen_o                   (sinc_axi_mgr_awlen[7:0]),
        .awsize_o                  (sinc_axi_mgr_awsize[2:0]),
        .awburst_o                 (sinc_axi_mgr_awburst[1:0]),
        .awcache_o                 (sinc_axi_mgr_awcache[3:0]),
        .awprot_o                  (sinc_axi_mgr_awprot[2:0]),
        .awqos_o                   (sinc_axi_mgr_awqos_unused[3:0]),
        .awregion_o                (sinc_axi_mgr_awregion_unused[3:0]),
        .awvalid_o                 (sinc_axi_mgr_awvalid),
        .wdata_o                   (sinc_axi_mgr_wdata[`HSP_AXI_MST_DWIDTH-1:0]),
        .wstrb_o                   (sinc_axi_mgr_wstrb[(`HSP_AXI_MST_DWIDTH/8)-1:0]),
        .wlast_o                   (sinc_axi_mgr_wlast),
        .wuser_o                   (unused_sinc_axi_mgr_wuser[`MSFT_AXI_MST_WU_WIDTH-1:0]),
        .wvalid_o                  (sinc_axi_mgr_wvalid),
        .bready_o                  (sinc_axi_mgr_bready),
        .arid_o                    (sinc_axi_mgr_arid[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .aruser_o                  (sinc_axi_mgr_aruser[`MSFT_AXI_MST_ARU_WIDTH-1:0]),
        .araddr_o                  (sinc_axi_mgr_araddr[31:0]),
        .arlen_o                   (sinc_axi_mgr_arlen[7:0]),
        .arsize_o                  (sinc_axi_mgr_arsize[2:0]),
        .arburst_o                 (sinc_axi_mgr_arburst[1:0]),
        .arlock_o                  (sinc_axi_mgr_arlock[`HSP_AXI_LOCK_BITS-1:0]),
        .awlock_o                  (sinc_axi_mgr_awlock[`HSP_AXI_LOCK_BITS-1:0]),
        .arcache_o                 (sinc_axi_mgr_arcache[3:0]),
        .arprot_o                  (sinc_axi_mgr_arprot[2:0]),
        .arqos_o                   (sinc_axi_mgr_arqos_unused[3:0]),
        .arregion_o                (sinc_axi_mgr_arregion_unused[3:0]),
        .arvalid_o                 (sinc_axi_mgr_arvalid),
        .rready_o                  (sinc_axi_mgr_rready),
        .engn_craccept_o           (mgr_engn_craccept_o),
        .engn_crvalid_o            (mgr_engn_crvalid_o),
        .engn_crresp_o             (mgr_engn_crresp_o[3:0]),
        .engn_cwaccept_o           (mgr_engn_cwaccept_o),
        .engn_cwvalid_o            (mgr_engn_cwvalid_o),
        .engn_cwresp_o             (mgr_engn_cwresp_o[3:0]),
        .engn_rdata_o              (mgr_engn_rdata_o[`HSP_AXI_MST_DWIDTH-1:0]),
        .engn_rvalid_o             (mgr_engn_rvalid_o),
        .engn_waccept_o            (mgr_engn_waccept_o),
        .engn_rdatachk_o           (unused_mgr_engn_rdatachk_o),
        .err_parity_o              (unused_mgr_err_parity),
        .err_r_parity_o            (unused_mgr_err_r_parity_o),
        .err_w_parity_o            (unused_mgr_err_w_parity_o),
        .err_r_addr_o              (unused_mgr_err_r_addr_o[31:0]),
        .err_w_addr_o              (unused_mgr_err_w_addr_o[31:0]),
        .err_chk_o                 (unused_mgr_err_chk_o[PCHKW-1:0]),
        
        .clk_i                     (clk_i),
        .reset_nai                 (lp_rstn_i),
        .awready_i                 (sinc_axi_mgr_awready),
        .wready_i                  (sinc_axi_mgr_wready),
        .bid_i                     (sinc_axi_mgr_bid[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .bresp_i                   (sinc_axi_mgr_bresp[1:0]),
        .buser_i                   (sinc_axi_mgr_buser[`MSFT_AXI_MST_BU_WIDTH-1:0]),
        .bvalid_i                  (sinc_axi_mgr_bvalid),
        .arready_i                 (sinc_axi_mgr_arready),
        .rid_i                     (sinc_axi_mgr_rid[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .rdata_i                   (sinc_axi_mgr_rdata[`HSP_AXI_MST_DWIDTH-1:0]),
        .rresp_i                   (sinc_axi_mgr_rresp[1:0]),
        .rlast_i                   (sinc_axi_mgr_rlast),
        .ruser_i                   (sinc_axi_mgr_ruser[`MSFT_AXI_MST_RU_WIDTH-1:0]),
        .rvalid_i                  (sinc_axi_mgr_rvalid),
        .engn_cread_i              (mgr_engn_cread_i),
        .engn_cwrite_i             (mgr_engn_cwrite_i),
        .engn_crstop_i             (mgr_engn_crstop_i),
        .engn_craddr_i             (mgr_engn_craddr_i[31:0]),
        .engn_crlen_i              (mgr_engn_crlen_i[31:0]),
        .engn_crid_i               (mgr_engn_crid_i[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .engn_cruser_i             (mgr_engn_cruser_i[`MSFT_AXI_MST_ENGNU_WIDTH-1:0]),
        .engn_crprot_i             (mgr_engn_crprot_i[2:0]),
        .engn_cwstop_i             (mgr_engn_cwstop_i),
        .engn_cwaddr_i             (mgr_engn_cwaddr_i[31:0]),
        .engn_cwlen_i              (mgr_engn_cwlen_i[31:0]),
        .engn_cwid_i               (mgr_engn_cwid_i[`HSP_AXI_MST_ID_WIDTH-1:0]),
        .engn_cwuser_i             (mgr_engn_cwuser_i[`MSFT_AXI_MST_ENGNU_WIDTH-1:0]),
        .engn_cwprot_i             (mgr_engn_cwprot_i[2:0]),
        .engn_raccept_i            (mgr_engn_raccept_i),
        .engn_wdata_i              (mgr_engn_wdata_i[`HSP_AXI_MST_DWIDTH-1:0]),
        .engn_wvalid_i             (mgr_engn_wvalid_i),
        .engn_aridchk_i            (unused_mgr_engn_aridchk_i),
        .engn_araddrchk_i          (unused_mgr_engn_araddrchk_i),
        .engn_arlenchk_i           (unused_mgr_engn_arlenchk_i),
        .engn_arprotchk_i          (unused_mgr_engn_arprotchk_i),
        .engn_aruserchk_i          (unused_mgr_engn_aruserchk_i),
        .engn_awidchk_i            (unused_mgr_engn_awidchk_i),
        .engn_awaddrchk_i          (unused_mgr_engn_awaddrchk_i),
        .engn_awlenchk_i           (unused_mgr_engn_awlenchk_i),
        .engn_awprotchk_i          (unused_mgr_engn_awprotchk_i),
        .engn_awuserchk_i          (unused_mgr_engn_awuserchk_i),
        .engn_wdatachk_i           (unused_mgr_engn_wdatachk_i),
        .clkg_test_mode_i          (clkg_test_mode_i),
        .clkg_override_i           (clkg_override_i),
        .err_parity_chk_disable_i  (err_parity_chk_disable_i));

    /* clock gating */
    c_clock_gate_ovr u_clock_gate_ovr (
		.clk        (clk_i),
		.enable     (clk_ig_enable),
		.ovr_en     (clkg_override_i),
		.rst_en     (1'b0),
		.test_mode  (clkg_test_mode_i),
		.gated_clk  (gclk));

    assign clk_ig_enable    = cmu_active;

    /* unused signals */
    assign unused_mgr_engn_aridchk_i        = 1'h0;
    assign unused_mgr_engn_araddrchk_i      = 1'h0;
    assign unused_mgr_engn_arlenchk_i       = 1'h0;
    assign unused_mgr_engn_arprotchk_i      = 1'h0;
    assign unused_mgr_engn_aruserchk_i      = 1'h0;
    assign unused_mgr_engn_awidchk_i        = 1'h0;
    assign unused_mgr_engn_awaddrchk_i      = 1'h0;
    assign unused_mgr_engn_awlenchk_i       = 1'h0;
    assign unused_mgr_engn_awprotchk_i      = 1'h0;
    assign unused_mgr_engn_awuserchk_i      = 1'h0;
    assign unused_mgr_engn_wdatachk_i       = 1'h0;

    assign sinc_axi_sub_arcache_unused      = sinc_axi_sub_arcache;
    assign sinc_axi_sub_awcache_unused      = sinc_axi_sub_awcache;

    assign err_parity_chk_disable_i         = 1'h0;

endmodule