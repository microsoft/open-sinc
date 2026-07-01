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
// File         : mem_erase.sv
// Description  : HW state machine to sequentially write '0's to the entire memory array.

module mem_erase (/*AUTOARG*/
    // Outputs
    erase_addr, erase_we, erase_done, engn_erase_done,
    // Inputs
    clk, reset_na, erase_start, engn_erase_start
    );


    //-------------------------------------------
    // Parameters
    //-------------------------------------------
    parameter ADDR_WIDTH = 23;                          // up to 23 bits of address
    parameter DATA_WIDTH = 64;                          // must be either 32 or 64 bits of data
    parameter ERASE_NBYTES = (DATA_WIDTH+7)/8;              // number of bytes to erase per cycle
    parameter ERASE_END_ADDR = (2**ADDR_WIDTH)-ERASE_NBYTES; // full erase up to this address
    parameter SUPPORT_ENGN_ERASE = 0;                   // support engine erase for this instance
    parameter SUPPORT_ERASE = 0;                        // support erase for this instance
    parameter ENGN_ERASE_END_ADDR = (2**ADDR_WIDTH)-ERASE_NBYTES; // engine erase up to this address
    parameter ERASE_START_ADDR = 0;                     // Start erase from this address
    parameter ENGN_ERASE_START_ADDR = 0;                      // Start engine erase from this address
    //-------------------------------------------
    // Inputs
    //-------------------------------------------
    input logic                     clk;
    input logic                     reset_na;

    input logic                     erase_start;

    //-------------------------------------------
    // Outputs
    //-------------------------------------------

    // to memories
    output logic  [ADDR_WIDTH-1:0] erase_addr;
    output logic                   erase_we;

    // to creg control
    output logic                   erase_done;

    //-------------------------------------------
    // Optional I/O to engine control, in order
    // to support engine erase capability.
    // May be tied off if this is not used
    input logic                    engn_erase_start;
    output logic                   engn_erase_done;

    logic                          full_erase_in_progress;
    logic                          new_full_erase_in_progress;

    //-------------------------------------------
    logic                          new_erase_we;
    logic  [ADDR_WIDTH-1:0]        new_erase_addr;
    logic                          new_erase_done;
    logic                          new_engn_erase_done;

generate if (SUPPORT_ENGN_ERASE == 1)
begin : gen_ENGN_ERASE
    always_comb begin
        if ((~full_erase_in_progress) && (erase_addr == ENGN_ERASE_END_ADDR))
        begin // if engine erase, stop when we reached the engine erase top address
            new_erase_we       = 1'b0;
            new_erase_addr     = {ADDR_WIDTH{1'b0}};
            new_full_erase_in_progress = full_erase_in_progress;
        end
        // Support partial erase or a full erase
        else if (full_erase_in_progress &&
            (erase_addr == ERASE_END_ADDR))
        begin // if full erase, stop when we reached the erase top address
            new_erase_we               = 1'b0;
            new_erase_addr = {ADDR_WIDTH{1'b0}};
            new_full_erase_in_progress = 1'b0;
        end
        else
        begin // else continue erasing, incrementing address by sizeof(memory)
            new_erase_we   = 1'b1;
            new_erase_addr = erase_addr + ERASE_NBYTES;
            new_full_erase_in_progress = full_erase_in_progress;
        end

        if ((!full_erase_in_progress) && (erase_addr == ENGN_ERASE_END_ADDR))
        begin
            new_engn_erase_done = 1'b1;
        end
        else
        begin
            new_engn_erase_done = 1'b0;
        end

        if (full_erase_in_progress && (erase_addr == ERASE_END_ADDR))
        begin
            new_erase_done      = 1'b1;
        end
        else
        begin
            new_erase_done      = 1'b0;
        end
    end
end
else // generate if (SUPPORT_ENGN_ERASE == 0)
begin : gen_NO_ENGN_ERASE
    always_comb begin
        // Do not support partial erase or a full erase
        if (erase_addr == ERASE_END_ADDR)
        begin // stop when we reached the full top address
            new_erase_we               = 1'b0;
            new_erase_addr = {ADDR_WIDTH{1'b0}};
            new_erase_done  = 1'b1;
        end
        else
        begin // else continue erasing, incrementing address by sizeof(memory)
            new_erase_we   = 1'b1;
            new_erase_addr = erase_addr + ERASE_NBYTES;
            new_erase_done  = 1'b0;
        end
    end

    // full_erase_in_progress and engn_erase_done becomes unused in this case
    assign new_full_erase_in_progress = 1'b0;
    assign new_engn_erase_done = engn_erase_done;
end
endgenerate


    always_ff @(posedge clk or negedge reset_na)
    begin
        if(~reset_na)
        begin
            erase_addr             <= {ADDR_WIDTH{1'b0}};
            erase_we               <= 1'b0;
            erase_done             <= 1'b0;
            engn_erase_done        <= 1'b0;
            full_erase_in_progress <= 1'b0;
        end
        else
        begin

`ifndef HSP_DV_FAST_ERASE
            // if fast erase is not defined, perform normal erase functionality
            if (erase_we)
            begin
                // as long as erase_we='1', erase is in progress
                // furthermore, whether it's engn erase or SW erase is determined by the
                // full_erase_in_progress flag
                erase_we   <= new_erase_we;
                erase_addr <= new_erase_addr;
                full_erase_in_progress <= new_full_erase_in_progress;
            end
            else if (engn_erase_start && SUPPORT_ENGN_ERASE)
            begin // starting to erase from ENGN_ERASE_START_ADDR up to ENGN_ERASE_END_ADDR
                erase_addr <= ADDR_WIDTH'(ENGN_ERASE_START_ADDR);
                erase_we   <= 1'b1;
            end
            // ignore erase_start if SUPPORT_ERASE is not set
            else if (erase_start && (~full_erase_in_progress) && SUPPORT_ERASE)
            begin // start = restart from ERASE_START_ADDR
                erase_addr             <= ADDR_WIDTH'(ERASE_START_ADDR);
                erase_we               <= 1'b1;
                full_erase_in_progress <= 1'b1;
            end

            erase_done     <= new_erase_done;
            engn_erase_done <= new_engn_erase_done;


`else // 'ifdef HSP_DV_FAST_ERASE
            // fast erase means HW return done immediately.
            // Test environment is expected to trigger on the start, and erase the memory
            // through side-loading functions
            if (erase_start) begin
                erase_done <= 1'b1;
            end
            if (erase_done) begin
                erase_done <= 1'b0;
            end

            if (engn_erase_start) begin
                engn_erase_done <= 1'b1;
            end
            if (engn_erase_done) begin
                engn_erase_done <= 1'b0;
            end
`endif // HSP_DV_FAST_ERASE

        end
    end

endmodule // mem_erase

