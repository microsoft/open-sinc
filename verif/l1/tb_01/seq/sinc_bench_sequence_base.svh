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
// File        : sinc_bench_sequence_base.svh
// Description : This file contains the top level and utility sequences

`ifndef SINC_BENCH_SEQUENCE_BASE
`define SINC_BENCH_SEQUENCE_BASE

//SINC Testbench Base Sequence
class sinc_bench_sequence_base extends uvmf_sequence_base #(uvm_sequence_item);

  `uvm_object_utils( sinc_bench_sequence_base )

  // pragma uvmf custom sequences begin
  // UVMF_CHANGE_ME : Instantiate, construct, and start sequences as needed to create stimulus scenarios.
  // Instantiate sequences here
  // pragma uvmf custom sequences end

  // Sequencer handles for each active interface in the environment
  // Reset sequencer
  rst_sequencer        m_rst_sequencer;
  // AXI sequencer
  tb_virtual_sequencer m_tb_vseqr;

  // RAM WRAPPER ERROR INJ sequencer
  // uvm_sequencer #(ramwrap_inject_transaction) m_lut_ramwrap_inject_agent_sequencer;
  // uvm_sequencer #(ramwrap_inject_transaction) m_key_ramwrap_inject_agent_sequencer;

  // Top level environment configuration handle
  typedef sinc_env_configuration sinc_env_configuration_t;
  sinc_env_configuration_t m_top_configuration;

  // Configuration handles to access interface BFM's

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

  extern function new(string name = "");

  //  extern virtual task pre_body();
  extern virtual task body();
  // extern virtual task post_body();

  /**
   * Monitor Key Vault Top for reset signal, release wait untial reset asserted.
   */
  extern virtual task wait_until_reset_is_deasserted();

  /**
   * TB controled wait statement.
   */
  extern virtual task wait_n_clks(int nb_clks);

endclass : sinc_bench_sequence_base

function sinc_bench_sequence_base::new(string name = "");
  super.new( name );
  // Retrieve the configuration handles from the uvm_config_db

  // Retrieve top level configuration handle
  if ( !uvm_config_db#(sinc_env_configuration_t)::get(null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", m_top_configuration) ) begin
    `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?", UVM_NONE)
    `uvm_fatal("CFG", "uvm_config_db#(sinc_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG")
  end

  // pragma uvmf custom new begin
  // pragma uvmf custom new end

endfunction : new

task sinc_bench_sequence_base::body();
  uvm_status_e                  my_status;
  uvm_reg_data_t                my_data;
  sinc_axi_reg_access_extension ext_obj;

  `uvm_info(get_name(), "Starting body", UVM_LOW)

  wait_until_reset_is_deasserted();

  `uvm_info("TOP_LEVEL_SEQ", $sformatf("Reading from %s", m_top_configuration.m_regmodel.status.get_name()), UVM_LOW)
  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end
  m_top_configuration.m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if (my_status != UVM_IS_OK) begin
    `uvm_error("REG_READ", "Could not read m_regmodel.status")
  end else begin
    `uvm_info(get_name(), $sformatf("Read 0x%x from reg %s:\n%s",
        my_data,
        m_top_configuration.m_regmodel.status.get_name(),
        m_top_configuration.m_regmodel.status.sprint()),
      UVM_LOW)
  end
  m_top_configuration.m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if (my_status != UVM_IS_OK) begin
    `uvm_error("REG_READ", "Could not read m_regmodel.status")
  end else begin
    `uvm_info(get_name(), $sformatf("Read 0x%x from reg %s:\n%s",
        my_data,
        m_top_configuration.m_regmodel.status.get_name(),
        m_top_configuration.m_regmodel.status.sprint()),
      UVM_LOW)
  end
  wait_n_clks(10);

  `uvm_info(get_name(), "Ending body", UVM_LOW)
endtask : body

task sinc_bench_sequence_base::wait_until_reset_is_deasserted();
  `uvm_info(get_name(), "Wait for hardware reset", UVM_LOW)
  wait(m_top_configuration.m_sinc_vif.resetn === 1'b1);
endtask : wait_until_reset_is_deasserted

task sinc_bench_sequence_base::wait_n_clks(int nb_clks);
  repeat(nb_clks) begin
    @(m_top_configuration.m_sinc_vif.mon_cb);
  end
endtask : wait_n_clks

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif // SINC_BENCH_SEQUENCE_BASE
