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
// File        : mpu.v
// Description : Provides memory read, write, and execution protection.




module hsp_mpu 
#(parameter ADDR_WIDTH = 13,
            NUM_PAGES = 2,
            CRYPTOS_ACC = 1, // 1 - support crypto accesses (shared RAM)  0 - Other
            ID_WIDTH = 4,
            REG_ADDR_WIDTH = 10,
            REG_DATA_WIDTH = 32,    // Must be 32
            ATTRIB_RESET = 4'h0,    // Reset value for attributes
            ATTRIB_WMASK = 4'h0,    // Bits with 0 will remain at 0
            SINGLE_CYCLE = 0        // Returns acc_vio in single cycle instead of default 1 stage pipeline
            )
(
    //-------------------------------------------
    // to/from logic
    //-------------------------------------------

    input logic clk,
    input logic reset_na,
    input logic soft_rst,

    // Access information
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [ID_WIDTH-1:0] id,
    input logic en,
    input logic we,
    input logic xe,
    input logic accsrc,       // 0- RP/SP  1- Crypto cores
    input logic mpu_top_page_acc_en,       // AEB to allow access to top page of SP ROM 

    // Register interface
    input logic [REG_ADDR_WIDTH-1:0] reg_addr,
    input logic [REG_DATA_WIDTH-1:0] reg_wdata,
    input logic reg_wr,
    input logic reg_rd,

    // Global control signals (affect all pages)
    input logic mpu_disable,
    input logic priv_mode,
    input logic override_nx,

    // Violation accvio information and transaction attributes
    output logic int_acc_vio,
    output logic [ID_WIDTH-1:0] accvio_id,
    output logic [ADDR_WIDTH-1:0] accvio_addr,
    output logic accvio_ex,
    output logic accvio_wr,
    output logic accvio_rd,
    output logic txn_rd,            // these signals are used to log info when acc vio is indicated by external logic
    output logic txn_wr,
    output logic txn_ex,
    output logic busy,

    // Register interface
    output logic [REG_DATA_WIDTH-1:0] reg_rdata,
    output logic reg_accerr,
    output logic reg_respvalid
);

    //-------------------------------------------
    // Local Parameters
    //-------------------------------------------

    // Note that Ceiling(a/b) = (a+b-1)/b for positive integers a,b
    localparam  NUM_REG_PER_SET = (NUM_PAGES + 7)/8;
    localparam  PRIV_ATTRIB_OFFSET = NUM_REG_PER_SET;
    localparam  CRYPTO_ATTRIB_OFFSET = NUM_REG_PER_SET*2;
    localparam  unsigned NUM_REGS = (CRYPTOS_ACC + 2) * NUM_REG_PER_SET;    // Total number of registers
    localparam  ATTRIB_SHIFT_WIDTH = 12;            // 4k mem per set of attrib
    localparam  LOCK = 3;
    localparam  EXECUTABLE = 2;
    localparam  WRITABLE = 1;
    localparam  READABLE = 0;
    localparam  NUM_PAGES_LP = (NUM_PAGES) & 16'hffff;

    // internal signals
    logic [REG_DATA_WIDTH-1:0] Regf [NUM_REGS-1:0];

    logic [REG_DATA_WIDTH-1:0] wr_diff;
    logic                      lock_err;
    logic                      wr_err;
    logic                      reg_addr_err;
    logic [REG_DATA_WIDTH-1:0]  reg_selected;
    logic                       acc_vio;
    integer                   i;

    assign reg_addr_err = reg_addr >= NUM_REGS;
    assign reg_selected = reg_addr_err ? {REG_DATA_WIDTH{1'b0}} : Regf[reg_addr[$clog2(NUM_REGS)-1:0]];
    
    // Diff the incoming data and current register value
    assign wr_diff = reg_selected ^ reg_wdata;

    // Check for attempts to modify locked bits
    logic [7:0]                nibble_lock_err;
    generate
        genvar                j;
        for (j=0; j<8; j=j+1) begin : lock_err_det
            assign nibble_lock_err[j] = reg_selected[(4*j)+LOCK] & (| wr_diff[(4*j)+3 : 4*j]);
        end
        assign lock_err = | nibble_lock_err;
    endgenerate

    assign wr_err = reg_wr & (reg_addr_err | lock_err);

    // Register write process
    always_ff @(posedge clk or negedge reset_na) begin
        if (~reset_na) begin
            for (i=0; i<NUM_REGS; i=i+1) begin
                Regf[i] <= {8{ATTRIB_RESET}};
            end
        end
        else if (soft_rst) begin
            for (i=0; i<NUM_REGS; i=i+1) begin
                Regf[i] <= {8{ATTRIB_RESET}};
            end
        end
        else if (reg_wr & ~wr_err) begin
            Regf[reg_addr[($clog2(NUM_REGS))-1:0]] <= reg_wdata & {8{ATTRIB_WMASK}};
        end
    end

    assign reg_rdata = reg_rd ? reg_selected : 32'b0;
    assign reg_respvalid = reg_rd | reg_wr;
    assign reg_accerr = wr_err | (reg_rd & reg_addr_err);

    // Violation checker

    // Latch memory control inputs (or not if single cycle)
    logic [REG_DATA_WIDTH-1:0] user_mode_reg;
   
    logic [REG_DATA_WIDTH-1:0] priv_mode_reg;
    logic [2:0]                attrib_sel;

    logic                      en_reg, we_reg, xe_reg, pm_reg;
    logic [ADDR_WIDTH-1:0]     addr_reg;
    logic [3:0]                id_reg;
    logic                      accsrc_reg;

    logic [(ADDR_WIDTH-ATTRIB_SHIFT_WIDTH)-1:0] page_sel;

    logic                                       top_page_access;
    logic                                       top_page_accvio;
    logic                                       top_page_accvio_reg;
 
   
    localparam  SIZE_RFADDR = $clog2(NUM_REGS);   

    assign page_sel         = addr[ADDR_WIDTH-1:ATTRIB_SHIFT_WIDTH];
    assign top_page_access  = (page_sel == (NUM_PAGES_LP-1'h1));
    assign top_page_accvio  = top_page_access & !mpu_top_page_acc_en;

    // (addr >> ATTRIB_SHIFT_WIDTH) selects the page number
    // ((addr >> ATTRIB_SHIFT_WIDTH) >> 3) selects the MPU logic. Each logic holds upto 8 pages
    generate 
        if (SINGLE_CYCLE == 1) begin : gen_SINGLE_CYCLE

        logic [31:0] user_mode_select;
        
        assign user_mode_select = 32'(((addr >> ATTRIB_SHIFT_WIDTH) >> 3) + (accsrc ? CRYPTO_ATTRIB_OFFSET : 32'h0));	 
        assign user_mode_reg = 32'(Regf[SIZE_RFADDR'(user_mode_select)]);	 
        assign priv_mode_reg = Regf[((addr >> ATTRIB_SHIFT_WIDTH) >> 3) + PRIV_ATTRIB_OFFSET];
        assign attrib_sel[2:0] = 3'(7'(addr >> ATTRIB_SHIFT_WIDTH) & 7'b0000111);
        assign en_reg = en;
        assign we_reg = we;
        assign xe_reg = xe; assign pm_reg = priv_mode;
        assign addr_reg = addr;
        assign id_reg = id;
        assign accsrc_reg = accsrc;
        assign top_page_accvio_reg = top_page_accvio;
    end
    else begin : gen_PIPELINED
        logic [REG_DATA_WIDTH-1:0] user_mode_reg_q;
        logic [REG_DATA_WIDTH-1:0] priv_mode_reg_q;
        logic [2:0]                attrib_sel_q;

        logic                      en_reg_q, we_reg_q, xe_reg_q, pm_reg_q;
        logic [ADDR_WIDTH-1:0]     addr_reg_q;
        logic [3:0]                id_reg_q;
        logic                      accsrc_reg_q;
        logic                      top_page_accvio_q;

	    logic [31:0]                user_mode_select;
        assign user_mode_select = 32'(((addr >> ATTRIB_SHIFT_WIDTH) >> 3) + (accsrc ? CRYPTO_ATTRIB_OFFSET : 32'b0)); //Created to fix overflow lint issue

        always_ff @(posedge clk or negedge reset_na) begin
            if (~reset_na) begin
                user_mode_reg_q <= 32'b0;
                priv_mode_reg_q <= 32'b0;
                attrib_sel_q <=    3'b0;
                en_reg_q <= 1'b0;
                we_reg_q <= 1'b0;
                xe_reg_q <= 1'b0; pm_reg_q <= 1'b0;
                addr_reg_q <= {ADDR_WIDTH{1'b0}};
                id_reg_q <= 4'b0;
                accsrc_reg_q <= 1'b0;
                top_page_accvio_q <= 1'b0;
            end
            else if (soft_rst) begin
                user_mode_reg_q <= 32'b0;
                priv_mode_reg_q <= 32'b0;
                attrib_sel_q <=    3'b0;
                en_reg_q <= 1'b0;
                we_reg_q <= 1'b0;
                xe_reg_q <= 1'b0; pm_reg_q <= 1'b0;
                addr_reg_q <= {ADDR_WIDTH{1'b0}};
                id_reg_q <= 4'b0;
                accsrc_reg_q <= 1'b0;
                top_page_accvio_q <= 1'b0;
            end
            else begin
                user_mode_reg_q <= Regf[SIZE_RFADDR'(user_mode_select)];
                priv_mode_reg_q <= Regf[($clog2(NUM_REGS))'(((addr >> ATTRIB_SHIFT_WIDTH) >> 3) + PRIV_ATTRIB_OFFSET)];
                attrib_sel_q <= 3'(addr >> ATTRIB_SHIFT_WIDTH) & 3'b111;
                en_reg_q <= en;
                we_reg_q <= we;
                xe_reg_q <= xe; pm_reg_q <= priv_mode;
                addr_reg_q <= addr;
                id_reg_q <= id;
                accsrc_reg_q <= accsrc;
                top_page_accvio_q <= top_page_accvio;
            end
        end

        assign user_mode_reg = user_mode_reg_q;
        assign priv_mode_reg = priv_mode_reg_q;
        assign attrib_sel = attrib_sel_q;

        assign en_reg = en_reg_q;
        assign we_reg = we_reg_q;
        assign xe_reg = xe_reg_q; assign pm_reg = pm_reg_q;
        assign addr_reg = addr_reg_q;
        assign id_reg = id_reg_q;
        assign accsrc_reg = accsrc_reg_q;
        assign top_page_accvio_reg = top_page_accvio_q;
    end
    endgenerate

    logic vio_valid;	// Indicates that the violation status is valid

    logic [2:0]  user_mode_attrib;
    logic [2:0]  priv_mode_attrib;
    
    assign user_mode_attrib = user_mode_reg[attrib_sel*4+:3];
    assign priv_mode_attrib = priv_mode_reg[attrib_sel*4+:3];

    logic [2:0]  actual_attrib;       // Actual attributes used for permission check
    assign actual_attrib = accsrc_reg ? user_mode_attrib : (pm_reg ? priv_mode_attrib : (user_mode_attrib & priv_mode_attrib));
    
    logic chk_en;
    assign chk_en = en_reg & ((~mpu_disable) | top_page_accvio_reg);

    always_comb begin
        accvio_rd = 1'b0;
        accvio_wr = 1'b0;
        accvio_ex = 1'b0;
        case ({chk_en, we_reg, xe_reg})
            3'b000:begin        // Inactive, only check the no-execute override
                acc_vio = en_reg & xe_reg & override_nx;
                accvio_ex = acc_vio;
            end
            3'b001:begin        // Inactive, only check the no-execute override
                acc_vio = en_reg & xe_reg & override_nx;
                accvio_ex = acc_vio;
            end
            3'b010:begin        // Inactive, only check the no-execute override
                acc_vio = en_reg & xe_reg & override_nx;
                accvio_ex = acc_vio;
            end
            3'b011:begin        // Inactive, only check the no-execute override
                acc_vio = en_reg & xe_reg & override_nx;
                accvio_ex = acc_vio;
            end
            3'b100:begin        // Read
                acc_vio = (~actual_attrib[READABLE]) | top_page_accvio_reg;
                accvio_rd = acc_vio;
            end
            3'b110:begin        // Write
                acc_vio = (~actual_attrib[WRITABLE]) | top_page_accvio_reg;
                accvio_wr = acc_vio;
            end
            3'b101:begin        // Instruction fetch
                acc_vio = ((~actual_attrib[EXECUTABLE]) | override_nx) | top_page_accvio_reg;
                accvio_ex = acc_vio;
            end
            3'b111:begin       // This should never happen. But it's handled here for completeness.
                acc_vio = 1'b1;
                accvio_ex = acc_vio;
                accvio_wr = acc_vio;
            end
        endcase
    end

    assign busy = en_reg;
    assign int_acc_vio = acc_vio;
    assign txn_rd = (en_reg & (~xe_reg) & (~we_reg));
    assign txn_wr = (en_reg & (~xe_reg) & we_reg);
    assign txn_ex = (en_reg & xe_reg & (~we_reg));
    assign accvio_id = id_reg;
    assign accvio_addr = addr_reg;

endmodule
