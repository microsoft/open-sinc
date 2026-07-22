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
// File        : peek_poke.sv
// Description : 

`include "uvm_macros.svh"

`define PEEK_POKE_HDL_PATH hdl_top.peek_poke

// DMB
`define PAL_SYS0_SLV0_BASE_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[0].start_addr
`define PAL_SYS0_SLV0_MAX_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[0].end_addr

// RNG
`define PAL_SYS0_SLV1_BASE_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[1].start_addr
`define PAL_SYS0_SLV1_MAX_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[1].end_addr

// KSU
`define PAL_SYS0_SLV2_BASE_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[2].start_addr
`define PAL_SYS0_SLV2_MAX_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[2].end_addr

// SHAREDRAM
`define PAL_SYS0_SLV3_BASE_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[3].start_addr
`define PAL_SYS0_SLV3_MAX_ADDR pal_user_params_pkg::pal_sys_params[0].slave_params[0].region_params[3].end_addr

module peek_poke;

  function static bit addr_decode(input bit [63:0] Addr, output int target_id);
    if (( (Addr >= `PAL_SYS0_SLV0_BASE_ADDR) && (Addr <= `PAL_SYS0_SLV0_MAX_ADDR) ) ||
        ( (Addr >= `PAL_SYS0_SLV1_BASE_ADDR) && (Addr <= `PAL_SYS0_SLV1_MAX_ADDR) ) ||
        ( (Addr >= `PAL_SYS0_SLV2_BASE_ADDR) && (Addr <= `PAL_SYS0_SLV2_MAX_ADDR) ) ||
        ( (Addr >= `PAL_SYS0_SLV3_BASE_ADDR) && (Addr <= `PAL_SYS0_SLV3_MAX_ADDR) )) begin
      target_id = 0;

      return (1);
    end
    return (0);
  endfunction: addr_decode

  //Backdoor memory read access
  function static int peek_mem (input bit [63:0] Addr, inout int unsigned Data);
    byte temp_data[4];
    int result;
    result = peek_mem_bytes(Addr, temp_data);
    Data     = {temp_data[3], temp_data[2], temp_data[1], temp_data[0]};
    return (result);
  endfunction : peek_mem

  //Backdoor memory write access
  function static int poke_mem (input bit [63:0] Addr, input int unsigned Data);
    byte temp_data[4];
    {temp_data[3], temp_data[2], temp_data[1], temp_data[0]} = Data;
    return (poke_mem_bytes(Addr, temp_data));
  endfunction : poke_mem

  function static int peek_mem_bytes(input bit [63:0] Addr, inout byte Data[]);
    int target_id;
    if(addr_decode(Addr, target_id)) begin
      case(target_id)
        0: return (peek_pal_slave_bytes(.sys_id(0), .slv_id(0), .Addr(Addr), .Data(Data)));
        default: return (0);
      endcase
    end else begin
      `uvm_error("PEEK_POKE",  $sformatf("ERROR (peek_poke.sv): peek addr of 0x%0x is invalid", Addr))
    end
    return (0);
  endfunction : peek_mem_bytes

  function static int poke_mem_bytes(input bit [63:0] Addr, input byte Data[]);
    int target_id;
    if(addr_decode(Addr, target_id)) begin
      case(target_id)
        0: return (poke_pal_slave_bytes(.sys_id(0), .slv_id(0), .Addr(Addr), .Data(Data)));
        default: return (0);
      endcase
    end else begin
      `uvm_error("PEEK_POKE", $sformatf("ERROR (peek_poke.sv): poke addr of 'h%0h is invalid", Addr))
    end
    return (0);
  endfunction : poke_mem_bytes

  `include "pal_slave_sinc_funcs.svh"
  `include "pal_slave_funcs.vh"
endmodule : peek_poke
