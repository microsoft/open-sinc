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
// File         : hsp_axi.vh
// Description  : AXI bus interface defines and master/slave ID assignments
//                for the HSP subsystem.

`ifdef __HSP_AXI_VH
`else

`define __HSP_AXI_VH

`define HSP_AXI_LOCK_BITS 1

//Custom Manager ID Fields
//Defines AxUSER[11:8] bits for each manager
`define AXI_MST_ID_SP       4'h0
`define AXI_MST_ID_SINC     4'h7

//AxUSER[11:8] represents the manager ID bits
`define AXI_USER_MID_LOCATION   11:8
`define AXI_USER_MID_WIDTH      4

//Manager ID Width Set
`define MSFT_AXI_PARITY_EN 0
`define HSP_AXI_MST_ID_WIDTH 1 //`AXI_IDW_M1
`define HSP_AXI_MST_AWIDTH 32 //`AXI_AW
`define HSP_AXI_MST_DWIDTH 32 //`AXI_DW
`define HSP_AXI_MST_WSTRB_WIDTH (`HSP_AXI_MST_DWIDTH/8)
`define MSFT_AXI_MST_ENGNU_WIDTH 12 // Represents the width of the AxUSER bits passed from the engine (does not include parity info)
`define MSFT_AXI_MST_ARU_WIDTH (`MSFT_AXI_MST_ENGNU_WIDTH )
`define MSFT_AXI_MST_AWU_WIDTH (`MSFT_AXI_MST_ENGNU_WIDTH )
`define MSFT_AXI_MST_WU_WIDTH (`MSFT_AXI_MST_ENGNU_WIDTH)
`define MSFT_AXI_MST_RU_WIDTH (`MSFT_AXI_MST_ENGNU_WIDTH)
`define MSFT_AXI_MST_BU_WIDTH `MSFT_AXI_MST_ENGNU_WIDTH
`define HSP_AXI_MID_WIDTH 4 //Doesn't seem to be used in the RTL, does get used in the HSSHA TB though

//Subordinate ID Width Set
`define HSP_AXI_SLV_ID_WIDTH 4 //`AXI_SIDW
`define HSP_AXI_SLV_AWIDTH `HSP_AXI_MST_AWIDTH
`define HSP_AXI_SLV_DWIDTH `HSP_AXI_MST_DWIDTH
`define HSP_AXI_SLV_WSTRB_WIDTH  `HSP_AXI_MST_WSTRB_WIDTH
`define MSFT_AXI_SLV_ENGNU_WIDTH `MSFT_AXI_MST_ENGNU_WIDTH
`define MSFT_AXI_SLV_ARU_WIDTH `MSFT_AXI_MST_ARU_WIDTH
`define MSFT_AXI_SLV_AWU_WIDTH `MSFT_AXI_MST_AWU_WIDTH
`define MSFT_AXI_SLV_WU_WIDTH `MSFT_AXI_MST_WU_WIDTH
`define MSFT_AXI_SLV_RU_WIDTH `MSFT_AXI_MST_RU_WIDTH
`define MSFT_AXI_SLV_BU_WIDTH `MSFT_AXI_MST_BU_WIDTH


// ALEN Encoding
`define AXI_ALEN_WIDTH 8

// ABURST Encoding
`define AXI_ABURST_FIXED      2'b00
`define AXI_ABURST_INCR       2'b01

// RRESP / BRESP Encoding
`define HSP_AXI_RESP_OKAY     2'b00
`define HSP_AXI_RESP_SLVERR   2'b10
`define HSP_AXI_RESP_DECERR   2'b11


`endif //__HSP_AXI_VH

