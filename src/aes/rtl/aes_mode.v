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
// File          : aes_mode.v
// Description   : AES modes

`include "aes.vh"

module aes_mode (
    clk_i,
    reset_nai,

    // from interface
    mode_i,             // mode select
    dir_i,              // dir = 1 -> encryption; dir = 0 -> decryption
    a_valid_i,          // input a is valid
    key_valid_i,        // input key is valid
    iv_valid_i,         // input initial value valid
    b_req_i,            // output message request
    a_i,                // input message a
    key_i,              // input key
    iv_i,               // input initial value
    unit_size_i,        // data unit size for XTS
    msg_length_i,       // input message length
    clear_i,            // clear internal states
    // to interface
    b_o,                // message b after process
    b_valid_o,          // message b is valid
    iv_o,               // iv for the next block
    a_req_o,            // message request

    // from aes core
    a_req_i,            // message request from aes core
    b_valid_i,          // message from aes core is valid
    key_req_i,          // key request from aes core
    b_i,                // message from aes core
    // to aes core
    a_o,                // message to aes core
    a_valid_o,          // message to aes core is valid
    b_req_o,            // message request to aes core
    key_o,              // key to aes core
    key_valid_o,        // key to aes core is valid
    dir_o
);


input            clk_i;
input            reset_nai;
input  [3:0]     mode_i;
input            dir_i;
input            a_valid_i;
input            key_valid_i;
input            iv_valid_i;
input            b_req_i;
input  [127:0]   a_i;
input  [255:0]   key_i;
input  [127:0]   iv_i;
input  [8:0]     unit_size_i;
input  [31:0]    msg_length_i;
input            clear_i;
output [127:0]   b_o;
output           b_valid_o;
output [127:0]   iv_o;
output           a_req_o;

input            a_req_i;
input            b_valid_i;
input            key_req_i;
input [3:0][3:0]   [7:0]     b_i;
output [3:0][3:0]  [7:0]     a_o;
output           a_valid_o;
output           b_req_o;
output [7:0][3:0]  [7:0]     key_o;
output           key_valid_o;
output           dir_o;

localparam STATE_WIDTH = 3;

reg    [127:0]   iv_r;
reg    [127:0]   iv_nxt;
reg    [127:0]   iv_swap;
wire   [127:0]   iv_plus_1;
reg    [127:0]   iv_unswap;
reg    [STATE_WIDTH-1:0]     cur_state;
reg    [STATE_WIDTH-1:0]     next_state;
reg              s_idle;
reg              s_key0;
reg              s_data0;
reg              s_key1;
reg              s_data1;
reg    [31:0]    msg_cnt;
reg    [127:0]   temp;
reg    [127:0]   temp_1d;
reg    [127:0]   b_vec;
reg [3:0][3:0]     [7:0]     a_state;
reg              i_valid_r;
reg [7:0][3:0]     [7:0]     key_state;
reg    [127:0]   a;
reg              a_valid;
reg              a_req;
reg    [127:0]   b;
reg              b_valid;
reg              b_req;
reg    [255:0]   key;
reg              key_valid;
reg    [8:0]     unit_cnt;
wire             eou;
wire             eom;
wire   [127:0]   temp_alpha;
wire             first_msg;

integer          ii;
integer          jj;

typedef enum bit [STATE_WIDTH-1:0]
  {
  IDLE  = 3'h0,
  KEY0  = 3'h1,
  DATA0 = 3'h2,
  KEY1  = 3'h3,
  DATA1 = 3'h4
  } aes_mode_fsm;

//
// state machine for different modes
// IDLE  : idle state
// KEY0  : program XTS tweaked key to aes core
// DATA0 : send data to aes core
// KEY1  : program XTS original key to aes core
// DATA1 : send data to aes core
//
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        cur_state <= IDLE;
    end
    else if (clear_i==1) begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= next_state;
    end
end

always @ * begin
    s_idle = 1'b0;
    s_key0 = 1'b0;
    s_data0 = 1'b0;
    s_key1 = 1'b0;
    s_data1 = 1'b0;
    case (cur_state)
        IDLE : begin
            s_idle = 1'b1;
            if (key_valid_i) begin
                if (key_req_i)
                    next_state = DATA0;
                // when AES core is not ready, e.g. DRBG is not ready
                else
                    next_state = KEY0;
            end
            else
                next_state = IDLE;
        end
        KEY0 : begin
            s_key0 = 1'b1;
            if (key_req_i)
                next_state = DATA0;
            else
                next_state = KEY0;
        end
        DATA0 : begin
            s_data0 = 1'b1;
            if (mode_i == `XTS) begin
                if (b_valid_i)
                    next_state = KEY1;
                else
                    next_state = DATA0;
            end
            else if (eom && b_valid_i && b_req_i)
                next_state = IDLE;
            else
                next_state = DATA0;
        end
        KEY1 : begin
            s_key1 = 1'b1;
            if (key_req_i)
                next_state = DATA1;
            else
                next_state = KEY1;
        end
        default : begin // DATA1
            s_data1 = 1'b1;
            if (b_valid_i && b_req_i) begin
                if (eom)
                    next_state = IDLE;
                else if (eou)
                    next_state = KEY0;
                else
                    next_state = DATA1;
            end
            else begin
                next_state = DATA1;
            end
        end
    endcase
end

//
// iv_r is used to store iv for the next block of next unit (XTS)
// for the first message block, it's always used as an input
// for other blocks, it's also used as an input in
// CFB-Decrypt, CTR, and XTS modes. So in these modes, iv_r should be updated
// right after a_req_i is received (a_req_i && s_data0 for XTS).
// In other cases, iv_r is simply used as a storage for possible write out of
// iv when there is a request.
//
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai)
        iv_r <= 128'b0;
    else if (clear_i)
        iv_r <= 128'b0;
    else if (iv_valid_i) // used as input to engine for the 1st block
        iv_r <= iv_i;
    else if (((mode_i == `CFB) && !dir_i) || // CFB-Decrypt
              (mode_i == `CTR)) begin        // CTR
        if (a_valid_i && a_req_i) // used as input
            iv_r <= iv_nxt;
    end
    else if (s_data0 && b_valid_i && (b_req_i || (mode_i == `XTS))) // used as storage of output
        iv_r <= iv_nxt;
end

always @ * begin
    for (ii=0; ii<16; ii=ii+1) begin
        for (jj=0; jj<8; jj=jj+1) begin
            iv_swap[(ii*8) + jj] = iv_r[((15-ii)*8) + jj];
        end
    end
    for (ii=0; ii<16; ii=ii+1) begin
        for (jj=0; jj<8; jj=jj+1) begin
            iv_unswap[(ii*8) + jj] = iv_plus_1[((15-ii)*8) + jj];
        end
    end
end

// in counter mode, increase by one starts from the most significant bit
assign iv_plus_1 = (mode_i == `CTR ? iv_swap : iv_r) + 1;



//
// In XTS mode, temp is used to store the tweak value, and temp_1d for the
// previous tweak value.
//
// In other modes, temp is used to store the input since sometimes temp is
// used directly to generate the output
//
assign temp_alpha = {temp[126:0], 1'b0} ^ (temp[127] ? 128'h87 : 128'h00);

always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai) begin
        temp <= 128'b0;
        temp_1d <= 128'b0;
    end
    else if (clear_i) begin
        temp <= 128'b0;
        temp_1d <= 128'b0;
    end
    else if (mode_i == `XTS) begin // in XTS mode
        if(s_data0 && b_valid_i) begin
            temp <= b_vec;
        end
        else if (s_data1 && a_valid_i && a_req_i) begin
            temp <= temp_alpha;
        end
        if (s_data1 && a_valid_i && a_req_i) begin
            temp_1d <= temp;
        end
    end
    else if (a_valid_i && a_req_o) // in other modes
        temp <= a_i;
end


//
// register and counter of message blocks
//
always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai)
        msg_cnt <= 32'b0;
    else if (clear_i || s_idle)
        msg_cnt <= 32'b0;
    else if (a_valid_i && a_req_o) // && msg_cnt < msg_length_i)
        msg_cnt <= msg_cnt + 16;
end
assign eom = (msg_cnt == msg_length_i);

always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai)
        unit_cnt <= 9'b0;
    else if (clear_i || s_idle || (eou && b_valid_i && b_req_i))
        unit_cnt <= 9'b0;
    else if (s_data1 && a_valid_i && a_req)
        unit_cnt <= unit_cnt + 1;
end
assign eou = (unit_cnt == unit_size_i);

always @ (posedge clk_i or negedge reset_nai) begin
    if (!reset_nai)
        i_valid_r <= 1'b0;
    else if (clear_i || s_idle)
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

always @ * begin

    // default values
    a = a_i;
    a_valid = a_valid_i;
    a_req = a_req_i;
    b = b_vec;
    b_valid = b_valid_i;
    b_req = b_req_i;
    key = key_i;
    key_valid = key_valid_i;
    iv_nxt = iv_r;

    case (mode_i)
        `CBC : begin
            a = dir_i ? (a_i ^ (first_msg ? iv_r : b_vec)) : a_i;
            b = dir_i ? b_vec : b_vec ^ iv_r;
            iv_nxt = dir_i ? b_vec : temp;
        end
        `CTR : begin
            a = iv_r;
            b = temp ^ b_vec;
            iv_nxt = iv_unswap;
        end
        `CFB : begin
            a = first_msg ? iv_r : (dir_i ? (temp ^ b_vec) : temp);
            b = temp ^ b_vec;
            iv_nxt = dir_i ? (b_vec ^ temp) : a_i;
        end
        `OFB : begin
            a = first_msg ? iv_r : b_vec;
            b = temp ^ b_vec;
            iv_nxt = b_vec;
        end
        `XTS : begin
            a = s_data0 ? iv_r : temp ^ a_i;
            a_valid = s_data0 ? i_valid_r : (s_data1 ? a_valid_i : 0);
            a_req = s_data1 & a_req_i;
            b = temp_1d ^ b_vec;
            b_valid = s_data1 & b_valid_i;
            key[127:0] = (s_key0 || s_data0) ? key_i[255:128] : key_i[127:0];
            key[255:128] = key_i[255:128];
            key_valid = s_key0 | s_key1;
            iv_nxt = iv_plus_1;
        end
        default : begin // `ECB
            a = a_i;
            a_valid = a_valid_i;
            a_req = a_req_i;
            b = b_vec;
            b_valid = b_valid_i;
            b_req = b_req_i;
            key = key_i;
            key_valid = key_valid_i;
            iv_nxt = iv_r;
        end
    endcase
end

assign a_o = a_state;
assign a_valid_o = a_valid & ~eom;
assign a_req_o = a_req;
assign b_o = b;
assign b_valid_o = b_valid;
assign b_req_o = b_req;
assign key_o = key_state;
assign key_valid_o = key_valid;
assign dir_o = (((mode_i == `XTS) && (s_idle || s_key0 || s_data0)) ||
               (mode_i == `CFB) ||
               (mode_i == `OFB) ||
               (mode_i == `CTR)) ? 1 : dir_i;
assign iv_o = iv_r;

endmodule

