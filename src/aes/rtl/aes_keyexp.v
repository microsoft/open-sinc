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
// File          : aes_keyexp.v
// Description   : Key expansion for AES

`include "aes.vh"

module aes_keyexp (
    // inputs
    clk_i,
    reset_nai,
    key_i,
    nk_i,
    nr_i,
    start_i,
    clear_i,
    dir_i,
    a_valid_i,
    b_req_i,

    // outputs
    rkey_o,
    rkey_idx_o,
    dp_en_o,
    key_req_o,
    last_round_o,
    b_valid_o,
    error_o
);

input            clk_i;
input            reset_nai;
input [7:0][3:0]   [7:0]     key_i;
input  [3:0]     nk_i;
input  [3:0]     nr_i;
input            start_i;
input            clear_i;
input            dir_i;
input            a_valid_i;
input            b_req_i;

output [3:0][3:0]  [7:0]     rkey_o;
output [3:0]     rkey_idx_o;  // to datapath, indicate which round key is ready
output           dp_en_o;
output           key_req_o;
output           last_round_o;
output           b_valid_o;
output           error_o;

localparam STATE_WIDTH = 4;

// state machine
typedef enum bit [STATE_WIDTH-1:0]
  {
  S_IDLE    = 4'h0,
  S_LOAD0   = 4'h1,
  S_LOAD1   = 4'h2,
  S_ADJUST  = 4'h3,
  S_ACTIVE  = 4'h4,
  S_LASTKEY = 4'h5,
  S_RELOAD0 = 4'h6,
  S_RELOAD1 = 4'h7,
  S_WRITE   = 4'h8,
  S_WAIT    = 4'h9
  } aes_keyexp_fsm;

// registers
reg [3:0][3:0]     [7:0]     ref_key_cur; // reference key
reg [3:0][3:0]     [7:0]     ref_key_pre; // reference key
reg [3:0][3:0]     [7:0]     key_cur;     // round key latest generated
reg [3:0][3:0]     [7:0]     key_pre;     // previous round key
reg    [STATE_WIDTH-1:0]     current_state;
reg    [6:0]     ki;
reg    [3:0]     rkey_idx;
reg              gen_lastkey;
reg              start_r;
reg    [STATE_WIDTH-1:0]     next_state;
reg [3:1][3:0]     [7:0]     key_tmp_mux;
reg [3:0][3:0]     [7:0]     key_nxt;     // next round key
reg [3:0][3:0]     [7:0]     key_nxt_dir0;
reg [3:0][3:0]     [7:0]     key_nxt_dir1;
reg [3:0][3:0]     [7:0]     key_nxt_dir;
reg [3:0][3:0]     [7:0]     key_nxt_add_dir;
reg [3:0][3:0]     [7:0]     key_nxt_add_inv_0;
reg [3:0][3:0]     [7:0]     key_nxt_add_inv_1;
reg [3:0][3:0]     [7:0]     key_nxt_inv;
reg    [7:0]     ki_nxt;
wire   [5:0]     ki_max;
reg              active;
reg              load0;
reg              load1;
reg    [3:0]     rcon_idx_dir;
reg    [4:0]     rcon_idx_inv;
wire   [3:0]     rcon_idx;
wire [3:0][3:0]     [7:0]     zero;
wire             aes128;
wire             aes192;
wire             aes256;
wire             sel_tmp_mux0;
wire             sel_tmp_mux1;
reg [3:0]     [7:0]     rotwordi0;
wire [3:0]    [7:0]     rotwordo0;
wire [3:0]    [7:0]     subwordi0;
wire [3:0]    [7:0]     subwordo0;
wire [3:0]    [7:0]     subword_rcon0;
wire [15:0]    [7:0]     rcon;
wire             aes192_sbox0;
wire             aes192_sbox1;
wire             finish;
wire   [7:0]     composite_rcon;
wire   [7:0]     rcon_mux;
wire [3:0][3:0]    [7:0]     active_key;
wire [3:0][3:0]    [7:0]     composite_key;
wire [3:0][3:0]    [7:0]     m_composite_key;
reg              reload0;
reg              reload1;
reg              adjust;
reg              lastkey;
reg              key_req;
reg              write;
reg              waitd;
reg              last_round_1d;

integer          i;
integer          j;
integer          k;

//
// datapath (DP):
// descript: Three states - S_IDLE -> S_LOAD -> S_ACTIVE
//           S_IDLE:   DP stays idle
//           S_LOAD:   DP loads the key into key_cur, key_pre
//           S_ACTIVE: DP generates one round key per clock
//                     AES-128, S_ACTIVE starts from the second round key
//                     AES-192, S_ACTIVE starts from the second round key
//                     AES-256, S_ACTIVE starts from the third round key
//           S_RELOAD: Reload the reference key to key_cur and key_pre
//
/*
// store key to local register
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                key_r[j][k] <= 8'h00;
            end
        end
    end
    else if (clear_i) begin
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                key_r[j][k] <= 8'h00;
            end
        end
    end
    else if (start_i) begin
        key_r <= key_i;
    end
end
*/
genvar gi, gj, gk;
generate
    for (gj=0; gj<4; gj=gj+1) begin
        for (gk=0; gk<4; gk=gk+1) begin
            assign zero[gj][gk] = 8'h00;
        end
    end
endgenerate

always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        start_r <= 1'b0;
    end
    else if (clear_i || active) begin
        start_r <= 1'b0;
    end
    else if (start_i) begin
        start_r <= 1'b1;
    end
end

// first convert key from binary field to composite field

generate
    for (gi=0; gi<4; gi=gi+1) begin
        for (gj=0; gj<4; gj=gj+1) begin
            assign active_key[gi][gj] = load1 ? key_i[4+gi][gj] : key_i[gi][gj];
        end
    end
endgenerate
generate
    for (gi=0; gi<4; gi=gi+1) begin : aes_affine_mul_t_outer_for
        for (gj=0; gj<4; gj=gj+1) begin : aes_affine_mul_t_inner_for
            aes_affine_mul_t aes_affine_mul_t0 (
                .a (active_key[gi][gj]),
                .b (composite_key[gi][gj])
            );
        end
    end
endgenerate

// convert the composite key
generate
    for (gi=0; gi<4; gi=gi+1) begin
        for (gj=0; gj<4; gj=gj+1) begin
            assign m_composite_key[gi][gj] = composite_key[gi][gj];
        end
    end
endgenerate

// temporary storage: key_cur and key_pre
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                key_cur[j][k] <= 8'h00;
                key_pre[j][k] <= 8'h00;
            end
        end
    end
    else if (clear_i) begin          // controller clear storage
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                key_cur[j][k] <= 8'h00;
                key_pre[j][k] <= 8'h00;
            end
        end
    end
    else begin
        if (!adjust && !write && !waitd) begin
            key_pre <= key_cur;
        end
        if (active || adjust) begin
            key_cur <= key_nxt;
        end
        else if (load0 || load1) begin
            key_cur <= m_composite_key;
        end
        else if (reload0) begin
            if (aes128)
                key_cur <= ref_key_cur;
            else
                key_cur <= ref_key_pre;
        end
        else if (reload1) begin
            key_cur <= ref_key_cur;
        end
    end
end

// reference storage: original key for encryption; last-round key for decryption
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                ref_key_cur[j][k] <= 8'h00;
                ref_key_pre[j][k] <= 8'h00;
            end
        end
    end
    else if (clear_i) begin          // controler clear storage
        for (j=0; j<4; j=j+1) begin
            for (k=0; k<4; k=k+1) begin
                ref_key_cur[j][k] <= 8'h00;
                ref_key_pre[j][k] <= 8'h00;
            end
        end
    end
    else begin
        // ref_key_cur
        if (dir_i) begin
            if (aes192 && adjust) begin
                ref_key_cur <= key_nxt;
            end
            else if (load0 || load1) begin
                ref_key_cur <= m_composite_key;
            end
        end
        else begin
            if (lastkey) begin
                if (aes128)
                    ref_key_cur <= key_cur;
                else
                    ref_key_cur <= key_pre;
            end
        end
        // ref_key_pre
        if (dir_i) begin
            if (load1)
                ref_key_pre <= ref_key_cur;
        end
        else begin
            if (lastkey)
                ref_key_pre <= key_cur;
        end
    end
end

// --------------------------------
// helper signals for datapath
// --------------------------------
assign aes128       = (nk_i == 4);
assign aes192       = (nk_i == 6);
assign aes256       = (nk_i == 8);
assign aes192_sbox1 = (dir_i || gen_lastkey) ?
                      ((ki==4) | (ki==16) | (ki==28) | (ki==40) | (ki==52)) & aes192 :
                      ((ki==12) | (ki==24) | (ki==36) | (ki==48)) & aes192;
assign aes192_sbox0 = (dir_i || gen_lastkey) ?
                      ((ki==12) | (ki==24) | (ki==36) | (ki==48)) & aes192 :
                      ((ki==8)  | (ki==20) | (ki==32) | (ki==44) | (ki==56)) & aes192;
assign sel_tmp_mux0 = aes192_sbox0 | aes128 | aes256;
assign sel_tmp_mux1 = aes192_sbox1;

// ---------------------------------
// datapath for direct calculation
// ---------------------------------
always @ * begin
        for (i=0; i<4; i=i+1) begin
            // select keyword[ki-nk]
            if (aes128)  begin
                key_nxt_add_dir[0][i] = key_cur[0][i];
                key_nxt_add_dir[1][i] = key_cur[1][i];
                key_nxt_add_dir[2][i] = key_cur[2][i];
                key_nxt_add_dir[3][i] = key_cur[3][i];
            end
            else if (aes192) begin
                key_nxt_add_dir[0][i] = key_pre[2][i];
                key_nxt_add_dir[1][i] = key_pre[3][i];
                if (adjust) begin
                    key_nxt_add_dir[2][i] = key_pre[0][i];
                    key_nxt_add_dir[3][i] = key_pre[1][i];
                end
                else begin
                    key_nxt_add_dir[2][i] = key_cur[0][i];
                    key_nxt_add_dir[3][i] = key_cur[1][i];
                end
            end
            else begin // AES-256
                key_nxt_add_dir[0][i] = key_pre[0][i];
                key_nxt_add_dir[1][i] = key_pre[1][i];
                key_nxt_add_dir[2][i] = key_pre[2][i];
                key_nxt_add_dir[3][i] = key_pre[3][i];
            end

            // the 1st datapath for direct operation
            if (aes192 && (!aes192_sbox0) && (!aes192_sbox1))
                key_tmp_mux[1][i] = key_cur[3][i];
            else
                key_tmp_mux[1][i] = subword_rcon0[i];
            key_nxt_dir0[0][i] = key_nxt_add_dir[0][i] ^ key_tmp_mux[1][i];
            key_nxt_dir0[1][i] = key_nxt_add_dir[1][i] ^ key_nxt_dir0[0][i];
            key_nxt_dir0[2][i] = key_nxt_add_dir[2][i] ^ key_nxt_dir0[1][i];
            key_nxt_dir0[3][i] = key_nxt_add_dir[3][i] ^ key_nxt_dir0[2][i];

            // the 2nd datapath for direct operation
            key_nxt_dir1[0][i] = key_nxt_add_dir[0][i] ^ key_cur[3][i];
            key_nxt_dir1[1][i] = key_nxt_add_dir[1][i] ^ key_nxt_dir1[0][i];
            key_nxt_dir1[2][i] = key_nxt_add_dir[2][i] ^ key_tmp_mux[1][i];
            key_nxt_dir1[3][i] = key_nxt_add_dir[3][i] ^ key_nxt_dir1[2][i];

            // adjust phase of aes192 doesn't change the 1st 2 words
            // of the 2nd round key
            if (adjust) begin
                key_nxt_dir[0][i] = key_cur[0][i];
                key_nxt_dir[1][i] = key_cur[1][i];
            end
            else begin
                key_nxt_dir[0][i] = aes192_sbox1 ? key_nxt_dir1[0][i] : key_nxt_dir0[0][i];
                key_nxt_dir[1][i] = aes192_sbox1 ? key_nxt_dir1[1][i] : key_nxt_dir0[1][i];
            end
            key_nxt_dir[2][i] = aes192_sbox1 ? key_nxt_dir1[2][i] : key_nxt_dir0[2][i];
            key_nxt_dir[3][i] = aes192_sbox1 ? key_nxt_dir1[3][i] : key_nxt_dir0[3][i];
        end
end

// ----------------------------------
// datapath for reverse calculation
// ----------------------------------
always @ * begin
        for (i=0; i<4; i=i+1) begin
            // key_tmp_mux[2-3]
            if (sel_tmp_mux0)
                key_tmp_mux[2][i] = subword_rcon0[i];
            else
                key_tmp_mux[2][i] = key_cur[3][i];
            if (sel_tmp_mux1)
                key_tmp_mux[3][i] = subword_rcon0[i];
            else
                key_tmp_mux[3][i] = key_cur[1][i];
            // key_nxt_add_inv_X
            if (aes128) begin
                key_nxt_add_inv_0[0][i] = key_tmp_mux[2][i];
                key_nxt_add_inv_0[1][i] = key_cur[0][i];
                key_nxt_add_inv_0[2][i] = key_cur[1][i];
                key_nxt_add_inv_0[3][i] = key_cur[2][i];
                key_nxt_add_inv_1[0][i] = key_cur[0][i];
                key_nxt_add_inv_1[1][i] = key_cur[1][i];
                key_nxt_add_inv_1[2][i] = key_cur[2][i];
                key_nxt_add_inv_1[3][i] = key_cur[3][i];
            end
            else if (aes192) begin
                key_nxt_add_inv_0[0][i] = key_tmp_mux[3][i];
                key_nxt_add_inv_0[1][i] = key_cur[2][i];
                key_nxt_add_inv_0[2][i] = key_tmp_mux[2][i];
                key_nxt_add_inv_0[3][i] = key_pre[0][i];
                key_nxt_add_inv_1[0][i] = key_cur[2][i];
                key_nxt_add_inv_1[1][i] = key_cur[3][i];
                key_nxt_add_inv_1[2][i] = key_pre[0][i];
                key_nxt_add_inv_1[3][i] = key_pre[1][i];
            end
            else begin
                key_nxt_add_inv_0[0][i] = key_tmp_mux[2][i];
                key_nxt_add_inv_0[1][i] = key_pre[0][i];
                key_nxt_add_inv_0[2][i] = key_pre[1][i];
                key_nxt_add_inv_0[3][i] = key_pre[2][i];
                key_nxt_add_inv_1[0][i] = key_pre[0][i];
                key_nxt_add_inv_1[1][i] = key_pre[1][i];
                key_nxt_add_inv_1[2][i] = key_pre[2][i];
                key_nxt_add_inv_1[3][i] = key_pre[3][i];
            end
            // key_nxt_inv
            for (k=0; k<4; k=k+1) begin
                key_nxt_inv[k][i] = key_nxt_add_inv_0[k][i] ^
                                       key_nxt_add_inv_1[k][i];
            end
        end
end

generate
    for (gj=0; gj<4; gj=gj+1) begin
        for (gk=0; gk<4; gk=gk+1) begin
            assign key_nxt[gj][gk] = (dir_i || gen_lastkey) ?
                   key_nxt_dir[gj][gk] : key_nxt_inv[gj][gk];
        end
    end
endgenerate

// -------------------------------------------------------------------
// generate subword_rcon, shared by both direct and reverse datapaths
// -------------------------------------------------------------------

assign rcon[ 0] = 8'h01;
assign rcon[ 1] = 8'h02;
assign rcon[ 2] = 8'h04;
assign rcon[ 3] = 8'h08;
assign rcon[ 4] = 8'h10;
assign rcon[ 5] = 8'h20;
assign rcon[ 6] = 8'h40;
assign rcon[ 7] = 8'h80;
assign rcon[ 8] = 8'h1b;
assign rcon[ 9] = 8'h36;
assign rcon[10] = 8'h00;
assign rcon[11] = 8'h00;
assign rcon[12] = 8'h00;
assign rcon[13] = 8'h00;
assign rcon[14] = 8'h00;
assign rcon[15] = 8'h00;

aes_affine_mul_t aes_affine_mul_t1 (
    .a (rcon[rcon_idx]),
    .b (composite_rcon)
);

// counter to indicate which rcon to use for direct calculation
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        rcon_idx_dir <= 4'b0;
    end
    else if (clear_i)
        rcon_idx_dir <= 4'b0;
    else if (start_i)
        rcon_idx_dir <= 4'b0;
    else if (aes128 && active)
        rcon_idx_dir <= rcon_idx_dir + 1;
    else if ((aes192_sbox0 || aes192_sbox1) && (active || adjust))
        rcon_idx_dir <= rcon_idx_dir + 1;
    else if (aes256 && (ki[2:0]==3'b000) && active)
        rcon_idx_dir <= rcon_idx_dir + 1;
    else if (reload0)
        rcon_idx_dir <= 4'b0;
    else if (aes192 && reload1)
        rcon_idx_dir <= 4'b1; // the 2nd reload for AES192 already covered
                              // the first rcon
end
// for reversed calculation, scan rcon reversely
always @ * begin
    if (aes128)
        rcon_idx_inv = 9 - rcon_idx_dir;
    // rcon_idx_dir starts from 1 at the beginning of S_ACTIVE
    else if (aes192)
        rcon_idx_inv = 8 - rcon_idx_dir; // 7 - rcon_idx_dir + 1;
    else
        rcon_idx_inv = 6 - rcon_idx_dir;
end
assign rcon_idx = (dir_i || gen_lastkey) ? rcon_idx_dir[3:0] : rcon_idx_inv[3:0];

// first rotword + subword + addrcon
generate
    for (gj=0; gj<4; gj=gj+1) begin
        assign rotwordi0[gj] =
            adjust                  ? key_cur[1][gj] :
            ((dir_i || gen_lastkey) && aes192_sbox1) ? key_nxt_dir1[1][gj] :
            (!dir_i && (!gen_lastkey) && aes128) ? (key_cur[3][gj] ^ key_cur[2][gj]) :
            (!dir_i && (!gen_lastkey) && aes192_sbox1) ? key_cur[1][gj] :
            key_cur[3][gj];
    end
endgenerate

aes_rotword aes_rotword0 (
    .a_i (rotwordi0),
    .b_o (rotwordo0)
);
// speciall process for aes256
assign subwordi0 = (aes256 && (ki[2:0] == 3'b100)) ? rotwordi0 : rotwordo0;

aes_subword aes_subword0 (
    .clk_i (clk_i),
    .reset_nai (reset_nai),
    .a_i (subwordi0),
    .dir_i(1'b1),
    .b_o (subwordo0),
    .error_o(error_o)
);

// special process for aes256
assign rcon_mux  = (aes256 && (ki[2:0] == 3'b100)) ?  8'b0 : composite_rcon;

generate
    for (gj=0; gj<4; gj=gj+1) begin
        if (gj==0) begin
            assign subword_rcon0[gj] = subwordo0[0] ^ rcon_mux;
        end
        else begin
            assign subword_rcon0[gj] = subwordo0[gj];
        end
     end
endgenerate

// ----------------------------------
// state machine
// ----------------------------------
assign ki_max = (nr_i + 1) * 4;
assign finish = (ki_nxt[5:0] >= ki_max);

// gen_lastkey to help the state machine
// this signal tells whether the key_exp module is generating the last round key
// for decryption
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        gen_lastkey <= 1'b0;
    end
    else if (clear_i) begin
        gen_lastkey <= 1'b0;
    end
    else if (start_i && !dir_i) begin
        gen_lastkey <= 1'b1;
    end
    else if (reload0) begin
        gen_lastkey <= 1'b0;
    end
end

// state machine
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        current_state <= S_IDLE;
        ki            <= 7'b000000;
    end
    else if (clear_i) begin
        current_state <= S_IDLE;
        ki            <= 7'b000000;
    end
    else begin
        current_state <= next_state;
        ki            <= ki_nxt[6:0];
    end
end

always @ * begin
    load0   = 1'b0;
    load1   = 1'b0;
    adjust  = 1'b0;
    active  = 1'b0;
    lastkey = 1'b0;
    key_req = 1'b0;
    reload0 = 1'b0;
    reload1 = 1'b0;
    write   = 1'b0;
    waitd   = 1'b0;
    ki_nxt  = {1'b0, ki};
    next_state = current_state;
    if (clear_i) begin
        next_state = S_IDLE;
        ki_nxt     = 8'h00;
    end
    else begin
        case (current_state)
            S_IDLE: begin
                ki_nxt = {1'b0, ki};
                if (start_i)
                    key_req = 1'b1;
                if (start_r && a_valid_i) begin
                    next_state = S_LOAD0;
                    ki_nxt = 8'h00;
                end
            end
            S_LOAD0: begin
                ki_nxt = 8'h04;
                load0 = 1'b1;
                if (aes128) begin
                    //if ((a_valid_i && b_req_i && dir_i) || gen_lastkey)
                        next_state = S_ACTIVE;
                    //else
                    //    next_state = S_WAIT;
                end
                else
                    next_state = S_LOAD1;
            end
            // aes192 and aes256 need two cycles to write to key storage
            S_LOAD1: begin
                if (aes192) begin
                    ki_nxt = 8'h04;
                    next_state = S_ADJUST;
                end
                else begin
                    ki_nxt = 8'h08;
                    //if ((a_valid_i && b_req_i && dir_i) || gen_lastkey)
                        next_state = S_ACTIVE;
                    //else
                    //    next_state = S_WAIT;
                end
                load1 = 1'b1;
            end
            // aes192 need one cycle to adjust the second round key
            S_ADJUST: begin
                adjust = 1'b1;
                ki_nxt = 8'h08;
                //if ((a_valid_i && b_req_i && dir_i) || gen_lastkey)
                    next_state = S_ACTIVE;
                //else
                //    next_state = S_WAIT;
            end
            S_ACTIVE: begin
                active = 1'b1;
                ki_nxt = ki + 4;
                if (gen_lastkey) begin
                    if (finish)
                        next_state = S_LASTKEY;
                end
                else begin
                    if (finish) begin
                        next_state = S_RELOAD0;
                    end
                end
                // b_req_i is always delayed. so last write's consiquence is
                // observed after the datapath starts to process new data.
                // when jumping from S_RELOAD* to S_ACTIVE, we use the previous
                // b_req_i as a prediction. When the actual b_req_i comes and
                // does not match, hazard occurs. In this case, we
                // fall back to S_RELOAD0 to recover this hazard. on the other
                // side, data path does not give out a_req_o too quickly.
                // this fall back happens before a_req_o is given out.
                //else if (!b_req_i)
                //    next_state = S_RELOAD0;
            end
            S_LASTKEY: begin
                next_state = S_RELOAD0;
                lastkey = 1'b1;
                active = 1'b0;
            end
            S_RELOAD0: begin
                reload0 = 1'b1;
                ki_nxt = 8'h04;
                if (aes128) begin
                    if (!b_req_i)
                        next_state = S_WRITE;
                    else if (a_valid_i)
                        next_state = S_ACTIVE;
                    else
                        next_state = S_WAIT;
                end
                else begin
                    next_state = S_RELOAD1;
                end
            end
            S_RELOAD1: begin // AES192 and AES256 need two cycles to reload
                reload1 = 1'b1;
                ki_nxt = 8'h08;
                if (!b_req_i)
                    next_state = S_WRITE;
                else if (a_valid_i)
                    next_state = S_ACTIVE;
                else
                    next_state = S_WAIT;
            end
            S_WRITE: begin
                write = 1'b1;
                if (b_req_i && a_valid_i)
                    next_state = S_ACTIVE;
                else if (b_req_i)
                    next_state = S_WAIT;
            end
            default: begin // S_WAIT
                waitd = 1'b1;
                if (start_i)
                    key_req = 1'b1;
                if (start_r && a_valid_i) begin
                    next_state = S_LOAD0;
                    ki_nxt = 8'h00;
                end
                else if (a_valid_i)
                    next_state = S_ACTIVE;
            end
        endcase
    end
end

// -----------------------------------
// generate outputs
// -----------------------------------

// counter to indicate which round key is valid on the rkey_o port
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai)
        rkey_idx <= 4'h0;
    else if (clear_i)
        rkey_idx <= 4'h0;
    // two reload cycles for AES192 and AES256, so the first cycle still need
    // index increase
    else if ((active || (!aes128 && reload0)) && (!gen_lastkey))
        rkey_idx <= rkey_idx + 1;
    else
        rkey_idx <= 4'h0;
end

// use last_round_1d to generate b_valid_o due to the result register in
// aes datapath
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        last_round_1d <= 1'b0;
    end
    else if (clear_i) begin
        last_round_1d <= 1'b0;
    end
    else begin
        last_round_1d <= last_round_o;
    end
end


// outputs
assign rkey_o     = gen_lastkey ? zero : (aes128 ? key_cur : key_pre);
assign dp_en_o    = (active | reload0 | reload1) & (~gen_lastkey);
assign key_req_o  = key_req;
assign rkey_idx_o = rkey_idx;
assign last_round_o = (rkey_idx == nr_i) & (nr_i != 4'b0);
assign b_valid_o = last_round_1d | write;

endmodule


