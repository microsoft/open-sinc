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
// File        : gpaes_agent_config_pkg.svh
// Description : MSFT Protocol Abstraction Layer Package

`ifndef GPAES_AGENT_CONFIG_PKG__SVH
`define GPAES_AGENT_CONFIG_PKG__SVH

package gpaes_agent_config_pkg;

`timescale 1ps/1ps

  import uvm_pkg::*;
  import uvmf_base_pkg_hdl::*;
  import uvmf_base_pkg::*;

`include "uvm_macros.svh"
`include "gpaes_agent_config_typedef.svh"
`include "gpaes_agent_config.svh"
`include "gpaes_packet_config.svh"
  
endpackage // gpaes_agent_config_pkg
  
`endif //GPAES_AGENT_CONFIG_PKG__SVH


