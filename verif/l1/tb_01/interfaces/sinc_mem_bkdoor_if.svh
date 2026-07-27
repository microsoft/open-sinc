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
// File        : sinc_mem_bkdoor_if.svh
// Description : 

`ifndef SINC_MEM_BKDOOR_IF
`define SINC_MEM_BKDOOR_IF

`include "uvm_macros.svh"


interface sinc_mem_bkdoor_if
  import uvm_pkg::*;
  import sinc_parameters_pkg::*;
  import sinc_env_pkg::*;
(
   input  logic clk,
   input  logic resetn
);

  function static cache_mem_w_ecc_t cache_mem_read (input int mem_addr);
    cache_mem_w_ecc_t orig_data;

    `uvm_info("CACHE_MEM_BKDOOR_IF", $sformatf("Cache original data, mem_addr[%0d] = 'h%0h ", mem_addr, `SINC_TB_TOP.cache_sram.ram[mem_addr]), UVM_HIGH)

    orig_data = `SINC_TB_TOP.cache_sram.ram[mem_addr];

    return(orig_data);

  endfunction : cache_mem_read


endinterface : sinc_mem_bkdoor_if

`endif // SINC_MEM_BKDOOR_IF
