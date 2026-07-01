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
// File        : sinc_cmu_crypto_wrap_ctrl_ret.sv
// Description : CMU crypto wrapper retention module. Stores AES encryption key
//               and temporarily holds AES seed across power-domain retention.

module sinc_cmu_crypto_wrap_ctrl_ret
#(
    parameter BLOCK_LENW            = 7
)
(
    input logic                     clk_i,
    input logic                     rstn_i,

    input logic                     is_r_key,
    input logic                     clr_key,
    input logic                     severe_err,
    input logic                     dma_c_wrap_r_vld,
    input logic [BLOCK_LENW-1:0]    rdata_bt_cnt,
    input logic [31:0]              dma_c_wrap_rdata,

    output logic [255:0]            key_q
    );


    /* flops to store seed or encryption key */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            key_q <= 256'h0;
        end
        else begin
            if(clr_key | severe_err) begin
                key_q <= 256'h0;
            end
            else if(is_r_key) begin
                if(dma_c_wrap_r_vld) begin
                    key_q[(rdata_bt_cnt*32)+(32-1)-:32] <= dma_c_wrap_rdata;
                end
            end
        end
    end


endmodule