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
// File        : pal_slave_sinc_funcs.svh
// Description : 

`ifndef PAL_SLAVE_UPKA_FUNCS
`define PAL_SLAVE_UPKA_FUNCS

//-----------------------------------------------------------------------------
// Common PAXOS + SNPS section
//-----------------------------------------------------------------------------

//TODO: set up Paxos user params pkg name
`define PAL_USER_PARAMS_PKG pal_user_params_pkg

//-----------------------------------------------------------------------------
// PAXOS specific section
//-----------------------------------------------------------------------------
`ifdef PAL_USE_PAXOS_AXI_SLAVE
//PAL internal Paxos instance to memory path - do not modify
`ifdef SIMULATION
`define PAL_PAXOS_MEM_PATH slave_en_blk.paxos_slave.paxos_slave_active.axi_slave0.memory.mem
`else
`define PAL_PAXOS_MEM_PATH slave_en_blk.paxos_slave.axi_slave0.memory.mem
`endif
//TODO: Implement mem_access_paxos (sys_id/slv_id to read_mem/write_mem call mapping) with
//      actual HDL paths for each slave.
//   Note: the addr argument has already been translated into the appropriate local address
//      and should not be used to determine the slave mapping. Use sys_id/slv_id instead.

//Example implementation
`define PAL_SYS0_HDL_PATH hdl_top.pal_axi_sys_inst
`define PAL_SYS0_SLV0_EN

//Map sys_id + slv_id to the correct Paxos read_mem/write_mem calls
function automatic void mem_access_paxos(
  input int                           sys_id,
        int                           slv_id,
        bit                           is_read,
        bit [`PAL_MAX_ADDR_WIDTH-1:0] addr,
  inout bit [`PAL_MAX_DATA_WIDTH-1:0] data
);
  case(sys_id)
    0: begin
      case(slv_id)
        0: begin
          `ifdef PAL_SYS0_SLV0_EN
          if(is_read)
            data = `PAL_SYS0_HDL_PATH.gen_slaves[0].`PAL_PAXOS_MEM_PATH.read_mem(addr);
          else
            `PAL_SYS0_HDL_PATH.gen_slaves[0].`PAL_PAXOS_MEM_PATH.write_mem(addr, data);
          `else
          $display("%t: ERROR: mem_access_paxos: paxos HDL_PATH not defined for sys_id %d, slv_id %d", $realtime, sys_id, slv_id);
          `endif
        end
        1: begin
          `ifdef PAL_SYS0_SLV1_EN
          if(is_read)
            data = `PAL_SYS0_HDL_PATH.gen_slaves[1].`PAL_PAXOS_MEM_PATH.read_mem(addr);
          else
            `PAL_SYS0_HDL_PATH.gen_slaves[1].`PAL_PAXOS_MEM_PATH.write_mem(addr, data);
          `else
          $display("%t: ERROR: mem_access_paxos: paxos HDL_PATH not defined for sys_id %d, slv_id %d", $realtime, sys_id, slv_id);
          `endif
        end
        //2: etc. (if additional slaves for system 0 exist)
      endcase
    end
    //1: etc. (if additional PAL systems exist)
  endcase
endfunction: mem_access_paxos
`endif

`endif // PAL_SLAVE_UPKA_FUNCS
