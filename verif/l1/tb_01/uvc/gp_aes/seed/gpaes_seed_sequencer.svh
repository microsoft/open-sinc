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
// File        : gpaes_seed_sequencer.svh
// Description : Gpaes Seed Sequencer.

`ifndef GPAES_SEED_SEQUENCER_SVH
`define GPAES_SEED_SEQUENCER_SVH


class gpaes_seed_sequencer extends uvm_sequencer #(gpaes_seed_transaction);

    `uvm_component_utils(gpaes_seed_sequencer)
  
    // gpaes_seed config
    protected gpaes_seed_config         cfg;
  
    function new(string name, uvm_component parent);
        super.new(name, parent);    
    endfunction: new
  
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(gpaes_seed_config)::get(this, "", "cfg", cfg)) begin
             `uvm_fatal("NOCFG",{"config must be set for: ",get_full_name(),".cfg"});
        end
    endfunction: build_phase
  
    function gpaes_seed_config get_cfg();
        return cfg;
    endfunction : get_cfg

endclass : gpaes_seed_sequencer

`endif  //GPAES_SEED_SEQUENCER_SVH


