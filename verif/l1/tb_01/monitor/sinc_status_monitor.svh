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
// File        : sinc_status_monitor.svh
// Description : 

`ifndef SINC_STATUS_MONITOR
`define SINC_STATUS_MONITOR

// The SINC_STATUS_MONITOR monitors the SINC's reset event, and SINC status.
class sinc_status_monitor extends uvm_monitor;

  // The SINC wrapper interface.
  typedef virtual interface sinc_v_if sinc_v_if_t;
  sinc_v_if_t m_monitor_if;

  // Analysis port for writing out SINC done
  uvm_analysis_port #(sinc_monitor_pkg::sinc_sideband_e) m_sinc_sideband_ap;

  // Variable: in reset value
  // Flag indicating whether we're in reset.
  local bit m_in_reset = 1;

  // Variable: reset_value
  // Store the current value of reset (for detecting changes)
  logic m_reset;

  // Variable: enable_checks
  // monitor can check on the data format of gathered signals
  bit m_enable_checks = 1;

  `uvm_component_utils_begin(sinc_status_monitor)
    `uvm_field_int (m_enable_checks, UVM_DEFAULT)
  `uvm_component_utils_end

  // Constructor.
  function new(string name="sinc_status_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // UVM Build Phase
  extern virtual function void build_phase(uvm_phase phase);

  // UVM end of elaboration phase. Check that all analysis ports are connected.
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction : end_of_elaboration_phase

  // UVM run phase.
  extern virtual task run_phase(uvm_phase phase);

  // monitor side band sinc_done
  extern virtual task collect_sinc_done();

  // monitor side band sinc_error
  extern virtual task collect_sinc_error();

endclass : sinc_status_monitor

function void sinc_status_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(0 == uvm_config_db #( sinc_v_if_t )::get( null , UVMF_VIRTUAL_INTERFACES, "SINC_V_IF" , m_monitor_if)) begin
    `uvm_fatal("SINC ENV", "uvm_config_db#(sinc_v_if_t)::get cannot find resource SINC_V_IF")
  end

  // Initialize the analysis ports
  m_sinc_sideband_ap = new("m_sinc_sideband_ap", this);

endfunction : build_phase

task sinc_status_monitor::run_phase(uvm_phase phase);
  fork : run_fork

    // sinc side band done single pulse
    begin
      collect_sinc_done();
    end

    // sinc side band error single pulse
    begin
      collect_sinc_error();
    end

  join_none

endtask : run_phase

task sinc_status_monitor::collect_sinc_done();
  sinc_sideband_e sinc_done;
  `uvm_info("SINC_SIDEBAND_SINC_DONE_MON", "started", UVM_LOW)
  forever begin
    @(posedge m_monitor_if.mon_cb.sinc_done);
    sinc_done = SINC_DONE_POSEDGE;
    `uvm_info("SINC_SIDEBAND_SINC_DONE_MON", "detect SINC DONE asserted", UVM_LOW)
    m_sinc_sideband_ap.write(sinc_done);
  end // forever begin

endtask : collect_sinc_done

task sinc_status_monitor::collect_sinc_error();
  sinc_sideband_e sinc_error;
  `uvm_info("SINC_SIDEBAND_SINC_ERROR_MON", "started", UVM_LOW)
  forever begin
    @(posedge m_monitor_if.mon_cb.sinc_err);
    sinc_error = SINC_ERROR_POSEDGE;
    `uvm_info("SINC_SIDEBAND_SINC_ERROR_MON", "detect SINC ERROR asserted", UVM_LOW)
    m_sinc_sideband_ap.write(sinc_error);
  end // forever begin

endtask : collect_sinc_error

`endif // SINC_STATUS_MONITOR
