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
// File        : gpaes_seed_monitor.svh
// Description : MSFT RanWrao Seed monitor.

`ifndef GPAES_SEED_MONITOR__SVH
 `define GPAES_SEED_MONITOR__SVH

 `define GPAES_SEED_PMP vif_mp
 `define GPAES_SEED_PCB `GPAES_SEED_PMP.cb_passive

typedef class gpaes_seed_config;
class gpaes_seed_monitor extends uvm_monitor;

  // This property is the virtual interfaced needed for this component to drive
  // and view HDL signals.
  protected virtual gpaes_seed_if vif;
  protected gpaes_seed_passive_vif vif_mp;

  // The following two bits are used to control whether checks and coverage are
  // done both in the monitor class and the interface.
  bit checks_enable = 1;
  bit coverage_enable = 1;

  protected string monitor_name = "trans_monitor";

  //Unique ID de-limiter
  local string uid;

  gpaes_seed_config cfg;
  
  max_seed_data_t seed_data_mask = 0;

  //Global counter to keep track of relative timing between the transfers
  protected int unsigned g_cntr = 0;
  //Global counter keeping track of clock cycle of the last transaction (Rd or Wr)
  protected int unsigned g_last_cntr = 0;
  // Transaction timeout in units of clock cycles (track pending response for each request issued)
  // = 0 ---> timeout disabled/inactive
  // > 0 ---> timeout monitored for each request issued
  protected int unsigned timeout = 0;

  string logger_str;


  uvm_analysis_port #(gpaes_seed_transaction) item_collected_port;

  // The following property holds the transaction information currently
  // begin captured (by the collect_address_phase and data_phase methods).
  protected gpaes_seed_transaction trans_collected;

  // gpaes_seed_coverage      gpaes_seed_cov;

  `uvm_component_utils_begin(gpaes_seed_monitor)
    `uvm_field_int(checks_enable, UVM_DEFAULT)
    `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_component_utils_end


  function new( string name = "", uvm_component parent = null );
    super.new( name, parent );
    trans_collected = new();
    item_collected_port = new("item_collected_port", this);
    uid = "__";
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual gpaes_seed_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_uid("BUILD_PHASE","001"),{"virtual interface must be set for: ",get_full_name(),".vif"});
    end else begin
      vif_mp = vif.mp_passive;
    end

    if (!uvm_config_db #(gpaes_seed_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_uid("BUILD_PHASE","002"),{"config must be set for: ",get_full_name(),".cfg"});
    end
    
    for (int i=0; i < cfg.m_seed_data_width; i++) begin
      seed_data_mask[i] = 1;;
    end
    
    monitor_name    = {cfg.agent_name, uid ,"GPAES_SEED_MON"};
    timeout         = cfg.tr_timeout;
    config_checks(cfg);
    logger_str      = get_name();
    // seed_cov                                              = gpaes_seed_coverage::type_id::create("seed_cov", this);
  endfunction: build_phase

  //Since monitor is common across master/slave, adding here. Better to be part of Agent but this also serves same as monitor always there passive or active.
  virtual function void config_checks(gpaes_seed_config cfg);
    if(cfg.m_seed_data_width  > `GPAES_MAX_SEED_DATA_WIDTH) begin
      `uvm_fatal(get_uid("CONFIG_CHECKS","m_seed_data_width"), $sformatf("Invalid config - cfg.m_seed_data_width(%0d)  > `GPAES_MAX_SEED_DATA_WIDTH (%0d), Fix define value!", cfg.m_seed_data_width, `GPAES_MAX_SEED_DATA_WIDTH));
    end
  endfunction


  virtual function string get_uid(string method_name,string unique_number);
    get_uid = {monitor_name,uid,method_name,uid,unique_number};
  endfunction

  virtual task run_phase(uvm_phase phase);

    forever begin
      @(posedge `GPAES_SEED_PCB.ARESETn)
        fork
          time_cntr();
          monitor_transfers();

          if (coverage_enable) begin
            fork
              // cov_cmdtype();
            join_none
          end
        join_none
      @(negedge `GPAES_SEED_PCB.ARESETn)
        disable fork;
          cleanup();
        end //forever

  endtask : run_phase

  // cleanup
  function void cleanup();
    int unsigned i;
    `uvm_info(monitor_name, $sformatf("cleanup called after dynamic reset\n"), UVM_DEBUG)
  endfunction : cleanup

  // time_cntr
  virtual protected task time_cntr();
    forever
      begin
        @(`GPAES_SEED_PCB);
        g_cntr <= g_cntr+1;
      end //forever
  endtask : time_cntr

  // monitor_transfers
  virtual protected task monitor_transfers();
    @(`GPAES_SEED_PCB);
    `uvm_info(monitor_name, "monitor_transfer executed", UVM_FULL)
    fork
      do_monitor();
    join
  endtask : monitor_transfers

  task automatic do_monitor();
    gpaes_seed_transaction trans;
    int trasaction_count = 0;

    `uvm_info(monitor_name, "start monitoring seed transaction", UVM_HIGH)

    forever begin
      int num_seed_transactions = 0;

      // wait for seed_start be asserted
      while ((`GPAES_SEED_PCB.seed_vld_i === 1'b0) || (`GPAES_SEED_PCB.seed_rdy_o === 1'b0)) begin
        @`GPAES_SEED_PCB;
      end
      
      `uvm_info(monitor_name, "Observe seed transaction start", UVM_HIGH)

      trans = new("trans"); //gpaes_seed_transaction::type_id::create("trans");
      trans.configure(cfg);
      if (!trans.randomize()) begin
        `uvm_fatal(logger_str, "Randomization failed.")
      end
      trans.m_event = START;
      notify_transaction(trans);
      num_seed_transactions = trans.m_seed_data.size();     

      // wait for totol seed transaction reach seed size of bits
      fork
        begin
          fork
            begin // wait for seed done
              automatic int i = 0;
              automatic int seed_in_bits = 0;
              while (seed_in_bits < cfg.m_seed_size_in_bits) begin
		if ((`GPAES_SEED_PCB.seed_vld_i === 1'b1) && (`GPAES_SEED_PCB.seed_rdy_o === 1'b1)) begin
		  trans.m_seed_data[i] = `GPAES_SEED_PCB.seed_i & seed_data_mask;
		  
                  i++;
                  seed_in_bits = seed_in_bits + cfg.m_seed_data_width;
		end
                
                if (seed_in_bits >= cfg.m_seed_size_in_bits) begin
                  break;
                end
                @`GPAES_SEED_PCB; //(posedge vif.ACLK);
              end
            end
            begin // collect seed data
              repeat (5000) @`GPAES_SEED_PCB; //(posedge vif.ACLK);
              // timeout
              repeat (cfg.tr_timeout) @`GPAES_SEED_PCB; //(posedge vif.ACLK);
              if (!cfg.suppress_error) begin
                `uvm_error(logger_str, $sformatf("Timeout waiting for current Seed transaction finishing collected seed transactions [%0d]",
                                                 trasaction_count))
              end
            end
          join_any
          disable fork;
        end
      join // extra level of hierarchy to limit the scope of disable label

      `uvm_info(monitor_name, "Observe seed transaction done", UVM_HIGH)
      //trans.m_done = 1'b1;
      trans.m_event = DONE;
      notify_transaction(trans);

      @`GPAES_SEED_PCB; //(posedge vif.ACLK);
    end

  endtask : do_monitor


  virtual function void notify_transaction(gpaes_seed_transaction monitored_trans);
    gpaes_seed_transaction trans = gpaes_seed_transaction::type_id::create("trans");
    trans.copy(monitored_trans);
    trans.m_cfg = cfg;
    // analyze(trans);
    `uvm_info("MON", trans.convert2string(),UVM_HIGH);
    //Broadcast this item through the analysis port
    item_collected_port.write(trans);
    // leave for sample cov
  endfunction : notify_transaction

  task wait_for_reset();
    @(`GPAES_SEED_PCB);
    do_wait_for_reset();
  endtask : wait_for_reset

  task do_wait_for_reset();
    wait ( `GPAES_SEED_PCB.ARESETn === 1 );
    @(`GPAES_SEED_PCB);
  endtask : do_wait_for_reset

  task wait_for_num_clocks(input int unsigned count);
    repeat (count) begin
      @(`GPAES_SEED_PCB);
    end
  endtask : wait_for_num_clocks

endclass : gpaes_seed_monitor




`endif //GPAES_SEED_MONITOR__SVH

