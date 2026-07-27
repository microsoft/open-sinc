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
// File        : sinc_axi_rand_seq.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_AXI_RAND_SEQ
`define SINC_AXI_RAND_SEQ

//SINC AXI Random Sequence
class sinc_axi_rand_seq extends sinc_axi_base_sequence;
  int m_num_iter = 1;

  `uvm_object_utils(sinc_axi_rand_seq)

  function new (string name="sinc_axi_rand_sequence");
    super.new (name);
  endfunction : new

  // main run body
  extern virtual task main_run_body();

  // randomize AXI protocol
  extern virtual task axi_rand(pal_cmd_type_t cmd);

endclass: sinc_axi_rand_seq

task sinc_axi_rand_seq::main_run_body();
  pal_addr_t      waddr;
  pal_addr_t      raddr;
  pal_data_t      wdata;
  pal_data_t      rdata;
  bit [7:0]       write_data[4];
  bit [7:0]       read_data[];
  pal_resp_type_t wresp;
  pal_resp_type_t rresp;
  string          use_infact;

  // scenario here
  `uvm_info(get_name(), "sinc_axi_rand_seq start", UVM_LOW)

  /*
   fork
   begin
   // fill in sinc_packet
   repeat (num_iter) begin : read
   axi_rand(.cmd(PAL_READ));
   end
   // fixme: add comment when to use below code
   sp_con_seq.wait_for_read_done();
   // wait event.trigger
   `uvm_info(get_name(), "sinc_axi_rand_seq rd done", UVM_LOW)
   end
   begin
   repeat (num_iter) begin : write
   axi_rand(.cmd(PAL_WRITE));
   end
   sp_con_seq.wait_for_write_done();
   `uvm_info(get_name(), "sinc_axi_rand_seq wr done", UVM_LOW)
   end
   join
   // #20us;
   // ->sp_con_seq.seq_done_e;
   */
endtask : main_run_body

task sinc_axi_rand_seq::axi_rand(pal_cmd_type_t cmd);
  pal_addr_t       addr;
  pal_burst_type_t burst_type;
  pal_beat_size_t  beat_size;
  bit [8:0]        burst_length;
  bit [7:0]        data[];
  bit [3:0]        tag_id;
  pal_axuser_t     axuser;
  pal_prot_t       prot         = 0;
  pal_lock_t       lock         = 0;
  pal_cache_t      cache;
  bit [15:0]       data_size;
  bit              addr_aligned;
  bit              wstrb[]      = {};

  // hard code for DV 0.2
  // write to KEY SLOT with data 'hF
  addr         = 32'h8f11_0004;
  beat_size    = PAL_BYTES_4;
  burst_length = 1;
  data_size    = 4;
  data         = new[4];
  data[0]      = 'hF;
  burst_type   = PAL_BT_INCR;

  `uvm_info("AXI_RAND",
    $sformatf("Sending transaction with following parameters: cmd = %s, addr = 0x%0x, burst_type = %s, beat_size = %s, burst_length = %0d, data_size = %0d\n",
      cmd.name(), addr, burst_type.name(), beat_size.name(), burst_length, data_size), UVM_MEDIUM)

  if ( cmd inside {PAL_WRITE, PAL_EXWR, PAL_LOCKWR} ) begin
    m_sp_con_seq.axi_write_burst_nb (
      .waddr      (addr      ),
      .wdata      (data      ),
      .wstrb      (wstrb     ), //.wstrb({})
      .beat_size  (beat_size ),
      .awuser     (axuser    ),
      .wburst_type(burst_type),
      .id         (tag_id    ),
      .use_id     (1         ),
      .prot       (prot      ),
      .lock       (lock      ),
      .cache(cache));
  end else begin
    m_sp_con_seq.axi_read_burst_nb (
      .raddr      (addr      ),
      .rdata_size (data_size ),
      .beat_size  (beat_size ),
      .aruser     (axuser    ),
      .rburst_type(burst_type),
      .id         (tag_id    ),
      .use_id     (1         ),
      .prot       (prot      ),
      .lock       (lock      ),
      .cache(cache));
  end
endtask : axi_rand

`endif // SINC_AXI_RAND_SEQ
