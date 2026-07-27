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
// File        : gpaes_seed_config.svh
// Description : 

`ifndef GPAES_SEED_CONFIG
 `define GPAES_SEED_CONFIG

// derived from standard gpaes agent config
class gpaes_seed_config extends gpaes_agent_config #(
   .DRIVER_T(gpaes_seed_driver),
   .MONITOR_T(gpaes_seed_monitor)
);

  `uvm_object_utils(gpaes_seed_config)

  // handler of the sequencer
  gpaes_seed_sequencer m_sequencer;

  // Gpaesper Attributes
  // shortint unsigned addr_width;
  // shortint unsigned data_width;
  // shortint unsigned we_width;

  // Agent name
  string mid = "erase";

  // Time out option
  int tr_timeout = 500000;

  // GPAES SEED configs
  int unsigned m_seed_data_width = 32; // data width of every seed transaction
  int unsigned m_seed_size_in_bits = 640; // 640 bits seed with 32 seed_data_width need 20 seed transactions
  bit          m_reactive_driver = 0; // when set, seed will always sent regardless of m_is_gpaes_req_packet_active
  int unsigned m_trans_bursts_per_seed = 20;

  // TB preference
  bit dont_drive_x = 0;
  bit randomize_dontcares = 0;
  bit suppress_error = 0;

  function new( string name = "" );
    super.new( name );
    has_coverage = 1;
  endfunction : new

  function void post_randomize();
    super.post_randomize();
  endfunction : post_randomize

  virtual function void initialize(uvm_active_passive_enum activity, string agent_path);
    super.initialize(activity, agent_path);

    // User can call this.initialize function to set cfg into config_db
    // It is automaticly set in ram_wrapper_sys_env
    uvm_config_db #(gpaes_seed_config)::set(uvm_root::get(), {agent_path, ".*"}, "cfg", this );

    return_transaction_response = 1'b0;
  endfunction : initialize

  virtual task wait_for_reset();
    monitor_bfm.wait_for_reset();
  endtask : wait_for_reset

  virtual task wait_for_num_clocks(int clocks);
    monitor_bfm.wait_for_num_clocks(clocks);
  endtask : wait_for_num_clocks

  virtual function string convert2string ();
    string indent = "";
    string printStr = $sformatf("   gpaes_seed_config: \n");
    printStr = $sformatf("%s%s  agent_num               = %0d\n", printStr, indent, agent_num);
    printStr = $sformatf("%s%s  agent_name              = %0s\n", printStr, indent, agent_name);
    printStr = $sformatf("%s%s  sys_name                = %0s\n", printStr, indent, sys_name);
    printStr = $sformatf("%s%s  agent_en                = %0d\n", printStr, indent, agent_en);
    printStr = $sformatf("%s%s  is_active               = %0s\n", printStr, indent, is_active.name());
    printStr = $sformatf("%s%s  enable_trans_log        = %0d\n", printStr, indent, enable_trans_log);
    printStr = $sformatf("%s%s  trans_log_file_name     = %0s\n", printStr, indent, trans_log_file_name);
    printStr = $sformatf("%s%s  m_seed_data_width       = %0d\n",  printStr, indent, m_seed_data_width);
    printStr = $sformatf("%s%s  m_seed_size_in_bits     = %0d\n",  printStr, indent, m_seed_size_in_bits);
    return printStr;

  endfunction : convert2string

  virtual function uvm_sequencer#(gpaes_seed_transaction) get_sequencer();
    return (m_sequencer);
  endfunction : get_sequencer

  function void set_dyn_params();
    // leave for potential micro control config through yml config
    // dyn_params = gpaes_dyn_params::type_id::create("gpaes_dyn_params");
    // dyn_params.set_params(agent_name, sys_name);
    // if(agent_en) begin
    //   dyn_params.parse_plusargs();
    // end

    trans_log_file_name = {agent_name, "_trans.log"};
  endfunction: set_dyn_params

endclass : gpaes_seed_config

`endif // GPAES_SEED_CONFIG
