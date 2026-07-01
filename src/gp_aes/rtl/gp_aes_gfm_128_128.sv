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
// File        : gp_aes_gfm_128_128.sv
// Description : Galois Field 128x128 multiplier. y[127:0] = x[127:0] * h[127:0].

module gp_aes_gfm_128_128
import gp_aes_pkg::*;
(
    //****************************************************************
    // Clock/Reset/Misc signals
    //****************************************************************
    input logic                                 clk_i,
    input logic                                 rstn_i,
    input logic                                 clear_i,
    input logic [127:0]                         x_0,
    input logic [127:0]                         x_1,
    input logic                                 x_vld,            // start the operation once x_vld goes high
    input logic [127:0]                         h,
    output logic [127:0]                        y_0,
    output logic [127:0]                        y_1,
    output logic                                y_vld,            // pulse when y_0 and y_1 are valid
    output logic                                gfm_fault
    );
    
    ghash_mul_fsm_t             state;
    ghash_mul_fsm_t             next_state;

    logic [15:0]                cand_0;
    logic [15:0]                cand_1;
    logic [127:0]               prod_0;
    logic [127:0]               prod_1;
    logic [127:0]               output_0;
    logic [127:0]               output_1;
    logic [127:0]               acc_0;
    logic [127:0]               acc_1;
    logic                       invld_state;

    // first instance of gfmac
    gp_aes_gfmac_16_128 u_gfmac_16_128_0 (
        // output
        .prod               (prod_0),
        // input
        .cand               (cand_0),
        .h                  (h),
        .acc                ({acc_0, 16'h0})
    );

    // Second GFM instance not needed without DPA
    logic [15:0] unused_cand_1;
    logic [127:0] unused_acc_1;

    assign unused_cand_1 = cand_1;
    assign unused_acc_1 = acc_1;
    assign output_1 = 128'h0;
    assign prod_1   = 128'h0;

    // counter to count 8 clocks. Once it starts, it can be reset 
    // either by asserting clear_i or once it reaches value 7

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            state <= CNT0;
        end
        else begin
            if(clear_i) begin
                state <= CNT0;
            end
            else begin
                state <= next_state;
            end
        end
    end

    always_comb begin
        next_state = state;
        cand_0 = 16'h0;
        acc_0 = 128'h0;
        cand_1 = 16'h0;
        acc_1 = 128'h0;
        invld_state = 1'h0;

        case(state)
            CNT0: begin
                cand_0 = x_0[127:112];
                acc_0 = 128'h0;

                cand_1 = x_1[127:112];
                acc_1 = 128'h0;

                if(x_vld) begin
                    next_state = CNT1;
                end
            end
            CNT1: begin
                cand_0 = x_0[111:96];
                acc_0 = output_0;

                cand_1 = x_1[111:96];
                acc_1 = output_1;

                next_state = CNT2;
            end
            CNT2: begin
                cand_0 = x_0[95:80];
                acc_0 = output_0;

                cand_1 = x_1[95:80];
                acc_1 = output_1;

                next_state = CNT3;
            end
            CNT3: begin
                cand_0 = x_0[79:64];
                acc_0 = output_0;

                cand_1 = x_1[79:64];
                acc_1 = output_1;

                next_state = CNT4;
            end
            CNT4: begin
                cand_0 = x_0[63:48];
                acc_0 = output_0;

                cand_1 = x_1[63:48];
                acc_1 = output_1;

                next_state = CNT5;
            end
            CNT5: begin
                cand_0 = x_0[47:32];
                acc_0 = output_0;

                cand_1 = x_1[47:32];
                acc_1 = output_1;

                next_state = CNT6;
            end
            CNT6: begin
                cand_0 = x_0[31:16];
                acc_0 = output_0;

                cand_1 = x_1[31:16];
                acc_1 = output_1;

                next_state = CNT7;
            end
            CNT7: begin
                cand_0 = x_0[15:0];
                acc_0 = output_0;

                cand_1 = x_1[15:0];
                acc_1 = output_1;

                next_state = CNT0;
            end
            default: begin
                invld_state = 1'h1;
                next_state = CNT0;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            output_0 <= 128'h0;
        end
        else begin
            if(clear_i) begin
                output_0 <= 128'h0;
            end
            else begin
                output_0 <= prod_0;
            end
        end
    end

    assign y_vld        = (state == CNT7);
    assign y_0          = y_vld ? prod_0 : 128'h0;
    assign y_1          = y_vld ? prod_1 : 128'h0;

    assign gfm_fault    = invld_state;

endmodule