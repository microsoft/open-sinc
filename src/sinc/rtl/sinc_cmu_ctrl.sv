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
// File        : sinc_cmu_ctrl.sv
// Description : CMU control FSM. Manages SInC state transitions, dispatches
//               FW commands, and coordinates block fetch with crypto wrapper.


module sinc_cmu_ctrl 
import sinc_pkg::*;
#(
    parameter BLOCK_SIZE        = 512,                      // Block size in B
    parameter ADDR_WIDTH        = 24

)
(
    /* clock, reset, misc */
    input logic                     clk_i,
    input logic                     rstn_i,
    input logic                     lp_rstn_i,
    input logic                     ciu_fault_err,
    input logic                     axi_sub_clock_gate_en_o,
    output logic                    aes_test_busy,
    output logic                    cmu_ctrl_active_cmd,            // used to block writes to all sinc regs and tells reg ctrl to generate inv cmd err
    output logic                    cmu_active,
    output logic                    sinc_done_o,
    output logic                    sinc_err_o,
    output logic                    sinc_fault_err_pulse,
    output logic                    severe_err,
    output logic                    sinc_cpu_non_active_state,

    /* reg control interface */
    input logic                     reg_ctrl_cmd_vld,
    input sinc_cmu_cmd_t            reg_ctrl_cmd,
    input logic                     sinc_reset_dis,
    input logic                     sinc_reinit_dis,
    input logic                     reg_ctrl_invld_cmd_err,
    input logic                     reg_ctrl_active,

    output logic                    cmu_ctrl_sts_upd,
    output sts_update_t             cmu_ctrl_sts,
    output logic                    set_sinc_reset_dis,
    output logic                    set_sinc_reinit_dis,
    output logic                    cmu_ctrl_fw_cmd_done,           // fw cmd done - used to clear cmd register

    /* CIU Interface */
    input logic                     ciu_block_fetch_req,
    input logic [ADDR_WIDTH-1:0]    ciu_addr,
    input logic                     ciu_reset_reinit_completed,
    output logic                    cmu_block_fetch_comp,
    output logic                    cmu_block_fetch_err,
    output logic                    cmu_sinc_reset,
    output logic                    cmu_sinc_reinit,
    output logic                    cmu_busy,
    output sinc_state_t             cmu_sinc_state,

    /* Crypto Wrap Interface */
    output sinc_cmu_cmd_t           cmu_ctrl_cmd,
    output logic                    cmu_ctrl_cmd_vld,
    output logic [23:0]             cmu_ctrl_fetch_block_num,

    input logic                     aes_seeded,
    input logic                     c_wrap_sts_upd,
    input sts_update_t              c_wrap_sts,
    input logic                     c_wrap_cmd_comp,
    input logic                     c_wrap_cmd_err,
    input logic                     c_wrap_fault_err,

    /* DMA interface */
    input logic                     dma_fault_err,

    /* Memory Erase Interface */
    input logic                     sinc_erase_done_o
);

    localparam BLOCK_SIZE_WORDW         = $clog2(BLOCK_SIZE/4);                     // signal width required to store block size in words
    localparam BLOCK_NUM_PAD_LEN        = 24 - (ADDR_WIDTH - BLOCK_SIZE_WORDW);     // pad 0s to make block num output width to 24b

    sinc_cmu_ctrl_fsm_t             state;
    sinc_cmu_ctrl_fsm_t             next_state;
    sinc_state_t                    next_cmu_sinc_state;
    sts_update_t                    sts, fetch_block_sts;
    sinc_cmu_cmd_t                  pend_cmd_req;


    logic [(ADDR_WIDTH-BLOCK_SIZE_WORDW)-1:0] ciu_addr_q;
    logic                           set_cmd_complete, set_pend_cmd_req, clr_pend_cmd_req;
    logic [BLOCK_SIZE_WORDW-1:0]    unused_ciu_addr;

    logic                           set_state_to_init;
    logic                           set_state_to_disabled;
    logic                           set_state_to_cache_active;
    logic                           sts_upd, fetch_block_sts_upd;
    logic                           set_c_wrap_cmd_comp;
    logic                           clr_c_wrap_cmd_comp;
    logic                           set_ciu_reset_reinit_comp;
    logic                           clr_ciu_reset_reinit_comp;
    logic                           c_wrap_cmd_comp_q;
    logic                           ciu_reset_reinit_comp_q;
    logic                           rst_ctrl_signals;
    logic                           fw_cmd_suc, stall_cpu_req;         // fw cmd success
    logic                           invld_state;
    logic                           invld_cmu_sinc_state;
    logic                           severe_err_din;
    logic                           assert_soft_reset;
    logic                           non_severe_err, c_wrap_block_fetch_comp;
    logic                           hw_fault, hw_fault_q, hw_fault_pulse_d, clr_hw_fault;
    logic                           next_fetch_block_state;
    logic                           fetch_block_state;

    sinc_cmu_ctrl_ret u_sinc_cmu_ctrl_ret (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .next_cmu_sinc_state(next_cmu_sinc_state),
        .severe_err(severe_err),
        .cmu_sinc_state(cmu_sinc_state)
    );

    /* FSM to control SInC state */
    always_comb begin : sinc_state_block
        next_cmu_sinc_state = cmu_sinc_state;
        invld_cmu_sinc_state = 1'h0;
        
        case(cmu_sinc_state)
            DISABLED: begin
                if(set_state_to_init) begin
                    next_cmu_sinc_state = INITIALIZATION;
                end
            end
            INITIALIZATION: begin
                if(set_state_to_cache_active) begin
                    next_cmu_sinc_state = CACHE_ACTIVE;
                end
                else if(set_state_to_disabled) begin
                    next_cmu_sinc_state = DISABLED;
                end
            end
            CACHE_ACTIVE: begin
                if(set_state_to_disabled) begin
                    next_cmu_sinc_state = DISABLED;
                end
                else if(set_state_to_init) begin
                    next_cmu_sinc_state = INITIALIZATION;
                end
            end
            CACHE_FAILED: begin
                if(set_state_to_disabled) begin
                    next_cmu_sinc_state = DISABLED;
                end
            end
            default: begin
                invld_cmu_sinc_state = 1'h1;
                next_cmu_sinc_state = CACHE_FAILED;
            end
        endcase
    end

    /* CMU control FSM to manage different commands */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            state <= SINC_IDLE;
        end
        else begin
            if(hw_fault) begin
                state <= SINC_IDLE;
            end
            else begin
                state <= next_state;
            end
        end
    end

    always_comb begin
        
        next_state                  = state;
        cmu_ctrl_cmd                = CMD_NONE;
        cmu_ctrl_cmd_vld            = 1'h0;
        stall_cpu_req               = 1'h0;
        aes_test_busy               = 1'h0;
        cmu_ctrl_active_cmd         = 1'h1;
        set_state_to_init           = 1'h0;
        set_state_to_cache_active   = 1'h0;
        set_state_to_disabled       = 1'h0;
        sts                         = STS_NONE;
        sts_upd                     = 1'h0;
        assert_soft_reset           = 1'h0;
        cmu_sinc_reinit             = 1'h0;
        cmu_ctrl_fetch_block_num    = 24'h0;
        rst_ctrl_signals            = 1'h0;
        cmu_ctrl_fw_cmd_done        = 1'h0;
        fw_cmd_suc                  = 1'h0;
        invld_state                 = 1'h0;
        set_sinc_reset_dis          = 1'h0;
        set_sinc_reinit_dis         = 1'h0;
        set_c_wrap_cmd_comp         = 1'h0;
        clr_c_wrap_cmd_comp         = 1'h0;
        set_ciu_reset_reinit_comp   = 1'h0;
        clr_ciu_reset_reinit_comp   = 1'h0;
        clr_hw_fault                = 1'h0;
        set_pend_cmd_req            = 1'h0;
        clr_pend_cmd_req            = 1'h0;
        c_wrap_block_fetch_comp            = 1'h0;
        case(state)
            SINC_IDLE: begin
                rst_ctrl_signals = 1'h1;
                cmu_ctrl_active_cmd = 1'h0;

                if(ciu_block_fetch_req | (pend_cmd_req == CMD_FETCH_BLOCK)) begin
                    cmu_ctrl_cmd_vld = 1'h1;            // send to crypto wrap
                    stall_cpu_req = 1'h1;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;

                    if (ciu_block_fetch_req) begin
                        if (aes_seeded) begin
                            cmu_ctrl_cmd = CMD_FETCH_BLOCK;
                            cmu_ctrl_fetch_block_num = {{BLOCK_NUM_PAD_LEN{1'h0}}, ciu_addr[ADDR_WIDTH-1:BLOCK_SIZE_WORDW]};
                            next_state = FETCH_BLOCK;
                        end
                        else begin
                            cmu_ctrl_cmd = CMD_AES_SEED;
                            set_pend_cmd_req = 1'h1;            // set pending cmd req to execute after AES seeding
                            next_state = AES_SEED;
                        end
                    end
                    else begin
                        cmu_ctrl_cmd = CMD_FETCH_BLOCK;
                        cmu_ctrl_fetch_block_num = {{BLOCK_NUM_PAD_LEN{1'h0}}, ciu_addr_q[(ADDR_WIDTH-BLOCK_SIZE_WORDW)-1:0]};
                        clr_pend_cmd_req = 1'h1;
                        next_state = FETCH_BLOCK;
                    end
                end
                else if(reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_SET_INIT)) begin
                    cmu_ctrl_cmd_vld = 1'h1;
                    cmu_ctrl_cmd = CMD_SET_INIT;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;
                    next_state = SET_INIT;
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_SET_CACHE_ACT))) begin
                    stall_cpu_req = 1'h1;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;
                    next_state = SET_CACHE_ACTIVE;
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_SINC_RESET))) begin
                    cmu_ctrl_active_cmd = 1'h1;
                    stall_cpu_req = 1'h1;
                    sts_upd = 1'h1;

                    if (sinc_reset_dis) begin
                        cmu_ctrl_fw_cmd_done = 1'h1;
                        sts = STS_INV_CMD;
                    end
                    else begin
                        cmu_ctrl_cmd_vld = 1'h1;
                        cmu_ctrl_cmd = CMD_SINC_RESET;
                        assert_soft_reset = 1'h1;
                        sts = STS_CMD_IN_PROG;
                        next_state = SINC_RESET;
                    end
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_SINC_REINIT))) begin
                    cmu_ctrl_active_cmd = 1'h1;
                    stall_cpu_req = 1'h1;
                    sts_upd = 1'h1;

                    if (sinc_reinit_dis) begin
                        cmu_ctrl_fw_cmd_done = 1'h1;
                        sts = STS_INV_CMD;
                    end
                    else begin
                        cmu_ctrl_cmd_vld = 1'h1;
                        cmu_ctrl_cmd = CMD_SINC_REINIT;
                        cmu_sinc_reinit = 1'h1;
                        sts = STS_CMD_IN_PROG;
                        next_state = SINC_REINIT;
                    end
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_ENCR_BLOCK)) | (pend_cmd_req == CMD_ENCR_BLOCK)) begin
                    cmu_ctrl_cmd_vld = 1'h1;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;

                    if (reg_ctrl_cmd_vld) begin
                        if (aes_seeded) begin
                            cmu_ctrl_cmd = CMD_ENCR_BLOCK;
                            next_state = ENCR_BLOCK;
                        end
                        else begin
                            cmu_ctrl_cmd = CMD_AES_SEED;
                            set_pend_cmd_req = 1'h1;            // set pending cmd req to execute after AES seeding
                            next_state = AES_SEED;
                        end
                    end
                    else begin
                        cmu_ctrl_cmd = CMD_ENCR_BLOCK;
                        clr_pend_cmd_req = 1'h1;
                        next_state = ENCR_BLOCK;
                    end
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_DIS_RESET))) begin
                    stall_cpu_req = 1'h1;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;
                    next_state = DIS_RESET;
                end
                else if ((reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_DIS_REINIT))) begin
                    stall_cpu_req = 1'h1;
                    cmu_ctrl_active_cmd = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;
                    next_state = DIS_REINIT;
                end
                else if (reg_ctrl_cmd_vld & (reg_ctrl_cmd == CMD_AES_TEST)) begin
                    cmu_ctrl_cmd_vld = 1'h1;
                    cmu_ctrl_cmd = CMD_AES_TEST;
                    cmu_ctrl_active_cmd = 1'h1;
                    aes_test_busy = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_IN_PROG;
                    next_state = AES_TEST;
                end
            end
            FETCH_BLOCK: begin
                cmu_ctrl_fetch_block_num = {{BLOCK_NUM_PAD_LEN{1'h0}}, ciu_addr_q[(ADDR_WIDTH-BLOCK_SIZE_WORDW)-1:0]};
                stall_cpu_req = 1'h1;
                if(c_wrap_cmd_comp) begin
                    c_wrap_block_fetch_comp = 1'h1;
                    next_state = SINC_IDLE;
                end
            end
            SET_INIT: begin
                if(c_wrap_cmd_comp) begin
                    next_state = SINC_IDLE;
                    cmu_ctrl_fw_cmd_done = 1'h1;

                    if(~c_wrap_cmd_err) begin
                        fw_cmd_suc = 1'h1;
                        set_state_to_init = 1'h1;
                        sts_upd = 1'h1;
                        sts = STS_CMD_SUC;
                    end
                end
            end
            SET_CACHE_ACTIVE: begin
                stall_cpu_req = 1'h1;
                set_state_to_cache_active = 1'h1;
                cmu_ctrl_fw_cmd_done = 1'h1;
                fw_cmd_suc = 1'h1;
                sts_upd = 1'h1;
                sts = STS_CMD_SUC;
                next_state = SINC_IDLE;
            end
            SINC_RESET: begin
                stall_cpu_req = 1'h1;
                set_c_wrap_cmd_comp = c_wrap_cmd_comp;
                set_ciu_reset_reinit_comp = ciu_reset_reinit_completed;
                clr_hw_fault = 1'h1;

                if(c_wrap_cmd_comp_q & ciu_reset_reinit_comp_q) begin
                    clr_c_wrap_cmd_comp = 1'h1;
                    clr_ciu_reset_reinit_comp = 1'h1;
                    cmu_ctrl_fw_cmd_done = 1'h1;
                    fw_cmd_suc = 1'h1;
                    set_state_to_disabled = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_SUC;
                    next_state = SINC_IDLE;
                end
            end
            SINC_REINIT: begin
                stall_cpu_req = 1'h1;
                set_c_wrap_cmd_comp = c_wrap_cmd_comp;
                set_ciu_reset_reinit_comp = ciu_reset_reinit_completed;

                if(c_wrap_cmd_comp_q & ciu_reset_reinit_comp_q) begin
                    clr_c_wrap_cmd_comp = 1'h1;
                    clr_ciu_reset_reinit_comp = 1'h1;
                    cmu_ctrl_fw_cmd_done = 1'h1;
                    fw_cmd_suc = 1'h1;
                    set_state_to_init = 1'h1;
                    sts_upd = 1'h1;
                    sts = STS_CMD_SUC;
                    next_state = SINC_IDLE;
                end
            end
            ENCR_BLOCK: begin
                if(c_wrap_cmd_comp) begin
                    next_state = SINC_IDLE;
                    cmu_ctrl_fw_cmd_done = 1'h1;

                    if(~c_wrap_cmd_err) begin
                        fw_cmd_suc = 1'h1;
                        sts_upd = 1'h1;
                        sts = STS_CMD_SUC;
                    end
                end
            end
            DIS_RESET: begin
                stall_cpu_req = 1'h1;
                set_sinc_reset_dis = 1'h1;
                cmu_ctrl_fw_cmd_done = 1'h1;
                fw_cmd_suc = 1'h1;
                sts_upd = 1'h1;
                sts = STS_CMD_SUC;
                next_state = SINC_IDLE;
            end
            DIS_REINIT: begin
                stall_cpu_req = 1'h1;
                set_sinc_reinit_dis = 1'h1;
                cmu_ctrl_fw_cmd_done = 1'h1;
                fw_cmd_suc = 1'h1;
                sts_upd = 1'h1;
                sts = STS_CMD_SUC;
                next_state = SINC_IDLE;
            end
            AES_TEST: begin
                cmu_ctrl_cmd_vld = reg_ctrl_cmd_vld;    // forward FW cmd writes to c_wrap
                cmu_ctrl_cmd = reg_ctrl_cmd;
                aes_test_busy = 1'h1;

                if(c_wrap_cmd_comp) begin
                    next_state = SINC_IDLE;
                    cmu_ctrl_fw_cmd_done = 1'h1;

                    if(~c_wrap_cmd_err) begin
                        fw_cmd_suc = 1'h1;
                        sts_upd = 1'h1;
                        sts = STS_CMD_SUC;
                    end
                end
            end
            AES_SEED: begin
                stall_cpu_req = (pend_cmd_req == CMD_FETCH_BLOCK);

                if(c_wrap_cmd_comp) begin
                    next_state = SINC_IDLE;

                    if (c_wrap_cmd_err) begin
                        clr_pend_cmd_req = 1'h1;        // clear pend req if RNG read failed, otherwise design'll go into RNG read loop
                        cmu_ctrl_fw_cmd_done = 1'h1;
                    end
                end
            end
            default: begin
                invld_state = 1'h1;
                cmu_ctrl_fw_cmd_done = 1'h1;
                next_state = SINC_IDLE;
            end
        endcase
    end

    /* track fetch block request to completion */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            fetch_block_state <= 1'h0;
        end
        else begin
            fetch_block_state <= next_fetch_block_state;
        end
    end

    always_comb begin
        next_fetch_block_state = fetch_block_state;
        cmu_block_fetch_comp = 1'h0;
        cmu_block_fetch_err = 1'h0;
        fetch_block_sts_upd = 1'h0;
        fetch_block_sts = STS_NONE;

        case(fetch_block_state)
            1'h0: begin
                if(ciu_block_fetch_req) begin
                    next_fetch_block_state = 1'h1;
                end
            end
            1'h1: begin
                cmu_block_fetch_comp = c_wrap_block_fetch_comp | hw_fault | hw_fault_q;
                cmu_block_fetch_err = (c_wrap_block_fetch_comp & c_wrap_cmd_err) | hw_fault | hw_fault_q;
                
                if ((c_wrap_block_fetch_comp & (~c_wrap_cmd_err)) | hw_fault | hw_fault_q) begin        // fetch block completes without error or HW fault
                    fetch_block_sts_upd = 1'h1;
                    fetch_block_sts = STS_NONE;
                end

                if(cmu_block_fetch_comp) begin
                    next_fetch_block_state = 1'h0;
                end
            end
            default: begin
                next_fetch_block_state = 1'h0;
            end
        endcase
    end

    /* Drive soft reset through a flop to ensure no glitches. 
        Only assert this active high soft reset when FW initiates sinc reset command */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            cmu_sinc_reset <= 1'h0;
        end
        else begin
            cmu_sinc_reset <= assert_soft_reset;
        end
    end

    /* flops to store ciu addr and ciu block fetch req during a fetch block request */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            ciu_addr_q <= {(ADDR_WIDTH-BLOCK_SIZE_WORDW){1'h0}};
        end
        else begin
            if (cmu_block_fetch_comp) begin
                ciu_addr_q <= {(ADDR_WIDTH-BLOCK_SIZE_WORDW){1'h0}};
            end
            else if (ciu_block_fetch_req) begin
                ciu_addr_q <= ciu_addr[ADDR_WIDTH-1:BLOCK_SIZE_WORDW];
            end
        end
    end

    /* flops to capture completion from c_wrap and CIU for sinc_reset cmd */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            c_wrap_cmd_comp_q <= 1'h0;
            ciu_reset_reinit_comp_q <= 1'h0;
        end
        else begin
            if (set_c_wrap_cmd_comp) begin
                c_wrap_cmd_comp_q <= 1'h1;
            end
            else if(clr_c_wrap_cmd_comp | rst_ctrl_signals) begin
                c_wrap_cmd_comp_q <= 1'h0;
            end

            if (set_ciu_reset_reinit_comp) begin
                ciu_reset_reinit_comp_q <= 1'h1;
            end
            else if(clr_ciu_reset_reinit_comp | rst_ctrl_signals) begin
                ciu_reset_reinit_comp_q <= 1'h0;
            end
        end
    end

    /* flop severe error to avoid any combo loop 
        flop fault_err to generate a pulse */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            severe_err <= 1'h0;
            sinc_fault_err_pulse <= 1'h0;
            hw_fault_q <= 1'h0;
        end
        else begin
            severe_err <= severe_err_din;
            sinc_fault_err_pulse <= hw_fault_pulse_d;

            if(clr_hw_fault) begin
                hw_fault_q <= 1'h0;
            end
            else if(hw_fault) begin
                hw_fault_q <= 1'h1;
            end
        end
    end

    /* capture incoming cmd to execute after AES seeding */
    always_ff @( posedge clk_i or negedge lp_rstn_i ) begin
        if(~lp_rstn_i) begin
            pend_cmd_req <= CMD_NONE;
        end
        else if (clr_pend_cmd_req) begin
            pend_cmd_req <= CMD_NONE;
        end
        else if (set_pend_cmd_req) begin
            if(ciu_block_fetch_req) begin
                pend_cmd_req <= CMD_FETCH_BLOCK;
            end
            else begin
                pend_cmd_req <= CMD_ENCR_BLOCK;
            end
        end
    end

    assign unused_ciu_addr[BLOCK_SIZE_WORDW-1:0] = ciu_addr[BLOCK_SIZE_WORDW-1:0];
    assign hw_fault                 = ciu_fault_err | c_wrap_fault_err | dma_fault_err | invld_state | invld_cmu_sinc_state;
    assign hw_fault_pulse_d         = hw_fault & (~hw_fault_q);

    assign cmu_ctrl_sts_upd         = sts_upd | c_wrap_sts_upd | fetch_block_sts_upd;         // update sts reg on c_wrap or internal request
    assign cmu_ctrl_sts             = sts_update_t'(sts | c_wrap_sts | fetch_block_sts);

    /* capture severe or non severe error */
    assign severe_err_din           = hw_fault ? 1'h1 : 
                                                (cmu_ctrl_sts_upd ? 
                                                    (
                                                        (cmu_ctrl_sts == STS_KEY_FET_ERR) | (cmu_ctrl_sts == STS_CAC_BLK_R_ERR) | 
                                                        (cmu_ctrl_sts == STS_AUTH_TAG_CHK_ERR) | (cmu_ctrl_sts == STS_AUTH_TAG_R_ERR) | 
                                                        (cmu_ctrl_sts == STS_RNG_SEED_ERR) | (cmu_ctrl_sts == STS_CAC_BLK_W_FET_BLK_ERR) |
                                                        (cmu_ctrl_sts == STS_AES_ERR)
                                                    ) : 1'h0
                                                );

    assign non_severe_err           = reg_ctrl_invld_cmd_err ? 1'h1 : 
                                                (cmu_ctrl_sts_upd ? 
                                                    (
                                                        (cmu_ctrl_sts == STS_INV_CMD) |
                                                        (cmu_ctrl_sts == STS_CAC_BLK_W_ENC_BLK_ERR) | (cmu_ctrl_sts == STS_AUTH_TAG_W_ERR)
                                                    ) : 1'h0
                                                );

    assign sinc_done_o              = fw_cmd_suc | sinc_erase_done_o;      // complete cmd successfully or erase done

    assign sinc_cpu_non_active_state = (cmu_sinc_state != CACHE_ACTIVE);

    assign cmu_active               = cmu_ctrl_active_cmd | severe_err | non_severe_err | reg_ctrl_active | axi_sub_clock_gate_en_o;
    assign sinc_err_o               = severe_err | non_severe_err;
    assign cmu_busy                 = stall_cpu_req;

endmodule
