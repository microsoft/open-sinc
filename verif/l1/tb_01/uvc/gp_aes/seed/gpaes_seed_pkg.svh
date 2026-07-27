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
// File        : gpaes_seed_pkg.svh
// Description : MSFT Protocol Abstraction Layer Package

`ifndef GPAES_SEED_PKG
`define GPAES_SEED_PKG

package gpaes_seed_pkg;

  import uvm_pkg::*;
  import uvmf_base_pkg_hdl::*;
  import uvmf_base_pkg::*;
  import gpaes_agent_config_pkg::*;
  import gpaes_seed_params_pkg::*;

`include "uvm_macros.svh"

`include "gpaes_seed_typedef.svh"
`include "gpaes_seed_transaction.svh"
`include "gpaes_seed_transaction_coverage.svh"

`include "gpaes_seed_sequencer.svh"
`include "gpaes_seed_driver.svh"
`include "gpaes_seed_monitor.svh"
`include "gpaes_seed_config.svh"

`include "gpaes_seed_base_sequence.svh"
`include "gpaes_seed_random_sequence.svh"
`include "gpaes_seed_agent.svh"

endpackage : gpaes_seed_pkg

`endif // GPAES_SEED_PKG
