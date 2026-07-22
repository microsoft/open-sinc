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
// File        : sinc_negative_base_test.svh
// Description : This UVM negative base test

`ifndef SINC_NEGATIVE_BASE_TEST
`define SINC_NEGATIVE_BASE_TEST

/**
 * SINC negative Testing Base Test
 */
class sinc_negative_base_test extends test_top;

  `uvm_component_utils( sinc_negative_base_test )

  function new( string name = "sinc_negative_base_test", uvm_component parent = null );
    super.new( name, parent );
  endfunction : new

  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);

  endfunction : build_phase// build_phase

  extern virtual function void start_of_simulation_phase(uvm_phase phase);

endclass : sinc_negative_base_test


function void sinc_negative_base_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(
      AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_RESERVED_AWBURST_ENCODING);
    environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(
      AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_RESERVED_ARBURST_ENCODING);
    environment.pal_sys_wrapper_env.pal_env[0].pal_masters[0].set_configuration_int(
      AXI4_CONFIG_ENABLE_ASSERTION, 0, mgc_axi4_v1_0_pkg::AXI4_INVALID_WRITE_STROBES_ON_ALIGNED_WRITE_TRANSFER);
    environment.m_ramwrap_sys_wrapper_env.m_ramwrap_sys_env[0].ramwrap_erase_agents[1].suppress_error();
  endfunction : start_of_simulation_phase


`endif // SINC_NEGATIVE_BASE_TEST
