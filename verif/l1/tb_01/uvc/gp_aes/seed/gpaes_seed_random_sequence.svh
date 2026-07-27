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
// File        : gpaes_seed_random_sequence.svh
// Description : 

`ifndef GPAES_SEED_RANDOM_SEQUENCE
`define GPAES_SEED_RANDOM_SEQUENCE
//
//----------------------------------------------------------------------
// Creation Date   : 1/29/2025
//----------------------------------------------------------------------
// DESCRIPTION:
//
// This sequences randomizes the gpaes_seed transaction and sends it
// to the UVM driver.
//
// This sequence constructs and randomizes a gpaes_seed_transaction.
//----------------------------------------------------------------------
//
class gpaes_seed_random_sequence extends gpaes_seed_base_sequence;

  `uvm_object_utils(gpaes_seed_random_sequence)

  function new(string name = "");
    super.new(name);
  endfunction: new

  virtual task body();
    m_req = gpaes_seed_transaction::type_id::create("m_req", , get_full_name());
    m_req.configure(m_cfg);
    start_item(m_req);
    if(!m_req.randomize()) `uvm_fatal("SEQ", "gpaes_seed_random_sequence::body()-gpaes_seed_transaction randomization failed")
    finish_item(m_req);
    `uvm_info(get_type_name(), {"Response:", m_req.convert2string()}, UVM_MEDIUM)
  endtask : body

endclass: gpaes_seed_random_sequence

`endif // GPAES_SEED_RANDOM_SEQUENCE
