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
// File        : sinc_cmu_crypto_wrap.sv
// Description : CMU crypto wrapper top-level. Instantiates AES engine, crypto
//               control, key retention, and input buffer for block encryption.
`include "aes.vh"

module sinc_cmu_crypto_wrap
import sinc_pkg::*;
#(
    parameter bit NO_SEED_LOADING   = 1'b0,                     // 1: skip RNG seed DMA reads (AES DRBG starts already-seeded)
    parameter BLOCK_SIZE            = 512,
    parameter CACHE_MEM_ADDR_WIDTH  = 16,
    parameter CACHE_SIZE            = 256,                      // IRAM Cache size in KB
    parameter unsigned KSU_KEY_SLOT_BASE_ADDR = 32'h8F0C_4000,  // 32b KSU key slot base address
    parameter unsigned RNG_SEED_BASE_ADDR = 32'h8F0A_0200,      // 32b RNG seed base address

    parameter BLOCK_SIZEW       = $clog2(BLOCK_SIZE),
    parameter BLOCK_LEN         = BLOCK_SIZE/4,
    parameter BLOCK_LENW        = $clog2(BLOCK_LEN),
    parameter unsigned NUM_AES_BLOCKS = BLOCK_SIZE/16,          // Each AES block consist of 16B or 128b
    parameter NUM_SETS              = ((CACHE_SIZE * 1024) / BLOCK_SIZE) / 4,
    parameter NUM_SETSW             = $clog2(NUM_SETS)
)
(
    input logic                     clk_i,
    input logic                     gclk,
    input logic                     rstn_i,
    input logic                     lp_rstn_i,
    input logic                     clkg_test_mode_i,
    input logic                     clkg_override_i,
    input logic                     sinc_erase_busy_o,
    input logic                     disable_encr_auth_check_i,

    /* CMU control interface */
    input sinc_cmu_cmd_t            cmu_ctrl_cmd,
    input logic                     cmu_ctrl_cmd_vld,
    input logic [23:0]              cmu_ctrl_fetch_block_num,
    input logic                     severe_err,

    output logic                    aes_seeded,
    output logic                    c_wrap_cmd_comp,
    output logic                    c_wrap_cmd_err,
    output logic                    c_wrap_sts_upd,
    output sts_update_t             c_wrap_sts,
    output logic                    c_wrap_fault_err,

    /* CIU interface */
    input logic                     ciu_mem_busy,

    output logic                    cmu_mem_wr,
    output logic [CACHE_MEM_ADDR_WIDTH-1:0] cmu_mem_addr,
    output logic [31:0]             cmu_mem_wdata,

    /* DMA controller interface */
    output logic                    c_wrap_dma_cread,
    input logic                     dma_c_wrap_craccept,
    output logic                    c_wrap_dma_cwrite,
    input logic                     dma_c_wrap_cwaccept,
    output logic [31:0]             c_wrap_dma_caddr,
    output logic [BLOCK_LENW-1:0]   c_wrap_dma_clen,
    output logic                    stop_dma_txn,

    output logic [31:0]             c_wrap_dma_wdata,
    output logic                    c_wrap_dma_w_vld,
    input logic                     dma_c_wrap_w_accept,
    input logic                     dma_c_wrap_cw_comp,
    input logic                     dma_c_wrap_cw_err,

    input logic [31:0]              dma_c_wrap_rdata,
    input logic                     dma_c_wrap_r_vld,
    input logic                     dma_c_wrap_cr_comp,
    input logic                     dma_c_wrap_cr_err,

    /* Register inputs/outputs */
    input logic [23:0]              block_encr_num,
    input logic [11:0]              num_of_blocks,
    input logic [31:0]              block_encr_addr,
    input logic [15:0]              block_encr_key,
    input logic [95:0]              aes_iv_nonce,
    input logic [31:0]              ext_block_base_addr,
    input logic [31:0]              ext_auth_tag_base_addr,
    input logic [127:0]             aes_test_din,
    input logic [17:0]              aes_test_ctrl,

    output logic [127:0]            aes_test_dout,
    output logic                    aes_test_sts_tag_out,
    output logic                    set_aes_test_sts_dout_vld,
    output logic                    clr_aes_test_sts_dout_vld,
    output logic                    aes_test_sts_din_rdy,
    output logic                    aes_test_sts_cfg_key_iv_rdy,
    output logic                    clr_cfg_key_iv_vld,
    output logic                    clr_aes_test_din_vld,
    output logic                    encr_block_sts_upd,
    output logic [11:0]             encr_block_sts
    );

    localparam IB_DEPTH         = NUM_AES_BLOCKS;
    localparam IB_COUNTW        = $clog2(((128 * IB_DEPTH) / 32) + 1);
    logic               busy_o_unused;
    logic               cfg_rdy_o;
    logic               cfg_vld_i;
    logic               cmd_err_o;
    logic               ctx_dout_rdy_i;
    logic               ctx_dout_vld_o;
    logic [383:0]       ctx_in_i;
    logic [383:0]       ctx_out_o_unused;
    logic               din_aad_sel_i;
    logic [4:0]         din_bytecnt_i;
    logic [127:0]       din_i;
    logic               din_last_i;
    logic               din_rdy_o;
    logic               din_vld_i;
    logic               dir_i;
    logic [4:0]         dout_bytecnt_o_unused;
    logic               dout_last_o;
    logic [127:0]       dout_o;
    logic [1:0]         fault_err_o;
    logic               gp_aes_clr;
    logic               ib_empty;
    logic               ib_ob_clr;
    logic [127:0]       ib_pop_data;
    logic               ib_pop_en;
    logic               ib_pop_rdy;
    logic [31:0]        ib_push_data;
    logic               ib_push_en;
    logic               iv_ctx_rdy_o;
    logic               iv_ctx_sel_i;
    logic               iv_ctx_vld_i;
    logic [127:0]       iv_i;
    logic [255:0]       key_i;
    logic               key_rdy_o;
    logic [1:0]         key_size_i;
    logic               key_vld_i;
    logic [3:0]         mode_i;
    logic               ob_empty;
    logic [31:0]        ob_pop_data;
    logic               ob_pop_en;
    logic               ob_pop_rdy;
    logic [127:0]       ob_push_data;
    logic               ob_push_en;
    logic [31:0]        seed_i;
    logic               seed_rdy_o;
    logic               seed_vld_i;
    logic               skip_key_i;
    logic [127:0]       tag_o;
    logic               tag_rdy_i;
    logic               tag_vld_o;
    logic [IB_COUNTW-1:0] unused_ib_entries_in_use;
    logic               unused_ib_full;
    logic               unused_ib_overflow_err;
    logic               unused_ib_push_rdy;
    logic               unused_ib_underflow_err;
    logic [2:0]         unused_ob_entries_in_use;
    logic               unused_ob_full;
    logic               unused_ob_overflow_err;
    logic               unused_ob_push_rdy;
    logic               unused_ob_underflow_err;
    sinc_cmu_ctrl_fsm_t             state;
    sinc_cmu_ctrl_fsm_t             next_state;

    logic                           is_state_fetch_block;

    

    sinc_cmu_crypto_wrap_ctrl #(
        // Parameters
        .NO_SEED_LOADING  (NO_SEED_LOADING),
        .BLOCK_SIZE       (BLOCK_SIZE),
        .CACHE_SIZE       (CACHE_SIZE),
        .KSU_KEY_SLOT_BASE_ADDR(KSU_KEY_SLOT_BASE_ADDR),
        .RNG_SEED_BASE_ADDR(RNG_SEED_BASE_ADDR),
        .CACHE_MEM_ADDR_WIDTH(CACHE_MEM_ADDR_WIDTH),
        .BLOCK_SIZEW      (BLOCK_SIZEW),
        .BLOCK_LEN        (BLOCK_LEN),
        .BLOCK_LENW       (BLOCK_LENW),
        .NUM_AES_BLOCKS   (NUM_AES_BLOCKS),
        .NUM_SETS         (NUM_SETS),
        .NUM_SETSW        (NUM_SETSW)
    ) u_crypto_wrap_ctrl (
        // Interfaces
        .cmu_ctrl_cmd         (cmu_ctrl_cmd),
        .c_wrap_sts           (c_wrap_sts),
        // Outputs
        .aes_seeded           (aes_seeded),
        .c_wrap_cmd_comp      (c_wrap_cmd_comp),
        .c_wrap_cmd_err       (c_wrap_cmd_err),
        .c_wrap_sts_upd       (c_wrap_sts_upd),
        .c_wrap_fault_err     (c_wrap_fault_err),
        .cmu_mem_wr           (cmu_mem_wr),
        .cmu_mem_addr         (cmu_mem_addr[CACHE_MEM_ADDR_WIDTH-1:0]),
        .cmu_mem_wdata        (cmu_mem_wdata[31:0]),
        .c_wrap_dma_cread     (c_wrap_dma_cread),
        .dma_c_wrap_craccept  (dma_c_wrap_craccept),
        .c_wrap_dma_cwrite    (c_wrap_dma_cwrite),
        .dma_c_wrap_cwaccept  (dma_c_wrap_cwaccept),
        .c_wrap_dma_caddr     (c_wrap_dma_caddr[31:0]),
        .c_wrap_dma_clen      (c_wrap_dma_clen[BLOCK_LENW-1:0]),
        .stop_dma_txn         (stop_dma_txn),
        .c_wrap_dma_wdata     (c_wrap_dma_wdata[31:0]),
        .c_wrap_dma_w_vld     (c_wrap_dma_w_vld),
        .aes_test_dout        (aes_test_dout[127:0]),
        .aes_test_sts_tag_out (aes_test_sts_tag_out),
        .set_aes_test_sts_dout_vld(set_aes_test_sts_dout_vld),
        .clr_aes_test_sts_dout_vld(clr_aes_test_sts_dout_vld),
        .aes_test_sts_din_rdy (aes_test_sts_din_rdy),
        .aes_test_sts_cfg_key_iv_rdy(aes_test_sts_cfg_key_iv_rdy),
        .clr_cfg_key_iv_vld   (clr_cfg_key_iv_vld),
        .clr_aes_test_din_vld (clr_aes_test_din_vld),
        .encr_block_sts_upd   (encr_block_sts_upd),
        .encr_block_sts       (encr_block_sts[11:0]),
        .ib_push_en           (ib_push_en),
        .ib_pop_en            (ib_pop_en),
        .ib_push_data         (ib_push_data[31:0]),
        .ib_ob_clr            (ib_ob_clr),
        .ob_push_en           (ob_push_en),
        .ob_pop_en            (ob_pop_en),
        .ob_push_data         (ob_push_data[127:0]),
        .gp_aes_clr           (gp_aes_clr),
        .seed_i               (seed_i[31:0]),
        .seed_vld_i           (seed_vld_i),
        .mode_i               (mode_i[3:0]),
        .dir_i                (dir_i),
        .cfg_vld_i            (cfg_vld_i),
        .key_i                (key_i[255:0]),
        .key_size_i           (key_size_i[1:0]),
        .key_vld_i            (key_vld_i),
        .skip_key_i           (skip_key_i),
        .iv_i                 (iv_i[127:0]),
        .ctx_in_i             (ctx_in_i[383:0]),
        .iv_ctx_sel_i         (iv_ctx_sel_i),
        .iv_ctx_vld_i         (iv_ctx_vld_i),
        .din_i                (din_i[127:0]),
        .din_bytecnt_i        (din_bytecnt_i[4:0]),
        .din_last_i           (din_last_i),
        .din_aad_sel_i        (din_aad_sel_i),
        .din_vld_i            (din_vld_i),
        .ctx_dout_rdy_i       (ctx_dout_rdy_i),
        .tag_rdy_i            (tag_rdy_i),
        // Inputs
        .clk_i                (clk_i),
        .gclk                 (gclk),
        .rstn_i               (rstn_i),
        .lp_rstn_i            (lp_rstn_i),
        .sinc_erase_busy_o    (sinc_erase_busy_o),
        .disable_encr_auth_check_i(disable_encr_auth_check_i),
        .cmu_ctrl_cmd_vld     (cmu_ctrl_cmd_vld),
        .cmu_ctrl_fetch_block_num(cmu_ctrl_fetch_block_num[23:0]),
        .severe_err           (severe_err),
        .ciu_mem_busy         (ciu_mem_busy),
        .dma_c_wrap_w_accept  (dma_c_wrap_w_accept),
        .dma_c_wrap_cw_comp   (dma_c_wrap_cw_comp),
        .dma_c_wrap_cw_err    (dma_c_wrap_cw_err),
        .dma_c_wrap_rdata     (dma_c_wrap_rdata[31:0]),
        .dma_c_wrap_r_vld     (dma_c_wrap_r_vld),
        .dma_c_wrap_cr_comp   (dma_c_wrap_cr_comp),
        .dma_c_wrap_cr_err    (dma_c_wrap_cr_err),
        .block_encr_num       (block_encr_num[23:0]),
        .num_of_blocks        (num_of_blocks[11:0]),
        .block_encr_addr      (block_encr_addr[31:0]),
        .block_encr_key       (block_encr_key[15:0]),
        .aes_iv_nonce         (aes_iv_nonce[95:0]),
        .ext_block_base_addr  (ext_block_base_addr[31:0]),
        .ext_auth_tag_base_addr(ext_auth_tag_base_addr[31:0]),
        .aes_test_din         (aes_test_din[127:0]),
        .aes_test_ctrl        (aes_test_ctrl[17:0]),
        .ib_pop_rdy           (ib_pop_rdy),
        .ib_pop_data          (ib_pop_data[127:0]),
        .ib_empty             (ib_empty),
        .ob_pop_rdy           (ob_pop_rdy),
        .ob_pop_data          (ob_pop_data[31:0]),
        .ob_empty             (ob_empty),
        .seed_rdy_o           (seed_rdy_o),
        .cfg_rdy_o            (cfg_rdy_o),
        .key_rdy_o            (key_rdy_o),
        .iv_ctx_rdy_o         (iv_ctx_rdy_o),
        .din_rdy_o            (din_rdy_o),
        .dout_o               (dout_o[127:0]),
        .dout_last_o          (dout_last_o),
        .ctx_dout_vld_o       (ctx_dout_vld_o),
        .tag_o                (tag_o[127:0]),
        .tag_vld_o            (tag_vld_o),
        .cmd_err_o            (cmd_err_o),
        .fault_err_o          (fault_err_o[1:0]));

    sinc_cmu_fifo #(
        .WIDTH(128),
        .DEPTH(IB_DEPTH),
        .PUSH_DATAW(32),
        .POP_DATAW(128)
    ) u_input_buf (
        // Outputs
        .push_rdy                     (unused_ib_push_rdy),
        .pop_rdy                      (ib_pop_rdy),
        .pop_data                     (ib_pop_data[127:0]),
        .empty                        (ib_empty),
        .full                         (unused_ib_full),
        .entries_in_use               (unused_ib_entries_in_use[IB_COUNTW-1:0]),
        .overflow_err                 (unused_ib_overflow_err),
        .underflow_err                (unused_ib_underflow_err),
        // Inputs
        .clk_i                        (clk_i),
        .rstn_i                       (lp_rstn_i),
        .clear                        (ib_ob_clr),
        .push_en                      (ib_push_en),
        .pop_en                       (ib_pop_en),
        .push_data                    (ib_push_data[31:0]));

    gp_aes u_gp_aes (
        // Outputs
        .seed_rdy_o                       (seed_rdy_o),
        .cfg_rdy_o                        (cfg_rdy_o),
        .key_rdy_o                        (key_rdy_o),
        .iv_ctx_rdy_o                     (iv_ctx_rdy_o),
        .din_rdy_o                        (din_rdy_o),
        .dout_o                           (dout_o[127:0]),
        .dout_bytecnt_o                   (dout_bytecnt_o_unused[4:0]),
        .dout_last_o                      (dout_last_o),
        .ctx_out_o                        (ctx_out_o_unused[383:0]),
        .ctx_dout_vld_o                   (ctx_dout_vld_o),
        .tag_o                            (tag_o[127:0]),
        .tag_vld_o                        (tag_vld_o),
        .cmd_err_o                        (cmd_err_o),
        .fault_err_o                      (fault_err_o[1:0]),
        .busy_o                           (busy_o_unused),
        // Inputs
        .clk_i                            (clk_i),
        .rstn_i                           (lp_rstn_i),
        .clear_i                          (gp_aes_clr),
        .clkg_test_mode_i                 (clkg_test_mode_i),
        .clkg_override_i                  (clkg_override_i),
        .seed_i                           (seed_i[31:0]),
        .seed_vld_i                       (seed_vld_i),
        .mode_i                           (mode_i[3:0]),
        .dir_i                            (dir_i),
        .cfg_vld_i                        (cfg_vld_i),
        .key_i                            (key_i[255:0]),
        .key_size_i                       (key_size_i[1:0]),
        .key_vld_i                        (key_vld_i),
        .skip_key_i                       (skip_key_i),
        .iv_i                             (iv_i[127:0]),
        .ctx_in_i                         (ctx_in_i[383:0]),
        .iv_ctx_sel_i                     (iv_ctx_sel_i),
        .iv_ctx_vld_i                     (iv_ctx_vld_i),
        .din_i                            (din_i[127:0]),
        .din_bytecnt_i                    (din_bytecnt_i[4:0]),
        .din_last_i                       (din_last_i),
        .din_aad_sel_i                    (din_aad_sel_i),
        .din_vld_i                        (din_vld_i),
        .ctx_dout_rdy_i                   (ctx_dout_rdy_i),
        .tag_rdy_i                        (tag_rdy_i));

    

    sinc_cmu_fifo #(
        .WIDTH(128),
        .DEPTH(1),
        .PUSH_DATAW(128),
        .POP_DATAW(32))

    u_output_buf  (
        // Outputs
        .push_rdy                    (unused_ob_push_rdy),
        .pop_rdy                     (ob_pop_rdy),
        .pop_data                    (ob_pop_data[31:0]),
        .empty                       (ob_empty),
        .full                        (unused_ob_full),
        .entries_in_use              (unused_ob_entries_in_use[2:0]),
        .overflow_err                (unused_ob_overflow_err),
        .underflow_err               (unused_ob_underflow_err),
        // Inputs
        .clk_i                       (clk_i),
        .rstn_i                      (lp_rstn_i),
        .clear                       (ib_ob_clr),
        .push_en                     (ob_push_en),
        .pop_en                      (ob_pop_en),
        .push_data                   (ob_push_data[127:0]));
                    
endmodule