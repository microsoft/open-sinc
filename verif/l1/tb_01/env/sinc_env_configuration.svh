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
// File        : sinc_env_configuration.svh
// Description : THis is the configuration for the sinc environment.

`ifndef SINC_ENV_CONFIGURATION
`define SINC_ENV_CONFIGURATION
/**
 * SINC Environment Configuration
 */
class sinc_env_configuration extends ip_base_env_configuration;

  sinc_regmodel          m_regmodel;
  sinc_virtual_sequencer m_vseqr;

  // TB Configs
  sinc_sys_cfg m_sys_cfg;

  // add virtual interface here
  typedef virtual interface sinc_v_if sinc_v_if_t;
  sinc_v_if_t m_sinc_vif;

  typedef virtual sinc_mem_bkdoor_if sinc_mem_bkdoor_if_t;
  sinc_mem_bkdoor_if_t m_mem_bkdoor_if;

  // RamWrapper SYS Wrapper Environment
  typedef ramwrap_sys_wrapper_env_configuration ramwrap_sys_wrapper_env_config_t;
  ramwrap_sys_wrapper_env_config_t m_ramwrap_sys_wrapper_env_config;

  string                m_ramwrap_sys_wrapper_env_interface_names[];
  uvmf_active_passive_t m_ramwrap_sys_wrapper_env_interface_activity[];


  // GPAES SYS Wrapper Environment
  typedef gpaes_sys_wrapper_env_configuration gpaes_sys_wrapper_env_config_t;
  gpaes_sys_wrapper_env_config_t m_gpaes_sys_wrapper_env_config;

  string                m_gpaes_sys_wrapper_env_interface_names[];
  uvmf_active_passive_t m_gpaes_sys_wrapper_env_interface_activity[];

  // Ccpuiper SYS Wrapper Environment
  typedef ccpui_sys_wrapper_env_configuration ccpui_sys_wrapper_env_config_t;
  ccpui_sys_wrapper_env_config_t m_ccpui_sys_wrapper_env_config;

  // CSD
  typedef sinc_csd sinc_csd_t;
  sinc_csd_t m_csd;

  // MEM Error Injection start and end event
  uvm_event#() m_mem_err_inj_event;

  string                m_ccpui_sys_wrapper_env_interface_names[];
  uvmf_active_passive_t m_ccpui_sys_wrapper_env_interface_activity[];

  `uvm_object_utils_begin(sinc_env_configuration)
    `uvm_field_object (m_regmodel ,       UVM_DEFAULT)
    `uvm_field_object (m_clk_env_config , UVM_DEFAULT)
    `uvm_field_object (m_rst_env_config , UVM_DEFAULT)
  `uvm_object_utils_end

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  // Constructs the configuration object for each agent in the environment.
  //
  function new( string name = "" );
    super.new( name );
    process_plusargs();
    sinc_configuration_cg          = new();
    m_ramwrap_sys_wrapper_env_config = ramwrap_sys_wrapper_env_config_t::type_id::create("ramwrap_sys_wrapper_env_config");      
    
    if(uvm_config_db#(gpaes_sys_wrapper_env_configuration)::get(null, "","gpaes_sys_wrapper_env_config_0", m_gpaes_sys_wrapper_env_config)) begin
      `uvm_info(get_name(), "Retrived gpaes_sys_wrapper_env_config from uvm_config_db", UVM_LOW)
    end else begin
       m_gpaes_sys_wrapper_env_config   = gpaes_sys_wrapper_env_config_t::type_id::create("gpaes_sys_wrapper_env_config");
       uvm_config_db#(gpaes_sys_wrapper_env_configuration)::set(uvm_root::get(), "*", "gpaes_sys_wrapper_env_config_0", m_gpaes_sys_wrapper_env_config); 
    end
    
    m_ccpui_sys_wrapper_env_config   = ccpui_sys_wrapper_env_config_t::type_id::create("ccpui_sys_wrapper_env_config");
    m_mem_err_inj_event                 = new();
  endfunction : new

  // ****************************************************************************
  // FUNCTION: post_randomize()
  // This function is automatically called after the randomize() function
  // is executed.
  //
  function void post_randomize();
    super.post_randomize();

    if(!m_ramwrap_sys_wrapper_env_config.randomize()) begin
      `uvm_fatal("RAND", "ramwrap_sys_wrapper_env randomization failed")
    end

    if(!m_gpaes_sys_wrapper_env_config.randomize()) begin
      `uvm_fatal("RAND", "gpaes_sys_wrapper_env randomization failed")
    end

    if(!m_ccpui_sys_wrapper_env_config.randomize()) begin
      `uvm_fatal("RAND", "ccpui_sys_wrapper_env randomization failed")
    end

  endfunction : post_randomize

  // ****************************************************************************
  // FUNCTION: convert2string()
  // This function converts all variables in this class to a single string for
  // logfile reporting. This function concatenates the convert2string result for
  // each agent configuration in this configuration class.
  //
  virtual function string convert2string();
    // pragma uvmf custom convert2string begin
    return ({
             super.convert2string(),
             {"\n", m_ccpui_sys_wrapper_env_config.convert2string(), "\n", m_ramwrap_sys_wrapper_env_config.convert2string(), "\n", m_gpaes_sys_wrapper_env_config.convert2string()}
      });

    // pragma uvmf custom convert2string end
  endfunction : convert2string
  // ****************************************************************************
  // FUNCTION: initialize();
  // This function configures each interface agents configuration class.  The
  // sim level determines the active/passive state of the agent.  The environment_path
  // identifies the hierarchy down to and including the instantiation name of the
  // environment for this configuration class.  Each instance of the environment
  // has its own configuration class.  The string interface names are used by
  // the agent configurations to identify the virtual interface handle to pull from
  // the uvm_config_db.
  //
  extern virtual function void initialize(
    uvmf_sim_level_t      sim_level,
    string                environment_path,
    string                interface_names[],
    uvm_reg_block         register_model       = null,
    uvmf_active_passive_t interface_activity[] = {}
  );

  extern virtual function void process_plusargs();

  covergroup sinc_configuration_cg;
    // pragma uvmf custom covergroup begin
    option.auto_bin_max=1024;
    // pragma uvmf custom covergroup end
  endgroup : sinc_configuration_cg

endclass : sinc_env_configuration

function void sinc_env_configuration::initialize(
    uvmf_sim_level_t      sim_level,
    string                environment_path,
    string                interface_names[],
    uvm_reg_block         register_model       = null,
    uvmf_active_passive_t interface_activity[] = {}
  );
  super.initialize(sim_level, environment_path, interface_names, register_model, interface_activity);

  m_ccpui_sys_wrapper_env_config.initialize( NA, {environment_path, ".ccpui_sys_wrapper_env"}, m_ccpui_sys_wrapper_env_interface_names, null, m_ccpui_sys_wrapper_env_interface_activity);

  m_ramwrap_sys_wrapper_env_config.initialize( NA, {environment_path, ".ramwrap_sys_wrapper_env"}, m_ramwrap_sys_wrapper_env_interface_names, null, m_ramwrap_sys_wrapper_env_interface_activity);

  m_gpaes_sys_wrapper_env_config.num_gpaes_sys += 1;
  m_gpaes_sys_wrapper_env_config.gpaes_sys_names.push_back(sinc_parameters_pkg::SINC_GPAES_SYS_NAME);
  m_gpaes_sys_wrapper_env_config.initialize( NA, {environment_path, ".gpaes_sys_wrapper_env"}, m_gpaes_sys_wrapper_env_interface_names, null, m_gpaes_sys_wrapper_env_interface_activity);
  m_gpaes_sys_wrapper_env_config.gpaes_sys_cfgs[m_gpaes_sys_wrapper_env_config.num_gpaes_sys - 1].uvm_path = {"*.gpaes_sys_env_", sinc_parameters_pkg::SINC_GPAES_SYS_NAME};
  m_gpaes_sys_wrapper_env_config.gpaes_sys_cfgs[m_gpaes_sys_wrapper_env_config.num_gpaes_sys - 1].seed_agent_en = 1;
  m_gpaes_sys_wrapper_env_config.gpaes_sys_cfgs[m_gpaes_sys_wrapper_env_config.num_gpaes_sys - 1].seed_agent_is_active = UVM_PASSIVE;

endfunction : initialize

function void sinc_env_configuration::process_plusargs();
  string debug_str = "SINC_ENV_CONFIGURATION";
  string tmp_str;

  /////////////////////////////////////////////////////////////////////////////////////////////////////////
  // tmp_str = "SINC_PARITY_ENV_ENABLE";                                 //
  // if($value$plusargs({tmp_str, "=%d"}, m_PARITY_ENV_ENABLE)) begin                    //
  //   `uvm_info(get_name(),  $sformatf("%s from plusarg = %d", tmp_str, m_PARITY_ENV_ENABLE ), UVM_LOW) //
  // end                                                 //
  /////////////////////////////////////////////////////////////////////////////////////////////////////////

endfunction : process_plusargs

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_ENV_CONFIGURATION
