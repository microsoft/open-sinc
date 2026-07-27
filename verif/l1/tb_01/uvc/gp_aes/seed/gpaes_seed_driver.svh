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
// File        : gpaes_seed_driver.svh
// Description : MSFT GPAES VIP Seed Driver

`ifndef GPAES_SEED_DRIVER__SV
 `define GPAES_SEED_DRIVER__SV

typedef class gpaes_seed_config;

class gpaes_seed_driver extends uvm_driver #(gpaes_seed_transaction);

  protected virtual gpaes_seed_if vif;

  gpaes_seed_transaction incoming_transactions[$];

  protected gpaes_seed_config cfg;

  gpaes_packet_config sys_gpaes_packet_config;

  bit first_transfer = 1;
  bit active_passive=0;
  
  max_seed_data_t seed_data_mask = 0;

  // Semaphore on Start and WDATA for current transaction occupy the ports
  protected semaphore sema_seed_start;

  event reset_driver;

  string logger_str;

  protected string driver_name = "driver";

  protected gpaes_seed_transaction incoming_trans_q[$];

  protected bit dont_drive_x = 0;
  protected bit randomize_dontcares = 0;
  protected bit just_got_reset = 1;
  protected int unsigned clk_cycle = 0;
  protected int unsigned clk_cycle_offset = 0;

  uvm_table_printer printer;

  uvm_analysis_port #(gpaes_seed_transaction) item_driven_port;

  `uvm_component_utils(gpaes_seed_driver)

  function new (string name, uvm_component parent);
    super.new(name, parent);
    item_driven_port = new("item_driven_port", this);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual gpaes_seed_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    end

    printer = new();

    if (!uvm_config_db #(gpaes_seed_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG",{"config must be set for: ",get_full_name(),".cfg"});
    end

    if (!uvm_config_db #(gpaes_packet_config)::get(this, "", "sys_gpaes_packet_cfg", sys_gpaes_packet_config)) begin
      `uvm_fatal("NOCFG",{"gpaes_seed_config must be set for: ",get_full_name(),".sys_gpaes_seed_cfg"});
    end

    //Plusarg override to not drive "X"es; this will be useful for FSDB generation for power estimation.
    if ($value$plusargs("GPAES_SEED_DRV_DONT_DRIVE_X=%0d", dont_drive_x)) begin
      `uvm_info(get_name(), $sformatf("Plusarg Override GPAES_SEED_DRV_DONT_DRIVE_X is set to %0d", dont_drive_x), UVM_MEDIUM)
    end else begin
      dont_drive_x = cfg.dont_drive_x;
      `uvm_info(get_name(), $sformatf("Copied dont_drive_x from cfg; it is set to %0d", dont_drive_x), UVM_DEBUG)
    end

    //Plusarg override to randomize don't cares if needed.
    if ($value$plusargs("GPAES_SEED_DRV_RAND_DONTCARES=%0d", randomize_dontcares)) begin
      `uvm_info(get_name(), $sformatf("Plusarg Override GPAES_SEED_DRV_RAND_DONTCARES is set to %0d", randomize_dontcares), UVM_MEDIUM)
    end else begin
      randomize_dontcares = cfg.randomize_dontcares;
      `uvm_info(get_name(), $sformatf("Copied randomize_dontcares from cfg; it is set to %0d", randomize_dontcares), UVM_DEBUG)
    end

    if (dont_drive_x == 1'b1 && randomize_dontcares == 1'b0) begin
      `uvm_warning(get_name(), $sformatf("dont_drive_x is set to 1 and randomize_dontcares is set to 0; this combination should be used only for power estimation FSDB generation; not for functional tests as this could mask certain bugs."))
    end

    driver_name = {cfg.agent_name, ".gpaes_seed_drvr"};
    logger_str      = get_name();

    sema_seed_start = new(1);
    
    for (int i=0; i < cfg.m_seed_data_width; i++) begin
      seed_data_mask[i] = 1;;
    end

  endfunction: build_phase

  // run phase
  virtual task run_phase(uvm_phase phase);
    //Wait for reset
    wait (vif.ARESETn == 0);
    reset_signals();

    forever begin
      @(posedge vif.ARESETn);
      fork
        get_and_drive_item();
        active_drive_trivium_seed_data();
        clk_cyc_counter();
      join_none
      @(reset_driver);
      `uvm_info(driver_name, $sformatf("DYNAMIC_RESET: Resetting driver\n"), UVM_DEBUG)
      disable fork;
        wait (vif.ARESETn == 0);
        reset_signals();
        cleanup();
      end
  endtask : run_phase

  function void cleanup;
    int unsigned i;
    `uvm_info(driver_name, $sformatf("DYNAMIC_RESET: cleanup after reset\n"), UVM_DEBUG)
    just_got_reset = 1;
    sema_seed_start = new(1);
  endfunction

  // Utility task to wait for a number of clock cycles.
  // This is a method of class syncBus_monitor.
  task automatic wait_clocks(int N = 1);
    if (N<0) N = 0; // protect against user error!
    repeat(N) @(posedge vif.ACLK);
  endtask : wait_clocks

  task clk_cyc_counter();
    forever
      begin
        @(posedge vif.ACLK);
        clk_cycle = clk_cycle+1;
      end
  endtask : clk_cyc_counter


  // get_and_drive
  virtual protected task get_and_drive_item();
    forever begin : get_and_drive_forever
      fork
        get_items();
        drive_items();
      join
    end : get_and_drive_forever
  endtask : get_and_drive_item

  virtual protected task get_items();
    automatic gpaes_seed_transaction drv_item;
    forever begin : get_forever
      seq_item_port.get_next_item(req);
      req.accept_tr();
      req.begin_tr();
      drv_item = new("drv_item");
      $cast(drv_item, req.clone());
      drv_item.set_id_info(req);
      incoming_transactions.push_back(req);
      `uvm_info(driver_name, $sformatf("TRANS_PUSH: seq_id: 0x%0x; trans_id: 0x%0x;", drv_item.get_sequence_id(), drv_item.get_transaction_id()), UVM_HIGH)
      seq_item_port.item_done();
    end : get_forever
  endtask : get_items

  // reset_signals
  task reset_signals();
    gpaes_seed_transaction init_tr;
    `uvm_info(driver_name, $sformatf("DYNAMIC_RESET: Resetting signals\n"), UVM_HIGH)
    vif.seed_i      = 0;
    vif.seed_vld_i  = 1'b0;
  endtask : reset_signals

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if(incoming_trans_q.size>0) begin
      `uvm_error(get_type_name(), $psprintf("There are still pending xaction in incoming_trans_q.size:%0d", incoming_trans_q.size));
    end
  endfunction

  task end_transfer(gpaes_seed_transaction rsp);
    fork : put_rsp
      begin
        seq_item_port.put(rsp);
      end
    join_none
    end_tr(rsp);
  endtask : end_transfer

  virtual task drive_items();
    automatic gpaes_seed_transaction drv_item;
    gpaes_seed_transaction tr;

    forever begin : drive_items_forever
      // while ((vif.ARESETn === 1'b0) || (incoming_transactions.size() == 0)) begin
      //   @(vif.cb_master);
      // end
      wait (incoming_transactions.size() != 0);
      tr = incoming_transactions.pop_front();
      drv_item = new("drv_item");
      $cast(drv_item, tr.clone());
      drv_item.set_id_info(tr);
      fork : drive_seed_fork
        initiate_and_get_response(drv_item);
      join_none
      @(posedge vif.ACLK);
    end : drive_items_forever
  endtask : drive_items

  virtual task automatic initiate_and_get_response(gpaes_seed_transaction initiator_trans);
    gpaes_seed_transaction seed_rsp;
    bit is_sema_owner;

    `uvm_info(driver_name, $sformatf("SEED_TRANS_START: seq_id: 0x%0x; trans_id: 0x%0x", initiator_trans.get_sequence_id(), initiator_trans.get_transaction_id()), UVM_HIGH)
    drive_single_seed (initiator_trans);

    // ********************************************** //
    // Seed before Seed done, currently not supported //
    // ********************************************** //

  endtask : initiate_and_get_response

  // get_and_drive
  virtual protected task active_drive_trivium_seed_data();
    max_seed_data_t m_rng_data;
    int unsigned seed_data_trans_cnt = 0;
    forever begin
      @(posedge vif.ACLK);
      if (!sema_seed_start.try_get(1)) begin
        continue;
      end
      if (cfg.m_reactive_driver && !sys_gpaes_packet_config.m_is_gpaes_req_packet_active) begin // reactive drive random data to seed interface
        if (vif.seed_rdy_o) begin
          if (!std::randomize(m_rng_data)) begin
            `uvm_fatal(get_name(), "Unable to randomize m_rng_data")
          end
          `uvm_info(driver_name, $sformatf("REACTIVE_DRIVE_TRIVIUM_SEED_DATA: [%0h]", m_rng_data & seed_data_mask), UVM_HIGH)
          vif.seed_vld_i <= 1;
          vif.seed_i     <= max_seed_data_t'(m_rng_data & seed_data_mask);
        end
      end else if (sys_gpaes_packet_config.m_is_gpaes_req_packet_active) begin // drive preset seed when there is ongoing sys level req packet
        // cast to max seed
        m_rng_data = max_seed_data_t'(sys_gpaes_packet_config.seed[seed_data_trans_cnt]);
        `uvm_info(driver_name, $sformatf("DRIVE_PRESET_SEED_DATA: [%0h]", m_rng_data & seed_data_mask), UVM_HIGH)
        vif.seed_vld_i <= 1;
        vif.seed_i     <= max_seed_data_t'(m_rng_data & seed_data_mask);
        seed_data_trans_cnt++;
        if (seed_data_trans_cnt == sys_gpaes_packet_config.seed.size()) begin
          seed_data_trans_cnt = 0;
        end
      end else begin
        vif.seed_vld_i <= 0;
        vif.seed_i     <= 0;
      end

      sema_seed_start.put(1);    
    end // forever begin
    
  endtask : active_drive_trivium_seed_data

  virtual task automatic drive_single_seed(gpaes_seed_transaction initiator_trans);
    gpaes_seed_transaction seed_rsp;
    bit is_sema_owner;

    `uvm_info(driver_name, $sformatf("Single Seed Start: seq_id: 0x%0x; trans_id: 0x%0x, seed_data.size: %0d", initiator_trans.get_sequence_id(), initiator_trans.get_transaction_id(), initiator_trans.m_seed_data.size()), UVM_HIGH)
    
    // acquire the semaphore first to make sure the seed port is idle
    sema_seed_start.get(1);

    // assert seed start for one clock
    @(posedge vif.ACLK);
    
    // wait for seed transaction done
    fork
      begin
        fork
          begin // wait for seed done
            for (int i = 0; i < initiator_trans.m_seed_data.size(); i++) begin
              vif.seed_vld_i <= 1;
              vif.seed_i     <= max_seed_data_t'(initiator_trans.m_seed_data[i] & seed_data_mask);
              @(posedge vif.ACLK);
            end
          end
          begin // collect write data            
            // timeout
            repeat (cfg.tr_timeout) @(posedge vif.ACLK);
            if (!cfg.suppress_error) begin
              `uvm_error(logger_str, $sformatf("Timeout waiting for current Seed transaction finishing drive seeds [%0p]",
                                               initiator_trans.m_seed_data))
            end else begin
              `uvm_info(logger_str, $sformatf("Timeout waiting for current Seed transaction finishing drive seeds [%0p]", initiator_trans.m_seed_data), UVM_HIGH)
            end
          end
        join_any
        disable fork;
      end
    join // extra level of hierarchy to limit the scope of disable label

    vif.seed_vld_i <= 0;
    vif.seed_i     <= 0;

    sema_seed_start.put(1);

    is_sema_owner = 0;

    `uvm_info(driver_name, $sformatf("SEED_TRANS_DRIVE_SEED_FORK: %s", initiator_trans.convert2string()), UVM_HIGH)

    seq_item_port.put_response(initiator_trans);
    initiator_trans.end_tr();

    // ********************************************* //
    // Seed Started Seed, currently not supported //
    // ********************************************* //

  endtask : drive_single_seed

endclass : gpaes_seed_driver

`endif //GPAES_SEED_DRIVER__SV

