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
// File        : sinc_erase_base_sequence.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_ERASE_BASE_SEQUENCE
`define SINC_ERASE_BASE_SEQUENCE

//SINC Erase Base Sequence
class sinc_erase_base_sequence extends ramwrap_erase_base_sequence;

  // Top level environment configuration handle
  typedef sinc_env_configuration sinc_env_configuration_t;
  sinc_env_configuration_t m_top_configuration;

  // Logger string
  string m_logger_str;

  `uvm_object_utils(sinc_erase_base_sequence)

  function new (string name="sinc_erase_base_sequence");
    super.new(name);
    m_logger_str = get_name();

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(sinc_env_configuration_t)::get(null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", m_top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?", UVM_NONE)
      `uvm_fatal("CFG", "uvm_config_db#(sinc_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG")
    end
  endfunction : new

  // --- body() ---
  extern virtual task body();

  /*
   * Helper Function For SINC Access
   *
   */
  extern virtual task erase_start (input erase_data_type_e erase_data_type = ramwrap_erase_pkg::ZERO);

endclass: sinc_erase_base_sequence

// body()
task sinc_erase_base_sequence::body();
  super.body();
  `uvm_info(get_type_name(), "Start sinc erase sequence\n", UVM_HIGH)
endtask : body

task sinc_erase_base_sequence::erase_start(input erase_data_type_e erase_data_type = ramwrap_erase_pkg::ZERO);

  string logger_str = "DV::erase_start";

  // SINC only implement CREG erase
  fork : ramwrap_erase_proc
    begin
      ramwrap_erase_start(.source(ramwrap_erase_pkg::CREG), .erase_data_type(erase_data_type));
    end
  join

endtask : erase_start

`endif // SINC_ERASE_BASE_SEQUENCE
