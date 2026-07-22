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
// File        : sinc_parameters_pkg.sv
// Description : This package contains test level parameters

`ifndef SINC_PARAMETERS_PKG
`define SINC_PARAMETERS_PKG

package sinc_parameters_pkg;

  import uvmf_base_pkg_hdl::*;

  // pragma uvmf custom package_imports_additional begin
  //      as many things are done for HSP here
  //---------------------------------------------------
  `include "hsp_axi.vh"
  `include "hsp_memmap.vh"
  `include "hsp_top.vh"

  // pragma uvmf custom package_imports_additional end
  parameter SINC_CACHE_MEM_RAM_WIDTH = 156;
  parameter SINC_CACHE_MEM_RAM_DEPTH = 16384;

  parameter SINC_CACHE_VTAG_RAM_WIDTH = 40;
  parameter SINC_CACHE_VTAG_RAM_DEPTH = 128;

  parameter KEY_MEM_START_ADDR           = 32'h8000_0000;
  parameter KEY_MEM_END_ADDR             = 32'h81FF_FFFF;
  parameter LUT_MEM_START_ADDR           = 32'h8F10_0000;
  parameter LUT_MEM_END_ADDR             = 32'h8F10_7FFF;
  parameter KEY_VAULT_REG_START_ADDR     = 32'h8F11_0000;
  parameter RESERVED_REGION_0_START_ADDR = 32'h8200_0000;
  parameter RESERVED_REGION_0_END_ADDR   = 32'h8F0A_FFFF;
  parameter RESERVED_REGION_1_START_ADDR = 32'h8F10_8000;
  parameter RESERVED_REGION_1_END_ADDR   = 32'h8F10_FFFF;
  parameter RESERVED_REGION_2_START_ADDR = 32'h8F11_0400;
  parameter RESERVED_REGION_2_END_ADDR   = 32'h8F1F_FFFF;
  parameter AXI_MST_ID_AXUSER_MSB        = 11;
  parameter AXI_MST_ID_AXUSER_LSB        = 8;
  parameter SP_MST_ID                    = 0;
  parameter AES_MST_ID                   = 1;
  parameter SHA_MST_ID                   = 2;
  parameter UPKA_MST_ID                  = 3;
  parameter CDED_MST_ID                  = '32hDEAD_BEAF;

  parameter LUT_RAM_WIDTH            = 38;
  parameter LUT_RAM_DEPTH            = 4095;
  parameter LUT_RAM_BACK_DOOR_ENABLE = 0;

  parameter KEY_RAM_WIDTH            = 38;
  parameter KEY_RAM_DEPTH            = 65535;
  parameter KEY_RAM_BACK_DOOR_ENABLE = 0;

endpackage : sinc_parameters_pkg

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_PARAMETERS_PKG
