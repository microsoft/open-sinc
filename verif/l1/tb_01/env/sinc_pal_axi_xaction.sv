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
// File        : sinc_pal_axi_xaction.sv
// Description : This class is used for address decode.

`ifndef SINC_PAL_AXI_XACTION
`define SINC_PAL_AXI_XACTION

/**
 * SINC PAL AXI Transaction
 */
class sinc_pal_axi_xaction extends pal_axi_xaction;

  `uvm_object_utils(sinc_pal_axi_xaction)

  const string REPORT_TAG = "SINC_PAL_AXI_XACTION";


  extern function new(string name = "sinc_pal_axi_xaction", pal_agent_config _pa_cfg=null);

  extern constraint cnst_exclusive_access;


endclass: sinc_pal_axi_xaction

constraint sinc_pal_axi_xaction::cnst_exclusive_access {
  // disable constraint on exclusive access
}

function sinc_pal_axi_xaction::new(string name = "sinc_pal_axi_xaction", pal_agent_config _pa_cfg=null);
    super.new(name);
    pa_cfg = _pa_cfg;
endfunction: new


`endif //SINC_PAL_AXI_XACTION
