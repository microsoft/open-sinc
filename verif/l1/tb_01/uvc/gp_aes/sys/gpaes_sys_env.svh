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
// File        : gpaes_sys_env.svh
// Description : Protocol Abstraction Layer System UVM Environment

`ifndef GPAES_SYS_ENV__SVH
`define GPAES_SYS_ENV__SVH

class gpaes_sys_env extends uvm_env;

  // Configuration
  gpaes_sys_config sys_cfg;

  // Virtual Sequencer
  gpaes_sys_virtual_sequencer vseqr;


  // GPAES_SYS Seed Agents
  gpaes_seed_agent             m_gpaes_seed_agent;
  gpaes_seed_config            m_gpaes_seed_agent_cfg;

  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils_begin(gpaes_sys_env)
  `uvm_component_utils_end

  // new - constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new


  function string get_mem_init();
    string meminit;
    if($value$plusargs("GPAES_SYS_MEM_INIT=%s", meminit)) begin
      `uvm_info(get_type_name(), $sformatf("Plusarg Override for GPAES_SYS_MEM_INIT:%s", meminit), UVM_MEDIUM)
    end else begin
      meminit = "ADDRESS";
    end
    return meminit;
  endfunction

  // build_phase
  function void build_phase(uvm_phase phase);
    string inst_name;
    byte unsigned num_seed_agents;

    //byte unsigned num_slaves;
    super.build_phase(phase);

    //Get the config object
    // uvm_config_db #(int)::dump();
    if (!uvm_config_db #(gpaes_sys_config)::get(this, "", "sys_cfg", sys_cfg))
      `uvm_fatal("NOCFG",{"config must be set for: ",get_full_name(),".sys_cfg"});

    // Virtual Sequencer
    uvm_config_db #(gpaes_sys_config)::set(this, "vseqr", "sys_cfg", sys_cfg);
    vseqr = gpaes_sys_virtual_sequencer::type_id::create("vseqr", this);

    // Seed agent Start
    m_gpaes_seed_agent_cfg = this.sys_cfg.seed_agent_cfg;
    
    // Create GPAES_SYS Seed Agents
    if (m_gpaes_seed_agent_cfg.agent_en) begin
      $sformat(inst_name, "gpaes_seed_agent");
      // Get the GPAES_SYS configs from the environment config and
      // assign them to the respective masters.
      uvm_config_db#(gpaes_seed_config)::set(this,$sformatf("%s",inst_name),"cfg", m_gpaes_seed_agent_cfg);
      uvm_config_db#(gpaes_seed_config)::set(this,$sformatf("%s.*",inst_name),"cfg", m_gpaes_seed_agent_cfg);
      uvm_config_db#(gpaes_sys_config)::set(this,$sformatf("%s.*",inst_name), "sys_cfg", sys_cfg);
      uvm_config_db#(gpaes_packet_config)::set(this,$sformatf("%s.*",inst_name), "sys_gpaes_packet_cfg", sys_cfg.active_gpaes_packet_config); 
        
      m_gpaes_seed_agent = gpaes_seed_agent::type_id::create(inst_name, this);
     
    end
    // Seed agent End
    

  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    shortint snpsm_idx;
    shortint snpss_idx;
    string meminit;
    byte tdata;
    meminit = get_mem_init();

    // Seed agent
    vseqr.gpaes_seed_agent_seqr = m_gpaes_seed_agent.sequencer;    

  endfunction : connect_phase

  //Synopsys callbacks for address/data beat monitoring
  virtual function void start_of_simulation_phase(uvm_phase phase);
    shortint snpsm_idx;
    shortint snpss_idx;
    super.start_of_simulation_phase(phase);

  endfunction: start_of_simulation_phase

endclass : gpaes_sys_env

`endif //GPAES_SYS_ENV__SVH
