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
// File        : sinc_axi_packet.svh
// Description : This is AXI packet used to randomize AXI requests to SINC.

`ifndef SINC_AXI_PACKET
`define SINC_AXI_PACKET

//---------------------------------
// SINC AXI Packet Class
//---------------------------------
class sinc_axi_packet extends sinc_base_packet;

  typedef sinc_axi_packet this_t;

  `uvm_object_utils(sinc_axi_packet)

  // AXI Attributes will be randomized without constraints, will be parsed at post_random
  rand pal_id_t                           m_rand_id;
  rand pal_beat_size_t                    m_rand_burst_size;
  rand pal_prot_t                         m_rand_prot          = PAL_NORM_SEC_DATA;
  rand pal_lock_t                         m_rand_lock          = PAL_NORMAL;
  rand pal_cache_t                        m_rand_cache         = PAL_NONMODIFIABLE_NONBUF;
  rand pal_axuser_t                       m_rand_axuser        = 0;
  rand pal_burst_type_t                   m_rand_burst_type;
  rand int                                m_rand_beats_delay[] = {};
  rand sinc_parameters_pkg::sinc_fw_cmd_e m_fw_cmd;
  rand sinc_parameters_pkg::sinc_reg_e    m_rd_dst_reg;
  rand sinc_parameters_pkg::sinc_reg_e    m_wr_dst_reg;

  // AXI Attributes used by sequence
  pal_addr_t       m_addr;
  bit [7:0]        m_write_data[];
  bit              m_wstrb[]       = {};
  bit [7:0]        m_read_data[];
  bit [9:0]        m_burst_length;
  pal_id_t         m_id;
  pal_beat_size_t  m_burst_size;
  pal_prot_t       m_prot;
  pal_lock_t       m_lock          = PAL_NORMAL;
  pal_cache_t      m_cache         =PAL_NONMODIFIABLE_NONBUF;
  pal_axuser_t     m_axuser        = 0;
  pal_burst_type_t m_burst_type    = PAL_BT_INCR;
  int              m_beats_delay[] = {};
  pal_resp_type_t  m_response;

  // the axi_cmd should preset by the sequence, default as read
  sinc_axi_cmd_e m_axi_cmd                      = sinc_env_pkg::SINC_AXI_SUB_READ;
  // decision on whether program registers with 8 * 32 bursts
  bit            m_en_global_long_write         = 0;
  // register handler index
  int            m_reg_handler_index;
  // when is_valid_req is set, the constraint will try to find request with attributes that result a valid transaction (response with OKAY)
  rand bit       m_is_valid_req;
  // when do_fw_request is set, write to control register to start one of the firmware operations, only valid for a write
  rand bit       m_do_fw_request;
  bit            m_pull_status_after_fw_request;

  // destination register
  sinc_parameters_pkg::sinc_reg_e m_dst_reg;
  uvm_reg_data_t                  m_reg_value;
  bit                             m_post_random_wdata;
  // string for destination register name
  string                          m_dst_reg_str;
  // reg model
  sinc_regmodel                   m_regmodel;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_axi_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // post_randomize()
  //---------------------------------
  extern function void post_randomize ();

  //---------------------------------
  // print_packet()
  //---------------------------------
  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  extern constraint order_c;

  // when m_DISABLE_ILLEGAL_REQ is set in sys_cfg, this packet will always set is_valid_req == 1
  // patched: this sinc_axi_packet is always aiming for valid request
  // error corruption will be done in err_inj_packet
  extern constraint valid_req_c;

  extern constraint valid_fw_cmd_c;

  extern constraint aes_only_disabled_c;

  // this constraint is not really neccesary when error cases supported in RTL
  // delete this when there is generic issues
  extern constraint master_id_c;

  extern constraint do_fw_request_c;

  extern constraint rd_dst_reg_c;

  extern constraint wr_dst_reg_c;

  extern constraint burst_type_c;
  extern constraint axi_burst_size_c;

endclass : sinc_axi_packet

function void sinc_axi_packet::post_randomize ();
  uvm_reg my_reg;
  bit     do_override_fw_cmd;
  int     rand_num;
  // randomized item under constraints:
  // is legal request aimed: is_valid_req

  `uvm_info(get_name(), $sformatf("post_randomize: debug - axi_cmd[%0s] \n", m_axi_cmd.name()), UVM_LOW)

  if (m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_READ) begin
    m_dst_reg = m_rd_dst_reg;
  end
  if (m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
    m_dst_reg = m_wr_dst_reg;
  end

  // common attributes
  // assign master component ID
  m_axuser       = m_rand_axuser;
  m_id           = m_rand_id;
  m_burst_size   = m_rand_burst_size;
  m_prot         = m_rand_prot;
  m_lock         = m_rand_lock;
  m_cache        = m_rand_cache;
  m_burst_length = 1;
  m_burst_type   = m_rand_burst_type;
  m_beats_delay  = m_rand_beats_delay;

  // set up address, data
  // structure register write AXI attributes
  my_reg = m_regmodel.get_reg_by_name(m_dst_reg.name().tolower());
  m_addr = my_reg.get_address();
  `uvm_info(get_name(), $sformatf("get reg[%0s] address['h%0h] \n", m_dst_reg.name(), m_addr), UVM_LOW)

  if (m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_READ) begin
    m_read_data = new[4];
  end else begin
    m_write_data = new[4];

    if (!std::randomize(m_write_data)) begin
      `uvm_fatal(get_name(), "Unable to randomize wdata")
    end

    m_post_random_wdata            = 0;
    m_pull_status_after_fw_request = 1;

    if (m_do_fw_request) begin
      m_dst_reg               = sinc_parameters_pkg::CMD;
      my_reg                  = m_regmodel.get_reg_by_name(m_dst_reg.name().tolower());
      m_addr                  = my_reg.get_address();
      do_override_fw_cmd      = 0;
      m_sys_cfg.m_skip_fw_cmd = 0;

      //handle cases where reset or reinit are result of randomization but are disabled
      //and also cases where disable commands are not allowed
      if((m_sys_cfg.m_sinc_tb_seq_never_dis_cmds == 1) && ((m_fw_cmd == SINC_DISABLE_RESET) || (m_fw_cmd == SINC_DISABLE_REINIT))) begin
        do_override_fw_cmd = 1;
      end
      if((m_sys_cfg.m_sinc_reset_disabled == 1) && (m_fw_cmd == SINC_SINC_RESET)) begin
        do_override_fw_cmd = 1;
      end
      if((m_sys_cfg.m_sinc_reinit_disabled == 1) && (m_fw_cmd == SINC_SINC_REINIT)) begin
        do_override_fw_cmd = 1;
      end
      if(m_sys_cfg.m_sinc_tb_seq_never_do_aes_test_cmds && (m_fw_cmd == SINC_AES_TEST_EN)) begin
        do_override_fw_cmd = 1;
      end


      //cache active should skip command most of time since only command options are
      //reset, reinit, or disable reset/reinit
      if(m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) begin
        if(!std::randomize(m_sys_cfg.m_skip_fw_cmd) with {m_sys_cfg.m_skip_fw_cmd dist {1:=60, 0:=40}; }) begin
          `uvm_fatal("RAND", "std::randomize failed to randomize sys_cfg.m_skip_fw_cmd")
        end
      end

      //select what fw_cmd to override with based on state
      if(do_override_fw_cmd) begin
        if(m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) begin
          m_fw_cmd = SINC_ENCR_BLOCK;
        end else begin
          m_sys_cfg.m_skip_fw_cmd = 1;
        end
      end
      `uvm_info(get_name(), $sformatf("post_randomize: debug setting m_skip_fw_cmd=1 - end\n"), UVM_HIGH)

      //handle always aes test mode override
      if(m_sys_cfg.m_sinc_tb_seq_only_do_aes_test_cmds) begin
        m_fw_cmd = SINC_AES_TEST_EN;
      end

      //handle desires cstate override, make sure we don't do any transition
      //todo switch to using enum instead of hard coded integer value for desired state
      if(m_sys_cfg.m_sinc_tb_seq_use_des_cache_state) begin
        case(m_sys_cfg.m_sinc_tb_seq_des_cache_state)
          //desired state is disabled
          0: begin
            if(m_fw_cmd == SINC_SET_INIT_STATE) begin
              m_fw_cmd = SINC_AES_TEST_EN;
            end
          end
          //desired state is initialized
          1: begin
            if((m_fw_cmd == SINC_SET_CACHE_ACTIVE_STATE) || (m_fw_cmd == SINC_SINC_RESET)) begin
              m_fw_cmd = SINC_ENCR_BLOCK;
            end
          end
          //desired state is active
          2: begin
            if((m_fw_cmd == SINC_SINC_REINIT) || (m_fw_cmd == SINC_SINC_RESET)) begin
              m_sys_cfg.m_skip_fw_cmd = 1;
            end
          end
          3: begin
            if(m_fw_cmd == SINC_SINC_RESET) begin
              m_sys_cfg.m_skip_fw_cmd = 1;
            end
          end
          default: begin
            //empty
          end
        endcase
      end

      m_reg_value         = m_fw_cmd;
      m_post_random_wdata = 1;
    end else begin
      //these registers need to be written with specific values, randomized once at start
      //also need to keep track of if these were set yet for some commands
      if(m_wr_dst_reg == sinc_parameters_pkg::AES_IV_NONCE_0) begin
        m_reg_value               = m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[0];
        m_post_random_wdata       = 1;
        m_sys_cfg.m_nonce0_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::AES_IV_NONCE_1) begin
        m_reg_value               = m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[1];
        m_post_random_wdata       = 1;
        m_sys_cfg.m_nonce1_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::AES_IV_NONCE_2) begin
        m_reg_value               = m_sys_cfg.m_aes_cfg.m_aes_iv_nonce_regs[2];
        m_post_random_wdata       = 1;
        m_sys_cfg.m_nonce2_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::BLOCK_ENCR_KEY) begin
        m_reg_value                 = m_sys_cfg.m_aes_cfg.m_key_slot;
        m_post_random_wdata         = 1;
        m_sys_cfg.m_key_slot_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::EXT_BLOCK_BASE_ADDR) begin
        m_reg_value                       = m_sys_cfg.m_ext_block_base_addr;
        m_post_random_wdata               = 1;
        m_sys_cfg.m_ext_block_base_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::EXT_AUTH_TAG_BASE_ADDR) begin
        m_reg_value                          = m_sys_cfg.m_ext_auth_tag_base_addr;
        m_post_random_wdata                  = 1;
        m_sys_cfg.m_ext_auth_tag_base_is_set = 1;
      end else if(m_wr_dst_reg == sinc_parameters_pkg::BLOCK_ENCR_ADDR) begin
        m_reg_value                        = sinc_parameters_pkg::SINC_SHAREDRAM_START_ADDR;
        m_post_random_wdata                = 1;
        m_sys_cfg.m_block_encr_addr_is_set = 1;
      end
    end

    if(m_post_random_wdata) begin
      foreach(m_write_data[i]) begin
        m_write_data[i] = m_reg_value[8*i +: 8];
      end
    end
  end

  if (m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
    m_wstrb = new[m_write_data.size()];
    for (int di=0; di < m_write_data.size(); di++) begin
      m_wstrb[di] = 1;
    end
  end

  `uvm_info(get_name(), $sformatf("post_randomize: debug - end\n"), UVM_LOW)
endfunction : post_randomize

function void sinc_axi_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" AXI Request on Iter_Num [%0d]: \n", iter_n)};
  str = {str, $sformatf(" AXI CMD          : [%0s]\n", m_axi_cmd.name())};
  str = {str, $sformatf(" AXI Address      : ['h%0h]\n", m_addr)};
  str = {str, $sformatf(" AXI DO_FW_REQ    : [%0d]\n", m_do_fw_request)};
  str = {str, $sformatf(" AXI IS_VALID_REQ : [%0d]\n", m_is_valid_req)};
  str = {str, $sformatf(" Reg Access - [%0s]\n", m_dst_reg.name())};
  if (m_axi_cmd == sinc_env_pkg::SINC_AXI_SUB_WRITE) begin
    logic [31:0] write_data_32;
    if (m_do_fw_request) begin
      str = {str, $sformatf(" Reg Access       : FW_CMD - [%0s]\n", m_fw_cmd.name())};
    end
    write_data_32 = {m_write_data[3], m_write_data[2], m_write_data[1], m_write_data[0]};
    str           = {str, $sformatf(" AXI Wrtie Request Attributes : addr['h%0h], wdata_size_8bits[%0d], burst_length[%0d], id['h%0h], burst_size[%0s]\n", m_addr, m_write_data.size(), m_burst_length, m_id, m_burst_size.name())};
    str           = {str, $sformatf(" AXI Write data   : ['h%0h] \n", write_data_32)};
  end else begin
    str = {str, $sformatf(" AXI Read Request Attributes : addr['h%0h], rdata_size_8bits[%0d], burst_length[%0d], id['h%0h], burst_size[%0s], AxUSER['h%0h]\n", m_addr, m_read_data.size(), m_burst_length, m_id, m_burst_size.name(), m_axuser)};
  end
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_AXI_PACKET", str, UVM_HIGH)

endfunction : print_packet

constraint sinc_axi_packet::order_c {
  solve m_is_valid_req before m_rand_burst_size;
  solve m_is_valid_req before m_rand_axuser;
  solve m_do_fw_request before m_wr_dst_reg;
}

constraint sinc_axi_packet::valid_req_c {
  // if (sys_cfg.m_disable_illegal_req)
  if (1) {
    m_is_valid_req == 1;
    // for debug usage
    // dst_comp == SINC_REG;
  } else {
    // there shouldn't be further constraint
  }
}

constraint sinc_axi_packet::axi_burst_size_c {
  if (m_is_valid_req) {
    m_rand_burst_size == PAL_BYTES_4;
  } else {
    // there shouldn't be further constraint here
    // error injection packet will be used to introduce this error case
  }
}

constraint sinc_axi_packet::valid_fw_cmd_c {

  //todo consider making the weights configurable from yml file
  (m_sys_cfg.m_cur_cache_state == CACHE_DISABLE_STATE) -> {
    m_fw_cmd dist {
      SINC_SET_INIT_STATE :=m_sys_cfg.m_sinc_tb_seq_cmd_set_init_state_ratio,
      SINC_AES_TEST_EN    :=m_sys_cfg.m_sinc_tb_seq_cmd_aes_test_ratio,
      SINC_DISABLE_RESET  :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reset_disabled_ratio,
      SINC_DISABLE_REINIT :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reinit_disabled_ratio
    };
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) -> {
    m_fw_cmd dist {
      SINC_SET_CACHE_ACTIVE_STATE :=m_sys_cfg.m_sinc_tb_seq_cmd_set_cache_active_state,
      SINC_ENCR_BLOCK             :=m_sys_cfg.m_sinc_tb_seq_cmd_encr_block_ratio,
      SINC_SINC_RESET             :=m_sys_cfg.m_sinc_tb_seq_cmd_sinc_reset_init_ratio,
      SINC_DISABLE_RESET          :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reset_init_ratio,
      SINC_DISABLE_REINIT         :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reinit_init_ratio
    };
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) -> {
    m_fw_cmd dist {
      SINC_SINC_RESET     :=m_sys_cfg.m_sinc_tb_seq_cmd_sinc_reset_active_ratio,
      SINC_SINC_REINIT    :=m_sys_cfg.m_sinc_tb_seq_cmd_sinc_reinit_ratio,
      SINC_DISABLE_RESET  :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reset_active_ratio,
      SINC_DISABLE_REINIT :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reinit_active_ratio
    };
  }
  (m_sys_cfg.m_cur_cache_state == CACHE_FAIL_STATE) -> {
    m_fw_cmd dist {
      SINC_SINC_RESET     :=m_sys_cfg.m_sinc_tb_seq_cmd_sinc_reset_fail_ratio,
      SINC_DISABLE_RESET  :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reset_failed_ratio,
      SINC_DISABLE_REINIT :=m_sys_cfg.m_sinc_tb_seq_cmd_disable_reinit_failed_ratio
    };
  }
}

constraint sinc_axi_packet::aes_only_disabled_c {
  m_wr_dst_reg != sinc_parameters_pkg::AES_TEST_CTRL;
  //if(sys_cfg.m_cur_cache_state != CACHE_DISABLE_STATE) {
  //  m_fw_cmd != SINC_AES_TEST_EN;
  //}
}

constraint sinc_axi_packet::master_id_c {
  if (m_is_valid_req) {
    m_rand_axuser == sinc_parameters_pkg::SP_MST_ID;
  } else {
    // there shouldn't be further constraint here
    // error injection packet will be used to introduce this error case
  }
}

constraint sinc_axi_packet::do_fw_request_c {
  m_do_fw_request dist {
    0 := 100 - m_sys_cfg.m_sinc_tb_seq_fw_operation_req_ratio,
    1 := m_sys_cfg.m_sinc_tb_seq_fw_operation_req_ratio
  };
}

constraint sinc_axi_packet::rd_dst_reg_c {
  m_rd_dst_reg inside {m_sys_cfg.m_comp_cfg[SINC_REG].m_readable_reg_list};
}

constraint sinc_axi_packet::wr_dst_reg_c {
  m_wr_dst_reg inside {m_sys_cfg.m_comp_cfg[SINC_REG].m_writeable_reg_list};
  if(m_do_fw_request == 0) {
    m_wr_dst_reg != sinc_parameters_pkg::CMD;
    m_wr_dst_reg != sinc_parameters_pkg::AES_TEST_CTRL;
  }

  if(m_sys_cfg.m_cur_cache_state == CACHE_INIT_STATE) {
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_KEY;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_0;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_1;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_2;
  }

  if(m_sys_cfg.m_cur_cache_state == CACHE_ACTIVE_STATE) {
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_NUM;
    m_wr_dst_reg != sinc_parameters_pkg::NUM_OF_BLOCKS;
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_ADDR;
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_KEY;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_0;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_1;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_2;
    m_wr_dst_reg != sinc_parameters_pkg::EXT_BLOCK_BASE_ADDR;
    m_wr_dst_reg != sinc_parameters_pkg::EXT_AUTH_TAG_BASE_ADDR;
  }

  if(m_sys_cfg.m_cur_cache_state == CACHE_FAIL_STATE) {
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_NUM;
    m_wr_dst_reg != sinc_parameters_pkg::NUM_OF_BLOCKS;
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_ADDR;
    m_wr_dst_reg != sinc_parameters_pkg::BLOCK_ENCR_KEY;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_0;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_1;
    m_wr_dst_reg != sinc_parameters_pkg::AES_IV_NONCE_2;
    m_wr_dst_reg != sinc_parameters_pkg::EXT_BLOCK_BASE_ADDR;
    m_wr_dst_reg != sinc_parameters_pkg::EXT_AUTH_TAG_BASE_ADDR;
  }

}

constraint sinc_axi_packet::burst_type_c {
  m_rand_burst_type inside {PAL_BT_FIXED, PAL_BT_INCR};

}
`endif // SINC_AXI_PACKET
