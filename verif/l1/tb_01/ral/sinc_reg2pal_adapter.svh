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
// File        : sinc_reg2pal_adapter.svh
// Description : 

`ifndef SINC_REG2PAL_ADAPTER
`define SINC_REG2PAL_ADAPTER

//define sinc  reg2pal
class sinc_reg2pal_adapter extends reg2pal_adapter;
  `uvm_object_utils(sinc_reg2pal_adapter)

  // msft_axi4_parity_util_func m_parity_util_func;

  extern function new(string name = "sinc_reg2pal_adapter");
  extern virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
  extern virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
endclass : sinc_reg2pal_adapter

/**
 *
 * @see pal_pkg::reg2pal_adapter.new
 * @param name - instance name
 * @return nothing
 */
function sinc_reg2pal_adapter::new(string name = "sinc_reg2pal_adapter");
  super.new(name);

  //m_parity_util_func = new();
endfunction : new

/**
 *
 * @see pal_pkg::reg2pal_adapter.reg2bus
 * @param rw - uvm_reg_bus_op
 * @return xaction
 */
function uvm_sequence_item sinc_reg2pal_adapter::reg2bus(const ref uvm_reg_bus_op rw);

  sinc_axi_reg_access_extension ext_obj;
  uvm_reg_item                  reg_item = get_item();
  pal_xaction                   xaction;
  uvm_sequence_item             seq_item;

  seq_item = super.reg2bus(rw);

  if($cast(xaction, seq_item)) begin
    if ((reg_item.extension != null) && ($cast(ext_obj, reg_item.extension))) begin
      xaction.axuser = ext_obj.m_axi_user_id;
      if (ext_obj.m_user_delay) begin
        xaction.user_delay           = ext_obj.m_user_delay;
        xaction.cmd_delay            = ext_obj.m_cmd_delay ;
        xaction.data_accept_delay    = new[1];
        xaction.data_accept_delay[0] = ext_obj.m_data_accept_delay;
        xaction.data_beat_delay      = new[1];
        xaction.data_beat_delay[0]   = ext_obj.m_data_beat_delay;
        xaction.wr_resp_accept_delay = ext_obj.m_wr_resp_accept_delay;
      end
    end
  end

  `uvm_info(REPORT_TAG, $sformatf("REG2BUS returning xaction: %s\n", xaction.convert2string() ), UVM_DEBUG)
  `uvm_info(REPORT_TAG, $sformatf("BUS2REG returning bus transaction: rw.kind = %d, rw.data = 'h%h\n", rw.kind, rw.data ), UVM_HIGH)

  return (xaction);

endfunction : reg2bus

function void sinc_reg2pal_adapter::bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
  pal_xaction xaction;
  if(!$cast(xaction, bus_item)) begin
    `uvm_fatal(REPORT_TAG, "Cannot cast provided bus item to pal xaction\n")
    return;
  end

  `uvm_info(REPORT_TAG, $sformatf("BUS2REG receieved xaction: %s\n", xaction.convert2string() ), UVM_HIGH)
  `uvm_info(REPORT_TAG, $sformatf("BUS2REG receieved xaction.cmd: %s\n", xaction.cmd.name()), UVM_HIGH)

  rw.addr   = xaction.addr;
  rw.n_bits = xaction.num_bytes * 8;

  if ((xaction.cmd == PAL_EXWR) || (xaction.cmd == PAL_LOCKWR)) begin
    xaction.cmd = PAL_WRITE;
  end

  if ((xaction.cmd == PAL_EXRD) || (xaction.cmd == PAL_LOCKRD)) begin
    xaction.cmd = PAL_READ;
  end

  if(xaction.cmd == PAL_READ) begin
    rw.kind   = UVM_READ;
    rw.status = UVM_IS_OK;
    // If any of the beat response is not OKAY, consider whole read response as not OKAY
    for (int i=0; i < xaction.rdresp.size(); i++) begin
      if((xaction.rdresp[i] != PAL_RESP_OKAY) && (xaction.rdresp[i] != PAL_RESP_EXOKAY)) begin
        rw.status = UVM_NOT_OK;
        break;
      end
    end

    // Convert xaction data to reg_bus data for read
    rw.data = `UVM_REG_DATA_WIDTH'h0;
    for (int di=0; di < xaction.num_bytes; di++) begin
      rw.data = rw.data | (xaction.data[di] << (8 * di)); // Little endian
    end
  end else if(xaction.cmd == PAL_WRITE) begin
    rw.kind   = UVM_WRITE;
    rw.status = ((xaction.wrresp == PAL_RESP_OKAY) || (xaction.wrresp == PAL_RESP_EXOKAY)) ? UVM_IS_OK : UVM_NOT_OK;
    rw.data   = `UVM_REG_DATA_WIDTH'h0;
    for (int di=0; di < xaction.num_bytes; di++) begin
      rw.data = rw.data | (xaction.data[di] << (8 * di)); // Little endian
    end
  end else begin
    `uvm_fatal(REPORT_TAG, "Unsupported PAL xaction cmd received\n")
  end

  `uvm_info(REPORT_TAG, $sformatf("BUS2REG returning bus transaction: rw.kind = %d, rw.data = 'h%h\n", rw.kind, rw.data ), UVM_HIGH)

endfunction: bus2reg

`endif //SINC_REG2PAL_ADAPTER
