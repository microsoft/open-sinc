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
// File        : sinc_cmu_crypto_wrap_ctrl.sv
// Description : CMU crypto wrapper control. Manages AES operations based on
//               commands and controls DMA controller for read/write transfers.

module sinc_cmu_crypto_wrap_ctrl
import sinc_pkg::*;
#(
    parameter bit NO_SEED_LOADING   = 1'b0,                     // skip RNG seed DMA reads (AES DRBG starts already-seeded)
    parameter BLOCK_SIZE            = 512,
    parameter CACHE_SIZE            = 256,                      // Cache IRAM size in KB
    parameter unsigned KSU_KEY_SLOT_BASE_ADDR = 32'h8F0C_4000,
    parameter unsigned RNG_SEED_BASE_ADDR = 32'h8F0A_0200,
    parameter CACHE_MEM_ADDR_WIDTH  = 14,
    // parameter ADDR_WIDTH            = 24,

    /* Derived parameter, don't set manually*/
    parameter BLOCK_SIZEW           = $clog2(BLOCK_SIZE),
    parameter BLOCK_LEN             = BLOCK_SIZE/4,             // Represent AXI len for a block (i.e. no. of 32b beats in a block)
    parameter BLOCK_LENW            = $clog2(BLOCK_LEN),
    parameter unsigned NUM_AES_BLOCKS = BLOCK_SIZE/16,           // Each AES block consist of 16B or 128b
    parameter NUM_SETS              = ((CACHE_SIZE * 1024) / BLOCK_SIZE) / 4,
    parameter NUM_SETSW             = $clog2(NUM_SETS)
)
(
    input logic                     clk_i,
    input logic                     gclk,
    input logic                     rstn_i,
    input logic                     lp_rstn_i,
    input logic                     sinc_erase_busy_o,
    input logic                     disable_encr_auth_check_i,

    /* CMU Control Interface */
    input sinc_cmu_cmd_t            cmu_ctrl_cmd,               // FW cmd indication from CMU ctrl block
    input logic                     cmu_ctrl_cmd_vld,
    input logic [23:0]              cmu_ctrl_fetch_block_num,
    input logic                     severe_err,

    output logic                    aes_seeded,
    output logic                    c_wrap_cmd_comp,            // cmd complete indication to cmu ctrl (including FETCH_BLOCK)
    output logic                    c_wrap_cmd_err,
    output logic                    c_wrap_sts_upd,             // signal sts reg update to cmu ctrl
    output sts_update_t             c_wrap_sts,                 // value of sts reg to be updated
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

    /* Reg ctrl interface */
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
    output logic [11:0]             encr_block_sts,
    /* Input buffer interface */
    output logic                    ib_push_en,
    output logic                    ib_pop_en,
    output logic [31:0]             ib_push_data,
    output logic                    ib_ob_clr,

    input logic                     ib_pop_rdy,   // Indicates that an entry is available to pop
    input logic [127:0]             ib_pop_data,

    input logic                     ib_empty,

    /* Output buffer interface */
    output logic                    ob_push_en,
    output logic                    ob_pop_en,
    output logic [127:0]            ob_push_data,

    input logic                     ob_pop_rdy,   // Indicates that an entry is available to pop
    input logic [31:0]              ob_pop_data,

    input logic                     ob_empty,

    /* GP AES interface */
    output logic                    gp_aes_clr,

    output logic [31:0]             seed_i,
    output logic                    seed_vld_i,
    input logic                     seed_rdy_o,

    output logic [3:0]              mode_i,
    output logic                    dir_i,
    output logic                    cfg_vld_i,
    input logic                     cfg_rdy_o,

    output logic [255:0]            key_i,
    output logic [1:0]              key_size_i,
    output logic                    key_vld_i,
    output logic                    skip_key_i,
    input logic                     key_rdy_o,

    output logic [127:0]            iv_i,
    output logic [383:0]            ctx_in_i,
    output logic                    iv_ctx_sel_i,
    output logic                    iv_ctx_vld_i,
    input logic                     iv_ctx_rdy_o,

    output logic [127:0]            din_i,
    output logic [4:0]              din_bytecnt_i,
    output logic                    din_last_i,
    output logic                    din_aad_sel_i,
    output logic                    din_vld_i,
    input logic                     din_rdy_o,

    input logic [127:0]             dout_o,
    input logic                     dout_last_o,
    input logic                     ctx_dout_vld_o,
    output logic                    ctx_dout_rdy_i,

    input logic [127:0]             tag_o,
    input logic                     tag_vld_o,
    output logic                    tag_rdy_i,

    input logic                     cmd_err_o,
    input logic [1:0]               fault_err_o
    );

    localparam NUM_AES_BLOCKSW = $clog2(NUM_AES_BLOCKS+1);

    sinc_cmu_ctrl_fsm_t             state;
    sinc_cmu_ctrl_fsm_t             next_state;
    sinc_sub_state_fsm_t            sub_state;
    sinc_sub_state_fsm_t            next_sub_state;
    aes_modes_t                     aes_test_mode_q;
    aes_modes_t                     aes_test_mode;
    key_sizes_t                     aes_test_key_len;
    sinc_aes_ctrl_fsm_t             aes_ctrl_state;
    sinc_aes_ctrl_fsm_t             next_aes_ctrl_state;
    sinc_sub_state_fsm_t            aes_ctrl_sub_state;
    sinc_sub_state_fsm_t            next_aes_ctrl_sub_state;
    sts_update_t                    sts;

    logic                           is_state_fetch_block;
    logic                           is_r_seed;
    logic [BLOCK_LENW-1:0]          cache_block_len;
    logic [31:0]                    fetch_block_addr;
    logic [31:0]                    fetch_block_tag_addr;
    logic [31:0]                    key_addr;
    logic [255:0]                   key_q;
    logic [BLOCK_LENW-1:0]          rdata_bt_cnt;
    logic [BLOCK_LENW-1:0]          wdata_bt_cnt;
    logic [NUM_AES_BLOCKSW-1:0]     total_aes_blocks;
    logic [NUM_AES_BLOCKSW-1:0]     aes_block_cnt;
    logic [11:0]                    encr_block_cnt;
    logic                           first_aes_block;
    logic                           first_aes_block_flag;
    logic                           last_aes_block;
    logic                           last_encr_block;
    logic [23:0]                    curr_encr_block_num;
    logic [31:0]                    curr_encr_block_r_addr;
    logic [31:0]                    curr_encr_block_w_addr;
    logic [31:0]                    curr_encr_block_tag_addr;
    logic                           aes_test_dir;
    logic                           aes_test_reuse_key;
    logic                           aes_test_cfg_key_iv_vld;
    logic                           aes_test_din_vld;
    logic [4:0]                     aes_test_din_bytecnt;
    logic                           aes_test_din_last;
    logic                           aes_test_din_aad_sel;
    logic                           aes_test_dout_ack;
    logic                           set_cfg_key_iv_rdy;
    logic                           clr_cfg_key_iv_rdy;
    logic                           aes_test_cfg_err;
    logic                           invld_cfg;
    logic                           invld_key_len;
    logic                           invld_din_bytecnt;
    logic                           invld_din_aad_sel;

    logic                           r_comp;
    logic                           clr_r_comp;
    logic                           w_comp;
    logic                           clr_w_comp;
    logic                           dma_r_exec;
    logic                           clr_dma_r_exec;
    logic                           set_dma_r_exec;
    logic                           dma_w_exec;
    logic                           clr_dma_w_exec;
    logic                           set_dma_w_exec;
    logic                           set_aes_seeded;
    logic                           clr_key;
    logic                           is_state_aes_test;
    logic                           is_state_encr_block;
    logic                           is_r_cache_block;
    logic                           is_r_key;
    logic                           is_r_tag;
    logic                           is_w_tag;
    logic                           is_w_cache_block;
    logic                           comp_tag_en;
    logic                           comp_tag_pass;
    logic                           aes_test_done;
    logic                           new_key_loaded;
    logic                           reuse_key;
    logic                           clr_aes_and_reuse_key;
    logic                           sts_upd;
    logic                           dma_r_comp;
    logic                           dma_w_comp;
    logic                           aes_err;
    logic                           aes_err_q;
    logic                           clr_aes_err;
    logic                           aes_test_din_err;
    logic                           rst_ctrl_signals;
    logic                           invld_state;
    logic                           invld_aes_ctrl_state;
    logic                           gp_aes_clr_din;
    logic                           internal_error;
    logic                           last_aes_out_block;
    logic                           start_aes_data;

    sinc_cmu_crypto_wrap_ctrl_ret #(
        .BLOCK_LENW(BLOCK_LENW)
    ) u_sinc_cmu_crypto_wrap_ctrl_ret (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .is_r_key(is_r_key),
        .clr_key(clr_key),
        .severe_err(severe_err),
        .rdata_bt_cnt(rdata_bt_cnt),
        .dma_c_wrap_r_vld(dma_c_wrap_r_vld),
        .dma_c_wrap_rdata(dma_c_wrap_rdata),
        .key_q(key_q)
    );

    /* Main crypto control FSM logic */
    /* Controls DMA commands, AES settings and writes out of output buffer */

    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if (~lp_rstn_i) begin
            state <= SINC_IDLE;
            sub_state <= SINC_SUB_STATE_1;
        end
        else begin
            if (severe_err) begin
                state <= SINC_IDLE;
                sub_state <= SINC_SUB_STATE_1;
            end
            else begin
                state <= next_state;
                sub_state <= next_sub_state;
            end
        end
    end

    always_comb begin
        next_state              = state;
        next_sub_state          = sub_state;
        
        cfg_vld_i               = 1'h0;
        c_wrap_dma_caddr        = 32'h0;
        c_wrap_dma_cread        = 1'h0;
        c_wrap_dma_cwrite       = 1'h0;
        c_wrap_dma_clen         = {BLOCK_LENW{1'h0}};
        c_wrap_dma_w_vld        = 1'h0;
        c_wrap_dma_wdata        = 32'h0;
        c_wrap_cmd_comp         = 1'h0;
        c_wrap_cmd_err          = 1'h0;
        stop_dma_txn            = 1'h0;
        clr_dma_r_exec          = 1'h0;
        clr_r_comp              = 1'h0;
        clr_dma_w_exec          = 1'h0;
        clr_w_comp              = 1'h0;
        clr_cfg_key_iv_vld      = 1'h0;
        clr_key                 = 1'h0;
        cmu_mem_wr              = 1'h0;
        cmu_mem_addr            = {CACHE_MEM_ADDR_WIDTH{1'h0}};
        cmu_mem_wdata           = 32'h0;
        comp_tag_en             = 1'h0;
        mode_i                  = AES_RSVD0;
        dir_i                   = 1'h0;
        is_state_encr_block     = 1'h0;
        is_state_fetch_block    = 1'h0;
        is_state_aes_test       = 1'h0;
        is_r_cache_block        = 1'h0;
        is_r_seed               = 1'h0;
        is_r_key                = 1'h0;
        is_r_tag                = 1'h0;
        is_w_tag                = 1'h0;
        is_w_cache_block        = 1'h0;
        // In GCM mode, 96b IV is appended on right by 32'h1 (as per NIST). Byte-reversing the append here before driving it to GP AES
        iv_i                    = {32'h0100_0000, 96'h0};
        iv_ctx_vld_i            = 1'h0;
        iv_ctx_sel_i            = 1'h0;
        new_key_loaded          = 1'h0;
        key_i                   = 256'h0;
        key_vld_i               = 1'h0;
        skip_key_i              = 1'h0;
        key_size_i              = KEY_SIZE_RSVD;
        ob_pop_en               = 1'h0;
        set_dma_r_exec          = 1'h0;
        set_dma_w_exec          = 1'h0;
        set_aes_seeded          = 1'h0;
        set_cfg_key_iv_rdy      = 1'h0;
        clr_cfg_key_iv_rdy      = 1'h0;
        sts_upd                 = 1'h0;
        sts                     = STS_NONE;
        encr_block_sts_upd      = 1'h0;
        rst_ctrl_signals        = 1'h0;
        invld_state             = 1'h0;
        clr_aes_err             = 1'h0;
        clr_aes_and_reuse_key   = 1'h0;
        start_aes_data          = 1'h0;

        case(state)
            SINC_IDLE: begin
                rst_ctrl_signals = 1'h1;

                if(cmu_ctrl_cmd_vld) begin
                    if(cmu_ctrl_cmd == CMD_SET_INIT) begin
                        next_state = SET_INIT;
                        next_sub_state = SINC_SUB_STATE_1;
                    end
                    else if (cmu_ctrl_cmd == CMD_ENCR_BLOCK) begin
                        next_state = ENCR_BLOCK;
                        next_sub_state = SINC_SUB_STATE_1;
                    end
                    else if(cmu_ctrl_cmd == CMD_FETCH_BLOCK) begin
                        next_state = FETCH_BLOCK;
                        next_sub_state = SINC_SUB_STATE_1;
                    end
                    else if (cmu_ctrl_cmd == CMD_SINC_RESET) begin
                        next_state = SINC_RESET;
                    end
                    else if (cmu_ctrl_cmd == CMD_SINC_REINIT) begin
                        next_state = SINC_REINIT;
                    end
                    else if (cmu_ctrl_cmd == CMD_AES_TEST) begin
                        set_cfg_key_iv_rdy = 1'h1;
                        next_state = AES_TEST;
                        next_sub_state = SINC_SUB_STATE_1;
                    end
                    else if (cmu_ctrl_cmd == CMD_AES_SEED) begin
                        if (NO_SEED_LOADING) begin
                            c_wrap_cmd_comp = 1'h1;
                        end else begin
                            next_state = AES_SEED;
                            next_sub_state = SINC_SUB_STATE_1;
                        end
                    end
                end
            end
            SET_INIT: begin
                case(sub_state)
                    SINC_SUB_STATE_1: begin                  // Break read seed into 2 reads of 10 beats for AES drbg
                        if (NO_SEED_LOADING) begin
                            next_sub_state = SINC_SUB_STATE_3;
                        end else begin
                            is_r_seed = 1'h1;               // this is first read seed
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~aes_seeded) begin
                                if(~dma_r_exec) begin
                                    c_wrap_dma_cread = 1'h1;
                                    c_wrap_dma_caddr = RNG_SEED_BASE_ADDR;
                                    c_wrap_dma_clen[3:0] = 4'hA;

                                    if (dma_c_wrap_craccept) begin
                                        set_dma_r_exec = 1'h1;    
                                    end
                                end

                                if (dma_c_wrap_cr_err) begin
                                    c_wrap_cmd_comp = 1'h1;
                                    c_wrap_cmd_err = 1'h1;
                                    sts_upd = 1'h1;
                                    sts = STS_RNG_SEED_ERR;
                                    next_state = SINC_IDLE;
                                end
                                else if(r_comp & dma_c_wrap_cr_comp) begin
                                    next_sub_state = SINC_SUB_STATE_2;
                                end
                            end
                            else begin
                                next_sub_state = SINC_SUB_STATE_3;
                            end
                        end
                    end
                    SINC_SUB_STATE_2: begin                  
                        is_r_seed = 1'h1;
                        clr_dma_r_exec = dma_r_comp;
                        clr_r_comp = dma_r_comp;

                        if(~dma_r_exec) begin
                            c_wrap_dma_cread = 1'h1;
                            c_wrap_dma_caddr = RNG_SEED_BASE_ADDR + 6'h28;       // continue from last read
                            c_wrap_dma_clen[3:0] = 4'hA;

                            if (dma_c_wrap_craccept) begin
                                set_dma_r_exec = 1'h1;    
                            end
                        end

                        if (dma_c_wrap_cr_err) begin
                            c_wrap_cmd_comp = 1'h1;
                            c_wrap_cmd_err = 1'h1;
                            sts_upd = 1'h1;
                            sts = STS_RNG_SEED_ERR;
                            next_state = SINC_IDLE;
                        end
                        else if(r_comp & dma_c_wrap_cr_comp) begin      // seed_rdy_o = 1'h1 is true
                            set_aes_seeded = 1'h1;
                            next_sub_state = SINC_SUB_STATE_3;
                        end
                    end
                    SINC_SUB_STATE_3: begin                 // read key
                        is_r_key = 1'h1;
                        clr_dma_r_exec = dma_r_comp;
                        clr_r_comp = dma_r_comp;
                        c_wrap_cmd_comp = dma_r_comp;

                        if(~dma_r_exec) begin
                            c_wrap_dma_cread = 1'h1;
                            c_wrap_dma_caddr = key_addr;
                            c_wrap_dma_clen[3:0] = 4'h8;

                            if (dma_c_wrap_craccept) begin
                                set_dma_r_exec = 1'h1;    
                            end
                        end

                        if (dma_c_wrap_cr_err) begin
                            c_wrap_cmd_err = 1'h1;
                            sts_upd = 1'h1;
                            sts = STS_KEY_FET_ERR;
                            next_state = SINC_IDLE;
                        end
                        else if (r_comp & dma_c_wrap_cr_comp) begin
                            new_key_loaded = 1'h1;
                            next_state = SINC_IDLE;
                        end
                    end
                    default: begin
                        invld_state = 1'h1;
                        next_sub_state = SINC_SUB_STATE_1;
                        next_state = SINC_IDLE; 
                    end
                endcase
            end
            ENCR_BLOCK: begin
                is_state_encr_block = 1'h1;

                if (aes_err_q | (num_of_blocks == 12'h0)) begin             // check for AES error or Num_of_blocks should be > 0
                    c_wrap_cmd_comp = 1'h1;
                    c_wrap_cmd_err = 1'h1;
                    stop_dma_txn = 1'h1;
                    clr_aes_err = 1'h1;
                    sts_upd = 1'h1;
                    sts = aes_err_q ? STS_AES_ERR : STS_INV_CMD;
                    next_state = SINC_IDLE;
                end
                else begin
                    case(sub_state)
                        SINC_SUB_STATE_1: begin                             // Send read block request to DMA controller
                            is_r_cache_block = 1'h1;                        // also drive AES inputs and ensure it is ready to accept data
                            is_w_cache_block = 1'h1;
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~disable_encr_auth_check_i) begin            // Only configure AES if encr is to be performed
                                cfg_vld_i = cfg_rdy_o;
                                mode_i = AES_GCM;
                                dir_i = 1'h1;
                                key_vld_i = key_rdy_o & (~reuse_key);
                                skip_key_i = key_rdy_o & reuse_key;
                                key_i = key_q[255:0];
                                key_size_i = KEY_SIZE_256;
                                iv_ctx_vld_i = iv_ctx_rdy_o;
                                iv_ctx_sel_i = 1'h1;
                                iv_i[95:0] = {aes_iv_nonce[71:0], curr_encr_block_num};   // curr_encr_block_num is based on a counter which increments for every block
                                start_aes_data = 1'h1;
                            end
                            
                            if(~dma_r_exec) begin
                                if(ib_empty) begin
                                    c_wrap_dma_cread = 1'h1;
                                    c_wrap_dma_caddr = curr_encr_block_r_addr;
                                    c_wrap_dma_clen = cache_block_len;

                                    if (dma_c_wrap_craccept) begin
                                        set_dma_r_exec = 1'h1;    
                                    end
                                end
                            end
                            else if (~dma_w_exec) begin                  // Send write request to pipeline write along with read
                                c_wrap_dma_cwrite = 1'h1;
                                c_wrap_dma_caddr = curr_encr_block_w_addr;
                                c_wrap_dma_clen = cache_block_len;

                                if (dma_c_wrap_cwaccept) begin
                                    set_dma_w_exec = 1'h1;    
                                end
                            end

                            if (dma_c_wrap_cr_err) begin                // check for read or write errors from DMA
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                stop_dma_txn = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_CAC_BLK_R_ERR;
                                encr_block_sts_upd = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(dma_c_wrap_cw_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                stop_dma_txn = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_CAC_BLK_W_ENC_BLK_ERR;
                                encr_block_sts_upd = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(r_comp & dma_c_wrap_cr_comp) begin
                                next_sub_state = SINC_SUB_STATE_2;
                            end

                            if(ob_pop_rdy) begin
                                ob_pop_en = dma_c_wrap_w_accept;        // Pop only when DMA and AXI mgr accepts
                                c_wrap_dma_w_vld = 1'h1;
                                c_wrap_dma_wdata = ob_pop_data;
                            end
                        end
                        SINC_SUB_STATE_2: begin                         // AES is processing data and write the result to external memory simultaneously
                            is_w_cache_block = 1'h1;
                            clr_dma_w_exec = dma_w_comp;
                            clr_w_comp = dma_w_comp;

                            if(ob_pop_rdy) begin
                                ob_pop_en = dma_c_wrap_w_accept;        // Pop only when DMA and AXI mgr accepts
                                c_wrap_dma_w_vld = 1'h1;
                                c_wrap_dma_wdata = ob_pop_data;
                            end
                            
                            if(dma_c_wrap_cw_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_CAC_BLK_W_ENC_BLK_ERR;
                                encr_block_sts_upd = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(w_comp & dma_c_wrap_cw_comp) begin  // complete cache block is written to external memory via DMA controller
                                if(~disable_encr_auth_check_i) begin
                                    next_sub_state = SINC_SUB_STATE_3;    
                                end
                                else begin                          // if encr is disabled, directly check if this was last block
                                    if(last_encr_block) begin
                                        c_wrap_cmd_comp = 1'h1;
                                        next_state = SINC_IDLE;
                                    end
                                    else begin                      // this block is finished. Continue encrypting more blocks
                                        next_sub_state = SINC_SUB_STATE_1; 
                                    end
                                end
                            end
                        end
                        SINC_SUB_STATE_3: begin                     // AES is processing tag. Send write request to DMA controller for
                            is_w_tag = 1'h1;                        // writing auth tag and wait for tag to be generated
                            clr_dma_w_exec = dma_w_comp;
                            clr_w_comp = dma_w_comp;

                            if (~dma_w_exec) begin
                                c_wrap_dma_cwrite = 1'h1;
                                c_wrap_dma_caddr = curr_encr_block_tag_addr;
                                c_wrap_dma_clen[2:0] = 3'h4;

                                if (dma_c_wrap_cwaccept) begin
                                    set_dma_w_exec = 1'h1;    
                                end
                            end

                            if(ob_pop_rdy) begin                    // write generated tag from OB to DMA controller
                                ob_pop_en = dma_c_wrap_w_accept;
                                c_wrap_dma_w_vld = 1'h1;
                                c_wrap_dma_wdata = ob_pop_data;
                            end

                            if(dma_c_wrap_cw_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_AUTH_TAG_W_ERR;
                                encr_block_sts_upd = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(w_comp & dma_c_wrap_cw_comp) begin  // complete cache block is written to external memory via DMA controller
                                if(last_encr_block) begin
                                    c_wrap_cmd_comp = 1'h1;
                                    next_state = SINC_IDLE;
                                end
                                else begin                      // this block is finished. Continue encrypting more blocks
                                    next_sub_state = SINC_SUB_STATE_1; 
                                end
                            end
                        end
                        default: begin
                            invld_state = 1'h1;
                            next_sub_state = SINC_SUB_STATE_1;
                            next_state = SINC_IDLE; 
                        end
                    endcase
                end
            end
            FETCH_BLOCK: begin
                is_state_fetch_block = 1'h1;

                if (aes_err_q) begin             // check for AES error
                    c_wrap_cmd_comp = 1'h1;
                    c_wrap_cmd_err = 1'h1;
                    stop_dma_txn = 1'h1;
                    clr_aes_err = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_AES_ERR;
                    next_state = SINC_IDLE;
                end
                else if(sinc_erase_busy_o) begin
                    c_wrap_cmd_comp = 1'h1;
                    c_wrap_cmd_err = 1'h1;
                    stop_dma_txn = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CAC_BLK_W_FET_BLK_ERR;
                    next_state = SINC_IDLE;
                end
                else begin
                    case(sub_state)
                        SINC_SUB_STATE_1: begin                     // Send read cache block request to DMA controller
                            is_r_cache_block = 1'h1;                // Also drive AES cfg, key and IV inputs and ensure it is ready to accept data
                            is_w_cache_block = 1'h1;
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~disable_encr_auth_check_i) begin            // Only configure AES if encr is to be performed
                                cfg_vld_i = cfg_rdy_o;
                                mode_i = AES_GCM;
                                dir_i = 1'h0;
                                key_vld_i = key_rdy_o & (~reuse_key);
                                skip_key_i = key_rdy_o & reuse_key;
                                key_i = key_q[255:0];
                                key_size_i = KEY_SIZE_256;
                                iv_ctx_vld_i = iv_ctx_rdy_o;
                                iv_ctx_sel_i = 1'h1;
                                iv_i[95:0] = {aes_iv_nonce[71:0], cmu_ctrl_fetch_block_num};
                                start_aes_data = 1'h1;
                            end

                            if(~dma_r_exec) begin                   // reach cache block from ext mem
                                if(ib_empty) begin
                                    c_wrap_dma_cread = 1'h1;
                                    c_wrap_dma_caddr = fetch_block_addr;
                                    c_wrap_dma_clen = cache_block_len;

                                    if (dma_c_wrap_craccept) begin
                                        set_dma_r_exec = 1'h1;    
                                    end
                                end
                            end

                            if(dma_c_wrap_cr_err) begin
                                sts_upd = 1'h1;
                                sts = STS_CAC_BLK_R_ERR;
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(r_comp & dma_c_wrap_cr_comp) begin      // transition to next sub state to process data
                                next_sub_state = SINC_SUB_STATE_2;
                            end
                            
                            if(ob_pop_rdy & (~ciu_mem_busy)) begin          // Pipeline the write along with read to reduce latency. Wr data to cache as soon as it is available
                                ob_pop_en = 1'h1;
                                cmu_mem_wr = 1'h1;
                                // shift block num by block size in 32b words, to get the starting memory address for that block num
                                cmu_mem_addr = {cmu_ctrl_fetch_block_num[NUM_SETSW-1:0], {(BLOCK_SIZEW - 2){1'h0}}} + wdata_bt_cnt;
                                cmu_mem_wdata = ob_pop_data;
                            end
                        end
                        SINC_SUB_STATE_2: begin                     // AES processing data and write AES output to cache IRAM
                            is_w_cache_block = 1'h1;

                            if(ob_pop_rdy & (~ciu_mem_busy)) begin
                                ob_pop_en = 1'h1;
                                cmu_mem_wr = 1'h1;
                                
                                // shift block num by block size in 32b words, to get the starting memory address for that block num
                                cmu_mem_addr = {cmu_ctrl_fetch_block_num[NUM_SETSW-1:0], {(BLOCK_SIZEW - 2){1'h0}}} + wdata_bt_cnt;
                                cmu_mem_wdata = ob_pop_data;
                            end
                            
                            if(w_comp) begin                        // complete cache block is written to external memory via DMA controller
                                clr_w_comp = 1'h1;

                                if(~disable_encr_auth_check_i) begin
                                    next_sub_state = SINC_SUB_STATE_3;
                                end
                                else begin                          // Sub state 3 is skipped as tag is not to be read
                                    next_sub_state = SINC_SUB_STATE_4;
                                end
                            end
                        end
                        SINC_SUB_STATE_3: begin                     // Read auth tag from external memory
                            is_r_tag = 1'h1;
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~dma_r_exec) begin
                                if(ib_empty) begin
                                    c_wrap_dma_cread = 1'h1;
                                    c_wrap_dma_caddr = fetch_block_tag_addr;
                                    c_wrap_dma_clen[2:0] = 3'h4;

                                    if (dma_c_wrap_craccept) begin
                                        set_dma_r_exec = 1'h1;    
                                    end
                                end
                            end

                            if (dma_c_wrap_cr_err) begin
                                sts_upd = 1'h1;
                                sts = STS_AUTH_TAG_R_ERR;
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                next_state = SINC_IDLE;
                            end
                            else if(r_comp & dma_c_wrap_cr_comp) begin
                                next_sub_state = SINC_SUB_STATE_4;
                            end
                        end
                        SINC_SUB_STATE_4: begin                     // Compare auth tag
                            if(tag_vld_o) begin                     // Only compare when expected tag is ready from above and AES has also calculated tag
                                comp_tag_en = 1'h1;
                                c_wrap_cmd_comp = 1'h1;
                                next_state = SINC_IDLE;

                                if (~comp_tag_pass) begin
                                    sts_upd = 1'h1;
                                    sts = STS_AUTH_TAG_CHK_ERR;
                                    c_wrap_cmd_err = 1'h1;
                                end
                            end
                            else if (disable_encr_auth_check_i) begin   // skip auth check
                                c_wrap_cmd_comp = 1'h1;
                                next_state = SINC_IDLE;
                            end
                        end
                        default: begin
                            invld_state = 1'h1;
                            next_sub_state = SINC_SUB_STATE_1;
                            next_state = SINC_IDLE;
                        end
                    endcase
                end
            end
            SINC_RESET: begin
                clr_key = 1'h1;
                clr_aes_and_reuse_key = 1'h1;       // sinc must reload the key into AES, as AES is cleared in this cmd
                clr_aes_err = 1'h1;                 // also clear aes error, since GP aes is soft reset
                c_wrap_cmd_comp = 1'h1;
                next_state = SINC_IDLE;
            end
            SINC_REINIT: begin
                clr_aes_and_reuse_key = 1'h1;       // sinc must reload the key into AES, as AES is cleared in this cmd 
                c_wrap_cmd_comp = 1'h1;
                next_state = SINC_IDLE;
            end
            AES_TEST: begin
                is_state_aes_test = 1'h1;
                clr_cfg_key_iv_vld = aes_test_sts_cfg_key_iv_rdy & aes_test_cfg_key_iv_vld;
                clr_cfg_key_iv_rdy = aes_test_sts_cfg_key_iv_rdy & aes_test_cfg_key_iv_vld;
                
                if (aes_err_q) begin             // check for AES error
                    c_wrap_cmd_comp = 1'h1;
                    c_wrap_cmd_err = 1'h1;
                    clr_dma_r_exec = 1'h1;
                    clr_r_comp = 1'h1;
                    clr_dma_w_exec = 1'h1;
                    clr_w_comp = 1'h1;
                    clr_aes_err = 1'h1;
                    clr_aes_and_reuse_key = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_AES_ERR;
                    next_state = SINC_IDLE;
                end
                else if (cmu_ctrl_cmd_vld) begin
                    clr_cfg_key_iv_rdy = 1'h1;
                    c_wrap_cmd_comp = 1'h1;
                    clr_dma_r_exec = 1'h1;
                    clr_r_comp = 1'h1;
                    clr_dma_w_exec = 1'h1;
                    clr_w_comp = 1'h1;
                    clr_aes_and_reuse_key = 1'h1;
                    next_state = SINC_IDLE;

                    if (cmu_ctrl_cmd != CMD_NONE) begin     // only allowed req is to exit out of test mode
                        c_wrap_cmd_err = 1'h1;              // any other req results in invld cmd err
                        sts_upd = 1'h1;
                        sts = STS_INV_CMD;
                    end
                end
                else begin
                    case(sub_state)
                        SINC_SUB_STATE_1: begin
                            if(aes_test_cfg_key_iv_vld) begin
                                if(~aes_test_cfg_err) begin
                                    if (NO_SEED_LOADING || aes_seeded) begin
                                        next_sub_state = SINC_SUB_STATE_4;
                                    end
                                    else begin
                                        next_sub_state = SINC_SUB_STATE_2;
                                    end
                                end
                                else begin                      // incorrect AES configuration
                                    c_wrap_cmd_comp = 1'h1;
                                    c_wrap_cmd_err = 1'h1;
                                    sts_upd = 1'h1;
                                    sts = STS_INV_CMD;
                                    next_state = SINC_IDLE;
                                end
                            end
                        end
                        SINC_SUB_STATE_2: begin                 
                            is_r_seed = 1'h1;                   // this is first read seed
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~dma_r_exec) begin
                                c_wrap_dma_cread = 1'h1;
                                c_wrap_dma_caddr = RNG_SEED_BASE_ADDR;
                                c_wrap_dma_clen[3:0] = 4'hA;

                                if (dma_c_wrap_craccept) begin
                                    set_dma_r_exec = 1'h1;    
                                end
                            end

                            if (dma_c_wrap_cr_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_RNG_SEED_ERR;
                                next_state = SINC_IDLE;
                            end
                            else if(r_comp & dma_c_wrap_cr_comp) begin
                                next_sub_state = SINC_SUB_STATE_3;
                            end
                        end
                        SINC_SUB_STATE_3: begin                  
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~dma_r_exec) begin
                                c_wrap_dma_cread = 1'h1;
                                c_wrap_dma_caddr = RNG_SEED_BASE_ADDR + 6'h28;       // continue from last read
                                c_wrap_dma_clen[3:0] = 4'hA;

                                if (dma_c_wrap_craccept) begin
                                    set_dma_r_exec = 1'h1;    
                                end
                            end

                            if (dma_c_wrap_cr_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_RNG_SEED_ERR;
                                next_state = SINC_IDLE;
                            end
                            else if(r_comp & dma_c_wrap_cr_comp) begin  // seed_rdy_o = 1'h1
                                set_aes_seeded = 1'h1;
                                next_sub_state = SINC_SUB_STATE_4;
                            end
                        end
                        SINC_SUB_STATE_4: begin                  // read key
                            is_r_key = 1'h1;
                            clr_dma_r_exec = dma_r_comp;
                            clr_r_comp = dma_r_comp;

                            if(~aes_test_sts_cfg_key_iv_rdy) begin          // aes_test_sts_cfg_key_iv_rdy = 0 means that FW already set cfg_key_iv_vld = 1
                                cfg_vld_i = cfg_rdy_o;                      // Set cfg in this cycle. Done to reduce latency by 1 cycle
                                mode_i = aes_test_mode;                     // Key and IV can be loaded in next sub state
                                dir_i = aes_test_dir;
                                
                                if(aes_test_reuse_key) begin
                                    next_sub_state = SINC_SUB_STATE_5;
                                end
                                else begin
                                    if(~dma_r_exec) begin
                                        c_wrap_dma_cread = 1'h1;
                                        c_wrap_dma_caddr = key_addr;
                                        c_wrap_dma_clen[3:0] = 4'h8;

                                        if (dma_c_wrap_craccept) begin
                                            set_dma_r_exec = 1'h1;    
                                        end
                                    end

                                    if (dma_c_wrap_cr_err) begin
                                            c_wrap_cmd_comp = 1'h1;
                                            c_wrap_cmd_err = 1'h1;
                                            sts_upd = 1'h1;
                                            sts = STS_KEY_FET_ERR;
                                            next_state = SINC_IDLE;
                                        end
                                    else if (r_comp & dma_c_wrap_cr_comp) begin
                                        new_key_loaded = 1'h1;
                                        next_sub_state = SINC_SUB_STATE_5;
                                    end
                                end
                            end
                        end
                        SINC_SUB_STATE_5: begin             // also drive AES inputs and ensure it is ready to accept data
                            key_vld_i = key_rdy_o & (~(aes_test_reuse_key & reuse_key));
                            skip_key_i = key_rdy_o & aes_test_reuse_key & reuse_key;
                            key_i = key_q[255:0];
                            key_size_i = aes_test_key_len;
                            iv_ctx_vld_i = iv_ctx_rdy_o;
                            iv_ctx_sel_i = 1'h1;
                            iv_i[95:0] = aes_iv_nonce[95:0];

                            if(aes_test_din_err) begin
                                c_wrap_cmd_comp = 1'h1;
                                c_wrap_cmd_err = 1'h1;
                                sts_upd = 1'h1;
                                sts = STS_INV_CMD;
                                next_state = SINC_IDLE;
                            end
                            else if(aes_test_done) begin         // wait till AES test done flag
                                set_cfg_key_iv_rdy = 1'h1;
                                next_sub_state = SINC_SUB_STATE_1;
                            end
                        end
                        default: begin
                            invld_state = 1'h1;
                            next_sub_state = SINC_SUB_STATE_1;
                            next_state = SINC_IDLE; 
                        end
                    endcase
                end
            end
            AES_SEED: begin
                if (NO_SEED_LOADING) begin
                    c_wrap_cmd_comp = 1'h1;
                    next_state = SINC_IDLE;
                end else begin
                  case(sub_state)
                    SINC_SUB_STATE_1: begin                     // Break read seed into 2 reads of 10 beats for AES drbg
                        is_r_seed = 1'h1;                       // this is first read seed
                        clr_dma_r_exec = dma_r_comp;
                        clr_r_comp = dma_r_comp;

                        if((~dma_r_exec) & (seed_rdy_o)) begin
                            c_wrap_dma_cread = 1'h1;
                            c_wrap_dma_caddr = RNG_SEED_BASE_ADDR;
                            c_wrap_dma_clen[3:0] = 4'hA;

                            if (dma_c_wrap_craccept) begin
                                set_dma_r_exec = 1'h1;    
                            end
                        end

                        if (dma_c_wrap_cr_err) begin
                            c_wrap_cmd_comp = 1'h1;
                            c_wrap_cmd_err = 1'h1;
                            sts_upd = 1'h1;
                            sts = STS_RNG_SEED_ERR;
                            next_state = SINC_IDLE;
                        end
                        else if(r_comp & dma_c_wrap_cr_comp) begin
                            next_sub_state = SINC_SUB_STATE_2;
                        end
                    end
                    SINC_SUB_STATE_2: begin                  // this is second read seed
                        is_r_seed = 1'h1;
                        clr_dma_r_exec = dma_r_comp;
                        clr_r_comp = dma_r_comp;

                        if(~dma_r_exec) begin
                            c_wrap_dma_cread = 1'h1;
                            c_wrap_dma_caddr = RNG_SEED_BASE_ADDR + 6'h28;       // continue from last read
                            c_wrap_dma_clen[3:0] = 4'hA;

                            if (dma_c_wrap_craccept) begin
                                set_dma_r_exec = 1'h1;    
                            end
                        end

                        if (dma_c_wrap_cr_err) begin
                            c_wrap_cmd_comp = 1'h1;
                            c_wrap_cmd_err = 1'h1;
                            sts_upd = 1'h1;
                            sts = STS_RNG_SEED_ERR;
                            next_state = SINC_IDLE;
                        end
                        else if(r_comp & dma_c_wrap_cr_comp) begin
                            c_wrap_cmd_comp = 1'h1;
                            set_aes_seeded = 1'h1;
                            next_state = SINC_IDLE;
                        end
                    end
                    default: begin
                        invld_state = 1'h1;
                        next_sub_state = SINC_SUB_STATE_1;
                        next_state = SINC_IDLE; 
                    end
                  endcase
                end
            end
            default: begin
                invld_state = 1'h1;
                next_sub_state = SINC_SUB_STATE_1;
                next_state = SINC_IDLE; 
            end
        endcase
    end

    /* AES data and tag controller logic */
    /* Also used to pop from IB and push to OB */
    always_ff @( posedge gclk or negedge lp_rstn_i ) begin
        if (~lp_rstn_i) begin
            aes_ctrl_state <= AES_IDLE;
            aes_ctrl_sub_state <= SINC_SUB_STATE_1;
        end
        else begin
            if(severe_err | internal_error) begin
                aes_ctrl_state <= AES_IDLE;
                aes_ctrl_sub_state <= SINC_SUB_STATE_1;
            end
            else begin
                aes_ctrl_state <= next_aes_ctrl_state;
                aes_ctrl_sub_state <= next_aes_ctrl_sub_state;
            end
        end
    end

    always_comb begin
        next_aes_ctrl_state     = aes_ctrl_state;
        next_aes_ctrl_sub_state = aes_ctrl_sub_state;
        aes_test_done           = 1'h0;
        aes_test_sts_din_rdy    = 1'h0;
        set_aes_test_sts_dout_vld = 1'h0;
        aes_test_sts_tag_out    = 1'h0;
        aes_test_dout           = 128'h0;
        clr_aes_test_din_vld    = 1'h0;
        ctx_dout_rdy_i          = 1'h0;
        din_vld_i               = 1'h0;
        din_last_i              = 1'h0;
        din_aad_sel_i           = 1'h0;
        din_i                   = 128'h0;
        din_bytecnt_i           = 5'h00;
        ib_pop_en               = 1'h0;
        ob_push_en              = 1'h0;
        ob_push_data            = 128'h0;
        tag_rdy_i               = 1'h0;
        invld_aes_ctrl_state    = 1'h0;
        clr_aes_test_sts_dout_vld = 1'h0;
        case(aes_ctrl_state)
            AES_IDLE: begin
                if(is_state_fetch_block | is_state_encr_block) begin
                    if(disable_encr_auth_check_i) begin
                        next_aes_ctrl_state = AES_BYPASS;
                    end
                    else if (start_aes_data) begin
                        next_aes_ctrl_state = AES_IN;
                    end
                end
                else if(is_state_aes_test) begin
                    next_aes_ctrl_state = AES_TEST_IN;
                end
            end
            AES_IN: begin       // Wait for IB data and AES din rdy to drive input
                if(ib_pop_rdy) begin                        //drive input when IB is ready
                    if(first_aes_block & ob_empty) begin    // if first input block, ensure ob is also empty before driving input
                        ctx_dout_rdy_i = 1'h1;
                        din_vld_i = 1'h1;
                        din_last_i = last_aes_block;
                        din_aad_sel_i = 1'h0;
                        din_i = ib_pop_data;
                        din_bytecnt_i = 5'h10;
                    end
                    else if(~first_aes_block) begin         // if not first input block, drive input as soon as it is available
                        din_vld_i = 1'h1;
                        din_last_i = last_aes_block;
                        din_aad_sel_i = 1'h0;
                        din_i = ib_pop_data;
                        din_bytecnt_i = 5'h10;
                    end
                end

                if(aes_err_q) begin
                    next_aes_ctrl_state = AES_IDLE;
                end
                else if (din_rdy_o & ib_pop_rdy) begin      // move to AES_OUT as soon as input is accepted
                    ib_pop_en = 1'h1;                       // only pop data when accepted
                    next_aes_ctrl_state = AES_OUT;
                end
                else if (last_aes_out_block) begin          // move to AES_OUT to capture the last output block
                    next_aes_ctrl_state = AES_OUT;
                end
            end
            AES_OUT: begin      // Wait for OB empty and AES dout vld to accept output
                if(aes_err_q) begin
                    next_aes_ctrl_state = AES_IDLE;
                end
                else if(ob_empty) begin
                    ctx_dout_rdy_i = 1'h1;

                    if(ctx_dout_vld_o) begin                        // output accepted, next state condition
                        ob_push_en = 1'h1;
                        ob_push_data = dout_o;
                        
                        if(dout_last_o) begin                       // move to TAG if last output
                            next_aes_ctrl_state = AES_TAG_OUT;
                        end
                        else if (~(din_rdy_o & ib_pop_rdy)) begin   // move to AES IN if output accepted but input not driven
                            next_aes_ctrl_state = AES_IN; 
                        end
                    end
                end

                if(din_rdy_o & ib_pop_rdy) begin       // drive input immediately if available
                    din_vld_i = 1'h1;
                    ib_pop_en = 1'h1;
                    din_last_i = last_aes_block;
                    din_aad_sel_i = 1'h0;
                    din_i = ib_pop_data;
                    din_bytecnt_i = 5'h10;
                end
            end
            AES_TAG_OUT: begin
                if(aes_err_q) begin
                    next_aes_ctrl_state = AES_IDLE;
                end
                else if(is_state_fetch_block) begin
                    if(comp_tag_en) begin                   // In fetch block command, only set tag rdy when tag is being compared (tag vld is already set at this point)
                        tag_rdy_i = 1'h1;
                        ib_pop_en = 1'h1;
                        next_aes_ctrl_state = AES_IDLE;
                    end
                end
                else if(is_state_encr_block) begin
                    if(ob_empty & tag_vld_o) begin                     // Store the auth tag in OB (don't use additional flops)
                        tag_rdy_i = 1'h1;
                        ob_push_en = 1'h1;
                        ob_push_data = tag_o;
                        next_aes_ctrl_state = AES_IDLE;
                    end
                end
            end
            AES_TEST_IN: begin                              // Drive din as soon as AES is ready to accept it
                if(c_wrap_cmd_comp) begin
                    clr_aes_test_din_vld = 1'h1;
                    next_aes_ctrl_state = AES_IDLE;
                end
                else begin
                    aes_test_sts_din_rdy = din_rdy_o;

                    if(din_rdy_o & aes_test_din_vld) begin
                        
                        din_vld_i = 1'h1;
                        din_last_i = aes_test_din_last;
                        din_aad_sel_i = aes_test_din_aad_sel;
                        din_i = aes_test_din;
                        din_bytecnt_i = aes_test_din_bytecnt;
                        ctx_dout_rdy_i = first_aes_block;       // set ctx_dout_rdy_i for first block as aes_core requires that. Read GP AES MAS for more details.
                        clr_aes_test_din_vld = 1'h1;

                        if(~aes_test_din_aad_sel) begin         // Only PT/CT generates output
                            next_aes_ctrl_state = AES_TEST_OUT;
                            next_aes_ctrl_sub_state = SINC_SUB_STATE_1;
                        end
                    end
                end
            end
            AES_TEST_OUT: begin
                if(c_wrap_cmd_comp) begin
                    clr_aes_test_sts_dout_vld = 1'h1;
                    next_aes_ctrl_state = AES_IDLE;
                end
                else begin
                    case(aes_ctrl_sub_state)
                        SINC_SUB_STATE_1: begin
                            set_aes_test_sts_dout_vld = ctx_dout_vld_o;         // set the dout valid field when AES sets dout vld
                            aes_test_dout = dout_o;
                            
                            if(first_aes_block) begin                       // set ctx_dout_rdy_i for first block as aes_core requires that. Read GP AES MAS for more details.
                                ctx_dout_rdy_i = 1'h1;

                                if(ctx_dout_vld_o) begin                    // for first block, go to sub-state 2 or 3 once vld arrives and wait for ack (special case)
                                    if(~dout_last_o) begin                  // sub state 2 if not the last output
                                        next_aes_ctrl_sub_state = SINC_SUB_STATE_2;
                                    end
                                    else begin                              // sub state 3, if it is last output
                                        next_aes_ctrl_sub_state = SINC_SUB_STATE_3;
                                    end
                                end
                            end
                            else begin
                                if(ctx_dout_vld_o & aes_test_dout_ack) begin    // for other blocks, set rdy only when ack arrives, otherwise AES will replace dout with tag
                                    ctx_dout_rdy_i = 1'h1;

                                    if(~dout_last_o) begin                      // continue if not the last output
                                        next_aes_ctrl_state = AES_TEST_IN; 
                                    end
                                    else begin
                                        if(aes_test_mode_q == AES_GCM) begin
                                            next_aes_ctrl_state = AES_TEST_TAG_OUT;
                                        end
                                        else begin
                                            aes_test_done = 1'h1;
                                            next_aes_ctrl_state = AES_TEST_IN;
                                        end
                                    end
                                end
                            end
                        end
                        SINC_SUB_STATE_2: begin                             // waiting for dout ack, but not the last output block
                            if(aes_test_dout_ack) begin                     // move back to test input state
                                next_aes_ctrl_state = AES_TEST_IN;
                            end
                        end
                        SINC_SUB_STATE_3: begin                             // waiting for dout ack for the last output block

                            if(aes_test_dout_ack) begin                     // move back to test tag out if GCM or input state if non-GCM
                                if(aes_test_mode_q == AES_GCM) begin
                                    next_aes_ctrl_state = AES_TEST_TAG_OUT;
                                end
                                else begin                                  // set done flag if non-GCM
                                    aes_test_done = 1'h1;
                                    next_aes_ctrl_state = AES_TEST_IN;
                                end
                            end
                        end
                        default: begin
                            invld_aes_ctrl_state = 1'h1;
                            next_aes_ctrl_state = AES_IDLE; 
                            next_aes_ctrl_sub_state = SINC_SUB_STATE_1;
                        end
                    endcase
                end
            end
            AES_TEST_TAG_OUT: begin
                if(c_wrap_cmd_comp) begin
                    clr_aes_test_sts_dout_vld = 1'h1;
                    next_aes_ctrl_state = AES_IDLE;
                end
                else begin
                    set_aes_test_sts_dout_vld = tag_vld_o;
                    aes_test_sts_tag_out = tag_vld_o;
                    aes_test_dout = tag_o;

                    if(tag_vld_o & aes_test_dout_ack) begin
                        tag_rdy_i = 1'h1;
                        aes_test_done = 1'h1;
                        next_aes_ctrl_state = AES_TEST_IN;
                    end
                end
            end
            AES_BYPASS:begin
                ob_push_en = ib_pop_rdy & ob_empty;     // Push data in OB when IB is ready and OB is empty
                ib_pop_en = ib_pop_rdy & ob_empty;      // Also pop IB at the same time as push OB
                ob_push_data = ib_pop_data;

                if(c_wrap_cmd_comp) begin                   // if AES is bypassed, there is no auth tag. Wait till last cache block is written
                    next_aes_ctrl_state = AES_IDLE;
                end
            end
            default: begin
                invld_aes_ctrl_state = 1'h1;
                next_aes_ctrl_state = AES_IDLE; 
            end
        endcase
    end

    /* Input buffer push controller */
    always_comb begin
        ib_push_en = 1'h0;
        ib_push_data = 32'h0;

        if(is_r_cache_block | is_r_tag) begin
            ib_push_en = dma_c_wrap_r_vld;
            ib_push_data = dma_c_wrap_rdata;
        end
    end

    /* Drive seed to GP AES */
    always_comb begin
        seed_vld_i = 1'h0;
        seed_i = 32'h0;

        if (!NO_SEED_LOADING) begin
            if(is_r_seed) begin
                seed_vld_i = dma_c_wrap_r_vld;
                seed_i = dma_c_wrap_rdata;
            end
        end
    end

    /* Read data beat counter */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            rdata_bt_cnt <= {BLOCK_LENW{1'h0}};
            r_comp <= 1'h0;
        end
        else begin
            if (clr_r_comp | rst_ctrl_signals) begin
                rdata_bt_cnt <= {BLOCK_LENW{1'h0}};
                r_comp <= 1'h0;
            end
            else if(is_r_seed) begin
                if(dma_c_wrap_r_vld) begin
                    if(rdata_bt_cnt[4:0] == 5'h09) begin
                        rdata_bt_cnt[4:0] <= 5'h00;
                        r_comp <= 1'h1;
                    end
                    else begin
                        rdata_bt_cnt[4:0] <= rdata_bt_cnt[4:0] + 5'h01;
                    end
                end
            end
            else if(is_r_key) begin
                if(dma_c_wrap_r_vld) begin
                    if(rdata_bt_cnt[2:0] == 3'h7) begin
                        rdata_bt_cnt[2:0] <= 3'h0;
                        r_comp <= 1'h1;
                    end
                    else begin
                        rdata_bt_cnt[2:0] <= rdata_bt_cnt[2:0] + 3'h1;
                    end
                end
            end
            else if(is_r_tag) begin
                if(dma_c_wrap_r_vld) begin
                    if(rdata_bt_cnt[1:0] == 2'h3) begin
                        rdata_bt_cnt[1:0] <= 2'h0;
                        r_comp <= 1'h1;
                    end
                    else begin
                        rdata_bt_cnt[1:0] <= rdata_bt_cnt[1:0] + 2'h1;
                    end
                end
            end
            else if(is_r_cache_block) begin
                if(dma_c_wrap_r_vld) begin
                    if(rdata_bt_cnt == (cache_block_len - 1'h1)) begin
                        rdata_bt_cnt <= {BLOCK_LENW{1'h0}};
                        r_comp <= 1'h1;
                    end
                    else begin
                        rdata_bt_cnt <= rdata_bt_cnt + 1'h1;
                    end
                end
            end
        end
    end

    /* Write data beat counter */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            wdata_bt_cnt <= {BLOCK_LENW{1'h0}};
            w_comp <= 1'h0;
        end
        else begin
            if (clr_w_comp | rst_ctrl_signals) begin
                w_comp <= 1'h0;
                wdata_bt_cnt <= {BLOCK_LENW{1'h0}};
            end
            else if(is_w_tag) begin
                if(c_wrap_dma_w_vld & dma_c_wrap_w_accept) begin
                    if(wdata_bt_cnt[1:0] == 2'h3) begin
                        wdata_bt_cnt[1:0] <= 2'h0;
                        w_comp <= 1'h1;
                    end
                    else begin
                        wdata_bt_cnt[1:0] <= wdata_bt_cnt[1:0] + 1'h1;
                    end
                end
            end
            else if(is_w_cache_block & is_state_encr_block) begin           // cache block is written to cache IRAM or external memory
                if(c_wrap_dma_w_vld & dma_c_wrap_w_accept) begin            // depending on whether cache is being encrypted during encr block cmd
                    if(wdata_bt_cnt == (cache_block_len - 1'h1)) begin      // or decrypted during fetch block cmd
                        wdata_bt_cnt <= {BLOCK_LENW{1'h0}};
                        w_comp <= 1'h1;
                    end
                    else begin
                        wdata_bt_cnt <= wdata_bt_cnt + 1'h1;
                    end
                end
            end
            else if(is_w_cache_block & is_state_fetch_block) begin
                if(cmu_mem_wr) begin
                    if(wdata_bt_cnt == (cache_block_len - 1'h1)) begin
                        wdata_bt_cnt <= {BLOCK_LENW{1'h0}};
                        w_comp <= 1'h1;
                    end
                    else begin
                        wdata_bt_cnt <= wdata_bt_cnt + 1'h1;
                    end
                end
            end
        end
    end

    /* Flag to indicate DMA r/w has been executed */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            dma_r_exec <= 1'h0;
            dma_w_exec <= 1'h0;
        end
        else begin
            if(clr_dma_r_exec | rst_ctrl_signals) begin
                dma_r_exec <= 1'h0;
            end
            else if(set_dma_r_exec) begin
                dma_r_exec <= 1'h1;
            end

            
            if(clr_dma_w_exec | rst_ctrl_signals) begin
                dma_w_exec <= 1'h0;
            end
            else if(set_dma_w_exec) begin
                dma_w_exec <= 1'h1;
            end
        end
    end

    /* counter to count num of blocks encrypted during encr_block cmd*/
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            encr_block_cnt <= 12'h0;
        end
        else begin
            if(rst_ctrl_signals) begin
                encr_block_cnt <= 12'h0;
            end
            else if(is_state_encr_block & dma_c_wrap_cw_comp &
                    (
                        (disable_encr_auth_check_i & is_w_cache_block) |
                        (is_w_tag)
                    )
            ) begin
                if(last_encr_block) begin
                    encr_block_cnt <= 12'h0;
                end
                else begin
                    encr_block_cnt <= encr_block_cnt + 1'h1;
                end
            end
        end
    end

    /* counter to count num of aes blocks processed in a single cache block*/
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            aes_block_cnt <= {NUM_AES_BLOCKSW{1'h0}};
        end
        else begin
            if(rst_ctrl_signals | (cfg_vld_i & cfg_rdy_o)) begin
                aes_block_cnt <= {NUM_AES_BLOCKSW{1'h0}};
            end
            else if(din_vld_i & din_rdy_o) begin
                if(aes_block_cnt == (total_aes_blocks - 1'h1)) begin
                    aes_block_cnt <= {NUM_AES_BLOCKSW{1'h0}};
                end
                else begin
                    aes_block_cnt <= aes_block_cnt + 1'h1;
                end
            end
        end
    end

    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            first_aes_block_flag <= 1'h0;
        end
        else begin
            if(rst_ctrl_signals) begin
                first_aes_block_flag <= 1'h0;
            end
            else if(din_vld_i & din_rdy_o & first_aes_block) begin
                first_aes_block_flag <= 1'h1;
            end
            else if (ctx_dout_vld_o & ctx_dout_rdy_i) begin
                first_aes_block_flag <= 1'h0;
            end
        end
    end

    /* flops to store reuse_key flag and aes_test_reuse_key_flag 
        reuse_key - tells whether a key is already loaded into AES for func mode, if so set skip_key_i for that AES op */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            reuse_key <= 1'h0;
        end
        else begin
            if(new_key_loaded | gp_aes_clr_din) begin
                reuse_key <= 1'h0;
            end
            else if(key_vld_i & key_rdy_o) begin
                reuse_key <= 1'h1;
            end
        end
    end

    /* flag to indicate whether AES drbg is seeded */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            aes_seeded <= NO_SEED_LOADING ? 1'b1 : 1'b0;
        end
        else begin
            if(set_aes_seeded) begin
                aes_seeded <= 1'h1;
            end
        end
    end

    /* flops for aes test mode operation, and other misc signals */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            aes_test_sts_cfg_key_iv_rdy <= 1'h0;
            aes_test_mode_q <= AES_RSVD0;
            aes_err_q <= 1'h0;
            gp_aes_clr <= 1'h0;
            last_aes_out_block <= 1'h0;
        end
        else begin
            if(clr_cfg_key_iv_rdy)begin
                aes_test_sts_cfg_key_iv_rdy <= 1'h0;
            end
            else if(set_cfg_key_iv_rdy) begin
                aes_test_sts_cfg_key_iv_rdy <= 1'h1;
            end

            if (rst_ctrl_signals) begin
                aes_test_mode_q <= AES_RSVD0;
            end
            else if(is_state_aes_test) begin
                if(cfg_vld_i & cfg_rdy_o) begin         // capture AES mode to know whether auth tag will be generated
                    aes_test_mode_q <= aes_test_mode;
                end
            end

            if (aes_err) begin                          // Store aes error until the next cmd uses AES
                aes_err_q <= 1'h1;
            end
            else if (clr_aes_err) begin                 // Only clear the error once it is flagged in one of the commands or sinc reset is perf
                aes_err_q <= 1'h0;
            end
            

            if(gp_aes_clr_din) begin                    // Drive gp aes clr using flop to avoid combo loop cause by aes core
                gp_aes_clr <= 1'h1;
            end
            else begin
                gp_aes_clr <= 1'h0;
            end

            if(last_aes_block & din_vld_i & din_rdy_o) begin        // Used by aes_ctrl_state FSM to move to AES_OUT to capture last output block
                last_aes_out_block <= 1'h1;
            end
            else if (ctx_dout_vld_o & dout_last_o & ctx_dout_rdy_i) begin
                last_aes_out_block <= 1'h0;
            end
        end
    end

    assign cache_block_len      = BLOCK_LENW'(unsigned'(BLOCK_LEN));
    assign total_aes_blocks     = NUM_AES_BLOCKSW'(NUM_AES_BLOCKS);
    assign last_aes_block       = (aes_block_cnt == (total_aes_blocks - 1'h1));
    assign first_aes_block      = (aes_block_cnt == {NUM_AES_BLOCKSW{1'h0}}) | first_aes_block_flag;
    assign c_wrap_sts_upd       = sts_upd;
    assign c_wrap_sts           = sts;
    assign encr_block_sts       = encr_block_cnt;

    assign fetch_block_addr     = {cmu_ctrl_fetch_block_num, {BLOCK_SIZEW{1'h0}}} + ext_block_base_addr;    // Block address for fetch block request 
    assign fetch_block_tag_addr = {cmu_ctrl_fetch_block_num, 4'h0} + ext_auth_tag_base_addr;                // Tag address for fetch block request 
    assign key_addr             = {block_encr_key, {7'h0}} + KSU_KEY_SLOT_BASE_ADDR;

    assign comp_tag_pass            = comp_tag_en ? (ib_pop_data == tag_o): 1'h0;
    assign last_encr_block          = (encr_block_cnt == (num_of_blocks - 1'h1));
    assign curr_encr_block_num      = block_encr_num + encr_block_cnt;
    assign curr_encr_block_r_addr   = {encr_block_cnt, {BLOCK_SIZEW{1'h0}}} + block_encr_addr;
    assign curr_encr_block_w_addr   = {curr_encr_block_num, {BLOCK_SIZEW{1'h0}}} + ext_block_base_addr;
    assign curr_encr_block_tag_addr = {curr_encr_block_num, {4'h0}} + ext_auth_tag_base_addr;

    assign dma_r_comp           = dma_c_wrap_cr_comp | dma_c_wrap_cr_err;       // used to clear diff flags
    assign dma_w_comp           = dma_c_wrap_cw_comp | dma_c_wrap_cw_err;       // used to clear diff flags

    assign aes_test_mode        = aes_modes_t'(aes_test_ctrl[3:0]);
    assign aes_test_dir         = aes_test_ctrl[4];
    assign aes_test_key_len     = key_sizes_t'(aes_test_ctrl[6:5]);
    assign aes_test_reuse_key   = aes_test_ctrl[7];
    assign aes_test_cfg_key_iv_vld = aes_test_ctrl[8];
    assign aes_test_din_vld     = aes_test_ctrl[9];
    assign aes_test_din_bytecnt = aes_test_ctrl[14:10];
    assign aes_test_din_last    = aes_test_ctrl[15];
    assign aes_test_din_aad_sel = aes_test_ctrl[16];
    assign aes_test_dout_ack    = aes_test_ctrl[17];

    assign invld_cfg            = aes_test_cfg_key_iv_vld & (aes_test_mode != AES_GCM) & (aes_test_mode != AES_ECB);
    assign invld_key_len        = aes_test_cfg_key_iv_vld & (aes_test_key_len != KEY_SIZE_256);
    assign invld_din_bytecnt    = aes_test_din_vld & (aes_test_mode == AES_ECB) & (aes_test_din_bytecnt < 5'h10);
    assign invld_din_aad_sel    = aes_test_din_vld & aes_test_din_aad_sel;
    assign aes_test_cfg_err     = invld_cfg | invld_key_len;
    assign aes_test_din_err     = invld_din_bytecnt | invld_din_aad_sel;

    assign c_wrap_fault_err     = invld_state | invld_aes_ctrl_state;
    assign aes_err              = cmd_err_o | (|fault_err_o);
    assign internal_error       = c_wrap_cmd_err;
    assign ib_ob_clr            = severe_err | internal_error;
    assign gp_aes_clr_din       = severe_err | clr_aes_and_reuse_key | internal_error;

    // Necessary tie-offs
    assign ctx_in_i             = 384'h0;

endmodule
