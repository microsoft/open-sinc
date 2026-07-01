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
// File          : axi_sub.v
// Description   : convert AXI subordinate interface to a register interface,
//               : each register access is done in one clock cycle
//               : accesses can be stalled by the engine

`include "hsp_axi.vh"

module axi_sub #(
    parameter ENGN_PARITY_EN = 0, // Enables AXI subordinate to generate and check parity on the engine interface signals
    parameter AXI_PARITY_EN = `MSFT_AXI_PARITY_EN, // Enables AXI subordinate to generate and check parity on the AXI interface signals
    parameter DFD = 1, // Data fifo depth - if <=BLEN, CFD should be set to 1
    parameter CFD = 1, // Control fifo depth
    parameter BLEN = 16, // Maximum burst length (must be <=256)
    parameter DW = `HSP_AXI_SLV_DWIDTH, // AXI data width
    parameter IDW = `HSP_AXI_SLV_ID_WIDTH, // AXI ID width
    parameter MIDW = `HSP_AXI_MST_ID_WIDTH, // AXI ID width on manager side (before fabric ID insertion)
    parameter ENGNUW = `MSFT_AXI_SLV_ENGNU_WIDTH, // AXI Engine AxUSER width - used for AxUSER bits from engine (not including parity)
    parameter ARUW = `MSFT_AXI_SLV_ARU_WIDTH, // AXI ARUSER width
    parameter AWUW = `MSFT_AXI_SLV_AWU_WIDTH, // AXI AWUSER width
    parameter WUW = `MSFT_AXI_SLV_WU_WIDTH, // AXI WUSER width
    parameter RUW = `MSFT_AXI_SLV_RU_WIDTH, // AXI RUSER width
    parameter BUW = `MSFT_AXI_SLV_BU_WIDTH, // AXI BUSER width
    parameter LW = `HSP_AXI_LOCK_BITS // AXI A*LOCK width
)(
    /*AUTOARG*/
   // Outputs
   awready_o, wready_o, bid_o, bresp_o, buser_o, bvalid_o, arready_o, rid_o,
   rdata_o, rresp_o, rlast_o, ruser_o, rvalid_o, engn_ren_o, engn_wen_o,
   engn_addr_o, engn_wdata_o, engn_wstrb_o, engn_id_o, engn_user_o,
   engn_idchk_o, engn_addrchk_o, engn_wdatachk_o, engn_wstrbchk_o, engn_userchk_o,
   chk_addr_o, chk_id_o, chk_user_o, chk_read_o, chk_write_o, chk_en_o,
   chk_size_o, chk_prot_o, chk_len_o, chk_burst_o, chk_wdata_o,
   chk_wstrb_o, chk_last_o, chk_idchk_o, chk_addrchk_o,
   chk_lenchk_o, chk_sizechk_o, chk_burstchk_o, chk_protchk_o,
   chk_wdatachk_o, chk_wstrbchk_o, chk_lastchk_o, chk_userchk_o,
   clock_gate_en_o, err_parity_o, err_r_parity_o, err_w_parity_o,
   err_r_addr_o, err_w_addr_o, err_chk_o,
   // Inputs
   clk_i, reset_nai, awid_i, awuser_i, awaddr_i, awlen_i, awsize_i,
   awprot_i, awburst_i, awlock_i, awvalid_i, wdata_i, wstrb_i, wlast_i,
   wuser_i, wvalid_i, bready_i, arid_i, aruser_i, araddr_i, arlen_i, arsize_i,
   arprot_i, arburst_i, arlock_i, arvalid_i, rready_i, engn_r_rdy_i,
   engn_w_rdy_i, engn_rdata_i, engn_r_err_i, engn_w_err_i, engn_rdatachk_i,
   chk_r_rdy_i, chk_w_rdy_i, chk_valid_r_i, chk_invalid_r_i,
   chk_valid_w_i, chk_invalid_w_i, clkg_test_mode_i, clkg_override_i,
   err_parity_chk_disable_i
   );

   localparam STRBW = DW/8;
   localparam LENW = $clog2(BLEN);
    
    // Parity check error parameters
    // The error check signal indicates which parity check signal(s) failed, indexed as follows:
    localparam PIDW                     = (MIDW + 7)/8;
    localparam PDW                      = (DW + 7)/8;
    localparam PSTRBW                   = (DW + 63)/64;
    localparam PENGNUW                  = (ENGNUW + 7)/8;

    localparam ERR_CHK_AWIDCHK_LSB      = 0;
    localparam ERR_CHK_AWIDCHK_MSB      = (ERR_CHK_AWIDCHK_LSB + PIDW) - 1;
    localparam ERR_CHK_AWADDRCHK_LSB    = ERR_CHK_AWIDCHK_MSB + 1;
    localparam ERR_CHK_AWADDRCHK_MSB    = (ERR_CHK_AWADDRCHK_LSB + 4) - 1;
    localparam ERR_CHK_AWLENCHK         = ERR_CHK_AWADDRCHK_MSB + 1;
    localparam ERR_CHK_AWCTLCHK0        = ERR_CHK_AWLENCHK + 1;
    localparam ERR_CHK_AWUSERCHK_LSB    = ERR_CHK_AWCTLCHK0 + 1;
    localparam ERR_CHK_AWUSERCHK_MSB    = (ERR_CHK_AWUSERCHK_LSB + PENGNUW) - 1;

    localparam ERR_CHK_WDATACHK_LSB     = ERR_CHK_AWUSERCHK_MSB + 1;
    localparam ERR_CHK_WDATACHK_MSB     = (ERR_CHK_WDATACHK_LSB + PDW) - 1;
    localparam ERR_CHK_WSTRBCHK_LSB     = ERR_CHK_WDATACHK_MSB + 1;
    localparam ERR_CHK_WSTRBCHK_MSB     = (ERR_CHK_WSTRBCHK_LSB + PSTRBW) - 1;
    localparam ERR_CHK_WLASTCHK         = ERR_CHK_WSTRBCHK_MSB + 1;

    localparam ERR_CHK_BIDCHK_LSB       = ERR_CHK_WLASTCHK + 1;
    localparam ERR_CHK_BIDCHK_MSB       = (ERR_CHK_BIDCHK_LSB + PIDW) - 1;
    localparam ERR_CHK_BRESPCHK         = ERR_CHK_BIDCHK_MSB + 1;

    localparam ERR_CHK_ARIDCHK_LSB      = ERR_CHK_BRESPCHK + 1;
    localparam ERR_CHK_ARIDCHK_MSB      = (ERR_CHK_ARIDCHK_LSB + PIDW) - 1;
    localparam ERR_CHK_ARADDRCHK_LSB    = ERR_CHK_ARIDCHK_MSB + 1;
    localparam ERR_CHK_ARADDRCHK_MSB    = (ERR_CHK_ARADDRCHK_LSB + 4) - 1;
    localparam ERR_CHK_ARLENCHK         = ERR_CHK_ARADDRCHK_MSB + 1;
    localparam ERR_CHK_ARCTLCHK0        = ERR_CHK_ARLENCHK + 1;
    localparam ERR_CHK_ARUSERCHK_LSB    = ERR_CHK_ARCTLCHK0 + 1;
    localparam ERR_CHK_ARUSERCHK_MSB    = (ERR_CHK_ARUSERCHK_LSB + PENGNUW) - 1;

    localparam ERR_CHK_RIDCHK_LSB       = ERR_CHK_ARUSERCHK_MSB + 1;
    localparam ERR_CHK_RIDCHK_MSB       = (ERR_CHK_RIDCHK_LSB + PIDW) - 1;
    localparam ERR_CHK_RDATACHK_LSB     = ERR_CHK_RIDCHK_MSB + 1;
    localparam ERR_CHK_RDATACHK_MSB     = (ERR_CHK_RDATACHK_LSB + PDW) - 1;
    localparam ERR_CHK_RRESPCHK         = ERR_CHK_RDATACHK_MSB + 1;
    localparam ERR_CHK_RLASTCHK         = ERR_CHK_RRESPCHK + 1;
    localparam PCHKW = (AXI_PARITY_EN | ENGN_PARITY_EN) ? ((ARUW - ENGNUW) + (AWUW - ENGNUW) + WUW + RUW + BUW) : (ERR_CHK_BRESPCHK - ERR_CHK_AWIDCHK_LSB);

    localparam EPDW = (DW+31)/32; //Engine data parity width
        
input               clk_i;
input               reset_nai;
// signals from and to axi interface
input  [IDW-1:0]    awid_i;
input  [AWUW-1:0]   awuser_i;
input  [31:0]       awaddr_i;
input  [7:0]        awlen_i;
input  [2:0]        awsize_i;
input  [2:0]        awprot_i;
input  [1:0]        awburst_i;
input  [LW-1:0]     awlock_i;
input               awvalid_i;
output              awready_o;

input  [DW-1:0]     wdata_i;
input  [STRBW-1:0]  wstrb_i;
input               wlast_i; // SUBERR if this is not asserted properly
input  [WUW-1:0]    wuser_i;
input               wvalid_i;
output              wready_o;

output [IDW-1:0]    bid_o;
output [1:0]        bresp_o;
output [BUW-1:0]    buser_o;
output              bvalid_o;
input               bready_i;

input  [IDW-1:0]    arid_i;
input  [ARUW-1:0]   aruser_i;
input  [31:0]       araddr_i;
input  [7:0]        arlen_i;
input  [2:0]        arsize_i;
input  [2:0]        arprot_i;
input  [1:0]        arburst_i;
input  [LW-1:0]     arlock_i;
input               arvalid_i;
output              arready_o;

output [IDW-1:0]    rid_o;
output [DW-1:0]     rdata_o;
output [1:0]        rresp_o;
output              rlast_o;
output [RUW-1:0]    ruser_o;
output              rvalid_o;
input               rready_i;
// signals from and to crypto engine
input               engn_r_rdy_i;
input               engn_w_rdy_i;
output              engn_ren_o;
output              engn_wen_o;
output [31:0]       engn_addr_o;
input  [DW-1:0]     engn_rdata_i;
input               engn_r_err_i;
input               engn_w_err_i;
output [DW-1:0]     engn_wdata_o;
output [STRBW-1:0]  engn_wstrb_o;
output [IDW-1:0]    engn_id_o;
output [ENGNUW-1:0] engn_user_o;

output              engn_idchk_o;
output              engn_addrchk_o;
input [(DW/32)-1:0]  engn_rdatachk_i;
output [(DW/32)-1:0] engn_wdatachk_o;
output              engn_wstrbchk_o;
output              engn_userchk_o;

// signals from and to access checker
input               chk_r_rdy_i;
input               chk_w_rdy_i;
output [31:0]       chk_addr_o;
output [IDW-1:0]    chk_id_o;
output [ENGNUW-1:0] chk_user_o;
output              chk_read_o;
output              chk_write_o;
output              chk_en_o;
output [2:0]        chk_size_o;
output [2:0]        chk_prot_o;
output [LENW-1:0]   chk_len_o;
output [1:0]        chk_burst_o;
output [DW-1:0]     chk_wdata_o;
output [STRBW-1:0]  chk_wstrb_o;
output              chk_last_o;

input               chk_valid_r_i;
input               chk_invalid_r_i;
input               chk_valid_w_i;
input               chk_invalid_w_i;

output              chk_idchk_o;
output              chk_addrchk_o;
output              chk_lenchk_o;
output              chk_sizechk_o;
output              chk_burstchk_o;
output              chk_protchk_o;
output [(DW/32)-1:0] chk_wdatachk_o;
output              chk_wstrbchk_o;
output              chk_lastchk_o;
output              chk_userchk_o;

// signals from and to control registers
output              err_parity_o;
output              err_r_parity_o;
output              err_w_parity_o;
output [31:0]       err_r_addr_o;
output [31:0]       err_w_addr_o;
output [PCHKW-1:0]  err_chk_o;

// pervasive
output              clock_gate_en_o;
input               clkg_test_mode_i;
input               clkg_override_i;
input               err_parity_chk_disable_i;

/*
* Gated Clock for data domain
*/

wire cg_read_en_din;
reg  cg_read_en_q;
wire cg_write_en_din;
reg  cg_write_en_q;
wire clkg_read_en;
wire clkg_write_en;
wire clkg_arb_en;

wire clk_gated_r;
wire clk_gated_w;
wire clk_gated_a;

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

// Enable signals for clock gates
assign clkg_read_en  = cg_read_en_din || cg_read_en_q;
assign clkg_write_en = cg_write_en_din || cg_write_en_q;
assign clkg_arb_en   = cg_read_en_din || cg_read_en_q || cg_write_en_din || cg_write_en_q;

c_clock_gate_ovr clock_gate_read (
    .clk        (clk_i),
    .enable     (clkg_read_en),
    .ovr_en     (clkg_override_i),
    .rst_en     (1'b0),
    .test_mode  (clkg_test_mode_i),
    .gated_clk  (clk_gated_r)
);

c_clock_gate_ovr clock_gate_write (
    .clk        (clk_i),
    .enable     (clkg_write_en),
    .ovr_en     (clkg_override_i),
    .rst_en     (1'b0),
    .test_mode  (clkg_test_mode_i),
    .gated_clk  (clk_gated_w)
);

c_clock_gate_ovr clock_gate_arb (
    .clk        (clk_i),
    .enable     (clkg_arb_en),
    .ovr_en     (clkg_override_i),
    .rst_en     (1'b0),
    .test_mode  (clkg_test_mode_i),
    .gated_clk  (clk_gated_a)
);

    // xUSER parity check parameters
    // The xUSER signals hold parity check information for all of the AXI signals, indexed as follows:
    // AWUSER
    localparam AWUSER_AWIDCHK_LSB      = ENGNUW;
    localparam AWUSER_AWIDCHK_MSB      = (AWUSER_AWIDCHK_LSB + PIDW) - 1;
    localparam AWUSER_AWADDRCHK_LSB    = AWUSER_AWIDCHK_MSB + 1;
    localparam AWUSER_AWADDRCHK_MSB    = (AWUSER_AWADDRCHK_LSB + 4) - 1;
    localparam AWUSER_AWLENCHK         = AWUSER_AWADDRCHK_MSB + 1;
    localparam AWUSER_AWCTLCHK0        = AWUSER_AWLENCHK + 1;
    localparam AWUSER_AWUSERCHK_LSB    = AWUSER_AWCTLCHK0 + 1;
    localparam AWUSER_AWUSERCHK_MSB    = (AWUSER_AWUSERCHK_LSB + PENGNUW) - 1;
    // WUSER
    localparam WUSER_WDATACHK_LSB      = 0;
    localparam WUSER_WDATACHK_MSB      = (WUSER_WDATACHK_LSB + (DW/8)) - 1;
    localparam WUSER_WSTRBCHK_LSB      = WUSER_WDATACHK_MSB + 1;
    localparam WUSER_WSTRBCHK_MSB      = (WUSER_WSTRBCHK_LSB + PSTRBW) - 1;
    localparam WUSER_WLASTCHK          = WUSER_WSTRBCHK_MSB + 1;
    // BUSER
    localparam BUSER_BIDCHK_LSB        = 0;
    localparam BUSER_BIDCHK_MSB        = (BUSER_BIDCHK_LSB + PIDW) - 1;
    localparam BUSER_BRESPCHK          = BUSER_BIDCHK_MSB + 1;
    // ARUSER
    localparam ARUSER_ARIDCHK_LSB      = ENGNUW;
    localparam ARUSER_ARIDCHK_MSB      = (ARUSER_ARIDCHK_LSB + PIDW) - 1;
    localparam ARUSER_ARADDRCHK_LSB    = ARUSER_ARIDCHK_MSB + 1;
    localparam ARUSER_ARADDRCHK_MSB    = (ARUSER_ARADDRCHK_LSB + 4) - 1;
    localparam ARUSER_ARLENCHK         = ARUSER_ARADDRCHK_MSB + 1;
    localparam ARUSER_ARCTLCHK0        = ARUSER_ARLENCHK + 1;
    localparam ARUSER_ARUSERCHK_LSB    = ARUSER_ARCTLCHK0 + 1;
    localparam ARUSER_ARUSERCHK_MSB    = (ARUSER_ARUSERCHK_LSB + PENGNUW) - 1;
    // RUSER
    localparam RUSER_RIDCHK_LSB        = 0;
    localparam RUSER_RIDCHK_MSB        = (RUSER_RIDCHK_LSB + PIDW) - 1;
    localparam RUSER_RDATACHK_LSB      = RUSER_RIDCHK_MSB + 1;
    localparam RUSER_RDATACHK_MSB      = (RUSER_RDATACHK_LSB + (DW/8)) - 1;
    localparam RUSER_RRESPCHK          = RUSER_RDATACHK_MSB + 1;
    localparam RUSER_RLASTCHK          = RUSER_RRESPCHK + 1;


    logic [1:0]      engn_parity_err;
    logic [1:0]      internal_parity_err;
    logic            chk_r_parity_err;
    logic            internal_engn_r_parity_err;
    logic            axi_internal_r_parity_err;
    logic            axi_internal_r_parity_err_din, axi_internal_r_parity_err_q;
    logic            chk_w_parity_err;
    logic            internal_engn_w_parity_err;
    logic            axi_internal_w_parity_err;
    logic            axi_internal_w_parity_err_din, axi_internal_w_parity_err_q;
    logic [1:0]      axi_parity_err;
    logic [PCHKW-1:0] axi_parity_err_chk;

/*
* Set up FIFOs
*/

// Control FIFO parameters
// The control FIFO records all address/response data for an AXI transaction,
// concatenated into one array, indexed as follows:
localparam CF_USER_LSB  = 0;
localparam CF_USER_MSB  = (CF_USER_LSB + ENGNUW) - 1;
localparam CF_ID_LSB    = CF_USER_MSB + 1;
localparam CF_MID_MSB   = (CF_ID_LSB + MIDW) - 1; //This is where the master ID portion of the ID ends
localparam CF_ID_MSB    = (CF_ID_LSB + IDW) - 1;
localparam CF_ADDR_LSB  = CF_ID_MSB + 1;
localparam CF_ADDR_MSB  = (CF_ADDR_LSB + 32) - 1;
localparam CF_LEN_LSB   = CF_ADDR_MSB + 1;
localparam CF_LEN_MSB   = (CF_LEN_LSB + 8) - 1;
localparam CF_SIZE_LSB  = CF_LEN_MSB + 1;
localparam CF_SIZE_MSB  = (CF_SIZE_LSB + 3) - 1;
localparam CF_PROT_LSB  = CF_SIZE_MSB + 1;
localparam CF_PROT_MSB  = (CF_PROT_LSB + 3) - 1;
localparam CF_LOCK_LSB  = CF_PROT_MSB + 1;
localparam CF_LOCK_MSB  = (CF_LOCK_LSB + LW) - 1;
localparam CF_BURST_LSB = CF_LOCK_MSB + 1;
localparam CF_BURST_MSB = (CF_BURST_LSB + 2) - 1;
localparam CF_RESP_LSB  = CF_BURST_MSB + 1; // LSB of resp bits is for error detected by AXI subordinate
localparam CF_RESP_MSB  = (CF_RESP_LSB + 2) - 1; // MSB of resp bits is for error detected by engine/checker

localparam CF_IDCHK_LSB      = 0;
localparam CF_IDCHK_MSB      = (CF_IDCHK_LSB + PIDW) - 1;
localparam CF_ADDRCHK_LSB    = CF_IDCHK_MSB + 1;
localparam CF_ADDRCHK_MSB    = (CF_ADDRCHK_LSB + 4) - 1;
localparam CF_LENCHK         = CF_ADDRCHK_MSB + 1;
localparam CF_CTLCHK0        = CF_LENCHK + 1;
localparam CF_USERCHK_LSB    = CF_CTLCHK0 + 1;
localparam CF_USERCHK_MSB    = (CF_USERCHK_LSB + PENGNUW) - 1;

localparam CFD_W        = (CFD == 1) ? $clog2(CFD+1) : $clog2(CFD); // Width of signals necessary to address into control FIFOs - if CFD=1, still want CFD_W to be 1 not 0
localparam DFD_W        = (DFD == 1) ? $clog2(DFD+1) : $clog2(DFD); // Width of signals necessary to address into data FIFOs - if DFD=1, still want DFD_W to be 1 not 0
localparam CFDP1_W      = $clog2(CFD+1); // Width of signals necessary to count free space in control FIFOs
localparam DFDP1_W      = $clog2(DFD+1); // Width of signals necessary to count free space in data FIFOs
// Separate data FIFO free parameters, only different from DFD if DFD<BLEN, to
// support small FIFO sizes. (Basically, fake free space to be bigger than it
// actually is)
localparam DFD_FREE     = (DFD < BLEN) ? BLEN : DFD;
localparam DFD_FREEP1_W = $clog2(DFD_FREE+1);

// Read/write control FIFOs
reg  [CF_RESP_MSB:0]    cr_fifo_din [0:CFD-1];
reg  [CF_RESP_MSB:0]    cr_fifo_q   [0:CFD-1];
reg  [CF_RESP_MSB:0]    cw_fifo_din [0:CFD-1];
reg  [CF_RESP_MSB:0]    cw_fifo_q   [0:CFD-1];
reg  [DW-1:0]           dr_fifo_din [0:DFD-1];
reg  [DW-1:0]           dr_fifo_q   [0:DFD-1];
reg  [(STRBW+DW):0]     dw_fifo_din [0:DFD-1];
reg  [(STRBW+DW):0]     dw_fifo_q   [0:DFD-1];
// FIFO start and end pointers, plus counters to track how many slots are
// unfilled in control FIFOs, and how many slots are unallocated, as well as
// filled, in data FIFOs
// For the control interface:
// The axi interface and engine/checker interface have separate start pointers
// so that they can run independently. On the read side, the checker interface
// should stay ahead of the AXI interface (data is read from engine, then
// output over AXI), while the reverse is true for the write interface (data
// is input from AXI then written to engine)
// The AXI address channels control the end pointers for read and write
// For the data interface:
// AXI controls the read start and write end pointers, checker/engine controls
// the read end and write start pointers
// Note that space is only "filled" when data is written to the FIFO, while
// space is "allocated" as soon as it is known that future transfers will use
// that space
wire [CFD_W-1:0]        cr_start_axi_din; //Can optimize these for CFD_W == 1 - defer
reg  [CFD_W-1:0]        cr_start_axi_q;
wire [CFD_W-1:0]        cr_start_chk_din;
reg  [CFD_W-1:0]        cr_start_chk_q;
wire [CFD_W-1:0]        cr_end_din;
reg  [CFD_W-1:0]        cr_end_q;
wire [CFDP1_W-1:0]      cr_remaining_axi_din;
reg  [CFDP1_W-1:0]      cr_remaining_axi_q;
wire [CFDP1_W-1:0]      cr_remaining_chk_din;
reg  [CFDP1_W-1:0]      cr_remaining_chk_q;
wire [CFD_W-1:0]        cw_start_axi_din;
reg  [CFD_W-1:0]        cw_start_axi_q;
wire [CFD_W-1:0]        cw_start_chk_din;
reg  [CFD_W-1:0]        cw_start_chk_q;
wire [CFD_W-1:0]        cw_end_din;
reg  [CFD_W-1:0]        cw_end_q;
wire [CFDP1_W-1:0]      cw_remaining_axi_din;
reg  [CFDP1_W-1:0]      cw_remaining_axi_q;
wire [CFDP1_W-1:0]      cw_remaining_chk_din;
reg  [CFDP1_W-1:0]      cw_remaining_chk_q;
wire [DFD_W-1:0]        dr_start_din;
reg  [DFD_W-1:0]        dr_start_q;
wire [DFD_W-1:0]        dr_end_din;
reg  [DFD_W-1:0]        dr_end_q;
wire [DFDP1_W-1:0]      dr_entries_din;
reg  [DFDP1_W-1:0]      dr_entries_q;
wire [DFD_FREEP1_W:0]   dr_free_din; // Adding extra bit for overflow
reg  [DFD_FREEP1_W-1:0] dr_free_q;
wire [DFD_W-1:0]        dw_start_din;
reg  [DFD_W-1:0]        dw_start_q;
wire [DFD_W-1:0]        dw_end_din;
reg  [DFD_W-1:0]        dw_end_q;
wire [DFDP1_W-1:0]      dw_entries_din;
reg  [DFDP1_W-1:0]      dw_entries_q;
wire [DFD_FREEP1_W:0]   dw_free_din; // Adding extra bit for overflow
reg  [DFD_FREEP1_W-1:0] dw_free_q;
// FIFO pointer advance signals. When set by control logic, these advance the
// corresponding pointer
reg                     cr_start_axi_advance;
reg                     cr_start_chk_advance;
reg                     cr_end_advance;
reg                     cw_start_axi_advance;
reg                     cw_start_chk_advance;
reg                     cw_end_advance;
reg                     dr_start_advance;
reg                     dr_end_advance;
reg                     dw_start_advance;
reg                     dw_end_advance;
// FIFO get/set signals. start_get always returns the FIFO entry at the
// current start pointer. end_set will be latched into the FIFO when
// end_advance is set
// start_resp_err_set allows the checker logic to latch a subordinate error into the
// entry at the current start pointer.
// For the control FIFOs, since one bit is controlled by start_resp_err_set,
// end_set is one bit shorter
wire [CF_RESP_MSB:0]    cr_start_axi_get;
wire [CF_RESP_MSB:0]    cr_start_chk_get;
wire [CF_RESP_LSB:0]    cr_end_set;
reg                     cr_start_resp_err_set;
wire [CF_RESP_MSB:0]    cw_start_axi_get;
wire [CF_RESP_MSB:0]    cw_start_chk_get;
wire [CF_RESP_LSB:0]    cw_end_set;
reg                     cw_start_resp_err_set;
wire [DW-1:0]           dr_start_get;
wire [DW-1:0]           dr_end_set;
wire [(STRBW+DW):0]     dw_start_get;
wire [(STRBW+DW):0]     dw_end_set;

// Set FIFO - FIFO retains previous value except at end pointer address, if
// end_advance is set
// For control FIFOs, if start_resp_set is not equal to OKAY (a new SUBERR has
// occurred), latch the new response into start_resp
always @(*) begin
    integer i;
    for (i=0; i<CFD; i = i+1) begin
        if (i == cr_end_q) begin // CR FIFO
            cr_fifo_din[i][CF_RESP_LSB:0] = cr_end_advance ? cr_end_set:
                                            cr_fifo_q[i][CF_RESP_LSB:0];
        end
        else begin
            cr_fifo_din[i][CF_RESP_LSB:0] = cr_fifo_q[i][CF_RESP_LSB:0];
        end

        cr_fifo_din[i][CF_RESP_MSB] = ((i == cr_start_axi_q) && cr_start_axi_advance) ? 1'b0 :
                                      ((i == cr_start_chk_q) && cr_start_resp_err_set) ? 1'b1 :
                                      cr_fifo_q[i][CF_RESP_MSB];

        if (i == cw_end_q) begin // CW FIFO
            cw_fifo_din[i][CF_RESP_LSB:0] = cw_end_advance ? cw_end_set:
                                            cw_fifo_q[i][CF_RESP_LSB:0];
        end
        else begin
            cw_fifo_din[i][CF_RESP_LSB:0] = cw_fifo_q[i][CF_RESP_LSB:0];
        end

        cw_fifo_din[i][CF_RESP_MSB] = ((i == cw_start_axi_q) && cw_start_axi_advance) ? 1'b0 :
                                      ((i == cw_start_chk_q) && cw_start_resp_err_set) ? 1'b1 :
                                      cw_fifo_q[i][CF_RESP_MSB];
    end
    for (i=0; i<DFD; i = i+1) begin
        if (i == dr_end_q) begin // DR FIFO
            dr_fifo_din[i] = dr_end_advance ? dr_end_set :
                             dr_fifo_q[i];
        end
        else begin
            dr_fifo_din[i] = dr_fifo_q[i];
        end

        if (i == dw_end_q) begin // DW FIFO
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
// Control remaining counter increments on control end_advance, decrements
// on control start_advance
// Data free counter increments on control end_advance, and decrements on
// data start_advance only allocate space in data if the new control entry
// is being set _without_ an AXI subordinate error
localparam unsigned [CFD_W-1:0] CFDW_ONE = 'b1;
localparam unsigned [CFDP1_W-1:0] CFDP1W_ONE = 'b1;
localparam unsigned [DFD_W-1:0] DFDW_ONE = 'b1;
localparam unsigned [DFDP1_W-1:0] DFDP1W_ONE = 'b1;
localparam unsigned [DFD_FREEP1_W-1:0] DFD_FREEP1W_ONE = {{(DFD_FREEP1_W-1){1'b0}}, 1'b1};
localparam unsigned [LENW:0] LENW_ONE = {{LENW{1'b0}}, 1'b1};

assign cr_start_axi_din     = (~cr_start_axi_advance) ? cr_start_axi_q :
                              (cr_start_axi_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              (cr_start_axi_q + CFDW_ONE);
assign cr_start_chk_din     = (~cr_start_chk_advance) ? cr_start_chk_q :
                              (cr_start_chk_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              (cr_start_chk_q + CFDW_ONE);
assign cr_end_din           = (~cr_end_advance) ? cr_end_q :
                              (cr_end_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              cr_end_q + CFDW_ONE;
assign cr_remaining_axi_din = (cr_start_axi_advance && cr_end_advance) ? cr_remaining_axi_q :
                              cr_start_axi_advance ? (cr_remaining_axi_q + CFDP1W_ONE) :
                              cr_end_advance ? (cr_remaining_axi_q - CFDP1W_ONE) :
                              cr_remaining_axi_q;
assign cr_remaining_chk_din = (cr_start_chk_advance && cr_end_advance) ? cr_remaining_chk_q :
                              cr_start_chk_advance ? (cr_remaining_chk_q + CFDP1W_ONE) :
                              cr_end_advance ? (cr_remaining_chk_q - CFDP1W_ONE) :
                              cr_remaining_chk_q;
assign cw_start_axi_din     = (~cw_start_axi_advance) ? cw_start_axi_q :
                              (cw_start_axi_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              cw_start_axi_q + CFDW_ONE;
assign cw_start_chk_din     = (~cw_start_chk_advance) ? cw_start_chk_q :
                              (cw_start_chk_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              (cw_start_chk_q + CFDW_ONE);
assign cw_end_din           = (~cw_end_advance) ? cw_end_q :
                              (cw_end_q == (CFD-1)) ? {CFD_W{1'b0}} :
                              (cw_end_q + CFDW_ONE);
assign cw_remaining_axi_din = (cw_start_axi_advance && cw_end_advance) ? cw_remaining_axi_q :
                              cw_start_axi_advance ? (cw_remaining_axi_q + CFDP1W_ONE) :
                              cw_end_advance ? (cw_remaining_axi_q - CFDP1W_ONE) :
                              cw_remaining_axi_q;
assign cw_remaining_chk_din = (cw_start_chk_advance && cw_end_advance) ? cw_remaining_chk_q :
                              cw_start_chk_advance ? (cw_remaining_chk_q + CFDP1W_ONE) :
                              cw_end_advance ? (cw_remaining_chk_q - CFDP1W_ONE) :
                              cw_remaining_chk_q;
assign dr_start_din         = (~dr_start_advance) ? dr_start_q :
                              (dr_start_q == (DFD-1)) ? {DFD_W{1'b0}} :
                              (dr_start_q + DFDW_ONE);
assign dr_end_din           = (~dr_end_advance) ? dr_end_q :
                              (dr_end_q == (DFD-1)) ? {DFD_W{1'b0}} :
                              (dr_end_q + DFDW_ONE);
assign dr_entries_din       = (dr_start_advance && dr_end_advance) ? dr_entries_q :
                              dr_start_advance ? (dr_entries_q - DFDP1W_ONE) :
                              dr_end_advance ? (dr_entries_q + DFDP1W_ONE) :
                              dr_entries_q;
localparam PADDING_RHS_W    = DFD_FREEP1_W-((CF_LEN_LSB+LENW)-CF_LEN_LSB);
wire [DFD_FREEP1_W-1:0] cr_end_set_len;
generate //Added the generate statement to handle padding based on parameters
if ((DFDP1_W - 1) == 0) begin: cr_end_set_len_not_padded
        assign cr_end_set_len = {1'b0,cr_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
end else begin :cr_end_set_len_padded
        assign cr_end_set_len = {{(PADDING_RHS_W){1'b0}},cr_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
end
endgenerate

assign dr_free_din          = (dr_start_advance && (cr_end_advance && (~cr_end_set[CF_RESP_LSB]))) ? (dr_free_q - cr_end_set_len) :
                              dr_start_advance ? (dr_free_q + DFD_FREEP1W_ONE) :
                              (cr_end_advance && (~cr_end_set[CF_RESP_LSB])) ? (dr_free_q - (cr_end_set_len + DFD_FREEP1W_ONE)) :
                              {1'b0, dr_free_q};
assign dw_start_din         = (~dw_start_advance) ? dw_start_q :
                              (dw_start_q == (DFD-1)) ? {DFD_W{1'b0}} :
                              (dw_start_q + DFDW_ONE);
assign dw_end_din           = (~dw_end_advance) ? dw_end_q :
                              (dw_end_q == (DFD-1)) ? {DFD_W{1'b0}} :
                              (dw_end_q + DFDW_ONE);
assign dw_entries_din       = (dw_start_advance && dw_end_advance) ? dw_entries_q :
                              dw_start_advance ? (dw_entries_q - DFDP1W_ONE) :
                              dw_end_advance ? (dw_entries_q + DFDP1W_ONE) :
                              dw_entries_q;

wire [DFD_FREEP1_W-1:0] cw_end_set_len;
generate //Added the generate statement to handle padding based on parameters
if ((DFDP1_W - 1) == 0) begin: cw_end_set_len_not_padded
        assign cw_end_set_len = {1'b0,cw_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
end else begin :cw_end_set_len_padded
        assign cw_end_set_len = {{(PADDING_RHS_W){1'b0}},cw_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
end
endgenerate

assign dw_free_din          = (dw_start_advance && (cw_end_advance && (~cw_end_set[CF_RESP_LSB]))) ? (dw_free_q - cw_end_set_len) :
                              dw_start_advance ? (dw_free_q + DFD_FREEP1W_ONE) :
                              (cw_end_advance && (~cw_end_set[CF_RESP_LSB])) ? (dw_free_q - (cw_end_set_len + DFD_FREEP1W_ONE)) :
                              {1'b0, dw_free_q};

// Set registers
always @(posedge clk_gated_r or negedge reset_nai) begin
    integer i;
    if (~reset_nai) begin
        for (i=0; i<CFD; i=i+1) begin // CR FIFO
            cr_fifo_q[i] <= {(CF_RESP_MSB+1){1'b0}};
        end
        for (i=0; i<DFD; i=i+1) begin // DR FIFO
            dr_fifo_q[i] <= {DW{1'b0}};
        end
    end
    else begin
        for (i=0; i<CFD; i=i+1) begin // CR FIFO
            cr_fifo_q[i] <= cr_fifo_din[i];
        end
        for (i=0; i<DFD; i=i+1) begin // DR FIFO
            dr_fifo_q[i] <= dr_fifo_din[i];
        end
    end
end
always @(posedge clk_gated_w or negedge reset_nai) begin
    integer i;
    if (~reset_nai) begin
        for (i=0; i<CFD; i=i+1) begin // CW FIFO
            cw_fifo_q[i] <= {(CF_RESP_MSB+1){1'b0}};
        end
        for (i=0; i<DFD; i=i+1) begin // DW FIFO
            dw_fifo_q[i] <= {(STRBW+DW+1){1'b0}};
        end
    end
    else begin
        for (i=0; i<DFD; i=i+1) begin // DW FIFO
            dw_fifo_q[i] <= dw_fifo_din[i];
        end
        for (i=0; i<CFD; i=i+1) begin // CW FIFO
            cw_fifo_q[i] <= cw_fifo_din[i];
        end
    end
end
always @(posedge clk_gated_r or negedge reset_nai) begin
    if (~reset_nai) begin
        cr_remaining_axi_q  <= CFD;
        cr_remaining_chk_q  <= CFD;
        dr_free_q           <= DFD_FREE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        cr_end_q <= {CFD_W{1'b0}};
        cr_start_axi_q <= {CFD_W{1'b0}};
        cr_start_chk_q <= {CFD_W{1'b0}};
        dr_end_q <= {DFD_W{1'b0}};
        dr_entries_q <= {DFDP1_W{1'b0}};
        dr_start_q <= {DFD_W{1'b0}};
        // End of automatics
    end
    else begin
        cr_start_axi_q      <= cr_start_axi_din;
        cr_start_chk_q      <= cr_start_chk_din;
        cr_end_q            <= cr_end_din;
        cr_remaining_axi_q  <= cr_remaining_axi_din;
        cr_remaining_chk_q  <= cr_remaining_chk_din;
        dr_start_q          <= dr_start_din;
        dr_end_q            <= dr_end_din;
        dr_entries_q        <= dr_entries_din;
        dr_free_q           <= dr_free_din[DFD_FREEP1_W-1:0];
    end
end
always @(posedge clk_gated_w or negedge reset_nai) begin
    if (~reset_nai) begin
        cw_remaining_axi_q  <= CFD;
        cw_remaining_chk_q  <= CFD;
        dw_free_q           <= DFD_FREE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        cw_end_q <= {CFD_W{1'b0}};
        cw_start_axi_q <= {CFD_W{1'b0}};
        cw_start_chk_q <= {CFD_W{1'b0}};
        dw_end_q <= {DFD_W{1'b0}};
        dw_entries_q <= {DFDP1_W{1'b0}};
        dw_start_q <= {DFD_W{1'b0}};
        // End of automatics
    end
    else begin
        cw_start_axi_q      <= cw_start_axi_din;
        cw_start_chk_q      <= cw_start_chk_din;
        cw_end_q            <= cw_end_din;
        cw_remaining_axi_q  <= cw_remaining_axi_din;
        cw_remaining_chk_q  <= cw_remaining_chk_din;
        dw_start_q          <= dw_start_din;
        dw_end_q            <= dw_end_din;
        dw_entries_q        <= dw_entries_din;
        dw_free_q           <= dw_free_din[DFD_FREEP1_W-1:0];
    end
end

//Set start_get to value of FIFO at start pointer
assign cr_start_axi_get = cr_fifo_q[cr_start_axi_q];
assign cr_start_chk_get = cr_fifo_q[cr_start_chk_q];
assign cw_start_axi_get = cw_fifo_q[cw_start_axi_q];
assign cw_start_chk_get = cw_fifo_q[cw_start_chk_q];
assign dr_start_get     = dr_fifo_q[dr_start_q];
assign dw_start_get     = dw_fifo_q[dw_start_q];


/*
* AXI Address Read/Write Controllers
*/

// AXI and engine read/write states - needed here but mostly used later
// SERR state is not used by AXI read channel
// Used by AXI write channel for a WID mismatch
// Used by engine read/write channels for engine check error
// WAIT is only used by engine write, when it can't advance the control FIFO
// start pointer because the burst channel is not ready to take another
// response
localparam unsigned [1:0] S_IDLE   = 2'b00;
localparam unsigned [1:0] S_RESP   = S_IDLE+2'b01;
localparam unsigned [1:0] S_SERR   = S_RESP+2'b01;
localparam unsigned [1:0] S_WAIT   = S_SERR+2'b01;

localparam AXI_SIZE = $clog2(DW)-3; // The only AXI transaction size supported for transactions with length>1 is 'h2 for DW=32, 'h3 for DW=64
localparam AXI_INCR = 2'b01; // The only AXI burst mode supported for transactions with length>1 is 'b01 (incremental burst)

// ready: asserted while there is free space in the control FIFO
// data: data from AXI address channel, concatenated for the control FIFO
// err: AXI subordinate detects that the address data is not supported
// capture: signal to latch data into the control FIFO
wire                    axi_ar_ready;
wire [CF_BURST_MSB:0]   axi_ar_data;
wire                    axi_ar_err;
wire                    axi_ar_capture;
wire                    axi_aw_ready;
wire [CF_BURST_MSB:0]   axi_aw_data;
wire                    axi_aw_err;
wire                    axi_aw_capture;

reg  [1:0]  axi_w_state_q; // This is predefined here, but mainly used in the AXI write control logic

// Set AXI address control signals
assign axi_ar_ready     = (|cr_remaining_axi_q) && (dr_free_q >= BLEN); // Ready to accept data when control FIFO has non-zero space remaining and data FIFO has at least BLEN unallocated entries
assign axi_ar_data      = {arburst_i,arlock_i,arprot_i,arsize_i,arlen_i,araddr_i,arid_i,aruser_i[ENGNUW-1:0]};
assign axi_ar_err       = (arlen_i >= BLEN) || // All transactions of length>BLEN are unsupported
                          (arsize_i > AXI_SIZE) || // Size cannot be larger than full word
                          (((|arlen_i) && (arburst_i != AXI_INCR)) || // If transaction length>1, burst type must be INCR
                          axi_parity_err[1]);
assign axi_ar_capture   = axi_ar_ready && arvalid_i;
assign axi_aw_ready     = (|cw_remaining_chk_q) && (|cw_remaining_axi_q) && (dw_free_q >= BLEN) && (axi_w_state_q != S_SERR); // Ready to accept data when control FIFO has non-zero space remaining and data FIFO has at least BLEN unallocated entries
assign axi_aw_data      = {awburst_i,awlock_i,awprot_i,awsize_i,awlen_i,awaddr_i,awid_i,awuser_i[ENGNUW-1:0]};
assign axi_aw_err       = (awlen_i >= BLEN) || // All transactions of length>BLEN are unsupported
                          (awsize_i > AXI_SIZE) || // Size cannot be larger than full word
                          (((|awlen_i) && (awburst_i != AXI_INCR)) || // If transaction length>1, burst type must be INCR
                          (|axi_parity_err_chk[ERR_CHK_AWUSERCHK_MSB:ERR_CHK_AWIDCHK_LSB])); // Parity error on AW channel
assign axi_aw_capture   = axi_aw_ready && awvalid_i;

// Set AXI outputs and FIFO signals based on control signals
assign arready_o        = axi_ar_ready;
assign cr_end_set       = {axi_ar_err,axi_ar_data};
assign cr_end_advance   = axi_ar_capture;
assign awready_o        = axi_aw_ready;
assign cw_end_set       = {axi_aw_err,axi_aw_data};
assign cw_end_advance   = axi_aw_capture;


/*
* AXI Read channel controller
*/

// AXI read control signals
reg  [1:0]      axi_r_state_din;
reg  [1:0]      axi_r_state_q;
reg  [7:0]      axi_r_len_rem_din;
reg  [7:0]      axi_r_len_rem_q;
reg             axi_r_chk_err_din;
reg             axi_r_chk_err_q;

wire            axi_r_cf_valid;
wire            axi_r_df_valid;
wire            axi_r_sub_err;
wire [IDW-1:0]  axi_r_id;
wire [DW-1:0]   axi_r_data;
wire [1:0]      axi_r_resp;
wire            axi_r_last;
wire            axi_r_valid;

always @(*) begin
    axi_r_len_rem_din = axi_r_len_rem_q;
    cr_start_axi_advance = 1'b0;
    dr_start_advance = 1'b0;
    axi_r_chk_err_din = cr_fifo_din[cr_start_axi_din][CF_RESP_MSB]; //Error is in process of being set

    if (axi_r_state_q == S_IDLE) begin
        if (axi_r_cf_valid) begin
            axi_r_state_din = S_RESP;
            axi_r_len_rem_din = cr_start_axi_get[CF_LEN_MSB:CF_LEN_LSB];
        end
        else begin
            axi_r_state_din = S_IDLE;
        end
    end
    else if (axi_r_state_q == S_RESP) begin
        axi_r_chk_err_din = (axi_r_valid && (~rready_i)) ? axi_r_chk_err_q : (cr_fifo_din[cr_start_axi_din][CF_RESP_MSB] || cr_start_axi_get[CF_RESP_MSB]); //Do not change error while valid is being held high but ready not accepted. Otherwise set on error already set/in process of being set
        if (axi_r_valid && rready_i) begin
            dr_start_advance = ~axi_r_sub_err; // Only advance data pointer if space is allocated (subordinate did not detect error on that transaction)
            if (|axi_r_len_rem_q) begin
                axi_r_len_rem_din = axi_r_len_rem_q - 8'h01;
                axi_r_state_din = S_RESP;
            end
            else begin
                cr_start_axi_advance = 1'b1;
                if (cr_remaining_axi_din == CFD) begin
                    axi_r_state_din = S_IDLE;
                end
                else begin
                    axi_r_state_din = S_RESP;
                    axi_r_len_rem_din = cr_fifo_din[cr_start_axi_din][CF_LEN_MSB:CF_LEN_LSB]; // Look ahead to the next AXI transaction and get the length. Saves a cycle vs returning to IDLE
                    axi_r_chk_err_din = cr_fifo_din[cr_start_axi_din][CF_RESP_MSB]; // Look ahead for error
                end
            end
        end
        else begin
            axi_r_state_din = S_RESP;
        end
    end
    else begin // Illegal state - will need to be excluded for coverage
        axi_r_state_din = S_IDLE;
    end
end

always @(posedge clk_gated_r or negedge reset_nai) begin
    if (~reset_nai) begin
        axi_r_state_q   <= S_IDLE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        axi_r_chk_err_q <= 1'h0;
        axi_r_len_rem_q <= 8'h0;
        // End of automatics
    end
    else begin
        axi_r_state_q   <= axi_r_state_din;
        axi_r_len_rem_q <= axi_r_len_rem_din;
        axi_r_chk_err_q <= axi_r_chk_err_din;
    end
end

assign axi_r_cf_valid   = (cr_remaining_axi_q != CFD);
assign axi_r_df_valid   = |dr_entries_q; // Entries is nonzero
assign axi_r_sub_err    = cr_start_axi_get[CF_RESP_LSB];
assign axi_r_id         = (axi_r_state_q == S_RESP) ? cr_start_axi_get[CF_ID_MSB:CF_ID_LSB] : {IDW{1'b0}};
assign axi_r_data       = (axi_r_df_valid && (~axi_r_sub_err) && (~axi_r_chk_err_q)) ? dr_start_get :
                          (dr_end_advance && (~axi_r_sub_err) && (~axi_r_chk_err_q) && (~cr_start_resp_err_set)) ? dr_end_set : {DW{1'b0}};
assign axi_r_resp       = (axi_r_sub_err || axi_r_chk_err_q || axi_internal_r_parity_err || axi_internal_r_parity_err_q) ? `HSP_AXI_RESP_SLVERR : `HSP_AXI_RESP_OKAY;
assign axi_r_last       = (axi_r_state_q == S_RESP) && (axi_r_len_rem_q == 8'd0);
assign axi_r_valid      = (axi_r_state_q == S_RESP) && (axi_r_df_valid || (dr_end_advance && (~cr_start_resp_err_set)) || axi_r_sub_err || (axi_r_chk_err_q && !(engn_ren_o && (!engn_r_rdy_i))));

assign rid_o    = axi_r_id;
assign rdata_o  = axi_r_data;
assign rresp_o  = axi_r_resp;
assign rlast_o  = axi_r_last;
assign rvalid_o = axi_r_valid;


/*
* AXI Write channel controller
*/

// AXI write control signals
reg  [1:0]  axi_w_state_din;
//reg  [1:0]  axi_w_state_q; // Defined earlier
reg  [7:0]  axi_w_len_rem_din;
reg  [7:0]  axi_w_len_rem_q;
reg         axi_w_wlast_err;

wire        axi_w_cf_valid;
wire        axi_w_df_valid;
wire        axi_w_sub_err;
//wire        axi_w_chk_err;
wire        axi_w_ready;
wire                chk_w_wlast_err; //defining early for use in this FSM

logic [CFDP1_W-1:0] axi_w_completed_cnt_q; //Number of transactions where all wdata was received but no response sent yet. Used in axi_b_state_q FSM
logic [CFDP1_W-1:0] axi_w_completed_cnt_din; 
logic       axi_w_completed_cnt_incr;
logic       axi_w_completed_cnt_decr;

wire [CF_RESP_MSB:0] cw_start_axi_get_adv;
assign cw_start_axi_get_adv = cw_fifo_din[cw_start_axi_din];

always @(*) begin
    axi_w_len_rem_din = axi_w_len_rem_q;
    cw_start_axi_advance = 1'b0;
    dw_end_advance = 1'b0;
    axi_w_wlast_err = 1'b0;
    axi_w_completed_cnt_incr = 1'b0;

    if (axi_w_state_q == S_IDLE) begin
        if (axi_w_cf_valid) begin
            axi_w_state_din = S_RESP;
            axi_w_len_rem_din = cw_start_axi_get[CF_LEN_MSB:CF_LEN_LSB];
        end
        else if (cw_end_advance) begin
            axi_w_state_din = S_RESP;
            axi_w_len_rem_din = cw_end_set[CF_LEN_MSB:CF_LEN_LSB];
        end
        else begin
            axi_w_state_din = S_IDLE;
        end
    end
    else if (axi_w_state_q == S_RESP) begin
        if (axi_w_ready && wvalid_i) begin
            dw_end_advance = ~axi_w_sub_err;
            if (|axi_w_len_rem_q) begin
                axi_w_len_rem_din = axi_w_len_rem_q - 8'h01;
                axi_w_state_din = S_RESP;
            end
            else begin
                cw_start_axi_advance = 1'b1;
                if ((~wlast_i) && (~axi_w_sub_err)) begin
                    axi_w_wlast_err = 1'b1;
                    if (chk_w_wlast_err) begin
                        axi_w_state_din = S_IDLE;
                        axi_w_completed_cnt_incr = 1'b1;
                    end
                    else begin
                        axi_w_state_din = S_SERR;
                    end
                end
                else begin
                    axi_w_completed_cnt_incr = 1'b1;
                    if (cw_remaining_axi_din == CFD) begin
                        axi_w_state_din = S_IDLE;
                    end
                    else begin
                        axi_w_state_din = S_IDLE; // Temp fix for DLP. Should change back to S_RESP and fix axi_b holdoff behavior.
                        axi_w_len_rem_din = cw_start_axi_get_adv[CF_LEN_MSB:CF_LEN_LSB];
                    end
                end
            end
        end
        else begin
            axi_w_state_din = S_RESP;
        end
    end
    else if (axi_w_state_q == S_SERR) begin
        axi_w_wlast_err = 1'b1;
        if (chk_w_wlast_err) begin
            axi_w_state_din = S_IDLE;
            axi_w_completed_cnt_incr = 1'b1;
        end
        else begin
            axi_w_state_din = S_SERR;
        end
    end
    else begin // Illegal state - will need to be excluded for coverage
        axi_w_state_din = S_IDLE;
    end
end

always @(posedge clk_gated_w or negedge reset_nai) begin
    if (~reset_nai) begin
        axi_w_state_q   <= S_IDLE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        axi_w_len_rem_q <= 8'h0;
        // End of automatics
    end
    else begin
        axi_w_state_q   <= axi_w_state_din;
        axi_w_len_rem_q <= axi_w_len_rem_din;
    end
end

always_comb begin
    if(axi_w_completed_cnt_incr && axi_w_completed_cnt_decr) begin
        axi_w_completed_cnt_din = axi_w_completed_cnt_q;
    end
    else if(axi_w_completed_cnt_incr) begin
        axi_w_completed_cnt_din = axi_w_completed_cnt_q + 1'b1;
    end
    else if(axi_w_completed_cnt_decr) begin
        axi_w_completed_cnt_din = axi_w_completed_cnt_q - 1'b1;
    end
    else begin
        axi_w_completed_cnt_din = axi_w_completed_cnt_q;
    end    
end

always_ff @(posedge clk_gated_w or negedge reset_nai) begin
    if (~reset_nai) begin
        axi_w_completed_cnt_q <= '0;
    end
    else begin
        axi_w_completed_cnt_q <= axi_w_completed_cnt_din;
    end
end


assign axi_w_cf_valid   = (cw_remaining_axi_q != CFD);
assign axi_w_df_valid   = (DFD < BLEN) ? dw_entries_q != DFD : 1; //change to generate to optimize? - defer

assign axi_w_sub_err    = cw_start_axi_get[CF_RESP_LSB];
//assign axi_w_chk_err    = cw_start_axi_get[CF_RESP_MSB];
assign axi_w_ready      = (axi_w_state_q == S_RESP) && axi_w_cf_valid && axi_w_df_valid;

assign wready_o         = axi_w_ready;
assign dw_end_set       = {(|axi_parity_err_chk[ERR_CHK_WLASTCHK:ERR_CHK_WDATACHK_LSB]),wstrb_i,wdata_i};


/*
* AXI Write Response channel controller
*/

// AXI write response control signals
reg  [1:0]      axi_b_state_din;
reg  [1:0]      axi_b_state_q;
reg  [IDW-1:0]  axi_b_id_din;
reg  [IDW-1:0]  axi_b_id_q;
reg  [1:0]      axi_b_resp_din;
reg  [1:0]      axi_b_resp_q;
reg             axi_b_holdoff_din;
reg             axi_b_holdoff_q;

wire            axi_b_valid;

always @(*) begin
    axi_b_id_din = axi_b_id_q;
    axi_b_resp_din = axi_b_resp_q;
    axi_b_holdoff_din = axi_b_holdoff_q;
    axi_w_completed_cnt_decr = 1'b0;

    if (axi_b_state_q == S_IDLE) begin
        if (cw_start_chk_advance) begin
            // Snoop the cw engine/checker start pointer signal - when it is asserted,
            // the transaction has been completed. The engine/checker controller is
            // responsible for waiting until this controller is idle to assert it
            axi_b_state_din = S_RESP;
            axi_b_id_din = cw_start_chk_get[CF_ID_MSB:CF_ID_LSB];
            axi_b_resp_din = ((|cw_start_chk_get[CF_RESP_MSB:CF_RESP_LSB]) || cw_start_resp_err_set) ? `HSP_AXI_RESP_SLVERR : `HSP_AXI_RESP_OKAY;
            axi_b_holdoff_din = cw_start_chk_get[CF_RESP_LSB] ? ((axi_w_completed_cnt_q == '0) && ( axi_w_state_din != S_IDLE)) : 1'b0; // If this is an automatic suberr, wait to send bresp until all AXI writes have completed
        end
        else begin
            axi_b_state_din = S_IDLE;
        end
    end
    else if (axi_b_state_q == S_RESP) begin
        axi_b_holdoff_din = axi_b_holdoff_q ? ((axi_w_completed_cnt_q == '0) && ( axi_w_state_din != S_IDLE)) : 1'b0;
        if (bready_i && (~axi_b_holdoff_q)) begin
            axi_w_completed_cnt_decr = 1'b1;
            axi_b_id_din = {IDW{1'b0}};
            axi_b_resp_din = 2'b00;
            axi_b_state_din = S_IDLE;
        end
        else begin
            axi_b_state_din = S_RESP;
        end
    end
    else begin // Illegal state - will need to be excluded for coverage
        axi_b_state_din = S_IDLE;
    end
end

always @(posedge clk_gated_w or negedge reset_nai) begin
    if (~reset_nai) begin
        axi_b_state_q   <= S_IDLE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        axi_b_holdoff_q <= 1'h0;
        axi_b_id_q <= {IDW{1'b0}};
        axi_b_resp_q <= 2'h0;
        // End of automatics
    end
    else begin
        axi_b_state_q   <= axi_b_state_din;
        axi_b_id_q      <= axi_b_id_din;
        axi_b_resp_q    <= axi_b_resp_din;
        axi_b_holdoff_q <= axi_b_holdoff_din;
    end
end

assign axi_b_valid  = (axi_b_state_q == S_RESP) && (~axi_b_holdoff_q);

assign bid_o    = axi_b_id_q;
assign bresp_o  = (axi_internal_w_parity_err || axi_internal_w_parity_err_q) ? `HSP_AXI_RESP_SLVERR : axi_b_resp_q;
assign bvalid_o = axi_b_valid;

/*
* Engine Read channel controller
*/

// Engine read control signals
reg  [1:0]          chk_r_state_din;
reg  [1:0]          chk_r_state_q;
reg  [LENW-1:0]     chk_r_len_rem_din;
reg  [LENW-1:0]     chk_r_len_rem_q;
reg  [32:0]         chk_r_addr_din; // Adding extra bit for overflow
reg  [31:0]         chk_r_addr_q;

wire                chk_r_cf_valid;
wire                chk_r_df_valid;
wire                chk_r_sub_err;
wire                chk_r_en;
wire [IDW-1:0]      chk_r_id;
wire [ENGNUW-1:0]   chk_r_user;
wire [2:0]          chk_r_size;
wire [2:0]          chk_r_prot;
wire [LENW-1:0]     chk_r_len;
wire [1:0]          chk_r_burst;
wire                chk_r_last;
wire [31:0]         chk_r_addr_adv;
wire [38:0]         chk_r_addr_adv_shft;

// Wires from engine read/write arbitration
wire                chk_a_valid_r;
wire                chk_a_invalid_r;
wire                chk_a_r_busy;
wire                chk_a_w_busy;
reg                 chk_a_engn_ren_q;

// Engine write control signals
// Declaring for look-ahead of write state
reg  [1:0]          chk_w_state_din;
reg  [1:0]          chk_w_state_q;

always @(*) begin
    chk_r_len_rem_din = chk_r_len_rem_q;
    chk_r_addr_din = {1'b0,chk_r_addr_q};

    cr_start_chk_advance = 1'b0;
    cr_start_resp_err_set = 1'b0;

    if (chk_r_state_q == S_IDLE) begin
        if (chk_r_cf_valid) begin
            if (chk_r_sub_err) begin
                chk_r_state_din = S_IDLE;
                cr_start_chk_advance = 1'b1;
            end
            else if (chk_w_state_q == S_IDLE) begin // transition to S_RESP only if write channel is done
                chk_r_state_din = S_RESP;
                chk_r_len_rem_din = cr_start_chk_get[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB];
                chk_r_addr_din = {1'b0,cr_start_chk_get[CF_ADDR_MSB:CF_ADDR_LSB]};
            end
            else begin
                chk_r_state_din = S_IDLE;
            end
        end
        else if (cr_end_advance) begin
            if (axi_ar_err) begin
                chk_r_state_din = S_IDLE;
                cr_start_chk_advance = 1'b1;
            end
            else if (chk_w_state_q == S_IDLE) begin // transition to S_RESP only if write channel is done

                chk_r_state_din = S_RESP;
                chk_r_len_rem_din = cr_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB];
                chk_r_addr_din = {1'b0,cr_end_set[CF_ADDR_MSB:CF_ADDR_LSB]};
            end
            else begin
                chk_r_state_din = S_IDLE;
            end
        end
        else begin
            chk_r_state_din = S_IDLE;
        end
    end
    else if (chk_r_state_q == S_RESP) begin
        if ((chk_r_en && chk_a_invalid_r && chk_r_rdy_i) || (engn_r_err_i && engn_ren_o) || engn_parity_err[1] || chk_r_parity_err || internal_engn_r_parity_err) begin
            cr_start_resp_err_set = 1'b1;
            chk_r_addr_din = 33'd0;
            chk_r_len_rem_din = chk_r_len_rem_q;
            chk_r_state_din = S_SERR;
        end
        else if (chk_r_en && chk_a_valid_r) begin
            if (chk_r_rdy_i && (~chk_a_r_busy) && (~chk_a_w_busy)) begin
                if (|chk_r_len_rem_q) begin
                    chk_r_len_rem_din = chk_r_len_rem_q - LENW_ONE;
                    chk_r_state_din = S_RESP;
                    chk_r_addr_din = (chk_r_addr_adv == 32'h0000_0004) ? {chk_r_addr_q[31:2],2'b00} + chk_r_addr_adv :
                                     (chk_r_addr_adv == 32'h0000_0002) ? {chk_r_addr_q[31:1],1'b0} + chk_r_addr_adv :
                                     chk_r_addr_q + chk_r_addr_adv;
                end
                else begin
                    chk_r_state_din = S_WAIT;
                    chk_r_addr_din = 33'b0;
                end
            end
            else begin
                chk_r_state_din = S_RESP;
            end
        end
        else begin
            chk_r_state_din = S_RESP;
        end
    end
    else if (chk_r_state_q == S_SERR) begin
        cr_start_resp_err_set = 1'b1;
        if (|chk_r_len_rem_q) begin
            chk_r_len_rem_din = dr_end_advance ? chk_r_len_rem_q - LENW_ONE : chk_r_len_rem_q;
            chk_r_state_din = S_SERR;
        end
        else begin
            if (dr_end_advance) begin
                cr_start_chk_advance = 1'b1;
                chk_r_state_din = S_IDLE;
            end
            else begin
                chk_r_state_din = S_SERR;
            end
        end
    end
    else if (chk_r_state_q == S_WAIT) begin
        if (dr_end_advance) begin
            cr_start_resp_err_set = engn_r_err_i || engn_parity_err[1] || internal_engn_r_parity_err;
            cr_start_chk_advance = 1'b1;
            chk_r_state_din = S_IDLE;
        end
        else begin
            chk_r_state_din = S_WAIT;
        end
    end
    else begin // Illegal state - will need to be excluded for coverage
        chk_r_state_din = S_IDLE;
    end
end

always @(posedge clk_gated_r or negedge reset_nai) begin
    if (~reset_nai) begin
        chk_r_state_q   <= S_IDLE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        chk_r_addr_q <= 32'h0;
        chk_r_len_rem_q <= {LENW{1'h0}};
        // End of automatics
    end
    else begin
        chk_r_state_q       <= chk_r_state_din;
        chk_r_len_rem_q     <= chk_r_len_rem_din;
        chk_r_addr_q        <= chk_r_addr_din[31:0];
    end
end

assign chk_r_cf_valid      = (cr_remaining_chk_q != CFD);
assign chk_r_df_valid      = (dr_entries_q != DFD) && ((~chk_a_engn_ren_q) || (dr_entries_q != (DFD-1))); // There is space in the fifo. If we have an outstanding transaction, there has to be more than one space in the fifo
assign chk_r_sub_err       = cr_start_chk_get[CF_RESP_LSB];
assign chk_r_en            = (chk_r_state_q == S_RESP) && chk_r_df_valid && (~chk_a_r_busy) && (~chk_a_w_busy) && (~chk_r_parity_err);
assign chk_r_user          = chk_r_en ? cr_start_chk_get[CF_USER_MSB:CF_USER_LSB] : {ENGNUW{1'b0}};
assign chk_r_id            = chk_r_en ? cr_start_chk_get[CF_ID_MSB:CF_ID_LSB] : {IDW{1'b0}};
assign chk_r_size          = chk_r_en ? cr_start_chk_get[CF_SIZE_MSB:CF_SIZE_LSB] : 3'd0;
assign chk_r_prot          = chk_r_en ? cr_start_chk_get[CF_PROT_MSB:CF_PROT_LSB] : 3'd0;
assign chk_r_len           = chk_r_en ? cr_start_chk_get[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB] : {LENW{1'd0}};
assign chk_r_burst         = chk_r_en ? cr_start_chk_get[CF_BURST_MSB:CF_BURST_LSB] : 2'd0;
assign chk_r_last          = chk_r_en ? ~(|chk_r_len_rem_q) : 1'b0;
assign chk_r_addr_adv_shft = 39'h00_0000_0001 << chk_r_size;
assign chk_r_addr_adv      = chk_r_en ? chk_r_addr_adv_shft[31:0] : 32'h0000_0000;

/*
* Engine Write channel controller
*/

// Engine write control signals
// reg  [1:0]          chk_w_state_din;
// reg  [1:0]          chk_w_state_q;
reg  [LENW:0]       chk_w_len_rem_din;
reg  [LENW:0]       chk_w_len_rem_q;
reg  [32:0]         chk_w_addr_din; // Adding extra bit for overflow
reg  [31:0]         chk_w_addr_q;
reg                 chk_w_dw_cplt_din;
reg                 chk_w_dw_cplt_q;

wire                chk_w_cf_valid;
wire                chk_w_df_valid;
wire                chk_w_sub_err;
wire                chk_w_engn_err;
wire                chk_w_en;
wire [IDW-1:0]      chk_w_id;
wire [ENGNUW-1:0]   chk_w_user;
wire [2:0]          chk_w_size;
wire [2:0]          chk_w_prot;
wire [LENW-1:0]     chk_w_len;
wire [1:0]          chk_w_burst;
wire [STRBW-1:0]    chk_w_wstrb;
wire                chk_w_perr; //Parity error on wdata
wire                chk_w_last;
wire [31:0]         chk_w_addr_adv;
wire [38:0]         chk_w_addr_adv_shft;
//wire                chk_w_wlast_err; //pre-defined

// Wires from engine read/write arbitration
wire                chk_a_valid_w;
wire                chk_a_invalid_w;
reg                 chk_a_engn_wen_q;

wire chk_w_engn_write = chk_a_engn_wen_q && (engn_w_rdy_i || engn_w_err_i);

always @(*) begin
    chk_w_len_rem_din = chk_w_len_rem_q;
    chk_w_addr_din = {1'b0,chk_w_addr_q};
    chk_w_dw_cplt_din = chk_w_dw_cplt_q;

    cw_start_chk_advance = 1'b0;
    cw_start_resp_err_set = 1'b0;

    if (chk_w_state_q == S_IDLE) begin
        if (chk_w_cf_valid) begin
            if (chk_w_sub_err) begin
                if (axi_b_state_q == S_IDLE) begin
                    chk_w_state_din = S_IDLE;
                    cw_start_chk_advance = 1'b1;
                end
                else if (chk_r_state_din == S_IDLE) begin // start transaction only if read channel is IDLE
                    chk_w_state_din = S_WAIT;
                end
                else begin
                    chk_w_state_din = S_IDLE;
                end
            end
            else if (chk_r_state_din == S_IDLE) begin // start transaction only if read channel is IDLE
                chk_w_state_din = S_RESP;
                chk_w_len_rem_din = {1'b0,cw_start_chk_get[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
                chk_w_addr_din = {1'b0,cw_start_chk_get[CF_ADDR_MSB:CF_ADDR_LSB]};
            end
            else begin
                chk_w_state_din = S_IDLE;
            end
        end
        else if (cw_end_advance) begin
            if (axi_aw_err) begin
                chk_w_state_din = S_IDLE;
            end
            else if (chk_r_state_din == S_IDLE) begin // start transaction only if read channel is IDLE
                chk_w_state_din = S_RESP;
                chk_w_len_rem_din = {1'b0,cw_end_set[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB]};
                chk_w_addr_din = {1'b0,cw_end_set[CF_ADDR_MSB:CF_ADDR_LSB]};
            end
            else begin
                chk_w_state_din = S_IDLE;
            end
            end
        else begin
            chk_w_state_din = S_IDLE;
        end
    end
    else if (chk_w_state_q == S_RESP) begin
        if (chk_w_wlast_err || (chk_w_en && chk_a_invalid_w && chk_w_rdy_i) || (chk_w_en && chk_w_perr) || (engn_w_err_i && engn_wen_o) || engn_parity_err[0] || chk_w_parity_err || internal_engn_w_parity_err) begin
            cw_start_resp_err_set = 1'b1;
            chk_w_addr_din = 33'h0_0000_0000;
            chk_w_len_rem_din = dw_start_advance ? chk_w_len_rem_q : (chk_w_len_rem_q + LENW_ONE);
            chk_w_state_din = S_SERR;
        end
        else if (chk_w_en && chk_a_valid_w) begin
            if (chk_w_rdy_i && (~chk_a_r_busy) && (~chk_a_w_busy)) begin
                if (|chk_w_len_rem_q) begin
                    chk_w_len_rem_din = chk_w_len_rem_q - LENW_ONE;
                    chk_w_state_din = S_RESP;
                    chk_w_addr_din = (chk_w_addr_adv == 32'h0000_0004) ? {chk_w_addr_q[31:2],2'b00} + chk_w_addr_adv :
                                     (chk_w_addr_adv == 32'h0000_0002) ? {chk_w_addr_q[31:1],1'b0} + chk_w_addr_adv :
                                     chk_w_addr_q + chk_w_addr_adv;
                end
                else begin
                    chk_w_addr_din = 33'h0_0000_0000;
                    chk_w_state_din = S_WAIT;
                    chk_w_dw_cplt_din = chk_w_engn_write;
                end
            end
            else begin
                chk_w_state_din = S_RESP;
            end
        end
        else begin
            chk_w_state_din = S_RESP;
        end
    end
    else if (chk_w_state_q == S_SERR) begin
        cw_start_resp_err_set = 1'b1;
        if (|chk_w_len_rem_q) begin
            if (dw_start_advance) begin
                chk_w_len_rem_din = chk_w_len_rem_q - LENW_ONE;
                chk_w_state_din = S_SERR;
            end
            else begin
                chk_w_state_din = S_SERR;
            end
        end
        else begin
            if (axi_b_state_q == S_IDLE) begin
                cw_start_chk_advance = 1'b1;
                chk_w_state_din = S_IDLE;
            end
            else begin
                chk_w_state_din = S_WAIT;
            end
        end
    end
    else if (chk_w_state_q == S_WAIT) begin
        cw_start_resp_err_set = engn_w_err_i || internal_engn_w_parity_err;

        if (engn_wen_o && !engn_w_rdy_i) begin
            chk_w_dw_cplt_din = chk_w_dw_cplt_q || chk_w_engn_write;
            chk_w_state_din = S_WAIT;
        end
        else if ((axi_b_state_q == S_IDLE) && (chk_w_dw_cplt_q || chk_w_engn_write || chk_w_sub_err || chk_w_engn_err)) begin
            cw_start_chk_advance = 1'b1;
            chk_w_dw_cplt_din = 1'b0;
            chk_w_state_din = S_IDLE;
        end
        else begin
            chk_w_dw_cplt_din = chk_w_dw_cplt_q || chk_w_engn_write;
            chk_w_state_din = S_WAIT;
        end
    end
    else begin // Illegal state - will need to be excluded for coverage
        chk_w_state_din = S_IDLE;
    end
end

always @(posedge clk_gated_w or negedge reset_nai) begin
    if (~reset_nai) begin
        chk_w_state_q   <= S_IDLE;
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        chk_w_addr_q <= 32'h0;
        chk_w_dw_cplt_q <= 1'h0;
        chk_w_len_rem_q <= '0;
        // End of automatics
    end
    else begin
        chk_w_state_q       <= chk_w_state_din;
        chk_w_len_rem_q     <= chk_w_len_rem_din;
        chk_w_addr_q        <= chk_w_addr_din[31:0];
        chk_w_dw_cplt_q     <= chk_w_dw_cplt_din;
    end
end

assign chk_w_cf_valid   = (cw_remaining_chk_q != CFD);
assign chk_w_df_valid   = |dw_entries_q; // Entries is nonzero
assign chk_w_sub_err    = cw_start_chk_get[CF_RESP_LSB];
assign chk_w_engn_err   = cw_start_chk_get[CF_RESP_MSB];
assign chk_w_en         = (chk_w_state_q == S_RESP) && (chk_w_df_valid || dw_end_advance) && (~chk_a_r_busy) && (~chk_a_w_busy) && (~chk_w_parity_err);
assign chk_w_user       = chk_w_en ? cw_start_chk_get[CF_USER_MSB:CF_USER_LSB] : {ENGNUW{1'b0}};
assign chk_w_id         = chk_w_en ? cw_start_chk_get[CF_ID_MSB:CF_ID_LSB] : {IDW{1'b0}};
assign chk_w_size       = chk_w_en ? cw_start_chk_get[CF_SIZE_MSB:CF_SIZE_LSB] : 3'd0;
assign chk_w_prot       = chk_w_en ? cw_start_chk_get[CF_PROT_MSB:CF_PROT_LSB] : 3'd0;
assign chk_w_len        = chk_w_en ? cw_start_chk_get[((CF_LEN_LSB+LENW)-1):CF_LEN_LSB] : {LENW{1'd0}};
assign chk_w_burst      = chk_w_en ? cw_start_chk_get[CF_BURST_MSB:CF_BURST_LSB] : 2'd0;
assign chk_w_wstrb      = (chk_w_en && chk_w_df_valid) ? dw_start_get[((STRBW+DW)-1):DW] :
                          (chk_w_en && dw_end_advance) ? dw_end_set[((STRBW+DW)-1):DW] : {STRBW{1'b0}};
assign chk_w_perr       = (chk_w_en && chk_w_df_valid) ? dw_start_get[STRBW+DW] :
                          (chk_w_en && dw_end_advance) ? dw_end_set[STRBW+DW] : 1'b0;
assign chk_w_last       = chk_w_en ? ~(|chk_w_len_rem_q) : 1'b0;
assign chk_w_addr_adv_shft = 39'h00_0000_0001 << chk_w_size;
assign chk_w_addr_adv   = chk_w_en ? chk_w_addr_adv_shft[31:0] : 32'h0000_0000;
generate //Added the generate statement as VCS compile had issues.
if (DFDP1_W > 1) begin: dfdp_w_gt1
        assign chk_w_wlast_err  =   (axi_w_wlast_err && (~(|dw_entries_q[DFDP1_W-1:1])) && (~chk_a_r_busy) && (~chk_a_w_busy)) ; // neet to gate on chk_w_last
end else begin :dfdp_w_1
        assign chk_w_wlast_err = (axi_w_wlast_err && (~chk_a_r_busy) && (~chk_a_w_busy)); // Entries is 1 or fewer and axi_w_wlast_err
end
endgenerate
//Engine Read/Write arbitration
wire               chk_a_engn_ren_din;
//reg             chk_a_engn_ren_q; // Predefined
wire               chk_a_engn_wen_din;
// reg             chk_a_engn_wen_q; // Predefined
wire [31:0]        chk_a_engn_addr_din;
reg  [31:0]        chk_a_engn_addr_q;
wire [DW-1:0]      chk_a_engn_wdata_din;
reg  [DW-1:0]      chk_a_engn_wdata_q;
wire [STRBW-1:0]   chk_a_engn_wstrb_din;
reg  [STRBW-1:0]   chk_a_engn_wstrb_q;
wire [IDW-1:0]     chk_a_engn_id_din;
reg  [IDW-1:0]     chk_a_engn_id_q;
wire [ENGNUW-1:0]  chk_a_engn_user_din;
reg  [ENGNUW-1:0]  chk_a_engn_user_q;

wire chk_a_read;
wire chk_a_write;
wire chk_a_r_adv;
wire chk_a_w_adv;

assign chk_a_engn_ren_din   = chk_a_r_adv ? 1'b1 :
                              ((~chk_a_r_busy) ? 1'b0 :
                              chk_a_engn_ren_q);
assign chk_a_engn_wen_din   = chk_a_w_adv ? 1'b1 :
                              ((~chk_a_w_busy) ? 1'b0 :
                              chk_a_engn_wen_q);
assign chk_a_engn_addr_din  = chk_a_r_adv ? chk_r_addr_q :
                              chk_a_w_adv ? chk_w_addr_q :
                              ((~chk_a_r_busy) && (~chk_a_w_busy)) ? 32'd0 :
                              chk_a_engn_addr_q;
assign chk_a_engn_wdata_din = (chk_a_w_adv && chk_w_df_valid) ? dw_start_get[DW-1:0] :
                              (chk_a_w_adv && dw_end_advance) ? dw_end_set[DW-1:0] :
                              (~chk_a_w_busy) ? {DW{1'b0}} :
                              chk_a_engn_wdata_q;
assign chk_a_engn_wstrb_din = chk_a_w_adv ? chk_w_wstrb :
                              (~chk_a_w_busy) ? {STRBW{1'b0}} :
                              chk_a_engn_wstrb_q;
assign chk_a_engn_id_din    = chk_a_r_adv ? chk_r_id :
                              chk_a_w_adv ? chk_w_id :
                              ((~chk_a_r_busy) && (~chk_a_w_busy)) ? {IDW{1'b0}} :
                              chk_a_engn_id_q;
assign chk_a_engn_user_din  = chk_a_r_adv ? chk_r_user :
                              chk_a_w_adv ? chk_w_user :
                              ((~chk_a_r_busy) && (~chk_a_w_busy)) ? {ENGNUW{1'b0}} :
                              chk_a_engn_user_q;

always @(posedge clk_gated_a or negedge reset_nai) begin
    if (~reset_nai) begin
        /*AUTORESET*/
        // Beginning of autoreset for uninitialized flops
        chk_a_engn_addr_q <= 32'h0;
        chk_a_engn_id_q <= {IDW{1'b0}};
        chk_a_engn_ren_q <= 1'h0;
        chk_a_engn_user_q <= {ENGNUW{1'b0}};
        chk_a_engn_wdata_q <= {DW{1'b0}};
        chk_a_engn_wstrb_q <= {STRBW{1'b0}};
        chk_a_engn_wen_q <= 1'h0;
        // End of automatics
    end
    else begin
        chk_a_engn_ren_q    <= chk_a_engn_ren_din;
        chk_a_engn_wen_q    <= chk_a_engn_wen_din;
        chk_a_engn_addr_q   <= chk_a_engn_addr_din;
        chk_a_engn_wdata_q  <= chk_a_engn_wdata_din;
        chk_a_engn_wstrb_q  <= chk_a_engn_wstrb_din;
        chk_a_engn_id_q     <= chk_a_engn_id_din;
        chk_a_engn_user_q   <= chk_a_engn_user_din;
    end
end

assign chk_a_read   = chk_r_en;
assign chk_a_write  = chk_w_en && (!chk_w_perr);
assign chk_a_r_adv  = chk_a_read && chk_r_rdy_i && chk_valid_r_i && (~chk_a_r_busy) && (~chk_a_w_busy) && (~(engn_ren_o && engn_r_err_i)) && !internal_engn_r_parity_err;
assign chk_a_w_adv  = chk_a_write && chk_w_rdy_i && chk_valid_w_i && (~chk_a_r_busy) && (~chk_a_w_busy) && (~(engn_wen_o && engn_w_err_i)) && !internal_engn_w_parity_err;
assign chk_a_r_busy = engn_ren_o && ~(engn_r_rdy_i || engn_r_err_i);
assign chk_a_w_busy = engn_wen_o && ~(engn_w_rdy_i || engn_w_err_i);

assign engn_ren_o   = chk_a_engn_ren_q && !internal_engn_r_parity_err;
assign engn_wen_o   = chk_a_engn_wen_q && !internal_engn_w_parity_err;
assign engn_addr_o  = chk_a_engn_addr_q;
assign engn_wdata_o = chk_a_engn_wdata_q;
assign engn_wstrb_o = chk_a_engn_wstrb_q;
assign engn_id_o    = chk_a_engn_id_q;
assign engn_user_o  = chk_a_engn_user_q;

assign chk_addr_o   = chk_a_read ? chk_r_addr_q :
                      chk_a_write ? chk_w_addr_q :
                      32'd0;
assign chk_id_o     = chk_a_read ? chk_r_id :
                      chk_a_write ? chk_w_id :
                      {IDW{1'b0}};
assign chk_user_o   = chk_a_read ? chk_r_user :
                      chk_a_write ? chk_w_user :
                      {ENGNUW{1'b0}};
assign chk_read_o   = chk_a_read;
assign chk_write_o  = chk_a_write;
assign chk_en_o     = engn_ren_o || engn_wen_o;
assign chk_size_o   = chk_a_read ? chk_r_size :
                      chk_a_write ? chk_w_size :
                      3'd0;
assign chk_prot_o   = chk_a_read ? chk_r_prot :
                      chk_a_write ? chk_w_prot :
                      3'd0;
assign chk_len_o    = chk_a_read ? chk_r_len[LENW-1:0] :
                      chk_a_write ? chk_w_len[LENW-1:0] :
                      {LENW{1'b0}};
assign chk_burst_o  = chk_a_read ? chk_r_burst :
                      chk_a_write ? chk_w_burst :
                      2'd0;
assign chk_wdata_o  = (chk_a_write && chk_w_df_valid) ? dw_start_get[DW-1:0] :
                      (chk_a_write && dw_end_advance) ? dw_end_set[DW-1:0] :
                      {DW{1'b0}};
assign chk_wstrb_o  = chk_a_write ? chk_w_wstrb :
                      {STRBW{1'b0}};
assign chk_last_o   = chk_a_read ? chk_r_last :
                      chk_a_write ? chk_w_last :
                      1'b0;

assign dr_end_set   = engn_rdata_i;

assign chk_a_valid_r    = chk_a_read ? chk_valid_r_i : 1'b0;
assign chk_a_invalid_r  = chk_a_read ? chk_invalid_r_i : 1'b0;
assign chk_a_valid_w    = chk_a_write ? chk_valid_w_i : 1'b0;
assign chk_a_invalid_w  = chk_a_write ? chk_invalid_w_i : 1'b0;

assign dr_end_advance   = (chk_r_state_q == S_IDLE) ? 1'b0 : (engn_ren_o && (engn_r_rdy_i || engn_r_err_i)) || internal_engn_r_parity_err || ((chk_r_state_q == S_SERR) && chk_r_df_valid && !(engn_ren_o && (!engn_r_rdy_i)));

assign dw_start_advance = (chk_write_o && chk_w_rdy_i) || ((chk_w_state_q == S_SERR) && (|chk_w_len_rem_q) && chk_w_df_valid); // Can improve this by ORing dw_end_advance into chk_w_df_valid

/*
 * Engine interface parity logic
 */

wire [31:0]                       engn_parity_err_r_addr;
wire [31:0]                       engn_parity_err_w_addr;
reg [PCHKW-1:0]                   engn_parity_err_chk;

generate if (ENGN_PARITY_EN == 1)
begin : gen_ENGN_PARITY
    // Generate engine parity outputs (AR, AW, W channel)
    // Engine should only check parity when data is valid (engn en and engn ready is high)
    reg [(DW/32)-1:0] engn_wdatachk;
    reg [(DW/32)-1:0] chk_wdatachk;

    always @(*) begin
        // Generate parity for every 32 bits of data
        for (integer i = 0; i < (DW/32); i = i + 1) begin
            engn_wdatachk[i] = ~^engn_wdata_o[i*32 +: 32];
            chk_wdatachk[i] = ~^chk_wdata_o[i*32 +: 32];
        end
    end
    assign engn_idchk_o = ~^engn_id_o;
    assign engn_wstrbchk_o = ~^engn_wstrb_o;
    assign engn_userchk_o = ~^engn_user_o;
    assign chk_idchk_o = ~^chk_id_o;
    assign chk_lenchk_o = ~^chk_len_o;
    assign chk_sizechk_o = ~^chk_size_o;
    assign chk_burstchk_o = ~^chk_burst_o;
    assign chk_protchk_o = ~^chk_prot_o;
    assign chk_wstrbchk_o = ~^chk_wstrb_o;
    assign chk_lastchk_o = ~^chk_last_o;
    assign chk_userchk_o = ~^chk_user_o;
    assign engn_wdatachk_o = engn_wdatachk;
    assign chk_wdatachk_o = chk_wdatachk;
    assign engn_addrchk_o = ~^engn_addr_o;
    assign chk_addrchk_o = ~^chk_addr_o;

    // Check engine parity inputs (R channel)
    // Check parity for every 32 bits of data
    always @(*) begin
        engn_parity_err_chk = {PCHKW{1'b0}};
        
        if(!err_parity_chk_disable_i) begin
            // Check parity for every 32 bits of data
            for (integer i = 0; i < EPDW; i = i + 1) begin
                engn_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = (engn_ren_o && engn_r_rdy_i) ? (engn_rdatachk_i[i] != ~^engn_rdata_i[i*32 +: 32]) : 1'b0;
            end
        end
        // Drive remaining parity check error signals to 0, since we only check engine rdata parity
        engn_parity_err_chk[ERR_CHK_RIDCHK_MSB:ERR_CHK_AWIDCHK_LSB] = {(ERR_CHK_RDATACHK_LSB){1'b0}};
        engn_parity_err_chk[ERR_CHK_RLASTCHK:ERR_CHK_RRESPCHK] = {(ERR_CHK_RLASTCHK-ERR_CHK_RDATACHK_MSB){1'b0}};
    end
    assign engn_parity_err[1] = |engn_parity_err_chk[ERR_CHK_RDATACHK_MSB:ERR_CHK_RDATACHK_LSB]; // parity error during read transaction
    assign engn_parity_err[0] = 1'b0; // No engn parity errors checked for write transactions
    assign engn_parity_err_r_addr = engn_parity_err[1] ? engn_addr_o : 32'h0;
    assign engn_parity_err_w_addr = '0;
end
else // generate if ENGN_PARITY_EN == 0
begin : gen_NO_ENGN_PARITY
    // Tie off unused engine parity output ports - engine should not check these parity signals
    assign engn_idchk_o = '0;
    assign engn_addrchk_o = '0;
    assign engn_wdatachk_o = '0;
    assign engn_wstrbchk_o = '0;
    assign engn_userchk_o = '0;
    assign chk_idchk_o = '0;
    assign chk_addrchk_o = '0;
    assign chk_lenchk_o = '0;
    assign chk_sizechk_o = '0;
    assign chk_burstchk_o = '0;
    assign chk_protchk_o = '0;
    assign chk_wdatachk_o = '0;
    assign chk_wstrbchk_o = '0;
    assign chk_lastchk_o = '0;
    assign chk_userchk_o = '0;

    assign engn_parity_err = 2'b00;
    assign engn_parity_err_r_addr = 32'h0;
    assign engn_parity_err_w_addr = '0;
    assign engn_parity_err_chk = '0;//{PCHKW{1'b0}};
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
     * 1) The length field is not covered
     * 2) Data parity can only handle multiples of 32
     * 3) Data strobe parity for data width > 256
     * 4) Address error output is only correct when the error is for the engine interface
     * 5) Missing protection for single error bits used for internal error tracking like in the cr_fifo_q
     * 
     */
    generate if ((AXI_PARITY_EN == 1) || (ENGN_PARITY_EN == 1))
    begin : gen_INTERNAL_PARITY
        // Generate internal parity
        
        //Read parity
        logic arprot_chk;
        logic araddr_chk;
        logic arid_chk;
        logic aruser_chk;
        
        localparam CR_CHK_W = 4;
        localparam CR_CHK_PROT = 3;
        localparam CR_CHK_ADDR = 2;
        localparam CR_CHK_ID = 1;
        localparam CR_CHK_USER = 0;
        logic [CR_CHK_W-1:0] cr_chk_end_set;    
        logic [CR_CHK_W-1:0] cr_chk_start_axi_get;
        logic [CR_CHK_W-1:0] cr_chk_start_chk_get;
       
        logic [CR_CHK_W-1:0] cr_chk_fifo_din [0:CFD-1];
        logic [CR_CHK_W-1:0] cr_chk_fifo_q [0:CFD-1];
        
        logic [EPDW-1:0] dr_chk_end_set;  
        logic [EPDW-1:0] dr_chk_fifo_din [0:DFD-1];
        logic [EPDW-1:0] dr_chk_fifo_q [0:DFD-1];
        
        logic [EPDW-1:0] dr_chk_start_get;
        
        always_comb begin
            arprot_chk = ~^arprot_i;
            araddr_chk = ~^araddr_i;
            arid_chk = ~^arid_i;
            aruser_chk = ~^aruser_i[ENGNUW-1:0];
            
            cr_chk_end_set = {arprot_chk,araddr_chk,arid_chk,aruser_chk};
            cr_chk_start_axi_get = cr_chk_fifo_q[cr_start_axi_q];
            cr_chk_start_chk_get = cr_chk_fifo_q[cr_start_chk_q];
            
            for (integer i = 0; i < EPDW; i = i + 1) begin
                dr_chk_end_set[i] = ~^engn_rdata_i[i*32 +: 32];
            end   
            
            dr_chk_start_get = dr_chk_fifo_q[dr_start_q];
        end
        
        always_comb begin
            integer i;
            for (i=0; i<CFD; i = i+1) begin
                if (i == cr_end_q) begin // CR FIFO
                    cr_chk_fifo_din[i][CR_CHK_W-1:0] = cr_end_advance ? cr_chk_end_set:
                                            cr_chk_fifo_q[i][CR_CHK_W-1:0];
                end
                else begin
                    cr_chk_fifo_din[i][CR_CHK_W-1:0] = cr_chk_fifo_q[i][CR_CHK_W-1:0];
                end
            end
            for (i=0; i<DFD; i = i+1) begin
                if (i == dr_end_q) begin // DR FIFO
                    dr_chk_fifo_din[i] = dr_end_advance ? dr_chk_end_set :
                                     dr_chk_fifo_q[i];
                end
                else begin
                    dr_chk_fifo_din[i] = dr_chk_fifo_q[i];
                end
            end
        end
        
        always_ff @(posedge clk_gated_r or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                for (i=0; i<CFD; i=i+1) begin // CR FIFO
                    cr_chk_fifo_q[i] <= '0;
                end
                for (i=0; i<DFD; i=i+1) begin // DR FIFO
                    dr_chk_fifo_q[i] <= '0;
                end
            end
            else begin
                for (i=0; i<CFD; i=i+1) begin // CR FIFO
                    cr_chk_fifo_q[i] <= cr_chk_fifo_din[i];
                end
                for (i=0; i<DFD; i=i+1) begin // DR FIFO
                    dr_chk_fifo_q[i] <= dr_chk_fifo_din[i];
                end
            end
        end
        
        logic chk_r_addr_chk_din;
        logic chk_r_addr_chk_q;
        
        always_comb begin
            chk_r_addr_chk_din = chk_r_addr_chk_q;
            if(chk_r_state_q == S_IDLE) begin
                //Grab address parity from AXI incoming parity FIFO
                if(chk_r_cf_valid) begin
                    chk_r_addr_chk_din = cr_chk_start_chk_get[CR_CHK_ADDR];
                end
                else begin
                    chk_r_addr_chk_din = cr_chk_end_set[CR_CHK_ADDR];
                end
            end
            else if ((chk_r_state_q == S_RESP) && chk_r_en && chk_a_valid_r) begin
                //Calculate latest incremented address parity
                chk_r_addr_chk_din = ~^chk_r_addr_din;
            end
        end
        
        always_ff @(posedge clk_gated_r or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                chk_r_addr_chk_q <= '0;
                axi_internal_r_parity_err_q <= '0;
            end
            else begin
                chk_r_addr_chk_q <= chk_r_addr_chk_din;
                axi_internal_r_parity_err_q <= axi_internal_r_parity_err_din;
            end
        end
        
        //Write parity
        logic awprot_chk;
        logic awaddr_chk;
        logic awid_chk;
        logic awuser_chk;
        
        localparam CW_CHK_W = 4;
        localparam CW_CHK_PROT = 3;
        localparam CW_CHK_ADDR = 2;
        localparam CW_CHK_ID = 1;
        localparam CW_CHK_USER = 0;
        logic [CW_CHK_W-1:0] cw_chk_end_set;    
        logic [CW_CHK_W-1:0] cw_chk_start_chk_get;
       
        logic [CW_CHK_W-1:0] cw_chk_fifo_din [0:CFD-1];
        logic [CW_CHK_W-1:0] cw_chk_fifo_q [0:CFD-1];
        
        logic [EPDW:0] dw_chk_end_set;  
        logic [EPDW:0] dw_chk_fifo_din [0:DFD-1];
        logic [EPDW:0] dw_chk_fifo_q [0:DFD-1];
        
        logic [EPDW:0] dw_chk_start_get;
        
        always_comb begin
            awprot_chk = ~^awprot_i;
            awaddr_chk = ~^awaddr_i;
            awid_chk = ~^awid_i;
            awuser_chk = ~^awuser_i[ENGNUW-1:0];
            
            cw_chk_end_set = {awprot_chk,awaddr_chk,awid_chk,awuser_chk};
            cw_chk_start_chk_get = cw_chk_fifo_q[cw_start_chk_q];
            
            for (integer i = 0; i < EPDW; i = i + 1) begin
                dw_chk_end_set[i] = ~^wdata_i[i*32 +: 32];
            end   
            dw_chk_end_set[EPDW] = ~^wstrb_i;       
            
            dw_chk_start_get = dw_chk_fifo_q[dw_start_q];
        end
        
        always_comb begin
            integer i;
            for (i=0; i<CFD; i = i+1) begin
                if (i == cw_end_q) begin // CW FIFO
                    cw_chk_fifo_din[i][CW_CHK_W-1:0] = cw_end_advance ? cw_chk_end_set:
                                            cw_chk_fifo_q[i][CW_CHK_W-1:0];
                end
                else begin
                    cw_chk_fifo_din[i][CW_CHK_W-1:0] = cw_chk_fifo_q[i][CW_CHK_W-1:0];
                end
//                cr_chk_fifo_din[i][CF_RESP_MSB] = ((i == cr_start_axi_q) && cr_start_axi_advance) ? 1'b0 :
//                                               ((i == cr_start_chk_q) && cr_start_resp_err_set) ? 1'b1 :
//                                               cr_fifo_q[i][CF_RESP_MSB];
            end
            for (i=0; i<DFD; i = i+1) begin
                if (i == dw_end_q) begin // DW FIFO
                    dw_chk_fifo_din[i] = dw_end_advance ? dw_chk_end_set :
                                     dw_chk_fifo_q[i];
                end
                else begin
                    dw_chk_fifo_din[i] = dw_chk_fifo_q[i];
                end
            end
        end
        
        always_ff @(posedge clk_gated_w or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                for (i=0; i<CFD; i=i+1) begin // CW FIFO
                    cw_chk_fifo_q[i] <= '0;
                end
                for (i=0; i<DFD; i=i+1) begin // DW FIFO
                    dw_chk_fifo_q[i] <= '0;
                end
            end
            else begin
                for (i=0; i<CFD; i=i+1) begin // CW FIFO
                    cw_chk_fifo_q[i] <= cw_chk_fifo_din[i];
                end
                for (i=0; i<DFD; i=i+1) begin // DW FIFO
                    dw_chk_fifo_q[i] <= dw_chk_fifo_din[i];
                end
            end
        end
        
        logic chk_w_addr_chk_din;
        logic chk_w_addr_chk_q;
        
        always_comb begin
            chk_w_addr_chk_din = chk_w_addr_chk_q;
            if(chk_w_state_q == S_IDLE) begin
                //Grab address parity from AXI incoming parity FIFO
                if(chk_w_cf_valid) begin
                    chk_w_addr_chk_din = cw_chk_start_chk_get[CW_CHK_ADDR];
                end
                else begin
                    chk_w_addr_chk_din = cw_chk_end_set[CW_CHK_ADDR];
                end
            end
            else if ((chk_w_state_q == S_RESP) && chk_w_en && chk_a_valid_w) begin
                //Calculate latest incremented address parity
                chk_w_addr_chk_din = ~^chk_w_addr_din;
            end
        end
        
        
        always_ff @(posedge clk_gated_w or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                chk_w_addr_chk_q <= '0;
            end
            else begin
                chk_w_addr_chk_q <= chk_w_addr_chk_din;
            end
        end      
        
        logic axi_b_id_chk_din;
        logic axi_b_id_chk_q;
        logic axi_b_resp_chk_din;
        logic axi_b_resp_chk_q;
        
        always_comb begin
            if((axi_b_state_q == S_IDLE) && cw_start_chk_advance) begin
                axi_b_id_chk_din = cw_chk_start_chk_get[CW_CHK_ID];
                axi_b_resp_chk_din = ~^axi_b_resp_din;
            end
            else begin
                axi_b_id_chk_din = axi_b_id_chk_q;
                axi_b_resp_chk_din = axi_b_resp_chk_q;
            end
        end
        
        always_ff @(posedge clk_gated_w or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                axi_b_id_chk_q <= '0;
                axi_b_resp_chk_q <= '0;
                axi_internal_w_parity_err_q  <= 1'b0;
            end
            else begin
                axi_b_id_chk_q <= axi_b_id_chk_din;
                axi_b_resp_chk_q <= axi_b_resp_chk_din;
                axi_internal_w_parity_err_q <= axi_internal_w_parity_err_din;
            end
        end   
        
        //Common engine interface flop protection
        logic engn_addr_chk_din;
        logic engn_addr_chk_q;
        logic [EPDW-1:0] engn_wdata_chk_din;
        logic [EPDW-1:0] engn_wdata_chk_q;
        logic engn_wstrb_chk_din;
        logic engn_wstrb_chk_q;
        logic engn_id_chk_din;
        logic engn_id_chk_q;
        logic engn_user_chk_din;
        logic engn_user_chk_q;
        
        always_comb begin
            engn_addr_chk_din = chk_a_r_adv ? chk_r_addr_chk_q :
                                chk_a_w_adv ? chk_w_addr_chk_q : engn_addr_chk_q;
            engn_wdata_chk_din = (chk_a_w_adv && chk_w_df_valid) ? dw_chk_start_get[EPDW-1:0] :
                                 (chk_a_w_adv && dw_end_advance) ? dw_chk_end_set[EPDW-1:0] :
                                 engn_wdata_chk_q;
            if(chk_a_w_adv) begin
                engn_wstrb_chk_din = (chk_w_en && chk_w_df_valid) ? dw_chk_start_get[EPDW] : dw_chk_end_set[EPDW];
            end
            else begin
                engn_wstrb_chk_din = engn_wstrb_chk_q;
            end
            engn_id_chk_din    = chk_a_r_adv ? cr_chk_start_chk_get[CR_CHK_ID] :
                                    chk_a_w_adv ? cw_chk_start_chk_get[CW_CHK_ID] :
                                    engn_id_chk_q;
            engn_user_chk_din  = chk_a_r_adv ? cr_chk_start_chk_get[CR_CHK_USER] :
                                    chk_a_w_adv ? cw_chk_start_chk_get[CR_CHK_USER] :
                                    engn_user_chk_q;
        end
        
        always_ff @(posedge clk_gated_a or negedge reset_nai) begin
            integer i;
            if (~reset_nai) begin
                engn_addr_chk_q <= '0;
                engn_wdata_chk_q <= '0;
                engn_wstrb_chk_q <= '0;
                engn_id_chk_q <= '0;
                engn_user_chk_q <= '0;
            end
            else begin
                engn_addr_chk_q <= engn_addr_chk_din;
                engn_wdata_chk_q <= engn_wdata_chk_din;
                engn_wstrb_chk_q <= engn_wstrb_chk_din;
                engn_id_chk_q <= engn_id_chk_din;
                engn_user_chk_q <= engn_user_chk_din;
            end
        end
        
        //Local parity error signals
        logic chk_wstrb_parity_err;
        logic [EPDW-1:0] chk_wdata_parity_err;
        logic internal_engn_addr_parity_err;
        logic internal_engn_id_parity_err;
        logic internal_engn_user_parity_err;
        logic internal_engn_wstrb_parity_err;
        logic [EPDW-1:0] internal_engn_wdata_parity_err;
        
        //Parity check
        always_comb begin
            // initial value, some bits will not be overridden, thus are set here
            internal_parity_err_chk = {PCHKW{1'b0}};
            chk_wstrb_parity_err = '0;
            chk_wdata_parity_err = '0;
            internal_engn_addr_parity_err = '0;
            internal_engn_id_parity_err = '0;
            internal_engn_user_parity_err = '0;
            internal_engn_wstrb_parity_err = '0;
            internal_engn_wdata_parity_err = '0;

            if(!err_parity_chk_disable_i) begin
                //Reads
                //Checker interface
                if((chk_r_state_q == S_RESP) && chk_r_df_valid && (~chk_a_r_busy) && (~chk_a_w_busy)) begin
                    internal_parity_err_chk[ERR_CHK_ARIDCHK_LSB]    = (cr_chk_start_chk_get[CR_CHK_ID]   != ~^cr_start_chk_get[CF_ID_MSB:CF_ID_LSB]);
                    internal_parity_err_chk[ERR_CHK_ARCTLCHK0]      = (cr_chk_start_chk_get[CR_CHK_PROT] != ~^cr_start_chk_get[CF_PROT_MSB:CF_PROT_LSB]);
                    internal_parity_err_chk[ERR_CHK_ARUSERCHK_LSB]  = (cr_chk_start_chk_get[CR_CHK_USER] != ~^cr_start_chk_get[CF_USER_MSB:CF_USER_LSB]);
                    internal_parity_err_chk[ERR_CHK_ARADDRCHK_LSB]  = (chk_r_addr_chk_q != ~^chk_r_addr_q);
                end
                
                //Engine interface
                if(chk_a_engn_ren_q) begin
                    internal_engn_addr_parity_err  = (engn_addr_chk_q != ~^chk_a_engn_addr_q);
                    internal_engn_id_parity_err  = (engn_id_chk_q != ~^chk_a_engn_id_q);
                    internal_engn_user_parity_err  = (engn_user_chk_q != ~^chk_a_engn_user_q);
                end
                
                //AXI response interface
                if((axi_r_state_q == S_RESP) && (!axi_internal_r_parity_err_q) && axi_r_df_valid) begin
                    internal_parity_err_chk[ERR_CHK_RIDCHK_LSB]    = (cr_chk_start_axi_get[CR_CHK_ID] != ~^cr_start_axi_get[CF_ID_MSB:CF_ID_LSB]);
                    for (integer i = 0; i < EPDW; i = i + 1) begin                           
                        if((~axi_r_sub_err) && (~axi_r_chk_err_q)) begin
                            internal_parity_err_chk[ERR_CHK_RDATACHK_LSB+i] = (dr_chk_start_get[i] != ~^dr_start_get[i*32 +: 32]);
                        end
                    end
                    //No response parity as this signal is directly derived and not something flopped
                end
                
                //Writes
                if((chk_w_state_q == S_RESP) && (chk_w_df_valid || dw_end_advance) && (~chk_a_r_busy) && (~chk_a_w_busy)) begin
                    internal_parity_err_chk[ERR_CHK_AWIDCHK_LSB]    = (cw_chk_start_chk_get[CW_CHK_ID]   != ~^cw_start_chk_get[CF_ID_MSB:CF_ID_LSB]);
                    internal_parity_err_chk[ERR_CHK_AWCTLCHK0]      = (cw_chk_start_chk_get[CW_CHK_PROT] != ~^cw_start_chk_get[CF_PROT_MSB:CF_PROT_LSB]);
                    internal_parity_err_chk[ERR_CHK_AWUSERCHK_LSB]  = (cw_chk_start_chk_get[CW_CHK_USER] != ~^cw_start_chk_get[CF_USER_MSB:CF_USER_LSB]);
                    internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB]  = (chk_w_addr_chk_q != ~^chk_w_addr_q);  
                    if(chk_w_df_valid) begin
                        chk_wstrb_parity_err = (dw_chk_start_get[EPDW] != ~^dw_start_get[((STRBW+DW)-1):DW]);
                        for (integer i = 0; i < EPDW; i = i + 1) begin
                            chk_wdata_parity_err[i]  = (dw_chk_start_get[i] != ~^dw_start_get[i*32 +: 32]);
                        end 
                    end
                end
                
                //Engine interface
                if(chk_a_engn_wen_q) begin
                    internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB+1]  = (engn_addr_chk_q != ~^chk_a_engn_addr_q);
                    internal_parity_err_chk[ERR_CHK_AWIDCHK_LSB+1]  = (engn_id_chk_q != ~^chk_a_engn_id_q);
                    internal_parity_err_chk[ERR_CHK_AWUSERCHK_LSB+1]  = (engn_user_chk_q != ~^chk_a_engn_user_q);
                    for (integer i = 0; i < EPDW; i = i + 1) begin
                        internal_engn_wdata_parity_err[i]  = (engn_wdata_chk_q[i] != ~^chk_a_engn_wdata_q[i*32 +: 32]);
                    end   
                    internal_engn_wstrb_parity_err = (engn_wstrb_chk_q != ~^chk_a_engn_wstrb_q);
                end
                
                //AXI response interface
                if((axi_b_state_q == S_RESP) && (!axi_internal_w_parity_err_q)) begin
                    internal_parity_err_chk[ERR_CHK_BIDCHK_LSB] = (axi_b_id_chk_q != ~(^axi_b_id_q));
                    internal_parity_err_chk[ERR_CHK_BRESPCHK] = (axi_b_resp_chk_q != ~(^axi_b_resp_q));
                end
            end
            
            //Using intermediate signals to work around LINT error. May also help with debug
            internal_parity_err_chk[ERR_CHK_ARADDRCHK_LSB+1] = internal_engn_addr_parity_err;
            internal_parity_err_chk[ERR_CHK_ARIDCHK_LSB+1] = internal_engn_id_parity_err;
            internal_parity_err_chk[ERR_CHK_ARUSERCHK_LSB+1] = internal_engn_user_parity_err;
            internal_parity_err_chk[ERR_CHK_WSTRBCHK_LSB] = chk_wstrb_parity_err | internal_engn_wstrb_parity_err;
            for (integer i = 0; i < EPDW; i = i + 1) begin
                internal_parity_err_chk[ERR_CHK_WDATACHK_LSB + i]  = chk_wdata_parity_err[i] | internal_engn_wdata_parity_err[i];
            end

            chk_r_parity_err = |{internal_parity_err_chk[ERR_CHK_ARIDCHK_LSB],
                                internal_parity_err_chk[ERR_CHK_ARCTLCHK0],
                                internal_parity_err_chk[ERR_CHK_ARUSERCHK_LSB],
                                internal_parity_err_chk[ERR_CHK_ARADDRCHK_LSB]};
            
            internal_engn_r_parity_err = |{internal_engn_addr_parity_err,
                                internal_engn_id_parity_err,
                                internal_engn_user_parity_err};
            
            chk_w_parity_err = |{internal_parity_err_chk[ERR_CHK_AWIDCHK_LSB],
                                internal_parity_err_chk[ERR_CHK_AWCTLCHK0],
                                internal_parity_err_chk[ERR_CHK_AWUSERCHK_LSB],
                                internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB],
                                chk_wdata_parity_err,
                                chk_wstrb_parity_err};
            
            internal_engn_w_parity_err = |{internal_parity_err_chk[ERR_CHK_AWIDCHK_LSB+1],
                                internal_parity_err_chk[ERR_CHK_AWUSERCHK_LSB+1],
                                internal_parity_err_chk[ERR_CHK_AWADDRCHK_LSB+1],
                                internal_engn_wdata_parity_err,
                                internal_engn_wstrb_parity_err};
            
            axi_internal_r_parity_err = |{internal_parity_err_chk[ERR_CHK_RIDCHK_MSB:ERR_CHK_RIDCHK_LSB],
                                         internal_parity_err_chk[ERR_CHK_RDATACHK_MSB:ERR_CHK_RDATACHK_LSB]};
            
            axi_internal_w_parity_err = |{internal_parity_err_chk[ERR_CHK_BIDCHK_MSB:ERR_CHK_BIDCHK_LSB],
                                         internal_parity_err_chk[ERR_CHK_BRESPCHK]};
            
            if(rvalid_o && rready_i) begin
                axi_internal_r_parity_err_din = 1'b0;
            end
            else begin
                axi_internal_r_parity_err_din = axi_internal_r_parity_err || axi_internal_r_parity_err_q;
            end
            
            if(bvalid_o && bready_i) begin
                axi_internal_w_parity_err_din = 1'b0;
            end
            else begin
                axi_internal_w_parity_err_din = axi_internal_w_parity_err || axi_internal_w_parity_err_q;
            end
            
            internal_parity_err[1] = (|internal_parity_err_chk[ERR_CHK_RLASTCHK:ERR_CHK_ARIDCHK_LSB]); // parity error during read transaction
            internal_parity_err[0] = (|internal_parity_err_chk[ERR_CHK_BRESPCHK:ERR_CHK_AWIDCHK_LSB]); // parity error during write transaction
            internal_parity_err_r_addr = internal_parity_err[1] ? chk_a_engn_addr_q : 32'h0;
            internal_parity_err_w_addr = internal_parity_err[0] ? chk_a_engn_addr_q : 32'h0; 
        end        
    end
    else // generate if both AXI_PARITY_EN == 0 and ENGN_PARITY_EN == 0
    begin : gen_NO_INTERNAL_PARITY
        assign chk_r_parity_err = '0;
        assign chk_w_parity_err = '0;
        assign internal_engn_r_parity_err = '0;
        assign internal_engn_w_parity_err = '0;
        assign axi_internal_r_parity_err = '0;
        assign axi_internal_r_parity_err_din = '0;
        assign axi_internal_r_parity_err_q = '0;
        assign axi_internal_w_parity_err = '0;
        assign axi_internal_w_parity_err_din = '0;
        assign axi_internal_w_parity_err_q = '0;
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

generate if (AXI_PARITY_EN == 1)
begin : gen_AXI_PARITY
    
    // Generate AXI parity output signals (B, R channel)
    
    //Write response
    logic [PIDW-1:0] axi_b_id_chk;

    always_comb begin
        for (integer i = 0; i < PIDW; i = i + 1) begin
            if(i == (PIDW-1)) begin
                axi_b_id_chk[i] = ~^bid_o[(MIDW-1):((PIDW-1)*8)];
            end
            else begin
                axi_b_id_chk[i] = ~^bid_o[i*8 +: 8];
            end
        end
    end
    
    assign buser_o[BUSER_BIDCHK_MSB:BUSER_BIDCHK_LSB] = axi_b_id_chk;
    assign buser_o[BUSER_BRESPCHK] = ~^bresp_o;

    //Read response
    logic [PIDW-1:0] axi_r_id_chk;
    logic [PDW-1:0] axi_r_data_chk;

    always_comb begin
        for (integer i = 0; i < PIDW; i = i + 1) begin
            if(i == (PIDW-1)) begin
                axi_r_id_chk[i] = ~^rid_o[(MIDW-1):((PIDW-1)*8)];
            end
            else begin
                axi_r_id_chk[i] = ~^rid_o[i*8 +: 8];
            end
        end
        for (integer i = 0; i < PDW; i = i + 1) begin
            axi_r_data_chk[i] = ~^rdata_o[i*8 +: 8];
        end
    end

    assign ruser_o[RUSER_RIDCHK_MSB:RUSER_RIDCHK_LSB] = axi_r_id_chk;
    assign ruser_o[RUSER_RRESPCHK] = ~^rresp_o;
    assign ruser_o[RUSER_RDATACHK_MSB:RUSER_RDATACHK_LSB] = axi_r_data_chk;
    assign ruser_o[RUSER_RLASTCHK] = ~^rlast_o;
        
    // Check AXI parity input signals (AW, AR, W channel)
    logic [PIDW-1:0] axi_aw_id_chk;      
    logic [3:0] axi_aw_addr_chk;         
    logic axi_aw_len_chk;                
    logic axi_aw_ctlchk0_chk;            
    logic [PENGNUW-1:0] axi_aw_user_chk; 
    
    logic [PIDW-1:0] axi_ar_id_chk;      
    logic [3:0] axi_ar_addr_chk;         
    logic axi_ar_len_chk;                
    logic axi_ar_ctlchk0_chk;            
    logic [PENGNUW-1:0] axi_ar_user_chk; 

    logic [PDW-1:0] axi_w_data_chk;      
    logic [PSTRBW-1:0] axi_w_strb_chk;   
    logic axi_w_last_chk;                
    
    assign axi_aw_id_chk       = awuser_i[AWUSER_AWIDCHK_MSB:AWUSER_AWIDCHK_LSB];
    assign axi_aw_addr_chk     = awuser_i[AWUSER_AWADDRCHK_MSB:AWUSER_AWADDRCHK_LSB];
    assign axi_aw_len_chk      = awuser_i[AWUSER_AWLENCHK];
    assign axi_aw_ctlchk0_chk  = awuser_i[AWUSER_AWCTLCHK0];
    assign axi_aw_user_chk     = awuser_i[AWUSER_AWUSERCHK_MSB:AWUSER_AWUSERCHK_LSB];
    
    assign axi_ar_id_chk       = aruser_i[ARUSER_ARIDCHK_MSB:ARUSER_ARIDCHK_LSB];
    assign axi_ar_addr_chk     = aruser_i[ARUSER_ARADDRCHK_MSB:ARUSER_ARADDRCHK_LSB];
    assign axi_ar_len_chk      = aruser_i[ARUSER_ARLENCHK];
    assign axi_ar_ctlchk0_chk  = aruser_i[ARUSER_ARCTLCHK0];
    assign axi_ar_user_chk     = aruser_i[ARUSER_ARUSERCHK_MSB:ARUSER_ARUSERCHK_LSB];

    assign axi_w_data_chk      = wuser_i[WUSER_WDATACHK_MSB:WUSER_WDATACHK_LSB];
    assign axi_w_strb_chk      = wuser_i[WUSER_WSTRBCHK_MSB:WUSER_WSTRBCHK_LSB];
    assign axi_w_last_chk      = wuser_i[WUSER_WLASTCHK];

    always @(*) begin
        // initial value, some bits will not be overridden, thus are set here
        axi_parity_err_chk = {PCHKW{1'b0}};

        // Check AXI parity inputs
        if(!err_parity_chk_disable_i) begin
            for (integer i = 0; i < PIDW; i = i + 1) begin
                if(i == (PIDW-1)) begin
                    axi_parity_err_chk[ERR_CHK_AWIDCHK_MSB] = (awvalid_i && awready_o) ? (axi_aw_id_chk[PIDW-1] != ~^awid_i[(MIDW-1):((PIDW-1)*8)]) : 1'b0;
                    axi_parity_err_chk[ERR_CHK_ARIDCHK_MSB] = (arvalid_i && arready_o) ? (axi_ar_id_chk[PIDW-1] != ~^arid_i[(MIDW-1):((PIDW-1)*8)]) : 1'b0;
                end
                else begin
                    axi_parity_err_chk[ERR_CHK_AWIDCHK_LSB+i] = (awvalid_i && awready_o) ? (axi_aw_id_chk[i] != ~^awid_i[i*8 +: 8]) : 1'b0;
                    axi_parity_err_chk[ERR_CHK_ARIDCHK_LSB+i] = (arvalid_i && arready_o) ? (axi_ar_id_chk[i] != ~^arid_i[i*8 +: 8]) : 1'b0;
                end
            end
            for (integer i = 0; i < 4; i = i + 1) begin
                axi_parity_err_chk[ERR_CHK_AWADDRCHK_LSB+i] = (awvalid_i && awready_o) ? (axi_aw_addr_chk[i] != ~^awaddr_i[i*8 +: 8]) : 1'b0;
                axi_parity_err_chk[ERR_CHK_ARADDRCHK_LSB+i] = (arvalid_i && arready_o) ? (axi_ar_addr_chk[i] != ~^araddr_i[i*8 +: 8]) : 1'b0;
            end
            axi_parity_err_chk[ERR_CHK_AWLENCHK] = (awvalid_i && awready_o) ? (axi_aw_len_chk != ~^awlen_i) : 1'b0;
            axi_parity_err_chk[ERR_CHK_ARLENCHK] = (arvalid_i && arready_o) ? (axi_ar_len_chk != ~^arlen_i) : 1'b0;
            axi_parity_err_chk[ERR_CHK_AWCTLCHK0] = (awvalid_i && awready_o) ? (axi_aw_ctlchk0_chk != ~^{awsize_i,awburst_i,awlock_i,awprot_i}) : 1'b0;
            axi_parity_err_chk[ERR_CHK_ARCTLCHK0] = (arvalid_i && arready_o) ? (axi_ar_ctlchk0_chk != ~^{arsize_i,arburst_i,arlock_i,arprot_i}) : 1'b0;
            for (integer i = 0; i < PENGNUW; i = i + 1) begin
                if(i == (PENGNUW-1)) begin
                    axi_parity_err_chk[ERR_CHK_AWUSERCHK_MSB] = (awvalid_i && awready_o) ? (axi_aw_user_chk[PENGNUW-1] != ~^awuser_i[(ENGNUW-1):((PENGNUW-1)*8)]) : 1'b0;
                    axi_parity_err_chk[ERR_CHK_ARUSERCHK_MSB] = (arvalid_i && arready_o) ? (axi_ar_user_chk[PENGNUW-1] != ~^aruser_i[(ENGNUW-1):((PENGNUW-1)*8)]) : 1'b0;
                end
                else begin
                    axi_parity_err_chk[ERR_CHK_AWUSERCHK_LSB+i] = (awvalid_i && awready_o) ? (axi_aw_user_chk[i] != ~^awuser_i[i*8 +: 8]) : 1'b0;
                    axi_parity_err_chk[ERR_CHK_ARUSERCHK_LSB+i] = (arvalid_i && arready_o) ? (axi_ar_user_chk[i] != ~^aruser_i[i*8 +: 8]) : 1'b0;
                end
            end
            for (integer i = 0; i < PDW; i = i + 1) begin
                axi_parity_err_chk[ERR_CHK_WDATACHK_LSB+i] = (wvalid_i && wready_o) ? (axi_w_data_chk[i] != ~^wdata_i[i*8 +: 8]) : '0;
            end
            axi_parity_err_chk[ERR_CHK_WSTRBCHK_MSB] = (wvalid_i && wready_o) ? (axi_w_strb_chk != ~^wstrb_i) : '0; //Does not work if data > 64bits
            axi_parity_err_chk[ERR_CHK_WLASTCHK] = (wvalid_i && wready_o) ? (axi_w_last_chk != ~^wlast_i) : 1'b0;
        end
    end
    
    assign axi_parity_err[1] = |axi_parity_err_chk[ERR_CHK_ARUSERCHK_MSB:ERR_CHK_ARIDCHK_LSB]; // parity error during read transaction
    assign axi_parity_err[0] = |axi_parity_err_chk[ERR_CHK_WLASTCHK:ERR_CHK_AWIDCHK_LSB]; // parity error during write transaction

    // Check if parity error occured with read or write transaction
    assign axi_parity_err_r_addr = axi_parity_err[1] ? araddr_i : 32'h0;
    assign axi_parity_err_w_addr = axi_parity_err[0] ? awaddr_i : 32'h0;

end
else // generate if AXI_PARITY_EN == 0
begin : gen_NO_AXI_PARITY
    // Tie off unused AXI parity output ports - AXI manager should not check these parity signals
    assign buser_o = {BUW{1'b0}};
    assign ruser_o = {RUW{1'b0}};

    assign axi_parity_err = 2'b00;
    assign axi_parity_err_r_addr = 32'h0;
    assign axi_parity_err_w_addr = 32'h0;
    assign axi_parity_err_chk = '0;//{PCHKW{1'b0}};
end
endgenerate

// Side channel parity error signals
assign err_w_parity_o = engn_parity_err[0] | axi_parity_err[0] | internal_parity_err[0];
assign err_r_parity_o = engn_parity_err[1] | axi_parity_err[1] | internal_parity_err[1];
assign err_parity_o   = err_r_parity_o | err_w_parity_o;
assign err_r_addr_o   = (engn_parity_err[1]  ? engn_parity_err_r_addr : // Want engn parity error to have priority since it will represent the earlier beat
                         internal_parity_err[1] ? internal_parity_err_r_addr :
                         axi_parity_err[1] ? axi_parity_err_r_addr :
                         32'h0);
assign err_w_addr_o   = (engn_parity_err[0] ? engn_parity_err_w_addr : // Want engn parity error to have priority since it will represent the earlier beat
                         internal_parity_err[0] ? internal_parity_err_w_addr :
                         axi_parity_err[0] ? axi_parity_err_w_addr :
                         32'h0);
assign err_chk_o      = engn_parity_err_chk | axi_parity_err_chk | internal_parity_err_chk;

// Clock gating enables defined at end because they rely on signals defined
// throughout code
assign cg_read_en_din  = axi_ar_capture ? 1'b1 :
                         ((cr_remaining_axi_din == CFD) && (axi_r_state_q != S_IDLE) && (axi_r_state_din == S_IDLE)) ? 1'b0 :
                         cg_read_en_q;
assign cg_write_en_din = axi_aw_capture ? 1'b1 :
                         ((cw_remaining_chk_din == CFD) && (axi_b_state_q != S_IDLE) && (axi_b_state_din == S_IDLE)) ? 1'b0 :
                         cg_write_en_q;

assign clock_gate_en_o = cg_read_en_din | cg_read_en_q | cg_write_en_din | cg_write_en_q;

    ////////////////////////////////
    // Assertions
    ////////////////////////////////

   `ifdef MSFT_ABV
        `include "axi_sub_assert.sv"
    `endif

endmodule

`include "msft_axi_undefs.vh"

