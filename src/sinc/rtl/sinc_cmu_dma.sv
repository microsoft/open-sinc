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
// File        : sinc_cmu_dma.sv
// Description : CMU DMA controller. Manages read and write data transfers
//               through the AXI manager interface.

module sinc_cmu_dma
import sinc_pkg::*;
#(
    parameter BLOCK_LENW            = 7                 // bit width to store above AXI len (in beats)
)
(
    input logic                     clk_i,
    input logic                     rstn_i,
    input logic                     severe_err,
    output logic                    dma_fault_err,

    /* Crypto wrap interface */
    input logic                     c_wrap_dma_cread,
    output logic                    dma_c_wrap_craccept,
    input logic                     c_wrap_dma_cwrite,
    output logic                    dma_c_wrap_cwaccept,
    input logic [31:0]              c_wrap_dma_caddr,
    input logic [BLOCK_LENW-1:0]    c_wrap_dma_clen,
    input logic                     stop_dma_txn,

    input logic [31:0]              c_wrap_dma_wdata,
    input logic                     c_wrap_dma_w_vld,
    output logic                    dma_c_wrap_w_accept,
    output logic                    dma_c_wrap_cw_comp,
    output logic                    dma_c_wrap_cw_err,

    output logic [31:0]             dma_c_wrap_rdata,
    output logic                    dma_c_wrap_r_vld,
    output logic                    dma_c_wrap_cr_comp,
    output logic                    dma_c_wrap_cr_err,

    /* AXI manager interface */
    /* Read interface */
    output logic                    mgr_engn_cread_i,
    output logic                    mgr_engn_crstop_i,
    output logic [31:0]             mgr_engn_craddr_i,
    output logic [31:0]             mgr_engn_crlen_i,
    output logic [`HSP_AXI_MST_ID_WIDTH-1:0] mgr_engn_crid_i,
    output logic [`MSFT_AXI_MST_ENGNU_WIDTH-1:0] mgr_engn_cruser_i,
    output logic [2:0]              mgr_engn_crprot_i,
    input logic                     mgr_engn_craccept_o,

    input logic [`HSP_AXI_MST_DWIDTH-1:0] mgr_engn_rdata_o,
    input logic                     mgr_engn_rvalid_o,
    output logic                    mgr_engn_raccept_i,

    input logic                     mgr_engn_crvalid_o,
    input logic [3:0]               mgr_engn_crresp_o,

    /* Write interface */
    output logic                    mgr_engn_cwrite_i,
    output logic                    mgr_engn_cwstop_i,
    output logic [31:0]             mgr_engn_cwaddr_i,
    output logic [31:0]             mgr_engn_cwlen_i,
    output logic [`HSP_AXI_MST_ID_WIDTH-1:0] mgr_engn_cwid_i,
    output logic [`MSFT_AXI_MST_ENGNU_WIDTH-1:0] mgr_engn_cwuser_i,
    output logic [2:0]              mgr_engn_cwprot_i,
    input logic                     mgr_engn_cwaccept_o,

    input logic                     mgr_engn_cwvalid_o,
    input logic [3:0]               mgr_engn_cwresp_o,

    output logic [`HSP_AXI_MST_DWIDTH-1:0] mgr_engn_wdata_i,
    output logic                    mgr_engn_wvalid_i,
    input logic                     mgr_engn_waccept_o
);

    sinc_dma_r_fsm_t                dma_r_state;
    sinc_dma_r_fsm_t                dma_r_next_state;
    sinc_dma_w_fsm_t                dma_w_state;
    sinc_dma_w_fsm_t                dma_w_next_state;

    logic [31:0]                    dma_r_addr_q;
    logic [31:0]                    dma_w_addr_q;
    logic [BLOCK_LENW - 1 : 0]      dma_r_len_q;
    logic [BLOCK_LENW - 1 : 0]      dma_w_len_q;
    logic [BLOCK_LENW - 1 : 0]      dma_r_last_beat;
    logic [BLOCK_LENW - 1 : 0]      dma_w_last_beat;
    logic [31:0]                    dma_r_addr_mux;
    logic [29:0]                    dma_r_len_mux;
    logic [31:0]                    dma_w_addr_mux;
    logic [29:0]                    dma_w_len_mux;
    logic                           cread;
    logic                           craccept;
    logic                           rvalid;
    logic                           raccept;
    logic                           crvalid;
    logic [3:0]                     crresp;
    logic                           cwrite;
    logic                           cwaccept;
    logic                           wvalid;
    logic                           waccept;
    logic                           cwvalid, unused_mgr_engn_craccept_o, unused_mgr_engn_cwaccept_o;
    logic [3:0]                     cwresp;
    logic                           r_comp, r_err;
    logic                           w_comp, w_err;
    logic [BLOCK_LENW-1:0]          r_beat_cnt;
    logic [BLOCK_LENW-1:0]          w_beat_cnt;
    logic                           r_comp_q;
    logic                           w_comp_q;
    logic                           invld_dma_r_state;
    logic                           invld_dma_w_state;
    logic                           r_stop_exec, set_r_stop_exec, clr_r_stop_exec;
    logic                           w_stop_exec, set_w_stop_exec, clr_w_stop_exec;

    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            dma_r_state <= DMA_R_IDLE;
            dma_w_state <= DMA_W_IDLE;
        end
        else begin
            if(severe_err | stop_dma_txn) begin
                dma_r_state <= DMA_R_FLUSH;
                dma_w_state <= DMA_W_FLUSH;
            end
            else begin
                dma_r_state <= dma_r_next_state;
                dma_w_state <= dma_w_next_state;
            end
        end
    end

    always_comb begin : dma_r_fsm_block

        dma_r_next_state            = dma_r_state;
        dma_c_wrap_r_vld            = 1'h0;
        dma_c_wrap_cr_comp          = 1'h0;
        dma_c_wrap_cr_err           = 1'h0;
        mgr_engn_crstop_i           = 1'h0;
        cread                       = 1'h0;
        raccept                     = 1'h0;
        // set_r_stop_exec             = 1'h0;
        clr_r_stop_exec             = 1'h0;
        invld_dma_r_state           = 1'h0;
        dma_c_wrap_craccept         = 1'h0;

        case(dma_r_state)
            DMA_R_IDLE: begin
                cread = c_wrap_dma_cread;
                
                if(cread & craccept) begin          // transition to DATA state if request already accepted
                    dma_c_wrap_craccept = 1'h1;
                    dma_r_next_state = DMA_R_DATA;
                end
            end
            DMA_R_DATA: begin                   // receive read data from axi mgr
                dma_c_wrap_r_vld = rvalid;
                raccept = 1'h1;
                
                if(crvalid) begin
                    if (crresp != 4'h0) begin
                        dma_r_next_state = DMA_R_IDLE;
                        dma_c_wrap_cr_err = 1'h1;
                    end
                end
                else if(r_comp) begin                // transition to RESP once all beats are accepted 
                    dma_r_next_state = DMA_R_RESP;
                end
            end
            DMA_R_RESP: begin                   // Read response from AXI mgr
                if(crvalid) begin
                    dma_r_next_state = DMA_R_IDLE;

                    if(crresp == 4'h0) begin        // signal error or comp based on response received from axi mgr
                        dma_c_wrap_cr_comp = 1'h1;
                    end
                    else begin
                        dma_c_wrap_cr_err = 1'h1;
                    end
                end
            end
            DMA_R_FLUSH: begin
                if (r_comp_q) begin                     // go back to idle if no outstanding txn
                    dma_r_next_state = DMA_R_IDLE;
                end
                else begin                              // otherwise, flush out the txn. In read, this means that AXI I/F still need to accept pending read data
                    raccept = 1'h1;

                    if(~r_stop_exec) begin              // request stop till it is accepted
                        mgr_engn_crstop_i = 1'h1;
                    end

                    if(crvalid) begin                   // wait for final resp before transitioning to idle
                        clr_r_stop_exec = 1'h1;
                        dma_r_next_state = DMA_R_IDLE;
                    end
                end
            end
            default: begin
                invld_dma_r_state = 1'h1;
                dma_r_next_state = DMA_R_IDLE;
            end
        endcase
    end

    always_comb begin : dma_w_fsm_block

        dma_w_next_state            = dma_w_state;
        cwrite                      = 1'h0;
        wvalid                      = 1'h0;
        dma_c_wrap_w_accept         = 1'h0;
        dma_c_wrap_cw_comp          = 1'h0;
        dma_c_wrap_cw_err           = 1'h0;
        mgr_engn_cwstop_i           = 1'h0;
        clr_w_stop_exec             = 1'h0;
        invld_dma_w_state           = 1'h0;
        dma_c_wrap_cwaccept         = 1'h0;
        
        case(dma_w_state)
            DMA_W_IDLE: begin
                cwrite = c_wrap_dma_cwrite;
                
                if(cwrite & cwaccept) begin          // if write req accepted, move to DATA state
                    dma_c_wrap_cwaccept = 1'h1;
                    dma_w_next_state = DMA_W_DATA;
                end
            end
            DMA_W_DATA: begin                   // send write data to AXI mgr
                wvalid = c_wrap_dma_w_vld;
                dma_c_wrap_w_accept = waccept;

                if(cwvalid) begin
                    if (cwresp != 4'h1) begin
                        dma_w_next_state = DMA_W_IDLE;
                        dma_c_wrap_cw_err = 1'h1;
                    end
                end
                else if(w_comp) begin                // transition to RESP once all beats are accepted by AXI mgr
                    dma_w_next_state = DMA_W_RESP;
                end
            end
            DMA_W_RESP: begin
                if(cwvalid) begin
                    dma_w_next_state = DMA_W_IDLE;

                    if(cwresp == 4'h1) begin        // signal error or comp based on response received from axi mgr
                        dma_c_wrap_cw_comp = 1'h1;
                    end
                    else begin
                        dma_c_wrap_cw_err = 1'h1;
                    end
                end
            end
            DMA_W_FLUSH: begin
                if (w_comp_q) begin
                    dma_w_next_state = DMA_W_IDLE;
                end
                else begin
                    wvalid = 1'h1;

                    if(~w_stop_exec) begin    // request stop till it is accepted
                        mgr_engn_cwstop_i = 1'h1;
                    end

                    if(cwvalid) begin                   // wait for final resp before transitioning to idle
                        clr_w_stop_exec = 1'h1;
                        dma_w_next_state = DMA_W_IDLE;
                    end
                end
            end
            default: begin
                invld_dma_w_state = 1'h1;
                dma_w_next_state = DMA_W_IDLE;
            end
        endcase
    end

    /* Capture len and addr for DMA requests */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            dma_r_addr_q <= 32'h0;
            dma_r_len_q <= {BLOCK_LENW{1'h0}};
            dma_w_addr_q <= 32'h0;
            dma_w_len_q <= {BLOCK_LENW{1'h0}};
        end
        else begin
            if(dma_c_wrap_cr_comp | dma_c_wrap_cr_err) begin
                dma_r_addr_q <= 32'h0;
                dma_r_len_q <= {BLOCK_LENW{1'h0}};
            end
            else if (c_wrap_dma_cread) begin
                dma_r_addr_q <= c_wrap_dma_caddr;
                dma_r_len_q <= c_wrap_dma_clen;
            end

            if (dma_c_wrap_cw_comp | dma_c_wrap_cw_err) begin
                dma_w_addr_q <= 32'h0;
                dma_w_len_q <= {BLOCK_LENW{1'h0}};
            end
            else if(c_wrap_dma_cwrite) begin
                dma_w_addr_q <= c_wrap_dma_caddr;
                dma_w_len_q <= c_wrap_dma_clen;
            end
        end
    end

    /* Count read data beats from axi mgr */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            r_beat_cnt <= {BLOCK_LENW{1'h0}};
            w_beat_cnt <= {BLOCK_LENW{1'h0}};
        end
        else begin
            if(r_comp | r_err) begin
                r_beat_cnt <= {BLOCK_LENW{1'h0}};
            end
            else if(rvalid & raccept) begin
                r_beat_cnt <= r_beat_cnt + 1'h1;
            end

            if(w_comp | w_err) begin
                w_beat_cnt <= {BLOCK_LENW{1'h0}};
            end
            else if(wvalid & waccept) begin
                w_beat_cnt <= w_beat_cnt + 1'h1;
            end
        end
    end

    /* Tracks whether transaction is pending or complete, and stop req accepted or pending */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            r_comp_q <= 1'h1;
            w_comp_q <= 1'h1;
            r_stop_exec <= 1'h0;
            w_stop_exec <= 1'h0;
        end
        else begin
            if(c_wrap_dma_cread & dma_c_wrap_craccept) begin
                r_comp_q <= 1'h0;
            end
            else if (crvalid) begin
                r_comp_q <= 1'h1;
            end

            if(c_wrap_dma_cwrite & dma_c_wrap_cwaccept) begin
                w_comp_q <= 1'h0;
            end
            else if (cwvalid) begin
                w_comp_q <= 1'h1;
            end

            if(clr_r_stop_exec) begin
                r_stop_exec <= 1'h0;
            end
            else if (set_r_stop_exec) begin
                r_stop_exec <= 1'h1;
            end

            if(clr_w_stop_exec) begin
                w_stop_exec <= 1'h0;
            end
            else if (set_w_stop_exec) begin
                w_stop_exec <= 1'h1;
            end
        end
    end

    assign r_comp       = rvalid & raccept & (r_beat_cnt == dma_r_last_beat);
    assign w_comp       = wvalid & waccept & (w_beat_cnt == dma_w_last_beat);
    assign r_err        = crvalid & (crresp != 4'h0);
    assign w_err        = cwvalid & (cwresp != 4'h1);

    assign dma_r_addr_mux                       = c_wrap_dma_cread ? c_wrap_dma_caddr : dma_r_addr_q;
    assign dma_r_len_mux[BLOCK_LENW-1:0]        = c_wrap_dma_cread ? c_wrap_dma_clen : dma_r_len_q;
    assign dma_r_len_mux[29:BLOCK_LENW]         = {(30-BLOCK_LENW){1'h0}};
    assign dma_r_last_beat                      = (dma_r_len_q - 1'h1);     // 1 less because counting starts from 0
    
    assign dma_w_addr_mux                       = c_wrap_dma_cwrite ? c_wrap_dma_caddr : dma_w_addr_q;
    assign dma_w_len_mux[BLOCK_LENW-1:0]        = c_wrap_dma_cwrite ? c_wrap_dma_clen : dma_w_len_q;
    assign dma_w_len_mux[29:BLOCK_LENW]         = {(30-BLOCK_LENW){1'h0}};
    assign dma_w_last_beat                      = (dma_w_len_q - 1'h1);     // 1 less because counting starts from 0

    // AXI mgr assignments
    assign mgr_engn_cread_i         = cread;
    assign mgr_engn_raccept_i       = raccept;
    assign mgr_engn_cwrite_i        = cwrite;
    assign mgr_engn_wvalid_i        = wvalid;
    
    // assign craccept                 = mgr_engn_craccept_o;
    assign unused_mgr_engn_craccept_o = mgr_engn_craccept_o;
    assign craccept                 = 1'h1;
    assign rvalid                   = mgr_engn_rvalid_o;
    assign crvalid                  = mgr_engn_crvalid_o;
    assign crresp                   = mgr_engn_crresp_o;
    // assign cwaccept                 = mgr_engn_cwaccept_o;
    assign unused_mgr_engn_cwaccept_o = mgr_engn_cwaccept_o;
    assign cwaccept                 = 1'h1;
    assign waccept                  = mgr_engn_waccept_o;
    assign cwvalid                  = mgr_engn_cwvalid_o;
    assign cwresp                   = mgr_engn_cwresp_o;

    /* Pad dma_*_len_mux LSB with 2'h0 to convert no. of beats to bytes since AXI mgr require length in bytes */
    assign mgr_engn_craddr_i = dma_r_addr_mux;
    assign mgr_engn_crlen_i = {dma_r_len_mux, 2'h0};
    assign mgr_engn_crid_i = {`HSP_AXI_MST_ID_WIDTH{1'h0}};
    assign mgr_engn_cruser_i = {`AXI_MST_ID_SINC, {(`MSFT_AXI_MST_ENGNU_WIDTH - `AXI_USER_MID_WIDTH){1'h0}}};
    assign mgr_engn_crprot_i = 3'h0;

    assign mgr_engn_cwaddr_i = dma_w_addr_mux;
    assign mgr_engn_cwlen_i = {dma_w_len_mux, 2'h0};
    assign mgr_engn_cwid_i = {`HSP_AXI_MST_ID_WIDTH{1'h0}};
    assign mgr_engn_cwuser_i = {`AXI_MST_ID_SINC, {(`MSFT_AXI_MST_ENGNU_WIDTH - `AXI_USER_MID_WIDTH){1'h0}}};
    assign mgr_engn_cwprot_i = 3'h0;

    assign dma_c_wrap_rdata = mgr_engn_rdata_o;
    assign mgr_engn_wdata_i = c_wrap_dma_wdata;

    assign set_r_stop_exec = mgr_engn_crstop_i & craccept;
    assign set_w_stop_exec = mgr_engn_cwstop_i & cwaccept;

    assign dma_fault_err = invld_dma_r_state | invld_dma_w_state;

endmodule
