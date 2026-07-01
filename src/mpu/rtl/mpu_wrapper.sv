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
// File         : mpu_wrapper.sv
// Description  : Wrapper that combines the MPU core and CSR-generated register interface.
//                Handles address decoding, register access, and access violation reporting.

/* 
    If number of pages are 128 or less, then the MPU register space split is 
    0x00 - 0xFC     - MPU CSR registers including reserved region
    0x100 - 0x1FC   - MPU attributes (enough to hold attributes for 1MB memory)
    
    Otherwise the MPU register space split is
    0x00 - 0xFC     - MPU CSR registes including reserved region
    0x100 - 0xFFC   - Reserved
    0x1000 - 0x1FFC - MPU attributes (enough to hold attributes for 16MB memory)

    Note that in the latter, 0x100 to 0xFFC is a reserved region. This is required because
    MPU attributes region must be aligned to 4K (0x1000). 
    This reserved region is outside CSR and attr reg space, hence need to be manually captured.
    This is captured using addr_decode_err signal
*/

module mpu_wrapper
#(
    parameter ADDR_WIDTH        = 13,
    parameter NUM_PAGES         = 2,
    parameter CRYPTOS_ACC       = 0,        // 1 = support crypto accesses (shared RAM)
    parameter FIXED_8K_MAP      = 0,        // Set to 1 to use 8K address map for legacy MPU design
    parameter REG_DATA_WIDTH    = 32,
    parameter REG_ADDR_WIDTH    = (FIXED_8K_MAP | (NUM_PAGES > 128)) ? 13 : 9,  // Should not override
    parameter ID_WIDTH          = 4,
    parameter ATTRIB_RESET      = 4'h0,     // Reset value for attributes
    parameter ATTRIB_WMASK      = 4'h0,     // Bits masked with 0 will remain at 0
    parameter SINGLE_CYCLE      = 0         // Returns acc_vio in single cycle instead of default 1 stage pipeline
)
(
    //-------------------------------------------
    // to/from logic
    //-------------------------------------------

    input                           clk,
    input                           reset_na,
    input                           clkg_override,
    input                           clkg_test_mode,
    input                           mpu_top_page_acc_en,   // AEB to allow access to top page of SP ROM
    input                           ext_acc_vio,            // Flag access vio from outside
    input                           soft_rst,               // synchronous reset input to reset all of MPU
    // Access information
    input [ADDR_WIDTH-1:0]          addr,
    input [ID_WIDTH-1:0]            id,
    input                           en,
    input                           we,
    input                           xe,
    input                           accsrc, // 0- RP/SP  1- Crypto cores

    // Register interface
    input [REG_ADDR_WIDTH-1:0]      mpu_reg_addr,
    input [REG_DATA_WIDTH-1:0]      mpu_reg_wdata,
    input                           mpu_reg_wr_en,
    input                           mpu_reg_rd_en,

    // Global control signals (affect all pages)
    input                           priv_mode,
    input                           mpu_disable,
    input                           override_nx, // Force no-execution

    // Violation information
    output                          acc_vio,
    output                          busy,

    // Register interface
    output   [REG_DATA_WIDTH-1:0] mpu_reg_rdata,
    output   [1:0]                  mpu_reg_resp,
    output                          mpu_reg_respvalid
);

    /* 
        If memory size > 1MB, then 4KB space is assigned to store attributes = 12b byte addr = 10b word addr 
        If memory size <= 1MB, then 256B space is assigned to store attributes = 8b byte addr = 6b word addr
    */
    localparam ATTR_REG_ADDR_WIDTH = REG_ADDR_WIDTH - 3;
   
    logic [23:0]   accvio_addr;        // From u_mpu of mpu.v
    generate
        if (ADDR_WIDTH < 24) begin
            assign accvio_addr[23:ADDR_WIDTH] = {(24-ADDR_WIDTH){1'b0}};
        end
    endgenerate

    /*AUTOLOGIC*/
    // Beginning of automatic wires (for undeclared instantiated-module outputs)
    logic               accvio_clear;           // From u_regs of mpu_regs.v
    logic               accvio_ex;              // From u_mpu of hsp_mpu.v
    logic [ID_WIDTH-1:0] accvio_id;             // From u_mpu of hsp_mpu.v
    logic               accvio_rd;              // From u_mpu of hsp_mpu.v
    logic               accvio_wr;              // From u_mpu of hsp_mpu.v
    logic               csr_err;                // From u_regs of mpu_regs.v
    logic               int_acc_vio;            // From u_mpu of hsp_mpu.v
    logic               txn_ex;                 // From u_mpu of hsp_mpu.v
    logic               txn_rd;                 // From u_mpu of hsp_mpu.v
    logic               txn_wr;                 // From u_mpu of hsp_mpu.v
    // End of automatics
    
    logic [7:0]                     csr_addr;
    logic                           csr_decode;
    logic                           csr_rd_en;
    logic                           csr_wr_en;
    logic [REG_DATA_WIDTH-1:0]      csr_wdata;
    logic [REG_DATA_WIDTH-1:0]      csr_rdata;
    logic                           csr_accerr;
    logic                           csr_respvalid;

    logic [ATTR_REG_ADDR_WIDTH-1:0] attr_reg_addr;
    logic                           attr_reg_decode;
    logic                           attr_reg_rd_en;
    logic                           attr_reg_wr_en;
    logic [REG_DATA_WIDTH-1:0]      attr_reg_wdata;
    logic [REG_DATA_WIDTH-1:0]      attr_reg_rdata;
    logic                           attr_reg_accerr;
    logic                           attr_reg_respvalid;
    logic                           addr_decode_err;
    logic                           log_acc_vio;
    logic                           log_acc_vio_rd;
    logic                           log_acc_vio_wr;
    logic                           log_acc_vio_ex;
    logic                           vio_valid;
    logic                           mpu_sts_clear;
    
    logic                           clkg_enable;
    logic                           clk_gated;

    assign clkg_enable = (en | busy | accvio_clear | soft_rst | mpu_reg_wr_en | mpu_reg_rd_en | mpu_reg_respvalid | (|(mpu_reg_resp)));
  
    c_clock_gate_ovr clock_gate (
                 .clk        (clk),
                 .enable     (clkg_enable),
                 .ovr_en     (clkg_override),
                 .rst_en     (1'b0),
                 .test_mode  (clkg_test_mode),
                 .gated_clk  (clk_gated)
                 );

    generate
        if(FIXED_8K_MAP | (NUM_PAGES > 128)) begin: gen_more_than_128_pages_block
            assign csr_decode       = (mpu_reg_addr[12:8] == 4'h0);         // Bit 12:8 must be 0 for CSR
            assign attr_reg_decode  = (mpu_reg_addr[12] == 1'h1);           // Bit 12 must be 1 for Attributes
            
            // If not in above range, then it is a decode error
            assign addr_decode_err  = (mpu_reg_rd_en | mpu_reg_wr_en) & (~(csr_decode | attr_reg_decode));

            assign attr_reg_addr    = mpu_reg_addr[11:2];
        end
        else begin: gen_less_than_128_pages_block
            assign csr_decode       = (mpu_reg_addr[8] == 1'h0);           // Bit 8 selects between CSR and Attributes
            assign attr_reg_decode  = (mpu_reg_addr[8] == 1'h1);
            
            assign attr_reg_addr    = mpu_reg_addr[7:2];
            assign addr_decode_err  = 1'h0;
        end
        
    endgenerate

    // CSR addressmap doesn't change based on memory size
    assign csr_addr             = mpu_reg_addr[7:0];
    assign csr_rd_en            = mpu_reg_rd_en & csr_decode;
    assign csr_wr_en            = mpu_reg_wr_en & csr_decode;
    assign csr_wdata            = mpu_reg_wdata;

    assign attr_reg_rd_en       = mpu_reg_rd_en & attr_reg_decode;
    assign attr_reg_wr_en       = mpu_reg_wr_en & attr_reg_decode;
    assign attr_reg_wdata       = mpu_reg_wdata;

    assign mpu_reg_rdata        = attr_reg_decode ? attr_reg_rdata : csr_rdata;
    assign mpu_reg_resp         = {(csr_err | attr_reg_accerr | addr_decode_err), mpu_reg_wr_en};
    assign mpu_reg_respvalid    = csr_respvalid | attr_reg_respvalid | addr_decode_err;

    // Same format as AXI GS response format
    // 2'b00 OK_R; read transaction finished successfully
    // 2'b01 OK_W; write transaction finished successfully
    // 2'b10 SLVERR_R; addressed slave generated error for read access
    // 2'b11 SLVERR_W; addressed slave generated an error for write access

 

    mpu_regs  
      u_regs (/*AUTOINST*/
              // Outputs
              .accvio_clear                       (accvio_clear),
              .mpu_reg_respvalid                  (csr_respvalid), // Templated
              .mpu_reg_err                        (csr_err),       // Templated
              .mpu_reg_rdata                      (csr_rdata[31:0]), // Templated
              // Inputs
              .accvio_id_clear                    (mpu_sts_clear),  // Templated
              .accvio_id_load_enable              (log_acc_vio),   // Templated
              .accvio_id_input                    (accvio_id[3:0]), // Templated
              .accvio_ex_clear                    (mpu_sts_clear),  // Templated
              .accvio_ex_load_enable              (log_acc_vio),   // Templated
              .accvio_ex_input                    (log_acc_vio_ex), // Templated
              .accvio_wr_clear                    (mpu_sts_clear),  // Templated
              .accvio_wr_load_enable              (log_acc_vio),   // Templated
              .accvio_wr_input                    (log_acc_vio_wr), // Templated
              .accvio_rd_clear                    (mpu_sts_clear),  // Templated
              .accvio_rd_load_enable              (log_acc_vio),   // Templated
              .accvio_rd_input                    (log_acc_vio_rd), // Templated
              .accvio_addr_clear                  (mpu_sts_clear),  // Templated
              .accvio_addr_load_enable            (log_acc_vio),   // Templated
              .accvio_addr_input                  (accvio_addr[23:0]), // Templated
              .mpu_reg_wr_en                      (csr_wr_en),     // Templated
              .mpu_reg_rd_en                      (csr_rd_en),     // Templated
              .mpu_reg_addr                       (csr_addr[7:0]), // Templated
              .mpu_reg_wdata                      (csr_wdata[31:0]), // Templated
              .reset_na                           (reset_na),
              .clk                                (clk));


    // expect to always input hsp_mpu 15 bit byte address.
    hsp_mpu #(
              .REG_ADDR_WIDTH                     (ATTR_REG_ADDR_WIDTH),
              /*AUTOINSTPARAM*/
              // Parameters
              .ADDR_WIDTH                         (ADDR_WIDTH),
              .NUM_PAGES                          (NUM_PAGES),
              .CRYPTOS_ACC                        (CRYPTOS_ACC),
              .ID_WIDTH                           (ID_WIDTH),
              .REG_DATA_WIDTH                     (REG_DATA_WIDTH),
              .ATTRIB_RESET                       (ATTRIB_RESET),
              .ATTRIB_WMASK                       (ATTRIB_WMASK),
              .SINGLE_CYCLE                       (SINGLE_CYCLE))
    u_mpu (
           /*AUTOINST*/
           // Outputs
           .int_acc_vio                           (int_acc_vio),
           .accvio_id                             (accvio_id[ID_WIDTH-1:0]),
           .accvio_addr                           (accvio_addr[ADDR_WIDTH-1:0]),
           .accvio_ex                             (accvio_ex),
           .accvio_wr                             (accvio_wr),
           .accvio_rd                             (accvio_rd),
           .txn_rd                                (txn_rd),
           .txn_wr                                (txn_wr),
           .txn_ex                                (txn_ex),
           .busy                                  (busy),
           .reg_rdata                             (attr_reg_rdata[REG_DATA_WIDTH-1:0]), // Templated
           .reg_accerr                            (attr_reg_accerr), // Templated
           .reg_respvalid                         (attr_reg_respvalid), // Templated
           // Inputs
           .clk                                   (clk_gated),     // Templated
           .reset_na                              (reset_na),
           .soft_rst                              (soft_rst),
           .addr                                  (addr[ADDR_WIDTH-1:0]),
           .id                                    (id[ID_WIDTH-1:0]),
           .en                                    (en),
           .we                                    (we),
           .xe                                    (xe),
           .accsrc                                (accsrc),
           .mpu_top_page_acc_en                   (mpu_top_page_acc_en),
           .reg_addr                              (attr_reg_addr[ATTR_REG_ADDR_WIDTH-1:0]), // Templated
           .reg_wdata                             (attr_reg_wdata[REG_DATA_WIDTH-1:0]), // Templated
           .reg_wr                                (attr_reg_wr_en), // Templated
           .reg_rd                                (attr_reg_rd_en), // Templated
           .mpu_disable                           (mpu_disable),
           .priv_mode                             (priv_mode),
           .override_nx                           (override_nx));

    /* Log acc vio only if it already doesn't contain any logged attributes */
    always_ff @( posedge clk or negedge reset_na ) begin
        if(~reset_na) begin
            vio_valid <= 1'h0;
        end
        else begin
            if(mpu_sts_clear) begin
                vio_valid <= 1'h0;
            end
            else if (log_acc_vio) begin
                vio_valid <= 1'h1;
            end
        end
    end

    /* log vio info based on who flagged acc vio
        addr and id are always same regardless of whether internal or external logic flags vio */
    assign log_acc_vio          = ((int_acc_vio | ext_acc_vio) & (~vio_valid));
    assign log_acc_vio_rd       = int_acc_vio ? accvio_rd : (ext_acc_vio ? txn_rd : 1'h0);
    assign log_acc_vio_wr       = int_acc_vio ? accvio_wr : (ext_acc_vio ? txn_wr : 1'h0);
    assign log_acc_vio_ex       = int_acc_vio ? accvio_ex : (ext_acc_vio ? txn_ex : 1'h0);

    assign acc_vio              = (int_acc_vio | ext_acc_vio);

    assign mpu_sts_clear        = accvio_clear | soft_rst;

endmodule

