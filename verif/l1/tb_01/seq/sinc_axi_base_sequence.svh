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
// File        : sinc_axi_base_sequence.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_AXI_BASE_SEQUENCE
`define SINC_AXI_BASE_SEQUENCE

typedef class axi_slv_ext_seq;

/**
 * SINC axi base sequence
 */
class sinc_axi_base_sequence extends hsp_virt_base_seq #(.AXI_ID_WIDTH(`HSP_AXI_SLV_ID_WIDTH));

  // Top level environment configuration handle
  typedef sinc_env_configuration sinc_env_configuration_t;
  sinc_env_configuration_t m_top_configuration;

  axi_slv_ext_seq#() m_sp_con_seq;
  // Logger string
  string             m_logger_str;

  `uvm_object_utils(sinc_axi_base_sequence)

  function new (string name="sinc_axi_base_sequence");
    super.new(name);
    m_logger_str = get_name();

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(sinc_env_configuration_t)::get(null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", m_top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?", UVM_NONE)
      `uvm_fatal("CFG", "uvm_config_db#(sinc_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG")
    end
  endfunction : new

  // --- pre_body() ---
  extern virtual task pre_body();
  // --- body() ---
  extern virtual task body();
  // --- post_body() ---
  extern virtual task post_body();
  // main run body
  extern virtual task main_run_body();

  /*
   * Helper Function For SINC Access
   *
   */

  // provide attributes from SINC's view
  extern virtual task write_mem (
    input     sinc_env_pkg::sinc_mem_type_e mem_type,
    input     pal_cmd_type_t                cmd,
    input     int                           slot,
    input     sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid = 0,
    input     sinc_lut_t                    lut        = 0,
    const ref bit [7:0]                     wdata[],
    ref       pal_resp_type_t               response,
    input     pal_beat_size_t               beat_size,
    input     pal_burst_type_t              burst_type,
    input     pal_id_t                      tag_id,
    input     pal_prot_t                    prot,
    input     pal_lock_t                    lock,
    input     pal_cache_t                   cache
  );

  // provide attributes from SINC's view
  extern virtual task read_mem (
    input sinc_env_pkg::sinc_mem_type_e mem_type,
    input pal_cmd_type_t                cmd,
    input int                           slot,
    input sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid = 0,
    input sinc_lut_t                    lut         = 0,
    ref   bit [7:0]                     read_data[],
    ref   pal_resp_type_t               response,
    input pal_beat_size_t               beat_size,
    input pal_burst_type_t              burst_type,
    input pal_id_t                      tag_id,
    input pal_prot_t                    prot,
    input pal_lock_t                    lock,
    input pal_cache_t                   cache
  );

  extern virtual task nb_read_mem (
    input     sinc_env_pkg::sinc_mem_type_e mem_type,
    input     pal_cmd_type_t                cmd,
    input     int                           slot,
    input     sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid = 0,
    input     sinc_lut_t                    lut         = 0,
    const ref bit [7:0]                     read_data[],
    input     pal_resp_type_t               response,
    input     pal_beat_size_t               beat_size,
    input     pal_burst_type_t              burst_type,
    input     pal_id_t                      tag_id,
    input     pal_prot_t                    prot,
    input     pal_lock_t                    lock,
    input     pal_cache_t                   cache
  );

  // provide attributes from AXI Interface's view - AXI blocking read requests
  extern virtual task sinc_axi_read_access_with (
    input pal_addr_t       addr,
    ref   bit [7:0]        read_data[],
    input bit [9:0]        burst_length,
    input pal_id_t         id,
    ref   pal_resp_type_t  response,
    input pal_beat_size_t  burst_size   =PAL_BYTES_4,
    input pal_prot_t       prot         =PAL_NORM_SEC_DATA,
    input pal_axuser_t     aruser       =0,
    input pal_lock_t       lock         = PAL_NORMAL,
    input pal_cache_t      cache        =PAL_NONMODIFIABLE_NONBUF,
    input pal_burst_type_t burst_type   =PAL_BT_INCR
  );

  // provide attributes from AXI Interface's view - AXI non-blocking read requests
  extern virtual task sinc_axi_nb_read_access_with (
    input pal_addr_t       raddr,
    input bit [15:0]       rdata_size,
    //Transaction type and expected response
    input pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input pal_axuser_t     aruser      = 0,
    input pal_burst_type_t rburst_type = PAL_BT_INCR,
    //Optional
    input pal_id_t         id          = 0,
    input bit              use_id      = 0,
    input pal_prot_t       prot        = PAL_NORM_SEC_DATA,
    input pal_lock_t       lock        = PAL_NORMAL,
    input pal_cache_t      cache       = PAL_NONMODIFIABLE_NONBUF
  );

  // provide attributes from AXI Interface's view - AXI blocking write requests
  extern virtual task sinc_axi_write_access_with (
    input     pal_addr_t       addr,
    const ref bit [7:0]        write_data[],
    const ref bit              wstrb[],                                // = {},
    input     bit [9:0]        burst_length,
    input     pal_id_t         id,
    input     pal_beat_size_t  burst_size,
    ref       pal_resp_type_t  response,
    input     pal_prot_t       prot         =PAL_NORM_SEC_DATA,
    input     pal_lock_t       lock         = PAL_NORMAL,
    input     pal_cache_t      cache        =PAL_NONMODIFIABLE_NONBUF,
    input     pal_axuser_t     awuser       = 0,
    input     pal_burst_type_t burst_type   = PAL_BT_INCR
    // const ref int              beats_delay[]                            // = {}
  );

  // provide attributes from AXI Interface's view - AXI non-blocking write requests
  extern virtual task sinc_axi_nb_write_access_with (
    input     pal_addr_t       waddr,
    const ref bit [7:0]        wdata[],
    input     pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input     pal_axuser_t     awuser      = 0,
    input     pal_burst_type_t wburst_type = PAL_BT_INCR,
    const ref bit              wstrb[],                   //     = {},

    //Optional
    input pal_id_t    id     = 0,
    input bit         use_id = 0,
    input pal_prot_t  prot   = PAL_NORM_SEC_DATA,
    input pal_lock_t  lock   = PAL_NORMAL,
    input pal_cache_t cache  = PAL_NONMODIFIABLE_NONBUF
  );

endclass: sinc_axi_base_sequence

// body()
task sinc_axi_base_sequence::body();
  `uvm_info(get_type_name(), "Sending pal_vseq\n", UVM_HIGH)
  fork : sp_con_seq_thread
    begin
      // sp_con_seq.start(p_sequencer.pal_vseqr[0].pal_master_seqr[0]);
      m_sp_con_seq.start(m_top_configuration.m_vseqr.m_pal_sequencer, this);
    end
  join_none
  //ensures that the sequence is started before proceeding below
  m_sp_con_seq.wait_for_sequence_state(~(UVM_CREATED | UVM_STOPPED | UVM_FINISHED));

  m_sp_con_seq.seq_setup();
  main_run_body();
  // test_done();
endtask : body

// main run body
task sinc_axi_base_sequence::main_run_body();
  time start_time;

  `uvm_info(m_logger_str, "Empty Virtual Base Sequence", UVM_NONE)

  start_time = $time();
  while(($time() - start_time) < 20ns) begin
    m_sp_con_seq.wait_clock_ticks(1);
  end

  ->m_sp_con_seq.seq_done_e;
endtask : main_run_body

// pre_body() task
task sinc_axi_base_sequence::pre_body();
  super.pre_body();
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~ SEQUENCE BEGIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)

  `uvm_info(m_logger_str, $sformatf("sinc_axi_base_sequence -- pre_body"), UVM_HIGH)

  sp_seq       = null;
  m_sp_con_seq = axi_slv_ext_seq#()::type_id::create("m_sp_con_seq", , get_full_name());
endtask : pre_body

// post body task
task sinc_axi_base_sequence::post_body();
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~ SEQUENCE END ~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  `uvm_info(m_logger_str, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", UVM_LOW)
  super.post_body();
endtask : post_body

task sinc_axi_base_sequence::write_mem (
    input     sinc_env_pkg::sinc_mem_type_e mem_type,
    input     pal_cmd_type_t                cmd,
    input     int                           slot,
    input     sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid,
    input     sinc_lut_t                    lut        = 0,
    const ref bit [7:0]                     wdata[],
    ref       pal_resp_type_t               response,
    input     pal_beat_size_t               beat_size,
    input     pal_burst_type_t              burst_type,
    input     pal_id_t                      tag_id,
    input     pal_prot_t                    prot,
    input     pal_lock_t                    lock,
    input     pal_cache_t                   cache
  );

  string logger_str = "DV::write_mem";

endtask : write_mem

task sinc_axi_base_sequence::read_mem (
    input sinc_env_pkg::sinc_mem_type_e mem_type,
    input pal_cmd_type_t                cmd,
    input int                           slot,
    input sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid,
    input sinc_lut_t                    lut         = 0,
    ref   bit [7:0]                     read_data[],
    ref   pal_resp_type_t               response,
    input pal_beat_size_t               beat_size,
    input pal_burst_type_t              burst_type,
    input pal_id_t                      tag_id,
    input pal_prot_t                    prot,
    input pal_lock_t                    lock,
    input pal_cache_t                   cache
  );

  string logger_str = "DV::read_mem";

endtask : read_mem

task sinc_axi_base_sequence::nb_read_mem (
    input     sinc_env_pkg::sinc_mem_type_e mem_type,
    input     pal_cmd_type_t                cmd,
    input     int                           slot,
    input     sinc_axi_mid_e                mid,
    // sinc_vfid_t vfid,
    input     sinc_lut_t                    lut         = 0,
    const ref bit [7:0]                     read_data[],
    input     pal_resp_type_t               response,
    input     pal_beat_size_t               beat_size,
    input     pal_burst_type_t              burst_type,
    input     pal_id_t                      tag_id,
    input     pal_prot_t                    prot,
    input     pal_lock_t                    lock,
    input     pal_cache_t                   cache
  );

  string logger_str = "DV::read_mem";

endtask : nb_read_mem

task sinc_axi_base_sequence::sinc_axi_read_access_with (
    input pal_addr_t       addr,
    ref   bit [7:0]        read_data[],
    input bit [9:0]        burst_length,
    input pal_id_t         id,
    ref   pal_resp_type_t  response,
    input pal_beat_size_t  burst_size   =PAL_BYTES_4,
    input pal_prot_t       prot         =PAL_NORM_SEC_DATA,
    input pal_axuser_t     aruser       =0,
    input pal_lock_t       lock         = PAL_NORMAL,
    input pal_cache_t      cache        =PAL_NONMODIFIABLE_NONBUF,
    input pal_burst_type_t burst_type   =PAL_BT_INCR
  );

  string logger_str = "DV::sinc_axi_read_access_with";

  m_sp_con_seq.axi_read_burst_resp ( .addr         (addr        ),
                                     .read_data    (read_data   ),
                                     .burst_length (burst_length),
                                     .burst_size   (burst_size  ),
                                     .aruser       (aruser      ),
                                     .burst_type   (burst_type  ),
                                     .id           (id          ),
                                     .prot         (prot        ),
                                     .lock         (lock        ),
                                     .cache        (cache       ),
                                     .response     (response    ),
                                     .add_parity   (0           )
  );

endtask : sinc_axi_read_access_with

task sinc_axi_base_sequence::sinc_axi_nb_read_access_with (
    input pal_addr_t       raddr,
    input bit [15:0]       rdata_size,
    //Transaction type and expected response
    input pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input pal_axuser_t     aruser      = 0,
    input pal_burst_type_t rburst_type = PAL_BT_INCR,
    //Optional
    input pal_id_t         id          = 0,
    input bit              use_id      = 0,
    input pal_prot_t       prot        = PAL_NORM_SEC_DATA,
    input pal_lock_t       lock        = PAL_NORMAL,
    input pal_cache_t      cache       = PAL_NONMODIFIABLE_NONBUF
  );

  string logger_str = "DV::sinc_axi_nb_read_access_with";

endtask : sinc_axi_nb_read_access_with

task sinc_axi_base_sequence::sinc_axi_write_access_with (
    input     pal_addr_t       addr,
    const ref bit [7:0]        write_data[],
    const ref bit              wstrb[],                                 // = {},
    input     bit [9:0]        burst_length,
    input     pal_id_t         id,
    input     pal_beat_size_t  burst_size,
    ref       pal_resp_type_t  response,
    input     pal_prot_t       prot         = PAL_NORM_SEC_DATA,
    input     pal_lock_t       lock         = PAL_NORMAL,
    input     pal_cache_t      cache        = PAL_NONMODIFIABLE_NONBUF,
    input     pal_axuser_t     awuser       = 0,
    input     pal_burst_type_t burst_type   = PAL_BT_INCR
    // const ref int              beats_delay[]                             // = {}
  );

  string logger_str = "DV::sinc_axi_write_access_with";

  m_sp_con_seq.axi_write_burst_resp (
    .addr        (addr        ),
    .write_data  (write_data  ),
    .wstrb       (wstrb       ),
    .burst_size  (burst_size  ),
    .awuser      (awuser      ),
    .burst_type  (burst_type  ),
    .id          (id          ),
    .prot        (prot        ),
    .lock        (lock        ),
    .burst_length(burst_length),
    .cache       (cache       ),
    .response    (response    ),
    .add_parity (0)); // sinc does not support parity

endtask : sinc_axi_write_access_with

task sinc_axi_base_sequence::sinc_axi_nb_write_access_with (
    // Required
    input     pal_addr_t       waddr,
    const ref bit [7:0]        wdata[],
    input     pal_beat_size_t  beat_size   = PAL_BYTES_4,
    input     pal_axuser_t     awuser      = 0,
    input     pal_burst_type_t wburst_type = PAL_BT_INCR,
    const ref bit              wstrb[],                   //     = {},

    //Optional
    input pal_id_t    id     = 0,
    input bit         use_id = 0,
    input pal_prot_t  prot   = PAL_NORM_SEC_DATA,
    input pal_lock_t  lock   = PAL_NORMAL,
    input pal_cache_t cache  = PAL_NONMODIFIABLE_NONBUF
  );

  string logger_str = "DV::sinc_axi_nb_write_access_with";

  //sp_con_seq.axi_write_burst_nb (
  m_sp_con_seq.pal_axi_write_burst_nb (
    .waddr       ( waddr      ),
    .wdata       ( wdata      ),
    .beat_size   ( beat_size  ),
    .awuser      ( awuser     ),
    .wburst_type ( wburst_type),
    .wstrb       ( wstrb      ),
    .id          ( id         ),
    .use_id      ( 1          ),
    .prot        ( prot       ),
    .lock        ( lock       ),
    .cache (cache));

endtask : sinc_axi_nb_write_access_with

`endif // SINC_AXI_BASE_SEQUENCE
