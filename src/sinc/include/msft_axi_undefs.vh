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
// File         : msft_axi_undefs.vh
// Description  : `undef counterpart to hsp_axi.vh; clears all AXI-related
//                macros so they can be safely redefined elsewhere.

`ifdef __HSP_AXI_VH
`else

`undef __HSP_AXI_VH

`undef HSP_AXI_LOCK_BITS

//Custom Manager ID Fields
//Defines AxUSER[11:8] bits for each manager
`undef AXI_MST_ID_SP
`undef AXI_MST_ID_SINC

//AxUSER[11:8] represents the manager ID bits
`undef AXI_USER_MID_LOCATION
`undef AXI_USER_MID_WIDTH

//Manager ID Width Set
`undef MSFT_AXI_PARITY_EN
`undef HSP_AXI_MST_ID_WIDTH
`undef HSP_AXI_MST_AWIDTH
`undef HSP_AXI_MST_DWIDTH
`undef HSP_AXI_MST_WSTRB_WIDTH
`undef MSFT_AXI_MST_ENGNU_WIDTH
`undef MSFT_AXI_MST_ARU_WIDTH
`undef MSFT_AXI_MST_AWU_WIDTH
`undef MSFT_AXI_MST_WU_WIDTH
`undef MSFT_AXI_MST_RU_WIDTH
`undef MSFT_AXI_MST_BU_WIDTH
`undef HSP_AXI_MID_WIDTH

//Subordinate ID Width Set
`undef HSP_AXI_SLV_ID_WIDTH
`undef HSP_AXI_SLV_AWIDTH
`undef HSP_AXI_SLV_DWIDTH
`undef HSP_AXI_SLV_WSTRB_WIDTH
`undef MSFT_AXI_SLV_ENGNU_WIDTH
`undef MSFT_AXI_SLV_ARU_WIDTH
`undef MSFT_AXI_SLV_AWU_WIDTH
`undef MSFT_AXI_SLV_WU_WIDTH
`undef MSFT_AXI_SLV_RU_WIDTH
`undef MSFT_AXI_SLV_BU_WIDTH


// ALEN Encoding
`undef AXI_ALEN_WIDTH

// ABURST Encoding
`undef AXI_ABURST_FIXED
`undef AXI_ABURST_INCR

// RRESP / BRESP Encoding
`undef HSP_AXI_RESP_OKAY
`undef HSP_AXI_RESP_SLVERR
`undef HSP_AXI_RESP_DECERR


`endif //__HSP_AXI_VH

