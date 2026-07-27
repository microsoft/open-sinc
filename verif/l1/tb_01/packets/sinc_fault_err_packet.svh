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
// File        : sinc_fault_err_packet.svh
// Description : This is SINC Fault Error injection random stimulus packet with constraint

`ifndef SINC_FAULT_ERR_PACKET
`define SINC_FAULT_ERR_PACKET

//---------------------------------
// SINC AXI Packet Class
//---------------------------------
class sinc_fault_err_packet extends sinc_base_packet;

  typedef sinc_fault_err_packet this_t;

  `uvm_object_utils(sinc_fault_err_packet)

  // debug_str
  string m_debug_str = "SINC_FAULT_ERR_PACKET";

  randc sinc_ciu_fsm_t m_force_on_ciu_cache_fsm_state;
  rand logic [5:0]     m_illegal_ciu_cache_fsm_state;

  randc sinc_vtag_erase_fsm_t m_force_on_vtag_erase_fsm_state;
  rand logic [1:0]            m_illegal_vtag_erase_fsm_state;

  randc sinc_cmu_ctrl_fsm_t m_force_on_cmu_ctrl_fsm_state;
  rand logic [6:0]          m_illegal_cmu_ctrl_fsm_state;

  randc sinc_state_t m_force_on_cmu_sinc_cache_fsm_state;
  rand logic [7:0]   m_illegal_cmu_sinc_cache_fsm_state;

  randc sinc_sub_state_fsm_t m_force_on_sinc_sub_fsm_state;
  rand logic [5:0]           m_illegal_sinc_sub_fsm_state;

  randc sinc_aes_ctrl_fsm_t m_force_on_aes_ctrl_fsm_state;
  rand logic [5:0]          m_illegal_aes_ctrl_fsm_state;

  randc sinc_dma_r_fsm_t m_force_on_dma_r_fsm_state;
  rand logic [5:0]       m_illegal_dma_r_fsm_state;

  randc sinc_dma_w_fsm_t m_force_on_dma_w_fsm_state;
  rand logic [5:0]       m_illegal_dma_w_fsm_state;

  //GPAES/AES FSM

  randc aes_keyexp_fsm_e m_force_on_aes_keyexp_fsm_state;
  rand logic [3:0]       m_illegal_aes_keyexp_fsm_state;

  randc mode_main_fsm_t m_force_on_gpaes_mode_main_fsm_state;
  rand logic [6:0]      m_illegal_gpaes_mode_main_fsm_state;

  randc ghash_mul_fsm_t m_force_on_ghash_mul_fsm_state;
  rand logic [5:0]      m_illegal_ghash_mul_fsm_state;

  randc mode_ghash_fsm_t m_force_on_gpaes_mode_ghash_fsm_state;
  rand logic [5:0]       m_illegal_gpaes_mode_ghash_fsm_state;

  randc sub_state_fsm_t m_force_on_gpaes_sub_state_fsm_state;
  rand logic [4:0]      m_illegal_gpaes_sub_state_fsm_state;

  randc mode_sec_fsm_t m_force_on_gpaes_mode_sec_fsm_state;
  rand logic [5:0]     m_illegal_gpaes_mode_sec_fsm_state;

  rand fsm_halt_recover_op_type_e m_fsm_halt_recover_by_op;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_fault_err_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // pre_randomize()
  //---------------------------------
  function void pre_randomize ();
    string debug_str = "sinc_fault_err_packet_pre_randomize";

    // digest the request
  endfunction : pre_randomize

  //---------------------------------
  // post_randomize()
  //---------------------------------
  function void post_randomize ();

  endfunction : post_randomize

  //---------------------------------
  // print_packet()
  //---------------------------------

  extern virtual function void print_packet ( int iter_n=0 );

  //---------------------------------
  // Constraints
  //---------------------------------

  constraint ciu_cache_fsm_state_c;
  constraint cmu_ctrl_fsm_state_c;
  constraint sinc_state_c;
  constraint sinc_aes_ctrl_fsm_c;
  constraint sinc_sub_state_fsm_c;
  constraint sinc_dma_r_fsm_c;
  constraint sinc_dma_w_fsm_c;
  constraint ghash_mul_fsm_c;
  constraint gpaes_mode_main_fsm_c;
  constraint gpaes_mode_ghash_fsm_c;
  constraint gpaes_sub_state_fsm_c;
  constraint gpaes_mode_sec_fsm_c;
  constraint aes_keyexp_fsm_c;

endclass : sinc_fault_err_packet

function void sinc_fault_err_packet::print_packet ( int iter_n=0 );
  string str;
  str = "\n ****************************************** \n";
  str = {str, $sformatf(" Fault error corrupt packet on Iter_Num [%0d]: \n", iter_n)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_ciu_cache_fsm_state.name(), m_illegal_ciu_cache_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_cmu_ctrl_fsm_state.name(), m_illegal_cmu_ctrl_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_cmu_sinc_cache_fsm_state.name(), m_illegal_cmu_sinc_cache_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_sinc_sub_fsm_state.name(), m_illegal_sinc_sub_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_aes_ctrl_fsm_state.name(), m_illegal_aes_ctrl_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_dma_r_fsm_state.name(), m_illegal_dma_r_fsm_state)};
  str = {str, $sformatf(" Forcing state [%0s] into ['h%0h]: \n", m_force_on_dma_w_fsm_state.name(), m_illegal_dma_w_fsm_state)};
  str = {str, $sformatf(" Forcing recover from [HALT] by: [%0s]\n", m_fsm_halt_recover_by_op.name())};
  str = {str, "\n ****************************************** \n"};
  `uvm_info("SINC_FAULT_ERR_PACKET", str, UVM_HIGH)
endfunction : print_packet

constraint sinc_fault_err_packet::ciu_cache_fsm_state_c {
  if(m_sys_cfg.m_sinc_tb_seq_des_cache_state == 2){ //Active sinc state
    m_force_on_ciu_cache_fsm_state inside { CIU_MEM_READ, CIU_WAIT, CIU_CACHE_MISS, CIU_RREAD };
  } else {
    m_force_on_ciu_cache_fsm_state inside {CIU_IDLE, CIU_MEM_READ, CIU_WAIT, CIU_MEM_WRITE, CIU_EXTRA };
  }
  !(m_illegal_ciu_cache_fsm_state inside {CIU_IDLE, CIU_MEM_READ, CIU_WAIT, CIU_CACHE_MISS, CIU_RREAD, CIU_MEM_WRITE, CIU_EXTRA, CIU_SM_FAULT});
}

constraint sinc_fault_err_packet::cmu_ctrl_fsm_state_c {
  if(m_sys_cfg.m_sinc_tb_seq_des_cache_state == 2) {//Active sinc state
    m_force_on_cmu_ctrl_fsm_state inside {FETCH_BLOCK, SET_CACHE_ACTIVE, SINC_RESET, SINC_REINIT, ENCR_BLOCK, AES_TEST , AES_SEED};
  }
  if(m_sys_cfg.m_sinc_fault_error_type_sinc_sub_state_fsm_illegal == 1) {//sinc sub state
    m_force_on_cmu_ctrl_fsm_state inside {FETCH_BLOCK, SET_INIT, ENCR_BLOCK, AES_TEST , AES_SEED};
  }
  if( (m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_main_fsm_illegal == 1) ||
      (m_sys_cfg.m_sinc_fault_error_type_gpaes_ghash_mul_fsm_illegal == 1) ||
      (m_sys_cfg.m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal == 1) ||
      (m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_sec_fsm_illegal  == 1) ||
      (m_sys_cfg.m_sinc_fault_error_type_gpaes_mode_ghash_fsm_illegal== 1) ){//sinc gpaes state
    m_force_on_cmu_ctrl_fsm_state inside {FETCH_BLOCK, ENCR_BLOCK, AES_TEST , AES_SEED};
  }
  else {
    m_force_on_cmu_ctrl_fsm_state inside {SINC_IDLE, SET_INIT, SET_CACHE_ACTIVE, SINC_RESET, SINC_REINIT, ENCR_BLOCK, DIS_RESET, DIS_REINIT, AES_TEST , AES_SEED}; //
  }
  !(m_illegal_cmu_ctrl_fsm_state inside {SINC_IDLE, FETCH_BLOCK, SET_INIT, SET_CACHE_ACTIVE, SINC_RESET, SINC_REINIT, ENCR_BLOCK, DIS_RESET, DIS_REINIT, AES_TEST, AES_SEED});
}

constraint sinc_fault_err_packet::sinc_state_c {
  if(m_sys_cfg.m_sinc_tb_seq_des_cache_state == 2) {//Active sinc state
    m_force_on_cmu_sinc_cache_fsm_state inside {CACHE_ACTIVE}; //removing CACHE_FAILED as it will be covered in ecc error test
  }else {
    m_force_on_cmu_sinc_cache_fsm_state inside {DISABLED, INITIALIZATION, CACHE_ACTIVE}; //removing CACHE_FAILED as it will be covered in ecc error test
  }
  !(m_illegal_cmu_sinc_cache_fsm_state inside {DISABLED, INITIALIZATION, CACHE_ACTIVE, CACHE_FAILED});
}

constraint sinc_fault_err_packet::sinc_aes_ctrl_fsm_c {
  m_force_on_aes_ctrl_fsm_state inside {AES_IDLE, AES_IN, AES_OUT, AES_TAG_OUT, AES_TEST_IN, AES_TEST_OUT, AES_TEST_TAG_OUT, AES_BYPASS};
  !(m_illegal_aes_ctrl_fsm_state inside {AES_IDLE, AES_IN, AES_OUT, AES_TAG_OUT, AES_TEST_IN, AES_TEST_OUT, AES_TEST_TAG_OUT, AES_BYPASS});
}

constraint sinc_fault_err_packet::sinc_sub_state_fsm_c {
  m_force_on_sinc_sub_fsm_state inside {SINC_SUB_STATE_1, SINC_SUB_STATE_2, SINC_SUB_STATE_3, SINC_SUB_STATE_4, SINC_SUB_STATE_5};
  !(m_illegal_sinc_sub_fsm_state inside {SINC_SUB_STATE_1, SINC_SUB_STATE_2, SINC_SUB_STATE_3, SINC_SUB_STATE_4, SINC_SUB_STATE_5});
}

constraint sinc_fault_err_packet::sinc_dma_r_fsm_c {
  m_force_on_dma_r_fsm_state inside {DMA_R_IDLE, DMA_R_REQ, DMA_R_DATA, DMA_R_RESP, DMA_R_FLUSH};
  !(m_illegal_dma_r_fsm_state inside {DMA_R_IDLE, DMA_R_REQ, DMA_R_DATA, DMA_R_RESP, DMA_R_FLUSH});
}

constraint sinc_fault_err_packet::sinc_dma_w_fsm_c {
  if(m_sys_cfg.m_sinc_tb_seq_des_cache_state) {
    m_force_on_dma_w_fsm_state inside {DMA_W_IDLE};
  } else {
    m_force_on_dma_w_fsm_state inside {DMA_W_IDLE, DMA_W_REQ, DMA_W_DATA, DMA_W_RESP, DMA_W_FLUSH};
  }
  !(m_illegal_dma_w_fsm_state inside {DMA_W_IDLE, DMA_W_REQ, DMA_W_DATA, DMA_W_RESP, DMA_W_FLUSH});
}

constraint sinc_fault_err_packet::ghash_mul_fsm_c {
  m_force_on_ghash_mul_fsm_state inside {CNT0, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6, CNT7};
  !(m_illegal_ghash_mul_fsm_state inside {CNT0, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6, CNT7});
}

constraint sinc_fault_err_packet::gpaes_mode_main_fsm_c {
  m_force_on_gpaes_mode_main_fsm_state inside {MODE_IDLE, MODE_CFG, MODE_IV, MODE_KEY, MODE_WAIT_DRBG, MODE_HASH_SUBKEY, MODE_AAD, MODE_DATA, MODE_TAG, MODE_ERR};
  !(m_illegal_gpaes_mode_main_fsm_state inside {MODE_IDLE, MODE_CFG, MODE_IV, MODE_KEY, MODE_WAIT_DRBG, MODE_HASH_SUBKEY, MODE_AAD, MODE_DATA, MODE_TAG, MODE_ERR});
}

constraint sinc_fault_err_packet::gpaes_mode_ghash_fsm_c {
  if(m_sys_cfg.m_sinc_fault_error_type_gpaes_sub_state_fsm_illegal == 1){ // sinc state
    m_force_on_gpaes_mode_ghash_fsm_state inside { MODE_GHASH_ENC, MODE_GHASH_DEC};
  } else {
    m_force_on_gpaes_mode_ghash_fsm_state inside {MODE_GHASH_IDLE, MODE_GHASH_AAD, MODE_GHASH_ENC, MODE_GHASH_DEC, MODE_GHASH_LAST};
  }  
  !(m_illegal_gpaes_mode_ghash_fsm_state inside {MODE_GHASH_IDLE, MODE_GHASH_AAD, MODE_GHASH_ENC, MODE_GHASH_DEC, MODE_GHASH_LAST});
}

constraint sinc_fault_err_packet::gpaes_sub_state_fsm_c {
  m_force_on_gpaes_sub_state_fsm_state inside {AES_SUB_STATE_1, AES_SUB_STATE_2, AES_SUB_STATE_3, AES_SUB_STATE_4};
  !(m_illegal_gpaes_sub_state_fsm_state inside {AES_SUB_STATE_1, AES_SUB_STATE_2, AES_SUB_STATE_3, AES_SUB_STATE_4});
}

constraint sinc_fault_err_packet::gpaes_mode_sec_fsm_c {
  m_force_on_gpaes_mode_sec_fsm_state inside {MODE_SEC_IDLE, MODE_SEC_KEY0, MODE_SEC_DATA0, MODE_SEC_KEY1, MODE_SEC_DATA1};
  !(m_illegal_gpaes_mode_sec_fsm_state inside {MODE_SEC_IDLE, MODE_SEC_KEY0, MODE_SEC_DATA0, MODE_SEC_KEY1, MODE_SEC_DATA1});
}

constraint sinc_fault_err_packet::aes_keyexp_fsm_c {
  m_force_on_aes_keyexp_fsm_state inside {S_IDLE, S_LOAD0, S_LOAD1, S_ADJUST, S_ACTIVE, S_LASTKEY, S_RELOAD0, S_RELOAD1, S_WRITE, S_WAIT};
  !(m_illegal_aes_keyexp_fsm_state inside {S_IDLE, S_LOAD0, S_LOAD1, S_ADJUST, S_ACTIVE, S_LASTKEY, S_RELOAD0, S_RELOAD1, S_WRITE, S_WAIT});
}

`endif // SINC_FAULT_ERR_PACKET
