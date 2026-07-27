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
// File        : test_top.svh
// Description : This top level UVM test is the base class for all

`ifndef TEST_TOP
`define TEST_TOP

typedef sinc_env_configuration sinc_env_configuration_t;
typedef sinc_env sinc_environment_t;

/**
 * SINC Top level Test
 */
class test_top extends uvmf_test_base #( .CONFIG_T(sinc_env_configuration_t), .ENV_T(sinc_environment_t), .TOP_LEVEL_SEQ_T(sinc_bench_sequence_base));

  `uvm_component_utils( test_top )

  string m_interface_names[] = {
    M_LUT_RAMWRAP_ENGINE_AGENT_BFM /* m_lut_ramwrap_engine_agent     [0] */ ,
    M_LUT_RAMWRAP_ERASE_AGENT_BFM /* m_lut_ramwrap_erase_agent      [1] */ ,
    M_LUT_RAMWRAP_INJECT_AGENT_BFM /* m_lut_ramwrap_inject_agent     [2] */ ,
    M_KEY_RAMWRAP_ENGINE_AGENT_BFM /* m_key_ramwrap_engine_agent     [3] */ ,
    M_KEY_RAMWRAP_ERASE_AGENT_BFM /* m_key_ramwrap_erase_agent      [4] */ ,
    M_KEY_RAMWRAP_INJECT_AGENT_BFM /* m_key_ramwrap_inject_agent     [5] */
  };

  uvmf_active_passive_t m_interface_activities[] = {
  };

  sinc_virtual_sequencer m_vseqr;

  sinc_regmodel m_regmodel;

  extern function new( string name = "", uvm_component parent = null );
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  // extern virtual task run_phase( uvm_phase phase );
  // extern virtual task pre_reset_phase(uvm_phase phase);
  // extern virtual task main_phase (uvm_phase phase);
  extern virtual function void start_of_simulation_phase (uvm_phase phase);

endclass : test_top

// ****************************************************************************
// FUNCTION: new()
// This is the standard systemVerilog constructor.  All components are
// constructed in the build_phase to allow factory overriding.
//
function test_top::new( string name = "", uvm_component parent = null );
  super.new( name, parent );
endfunction : new

// ****************************************************************************
// FUNCTION: build_phase()
// The construction of the configuration and environment classes is done in
// the build_phase of uvmf_test_base.  Once the configuraton and environment
// classes are built then the initialize call is made to perform the
// following:
//     Monitor and driver BFM virtual interface handle passing into agents
//     Set the active/passive state for each agent
// Once this build_phase completes, the build_phase of the environment is
// executed which builds the agents.
//
function void test_top::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // pragma uvmf custom configuration_settings_post_randomize begin
  // pragma uvmf custom configuration_settings_post_randomize end

  `uvm_info(get_name(), "Creating register model", UVM_LOW)

  reg2pal_adapter::type_id::set_type_override(sinc_reg2pal_adapter::get_type(), 1);
  test_top::set_type_override_by_type(uvm_reg_map::get_type(), pal_uvm_reg_map::get_type());

  // override pal_axi_xaction with sinc_pal_axi_xaction to get around nonsense constrains
  pal_axi_xaction::type_id::set_type_override(sinc_pal_axi_xaction::get_type(), 1);

  m_regmodel = sinc_regmodel::type_id::create("m_regmodel", this);
  m_regmodel.build();
  m_regmodel.set_hdl_path_root("hdl_top.sinc.u_sinc_cmu.u_reg_ctrl.u_sinc_regs");
  m_regmodel.reset();
  m_regmodel.lock_model();
  m_regmodel.default_map.set_base_addr(sinc_parameters_pkg::SINC_REG_START_ADDR);
  uvm_config_db #(sinc_regmodel)::set(this, "environment", "m_regmodel", m_regmodel);

  configuration.initialize(
    .sim_level          (NA                         ),
    .environment_path   ("uvm_test_top.environment" ),
    .interface_names    (m_interface_names            ),
    .register_model     (m_regmodel                 ),
    .interface_activity (m_interface_activities       )
  );

  m_vseqr             = sinc_virtual_sequencer::type_id::create("m_vseqr", this);
  environment.m_vseqr = m_vseqr;

endfunction : build_phase

function void test_top::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  top_level_sequence.m_rst_sequencer = environment.m_rst_agent.m_sequencer;
  top_level_sequence.m_tb_vseqr      = environment.pal_sys_wrapper_env.tb_vseqr;

  // top_level_sequence.m_lut_ramwrap_inject_agent_sequencer  = environment.m_lut_ramwrap_inject_agent.sequencer;
  // top_level_sequence.m_key_ramwrap_inject_agent_sequencer  = environment.m_key_ramwrap_inject_agent.sequencer;

endfunction : connect_phase

function void test_top::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);

  // mask AXI UVC interface error on optional ports (MSFT AXI SUB module has application specifc usage)

  // Disable MVC native assertions for exclusive lock transactions (prevents MVC_ERROR in log)
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(pal_pkg::AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_EXCLUSIVE_READ_ACCESS_MODIFIABLE);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(pal_pkg::AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_EXCLUSIVE_WRITE_ACCESS_MODIFIABLE);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(pal_pkg::AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_EX_RD_OKAY_RESP_EXPECTED_EXOKAY);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(pal_pkg::AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_EX_WRITE_BEFORE_EX_READ_RESPONSE);

  // mask error messages associated w/ exclusive lock transactions
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60119", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60122", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60123", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60128", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60135", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60137", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60151", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60150", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60181", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60182", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60147", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60147", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60124", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60205", UVM_INFO);

  // mask error messages associated w/ cache transactions
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60190", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60161", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60188", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60191", UVM_INFO);

  // mask cache related
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60187", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60189", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60192", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60160", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60162", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60163", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60164", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60165", UVM_INFO);

  // mask AXI error injection intended
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60173", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60174", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60148", UVM_INFO);
  environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60153", UVM_INFO);

  // mask parity error test related issue cause by forcing bad parity
  // fixme: this is a real RTL issue
  // environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].qvip_agent.set_report_severity_id_override(UVM_ERROR, "QVIP/AXI4/60037", UVM_INFO);

  // mask volatile reg field mirrored value warnings (expected for status register fields)
  // Apply on uvm_top since the warning is emitted by uvm_reg_field objects (uvm_object), not uvm_component
  uvm_top.set_report_severity_id_override(UVM_WARNING, "UVM/FLD/GET_MIRRORED_VAL/VOL", UVM_INFO);
endfunction : start_of_simulation_phase

/**
 * Kill/Stop all sequences
 *
 * @see uvmf_base_pkg::uvmf_test_base.build_phase
 * @param phase -  uvm phase
 */
/*
 task test_top::pre_reset_phase(uvm_phase phase);
 super.pre_reset_phase(phase);
 m_vseqr.stop_sequences();
 top_level_sequence.kill();
 endtask : pre_reset_phase
 */

/**
 * Override run_phase
 *
 * @see uvmf_base_pkg::uvmf_test_base.run_phase
 * @param phase - uvm phase
 */
/*
 task test_top::run_phase( uvm_phase phase );
 string debug_str = "RUN_PHASE";
 phase.raise_objection (this, debug_str);

 if (0 == top_level_sequence.randomize())
 `uvm_fatal(debug_str, $sformatf("Randomize failed!!!"))

 top_level_sequence.start(m_vseqr);

 environment.pal_sys_wrapper_env.tb_vseqr.tb_if.test_done = 1;

 phase.drop_objection (this, debug_str);
 endtask : run_phase
 */

/**
 *
 * @see uvm_pkg::uvm_component.main_phase
 * @param phase - uvm phase
 */
/*
 task test_top::main_phase (uvm_phase phase);
 super.main_phase(phase);
 endtask : main_phase
 */

`endif // TEST_TOP
