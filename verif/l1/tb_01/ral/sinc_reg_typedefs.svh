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
// File        : sinc_reg_typedefs.svh
// Description : 

`ifndef SINC_REG_TYPEDEFS__SVH
`define SINC_REG_TYPEDEFS__SVH


typedef bit [31:0] sinc_reg_addr_t;
// Queue of integers type used as return for functions
typedef sinc_reg_addr_t  sinc_reg_q_addr_t [$];
typedef bit [31:0] sinc_reg_data_t;

// struct of status register
typedef struct {
  bit   busy;
  bit   complete;
  bit   error_cmd;
  bit   error_fault;
  bit   match_sts;
} sinc_status_reg_struct_s;


`endif
