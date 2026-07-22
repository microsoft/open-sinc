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
// File        : sinc_axi_reg_access_extension.svh
// Description : 

`ifndef SINC_AXI_REG_ACCESS_EXTENSION
`define SINC_AXI_REG_ACCESS_EXTENSION

//rng2 dut config
class sinc_axi_reg_access_extension extends uvm_object;
  `uvm_object_utils(sinc_axi_reg_access_extension)

  rand bit [(`MSFT_AXI_MST_ENGNU_WIDTH-1):0]    m_axi_user_id;
  int unsigned  m_cmd_delay;
  int unsigned  m_data_accept_delay;
  int unsigned  m_data_beat_delay;
  int unsigned  m_wr_resp_accept_delay;
  bit           m_user_delay;

  function new (string name="sinc_axi_reg_access_extension");
    super.new (name);
  endfunction: new

  extern constraint reg_axi_user_c;

endclass: sinc_axi_reg_access_extension

constraint sinc_axi_reg_access_extension::reg_axi_user_c {
  m_axi_user_id inside {sinc_parameters_pkg::SP_MST_ID};
}

`endif //SINC_AXI_REG_ACCESS_EXTENSION
