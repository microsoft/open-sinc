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
// File        : sinc_env_defines.svh
// Description : 

`ifndef SINC_ENV_DEFINES__SVH
`define SINC_ENV_DEFINES__SVH

`define DUT_TOP "hdl_top"

`define WRITE_CREG_BY_NAME_INDEX(REGNAME, INDEX, VALUE) \
  `uvm_info($sformatf("WRITE_TO_%s", REGNAME), $sformatf("index[%0d], value[%0h]", REGNAME, INDEX, VALUE), UVM_NONE) \
  write_value(m_regmodel.``REGNAME``INDEX, VALUE);

`endif
