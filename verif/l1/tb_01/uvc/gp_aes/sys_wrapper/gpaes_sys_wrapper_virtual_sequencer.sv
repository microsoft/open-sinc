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
// File        : gpaes_sys_wrapper_virtual_sequencer.sv
// Description : Central Virtual Sequencer for Multiple Gpaesper System UVM Environment

`ifndef GPAES_SYS_WRAPPER_VIRTUAL_SEQUENCER
`define GPAES_SYS_WRAPPER_VIRTUAL_SEQUENCER

class gpaes_sys_wrapper_virtual_sequencer extends uvm_virtual_sequencer;

    `uvm_component_utils(gpaes_sys_wrapper_virtual_sequencer)

    //gpaes virtual sequencer handles to each system
    gpaes_sys_virtual_sequencer gpaes_sys_vseqr[];

    // Back Door Access component
    //gpaes_peek_poke_base     peek_poke;

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);

endclass : gpaes_sys_wrapper_virtual_sequencer

/**
 *
 * @see uvm_pkg::uvm_sequencer.new
 * @param name - instance name
 * @param parent - parent
 * @return nothing
 */
function gpaes_sys_wrapper_virtual_sequencer::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction: new

/**
 *
 * @see uvm_pkg::uvm_sequencer_param_base.build_phase
 * @param phase - uvm phase
 */
function void gpaes_sys_wrapper_virtual_sequencer::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction: build_phase

`endif  // GPAES_SYS_WRAPPER_VIRTUAL_SEQUENCER

