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
// File         : mem_defines.vh
// Description  : RAM-wrapper instantiation parameter defines (depth, width,
//                ECC, erase, parity) for each on-chip memory block.

`ifdef __MEM_DEFINES_VH
`else

`define __MEM_DEFINES_VH


// RAM Wrapper Parameters

// SP_CIRAM0 defines
`define MSFT_SP_CIRAM0_ADDR_WIDTH                                14
`define MSFT_SP_CIRAM0_SIZE                                      262144
`define MSFT_SP_CIRAM0_DATA_WIDTH                                128
`define MSFT_SP_CIRAM0_SUPPORT_SECDED                            1
`define MSFT_SP_CIRAM0_SUPPORT_RMW                               1
`define MSFT_SP_CIRAM0_SUPPORT_INJECT                            1
`define MSFT_SP_CIRAM0_SUPPORT_ERASE                             1
`define MSFT_SP_CIRAM0_SUPPORT_WRITE_BACK                        0
`define MSFT_SP_CIRAM0_RMW_PIPELINE                              0
`define MSFT_SP_CIRAM0_PARITY_EN                                 0
`define MSFT_SP_CIRAM0_ERASE_END_ADDR                            262128
`define MSFT_SP_CIRAM0_ENGN_ERASE_END_ADDR                       262128
`define MSFT_SP_CIRAM0_ERASE_START_ADDR                          0
`define MSFT_SP_CIRAM0_ENGN_ERASE_START_ADDR                     0

`endif //__MEM_DEFINES_VH
