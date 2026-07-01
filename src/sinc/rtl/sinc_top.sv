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
// File        : sinc_top.sv
// Description : Top-level module for SINC CIU, integrating cache, CPU interface, and MPU.

module sinc_top
import sinc_pkg::*;
#(
    parameter bit NO_SEED_LOADING   = 1'b1,       // 1: skip RNG seed DMA reads (AES DRBG starts already-seeded)
    parameter EIRAM_SIZE            = 16384,      // External Memory size in KB
    parameter CACHE_SIZE            = 256,        // IRAM Cache size in KB
    parameter BLOCK_SIZE            = 512,        // Cache block size in B
    parameter INPUT_BUFFER_SIZE     = 512,        // Input buffer size in B. Not used/supported in this version.
    parameter DATA_WIDTH            = 32,         // Data width from CPU
    parameter ADDR_WIDTH            = 22,         // Address width from CPU
    parameter ENGN_PARITY_EN        = 0,          // Enables AXI subordinate to generate and check parity on the engine interface signals
    parameter AXI_PARITY_EN         = 0,          // Enables AXI subordinate to generate and check parity on the AXI interface signals
    parameter AXI_SUB_DFD           = 1,          // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter AXI_SUB_CFD           = 1,          // Control fifo depth
    parameter AXI_SUB_BLEN          = 4,          // Maximum burst length (must be <=256)
    parameter AXI_MGR_DFD           = 1,          // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter AXI_MGR_BLEN          = 16,         // Maximum burst length (must be <=256)
    parameter AXI_MGR_ANUM          = 0,
    parameter unsigned KSU_KEY_SLOT_BASE_ADDR   = 32'h8F0C_4000,      // 32b KSU key slot base address
    parameter unsigned RNG_SEED_BASE_ADDR       = 32'h8F0A_0200,      // 32b RNG seed base address
    parameter unsigned REG_BASE_ADDR            = 32'h8000_0000,
    parameter unsigned REG_END_ADDR             = 32'h8000_0400,
    parameter CACHE_MEM_ADDR_WIDTH  = 14,               // Addr width of cache mem. Replace with mem defines
    parameter CACHE_MEM_WIDTH       = 156,			    // Cache RAM Size
    parameter CACHE_DATA_WIDTH      = 4*DATA_WIDTH,		// 4 banks of SRAM and 32-bit each
    /*  Data Width of VTAG RA
        1b for valid, $clog2(EIRAM_SIZE/CACHE_SIZE) for number of tag bits if cache was direct mapped, 2b because cache is 4-way set associative */
    parameter CACHE_TAG_WIDTH       = ($clog2(EIRAM_SIZE) - $clog2(CACHE_SIZE)) + 2,	// Cache Tag Size
    parameter CACHE_VTAG_WIDTH      = 4*(1 + CACHE_TAG_WIDTH),				            // Data Width of VTAG RA
    parameter CACHE_PVTAG_WIDTH     = (CACHE_VTAG_WIDTH + 4),				            // Data plus Parity Width of VTAG RA
    parameter CACHE_VTAG_ADDR_WIDTH = ($clog2(CACHE_SIZE) - $clog2(BLOCK_SIZE)) + 8,	// Address Width of VTAG RA
    parameter CACHE_VTAG_USE_RF     = 1,						                        // 1 - Using RF Macro as VTAG memory; 0 - Using Flops such as cache_vtag.sv
    parameter MPU_REG_ADDR_WIDTH    = ((EIRAM_SIZE*1024) > (1024*1024)) ? 13 : 9,       // If size is > 1MB, then addr width must be 13, otherwise 9. Carefully review before overriding to any other value
    parameter MPU_SINGLE_CYCLE	    = 0 						                        // 0 - MPU Violation Indicator available at next cycle; 1 - at same cycle
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
    input logic                                 sinc_err_chk_disable_i,
    input logic                                 sinc_err_parity_chk_disable_i,
    input logic                                 sinc_ret_en_ni, // Used to retain ZPR flops. (ACTIVE LOW)
    input logic                                 sinc_iso_en_i, // Used for isolation cells 
    output logic                                sinc_err_o,
    output logic [1:0]                          sinc_err_parity_o,
    output logic                                sinc_done_o,
    output logic                                sinc_active_o,

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
    output logic [`HSP_AXI_MST_AWIDTH-1:0]      sinc_axi_mgr_awaddr,
    output logic [`MSFT_AXI_MST_AWU_WIDTH-1:0]  sinc_axi_mgr_awuser,
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
    output logic [`HSP_AXI_MST_DWIDTH-1:0]      sinc_axi_mgr_wdata,
    output logic                           		sinc_axi_mgr_wlast,
    output logic [3:0]                     		sinc_axi_mgr_wstrb,
    output logic                           		sinc_axi_mgr_wvalid,
    input logic                          		sinc_axi_mgr_wready,

    // Write Response channel
    output logic                           		sinc_axi_mgr_bready,
    input logic [`MSFT_AXI_MST_BU_WIDTH-1:0]    sinc_axi_mgr_buser,
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
    // CPU Interface
    //****************************************************************
    input logic                                 cpu_sinc_en_i,
    input logic                                 cpu_sinc_we_i,
    input logic [(DATA_WIDTH/8) - 1 : 0]        cpu_sinc_wr_byte_en_i,
    input logic [ADDR_WIDTH-1:0]                cpu_sinc_addr_i,
    input logic [DATA_WIDTH-1:0]                cpu_sinc_wdata_i,
    input logic                                 cpu_sinc_loadstore_i,
    input logic                                 cpu_sinc_priv_mode_i,
    output logic                                sinc_cpu_rdata_vld_o,
    output logic [DATA_WIDTH-1:0]               sinc_cpu_rdata_o,
    output logic                                sinc_cpu_r_err_o,
    output logic                                sinc_cpu_busy_o,
    output logic                                sinc_cpu_non_active_state,
    
    //****************************************************************
    // Memory Erase Interface
    //****************************************************************
    input logic 				                sinc_erase_start_i,
    input logic [(4*DATA_WIDTH) - 1 : 0]        sinc_erase_data_i,
    output logic 				                sinc_erase_done_o,
    output logic 				                sinc_erase_busy_o,
    output logic 				                sinc_err_erase_busy_o,

    //****************************************************************
    // Error Inject and Error Log Interface
    //****************************************************************
    input logic 				                sinc_err_inject_en_i,
    input logic [CACHE_MEM_ADDR_WIDTH-1:0]      sinc_err_inject_addr_i,
    input logic [CACHE_MEM_WIDTH-1:0]	        sinc_err_inject_data_i,
    output logic 				                sinc_err_inject_done_o,   
    output logic 				                sinc_err_uncorr_o,
    output logic [CACHE_MEM_ADDR_WIDTH-1:0]	    sinc_err_addr_o,
    output logic [2:0]	                        sinc_err_corr_o,
    

    //****************************************************************
    // Cache IRAM Memory Interface
    //****************************************************************
    output logic 		             	        sinc_ciram_clk_o,
    output logic [CACHE_MEM_ADDR_WIDTH-1:0] 	sinc_ciram_addr_o,
    output logic 		             	        sinc_ciram_we_o,
    output logic                                sinc_ciram_en_o,
    output logic [CACHE_MEM_WIDTH-1:0]          sinc_ciram_wdata_o,
    input logic	[CACHE_MEM_WIDTH-1:0]           sinc_ciram_rdata_i,

    //****************************************************************
    // VTAG Memory Interface
    //****************************************************************

    output logic 		             	        sinc_vtag_clk_o,
    output logic [CACHE_VTAG_ADDR_WIDTH - 1 : 0] sinc_vtag_addr_o,
    output logic [3:0]		             	    sinc_vtag_we_o,
    output logic [3:0]                          sinc_vtag_en_o,
    output logic [CACHE_PVTAG_WIDTH - 1 : 0]    sinc_vtag_wdata_o,
    input [CACHE_PVTAG_WIDTH - 1 : 0]           sinc_vtag_rdata_i,

    //****************************************************************
    // MPU Interface
    //****************************************************************
    input logic [MPU_REG_ADDR_WIDTH-1:0] 	    sinc_mpu_reg_addr_i,
    input logic 		             	        sinc_mpu_reg_wr_i,
    input logic                                 sinc_mpu_reg_rd_i,
    input logic [DATA_WIDTH-1:0]                sinc_mpu_reg_wdata_i,
    output logic [DATA_WIDTH-1:0]               sinc_mpu_reg_rdata_o,
    output logic [1:0]                          sinc_mpu_reg_resp_o,
    output logic                                sinc_mpu_reg_resp_vld_o,
    output logic                                sinc_mpu_err_accvio_o,
    input logic                                 sinc_mpu_disable_i,
    input logic                                 sinc_chkpt_spramnx_i

	);

    /* Local parameters */
    localparam BLOCK_SIZEW              = $clog2(BLOCK_SIZE);                               // signal width required to store block size in bytes
    localparam BLOCK_LEN                = BLOCK_SIZE/4;                                     // Represent AXI len for a block (i.e. no. of 32b beats in a block)
    localparam BLOCK_LENW               = $clog2(BLOCK_LEN + 1);
    localparam unsigned NUM_AES_BLOCKS  = BLOCK_SIZE/16;                                    // Each AES block consist of 16B or 128b
    localparam NUM_SETS                 = ((CACHE_SIZE * 1024) / BLOCK_SIZE) / 4;
    localparam NUM_SETSW                = $clog2(NUM_SETS);
    localparam ATTRIB_RESET             = 4'b0111;
    localparam ATTRIB_WMASK             = 4'b1111;
    localparam RAM_WRAPPER_ADDR_WIDTH   = `MSFT_SP_CIRAM0_ADDR_WIDTH;
    localparam RAM_WRAPPER_DATA_WIDTH   = `MSFT_SP_CIRAM0_DATA_WIDTH;
    localparam RAM_WRAPPER_SIZE         = `MSFT_SP_CIRAM0_SIZE;				                                        // total number of bytes; must be addressable using 'ADDR_WIDTH' bits of addresses
    localparam RAM_WRAPPER_SUPPORT_SECDED = `MSFT_SP_CIRAM0_SUPPORT_SECDED;                                         // Set to 1 for enabling SECDED scheme. Set to 0 for DED scheme.
    localparam RAM_WRAPPER_SUPPORT_RMW  = `MSFT_SP_CIRAM0_SUPPORT_RMW;                                              // support Read-Mod-Write
    localparam RAM_WRAPPER_SUPPORT_INJECT = `MSFT_SP_CIRAM0_SUPPORT_INJECT;                                         // support error inject
    localparam RAM_WRAPPER_SUPPORT_ENGN_ERASE = 1;                                                                  // support engine erase for this instance
    localparam RAM_WRAPPER_SUPPORT_ERASE = `MSFT_SP_CIRAM0_SUPPORT_ERASE;                                           // support creg erase for this instance
    localparam RAM_WRAPPER_SUPPORT_WRITE_BACK = `MSFT_SP_CIRAM0_SUPPORT_WRITE_BACK;                                 // Set to enable write back on correctable errors during read.
    localparam RAM_WRAPPER_RMW_PIPELINE = `MSFT_SP_CIRAM0_RMW_PIPELINE;                                             // 0 - No pipelining on RMW writes; 1 - One pipeline stage on RMW writes
    localparam RAM_WRAPPER_PARITY_EN    = `MSFT_SP_CIRAM0_PARITY_EN;                                                // Parity enable for engine input signals and internal flops that are not ECC protected.
    localparam RAM_WRAPPER_ERASE_START_ADDR = `MSFT_SP_CIRAM0_ERASE_START_ADDR;                                     // Start erase from this address
    localparam RAM_WRAPPER_ENGN_ERASE_START_ADDR = `MSFT_SP_CIRAM0_ENGN_ERASE_START_ADDR;                           // Start Engine erase from this address
    localparam RAM_WRAPPER_ERASE_END_ADDR = `MSFT_SP_CIRAM0_ERASE_END_ADDR / (RAM_WRAPPER_DATA_WIDTH/8);	        // full erase up to this address
    localparam RAM_WRAPPER_ENGN_ERASE_END_ADDR = `MSFT_SP_CIRAM0_ENGN_ERASE_END_ADDR / (RAM_WRAPPER_DATA_WIDTH/8);	// engine erase up to this address



    logic               cmu_active;                
    logic               cmu_block_fetch_comp;      
    logic               cmu_block_fetch_err;       
    logic               cmu_busy;                  
    logic [CACHE_MEM_ADDR_WIDTH-1:0] cmu_mem_addr; 
    logic [31:0]        cmu_mem_wdata;             
    logic               cmu_mem_wr;                
    logic               cmu_sinc_reinit;           
    logic               cmu_sinc_reset;            


    sinc_state_t                    cmu_sinc_state;

    logic                           ciu_block_fetch_req;
    logic [ADDR_WIDTH-1:0]          ciu_addr;
    logic		                    ciu_cache_hit;
    logic                           ciu_mem_busy;
    logic                           ciu_fault_err;
    logic                           ciu_active;
    logic			                ciu_gclk;
    logic                           ciu_reset_reinit_completed;

    sinc_cmu #(
               .NO_SEED_LOADING                   (NO_SEED_LOADING),
               .CACHE_SIZE                        (CACHE_SIZE),
               .BLOCK_SIZE                        (BLOCK_SIZE),
               .ADDR_WIDTH                        (ADDR_WIDTH),
               .ENGN_PARITY_EN                    (ENGN_PARITY_EN),
               .AXI_PARITY_EN                     (AXI_PARITY_EN),
               .AXI_SUB_DFD                       (AXI_SUB_DFD),
               .AXI_SUB_CFD                       (AXI_SUB_CFD),
               .AXI_SUB_BLEN                      (AXI_SUB_BLEN),
               .AXI_MGR_DFD                       (AXI_MGR_DFD),
               .AXI_MGR_BLEN                      (AXI_MGR_BLEN),
               .AXI_MGR_ANUM                      (AXI_MGR_ANUM),
               .KSU_KEY_SLOT_BASE_ADDR            (KSU_KEY_SLOT_BASE_ADDR),
               .RNG_SEED_BASE_ADDR                (RNG_SEED_BASE_ADDR),
               .REG_BASE_ADDR                     (REG_BASE_ADDR),
               .REG_END_ADDR                      (REG_END_ADDR),
               .CACHE_MEM_ADDR_WIDTH              (CACHE_MEM_ADDR_WIDTH),
               .BLOCK_SIZEW                       (BLOCK_SIZEW),
               .BLOCK_LEN                         (BLOCK_LEN),
               .BLOCK_LENW                        (BLOCK_LENW),
               .NUM_AES_BLOCKS                    (NUM_AES_BLOCKS),
               .NUM_SETS                          (NUM_SETS),
               .NUM_SETSW                         (NUM_SETSW))
    u_sinc_cmu (
                .cmu_sinc_state                   (cmu_sinc_state),
                // Outputs
                .cmu_active                       (cmu_active),
                .sinc_done_o                      (sinc_done_o),
                .sinc_err_o                       (sinc_err_o),
                .sinc_cpu_non_active_state        (sinc_cpu_non_active_state),
                .sinc_axi_mgr_araddr              (sinc_axi_mgr_araddr[`HSP_AXI_SLV_AWIDTH-1:0]),
                .sinc_axi_mgr_aruser              (sinc_axi_mgr_aruser[`MSFT_AXI_SLV_ARU_WIDTH-1:0]),
                .sinc_axi_mgr_arburst             (sinc_axi_mgr_arburst[1:0]),
                .sinc_axi_mgr_arcache             (sinc_axi_mgr_arcache[3:0]),
                .sinc_axi_mgr_arid                (sinc_axi_mgr_arid[`HSP_AXI_MST_ID_WIDTH-1:0]),
                .sinc_axi_mgr_arlen               (sinc_axi_mgr_arlen[`AXI_ALEN_WIDTH-1:0]),
                .sinc_axi_mgr_arlock              (sinc_axi_mgr_arlock[`HSP_AXI_LOCK_BITS-1:0]),
                .sinc_axi_mgr_arprot              (sinc_axi_mgr_arprot[2:0]),
                .sinc_axi_mgr_arsize              (sinc_axi_mgr_arsize[2:0]),
                .sinc_axi_mgr_arvalid             (sinc_axi_mgr_arvalid),
                .sinc_axi_mgr_rready              (sinc_axi_mgr_rready),
                .sinc_axi_mgr_awaddr              (sinc_axi_mgr_awaddr[`HSP_AXI_SLV_AWIDTH-1:0]),
                .sinc_axi_mgr_awuser              (sinc_axi_mgr_awuser[`MSFT_AXI_SLV_AWU_WIDTH-1:0]),
                .sinc_axi_mgr_awburst             (sinc_axi_mgr_awburst[1:0]),
                .sinc_axi_mgr_awcache             (sinc_axi_mgr_awcache[3:0]),
                .sinc_axi_mgr_awid                (sinc_axi_mgr_awid[`HSP_AXI_MST_ID_WIDTH-1:0]),
                .sinc_axi_mgr_awlen               (sinc_axi_mgr_awlen[`AXI_ALEN_WIDTH-1:0]),
                .sinc_axi_mgr_awlock              (sinc_axi_mgr_awlock[`HSP_AXI_LOCK_BITS-1:0]),
                .sinc_axi_mgr_awprot              (sinc_axi_mgr_awprot[2:0]),
                .sinc_axi_mgr_awsize              (sinc_axi_mgr_awsize[2:0]),
                .sinc_axi_mgr_awvalid             (sinc_axi_mgr_awvalid),
                .sinc_axi_mgr_wdata               (sinc_axi_mgr_wdata[`HSP_AXI_SLV_DWIDTH-1:0]),
                .sinc_axi_mgr_wlast               (sinc_axi_mgr_wlast),
                .sinc_axi_mgr_wstrb               (sinc_axi_mgr_wstrb[3:0]),
                .sinc_axi_mgr_wvalid              (sinc_axi_mgr_wvalid),
                .sinc_axi_mgr_bready              (sinc_axi_mgr_bready),
                .sinc_axi_sub_arready             (sinc_axi_sub_arready),
                .sinc_axi_sub_rdata               (sinc_axi_sub_rdata[`HSP_AXI_SLV_DWIDTH-1:0]),
                .sinc_axi_sub_ruser               (sinc_axi_sub_ruser[`MSFT_AXI_SLV_RU_WIDTH-1:0]),
                .sinc_axi_sub_rid                 (sinc_axi_sub_rid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
                .sinc_axi_sub_rlast               (sinc_axi_sub_rlast),
                .sinc_axi_sub_rresp               (sinc_axi_sub_rresp[1:0]),
                .sinc_axi_sub_rvalid              (sinc_axi_sub_rvalid),
                .sinc_axi_sub_awready             (sinc_axi_sub_awready),
                .sinc_axi_sub_wready              (sinc_axi_sub_wready),
                .sinc_axi_sub_buser               (sinc_axi_sub_buser[`MSFT_AXI_SLV_BU_WIDTH-1:0]),
                .sinc_axi_sub_bid                 (sinc_axi_sub_bid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
                .sinc_axi_sub_bresp               (sinc_axi_sub_bresp[1:0]),
                .sinc_axi_sub_bvalid              (sinc_axi_sub_bvalid),
                .cmu_block_fetch_comp             (cmu_block_fetch_comp),
                .cmu_block_fetch_err              (cmu_block_fetch_err),
                .cmu_busy                         (cmu_busy),
                .cmu_sinc_reset                   (cmu_sinc_reset),
                .cmu_sinc_reinit                  (cmu_sinc_reinit),
                .cmu_mem_addr                     (cmu_mem_addr[CACHE_MEM_ADDR_WIDTH-1:0]),
                .cmu_mem_wr                       (cmu_mem_wr),
                .cmu_mem_wdata                    (cmu_mem_wdata[31:0]),
                // Inputs
                .clk_i                            (clk_i),
                .rstn_i                           (rstn_i),
                .lp_rstn_i                        (lp_rstn_i),
                .clkg_override_i                  (clkg_override_i),
                .clkg_test_mode_i                 (clkg_test_mode_i),
                .disable_encr_auth_check_i        (disable_encr_auth_check_i),
                .sinc_axi_mgr_arready             (sinc_axi_mgr_arready),
                .sinc_axi_mgr_rdata               (sinc_axi_mgr_rdata[`HSP_AXI_SLV_DWIDTH-1:0]),
                .sinc_axi_mgr_ruser               (sinc_axi_mgr_ruser[`MSFT_AXI_SLV_RU_WIDTH-1:0]),
                .sinc_axi_mgr_rid                 (sinc_axi_mgr_rid[`HSP_AXI_MST_ID_WIDTH-1:0]),
                .sinc_axi_mgr_rlast               (sinc_axi_mgr_rlast),
                .sinc_axi_mgr_rresp               (sinc_axi_mgr_rresp[1:0]),
                .sinc_axi_mgr_rvalid              (sinc_axi_mgr_rvalid),
                .sinc_axi_mgr_awready             (sinc_axi_mgr_awready),
                .sinc_axi_mgr_wready              (sinc_axi_mgr_wready),
                .sinc_axi_mgr_buser               (sinc_axi_mgr_buser[`MSFT_AXI_SLV_BU_WIDTH-1:0]),
                .sinc_axi_mgr_bid                 (sinc_axi_mgr_bid[`HSP_AXI_MST_ID_WIDTH-1:0]),
                .sinc_axi_mgr_bresp               (sinc_axi_mgr_bresp[1:0]),
                .sinc_axi_mgr_bvalid              (sinc_axi_mgr_bvalid),
                .sinc_axi_sub_araddr              (sinc_axi_sub_araddr[`HSP_AXI_SLV_AWIDTH-1:0]),
                .sinc_axi_sub_aruser              (sinc_axi_sub_aruser[`MSFT_AXI_SLV_ARU_WIDTH-1:0]),
                .sinc_axi_sub_arburst             (sinc_axi_sub_arburst[1:0]),
                .sinc_axi_sub_arcache             (sinc_axi_sub_arcache[3:0]),
                .sinc_axi_sub_arid                (sinc_axi_sub_arid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
                .sinc_axi_sub_arlen               (sinc_axi_sub_arlen[`AXI_ALEN_WIDTH-1:0]),
                .sinc_axi_sub_arlock              (sinc_axi_sub_arlock[`HSP_AXI_LOCK_BITS-1:0]),
                .sinc_axi_sub_arprot              (sinc_axi_sub_arprot[2:0]),
                .sinc_axi_sub_arsize              (sinc_axi_sub_arsize[2:0]),
                .sinc_axi_sub_arvalid             (sinc_axi_sub_arvalid),
                .sinc_axi_sub_rready              (sinc_axi_sub_rready),
                .sinc_axi_sub_awaddr              (sinc_axi_sub_awaddr[`HSP_AXI_SLV_AWIDTH-1:0]),
                .sinc_axi_sub_awuser              (sinc_axi_sub_awuser[`MSFT_AXI_SLV_AWU_WIDTH-1:0]),
                .sinc_axi_sub_awburst             (sinc_axi_sub_awburst[1:0]),
                .sinc_axi_sub_awcache             (sinc_axi_sub_awcache[3:0]),
                .sinc_axi_sub_awid                (sinc_axi_sub_awid[`HSP_AXI_SLV_ID_WIDTH-1:0]),
                .sinc_axi_sub_awlen               (sinc_axi_sub_awlen[`AXI_ALEN_WIDTH-1:0]),
                .sinc_axi_sub_awlock              (sinc_axi_sub_awlock[`HSP_AXI_LOCK_BITS-1:0]),
                .sinc_axi_sub_awprot              (sinc_axi_sub_awprot[2:0]),
                .sinc_axi_sub_awsize              (sinc_axi_sub_awsize[2:0]),
                .sinc_axi_sub_awvalid             (sinc_axi_sub_awvalid),
                .sinc_axi_sub_wdata               (sinc_axi_sub_wdata[`HSP_AXI_SLV_DWIDTH-1:0]),
                .sinc_axi_sub_wlast               (sinc_axi_sub_wlast),
                .sinc_axi_sub_wstrb               (sinc_axi_sub_wstrb[3:0]),
                .sinc_axi_sub_wvalid              (sinc_axi_sub_wvalid),
                .sinc_axi_sub_bready              (sinc_axi_sub_bready),
                .sinc_erase_busy_o                (sinc_erase_busy_o),
                .sinc_erase_done_o                (sinc_erase_done_o),
                .ciu_block_fetch_req              (ciu_block_fetch_req),
                .ciu_addr                         (ciu_addr[ADDR_WIDTH-1:0]),
                .ciu_cache_hit                    (ciu_cache_hit),
                .ciu_reset_reinit_completed       (ciu_reset_reinit_completed),
                .ciu_mem_busy                     (ciu_mem_busy),
                .ciu_fault_err                    (ciu_fault_err));

    assign sinc_active_o = cmu_active | ciu_active;
    assign sinc_err_parity_o = 2'h0;

    sinc_ciu #(
               	.EIRAM_SIZE                        (EIRAM_SIZE),
               	.CACHE_SIZE                        (CACHE_SIZE),
               	.BLOCK_SIZE                        (BLOCK_SIZE),
               	.DATA_WIDTH                        (DATA_WIDTH),
               	.ADDR_WIDTH                        (ADDR_WIDTH),
               	.CACHE_MEM_ADDR_WIDTH              (CACHE_MEM_ADDR_WIDTH),
               	.CACHE_MEM_WIDTH                   (CACHE_MEM_WIDTH),
		        .MPU_REG_ADDR_WIDTH                (MPU_REG_ADDR_WIDTH),
		        .MPU_REG_DATA_WIDTH                (32),
			    .MPU_SINGLE_CYCLE	               (MPU_SINGLE_CYCLE),
			    .ATTRIB_RESET 	                   (ATTRIB_RESET),
			    .ATTRIB_WMASK 	                   (ATTRIB_WMASK),
                .CACHE_DATA_WIDTH                  (CACHE_DATA_WIDTH),
                .CACHE_TAG_WIDTH                   (CACHE_TAG_WIDTH),
                .CACHE_VTAG_WIDTH                  (CACHE_VTAG_WIDTH),
                .CACHE_SETIDX_WIDTH                (CACHE_VTAG_ADDR_WIDTH),
		        .CACHE_VTAG_USE_RF 		           (CACHE_VTAG_USE_RF),
                .RAM_WRAPPER_ADDR_WIDTH            (RAM_WRAPPER_ADDR_WIDTH),
                .RAM_WRAPPER_DATA_WIDTH            (RAM_WRAPPER_DATA_WIDTH),
                .RAM_WRAPPER_SIZE                  (RAM_WRAPPER_SIZE),
                .RAM_WRAPPER_SUPPORT_SECDED        (RAM_WRAPPER_SUPPORT_SECDED),
                .RAM_WRAPPER_SUPPORT_RMW           (RAM_WRAPPER_SUPPORT_RMW),
                .RAM_WRAPPER_SUPPORT_INJECT        (RAM_WRAPPER_SUPPORT_INJECT),
                .RAM_WRAPPER_SUPPORT_ENGN_ERASE    (RAM_WRAPPER_SUPPORT_ENGN_ERASE), 
                .RAM_WRAPPER_SUPPORT_ERASE         (RAM_WRAPPER_SUPPORT_ERASE),
                .RAM_WRAPPER_SUPPORT_WRITE_BACK    (RAM_WRAPPER_SUPPORT_WRITE_BACK), 
                .RAM_WRAPPER_RMW_PIPELINE          (RAM_WRAPPER_RMW_PIPELINE),
                .RAM_WRAPPER_PARITY_EN             (RAM_WRAPPER_PARITY_EN),
                .RAM_WRAPPER_ERASE_START_ADDR      (RAM_WRAPPER_ERASE_START_ADDR),
                .RAM_WRAPPER_ENGN_ERASE_START_ADDR (RAM_WRAPPER_ENGN_ERASE_START_ADDR),
                .RAM_WRAPPER_ERASE_END_ADDR        (RAM_WRAPPER_ERASE_END_ADDR),
                .RAM_WRAPPER_ENGN_ERASE_END_ADDR   (RAM_WRAPPER_ENGN_ERASE_END_ADDR)) 
    u_sinc_ciu (
		        // Pervasive signals
		        // Inputs
		        .clk (clk_i),
                .rstn (rstn_i),
                .lp_rstn_i (lp_rstn_i),
                .clkg_override (clkg_override_i),
                .clkg_test_mode (clkg_test_mode_i),
		        // Misc
		        // Outputs
		        .ciu_active ( ciu_active ),
		        .ciu_fault_err ( ciu_fault_err ),
		        .ciu_gclk ( ciu_gclk ),
		        // Inputs
		        .sinc_err_chk_disable_i (sinc_err_chk_disable_i),
		        .sinc_err_parity_chk_disable_i (sinc_err_parity_chk_disable_i),
		        // SP Interface
		        // Outputs
		        .mem_cpu_busy (sinc_cpu_busy_o),
		        .mem_cpu_rdata_vld (sinc_cpu_rdata_vld_o),
		        .mem_cpu_read_err (sinc_cpu_r_err_o),
		        .mem_cpu_rdata (sinc_cpu_rdata_o[DATA_WIDTH - 1 : 0]),
		        // Inputs
		        .cpu_mem_en (cpu_sinc_en_i),
		        .cpu_mem_we (cpu_sinc_we_i),
		        .cpu_mem_addr (cpu_sinc_addr_i[ADDR_WIDTH - 1 : 0]),
		        .cpu_mem_wdata (cpu_sinc_wdata_i[DATA_WIDTH - 1 : 0]),
		        .cpu_mem_wr_byte_en (cpu_sinc_wr_byte_en_i[(DATA_WIDTH/8) - 1 : 0]),
		        .cpu_mem_loadstore (cpu_sinc_loadstore_i),
		        .cpu_mem_priv_mode (cpu_sinc_priv_mode_i),
    		    // Memory Interface
		        // Outputs
		        .mem_en (sinc_ciram_en_o),
		        .mem_we (sinc_ciram_we_o),
		        .mem_addr (sinc_ciram_addr_o[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
		        .mem_wdata (sinc_ciram_wdata_o[CACHE_MEM_WIDTH - 1 : 0]),
		        // Inputs
		        .mem_rdata (sinc_ciram_rdata_i[CACHE_MEM_WIDTH - 1 : 0]),
		        // VTAG RA Interface
		        // Outputs
		        .sinc_vtag_addr (sinc_vtag_addr_o[CACHE_VTAG_ADDR_WIDTH - 1 : 0]),
		        .sinc_vtag_we (sinc_vtag_we_o[3 : 0]),
		        .sinc_vtag_en (sinc_vtag_en_o[3 : 0]),
		        .sinc_vtag_wdata (sinc_vtag_wdata_o),
		        // Inputs
		        .sinc_vtag_rdata (sinc_vtag_rdata_i),
		        // Memory Erase Interface with CREG
		        // Outputs
		        .mem_erase_busy (sinc_erase_busy_o),
		        .mem_erase_done (sinc_erase_done_o),
		        .mem_err_erase_busy (sinc_err_erase_busy_o),
		        // Inputs
		        .mem_erase_start (sinc_erase_start_i),
		        .mem_erase_wdata (sinc_erase_data_i[(4*DATA_WIDTH) - 1 : 0]),
    		    // Error Inject and Error Log Interface with CREG
		        // Outputs
		        .mem_err_inject_done (sinc_err_inject_done_o),
		        .mem_err_uncorr (sinc_err_uncorr_o),
		        .mem_err_addr (sinc_err_addr_o[CACHE_MEM_ADDR_WIDTH - 1:0]),
		        .mem_err_corr (sinc_err_corr_o[2 : 0]),
		        // Inputs
		        .mem_err_inject_en (sinc_err_inject_en_i),
		        .mem_err_inject_addr (sinc_err_inject_addr_i[CACHE_MEM_ADDR_WIDTH-1:0]),
		        .mem_err_inject_data (sinc_err_inject_data_i[CACHE_MEM_WIDTH-1: 0]),
   		        // MPU Interface with CREG
		        // Outputs
		        .mpu_reg_rdata (sinc_mpu_reg_rdata_o[32 - 1 : 0]),
		        .mpu_err_accvio (sinc_mpu_err_accvio_o),
		        .mpu_reg_resp (sinc_mpu_reg_resp_o),
		        .mpu_reg_resp_vld (sinc_mpu_reg_resp_vld_o),
		        // Inputs
		        .mpu_disable (sinc_mpu_disable_i),
		        .chkpt_spramnx (sinc_chkpt_spramnx_i),
		        .mpu_reg_wr (sinc_mpu_reg_wr_i),
		        .mpu_reg_rd (sinc_mpu_reg_rd_i),
		        .mpu_reg_addr (sinc_mpu_reg_addr_i[MPU_REG_ADDR_WIDTH - 1 : 0]),
		        .mpu_reg_wdata (sinc_mpu_reg_wdata_i[32 - 1 : 0]),
		        // CMU Interface
		        // Outputs
		        .ciu_mem_busy (ciu_mem_busy),
		        .ciu_reset_reinit_completed (ciu_reset_reinit_completed),
		        .ciu_cache_hit (ciu_cache_hit),
		        .ciu_block_fetch_req (ciu_block_fetch_req),
                .ciu_block_addr (ciu_addr[ADDR_WIDTH-1:0]),
		        // Inputs
		        .cmu_block_fetch_comp (cmu_block_fetch_comp),
		        .cmu_block_fetch_err (cmu_block_fetch_err),
		        .cmu_busy (cmu_busy),
		        .cmu_sinc_state (cmu_sinc_state),
		        .cmu_sinc_reset (cmu_sinc_reset),
                .cmu_sinc_reinit (cmu_sinc_reinit),
		        .cmu_mem_we (cmu_mem_wr),
		        .cmu_mem_addr (cmu_mem_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
		        .cmu_mem_wdata (cmu_mem_wdata[DATA_WIDTH - 1 : 0])
	);

    assign sinc_ciram_clk_o = ciu_gclk;
    assign sinc_vtag_clk_o = ciu_gclk;
	
endmodule