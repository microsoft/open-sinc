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
// File        : gpaes_sys_config.svh
// Description : Protocol Abstraction Layer System Configuration

`ifndef GPAES_SYS_CONFIG__SV
`define GPAES_SYS_CONFIG__SV

class gpaes_sys_config extends uvm_transaction;

  //Register with factory
  `uvm_object_utils(gpaes_sys_config)

  string        hdl_path;
  string        uvm_path;
  string        sys_name;

  // wrapper config pass by
  int           sys_wrapper_id = 0;

  // Seed agent
  bit               seed_agent_en;
  uvm_active_passive_enum     seed_agent_is_active  = UVM_ACTIVE;
  gpaes_seed_config seed_agent_cfg;

  // active AES packet config
  gpaes_packet_config active_gpaes_packet_config;

  // GPAES parameter config per sys
  /*
    Endian of AES per sys 
   */
  bit           aes_little_endian = 1; 


  extern function new(string name = "gpaes_sys_cfg");
  extern function void create_agent_configs(string sys_name);
  extern function string convert2string();

endclass : gpaes_sys_config

function gpaes_sys_config::new(string name = "gpaes_sys_cfg");
  super.new(name);
  
  active_gpaes_packet_config = gpaes_packet_config::type_id::create("active_gpaes_packet_config");
  active_gpaes_packet_config.packet_wrapper_id = sys_wrapper_id;
endfunction : new

function void gpaes_sys_config::create_agent_configs(string sys_name);

  // Seed agent  
  seed_agent_cfg = gpaes_seed_config::type_id::create($sformatf("seed_agent_cfg_%0s", sys_name));
  seed_agent_en = 1;

endfunction : create_agent_configs

function string gpaes_sys_config::convert2string();
  string printStr = "";
  printStr = $sformatf("%sGPAES_SYS_VERSION            = %s\n", printStr, `GPAES_SYS_VERSION);
  printStr = $sformatf("%sGPAES_SYS_WRAPPER_ID         = %d\n", printStr, sys_wrapper_id);
  printStr = $sformatf("%s hdl_path               = %s\n", printStr, hdl_path  );

  // Seed agent
  printStr = $sformatf("%s-------------------------------------------------------------------------------------------\n", printStr);
  if(!seed_agent_cfg.agent_en)
    printStr = $sformatf("%s Seed Agent Config: DISABLED\n", printStr);
  else begin
    printStr = $sformatf("%s Seed Agent Config: \n", printStr);
    printStr = $sformatf("%s-------------------------------------------------------------------------------------------\n", printStr);
    printStr = $sformatf("%s %s\n", printStr, seed_agent_cfg.convert2string());
  end
  printStr = $sformatf("%s-------------------------------------------------------------------------------------------\n", printStr);

  return printStr;
endfunction : convert2string

`endif //GPAES_SYS_CONFIG__SV

