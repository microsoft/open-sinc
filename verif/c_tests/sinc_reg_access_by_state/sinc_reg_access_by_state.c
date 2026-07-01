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
// File          : sinc_reg_access_by_state.c
// Description   : C test that exercises SInC register accesses across each operational state

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/int/int_driver.h>

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t gen_different_wdata(uint32_t orig_data, uint32_t mask)
{
  uint32_t data;

  //if mask is 0 we have to return 0, can't generate new data
  if(mask == 0)
  {
    return 0;
  }

  do{
    data = (rand() & mask);
  } while(data == orig_data);
  return data;
}

uint32_t check_reg(volatile uint32_t * addr, uint32_t wmask, uint32_t wallowed, SINC_STATE_t state)
{
  uint32_t rdata1, rdata2;
  uint32_t wdata;

  rdata1 = hw_read32(addr);
  wdata = gen_different_wdata(rdata1,wmask);
  hw_write32(addr,wdata);
  rdata2 = hw_read32(addr);

  if(wallowed)
  {
    if(rdata2 != wdata)
    {
      hw_errmsg("Read back data 0x%08x for register address 0x%08x did not match written data 0x%08x in state 0x%02x\n",rdata2,addr,wdata,state);
      return 1;
    }
    else
    {
      hw_status("Read back data 0x%08x for register address 0x%08x matched written data in state 0x%02x\n",rdata2,addr,state);
    }
  }
  else
  {
    if(rdata2 != rdata1)
    {
      hw_errmsg("Read back data 0x%08x for register address 0x%08x did not match previously read data 0x%08x before write of 0x%08x in state 0x%02x\n",rdata2,addr,rdata1,wdata,state);
      return 1;
    }
    else
    {
      hw_status("Read back data 0x%08x for register address 0x%08x matched previously read data before write in state 0x%02x\n",rdata2,addr,state);
    }
  }
  return 0;
}

//read all registers rdata;
uint32_t write_read_all_regs(SINC_STATE_t state)
{
    
  uint32_t errors = 0;
  uint32_t wallowed;
  Sinc_regs *sinc_regs_ptr = (Sinc_regs *)SSY_HSP_SINC_BASE_ADDR;

  //block encr num
  wallowed = ((state == SINC_STATE_DISABLED) || (state == SINC_STATE_INITIALIZED)) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->block_encr_num,SINC_REGS_BLOCK_ENCR_NUM_WRITE_MASK,wallowed,state);

  //num_of_blocks
  wallowed = ((state == SINC_STATE_DISABLED) || (state == SINC_STATE_INITIALIZED)) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->num_of_blocks,SINC_REGS_NUM_OF_BLOCKS_WRITE_MASK,wallowed,state);
  
  //block_encr_addr
  wallowed = ((state == SINC_STATE_DISABLED) || (state == SINC_STATE_INITIALIZED)) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->block_encr_addr,SINC_REGS_BLOCK_ENCR_ADDR_WRITE_MASK,wallowed,state);

  //block_encr_key
  wallowed = (state == SINC_STATE_DISABLED) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->block_encr_key,SINC_REGS_BLOCK_ENCR_KEY_WRITE_MASK,wallowed,state);

  //aes_iv_nonce_0
  wallowed = (state == SINC_STATE_DISABLED) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->aes_iv_nonce_0,SINC_REGS_AES_IV_NONCE_0_WRITE_MASK,wallowed,state);

  //aes_iv_nonce_1
  wallowed = (state == SINC_STATE_DISABLED) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->aes_iv_nonce_1,SINC_REGS_AES_IV_NONCE_1_WRITE_MASK,wallowed,state);

  //aes_iv_nonce_2
  wallowed = (state == SINC_STATE_DISABLED) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->aes_iv_nonce_2,SINC_REGS_AES_IV_NONCE_2_WRITE_MASK,wallowed,state);

  //ext_block_base_addr
  wallowed = ((state == SINC_STATE_DISABLED) || (state == SINC_STATE_INITIALIZED)) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->ext_block_base_addr,SINC_REGS_EXT_BLOCK_BASE_ADDR_WRITE_MASK,wallowed,state);

  //ext_auth_tag_base_addr
  wallowed = ((state == SINC_STATE_DISABLED) || (state == SINC_STATE_INITIALIZED)) ? 1 : 0;
  errors+=check_reg(&sinc_regs_ptr->ext_auth_tag_base_addr,SINC_REGS_EXT_AUTH_TAG_BASE_ADDR_WRITE_MASK,wallowed,state);

  return errors;
}

//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  SINC_DRIVER sinc_dvr;
  uint32_t errors = 0;
  uint32_t * ccs_cmd_buf;
  uint32_t key_attr;
  DMB_DRIVER dmb4hsp;
  ALLOC_MEM * mem;
  uint64_t dmb_addr;
  INT_DRIVER *intr = intr->get_instance();
  dmb_addr = SYS_SRAM4_BASE_ADDR;
  

  uint32_t* block_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);
  uint32_t* tag_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr + 0x1000000,0x0,0xA,0x0);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //allocate buffer for command struct
  mem = new ALLOC_MEM((uint32_t *)SSY_HSP_SHAREDRAM_BASE_ADDR, 8);
  mem->alloc_init();
  ccs_cmd_buf = (uint32_t*)mem->alloc(24); 
  if(ccs_cmd_buf == NULL)
  {
      hw_errmsg(" Request CCS CMD Pointer Buffer Memory size not available in Memory selected.  \n");
      hw_done(HW_TEST_FAIL);
      return;
  }
  
  //construct ccs driver
  CCS_DRIVER ccs_cmd = CCS_DRIVER(ccs_cmd_buf,NULL,NULL,NULL);

  //setup key in KSU for SINC to use
  key_attr = rand();
  key_attr |= (KSU_ATTR_IS_DEVICE_SECRET | KSU_ATTR_AES_ENCRYPT_ALLOWED | KSU_ATTR_AES_DECRYPT_ALLOWED);
  key_attr &= (~KSU_ATTR_KEY_SIZE_384);

  errors+=ccs_cmd.gen_random_key_fixed_attr(0,key_attr);

  //check that we can read and all registers as a sanity check
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  write_read_all_regs(SINC_STATE_DISABLED);

  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_ext_block_base_addr((uint32_t)block_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr((uint32_t)tag_addr_ptr);
  
  errors+=sinc_dvr.transition_to_initialized();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_INITIALIZED);
  write_read_all_regs(SINC_STATE_INITIALIZED);

  errors+=sinc_dvr.transition_to_cache_active();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_ACTIVE);
  write_read_all_regs(SINC_STATE_CACHE_ACTIVE);

  intr->disable_interrupt(IRQ, HSP_DMB_IRQ);
  intr->disable_interrupt(IRQ, HSP_AXI_WDT_IRQ);

  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x0);
  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  write_read_all_regs(SINC_STATE_CACHE_FAILED);

  if(errors) {
    hw_done(HW_TEST_FAIL);
  } else {
    hw_done(HW_TEST_PASS);
  }

}

//--------------------------------------------------------------------------------
// {{{ CLEANUP_TEST
//--------------------------------------------------------------------------------
VOID CLEANUP_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}
