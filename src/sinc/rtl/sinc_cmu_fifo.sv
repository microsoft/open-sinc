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
// File        : sinc_cmu_fifo.sv
// Description : CMU input buffer (FIFO). Stores cache block data fetched via
//               AXI manager with asymmetric push/pop data widths.

module sinc_cmu_fifo #(
    parameter WIDTH             = 128,
    parameter DEPTH             = 32,       // Must always be power of 2
    parameter PUSH_DATAW        = 32,       // Other values may not be supported
    parameter POP_DATAW         = 128,      // Other values may not be supported

    /* Derived parameters, don't set manually */
    parameter PUSH_ENTRIES      = (WIDTH * DEPTH) / PUSH_DATAW,
    parameter PUSH_ADDRW        = (PUSH_ENTRIES == 1) ? 1 : $clog2(PUSH_ENTRIES),
    parameter POP_ENTRIES       = (WIDTH * DEPTH) / POP_DATAW,
    parameter POP_ADDRW         = (POP_ENTRIES == 1) ? 1 : $clog2(POP_ENTRIES),
    parameter COUNT_WIDTH       = (PUSH_DATAW < POP_DATAW) ? $clog2(PUSH_ENTRIES+1) : $clog2(POP_ENTRIES+1)
)
(
    input logic                     clk_i,
    input logic                     rstn_i,
    input logic                     clear,

    input logic                     push_en,
    input logic                     pop_en,
    input logic [PUSH_DATAW-1:0]    push_data,

    output logic                    push_rdy,  // indicates that there is a space available to push an entry
    output logic                    pop_rdy,   // Indicates that an entry is available to pop
    output logic [POP_DATAW-1:0]    pop_data,

    output logic                    empty,
    output logic                    full,
    output logic [COUNT_WIDTH-1:0]  entries_in_use,
    output logic                    overflow_err,
    output logic                    underflow_err
);

    localparam unsigned PUSH_POP_RATIO  = (PUSH_DATAW < POP_DATAW) ? (POP_DATAW/PUSH_DATAW) : (PUSH_DATAW/POP_DATAW);
    localparam unsigned PUSH_POP_RATIOW = (PUSH_POP_RATIO == 1) ? 1 : $clog2(PUSH_POP_RATIO);
    localparam unsigned PTRW            = (PUSH_DATAW < POP_DATAW) ? PUSH_ADDRW : POP_ADDRW;
    localparam unsigned LINEW           = (DEPTH == 1) ? 1 : (PTRW - PUSH_POP_RATIOW);
    localparam NUM_STORAGE_CHUNKS       = (PUSH_DATAW < POP_DATAW) ? (WIDTH / PUSH_DATAW) : (WIDTH / POP_DATAW);
    localparam STORAGE_CHUNKSW          = (PUSH_DATAW < POP_DATAW) ? PUSH_DATAW : POP_DATAW;

    typedef struct packed {
        logic                   wrap;
        logic [PTRW-1:0]        ptr;
    } fifo_ptr_t;

    fifo_ptr_t                  push_ptr_din;
    fifo_ptr_t                  push_ptr_q;
    fifo_ptr_t                  pop_ptr_din;
    fifo_ptr_t                  pop_ptr_q;


    logic                       wrap_match;
    logic                       ptr_match;
    logic                       line_match;

    logic                       push_qual;
    logic                       pop_qual;
    logic [POP_DATAW-1:0]       pop_data_int;


    logic [LINEW-1:0]           push_ptr_line;
    logic [PUSH_POP_RATIOW-1:0] push_ptr_pos;
    logic [LINEW-1:0]           pop_ptr_line;
    logic [PUSH_POP_RATIOW-1:0] pop_ptr_pos;

    logic                       almost_full;            // applicable when PUSH_DATAW > POP_DATAW
    logic                       almost_empty;           // applicable when PUSH_DATAW < POP_DATAW

    logic [DEPTH-1:0][NUM_STORAGE_CHUNKS-1:0][STORAGE_CHUNKSW-1:0]  memory;

    logic [PUSH_ADDRW-1:0]      unused_push_addr;
    logic [POP_ADDRW-1:0]       unused_pop_addr;

    generate
        if(DEPTH == 1) begin: gen_single_line_fifo
            assign push_ptr_line = 1'h0;
            assign pop_ptr_line = 1'h0;
        end
        else begin: gen_multi_line_fifo
            always_comb begin
                push_ptr_line = push_ptr_q.ptr[PTRW - 1 : PUSH_POP_RATIOW];        
                pop_ptr_line = pop_ptr_q.ptr[PTRW - 1 : PUSH_POP_RATIOW];
            end
        end
    endgenerate

    always_comb begin

        /* calculate ptr line and position */
        push_ptr_pos = push_ptr_q.ptr[PUSH_POP_RATIOW - 1 : 0];
        
        // pop_ptr_line = pop_ptr_q.ptr[PTRW - 1 : PUSH_POP_RATIOW];
        pop_ptr_pos = pop_ptr_q.ptr[PUSH_POP_RATIOW - 1 : 0];

        /* Compute absolute full/empty flags by checking pointer equality */
        wrap_match = (push_ptr_q.wrap == pop_ptr_q.wrap);
        ptr_match  = (push_ptr_q.ptr == pop_ptr_q.ptr);
        line_match = (push_ptr_line == pop_ptr_line);

        empty = wrap_match & ptr_match;
        full  = (~wrap_match) & ptr_match;
        
        /* almost_full is the condition where even if FIFO is not full, pushing data will cause overflow_err
        because only a partial push entry is available. Similar is true for almost_empty */
        almost_empty = wrap_match & line_match & (~ptr_match);          // only applicable when PUSH_DATAW < POP_DATAW
        almost_full = (~wrap_match) & line_match & (~ptr_match);        // only applicable when PUSH_DATAW > POP_DATAW

        /* only push/pop if the FIFO isn't full/empty, respectively */
        push_qual       = push_en & push_rdy;
        pop_qual        = pop_en & pop_rdy;

        /* Hardware assertions for debug purposes */
        overflow_err    = push_en & (~push_rdy);
        underflow_err   = pop_en & (~pop_rdy);
        
        entries_in_use = {~wrap_match, push_ptr_q.ptr} - {1'b0, pop_ptr_q.ptr};
    end

    generate
        if (PUSH_DATAW < POP_DATAW) begin
            always_comb begin
                // If FIFO is a power of 2 depth, just add one to update the pointers.
                // The pointers will naturally wrap and rollover at FIFO_DEPTH.
                push_ptr_din = push_ptr_q + 1'h1;
                pop_ptr_din = pop_ptr_q + (PUSH_POP_RATIOW + 1)'(PUSH_POP_RATIO);
            end
        end
        else begin
            always_comb begin
                // If FIFO is a power of 2 depth, just add one to update the pointers.
                // The pointers will naturally wrap and rollover at FIFO_DEPTH.
                push_ptr_din = push_ptr_q + (PUSH_POP_RATIOW + 1)'(PUSH_POP_RATIO);
                pop_ptr_din = pop_ptr_q + 1'h1;
            end
        end
    endgenerate

    // Update the write pointer whenever there is a push
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (~rstn_i) begin
            push_ptr_q <= '0;
        end
        else if (clear) begin
            push_ptr_q <= '0;
        end
        else if (push_qual) begin
            push_ptr_q <= push_ptr_din;
        end
    end

    // Update the read pointer whenever there is a pop
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (~rstn_i) begin
            pop_ptr_q <= '0;
        end
        else if (clear) begin
            pop_ptr_q <= '0;
        end
        else if (pop_qual) begin
            pop_ptr_q <= pop_ptr_din;
        end
    end

    /* The entry count can be computed simply by using ~wrap_match as the MSB
        of the write pointer to implicitly add a power of 2 number to it. */

    /* memory storage */
    generate
        if(PUSH_DATAW < POP_DATAW) begin: gen_push_less_than_pop_block

            logic [PUSH_POP_RATIOW-1:0] unused_pop_ptr_pos;
            
            always_ff @( posedge clk_i or negedge rstn_i ) begin
                if(~rstn_i) begin
                    for (int i = 0; i < DEPTH; i = i + 1) begin
                        for (int j = 0; j < NUM_STORAGE_CHUNKS; j = j + 1) begin
                            memory[i][j] <= {PUSH_DATAW{1'h0}};
                        end
                    end
                end
                else if(clear) begin
                    for (int i = 0; i < DEPTH; i = i + 1) begin
                        for (int j = 0; j < NUM_STORAGE_CHUNKS; j = j + 1) begin
                            memory[i][j] <= {PUSH_DATAW{1'h0}};
                        end
                    end
                end
                else if(push_qual) begin
                    memory[push_ptr_line][push_ptr_pos] <= push_data;
                end
            end

            for (genvar i = 0; i < NUM_STORAGE_CHUNKS; i = i + 1) begin
                assign pop_data_int[(i*STORAGE_CHUNKSW)+(STORAGE_CHUNKSW-1)-:STORAGE_CHUNKSW] = memory[pop_ptr_line][i];
            end

            assign unused_pop_ptr_pos = pop_ptr_pos;

        end
        else begin: gen_pop_less_than_pop_block

            logic [PUSH_POP_RATIOW-1:0] unused_push_ptr_pos;
            
            always_ff @( posedge clk_i or negedge rstn_i ) begin
                if(~rstn_i) begin
                    for (int i = 0; i < DEPTH; i = i + 1) begin
                        for (int j = 0; j < NUM_STORAGE_CHUNKS; j = j + 1) begin
                            memory[i][j] <= {POP_DATAW{1'h0}};
                        end
                    end
                end
                else if(clear) begin
                    for (int i = 0; i < DEPTH; i = i + 1) begin
                        for (int j = 0; j < NUM_STORAGE_CHUNKS; j = j + 1) begin
                            memory[i][j] <= {POP_DATAW{1'h0}};
                        end
                    end
                end
                else begin
                    if(push_qual) begin
                        for (int i = 0; i < NUM_STORAGE_CHUNKS; i = i + 1) begin
                            memory[push_ptr_line][i] <= push_data[(i*STORAGE_CHUNKSW)+(STORAGE_CHUNKSW-1)-:STORAGE_CHUNKSW];
                        end
                    end
                end
            end

            assign pop_data_int = memory[pop_ptr_line][pop_ptr_pos];

            assign unused_push_ptr_pos = push_ptr_pos;

        end
    endgenerate

    assign push_rdy         = ~(full | almost_full);
    assign pop_rdy          = ~(empty | almost_empty);
    assign pop_data         = pop_data_int;

endmodule