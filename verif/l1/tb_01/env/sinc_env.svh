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
// File        : sinc_env.svh
// Description : This environment contains all agents, predictors and

`ifndef SINC_ENV
`define SINC_ENV
/**
 * SINC Environment
 */
class sinc_env extends ip_base_environment #(.CONFIG_T( sinc_env_configuration ));

  `uvm_component_utils( sinc_env )

  // RamWrapper Environment
  typedef ramwrap_sys_wrapper_environment ramwrap_sys_wrapper_env_t;
  ramwrap_sys_wrapper_env_t m_ramwrap_sys_wrapper_env;

  // GPAES Environment
  typedef gpaes_sys_wrapper_environment gpaes_sys_wrapper_env_t;
  gpaes_sys_wrapper_env_t m_gpaes_sys_wrapper_env;

  // CCPUI Environment
  typedef ccpui_sys_wrapper_environment ccpui_sys_wrapper_env_t;
  ccpui_sys_wrapper_env_t m_ccpui_sys_wrapper_env;

  sinc_virtual_sequencer m_vseqr;

  sinc_regmodel m_regmodel;

  sinc_regmodel m_sinc_reg_tlb;

  typedef sinc_scoreboard #(.CONFIG_T(CONFIG_T)) sinc_sb_t;
  sinc_sb_t m_sinc_sb;

  typedef virtual interface sinc_v_if sinc_v_if_t;
  virtual interface sinc_mem_bkdoor_if m_mem_bkdoor_if;

  ///////////////////////////////////////////////////////
  // Variable: sys_cfg
  // Contains information about all SINC components
  sinc_env_pkg::sinc_sys_cfg m_sys_cfg;

  // Variable: csd
  // Handle to sinc cache storage directory
  sinc_csd m_csd;

  // Variable: addr_decoder
  // Handle to address decoder
  sinc_address_decoder m_addr_decoder;

  sinc_status_monitor m_status_mon;

  extern function new(string name = "", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_plusargs();
  extern virtual function void connect_phase(uvm_phase phase);

endclass : sinc_env

// ****************************************************************************
// FUNCTION : new()
// This function is the standard SystemVerilog constructor.
//
function sinc_env::new( string name = "", uvm_component parent = null );
  super.new( name, parent );
endfunction : new

// ****************************************************************************
// FUNCTION: build_phase()
// This function builds all components within this environment.
//
function void sinc_env::build_phase(uvm_phase phase);
  uvm_reg my_regs[$];
  super.build_phase(phase);

  if (!uvm_config_db #(sinc_regmodel)::get(this, "", "m_regmodel", m_regmodel)) begin
    `uvm_error(get_name(), "Could not find register model in uvm_config_db")
  end else begin
    `uvm_info(get_name(), "Retrived register model from uvm_config_db", UVM_LOW)
  end
  configuration.m_regmodel = m_regmodel;
  configuration.m_vseqr    = m_vseqr;

  m_ccpui_sys_wrapper_env = ccpui_sys_wrapper_env_t::type_id::create("m_ccpui_sys_wrapper_env", this);
  m_ccpui_sys_wrapper_env.set_config(configuration.m_ccpui_sys_wrapper_env_config);

  // SINC system config
  // Configuration for stimulus and checker usage
  m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  if(m_sys_cfg == null) begin
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::type_id::create("m_sys_cfg", this);
  end
  configuration.m_sys_cfg            = m_sys_cfg;
  configuration.m_sys_cfg.m_regmodel = m_regmodel;

  // extend non generic configs
  m_regmodel.get_registers(my_regs);
  foreach(my_regs[i]) begin
    m_sys_cfg.construct_reg_list_with_reg_name(my_regs[i].get_name());
  end
  `uvm_info("SINC_ENV:", $sformatf("Updated readable_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_readable_reg_list), UVM_HIGH)
  `uvm_info("SINC_ENV:", $sformatf("Updated writable_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_writeable_reg_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_disable_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_write_discard_in_cache_disable_reg_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_init_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_write_discard_in_cache_init_reg_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_active_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_write_discard_in_cache_active_reg_list), UVM_HIGH)
  `uvm_info("SINC_SYS_CFG:", $sformatf("Updated write_discard_in_cache_fail_reg_list: %0p ", m_sys_cfg.m_comp_cfg[SINC_REG].m_write_discard_in_cache_fail_reg_list), UVM_HIGH)

  m_addr_decoder                = sinc_address_decoder::type_id::create ("m_addr_decoder", this);
  m_csd                         = sinc_csd::type_id::create ("m_csd", this);
  configuration.m_csd           = m_csd;
  configuration.m_sys_cfg.m_csd = m_csd;

  m_ramwrap_sys_wrapper_env = ramwrap_sys_wrapper_env_t::type_id::create("m_ramwrap_sys_wrapper_env", this);
  m_ramwrap_sys_wrapper_env.set_config(configuration.m_ramwrap_sys_wrapper_env_config);

  if (uvm_config_db #(gpaes_sys_wrapper_environment)::get(this, "", "gpaes_sys_wrapper_env_0", m_gpaes_sys_wrapper_env)) begin
     `uvm_info("SINC_ENV:", $sformatf("m_gpaes_sys_wrapper_env get from CFG_DB: %0s ", m_gpaes_sys_wrapper_env.m_name), UVM_HIGH)
  end else begin
      m_gpaes_sys_wrapper_env = gpaes_sys_wrapper_env_t::type_id::create("m_gpaes_sys_wrapper_env_0", this);
      uvm_config_db #(gpaes_sys_wrapper_environment)::set(uvm_root::get(), "*", "m_gpaes_sys_wrapper_env_0", m_gpaes_sys_wrapper_env);
  end     
  
  m_gpaes_sys_wrapper_env.set_config(configuration.m_gpaes_sys_wrapper_env_config);

  m_sinc_sb                 = sinc_sb_t::type_id::create("m_sinc_sb", this);
  m_sinc_sb.m_configuration = configuration;
  // m_csd.top_configuration = configuration;

  m_status_mon = sinc_status_monitor::type_id::create ("m_status_mon", this);

  // create SInC Register TLB
  m_sinc_reg_tlb = sinc_regmodel::type_id::create("m_sinc_reg_tlb", this);
  m_sinc_reg_tlb.build();
  m_sinc_reg_tlb.set_hdl_path_root("hdl_top.sinc.u_sinc_cmu.u_reg_ctrl.u_sinc_regs");
  m_sinc_reg_tlb.reset();
  m_sinc_reg_tlb.lock_model();
  m_sinc_reg_tlb.default_map.set_base_addr(sinc_parameters_pkg::SINC_REG_START_ADDR);
  m_sys_cfg.m_sinc_reg_tlb = m_sinc_reg_tlb;

endfunction : build_phase

// ****************************************************************************
// FUNCTION: connect_phase()
// This function makes all connections within this environment.  Connections
// typically inclue agent to predictor, predictor to scoreboard and scoreboard
// to agent.
//
function void sinc_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(!uvm_config_db#(sinc_v_if_t)::
      get(null, UVMF_VIRTUAL_INTERFACES, "SINC_V_IF", configuration.m_sinc_vif)) begin
    `uvm_fatal(get_name(), "uvm_config_db#(sinc_v_if_t)::get cannot find resource SINC_V_IF")
  end

  if (!uvm_config_db #(virtual sinc_mem_bkdoor_if)::get (null , UVMF_VIRTUAL_INTERFACES , "mem_bkdoor_if" ,
        configuration.m_mem_bkdoor_if)) begin
    `uvm_error("Config Error", "Unable to retrieve backdoor memory interface")
  end

  // virtual interface
  configuration.m_sys_cfg.m_sinc_vif = configuration.m_sinc_vif;

  // Sequencers
  // PAL sequencer
  m_vseqr.m_pal_sequencer                    = pal_sys_wrapper_env.tb_vseqr.pal_vseqr[0].pal_master_seqr[0];
  m_vseqr.m_rst_sequencer                    = m_rst_agent.m_sequencer;
  m_vseqr.m_tb_vseqr                         = pal_sys_wrapper_env.tb_vseqr;
  // Ramwrapper sequencer
  m_vseqr.m_ramwrap_sys_wrapper_vseqr        = m_ramwrap_sys_wrapper_env.sys_wrapper_vseqr;
  m_vseqr.m_cache_mem_erase_agent_seqr       = m_ramwrap_sys_wrapper_env.sys_wrapper_vseqr.ramwrap_sys_vseqr[0].ramwrap_erase_agent_seqr[0];
  m_vseqr.m_cache_mem_ramwrap_inj_agent_seqr = m_ramwrap_sys_wrapper_env.sys_wrapper_vseqr.ramwrap_sys_vseqr[0].ramwrap_inject_agent_seqr[0];
  // GPAES sequencer
  m_vseqr.m_gpaes_sys_wrapper_vseqr          = m_gpaes_sys_wrapper_env.sys_wrapper_vseqr;
  m_vseqr.m_gpaes_seed_agent_seqr            = m_gpaes_sys_wrapper_env.sys_wrapper_vseqr.gpaes_sys_vseqr[0].gpaes_seed_agent_seqr;
  // CPU sequencer
  m_vseqr.m_cpu_mem_agent_seqr               = m_ccpui_sys_wrapper_env.sys_wrapper_vseqr.ccpui_sys_vseqr[0].ccpui_cpu_mem_agent_seqr[0];
  // MPU sequencer
  m_vseqr.m_mpu_agent_seqr                   = m_ccpui_sys_wrapper_env.sys_wrapper_vseqr.ccpui_sys_vseqr[0].ccpui_mpu_agent_seqr[0];

  // TLM connections
  // RESET TLM
  m_rst_agent.m_analysis_port.connect(m_sinc_sb.m_sinc_reset_ae);
  // m_rst_agent.m_analysis_port.connect(m_ksd.reset_xp);
  // PAL TLM
  pal_sys_wrapper_env.master_ap[pal_user_params_pkg::num_pal_sys - 1][0].connect(m_sinc_sb.m_sinc_axi_sub_ae);
  pal_sys_wrapper_env.slave_ap[pal_user_params_pkg::num_pal_sys - 1][0].connect(m_sinc_sb.m_sinc_axi_mgr_ae);
  // connect pal with ral
  pal_sys_wrapper_env.pal_env[0].set_reg_map(0, configuration.m_regmodel.default_map);
  // RamWrapper TLM
  m_ramwrap_sys_wrapper_env.mem_agent_ap[ramwrap_user_params_pkg::num_ramwrap_sys - 1][0].connect(m_sinc_sb.m_sinc_cache_mem_mem_ae);
  m_ramwrap_sys_wrapper_env.erase_agent_ap[ramwrap_user_params_pkg::num_ramwrap_sys - 1][0].connect(m_sinc_sb.m_sinc_cache_mem_erase_ae);
  // CPU TLM
  m_ccpui_sys_wrapper_env.cpu_mem_agent_ap[ccpui_user_params_pkg::num_ccpui_sys - 1][0].connect(m_sinc_sb.m_sinc_cpu_mem_ae);
  // MPU TLM
  m_ccpui_sys_wrapper_env.mpu_agent_ap[ccpui_user_params_pkg::num_ccpui_sys - 1][0].connect(m_sinc_sb.m_sinc_mpu_ae);
  // SINC status monitor
  m_status_mon.m_sinc_sideband_ap.connect(m_sinc_sb.m_sinc_sideband_ae);

  // CSD
  m_csd.m_mem_bkdoor_if_h = configuration.m_mem_bkdoor_if;
  m_csd.m_mem_config      = configuration.m_ramwrap_sys_wrapper_env_config.ramwrap_sys_cfg[0].mem_agents_cfg[0];

  // passing configurations
  m_sys_cfg.m_mpu_cfg              = configuration.m_ccpui_sys_wrapper_env_config.ccpui_sys_cfg[0].mpu_agents_cfg[0];
  m_sys_cfg.m_ham                  = configuration.m_ramwrap_sys_wrapper_env_config.ramwrap_sys_cfg[0].mem_agents_cfg[0].get_model();
  m_sys_cfg.m_pal_slv_err_injector = pal_sys_wrapper_env.pal_env[0].pal_slv_err_injector;

endfunction : connect_phase

function void sinc_env::configure_plusargs();
  string value;

endfunction : configure_plusargs

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_ENV
