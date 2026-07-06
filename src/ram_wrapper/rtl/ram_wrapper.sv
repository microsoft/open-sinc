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
// File        : ram_wrapper.sv
// Description : RAM wrapper integrating EDC (error detection code) and memory
//               erase functionality.

module ram_wrapper (/*AUTOARG*/
                    // Outputs
                    rdata_o, rdata_valid_o, busy_o, engn_erase_done_o, ram_me_o, ram_we_o, ram_adr_o, ram_di_o, w_err_parity_o, r_err_parity_o, rdatachk_o,
                    erase_busy_o, erase_done_o, err_erase_busy_o, err_uncorr_o, err_addr_o, err_corr_o, inject_done_o, inject_busy_o,
                    // Inputs
                    clk_i, reset_na_i, wdata_i, addr_i, en_i, we_i, engn_erase_start_i, ram_qi_i, erase_start_i,
                    erase_wdata_i, err_chk_disable_i, inject_i, inject_addr_i, inject_mask_i,
                    err_parity_chk_disable_i, addrchk_i, wdatachk_i
                    );

    //-------------------------------------------
    // Parameters
    //-------------------------------------------
    parameter ADDR_WIDTH = 10;                          // can't be more than 23
    parameter SIZE = 4096;                              // total number of bytes, must be addressable using 'ADDR_WIDTH' bits of addresses
    parameter DATA_WIDTH = 32;                          // must be either 32 or 64 bits of data
    parameter NUM_BYTES = DATA_WIDTH/8;                 // 4 or 8 bytes, depending on DATA_WIDTH
    parameter SUPPORT_SECDED = 1;                       // Set to 1 for enabling SECDED scheme. Set to 0 for DED scheme.
    parameter SUPPORT_RMW = 1;                          // support Read-Mod-Write
    parameter SUPPORT_INJECT = 1;                       // support error inject
    parameter SUPPORT_ENGN_ERASE = 0;                   // support engine erase for this instance
    parameter SUPPORT_ERASE = 1;                        // support creg erase for this instance
    parameter SUPPORT_WRITE_BACK = 0;                   // Set to enable write back on correctable errors during read. When enabled, RMW_PIPELINE also applies to write back.
    parameter RMW_PIPELINE = 0;                         // 0 - No pipelining on RMW writes, 1 - One pipeline stage on RMW writes
    parameter PARITY_EN = 0;                            // Parity enable for engine input signals and internal flops that are not ECC protected. 0 - No parity protection 1- Parity protection enabled


    //-------------------------------------------
    // Derived Parameters - Do not change manually
    //-------------------------------------------
    parameter CHECK_WIDTH = SUPPORT_SECDED ? (7*(DATA_WIDTH/32)) : (6*(DATA_WIDTH/32));
    parameter CODE_WIDTH  = DATA_WIDTH + CHECK_WIDTH;
    parameter NUM_LSBS = $clog2(NUM_BYTES-1);           // Number of address LSBs
    parameter ERASE_ADDR_WIDTH = ADDR_WIDTH + NUM_LSBS; // Erase addr includes LSBs
    parameter ERASE_NBYTES = NUM_BYTES;                 // number of bytes to erase per cycle

    //-------------------------------------------
    // Change below parameters as applicable
    //-------------------------------------------
    parameter ERASE_START_ADDR = 0;                     // Start erase from this address
    parameter ENGN_ERASE_START_ADDR = 0;                // Start Engine erase from this address
    parameter ERASE_END_ADDR = SIZE-ERASE_NBYTES;       // full erase up to this address
    parameter ENGN_ERASE_END_ADDR = SIZE-ERASE_NBYTES;  // engine erase up to this address
    parameter bit INVERSION [0:CODE_WIDTH-1] = '{CODE_WIDTH{1'b0}};     // Each element indicates whether the bit is inverted. Element index is bit position.
                                                                        // A element of index x with value 1 indicates that bit x is inverted.
    parameter int SHUFFLING [0:CODE_WIDTH-1] = '{CODE_WIDTH{1'b0}};     // Each element indicates the relative position that a bit is mapped to.
                                                                        // A element of index x with value y indicates that bit x is mapped to bit (x+y).


    localparam C_ERRDATA = 32'hDEADBEEF; // this is what is returned as rdata if there is an EDC error
    localparam ERR_CORR_WIDTH = $clog2((DATA_WIDTH/32)+1);

    //-------------------------------------------
    // to/from logic
    //-------------------------------------------
    input logic                         clk_i;
    input logic                         reset_na_i;

    input logic [DATA_WIDTH-1:0]        wdata_i;
    input logic [ADDR_WIDTH-1:0]        addr_i;
    input logic                         en_i;
    input logic [(DATA_WIDTH/8)-1:0]    we_i;

    output logic [DATA_WIDTH-1:0]       rdata_o;
    output logic                        rdata_valid_o;
    output logic                        busy_o;

    // may be tied off is engine doesn't need to perform a memory erase
    input logic                         engn_erase_start_i;
    output logic                        engn_erase_done_o;

    //-------------------------------------------
    // to/from memory macros
    //-------------------------------------------
    output logic                        ram_me_o;
    output logic                        ram_we_o;
    output logic [ADDR_WIDTH-1:0]       ram_adr_o;
    output logic [CODE_WIDTH-1:0]       ram_di_o;
    input logic [CODE_WIDTH-1:0]        ram_qi_i;

    //-------------------------------------------
    // to/from control registers
    //-------------------------------------------
    // erase signals
    input logic                         erase_start_i; // single cycle pulse
    input logic [DATA_WIDTH-1:0]        erase_wdata_i; // random data to erase memory with
    output logic                        erase_busy_o;  // indicating erase is in progress
    output logic                        erase_done_o;  // single cycle pulse

    // error correction and detection signals
    output logic                        err_erase_busy_o;
    output logic                        err_uncorr_o;
    output logic [ADDR_WIDTH-1:0]       err_addr_o;
    output logic [ERR_CORR_WIDTH-1:0]   err_corr_o;

    // error injection signals
    input logic                         inject_i;
    input logic [ADDR_WIDTH-1:0]        inject_addr_i;
    input logic [CODE_WIDTH-1:0]        inject_mask_i;
    output logic                        inject_done_o;
    output logic                        inject_busy_o;

    // parity and SECDED disablement signals
    input logic                         err_chk_disable_i;
    input logic                         err_parity_chk_disable_i;

    // parity check and generation
    input logic [((ADDR_WIDTH+31)/32)-1:0] addrchk_i;
    input logic [(DATA_WIDTH/32)-1:0]   wdatachk_i;
    output logic [(DATA_WIDTH/32)-1:0]  rdatachk_o;

    // parity error
    output logic                        r_err_parity_o;
    output logic                        w_err_parity_o;

    //-------------------------------------------
    // internal signals
    //-------------------------------------------
    logic [ERASE_ADDR_WIDTH-1:0] erase_addr;
    logic                       erase_we;
    logic                       qualified_en;
    logic                       support_inject_vld;
    logic                       inject_in_progress;
    logic                       non_rmw_en;
    logic                       rmw_en;
    logic                       rmw_we;
    logic [DATA_WIDTH-1:0]      rmw_wdata;
    logic [ADDR_WIDTH-1:0]      rmw_addr;
    logic                       rmw_busy;
    logic [ADDR_WIDTH-1:0]      iedc_addr;
    logic [DATA_WIDTH-1:0]      iedc_data;
    logic [CODE_WIDTH-1:0]      iedc_code;
    logic [DATA_WIDTH-1:0]      oedc_data;

    logic                       non_rmw_rd_q;
    logic                       non_rmw_rd_vld;
    logic                       non_rmw_wr_q;
    logic                       rmw_rd_q;
    logic                       rmw_rd_vld;
    logic [ADDR_WIDTH-1:0]      addr_q;
    logic [ADDR_WIDTH-1:0]      addr_q2;
    logic [CODE_WIDTH-1:0]      oedc_code;
    logic                       edc_failed;
    logic                       rmw_edcfail;
    logic                       rmw_parity_err;
    logic [(DATA_WIDTH/32)-1:0] err_uncorr;
    logic  [$clog2((DATA_WIDTH/32)+1)-1:0] err_corr_total;
    logic [(DATA_WIDTH/32)-1:0] err_corr;
    logic [DATA_WIDTH-1:0]      err_rdata;

    logic [CODE_WIDTH-1:0]      unscrambled_ram_di;
    logic [CODE_WIDTH-1:0]      unscrambled_ram_qi;

    // write-back
    logic [ADDR_WIDTH-1:0]      wb_addr;
    logic [DATA_WIDTH-1:0]      wb_wdata;
    logic                       wb_en;
    logic                       wb_init;
    logic                       wb_busy;
    logic                       wb_block;

    // parity
    logic   [((DATA_WIDTH+31)/32)-1:0]          wdata_parity_chk;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          addr_parity_chk;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          addr_q2_parity_chk;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          rd_addr_q2_err_parity;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          addr_chk_q;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          addr_chk_q2;
    logic                                       en_q;
    logic                                       en_q2;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          wb_waddr_chk;
    logic   [(DATA_WIDTH/32)-1:0]               wb_wdata_chk;
    logic   [(DATA_WIDTH/32)-1:0]               wb_wdata_parity_chk;
    logic                                       wb_addr_parity_chk;
    logic   [((ADDR_WIDTH+31)/32)-1:0]          wb_parity_chk;
    logic                                       rmw_addr_q2_parity_chk;

    
    //-------------------------------------------
    // memory erase logic
    //-------------------------------------------
    generate if (SUPPORT_ERASE == 1)
    begin : gen_SUPPORT_ERASE
    mem_erase #(.ADDR_WIDTH(ERASE_ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .ERASE_NBYTES(ERASE_NBYTES),
                .ERASE_END_ADDR(ERASE_END_ADDR),
                .ENGN_ERASE_END_ADDR(ENGN_ERASE_END_ADDR),
                .SUPPORT_ENGN_ERASE(SUPPORT_ENGN_ERASE),
                .SUPPORT_ERASE(SUPPORT_ERASE),
                .ERASE_START_ADDR(ERASE_START_ADDR),
                .ENGN_ERASE_START_ADDR(ENGN_ERASE_START_ADDR)
                )
    u_mem_erase
        (// Outputs
         .erase_addr(erase_addr),
         .erase_we(erase_we),
         .erase_done(erase_done_o),
         .engn_erase_done(engn_erase_done_o),
         // Inputs
         .clk(clk_i),
         .reset_na(reset_na_i),
         .erase_start(erase_start_i),
         .engn_erase_start(engn_erase_start_i)
         );

    // if erase is in progress, assert error if any other transactions takes
    assign erase_busy_o = erase_we;
    assign err_erase_busy_o = (erase_we) ? (rmw_busy | en_i | wb_busy) : 1'b0;

    assign qualified_en = (erase_we | w_err_parity_o | rmw_busy | wb_busy) ? 1'b0 : en_i;

    end
    else
    begin : gen_NO_ERASE
        assign erase_addr = {ERASE_ADDR_WIDTH{1'b0}};
        assign erase_we = 1'b0;
        assign erase_done_o = 1'b0;
        assign engn_erase_done_o = 1'b0;

        assign erase_busy_o = 1'b0;
        assign err_erase_busy_o = 1'b0;

        assign qualified_en = en_i & (~rmw_busy) & (~wb_busy);
    end
    endgenerate

    //-------------------------------------------
    // read modify write logic
    //-------------------------------------------

    generate if (SUPPORT_RMW == 1)
    begin : gen_SUPPORT_RMW
        mem_rmw #(.DATA_WIDTH(DATA_WIDTH),
                  .ADDR_WIDTH(ADDR_WIDTH),
                  .RMW_PIPELINE(RMW_PIPELINE),
                  .PARITY_EN(PARITY_EN)
                  )
        mem_rmw (
            .non_rmw_en(non_rmw_en),
            .rmw_en(rmw_en),
            .rmw_we(rmw_we),
            .rmw_wdata(rmw_wdata),
            .rmw_addr(rmw_addr),
            .rmw_busy(rmw_busy),
            .clk(clk_i),
            .reset_na(reset_na_i),
            .en(qualified_en),
            .we(we_i),
            .wdata(wdata_i),
            .addr(addr_i),
            .rdata(oedc_data),
            .rmw_error(rmw_edcfail),
            .rmw_parity_err(rmw_parity_err),
            .err_parity_chk_disable_i(err_parity_chk_disable_i),
            .addr_chk(addrchk_i),
            .wdata_chk(wdatachk_i)
        );

    end else begin : gen_NO_RMW
        // just a pass-through reassignment if no rmw support is needed
        assign non_rmw_en     = qualified_en;
        assign rmw_addr       = addr_i;
        assign rmw_busy       = 1'b0;
        assign rmw_en         = 1'b0;
        assign rmw_we         = |we_i;
        assign rmw_wdata      = wdata_i;
        assign rmw_parity_err = 1'b0;
    end
    endgenerate

    // ram_wrapper is busy if rmw_busy or wb_busy
    assign busy_o = (rmw_busy & (~erase_we)) | wb_busy;

    //-------------------------------------------
    // EDC/ECC Generator at the input logic to the RAM
    //-------------------------------------------
    // recalculate low address bits, take erase addr caluculate by mem_erase subblock, add an offset based on
    // forced word address driven at the time of instantiation

    assign iedc_addr = erase_we ? erase_addr[ERASE_ADDR_WIDTH-1:(ERASE_ADDR_WIDTH-ADDR_WIDTH)] :
                            (
                                (wb_en & (~wb_parity_chk)) ? wb_addr : ((non_rmw_en | rmw_en) ? rmw_addr : {ADDR_WIDTH{1'h0}})
                            );

    assign iedc_data = erase_we ? erase_wdata_i[DATA_WIDTH-1:0] :
                            (
                                (wb_en & (~wb_parity_chk)) ? wb_wdata : ((non_rmw_en | rmw_en) ? rmw_wdata : {DATA_WIDTH{1'h0}})
                            );

    genvar i;
    generate
    for (i = 0; i < (DATA_WIDTH/32); i = i + 1) begin : encoding

        logic [NUM_LSBS-1:0] iedc_addr_lsbs;
        assign iedc_addr_lsbs = NUM_LSBS'(unsigned'(i) << 2); // Word address for this set of 32 bits

        if(SUPPORT_SECDED == 1) begin: secded_scheme_gen

        localparam ENC_ADDR_WIDTH = ((ADDR_WIDTH+NUM_LSBS) > 24) ? 24 : ADDR_WIDTH+NUM_LSBS;

            secded_enc #(.ADDR_WIDTH(ENC_ADDR_WIDTH))
            secded_enc (
                // Outputs
                .code_out   (iedc_code[(38+(i*39)):(i*39)]),
                // Inputs
                .data_in    (iedc_data[(31+(i*32)):(i*32)]),
                .addr   ({iedc_addr,iedc_addr_lsbs})
            );

        end: secded_scheme_gen
        else begin: ded_scheme_gen

        localparam ENC_ADDR_WIDTH = ((ADDR_WIDTH+NUM_LSBS) > 23) ? 23 : ADDR_WIDTH+NUM_LSBS;

            edc_gen #(.ADDR_WIDTH(ENC_ADDR_WIDTH),
                    .EDC_GEN(1))
            iedc_gen (
                // Outputs
                .code_out  (iedc_code[(37+(i*38)):(i*38)]),
                .check (),
                .err_uncorr(),
                .data_out(),
                // Inputs
                .data_in  (iedc_data[(31+(i*32)):(i*32)]),
                .addr  ({iedc_addr,iedc_addr_lsbs}),
                .code_in    (38'h0),
                .err_chk_disable    (1'b0)
            );
        end: ded_scheme_gen
    end: encoding
    endgenerate


    //-------------------------------------------
    // Error Inejct logic
    //-------------------------------------------
    // signal inject done as soon as inject is able to squeeze in a write

    assign inject_done_o = support_inject_vld & inject_in_progress & ~(erase_we | rmw_en | non_rmw_en | wb_en);
    assign inject_busy_o = support_inject_vld & inject_in_progress;

    generate if (SUPPORT_INJECT == 1)
    begin : gen_SUPPORT_INJECT
        logic  inject_q;

        assign support_inject_vld = 1'h1;

        always_ff @(posedge clk_i or negedge reset_na_i) begin
            if (~reset_na_i) begin
                inject_in_progress <= 1'b0;
                inject_q <= 1'b0;
            end
            else
            begin
                inject_q <= inject_i;

                if ((~inject_in_progress) && inject_i && (~inject_q))
                begin
                    // rising edge of 'inject' starts inject_in_progress
                    inject_in_progress <= 1'b1;
                end
                else if (inject_in_progress && inject_done_o)
                begin
                    inject_in_progress <= 1'b0;
                end
            end
        end
    end
    else // generate if not (SUPPORT_INJECT)
    begin : gen_NO_INJECT
        assign support_inject_vld = 1'h0;
        assign inject_in_progress = 1'b0;
    end
    endgenerate


    //-------------------------------------------
    // I/O to the memory array
    //-------------------------------------------
    always_comb begin
        if (erase_we | rmw_en | non_rmw_en | (wb_en & (~wb_parity_chk)))
        begin
            ram_adr_o = iedc_addr;
            unscrambled_ram_di  = iedc_code;
            ram_me_o  = 1'b1;
            ram_we_o  = erase_we | (rmw_we & (~w_err_parity_o)) | wb_en;
        end
        else if (support_inject_vld & inject_in_progress)
        begin
            ram_adr_o = inject_addr_i;
            unscrambled_ram_di  = inject_mask_i;
            ram_me_o  = 1'b1;
            ram_we_o  = 1'b1;
        end
        else
        begin
            ram_adr_o = iedc_addr;
            unscrambled_ram_di  = iedc_code;
            ram_me_o  = 1'b0;
            ram_we_o  = 1'b0;
        end
    end

    generate
        genvar si;
        for(si = 0; si < CODE_WIDTH; si = si + 1) begin: scrambling_block
                assign ram_di_o[si+SHUFFLING[si]] = unscrambled_ram_di[si] ^ INVERSION[si];         // Scrambling engine write data
                assign unscrambled_ram_qi[si] = ram_qi_i[si+SHUFFLING[si]] ^ INVERSION[si];        // Unscrambling read data
        end: scrambling_block
    endgenerate

    // If memory have a flop at the output, we'd just take it as is.
    // Otherwise, we'd need to add a flop before using it
    //assign oedc_code = unscrambled_ram_qi;

    always_ff @(posedge clk_i or negedge reset_na_i)
    begin
        if (~reset_na_i) begin
            oedc_code             <= {CODE_WIDTH{1'b0}};
            addr_q                <= {ADDR_WIDTH{1'b0}};
            addr_q2               <= {ADDR_WIDTH{1'b0}};
            non_rmw_rd_q          <= 1'b0;
            non_rmw_wr_q          <= 1'b0;
            non_rmw_rd_vld        <= 1'b0;
            rmw_rd_q              <= 1'b0;
            rmw_rd_vld            <= 1'b0;
            addr_chk_q            <= 1'b0;
            addr_chk_q2           <= 1'b0;
            en_q                  <= 1'b0;
            en_q2                 <= 1'b0;
        end
        else begin
            addr_q                <= ram_adr_o[ADDR_WIDTH-1:0];
            addr_q2               <= addr_q[ADDR_WIDTH-1:0];
            en_q                  <= en_i;
            en_q2                 <= en_q;

            // Assert read valid after two cycles of sending the read to memory
            non_rmw_rd_q          <= non_rmw_en & ~rmw_we;
            non_rmw_rd_vld        <= non_rmw_rd_q;
            non_rmw_wr_q          <= non_rmw_en & rmw_we;
            rmw_rd_q              <= rmw_en & ~rmw_we;
            rmw_rd_vld            <= rmw_rd_q;

            oedc_code             <= unscrambled_ram_qi;

            addr_chk_q            <= addrchk_i;
            addr_chk_q2           <= addr_chk_q;
        end
    end


    //-------------------------------------------
    // Error Detection Code Generator at the output logic of the RAM
    //-------------------------------------------

    // compare oedc check bits with the bits we got from the RAM, if they are the same, then
    // no error and return data if it's a read if they are different, then raise error flag,
    // and return no data.


    generate
        genvar j;
        for (j = 0; j < (DATA_WIDTH/32); j = j + 1) begin : assign_oedc_expected_check_bits_for

            logic [NUM_LSBS-1:0] oedc_addr_lsbs;
            assign oedc_addr_lsbs = NUM_LSBS'(unsigned'(j) << 2); // Word address for this set of 32 bits

            if(SUPPORT_SECDED == 1) begin: secded_scheme_check

            localparam DEC_ADDR_WIDTH = ((ADDR_WIDTH+NUM_LSBS) > 24) ? 24 : ADDR_WIDTH+NUM_LSBS;

                secded_dec #(.ADDR_WIDTH(DEC_ADDR_WIDTH))
                secded_dec (
                    // Outputs
                    .data_out   (oedc_data[(31+(j*32)):(j*32)]),
                    .err_corr   (err_corr[j]),
                    .err_uncorr (err_uncorr[j]),
                    // Inputs
                    .code_in    (oedc_code[(38+(j*39)):(j*39)]),
                    .addr   ({addr_q2,oedc_addr_lsbs}),
                    .err_chk_disable    (err_chk_disable_i)
                );

                // assign err_corr_total = err_corr_total + err_corr[j];

            end // secded_scheme_check
            else begin: ded_scheme_check
            // EDC generator at the output

            localparam DEC_ADDR_WIDTH = ((ADDR_WIDTH+NUM_LSBS) > 23) ? 23 : ADDR_WIDTH+NUM_LSBS;
                edc_gen   #(.ADDR_WIDTH(DEC_ADDR_WIDTH),
                            .EDC_GEN(0))
                oedc_gen
                    (// Outputs
                    .code_out  (),
                    .check (),
                    .err_uncorr (err_uncorr[j]),
                    .data_out(oedc_data[(31+(j*32)):(j*32)]),
                    // Inputs
                    .data_in  (32'h0),
                    .addr  ({addr_q2,oedc_addr_lsbs}),
                    .code_in (oedc_code[(37+(j*38)):(j*38)]),
                    .err_chk_disable (err_chk_disable_i));

                // assign err_corr_total = 'b0;
                assign err_corr[j] = 1'b0;
            end // ded_scheme_check
        end
    endgenerate

    always_comb begin
        if(SUPPORT_SECDED == 1) begin
            err_corr_total = 'h0;
            for(integer k = 0; k < (DATA_WIDTH/32); k=k+1) begin
                err_corr_total = err_corr_total + err_corr[k];
            end
        end
        else begin
            err_corr_total = 'h0;
        end
    end

    assign edc_failed = (non_rmw_rd_vld | rmw_rd_vld) & (|(err_uncorr));
    assign err_uncorr_o = edc_failed;
    assign err_corr_o = {ERR_CORR_WIDTH{(non_rmw_rd_vld | rmw_rd_vld)}} & err_corr_total;

    assign err_addr_o = (err_uncorr_o | (|err_corr_o)) ? addr_q2 : {ADDR_WIDTH{1'b0}};

    generate
        genvar i_err;
        for (i_err = 0; i_err < (DATA_WIDTH/32); i_err = i_err + 1) begin
            assign err_rdata[((i_err*32)+31)-:32] = C_ERRDATA;
        end
    endgenerate

    assign rdata_o          = (err_uncorr_o | r_err_parity_o) ? err_rdata : oedc_data;
    assign rdata_valid_o    = non_rmw_rd_vld & (~edc_failed) & (~r_err_parity_o);         // Assert the read valid for non-RMW transaction only
    assign rmw_edcfail      = edc_failed & rmw_busy;

    generate
        if(SUPPORT_WRITE_BACK) begin: gen_wb

            assign wb_block = non_rmw_wr_q & (addr_q == addr_q2); 
            assign wb_init = rdata_valid_o & (|err_corr_o) & (~r_err_parity_o) & (~wb_block) & (~erase_we);     // initiate write-back

            if(RMW_PIPELINE) begin: gen_wb_pipeline
                always_ff @(posedge clk_i or negedge reset_na_i) begin
                    if (~reset_na_i) begin
                        wb_en          <= 1'h0;
                        wb_wdata       <= {DATA_WIDTH{1'h0}};
                        wb_addr        <= {ADDR_WIDTH{1'h0}};
                        wb_waddr_chk   <= 'h0;
                        wb_wdata_chk   <= 'h0;
                    end
                    else begin
                        if(wb_init & (~erase_start_i) & (~engn_erase_start_i)) begin
                            wb_en        <= 1'h1;
                            wb_wdata     <= rdata_o;
                            wb_addr      <= addr_q2;
                            wb_waddr_chk <= addr_chk_q2;
                            wb_wdata_chk <= rdatachk_o;
                        end
                        else begin
                            wb_en        <= 1'h0;
                            wb_wdata     <= {DATA_WIDTH{1'h0}};
                            wb_addr      <= {ADDR_WIDTH{1'h0}};
                            wb_waddr_chk <= 'h0;
                            wb_wdata_chk <= 'h0;
                        end
                    end
                end

                assign wb_busy = wb_init | wb_en;                // set busy during write-back

            end
            else begin: gen_wb_non_pipeline
                assign wb_en        = wb_init;
                assign wb_wdata     = rdata_o;
                assign wb_addr      = addr_q2;
                assign wb_busy      = wb_init;
                assign wb_waddr_chk = addr_chk_q2;
                assign wb_wdata_chk = rdatachk_o;
            end

        end
        else begin: gen_no_wb
            assign wb_init      = 1'h0;
            assign wb_en        = 1'h0;
            assign wb_wdata     = {DATA_WIDTH{1'h0}};
            assign wb_addr      = {ADDR_WIDTH{1'h0}};
            assign wb_busy      = 1'h0;
            assign wb_waddr_chk = 'h0;
            assign wb_wdata_chk = 'h0;
        end
    endgenerate

    /* Parity Error logic */
    generate if (PARITY_EN == 1)
    begin : gen_PARITY
        // Parity checking and generation for address and data
        always_comb begin
            for (integer pi = 0; pi < (DATA_WIDTH/32); pi = pi + 1) begin
                // Generate parity for every 32 bits of valid read data
                rdatachk_o[pi] = (~^rdata_o[pi*32 +: 32]);

                // Check parity for every 32 bits of write data
                wdata_parity_chk[pi] = (err_parity_chk_disable_i | (~en_i) | (~(|we_i[(DATA_WIDTH/8)-1:0]))) ? 1'b0 : (wdatachk_i[pi] != ~^wdata_i[pi*32 +: 32]);

                if (RMW_PIPELINE) begin : gen_wb_wdata_parity_err
                    wb_wdata_parity_chk[pi] = (err_parity_chk_disable_i | (~wb_en)) ? 1'b0 : (wb_wdata_chk[pi] != ~^wb_wdata[pi*32 +: 32]);

                end
                else begin : gen_no_wb_wdata_parity_err
                    wb_wdata_parity_chk[pi] = 'h0;
                end
            end
        end

        // Parity check for input address and address q2 flop
        assign addr_parity_chk = (err_parity_chk_disable_i | (~en_i)) ? 1'b0 : (addrchk_i != ~^addr_i[ADDR_WIDTH-1:0]);
        assign addr_q2_parity_chk = (err_parity_chk_disable_i | (~en_q2)) ? 1'b0 : (addr_chk_q2 != ~^addr_q2[ADDR_WIDTH-1:0]);
        assign rd_addr_q2_err_parity = (|addr_q2_parity_chk) & non_rmw_rd_vld ;
        

        // Parity check for write back data and address, only required when
        // RMW_PIPELINE is set
        if (RMW_PIPELINE) begin : gen_wb_parity_err
            assign wb_addr_parity_chk = (err_parity_chk_disable_i | (~wb_en)) ? 1'b0 : (wb_waddr_chk != ~^wb_addr[ADDR_WIDTH-1:0]);
            assign wb_parity_chk = (|wb_addr_parity_chk) | (|wb_wdata_parity_chk);
            always_ff @(posedge clk_i or negedge reset_na_i) begin
                if (~reset_na_i) begin
                    rmw_addr_q2_parity_chk <= '0;
                end
                else begin
                    rmw_addr_q2_parity_chk <= (|addr_q2_parity_chk) && rmw_rd_vld;
                end
            end
        end
        else begin: gen_no_wb_parity_error
            assign wb_addr_parity_chk = '0;
            assign wb_parity_chk = '0;
            assign rmw_addr_q2_parity_chk = (|addr_q2_parity_chk) && rmw_rd_vld;
        end

        // Read and write parity error output pulse
        //assign w_err_parity_o = (((|wdata_parity_chk) | (|addr_parity_chk) | (|we_parity_chk)) & (we_i == 4'hf)) || (rmw_parity_err | rmw_addr_q2_parity_chk);
        assign w_err_parity_o = (((|wdata_parity_chk) | (|addr_parity_chk)) & (we_i == {NUM_BYTES{1'b1}})) || (rmw_parity_err | rmw_addr_q2_parity_chk);
        //assign r_err_parity_o =  rd_addr_q2_err_parity | we_parity_chk_q2;
        assign r_err_parity_o =  rd_addr_q2_err_parity;

    end
    else begin : gen_no_PARITY
        assign rdatachk_o = '0;
        assign wb_parity_chk = '0;
        assign r_err_parity_o = '0;
        assign w_err_parity_o = '0;
    end
    endgenerate

endmodule // ram_wrapper
