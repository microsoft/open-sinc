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
// File        : sinc_regmodel.svh
// Description : 

`ifndef SINC_REGMODEL
`define SINC_REGMODEL

class sinc_regmodel extends csr_block_sinc_regs;
  string m_reg_hdl_paths;

  `uvm_object_utils_begin(sinc_regmodel)
    `uvm_field_string( m_reg_hdl_paths , UVM_DEFAULT )
  `uvm_object_utils_end

  function new(string name="sinc_regmodel");
    super.new(name);
  endfunction : new

  extern virtual function void build ();
  extern virtual function void reset (string kind="HARD");
  /**
   * Keeping track of the previous value helps the scoreboard accurately
   */
  extern virtual function bit get_previous_reg_value();
  extern virtual function bit set_reg_by_name(string r_name, sinc_reg_data_t r_data);

endclass : sinc_regmodel

function void sinc_regmodel::build ();
  super.build();
endfunction : build

function void sinc_regmodel::reset(string kind="HARD");
  super.reset(kind);
endfunction : reset

function bit sinc_regmodel::get_previous_reg_value();
  return (0);
endfunction : get_previous_reg_value

// Set register by name
// if register found - return 1
// else - return 0
function bit sinc_regmodel::set_reg_by_name(string r_name, sinc_reg_data_t r_data);
  string         report_str = "SET_REG_BY_NAME";
  uvm_reg        dst_reg    = get_reg_by_name(r_name);
  uvm_reg_data_t reg_value  = uvm_reg_data_t'(r_data);
  `uvm_info(report_str, $sformatf("[%0s] - set Data ['h%0h]",
      r_name, r_data), UVM_HIGH)

  if (dst_reg !== null) begin
    if (dst_reg.predict(reg_value)) begin
      return (1);
    end else begin
      return (0);
    end
  end else begin
    return (0);
  end
endfunction : set_reg_by_name

/*
 // Get register by name
 // if register found - return register handler
 // else - return null
 function uvm_reg sinc_regmodel::get_reg_by_name(string r_name);
 string report_str = "SET_REG_BY_NAME";
 uvm_reg dst_reg = this.get_reg_by_name(r_name);
 uvm_reg_data_t    reg_value = uvm_reg_data_t'(r_data);
 `uvm_info(report_str, $sformatf("[%0s] -set Data [%0h]",
 r_name, r_data), UVM_HIGH);

 if (dst_reg !== null) begin
 if (dst_reg.predict(reg_value)) begin
 return 1;
 end else begin
 return 0;
 end
 end else begin
 return 0;
 end
 endfunction : get_reg_by_name
 */


`endif // SINC_REGMODEL
