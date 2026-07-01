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
// File        : sinc_ciu_vtag_ret.sv
// Description : VTAG retention module. Maintains FIFO status registers for
//               cache set replacement across power-domain retention.

module sinc_ciu_vtag_ret
    #(
    CACHE_SETIDX_WIDTH = 8
    ) (
    input								clk,
    input 	       						rstn,
    input								sync_ciu_reset,
    //****************************************************************
    // sinc_ciu_ctrl Interface
    //****************************************************************
    output logic [2 - 1 : 0]            cache_fifo_status,
    input								ciu_vtag_update,
    input [CACHE_SETIDX_WIDTH - 1 : 0]	cache_set_idx
);

////
//// Local Parameters
////
localparam NUM_OF_CACHE_SETS = (2**CACHE_SETIDX_WIDTH);

////
//// Internal Signals
////
logic [2 - 1 : 0]			fifo_sta_reg[NUM_OF_CACHE_SETS - 1 : 0], nxt_fifo_sta_reg[NUM_OF_CACHE_SETS - 1 : 0];
genvar						gen_idx;

////
//// Link to Output
////
assign cache_fifo_status = fifo_sta_reg[cache_set_idx];

////
//// fifo_sta_reg
////
always_comb begin
    // default
    nxt_fifo_sta_reg = fifo_sta_reg;

    if (ciu_vtag_update) begin
	// pointing to next block to be evicted
	nxt_fifo_sta_reg[cache_set_idx] = fifo_sta_reg[cache_set_idx] + 2'b01;
    end
end

generate 
  for (gen_idx = 0; gen_idx < NUM_OF_CACHE_SETS; gen_idx++) begin: gen_fifo_sta_reg

    always_ff @(posedge clk or negedge rstn) begin
    	if (!rstn) begin
	    fifo_sta_reg[gen_idx] <= {2{1'b0}};
    	end
    	else begin // rstn
	    if (sync_ciu_reset) begin
	    	fifo_sta_reg[gen_idx] <= {2{1'b0}};
	    end
	    else begin // !sync_ciu_reset
	    	if ((gen_idx == cache_set_idx) && ciu_vtag_update) begin
	    	    fifo_sta_reg[gen_idx] <= nxt_fifo_sta_reg[gen_idx];
	    	end
	    end
    	end
    end

  end
endgenerate

////
//// Assertions
////

`ifdef _USE_SINC_ASSERT_
////      `include "../assert/sinc_ciu_assert.sv"
`endif
	
endmodule
