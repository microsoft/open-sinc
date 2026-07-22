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
// File        : sinc_01_vtag_ram_wrap.sv
// Description : 


`include "hsp_defines.vh"
`include "mem_defines.vh"
`include "msft_glbl_defs.vh"

module sinc_vtag_ram_wrap (
  // inputs
  input  logic                                          clk,
  input  logic [3:0]                                    en,
  input  logic [`MSFT_SINC_VTAG0_ADDR_WIDTH-1:0]        addr,
  input  logic [`MEM_CTRL_WIDTH-1:0]                    mem_ctrl,
  input  logic                                          rstn,
  input  logic                                          pg_ret,
  input  logic                                          pg_sd,
  input  logic                                          pg_ds,
  input  logic [3:0]                                    wr_en,
  input  logic [`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH-1:0] wr_data,
  // outputs
  output logic [`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH-1:0] rd_data
);

  parameter INIT_FILE = "";

  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] rd_data0;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] wr_data0;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] rd_data1;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] wr_data1;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] rd_data2;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] wr_data2;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] rd_data3;
  logic [(`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH/4)-1:0] wr_data3;

  logic rst;

  msftDvIp_fpga_ram #(
    .RAM_WIDTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_WIDTH/4),
    .RAM_DEPTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_DEPTH  ),
    .RAM_BACK_DOOR_ENABLE (0                                               )
  ) mem_wrap0 (
    // Outputs
    .dout (rd_data0),

    // Inputs
    .clk  (clk     ),
    .cs   (en[0]   ),
    // .RST            (rst),
    .we   (wr_en[0]),
    // .MEM_POWER_CTRL (MEM_CTRL[`MEM_CTRL_WIDTH-1:0]),
    .addr (addr    ),
    .din  (wr_data0));

  msftDvIp_fpga_ram #(
    .RAM_WIDTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_WIDTH/4),
    .RAM_DEPTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_DEPTH  ),
    .RAM_BACK_DOOR_ENABLE (0                                               )
  ) mem_wrap1 (
    // Outputs
    .dout (rd_data1),

    // Inputs
    .clk  (clk     ),
    .cs   (en[1]   ),
    // .RST            (rst),
    .we   (wr_en[1]),
    // .MEM_POWER_CTRL (MEM_CTRL[`MEM_CTRL_WIDTH-1:0]),
    .addr (addr    ),
    .din  (wr_data1));

  msftDvIp_fpga_ram #(
    .RAM_WIDTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_WIDTH/4),
    .RAM_DEPTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_DEPTH  ),
    .RAM_BACK_DOOR_ENABLE (0                                               )
  ) mem_wrap2 (
    // Outputs
    .dout (rd_data2),

    // Inputs
    .clk  (clk     ),
    .cs   (en[2]   ),
    // .RST            (RST),
    .we   (wr_en[2]),
    // .MEM_POWER_CTRL (MEM_CTRL[`MEM_CTRL_WIDTH-1:0]),
    .addr (addr    ),
    .din  (wr_data2));

  msftDvIp_fpga_ram #(
    .RAM_WIDTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_WIDTH/4),
    .RAM_DEPTH            (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_DEPTH  ),
    .RAM_BACK_DOOR_ENABLE (0                                               )
  ) mem_wrap3 (
    // Outputs
    .dout (rd_data3),

    // Inputs
    .clk  (clk     ),
    .cs   (en[3]   ),
    // .RST            (rst),
    .we   (wr_en[3]),
    // .MEM_POWER_CTRL (MEM_CTRL[`MEM_CTRL_WIDTH-1:0]),
    .addr (addr    ),
    .din  (wr_data3));

  assign rd_data                                  = {rd_data3, rd_data2, rd_data1, rd_data0};
  assign {wr_data3, wr_data2, wr_data1, wr_data0} = wr_data;

endmodule : sinc_vtag_ram_wrap
