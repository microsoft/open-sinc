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
// File        : gpaes_seed_base_sequence.svh
// Description : This file contains the class used as the base class for all

`ifndef GPAES_SEED_BASE_SEQUENCE
`define GPAES_SEED_BASE_SEQUENCE

class gpaes_seed_base_sequence extends uvm_sequence #(.REQ(gpaes_seed_transaction), .RSP(gpaes_seed_transaction));

  `uvm_object_utils(gpaes_seed_base_sequence)

  `uvm_declare_p_sequencer(gpaes_seed_sequencer)

  event seq_done_e;

  typedef gpaes_seed_transaction gpaes_seed_transaction_req_t;
  gpaes_seed_transaction_req_t m_req;
  typedef gpaes_seed_transaction gpaes_seed_transaction_rsp_t;
  gpaes_seed_transaction_rsp_t m_rsp;

  gpaes_seed_config m_cfg;

  event m_new_rsp;

  int next_trans_id;

  int ongoing_xact_cnt;

  function new( string name ="");
    super.new( name );
    m_req = gpaes_seed_transaction_req_t::type_id::create("m_req", , get_full_name());
    m_rsp = gpaes_seed_transaction_rsp_t::type_id::create("m_rsp", , get_full_name());
  endfunction : new

  virtual function void configure(gpaes_seed_config cfg);
    m_cfg = cfg;
  endfunction : configure

  virtual task get_responses();
    fork : thread1
      begin
        get_response(m_rsp);
        ->m_new_rsp;
        `uvm_info(get_type_name(), {"New response transaction:", m_rsp.convert2string()}, UVM_MEDIUM)
      end
    join_none
  endtask : get_responses

  virtual task body();
    // Setup local variables
    seq_setup();
    m_req.configure(m_cfg);
    `uvm_info(get_name(), "Erase sequence and waiting for done", UVM_NONE)

    // erase base sequence does not introduce start transactions

    wait(seq_done_e.triggered);
    `uvm_info(get_name(), "Erase sequence done", UVM_NONE)
  endtask : body

  // Base Sequence Setup task
  task seq_setup();
    m_cfg = p_sequencer.get_cfg();
    `uvm_info(get_type_name(), "seq_setup done\n", UVM_HIGH)
  endtask : seq_setup

  // Suggested task to issue firmware erase from creg
  extern virtual task gpaes_seed_start (gpaes_seed_transaction seed_tr);

  extern virtual task wait_for_xaction_done();

endclass : gpaes_seed_base_sequence

task gpaes_seed_base_sequence::gpaes_seed_start
  (
   //Required
   gpaes_seed_transaction seed_tr
   );

  gpaes_seed_transaction_req_t trans, trans_resp;

  // each trasaction from this erase has unique id
  int my_trans_id = next_trans_id++;

  `uvm_info(get_type_name(), $sformatf("gpaes_seed_start, tr_id %0s\n", my_trans_id), UVM_HIGH)

  //Create transaction
  `uvm_create(trans)

  // pass erase config
  trans.configure(m_cfg);
  trans.set_transaction_id(my_trans_id);

  assert(trans.randomize() with
         {
          // 
          });

  if (seed_tr !== null) begin
    trans.m_seed_data = seed_tr.m_seed_data;
  end

  //Send transaction
  `uvm_info(get_type_name(), $sformatf("Sending Transaction: %s\n", trans.convert2string()), UVM_HIGH)

  fork
    begin : request
      `uvm_send(trans);
      ongoing_xact_cnt++;
      `uvm_info(get_type_name(), $sformatf("Sent Transaction: %s\n", trans.convert2string()), UVM_HIGH)
    end : request
    begin : response
      // trans_resp = gpaes_seed_transaction_rsp_t::type_id::create("m_rsp", , get_full_name());
      `uvm_info(get_type_name(), $sformatf("Wait for Response on trans_id : %0d\n", my_trans_id), UVM_HIGH)
      get_response(trans_resp, my_trans_id);
      ongoing_xact_cnt--;
      `uvm_info(get_type_name(), $sformatf("Got Response   : %s\n", trans_resp.convert2string()), UVM_HIGH)
    end : response
  join

endtask: gpaes_seed_start

// wait until all pending transaction receive response
task gpaes_seed_base_sequence::wait_for_xaction_done();
  wait (ongoing_xact_cnt == 0);
endtask : wait_for_xaction_done

`endif // GPAES_SEED_BASE_SEQUENCE
