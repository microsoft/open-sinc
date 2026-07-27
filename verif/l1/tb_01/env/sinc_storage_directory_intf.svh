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
// File        : sinc_storage_directory_intf.svh
// Description : This class defines the stimulus (sequence) interface into the Key Storage of the system.  It is

`ifndef SINC_STORAGE_DIRECTORY_INTF_SVH
`define SINC_STORAGE_DIRECTORY_INTF_SVH

virtual class sinc_storage_directory_intf extends uvm_component; // {
  
  typedef sinc_env_pkg::sinc_cmd_e req_cmd_list_t[$];
  protected static sinc_storage_directory_intf _instance;

  localparam DATA_W = 32;

  // ****************************************
  // Function: new
  // Constructor.
  function new(string name, uvm_component parent);
    super.new(name,parent);
    if (_instance != null) begin
      `uvm_fatal("illegal instance of singleton","Can't instance a singleton more than once.")
    end
    _instance = this;

  endfunction: new

  // ****************************************
  // Function: get_inst
  // A static function which returns the singleton instance of this class.
  static function sinc_storage_directory_intf get_inst();
    if (_instance != null) begin
      return _instance;
    end
    else begin
      return null;
    end
  endfunction : get_inst

  // ****************************************
  // Function: is_req_valid
  // Given an address and a master request cmd type, returns true if the requested cmd can be issueed for that address.
  //
  pure virtual function int is_req_valid(
                                         sinc_env_pkg::sinc_comp_e mstr_id,
                                         sinc_env_pkg::address_t addr,
                                         sinc_env_pkg::sinc_cmd_e cmd,
                                         bit create_storage_state = 0
                                         );


  // Function: write_reset_xp
  pure virtual function void write_reset_xp(rst_pkg::rst_seq_item reset_state);

  // ********************************************************************************
  // ********************************************************************************
  // Function: sending_req
  // Called by sequence when a request will be sent to the sequencer.
  // Log this as an outstanding request pending, this will be used to determine
  // the validity of requests following.
  //
  pure virtual function void sending_axi_req(
                                         sinc_env_pkg::sinc_comp_e mstr_id,
                                         sinc_env_pkg::address_t addr,
                                         sinc_env_pkg::sinc_cmd_e cmd,
                                         bit check_req_valid=1
                                         );

  // ********************************************************************************
  // Function: make_request
  //  Given an address, a master, and a command, make a request to the key storage directory
  //  for valid key state.  It will new allocate new key directory if necessary.  Returns
  //  1 for success.
  pure virtual function int make_request(sinc_env_pkg::sinc_comp_e mstr_id, 
                                         sinc_env_pkg::address_t addr, 
                                         sinc_env_pkg::sinc_cmd_e cmd,
                                         bit init_line_data=0
                                         );

                                                                  

  // ****************************************
  // Function: get_req_pending
  // If ksd state exists returns
  // pure virtual function int get_req_pending(sinc_env_pkg::sinc_comp_e mstr_id, sinc_env_pkg::address_t addr);

  // Function: set_passive_mode
  // Update passive_mode
  pure virtual function void set_passive_mode(bit new_value);

  // ********************************************************************************
  // Function: get_passive_mode
  // Returns passive_mode
  pure virtual function bit get_passive_mode();

endclass : sinc_storage_directory_intf // }

`endif //  `ifndef SINC_STORAGE_DIRECTORY_INTF_SVH
