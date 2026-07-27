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
// File        : gpaes_seed_transaction_coverage.svh
// Description : Gpaes Seed Transaction Coverage

`ifndef GPAES_SEED_TRANSACTION_COVERAGE
`define GPAES_SEED_TRANSACTION_COVERAGE

class gpaes_seed_transaction_coverage  extends uvm_subscriber #(.T(gpaes_seed_transaction));

  `uvm_component_utils(gpaes_seed_transaction_coverage)

  T m_coverage_trans;

  gpaes_seed_config cfg;

  extern function new(string name = "", uvm_component parent = null);

  extern virtual function void build_phase(uvm_phase phase);

  extern virtual function void write(T t);

  covergroup gpaes_seed_transaction_cg;
    option.auto_bin_max=1024;
    option.per_instance=1;
    // cp_done: coverpoint m_coverage_trans.m_event {
    //   bins start = { START };
    //   bins done  = { DONE };
    // }
  endgroup : gpaes_seed_transaction_cg

endclass : gpaes_seed_transaction_coverage

function gpaes_seed_transaction_coverage::new(string name = "", uvm_component parent = null);
  super.new(name, parent);
    
  // uvm_config_db #(int)::dump();
    
  if (!uvm_config_db #(gpaes_seed_config)::get(this, "", "cfg", cfg))
    `uvm_fatal("NOCFG",{"config must be set for: ",get_full_name(),".cfg"});

  gpaes_seed_transaction_cg = new();

endfunction : new

function void gpaes_seed_transaction_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);

  gpaes_seed_transaction_cg.set_inst_name($sformatf("gpaes_seed_transaction_cg_%s", get_full_name()));

endfunction : build_phase

function void gpaes_seed_transaction_coverage::write(T t);
  `uvm_info(get_type_name(), "Received transaction", UVM_HIGH)
  m_coverage_trans = t;
  gpaes_seed_transaction_cg.sample(); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE CVED */

endfunction : write

`endif // GPAES_SEED_TRANSACTION_COVERAGE
