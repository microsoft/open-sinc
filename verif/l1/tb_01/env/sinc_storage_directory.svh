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
// File        : sinc_storage_directory.svh
// Description : This class defines the methods implementation on in directory's interface.

`ifndef SINC_STORAGE_DIRECTORY_SVH
 `define SINC_STORAGE_DIRECTORY_SVH

class sinc_storage_directory extends sinc_storage_directory_intf; // {
  bit SINC_KSD_PASSIVE;

  `uvm_component_utils_begin(sinc_storage_directory)
    `uvm_field_int(SINC_KSD_PASSIVE, UVM_DEFAULT);
  `uvm_component_utils_end

  protected static sinc_storage_directory _storage_directory_instance;

  //The Current UVM phase
  uvm_phase current_phase;

  // memory back door interface
  typedef virtual sinc_mem_bkdoor_if    sinc_mem_bkdoor_if_t;
  sinc_mem_bkdoor_if_t                  mem_bkdoor_if_h;

  //
  // Analysis port for Reset UVC connection
  //
  `uvm_analysis_imp_decl(_reset_xp)
  uvm_analysis_imp_reset_xp#(rst_pkg::rst_seq_item, sinc_storage_directory) reset_xp;

  //
  // Analysis port for side-band erase
  //
  // `uvm_analysis_imp_decl(_sideband_erase_xp)
  // uvm_analysis_imp_sideband_erase_xp#(sinc_env_pkg::sinc_erase_e, sinc_storage_directory) sideband_erase_xp;

  //
  // Analysis port for side-band sinc_done
  //
  // `uvm_analysis_imp_decl(_sideband_sinc_done_xp)
  // uvm_analysis_imp_sideband_sinc_done_xp#(sinc_env_pkg::sinc_sideband_done_e, sinc_storage_directory) sideband_sinc_done_xp;

  //
  // Analysis port implementations for all channels on all AXI ports
  //
  `uvm_analysis_imp_decl(_sinc_axi_mst_ae)
  uvm_analysis_imp_sinc_axi_mst_ae #(pal_xaction, sinc_storage_directory) sinc_axi_mst_ae;

  `uvm_analysis_imp_decl(_sinc_key_mem_erase_ae)
  uvm_analysis_imp_sinc_key_mem_erase_ae #(ramwrap_erase_transaction, sinc_storage_directory) sinc_key_mem_erase_ae;


  // Variable: sys_cfg
  // config parameters for each SINC component on each SINC
  sinc_env_pkg::sinc_sys_cfg m_sys_cfg;

  // Variable: top_configuration
  // Top leveel configuration handler
  sinc_env_configuration top_configuration;

  // Variable addr_dec_t
  // Address Decoder Type
  typedef sinc_env_pkg::sinc_address_decoder addr_dec_t;

  // Flag to indicate if check is enabled
  bit self_check_enable = 1;

  // Group: Fields

  // Variable: addr_dec
  // Address Decoder
  addr_dec_t  addr_dec;

  // variable: outstanding_requests
  // local sinc_storage_state       outstanding_requests[full_tag_t];
  // local sinc_env_pkg::sinc_cmd_e   outstanding_cmds[full_tag_t];
  // local bit [7:0]              outstanding_req_attr[full_tag_t];
  // local bit                    outstanding_req_ack[full_tag_t];
  // local int                    outstanding_mstr_num[full_tag_t];


  pal_xaction axi_req_item;   // Used for command decode routines built in, use for AXI master type

  // set to one to automatically create slot if slot not exist during is_req_valid check.
  bit                          auto_slot_cfg_is_active = 0;

  // Passive Mode
  local bit                    passive_mode = 0;                  // Default is active mode

  // Track reset state
  local bit in_reset = 0;
  local bit reset_done = 0;

  // Log SINC init_sinc_hold has been asserted
  local int     sinc_init_hold_asserted = 0;
  local int     sinc_init_on_hold = 0;

  // Keep a count of acks tracked
  local int ack_count = 1;

  // Log erase_enable event
  local int erase_done = 0;
  sinc_env_pkg::sinc_erase_e m_sinc_erase_status = SINC_ERASE_INACTIVE;
  local bit clear_pcr_after_erase = 1'b0;

  // EDC error injection enable
  bit       edc_err_inj_en = 0;

  int req_unitid;
  int rsp_unitid;

  // ********************************************************************************

  extern function      new(string name, uvm_component parent);
  extern virtual task  reset_phase(uvm_phase phase);
  extern virtual function void phase_started(uvm_phase phase);
  extern function void build_phase(uvm_phase phase);
  extern task          run_phase(uvm_phase phase);
  extern function void extract_phase(uvm_phase phase);

  // ********************************************************************************
  // ********************************************************************************
  // Function: get_storage_directory_inst
  // A static function which returns the singleton instance of this class.
  //
  static function sinc_storage_directory get_storage_directory_inst();
    if (_storage_directory_instance != null) begin
      return _storage_directory_instance;
    end
    else begin
      return null;
    end
  endfunction : get_storage_directory_inst

  extern virtual function void set_passive_mode(bit new_value);
  extern virtual function bit get_passive_mode();


  // ********************************************************************************
  // ********************************************************************************
  // Function: sending_axi_req
  // Called by sequence when a request will be sent to the sequencer.
  // Log this as an outstanding request pending, this will be used to determine
  // the validity of requests following.
  //
  extern virtual function void sending_axi_req(
                                               sinc_env_pkg::sinc_comp_e mstr_id,
                                               sinc_env_pkg::address_t addr,
                                               sinc_env_pkg::sinc_cmd_e cmd,
                                               bit check_req_valid=1
                                               );

  // ********************************************************************************
  // ********************************************************************************
  // Function: is_req_valid
  // Given an address and a master request cmd type, returns true if the requested cmd can be issued for that address.
  // Called by sequence during is_relevant.

  //  Additionally the sequence should call this method when responding
  // to the response packet to check for CANCEL indication.

  //  Similar to make_request except that it does not allocate new storage state.
  extern virtual function int is_req_valid(
                                           sinc_env_pkg::sinc_comp_e mstr_id,
                                           sinc_env_pkg::address_t addr,
                                           sinc_env_pkg::sinc_cmd_e cmd,
                                           bit create_storage_state = 0
                                           );

  // ********************************************************************************
  // ********************************************************************************
  // Function: is_cmd_valid
  extern virtual function int is_cmd_valid(
                                           sinc_env_pkg::sinc_comp_e mstr_id,
                                           sinc_env_pkg::address_t addr,
                                           sinc_env_pkg::sinc_cmd_e cmd
                                           );


  // ********************************************************************************
  // ********************************************************************************
  // Function: make_request
  //  Given an address, a mstr_id, and a command, make a request to the storage diretory
  //  for valid storage state.  It will new allocate new storage state if necessary.
  //  Returns 1 for success.
  extern virtual function int make_request(
                                           sinc_env_pkg::sinc_comp_e mstr_id,
                                           sinc_env_pkg::address_t addr,
                                           sinc_env_pkg::sinc_cmd_e cmd,
                                           bit init_line_data=0
                                           );

  // ********************************************************************************
  // ********************************************************************************
  // Function: gen_valid_attr
  // extern virtual function set_valid_with_slot(
  //                                                   sinc_env_pkg::sinc_comp_e mstr_id,
  //                                                   sinc_env_pkg::address_t addr,
  //                                                   sinc_env_pkg::sinc_cmd_e cmd
  //                                                   );


  // ********************************************************************************
  // ********************************************************************************
  // Function: make_request_with_cmd
  //  Given a memory block from the memory manager, request type, and mstr_id, return an address within the
  // memory block for which it is legal to issue the request.  It will create a new storage state if none exists
  // for the requested address.
  // extern virtual function sinc_storage_state  make_request_with_cmd(
  //                                                                  sinc_env_pkg::sinc_comp_e mstr_id,
  //                                                                  sinc_env_pkg::sinc_cmd_e cmd
  //                                                                  );

  // Function: wr_storage_data
  // Write storage
  // Will write all data starting at addr.  Line must be valid.  Can not cross storage slot boundary
  extern virtual function void wr_storage_data(sinc_env_pkg::address_t addr, bit [7:0] wr_bytes[$]);

  // ****************************************
  // Function: rd_storage_data
  // Read storage data
  // Will read starting at addr.  Line must be valid.  Can not cross storage line boundary
  extern virtual function void rd_storage_data(sinc_env_pkg::address_t addr, int size_in_bytes, ref bit [7:0] rd_bytes[$]);

  // ****************************************
  // Function: get_req_pending
  // If storage state exists returns
  // extern virtual function int get_req_pending(sinc_env_pkg::sinc_comp_e mstr_id, sinc_env_pkg::address_t addr
  //                                             );

  // ****************************************
  // Function: storage_state_exists
  // Returns the 1 if slot state exists for this address
  // extern virtual function bit storage_state_exists(sinc_env_pkg::address_type_e dst_addr_type, int slot);

  // ********************************************************************************
  // ********************************************************************************
  // Function: print_outstanding_requests
  // Prints all outstanding requests
  extern function void print_outstanding_requests();

  // ********************************************************************************
  // ********************************************************************************
  // Function: complete_request
  // Request has completed.  Remove outstanding_request
  // extern function void complete_request(sinc_env_pkg::sinc_comp_e src_id,
  //                                       sinc_env_pkg::sinc_cmd_e cmd,
  //                                       sinc_env_pkg::address_t addr
  //                                       );

  //
  //  Monitor connections
  //

  // ********************************************************************************
  // Function: write_reset_xp
  //   Reset Monitor implementation
  extern virtual function void write_reset_xp(rst_pkg::rst_seq_item reset_state);

  // ********************************************************************************
  // Function: write_sideband_erase_xp
  //   Erase Monitor implementation
  // extern virtual function void write_sideband_erase_xp(sinc_env_pkg::sinc_erase_e sinc_erase_status);

  // ********************************************************************************
  // Function: write_sideband_sinc_done_xp
  //   SINC_DONE Monitor implementation
  // extern virtual function void write_sideband_sinc_done_xp(sinc_env_pkg::sinc_sideband_done_e sinc_done);

  // ********************************************************************************
  // Function: write_sinc_axi_mst_ae
  // Master is initiating an AXI request
  //   Monitor implementation
  extern virtual function void write_sinc_axi_mst_ae(pal_xaction trans);

  // ********************************************************************************
  // Function: write_sinc_key_mem_erase_ae
  // Erase operation to Key Vault
  //   Monitor implementation
  extern virtual function void write_sinc_key_mem_erase_ae(ramwrap_erase_transaction t);
endclass : sinc_storage_directory // }

// ********************************************************************************
// ********************************************************************************
function sinc_storage_directory::new(string name, uvm_component parent);
  super.new(name,parent);
  _storage_directory_instance = this;

  SINC_KSD_PASSIVE      = 0;
  addr_dec  = addr_dec_t::get_inst();

  // Get the backdoor memory interface.
  if (!uvm_config_db #(virtual sinc_mem_bkdoor_if)::get (null , UVMF_VIRTUAL_INTERFACES , "mem_bkdoor_if" ,
                                                       mem_bkdoor_if_h)) begin
    `uvm_error("Config Error", "Unable to retrieve backdoor memory interface")
  end

endfunction: new

// ********************************************************************************
// Task: reset_phase
// Reset dut's mem
task sinc_storage_directory::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  // mem_bkdoor_if_h.sinc_erase();
endtask : reset_phase



// ********************************************************************************
// ********************************************************************************
function void sinc_storage_directory::phase_started(uvm_phase phase);
  current_phase = phase;
endfunction : phase_started

// ********************************************************************************
// ********************************************************************************
function void sinc_storage_directory::build_phase(uvm_phase phase);
  super.build_phase(phase);

  m_sys_cfg   = sinc_env_pkg::sinc_sys_cfg::get_inst();

  this.reset_xp = new("reset_xp",this);
  this.sinc_axi_mst_ae = new("sinc_axi_mst_ae",this);
  this.sinc_key_mem_erase_ae = new("sinc_key_mem_erase_ae", this);

endfunction : build_phase

// ********************************************************************************
// ********************************************************************************
// task: run_phase
task sinc_storage_directory::run_phase(uvm_phase phase);

  super.run_phase(phase);

endtask : run_phase

// ********************************************************************************
// ********************************************************************************
// Function: extract_phase
// This is called at the end of the sim run_phase.
//
function void sinc_storage_directory::extract_phase(uvm_phase phase); // {


endfunction : extract_phase


// ********************************************************************************
// ********************************************************************************
// Called by sequence when a request will be sent to the sequencer.
// Log this as an outstanding request pending, this will be used to determine
// the validity of requests following.
//
function void sinc_storage_directory::sending_axi_req(
                                                    sinc_env_pkg::sinc_comp_e mstr_id,
                                                    sinc_env_pkg::address_t addr,
                                                    sinc_env_pkg::sinc_cmd_e cmd,
                                                    bit check_req_valid=1
                                                    );


endfunction : sending_axi_req

// ********************************************************************************
// ********************************************************************************
// Function: is_req_valid
// Given an address and a master request cmd type, returns true if the requested cmd can be issued for that address.
// Called by sequence during is_relevant.
//
// Additionally the sequence should call this method when responding
//  to the response packet to check for CANCEL indication.
//  Similar to make_request except that it does not allocate new storage state.
function int sinc_storage_directory::is_req_valid(
                                                sinc_env_pkg::sinc_comp_e mstr_id,
                                                sinc_env_pkg::address_t addr,
                                                sinc_env_pkg::sinc_cmd_e cmd,
                                                bit create_storage_state = 0
                                                );

endfunction : is_req_valid

// ********************************************************************************
// ********************************************************************************
// Function: is_cmd_valid
function int sinc_storage_directory::is_cmd_valid(
                                                sinc_env_pkg::sinc_comp_e mstr_id,
                                                sinc_env_pkg::address_t addr,
                                                sinc_env_pkg::sinc_cmd_e cmd
                                                );
endfunction : is_cmd_valid

// ****************************************
// Function: wr_storage_data
// Write storage data.
// Will write all data starting at addr.  Line must be valid.  Must not cross storage line boundary
function void sinc_storage_directory::wr_storage_data(sinc_env_pkg::address_t addr, bit [7:0] wr_bytes[$]);
  if (in_reset || passive_mode || SINC_KSD_PASSIVE) return;


endfunction : wr_storage_data

// ****************************************
// Function: rd_storage_data
// Read storage data
// Will read data starting at addr.  Line must be valid.  Must not cross storage line boundary
function void sinc_storage_directory::rd_storage_data(sinc_env_pkg::address_t addr, int size_in_bytes, ref bit [7:0] rd_bytes[$]);


endfunction : rd_storage_data

// ********************************************************************************
// ********************************************************************************
// Function: make_request
//  Given an address, a mstr_id, and a command, make a request to the storage diretory
//  for valid storage state.  It will new allocate new storage state if necessary.  Returns
//  1 for success.
function int sinc_storage_directory::make_request(
                                                sinc_env_pkg::sinc_comp_e mstr_id,
                                                sinc_env_pkg::address_t addr,
                                                sinc_env_pkg::sinc_cmd_e cmd,
                                                bit init_line_data=0
                                                );

endfunction : make_request



// ********************************************************************************
// ********************************************************************************
// Function: print_outstanding_requests
function void sinc_storage_directory::print_outstanding_requests();

endfunction

// ********************************************************************************
// ********************************************************************************
// Function: set_passive_mode
// Update passive_mode
function void sinc_storage_directory::set_passive_mode(bit new_value);
  passive_mode = new_value;
endfunction : set_passive_mode

// ********************************************************************************
// ********************************************************************************
// Function: get_passive_mode
// Returns passive_mode
function bit sinc_storage_directory::get_passive_mode();
  return(passive_mode || SINC_KSD_PASSIVE);
endfunction : get_passive_mode

//
//  Monitor connections
//

// ********************************************************************************
// Function: write_reset_xp
//   Monitor implementation
function void sinc_storage_directory::write_reset_xp(rst_pkg::rst_seq_item reset_state);
  string report_str = "STORAGE_DIRECTORY_SINC_RESET";

  if (reset_state.m_rstn === 1'b0) begin
    reset_done = 0;
    `uvm_info(report_str, "Reset inactive detected", UVM_LOW)
  end

  if (reset_state.m_rstn === 1'b1)  begin
    `uvm_info(report_str, "Reset active detected", UVM_LOW)
    if (reset_done==0) begin
      // reset LUT when finish SB_PKT_LUT_ERASE_AFTER_RESET entry in SB
      // sinc_lut_t lut_r_value = 0;
      // // reset all storage states for LUT
      // for (int i=0; i<sinc_parameters_pkg::KEY_VAULT_LUT_SLOTS; i++) begin
      // 	  m_sys_cfg.m_comp_cfg[SINC_LUT].update_lut(i, 'h0);
      // end
      reset_done = 1;
    end
  end

endfunction : write_reset_xp


// ********************************************************************************
// Function: write_axi_req_ap
// Master is initiating an AXI request
//   Monitor implementation
function void sinc_storage_directory::write_sinc_axi_mst_ae(pal_xaction trans);
  pal_resp_type_t        slv_resp = PAL_RESP_OKAY;
  sinc_comp_e dst_comp_type;
  int slot_num;
  bit [7 : 0] wr_data_q[$];
  bit [sinc_parameters_pkg::KEY_VAULT_KEY_WIDTH-1 : 0]  key_wr_data = 'h0;
  bit [sinc_parameters_pkg::KEY_VAULT_LUT_WIDTH-1 : 0]  lut_wr_data = 'h0;
  key_data_t key;
  sinc_lut_t lut;

  address_t address;

  `uvm_info("sinc_storage_directory", "Inside AXI TLM", UVM_HIGH)

  axi_req_item = pal_xaction::type_id::create("axi_req_item", this);

  if (!$cast(axi_req_item, trans)) begin
    `uvm_error("sinc_storage_directory", $sformatf("\n$cast Error for AXI Transaction \n%s", axi_req_item.sprint()))
  end

  address = axi_req_item.addr;

  `uvm_info(get_name(), $sformatf("\nsinc_storage_directory: receive AXI Transaction \n%s", axi_req_item.sprint()),  UVM_HIGH)

  // only process AXI transaction data phase items for now
  if (axi_req_item.xaction_phase == PAL_PH_ADDR) begin
    `uvm_info(get_name(), $sformatf("\n ksd: only process AXI transaction data phase item for now\n%s", axi_req_item.sprint()),  UVM_HIGH)
    return;
  end

  // only process request with OKAY response
  if (axi_req_item.cmd == PAL_READ) begin
    foreach (axi_req_item.rdresp[i]) begin
      if ((axi_req_item.rdresp[i] !== PAL_RESP_OKAY) && (slv_resp == PAL_RESP_OKAY)) begin
        slv_resp = axi_req_item.rdresp[i];
      end
    end
  end else if (axi_req_item.cmd == PAL_WRITE)begin
    slv_resp = axi_req_item.wrresp;
  end

  if (slv_resp == PAL_RESP_SLVERR) begin
    `uvm_info(get_name(), $sformatf("\nsinc_storage_directory doesn't handle AXI transactions with slv_err addr: %0h", axi_req_item.addr),  UVM_HIGH)
    return;
  end

  // KSD can check the read vs backdoor, but for now it is done by the scoreboard
  if (axi_req_item.cmd == AXI_READ) begin
    `uvm_info(get_name(), $sformatf("\nksu_storage_directory doesn't handle %0s transactions", axi_req_item.cmd.name()),  UVM_HIGH)
    return;
  end

  dst_comp_type = addr_dec.get_dst_type_hit(address);

  `uvm_info("ksu_storage_directory:", $sformatf("dst_comp_type: %0s", dst_comp_type.name()), UVM_HIGH);

  // sinc_storage_directory only process requests to KEY and LUT
  if (dst_comp_type == SINC_KEY || dst_comp_type == SINC_LUT) begin
    slot_num = addr_dec.get_slot_hit(dst_comp_type, address);

    foreach (axi_req_item.wstrb[i]) begin
      if (axi_req_item.wstrb[i]) begin
        // `uvm_info("ksu_storage_directory:", $sformatf("pack write data %0h", axi_req_item.data[i]), UVM_HIGH);
        wr_data_q[i] = axi_req_item.data[i];
      end else begin
        wr_data_q[i] = 'hx;
      end
    end

    if (slot_num == -1) begin
      `uvm_error("INVALID_SLOT_NUM", $sformatf("Could not found right slot number for address[%0h]", address))
    end else begin
      if (dst_comp_type == SINC_KEY) begin
        // transfer bytes into 1 dimentional bits
        foreach (wr_data_q[i]) begin
          key_wr_data[i*8 +:8] = wr_data_q[i];
        end
        // transfer into key_data_t for TB
        foreach (key[i]) begin
          key[i] = key_wr_data[i*32 +:32];
        end
        // m_sys_cfg.m_comp_cfg[dst_comp_type].slot_cfg[slot_num].key = key;
        m_sys_cfg.m_comp_cfg[dst_comp_type].update_key(slot_num, key, UVM_HIGH);
        `uvm_info(get_name(), $sformatf("\nsinc_storage_directory update [%0s_CFG][%0d] = %0p", dst_comp_type.name(), slot_num, key),  UVM_HIGH)
      end

      if (dst_comp_type == SINC_LUT) begin
        // transfer into sinc_lut_t for TB
        if (axi_req_item.wstrb.size() == 4) begin
          lut = {wr_data_q[3], wr_data_q[2], wr_data_q[1], wr_data_q[0]};
        end else begin
          `uvm_error("INVALID_LUT_WRITE_DATA", $sformatf("Write to LUT should be 32 bits, wstrb.size[%0h]", axi_req_item.wstrb.size()))
        end
        // m_sys_cfg.m_comp_cfg[dst_comp_type].slot_cfg[slot_num].lut = lut;
        m_sys_cfg.m_comp_cfg[dst_comp_type].update_lut(slot_num, lut, UVM_HIGH);
        `uvm_info(get_name(), $sformatf("\nsinc_storage_directory update [%0s_CFG][%0d] = %0h", dst_comp_type.name(), slot_num, lut),  UVM_HIGH)
      end
    end
  end

endfunction : write_sinc_axi_mst_ae

  // FUNCTION: write_sinc_key_mem_erase_ae
  // Transactions received through sinc_key_mem_erase_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
function void sinc_storage_directory::write_sinc_key_mem_erase_ae(ramwrap_erase_transaction t);
  string report_str = "WRITE_SINC_KEY_MEM_ERASE_AE";

  `uvm_info(get_name(), $sformatf("\nsinc_storage_directory: receive Erase Transaction \n%s", t.convert2string()),  UVM_HIGH)

  if (t.m_event == START) begin
    // Storage Directory doesn't care start
  end else if (t.m_event == DONE) begin
    sinc_lut_t lut_reset_value = sinc_parameters_pkg::KEY_VAULT_LUT_RESET_VALUE;

    // set lut data after erase, should be all zero
    for (int i=0; i<sinc_parameters_pkg::KEY_VAULT_LUT_SLOTS; i++) begin
      m_sys_cfg.m_comp_cfg[SINC_LUT].update_lut(i, lut_reset_value);
    end

    // update key data by backdoor poke, as it is erased with random data.
    // scoreboard has checked on the mem interface operation with memory result, so only needs to update local memory in storage directory
    for (int i=0; i<sinc_parameters_pkg::KEY_VAULT_KEY_SLOTS; i++) begin
      m_sys_cfg.m_comp_cfg[SINC_KEY].update_key(i, top_configuration.mem_bkdoor_if_h.sinc_key_read(i));
    end

  end
endfunction : write_sinc_key_mem_erase_ae


`endif //  `ifndef SINC_STORAGE_DIRECTORY_SVH
