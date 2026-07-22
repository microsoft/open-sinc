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
// File        : sinc_virtual_sequencer.svh
// Description : 

`ifndef SINC_VIRTUAL_SEQUENCER
`define SINC_VIRTUAL_SEQUENCER

class sinc_virtual_sequencer extends uvm_virtual_sequencer;

  rst_sequencer        m_rst_sequencer;
  pal_master_sequencer m_pal_sequencer;
  tb_virtual_sequencer m_tb_vseqr;

  typedef uvm_sequencer #(ramwrap_inject_transaction) inject_sequencer_t;
  // general handler for ramwrap_sys_wrapper
  ramwrap_sys_wrapper_virtual_sequencer m_ramwrap_sys_wrapper_vseqr;
  ramwrap_erase_sequencer               m_cache_mem_erase_agent_seqr;
  ramwrap_erase_sequencer               m_cache_vtag_erase_agent_seqr;
    
  gpaes_sys_wrapper_virtual_sequencer   m_gpaes_sys_wrapper_vseqr;
  gpaes_seed_sequencer                  m_gpaes_seed_agent_seqr;
  
  inject_sequencer_t                    m_cache_mem_ramwrap_inj_agent_seqr;
  // inject_sequencer_t        m_cache_vtag_inject_agent_seqr;

  // CCPUI Sequencers
  ccpui_cpu_mem_sequencer m_cpu_mem_agent_seqr;
  ccpui_mpu_sequencer     m_mpu_agent_seqr;

  `uvm_component_utils(sinc_virtual_sequencer)

  extern function new(string name, uvm_component parent);

endclass : sinc_virtual_sequencer

/**
 *
 * @see uvm_pkg::uvm_sequencer.new
 * @param name - instance name
 * @param parent - parent
 * @return nothing
 */
function sinc_virtual_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

`endif // SINC_VIRTUAL_SEQUENCER
