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
// File          : axi_mgr.v
// Description   : convert AXI manager interface to a engine interface


`include "hsp_axi.vh"

module axi_mgr #(
                 parameter ENGN_PARITY_EN = 1, // Enables AXI manager to generate and check parity on the engine interface signals
                 parameter AXI_PARITY_EN = `MSFT_AXI_PARITY_EN, // Enables AXI manager to generate and check parity on the AXI interface signals
                 parameter DFD = 1, // Data FIFO depth
                 parameter BLEN = 16, // Maximum burst length (must be power of 2 and <=16)
                 parameter ANUM = 0, // Number of outstanding address read/writes allowed. If zero, only issues AR/AW commands when space/data available in FIFO (respectively)
                 parameter DW = `HSP_AXI_MST_DWIDTH, // AXI data width
                 parameter IDW = `HSP_AXI_MST_ID_WIDTH, // AXI ID width
                 parameter ENGNUW = `MSFT_AXI_MST_ENGNU_WIDTH, // AXI Engine AxUSER width - used for AxUSER bits from engine (not including parity)
                 parameter ARUW = `MSFT_AXI_MST_ARU_WIDTH, // AXI ARUSER width
                 parameter AWUW = `MSFT_AXI_MST_AWU_WIDTH, // AXI AWUSER width
                 parameter WUW = `MSFT_AXI_MST_WU_WIDTH, // AXI WUSER width
                 parameter RUW = `MSFT_AXI_MST_RU_WIDTH, // AXI RUSER width
                 parameter BUW = `MSFT_AXI_MST_BU_WIDTH, // AXI BUSER width
                 parameter LW = `HSP_AXI_LOCK_BITS // AXI A*LOCK width
                 )(
                   /*AUTOARG*/
   // Outputs
   awid_o, awuser_o, awaddr_o, awlen_o, awsize_o, awburst_o,
   awcache_o, awprot_o, awqos_o, awregion_o, awvalid_o, wdata_o,
   wstrb_o, wlast_o, wuser_o, wvalid_o, bready_o, arid_o, aruser_o, araddr_o,
   arlen_o, arsize_o, arburst_o, arlock_o, awlock_o, arcache_o,
   arprot_o, arqos_o, arregion_o, arvalid_o, rready_o,
   engn_craccept_o, engn_crvalid_o, engn_crresp_o, engn_cwaccept_o,
   engn_cwvalid_o, engn_cwresp_o, engn_rdata_o, engn_rvalid_o,
   engn_waccept_o, engn_rdatachk_o, err_parity_o, err_r_addr_o, err_w_addr_o, err_chk_o,
   err_r_parity_o, err_w_parity_o,
   // Inputs
   clk_i, reset_nai, awready_i, wready_i, bid_i, bresp_i, buser_i, bvalid_i,
   arready_i, rid_i, rdata_i, rresp_i, rlast_i, ruser_i, rvalid_i,
   engn_cread_i, engn_cwrite_i, engn_crstop_i, engn_craddr_i,
   engn_crlen_i, engn_crid_i, engn_cruser_i, engn_crprot_i,
   engn_cwstop_i, engn_cwaddr_i, engn_cwlen_i, engn_cwid_i,
   engn_cwuser_i, engn_cwprot_i, engn_raccept_i, engn_wdata_i,
   engn_wvalid_i, engn_aridchk_i, engn_araddrchk_i, engn_arlenchk_i,
   engn_arprotchk_i, engn_aruserchk_i, engn_awidchk_i, engn_awaddrchk_i,
   engn_awlenchk_i, engn_awuserchk_i, engn_awprotchk_i, engn_wdatachk_i,
   clkg_test_mode_i, clkg_override_i, err_parity_chk_disable_i
   );

    localparam STRBW        = DW/8;
    localparam STRBW_W      = $clog2(STRBW);
    localparam BLEN_W       = $clog2(BLEN);
    localparam AWORDS       = (ANUM > 0) ? ANUM*BLEN :
                              (DFD < BLEN) ? BLEN :
                                           DFD;
    localparam AWORDSP1_W   = $clog2(AWORDS+1);
    localparam DW_RESET     = (|ANUM)       ? AWORDS :
                              (DFD < BLEN)    ? BLEN :
                                              {AWORDSP1_W{1'b0}};

 // Parity check error parameters
    // The error check signal indicates which parity check signal(s) failed, indexed as follows:
    localparam PIDW                     = (IDW + 7)/8;
    localparam PDW                      = (DW + 7)/8;
    localparam PSTRBW                   = (DW + 63)/64;
    localparam PENGNUW                  = (ENGNUW + 7)/8;

    localparam ERR_CHK_AWIDCHK_LSB      = 0;
    localparam ERR_CHK_AWIDCHK_MSB      = ((ERR_CHK_AWIDCHK_LSB + PIDW) - 1);
    localparam ERR_CHK_AWADDRCHK_LSB    = ERR_CHK_AWIDCHK_MSB + 1;
    localparam ERR_CHK_AWADDRCHK_MSB    = ((ERR_CHK_AWADDRCHK_LSB + 4) - 1);
    localparam ERR_CHK_AWLENCHK         = ERR_CHK_AWADDRCHK_MSB + 1;
    localparam ERR_CHK_AWCTLCHK0        = ERR_CHK_AWLENCHK + 1;
    localparam ERR_CHK_AWUSERCHK_LSB    = ERR_CHK_AWCTLCHK0 + 1;
    localparam ERR_CHK_AWUSERCHK_MSB    = ((ERR_CHK_AWUSERCHK_LSB + PENGNUW) - 1);

    localparam ERR_CHK_WDATACHK_LSB     = ERR_CHK_AWUSERCHK_MSB + 1;
    localparam ERR_CHK_WDATACHK_MSB     = ((ERR_CHK_WDATACHK_LSB + PDW) - 1);
    localparam ERR_CHK_WSTRBCHK_LSB     = ERR_CHK_WDATACHK_MSB + 1;
    localparam ERR_CHK_WSTRBCHK_MSB     = ((ERR_CHK_WSTRBCHK_LSB + PSTRBW) - 1);
    localparam ERR_CHK_WLASTCHK         = ERR_CHK_WSTRBCHK_MSB + 1;

    localparam ERR_CHK_BIDCHK_LSB       = ERR_CHK_WLASTCHK + 1;
    localparam ERR_CHK_BIDCHK_MSB       = ((ERR_CHK_BIDCHK_LSB + PIDW) - 1);
    localparam ERR_CHK_BRESPCHK         = ERR_CHK_BIDCHK_MSB + 1;

    localparam ERR_CHK_ARIDCHK_LSB      = ERR_CHK_BRESPCHK + 1;
    localparam ERR_CHK_ARIDCHK_MSB      = ((ERR_CHK_ARIDCHK_LSB + PIDW) - 1);
    localparam ERR_CHK_ARADDRCHK_LSB    = ERR_CHK_ARIDCHK_MSB + 1;
    localparam ERR_CHK_ARADDRCHK_MSB    = ((ERR_CHK_ARADDRCHK_LSB + 4) - 1);
    localparam ERR_CHK_ARLENCHK         = ERR_CHK_ARADDRCHK_MSB + 1;
    localparam ERR_CHK_ARCTLCHK0        = ERR_CHK_ARLENCHK + 1;
    localparam ERR_CHK_ARUSERCHK_LSB    = ERR_CHK_ARCTLCHK0 + 1;
    localparam ERR_CHK_ARUSERCHK_MSB    = ((ERR_CHK_ARUSERCHK_LSB + PENGNUW) - 1);

    localparam ERR_CHK_RIDCHK_LSB       = ERR_CHK_ARUSERCHK_MSB + 1;
    localparam ERR_CHK_RIDCHK_MSB       = ((ERR_CHK_RIDCHK_LSB + PIDW) - 1);
    localparam ERR_CHK_RDATACHK_LSB     = ERR_CHK_RIDCHK_MSB + 1;
    localparam ERR_CHK_RDATACHK_MSB     = ((ERR_CHK_RDATACHK_LSB + PDW) - 1);
    localparam ERR_CHK_RRESPCHK         = ERR_CHK_RDATACHK_MSB + 1;
    localparam ERR_CHK_RLASTCHK         = ERR_CHK_RRESPCHK + 1;

    // xUSER parity check parameters
    // The xUSER signals hold parity check information for all of the AXI signals, indexed as follows:
    // AWUSER
    localparam AWUSER_AWIDCHK_LSB      = ENGNUW;
    localparam AWUSER_AWIDCHK_MSB      = ((AWUSER_AWIDCHK_LSB + PIDW) - 1);
    localparam AWUSER_AWADDRCHK_LSB    = AWUSER_AWIDCHK_MSB + 1;
    localparam AWUSER_AWADDRCHK_MSB    = ((AWUSER_AWADDRCHK_LSB + 4) - 1);
    localparam AWUSER_AWLENCHK         = AWUSER_AWADDRCHK_MSB + 1;
    localparam AWUSER_AWCTLCHK0        = AWUSER_AWLENCHK + 1;
    localparam AWUSER_AWUSERCHK_LSB    = AWUSER_AWCTLCHK0 + 1;
    localparam AWUSER_AWUSERCHK_MSB    = ((AWUSER_AWUSERCHK_LSB + PENGNUW) - 1);
    // WUSER
    localparam WUSER_WDATACHK_LSB      = 0;
    localparam WUSER_WDATACHK_MSB      = ((WUSER_WDATACHK_LSB + (DW/8)) - 1);
    localparam WUSER_WSTRBCHK_LSB      = WUSER_WDATACHK_MSB + 1;
    localparam WUSER_WSTRBCHK_MSB      = ((WUSER_WSTRBCHK_LSB + PSTRBW) - 1);
    localparam WUSER_WLASTCHK          = WUSER_WSTRBCHK_MSB + 1;
    // BUSER
    localparam BUSER_BIDCHK_LSB        = 0;
    localparam BUSER_BIDCHK_MSB        = ((BUSER_BIDCHK_LSB + PIDW) - 1);
    localparam BUSER_BRESPCHK          = BUSER_BIDCHK_MSB + 1;
    // ARUSER
    localparam ARUSER_ARIDCHK_LSB      = ENGNUW;
    localparam ARUSER_ARIDCHK_MSB      = ((ARUSER_ARIDCHK_LSB + PIDW) - 1);
    localparam ARUSER_ARADDRCHK_LSB    = ARUSER_ARIDCHK_MSB + 1;
    localparam ARUSER_ARADDRCHK_MSB    = ((ARUSER_ARADDRCHK_LSB + 4) - 1);
    localparam ARUSER_ARLENCHK         = ARUSER_ARADDRCHK_MSB + 1;
    localparam ARUSER_ARCTLCHK0        = ARUSER_ARLENCHK + 1;
    localparam ARUSER_ARUSERCHK_LSB    = ARUSER_ARCTLCHK0 + 1;
    localparam ARUSER_ARUSERCHK_MSB    = ((ARUSER_ARUSERCHK_LSB + PENGNUW) - 1);
    // RUSER
    localparam RUSER_RIDCHK_LSB        = 0;
    localparam RUSER_RIDCHK_MSB        = ((RUSER_RIDCHK_LSB + PIDW) - 1);
    localparam RUSER_RDATACHK_LSB      = RUSER_RIDCHK_MSB + 1;
    localparam RUSER_RDATACHK_MSB      = ((RUSER_RDATACHK_LSB + (DW/8)) - 1);
    localparam RUSER_RRESPCHK          = RUSER_RDATACHK_MSB + 1;
    localparam RUSER_RLASTCHK          = RUSER_RRESPCHK + 1;

    /*
     * Read and write data FIFO
     */

    localparam DFD_W    = (DFD == 1) ? $clog2(DFD+1) : $clog2(DFD); // Width of signals necessary to address into data FIFOs - if DFD=1, still want DFD_W to be 1 not 0
    localparam DFDP1_W  = $clog2(DFD+1); // Width of signals necessary to count free space in data FIFOs
    localparam PCHKW        = (AXI_PARITY_EN | ENGN_PARITY_EN) ? ((ARUW - ENGNUW) + (AWUW - ENGNUW) + WUW + RUW + BUW): (ERR_CHK_BRESPCHK - ERR_CHK_AWIDCHK_LSB);

    input                               clk_i;
    input                               reset_nai;
    // signals from and to axi interface
    output [IDW-1:0]                    awid_o;
    output [AWUW-1:0]                   awuser_o;
    output [31:0]                       awaddr_o;
    output [7:0]                        awlen_o;
    output [2:0]                        awsize_o;
    output [1:0]                        awburst_o;

    output [3:0]                        awcache_o;
    output [2:0]                        awprot_o;
    output [3:0]                        awqos_o;
    output [3:0]                        awregion_o;
    output                              awvalid_o;
    input                               awready_i;
    output [DW-1:0]                     wdata_o;
    output [(DW/8)-1:0]                 wstrb_o;
    output                              wlast_o;
    output [WUW-1:0]                    wuser_o;
    output                              wvalid_o;
    input                               wready_i;

    input [IDW-1:0]                     bid_i;
    input [1:0]                         bresp_i;
    input [BUW-1:0]                     buser_i;
    input                               bvalid_i;
    output                              bready_o;

    output [IDW-1:0]                    arid_o;
    output [ARUW-1:0]                   aruser_o;
    output [31:0]                       araddr_o;
    output [7:0]                        arlen_o;
    output [2:0]                        arsize_o;
    output [1:0]                        arburst_o;

    output [LW-1:0]                     arlock_o;
    output [LW-1:0]                     awlock_o;
    output [3:0]                        arcache_o;
    output [2:0]                        arprot_o;
    output [3:0]                        arqos_o;
    output [3:0]                        arregion_o;
    output                              arvalid_o;
    input                               arready_i;

    input [IDW-1:0]                     rid_i;
    input [DW-1:0]                      rdata_i;
    input [1:0]                         rresp_i;
    input                               rlast_i;
    input [RUW-1:0]                     ruser_i;
    input                               rvalid_i;
    output                              rready_o;
    // signals from and to crypto engine
    input                               engn_cread_i;
    input                               engn_cwrite_i;
    input                               engn_crstop_i;
    output                              engn_craccept_o;
    input [31:0]                        engn_craddr_i;
    input [31:0]                        engn_crlen_i;
    input [IDW-1:0]                     engn_crid_i;
    input [ENGNUW-1:0]                  engn_cruser_i;
    input [2:0]                         engn_crprot_i;
    output                              engn_crvalid_o;
    output [3:0]                        engn_crresp_o;
    input                               engn_cwstop_i;
    output                              engn_cwaccept_o;
    input [31:0]                        engn_cwaddr_i;
    input [31:0]                        engn_cwlen_i;
    input [IDW-1:0]                     engn_cwid_i;
    input [ENGNUW-1:0]                  engn_cwuser_i;
    input [2:0]                         engn_cwprot_i;
    output                              engn_cwvalid_o;
    output [3:0]                        engn_cwresp_o;

    output [DW-1:0]                     engn_rdata_o;
    output                              engn_rvalid_o;
    input                               engn_raccept_i;

    input [DW-1:0]                      engn_wdata_i;
    input                               engn_wvalid_i;
    output                              engn_waccept_o;

    input                               engn_aridchk_i;
    input                               engn_araddrchk_i;
    input                               engn_arlenchk_i;
    input                               engn_arprotchk_i;
    input                               engn_aruserchk_i;
    input                               engn_awidchk_i;
    input                               engn_awaddrchk_i;
    input                               engn_awlenchk_i;
    input                               engn_awprotchk_i;
    input                               engn_awuserchk_i;
    output [(DW/32)-1:0]                engn_rdatachk_o;
    input [(DW/32)-1:0]                 engn_wdatachk_i;

    // signals from and to control registers
    output                              err_parity_o;
    output                              err_r_parity_o;
    output                              err_w_parity_o;
    output [31:0]                       err_r_addr_o;
    output [31:0]                       err_w_addr_o;
    output [PCHKW-1:0]                  err_chk_o;

    // pervasive
    input                               clkg_test_mode_i;
    input                               clkg_override_i;
    input                               err_parity_chk_disable_i;

    /*
     * Gated Clock for data domain
     */

    wire    cg_read_en_din;
    reg     cg_read_en_q;
    wire    cg_write_en_din;
    reg     cg_write_en_q;

    wire    clk_gated_r;
    wire    clk_gated_w;

    // Clock gating enables defined at end because they rely on signals defined
    // throughout code

    always @(posedge clk_i or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            cg_read_en_q <= 1'h0;
            cg_write_en_q <= 1'h0;
            // End of automatics
        end
        else begin
            cg_read_en_q    <= cg_read_en_din;
            cg_write_en_q   <= cg_write_en_din;
        end
    end

    c_clock_gate_ovr clock_gate_read (
                                      .clk        (clk_i),
                                      .enable     (cg_read_en_din),
                                      .ovr_en     (clkg_override_i),
                                      .rst_en     (1'b0),
                                      .test_mode  (clkg_test_mode_i),
                                      .gated_clk  (clk_gated_r)
                                      );

    c_clock_gate_ovr clock_gate_write (
                                       .clk        (clk_i),
                                       .enable     (cg_write_en_din),
                                       .ovr_en     (clkg_override_i),
                                       .rst_en     (1'b0),
                                       .test_mode  (clkg_test_mode_i),
                                       .gated_clk  (clk_gated_w)
                                       );

   
    // Read/write control FIFOs
    reg [DW-1:0]    dr_fifo_din [0:DFD-1];
    reg [DW-1:0]    dr_fifo_q   [0:DFD-1];
    reg [DW-1:0]    dw_fifo_din [0:DFD-1];
    reg [DW-1:0]    dw_fifo_q   [0:DFD-1];

    // FIFO start and end pointers, plus counters to track how many slots are
    // unallocated, as well as filled
    // During read, engine data controls start pointer, AXI data controls end
    // pointer. During write, engine data controls end pointer, AXI data controls
    // start pointer
    // "entries" tracks unallocated space in FIFO based on engine control signals
    wire [DFD_W-1:0]        dr_start_din;
    reg  [DFD_W-1:0]        dr_start_q;
    wire [DFD_W-1:0]        dr_end_din;
    reg  [DFD_W-1:0]        dr_end_q;
    wire [DFDP1_W-1:0]      dr_entries_din;
    reg  [DFDP1_W-1:0]      dr_entries_q;
    wire [AWORDSP1_W:0]     dr_free_din; // Extended 1 bit for no carry loss
    reg  [AWORDSP1_W-1:0]   dr_free_q;
    wire [DFD_W-1:0]        dw_start_din;
    reg  [DFD_W-1:0]        dw_start_q;
    wire [DFD_W-1:0]        dw_end_din;
    reg  [DFD_W-1:0]        dw_end_q;
    wire [DFDP1_W-1:0]      dw_entries_din;
    reg  [DFDP1_W-1:0]      dw_entries_q;
    wire [AWORDSP1_W:0]     dw_free_din; // Extended 1 bit for no carry loss
    reg  [AWORDSP1_W-1:0]   dw_free_q;
    // FIFO pointer advance signals. When set by control logic, these advance the
    // corresponding pointer
    // Reset signals set fifo pointers and entry counters back to zero (used after
    // processing an error).
    reg                     dr_start_advance;
    wire                    dr_end_advance;
    wire                    dw_start_advance;
    wire                    dw_end_advance;
    reg                     dr_reset;
    reg                     dw_reset;
    // FIFO get/set signals. start_get always returns the FIFO entry at the
    // current start pointer. end_set will be latched into the FIFO when
    // end_advance is set.
    wire [DW-1:0]           dr_start_get;
    wire [DW-1:0]           dr_end_set;
    wire [DW-1:0]           dw_start_get;
    wire [DW-1:0]           dw_end_set;
    // Wires needed for free, to be instantiated later
    wire [4:0]              axi_ar_len;
    wire                    axi_ar_issue;
    wire [4:0]              axi_aw_len;
    wire                    axi_aw_issue;
    // Width-extended versions for lint-clean comparisons with dr_free_q/dw_free_q
    // Use intermediate 6-bit wire then slice to avoid zero-replication when AWORDSP1_W=5
    wire [5:0]              axi_ar_len_padded = {1'b0, axi_ar_len};
    wire [5:0]              axi_aw_len_padded = {1'b0, axi_aw_len};
    wire [AWORDSP1_W-1:0]   axi_ar_len_ext = axi_ar_len_padded[AWORDSP1_W-1:0];
    wire [AWORDSP1_W-1:0]   axi_aw_len_ext = axi_aw_len_padded[AWORDSP1_W-1:0];

    // Set FIFO - FIFO retains previous value except at end pointer address, if
    // end_advance is set
    always @(*) begin
        integer i;
        for (i=0; i<DFD; i = i+1) begin
            if (i == dr_end_q) begin
                dr_fifo_din[i] = dr_end_advance ? dr_end_set :
                                 dr_fifo_q[i];
            end
            else begin
                dr_fifo_din[i] = dr_fifo_q[i];
            end

            if (i == dw_end_q) begin
                dw_fifo_din[i] = dw_end_advance ? dw_end_set :
                                 dw_fifo_q[i];
            end
            else begin
                dw_fifo_din[i] = dw_fifo_q[i];
            end
        end
    end

    // Set pointers/counters
    // Pointers increment on advance signal, and wrap around at CFD
    wire dw_free_adv = (DW_RESET == 0) ? dw_end_advance : dw_start_advance; // If DW_RESET=0, advance when data enters FIFO, for DW_RESET>1, advance when data exits FIFO
    localparam unsigned [DFD_W-1:0] DFDW_ONE = 'b1;
    localparam unsigned [DFDP1_W-1:0] DFDP1W_ONE = 'b1;
    localparam unsigned [AWORDSP1_W-1:0] AWORDSP1W_ONE = 'b1;
    localparam unsigned [BLEN_W-1:0] BLENW_ONE = 'b1;
    localparam unsigned [STRBW-1:0] STRBW_ONE = 'b1;

    assign dr_start_din   = dr_reset ? {DFD_W{1'b0}} :
                            (~dr_start_advance) ? dr_start_q :
                            (dr_start_q == (DFD-1)) ? {DFD_W{1'b0}} :
                            dr_start_q + DFDW_ONE;
    assign dr_end_din     = dr_reset ? {DFD_W{1'b0}} :
                            (~dr_end_advance) ? dr_end_q :
                            (dr_end_q == (DFD-1)) ? {DFD_W{1'b0}} :
                            (dr_end_q + DFDW_ONE);
    assign dr_entries_din = dr_reset ? {DFDP1_W{1'b0}} :
                            (dr_start_advance && dr_end_advance) ? dr_entries_q :
                            dr_start_advance ? (dr_entries_q - DFDP1W_ONE) :
                            dr_end_advance ? (dr_entries_q + DFDP1W_ONE) :
                            dr_entries_q;
    assign dr_free_din      = dr_reset ? (AWORDSP1_W+1)'(AWORDS) :
                              (dr_start_advance && axi_ar_issue) ? ((dr_free_q + AWORDSP1W_ONE) - axi_ar_len) :
                              dr_start_advance ? (dr_free_q + AWORDSP1W_ONE) :
                              axi_ar_issue ? (dr_free_q - axi_ar_len) :
                              {1'b0, dr_free_q};
    assign dw_start_din   = dw_reset ? {DFD_W{1'b0}} :
                            (~dw_start_advance) ? dw_start_q :
                            (dw_start_q == (DFD-1)) ? {DFD_W{1'b0}} :
                            (dw_start_q + DFDW_ONE);
    assign dw_end_din     = dw_reset ? {DFD_W{1'b0}} :
                            (~dw_end_advance) ? dw_end_q :
                            (dw_end_q == (DFD-1)) ? {DFD_W{1'b0}} :
                            (dw_end_q + DFDW_ONE);
    assign dw_entries_din = dw_reset ? {DFDP1_W{1'b0}} :
                            (dw_start_advance && dw_end_advance) ? dw_entries_q :
                            dw_start_advance ? (dw_entries_q - DFDP1W_ONE) :
                            dw_end_advance ? (dw_entries_q + DFDP1W_ONE) :
                            dw_entries_q;
    assign dw_free_din    = dw_reset ? DW_RESET :
                            (dw_free_adv && axi_aw_issue) ? ((dw_free_q + AWORDSP1W_ONE) - axi_aw_len) :
                            dw_free_adv ? (dw_free_q + AWORDSP1W_ONE) :
                            axi_aw_issue ? (dw_free_q - axi_aw_len) :
                            {1'b0, dw_free_q};

    // Set registers
    always @(posedge clk_gated_r or negedge reset_nai) begin
        integer i;
        if (~reset_nai) begin
            for (i=0; i<DFD; i=i+1) begin
                dr_fifo_q[i] <= {DW{1'b0}};
            end
        end
        else begin
            for (i=0; i<DFD; i=i+1) begin
                dr_fifo_q[i] <= dr_fifo_din[i];
            end
        end
    end
    always @(posedge clk_gated_w or negedge reset_nai) begin
        integer i;
        if (~reset_nai) begin
            for (i=0; i<DFD; i=i+1) begin
                dw_fifo_q[i] <= {DW{1'b0}};
            end
        end
        else begin
            for (i=0; i<DFD; i=i+1) begin
                dw_fifo_q[i] <= dw_fifo_din[i];
            end
        end
    end
    always @(posedge clk_gated_r or negedge reset_nai) begin
        if (~reset_nai) begin
            dr_free_q        <= AWORDS;
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            dr_end_q <= {DFD_W{1'b0}};
            dr_entries_q <= {DFDP1_W{1'b0}};
            dr_start_q <= {DFD_W{1'b0}};
            // End of automatics
        end
        else begin
            dr_start_q      <= dr_start_din;
            dr_end_q        <= dr_end_din;
            dr_entries_q    <= dr_entries_din;
            dr_free_q        <= dr_free_din[AWORDSP1_W-1:0];
        end
    end
    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            dw_free_q        <= DW_RESET;
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            dw_end_q <= {DFD_W{1'b0}};
            dw_entries_q <= {DFDP1_W{1'b0}};
            dw_start_q <= {DFD_W{1'b0}};
            // End of automatics
        end
        else begin
            dw_start_q      <= dw_start_din;
            dw_end_q        <= dw_end_din;
            dw_entries_q    <= dw_entries_din;
            dw_free_q        <= dw_free_din[AWORDSP1_W-1:0];
        end
    end

    // Set start_get to value of FIFO at start pointer
    assign dr_start_get = (dr_entries_q == {DFDP1_W{1'b0}}) ? dr_fifo_din[dr_start_q] : dr_fifo_q[dr_start_q];
    assign dw_start_get = (dw_entries_q == {DFDP1_W{1'b0}}) ? dw_fifo_din[dw_start_q] : dw_fifo_q[dw_start_q];


    /*
     * Engine Read Control/Response FSM
     */

    // Engine cresp encoding
    localparam ENGN_OK_R        = 4'h0;
    localparam ENGN_OK_W        = 4'h1;
    localparam ENGN_SUBERR_R    = 4'h4;
    localparam ENGN_SUBERR_W    = 4'h5;
    localparam ENGN_DECERR_R    = 4'h6;
    localparam ENGN_DECERR_W    = 4'h7;
    localparam ENGN_MGRERR      = 4'h8;

    // Engine control/response states
    localparam unsigned [2:0] S_IDLE   = '0;            // Idle state
    localparam unsigned [2:0] S_PROC   = S_IDLE+1;     // Accept engine read request
    localparam unsigned [2:0] S_PERR   = S_PROC+1;     // Process AXI read error
    localparam unsigned [2:0] S_PRES   = S_PERR+1;     // Issue engine read response
    localparam unsigned [2:0] S_SERR   = S_PRES+1;     // Process stop request
    localparam unsigned [2:0] S_SRES   = S_SERR+1;     // Issue engine stop response

    logic [1:0]      engn_parity_err;
    logic [1:0]      internal_parity_err;
    logic [1:0]      axi_parity_err;

    reg  [2:0]      engn_cr_state_din;
    reg [2:0]       engn_cr_state_q;
    wire [31:0]     engn_cr_addr_din;
    reg [31:0]      engn_cr_addr_q;
    wire [31:0]     engn_cr_len_din;
    reg [31:0]      engn_cr_len_q;
    wire [IDW-1:0]  engn_cr_id_din;
    reg [IDW-1:0]   engn_cr_id_q;
    wire [ENGNUW-1:0]  engn_cr_user_din;
    reg [ENGNUW-1:0]   engn_cr_user_q;
    wire [1:0]      engn_cr_resp_din; // To be driven by axi rdata FSM
    reg [1:0]       engn_cr_resp_q;
    reg             engn_cr_accept_din;
    reg             engn_cr_accept_q;
    reg [32:0]      engn_cr_overflow_din;
    reg [32:0]      engn_cr_overflow_q;
    wire [2:0]      engn_cr_prot_din;
    reg [2:0]       engn_cr_prot_q;
    logic           engn_cr_parity_err_din, engn_cr_parity_err_q;

    wire            engn_cr_valid;
    reg [3:0]       engn_cr_resp;
    wire            engn_cr_done; // To be driven by axi rdata and engn read FSM
    wire            engn_cr_idle; // To be driven by axi rdata and engn read FSM
    wire            engn_cr_error;

    always @(*) begin
        engn_cr_accept_din = 1'b0;
        dr_reset = 1'b0;
        engn_cr_overflow_din = engn_cr_overflow_q;
        engn_cr_parity_err_din = engn_parity_err[1] | internal_parity_err[1] | engn_cr_parity_err_q;

        if (engn_cr_state_q == S_IDLE) begin
            if (engn_crstop_i == 1'b1) begin
                engn_cr_state_din = S_SERR;
                engn_cr_accept_din = 1'b1;
            end
            else if (engn_cread_i == 1'b1) begin
                engn_cr_overflow_din = engn_craddr_i + engn_crlen_i;
                if ((engn_cr_overflow_din > 33'h100000000) | engn_parity_err[1]) begin
                    engn_cr_state_din = S_SERR;
                end
                else begin
                    engn_cr_state_din = S_PROC;
                end
                engn_cr_accept_din = 1'b1;
            end
            else begin
                engn_cr_state_din = S_IDLE;
            end
        end
        else if (engn_cr_state_q == S_PROC) begin
            if ((engn_crstop_i == 1'b1) | internal_parity_err[1]) begin
                engn_cr_state_din = S_SERR;
                engn_cr_accept_din = 1'b1;
            end
            else if (engn_cr_resp_q[1]) begin // If MSB of resp is high, either SUBERR or DECERR has been received
                engn_cr_state_din = S_PERR;
            end
            else if (engn_cr_done) begin
                engn_cr_state_din = S_PRES;
            end
            else begin
                engn_cr_state_din = S_PROC;
            end
        end
        else if (engn_cr_state_q == S_PERR) begin
            if (engn_crstop_i == 1'b1) begin
                engn_cr_state_din = S_SERR;
                engn_cr_accept_din = 1'b1;
            end
            else if (engn_cr_done) begin
                dr_reset = 1'b1;
                engn_cr_state_din = S_PRES;
            end
            else begin
                engn_cr_state_din = S_PERR;
            end
        end
        else if (engn_cr_state_q == S_PRES) begin
            if (engn_crstop_i == 1'b1) begin
                engn_cr_state_din = S_SERR;
                engn_cr_accept_din = 1'b1;
            end
            else begin
                engn_cr_overflow_din = 33'h0_0000_0000;
                engn_cr_parity_err_din = 1'b0;
                engn_cr_state_din = S_IDLE;
            end
        end
        else if (engn_cr_state_q == S_SERR) begin
            if (engn_crstop_i == 1'b1) begin
                engn_cr_state_din = S_SERR;
                engn_cr_accept_din = 1'b1;
                engn_cr_overflow_din = 33'h0_0000_0000;
            end
            else if (engn_cr_done || engn_cr_idle) begin
                dr_reset = 1'b1;
                engn_cr_state_din = S_SRES;
            end
            else begin
                engn_cr_state_din = S_SERR;
            end
        end
        else if (engn_cr_state_q == S_SRES) begin
            engn_cr_overflow_din = 33'h0_0000_0000;
            engn_cr_parity_err_din = 1'b0;
            engn_cr_state_din = S_IDLE;
        end
        else begin
            // Default case - will need to be excluded from coverage
            engn_cr_state_din = S_IDLE;
        end
    end

    assign engn_cr_addr_din = ((engn_cr_state_din == S_IDLE) && (engn_cr_state_q != S_IDLE)) ? 32'h0000_0000 :
                              ((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) ? engn_craddr_i :
                              engn_cr_addr_q;
    assign engn_cr_len_din  = ((engn_cr_state_din == S_IDLE) && (engn_cr_state_q != S_IDLE)) ? 32'h0000_0000 :
                              ((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) ? engn_crlen_i :
                              engn_cr_len_q;
    assign engn_cr_id_din   = ((engn_cr_state_din == S_IDLE) && (engn_cr_state_q != S_IDLE)) ? {(IDW+1){1'b0}} :
                              ((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) ? engn_crid_i :
                              engn_cr_id_q;
    assign engn_cr_user_din = ((engn_cr_state_din == S_IDLE) && (engn_cr_state_q != S_IDLE)) ? {(ENGNUW+1){1'b0}} :
                              ((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) ? engn_cruser_i :
                              engn_cr_user_q;
    assign engn_cr_prot_din = ((engn_cr_state_din == S_IDLE) && (engn_cr_state_q != S_IDLE)) ? 3'b000 :
                              ((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) ? engn_crprot_i :
                              engn_cr_prot_q;

    always @(posedge clk_i or negedge reset_nai) begin
        if (~reset_nai) begin
            engn_cr_state_q  <= S_IDLE;
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            engn_cr_accept_q <= 1'h0;
            engn_cr_addr_q <= 32'h0;
            engn_cr_id_q <= {IDW{1'b0}};
            engn_cr_len_q <= 32'h0;
            engn_cr_overflow_q <= 33'h0;
            engn_cr_resp_q <= 2'h0;
            engn_cr_prot_q <= 3'h0;
            engn_cr_user_q <= {ENGNUW{1'b0}};
            engn_cr_parity_err_q <= '0;
            // End of automatics
        end
        else begin
            engn_cr_state_q  <= engn_cr_state_din;
            engn_cr_addr_q   <= engn_cr_addr_din;
            engn_cr_len_q    <= engn_cr_len_din;
            engn_cr_id_q     <= engn_cr_id_din;
            engn_cr_user_q   <= engn_cr_user_din;
            engn_cr_prot_q   <= engn_cr_prot_din;
            engn_cr_resp_q   <= engn_cr_resp_din;
            engn_cr_accept_q <= engn_cr_accept_din;
            engn_cr_overflow_q <= engn_cr_overflow_din;
            engn_cr_parity_err_q <= engn_cr_parity_err_din;
        end
    end

    assign engn_cr_valid = (engn_cr_state_q == S_PRES) || (engn_cr_state_q == S_SRES);
    assign engn_cr_error = (engn_cr_state_q == S_PERR) || (engn_cr_state_q == S_SERR);

    always @(*) begin
        if (engn_cr_state_q == S_PRES) begin
            if ((engn_cr_resp_q == `HSP_AXI_RESP_SLVERR) || internal_parity_err[1] || engn_cr_parity_err_q) begin
                engn_cr_resp = ENGN_SUBERR_R;
            end
            else if (engn_cr_resp_q == `HSP_AXI_RESP_DECERR) begin
                engn_cr_resp = ENGN_DECERR_R;
            end
            else begin
                engn_cr_resp = ENGN_OK_R;
            end
        end
        else if (engn_cr_state_q == S_SRES) begin
            if ((engn_cr_overflow_q > 33'h100000000) || internal_parity_err[1] || engn_cr_parity_err_q) begin
                engn_cr_resp = ENGN_SUBERR_R;
            end
            else begin
                engn_cr_resp = ENGN_MGRERR;
            end
        end
        else begin
            engn_cr_resp = ENGN_OK_R;
        end
    end

    assign engn_craccept_o = engn_cr_accept_q;
    assign engn_crvalid_o  = engn_cr_valid;
    assign engn_crresp_o   = engn_cr_valid ? engn_cr_resp : 4'd0;


    /*
     * Engine Write Control/Response FSM
     */

    reg  [2:0]      engn_cw_state_din;
    reg [2:0]       engn_cw_state_q;
    wire [31:0]     engn_cw_addr_din;
    reg [31:0]      engn_cw_addr_q;
    wire [31:0]     engn_cw_len_din;
    reg [31:0]      engn_cw_len_q;
    wire [IDW-1:0]  engn_cw_id_din;
    reg [IDW-1:0]   engn_cw_id_q;
    wire [ENGNUW-1:0]  engn_cw_user_din;
    reg [ENGNUW-1:0]   engn_cw_user_q;
    wire [2:0]      engn_cw_prot_din;
    reg [2:0]       engn_cw_prot_q;
    wire [1:0]      engn_cw_resp_din; // To be driven by axi wdata FSM
    reg [1:0]       engn_cw_resp_q;
    reg             engn_cw_accept_din;
    reg             engn_cw_accept_q;
    reg [32:0]      engn_cw_overflow_din;
    reg [32:0]      engn_cw_overflow_q;
    reg             engn_wstop_req_synced;
    wire            engn_wstop_req;
    wire            engn_cw_error;
    logic           engn_cw_parity_err_din, engn_cw_parity_err_q;

    wire            engn_cw_valid;
    reg [3:0]       engn_cw_resp;
    wire            engn_cw_done; // To be driven by axi wdata and engn write FSM
    wire            engn_cw_idle; // To be driven by axi wdata and engn write FSM

    always @(*) begin
        engn_cw_accept_din = 1'b0;
        dw_reset = 1'b0;
        engn_cw_overflow_din = engn_cw_overflow_q;
        engn_cw_parity_err_din = engn_parity_err[0] | internal_parity_err[0] | engn_cw_parity_err_q;

        if (engn_cw_state_q == S_IDLE) begin
            if (engn_cwstop_i == 1'b1) begin
                engn_cw_state_din = S_SERR;
                engn_cw_accept_din = 1'b1;
            end
            else if (engn_cwrite_i == 1'b1) begin
                engn_cw_overflow_din = engn_cwaddr_i + engn_cwlen_i;
                if ((engn_cw_overflow_din > 33'h100000000) | engn_parity_err[0]) begin
                    engn_cw_state_din = S_SERR;
                end
                else begin
                    engn_cw_state_din = S_PROC;
                end
                engn_cw_accept_din = 1'b1;
            end
            else begin
                engn_cw_state_din = S_IDLE;
            end
        end
        else if (engn_cw_state_q == S_PROC) begin
            if ((engn_cwstop_i == 1'b1) || internal_parity_err[0]) begin
                engn_cw_state_din = S_SERR;
                engn_cw_accept_din = 1'b1;
            end
            else if (engn_cw_resp_q[1]) begin // If MSB of resp is high, either SUBERR or DECERR has been received
                engn_cw_state_din = S_PERR;
            end
            else if (engn_cw_done) begin
                engn_cw_state_din = S_PRES;
            end
            else begin
                engn_cw_state_din = S_PROC;
            end
        end
        else if (engn_cw_state_q == S_PERR) begin
            if (engn_cwstop_i == 1'b1) begin
                engn_cw_state_din = S_SERR;
                engn_cw_accept_din = 1'b1;
            end
            else if (engn_cw_done) begin
                engn_cw_state_din = S_PRES;
                dw_reset = 1'b1;
            end
            else begin
                engn_cw_state_din = S_PERR;
            end
        end
        else if (engn_cw_state_q == S_PRES) begin
            if (engn_cwstop_i == 1'b1) begin
                engn_cw_state_din = S_SERR;
                engn_cw_accept_din = 1'b1;
            end
            else begin
                engn_cw_overflow_din = 33'h0_0000_0000;
                engn_cw_parity_err_din = 1'b0;
                engn_cw_state_din = S_IDLE;
                dw_reset = 1'b1; // in case engn sent extraneous beats
            end
        end
        else if (engn_cw_state_q == S_SERR) begin
            if (engn_cwstop_i == 1'b1) begin
                engn_cw_state_din = S_SERR;
                engn_cw_accept_din = 1'b1;
            end
            else if (engn_cw_done || engn_cw_idle) begin
                engn_cw_state_din = S_SRES;
                dw_reset = 1'b1;
            end
            else begin
                engn_cw_state_din = S_SERR;
            end
        end
        else if (engn_cw_state_q == S_SRES) begin
            engn_cw_overflow_din = 33'h0_0000_0000;
            engn_cw_parity_err_din = 1'b0;
            engn_cw_state_din = S_IDLE;
        end
        else begin
            // Default case - will need to be excluded from coverage
            engn_cw_state_din = S_IDLE;
        end
    end

    assign engn_cw_addr_din = ((engn_cw_state_din == S_IDLE) && (engn_cw_state_q != S_IDLE)) ? 32'h0000_0000 :
                              ((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) ? engn_cwaddr_i :
                              engn_cw_addr_q;
    assign engn_cw_len_din  = ((engn_cw_state_din == S_IDLE) && (engn_cw_state_q != S_IDLE)) ? 32'h0000_0000 :
                              ((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) ? engn_cwlen_i :
                              engn_cw_len_q;
    assign engn_cw_id_din   = ((engn_cw_state_din == S_IDLE) && (engn_cw_state_q != S_IDLE)) ? {(IDW+1){1'b0}} :
                              ((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) ? engn_cwid_i :
                              engn_cw_id_q;
    assign engn_cw_user_din = ((engn_cw_state_din == S_IDLE) && (engn_cw_state_q != S_IDLE)) ? {(ENGNUW+1){1'b0}} :
                              ((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) ? engn_cwuser_i :
                              engn_cw_user_q;
    assign engn_cw_prot_din = ((engn_cw_state_din == S_IDLE) && (engn_cw_state_q != S_IDLE)) ? 3'b000 :
                              ((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) ? engn_cwprot_i :
                              engn_cw_prot_q;

    always @(posedge clk_i or negedge reset_nai) begin
        if (~reset_nai) begin
            engn_cw_state_q  <= S_IDLE;
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            engn_cw_accept_q <= 1'h0;
            engn_cw_addr_q <= 32'h0;
            engn_cw_id_q <= {IDW{1'b0}};
            engn_cw_len_q <= 32'h0;
            engn_cw_overflow_q <= 33'h0;
            engn_cw_resp_q <= 2'h0;
            engn_cw_user_q <= {ENGNUW{1'b0}};
            engn_cw_prot_q <= 3'h0;
            engn_cw_parity_err_q <= '0;
            // End of automatics
        end
        else begin
            engn_cw_state_q  <= engn_cw_state_din;
            engn_cw_addr_q   <= engn_cw_addr_din;
            engn_cw_len_q    <= engn_cw_len_din;
            engn_cw_id_q     <= engn_cw_id_din;
            engn_cw_user_q   <= engn_cw_user_din;
            engn_cw_prot_q   <= engn_cw_prot_din;
            engn_cw_resp_q   <= engn_cw_resp_din;
            engn_cw_accept_q <= engn_cw_accept_din;
            engn_cw_overflow_q <= engn_cw_overflow_din;
            engn_cw_parity_err_q <= engn_cw_parity_err_din;
        end
    end

    assign engn_cw_valid = (engn_cw_state_q == S_PRES) || (engn_cw_state_q == S_SRES);

    always @(*) begin
        if (engn_cw_state_q == S_PRES) begin
            if ((engn_cw_resp_q == `HSP_AXI_RESP_SLVERR) || internal_parity_err[0] || engn_cw_parity_err_q) begin
                engn_cw_resp = ENGN_SUBERR_W;
            end
            else if (engn_cw_resp_q == `HSP_AXI_RESP_DECERR) begin
                engn_cw_resp = ENGN_DECERR_W;
            end
            else begin
                engn_cw_resp = ENGN_OK_W;
            end
        end
        else if (engn_cw_state_q == S_SRES) begin
            if ((engn_cw_overflow_q > 33'h100000000) || internal_parity_err[0] || engn_cw_parity_err_q) begin
                engn_cw_resp = ENGN_SUBERR_W;
            end
            else begin
                engn_cw_resp = ENGN_MGRERR;
            end
        end
        else begin
            engn_cw_resp = ENGN_OK_W;
        end
    end

    assign engn_cwaccept_o = engn_cw_accept_q;
    assign engn_cwvalid_o  = engn_cw_valid;
    assign engn_cwresp_o   = engn_cw_valid ? engn_cw_resp : 4'd0;


    /*
     * Engine Read channel controller and engine read alignment
     */

    // AXI and engine read/write states
    //localparam unsigned S_IDLE   = 0; // Already defined previously
    //localparam unsigned S_PROC   = S_PROC+1; // Already defined previously
    localparam unsigned [2:0] S_DONE   = S_PROC+1;

    reg  [2:0]          engn_r_state_din;
    reg [2:0]           engn_r_state_q;
    reg [31:0]          engn_r_len_rem_din;
    reg [31:0]          engn_r_len_rem_q;
    reg [(2*DW)-1:0]    engn_r_align_din;
    reg [(2*DW)-1:0]    engn_r_align_q;
    reg                 engn_r_first_din;
    reg                 engn_r_first_q;
    reg                 engn_r_valid_din;
    reg                 engn_r_valid_q;

    wire [((STRBW_W+3)-1):0] engn_r_addr_offset; // This is how many bits each entry needs to be shifted by to un-address-align
    wire                 engn_r_fifo_valid;

    wire [STRBW_W:0]     engn_r_len_sub = engn_r_first_q ? STRBW - engn_cr_addr_q[STRBW_W-1:0] : STRBW;
    wire unsigned [31:0] engn_r_len_sub_32 = {{(32-(STRBW_W+1)){1'b0}},engn_r_len_sub};
    wire unsigned [31:0] engn_cr_addr_bytes = {{(32-STRBW_W){1'b0}},engn_cr_addr_q[STRBW_W-1:0]};
    wire [32:0]          engn_cr_addr_len = engn_cr_addr_bytes + engn_cr_len_q;
    wire unsigned [STRBW_W:0] engn_cr_strbw_minus_addr = STRBW-engn_cr_addr_q[STRBW_W-1:0];

    always @(*) begin
        engn_r_len_rem_din = engn_r_len_rem_q;
        engn_r_align_din = engn_r_align_q;
        engn_r_first_din = engn_r_first_q;
        engn_r_valid_din = engn_r_valid_q;
        dr_start_advance = 1'b0;

        if (engn_r_state_q == S_IDLE) begin
            if (engn_cr_state_q == S_PROC) begin
                if (engn_cr_len_q != 32'h0000_0000) begin
                    engn_r_state_din = S_PROC;
                    engn_r_len_rem_din = engn_cr_len_q;
                    engn_r_first_din = 1'b1;
                end
                else begin
                    engn_r_state_din = S_DONE;
                end
            end
            else begin
                engn_r_state_din = S_IDLE;
            end
        end
        else if (engn_r_state_q == S_PROC) begin
            if (engn_cr_error) begin
                engn_r_len_rem_din = 32'h0000_0000;
                engn_r_align_din = {(2*DW){1'b0}};
                engn_r_valid_din = 1'b0;
                engn_r_state_din = S_DONE;
            end
            else if (engn_r_fifo_valid) begin
                engn_r_state_din = S_PROC;

                if (engn_r_first_q || (~engn_r_valid_q) || engn_raccept_i) begin
                    engn_r_len_rem_din = (engn_r_len_rem_q <= engn_r_len_sub_32) ? 32'h0000_0000 : engn_r_len_rem_q - engn_r_len_sub_32;
                    engn_r_align_din = (engn_r_first_q && (engn_cr_addr_len[31:0] <= STRBW)) ? {{DW{1'b0}},dr_start_get} >> engn_r_addr_offset :
                                       {{DW{1'b0}},engn_r_align_q[(2*DW)-1:DW]} | ({dr_start_get,{DW{1'b0}}} >> engn_r_addr_offset);
                    engn_r_first_din = 1'b0;
                    engn_r_valid_din = (engn_r_first_q && (engn_cr_addr_len[31:0] <= STRBW)) ? 1'b1 : (~engn_r_first_q);
                    dr_start_advance = 1'b1;
                end
                else begin
                end
            end
            else begin
                engn_r_valid_din = engn_r_valid_q && (~engn_raccept_i);
                if (engn_r_valid_q && engn_raccept_i) begin
                    if (~(|engn_r_len_rem_q)) begin
                        engn_r_state_din = S_DONE;
                        if (((|engn_cr_addr_q[(STRBW_W-1):0]) && ((~(|engn_cr_len_q[STRBW_W-1:0])) || (engn_cr_strbw_minus_addr < {1'b0,engn_cr_len_q[STRBW_W-1:0]}))) ||
                           (engn_cr_addr_len[31:0] <= STRBW)) begin
                            engn_r_align_din = {(2*DW){1'b0}};
                            engn_r_valid_din = 1'b0;
                        end
                        else begin
                            engn_r_align_din = {{DW{1'b0}},engn_r_align_q[(2*DW)-1:DW]};
                            engn_r_valid_din = 1'b1;
                        end
                    end
                    else begin
                        engn_r_state_din = S_PROC;
                        engn_r_valid_din = 1'b0;
                    end
                end
                else begin
                    engn_r_state_din = S_PROC;
                end
            end
        end
        else if (engn_r_state_q == S_DONE) begin
            if (engn_r_valid_q) begin
                if (engn_raccept_i | engn_cr_error) begin // Clear the FIFO on error when in done state.
                    engn_r_len_rem_din = 32'h0000_0000;
                    engn_r_align_din = {(2*DW){1'b0}};
                    engn_r_valid_din = 1'b0;

                    if (engn_cr_state_q == S_IDLE) begin
                        engn_r_state_din = S_IDLE;
                    end
                    else begin
                        engn_r_state_din = S_DONE;
                    end
                end
                else begin
                    engn_r_state_din = S_DONE;
                end
            end
            else begin
                engn_r_len_rem_din = 32'h0000_0000;
                engn_r_align_din = {(2*DW){1'b0}};
                engn_r_valid_din = 1'b0;

                if (engn_cr_state_q == S_IDLE) begin
                    engn_r_state_din = S_IDLE;
                end
                else begin
                    engn_r_state_din = S_DONE;
                end
            end
        end
        else begin
            engn_r_state_din = S_IDLE; // Default case - will need to exclude from coverage
        end
    end

    always @(posedge clk_gated_r or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            engn_r_align_q <= {(1+((2*DW)-1)){1'b0}};
            engn_r_first_q <= 1'h0;
            engn_r_len_rem_q <= 32'h0;
            engn_r_state_q <= S_IDLE;
            engn_r_valid_q <= 1'h0;
            // End of automatics
    end
        else begin
            engn_r_state_q      <= engn_r_state_din;
            engn_r_len_rem_q    <= engn_r_len_rem_din;
            engn_r_align_q      <= engn_r_align_din;
            engn_r_first_q      <= engn_r_first_din;
            engn_r_valid_q      <= engn_r_valid_din;
        end
    end

    assign engn_r_addr_offset   = engn_cr_addr_q[STRBW_W-1:0] << 3; // Should equal starting address * 8
    assign engn_r_fifo_valid    = |dr_entries_q;

    // if engine error or AXI error, stop sending data to engine
    assign engn_rdata_o     = (engn_cr_error || engn_cr_resp_q[1]) ? {32{1'b0}} : engn_r_align_q[DW-1:0];
    assign engn_rvalid_o    = (engn_cr_error || engn_cr_resp_q[1]) ? 1'b0 : engn_r_valid_q;


    /*
     * Engine Write channel controller and write alignment
     */

    wire                        axi_aw_valid;
    reg [31-(STRBW_W+BLEN_W):0] axi_w_num_cmplt_din;
    reg [31-(STRBW_W+BLEN_W):0] axi_w_num_cmplt_q;
    reg [31-(STRBW_W+BLEN_W):0] axi_aw_num_issued_din;
    reg [31-(STRBW_W+BLEN_W):0] axi_aw_num_issued_q;
    reg  [2:0]          engn_w_state_din;
    reg [2:0]           engn_w_state_q;
    reg [32:0]          engn_w_len_rem_din;
    reg [32:0]          engn_w_len_rem_q;
    reg [(2*DW)-1:0]    engn_w_align_din;
    reg [(2*DW)-1:0]    engn_w_align_q;
    reg                 engn_w_valid_din;
    reg                 engn_w_valid_q;
    reg                 engn_w_first_din;
    reg                 engn_w_first_q;

    wire [((STRBW_W+3)-1):0] engn_w_addr_offset; // This is how many bits each entry needs to be shifted by to un-address-align
    wire                 engn_w_fifo_ready;
    wire                 axi_w_valid; // Pre-defining for pipeline speedup

    wire unsigned [31:0] engn_cw_addr_bytes = {{(32-STRBW_W){1'b0}},engn_cw_addr_q[STRBW_W-1:0]};
    wire unsigned [STRBW_W:0] engn_cw_last_word_size = (|engn_cw_len_q[STRBW_W-1:0]) ? {1'b0,engn_cw_len_q[STRBW_W-1:0]} : STRBW;
    wire unsigned [STRBW_W:0] engn_cw_strbw_minus_addr = STRBW-engn_cw_addr_q[STRBW_W-1:0];
    reg [32:0]           axi_aw_len_rem_din;
    reg [32:0]           axi_aw_len_rem_q;
    reg                  wstrb_zero_din;
    reg                  wstrb_zero_q;
    always @(*) begin
        engn_w_len_rem_din = engn_w_len_rem_q;
        engn_w_align_din = engn_w_align_q;
        engn_w_valid_din = engn_w_valid_q;
        engn_w_first_din = engn_w_first_q;
        wstrb_zero_din = wstrb_zero_q;
        if (engn_w_state_q == S_IDLE) begin
            if (engn_cw_state_q == S_PROC) begin
                if (engn_cw_len_q != 32'h0000_0000) begin
                    engn_w_state_din = S_PROC;
                    engn_w_len_rem_din = engn_cw_len_q + engn_cw_addr_bytes; // Add on offset bytes to length
                    engn_w_valid_din = 1'b0;
                    engn_w_first_din = 1'b1;
                    wstrb_zero_din = 1'b0;
                end
                else begin
                    engn_w_state_din = S_DONE;
                end
            end
            else begin
                engn_w_state_din = S_IDLE;
            end
        end
        else if (engn_w_state_q == S_PROC) begin
            if (engn_cw_error && ((axi_w_num_cmplt_q == axi_aw_num_issued_q) && (~axi_aw_valid) )) begin
                engn_w_state_din = S_DONE;
            end
            else if (engn_wvalid_i && (engn_w_first_q || (engn_w_len_rem_q >= {{(33-(STRBW_W+1)){1'b0}}, engn_cw_last_word_size}))) begin
                engn_w_state_din = S_PROC;

                if (engn_w_fifo_ready || (~engn_w_valid_q)) begin
                    if (~engn_wstop_req) begin
                        // engn has not asserted stop request
                        engn_w_len_rem_din = engn_w_valid_q ? ((engn_w_len_rem_q >= STRBW) ? (engn_w_len_rem_q - STRBW) : {(33){1'b0}}) : engn_w_len_rem_q;
                        engn_w_align_din = {{DW{1'b0}},engn_w_align_q[(2*DW)-1:DW]} |
                                           (engn_wdata_i << engn_w_addr_offset);
                        engn_w_valid_din = 1'b1;
                        engn_w_first_din = 1'b0;
                    end
                    else if ((~engn_wstop_req_synced) && ~|dw_entries_q) begin
                        // engn asserted stop request but write channeel is
                        // out of sync. AND there is no data to transmit on
                        // AXI write channel
                        engn_w_align_din = {2*DW{1'b0}};
                        engn_w_valid_din = 1'b1;
                        engn_w_first_din = 1'b0;
                        wstrb_zero_din = 1'b1;
                    end
                    else begin
                    end
                end
                else begin
                end
            end
            else begin
                engn_w_valid_din = engn_w_valid_q && (~engn_w_fifo_ready);
                if (engn_w_valid_q && engn_w_fifo_ready) begin
                    if (((engn_w_len_rem_q < (STRBW*2'h2)) && (engn_w_len_rem_q > (STRBW))) && ((|engn_cw_addr_q[STRBW_W-1:0]) && ((~(|engn_cw_len_q[STRBW_W-1:0])) || (engn_cw_strbw_minus_addr < {1'b0,engn_cw_len_q[STRBW_W-1:0]})))) begin
                        engn_w_state_din = S_PROC;
                        engn_w_len_rem_din = (engn_w_len_rem_q - STRBW);
                        engn_w_align_din = {{DW{1'b0}},engn_w_align_q[(2*DW)-1:DW]};
                        engn_w_valid_din = 1'b1;
                    end
                    else if (engn_w_len_rem_q <= STRBW) begin
                        engn_w_state_din = S_DONE;
                        engn_w_len_rem_din = 33'h0_0000_0000;
                        engn_w_align_din = {(2*DW){1'b0}};
                    end
                    else begin
                        engn_w_state_din = S_PROC;
                        engn_w_len_rem_din = (engn_w_len_rem_q - STRBW);
                    end
                end
                else begin
                    engn_w_state_din = S_PROC;
                end
            end
        end
        else if (engn_w_state_q == S_DONE) begin
            if (engn_cw_state_q == S_IDLE) begin
                engn_w_state_din = S_IDLE;
                engn_w_len_rem_din = 33'h0_0000_0000;
                engn_w_align_din = {(2*DW){1'b0}};
            end
            else begin
                engn_w_state_din = S_DONE;
            end
        end
        else begin
            // Default state - exclude for coverage
            engn_w_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            engn_w_align_q <= {(1+((2*DW)-1)){1'b0}};
            engn_w_first_q <= 1'h0;
            engn_w_len_rem_q <= 33'h0;
            engn_w_state_q <= S_IDLE;
            engn_w_valid_q <= 1'h0;
            wstrb_zero_q <= 1'b0;
            // End of automatics
    end
        else begin
            engn_w_state_q      <= engn_w_state_din;
            engn_w_len_rem_q    <= engn_w_len_rem_din;
            engn_w_align_q      <= engn_w_align_din;
            engn_w_valid_q        <= engn_w_valid_din;
            engn_w_first_q        <= engn_w_first_din;
            wstrb_zero_q    <= wstrb_zero_din;
        end
    end

    assign engn_w_addr_offset   = engn_cw_addr_q[$clog2(STRBW)-1:0] << 3; // Should equal starting address * 8
    assign engn_w_fifo_ready    = (dw_entries_q < DFD) | (wready_i && axi_w_valid);

    assign engn_waccept_o   = ((engn_w_state_q == S_PROC) && (~engn_wstop_req)) ? ((engn_w_fifo_ready || (~engn_w_valid_q)) && (engn_w_first_q || (engn_w_len_rem_q >= {{(33-(STRBW_W+1)){1'b0}}, engn_cw_last_word_size}))) : 1'b0;
    assign dw_end_set       = engn_w_align_q[DW-1:0];
    assign dw_end_advance   = ((engn_w_state_q == S_PROC) && (~engn_wstop_req_synced)) ? (engn_w_valid_q || ((~engn_w_first_q) && (engn_w_len_rem_q < {{(33-(STRBW_W+1)){1'b0}}, engn_cw_last_word_size}))) && engn_w_fifo_ready : 1'b0;


    /*
     * AXI Address Read channel controller
     */

    localparam ABURST    = 2'b01;
    localparam ACACHE    = 4'b0000;
    localparam ALOCK     = 2'b00;
    localparam AQOS      = 4'd0;
    localparam AREGION   = 4'd0;
    localparam ASIZE     = STRBW_W;

    localparam unsigned [(31-(STRBW_W+BLEN_W)):0] MAX_BURST_SIZE = 1;

    reg  [2:0]      axi_ar_state_din;
    reg [2:0]       axi_ar_state_q;
    reg [32:0]      axi_ar_len_rem_din;
    reg [32:0]      axi_ar_len_rem_q;
    reg [31:0]      axi_ar_addr_din;
    reg [31:0]      axi_ar_addr_q;
    reg [IDW-1:0]   axi_ar_id_din;
    reg [IDW-1:0]   axi_ar_id_q;
    reg [ENGNUW-1:0]   axi_ar_user_din;
    reg [ENGNUW-1:0]   axi_ar_user_q;
    reg [2:0]       axi_ar_prot_din;
    reg [2:0]       axi_ar_prot_q;
    wire [31:0]     axi_ar_addr_next;
    wire            axi_ar_valid;
    //wire [4:0]      axi_ar_len; //Previously defined
    wire [3:0]      axi_ar_axilen;
    //wire            axi_ar_issue; //Previously defined

    wire unsigned [32:0] axi_ar_len_words = (axi_ar_len > 5'h00) ? {{(33-(5+STRBW_W)){1'b0}},axi_ar_len,{STRBW_W{1'b0}}} :
                                                {{(33-(5+STRBW_W)){1'b0}},5'h01,{STRBW_W{1'b0}}};


    always @(*) begin
        axi_ar_len_rem_din = axi_ar_len_rem_q;
        axi_ar_addr_din = axi_ar_addr_q;
        axi_ar_id_din = axi_ar_id_q;
        axi_ar_user_din = axi_ar_user_q;
        axi_ar_prot_din = axi_ar_prot_q;

        if (axi_ar_state_q == S_IDLE) begin
            if (engn_cr_state_q == S_PROC) begin
                if ((engn_cr_len_q != 32'h0000_0000) && (!internal_parity_err[1])) begin
                    axi_ar_state_din = S_PROC;
                    axi_ar_len_rem_din = engn_cr_len_q + engn_cr_addr_bytes;
                    axi_ar_addr_din = {engn_cr_addr_q[31:STRBW_W],{STRBW_W{1'b0}}};
                    axi_ar_id_din = engn_cr_id_q;
                    axi_ar_user_din = engn_cr_user_q;
                    axi_ar_prot_din = engn_cr_prot_q;
                end
                else begin
                    axi_ar_state_din = S_DONE;
                end
            end
            else begin
                axi_ar_state_din = S_IDLE;
            end
        end
        else if (axi_ar_state_q == S_PROC) begin
            if (internal_parity_err[1]) begin
                //Abort. May violate AXI protocol, but this unavoidable when the driving flop is corrupted
                //unless some redundancy scheme is used with backup data for the various fields
                axi_ar_state_din = S_DONE;
                axi_ar_len_rem_din = 33'h0_0000_0000;
            end
            else if (engn_cr_error) begin
                if ((~axi_ar_valid) || axi_ar_issue) begin
                    axi_ar_state_din = S_DONE;
                end
                else begin
                    axi_ar_state_din = S_PROC;
                end
            end
            else if (axi_ar_issue) begin
                if (axi_ar_len_words >= axi_ar_len_rem_q) begin
                    axi_ar_state_din = S_DONE;
                    axi_ar_len_rem_din = 33'h0_0000_0000;
                end
                else begin
                    axi_ar_state_din = S_PROC;
                    axi_ar_len_rem_din = axi_ar_len_rem_q - axi_ar_len_words;
                    axi_ar_addr_din = axi_ar_addr_next;
                end
            end
            else begin
                axi_ar_state_din = S_PROC;
            end
        end
        else if (axi_ar_state_q == S_DONE) begin
            if (engn_cr_state_q == S_IDLE) begin
                axi_ar_state_din = S_IDLE;
                axi_ar_len_rem_din = 33'h0_0000_0000;
                axi_ar_addr_din = 32'h0000_0000;
                axi_ar_id_din = {IDW{1'b0}};
                axi_ar_user_din = {ENGNUW{1'b0}};
                axi_ar_prot_din = 3'h0;
            end
            else begin
                axi_ar_state_din = S_DONE;
            end
        end
        else begin
            // default - exclude for coverage
            axi_ar_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_r or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            axi_ar_addr_q <= 32'h0;
            axi_ar_id_q <= {IDW{1'b0}};
            axi_ar_len_rem_q <= 33'h0;
            axi_ar_state_q <= 3'h0;
            axi_ar_user_q <= {ENGNUW{1'b0}};
            axi_ar_prot_q <= 3'h0;
            // End of automatics
        end
        else begin
            axi_ar_state_q      <= axi_ar_state_din;
            axi_ar_len_rem_q    <= axi_ar_len_rem_din;
            axi_ar_addr_q       <= axi_ar_addr_din;
            axi_ar_id_q         <= axi_ar_id_din;
            axi_ar_user_q       <= axi_ar_user_din;
            axi_ar_prot_q       <= axi_ar_prot_din;
        end
    end

    wire [(32-(STRBW_W+BLEN_W)):0] axi_ar_addr_next_int = axi_ar_addr_q[31:(STRBW_W+BLEN_W)]+MAX_BURST_SIZE;
    assign      axi_ar_addr_next = {axi_ar_addr_next_int[(31-(STRBW_W+BLEN_W)):0],
                               {(STRBW_W+BLEN_W){1'b0}}};
    assign      axi_ar_valid = (axi_ar_state_q == S_SERR) ? 1'b1 : 
                               (axi_ar_state_q == S_PROC) ? ((axi_ar_len_ext <= dr_free_q) && (!internal_parity_err[1])) : 1'b0;
    wire [31:0] axi_ar_addr_diff = (axi_ar_addr_next - axi_ar_addr_q);
    // MAX len for next transfer is minimum determined by
    // difference between successive addresses, OR
    // LEN remaining (in bytes) that can be accommodated in one transaction
    wire [(STRBW_W+BLEN_W+1):0]  axi_ar_len_max  = (axi_ar_addr_diff < axi_ar_len_rem_q[31:0])  ?
                                    ((STRBW_W+BLEN_W+1)'(axi_ar_addr_diff[(STRBW_W+BLEN_W) : 0] >> ASIZE) + ((STRBW_W+BLEN_W+1)'(|axi_ar_addr_diff[(ASIZE-1) : 0])))    :
                                    ((STRBW_W+BLEN_W+1)'(axi_ar_len_rem_q[(STRBW_W+BLEN_W) : 0] >> ASIZE)  + ((STRBW_W+BLEN_W+1)'(|axi_ar_len_rem_q[(ASIZE-1) : 0])))    ;

    wire unsigned [32:0] axi_ar_len_max_addr = {{(33-(5+STRBW_W)){1'b0}},axi_ar_len_max[(STRBW_W+BLEN_W+1):0],{STRBW_W{1'b0}}};

    wire [4:0]  axi_arlen_temp = axi_ar_len_rem_q[(3+STRBW_W):STRBW_W] + {3'd0,(|axi_ar_len_rem_q[STRBW_W-1:0])};

    assign      axi_ar_len = (axi_ar_len_max_addr > axi_ar_len_rem_q) ?
                              axi_arlen_temp :
                              axi_ar_len_max[4:0];

    wire [4:0]  axi_ar_lenm1 = (axi_ar_len > 0) ? axi_ar_len - 5'h01 : 5'h00;
    assign      axi_ar_axilen = (axi_ar_state_q != S_PROC) ? 4'h0 : axi_ar_lenm1[3:0];
    assign      axi_ar_issue = axi_ar_valid && arready_i;


    assign araddr_o        = axi_ar_addr_q;
    assign arburst_o       = ABURST;
    assign arcache_o       = ACACHE;
    assign arid_o          = axi_ar_id_q;
    assign aruser_o[ENGNUW-1:0] = axi_ar_user_q;
    assign arprot_o        = axi_ar_prot_q;
    assign arlen_o         = {4'h0,axi_ar_axilen};
    assign arlock_o     = ALOCK;
    assign arqos_o         = AQOS;
    assign arregion_o    = AREGION;
    assign arsize_o     = ASIZE;
    assign arvalid_o    = axi_ar_valid;



    /*
     * AXI Address Write channel controller
     */

    reg [2:0]            axi_aw_state_din;
    reg [2:0]            axi_aw_state_q;

// signal below are defined earlier in engine write controller logic
//    reg [32:0]           axi_aw_len_rem_din;
//    reg [31:0]           axi_aw_len_rem_q;
//    reg [31-(STRBW_W+BLEN_W):0] axi_aw_num_issued_din;
//    reg [31-(STRBW_W+BLEN_W):0] axi_aw_num_issued_q;
    reg [31:0]           axi_aw_addr_din;
    reg [31:0]           axi_aw_addr_q;

    reg [IDW-1:0]               axi_aw_id_din;
    reg [IDW-1:0]               axi_aw_id_q;
    reg [ENGNUW-1:0]            axi_aw_user_din;
    reg [ENGNUW-1:0]            axi_aw_user_q;
    reg [2:0]                   axi_aw_prot_din;
    reg [2:0]                   axi_aw_prot_q;

    wire [31:0]                 axi_aw_addr_next;
//    wire                        axi_aw_valid;
    //wire [4:0]      axi_aw_len; //Previously defined
    wire [3:0]                  axi_aw_axilen;
    //wire            axi_aw_issue; //Previously defined

    wire unsigned [32:0] axi_aw_len_words = (axi_aw_len > 5'h00) ? {{(33-(5+STRBW_W)){1'b0}},axi_aw_len,{STRBW_W{1'b0}}} :
                                                {{(33-(5+STRBW_W)){1'b0}},5'h01,{STRBW_W{1'b0}}};

    always @(*) begin
        axi_aw_len_rem_din = axi_aw_len_rem_q;
        axi_aw_addr_din = axi_aw_addr_q;
        axi_aw_num_issued_din = axi_aw_num_issued_q;
        axi_aw_id_din = axi_aw_id_q;
        axi_aw_user_din = axi_aw_user_q;
        axi_aw_prot_din = axi_aw_prot_q;

        if (axi_aw_state_q == S_IDLE) begin
            if (engn_cw_state_q == S_PROC) begin
                if ((engn_cw_len_q != 32'h0000_0000) && (!internal_parity_err[0])) begin
                    axi_aw_state_din = S_PROC;
                    axi_aw_len_rem_din = engn_cw_len_q + engn_cw_addr_bytes;
                    axi_aw_addr_din = {engn_cw_addr_q[31:STRBW_W],{STRBW_W{1'b0}}};
                    axi_aw_num_issued_din = {(32-(STRBW_W+BLEN_W)){1'b0}};
                    axi_aw_id_din = engn_cw_id_q;
                    axi_aw_user_din = engn_cw_user_q;
                    axi_aw_prot_din = engn_cw_prot_q;
                end
                else begin
                    axi_aw_state_din = S_DONE;
                end
            end
            else begin
                axi_aw_state_din = S_IDLE;
            end
        end
        else if (axi_aw_state_q == S_PROC) begin
            if (internal_parity_err[0]) begin
                //Abort. May violate AXI protocol, but this unavoidable when the driving flop is corrupted
                //unless some redundancy scheme is used with backup data for the various fields
                axi_aw_state_din = S_DONE;
                axi_aw_len_rem_din = 33'h0_0000_0000;
            end
            else if (engn_cw_error) begin
                if (~axi_aw_valid) begin
                    axi_aw_state_din = S_DONE;
                end
                else if (axi_aw_issue) begin
                    axi_aw_state_din = S_DONE;
                    axi_aw_num_issued_din = axi_aw_num_issued_q + MAX_BURST_SIZE;
                end
                else begin
                    axi_aw_state_din = S_PROC;
                end
            end
            else if (axi_aw_issue) begin
                axi_aw_num_issued_din = axi_aw_num_issued_q + MAX_BURST_SIZE;

                if (axi_aw_len_words >= axi_aw_len_rem_q) begin
                    axi_aw_state_din = S_DONE;
                    axi_aw_len_rem_din = 33'h0_0000_0000;
                end
                else begin
                    axi_aw_state_din = S_PROC;
                    axi_aw_len_rem_din = axi_aw_len_rem_q - axi_aw_len_words;
                    axi_aw_addr_din = axi_aw_addr_next;
                end
            end
            else begin
                axi_aw_state_din = S_PROC;
            end
        end
        else if (axi_aw_state_q == S_DONE) begin
            if (engn_cw_state_q == S_IDLE) begin
                axi_aw_state_din = S_IDLE;
                axi_aw_len_rem_din = 33'h0_0000_0000;
                axi_aw_addr_din = 32'h0000_0000;
                axi_aw_id_din = {IDW{1'b0}};
                axi_aw_user_din = {ENGNUW{1'b0}};
                axi_aw_prot_din = 3'h0;
                axi_aw_num_issued_din = {(32-(STRBW_W+BLEN_W)){1'b0}};
            end
            else begin
                axi_aw_state_din = S_DONE;
            end
        end
        else begin
            // default - exclude for coverage
            axi_aw_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            axi_aw_addr_q <= 32'h0;
            axi_aw_id_q <= {IDW{1'b0}};
            axi_aw_len_rem_q <= 33'h0;
            axi_aw_num_issued_q <= {(1+(31-(STRBW_W+BLEN_W))){1'b0}};
            axi_aw_state_q <= 3'h0;
            axi_aw_user_q <= {ENGNUW{1'b0}};
            axi_aw_prot_q <= 3'h0;
            // End of automatics
        end
        else begin
            axi_aw_state_q      <= axi_aw_state_din;
            axi_aw_len_rem_q    <= axi_aw_len_rem_din;
            axi_aw_addr_q       <= axi_aw_addr_din;
            axi_aw_id_q         <= axi_aw_id_din;
            axi_aw_user_q       <= axi_aw_user_din;
            axi_aw_prot_q       <= axi_aw_prot_din;
            axi_aw_num_issued_q <= axi_aw_num_issued_din;
        end
    end

    wire [(32-(STRBW_W+BLEN_W)):0] axi_aw_addr_next_int = axi_aw_addr_q[31:(STRBW_W+BLEN_W)]+MAX_BURST_SIZE;
    assign axi_aw_addr_next = {axi_aw_addr_next_int[(31-(STRBW_W+BLEN_W)):0],
                               {(STRBW_W+BLEN_W){1'b0}}};
    assign axi_aw_valid = ((axi_aw_state_q == S_PROC) && (~engn_w_first_q)) ? ((axi_aw_len_ext <= dw_free_q) && (!internal_parity_err[0])) : 1'b0;
    wire [31:0] axi_aw_addr_diff = (axi_aw_addr_next - axi_aw_addr_q);
    // MAX len for next transfer is minimum determined by
    // difference between successive addresses, OR
    // LEN remaining (in bits) that can be accomoadated in one transaction
    wire [(STRBW_W+BLEN_W):0]  axi_aw_len_max  = (axi_aw_addr_diff < axi_aw_len_rem_q[31:0])  ?
                                    ((axi_aw_addr_diff[(STRBW_W+BLEN_W) : 0] >> ASIZE) + (|axi_aw_addr_diff[(ASIZE-1) : 0]))        :
                                    ((axi_aw_len_rem_q[(STRBW_W+BLEN_W) : 0] >> ASIZE) + (|axi_aw_len_rem_q[(ASIZE-1) : 0]));
    // wire [4:0] axi_aw_len_max = axi_aw_addr_next[(STRBW_W+BLEN_W):STRBW_W] - axi_aw_addr_q[(STRBW_W+BLEN_W):STRBW_W];

    wire [4:0]  axi_awlen_temp = axi_aw_len_rem_q[(3+STRBW_W):STRBW_W] + {3'd0,(|axi_aw_len_rem_q[STRBW_W-1:0])};

    wire unsigned [32:0] axi_aw_len_max_addr = {{(33-(BLEN_W+(2*STRBW_W))){1'b0}},axi_aw_len_max,{STRBW_W{1'b0}}};
    assign axi_aw_len = (axi_aw_len_max_addr > axi_aw_len_rem_q)    ?
                         axi_awlen_temp   :
                         axi_aw_len_max[4:0];

    wire [4:0]           axi_aw_lenm1 = (axi_aw_len > 5'h00) ? (axi_aw_len - 5'h01) :
                                        axi_aw_len[4:0];
    assign axi_aw_axilen = (axi_aw_state_q != S_PROC) ? 4'd0 : axi_aw_lenm1[3:0];
    assign axi_aw_issue = axi_aw_valid && awready_i;


    assign awaddr_o        = axi_aw_addr_q;
    assign awburst_o     = ABURST;
    assign awcache_o     = ACACHE;
    assign awid_o         = axi_aw_id_q;
    assign awuser_o[ENGNUW-1:0] = axi_aw_user_q;
    assign awprot_o       = axi_aw_prot_q;
    assign awlen_o         = {4'd0,axi_aw_axilen};
    assign awlock_o     = ALOCK;
    assign awqos_o         = AQOS;
    assign awregion_o    = AREGION;
    assign awsize_o     = ASIZE;
    assign awvalid_o    = axi_aw_valid;



    /*
     * AXI Read Data channel controller
     */

    reg [2:0]            axi_r_state_din;
    reg [2:0]            axi_r_state_q;
    reg [IDW-1:0]        axi_r_id_exp_din;
    reg [IDW-1:0]        axi_r_id_exp_q;
    reg [BLEN_W-1:0]     axi_r_addr_din;
    reg [BLEN_W-1:0]     axi_r_addr_q;
    reg [AWORDSP1_W:0]   axi_r_count_din;
    reg [AWORDSP1_W-1:0] axi_r_count_q;

    wire                 axi_r_ready;
    wire                 axi_r_last_beat;
    wire                 axi_r_last_exp;

    wire [AWORDSP1_W:0] axi_r_free_plus_entries = (dr_free_q + axi_r_count_q) + AWORDSP1W_ONE;

    always @(*) begin
        axi_r_id_exp_din = axi_r_id_exp_q;
        axi_r_addr_din = axi_r_addr_q;
        axi_r_count_din = {1'b0,axi_r_count_q};

        if (axi_r_state_q == S_IDLE) begin
            if (engn_cr_state_q == S_PROC) begin
                if (engn_cr_len_q != 32'h0000_0000) begin
                    axi_r_id_exp_din = engn_cr_id_q;
                    axi_r_addr_din = engn_cr_addr_q[((BLEN_W+STRBW_W)-1):STRBW_W];
                    axi_r_count_din = {(AWORDSP1_W+1){1'b0}};
                    axi_r_state_din = S_PROC;
                end
                else begin
                    axi_r_state_din = S_DONE;
                end
            end
            else begin
                axi_r_state_din = S_IDLE;
            end
        end
        else if (axi_r_state_q == S_PROC) begin
            axi_r_count_din = (dr_end_advance && dr_start_advance) ? {1'b0, axi_r_count_q} :
                              dr_end_advance ? axi_r_count_q + AWORDSP1W_ONE :
                              dr_start_advance ? axi_r_count_q - AWORDSP1W_ONE :
                              {1'b0, axi_r_count_q};
            if (dr_end_advance) begin
                axi_r_addr_din = axi_r_addr_q + BLENW_ONE;
                if (axi_r_last_beat) begin
                    axi_r_state_din = S_DONE;
                end
                else begin
                    axi_r_state_din = S_PROC;
                end
            end
            else begin
                if ((axi_ar_state_q == S_DONE) && (axi_r_free_plus_entries > AWORDS)) begin // Catches case where AR stops after last RLAST, but before issuing an additional read transaction (occurs on DECERR/SUBERR)
                    axi_r_state_din = S_DONE;
                end
                else begin
                    axi_r_state_din = S_PROC;
                end
            end
        end
        else if (axi_r_state_q == S_DONE) begin
            if (engn_cr_state_q == S_IDLE) begin
                axi_r_id_exp_din = {IDW{1'b0}};
                axi_r_addr_din = {BLEN_W{1'b0}};
                axi_r_state_din = S_IDLE;
            end
            else begin
                axi_r_state_din = S_DONE;
            end
        end
        else begin
            //Default - exclude from coverage
            axi_r_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_r or negedge reset_nai) begin
        if (~reset_nai) begin
            axi_r_state_q   <= S_IDLE;
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            axi_r_addr_q <= {BLEN_W{1'b0}};
            axi_r_count_q <= {AWORDSP1_W{1'b0}};
            axi_r_id_exp_q <= {IDW{1'b0}};
            // End of automatics
        end
        else begin
            axi_r_state_q   <= axi_r_state_din;
            axi_r_id_exp_q  <= axi_r_id_exp_din;
            axi_r_addr_q    <= axi_r_addr_din;
            axi_r_count_q   <= axi_r_count_din[AWORDSP1_W-1:0];
        end
    end

    assign axi_r_ready = (axi_r_state_q == S_PROC) && ((dr_entries_q < DFD) || (engn_r_state_q == S_DONE) || ((~engn_cr_error) && (engn_r_first_q || (~engn_r_valid_q) || engn_raccept_i))); // Allow entries to overflow when the engine is already done (ie. we're in an error state)
    assign axi_r_last_beat = (axi_ar_state_q == S_DONE) && (axi_r_free_plus_entries == AWORDS);
    assign axi_r_last_exp = axi_r_last_beat ? 1'b1 :
                            (&axi_r_addr_q) ? 1'b1 :
                            1'b0;

    assign dr_end_advance = axi_r_ready && rvalid_i;
    assign dr_end_set = (rresp_i[1] || engn_cr_resp_q[1]) ? {DW{1'b0}} : rdata_i;
    assign engn_cr_resp_din = (engn_cr_state_q == S_IDLE) ? 2'd0 :
                              (err_r_parity_o) ? `HSP_AXI_RESP_SLVERR :
                              engn_cr_resp_q[1] ? engn_cr_resp_q :
                              (~dr_end_advance) ? engn_cr_resp_q :
                              (rid_i != axi_r_id_exp_q) ? `HSP_AXI_RESP_SLVERR :
                              (rlast_i != axi_r_last_exp) ? `HSP_AXI_RESP_SLVERR :
                              rresp_i;

    assign rready_o = axi_r_ready;
    assign engn_cr_done = (axi_r_state_q == S_DONE) && (engn_r_state_q == S_DONE) && (~engn_r_valid_q );   
    assign engn_cr_idle = (axi_r_state_q == S_IDLE) && (engn_r_state_q == S_IDLE);



    /*
     * AXI Write Data channel controller
     */

    reg  [2:0]      axi_w_state_din;
    reg [2:0]       axi_w_state_q;
    reg [32:0]      axi_w_addr_din;
    reg [31:0]      axi_w_addr_q;
    reg [32:0]      axi_w_len_rem_din;
    reg [32:0]      axi_w_len_rem_q;
//    reg [31-(STRBW_W+BLEN_W):0] axi_w_num_cmplt_din;
//    reg [31-(STRBW_W+BLEN_W):0] axi_w_num_cmplt_q;
    reg                         axi_w_suberr_din;
    reg                         axi_w_suberr_q;
    reg                         axi_w_cwstate_din;
    reg                         axi_w_cwstate_q;
    reg [IDW-1:0]               axi_w_id_din;
    reg [IDW-1:0]               axi_w_id_q;

    wire [DW-1:0]               axi_w_data;
    wire                        axi_w_last;
    wire [STRBW-1:0]            axi_w_strb;
//    wire                        axi_w_valid; //Defined earlier in engn_w fsm

    wire [31-(STRBW_W+BLEN_W):0] last_one = axi_w_last ? MAX_BURST_SIZE : {(32-(STRBW_W+BLEN_W)){1'b0}};

    assign engn_wstop_req = (engn_cw_state_din == S_SERR);
    assign engn_cw_error = (engn_cw_state_din == S_PERR) || (engn_cw_state_din == S_SERR);
    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            engn_wstop_req_synced <= 1'b0;
        end
        else begin
            if (wready_i && engn_wstop_req) begin
                engn_wstop_req_synced <= 1'b1;
            end
            else if (axi_w_state_q == S_IDLE) begin
                engn_wstop_req_synced <= 1'b0;
            end
            else begin
            end
        end
    end


    always @(*) begin
        axi_w_addr_din = {1'b0,axi_w_addr_q};
        axi_w_len_rem_din = axi_w_len_rem_q;
        axi_w_num_cmplt_din = axi_w_num_cmplt_q;
        axi_w_suberr_din = axi_w_suberr_q;
        axi_w_cwstate_din = axi_w_cwstate_q;
        axi_w_id_din = axi_w_id_q;

        if (axi_w_state_q == S_IDLE) begin
            if (engn_cw_state_q == S_PROC) begin
                if (engn_cw_len_q != 32'h0000_0000) begin
                    axi_w_state_din = S_PROC;
                    axi_w_addr_din = {1'b0,engn_cw_addr_q};
                    axi_w_len_rem_din = engn_cw_len_q + engn_cw_addr_bytes;
                    axi_w_num_cmplt_din = {(32-(STRBW_W+BLEN_W)){1'b0}};
                    axi_w_suberr_din = engn_cw_resp_q[1];
                    axi_w_cwstate_din = 1'b1;
                    axi_w_id_din = engn_cw_id_q;
                end
                else begin
                    axi_w_state_din = S_DONE;
                end
            end
            else begin
                axi_w_state_din = S_IDLE;
            end
        end
        else if (axi_w_state_q == S_PROC) begin
            if (axi_w_valid && wready_i) begin
                axi_w_addr_din = {axi_w_addr_din[31:STRBW_W],{STRBW_W{1'b0}}} + STRBW;
                axi_w_len_rem_din = (axi_w_len_rem_q - STRBW);
                axi_w_num_cmplt_din = (axi_w_num_cmplt_q + last_one);
                axi_w_suberr_din = engn_cw_resp_q[1] || internal_parity_err[0];
                axi_w_cwstate_din = (engn_cw_state_q == S_PROC);
            end
            else begin
                axi_w_suberr_din = axi_w_suberr_q || internal_parity_err[0];
            end

            if ((axi_aw_state_q == S_DONE) && (axi_w_num_cmplt_q >= axi_aw_num_issued_q)) begin
                axi_w_id_din = {IDW{1'b0}};
                axi_w_state_din = S_DONE;
            end
            else begin
                axi_w_state_din = S_PROC;
            end
        end
        else if (axi_w_state_q == S_DONE) begin
            if (engn_cw_state_q == S_IDLE) begin
                axi_w_state_din = S_IDLE;
            end
            else begin
                axi_w_state_din = S_DONE;
            end
        end
        else begin
            //Default - exclude from coverage
            axi_w_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            axi_w_addr_q <= 32'h0;
            axi_w_cwstate_q <= 1'h0;
            axi_w_id_q <= {IDW{1'b0}};
            axi_w_len_rem_q <= 33'h0;
            axi_w_num_cmplt_q <= {(1+(31-(STRBW_W+BLEN_W))){1'b0}};
            axi_w_suberr_q <= 1'h0;
            axi_w_state_q <= S_IDLE;
            // End of automatics
        end
        else begin
            axi_w_state_q       <= axi_w_state_din;
            axi_w_addr_q        <= axi_w_addr_din[31:0];
            axi_w_len_rem_q     <= axi_w_len_rem_din;
            axi_w_num_cmplt_q   <= axi_w_num_cmplt_din;
            axi_w_suberr_q      <= axi_w_suberr_din;
            axi_w_cwstate_q     <= axi_w_cwstate_din;
            axi_w_id_q          <= axi_w_id_din;
        end
    end

    assign axi_w_data = ((axi_w_state_q == S_PROC) && axi_w_cwstate_q && (~engn_wstop_req_synced)) ? dw_start_get : {DW{1'b0}};
    assign axi_w_last = (axi_w_state_q == S_PROC) ? ((&axi_w_addr_q[((BLEN_W+STRBW_W)-1):STRBW_W])) || (axi_w_len_rem_q <= STRBW) :
                        1'b0;
    wire [STRBW-1:0] axi_w_strb_addr_mask = (STRBW_ONE << axi_w_addr_q[STRBW_W-1:0]) - STRBW_ONE;
    wire [STRBW-1:0] axi_w_strb_rem_mask = (|axi_w_len_rem_q[32:STRBW_W]) ? {STRBW{1'b1}} : (STRBW_ONE << axi_w_len_rem_q[STRBW_W-1:0]) - STRBW_ONE;

    assign axi_w_strb = ((~(axi_w_state_q == S_PROC)) || (wstrb_zero_q || engn_wstop_req_synced) || internal_parity_err[0]) ? {STRBW{1'b0}} :
                        axi_w_suberr_q ? {STRBW{1'b0}} :
                        (~axi_w_strb_addr_mask) & axi_w_strb_rem_mask;

    assign axi_w_valid = (axi_w_state_q == S_PROC) & (axi_w_num_cmplt_q < axi_aw_num_issued_q) & ((|dw_entries_q) || engn_wstop_req_synced);


    assign dw_start_advance = (wready_i & axi_w_valid) && (~engn_wstop_req_synced);
    assign wdata_o = axi_w_data;
    assign wlast_o = axi_w_last;
    assign wstrb_o = axi_w_strb;
    assign wvalid_o = axi_w_valid;


    /*
     * AXI Write Response channel controller
     */


    reg [2:0]        axi_b_state_din;
    reg [2:0]        axi_b_state_q;
    reg [31-(STRBW_W+BLEN_W):0] axi_b_num_cmplt_din;
    reg [31-(STRBW_W+BLEN_W):0] axi_b_num_cmplt_q;
    reg [IDW-1:0]               axi_b_id_exp_din;
    reg [IDW-1:0]               axi_b_id_exp_q;

    wire        axi_b_ready;

    always @(*) begin
        axi_b_num_cmplt_din = axi_b_num_cmplt_q;
        axi_b_id_exp_din = axi_b_id_exp_q;

        if (axi_b_state_q == S_IDLE) begin
            if (engn_cw_state_q == S_PROC) begin
                if (engn_cw_len_q != 32'h0000_0000) begin
                    axi_b_state_din = S_PROC;
                    axi_b_num_cmplt_din = {(32-(STRBW_W+BLEN_W)){1'b0}};
                    axi_b_id_exp_din = engn_cw_id_q;
                end
                else begin
                    axi_b_state_din = S_DONE;
                end
            end
            else begin
                axi_b_state_din = S_IDLE;
            end
        end
        else if (axi_b_state_q == S_PROC) begin
            if (axi_b_ready && bvalid_i) begin
                axi_b_num_cmplt_din = axi_b_num_cmplt_q + MAX_BURST_SIZE;
            end
            else begin
            end

            if ((axi_aw_state_q == S_DONE) && (axi_b_num_cmplt_q >= axi_aw_num_issued_q)) begin
                axi_b_state_din = S_DONE;
            end
            else begin
                axi_b_state_din = S_PROC;
            end
        end
        else if (axi_b_state_q == S_DONE) begin
            if (engn_cw_state_q == S_IDLE) begin
                axi_b_state_din = S_IDLE;
                axi_b_num_cmplt_din = {(32-(STRBW_W+BLEN_W)){1'b0}};
                axi_b_id_exp_din = {IDW{1'b0}};
            end
            else begin
                axi_b_state_din = S_DONE;
            end
        end
        else begin
            //Default - exclude from coverage
            axi_b_state_din = S_IDLE;
        end
    end

    always @(posedge clk_gated_w or negedge reset_nai) begin
        if (~reset_nai) begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            axi_b_id_exp_q <= {IDW{1'b0}};
            axi_b_num_cmplt_q <= {(1+(31-(STRBW_W+BLEN_W))){1'b0}};
            axi_b_state_q <= S_IDLE;
            // End of automatics
    end
        else begin
            axi_b_state_q      <= axi_b_state_din;
            axi_b_num_cmplt_q  <= axi_b_num_cmplt_din;
            axi_b_id_exp_q     <= axi_b_id_exp_din;
        end
    end

    assign axi_b_ready = (axi_b_state_q == S_PROC) && (axi_b_num_cmplt_q < axi_aw_num_issued_q);

    assign engn_cw_resp_din = (engn_cw_state_q == S_IDLE) ? 2'd0 :
                              (err_w_parity_o) ? `HSP_AXI_RESP_SLVERR :
                              engn_cw_resp_q[1] ? engn_cw_resp_q :
                              (~(bvalid_i && axi_b_ready)) ? engn_cw_resp_q :
                              (bid_i != axi_b_id_exp_q) ? `HSP_AXI_RESP_SLVERR :
                              bresp_i;

    assign bready_o = axi_b_ready;
    assign engn_cw_done = (axi_w_state_q == S_DONE) && (axi_b_state_q == S_DONE) && (engn_w_state_q == S_DONE);
    assign engn_cw_idle = (axi_w_state_q == S_IDLE) && (axi_b_state_q == S_IDLE) && (engn_w_state_q == S_IDLE);

    /*
     * Engine interface parity logic
     */

    wire [31:0]                       engn_parity_err_r_addr;
    wire [31:0]                       engn_parity_err_w_addr;
    reg [PCHKW-1:0]                   engn_parity_err_chk;

    generate if (ENGN_PARITY_EN == 1)
    begin : gen_ENGN_PARITY
        // Generate engine parity outputs (R channel)
        // Engine should only check parity when data is valid (engn valid and engn accept)
        reg [(DW/32)-1:0] engn_rdatachk;
        always @(*) begin
            // Generate parity for every 32 bits of data
            for (integer i = 0; i < (DW/32); i = i + 1) begin
                engn_rdatachk[i] = ~^engn_rdata_o[i*32 +: 32];
            end
        end
        assign engn_rdatachk_o = engn_rdatachk;

        // Check engine parity inputs (AR, AW, W channel)
        always @(*) begin
            // initial value, some bits will not be overriden, thus are set here
            engn_parity_err_chk = {PCHKW{1'b0}};

            if(!err_parity_chk_disable_i) begin
                //Note: Unlike AXI there is 32b/1b protection on ID and USER on the engine side. Thus the error is mapped to only the LSB of the associated engine err_chk signal
                engn_parity_err_chk[ERR_CHK_ARIDCHK_LSB] = (engn_cread_i && engn_craccept_o) ? (engn_aridchk_i != ~^engn_crid_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_ARLENCHK] = (engn_cread_i && engn_craccept_o) ? (engn_arlenchk_i != ~^engn_crlen_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_ARCTLCHK0] = (engn_cread_i && engn_craccept_o) ? (engn_arprotchk_i != ~^engn_crprot_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_ARUSERCHK_LSB] = (engn_cread_i && engn_craccept_o) ? (engn_aruserchk_i != ~^engn_cruser_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_AWIDCHK_LSB] = (engn_cwrite_i && engn_cwaccept_o) ? (engn_awidchk_i != ~^engn_cwid_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_AWLENCHK] = (engn_cwrite_i && engn_cwaccept_o) ? (engn_awlenchk_i != ~^engn_cwlen_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_AWCTLCHK0] = (engn_cwrite_i && engn_cwaccept_o) ? (engn_awprotchk_i != ~^engn_cwprot_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_AWUSERCHK_LSB] = (engn_cwrite_i && engn_cwaccept_o) ? (engn_awuserchk_i != ~^engn_cwuser_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_ARADDRCHK_LSB] = (engn_cread_i && engn_craccept_o) ? (engn_araddrchk_i != ~^engn_craddr_i) : 1'b0;
                engn_parity_err_chk[ERR_CHK_AWADDRCHK_LSB] = (engn_cwrite_i && engn_cwaccept_o) ? (engn_awaddrchk_i != ~^engn_cwaddr_i) : 1'b0;
                // Check parity for every 32 bits of data
                for (integer i = 0; i < (DW/32); i = i + 1) begin
                    engn_parity_err_chk[ERR_CHK_WDATACHK_LSB+i] = (engn_wvalid_i && engn_waccept_o) ? (engn_wdatachk_i[i] != ~^engn_wdata_i[i*32 +: 32]) : 1'b0;
                end
            end
        end
        assign engn_parity_err[1] = (|engn_parity_err_chk[ERR_CHK_ARUSERCHK_MSB:ERR_CHK_ARIDCHK_LSB]); // parity error during read transaction
        assign engn_parity_err[0] = (|engn_parity_err_chk[ERR_CHK_WDATACHK_MSB:ERR_CHK_AWIDCHK_LSB]); // parity error during write transaction
        assign engn_parity_err_r_addr = engn_parity_err[1] ? engn_craddr_i : 32'h0;
        assign engn_parity_err_w_addr = (|engn_parity_err_chk[ERR_CHK_WDATACHK_MSB:ERR_CHK_WDATACHK_LSB]) ? engn_cw_addr_q :
                                        (|engn_parity_err_chk[ERR_CHK_AWUSERCHK_MSB:ERR_CHK_AWIDCHK_LSB]) ? engn_cwaddr_i :
                                        32'h0;
    end
    else // generate if ENGN_PARITY_EN == 0
    begin : gen_NO_ENGN_PARITY
        // Tie off unused engine parity output ports - engine should not check these parity signals
        assign engn_rdatachk_o = '0;

        assign engn_parity_err = 2'b00;
        assign engn_parity_err_r_addr = 32'h0;
        assign engn_parity_err_w_addr = 32'h0;
        assign engn_parity_err_chk = {PCHKW{1'b0}};
    end
    endgenerate

    /*
     * Internal parity logic. Enabled whenever either AXI or ENGN parity is enabled
     */     
    logic [31:0]                       internal_parity_err_r_addr;
    logic [31:0]                       internal_parity_err_w_addr;
    logic [PCHKW-1:0]                  internal_parity_err_chk;
    
    
    /*
     * Note: Following are future enhancement for parity that are not a SoC architecture requirement for the current version of data/address protection:
     * 
     * 1) Currently parity only protects the internal fields and then detects a mismatch when it gets to the last flop on the AXI side
     * It then uses that mismatch to pull down the AXI valid and issue an error    
     * What it does not protect is corrupted data causing the FSM to make bad transitions and ending up in strange states
     * 
     * 2) The length field (len_rem/len_q) is not covered
     * 
     */
    
    generate if ((AXI_PARITY_EN == 1) || (ENGN_PARITY_EN == 1))
    begin : gen_INTERNAL_PARITY
        // Generate internal parity
        
        //Read address
        logic                     engn_cr_id_chk_q;
        logic                     engn_cr_addr_chk_q;
        logic                     engn_cr_prot_chk_q;
        logic                     engn_cr_user_chk_q;

        //Generate internal parity when a new read is accepted from the engine
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_cr_id_chk_q <= 1'b1;
                engn_cr_addr_chk_q <= 1'b1;
                engn_cr_prot_chk_q <= 1'b1;
                engn_cr_user_chk_q <= 1'b1;
            end
            else begin
                if((engn_cr_state_din == S_PROC) && (engn_cr_state_q != S_PROC)) begin
                    engn_cr_id_chk_q <= ~(^engn_cr_id_din);
                    engn_cr_addr_chk_q <= ~(^engn_cr_addr_din);
                    engn_cr_prot_chk_q <= ~(^engn_cr_prot_din);
                    engn_cr_user_chk_q <= ~(^engn_cr_user_din);
                end
            end
        end
            
        logic axi_ar_addr_chk_din;
        logic axi_ar_addr_chk_q;
        logic axi_ar_id_chk_din;
        logic axi_ar_id_chk_q;
        logic axi_ar_user_chk_din;
        logic axi_ar_user_chk_q;
        logic axi_ar_prot_chk_din;
        logic axi_ar_prot_chk_q;
        
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                axi_ar_addr_chk_q <= 1'b1;
                axi_ar_id_chk_q <= 1'b1;
                axi_ar_user_chk_q <= 1'b1;
                axi_ar_prot_chk_q <= 1'b1;
            end
            else begin
                axi_ar_addr_chk_q <= axi_ar_addr_chk_din;
                axi_ar_id_chk_q <= axi_ar_id_chk_din;
                axi_ar_user_chk_q <= axi_ar_user_chk_din;
                axi_ar_prot_chk_q <= axi_ar_prot_chk_din;
            end
        end
        
        always_comb begin
            axi_ar_addr_chk_din = axi_ar_addr_chk_q;
            axi_ar_id_chk_din = axi_ar_id_chk_q;
            axi_ar_user_chk_din = axi_ar_user_chk_q;
            axi_ar_prot_chk_din = axi_ar_prot_chk_q;
            
            //New engine read transaction
            if((axi_ar_state_q == S_IDLE) && (engn_cr_state_q == S_PROC) && (engn_cr_len_q != 32'h0000_0000)) begin
                axi_ar_addr_chk_din = ~(^axi_ar_addr_din);
                axi_ar_id_chk_din = engn_cr_id_chk_q;
                axi_ar_user_chk_din = engn_cr_user_chk_q;
                axi_ar_prot_chk_din = engn_cr_prot_chk_q;
            end
            //New AXI read transaction for previous engine read request
            else if((axi_ar_state_q == S_PROC) && axi_ar_issue) begin
                axi_ar_addr_chk_din = ~(^axi_ar_addr_din);               
            end
        end
        
        //Write address
        logic                     engn_cw_id_chk_q;
        logic                     engn_cw_addr_chk_q;
        logic                     engn_cw_prot_chk_q;
        logic                     engn_cw_user_chk_q;

        //Generate internal parity when a new read is accepted from the engine
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_cw_id_chk_q <= 1'b1;
                engn_cw_addr_chk_q <= 1'b1;
                engn_cw_prot_chk_q <= 1'b1;
                engn_cw_user_chk_q <= 1'b1;
            end
            else begin
                if((engn_cw_state_din == S_PROC) && (engn_cw_state_q != S_PROC)) begin
                    engn_cw_id_chk_q <= ~(^engn_cw_id_din);
                    engn_cw_addr_chk_q <= ~(^engn_cw_addr_din);
                    engn_cw_prot_chk_q <= ~(^engn_cw_prot_din);
                    engn_cw_user_chk_q <= ~(^engn_cw_user_din);
                end
            end
        end
            
        logic axi_aw_addr_chk_din;
        logic axi_aw_addr_chk_q;
        logic axi_aw_id_chk_din;
        logic axi_aw_id_chk_q;
        logic axi_aw_user_chk_din;
        logic axi_aw_user_chk_q;
        logic axi_aw_prot_chk_din;
        logic axi_aw_prot_chk_q;
        
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                axi_aw_addr_chk_q <= 1'b1;
                axi_aw_id_chk_q <= 1'b1;
                axi_aw_user_chk_q <= 1'b1;
                axi_aw_prot_chk_q <= 1'b1;
            end
            else begin
                axi_aw_addr_chk_q <= axi_aw_addr_chk_din;
                axi_aw_id_chk_q <= axi_aw_id_chk_din;
                axi_aw_user_chk_q <= axi_aw_user_chk_din;
                axi_aw_prot_chk_q <= axi_aw_prot_chk_din;
            end
        end
        
        always_comb begin
            axi_aw_addr_chk_din = axi_aw_addr_chk_q;
            axi_aw_id_chk_din = axi_aw_id_chk_q;
            axi_aw_user_chk_din = axi_aw_user_chk_q;
            axi_aw_prot_chk_din = axi_aw_prot_chk_q;
            
            //New engine write transaction
            if((axi_aw_state_q == S_IDLE) && (engn_cw_state_q == S_PROC) && (engn_cw_len_q != 32'h0000_0000)) begin
                axi_aw_addr_chk_din = ~(^axi_aw_addr_din);
                axi_aw_id_chk_din = engn_cw_id_chk_q;
                axi_aw_user_chk_din = engn_cw_user_chk_q;
                axi_aw_prot_chk_din = engn_cw_prot_chk_q;
            end
            //New AXI write transaction for previous engine write request
            else if((axi_aw_state_q == S_PROC) && axi_aw_issue) begin
                axi_aw_addr_chk_din = ~(^axi_aw_addr_din);               
            end
        end
        
        //Write data
        logic [((2*DW)/32)-1:0] engn_w_align_chk_din;
        logic [((2*DW)/32)-1:0] engn_w_align_chk_q;        
        
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_w_align_chk_q <= '1;
            end
            else begin
                engn_w_align_chk_q <= engn_w_align_chk_din;
            end
        end
        
        always_comb begin
            for (integer i = 0; i < ((2*DW)/32); i = i + 1) begin
                engn_w_align_chk_din[i] = ~(^engn_w_align_din[i*32 +: 32]);
            end
        end
        
        logic [(DW/32)-1:0]           dw_end_set_chk;
        logic [(DW/32)-1:0]           dw_chk_fifo_din [0:DFD-1];
        logic [(DW/32)-1:0]           dw_chk_fifo_q   [0:DFD-1];
        logic [(DW/32)-1:0]           dw_start_get_chk;

        assign dw_end_set_chk = engn_w_align_chk_q[0];
        
        always_comb begin
            for (integer i = 0; i < DFD; i = i + 1) begin
                if (i == dw_end_q) begin
                    dw_chk_fifo_din[i] = dw_end_advance ? dw_end_set_chk :
                                         dw_chk_fifo_q[i];
                end
                else begin
                    dw_chk_fifo_din[i] = dw_chk_fifo_q[i];
                end
            end
        end

        always @(posedge clk_gated_w or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                for (i = 0; i < DFD; i = i + 1) begin
                    dw_chk_fifo_q[i] <= {(DW/32){1'b1}};
                end
            end
            else begin
                for (i = 0; i < DFD; i = i + 1) begin
                    dw_chk_fifo_q[i] <= dw_chk_fifo_din[i];
                end
            end
        end

        assign dw_start_get_chk = (dw_entries_q == {DFDP1_W{1'b0}}) ? dw_chk_fifo_din[dw_start_q] : dw_chk_fifo_q[dw_start_q];
               
        //Write response
        logic                         engn_cw_resp_chk_q;        
        
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_cw_resp_chk_q <= 1'b1;
            end
            else begin
                engn_cw_resp_chk_q <= ~(^engn_cw_resp_din);
            end
        end
        
        //Read responses
        logic                         engn_cr_resp_chk_q;        
        
        always @(posedge clk_i or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_cr_resp_chk_q <= 1'b1;
            end
            else begin
                engn_cr_resp_chk_q <= ~(^engn_cr_resp_din);
            end
        end
        
        //Read data
        logic [(DW/32)-1:0]           dr_end_set_chk;
        logic [(DW/32)-1:0]           dr_chk_fifo_din [0:DFD-1];
        logic [(DW/32)-1:0]           dr_chk_fifo_q   [0:DFD-1];
        logic [(DW/32)-1:0]           dr_start_get_chk;

        always_comb begin
            for (integer i = 0; i < (DW/32); i = i + 1) begin
                dr_end_set_chk[i] = ~(^dr_end_set[i*32 +: 32]);
            end
        end
        
        always_comb begin
            for (integer i = 0; i < DFD; i = i + 1) begin
                if (i == dr_end_q) begin
                    dr_chk_fifo_din[i] = dr_end_advance ? dr_end_set_chk :
                                         dr_chk_fifo_q[i];
                end
                else begin
                    dr_chk_fifo_din[i] = dr_chk_fifo_q[i];
                end
            end
        end

        always @(posedge clk_gated_r or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                for (i = 0; i < DFD; i = i + 1) begin
                    dr_chk_fifo_q[i] <= {(DW/32){1'b1}};
                end
            end
            else begin
                for (i = 0; i < DFD; i = i + 1) begin
                    dr_chk_fifo_q[i] <= dr_chk_fifo_din[i];
                end
            end
        end

        assign dr_start_get_chk = (dr_entries_q == {DFDP1_W{1'b0}}) ? dr_chk_fifo_din[dr_start_q] : dr_chk_fifo_q[dr_start_q];
               
        logic [(DW/32)-1:0]    engn_r_align_chk_din;
        logic [(DW/32)-1:0]    engn_r_align_chk_q;

        always @(*) begin
            // Only generate parity on ralign [DW-1:0] since that is what is used for engn rdata
            for (integer i = 0; i < (DW/32); i = i + 1) begin
                engn_r_align_chk_din[i] = ~^engn_r_align_din[i*32 +: 32];
            end
        end

        always @(posedge clk_gated_r or negedge reset_nai) begin
            if (~reset_nai) begin
                // On reset, signals are set to 0, so odd parity should be 1
                engn_r_align_chk_q <= {(DW/32){1'b1}};
            end
            else begin
                engn_r_align_chk_q <= engn_r_align_chk_din;
            end
        end
        
        //Parity check
        always_comb begin
            // initial value, some bits will not be overridden, thus are set here
            internal_parity_err_chk = {PCHKW{1'b0}};

            if(!err_parity_chk_disable_i) begin
                //Outgoing transaction -> check parity when it is on the last flop and being driven to the AXI interface
                internal_parity_err_chk[ERR_CHK_ARIDCHK_LSB] = ((axi_ar_state_q == S_PROC) && (axi_ar_len_ext <= dr_free_q)) ? (axi_ar_id_chk_q != ~(^axi_ar_id_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_ARCTLCHK0] = ((axi_ar_state_q == S_PROC) && (axi_ar_len_ext <= dr_free_q)) ? (axi_ar_prot_chk_q != ~(^axi_ar_prot_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_ARUSERCHK_LSB] = ((axi_ar_state_q == S_PROC) && (axi_ar_len_ext <= dr_free_q)) ? (axi_ar_user_chk_q != ~(^axi_ar_user_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_ARADDRCHK_LSB] = ((axi_ar_state_q == S_IDLE) && (engn_cr_state_q == S_PROC) && (engn_cr_len_q != 32'h0000_0000)) ? (engn_cr_addr_chk_q != ~(^engn_cr_addr_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_ARADDRCHK_LSB+1] = ((axi_ar_state_q == S_PROC) && (axi_ar_len_ext <= dr_free_q)) ? (axi_ar_addr_chk_q != ~(^axi_ar_addr_q)) : 1'b0;
                
                internal_parity_err_chk[ERR_CHK_AWIDCHK_LSB] = ((axi_aw_state_q == S_PROC) && (~engn_w_first_q) && (axi_aw_len_ext <= dw_free_q)) ? (axi_aw_id_chk_q != ~(^axi_aw_id_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_AWCTLCHK0] = ((axi_aw_state_q == S_PROC) && (~engn_w_first_q) && (axi_aw_len_ext <= dw_free_q)) ? (axi_aw_prot_chk_q != ~(^axi_aw_prot_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_AWUSERCHK_LSB] = ((axi_aw_state_q == S_PROC) && (~engn_w_first_q) && (axi_aw_len_ext <= dw_free_q)) ? (axi_aw_user_chk_q != ~(^axi_aw_user_q)) : 1'b0;                    
                internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB] = ((axi_aw_state_q == S_IDLE) && (engn_cw_state_q == S_PROC) && (engn_cw_len_q != 32'h0000_0000)) ? (engn_cw_addr_chk_q != ~(^engn_cw_addr_q)) : 1'b0;
                internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB+1] = ((axi_aw_state_q == S_PROC) && (~engn_w_first_q) && (axi_aw_len_ext <= dw_free_q)) ? (axi_aw_addr_chk_q != ~(^axi_aw_addr_q)) : 1'b0;
    
                internal_parity_err_chk[ERR_CHK_WDATACHK_MSB] = (engn_w_state_q == S_PROC) ? (engn_w_align_chk_q[1] != ~(^engn_w_align_q[(2*DW)-1:DW])) : 1'b0;
                for (integer i = 0; i < (DW/32); i = i + 1) begin
                    internal_parity_err_chk[ERR_CHK_WDATACHK_MSB] = (engn_w_state_q == S_PROC) ? (engn_w_align_chk_q[(DW/32) + i] != ~(^engn_w_align_q[(DW + (i*32)) +: 32])) : 1'b0;
                    internal_parity_err_chk[ERR_CHK_WDATACHK_LSB+i] = ((axi_w_state_q == S_PROC) && axi_w_cwstate_q && (~engn_wstop_req_synced) && (~axi_w_suberr_q) && (axi_w_num_cmplt_q < axi_aw_num_issued_q)) ? (dw_start_get_chk[i] != ~(^dw_start_get[i*32 +: 32])) : 1'b0;
                end
                
                //Incoming read parity, check on last flop on engine side, plus flop before read align since this modifies the data
                for (integer i = 0; i < (DW/32); i = i + 1) begin
                    if((engn_r_state_q == S_PROC) && (!engn_cr_error) && engn_r_fifo_valid && (engn_r_first_q || (~engn_r_valid_q) || engn_raccept_i)) begin
                        internal_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = (dr_start_get_chk[i] != ~(^dr_start_get[i*32 +: 32]));
                    end
                    else if (engn_r_valid_q && (!engn_cr_error) && (!engn_cr_resp_q[1])) begin
                        internal_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = (engn_r_align_chk_q[i] != ~(^engn_r_align_q[i*32 +: 32]));                        
                    end
                    else begin
                        internal_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = 1'b0;
                    end
                end
    
                internal_parity_err_chk[ERR_CHK_RRESPCHK] = engn_cr_valid ? (engn_cr_resp_chk_q != ~(^engn_cr_resp_q)) : 1'b0;
                
                internal_parity_err_chk[ERR_CHK_BRESPCHK] = engn_cw_valid ? (engn_cw_resp_chk_q != ~(^engn_cw_resp_q)) : 1'b0;
            end
            internal_parity_err[1] = (|internal_parity_err_chk[ERR_CHK_RLASTCHK:ERR_CHK_ARIDCHK_LSB]); // parity error during read transaction
            internal_parity_err[0] = (|internal_parity_err_chk[ERR_CHK_BRESPCHK:ERR_CHK_AWIDCHK_LSB]); // parity error during write transaction
            internal_parity_err_r_addr = internal_parity_err[1] ? engn_cr_addr_q : 32'h0;
            internal_parity_err_w_addr = internal_parity_err[0] ? engn_cw_addr_q : 32'h0;  
        end
    end
    else // generate if both AXI_PARITY_EN == 0 and ENGN_PARITY_EN == 0
    begin : gen_NO_INTERNAL_PARITY
        assign internal_parity_err = 2'b00;
        assign internal_parity_err_r_addr = 32'h0;
        assign internal_parity_err_w_addr = 32'h0;
        assign internal_parity_err_chk = {PCHKW{1'b0}};
    end
    endgenerate   

    /*
     * AXI interface parity logic
     */

    wire [31:0]                       axi_parity_err_r_addr;
    wire [31:0]                       axi_parity_err_w_addr;
    reg [PCHKW-1:0]                   axi_parity_err_chk;

    generate if (AXI_PARITY_EN == 1)
    begin : gen_AXI_PARITY

        // Generate AXI parity output signals
        
        logic [PIDW-1:0]    axi_ar_id_chk;
        logic [3:0]         axi_ar_addr_chk;
        logic               axi_ar_ctlchk0_chk;
        logic [PENGNUW-1:0] axi_ar_user_chk;
        
        always_comb begin
            axi_ar_ctlchk0_chk = ~^{arsize_o,arburst_o,arlock_o,arprot_o};

            // Generate parity for every 8 bits of address, ID, and USER
            for (integer i = 0; i < PIDW; i = i + 1) begin
                if(i == (PIDW-1)) begin
                    axi_ar_id_chk[i] = ~^arid_o[(IDW-1):((PIDW-1)*8)];
                end
                else begin
                    axi_ar_id_chk[i] = ~^arid_o[i*8 +: 8];
                end
            end

            for (integer i = 0; i < 4; i = i + 1) begin
                axi_ar_addr_chk[i] = ~^araddr_o[i*8 +: 8];
            end

            for (integer i = 0; i < PENGNUW; i = i + 1) begin
                if(i == (PENGNUW-1)) begin
                    axi_ar_user_chk[i] = ~^aruser_o[(ENGNUW-1):((PENGNUW-1)*8)];
                end
                else begin
                    axi_ar_user_chk[i] = ~^aruser_o[i*8 +: 8];
                end
            end
        end
       
        logic [PIDW-1:0]    axi_aw_id_chk;
        logic [3:0]         axi_aw_addr_chk;
        logic               axi_aw_ctlchk0_chk;
        logic [PENGNUW-1:0] axi_aw_user_chk;
        logic [PDW-1:0]     axi_w_data_chk;


        always_comb begin
            axi_aw_ctlchk0_chk = ~^{awsize_o,awburst_o,awlock_o,awprot_o};

            // Generate parity for every 8 bits of address, ID, and USER
            for (integer i = 0; i < PIDW; i = i + 1) begin
                if(i == (PIDW-1)) begin
                    axi_aw_id_chk[i] = ~^awid_o[(IDW-1):((PIDW-1)*8)];
                end
                else begin
                    axi_aw_id_chk[i] = ~^awid_o[i*8 +: 8];
                end
            end

            for (integer i = 0; i < 4; i = i + 1) begin
                axi_aw_addr_chk[i] = ~^awaddr_o[i*8 +: 8];
            end

            for (integer i = 0; i < PENGNUW; i = i + 1) begin
                if(i == (PENGNUW-1)) begin
                    axi_aw_user_chk[i] = ~^awuser_o[(ENGNUW-1):((PENGNUW-1)*8)];
                end
                else begin
                    axi_aw_user_chk[i] = ~^awuser_o[i*8 +: 8];
                end
            end
            
            for (integer i = 0; i < (DW/8); i = i + 1) begin
                axi_w_data_chk[i] = ~^wdata_o[i*8 +: 8];
            end
        end
        
        assign aruser_o[ARUSER_ARIDCHK_MSB:ARUSER_ARIDCHK_LSB] = axi_ar_id_chk;
        assign aruser_o[ARUSER_ARADDRCHK_MSB:ARUSER_ARADDRCHK_LSB] = axi_ar_addr_chk;
        assign aruser_o[ARUSER_ARLENCHK] = ~^arlen_o;
        assign aruser_o[ARUSER_ARCTLCHK0] = axi_ar_ctlchk0_chk;
        assign aruser_o[ARUSER_ARUSERCHK_MSB:ARUSER_ARUSERCHK_LSB] = axi_ar_user_chk;

        assign awuser_o[AWUSER_AWIDCHK_MSB:AWUSER_AWIDCHK_LSB] = axi_aw_id_chk;
        assign awuser_o[AWUSER_AWADDRCHK_MSB:AWUSER_AWADDRCHK_LSB] = axi_aw_addr_chk;
        assign awuser_o[AWUSER_AWLENCHK] = ~^awlen_o;
        assign awuser_o[AWUSER_AWCTLCHK0] = axi_aw_ctlchk0_chk;
        assign awuser_o[AWUSER_AWUSERCHK_MSB:AWUSER_AWUSERCHK_LSB] = axi_aw_user_chk;

        assign wuser_o[WUSER_WDATACHK_MSB:WUSER_WDATACHK_LSB] = axi_w_data_chk;
        assign wuser_o[WUSER_WSTRBCHK_MSB:WUSER_WSTRBCHK_LSB] = ~^wstrb_o; //Does not scale beyond 64 bits of data, should be in a loop
        assign wuser_o[WUSER_WLASTCHK] = ~^wlast_o;

        // Check AXI parity input signals

        // AXI parity check input signals
        wire [PIDW-1:0] axi_b_id_chk = buser_i[BUSER_BIDCHK_MSB:BUSER_BIDCHK_LSB];
        wire axi_b_resp_chk = buser_i[BUSER_BRESPCHK];

        wire [PIDW-1:0] axi_r_id_chk = ruser_i[RUSER_RIDCHK_MSB:RUSER_RIDCHK_LSB];
        wire [PDW-1:0] axi_r_data_chk = ruser_i[RUSER_RDATACHK_MSB:RUSER_RDATACHK_LSB];
        wire axi_r_resp_chk = ruser_i[RUSER_RRESPCHK];
        wire axi_r_last_chk = ruser_i[RUSER_RLASTCHK];

        always @(*) begin
            // initial value, some bits will not be overridden, thus are set here
            axi_parity_err_chk = {PCHKW{1'b0}};

            // Check AXI parity inputs
            if(!err_parity_chk_disable_i) begin
                for (integer i = 0; i < PIDW; i = i + 1) begin
                    if(i == (PIDW-1)) begin
                        axi_parity_err_chk[ERR_CHK_BIDCHK_MSB] = (bvalid_i && bready_o) ? (axi_b_id_chk[PIDW-1] != ~^bid_i[(IDW-1):((PIDW-1)*8)]) : 1'b0;
                        axi_parity_err_chk[ERR_CHK_RIDCHK_MSB] = (rvalid_i && rready_o) ? (axi_r_id_chk[PIDW-1] != ~^rid_i[(IDW-1):((PIDW-1)*8)]) : 1'b0;
                    end
                    else begin
                        axi_parity_err_chk[ERR_CHK_BIDCHK_LSB+i] = (bvalid_i && bready_o) ? (axi_b_id_chk[i] != ~^bid_i[i*8 +: 8]) : '0;
                        axi_parity_err_chk[ERR_CHK_RIDCHK_LSB+i] = (rvalid_i && rready_o) ? (axi_r_id_chk[i] != ~^rid_i[i*8 +: 8]) : '0;
                    end
                end
                axi_parity_err_chk[ERR_CHK_BRESPCHK] = (bvalid_i && bready_o) ? (axi_b_resp_chk != ~^bresp_i) : 1'b0;
                
                for (integer i = 0; i < PDW; i = i + 1) begin
                    axi_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = (rvalid_i && rready_o) ? (axi_r_data_chk[i] != ~^rdata_i[i*8 +: 8]) : '0;
                end
                axi_parity_err_chk[ERR_CHK_RRESPCHK] = (rvalid_i && rready_o) ? (axi_r_resp_chk != ~^rresp_i) : 1'b0;
                axi_parity_err_chk[ERR_CHK_RLASTCHK] = (rvalid_i && rready_o) ? (axi_r_last_chk != ~^rlast_i) : 1'b0;
            end
        end

        assign axi_parity_err[1] = (|axi_parity_err_chk[ERR_CHK_RLASTCHK:ERR_CHK_ARIDCHK_LSB]); // parity error during read transaction
        assign axi_parity_err[0] = (|axi_parity_err_chk[ERR_CHK_BRESPCHK:ERR_CHK_AWIDCHK_LSB]); // parity error during write transaction
        // Check if parity error occurred with read or write transaction
        assign axi_parity_err_r_addr = axi_parity_err[1] ? araddr_o : 32'h0;
        assign axi_parity_err_w_addr = axi_parity_err[0] ? awaddr_o : 32'h0;
    end
    else // generate if AXI_PARITY_EN == 0
    begin : gen_NO_AXI_PARITY
        // Tie off unused AXI parity output ports - AXI subordinate should not check these parity signals
        if(ARUW > ENGNUW) begin         // ARUW and AWUW are always same
            assign aruser_o[ARUW-1:ENGNUW] = {(ARUW-ENGNUW){1'b0}};
            assign awuser_o[AWUW-1:ENGNUW] = {(AWUW-ENGNUW){1'b0}};
        end

        assign wuser_o = {WUW{1'b0}};

        assign axi_parity_err = 2'b00;
        assign axi_parity_err_r_addr = 32'h0;
        assign axi_parity_err_w_addr = 32'h0;
        assign axi_parity_err_chk = {PCHKW{1'b0}};
    end
    endgenerate

 
    // Side channel parity error signals
    assign err_w_parity_o = engn_parity_err[0] | axi_parity_err[0] | internal_parity_err[0];
    assign err_r_parity_o = engn_parity_err[1] | axi_parity_err[1] | internal_parity_err[1];
    assign err_parity_o   = err_r_parity_o | err_w_parity_o;
    assign err_r_addr_o   = (axi_parity_err[1]  ? axi_parity_err_r_addr : // Want axi parity error to have priority since it will represent the earlier beat
                             internal_parity_err[1] ? internal_parity_err_r_addr :
                             engn_parity_err[1] ? engn_parity_err_r_addr :
                             32'h0);
    assign err_w_addr_o   = (axi_parity_err[0] ? axi_parity_err_w_addr : // Want axi parity error to have priority since it will represent the earlier beat
                             internal_parity_err[0] ? internal_parity_err_w_addr :
                             engn_parity_err[0] ? engn_parity_err_w_addr :
                             32'h0);
    assign err_chk_o      = engn_parity_err_chk | axi_parity_err_chk | internal_parity_err_chk;


    // Clock gating enables defined at end because they rely on signals defined
    // throughout code
    assign cg_read_en_din  = (engn_cr_state_din == S_PROC) ? 1'b1 :
                             (engn_cr_state_q == S_IDLE) ? 1'b0 :
                             cg_read_en_q;
    assign cg_write_en_din = (engn_cw_state_din == S_PROC) ? 1'b1 :
                             (engn_cw_state_q == S_IDLE) ? 1'b0 :
                             cg_write_en_q;

    /*AUTOTIEOFF*/

    ////////////////////////////////
    // Assertions
    ////////////////////////////////

  `ifdef MSFT_ABV
        `include "axi_mgr_assert.sv"
    `endif

endmodule

`include "msft_axi_undefs.vh"
