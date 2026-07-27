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
// File        : gpaes_seed_agent.svh
// Description : Ramwrap Erase Agent

`ifndef GPAES_SEED_AGENT
`define GPAES_SEED_AGENT

class gpaes_seed_agent extends uvm_agent;

  protected int agent_id;
  protected gpaes_seed_config cfg;

  gpaes_seed_driver driver;
  gpaes_seed_sequencer sequencer;
  gpaes_seed_monitor monitor;
  gpaes_seed_transaction_coverage coverage;
  
  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils_begin(gpaes_seed_agent)
    `uvm_field_int(agent_id, UVM_DEFAULT)
  `uvm_component_utils_end

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  //Override get_is_active to return the value from the agent config
  virtual function uvm_active_passive_enum get_is_active();
    return uvm_active_passive_enum'(cfg.is_active);
  endfunction : get_is_active

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db #(gpaes_seed_config)::get(this, "", "cfg", cfg))
       `uvm_fatal("NOCFG",{"config must be set for: ",get_full_name(),".cfg"});
    
    monitor = gpaes_seed_monitor::type_id::create("monitor", this);

    if(get_is_active() == UVM_ACTIVE) begin
      sequencer = gpaes_seed_sequencer::type_id::create("sequencer", this);
      driver = gpaes_seed_driver::type_id::create("driver", this);
      cfg.m_sequencer = sequencer;
    end

    // Coverage component
    // Construct a coverage collector if configured to do so
    if (cfg.has_coverage) begin 
      coverage = gpaes_seed_transaction_coverage::type_id::create({cfg.agent_name,"_coverage"},this);
    end

  endfunction : build_phase

  // connect_phase
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.rsp_port.connect(sequencer.rsp_export);
    end

    if (cfg.has_coverage) begin
       monitor.item_collected_port.connect(coverage.analysis_export);
     end
  endfunction : connect_phase

  virtual task pre_reset_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      sequencer.stop_sequences();
      ->driver.reset_driver;
    end
  endtask : pre_reset_phase

  virtual function gpaes_seed_config get_cfg();
    return cfg;
  endfunction : get_cfg
  
  virtual function void suppress_error();
    cfg.suppress_error = 1;
  endfunction : suppress_error
  

endclass : gpaes_seed_agent

`endif // GPAES_SEED_AGENT
