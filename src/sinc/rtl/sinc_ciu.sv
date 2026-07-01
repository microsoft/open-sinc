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
// File        : sinc_ciu.sv
// Description : Cache Interface Unit (CIU). Integrates RAM wrapper, clock gate,
//               CIU control, VTAG, and MPU retention modules for CPU cache access.

module sinc_ciu
   import sinc_pkg::*;
    #(
    // Parameters
    EIRAM_SIZE = 16384,							                        // in KB
    CACHE_SIZE = 256,							                        // in KB
    BLOCK_SIZE = 256,							                        // in Byte
    DATA_WIDTH = 32,							                        // in bit, only for data in each bank of Cache Memory
    ADDR_WIDTH = $clog2(EIRAM_SIZE) + 8,				                // $clog2(EIRAM_SIZE) + 8: aligned to 4 Bytes
    CACHE_MEM_ADDR_WIDTH = $clog2((CACHE_SIZE*1024)>>4), 		        // $clog2(CACHE_SIZE) + 6: aligned to 128-bit longword
    CACHE_MEM_WIDTH = (DATA_WIDTH == 32) ? 4*39 : DATA_WIDTH,		    // CACHE_MEM_WIDTH = DATA_WIDTH + ECC_CODE_WIDTH for each bank of Cache Memory
    MPU_REG_ADDR_WIDTH = ((EIRAM_SIZE*1024) > (1024*1024)) ? 13 : 9,
    MPU_REG_DATA_WIDTH = 32,
    ATTRIB_RESET = 4'b0111,
    ATTRIB_WMASK = 4'b1111,
    MPU_SINGLE_CYCLE = 0,						                        // default: MPU violation indicator available at next cycle
    CACHE_DATA_WIDTH = 4*DATA_WIDTH,					                // 4 banks of SRAM and 32-bit each
    CACHE_TAG_WIDTH = ($clog2(EIRAM_SIZE) - $clog2(CACHE_SIZE)) + 2,    // Cache Tag Size
    CACHE_VTAG_WIDTH = 4*(1+CACHE_TAG_WIDTH),				            // Data Width of VTAG RA
    CACHE_SETIDX_WIDTH = ($clog2(CACHE_SIZE) - $clog2(BLOCK_SIZE)) + 8,	// Cache Index Size 
    CACHE_VTAG_USE_RF = 1,						                        // 1 - Use RF Macro for storing VTAG; 0 - Use Flops
    RAM_WRAPPER_ADDR_WIDTH = CACHE_MEM_ADDR_WIDTH,
    RAM_WRAPPER_DATA_WIDTH = CACHE_DATA_WIDTH,
    RAM_WRAPPER_SIZE = (CACHE_SIZE * 1024),				                // total number of bytes, must be addressable using 'ADDR_WIDTH' bits of addresses
    RAM_WRAPPER_SUPPORT_SECDED = 1,                       		        // Set to 1 for enabling SECDED scheme. Set to 0 for DED scheme.
    RAM_WRAPPER_SUPPORT_RMW = 1,                          		        // support Read-Mod-Write
    RAM_WRAPPER_SUPPORT_INJECT = 1,                       		        // support error inject
    RAM_WRAPPER_SUPPORT_ENGN_ERASE = 1,                   		        // support engine erase for this instance
    RAM_WRAPPER_SUPPORT_ERASE = 1,                        		        // support creg erase for this instance
    RAM_WRAPPER_SUPPORT_WRITE_BACK = 0,                   		        // Set to enable write back on correctable errors during read.
    RAM_WRAPPER_RMW_PIPELINE = 0,                         		        // 0 - No pipelining on RMW writes, 1 - One pipeline stage on RMW writes
    RAM_WRAPPER_PARITY_EN = 0,                            		        // Parity enable for engine input signals and internal flops that are not ECC protected.
    RAM_WRAPPER_ERASE_START_ADDR = 0,                     		        // Start erase from this address
    RAM_WRAPPER_ENGN_ERASE_START_ADDR = 0,                		        // Start Engine erase from this address
    RAM_WRAPPER_NUM_BYTES = RAM_WRAPPER_DATA_WIDTH/8,                 	// 4 or 8 bytes, depending on DATA_WIDTH
    RAM_WRAPPER_ERASE_END_ADDR = RAM_WRAPPER_SIZE - RAM_WRAPPER_NUM_BYTES,	// full erase up to this address
    RAM_WRAPPER_ENGN_ERASE_END_ADDR = RAM_WRAPPER_SIZE - RAM_WRAPPER_NUM_BYTES,	// engine erase up to this address
    localparam CACHE_PVTAG_WIDTH = (CACHE_TAG_WIDTH < 10)  ? (CACHE_VTAG_WIDTH + 4) : (CACHE_VTAG_WIDTH + 8),
    localparam ERR_CORR_WIDTH = $clog2((CACHE_DATA_WIDTH/32)+1)		    // it will be 3 for CACHE_DATA_WIDTH = 128
    ) (

    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input						                    clk,
    input 	       					                rstn,
    input                                           lp_rstn_i,
    input						                    clkg_override,
    input						                    clkg_test_mode,
    input						                    sinc_err_chk_disable_i,
    input						                    sinc_err_parity_chk_disable_i,
    output logic					                ciu_fault_err,
    output logic					                ciu_active,
    output logic					                ciu_gclk,

    //**********************************************************************
    // Interface with CPU (SP):
    //	  DATA_WIDTH default 32-bit width of data
    //**********************************************************************
    output logic                                	mem_cpu_busy,
    output logic                                	mem_cpu_rdata_vld,
    output logic [DATA_WIDTH-1:0]               	mem_cpu_rdata,
    output logic                                	mem_cpu_read_err,
    input						                    cpu_mem_en,
    input						                    cpu_mem_we,
    input [ADDR_WIDTH - 1 : 0]				        cpu_mem_addr,
    input [DATA_WIDTH - 1 : 0]				        cpu_mem_wdata,
    input [(DATA_WIDTH/8) - 1 : 0] 			        cpu_mem_wr_byte_en,
    input						                    cpu_mem_loadstore,
    input						                    cpu_mem_priv_mode,

    //****************************************************************
    // Memory Interface:
    //    CACHE_MEM_WIDTH 4*39 while default 39-bit width of each bank with data plus ECC code
    //****************************************************************
    output logic                                	mem_en,
    output logic 		             		        mem_we,
    output logic [CACHE_MEM_ADDR_WIDTH - 1 : 0] 	mem_addr,
    output logic [CACHE_MEM_WIDTH - 1 : 0]          mem_wdata,
    input [CACHE_MEM_WIDTH - 1 : 0]             	mem_rdata,

    //****************************************************************
    // VTAG RA Interface:
    //    CACHE_PVTAG_WIDTH = (CACHE_TAG_WIDTH < 10)  ? (CACHE_VTAG_WIDTH + 4) : (CACHE_VTAG_WIDTH + 8)
    //****************************************************************
    output logic [CACHE_SETIDX_WIDTH - 1 : 0]     	sinc_vtag_addr,
    output logic [3:0]                              sinc_vtag_we,
    output logic [3:0]                              sinc_vtag_en,
    output logic [CACHE_PVTAG_WIDTH - 1 : 0]        sinc_vtag_wdata,
    input [CACHE_PVTAG_WIDTH - 1 : 0]           	sinc_vtag_rdata,

    //****************************************************************
    // Memory Erase Interface with CREG
    //    CACHE_DATA_WIDTH default 128-bit width of data without ECC codes
    //****************************************************************
    input 						                    mem_erase_start,
    input [CACHE_DATA_WIDTH-1:0]                	mem_erase_wdata,
    output logic 					                mem_erase_busy,
    output logic 					                mem_erase_done,
    output logic 					                mem_err_erase_busy,

    //****************************************************************
    // Error Inject and Error Log Interface with CREG
    //****************************************************************
    input 						                    mem_err_inject_en,
    input [CACHE_MEM_ADDR_WIDTH - 1 : 0] 		    mem_err_inject_addr,
    input [CACHE_MEM_WIDTH - 1 : 0]       		    mem_err_inject_data,
    output logic 					                mem_err_inject_done,
    output logic 					                mem_err_uncorr,
    output logic [CACHE_MEM_ADDR_WIDTH - 1 : 0]		mem_err_addr,
    output logic [ERR_CORR_WIDTH - 1 : 0]           mem_err_corr,

    //****************************************************************
    // MPU Interface with CREG
    //****************************************************************
    input  	                                	    mpu_disable,
    input 		                                    chkpt_spramnx,
    input  		             			            mpu_reg_wr,
    input [MPU_REG_ADDR_WIDTH - 1 : 0] 			    mpu_reg_addr,
    input  		                                    mpu_reg_rd,
    input [MPU_REG_DATA_WIDTH - 1 : 0]			    mpu_reg_wdata,
    output logic [MPU_REG_DATA_WIDTH - 1 : 0]		mpu_reg_rdata,
    output logic                                	mpu_err_accvio,
    output logic [1:0]                              mpu_reg_resp,
    output logic                                	mpu_reg_resp_vld,

    //****************************************************************
    // CMU Interface
    //****************************************************************
    input 		                                    cmu_block_fetch_comp,
    input						                    cmu_block_fetch_err,
    input 		                                    cmu_busy,
    input sinc_state_t			        	        cmu_sinc_state,
    input 		                                    cmu_sinc_reset,
    input						                    cmu_sinc_reinit,
    input 		                                    cmu_mem_we,
    input [CACHE_MEM_ADDR_WIDTH - 1 : 0]		    cmu_mem_addr,
    input [DATA_WIDTH - 1 : 0]				        cmu_mem_wdata,
    output logic					                ciu_mem_busy,
    output logic					                ciu_reset_reinit_completed,
    output logic                                	ciu_cache_hit,
    output logic                                	ciu_block_fetch_req,
    output logic [ADDR_WIDTH - 1 : 0]		        ciu_block_addr);

////
//// Local Parameters
////
localparam NUM_PAGES_IN_EXTERNAL_IRAM = (EIRAM_SIZE / 4);		// EIRAM_SIZE in KB while each page is 4KB
localparam ERR_RDATA = {(DATA_WIDTH/32){`C_ERRDATA}};		    // Message to indicate error on rdata

////
//// Internal Signals
////
logic						            mpu_top_page_acc_en;
logic [ADDR_WIDTH - 1 : 0]	            req_addr;
logic [4 - 1 : 0]			            req_id;
logic						            req_en;
logic						            req_we;
logic						            req_xe;
logic						            req_pm;
logic						            req_accsrc, ciu_mpu_accsrc;
logic  	                                override_nx;
logic						            mpu_acc_vio;
logic						            mpu_busy;
logic [CACHE_DATA_WIDTH - 1 : 0]        ciu_mem_wdata;
logic						            mem_ciu_busy;
logic [CACHE_DATA_WIDTH - 1 : 0]	    mem_ciu_rdata;
logic						            mem_ciu_rdata_valid;
logic [CACHE_MEM_ADDR_WIDTH - 1 : 0]    ciu_mem_addr;
logic						            ciu_mem_en;
logic [(CACHE_DATA_WIDTH/8) - 1 : 0]	ciu_mem_we;
logic 						            ciu_mem_engn_erase_start;
logic						            mem_ciu_engn_erase_done;
logic						            vtag_cache_hit;
logic [2 - 1 : 0]				        vtag_cache_hit_word_idx;
logic [2 - 1 : 0]				        cache_fifo_status;
logic						            vtag_parity_error;
logic						            ciu_vtag_update;
logic						            ciu_vtag_comp;
logic [CACHE_TAG_WIDTH - 1 : 0]			cache_tag;
logic [CACHE_SETIDX_WIDTH - 1 : 0]		cache_set_idx;
logic						            ciu_mem_erase_busy, mem_wrapper_erase_busy;
logic						            ciu_sm_fault_err;
logic						            error_happened;
logic [DATA_WIDTH-1:0]                  ciu_cpu_rdata;
logic						            cpu_read_upon_accvio;
logic						            ciu_acc_vio;
logic						            clock_gate_rst_en;
logic						            mem_init_in_action;
logic						            mem_init_active_r, nxt_mem_init_active;
logic						            ciu_clock_waken, ciu_clock_waken_r;
logic						            clock_gate_enable;
logic						            cpu_mem_access;
logic						            gclk;
logic						            vtag_erase_busy;
logic						            vtag_erase_start;
logic						            mem_inject_in_action;
logic						            mem_inject_active_r, nxt_mem_inject_active;
logic						            cmu_sinc_in_reset;
logic						            cmu_sinc_reset_active_r, nxt_cmu_sinc_reset_active;
logic						            sync_ciu_reset;
logic						            soft_rst;
logic						            ext_acc_vio;
logic						            read_err_on_erase_busy;

////
//// Link to Output
////
assign mpu_err_accvio = ciu_acc_vio;
assign ciu_fault_err = (ciu_sm_fault_err || mem_err_uncorr || vtag_parity_error);
assign mem_cpu_rdata = error_happened ? ERR_RDATA : ciu_cpu_rdata;
assign ciu_gclk = gclk;
assign mem_err_erase_busy = (read_err_on_erase_busy || (mem_erase_busy && cpu_mem_en));

////
//// Misc
////
assign req_accsrc = ciu_mpu_accsrc;
assign vtag_erase_start = (mem_erase_start || ciu_mem_engn_erase_start);
assign mem_erase_busy = (ciu_mem_erase_busy || mem_wrapper_erase_busy || vtag_erase_busy);
assign soft_rst = cmu_sinc_reset;
assign sync_ciu_reset = (cmu_sinc_reset || cmu_sinc_reinit);

////
//// Generating error_happened
////
always_comb begin
    error_happened = 1'b0;
    if (mem_cpu_read_err ||
	mem_err_uncorr ||
	cpu_read_upon_accvio) begin
    	error_happened = 1'b1;
    end
end

////
//// sinc_ciu_ctrl.sv
////
sinc_ciu_ctrl #(
    .MPU_SINGLE_CYCLE   (MPU_SINGLE_CYCLE),
    .CPU_DATA_WIDTH     (DATA_WIDTH),
    .EIRAM_ADDR_WIDTH   (ADDR_WIDTH),
    .CACHE_ADDR_WIDTH   (CACHE_MEM_ADDR_WIDTH),
    .CACHE_TAG_WIDTH    (CACHE_TAG_WIDTH),
    .CACHE_SETIDX_WIDTH (CACHE_SETIDX_WIDTH),
    .CACHE_DATA_WIDTH   (CACHE_DATA_WIDTH)
) u_ciu_ctrl (
    //// Pervasive input signals
    .clk                       (gclk),
    .lp_rstn_i                 (lp_rstn_i),

    //// Misc
    // output
    .ciu_fault_err             (ciu_sm_fault_err),
    .ciu_active                (ciu_active),
    .ciu_acc_vio               (ciu_acc_vio),
    .cpu_read_upon_accvio      (cpu_read_upon_accvio),
    // input
    .sync_ciu_reset            (sync_ciu_reset),
    .ext_mem_erase_busy        (mem_erase_busy),

    //// SP Interface
    // output
    .mem_cpu_busy              (mem_cpu_busy),
    .mem_cpu_rdata_vld         (mem_cpu_rdata_vld),
    .mem_cpu_rdata             (ciu_cpu_rdata[DATA_WIDTH - 1 : 0]),
    .mem_cpu_read_err          (mem_cpu_read_err),
    // input
    .cpu_mem_en                (cpu_mem_en),
    .cpu_mem_we                (cpu_mem_we),
    .cpu_mem_loadstore         (cpu_mem_loadstore),
    .cpu_mem_priv_mode         (cpu_mem_priv_mode),
    .cpu_mem_wr_byte_en        (cpu_mem_wr_byte_en),
    .cpu_mem_addr              (cpu_mem_addr[ADDR_WIDTH - 1 : 0]),
    .cpu_mem_wdata             (cpu_mem_wdata[DATA_WIDTH - 1 : 0]),

    //// Engine I/F of RAM Wrapper
    // output
    .ciu_mem_wdata             (ciu_mem_wdata),
    .ciu_mem_addr              (ciu_mem_addr),
    .ciu_mem_en                (ciu_mem_en),
    .ciu_mem_we                (ciu_mem_we),
    // input
    .mem_ciu_rdata             (mem_ciu_rdata),
    .mem_ciu_rdata_valid       (mem_ciu_rdata_valid),
    .mem_ciu_busy              (mem_ciu_busy),
    .mem_err_uncorr            (mem_err_uncorr),

    //// Erase Operation
    // output
    .ciu_mem_engn_erase_start  (ciu_mem_engn_erase_start),
    .ciu_mem_erase_busy        (ciu_mem_erase_busy),
    // input
    .mem_ciu_engn_erase_done   (mem_ciu_engn_erase_done),

    //// MPU Interface
    // output
    .req_addr                  (req_addr[ADDR_WIDTH - 1 : 0]),
    .req_id                    (req_id[4 - 1 : 0]),
    .req_en                    (req_en),
    .req_we                    (req_we),
    .req_xe                    (req_xe),
    .req_pm                    (req_pm),
    .ext_acc_vio               (ext_acc_vio),
    // input
    .mpu_acc_vio               (mpu_acc_vio),
    .mpu_busy                  (mpu_busy),

    //// CMU Interface
    // output
    .ciu_mem_busy              (ciu_mem_busy),
    .ciu_reset_completed       (ciu_reset_reinit_completed),
    .ciu_cmu_cache_hit         (ciu_cache_hit),
    .ciu_block_fetch_req       (ciu_block_fetch_req),
    .ciu_block_addr            (ciu_block_addr[ADDR_WIDTH - 1 : 0]),
    // input
    .cmu_block_fetch_comp      (cmu_block_fetch_comp),
    .cmu_block_fetch_err       (cmu_block_fetch_err),
    .cmu_busy                  (cmu_busy),
    .cmu_sinc_state            (cmu_sinc_state),
    .cmu_mem_we                (cmu_mem_we),
    .cmu_mem_addr              (cmu_mem_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
    .cmu_mem_wdata             (cmu_mem_wdata[DATA_WIDTH - 1 : 0]),

    //// VTAG Control Interface
    // output
    .ciu_vtag_comp             (ciu_vtag_comp),
    .ciu_vtag_update           (ciu_vtag_update),
    .cache_tag                 (cache_tag[CACHE_TAG_WIDTH - 1 : 0]),
    .cache_set_idx             (cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0]),
    // input
    .vtag_cache_hit            (vtag_cache_hit),
    .vtag_cache_hit_word_idx   (vtag_cache_hit_word_idx[1 : 0]),
    .vtag_parity_error         (vtag_parity_error),
    .cache_fifo_status         (cache_fifo_status[1 : 0])
);

////
//// sinc_ciu_vtag.sv
////
sinc_ciu_vtag #(
    .CACHE_TAG_WIDTH    (CACHE_TAG_WIDTH),
    .CACHE_SETIDX_WIDTH (CACHE_SETIDX_WIDTH),
    .CACHE_VTAG_USE_RF  (CACHE_VTAG_USE_RF)
) u_ciu_vtag (
    //// Pervasive input signals
    .clk                      (gclk),
    .rstn                     (rstn),
    .lp_rstn_i                (lp_rstn_i),
    .sync_ciu_reset           (sync_ciu_reset),

    //// sinc_ciu_ctrl Interface
    // output
    .vtag_cache_hit           (vtag_cache_hit),
    .vtag_cache_hit_word_idx  (vtag_cache_hit_word_idx[1 : 0]),
    .cache_fifo_status        (cache_fifo_status[1 : 0]),
    .vtag_parity_error        (vtag_parity_error),
    // input
    .ciu_vtag_comp            (ciu_vtag_comp),
    .ciu_vtag_update          (ciu_vtag_update),
    .cache_tag                (cache_tag[CACHE_TAG_WIDTH - 1 : 0]),
    .cache_set_idx            (cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0]),

    //// Memory Erase Interface
    // output
    .vtag_erase_busy          (vtag_erase_busy),
    // input
    .vtag_erase_start         (vtag_erase_start),

    //// VTAG RA Interface
    // output
    .sinc_vtag_addr           (sinc_vtag_addr[CACHE_SETIDX_WIDTH - 1 : 0]),
    .sinc_vtag_we             (sinc_vtag_we[3:0]),
    .sinc_vtag_en             (sinc_vtag_en[3:0]),
    .sinc_vtag_wdata          (sinc_vtag_wdata[CACHE_PVTAG_WIDTH - 1 : 0]),
    // input
    .sinc_vtag_rdata          (sinc_vtag_rdata[CACHE_PVTAG_WIDTH - 1 : 0])
);


assign mpu_top_page_acc_en = 1'b1;		
assign ciu_mpu_accsrc = 1'b0;			
assign override_nx = chkpt_spramnx;		

sinc_ciu_mpu_ret #(
    .EIRAM_SIZE          (EIRAM_SIZE),
    .ADDR_WIDTH          (ADDR_WIDTH),
    .NUM_PAGES           (NUM_PAGES_IN_EXTERNAL_IRAM),
    .CRYPTOS_ACC         (0),
    .ATTRIB_RESET        (ATTRIB_RESET),
    .ATTRIB_WMASK        (ATTRIB_WMASK),
    .MPU_REG_ADDR_WIDTH  (MPU_REG_ADDR_WIDTH),
    .MPU_REG_DATA_WIDTH  (MPU_REG_DATA_WIDTH),
    .MPU_SINGLE_CYCLE    (MPU_SINGLE_CYCLE)
) u_mpu_ret (
    //// Pervasive
    .clk                  (clk),
    .rstn                 (rstn),
    .soft_rst             (soft_rst),
    .clkg_override        (clkg_override),
    .clkg_test_mode       (clkg_test_mode),

    //// Global control signals (affect all pages)
    .priv_mode            (req_pm),
    .mpu_disable          (mpu_disable),
    .override_nx          (override_nx),

    //// Access information
    .ext_acc_vio          (ext_acc_vio),
    .mpu_top_page_acc_en  (mpu_top_page_acc_en),
    .req_accsrc           (req_accsrc),
    .req_addr             (req_addr),
    .req_id               (req_id[4 - 1 : 0]),
    .req_en               (req_en),
    .req_we               (req_we),
    .req_xe               (req_xe),

    //// Violation information
    // output
    .acc_vio              (mpu_acc_vio),
    .mpu_busy             (mpu_busy),

    //// Register interface
    // output
    .mpu_reg_rdata        (mpu_reg_rdata[MPU_REG_DATA_WIDTH - 1 : 0]),
    .mpu_reg_resp         (mpu_reg_resp[2 - 1 : 0]),
    .mpu_reg_resp_vld     (mpu_reg_resp_vld),
    // input
    .mpu_reg_addr         (mpu_reg_addr[MPU_REG_ADDR_WIDTH - 1 : 0]),
    .mpu_reg_wdata        (mpu_reg_wdata[MPU_REG_DATA_WIDTH - 1 : 0]),
    .mpu_reg_wr           (mpu_reg_wr),
    .mpu_reg_rd           (mpu_reg_rd)
);


logic [CACHE_MEM_WIDTH - 1 : 0] 	            inject_mask_i;
logic [((CACHE_MEM_ADDR_WIDTH+31)/32) - 1 : 0] 	addrchk_i;
logic [(CACHE_DATA_WIDTH/32) - 1 : 0] 	        wdatachk_i;
logic                        		            unused_inject_busy_o;			
logic [(CACHE_DATA_WIDTH/32)-1:0]  	            unused_rdatachk_o;
logic                        		            unused_r_err_parity_o;
logic                        		            unused_w_err_parity_o;

assign inject_mask_i = mem_err_inject_data[CACHE_MEM_WIDTH - 1 : 0];
assign addrchk_i = {((CACHE_MEM_ADDR_WIDTH+31)/32){1'b0}};			
assign wdatachk_i = {(CACHE_DATA_WIDTH/32){1'b0}};				

ram_wrapper #(
    .ADDR_WIDTH            (RAM_WRAPPER_ADDR_WIDTH),
    .DATA_WIDTH            (RAM_WRAPPER_DATA_WIDTH),
    .DEPTH                  (RAM_WRAPPER_SIZE),
    .ERASE_START_ADDR      (RAM_WRAPPER_ERASE_START_ADDR),
    .ERASE_END_ADDR        (RAM_WRAPPER_ERASE_END_ADDR),
    .ENGN_ERASE_START_ADDR (RAM_WRAPPER_ENGN_ERASE_START_ADDR),
    .ENGN_ERASE_END_ADDR   (RAM_WRAPPER_ENGN_ERASE_END_ADDR),
    .SUPPORT_WRITE_BACK    (RAM_WRAPPER_SUPPORT_WRITE_BACK),
    .RMW_PIPELINE          (RAM_WRAPPER_RMW_PIPELINE),
    .PARITY_EN             (RAM_WRAPPER_PARITY_EN),
    .SUPPORT_SECDED        (RAM_WRAPPER_SUPPORT_SECDED),
    .SUPPORT_RMW           (RAM_WRAPPER_SUPPORT_RMW),
    .SUPPORT_INJECT        (RAM_WRAPPER_SUPPORT_INJECT),
    .SUPPORT_ENGN_ERASE    (RAM_WRAPPER_SUPPORT_ENGN_ERASE),
    .SUPPORT_ERASE         (RAM_WRAPPER_SUPPORT_ERASE)
) u_ram_wrapper (
    //// Pervasive input signals
    .clk_i                     (gclk),
    .reset_na_i                (lp_rstn_i),

    //// CIU Interface
    // input
    .wdata_i                   (ciu_mem_wdata[CACHE_DATA_WIDTH - 1 : 0]),
    .addr_i                    (ciu_mem_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
    .en_i                      (ciu_mem_en),
    .we_i                      (ciu_mem_we[(CACHE_DATA_WIDTH/8) - 1 : 0]),
    // output
    .busy_o                    (mem_ciu_busy),
    .rdata_valid_o             (mem_ciu_rdata_valid),
    .rdata_o                   (mem_ciu_rdata[CACHE_DATA_WIDTH - 1 : 0]),

    //// Memory I/F
    // input
    .ram_qi_i                  (mem_rdata),
    // output
    .ram_me_o                  (mem_en),
    .ram_we_o                  (mem_we),
    .ram_adr_o                 (mem_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
    .ram_di_o                  (mem_wdata[CACHE_MEM_WIDTH - 1 : 0]),

    //// Erase I/F
    // output
    .engn_erase_done_o         (mem_ciu_engn_erase_done),
    .erase_busy_o              (mem_wrapper_erase_busy),
    .erase_done_o              (mem_erase_done),
    .err_erase_busy_o          (read_err_on_erase_busy),
    // input
    .engn_erase_start_i        (ciu_mem_engn_erase_start),
    .erase_start_i             (mem_erase_start),
    .erase_wdata_i             (mem_erase_wdata[CACHE_DATA_WIDTH - 1 : 0]),

    //// Error Inject and Error Log I/F
    // output
    .inject_done_o             (mem_err_inject_done),
    .inject_busy_o             (unused_inject_busy_o),
    .err_uncorr_o              (mem_err_uncorr),
    .err_addr_o                (mem_err_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
    .err_corr_o                (mem_err_corr),
    .r_err_parity_o            (unused_r_err_parity_o),
    .w_err_parity_o            (unused_w_err_parity_o),
    .rdatachk_o                (unused_rdatachk_o),
    // input
    .inject_i                  (mem_err_inject_en),
    .inject_addr_i             (mem_err_inject_addr[CACHE_MEM_ADDR_WIDTH - 1 : 0]),
    .inject_mask_i             (inject_mask_i),
    .err_chk_disable_i         (sinc_err_chk_disable_i),
    .err_parity_chk_disable_i  (sinc_err_parity_chk_disable_i),
    .addrchk_i                 (addrchk_i),
    .wdatachk_i                (wdatachk_i)
);

////
//// Clock Gating
////
assign clock_gate_rst_en = 1'b0;						// This one tied to 1'b0
assign cpu_mem_access = cpu_mem_en;
assign mem_init_in_action = (mem_erase_start || mem_init_active_r);
assign mem_inject_in_action = (mem_err_inject_en || mem_inject_active_r);
assign cmu_sinc_in_reset = (sync_ciu_reset || cmu_sinc_reset_active_r);
assign ciu_clock_waken = (cmu_busy || ciu_active || cpu_mem_access || cmu_sinc_in_reset || mem_inject_in_action || mem_init_in_action);
assign clock_gate_enable = (ciu_clock_waken || ciu_clock_waken_r);

always_comb begin
    nxt_mem_init_active = mem_init_active_r;

    if (mem_init_active_r) begin
	if (mem_erase_done) begin
	    nxt_mem_init_active = 1'b0;
	end
    end
    else begin // !mem_init_active_r
	if (mem_erase_start) begin
	    nxt_mem_init_active = 1'b1;
	end
    end
end

always_comb begin
    nxt_mem_inject_active = mem_inject_active_r;

    if (mem_inject_active_r) begin
	if (mem_err_inject_done) begin
	    nxt_mem_inject_active = 1'b0;
	end
    end
    else begin // !mem_inject_active_r
	if (mem_err_inject_en) begin
	    nxt_mem_inject_active = 1'b1;
	end
    end
end

always_comb begin
    nxt_cmu_sinc_reset_active = cmu_sinc_reset_active_r;

    if (cmu_sinc_reset_active_r) begin
	if (ciu_reset_reinit_completed) begin
	    nxt_cmu_sinc_reset_active = 1'b0;
	end
    end
    else begin // !cmu_sinc_reset_active_r
	if (sync_ciu_reset) begin
	    nxt_cmu_sinc_reset_active = 1'b1;
	end
    end
end

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
        ciu_clock_waken_r <= 1'b0;
	mem_init_active_r <= 1'b0;
	mem_inject_active_r <= 1'b0;
	cmu_sinc_reset_active_r <= 1'b0;
    end
    else begin // lp_rstn_i
        ciu_clock_waken_r <= ciu_clock_waken;
        mem_init_active_r <= nxt_mem_init_active;
        mem_inject_active_r <= nxt_mem_inject_active;
        cmu_sinc_reset_active_r <= nxt_cmu_sinc_reset_active;
    end
end

c_clock_gate_ovr u_clock_gate_ovr (
    .clk        (clk),
    .enable     (clock_gate_enable),
    .rst_en     (clock_gate_rst_en),
    .ovr_en     (clkg_override),
    .test_mode  (clkg_test_mode),
    .gated_clk  (gclk)
);

////
//// Assertions
////

`ifdef _USE_SINC_ASSERT_
      `include "../assert/sinc_ciu_assert.sv"
`endif
	
endmodule
