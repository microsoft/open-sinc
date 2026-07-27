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
// File        : sinc_ramwrap_inj_base_sequence.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_RAMWRAP_INJ_BASE_SEQUENCE
`define SINC_RAMWRAP_INJ_BASE_SEQUENCE

// SINC IP specific ramwrapper ECC error injection sequence
class sinc_ramwrap_inj_base_sequence extends ramwrap_inject_sequence_base;

  event seq_done_event;

  int m_next_trans_id;

  int m_ongoing_xact_cnt;

  // Top level environment configuration handle
  typedef sinc_env_configuration sinc_env_configuration_t;
  sinc_env_configuration_t m_top_configuration;

  // Logger string
  string m_logger_str;

  `uvm_object_utils(sinc_ramwrap_inj_base_sequence)

  function new (string name="sinc_ramwrap_inj_base_sequence");
    super.new(name);
    m_logger_str = get_name();

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(sinc_env_configuration_t)::get(null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", m_top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?", UVM_NONE)
      `uvm_fatal("CFG", "uvm_config_db#(sinc_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG")
    end
  endfunction : new

  // Base Sequence Setup task
  virtual task seq_setup();
    // m_cfg = p_sequencer.get_cfg();
    m_req.configure(m_cfg);
    `uvm_info(get_type_name(), "seq_setup done\n", UVM_HIGH)
  endtask : seq_setup

  // --- body() ---
  extern virtual task body();

  /*
   * Helper Function For SINC Access
   *
   */
  extern virtual task inj_start_on_address (input [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, input [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);

  extern virtual task ramwrap_inj_start_on_address (input [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, input [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);

endclass: sinc_ramwrap_inj_base_sequence

// body()
task sinc_ramwrap_inj_base_sequence::body();
  // super.body();
  seq_setup();
  `uvm_info(get_name(), "sinc_ramwrap_inj_base_sequence waiting for done", UVM_NONE)

  wait(seq_done_event.triggered);
  `uvm_info(get_name(), "sinc_ramwrap_inj_base_sequence sequence done", UVM_NONE)
endtask : body

task sinc_ramwrap_inj_base_sequence::inj_start_on_address(input [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, input [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);

  string logger_str = "DV::ramwrap_inj_start";

  // SINC only implement CREG ramwrap_inj
  fork : ramwrap_inj_proc
    begin
      ramwrap_inj_start_on_address(address, data);
    end

  join

endtask : inj_start_on_address

task sinc_ramwrap_inj_base_sequence::ramwrap_inj_start_on_address(input [`RAMWRAP_MAX_ADDR_WIDTH - 1:0] address, input [`RAMWRAP_MAX_DATA_WIDTH - 1:0] data);

  ramwrap_inject_transaction_req_t trans;
  ramwrap_inject_transaction_req_t trans_resp;

  // each trasaction from this ramwrap_inj has unique id
  int my_trans_id = m_next_trans_id++;

  `uvm_info(get_type_name(), $sformatf("ramwrap_inj_start[%0d]: address['h%0h] \n", my_trans_id, address), UVM_HIGH)

  //Create transaction
  trans = ramwrap_inject_transaction::type_id::create("trans", , get_full_name());

  // pass ramwrap_inj config
  trans.configure(m_cfg);
  trans.set_transaction_id(my_trans_id);
  start_item(trans);

  if(!trans.randomize() with {
        m_address == address;
        m_data == data;
      }) begin
        `uvm_fatal("RAND", "failed to randomize 'trans'")
  end

  finish_item(trans);

  //Send transaction
  `uvm_info(get_type_name(), $sformatf("Sending Transaction: %s\n", trans.convert2string()), UVM_HIGH)

endtask: ramwrap_inj_start_on_address

`endif // SINC_RAMWRAP_INJ_BASE_SEQUENCE
