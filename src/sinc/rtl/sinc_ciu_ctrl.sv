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
// File        : sinc_ciu_ctrl.sv
// Description : CIU control logic for cache-miss handling, CPU read/write
//               arbitration, and MPU access violation detection.

module sinc_ciu_ctrl
    import sinc_pkg::*;
    #(
    // Parameters
    MPU_SINGLE_CYCLE = 0,	// 0: mpu_acc_vio available at next cycle; 1: at same cycle
    CPU_DATA_WIDTH = 32,	// DATA_WIDTH
    EIRAM_ADDR_WIDTH = 22,	// $clog2(EIRAM_SIZE) + 8, aligned to 4 Bytes, while EIRAM_SIZE default to 16384 KB (16MB)
    CACHE_ADDR_WIDTH = 14,	// $clog2(CACHE_SIZE) + 6, aligned to 128-bit longword, while CACHE_SIZE default to 256 KB
    CACHE_TAG_WIDTH = 8,	// $clog2(EIRAM_SIZE/CACHE_SIZE) + 2, while EIRAM_SIZE default to 16384 KB and CACHE_SIZE default to 256 KB
    CACHE_SETIDX_WIDTH = 8,	// $clog2(CACHE_SIZE/BLOCK_SIZE) + 8, while CACHE_SIZE default to 256 KB and BLOCK_SIZE default to 256 Bytes
    CACHE_DATA_WIDTH = 128	// 4*DATA_WIDTH
    ) (
    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input												clk,
    input 	       										lp_rstn_i,

    output logic										ciu_fault_err,
    output logic										ciu_active,
    output logic										ciu_acc_vio,
    output logic										cpu_read_upon_accvio,
    input                       						sync_ciu_reset,
    input												ext_mem_erase_busy,

    //****************************************************************
    // CPU I/F
    //    1) cpu_mem_priv_mode_i goes to mpu_wrapper
    //****************************************************************
    output logic                           				mem_cpu_busy,
    output logic                           				mem_cpu_rdata_vld,
    output logic [CPU_DATA_WIDTH-1:0]      				mem_cpu_rdata,
    output logic                           				mem_cpu_read_err,
    input                                  				cpu_mem_en,
    input                                  				cpu_mem_we,
    input								   				cpu_mem_loadstore,
    input								   				cpu_mem_priv_mode,
    input [(CPU_DATA_WIDTH/8) - 1 : 0]     				cpu_mem_wr_byte_en,
    input [EIRAM_ADDR_WIDTH - 1 : 0]       				cpu_mem_addr,
    input [CPU_DATA_WIDTH - 1 : 0]         				cpu_mem_wdata,

    //****************************************************************
    // RAM Wrapper Engine I/F
    //****************************************************************
    output logic [CACHE_DATA_WIDTH - 1 : 0]				ciu_mem_wdata,
    output logic [CACHE_ADDR_WIDTH - 1 : 0]				ciu_mem_addr,
    output logic										ciu_mem_en,
    output logic [(CACHE_DATA_WIDTH/8) - 1 : 0]			ciu_mem_we,
    input [CACHE_DATA_WIDTH - 1 : 0]					mem_ciu_rdata,
    input												mem_ciu_rdata_valid,
    input												mem_ciu_busy,
    input												mem_err_uncorr,

    //****************************************************************
    // Erase Opertion with RAM Wrapper
    //****************************************************************
    output logic										ciu_mem_engn_erase_start,
    input												mem_ciu_engn_erase_done,
    output logic										ciu_mem_erase_busy,

    //****************************************************************
    // MPU Interface
    //****************************************************************
    output logic [EIRAM_ADDR_WIDTH - 1 : 0] 			req_addr,
    output logic [4 - 1 : 0] 							req_id,
    output logic										req_en,
    output logic										req_we,
    output logic										req_xe,
    output logic										req_pm,
    input												mpu_acc_vio,
    input												mpu_busy,
    output logic										ext_acc_vio,

    //****************************************************************
    // CMU Interface
    //****************************************************************
    input                                               cmu_block_fetch_comp,
    input												cmu_block_fetch_err,
    input                                               cmu_busy,
    input sinc_state_t                                  cmu_sinc_state,
    input                                               cmu_mem_we,
    input [CACHE_ADDR_WIDTH - 1 : 0]                	cmu_mem_addr,
    input [CPU_DATA_WIDTH - 1 : 0]                      cmu_mem_wdata,
    output logic										ciu_mem_busy,
    output logic                                        ciu_reset_completed,
    output logic                                        ciu_cmu_cache_hit,
    output logic                                        ciu_block_fetch_req,
    output logic [EIRAM_ADDR_WIDTH - 1 : 0]             ciu_block_addr,

    //****************************************************************
    // Interface with VTAG and FIFO Status
    //****************************************************************
    input												vtag_cache_hit,
    input [2 - 1 : 0]                             		vtag_cache_hit_word_idx,
    input [2 - 1 : 0]                             		cache_fifo_status,
    input												vtag_parity_error,
    output logic										ciu_vtag_comp,
    output logic										ciu_vtag_update,
    output logic [CACHE_TAG_WIDTH - 1 : 0]				cache_tag,
    output logic [CACHE_SETIDX_WIDTH - 1 : 0]			cache_set_idx);

////
//// Local Parameters
////

////
//// Internal Signals
////
sinc_ciu_fsm_t 						ciu_cache_sm_r, nxt_ciu_cache_sm;
logic								ciu_cache_sm_fault;
logic [EIRAM_ADDR_WIDTH - 1 : 0]    cpu_mem_addr_r, nxt_cpu_mem_addr;
logic                           	mem_cpu_busy_r, nxt_mem_cpu_busy;
logic								valid_cpu_read, valid_cpu_write, valid_cmu_write;
logic                               mem_cpu_rdata_vld_r, nxt_mem_cpu_rdata_vld;
logic								mem_rread;
logic								cpu_mem_write;
logic								ciu_block_fetch_req_r, nxt_ciu_block_fetch_req;
logic								mem_ciu_erase_busy_r, nxt_mem_ciu_erase_busy;
logic [2 - 1 : 0]					block_write_sel;
logic [2 - 1 : 0]					block_read_sel_r, nxt_block_read_sel;
logic								cache_active_mode;
logic [CPU_DATA_WIDTH - 1 : 0]		cpu_mem_wdata_r, nxt_cpu_mem_wdata;
logic								ciu_mem_write_r, nxt_ciu_mem_write;
logic								ciu_active_r, nxt_ciu_active;
logic [(CPU_DATA_WIDTH/8) - 1 : 0]  write_bytes_en;
logic								valid_cpu_mem_we;
logic [(CPU_DATA_WIDTH/8) - 1 : 0]  cpu_mem_wr_byte_en_r, nxt_cpu_mem_wr_byte_en;
logic                               mpu_read_vio_r, nxt_mpu_read_vio;
logic								vtag_parity_err_r, nxt_vtag_parity_err;
logic								cmu_fetch_err_r, nxt_cmu_fetch_err;
logic								pending_cpu_mem_read_r, nxt_pending_cpu_mem_read;
logic								pending_cpu_access_upon_cache_failed_r, nxt_pending_cpu_access_upon_cache_failed;
logic								cpu_access_upon_mpu_busy;
logic	                            sync_eng_erase_r;
logic								cpu_access_upon_cache_failed;
logic								cpu_write_upon_cache_active;
logic								ext_acc_vio_r, nxt_ext_acc_vio;
logic								cache_miss_r, nxt_cache_miss;
logic								req_xe_r, nxt_req_xe;
logic								req_pm_r, nxt_req_pm;
logic								cpu_read_upon_erase_busy;
logic								other_error_r, nxt_other_error;
logic								pending_cpu_mem_write_r, nxt_pending_cpu_mem_write;
logic								cpu_write_upon_erase_busy;

////
//// Link to Output
////
assign ciu_block_addr = cpu_mem_addr_r;
assign mem_cpu_busy = (mem_cpu_busy_r || (pending_cpu_mem_write_r || pending_cpu_mem_read_r || pending_cpu_access_upon_cache_failed_r) || cmu_busy);
assign mem_cpu_rdata_vld = (mem_cpu_rdata_vld_r && (!mem_cpu_read_err));
assign ciu_block_fetch_req = ciu_block_fetch_req_r;
assign ciu_mem_erase_busy = mem_ciu_erase_busy_r;
assign ciu_mem_busy = mem_ciu_busy;			
assign ciu_fault_err = ciu_cache_sm_fault;		// (sinc_ciu_fault_r || ciu_cache_sm_fault);
assign ciu_active = ciu_active_r;

////
//// Place holder
////
assign req_id = 4'h0;	// Fixed value




assign ciu_acc_vio = (mpu_read_vio_r || (mpu_acc_vio && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_WRITE)));
assign valid_cpu_mem_we = (cpu_mem_we && (|cpu_mem_wr_byte_en));
assign cpu_read_upon_accvio = ((ciu_acc_vio && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ)) || cpu_access_upon_mpu_busy);
assign cpu_read_upon_erase_busy = (ext_mem_erase_busy && ((cpu_mem_en && (!cpu_mem_we)) || pending_cpu_mem_read_r));
assign cpu_write_upon_erase_busy = (ext_mem_erase_busy && ((cpu_mem_en && valid_cpu_mem_we) || pending_cpu_mem_write_r));

////
//// ext_acc_vio to instruct MPU for logging the related event
////	1) cache-active: All write requests will cause such external MPU violation
////	2) cache-failed: All requests (Read or Write) will cause such external MPU violation
////	3) cache_active: cmu_busy asserted upon the time while ciu_block_fetch_req is about to issue
////
assign cpu_write_upon_cache_active = (((cpu_mem_en && valid_cpu_mem_we) || pending_cpu_mem_write_r) && cache_active_mode);
assign cpu_access_upon_cache_failed = ((cpu_mem_en && ((!cpu_mem_we) || valid_cpu_mem_we)) && (sinc_state_t'(cmu_sinc_state) == CACHE_FAILED));

generate 
    if (MPU_SINGLE_CYCLE == 0) begin: ext_vio_next_cycle
	assign ext_acc_vio = ext_acc_vio_r;
    end
    else begin: ext_vio_same_cycle
	assign ext_acc_vio = nxt_ext_acc_vio;
    end 
endgenerate

////
//// Engine Erase
////
assign ciu_mem_engn_erase_start = (sync_eng_erase_r && !mem_ciu_erase_busy_r);
assign ciu_reset_completed = (mem_ciu_erase_busy_r && mem_ciu_engn_erase_done);

always_comb begin
    // default
    nxt_mem_ciu_erase_busy = mem_ciu_erase_busy_r;

    if (sync_eng_erase_r) begin
	nxt_mem_ciu_erase_busy = 1'b1;
    end
    else begin // !sync_ciu_reset
    	if (ciu_reset_completed) begin
	    nxt_mem_ciu_erase_busy = 1'b0;
	end
    end
end

////
//// valid_cpu_read and valid_cpu_write
////	1) CPU Read can be only valid in Disable, Initialization and Cache Active.
////		1.1) CPU Read not allowed if CIU_INACT (i.e., Invalid or Cache Failed).
////	2) CPU Write can be only valid in Disable and Initialization.
////		2.1) CPU Write not allowed if CIU_INACT (i.e., Invalid or Cache Failed) or CIU_CACHE_ACT.
////	3) cmu_state needs to be stable for any read and write from CPU.
////
assign valid_cpu_read = (!cmu_busy) && (!cpu_read_upon_erase_busy) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && 
		( ((cpu_mem_en && (!cpu_mem_we)) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || pending_cpu_mem_read_r );
assign valid_cpu_write = (!cmu_busy) && (!cpu_write_upon_erase_busy) && ((sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && (!cache_active_mode)) && 
		( ((cpu_mem_en && valid_cpu_mem_we) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || pending_cpu_mem_write_r );

////
//// valid_cmu_write
////	1) CMU Write can be valid only in Cache Active.
assign cache_active_mode = (sinc_state_t'(cmu_sinc_state) == CACHE_ACTIVE);
assign valid_cmu_write = cache_active_mode && cmu_mem_we;

////
//// Generating ciu_mem_en, ciu_mem_we and ciu_mem_addr to RAM Wrapper
////		also req_en, req_we and req_addr to MPU
////	1) Address from 
////	    1.1) CPU to performing read or write:	cpu_mem_addr[EIRAM_ADDR_WIDTH - 1 : 0]
////	    1.2) CMU to performing write:		cmu_mem_addr[CACHE_ADDR_WIDTH - 1 : 0]
////	2) Address To 
////	    2.1) RAM Wrapper for performing read or write:	ciu_mem_addr[CACHE_ADDR_WIDTH - 1 : 0] 
////	    2.2) MPU Wrapper for checking read or write: 	cpu_mem_addr -> req_addr[EIRAM_ADDR_WIDTH - 1 : 0]
////	    2.4) CMU to fetching from EIRAM:			cpu_mem_addr_r -> ciu_block_addr[EIRAM_ADDR_WIDTH - 1 : 0]
////	3) Index with tag for 
////	    3.1) updating VTAG and FIFO Status:	cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0] and cache_tag[CACHE_TAG_WIDTH - 1 : 0]
////	    3.2) performing tag search:		cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0] and cache_tag[CACHE_TAG_WIDTH - 1 : 0]
////
assign ciu_mem_en = ((valid_cpu_read || mem_rread) || cpu_mem_write || valid_cmu_write);
assign req_we = (valid_cpu_write || (nxt_ext_acc_vio && (valid_cpu_mem_we || pending_cpu_mem_write_r)));

always_comb begin
    // default
    ciu_mem_addr = cpu_mem_addr[CACHE_ADDR_WIDTH - 1 : 0];
    ciu_mem_wdata = {(CACHE_DATA_WIDTH/CPU_DATA_WIDTH){cpu_mem_wdata[CPU_DATA_WIDTH - 1 : 0]}};
    req_addr = cpu_mem_addr;
    req_xe = (~cpu_mem_loadstore);   // Used to be fixed to 0
    req_pm = cpu_mem_priv_mode;

    if (cache_active_mode) begin
    	if (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_CACHE_MISS) begin
	    // for CMU Write
    	    ciu_mem_addr = cmu_mem_addr[CACHE_ADDR_WIDTH - 1 : 0];
	    ciu_mem_wdata = {(CACHE_DATA_WIDTH/CPU_DATA_WIDTH){cmu_mem_wdata[CPU_DATA_WIDTH - 1 : 0]}};
	end
	else begin
    	    if ((sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_RREAD) || (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ)) begin
		// for original CPU Read or
		// for pending CPU Read or
		// for CPU re-read after Cache Missed
		ciu_mem_addr = cpu_mem_addr_r[CACHE_ADDR_WIDTH - 1 : 0]; 
    	        req_addr = cpu_mem_addr_r;
		req_xe = req_xe_r;
		req_pm = req_pm_r;
	    end
	    else begin
	    	if (pending_cpu_mem_read_r) begin
		    ciu_mem_addr = cpu_mem_addr_r[CACHE_ADDR_WIDTH - 1 : 0]; 
    	    	    req_addr = cpu_mem_addr_r;
		    req_xe = req_xe_r;
		    req_pm = req_pm_r;
	    	end
	    end
	end
    end
    else begin // !cache_active_mode
	if ((sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_WRITE) || (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_EXTRA)) begin
	    ciu_mem_addr = cpu_mem_addr_r[(CACHE_ADDR_WIDTH + 2) - 1 : 2];
    	    ciu_mem_wdata = {(CACHE_DATA_WIDTH/CPU_DATA_WIDTH){cpu_mem_wdata_r[CPU_DATA_WIDTH - 1 : 0]}};
    	    req_addr = cpu_mem_addr_r;
	    req_xe = req_xe_r;
	    req_pm = req_pm_r;
	end
	else begin
	    if (pending_cpu_mem_read_r || pending_cpu_mem_write_r) begin
		ciu_mem_addr = cpu_mem_addr_r[(CACHE_ADDR_WIDTH + 2) - 1 : 2]; 
    	    	req_addr = cpu_mem_addr_r;
		req_xe = req_xe_r;
	    	req_pm = req_pm_r;
	    end
	    else begin
	    	ciu_mem_addr = cpu_mem_addr[(CACHE_ADDR_WIDTH + 2) - 1 : 2];
	    end
	end
    end
end

generate 

	if (MPU_SINGLE_CYCLE == 0) begin: gen_mpu_next_cycle // generate

always_comb begin
    // default
    block_write_sel = cpu_mem_addr_r[1 : 0];
    write_bytes_en = cpu_mem_wr_byte_en_r;

    if (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_CACHE_MISS) begin
    	block_write_sel = cache_fifo_status;
	write_bytes_en = {(CPU_DATA_WIDTH/8){1'b1}};
    end

end

always_comb begin
    // default
    ciu_mem_we = 16'h0000;

    if (ciu_mem_write_r && (!(mpu_acc_vio || ext_acc_vio_r))) begin
      case (block_write_sel[1:0])
	2'b00: ciu_mem_we = {12'h000, write_bytes_en};
	2'b01: ciu_mem_we = {8'h00, write_bytes_en, 4'h0};
	2'b10: ciu_mem_we = {4'h0, write_bytes_en, 8'h00};
	2'b11: ciu_mem_we = {write_bytes_en, 12'h000};
      endcase
    end
end
	end
	else begin: gen_mpu_same_cycle // such as MPU_SINGLE_CYCLE == 1

always_comb begin
    // default
    block_write_sel = cpu_mem_addr[1 : 0];
    write_bytes_en = cpu_mem_wr_byte_en;

    if (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_CACHE_MISS) begin
    	block_write_sel = cache_fifo_status;
	write_bytes_en = {(CPU_DATA_WIDTH/8){1'b1}};
    end

end

always_comb begin
    // default
    ciu_mem_we = 16'h0000;

    if ((cpu_mem_write || ciu_mem_write_r)) begin
      case (block_write_sel[1:0])
	2'b00: ciu_mem_we = {12'h000, write_bytes_en};
	2'b01: ciu_mem_we = {8'h00, write_bytes_en, 4'h0};
	2'b10: ciu_mem_we = {4'h0, write_bytes_en, 8'h00};
	2'b11: ciu_mem_we = {write_bytes_en, 12'h000};
      endcase
    end
end

	end

endgenerate

////
//// ciu_vtag_comp, cache_tag and cache_set_idx
////
assign ciu_vtag_comp = (cache_active_mode && ((( (cpu_mem_en && (!valid_cpu_mem_we)) || pending_cpu_mem_read_r ) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || mem_rread));

always_comb begin
    // default
    cache_tag = cpu_mem_addr[EIRAM_ADDR_WIDTH - 1 : CACHE_ADDR_WIDTH];
    cache_set_idx = cpu_mem_addr[CACHE_ADDR_WIDTH - 1 -: CACHE_SETIDX_WIDTH];

    if ((sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_CACHE_MISS) || (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_RREAD)) begin
	// for ciu_vtag_updating or comparing
    	cache_tag[CACHE_TAG_WIDTH - 1 : 0] = cpu_mem_addr_r[EIRAM_ADDR_WIDTH - 1 : CACHE_ADDR_WIDTH];
    	cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0] = cpu_mem_addr_r[CACHE_ADDR_WIDTH - 1 -: CACHE_SETIDX_WIDTH];
    end
    else begin
	if ((sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE) && pending_cpu_mem_read_r) begin
    	    cache_tag[CACHE_TAG_WIDTH - 1 : 0] = cpu_mem_addr_r[EIRAM_ADDR_WIDTH - 1 : CACHE_ADDR_WIDTH];
    	    cache_set_idx[CACHE_SETIDX_WIDTH - 1 : 0] = cpu_mem_addr_r[CACHE_ADDR_WIDTH - 1 -: CACHE_SETIDX_WIDTH];
	end
    end
end

////
//// Generating mem_cpu_rdata[CPU_DATA_WIDTH-1:0] from mem_ciu_rdata[CACHE_DATA_WIDTH-1:0]
////	Note that mem_cpu_rdata not flopped out after MUX
////
always_comb begin
    // default
    nxt_block_read_sel = block_read_sel_r;

    if (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ) begin
	if (cache_active_mode) begin
    	    nxt_block_read_sel = vtag_cache_hit_word_idx;
	end
	else begin // !cache_active_mode
	    nxt_block_read_sel = cpu_mem_addr_r[1 : 0];
	end
    end
end

always_comb begin
    case (block_read_sel_r)
	2'b00: begin
		mem_cpu_rdata = mem_ciu_rdata[0 +: 32];
	  end
	2'b01: begin
		mem_cpu_rdata = mem_ciu_rdata[32 +: 32];
	  end
	2'b10: begin
		mem_cpu_rdata = mem_ciu_rdata[64 +: 32];
	  end
	2'b11: begin
		mem_cpu_rdata = mem_ciu_rdata[96 +: 32];
	  end
    endcase
end

////
//// rdata_avail and ciu_cmu_cache_hit
////
assign ciu_cmu_cache_hit = (cache_active_mode && vtag_cache_hit && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ) && (!cache_miss_r));

////
//// ciu_cache_sm_r
////
generate 

	if (MPU_SINGLE_CYCLE == 0) begin: gen_mpu_single_cycle // generate

assign req_en = (((valid_cpu_read || mem_rread || valid_cpu_write) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE) && (!mpu_busy)) || nxt_ext_acc_vio);
assign cpu_access_upon_mpu_busy = (cpu_mem_en && mpu_busy);

always_comb begin
    // default
    nxt_ciu_cache_sm = ciu_cache_sm_r;
    nxt_mem_cpu_busy = mem_cpu_busy_r;
    nxt_cpu_mem_addr = cpu_mem_addr_r;
    nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en_r;
    nxt_cpu_mem_wdata = cpu_mem_wdata_r;
    nxt_mem_cpu_rdata_vld = 1'b0;
    nxt_ciu_block_fetch_req = 1'b0;
    ciu_vtag_update = 1'b0;
    mem_rread = 1'b0;
    cpu_mem_write = 1'b0;
    nxt_ciu_mem_write = ciu_mem_write_r;
    ciu_cache_sm_fault = 1'b0;
    mem_cpu_read_err = 1'b0;
    nxt_ciu_active = ciu_active_r;
    nxt_mpu_read_vio = 1'b0;
    nxt_vtag_parity_err = 1'b0;
    nxt_cmu_fetch_err = 1'b0;
    nxt_pending_cpu_mem_read = pending_cpu_mem_read_r;
    nxt_pending_cpu_access_upon_cache_failed = pending_cpu_access_upon_cache_failed_r;
    nxt_ext_acc_vio = 1'b0;
    nxt_cache_miss = cache_miss_r;
    nxt_req_xe = req_xe_r;
    nxt_req_pm = req_pm_r;
    nxt_other_error = other_error_r;
    nxt_pending_cpu_mem_write = pending_cpu_mem_write_r;

    case (ciu_cache_sm_r)
      CIU_IDLE: begin
	    if (valid_cpu_read) begin
		if (pending_cpu_mem_read_r) begin
    		    nxt_cpu_mem_addr = cpu_mem_addr_r;
		    nxt_pending_cpu_mem_read = 1'b0;
		end
		else begin // !pending_cpu_mem_read_r
    		    nxt_cpu_mem_addr = cpu_mem_addr;
    		    nxt_req_xe = req_xe;
    		    nxt_req_pm = req_pm;
		end
    		nxt_mem_cpu_busy = 1'b1;
		nxt_ciu_active = 1'b1;
            	nxt_ciu_cache_sm = CIU_MEM_READ;
	    end
	    else begin // !valid_cpu_read
		if (valid_cpu_write) begin
		    if (pending_cpu_mem_write_r) begin
    		    	nxt_cpu_mem_addr = cpu_mem_addr_r;
    		    	nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en_r;
    		    	nxt_cpu_mem_wdata = cpu_mem_wdata_r;
		    	nxt_pending_cpu_mem_write = 1'b0;
		    end
		    else begin
    		    	nxt_cpu_mem_addr = cpu_mem_addr;
    		    	nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en;
    		    	nxt_cpu_mem_wdata = cpu_mem_wdata;
    		    	nxt_req_xe = req_xe;
    		    	nxt_req_pm = req_pm;
		    end
    		    nxt_mem_cpu_busy = 1'b1;
    		    nxt_ciu_mem_write = 1'b1;
		    nxt_ciu_active = 1'b1;
		    nxt_ciu_cache_sm = CIU_MEM_WRITE;
		end
		else begin
		    if (cpu_access_upon_cache_failed || pending_cpu_access_upon_cache_failed_r || cpu_read_upon_erase_busy || cpu_write_upon_erase_busy) begin
    		        nxt_ext_acc_vio = (cpu_access_upon_cache_failed || pending_cpu_access_upon_cache_failed_r);
		        nxt_other_error = cpu_read_upon_erase_busy;
    			nxt_mem_cpu_busy = 1'b1;
			nxt_ciu_active = 1'b1;
			if ((cpu_mem_en && (!cpu_mem_we)) || (pending_cpu_access_upon_cache_failed_r && (!pending_cpu_mem_write_r)) || pending_cpu_mem_read_r) begin
			    if (pending_cpu_mem_read_r) begin
				nxt_pending_cpu_mem_read = 1'b0;
			    end
            		    nxt_ciu_cache_sm = CIU_MEM_READ;
			end
			else begin // SP Write
		            nxt_other_error = cpu_write_upon_erase_busy;
		    	    nxt_ciu_cache_sm = CIU_MEM_WRITE;
			end
		    end
		    else begin // !cpu_access_upon_cache_failed
			if (cpu_write_upon_cache_active) begin
    			    nxt_ext_acc_vio = 1'b1;
    			    nxt_mem_cpu_busy = 1'b1;
			    nxt_ciu_active = 1'b1;
		    	    nxt_ciu_cache_sm = CIU_MEM_WRITE;
			end
			else begin
			    if (pending_cpu_mem_write_r && cache_active_mode) begin
				nxt_pending_cpu_mem_write = 1'b0;
    			    	nxt_ext_acc_vio = 1'b1;
    			    	nxt_mem_cpu_busy = 1'b1;
			    	nxt_ciu_active = 1'b1;
		    	    	nxt_ciu_cache_sm = CIU_MEM_WRITE;
			    end
			end
		    end
		end
	    end
	end
      CIU_MEM_READ: begin
	    if (mpu_acc_vio || ext_acc_vio_r || other_error_r || ext_mem_erase_busy) begin
    		nxt_mpu_read_vio = (mpu_acc_vio || ext_acc_vio_r);
    		nxt_mem_cpu_busy = 1'b0;
            	nxt_ciu_cache_sm = CIU_WAIT;
	    end
	    else begin // !mpu_acc_vio && !ext_acc_vio_r
		if (cache_active_mode) begin
		    if (vtag_parity_error) begin
    			nxt_vtag_parity_err = 1'b1;
            	    	nxt_ciu_cache_sm = CIU_WAIT;
		    end
		    else begin // !vtag_parity_error
			if (vtag_cache_hit) begin
    	    	    	    nxt_mem_cpu_rdata_vld = 1'b1;
                            if (cache_miss_r) begin
                                nxt_cache_miss = 1'b0;
                            end
            	    	    nxt_ciu_cache_sm = CIU_WAIT;
			end
			else begin // !vtag_cache_hit
                            if (cmu_busy) begin
    							nxt_mem_cpu_busy = 1'b0;
                                nxt_ciu_cache_sm = CIU_WAIT;
                            end
                            else begin // !cmu_busy
                                // ciu_block_addr from cpu_mem_addr_r
                                nxt_ciu_block_fetch_req = 1'b1;
                                nxt_ciu_mem_write = 1'b1;
                                nxt_cache_miss = 1'b1;
                                nxt_ciu_cache_sm = CIU_CACHE_MISS;
                            end
			end
		    end
		end
		else begin // !cache_active_mode
		    if (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) begin
			// CACHE_FAILED will make mem_cpu_rdata_vld_r use default 0
			//	thus mem_cpu_read_err set to 1 in CIU_WAIT
    	    	nxt_mem_cpu_rdata_vld = 1'b1;
		    end
            	nxt_ciu_cache_sm = CIU_WAIT;
		end
	    end
	end
      CIU_WAIT: begin
	    nxt_ciu_active = 1'b0;
    	nxt_mem_cpu_busy = 1'b0;
        nxt_ciu_cache_sm = CIU_IDLE;

	    if (cpu_mem_en && (!cpu_mem_we)) begin
		if (cpu_access_upon_cache_failed) begin
		    nxt_pending_cpu_access_upon_cache_failed = 1'b1;
		end
		else begin // !cpu_access_upon_cache_failed
    		    nxt_pending_cpu_mem_read = 1'b1;
    		    nxt_cpu_mem_addr = cpu_mem_addr;
    		    nxt_req_xe = req_xe;
    		    nxt_req_pm = req_pm;
	    	    if (pending_cpu_access_upon_cache_failed_r) begin
			nxt_pending_cpu_access_upon_cache_failed = 1'b0;
		    end
		end
	    end
	    else begin // !cpu_mem_en || cpu_mem_we
	    	if (cpu_mem_en && valid_cpu_mem_we) begin
    		    nxt_pending_cpu_mem_write = 1'b1;
		    if (cpu_access_upon_cache_failed) begin
		    	nxt_pending_cpu_access_upon_cache_failed = 1'b1;
		    end
		    else begin
    		    	nxt_cpu_mem_addr = cpu_mem_addr;
    		    	nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en;
    		    	nxt_cpu_mem_wdata = cpu_mem_wdata;
    		    	nxt_req_xe = req_xe;
    		    	nxt_req_pm = req_pm;
	    		if (pending_cpu_access_upon_cache_failed_r) begin
		    	    nxt_pending_cpu_access_upon_cache_failed = 1'b0;
	    		end
		    end
		end
		else begin
		    if (req_xe_r) begin
    		    	nxt_req_xe = 1'b0;
		    end
		    if (req_pm_r) begin
    		    	nxt_req_pm = 1'b0;
		    end
	    	    if (pending_cpu_access_upon_cache_failed_r) begin
		    	nxt_pending_cpu_access_upon_cache_failed = 1'b0;
	    	    end
		end
	    end

	    if (ciu_mem_write_r) begin
    		nxt_ciu_mem_write = 1'b0;
	    end

	    if (mpu_read_vio_r || vtag_parity_err_r || cmu_fetch_err_r || other_error_r || (ext_mem_erase_busy && (!ciu_mem_write_r))) begin
	    	mem_cpu_read_err = 1'b1;
		if (other_error_r) begin
		    nxt_other_error = 1'b0;
		end
	    end
	    else begin // !mpu_read_vio_r && !vtag_parity_err_r && !cmu_fetch_err_r && !other_error_r
	    	if ((mem_ciu_rdata_valid != mem_cpu_rdata_vld_r) || (mem_err_uncorr && mem_cpu_rdata_vld_r)) begin
	    	// 1) these two rdata_valid expected to match, either 0 or 1
			// 2) mem_err_uncorr for the expected read
		    mem_cpu_read_err = 1'b1;
	    	end
	    end
	end
      CIU_CACHE_MISS: begin
	    if (cmu_block_fetch_comp) begin
		if (cmu_block_fetch_err) begin
    		    nxt_cmu_fetch_err = 1'b1;
            	    nxt_ciu_cache_sm = CIU_WAIT;
		end
		else begin // !cmu_block_fetch_err
    		    ciu_vtag_update = 1'b1;
    		    nxt_ciu_mem_write = 1'b0;
		    nxt_ciu_cache_sm = CIU_RREAD;
		end
	    end
	end
      CIU_RREAD: begin
    	    mem_rread = 1'b1;
	    nxt_ciu_cache_sm = CIU_MEM_READ;
	end
      CIU_MEM_WRITE: begin
	    if (mpu_acc_vio || ext_acc_vio_r || other_error_r) begin
    	    	nxt_mem_cpu_busy = 1'b0;
    		nxt_ciu_mem_write = 1'b0;
		nxt_ciu_active = 1'b0;
		if (pending_cpu_mem_write_r) begin
		    nxt_pending_cpu_mem_write = 1'b0;
		end
		if (other_error_r) begin
		    nxt_other_error = 1'b0;
		end
		if (pending_cpu_access_upon_cache_failed_r) begin
		    nxt_pending_cpu_access_upon_cache_failed = 1'b0;
		end
            	nxt_ciu_cache_sm = CIU_IDLE;
	    end
	    else begin // !mpu_acc_vio && !ext_acc_vio_r
		cpu_mem_write = 1'b1;
            	nxt_ciu_cache_sm = CIU_EXTRA;
	    end
	end
      CIU_EXTRA: begin
            nxt_ciu_cache_sm = CIU_WAIT;
	end
      CIU_SM_FAULT: begin
    	    nxt_mem_cpu_busy = 1'b0;
	    nxt_ciu_active = 1'b0;
	    ciu_cache_sm_fault = 1'b1;
            nxt_ciu_cache_sm = CIU_IDLE;
	end
      default: begin
            //// All legal states are decoded above
            //// A fault must occure to hit this code
	    ciu_cache_sm_fault = 1'b1;
	    nxt_ciu_active = 1'b1;
            nxt_ciu_cache_sm = CIU_SM_FAULT;
        end
    endcase
end

	end
	else begin: gen_no_mpu_single_cycle // such as MPU_SINGLE_CYCLE == 1

logic							vio_r, nxt_vio;

assign req_en = ((valid_cpu_read || mem_rread || valid_cpu_write) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE));
assign cpu_access_upon_mpu_busy = (1'b0 & mpu_busy);		// mpu_busy cannot be used for Case 1

always_comb begin
    // default
    nxt_ciu_cache_sm = ciu_cache_sm_r;
    nxt_mem_cpu_busy = mem_cpu_busy_r;
    nxt_cpu_mem_addr = cpu_mem_addr_r;
    nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en_r;
    nxt_cpu_mem_wdata = cpu_mem_wdata_r;
    nxt_mem_cpu_rdata_vld = 1'b0;
    nxt_ciu_block_fetch_req = 1'b0;
    ciu_vtag_update = 1'b0;
    mem_rread = 1'b0;
    cpu_mem_write = 1'b0;
    nxt_ciu_mem_write = ciu_mem_write_r;
    ciu_cache_sm_fault = 1'b0;
    mem_cpu_read_err = 1'b0;
    nxt_vio = vio_r;
    nxt_ciu_active = ciu_active_r;
    nxt_mpu_read_vio = 1'b0;
    nxt_vtag_parity_err = 1'b0;
    nxt_cmu_fetch_err = 1'b0;
    nxt_pending_cpu_mem_read = pending_cpu_mem_read_r;
    nxt_pending_cpu_access_upon_cache_failed = pending_cpu_access_upon_cache_failed_r;
    nxt_ext_acc_vio = 1'b0;
    nxt_cache_miss = cache_miss_r;
    nxt_req_xe = req_xe_r;
    nxt_req_pm = req_pm_r;
    nxt_other_error = other_error_r;
    nxt_pending_cpu_mem_write = pending_cpu_mem_write_r;

    case (ciu_cache_sm_r)
      CIU_IDLE: begin
	    if (valid_cpu_read) begin
		if (pending_cpu_mem_read_r) begin
    		    nxt_cpu_mem_addr = cpu_mem_addr_r;
		    nxt_pending_cpu_mem_read = 1'b0;
		end
		else begin // !pending_cpu_mem_read_r
    		    nxt_cpu_mem_addr = cpu_mem_addr;
    		    nxt_req_xe = req_xe;
    		    nxt_req_pm = req_pm;
		end
    		nxt_mem_cpu_busy = 1'b1;
		nxt_ciu_active = 1'b1;
            	nxt_ciu_cache_sm = CIU_MEM_READ;
    		nxt_vio = mpu_acc_vio;
	    end
	    else begin // !valid_cpu_read
		if (cpu_access_upon_cache_failed || pending_cpu_access_upon_cache_failed_r || cpu_read_upon_erase_busy) begin
    		    nxt_ext_acc_vio = (cpu_access_upon_cache_failed || pending_cpu_access_upon_cache_failed_r);
		    nxt_other_error = cpu_read_upon_erase_busy;
    		    nxt_mem_cpu_busy = 1'b1;
		    nxt_ciu_active = 1'b1;
		    if ((cpu_mem_en && (!cpu_mem_we)) || pending_cpu_access_upon_cache_failed_r) begin
            		nxt_ciu_cache_sm = CIU_MEM_READ;
		    end
		    else begin
            	    	nxt_ciu_cache_sm = CIU_EXTRA;
		    end
		end
		else begin // !cpu_access_upon_cache_failed
		    if (cpu_write_upon_cache_active) begin
    		    	nxt_ext_acc_vio = 1'b1;
    		    	nxt_mem_cpu_busy = 1'b1;
		    	nxt_ciu_active = 1'b1;
            	    	nxt_ciu_cache_sm = CIU_EXTRA;
		    end
		    else begin // !cpu_write_upon_cache_active
		    	if (valid_cpu_write && (!mpu_acc_vio)) begin
    		    	    nxt_cpu_mem_addr = cpu_mem_addr;
    		    	    nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en;
    		    	    nxt_cpu_mem_wdata = cpu_mem_wdata;
    		    	    nxt_mem_cpu_busy = 1'b1;
    		    	    nxt_ciu_mem_write = 1'b1;
		    	    cpu_mem_write = 1'b1;
    		    	    nxt_ciu_active = 1'b1;
            	    	    nxt_ciu_cache_sm = CIU_EXTRA;
		    	end
		    end
		end
	    end
	end
      CIU_MEM_READ: begin
	    if (vio_r || ext_acc_vio_r || other_error_r || ext_mem_erase_busy) begin
    		nxt_mpu_read_vio = (vio_r || ext_acc_vio_r);
    		nxt_mem_cpu_busy = 1'b0;
            	nxt_ciu_cache_sm = CIU_WAIT;
	    end
	    else begin // !vio_r && !ext_acc_vio_r 
		if (cache_active_mode) begin
		    if (vtag_parity_error) begin
    			nxt_vtag_parity_err = 1'b1;
            	    	nxt_ciu_cache_sm = CIU_WAIT;
		    end
		    else begin // !vtag_parity_error
			if (vtag_cache_hit) begin
    	    	    	    nxt_mem_cpu_rdata_vld = 1'b1;
                            if (cache_miss_r) begin
                                nxt_cache_miss = 1'b0;
                            end
            	    	    nxt_ciu_cache_sm = CIU_WAIT;
			end
			else begin // !vtag_cache_hit
		            // ciu_block_addr from cpu_mem_addr_r
    		    	    nxt_ciu_block_fetch_req = 1'b1;
    		    	    nxt_ciu_mem_write = 1'b1;
			    nxt_cache_miss = 1'b1;
            	    	    nxt_ciu_cache_sm = CIU_CACHE_MISS;
			end
		    end
		end
		else begin // !cache_active_mode
		    if (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) begin
			// CACHE_FAILED will make mem_cpu_rdata_vld_r use default 0
			//	thus mem_cpu_read_err set to 1 in CIU_WAIT
    	    	nxt_mem_cpu_rdata_vld = 1'b1;
		    end
            	nxt_ciu_cache_sm = CIU_WAIT;
		end
	    end
	end
      CIU_WAIT: begin
	    nxt_ciu_active = 1'b0;
    	    nxt_mem_cpu_busy = 1'b0;
            nxt_ciu_cache_sm = CIU_IDLE;

	    if (cpu_mem_en && (!cpu_mem_we)) begin
		if (cpu_access_upon_cache_failed) begin
		    nxt_pending_cpu_access_upon_cache_failed = 1'b1;
		end
		else begin // !cpu_access_upon_cache_failed
    		    nxt_pending_cpu_mem_read = 1'b1;
    		    nxt_vio = 1'b0;
    		    nxt_cpu_mem_addr = cpu_mem_addr;
    		    nxt_req_xe = req_xe;
    		    nxt_req_pm = req_pm;
		end
	    end
	    else begin // !cpu_mem_en || cpu_mem_we
	    	if (cpu_mem_en && valid_cpu_mem_we) begin
    		    nxt_pending_cpu_mem_write = 1'b1;
    		    nxt_cpu_mem_addr = cpu_mem_addr;
    		    nxt_cpu_mem_wr_byte_en = cpu_mem_wr_byte_en;
    		    nxt_cpu_mem_wdata = cpu_mem_wdata;
    		    nxt_req_xe = req_xe;
    		    nxt_req_pm = req_pm;
		end
		else begin
		    if (req_xe_r) begin
    		    	nxt_req_xe = 1'b0;
		    end
		    if (req_pm_r) begin
    		    	nxt_req_pm = 1'b0;
		    end
		end
	    end

	    if (pending_cpu_access_upon_cache_failed_r) begin
		nxt_pending_cpu_access_upon_cache_failed = 1'b0;
	    end

	    if (ciu_mem_write_r) begin
    		nxt_ciu_mem_write = 1'b0;
	    end

	    if (mpu_read_vio_r || vtag_parity_err_r || cmu_fetch_err_r || other_error_r || (ext_mem_erase_busy && (!ciu_mem_write_r))) begin
	    	mem_cpu_read_err = 1'b1;
		if (other_error_r) begin
		    nxt_other_error = 1'b0;
		end
	    end
	    else begin // !mpu_read_vio_r && !vtag_parity_err_r && !cmu_fetch_err_r && !other_error_r
	    	if ((mem_ciu_rdata_valid != mem_cpu_rdata_vld_r) || (mem_err_uncorr && mem_cpu_rdata_vld_r)) begin
	    	// 1) these two rdata_valid expected to match, either 0 or 1
			// 2) mem_err_uncorr for the expected read
		    mem_cpu_read_err = 1'b1;
	    	end
	    end
	end
      CIU_CACHE_MISS: begin
	    if (cmu_block_fetch_comp) begin
		if (cmu_block_fetch_err) begin
		    mem_cpu_read_err = 1'b1;
            	    nxt_ciu_cache_sm = CIU_SM_FAULT;
		end
		else begin // !cmu_block_fetch_err
    		    ciu_vtag_update = 1'b1;
    		    nxt_ciu_mem_write = 1'b0;
		    nxt_ciu_cache_sm = CIU_RREAD;
		end
	    end
	end
      CIU_RREAD: begin
    	    mem_rread = 1'b1;
	    nxt_ciu_cache_sm = CIU_MEM_READ;
	end
      CIU_EXTRA: begin
            nxt_ciu_cache_sm = CIU_WAIT;
	end
      CIU_SM_FAULT: begin
	    mem_cpu_read_err = mpu_read_vio_r;
    	    nxt_mem_cpu_busy = 1'b0;
	    nxt_ciu_active = 1'b0;
            nxt_ciu_cache_sm = CIU_IDLE;
	end
      default: begin
            //// All legal states are decoded above
            //// A fault must occure to hit this code
	    ciu_cache_sm_fault = 1'b1;
    	    nxt_ciu_active = 1'b1;
            nxt_ciu_cache_sm = CIU_SM_FAULT;
        end
    endcase
end

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
	vio_r <= 1'b0;
    end
    else begin // lp_rstn_i
	if (sync_ciu_reset) begin
	    vio_r <= 1'b0;
	end 
	else begin // !sync_ciu_reset 
	    vio_r <= nxt_vio;
	end
    end
end

	end // generate

endgenerate

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
        ciu_cache_sm_r <= CIU_IDLE;
    end
    else begin
	if (sync_ciu_reset) begin
            ciu_cache_sm_r <= CIU_IDLE;
	end
	else begin // !sync_ciu_reset
            ciu_cache_sm_r <= nxt_ciu_cache_sm;
	end
    end
end

////
//// Flops
////
always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
		sync_eng_erase_r <= 1'b0;
		mem_ciu_erase_busy_r <= 1'b0;
		mem_cpu_busy_r <= 1'b0;
		cpu_mem_addr_r <= {EIRAM_ADDR_WIDTH{1'b0}};
		cpu_mem_wr_byte_en_r <= {(CPU_DATA_WIDTH/8){1'b0}};
		cpu_mem_wdata_r <= {CPU_DATA_WIDTH{1'b0}};
		block_read_sel_r <= {2{1'b0}};
		mem_cpu_rdata_vld_r <= 1'b0;
		ciu_block_fetch_req_r <= 1'b0;
		ciu_mem_write_r <= 1'b0;
		//sinc_ciu_fault_r <= 1'b0;
		ciu_active_r <= 1'b0;
		mpu_read_vio_r <= 1'b0;
		vtag_parity_err_r <= 1'b0;
		cmu_fetch_err_r <= 1'b0;
		pending_cpu_mem_read_r <= 1'b0;
		pending_cpu_access_upon_cache_failed_r <= 1'b0;
		ext_acc_vio_r <= 1'b0;
		cache_miss_r <= 1'b0;
		req_xe_r <= 1'b0;
		req_pm_r <= 1'b0;
		other_error_r <= 1'b0;
		pending_cpu_mem_write_r <= 1'b0;
    end
    else begin // lp_rstn_i
	sync_eng_erase_r <= sync_ciu_reset;

	if (sync_ciu_reset) begin
	    mem_ciu_erase_busy_r <= 1'b0;
	    mem_cpu_busy_r <= 1'b0;
	    cpu_mem_addr_r <= {EIRAM_ADDR_WIDTH{1'b0}};
	    cpu_mem_wr_byte_en_r <= {(CPU_DATA_WIDTH/8){1'b0}};
	    cpu_mem_wdata_r <= {CPU_DATA_WIDTH{1'b0}};
	    block_read_sel_r <= {2{1'b0}};
	    mem_cpu_rdata_vld_r <= 1'b0;
	    ciu_block_fetch_req_r <= 1'b0;
	    ciu_mem_write_r <= 1'b0;
	    //sinc_ciu_fault_r <= 1'b0;
	    ciu_active_r <= 1'b0;
	    mpu_read_vio_r <= 1'b0;
	    vtag_parity_err_r <= 1'b0;
	    cmu_fetch_err_r <= 1'b0;
	    pending_cpu_mem_read_r <= 1'b0;
	    pending_cpu_access_upon_cache_failed_r <= 1'b0;
	    ext_acc_vio_r <= 1'b0;
	    cache_miss_r <= 1'b0;
	    req_xe_r <= 1'b0;
	    req_pm_r <= 1'b0;
	    other_error_r <= 1'b0;
	    pending_cpu_mem_write_r <= 1'b0;
	end
	else begin // !sync_ciu_reset
	    mem_ciu_erase_busy_r <= nxt_mem_ciu_erase_busy;
	    mem_cpu_busy_r <= nxt_mem_cpu_busy;
	    cpu_mem_addr_r <= nxt_cpu_mem_addr;
	    cpu_mem_wr_byte_en_r <= nxt_cpu_mem_wr_byte_en;
	    cpu_mem_wdata_r <= nxt_cpu_mem_wdata;
	    block_read_sel_r <= nxt_block_read_sel;
	    mem_cpu_rdata_vld_r <= nxt_mem_cpu_rdata_vld;
	    ciu_block_fetch_req_r <= nxt_ciu_block_fetch_req;
	    ciu_mem_write_r <= nxt_ciu_mem_write;
            //sinc_ciu_fault_r <= nxt_sinc_ciu_fault;
	    ciu_active_r <= nxt_ciu_active;
	    mpu_read_vio_r <= nxt_mpu_read_vio;
	    vtag_parity_err_r <= nxt_vtag_parity_err;
	    cmu_fetch_err_r <= nxt_cmu_fetch_err;
	    pending_cpu_mem_read_r <= nxt_pending_cpu_mem_read;
	    pending_cpu_access_upon_cache_failed_r <= nxt_pending_cpu_access_upon_cache_failed;
	    ext_acc_vio_r <= nxt_ext_acc_vio;
	    cache_miss_r <= nxt_cache_miss;
	    req_xe_r <= nxt_req_xe;
	    req_pm_r <= nxt_req_pm;
	    other_error_r <= nxt_other_error;
	    pending_cpu_mem_write_r <= nxt_pending_cpu_mem_write;
	end
    end
end

////
//// Assertions
////

`ifdef _USE_SINC_ASSERT_
////      `include "../assert/sinc_ciu_assert.sv"
`endif
	
endmodule
