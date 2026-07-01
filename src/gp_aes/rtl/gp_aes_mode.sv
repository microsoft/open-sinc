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
// File        : gp_aes_mode.sv
// Description : GP AES mode controller. Controls AES mode of operation and
//               flow of data through AES core and AES GHASH modules.

module gp_aes_mode
import gp_aes_pkg::*;
(

    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic                                 clear_i,
    input logic [8:0]                           unit_size_i,

    //****************************************************************
    // Configuration
    //****************************************************************
    input logic [3:0]                           mode_i,
    input logic                                 dir_i,
    input logic                                 cfg_vld_i,
    output logic                                cfg_rdy_o,

    //****************************************************************
    // Key interface
    //****************************************************************
    input logic [255:0]                         key_i,
    input logic [1:0]                           key_size_i,
    input logic                                 key_vld_i,
    input logic                                 skip_key_i,
    output logic                                key_rdy_o,

    //****************************************************************
    // IV/Input context interface
    //****************************************************************
    input logic [127:0]                         iv_i,
    input logic [383:0]                         ctx_in_i,
    input logic                                 iv_ctx_sel_i,
    input logic                                 iv_ctx_vld_i,
    output logic                                iv_ctx_rdy_o,

    //****************************************************************
    // Input data interface
    //****************************************************************
    input logic [127:0]                         din_i,
    input logic [4:0]                           din_bytecnt_i,
    input logic                                 din_last_i,
    input logic                                 din_aad_sel_i,
    input logic                                 din_vld_i,
    output logic                                din_rdy_o,

    //****************************************************************
    // Output data/Output context interface
    //****************************************************************
    output logic [127:0]                        dout_o,
    output logic [4:0]                          dout_bytecnt_o,
    output logic                                dout_last_o,
    output logic [383:0]                        ctx_out_o,
    output logic                                ctx_dout_vld_o,
    input logic                                 ctx_dout_rdy_i,

    //****************************************************************
    // Authentication tag interface
    //****************************************************************
    output logic [127:0]                        tag_o,
    output logic                                tag_vld_o,
    input logic                                 tag_rdy_i,

    //****************************************************************
    // Status interface
    //****************************************************************
    output logic                                cmd_err_o,
    output logic [1:0]                          fault_err_o,
    output logic                                busy_o,

    //****************************************************************
    // AES core interface
    //****************************************************************
    input logic                                 a_req_i,        // from core - core input rdy
    input logic                                 b_valid_i,      // from core - core output vld
    input logic [3:0][3:0] [7:0]                b_i,
    input logic                                 core_fault_i,

    output logic [3:0][3:0] [7:0]               a_o,
    output logic                                a_valid_o,      // to core - core input vld
    output logic                                b_req_o,        // to core - core output rdy
    output logic                                key_valid_o,    // to core - key valid
    output logic [7:0][3:0] [7:0]               key_o,
    output logic                                dir_o,
    output logic [3:0]                          nr_o,
    output logic [3:0]                          nk_o,
    output logic                                ghash_en_o,

    //****************************************************************
    // AES GHASH interface
    //****************************************************************
    input logic                                 ghash_in_rdy,
    input logic [127:0]                         ghash_out,
    input logic                                 ghash_out_vld,
    input logic                                 ghash_fault,

    output logic [127:0]                        ghash_in,
    output logic                                ghash_in_last,
    output logic                                ghash_in_vld,
    output logic                                ghash_out_rdy,
    output logic [127:0]                        h
    );


    integer          ii;
    integer          jj;

    /* Main Mode FSM */
    mode_main_fsm_t             mode_state;
    mode_main_fsm_t             next_mode_state;
    sub_state_fsm_t             mode_sub_state;
    sub_state_fsm_t             next_mode_sub_state;

    /* GHASH FSM */
    mode_ghash_fsm_t            ghash_state;
    mode_ghash_fsm_t            next_ghash_state;
    sub_state_fsm_t             ghash_sub_state;
    sub_state_fsm_t             next_ghash_sub_state;

    /* Core input control FSM */
    core_in_fsm_t               core_in_state;
    core_in_fsm_t               next_core_in_state;

    /* Secondary Mode FSM */
    mode_sec_fsm_t              cur_state;
    mode_sec_fsm_t              next_state;
    
    aes_modes_t                 mode_q;
    key_sizes_t                 key_size_q;
    key_sizes_t                 key_size;

    logic [127:0]               iv_r;
    logic [127:0]               iv_nxt;
    logic [127:0]               iv_swap;
    logic [127:0]               iv_i_swap;
    logic [127:0]               iv_plus_1;
    logic [127:0]               iv_unswap;
    logic                       s_idle;
    logic                       s_key0;
    logic                       s_data0;
    logic                       s_key1;
    logic                       s_data1;
    logic [31:0]                msg_cnt;
    logic [127:0]               temp;
    logic [127:0]               temp_1d;
    logic [127:0]               b_vec;
    logic [3:0][3:0][7:0]       a_state;
    logic                       i_valid_r;
    logic [7:0][3:0][7:0]       key_state;
    logic [127:0]               a;
    logic                       a_valid;
    logic                       a_req_unused;           // a_req_unused is used by XTS mode for unit cnt
    logic [127:0]               b;
    logic                       b_valid;
    logic [127:0]               b_byte_swap;
    logic [127:0]               b_bit_swap;
    logic [255:0]               key;
    logic                       key_valid;
    logic [8:0]                 unit_cnt;
    logic                       eou;
    logic                       eom;
    logic [127:0]               temp_alpha;
    logic                       first_msg;

    logic                       a_valid_int;    // a_valid intermediate
    logic                       dir_q;
    logic [127:0]               din_q;
    logic [127:0]               din_i_padded;
    logic [4:0]                 bytes_in_din;
    logic [4:0]                 bytes_in_din_q;
    logic [127:0]               din_mux;
    logic [127:0]               din_mux_byte_swap;
    logic [127:0]               din_mux_bit_swap;
    logic [255:0]               key_q;
    logic [255:0]               key_mux;
    logic [127:0]               iv_tag;
    logic [1:0]                 din_last_q;
    logic [1:0][4:0]            din_bytecnt_q;
    logic [1:0]                 din_ptr;
    logic [1:0]                 dout_ptr;

    logic                       is_mode_aad;
    logic                       is_mode_data;
    logic                       is_mode_tag;
    logic                       is_ghash_aad;
    logic                       is_ghash_enc;
    logic                       is_ghash_dec;
    logic                       is_ghash_last;
    logic [31:0]                aad_cnt;
    logic                       rst_ctrl_signals;
    logic                       din_hndshk;
    logic [127:0]               inc32_in_unswap;
    logic [127:0]               inc32_in_swap;
    logic [127:0]               inc32_out_unswap;
    logic [127:0]               inc32_out_swap;
    logic                       precomp_h_start;
    logic                       precomp_h_done;
    logic                       precomp_h_en;
    logic                       h_vld;
    logic                       cfg_err;
    logic                       key_size_err;
    logic                       din_err;
    logic [34:0]                aad_cnt_bits;
    logic [34:0]                msg_cnt_bits;
    logic [127:0]               ghash_len;
    logic [127:0]               ghash_len_bit_swap;
    logic [127:0]               ghash_out_bit_swap;
    logic [127:0]               ghash_out_byte_swap;
    logic                       skip_key_q;
    logic                       iv_hndshk;
    logic                       mode_active;
    logic                       ctx_err;
    logic                       invld_mode_state;
    logic                       invld_ghash_state;
    logic                       invld_core_in_state;
    logic                       invld_mode_sub_state;
    logic                       invld_ghash_sub_state;
    logic                       invld_cur_state;
    logic                       dout_hndshk;
    logic                       new_key_hndshk;
    logic                       any_key_hndshk;
    logic [4:0]                 bytecnt;

    logic [383:0]               unused_ctx_in_i;
    logic                       is_wait_input_drive;
    logic                       din_ov_flag;
    logic                       dout_ov_flag;
    logic                       din_dout_ptr_match;
    logic                       din_dout_fifo_empty;
    logic                       din_ptr_pos;
    logic                       dout_ptr_pos;
    logic [255:0]               key_i_f;
    logic [1:0]                 key_size_i_f;
    logic                       key_vld_i_f;
    logic                       skip_key_i_f;
    logic                       cmd_err_f;
    logic                       cmd_err;
    logic                       mode_active_f;    

    assign cmd_err_o = cmd_err_f;

    /* State flops */
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            ghash_state         <= MODE_GHASH_IDLE;
            ghash_sub_state     <= AES_SUB_STATE_1;

            core_in_state       <= WAIT_FOR_INPUT_DRIVE;
        end
        else begin
            if(clear_i) begin
                ghash_state         <= MODE_GHASH_IDLE;
                ghash_sub_state     <= AES_SUB_STATE_1;

                core_in_state       <= WAIT_FOR_INPUT_DRIVE;
            end
            else begin
                ghash_state         <= next_ghash_state;
                ghash_sub_state     <= next_ghash_sub_state;

                core_in_state       <= next_core_in_state;
            end
        end
    end

    /* State flops */
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            mode_state          <= MODE_IDLE;
            mode_sub_state      <= AES_SUB_STATE_1;
        end
        else begin
            if(clear_i & (mode_state != MODE_IDLE)) begin
                mode_state          <= MODE_CFG;
                mode_sub_state      <= AES_SUB_STATE_1;
            end
            else if (cmd_err_f | (|fault_err_o)) begin
                mode_state          <= MODE_ERR;
                mode_sub_state      <= AES_SUB_STATE_1;
            end
            else begin
                mode_state          <= next_mode_state;
                mode_sub_state      <= next_mode_sub_state;
            end
        end
    end
    
    always_ff @(posedge clk_i or negedge rstn_i) begin
       if(~rstn_i) begin
          cmd_err_f    <= 'b0;
          key_i_f      <= 'b0;
          key_size_i_f <= 'b0; 
          key_vld_i_f  <= 'b0;
          skip_key_i_f <= 'b0;
      mode_active_f <= 1'b0;
       end 
       else begin
          if(clear_i) begin
             cmd_err_f    <= 'b0;
             key_i_f      <= 'b0;
             key_size_i_f <= 'b0; 
             key_vld_i_f  <= 'b0;
             skip_key_i_f <= 'b0;
      mode_active_f <= 1'b0;
          end
          else begin
             cmd_err_f    <= cmd_err;
             key_i_f      <= key_i;
             key_size_i_f <= key_size_i; 
             key_vld_i_f  <= key_vld_i;
             skip_key_i_f <= skip_key_i;
         mode_active_f <= mode_active;
          end
        end
    end
    /* 
    FSM to control top level inputs/outputs in different stages of AES
    It is also responsible for maintaining operation sequence for each invocation of AES. 
    */
    always_comb begin : mode_fsm_block

        next_mode_state             = mode_state;
        next_mode_sub_state         = mode_sub_state;
        cfg_rdy_o                   = 1'h0;
        iv_ctx_rdy_o                = 1'h0;
        key_rdy_o                   = 1'h0;
        precomp_h_start             = 1'h0;
        precomp_h_en                = 1'h0;
        precomp_h_done              = 1'h0;
        din_rdy_o                   = 1'h0;
        ghash_out_rdy               = 1'h0;
        is_mode_aad                 = 1'h0;
        is_mode_data                = 1'h0;
        is_mode_tag                 = 1'h0;
        rst_ctrl_signals            = 1'h0;
        b_req_o                     = 1'h0;
        ctx_dout_vld_o              = 1'h0;
        tag_vld_o                   = 1'h0;
        //invld_mode_state            = 1'h0;
        mode_active                 = 1'h0;
        
        case(mode_state)
            MODE_IDLE: begin
                rst_ctrl_signals = 1'h1;
                next_mode_state = MODE_CFG;
            end
            MODE_CFG: begin
               if(clear_i==0) begin
                   cfg_rdy_o = 1'h1;
               end         
               rst_ctrl_signals = 1'h1;

               if(cfg_vld_i & (clear_i == 0)) begin
                   mode_active = 1'h1;
                   next_mode_state = MODE_KEY;
               end
            end
            MODE_KEY: begin
                key_rdy_o = 1'h1;
                mode_active = 1'h1;

                if(key_vld_i_f | skip_key_i_f) begin
                    if(key_size_err) begin
                        next_mode_state = MODE_ERR;
                    end
                    else if(mode_q != AES_ECB) begin
                        next_mode_state = MODE_IV;
                    end
                    else begin
                        next_mode_state = MODE_WAIT_DRBG;       // ECB mode doesn't require IV
                        
                    end
                end
            end
            MODE_IV: begin
                iv_ctx_rdy_o = 1'h1;
                mode_active = 1'h1;

                if(iv_ctx_vld_i) begin
                    if(~iv_ctx_sel_i) begin
                        next_mode_state = MODE_ERR;
                    end
                    else begin
                        next_mode_state = MODE_WAIT_DRBG;
                    end
                end
            end
            MODE_WAIT_DRBG: begin
                mode_active = 1'h1;

                if(mode_q != AES_GCM) begin
                    next_mode_state = MODE_DATA;
                    next_mode_sub_state = AES_SUB_STATE_1;
                end
                else begin      // Precompute hash subkey for ghash before processing AAD or PT/CT
                    if(skip_key_q & h_vld) begin        // skip hash subkey computation if it is already calculated
                            next_mode_state = MODE_AAD;     //  and key loading was skipped
                        end
                        else begin
                            precomp_h_start = 1'h1;         //need a pulse signal along with level signal
                            precomp_h_en = 1'h1;
                            next_mode_state = MODE_HASH_SUBKEY;
                        end
                    end
            end
            MODE_HASH_SUBKEY: begin         // Wait for hash subkey to be calculated
                precomp_h_en = 1'h1;        // continue to hold this to keep core input block steady and store core output
                mode_active = 1'h1;
                b_req_o = 1'h1;
                
                if(b_valid) begin
                    precomp_h_done = 1'h1;
                    next_mode_state = MODE_AAD;
                    next_mode_sub_state = AES_SUB_STATE_1;
                end
            end
            MODE_AAD: begin
                is_mode_aad = 1'h1;
                mode_active = 1'h1;

                case(mode_sub_state)
                    AES_SUB_STATE_1: begin      // Wait for input block
                        din_rdy_o = 1'h1;       // Both AES core and ghash are ready at this point including drbg. 
                                                    
                        if(din_vld_i) begin  
                            if (din_aad_sel_i) begin        // Input data is AAD
                                next_mode_sub_state = AES_SUB_STATE_2;
                            end
                            else begin                      // Input data is PT/CT
                                is_mode_aad = 1'h0;
                                is_mode_data = 1'h1;        // Need to capture this as PT/CT input to AES core
                                next_mode_state = MODE_DATA;
                                next_mode_sub_state = AES_SUB_STATE_2;
                            end
                        end
                    end
                    AES_SUB_STATE_2: begin                  // block being processed by ghash
                        if(ghash_in_rdy) begin              // ghash ready for next block
                            din_rdy_o = 1'h1;

                            if(din_vld_i) begin
                                if(~din_aad_sel_i) begin    // Input data is PT/CT
                                    is_mode_aad = 1'h0;
                                    is_mode_data = 1'h1;    // Need to capture this as PT/CT input to AES core
                                    next_mode_state = MODE_DATA;
                                    next_mode_sub_state = AES_SUB_STATE_2;
                                end
                                else begin                  // Input data is AAD
                                    if (din_last_i) begin   // Input AAD block is the last block
                                        next_mode_state = MODE_TAG;
                                        next_mode_sub_state = AES_SUB_STATE_1;
                                    end
                                end
                            end
                            else begin
                                next_mode_sub_state = AES_SUB_STATE_1;
                            end
                        end
                    end
                    default: begin
                        //invld_mode_state = 1'h1;
                        next_mode_sub_state = AES_SUB_STATE_1;
                        next_mode_state = MODE_ERR;
                    end
                endcase
            end
            MODE_DATA: begin
                is_mode_data = 1'h1;
                mode_active = 1'h1;

                case(mode_sub_state)
                    AES_SUB_STATE_1: begin                  // Wait for input data to be sent
                        if(is_wait_input_drive & (~eom)) begin
                            din_rdy_o = 1'h1;

                            if(din_vld_i) begin
                                if(mode_q == AES_GCM) begin
                                    next_mode_sub_state = AES_SUB_STATE_2;
                                end
                                else begin
                                    next_mode_sub_state = AES_SUB_STATE_3;
                                end
                            end
                        end
                        else if (eom | (~din_dout_fifo_empty)) begin        // Move to sub state 2 or 3 if AES isn't finished processing all input blocks provided
                            if(mode_q == AES_GCM) begin
                                next_mode_sub_state = AES_SUB_STATE_2;
                            end
                            else begin
                                next_mode_sub_state = AES_SUB_STATE_3;
                            end
                        end
                    end
                    AES_SUB_STATE_2: begin                  // Wait for core output to be generated (GCM mode)
                        b_req_o = ctx_dout_rdy_i;
                        /* Future improvement - sub state 2 can be removed and combined together with sub state 3 
                            to improve the latency from 16->15 cycles for GCM mode. Remove all instances of if-else between sub state 2 and 3.
                            It also requires updating the masking logic to ensure GHASH and core don't use the same mask value */
                        // din_rdy_o = is_wait_input_drive & (~eom); 

                        if(b_valid) begin
                            ctx_dout_vld_o = 1'h1;
                            /* This provides GCM mode an extra cycle so GHASH can use the drbg mask in a spare cycle. */
                            din_rdy_o = is_wait_input_drive & (~eom);   // set din_rdy if previous input accepted

                            if (ctx_dout_rdy_i) begin               // if output accepted on the same cycle as generated
                                if(eom) begin                       // Don't assert din_rdy if this was last block
                                    next_mode_state = MODE_TAG;
                                    next_mode_sub_state = AES_SUB_STATE_1;
                                end
                                else begin
                                    if(~din_hndshk) begin    // Move to sub state 1 if output accepted but next input not provided
                                        next_mode_sub_state = AES_SUB_STATE_1;
                                    end
                                end
                            end
                            else begin                      // Move to sub state 3 if output not accepted
                                next_mode_sub_state = AES_SUB_STATE_4;
                            end
                        end
                    end
                    AES_SUB_STATE_3: begin                  // Wait for core output to be generated (non-GCM mode)
                        b_req_o = ctx_dout_rdy_i;
                        din_rdy_o = is_wait_input_drive & (~eom);       // set din_rdy if previous input accepted

                        if(b_valid) begin
                            ctx_dout_vld_o = 1'h1;

                            if (ctx_dout_rdy_i) begin               // if output accepted on the same cycle as generated
                                if(eom) begin                       // Don't assert din_rdy if this was last block
                                    next_mode_state = MODE_CFG;
                                    next_mode_sub_state = AES_SUB_STATE_1; //AES_SUB_STATE_3 is invalid state in MODE_AAD, hence substate has to be in AES_SUB_STATE_1
                                end
                                else begin
                                    if(~din_hndshk) begin    // Move to sub state 1 if output accepted but next input not provided
                                        next_mode_sub_state = AES_SUB_STATE_1;
                                    end
                                end
                            end
                            else begin                      // Move to sub state 4 if output not accepted
                                next_mode_sub_state = AES_SUB_STATE_4;
                            end
                        end
                    end
                    AES_SUB_STATE_4: begin                  // Wait for output to be accepted
                        ctx_dout_vld_o = 1'h1;              // TODO: ASSERT b_valid must stay high in this state
                        b_req_o = ctx_dout_rdy_i;
                        din_rdy_o = is_wait_input_drive & (~eom);   // set din_rdy if previous input accepted

                        if (ctx_dout_rdy_i) begin
                            if(eom) begin                   // Don't assert din_rdy if this was last block
                                if (mode_q == AES_GCM) begin
                                    next_mode_state = MODE_TAG;
                                    next_mode_sub_state = AES_SUB_STATE_1;
                                end
                                else begin
                                    next_mode_state = MODE_CFG;
                                    next_mode_sub_state = AES_SUB_STATE_1;
                                end
                            end
                            else begin
                                if(~din_hndshk) begin       // Move to sub state 1 if output accepted but next input not valid
                                    next_mode_sub_state = AES_SUB_STATE_1;
                                end
                                else begin                  // Move to sub state 2 or 3 if output accepted and input valid
                                    if(mode_q == AES_GCM) begin
                                        next_mode_sub_state = AES_SUB_STATE_2;
                                    end
                                    else begin
                                        next_mode_sub_state = AES_SUB_STATE_3;
                                    end
                                end
                            end
                        end
                    end
                    default: begin
                        //invld_mode_state = 1'h1;
                        next_mode_state = MODE_ERR;
                        next_mode_sub_state = AES_SUB_STATE_1;
                    end
                endcase
            end
            MODE_TAG: begin
                is_mode_tag = 1'h1;
                mode_active = 1'h1;

                case(mode_sub_state)
                    AES_SUB_STATE_1: begin              // Wait for GHASH to finish
                        ghash_out_rdy = 1'h1;
                        if(ghash_out_vld) begin     // Once GHASH is done, move to next sub state and wait until AES generates the tag
                            next_mode_sub_state = AES_SUB_STATE_2;
                        end
                    end
                    AES_SUB_STATE_2: begin              // Wait for AES to generate the tag
                        b_req_o = tag_rdy_i;        // AES is run by core_in_fsm
                        tag_vld_o = b_valid;
                        if (b_valid & tag_rdy_i) begin        // Tag read by external logic
                            next_mode_state = MODE_CFG;
                        end
                    end
                    default: begin
                        //invld_mode_state = 1'h1;
                        next_mode_state = MODE_ERR;
                        next_mode_sub_state = AES_SUB_STATE_1;
                    end
                endcase
            end
            MODE_ERR: begin
                if(clear_i) begin
                    mode_active = 1'h1;
                    rst_ctrl_signals = 1'h1;
                    next_mode_state = MODE_CFG;
                end
            end
            default: begin
                //invld_mode_state = 1'h1;
                mode_active = 1'h1;
                next_mode_state = MODE_ERR;
            end
        endcase
    end

    /*
    FSM to control GHASH input during different stages in GCM
    */
    always_comb begin : mode_ghash_fsm_block

        next_ghash_state        = ghash_state;
        next_ghash_sub_state    = ghash_sub_state;
        ghash_in_vld            = 1'h0;
        ghash_in_last           = 1'h0;
        is_ghash_aad            = 1'h0;
        is_ghash_enc            = 1'h0;
        is_ghash_dec            = 1'h0;
        is_ghash_last           = 1'h0;
        //invld_ghash_state       = 1'h0;

        case(ghash_state)
            MODE_GHASH_IDLE: begin
                if(cfg_vld_i & cfg_rdy_o & (aes_modes_t'(mode_i) == AES_GCM)) begin
                    next_ghash_state = MODE_GHASH_AAD;
                end
            end
            MODE_GHASH_AAD: begin                               // ghash is processing AAD
                is_ghash_aad = 1'h1;

                if(din_vld_i & din_rdy_o) begin                     // Input data is AAD
                    if(din_aad_sel_i) begin
                        ghash_in_vld = 1'h1;
                        
                        if(din_last_i) begin
                            next_ghash_state = MODE_GHASH_LAST;
                        end
                    end
                    else begin
                        if(dir_q) begin                             // Encryption
                            next_ghash_state = MODE_GHASH_ENC;      // CT block not generated at this point
                            next_ghash_sub_state = AES_SUB_STATE_1;
                        end
                        else begin                                  // Decryption
                            ghash_in_vld = 1'h1;                    // CT block also sent to ghash

                            if(din_last_i) begin
                                next_ghash_state = MODE_GHASH_LAST;
                            end
                            else begin
                                next_ghash_state = MODE_GHASH_DEC;
                                next_ghash_sub_state = AES_SUB_STATE_1;
                            end
                        end
                    end
                end
            end
            MODE_GHASH_ENC: begin                               // ghash in data encryption mode
                is_ghash_enc = 1'h1;

                case(ghash_sub_state)
                    AES_SUB_STATE_1: begin                          // Waiting for AES core output to send to GHASH
                        if(b_valid) begin
                            ghash_in_vld = 1'h1;

                            if(~ctx_dout_rdy_i) begin           // wait in sub state 2 if external logic not ready to accept output
                                next_ghash_sub_state = AES_SUB_STATE_2;
                            end
                            else begin                          // if core output accepted, then wait for next core output
                                if(eom) begin                   // if it was last block, next should be len(AAD) || len(CT)
                                    next_ghash_state = MODE_GHASH_LAST;
                                end    
                            end
                        end
                    end
                    AES_SUB_STATE_2: begin
                        if(ctx_dout_rdy_i) begin
                            if(eom) begin                       // if it was last block, next should be len(AAD) || len(CT)
                                next_ghash_state = MODE_GHASH_LAST;
                            end
                            else begin
                                next_ghash_sub_state = AES_SUB_STATE_1;
                            end
                        end
                    end
                    default: begin
                        //invld_ghash_state = 1'h1;
                        next_ghash_state = MODE_GHASH_IDLE;
                        next_ghash_sub_state = AES_SUB_STATE_1;
                    end
                endcase
            end
            MODE_GHASH_DEC: begin                               // ghash in data decryption mode
                is_ghash_dec = 1'h1;

                case(ghash_sub_state)
                    AES_SUB_STATE_1: begin
                        if(din_hndshk) begin                    // Send din to ghash ASAP (and to core)
                            if (ghash_in_rdy) begin
                                ghash_in_vld = 1'h1;

                                if(din_last_i) begin            // move to sub state 4 once last input block is sent to GHASH 
                                    next_ghash_sub_state = AES_SUB_STATE_4;
                                end
                            end
                            else begin                          // if GHASH not ready, wait for it to be ready, in sub state 2 or 3
                                if(din_last_i) begin            // if last din, go to sub state 3, otherwise sub state 2
                                    next_ghash_sub_state = AES_SUB_STATE_3;
                                end
                                else begin
                                    next_ghash_sub_state = AES_SUB_STATE_2;
                                end
                            end
                        end
                    end
                    AES_SUB_STATE_2: begin
                        if (ghash_in_rdy) begin
                            ghash_in_vld = 1'h1;
                            next_ghash_sub_state = AES_SUB_STATE_1;     // more input blocks to be processed
                        end
                    end
                    AES_SUB_STATE_3: begin
                        if (ghash_in_rdy) begin
                            ghash_in_vld = 1'h1;
                            next_ghash_sub_state = AES_SUB_STATE_4;     // this was last input block to process
                        end
                    end
                    AES_SUB_STATE_4: begin
                        if(b_valid & eom) begin
                            next_ghash_state = MODE_GHASH_LAST;         // aes core is done so ghash can use mask
                        end
                    end
                    default: begin
                        //invld_ghash_state = 1'h1;
                        next_ghash_state = MODE_GHASH_IDLE;
                        next_ghash_sub_state = AES_SUB_STATE_1;
                    end
                endcase
            end
            MODE_GHASH_LAST: begin                              // Send last input to ghash which is len(AAD) || len(CT)
                is_ghash_last = 1'h1;

                if(ghash_in_rdy) begin
                    ghash_in_vld = 1'h1;
                    ghash_in_last = 1'h1;
                    next_ghash_state = MODE_GHASH_IDLE;
                end
            end
            default: begin
                //invld_ghash_state = 1'h1;
                next_ghash_state = MODE_GHASH_IDLE;
                next_ghash_sub_state = AES_SUB_STATE_1;
            end
        endcase
    end

    /*
    Logic to control AES core input during different stages
    */
    always_comb begin : core_input_fsm_block

        a_valid_int = 1'h0;
        next_core_in_state = core_in_state;
        //invld_core_in_state = 1'h0;
        is_wait_input_drive = 1'h0;
        // is_wait_input_accept = 1'h0;
        
        case(core_in_state)
            WAIT_FOR_INPUT_DRIVE: begin
                is_wait_input_drive = 1'h1;

                if(is_mode_data) begin
                    if (din_hndshk) begin    // Wait until din handshake to drive the input data to core
                        a_valid_int = 1'h1;
                        next_core_in_state = WAIT_FOR_INPUT_ACCEPT;
                    end
                end
                else if (is_mode_tag) begin
                    if (ghash_out_vld & ghash_out_rdy) begin    // Wait until ghash out handshake to drive the ghash output as input to core
                        a_valid_int = 1'h1;
                        next_core_in_state = WAIT_FOR_INPUT_ACCEPT;
                    end
                end
                else if (precomp_h_start) begin
                    a_valid_int = 1'h1;
                    next_core_in_state = WAIT_FOR_INPUT_ACCEPT;
                end
            end
            WAIT_FOR_INPUT_ACCEPT: begin
                // is_wait_input_accept = 1'h1;
                a_valid_int = 1'h1;
                if(a_req_i) begin
                    next_core_in_state = WAIT_FOR_INPUT_DRIVE;
                end
            end
            default: begin
                //invld_core_in_state = 1'h1;
                next_core_in_state = WAIT_FOR_INPUT_DRIVE;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin: capture_input_block
        if(~rstn_i) begin
            mode_q          <= AES_RSVD0;
            dir_q           <= 1'h0;
            din_q           <= 128'h0;
            key_q           <= 256'h0;
            key_size_q      <= KEY_SIZE_128;
            skip_key_q      <= 1'h0;
            h               <= 128'h0;
            h_vld           <= 1'h0;
            din_last_q      <= 2'h0;
            din_bytecnt_q[1:0] <= 10'h0;
            din_ptr         <= 2'h0;                // Bit 1 = empty/full flag, Bit 0 = pointer position
            dout_ptr        <= 2'h0;                // Bit 1 = empty/full flag, Bit 0 = pointer position
        end
        else if(clear_i) begin
            mode_q          <= AES_RSVD0;
            dir_q           <= 1'h0;
            din_q           <= 128'h0;
            key_q           <= 256'h0;
            key_size_q      <= KEY_SIZE_128;
            h               <= 128'h0;
            h_vld           <= 1'h0;
            din_last_q      <= 2'h0;
            din_bytecnt_q[1:0] <= 10'h0;
            din_ptr         <= 2'h0;
            dout_ptr        <= 2'h0;
        end
        else begin
            if(cfg_vld_i & cfg_rdy_o) begin
                mode_q <= aes_modes_t'(mode_i);
                dir_q <= dir_i;
            end

        if(din_hndshk) begin
            din_q <= din_i_padded;
            end

            if(new_key_hndshk) begin
                key_q <= key_i_f;
                key_size_q <= key_sizes_t'(key_size_i_f);
                skip_key_q <= 1'h0;                 // new key loaded 
            end
            else if(key_rdy_o & skip_key_i_f) begin
                skip_key_q <= 1'h1;                 // the key loading was skipped, so HASH_SUBKEY state can be skipped
            end

            if(precomp_h_done) begin                // Capture hash subkey on precomp_h_done and hold it until reset
                h <= b_bit_swap;
            end

            if (precomp_h_start | new_key_hndshk) begin
               h_vld <= 1'h0; 
            end
            else if(precomp_h_done) begin
                h_vld <= 1'h1;
            end

            if(din_hndshk) begin
                din_ptr <= din_ptr + 1'h1;
                din_last_q[din_ptr_pos] <= din_last_i;

                if(din_last_i) begin
                    din_bytecnt_q[din_ptr_pos] <= din_bytecnt_i;
                end
                else begin
                    din_bytecnt_q[din_ptr_pos] <= 5'h10;
                end
            end
            
            if(dout_hndshk) begin
                dout_ptr <= dout_ptr + 1'h1;
            end
        end
    end

    assign din_mux              = (din_hndshk) ? din_i_padded : din_q;
    assign key_mux              = (new_key_hndshk) ? key_i_f : key_q;
    assign eom                  = (din_last_q[dout_ptr_pos]) & (~din_dout_ptr_match);
    assign bytecnt              = din_bytecnt_q[dout_ptr_pos];
    assign din_ov_flag          = din_ptr[1];
    assign dout_ov_flag         = dout_ptr[1];
    assign din_ptr_pos          = din_ptr[0];
    assign dout_ptr_pos         = dout_ptr[0];
    assign din_dout_ptr_match   = (din_ptr[0] == dout_ptr[0]);
    assign din_dout_fifo_empty  = din_dout_ptr_match & (din_ov_flag == dout_ov_flag);

    /* Logic to capture command error */
    always_comb begin : cfg_chk_block

        key_size_err = 1'h0;
        din_err = 1'h0;
        ctx_err = 1'h0;
        cfg_err = 1'h0;

        if (cfg_vld_i & cfg_rdy_o) begin
            if((mode_i == AES_XTS) || (mode_i == 0) || (mode_i > 4'h7)) begin
                cfg_err = 1'h1;
            end
        end

        // Supported key_size is 256, 192 or 128
        if(new_key_hndshk) begin
            if ((key_size_i_f == KEY_SIZE_256) || 
                (key_size_i_f == KEY_SIZE_192) ||
                (key_size_i_f == KEY_SIZE_128)) begin
                key_size_err = 1'h0;
            end
        else begin
                key_size_err = 1'h1;
            end
        end

        //if(din_hndshk && din_last_i) begin
        if(din_hndshk) begin
           if ( (din_aad_sel_i & (mode_q != AES_GCM)) || (din_aad_sel_i & ((din_bytecnt_i == 5'h00) || (din_bytecnt_i > 5'h10) )) ||
               (din_last_i && ((((mode_q == AES_ECB) || (mode_q == AES_CBC)) && (din_bytecnt_i != 5'h10)) ||
            (((mode_q == AES_GCM) || (mode_q == AES_OFB) || (mode_q == AES_CTR) || (mode_q == AES_CFB)) && 
          (((din_bytecnt_i == 5'h00) || (din_bytecnt_i > 5'h10) ))) ))) begin
              din_err = 1'h1;
       end
           else begin
              din_err = 1'h0;
       end
        end


        if(iv_hndshk & (~iv_ctx_sel_i)) begin
            ctx_err = 1'h1;
        end
    end

    //
    // state machine for different modes
    // MODE_SEC_IDLE  : idle state
    // MODE_SEC_KEY0  : program XTS tweaked key to aes core
    // MODE_SEC_DATA0 : send data to aes core
    // MODE_SEC_KEY1  : program XTS original key to aes core
    // MODE_SEC_DATA1 : send data to aes core
    //
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            cur_state <= MODE_SEC_IDLE;
        end
        else if(clear_i) begin
            cur_state <= MODE_SEC_IDLE;
        end
        else begin
            cur_state <= next_state;
        end
    end

    always_comb begin
        next_state = cur_state;
        s_idle = 1'b0;
        s_key0 = 1'b0;
        s_data0 = 1'b0;
        s_key1 = 1'b0;
        s_data1 = 1'b0;
        //invld_cur_state = 1'h0;

        case(cur_state)
            MODE_SEC_IDLE : begin
                s_idle = 1'b1;
                if (key_vld_i_f | skip_key_i_f) begin 
                    if (key_rdy_o)
                        next_state = MODE_SEC_DATA0;
                    // when AES core is not ready, e.g. DRBG is not ready
                    else
                        next_state = MODE_SEC_KEY0;
                end
                else
                    next_state = MODE_SEC_IDLE;
            end
            MODE_SEC_KEY0 : begin
                s_key0 = 1'b1;
                if (key_rdy_o)
                    next_state = MODE_SEC_DATA0;
                else
                    next_state = MODE_SEC_KEY0;
            end
            MODE_SEC_DATA0 : begin
                s_data0 = 1'b1;
                if (mode_q == `XTS) begin
                    if (b_valid_i)
                        next_state = MODE_SEC_KEY1;
                    else
                        next_state = MODE_SEC_DATA0;
                end
                else if (eom && b_valid_i && ctx_dout_rdy_i)
                    next_state = MODE_SEC_IDLE;
                else
                    next_state = MODE_SEC_DATA0;
            end
            MODE_SEC_KEY1 : begin
                s_key1 = 1'b1;
                if (new_key_hndshk)
                    next_state = MODE_SEC_DATA1;
                else
                    next_state = MODE_SEC_KEY1;
            end
            MODE_SEC_DATA1 : begin
                s_data1 = 1'b1;
                if (b_valid_i && ctx_dout_rdy_i) begin
                    if (eom)
                        next_state = MODE_SEC_IDLE;
                    else if (eou)
                        next_state = MODE_SEC_KEY0;
                    else
                        next_state = MODE_SEC_DATA1;
                end
                else begin
                    next_state = MODE_SEC_DATA1;
                end
            end
            default : begin
                //invld_cur_state = 1'h1;
                next_state = MODE_SEC_IDLE;
            end
        endcase
    end

    /*
        iv_r is used to store iv for the next block of next unit (XTS)
        for the first message block, it's always used as an input
        for other blocks, it's also used as an input in 
        CFB-Decrypt, CTR, and XTS modes. So in these modes, iv_r should be updated 
        right after a_req_i is received (a_req_i && s_data0 for XTS).
        In other cases, iv_r is simply used as a storage for possible write out of
        iv when there is a request.
    */
    
    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            iv_r <= 128'b0;
            iv_tag <= 128'b0;
        end
        else if (clear_i | rst_ctrl_signals) begin
            iv_r <= 128'b0;
            iv_tag <= 128'b0;
        end
        else if (iv_ctx_vld_i & iv_ctx_sel_i & iv_ctx_rdy_o) begin      // Store input IV
            if (mode_q != AES_GCM) begin        // Store input IV as is for non-GCM mode
                iv_r <= iv_i;
            end
            else begin                          // GCM mode
                iv_r <= inc32_out_unswap;       // Increment input IV for first input block
                iv_tag <= iv_i;                 // store the original IV for auth tag calculation
            end
        end
        else if (((mode_q == AES_CFB) && !dir_q) | (mode_q == AES_CTR)) begin    // CFB-Decrypt or CTR
            if (a_valid_int && a_req_i) begin                       // increment 
                iv_r <= iv_nxt;
            end
        end
        else if (mode_q == AES_GCM) begin                           // GCM
            if (a_valid_int & a_req_i & (~precomp_h_en)) begin      // increment 
                iv_r <= iv_nxt;
            end
        end
        else if (s_data0 && b_valid_i && (ctx_dout_rdy_i || (mode_q == AES_XTS))) begin // used as storage of output
            iv_r <= iv_nxt;
        end
    end

    /* byte reversing IV for incrementing as per NIST algorithm */
    always_comb begin
        for (ii=0; ii<16; ii=ii+1) begin
            for (jj=0; jj<8; jj=jj+1) begin
                iv_swap[(ii*8) + jj] = iv_r[((15-ii)*8) + jj];
                inc32_in_swap[(ii*8) + jj] = inc32_in_unswap[((15-ii)*8) + jj];
                b_byte_swap[(ii*8) + jj] = b[((15-ii)*8) + jj];
                din_mux_byte_swap[(ii*8) + jj] = din_mux[((15-ii)*8) + jj];
                ghash_out_byte_swap[(ii*8) + jj] = ghash_out_bit_swap[((15-ii)*8) + jj];
            end
        end
        for (ii=0; ii<16; ii=ii+1) begin
            for (jj=0; jj<8; jj=jj+1) begin
                iv_unswap[(ii*8) + jj] = iv_plus_1[((15-ii)*8) + jj];
                inc32_out_unswap[(ii*8) + jj] = inc32_out_swap[((15-ii)*8) + jj];
            end
        end
    end

    // in counter mode, increase by one starts from the most significant bit
    assign iv_plus_1 = ((mode_q == AES_CTR) ? iv_swap : iv_r) + 1;

    /*
        GCM mode needs a specific inc32 function which is an increment function
        applied to only upper 32b of the counter.
        Also the first counter used in enc/dec is IV + 1, unlike CTR mode which uses IV.
        The original IV is used during authentication tag calculation so it is stored separately
    */

    gp_aes_inc32 u_gp_aes_inc32 (
        // output
        .inc32_out          (inc32_out_swap),
        // input
        .inc32_in           (inc32_in_swap)
    );

    always_comb begin
        inc32_in_unswap = 128'h0;
        
        if(mode_q == AES_GCM) begin
            if(iv_ctx_vld_i & iv_ctx_sel_i & iv_ctx_rdy_o) begin
                inc32_in_unswap = iv_i;
            end
            else begin
                inc32_in_unswap = iv_r;
            end
        end
    end

    /* 
        Bit reversing inputs to GHASH and outputs from GHASH.
        This is required as GHASH mul in NIST is right-shift mul whereas
        RTL is designed as left-shift mul 
    */
    always_comb begin
        for (int ac = 0; ac < 128; ac = ac + 1) begin
            din_mux_bit_swap[ac] = din_mux_byte_swap[127-ac];
            b_bit_swap[ac] = b_byte_swap[127-ac];
            ghash_len_bit_swap[ac] = ghash_len[127-ac];
            ghash_out_bit_swap[ac] = ghash_out[127-ac];
        end
    end

    //
    // In XTS mode, temp is used to store the tweak value, and temp_1d for the
    // previous tweak value.
    //
    // In other modes, temp is used to store the input since sometimes temp is 
    // used directly to generate the output
    //
    assign temp_alpha = {temp[126:0], 1'b0} ^ (temp[127] ? 128'h87 : 128'h00);

    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            temp <= 128'b0;
            temp_1d <= 128'b0;
        end
        else if (clear_i | rst_ctrl_signals) begin
            temp <= 128'b0;
            temp_1d <= 128'b0;
        end
        else if (mode_q == AES_XTS) begin // in XTS mode
            if(s_data0 & b_valid_i) begin
                temp <= b_vec;
            end
            else if (s_data1 & a_valid_int & a_req_i) begin
                temp <= temp_alpha;
                temp_1d <= temp;
            end
        end
        else if (mode_q == AES_GCM) begin   // GCM mode
            if(is_mode_data & a_valid_int & a_req_i) begin
                temp <= din_mux;                // capture input PT/CT for XORing later
            end
            else if(is_mode_tag & ghash_out_vld & ghash_out_rdy) begin
                temp <= ghash_out_byte_swap;     // capture ghash output for XORing later
            end
        end
        else if (a_valid_int & a_req_i) // in other modes
            temp <= din_mux;
    end

    //
    // register and counter of message blocks in BYTES
    //

    assign bytes_in_din = din_hndshk? 
                    ((din_aad_sel_i | din_last_i) ?
                     din_bytecnt_i :
                     5'h10) :
                            bytes_in_din_q;

   assign din_i_padded = din_i & (128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> ((16 - bytes_in_din) * 8));

    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            bytes_in_din_q <= 5'h10;
        else
            bytes_in_din_q <= bytes_in_din;
    end

   //
    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            msg_cnt <= 32'h0;
        else if (clear_i | (s_idle & (mode_q == AES_XTS)) | ghash_out_vld | rst_ctrl_signals)
            msg_cnt <= 32'h0;
        else if (a_valid_o & a_req_i & is_mode_data)
            //msg_cnt <= msg_cnt + 5'h10;
            msg_cnt <= msg_cnt + bytes_in_din_q;
    end

    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            aad_cnt <= 32'h0;
        else if (clear_i | ghash_out_vld | rst_ctrl_signals)
            aad_cnt <= 32'h0;
        else if (ghash_in_vld & ghash_in_rdy & is_mode_aad)
            aad_cnt <= aad_cnt + bytes_in_din;
    end

    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            unit_cnt <= 9'b0;
        else if (clear_i | s_idle | (eou & b_valid_i & ctx_dout_rdy_i) | rst_ctrl_signals)
            unit_cnt <= 9'b0;
        else if (s_data1 & a_valid_o & a_req_i & is_mode_data)
            unit_cnt <= unit_cnt + 1;
    end
    
    assign eou = (unit_cnt == unit_size_i);

    always_ff @ (posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            i_valid_r <= 1'b0;
        else if (clear_i | s_idle | rst_ctrl_signals)
            i_valid_r <= 1'b0;
        else if (s_key0)
            i_valid_r <= 1'b1;
        else if (a_req_i)
            i_valid_r <= 1'b0;
    end

    //
    // convertion between vector and state
    // state[0][0] = vec_byte[0]
    // state[1][0] = vec_byte[1]
    // state[i][j] = vec_byte[j*4 + i]
    //
    genvar i, j;
    generate
        // convert state format to vector format
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<4; j=j+1) begin
                assign a_state[i][j] = a[(i*4*8) + (j*8) + 7 : (i*4*8) + (j*8) + 0];
                assign b_vec[(i*4*8) + (j*8) + 7 : (i*4*8) + (j*8) + 0] = b_i[i][j];
            end
        end
        for (i=0; i<8; i=i+1) begin
            for (j=0; j<4; j=j+1) begin
                assign key_state[i][j] = key[(i*4*8) + (j*8) + 7 : (i*4*8) + (j*8) + 0];
            end
        end
    endgenerate


    //
    // outputs generation
    //


    assign first_msg = (msg_cnt == 32'b0);

    always_comb begin
        
        // default values
        a = 128'h0;
        a_valid = 1'h0;
        a_req_unused = a_req_i;
        b = 128'h0;
        b_valid = 1'h0;
        key = 256'h0;
        key_valid = 1'h0;
        iv_nxt = 128'h0;
        
        case (mode_q)
            AES_ECB: begin
                a = din_mux;
                a_valid = a_valid_int;
                a_req_unused = a_req_i;
                b = b_vec;
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;
                iv_nxt = iv_r;
            end
            AES_CBC : begin
                a = dir_q ? (din_mux ^ (first_msg ? iv_r : b_vec)) : din_mux;
                a_valid = a_valid_int;
                b = dir_q ? b_vec : (b_vec ^ iv_r);
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;
                iv_nxt = dir_q ? b_vec : temp;
            end
            AES_CTR : begin
                a = iv_r;
                a_valid = a_valid_int;
                b = temp ^ b_vec;
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;
                iv_nxt = iv_unswap;
            end
            AES_CFB : begin
                a = first_msg ? iv_r : (dir_q ? (temp ^ b_vec) : temp);
                a_valid = a_valid_int;
                b = temp ^ b_vec;
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;
                iv_nxt = dir_q ? (b_vec ^ temp) : din_mux;
            end
            AES_OFB : begin
                a = first_msg ? iv_r : b_vec;
                a_valid = a_valid_int;
                b = temp ^ b_vec;
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;
                iv_nxt = b_vec;
            end
            AES_XTS : begin
                a = s_data0 ? iv_r : temp ^ din_mux;
                // a_valid = s_data0 ? i_valid_r : (s_data1 ? a_valid_i : 0);
                a_valid = s_data0 ? i_valid_r : (s_data1 ? a_valid_int : 0);
                a_req_unused = s_data1 & a_req_i;
                b = temp_1d ^ b_vec;
                b_valid = s_data1 & b_valid_i;
                key[127:0] = (s_key0 || s_data0) ? key_mux[255:128] : key_mux[127:0];
                key[255:128] = key_mux[255:128];
                key_valid = s_key0 | s_key1;
                iv_nxt = iv_plus_1;
            end
            AES_GCM: begin
                a_valid = a_valid_int;
                b_valid = b_valid_i;
                key = key_mux;
                key_valid = any_key_hndshk;

                if (is_mode_data) begin
                    a = iv_r;
                    b = temp ^ b_vec;
                    iv_nxt = inc32_out_unswap;
                end
                else if(is_mode_tag) begin
                    a = iv_tag;
                    b = temp ^ b_vec;
                end
                else if(precomp_h_en) begin
                    a = 128'h0;
                    b = b_vec;
                end
            end
            default : begin
                a = 128'h0;
                a_valid = 1'h0;
                a_req_unused = 1'h0;
                b = 128'h0;
                b_valid = 1'h0;
                key = 256'h0;
                key_valid = 1'h0;
                iv_nxt = 128'h0;
            end
        endcase
    end


    assign a_o              = a_state;
    assign a_valid_o        = a_valid;

    assign dout_o           = is_mode_data ? b : 128'h0;
    assign dout_bytecnt_o   = bytecnt;
    assign dout_last_o      = ctx_dout_vld_o & din_last_q[dout_ptr_pos];
    assign key_o            = key_state;
    assign key_valid_o      = key_valid;
    assign dir_o            = (
                                    ((mode_q == AES_XTS) & (s_idle | s_key0 | s_data0)) |
                                    (mode_q == AES_CFB) | 
                                    (mode_q == AES_OFB) |
                                    (mode_q == AES_CTR) |
                                    (mode_q == AES_GCM)
                                ) ? 1 : dir_q;
    assign aad_cnt_bits     = aad_cnt << 3;
    assign msg_cnt_bits     = msg_cnt << 3;
    assign ghash_len = {{29'h0}, aad_cnt_bits, {29'h0}, msg_cnt_bits};

    assign ghash_in         = is_ghash_aad ? din_mux_bit_swap : 
   //                             (is_ghash_enc ? b_bit_swap & (128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << ((16 - bytecnt) * 8)): 
                                (is_ghash_enc ? b_bit_swap & (128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> ((16 - bytecnt) * 8)): 
                                    (is_ghash_dec ? din_mux_bit_swap : 
                                        (is_ghash_last ? ghash_len_bit_swap : 128'h0)
                                    )
                                );
    assign tag_o            = is_mode_tag ? b : 128'h0;

    assign key_size         = (new_key_hndshk) ? key_sizes_t'(key_size_i_f) : key_size_q;

    assign nr_o             = (key_size == KEY_SIZE_128) ? 4'hA : 
                                (
                                    (key_size == KEY_SIZE_192) ? 4'hC : 
                                    (
                                        (key_size == KEY_SIZE_256) ? 4'hE : 4'hA
                                    )
                                );
    assign nk_o             = (key_size == KEY_SIZE_128) ? 4'h4 : 
                                (
                                    (key_size == KEY_SIZE_192) ? 4'h6 : 
                                    (
                                        (key_size == KEY_SIZE_256) ? 4'h8 : 4'h4
                                    )
                                );
    assign din_hndshk       = din_vld_i & din_rdy_o;
    assign iv_hndshk        = iv_ctx_vld_i & iv_ctx_rdy_o; //Commented to fix LINT warnings as this signal is not used
    assign new_key_hndshk   = key_vld_i_f & (~skip_key_i_f) & key_rdy_o;
    assign any_key_hndshk   = (key_vld_i_f | skip_key_i_f) & key_rdy_o;
    assign dout_hndshk      = (ctx_dout_vld_o & ctx_dout_rdy_i) | (is_mode_aad & ghash_in_rdy & ghash_in_vld);
    assign ghash_en_o       = ghash_in_vld;

    assign ctx_out_o = 384'h0;

    logic invld_mode_sub_state_f;
    logic invld_ghash_state_f; 
    logic invld_cur_state_f; 
    logic invld_core_in_state_f; 
    logic invld_ghash_sub_state_f; 
    logic invld_mode_state_f;

    /* cmd err is incorrect settings 
        fault_err[0] is invalid FSM state
        fault_err[1] is fault error from core */
    assign fault_err_o[0] = invld_mode_state_f | invld_mode_sub_state_f | invld_ghash_state_f | invld_ghash_sub_state_f | invld_core_in_state_f | invld_cur_state_f | ghash_fault;
    assign cmd_err        = cfg_err | key_size_err | din_err | ctx_err;
    assign fault_err_o[1] = core_fault_i;

    assign busy_o         = (mode_active | mode_active_f);

    assign unused_ctx_in_i = ctx_in_i;


    always_comb begin
        invld_mode_state  = 1'b0;          
    case(mode_state)
           MODE_IDLE : 
              invld_mode_state  = 1'b0;            
           MODE_CFG  : 
              invld_mode_state  = 1'b0;            
           MODE_IV   :
              invld_mode_state  = 1'b0;            
           MODE_KEY  :
              invld_mode_state  = 1'b0;            
           MODE_WAIT_DRBG :
              invld_mode_state  = 1'b0;            
           MODE_HASH_SUBKEY :
              invld_mode_state  = 1'b0;            
           MODE_AAD :
              invld_mode_state  = 1'b0;            
           MODE_DATA :
              invld_mode_state  = 1'b0;            
           MODE_TAG  :
              invld_mode_state  = 1'b0;            
           MODE_ERR  :
              invld_mode_state  = 1'b0;            
           default :      
              invld_mode_state  = 1'b1;            
        endcase     
    end


    always_ff @(posedge clk_i or negedge rstn_i) begin
       if(!rstn_i) begin        
          invld_mode_sub_state_f  <= 1'h0;
          invld_ghash_state_f     <= 1'b0;    
          invld_cur_state_f       <= 1'b0;    
          invld_core_in_state_f   <= 1'b0;    
          invld_ghash_sub_state_f <= 1'b0;    
      invld_mode_state_f      <= 1'b0;    
       end else 
       begin           
          if(clear_i) begin
             invld_mode_sub_state_f  <= 1'h0;
             invld_ghash_state_f     <= 1'b0;     
             invld_cur_state_f       <= 1'b0;     
             invld_core_in_state_f   <= 1'b0;     
             invld_ghash_sub_state_f <= 1'b0;     
         invld_mode_state_f      <= 1'b0;    
          end
      else begin      
               if (invld_mode_sub_state)  invld_mode_sub_state_f  <= 1'b1;
               if (invld_ghash_state)     invld_ghash_state_f     <= 1'b1;    
               if (invld_cur_state)       invld_cur_state_f       <= 1'b1;    
               if (invld_core_in_state)   invld_core_in_state_f   <= 1'b1;    
               if (invld_ghash_sub_state) invld_ghash_sub_state_f <= 1'b1;    
           if (invld_mode_state)      invld_mode_state_f      <= 1'b1;    
          end  
       end    
    end     

    always_comb begin
        invld_mode_sub_state = 1'h0;
        //case(mode_sub_state)
        unique case(mode_sub_state)
            AES_SUB_STATE_1  :
               invld_mode_sub_state = 1'h0;
            AES_SUB_STATE_2  :
               invld_mode_sub_state = 1'h0;
            AES_SUB_STATE_3  :
               invld_mode_sub_state = 1'h0;
            AES_SUB_STATE_4  :
               invld_mode_sub_state = 1'h0;
            default          :
               invld_mode_sub_state = 1'h1;
        endcase     
    end

    always_comb begin
        invld_ghash_sub_state = 1'h0;
        case(ghash_sub_state)
            AES_SUB_STATE_1  :
               invld_ghash_sub_state = 1'h0;
            AES_SUB_STATE_2  :
               invld_ghash_sub_state = 1'h0;
            AES_SUB_STATE_3  :
               invld_ghash_sub_state = 1'h0;
            AES_SUB_STATE_4  :
               invld_ghash_sub_state = 1'h0;
            default          :
               invld_ghash_sub_state = 1'h1;
        endcase     
    end 

    always_comb begin
        invld_core_in_state = 1'h0;
        case(core_in_state)
           WAIT_FOR_INPUT_DRIVE  :
              invld_core_in_state = 1'h0;
           WAIT_FOR_INPUT_ACCEPT :
              invld_core_in_state = 1'h0;
           default :       
              invld_core_in_state = 1'h1;
         endcase
    end  

    always_comb begin
        invld_cur_state =  1'b0;           
        case(cur_state)
           MODE_SEC_IDLE   :
              invld_cur_state =  1'b0;         
           MODE_SEC_KEY0   :
              invld_cur_state =  1'b0;         
           MODE_SEC_DATA0  :
              invld_cur_state =  1'b0;         
           MODE_SEC_KEY1   :
              invld_cur_state =  1'b0;         
           MODE_SEC_DATA1  :
              invld_cur_state =  1'b0;         
       default         :
              invld_cur_state =  1'b1;         
        endcase
    end    

    always_comb begin
        invld_ghash_state = 1'b0;          
        case(ghash_state)
           MODE_GHASH_IDLE :
              invld_ghash_state = 1'b0;        
           MODE_GHASH_AAD  :
              invld_ghash_state = 1'b0;        
           MODE_GHASH_ENC  :
              invld_ghash_state = 1'b0;        
           MODE_GHASH_DEC  :
              invld_ghash_state = 1'b0;        
           MODE_GHASH_LAST :
              invld_ghash_state = 1'b0;        
       default         :
              invld_ghash_state = 1'b1;        
        endcase     
    end     
endmodule
