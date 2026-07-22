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
// File        : sinc_ecc_error_inj_test_seq.svh
// Description : 

`ifndef SINC_ECC_ERROR_INJ_TEST_SEQ
`define SINC_ECC_ERROR_INJ_TEST_SEQ
//------------------------------------------------------------------------------
// SEQUENCE: sinc_ecc_error_inj_test_seq
//------------------------------------------------------------------------------

typedef enum { DISABLED=0, INIT, ACTIVE, FAILED } cache_state_e;
typedef enum { CORRECTABLE=0, UNCORRECTABLE } ecc_error_typ_e;

/**
 * ECC Error Injection Test Sequence
 */
class sinc_ecc_error_inj_test_seq extends sinc_virtual_base_sequence;

  `uvm_object_utils(sinc_ecc_error_inj_test_seq)

  // copy of prior key for reuse key and bit to see if we have established an initial key
  sinc_key_t m_reuse_key_data;
  bit        m_initial_key_set     = 0;
  bit [6:0]  m_set_for_encrypt;
  bit [7:0]  m_tags_for_encrypt[5];

  // Flags passed by yml
  // enable specific test sequence in sanity test
  bit m_sinc_error_chk_disabled = 0;

  bit m_cpu_mem_test_only;

  cache_state_e   m_cache_state;
  ecc_error_typ_e m_ecc_error_typ;

  function new(string name="sinc_ecc_error_inj_test_seq");
    super.new(name);
    process_plusargs_and_populate_seq_item();
  endfunction : new

  //Reused task from sanity sequnce
  extern virtual task init_state_fw_operations();
  extern virtual task disable_state_fw_operations();
  extern virtual task start_erase_optional();
  extern virtual task body();

  //ECC error specific task
  extern virtual task sequential_run_body();
  extern virtual function void process_plusargs_and_populate_seq_item();
  extern virtual task cpu_mem_access_check(input ccpui_cpu_mem_addr_t addr, bit is_wr_rd, output ccpui_cpu_mem_data_t cpu_read_data);
  extern virtual task cpu_mem_access_ecc_check(input ccpui_cpu_mem_addr_t addr, ccpui_cpu_mem_data_t exp_data, bit is_wr_rd, bit correctable);
  extern virtual task sinc_status_reg_err_chk(input bit correctable);
  extern virtual task correctable_ecc_error();
  extern virtual task uncorrectable_ecc_error();
  extern virtual task error_chk_and_recovery();
  extern virtual task find_flipped_bit(ccpui_cpu_mem_addr_t addr, cache_mem_w_ecc_t data1, cache_mem_w_ecc_t data2, output int flipped_bit);
  extern virtual task get_error_injected_address(
           ccpui_cpu_mem_addr_t addr,
           cache_mem_w_ecc_t    data1,
           cache_mem_w_ecc_t    data2,
    output ccpui_cpu_mem_addr_t flipped_bit_address,
    output bit [7:0]            addr_index
  );

endclass : sinc_ecc_error_inj_test_seq

task sinc_ecc_error_inj_test_seq::start_erase_optional();
  string       debug_str        = "start_erase_optional_body";
  logic [31:0] erase_data_value;

  `uvm_info(get_name(), $sformatf("%s: started", debug_str), UVM_LOW)

  // start erase
  if (!std::randomize(erase_data_value)) begin
    `uvm_fatal(get_name(), "Unable to randomize erase_data_value")
  end

  // start cache erase
  fork: sinc_sanity_erase_fork
    begin
      m_erase_rand_seq.erase_cache();
    end
  join: sinc_sanity_erase_fork

  `uvm_info(get_name(), $sformatf("%s: ended", debug_str), UVM_LOW)

  // re-initialize Cache Storage Directory as the cache mem has been wiped
  m_csd.init_csd(.en_bkdoor_load(1));

endtask : start_erase_optional

task sinc_ecc_error_inj_test_seq::sequential_run_body();
  string debug_str = "ecc_error_inj_seq_body";

  `uvm_info(get_name(), $sformatf("Starting %s selected configuration ECC_ERROR= %s CACHE_STATE = %s erro_check=%d", debug_str, m_ecc_error_typ.name(), m_cache_state.name(), m_sinc_error_chk_disabled), UVM_LOW)

  if(m_sinc_error_chk_disabled) begin
    //Drive sinc_err_chk_disabled to 1
    m_top_configuration.m_sinc_vif.force_or_release_sinc_err_chk_disabled(1, 1);
  end

  wait_n_clks(10);

  if(m_ecc_error_typ == CORRECTABLE) begin
    correctable_ecc_error();
  end
  if(m_ecc_error_typ == UNCORRECTABLE) begin
    uncorrectable_ecc_error();
  end

  `uvm_info (get_name(), $sformatf("%s: test sequence completed", debug_str), UVM_LOW)

endtask : sequential_run_body

task sinc_ecc_error_inj_test_seq::body();
  string debug_str = "DV::sinc_ecc_error_inj_test_seq::body";
  super.body();

  test_done();
endtask : body

function void sinc_ecc_error_inj_test_seq:: process_plusargs_and_populate_seq_item();
  string debug_str     = "SINC_SANITY_SEQ_PROCESS_PLUSARGS";
  string tmp_string;
  string cache_state;
  string ecc_error_typ;

  if ($value$plusargs("SINC_TB_CACHE_STATE=%0s", cache_state)) begin
    `uvm_info(get_name(), $sformatf("Plusarg Override SINC_CACHE_STATE is set to %0s", cache_state), UVM_LOW)
    if (cache_state == "DISABLED") begin
      m_cache_state = DISABLED;
    end else if (cache_state == "INIT") begin
      m_cache_state = INIT;
    end else if (cache_state == "ACTIVE") begin
      m_cache_state = ACTIVE;
    end else if (cache_state == "RANDOM") begin
      if(!std::randomize(m_cache_state) with {m_cache_state != FAILED;}) begin
        `uvm_fatal(get_name(), "std::Randomize failed to randomize m_cache_state")
      end
    end else begin
      if(!std::randomize(m_cache_state) with {m_cache_state != FAILED;}) begin
        `uvm_fatal(get_name(), "std::Randomize failed to randomize m_cache_state")
      end
    end
    `uvm_info(get_name(), $sformatf("Used cache_state: %0s", m_cache_state.name()), UVM_NONE)
  end

  if ($value$plusargs("SINC_TB_ECC_ERROR=%0s", ecc_error_typ)) begin
    `uvm_info(get_name(), $sformatf("Plusarg Override SINC_ecc_error_typ is set to %0s", ecc_error_typ), UVM_LOW)
    if (ecc_error_typ == "UNCORRECTABLE") begin
      m_ecc_error_typ = UNCORRECTABLE;
    end else if (ecc_error_typ == "CORRECTABLE") begin
      m_ecc_error_typ = CORRECTABLE;
    end else if (ecc_error_typ == "RANDOM") begin
      if(!std::randomize(m_ecc_error_typ) ) begin
        `uvm_fatal(get_name(), "std::Randomize failed to randomize m_ecc_error_typ")
      end
    end else begin
      if(!std::randomize(m_ecc_error_typ) ) begin
        `uvm_fatal(get_name(), "std::Randomize failed to randomize m_ecc_error_typ")
      end
    end
    `uvm_info(get_name(), $sformatf("Used ecc_error_typ: %0s", m_ecc_error_typ.name()), UVM_NONE)
  end

  if($value$plusargs("SINC_TB_ERROR_CHK_DISABLED=%d", m_sinc_error_chk_disabled)) begin
    `uvm_info(get_name(), $sformatf("SINC_TB_ERROR_CHK_DISABLED from plusarg = %d", m_sinc_error_chk_disabled), UVM_LOW)
  end

  //TODO Random
  //if((ecc_error_typ == "RANDOM") & (cache_state == "RANDOM")) begin
  //  m_sinc_error_chk_disabled = $urandom_range(1);
  //  `uvm_info(get_name(), $sformatf("Random %s selected as = %d", tmp_str, m_sinc_error_chk_disabled), UVM_LOW)
  //end

endfunction : process_plusargs_and_populate_seq_item

task sinc_ecc_error_inj_test_seq::sinc_status_reg_err_chk(input bit correctable);
  string debug_str        = "DV::sinc_status_reg_err_chk";
  bit    neg_test;
  logic  mem_err_uncorr_o;

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
  if(my_status != UVM_IS_OK) begin
    `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
  end

  if(correctable) begin
    if(my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])
      `uvm_error(get_name(), $sformatf("Uncorrectable error detected SINC_STATUS['h%h] but correctable ecc error expected", my_data))
  end else begin
    if(!my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB])
      `uvm_error(get_name(), $sformatf("Uncorrectable error expected but not observed SINC_STATUS['h%h]", my_data))
  end

  if(my_data[`SINC_REGS_STATUS_AES_ERR_MSB])
    `uvm_error(get_name(), $sformatf("AES error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_W_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag write  error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_CHK_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag check   error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_AUTH_TAG_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Authentication tag read   error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_FETCH_BLOCK_MSB])
    `uvm_error(get_name(), $sformatf("Write cache block error during fetch block command  error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK_MSB])
    `uvm_error(get_name(), $sformatf("Write cache block error during encrypt block command  error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_CACHE_BLOCK_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Read cache block error   detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_KEY_FETCH_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Key fetch failed error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_RNG_SEED_R_ERR_MSB])
    `uvm_error(get_name(), $sformatf("RNG seed read  error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_INVALID_CMD_ERR_MSB])
    `uvm_error(get_name(), $sformatf("Invalid command error detected 'h%h", my_data))

  if(my_data[`SINC_REGS_STATUS_CMD_FAILED_MSB])
    `uvm_error(get_name(), $sformatf("Command failed  error detected 'h%h", my_data))

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)

endtask : sinc_status_reg_err_chk

//CPU READ/WRITE access with data integrity check wrt ECC error
task sinc_ecc_error_inj_test_seq::cpu_mem_access_ecc_check(input ccpui_cpu_mem_addr_t addr, ccpui_cpu_mem_data_t exp_data, bit is_wr_rd, bit correctable);

  string                        debug_str      = "DV::sinc_cpu_mem_access_ecc_check";
  ccpui_cpu_mem_addr_t          cpu_addr;
  bit                           cpu_write;
  ccpui_cpu_mem_we_t            cpu_we;
  ccpui_cpu_mem_data_t          cpu_read_data;
  ccpui_cpu_mem_data_t          cpu_write_data = 0;
  logic                         cpu_loadstore;                                       // must be 1 for CPU WRITE
  logic                         cpu_privmode;
  bit                           is_mpu_allowed;
  bit                           r_acc_vio;
  bit                           r_accvio_ex;
  bit                           r_accvio_rd;
  bit                           r_accvio_wr;
  cache_mem_w_ecc_t             inj_data;
  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  `uvm_info (get_name(), $sformatf("%s: cpu_addr 'h%h", debug_str, addr), UVM_HIGH)

  //CPU Read
  if(!is_wr_rd) begin
    //for(int i=addr ; i< addr+4 ; i++) begin
    // task 1, test on address 0
    `uvm_info (get_name(), $sformatf("%s: task 1, test on address 'h%h", debug_str, addr), UVM_HIGH)
    // test read - addr[0]
    cpu_write     = 0;
    cpu_addr      = addr;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
      .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
    if (!is_mpu_allowed) begin
      if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
        `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
      end
    end else begin
      if ((cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) && correctable) begin
        `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
      end
    end

    //correctable : 1 = correctable error 0: uncorrectable error
    case({correctable, m_sinc_error_chk_disabled})
      2'b00: begin
        //Uncorrectable error, shoud return SINC_CPU_ERRDATA
        if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
          `uvm_error(get_name(), $sformatf("%s:Addr['h%h] Expect Data['h%h] due to uncorrectable error, Actual ['h%0h] ", debug_str, cpu_addr, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
        end
      end
      2'b01: begin
        //UnCorrectable error scenario With SINC_ERROR_CHK_DISABLED set to 1
        //expected to get corrupted data
        if (cpu_read_data === exp_data) begin
          `uvm_error(get_name(), $sformatf("%s:m_sinc_error_chk_disabled set, expected data not to be corrected .Addr['h%h] Expect Data['h%h] Actual ['h%0h]", debug_str, cpu_addr, exp_data, cpu_read_data))
        end
      end
      2'b10: begin
        //Correctable error scenario returns corrected data
        //Should be same as data before error injection
        if (cpu_read_data !== exp_data) begin
          `uvm_error(get_name(), $sformatf("%s:Addr['h%h] Expect Data['h%h] due to correctable error, Actual ['h%0h]", debug_str, cpu_addr, exp_data, cpu_read_data))
        end
      end
      2'b11: begin
        //Correctable error scenario with SINC_ERROR_CHK_DISABLED set to 1
        //Should get uncorrecte/corrupted data
        if (cpu_read_data === exp_data) begin
          `uvm_error(get_name(), $sformatf("%s:m_sinc_error_chk_disabled set expected data not to be corrected .Addr['h%h] Expect Data['h%h] Actual ['h%0h]", debug_str, cpu_addr, exp_data, cpu_read_data))
        end
      end
      default: begin
        //null
      end
    endcase
    `uvm_info (get_name(), $sformatf("%s:DEBUG : CPU READ access complete cpu_addr:'h%h data: 'h%h", debug_str, addr, cpu_read_data), UVM_HIGH)
  end
  //CPU WRITE
  else begin

    // test write - addr[0]
    cpu_write      = 1;
    cpu_addr       = addr;
    cpu_we         = 'hF;
    cpu_loadstore  = 1;
    cpu_privmode   = 1;
    cpu_write_data = 'hFFFF_FFFF;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
    `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

    // test read after write - addr[0]
    cpu_write     = 0;
    cpu_addr      = addr;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    if (cpu_read_data !== cpu_write_data) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
    end
    if(!correctable) begin
      if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA)
        `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h] due to uncorrectable error, Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
    end
    `uvm_info (get_name(), $sformatf("%s:DEBUG : CPU Write access complete cpu_addr:'h%h data: 'h%h", debug_str, addr, cpu_read_data), UVM_HIGH)

  end
  `uvm_info (get_name(), $sformatf("%s:Addr['h%0h]   cpu_read_data['h%0h] ", debug_str, addr, cpu_read_data), UVM_LOW)

endtask : cpu_mem_access_ecc_check

//CPU read/write access with data integrity checker
task sinc_ecc_error_inj_test_seq::cpu_mem_access_check(input ccpui_cpu_mem_addr_t addr, bit is_wr_rd, output ccpui_cpu_mem_data_t cpu_read_data);
  string                        debug_str      = "DV::sinc_cpu_mem_access_check";
  ccpui_cpu_mem_addr_t          cpu_addr;
  bit                           cpu_write;
  ccpui_cpu_mem_we_t            cpu_we;
  //ccpui_cpu_mem_data_t      cpu_read_data;
  ccpui_cpu_mem_data_t          cpu_write_data = 0;
  logic                         cpu_loadstore;                                   // must be 1 for CPU WRITE
  logic                         cpu_privmode;
  bit                           is_mpu_allowed;
  bit                           r_acc_vio;
  bit                           r_accvio_ex;
  bit                           r_accvio_rd;
  bit                           r_accvio_wr;
  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;

  `uvm_info (get_name(), $sformatf("%s: cpu_addr 'h%h", debug_str, addr), UVM_HIGH)

  if(!is_wr_rd) begin
    // test read - addr[0]
    cpu_write     = 0;
    cpu_addr      = addr;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    is_mpu_allowed = m_mpu_cfg.is_mpu_allowed(.we(cpu_write), .loadstore(cpu_loadstore), .accsrc(0), .priv_mode(cpu_privmode), .addr(cpu_addr), .r_acc_vio(r_acc_vio),
      .r_accvio_ex(r_accvio_ex), .r_accvio_rd(r_accvio_rd), .r_accvio_wr(r_accvio_wr));
    if (!is_mpu_allowed) begin
      if (cpu_read_data !== sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
        `uvm_error(get_name(), $sformatf("%s: Expect Data['h%h], Actual ['h%0h]", debug_str, sinc_parameters_pkg::SINC_CPU_ERRDATA, cpu_read_data))
      end
    end else begin
      if (cpu_read_data == sinc_parameters_pkg::SINC_CPU_ERRDATA) begin
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        if(my_status != UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end
        if((my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB]))
          `uvm_error(get_name(), $sformatf("%s:unexpected HW_FAULT. SINC_STATUS['h%0h], CPU_READ_DATA ['h%0h]", debug_str, my_data, cpu_read_data))
      end
    end

    `uvm_info (get_name(), $sformatf("%s:DEBUG : CPU READ access complete cpu_addr:'h%h data: 'h%h", debug_str, addr, cpu_read_data), UVM_HIGH)
  end else begin
    // test write - addr[0]
    cpu_write      = 1;
    cpu_addr       = addr;
    cpu_we         = 'hF;
    cpu_loadstore  = 1;
    cpu_privmode   = 1;
    cpu_write_data = 'hFFFF_FFFF;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_write(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .write_data(cpu_write_data), .we(cpu_we));
    `uvm_info (get_name(), $sformatf("%s: CPU Write addr['h%0h], write_data['h%0h]", debug_str, cpu_addr, cpu_write_data), UVM_HIGH)

    // test read after write - addr[0]
    cpu_write     = 0;
    cpu_addr      = addr;
    cpu_we        = 'h0;
    cpu_loadstore = 1;
    cpu_privmode  = 1;
    m_cpu_rand_seq.m_cpu_mem_seq.ccpui_cpu_mem_read(.addr(cpu_addr), .loadstore(cpu_loadstore), .privmode(cpu_privmode), .read_data(cpu_read_data));
    `uvm_info (get_name(), $sformatf("%s: CPU Read addr['h%0h], read_data['h%0h]", debug_str, cpu_addr, cpu_read_data), UVM_HIGH)
    if (cpu_read_data !== cpu_write_data) begin
      `uvm_error(get_name(), $sformatf("%s: Expect Data['h%0h], Actual ['h%0h]", debug_str, cpu_write_data, cpu_read_data))
    end
    `uvm_info (get_name(), $sformatf("%s:DEBUG : CPU Write access complete cpu_addr:'h%h data: 'h%h", debug_str, addr, cpu_read_data), UVM_HIGH)
  end
  //end

  `uvm_info (get_name(), $sformatf("%s: test on address 'h%h - done", debug_str, addr), UVM_LOW)

endtask : cpu_mem_access_check

task sinc_ecc_error_inj_test_seq::disable_state_fw_operations();
  string         debug_str              = "DV::disable_state_fw_operations";
  reg_data_t     aes_iv_nonce_0         = 'h0;
  reg_data_t     aes_iv_nonce_1         = 'h0;
  reg_data_t     aes_iv_nonce_2         = 'h0;
  reg_data_t     block_encr_key         = 'h0;
  reg_data_t     ext_block_base_addr    = 'h0;
  reg_data_t     ext_auth_tag_base_addr = 'h0;
  uvm_reg_data_t my_data;
  bit            timeout;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  load_key_to_axi_mem(m_sys_cfg.m_aes_cfg.m_key_axi_addr, m_sys_cfg.m_aes_cfg.m_key_data);
  fw_set_init_state (.program_misc_reg(1), .aes_iv_nonce_0(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0]), .aes_iv_nonce_1(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1]), .aes_iv_nonce_2(m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2]), .block_encr_key(m_sys_cfg.m_aes_cfg.m_key_slot), .ext_block_base_addr(m_sys_cfg.m_ext_block_base_addr), .ext_auth_tag_base_addr(m_sys_cfg.m_ext_auth_tag_base_addr));

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  // fixme-hw: below code will be removed after scoreboard and monitor in place
  m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_INIT_STATE;

endtask : disable_state_fw_operations

task sinc_ecc_error_inj_test_seq::init_state_fw_operations();
  string         debug_str       = "DV::init_state_fw_operations";
  bit            timeout;
  uvm_reg_data_t my_data;
  reg_data_t     block_encr_num  = 'h0;
  reg_data_t     block_encr_addr = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;
  reg_data_t     num_of_blocks   = 'h1;
  int            num_encrypts;

  `uvm_info (get_name(), $sformatf("%s: task started", debug_str), UVM_LOW)

  m_set_for_encrypt     = 'h0;
  m_tags_for_encrypt[0] = 'h0;

  //For CPU MEM only case we are testing cache evicition
  //when other tests are present we only test hits and misses with one block due to sanity test time constraints
  //For cache eviction case 4 we need to encrypt 4 blocks with same set and different tags will fill in the cache set (4-way associated cache)
  //Then need to encrypt 5th block with same set and different tag to use to trigger an evict of the first block with
  //Since each block needs to have same set and different tag, they aren't contiguous
  //so need to do 5 encrypt block commands with num_of_blocks set to 1
  if(m_cpu_mem_test_only) begin
    num_encrypts          = 5;
    m_tags_for_encrypt[1] = 'h18;
    m_tags_for_encrypt[2] = 'h31;
    m_tags_for_encrypt[3] = 'h3c;
    m_tags_for_encrypt[4] = 'had;
  end else begin
    num_encrypts = 1;
  end

  for (int i=0; i < num_encrypts; i++) begin
    //256kb Iram with 512 byte block size, and 4 way set associative means 128 sets (256*1024)/(512*4), so 7 bits for set
    //16MB external memory with 512 byte block size means 32, 768 blocks, so block num is 14:0 with 14:7 being the tag
    block_encr_num[6:0]  = m_set_for_encrypt;
    block_encr_num[14:7] = m_tags_for_encrypt[i];
    fw_block_encr(.program_misc_reg(1), .block_encr_num(block_encr_num), .block_encr_addr(block_encr_addr), .num_of_blocks(num_of_blocks));

    pull_status(my_data, timeout);
    `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

    if (timeout) begin
      `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
    end else begin
      if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB])) begin
        `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
            my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
      end
    end
  end

  // change cache state from init to active
  fw_set_active_state();

  pull_status(my_data, timeout);
  `uvm_info (get_name(), $sformatf("%s: Status['h%0h], timeout[%0d]", debug_str, my_data, timeout), UVM_HIGH)

  if (timeout) begin
    `uvm_error(get_name(), $sformatf("%s: Pull status timeout(%0d)", debug_str, timeout))
  end else begin
    if (!(my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB] && (my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hF0))) begin
      `uvm_error(get_name(), $sformatf("%s: expected cmd_success[1]vs.[%0d], Cache_state[F]vs.['h%0h]", debug_str,
          my_data[`SINC_REGS_STATUS_CMD_SUCCESS_LSB], my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB]))
    end
  end

  m_sys_cfg.m_cur_cache_state = sinc_parameters_pkg::CACHE_ACTIVE_STATE;

  `uvm_info (get_name(), $sformatf("%s: task finished", debug_str), UVM_LOW)
endtask : init_state_fw_operations

task sinc_ecc_error_inj_test_seq::find_flipped_bit(ccpui_cpu_mem_addr_t addr, cache_mem_w_ecc_t data1, cache_mem_w_ecc_t data2, output int flipped_bit);
  string            debug_str = "find_flipped_bit";
  cache_mem_w_ecc_t xor_data;
  flipped_bit = 0;
  xor_data    = data1 ^ data2;
  for (int i = 0; i < sinc_parameters_pkg::SINC_CACHE_MEM_RAM_WIDTH; i++) begin
    if (xor_data[i] === 1) begin
      flipped_bit = i;
      break;
    end
  end
  `uvm_info(debug_str, $sformatf("original data['h%0h] inj_data['h%0h]  flipped bit [%0d] xor_data['h%0h] ", data1, data2, flipped_bit, xor_data ), UVM_LOW)
endtask : find_flipped_bit

task sinc_ecc_error_inj_test_seq::get_error_injected_address(
           ccpui_cpu_mem_addr_t addr,
           cache_mem_w_ecc_t    data1,
           cache_mem_w_ecc_t    data2,
    output ccpui_cpu_mem_addr_t flipped_bit_address,
    output bit [7:0]            addr_index
  );
  string debug_str     = "get_error_injected_address";
  int    flipped_bit;
  //Each data blk consisits of 32b data + 7b parity
  int    data_blk_size = 39;

  find_flipped_bit(addr, data1, data2, flipped_bit);
  addr_index          = flipped_bit / data_blk_size;
  flipped_bit_address = addr + (flipped_bit / data_blk_size);
  `uvm_info(debug_str, $sformatf("original address['h%0h] inj_address['h%0h]  flipped bit [%0d] addr_index[%0d]", addr, flipped_bit_address, flipped_bit, addr_index ), UVM_LOW)
endtask : get_error_injected_address

//Scenario:
//Access a cache memory location and check no error triggered
//Inject 1 bit error in the same memory
//Access the same memory location, corr error should generated
//Read from error injected memory shoud return corrected data
//If sinc_err_chk_disable is set corrupted data will be returned

task sinc_ecc_error_inj_test_seq::correctable_ecc_error();
  uvm_reg_data_t       my_data;
  bit                  timeout;
  ccpui_cpu_mem_data_t read_data;
  ccpui_cpu_mem_data_t mem_read_data[4];
  string               debug_str        = "correctable_ecc_error";
  cache_mem_w_ecc_t    data_orig;
  cache_mem_w_ecc_t    data_inj;
  ccpui_cpu_mem_addr_t addr;
  ccpui_cpu_mem_addr_t mem_addr;
  ccpui_cpu_mem_addr_t addr_err_inj;
  bit [7:0]            addr_index;

  //Disbaled state correcatble ecc error check
  //Check cpu mem access before error injection
  addr = 'h0;
  `uvm_info(get_name(), "CPU access before error injection 2", UVM_LOW)
  cpu_mem_access_check(addr, 0, read_data);
  mem_read_data[0] = read_data;
  cpu_mem_access_check(addr + 1, 0, read_data);
  mem_read_data[1] = read_data;
  cpu_mem_access_check(addr + 2, 0, read_data);
  mem_read_data[2] = read_data;
  cpu_mem_access_check(addr + 3, 0, read_data);
  mem_read_data[3] = read_data;

  mem_addr  = addr / 4;
  data_orig = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  //1 bit Error injection(correctable)
  `uvm_info(get_name(), "Starting error injection ", UVM_LOW)
  ramwrap_ecc_error_inj_w_addr (mem_addr, 1, 0);
  `uvm_info(get_name(), "Completed error injection ", UVM_LOW)
  data_inj = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  get_error_injected_address(addr, data_orig, data_inj, addr_err_inj, addr_index);

  cpu_mem_access_ecc_check(addr_err_inj, mem_read_data[addr_index], 0, 1);
  sinc_status_reg_err_chk(1);

  addr = 'hFFFC;
  `uvm_info(get_name(), "CPU access before error injection 2", UVM_LOW)
  cpu_mem_access_check(addr, 0, read_data);
  mem_read_data[0] = read_data;
  cpu_mem_access_check(addr + 1, 0, read_data);
  mem_read_data[1] = read_data;
  cpu_mem_access_check(addr + 2, 0, read_data);
  mem_read_data[2] = read_data;
  cpu_mem_access_check(addr + 3, 0, read_data);
  mem_read_data[3] = read_data;

  mem_addr  = addr / 4;
  data_orig = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  //1 bit Error injection(correctable)
  `uvm_info(get_name(), "Starting error injection ", UVM_HIGH)
  ramwrap_ecc_error_inj_w_addr (mem_addr, 1, 0);
  `uvm_info(get_name(), "Completed error injection ", UVM_HIGH)
  data_inj = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  get_error_injected_address(addr, data_orig, data_inj, addr_err_inj, addr_index);

  cpu_mem_access_ecc_check(addr_err_inj, mem_read_data[addr_index], 0, 1);
  sinc_status_reg_err_chk(1);

  wait_n_clks(50);

  disable_state_fw_operations();

  wait_n_clks(20);
  `uvm_info(get_name(), "Starting register test for INIT STATE", UVM_LOW)

  addr = 24;
  `uvm_info(get_name(), "CPU access before error injection 2", UVM_HIGH)
  cpu_mem_access_check(addr, 0, read_data);
  mem_read_data[0] = read_data;
  cpu_mem_access_check(addr + 1, 0, read_data);
  mem_read_data[1] = read_data;
  cpu_mem_access_check(addr + 2, 0, read_data);
  mem_read_data[2] = read_data;
  cpu_mem_access_check(addr + 3, 0, read_data);
  mem_read_data[3] = read_data;

  mem_addr  = addr / 4;
  data_orig = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  //1 bit Error injection(correctable)
  `uvm_info(get_name(), "Starting error injection ", UVM_HIGH)
  ramwrap_ecc_error_inj_w_addr (mem_addr, 1, 0);
  `uvm_info(get_name(), "Completed error injection ", UVM_HIGH)
  data_inj = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  get_error_injected_address(addr, data_orig, data_inj, addr_err_inj, addr_index);

  cpu_mem_access_ecc_check(addr_err_inj, mem_read_data[addr_index], 0, 1);
  sinc_status_reg_err_chk(1);
  //Check write
  cpu_mem_access_ecc_check(addr, read_data, 1, 1);
  sinc_status_reg_err_chk(1);

  init_state_fw_operations();

  `uvm_info(get_name(), "Starting register test for ACTIVE STATE", UVM_LOW)
  wait_n_clks(20);

  addr = 4;
  `uvm_info(get_name(), "CPU access before error injection 2", UVM_HIGH)
  cpu_mem_access_check(addr, 0, read_data);
  mem_read_data[0] = read_data;
  cpu_mem_access_check(addr + 1, 0, read_data);
  mem_read_data[1] = read_data;
  cpu_mem_access_check(addr + 2, 0, read_data);
  mem_read_data[2] = read_data;
  cpu_mem_access_check(addr + 3, 0, read_data);
  mem_read_data[3] = read_data;

  mem_addr  = addr;
  data_orig = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  //1 bit Error injection(correctable)
  `uvm_info(get_name(), "Starting error injection ", UVM_HIGH)
  ramwrap_ecc_error_inj_w_addr (mem_addr, 1, 1);
  `uvm_info(get_name(), "Completed error injection ", UVM_HIGH)
  data_inj = m_top_configuration.m_mem_bkdoor_if.cache_mem_read(int'(mem_addr));
  get_error_injected_address(addr, data_orig, data_inj, addr_err_inj, addr_index);

  cpu_mem_access_ecc_check(addr_err_inj, mem_read_data[addr_index], 0, 1);
  sinc_status_reg_err_chk(1);

  wait_n_clks(20);

endtask : correctable_ecc_error

//Scenario:
//Access a cache memory location and check no error triggered
//Inject 2 bit error in the same memory
//Access the same memory location, uncorr error should generated
//HW fault should be set in status register
//Read from error injected memory shoud return ERRDATA(0)
//Cache will be in cache failed state
//Need to issue fw reset command to recover cache fsm to disbaled state.
//If sinc_err_chk_disable is set corrupted data will be returned without any
//error set in STATUS register

task sinc_ecc_error_inj_test_seq::uncorrectable_ecc_error();
  uvm_reg_data_t       my_data;
  bit                  timeout;
  ccpui_cpu_mem_data_t read_data;
  string               debug_str = "uncorrectable_ecc_error";
  ccpui_cpu_mem_addr_t addr;
  ccpui_cpu_mem_addr_t mem_addr;

  wait_n_clks(20);
  if(m_cache_state == DISABLED) begin

    `uvm_info(get_name(), $sformatf("%s sequnce started in %s cache state", debug_str, m_cache_state.name()), UVM_LOW)
    //The error injcted in cache ram is 128bit while CPU reads 32 bits per
    addr = 4;
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "CPU access before error injection completed", UVM_HIGH)
    mem_addr = addr / 4;
    ramwrap_ecc_error_inj_w_addr (mem_addr, 0, 0);
    `uvm_info(get_name(), "Completed error injection in disabled state", UVM_HIGH)
    cpu_mem_access_ecc_check(addr, read_data, 0, 0);
    error_chk_and_recovery();
    wait_n_clks(10);
    `uvm_info(get_name(), "Starting CPU access after error recovery", UVM_HIGH)
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "CPU access after error recovery completed", UVM_HIGH)

  end

  if(m_cache_state == INIT) begin

    `uvm_info(get_name(), $sformatf("%s sequnce started in %s cache state", debug_str, m_cache_state.name()), UVM_LOW)
    disable_state_fw_operations();
    `uvm_info(get_name(), "Starting  INIT STATE", UVM_HIGH)
    //The error injcted in cache ram is 128bit while CPU reads 32 bits per
    addr = 8;
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "CPU access before error injection completed", UVM_HIGH)
    mem_addr = addr / 4;
    ramwrap_ecc_error_inj_w_addr (mem_addr, 0, 0);
    `uvm_info(get_name(), "Completed error injection in disabled state", UVM_HIGH)
    cpu_mem_access_ecc_check(addr, read_data, 0, 0);
    error_chk_and_recovery();
    `uvm_info(get_name(), "Completed error_chk_and_recovery", UVM_HIGH)
    wait_n_clks(10);
    `uvm_info(get_name(), "started mem access after err inj done", UVM_HIGH)
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "Completed error_chk_and_recovery", UVM_HIGH)

  end

  if(m_cache_state == ACTIVE) begin

    `uvm_info(get_name(), $sformatf("%s sequnce started in %s cache state", debug_str, m_cache_state.name()), UVM_LOW)
    disable_state_fw_operations();
    `uvm_info(get_name(), "Starting  INIT STATE", UVM_HIGH)
    init_state_fw_operations();

    `uvm_info(get_name(), "Starting  ACTIVE STATE", UVM_HIGH)
    wait_n_clks(20);
    addr = 24;
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "CPU access before error injection completed", UVM_HIGH)
    ramwrap_ecc_error_inj_w_addr (addr, 0, 1);
    `uvm_info(get_name(), "Completed error injection in Active state", UVM_HIGH)
    cpu_mem_access_ecc_check(addr, read_data, 0, 0);
    `uvm_info(get_name(), "CPU access after error injetion done", UVM_HIGH)
    error_chk_and_recovery();
    wait_n_clks(20);
    `uvm_info(get_name(), "Starting CPU access after error recovery", UVM_HIGH)
    cpu_mem_access_check(addr, 0, read_data);
    `uvm_info(get_name(), "CPU access after error recovery completed", UVM_HIGH)

  end

endtask : uncorrectable_ecc_error

task sinc_ecc_error_inj_test_seq::error_chk_and_recovery();
  string debug_str = "DV::error_chk_and_recovery";

  uvm_reg_data_t                my_data;
  uvm_status_e                  my_status;
  sinc_axi_reg_access_extension ext_obj;
  process                       ecc_proc[$];
  bit                           timeout;

  ext_obj = sinc_axi_reg_access_extension::type_id::create("ext_obj", , get_full_name());
  if (0 == ext_obj.randomize() with {
        // add flavor if need
      }) begin
    `uvm_fatal(get_name(), $sformatf("%s: randomize failed!!!", "sinc_axi_reg_access_extension object"))
  end

  if(!m_sinc_error_chk_disabled) begin
    `uvm_info (get_name(), $sformatf("%s: start checking STATUS register", debug_str), UVM_HIGH)
    //Wait for status register
    fork : check_for_busy_fork
      begin
        ecc_proc.push_back(process::self());
        m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
        if(my_status != UVM_IS_OK) begin
          `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
        end
        // SINC UNCORRECTABLE ERROR
        while (!my_data[`SINC_REGS_STATUS_SINC_HW_FAULT_LSB]) begin//hw fault
          //If m_sinc_error_chk_disabled is set no need to wait for HW fault
          wait_n_clks(10);
          m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
          if(my_status != UVM_IS_OK) begin
            `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
          end
        end
        timeout=0;
        `uvm_info(get_name(), $sformatf("Observed HW_FAULT error, STATUS_REG[%d] ='h%h", `SINC_REGS_STATUS_SINC_HW_FAULT_LSB, my_data), UVM_LOW)
      end
      begin
        ecc_proc.push_back(process::self());
        `uvm_info(get_name(), "check_error_status : timeout loop started", UVM_HIGH)
        wait_n_clks(1000);
        timeout=1;
        `uvm_info(get_name(), "check_error_status : timeout loop ended", UVM_HIGH)
      end
    join_any
    // Kill any outstanding processes
    foreach(ecc_proc[i]) begin
      if ((ecc_proc[i] != null) && (ecc_proc[i].status() != process::FINISHED)) begin
        ecc_proc[i].kill();
      end
    end

    //if(!m_sinc_error_chk_disabled) begin
    if(timeout)
      `uvm_error(get_name(), $sformatf("expected Uncorratable error but not triggered. SINC STATUS ['h%h]", my_data))
    else begin
      wait_n_clks(5);
      m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
      if(my_status != UVM_IS_OK) begin
        `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
      end
      //STATUS[7:0] == 'hFF : Cache failed state
      if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] !== 'hFF)
        `uvm_error(get_name(), $sformatf("Expected Cache_failed state. SINC STATE ['h%h]", my_data))

      if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hFF) begin
        `uvm_info(get_name(), $sformatf("In CACHE_FAILED_STATE, issuing reset cmd STATUS_REG['h%h]", my_data), UVM_LOW)
        fw_sinc_reset_cmd();
        pull_status(my_data, timeout);
      end
    end
  end else begin
    `uvm_info(get_name(), "error_chk_and_recovery : skipping waiting for STATUS register read as m_sinc_error_chk_disabled set", UVM_HIGH)
    wait_n_clks(5);
    m_regmodel.status.read(my_status, my_data, .extension(ext_obj));
    if(my_status != UVM_IS_OK) begin
      `uvm_error(get_name(), $sformatf("m_regmodel.status.read returned status %s", my_status.name()))
    end
    if(my_data[`SINC_REGS_STATUS_STATE_MSB:`SINC_REGS_STATUS_STATE_LSB] === 'hFF)
      `uvm_error(get_name(), $sformatf("SINC_ERROR_CHK_DISABLED set Cache_failed state not expected. SINC STATE ['h%h]", my_data))
  end

  `uvm_info(get_name(), "error_chk_and_recovery : DONE", UVM_HIGH)

endtask : error_chk_and_recovery

`endif // SINC_ECC_ERROR_INJ_TEST_SEQ
