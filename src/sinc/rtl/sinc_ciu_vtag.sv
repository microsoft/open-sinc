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
// File        : sinc_ciu_vtag.sv
// Description : CIU VTAG (Valid Tag) module. Performs cache tag comparison for
//               hit/miss detection and manages 4-way set-associative eviction.

module sinc_ciu_vtag
    import sinc_pkg::*;
    #(
    // Parameters
    CACHE_TAG_WIDTH = 8,
    CACHE_SETIDX_WIDTH = 8,
    CACHE_VTAG_USE_RF = 1,
    localparam CACHE_VTAG_WIDTH = 4*(1+CACHE_TAG_WIDTH),
    localparam CACHE_PVTAG_WIDTH = (CACHE_TAG_WIDTH < 10)  ? (CACHE_VTAG_WIDTH + 4) : (CACHE_VTAG_WIDTH + 8)
    ) (
    input										clk,
    input 	       								rstn,
	input 	       								lp_rstn_i,
    input										sync_ciu_reset,
    //****************************************************************
    // sinc_ciu_ctrl Interface
    //****************************************************************
    output logic								vtag_cache_hit,
    output logic [2 - 1 : 0]            		vtag_cache_hit_word_idx,
    output logic [2 - 1 : 0]            		cache_fifo_status,
    output logic								vtag_parity_error,
    input										ciu_vtag_comp,
    input										ciu_vtag_update,
    input [CACHE_TAG_WIDTH - 1 : 0]				cache_tag,
    input [CACHE_SETIDX_WIDTH - 1 : 0]			cache_set_idx,
    //****************************************************************
    // Memory Erase Interface
    //****************************************************************
    input										vtag_erase_start,
    output logic								vtag_erase_busy,
    //****************************************************************
    // VTAG RA Interface:
    //    CACHE_PVTAG_WIDTH = (CACHE_TAG_WIDTH < 10)  ? (CACHE_VTAG_WIDTH + 4) : (CACHE_VTAG_WIDTH + 8)
    //****************************************************************
    output logic [CACHE_SETIDX_WIDTH - 1 : 0]	sinc_vtag_addr,
    output logic [3:0]                          sinc_vtag_we,
    output logic [3:0]                          sinc_vtag_en,
    output logic [CACHE_PVTAG_WIDTH - 1 : 0]    sinc_vtag_wdata,
    input [CACHE_PVTAG_WIDTH - 1 : 0]           sinc_vtag_rdata
);


typedef struct packed {
  logic          					parity;
  logic          					valid;
  logic [CACHE_TAG_WIDTH - 1 : 0]	tag;
} VTAG_BITS;

VTAG_BITS							vtag00_reg, nxt_vtag00_reg;
VTAG_BITS							vtag01_reg, nxt_vtag01_reg;
VTAG_BITS							vtag10_reg, nxt_vtag10_reg;
VTAG_BITS							vtag11_reg, nxt_vtag11_reg;
VTAG_BITS							vtag[3:0];

logic [3:0]							block_hit;
logic								vtag_cache_hit_r, nxt_vtag_cache_hit;
logic [2 - 1 : 0]           		vtag_cache_hit_word_idx_r, nxt_vtag_cache_hit_word_idx;
logic								vtag00_update, vtag01_update, vtag10_update, vtag11_update;
logic [3:0]							parity_pass;

sinc_vtag_erase_fsm_t 				vtag_sm_r, nxt_vtag_sm;
logic								vtag_erase_we;
logic								last_vtag_erase;
logic [CACHE_SETIDX_WIDTH - 1 : 0]	vtag_erase_addr_r, nxt_vtag_erase_addr;
logic								is_erase_op;

genvar						gen_idx;

////
//// Link to Output
////
assign vtag_cache_hit = vtag_cache_hit_r;
assign vtag_cache_hit_word_idx = vtag_cache_hit_word_idx_r;
assign sinc_vtag_en = {4{ciu_vtag_comp}} | sinc_vtag_we;
assign vtag_erase_busy = is_erase_op;

always_comb begin
    // default
    sinc_vtag_we = {vtag11_update, vtag10_update, vtag01_update, vtag00_update};
    sinc_vtag_wdata = {nxt_vtag11_reg, nxt_vtag10_reg, nxt_vtag01_reg, nxt_vtag00_reg};
    sinc_vtag_addr = cache_set_idx;

    if (is_erase_op) begin
	sinc_vtag_we = {4{vtag_erase_we}};
	sinc_vtag_addr = vtag_erase_addr_r;
	sinc_vtag_wdata = {CACHE_PVTAG_WIDTH{1'b0}};	// {4{(~(parity_gen(.data_in({CACHE_TAG_WIDTH{1'b1}})))), 1'b0, {CACHE_TAG_WIDTH{1'b1}}}} for testing
    end
end


assign vtag11_reg = sinc_vtag_rdata[CACHE_PVTAG_WIDTH - 1 -: (CACHE_TAG_WIDTH + 1 + 1)];
assign vtag10_reg = sinc_vtag_rdata[(CACHE_PVTAG_WIDTH - 1) - (1*(CACHE_TAG_WIDTH + 1 + 1)) -: (CACHE_TAG_WIDTH + 1 + 1)];
assign vtag01_reg = sinc_vtag_rdata[(CACHE_PVTAG_WIDTH - 1) - (2*(CACHE_TAG_WIDTH + 1 + 1)) -: (CACHE_TAG_WIDTH + 1 + 1)];
assign vtag00_reg = sinc_vtag_rdata[(CACHE_PVTAG_WIDTH - 1) - (3*(CACHE_TAG_WIDTH + 1 + 1)) -: (CACHE_TAG_WIDTH + 1 + 1)];

assign vtag[0] = vtag00_reg;
assign vtag[1] = vtag01_reg;
assign vtag[2] = vtag10_reg;
assign vtag[3] = vtag11_reg;

assign vtag_parity_error = (~(&parity_pass[3:0]));

generate 

  if (CACHE_VTAG_USE_RF == 0) begin: gen_use_ciu_vtag_comp

for (gen_idx = 0; gen_idx < 4; gen_idx++) begin: gen_block_hit

  always_comb begin
    // default
    block_hit[gen_idx] = 1'b0;
    parity_pass[gen_idx] = 1'b1;

    if (vtag[gen_idx].valid && ciu_vtag_comp) begin
    	if (parity_chk(.data_in(vtag[gen_idx]))) begin
    	    if (vtag[gen_idx].tag == cache_tag) begin
    	    	block_hit[gen_idx] = 1'b1;
    	    end
    	end
    	else begin // !parity_chk
    	    parity_pass[gen_idx] = 1'b0;
    	end
    end
  end

end // for

  end
  else begin: gen_use_ciu_vtag_comp_r

logic						ciu_vtag_comp_r;
logic [CACHE_TAG_WIDTH - 1 : 0]			cache_tag_r;

for (gen_idx = 0; gen_idx < 4; gen_idx++) begin: gen_block_hit

  always_comb begin
    // default
    block_hit[gen_idx] = 1'b0;
    parity_pass[gen_idx] = 1'b1;

    if (vtag[gen_idx].valid && ciu_vtag_comp_r) begin
    	if (parity_chk(.data_in(vtag[gen_idx]))) begin
    	    if (vtag[gen_idx].tag == cache_tag_r) begin
    	    	block_hit[gen_idx] = 1'b1;
    	    end
    	end
    	else begin // !parity_chk
    	    parity_pass[gen_idx] = 1'b0;
    	end
    end
  end

end // for

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
	ciu_vtag_comp_r <= 1'b0;
	cache_tag_r <= {CACHE_TAG_WIDTH{1'b0}};
    end
    else begin // lp_rstn_i
	if (sync_ciu_reset) begin
	    ciu_vtag_comp_r <= 1'b0;
	    cache_tag_r <= {CACHE_TAG_WIDTH{1'b0}};
	end
	else begin // !sync_ciu_reset
	    ciu_vtag_comp_r <= ciu_vtag_comp;
	    cache_tag_r <= cache_tag;
	end
    end
end

  end

endgenerate

always_comb begin

    case (block_hit[3:0])
	4'b0001: begin
		nxt_vtag_cache_hit = 1'b1;
		nxt_vtag_cache_hit_word_idx = 2'b00;
	  end
	4'b0010: begin
		nxt_vtag_cache_hit = 1'b1;
		nxt_vtag_cache_hit_word_idx = 2'b01;
	  end
	4'b0100: begin
		nxt_vtag_cache_hit = 1'b1;
		nxt_vtag_cache_hit_word_idx = 2'b10;
	  end
	4'b1000: begin
		nxt_vtag_cache_hit = 1'b1;
		nxt_vtag_cache_hit_word_idx = 2'b11;
	  end
	default: begin
    		nxt_vtag_cache_hit = 1'b0;
    		nxt_vtag_cache_hit_word_idx = 2'b00;
	  end
    endcase
end

generate

  if (CACHE_VTAG_USE_RF == 0) begin: gen_use_flop

////
//// Flops
////
always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
	vtag_cache_hit_r <= 1'b0;
	vtag_cache_hit_word_idx_r <= 2'd0;
    end
    else begin // lp_rstn_i
	if (sync_ciu_reset) begin
	    vtag_cache_hit_r <= 1'b0;
	    vtag_cache_hit_word_idx_r <= 2'd0;
	end
	else begin // !sync_ciu_reset
	    if (ciu_vtag_comp) begin
	    	vtag_cache_hit_r <= nxt_vtag_cache_hit;
	    	vtag_cache_hit_word_idx_r <= nxt_vtag_cache_hit_word_idx;
	    end
	    else begin
	    	if (vtag_cache_hit_r) begin
	    	    vtag_cache_hit_r <= 1'b0;
	    	end
	    end
	end
    end
end

  end
  else begin: gen_skip_flop

assign vtag_cache_hit_r = nxt_vtag_cache_hit;
assign vtag_cache_hit_word_idx_r = nxt_vtag_cache_hit_word_idx;

  end

endgenerate

////
//// fifo_sta_reg and cache_fifo_status
////
sinc_ciu_vtag_ret #(
	.CACHE_SETIDX_WIDTH (CACHE_SETIDX_WIDTH)
) u_vtag_ret (
	//input
    .clk ( clk ),				
    .rstn ( rstn ),				
    .sync_ciu_reset ( sync_ciu_reset ),		
    .ciu_vtag_update ( ciu_vtag_update ),	
    .cache_set_idx ( cache_set_idx ),		
	//output
    .cache_fifo_status ( cache_fifo_status )	
);

////
//// vtag00_reg, vtag01_reg, vtag10_reg and vtag11_reg
////
always_comb begin
    // default
    nxt_vtag00_reg = vtag00_reg;
    nxt_vtag01_reg = vtag01_reg;
    nxt_vtag10_reg = vtag10_reg;
    nxt_vtag11_reg = vtag11_reg;
    vtag00_update = 1'b0;
    vtag01_update = 1'b0;
    vtag10_update = 1'b0;
    vtag11_update = 1'b0;

    if (ciu_vtag_update) begin
	case (cache_fifo_status)
	    2'b00: begin
		    nxt_vtag00_reg.parity = parity_gen(.data_in(cache_tag));
		    nxt_vtag00_reg.valid = 1'b1;
		    nxt_vtag00_reg.tag = cache_tag;
		    vtag00_update = 1'b1;
		end
	    2'b01: begin
		    nxt_vtag01_reg.parity = parity_gen(.data_in(cache_tag));
		    nxt_vtag01_reg.valid = 1'b1;
		    nxt_vtag01_reg.tag = cache_tag;
		    vtag01_update = 1'b1;
		end
	    2'b10: begin
		    nxt_vtag10_reg.parity = parity_gen(.data_in(cache_tag));
		    nxt_vtag10_reg.valid = 1'b1;
		    nxt_vtag10_reg.tag = cache_tag;
		    vtag10_update = 1'b1;
		end
	    2'b11: begin
		    nxt_vtag11_reg.parity = parity_gen(.data_in(cache_tag));
		    nxt_vtag11_reg.valid = 1'b1;
		    nxt_vtag11_reg.tag = cache_tag;
		    vtag11_update = 1'b1;
		end
	endcase
    end
end

////
//// Erasing Operation
////
assign last_vtag_erase = (vtag_erase_addr_r == {CACHE_SETIDX_WIDTH{1'b1}});

always_comb begin
    // default
    nxt_vtag_sm = vtag_sm_r;
    nxt_vtag_erase_addr = vtag_erase_addr_r;
    vtag_erase_we = 1'b0;
    is_erase_op = 1'b0;

    case (vtag_sm_r)
	VTAG_ERASE_IDLE: begin
	    if (vtag_erase_start) begin
    		is_erase_op = 1'b1;
    		vtag_erase_we = 1'b1;	// Write [0]
    		nxt_vtag_erase_addr = vtag_erase_addr_r + 1;
    		nxt_vtag_sm = VTAG_ERASE_WR;
	    end
	end
	VTAG_ERASE_WR: begin
    	    is_erase_op = 1'b1;
    	    vtag_erase_we = 1'b1;	// Write [vtag_erase_addr_r]

	    if (last_vtag_erase) begin
        	nxt_vtag_erase_addr = {CACHE_SETIDX_WIDTH{1'b0}};
    		nxt_vtag_sm = VTAG_ERASE_IDLE;
	    end
	    else begin // !last_vtag_erase
    		nxt_vtag_erase_addr = vtag_erase_addr_r + 1;
	    end
	end
    endcase
end

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
	vtag_sm_r <= VTAG_ERASE_IDLE;
    end
    else begin // lp_rstn_i
	if (sync_ciu_reset) begin
	    vtag_sm_r <= VTAG_ERASE_IDLE;
	end
	else begin // !sync_ciu_reset
	    vtag_sm_r <= nxt_vtag_sm;
	end
    end
end

always_ff @(posedge clk or negedge lp_rstn_i) begin
    if (!lp_rstn_i) begin
        vtag_erase_addr_r <= {CACHE_SETIDX_WIDTH{1'b0}};
    end
    else begin // lp_rstn_i
	if (sync_ciu_reset) begin
            vtag_erase_addr_r <= {CACHE_SETIDX_WIDTH{1'b0}};
	end
	else begin // !sync_ciu_reset
	    vtag_erase_addr_r <= nxt_vtag_erase_addr;
	end
    end
end

////
//// Functions
////	parity_gen (data_in)
////	parity_chk (data_in)
////
function automatic logic parity_gen (
        input [CACHE_TAG_WIDTH - 1 : 0] data_in);

  // Even Parity that always count valid 1
  parity_gen = (~^data_in);

endfunction

function automatic logic parity_chk (
        input [CACHE_TAG_WIDTH + 1 : 0] data_in);

  // Even Parity that always count valid 1
  parity_chk = (~^data_in);

endfunction

////
//// Assertions
////

`ifdef _USE_SINC_ASSERT_
////      `include "../assert/sinc_ciu_assert.sv"
`endif
	
endmodule
