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
// File        : gpaes_sys_inc.sv
// Description : GPAES include file for creating interface connection modules

generate
  /* localparam gpaes_master_type_t         master_type[`GPAES_MAX_NUM_MASTERS] = sys_params.master_type; */
  /* localparam bit [0:`GPAES_MAX_NUM_MASTERS-1] master_en = sys_params.master_en; */

  
  initial begin : gpaes_seed_auto_gen
    m_gpaes_sys_if.gpaes_seed_mif.IFNAME = $sformatf("GPAES_SEED_MIF: %0s_SEED_IF", SYS_NAME);
    uvm_config_db#(virtual gpaes_clkrst_if)::set(uvm_root::get(), $sformatf("%s.gpaes_seed_agent", uvm_path_inst), "clkrst_if", m_gpaes_sys_if.gpaes_clkrst_if_inst);
    uvm_config_db#(virtual gpaes_seed_if)::set(uvm_root::get(), $sformatf("%s.gpaes_seed_agent.*", uvm_path_inst), "vif", m_gpaes_sys_if.gpaes_seed_mif);
  end : gpaes_seed_auto_gen
  



endgenerate



