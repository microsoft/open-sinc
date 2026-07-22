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
// File        : gpaes_seed_params_pkg.sv
// Description : 

`ifndef GPAES_SEED_PARAMS_PKG__SV
 `define GPAES_SEED_PARAMS_PKG__SV


package gpaes_seed_params_pkg;

 `ifdef SIMULATION
  import uvm_pkg::*;
  `include "uvm_macros.svh"
 `endif

endpackage

`endif //GPAES_SEED_PARAMS_PKG__SV
