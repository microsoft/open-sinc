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
// File        : gpaes_sys_wrapper_environment.svh
// Description : Wrapper for Multiple Gpaesper System UVM Environment

`ifndef GPAES_SYS_WRAPPER_ENVIRONMENT
 `define GPAES_SYS_WRAPPER_ENVIRONMENT

class gpaes_sys_wrapper_environment extends uvmf_environment_base #(
                                                                    .CONFIG_T( gpaes_sys_wrapper_env_configuration
                                                                               ));
  `uvm_component_utils(gpaes_sys_wrapper_environment)

  // monitor analysis ports
  uvm_analysis_port #(gpaes_seed_transaction)   seed_agent_ap[];

  gpaes_sys_wrapper_virtual_sequencer   sys_wrapper_vseqr;

  // GPAES Sys Config Creator
  gpaes_user_config_creator rucc;

  typedef gpaes_sys_env  gpaes_sys_env_t;
  gpaes_sys_env_t m_gpaes_sys_env[$];

  extern function new( string name = "", uvm_component parent = null );
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void set_gpaes_config();
  extern virtual function void configure_gpaes_configs();
  extern virtual function void configure_gpaes_seed_config(gpaes_seed_config seed_cfg);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : gpaes_sys_wrapper_environment

/**
 *
 * @see uvmf_base_pkg::uvmf_environment_base.new
 * @param name - instance name
 * @param parent - parent
 * @return nothing
 */
function gpaes_sys_wrapper_environment::new( string name = "", uvm_component parent = null );
  super.new( name, parent );
endfunction : new

/**
 *
 * @see uvm_pkg::uvm_component.build_phase
 * @param phase - uvm phase
 */
function void gpaes_sys_wrapper_environment::build_phase(uvm_phase phase);
  super.build_phase(phase);

  //generate analysis ports for every master in each gpaes_sys
  for (int sys_num=0; sys_num < configuration.num_gpaes_sys; sys_num++) begin
    
    // Seed agent
    seed_agent_ap = new[configuration.num_gpaes_sys];
    seed_agent_ap[sys_num] = uvm_analysis_port #(gpaes_seed_transaction)::new($sformatf("seed_ap[%0s]", configuration.gpaes_sys_names[sys_num]), this);

  end

  //create each gpaes_sys_env  
  for (int i=0; i < configuration.num_gpaes_sys; i++) begin
    gpaes_sys_env gpaes_sys_env_obj;    
       
    gpaes_sys_env_obj = gpaes_sys_env::type_id::create($sformatf("gpaes_sys_env_%0s", configuration.gpaes_sys_names[i]), this);
    m_gpaes_sys_env.push_back(gpaes_sys_env_obj);
  end


  sys_wrapper_vseqr = gpaes_sys_wrapper_virtual_sequencer::type_id::create("sys_wrapper_vseqr", this);
  sys_wrapper_vseqr.gpaes_sys_vseqr = new[configuration.num_gpaes_sys];

  // Place the Virtual Sequencer handle into the config_db for the top level sequence to retrieve and use when starting GPAES sequences.
  uvm_config_db #(gpaes_sys_wrapper_virtual_sequencer)::set(uvm_root::get(), UVMF_SEQUENCERS, "sys_wrapper_vseqr", sys_wrapper_vseqr);

  set_gpaes_config();

  for (int i=0; i < configuration.num_gpaes_sys; i++) begin
    m_gpaes_sys_env[i].sys_cfg = configuration.gpaes_sys_cfgs[i];
  end

endfunction : build_phase

/**
 * Create GPAES configuration
 */
function void gpaes_sys_wrapper_environment::set_gpaes_config();
  string debug_str = "SET_GPAES_CONFIG";
  string msg_str;
  rucc = gpaes_user_config_creator::type_id::create("rucc");
  for (byte unsigned i=0; i < configuration.num_gpaes_sys; i++) begin
    // configuration.gpaes_sys_cfg[i] = gpaes_sys_config::type_id::create(sys_num.name(), this);
    rucc.configure_user_configs(configuration.gpaes_sys_cfgs[i]);
    configure_gpaes_configs();
    uvm_config_db #(gpaes_sys_config)::set(this, $sformatf("*gpaes_sys_env_%0s", configuration.gpaes_sys_names[i]), "sys_cfg", configuration.gpaes_sys_cfgs[i]);

    msg_str = {"=====================================================\n"};
    msg_str = {msg_str, $sformatf("                GPAES Sys Env Config: [%0d]\n", i)};
    msg_str = {msg_str, $sformatf("=====================================================\n")};
    msg_str = {msg_str, $sformatf(" %s\n", configuration.gpaes_sys_cfgs[i].convert2string())};
    msg_str = {msg_str, $sformatf("=====================================================\n")};
    `uvm_info(debug_str, $sformatf("n%s", msg_str), UVM_LOW)
  end
endfunction : set_gpaes_config

/**
 * Calls Configure_gpaes_aent_config
 */
function void gpaes_sys_wrapper_environment::configure_gpaes_configs();
  foreach (configuration.gpaes_sys_cfgs[i]) begin  
      
    // SEED
    configure_gpaes_seed_config(configuration.gpaes_sys_cfgs[i].seed_agent_cfg);
   
  end
endfunction : configure_gpaes_configs

/**
 * configure_gpaes_agent_config
 *
 * @param agt_cfg - agt_cfg
 */
function void gpaes_sys_wrapper_environment::configure_gpaes_seed_config(gpaes_seed_config seed_cfg);
  //
endfunction : configure_gpaes_seed_config

/**
 *
 * @see uvm_pkg::uvm_component.connect_phase
 * @param phase - uvm phase
 */
function void gpaes_sys_wrapper_environment::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  for (int sys_num=0; sys_num < configuration.num_gpaes_sys; sys_num++) begin   
    // Seed agent
    m_gpaes_sys_env[sys_num].m_gpaes_seed_agent.monitor.item_collected_port.connect(seed_agent_ap[sys_num]);
  end

  for (int i=0; i < configuration.num_gpaes_sys; i++) begin
    sys_wrapper_vseqr.gpaes_sys_vseqr[i] = m_gpaes_sys_env[i].vseqr;
  end

endfunction : connect_phase

`endif // GPAES_SYS_WRAPPER_ENVIRONMENT
