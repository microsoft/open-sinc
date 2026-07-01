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
// File        : sinc_cmu_ctrl_ret.sv
// Description : CMU control retention module. Holds the SInC state register
//               across power-domain retention.


module sinc_cmu_ctrl_ret 
import sinc_pkg::*;
(
    input logic                     clk_i,
    input logic                     rstn_i,

    input sinc_state_t              next_cmu_sinc_state,
    input logic                     severe_err,

    output sinc_state_t             cmu_sinc_state
);

    /* logic holding sinc state */
    always_ff @( posedge clk_i or negedge rstn_i ) begin
        if(~rstn_i) begin
            cmu_sinc_state <= DISABLED;
        end
        else begin
            if(severe_err) begin
                cmu_sinc_state <= CACHE_FAILED;
            end
            else begin
                cmu_sinc_state <= next_cmu_sinc_state;
            end
        end
    end

endmodule