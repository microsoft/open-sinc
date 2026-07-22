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
// File        : gpaes_sys_user_config_creator.sv
// Description : Protocol Abstraction Layer System

`ifndef GPAES_USER_CONFIG_CREATOR__SV
 `define GPAES_USER_CONFIG_CREATOR__SV

class gpaes_user_config_creator extends uvm_transaction;

  //Register with factory
  `uvm_object_utils(gpaes_user_config_creator)

  bit                         enable_trans_log = 0;

  extern function new(string name = "gpaes_user_config_creator");
  extern function void configure_user_configs(gpaes_sys_config sys_cfg);
  extern function void check_user_config(gpaes_sys_config sys_cfg);

endclass : gpaes_user_config_creator

function gpaes_user_config_creator::new(string name = "gpaes_user_config_creator");
  super.new(name);
  if ($value$plusargs("GPAES_EN_TRANS_LOG=%d", enable_trans_log)) begin
    if (enable_trans_log == 1)
      `uvm_info(get_full_name(), $sformatf("User has specified plusarg Override GPAES_EN_TRANS_LOG=%d; hence enabled GPAES trans log generation.", enable_trans_log), UVM_MEDIUM)
    else
      `uvm_info(get_full_name(), $sformatf("User has specified plusarg Override GPAES_EN_TRANS_LOG=%d; hence disabled GPAES trans log generation.", enable_trans_log), UVM_MEDIUM)
  end else begin
    if (!enable_trans_log)
      `uvm_info(get_full_name(), $sformatf("GPAES trans log generation is disabled by default; please use +GPAES_EN_TRANS_LOG=1 to enable this, if needed."), UVM_MEDIUM)
  end
endfunction : new

function void gpaes_user_config_creator::check_user_config(gpaes_sys_config sys_cfg);

  // Seed agent
  if(sys_cfg.seed_agent_cfg.m_seed_data_width > `GPAES_MAX_SEED_DATA_WIDTH) begin
    `uvm_fatal(get_full_name(), $sformatf("Configured data_width = %0d is bigger than the GPAES_MAX_DATA_WIDTH = %0d in seed_agent which is  \"%s\" in GPAES_SYSTEM \"%s\"",sys_cfg.seed_agent_cfg.m_seed_data_width,`GPAES_MAX_SEED_DATA_WIDTH,sys_cfg.seed_agent_cfg.agent_name, sys_cfg.sys_name))
  end  

endfunction : check_user_config

function void gpaes_user_config_creator::configure_user_configs(gpaes_sys_config sys_cfg);
  // sys_cfg.hdl_path                 = sys_params.hdl_path;
  // sys_cfg.sys_name                 = sys_params.sys_name;

  sys_cfg.create_agent_configs(sys_cfg.sys_name);

  // Seed agent Start
  sys_cfg.seed_agent_en                = sys_cfg.seed_agent_en;  

  sys_cfg.seed_agent_cfg.enable_trans_log         = this.enable_trans_log;
  
  sys_cfg.seed_agent_cfg.agent_en                 = sys_cfg.seed_agent_en;
  sys_cfg.seed_agent_cfg.agent_num                = sys_cfg.sys_wrapper_id;
  sys_cfg.seed_agent_cfg.agent_name               = $sformatf("%s_seed_agent", sys_cfg.sys_name);
  sys_cfg.seed_agent_cfg.sys_name                 = sys_cfg.sys_name;
  sys_cfg.seed_agent_cfg.is_active                = sys_cfg.seed_agent_is_active;
  // sys_cfg.seed_agents_cfg.m_seed_data_width        = sys_params.seed_params.seed_data_width;

  // //dyn_params are set based on test YML plusargs
  // sys_cfg.seed_agents_cfg.set_dyn_params();
  sys_cfg.seed_agent_cfg.initialize(sys_cfg.seed_agent_cfg.is_active, $sformatf("%s.gpaes_seed_agent", sys_cfg.uvm_path));
    
  // Seed agent End  

  this.check_user_config(sys_cfg);

endfunction : configure_user_configs

`endif //GPAES_USER_CONFIG_CREATOR__SV

