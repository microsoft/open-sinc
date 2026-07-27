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
// File        : gpaes_sys_params_pkg.sv
// Description : 

`ifndef GPAES_SYS_PARAMS_PKG__SV
 `define GPAES_SYS_PARAMS_PKG__SV

package gpaes_sys_params_pkg;

 `include "gpaes_sys_defines.svh"

 `ifdef SIMULATION
  import uvm_pkg::*;
  `include "uvm_macros.svh"
 `endif



  // GPAES_SEED_PARAMS_BEGIN
  typedef struct{
    byte unsigned             client_num;
    string                    client_name;
    uvm_active_passive_enum   is_active;
    int unsigned              seed_data_width;
  } gpaes_seed_params_t;
  // GPAES_SEED_PARAMS END


  // GPAES_SYS_PARAMS_BEGIN
  typedef struct{
    byte unsigned             sys_id;
    string                    sys_name;
    string                    uvm_path;
    string                    hdl_path;

    // Seed
    bit                       seed_agent_en;
    gpaes_seed_params_t   seed_params;
    
  } gpaes_sys_params_t;
  // GPAES_SYS_PARAMS_END

  endpackage

`endif //GPAES_SYS_PARAMS_PKG__SV
