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
// File        : gpaes_sys_wrapper_env_configuration.svh
// Description : Gpaesper SYS Environment configuration

`ifndef GPAES_SYS_WRAPPER_ENV_CONFIGURATION
`define GPAES_SYS_WRAPPER_ENV_CONFIGURATION

class gpaes_sys_wrapper_env_configuration extends uvmf_environment_configuration_base;

  `uvm_object_utils(gpaes_sys_wrapper_env_configuration)
  
  gpaes_sys_config gpaes_sys_cfgs[$];
  bit              gpaes_sys_env_en[$];
  int unsigned     num_gpaes_sys;
  string           gpaes_sys_names[$];

  extern function new( string name = "" );
  extern function void post_randomize();
  extern virtual function string convert2string();
  extern virtual function void initialize(uvmf_sim_level_t sim_level, string environment_path, string interface_names[], uvm_reg_block register_model = null, uvmf_active_passive_t interface_activity[] = {});

endclass : gpaes_sys_wrapper_env_configuration

/**
 *
 * @see uvmf_base_pkg::uvmf_environment_configuration_base.new
 * @param name - instance name
 * @return nothing
 */
function gpaes_sys_wrapper_env_configuration::new( string name = "" );
    super.new( name );
endfunction : new

/**
 *
 * @see uvmf_base_pkg::uvmf_environment_configuration_base.new
 * @param name - instance name
 * @return nothing
 */
function void gpaes_sys_wrapper_env_configuration::post_randomize();
    super.post_randomize();
endfunction : post_randomize

/**
 *
 * @see uvmf_base_pkg::uvmf_environment_configuration_base.post_randomize
 */
function string gpaes_sys_wrapper_env_configuration::convert2string();
    string result = "";
    return (result);
endfunction : convert2string

/**
 *
 * @see uvmf_base_pkg::uvmf_environment_configuration_base.initialize
 * @param sim_level - sim_level
 * @param environment_path - environment_path
 * @param interface_names - interface_names
 * @param register_model - register_model
 * @param interface_activity - interface_activity
 */
function void gpaes_sys_wrapper_env_configuration::initialize(uvmf_sim_level_t sim_level,
        string environment_path,
        string interface_names[],
        uvm_reg_block register_model = null,
        uvmf_active_passive_t interface_activity[] = {}
    );

  // gpaes_sys_cfgs = new[num_gpaes_sys];
  for (int i=0; i<num_gpaes_sys; i++) begin
    if (gpaes_sys_cfgs[i] == null) begin
        gpaes_sys_config gpaes_sys_config_obj;
        
        gpaes_sys_config_obj = gpaes_sys_config::type_id::create(gpaes_sys_names[i]);        
        
        gpaes_sys_cfgs.push_back(gpaes_sys_config_obj);        
       `uvm_info("GPAES_SYS_WRAPPER_ENV_CONFIGURATION:", $sformatf("Create gpaes_sys_cfg - id[%0d], name[%0s] ", i, gpaes_sys_names[i]), UVM_HIGH)       
    end
  end

  // gpaes_sys_env_en = new[num_gpaes_sys];
  
  super.initialize(sim_level, environment_path, interface_names, register_model, interface_activity);

endfunction : initialize

`endif // GPAES_SYS_WRAPPER_ENV_CONFIGURATION
