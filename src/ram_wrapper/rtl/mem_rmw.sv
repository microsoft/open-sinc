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
// File        : mem_rmw.sv
// Description : Logic to handle partial word writes by performing a
//               read-modify-write cycle.

module mem_rmw (/*AUTOARG*/
    // Outputs
    non_rmw_en, rmw_en, rmw_we, rmw_wdata, rmw_addr, rmw_busy, rmw_parity_err,
    // Inputs
    clk, reset_na, en, we, wdata, addr, rdata, rmw_error, err_parity_chk_disable_i, addr_chk, wdata_chk
    );

    //-------------------------------------------
    // Parameters
    //-------------------------------------------

    parameter DATA_WIDTH = 64;                     // must be either 32 or 64 bits of data
    parameter ADDR_WIDTH = 23;
    parameter RMW_PIPELINE = 0;
    parameter PARITY_EN = 0;
    parameter NUM_BYTES = DATA_WIDTH/8;

    localparam RMW_STATE_IDLE = 1'b0;
    localparam RMW_STATE_BUSY = 1'b1;

    typedef enum logic [1:0]
    {
        RMW_PHASE_RD            = 2'h0,
        RMW_PHASE_PIPELINE      = 2'h1,
        RMW_PHASE_WR            = 2'h2
    } rmw_phase_t;     // RMW Phase

    //-------------------------------------------
    // to/from logic
    //-------------------------------------------
    input logic                       clk;
    input logic                       reset_na;
    input logic                       en;
    input logic [NUM_BYTES-1:0]       we;
    input logic [DATA_WIDTH-1:0]      wdata;
    input logic [ADDR_WIDTH-1:0]      addr;
    input logic [DATA_WIDTH-1:0]      rdata;

    input logic                       rmw_error;

    input logic                       err_parity_chk_disable_i;
    input logic                       addr_chk;
    input logic [(DATA_WIDTH/32)-1:0] wdata_chk; 

    output reg                        non_rmw_en;
    output logic                      rmw_en;
    output logic                      rmw_we;
    output logic [DATA_WIDTH-1:0]     rmw_wdata;
    output logic [ADDR_WIDTH-1:0]     rmw_addr;

    output logic                      rmw_busy;
    output logic                      rmw_parity_err;

    //-------------------------------------------
    // internals
    //-------------------------------------------
    logic [NUM_BYTES-1:0]       we_q;
    logic [DATA_WIDTH-1:0]      wdata_q;
    logic [ADDR_WIDTH-1:0]      addr_q;

    logic [DATA_WIDTH-1:0]      mod_wdata;
    logic [DATA_WIDTH-1:0]      final_mod_wdata;
    logic                       final_rmw_error;
    logic                       next_rmw_state;
    logic                       rmw_state;
    logic                       rmw_pipeline_vld;

    logic                       addr_chk_err;
    logic                       wdata_chk_err;
    logic                       rmw_pipeline_wdata_chk_err;

    rmw_phase_t                 next_rmw_phase;
    rmw_phase_t                 rmw_phase;

    genvar                      iter;
    generate for (iter=0; iter<NUM_BYTES; iter=iter+1)
    begin : gen_MOD_WDATA
        assign mod_wdata[((iter+1)*8)-1:iter*8] = we_q[iter]
                                            ? wdata_q[((iter+1)*8)-1:iter*8]
                                            : rdata[((iter+1)*8)-1:iter*8];
    end
    endgenerate

    //-------------------------------------------
    // driving signals to the memory side
    //-------------------------------------------


    always_comb begin
        non_rmw_en      = 1'b0;
        rmw_en          = 1'b0;
        rmw_we          = 1'b0;
        rmw_wdata       = {DATA_WIDTH{1'b0}};
        rmw_addr        = addr;

        next_rmw_state  = rmw_state;
        next_rmw_phase  = rmw_phase;

        case (rmw_state)
            RMW_STATE_IDLE: begin
                if (en && (we == {NUM_BYTES{1'b0}}))
                begin // a normal read, drive signals to memories as-is, wait for data to come back
                    non_rmw_en      = 1'b1;
                end
                else if (en && (we == {NUM_BYTES{1'b1}}))
                begin                     // full word write
                    non_rmw_en      = 1'b1;
                    rmw_we          = 1'b1;
                    rmw_wdata       = wdata;
                end
                else if (en)
                begin                     // paritial write, kick off read-mod-write cycle
                    rmw_en          = 1'b1;
                    next_rmw_state  = RMW_STATE_BUSY;
                end
                // else do nothing
            end

            RMW_STATE_BUSY: begin
                // Use saved address for the rest of RMW cycles
                rmw_addr = addr_q;

                if (rmw_phase == RMW_PHASE_RD) begin            // read phase
                    if(rmw_pipeline_vld) begin
                        next_rmw_phase  = RMW_PHASE_PIPELINE;
                    end
                    else begin
                        next_rmw_phase  = RMW_PHASE_WR;
                    end
                end
                else if (rmw_phase == RMW_PHASE_PIPELINE) begin // Don't do anything. Just a pipeline stage
                        next_rmw_phase  = RMW_PHASE_WR;
                end
                else if (rmw_phase == RMW_PHASE_WR) begin       // write phase
                    if (~final_rmw_error) begin
                        rmw_en          = 1'b1;
                        rmw_we          = 1'b1;
                        rmw_wdata       = final_mod_wdata;
                    end

                    next_rmw_state  = RMW_STATE_IDLE;
                    next_rmw_phase  = RMW_PHASE_RD;
                end
                else begin
                    next_rmw_state  = RMW_STATE_IDLE;
                    next_rmw_phase  = RMW_PHASE_RD;
                end
            end

            default: begin
                next_rmw_state = RMW_STATE_IDLE;
            end

        endcase // case (rmw_state)
    end

    generate
        if(RMW_PIPELINE) begin
            assign rmw_pipeline_vld = 1'h1;
        end
        else begin
            assign rmw_pipeline_vld = 1'h0;
        end
    endgenerate

    //-------------------------------------------
    // Registers
    //-------------------------------------------

    always_ff @(posedge clk or negedge reset_na) begin
        if (~reset_na) begin
            rmw_state    <= RMW_STATE_IDLE;
            rmw_phase    <= RMW_PHASE_RD;
            we_q         <= {NUM_BYTES{1'b0}};
            wdata_q      <= {DATA_WIDTH{1'b0}};
            addr_q       <= {ADDR_WIDTH{1'b0}};
        end else begin
            rmw_state    <= next_rmw_state;
            rmw_phase    <= next_rmw_phase;

            // Save write strobes, address, and data at the beginning of
            // a partial write.
            if ((rmw_state == RMW_STATE_IDLE) && (next_rmw_state == RMW_STATE_BUSY))
            begin
                we_q         <= we;
                wdata_q      <= wdata;
                addr_q       <= addr;

            end
        end
    end
    logic [DATA_WIDTH-1:0] mod_wdata_q;
    logic rmw_error_q;

    generate
        if (RMW_PIPELINE == 1) begin: gen_wdata_pipeline
            always_ff @(posedge clk or negedge reset_na) begin
                if(~reset_na) begin
                    mod_wdata_q <= {DATA_WIDTH{1'h0}};
                    rmw_error_q <= 1'h0;
                end
                else begin
                    mod_wdata_q <= mod_wdata;
                    rmw_error_q <= rmw_error | rmw_parity_err;
                end
            end
            assign final_mod_wdata = mod_wdata_q;
            assign final_rmw_error = rmw_error_q | rmw_parity_err;
        end
        else begin: gen_wdata_no_pipeline
            assign final_mod_wdata = mod_wdata;
            assign final_rmw_error = rmw_error | rmw_parity_err;
        end
    endgenerate

    /* Parity Error logic */
    generate if (PARITY_EN == 1)
    begin: gen_rmw_parity_en
        logic addr_chk_q;
        logic [(DATA_WIDTH/32)-1:0] wdata_chk_q;

        always_ff @(posedge clk or negedge reset_na) begin
            if (~reset_na) begin
                addr_chk_q <= '1;
                wdata_chk_q <= '1;
            end else begin
                if ((rmw_state == RMW_STATE_IDLE) && (next_rmw_state == RMW_STATE_BUSY)) begin
                    addr_chk_q <= addr_chk;
                    wdata_chk_q <= wdata_chk;
                end
            end
        end

        always_comb begin
            wdata_chk_err = 'b0;
            for (integer di = 0; di < (DATA_WIDTH/32); di = di + 1) begin

                // Check parity on the unmodified write data flop
                if(~err_parity_chk_disable_i) begin
                    wdata_chk_err |= (rmw_phase == RMW_PHASE_WR) ? (wdata_chk_q[di] != (~^wdata_q[di*32 +: 32])) : 1'b0;
                end
            end


            // Check
            if(err_parity_chk_disable_i) begin
                addr_chk_err = '0;
            end else begin
                //Address is always used during the write cycle, regardless of pipeline or not
                addr_chk_err = (rmw_phase == RMW_PHASE_WR) ? (addr_chk_q != (~^addr_q)) : 1'b0;
             end
        end
    end
    else begin: gen_rmw_no_parity_en
        assign addr_chk_err = '0;
        assign wdata_chk_err = '0;
    end
    endgenerate


    generate if ((PARITY_EN == 1) && (RMW_PIPELINE == 1))
    begin: gen_rmw_pipeline_parity_en
        logic [(DATA_WIDTH/32)-1:0] rmw_pipeline_wdata_chk_q, rmw_pipeline_wdata_chk;

        always_ff @(posedge clk or negedge reset_na) begin
            if (~reset_na) begin
                rmw_pipeline_wdata_chk_q <= '1;
            end else begin
                if ((rmw_phase == RMW_PHASE_PIPELINE)) begin
                    rmw_pipeline_wdata_chk_q <= rmw_pipeline_wdata_chk;
                end
            end
        end

        // Parity checking and generation for flop of data
        always_comb begin
            rmw_pipeline_wdata_chk_err = '0;
            for (integer di = 0; di < (DATA_WIDTH/32); di = di + 1) begin
                // Generate
                rmw_pipeline_wdata_chk[di] = ~^mod_wdata[di*32 +: 32];

                // Check parity on the modified write data flop
                if(~err_parity_chk_disable_i) begin
                    rmw_pipeline_wdata_chk_err |= (rmw_phase == RMW_PHASE_WR) ? (rmw_pipeline_wdata_chk_q[di] != (~^mod_wdata_q[di*32 +: 32])) : 1'b0;
                end
            end
        end
    end
    else begin: gen_rmw_no_pipeline_parity_en
        assign rmw_pipeline_wdata_chk_err = '0;
    end
    endgenerate

    assign rmw_busy = (rmw_state == RMW_STATE_BUSY);
    assign rmw_parity_err = addr_chk_err | wdata_chk_err | rmw_pipeline_wdata_chk_err;

endmodule

