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
// File        : gpaes_seed_transaction.svh
// Description : 

`ifndef GPAES_SEED_TRANSACTION
 `define GPAES_SEED_TRANSACTION

typedef class gpaes_seed_config;

class gpaes_seed_transaction extends uvmf_transaction_base;

  `uvm_object_utils(gpaes_seed_transaction)

  rand max_seed_data_t m_seed_data[]; /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE SVTB.6.10 */

  // delays to introduce when seeding
  rand int unsigned m_delay;

  // indicate seed start/done event
  seed_event_e m_event;

  gpaes_seed_config m_cfg;

  extern function new(string name = "");

  extern virtual function void configure(gpaes_seed_config cfg);

  extern function void post_randomize();

  extern virtual function string convert2string();

  extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

  extern virtual function void do_copy(uvm_object rhs);

  constraint c_delay {
    m_delay dist { 'h0 :/ 70, [1:50] :/ 20,  [51:100] :/ 10};
  }

  constraint c_seed_data_size {
    m_seed_data.size() == m_cfg.m_seed_size_in_bits / m_cfg.m_seed_data_width;
  }

endclass : gpaes_seed_transaction

function gpaes_seed_transaction::new(string name = "");
  super.new( name );
endfunction : new

function void gpaes_seed_transaction::configure(gpaes_seed_config cfg);
  m_cfg = cfg;
endfunction : configure

function string gpaes_seed_transaction::convert2string();
  string msg = $sformatf("\n \
-------------------------SEED TRANS------------------------- \n \
NAME             VALUE \n \
data_size    = %0d \n \
m_delay      = %0d \n \
--------------------------------------------------------------\n", m_seed_data.size(), m_delay);
    
    
    
  foreach (m_seed_data[i]) begin
      msg = $sformatf("%s  seed_data[%0d]             = %0h\n", msg, i, m_seed_data[i]);
  end
  
  return (msg);
endfunction : convert2string

function bit gpaes_seed_transaction::do_compare(uvm_object rhs, uvm_comparer comparer); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.2.1.1 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.1.4.4.2 */
  gpaes_seed_transaction rhs_;
  bit result = super.do_compare(rhs, comparer);
  if (!$cast(rhs_, rhs)) return (0);
  foreach (rhs_.m_seed_data[i]) begin
    result &= comparer.compare_field($sformatf("m_data[%0d]", i), m_seed_data[i], rhs_.m_seed_data[i], m_cfg.m_seed_data_width);
  end
  return (result);
endfunction : do_compare

function void gpaes_seed_transaction::do_copy(uvm_object rhs); /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.2.2.1 */ /* @DVT_LINTER_WAIVER "Generated Code Waiver" DISABLE UVM.3.1.4.3.2 */
  gpaes_seed_transaction rhs_;
  if (!$cast(rhs_, rhs)) begin
    `uvm_fatal(get_type_name(), "Cast failed.")
  end
  super.do_copy(rhs);
  m_event = rhs_.m_event;
  m_delay = rhs_.m_delay;
  m_seed_data = new [rhs_.m_seed_data.size()];
  foreach (rhs_.m_seed_data[i]) begin
    m_seed_data[i] = rhs_.m_seed_data[i];
  end

endfunction : do_copy

function void gpaes_seed_transaction::post_randomize();
  // leave blank
endfunction : post_randomize


`endif // GPAES_SEED_TRANSACTION
