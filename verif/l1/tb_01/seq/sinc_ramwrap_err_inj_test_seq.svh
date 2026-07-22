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
// File        : sinc_ramwrap_err_inj_test_seq.svh
// Description : 

`ifndef SINC_RAMWRAP_ERR_INJ_TEST_SEQ
`define SINC_RAMWRAP_ERR_INJ_TEST_SEQ

//------------------------------------------------------------------------------
// SEQUENCE: sinc_ramwrap_err_inj_test_seq
//------------------------------------------------------------------------------

// fixme: dummy class to update
// please refer to the kv ramwrap err inj test seq

//SINC RAMWRapper Error Inject Test Sequence
class sinc_ramwrap_err_inj_test_seq extends sinc_virtual_base_sequence;
  `uvm_object_utils(sinc_ramwrap_err_inj_test_seq)
  function new(string name="sinc_ramwrap_err_inj_test_seq");
    super.new(name);
  endfunction : new

endclass : sinc_ramwrap_err_inj_test_seq

`endif // SINC_RAMWRAP_ERR_INJ_TEST_SEQ
