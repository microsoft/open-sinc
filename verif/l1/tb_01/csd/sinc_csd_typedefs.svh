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
// File        : sinc_csd_typedefs.svh
// Description : 

`ifndef SINC_CSD_TYPEDEFS
`define SINC_CSD_TYPEDEFS

typedef bit [31:0] csd_address_t;

/* Word address:
 *
 Address [31:22] = Base addr
 Address [21:14] = Tag
 Address [13:7]  = Set
 Address [6:0]   = Offset
 */
typedef bit [sinc_parameters_pkg::SINC_CACHE_BASE_ADDR_WIDTH - 1:0] sinc_cache_offset_t;
typedef bit [sinc_parameters_pkg::SINC_CACHE_BYTE_OFFSET_WIDTH - 1:0] sinc_cache_byte_offset_t;
typedef bit [sinc_parameters_pkg::SINC_CACHE_SET_WIDTH - 1:0] sinc_cache_set_t;
typedef bit [sinc_parameters_pkg::SINC_CACHE_TAG_WIDTH - 1:0] sinc_cache_tag_t;
typedef bit [1:0] sinc_cache_fifo_idx_t;

typedef bit [sinc_parameters_pkg::SINC_MEM_LINE_WIDTH - 1:0] mem_line_data_t;
typedef mem_line_data_t cache_line_data_t[128];

typedef bit [(sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE * 8) - 1:0] csd_cache_block_t;
typedef bit [(sinc_parameters_pkg::SINC_CACHE_BLOCK_AUTH_TAG_SIZE * 8) - 1:0] csd_auth_tag_t;

`endif // SINC_CSD_TYPEDEFS
