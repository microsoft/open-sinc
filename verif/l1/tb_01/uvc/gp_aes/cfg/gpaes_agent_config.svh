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
// File        : gpaes_agent_config.svh
// Description : 

`ifndef GPAES_AGENT_CONFIG
 `define GPAES_AGENT_CONFIG
virtual class gpaes_agent_config #( 
   type DRIVER_T,
   type MONITOR_T
) extends uvm_object;

  // VARIABLE: driver_bfm
  // VARIABLE: monitor_bfm
  DRIVER_T  driver_bfm;
  MONITOR_T monitor_bfm;

  // dynamic parameters control
  // gpaes_dyn_params dyn_params;

  int unsigned                agent_num  = 0;
  string                      agent_name = "GPAES_AGENT";
  string                      sys_name   = "GPAES_SYS";
  bit                         agent_en   = 1;
  uvm_active_passive_enum     is_active  = UVM_ACTIVE;
  bit                         enable_trans_log = 0;
  string                      trans_log_file_name = {agent_name, "_trans.log"};
  
  bit has_coverage = 0;
  
  bit return_transaction_response;
  
  function new( string name = "" );
    super.new( name );
    has_coverage = 0;
  endfunction : new

  function void post_randomize();
    super.post_randomize();
  endfunction : post_randomize

  virtual function void initialize(uvm_active_passive_enum activity, string agent_path);
    // leave blank for extended agent config
    // Example
    /*
    if ( activity == ACTIVE ) begin
      if( !uvm_config_db #( DRIVER_T )::get( null , "UVM_DRIVER" , interface_name , driver_bfm ) ) begin
        $stacktrace;
        `uvm_fatal("CFG" , $sformatf("uvm_config_db #( DRIVER_T )::get cannot find driver resource with interface_name %s",interface_name) )
      end
    end
    */
  endfunction : initialize

  virtual function string convert2string ();
    string indent = "";
    string printStr = $sformatf(" gpaes_agent_config: \n");
    // leave blank for extended agent config
    // Example
    /*
    printStr = $sformatf("%s%s  m_max_addr            = %0d\n", printStr, indent, m_max_addr);
    printStr = $sformatf("%s%s  m_max_we              = %s\n",  printStr, indent, m_max_we);
    printStr = $sformatf("%s%s  m_support_rmw         = %s\n",  printStr, indent, m_support_rmw);
    printStr = $sformatf("%s%s  m_ignore_rmw_busy     = %s\n",  printStr, indent, m_ignore_rmw_busy);
    printStr = $sformatf("%s%s  addr_width            = %0d\n", printStr, indent, addr_width);
    printStr = $sformatf("%s%s  data_width            = %0d\n", printStr, indent, data_width);
     */
    return printStr;
  endfunction : convert2string

  function void set_dyn_params();
    // leave for potential micro control config through yml config
    // dyn_params = gpaes_dyn_params::type_id::create("gpaes_dyn_params");
    // dyn_params.set_params(agent_name, sys_name);
    // if(agent_en) begin
    //   dyn_params.parse_plusargs();
    // end
    trans_log_file_name = {agent_name, "_trans.log"};
  endfunction: set_dyn_params
  
endclass : gpaes_agent_config

`endif // GPAES_AEGNT_CONFIG
