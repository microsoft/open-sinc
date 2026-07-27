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
// File        : axi_slv_ext_seq.svh
// Description : 

`ifndef AXI_SLV_EXT_SEQ
`define AXI_SLV_EXT_SEQ
//--------------------------------------------------------------------------------------------
// class axi_slv_ext_seq
//
// Extension of axi_base_seq w/ added read/write tasks which don't wait for response
//--------------------------------------------------------------------------------------------
class axi_slv_ext_seq #(
  int AXI_ADDRESS_WIDTH = 32,
  int AXI_RDATA_WIDTH   = 32,
  int AXI_WDATA_WIDTH   = 32,
  int AXI_ID_WIDTH      = 4,
  int AXI_ID_VAL        = 1
) extends hsp_axi_base_seq #(
  .AXI_ADDRESS_WIDTH(AXI_ADDRESS_WIDTH),
  .AXI_RDATA_WIDTH  (AXI_RDATA_WIDTH  ),
  .AXI_WDATA_WIDTH  (AXI_WDATA_WIDTH  ),
  .AXI_ID_WIDTH     (AXI_ID_WIDTH     ),
  .AXI_ID_VAL       (AXI_ID_VAL       )
);

  // Write/Read outstanding transaction counters
  int m_wr_xact_cnt;
  int m_rd_xact_cnt;

  `uvm_object_param_utils(
    axi_slv_ext_seq #(
      AXI_ADDRESS_WIDTH,
      AXI_RDATA_WIDTH,
      AXI_WDATA_WIDTH,
      AXI_ID_WIDTH,
      AXI_ID_VAL
    )
  )

  `uvm_declare_p_sequencer(pal_master_sequencer)

  function new(string name="axi_slv_ext_seq");
    super.new(name);
    set_response_queue_depth(-1); // deep queue
  endfunction : new

  // Task to perform a single AXI write burst. Burst length is based on wdata.size() and beat_size
  // The wdata byte array will be converted to data bus format based on address alignment and
  // burst type; the byte array contents are expected to be in the same order as they would go
  // out on the bus; i.e., the byte array element 0 will correspond to the very first address accessed
  // in the burst; for PAL_BT_INCR, the very first address accessed will be the lowest
  // address of the burst ; whereas for PAL_BT_WRAP, it need not be the lowest address.

  // This task creates/send Write Address/Data Channel transaction and DOESN'T wait for response transaction
  extern virtual task axi_write_burst_nb (
    //Required
    input     pal_addr_t       waddr,
    const ref bit [7:0]        wdata[],
    input     pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input     pal_axuser_t     awuser      = 0,
    input     pal_burst_type_t wburst_type = PAL_BT_INCR,
    const ref bit              wstrb[],                   //    = {}

    //Optional
    input pal_id_t    id     = 0,
    input bit         use_id = 0,
    input pal_prot_t  prot   = PAL_NORM_SEC_DATA,
    input pal_lock_t  lock   = PAL_NORMAL,
    input pal_cache_t cache  = PAL_NONMODIFIABLE_NONBUF
  );

  // wait until all write transactions (address phase completed) receive response, i.e. data and response phases done
  // in other words, wait until there is no outstanding write transactions
  virtual task wait_for_write_done();
    wait (m_wr_xact_cnt == 0);
  endtask : wait_for_write_done

  // Task to perform a single AXI read burst. Burst length is based on rdata.size() and beat_size
  // The bus data will be converted into the rdata byte array based on the address alignment and
  // burst type; the byte array contents will to be in the same order as they were seen
  // on the bus; i.e., the byte array element 0 will correspond to the very first address accessed
  // in the burst; for PAL_BT_INCR, the very first address accessed will be the lowest
  // address of the burst ; whereas for PAL_BT_WRAP, it need not be the lowest address.

  // This task creates/send Read Address Channel transaction and DOESN'T wait for response transaction
  extern virtual task axi_read_burst_nb(
    input pal_addr_t       raddr,
    input bit [15:0]       rdata_size,
    input pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input pal_axuser_t     aruser      = 0,
    input pal_burst_type_t rburst_type = PAL_BT_INCR,
    input pal_id_t         id          = 0,
    input bit              use_id      = 0,
    input pal_prot_t       prot        = PAL_NORM_SEC_DATA,
    input pal_lock_t       lock        = PAL_NORMAL,
    input pal_cache_t      cache       = PAL_NONMODIFIABLE_NONBUF
  );

  // wait until all read transactions (address phase completed) receive response, i.e. data and response phases done
  // in other words, wait until there is no outstanding read transactions
  virtual task wait_for_read_done();
    wait (m_rd_xact_cnt == 0);
  endtask : wait_for_read_done

  //------------------------------------------------------------------------//
  // Wait for the specified number of clocks - backward compatibility task
  //------------------------------------------------------------------------//
  virtual task clock_delay(int unsigned num_cycles);
    wait_clock_ticks(num_cycles);
  endtask : clock_delay

endclass : axi_slv_ext_seq

task axi_slv_ext_seq::axi_write_burst_nb (
    //Required
    input     pal_addr_t       waddr,
    const ref bit [7:0]        wdata[],
    input     pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input     pal_axuser_t     awuser      = 0,
    input     pal_burst_type_t wburst_type = PAL_BT_INCR,
    const ref bit              wstrb[],                   //  ={}

    //Optional
    input pal_id_t    id     = 0,
    input bit         use_id = 0,
    input pal_prot_t  prot   = PAL_NORM_SEC_DATA,
    input pal_lock_t  lock   = PAL_NORMAL,
    input pal_cache_t cache  = PAL_NONMODIFIABLE_NONBUF
  );

  pal_xaction     trans;
  pal_xaction     trans_resp;
  int unsigned    beat_size_in_bytes;
  bit             my_resp_match[];                      //Using local variable to avoid any issues due to multiple calls accessing the same shared temp variable
  pal_resp_type_t my_resp[];
  int             my_trans_id        = next_trans_id++; //Note that we do not track outstanding trans_id's. Would need to have a transaction outstanding

  // `uvm_error("FIXME",
  //            $sformatf("Use hsp_axi_base_seq's commond nb task %0d",
  //       1))
  //Create transaction
  `uvm_create(trans)
  trans.pa_cfg = pa_cfg;
  trans.set_transaction_id(my_trans_id);
  if(!trans.randomize() with {
        cmd == PAL_WRITE;
        addr == waddr;
        num_bytes == wdata.size();
        burst_type == wburst_type;
        log2_beat_size == beat_size;
        qos == 0;
        axuser == awuser;
        axprot == prot;
        axlock == lock;
        axcache == cache;
      }) begin
    `uvm_fatal("RAND", "failed to randomize 'trans'")
  end
  if(use_id) begin
    trans.tag_id = id;
  end
  for (int di=0; di < wdata.size(); di++) begin
    trans.data[di] = wdata[di];
  end
  if (wstrb.size() != 0) begin
    if (wstrb.size() != wdata.size()) begin
      `uvm_fatal(get_type_name(), $sformatf("pal_write_burst: wstrb array size %0d is not equal to wdata array size %0d\n", wstrb.size(), wdata.size()))
    end
    trans.wstrb = wstrb;
  end else begin
    for (int di=0; di < wdata.size(); di++) begin
      trans.wstrb[di] = 1;
    end
  end
  trans.xaction_phase = PAL_PH_ADDR;

  //Send transaction / receive response
  fork : send_transaction_proc
    begin : request
      `uvm_send(trans)
      m_wr_xact_cnt++;
    end : request
    begin : response
      get_response(trans_resp, my_trans_id);
      m_wr_xact_cnt--;
    end : response
  join_any

  `uvm_info(get_type_name(), $sformatf("pal_write_burst: addr: 0x%0x; data: %p; burst_type = %s\n", waddr, wdata, wburst_type.name()), UVM_MEDIUM)

endtask: axi_write_burst_nb

task axi_slv_ext_seq::axi_read_burst_nb(
    input pal_addr_t       raddr,
    input bit [15:0]       rdata_size,
    input pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input pal_axuser_t     aruser      = 0,
    input pal_burst_type_t rburst_type = PAL_BT_INCR,
    input pal_id_t         id          = 0,
    input bit              use_id      = 0,
    input pal_prot_t       prot        = PAL_NORM_SEC_DATA,
    input pal_lock_t       lock        = PAL_NORMAL,
    input pal_cache_t      cache       = PAL_NONMODIFIABLE_NONBUF
  );
  pal_xaction  trans;
  pal_xaction  trans_resp;
  int unsigned beat_size_in_bytes;
  int          my_trans_id        = next_trans_id++; //Note that we do not track outstanding trans_id's. Would need to have a transaction outstanding

  // `uvm_error("FIXME",
  //            $sformatf("Use hsp_axi_base_seq's commond nb task %0d",
  //           1))
  `uvm_create(trans)
  trans.pa_cfg = pa_cfg;
  trans.set_transaction_id(my_trans_id);
  if(!trans.randomize() with {
        cmd == PAL_READ;
        addr == raddr;
        num_bytes == rdata_size;
        burst_type == rburst_type;
        log2_beat_size == beat_size;
        qos == 0;
        axuser == aruser;
        axprot == prot;
        axlock == lock;
        axcache == cache; }) begin
    `uvm_fatal("RAND", "failed to randomize 'trans'")
  end
  if(use_id) begin
    trans.tag_id = id;
  end
  trans.xaction_phase = PAL_PH_ADDR;

  fork : rd_transaction_proc
    begin : rd_addr_phase
      `uvm_send(trans)
      m_rd_xact_cnt++;
    end : rd_addr_phase
    begin : rd_data_phase
      `uvm_create(trans_resp)
      get_response(trans_resp, my_trans_id);
      m_rd_xact_cnt--;
    end : rd_data_phase
  join_any

  `uvm_info(get_type_name(), $sformatf("pal_read_burst: addr: 0x%0x; data_size: %0d; burst_type = %s\n", raddr, rdata_size, rburst_type.name()), UVM_MEDIUM)

endtask : axi_read_burst_nb

`endif // AXI_SLV_EXT_SEQ