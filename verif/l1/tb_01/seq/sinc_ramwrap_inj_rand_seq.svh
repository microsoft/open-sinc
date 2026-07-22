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
// File        : sinc_ramwrap_inj_rand_seq.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_RAMWRAP_INJ_RAND_SEQ
`define SINC_RAMWRAP_INJ_RAND_SEQ

// SINC ramwrap error injection virtual sequence
class sinc_ramwrap_inj_rand_seq extends uvmf_sequence_base #(uvm_sequence_item);
  int m_num_iter = 1;

  // Top level environment configuration handle
  typedef sinc_env_configuration sinc_env_configuration_t;
  sinc_env_configuration_t m_top_configuration;

  sinc_ramwrap_inj_base_sequence m_cache_mem_ramwrap_inj_seq;

  // Logger string
  string m_logger_str;

  `uvm_object_utils(sinc_ramwrap_inj_rand_seq)

  function new (string name="sinc_ramwrap_inj_rand_seq");
    super.new (name);
    m_logger_str = get_name();

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(sinc_env_configuration_t)::get(null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", m_top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?", UVM_NONE)
      `uvm_fatal("CFG", "uvm_config_db#(sinc_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG")
    end
  endfunction : new

  // --- pre_body() ---
  extern virtual task pre_body();
  // --- body() ---
  extern virtual task body();
  // --- post_body() ---
  extern virtual task post_body();

  // --- Ramwrap_inj CACHE_MEM ---
  extern virtual task ramwrap_inj_cache_mem(logic [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);

endclass: sinc_ramwrap_inj_rand_seq

// pre_body() task
task sinc_ramwrap_inj_rand_seq::pre_body();
  uvm_phase starting_phase = get_starting_phase();
  super.pre_body();
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~ SEQUENCE BEGIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)

  if (starting_phase != null) begin
    `uvm_info(get_type_name(),
      $sformatf("%s pre_body() raising %s objection",
        get_sequence_path(),
        starting_phase.get_name()), UVM_MEDIUM)
    starting_phase.raise_objection(this, "Started pre body virt_base_seq");
  end

  `uvm_info(m_logger_str, $sformatf("sinc_ramwrap_inj_base_sequence -- pre_body"), UVM_HIGH)

  m_cache_mem_ramwrap_inj_seq = sinc_ramwrap_inj_base_sequence::type_id::create("m_cache_mem_ramwrap_inj_seq", , get_full_name());
endtask : pre_body

// body
task sinc_ramwrap_inj_rand_seq::body();

  // scenario here
  `uvm_info(get_name(), "sinc_ramwrap_inj_rand_seq start", UVM_LOW)

  m_cache_mem_ramwrap_inj_seq.configure(m_top_configuration.m_ramwrap_sys_wrapper_env_config.ramwrap_sys_cfg[0].inject_agents_cfg[0]);

  fork : cache_ramwrap_inj_proc
    begin
      m_cache_mem_ramwrap_inj_seq.start(m_top_configuration.m_vseqr.m_cache_mem_ramwrap_inj_agent_seqr, .parent_sequence(this));
    end
  join_none

  repeat (20) begin
    @(m_top_configuration.m_sinc_vif.mon_cb);
  end

endtask : body

// Drop the objection in the post_body so the objection is removed when

task sinc_ramwrap_inj_rand_seq::post_body();
  uvm_phase starting_phase = get_starting_phase();
  super.post_body();
  if (starting_phase != null) begin
    `uvm_info(get_type_name(),
      $sformatf("%s post_body() dropping %s objection",
        get_sequence_path(),
        starting_phase.get_name()), UVM_MEDIUM)
    starting_phase.drop_objection(this, "Ended post body virt_base_seq");
  end
endtask : post_body

task sinc_ramwrap_inj_rand_seq::ramwrap_inj_cache_mem(logic [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  `uvm_info(m_logger_str,
    $sformatf("~~~~~~~~~~~~~~~~~~~~ CACHE_MEM Ramwrap_inj BEGIN on Addr ['h%0h] ~~~~~~~~~~~~~~~~~~~~~~~~~~",
      address), UVM_MEDIUM)

  m_cache_mem_ramwrap_inj_seq.inj_start_on_address(address, data);

  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~ CACHE_MEM Ramwrap_inj DONE ~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
endtask : ramwrap_inj_cache_mem

`endif // SINC_RAMWRAP_INJ_RAND_SEQ
