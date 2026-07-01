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
// File          : sinc_non_severe_err.c
// Description   : C test that injects non-severe errors and verifies SInC continues operating

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/misc/misc_driver.h>
#include <drivers/int/int_driver.h>
#include "drivers/mem_err/mem_err_defines.h"
#include <drivers/crypto/crypto_driver.h>
#include <drivers/mpu/mpu_isr.h>
#include <drivers/sp_bus_err/sp_bus_err_isr.h>


//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t check_sp_bus_and_mpu_err(INT_DRIVER *intr, uint32_t exp_sp_bus_err_cnt, uint32_t exp_mpu_intr_cnt) {
  uint32_t sp_bus_err_cnt, mpu_intr_cnt, errors=0;
  
  //check interrupt counts, need to delay a bit so read doesn't beat interrupt
  for(uint32_t i=0;i<100;i++);
  sp_bus_err_cnt = intr->int_info[HSP_SP_BUS_ERR_IRQ].int_trig_count;
  mpu_intr_cnt = intr->int_info[HSP_MPU_IRQ].int_trig_count;

  if(sp_bus_err_cnt != exp_sp_bus_err_cnt)
  {
    hw_errmsg("sp bus err cnt is %d expected %d\n",sp_bus_err_cnt,exp_sp_bus_err_cnt);
    errors++;
  }

  if(mpu_intr_cnt != exp_mpu_intr_cnt)
  {
    hw_errmsg("mpu intr coun is %d expected %d\n",mpu_intr_cnt,exp_mpu_intr_cnt);
    errors++;
  }
  return errors;
}

//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  INT_DRIVER *intr = intr->get_instance();
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t nonce[3];
  MPU_INT_REGS_t *mpu_int_regs = (MPU_INT_REGS_t *)(SSY_HSP_MPU_ERROR_REGS);
  //CRYPTO_REGS *crypto_regs = (CRYPTO_REGS*) SSY_HSP_CREG_CRYPTO_ADDR;
  intr->enable_interrupt(IRQ, HSP_SP_BUS_ERR_IRQ, (ISR_t)sp_bus_err_interrupt_handler); ///< Enable sp bus error interrupt
  intr->enable_interrupt(IRQ, HSP_MPU_IRQ, (ISR_t)mpu_interrupt_handler);
  intr->enable_interrupt(IRQ, HSP_DBT_IRQ, (ISR_t)mpu_dabort_handler);
  mpu_int_regs->MPU_INTEN = (1<<MPU_SPCIRAM);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //ciram_start_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;

  intr->disable_interrupt(IRQ, HSP_AXI_WDT_IRQ);
  intr->disable_interrupt(IRQ, HSP_DMB_IRQ);

  dmb_addr = SYS_SRAM4_BASE_ADDR;
  

  uint32_t* block_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);
  uint32_t* tag_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr + 0x1000000,0x0,0xA,0x0);

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
  random_fill(nonce,3);

  sinc_dvr.write_block_encr_num(0);
  sinc_dvr.write_num_of_blocks(0);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)block_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr((uint32_t)tag_addr_ptr);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("block_addr_ptr is 0x%08x\n",block_addr_ptr);
  hw_status("tag_addr_ptr is 0x%08x\n",tag_addr_ptr);

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  //test covers all sever errors not covered elsewhere
  
  //Cache block write error during encrypt block command 
  errors+=sinc_dvr.transition_to_initialized();
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x0);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,0);
  sinc_dvr.write_num_of_blocks(1);
  errors+=sinc_dvr.call_encrypt_block(SINC_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_INITIALIZED);
  check_sp_bus_and_mpu_err(intr, 0, 0);

  //do allowed transaction
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x1);
  errors+=sinc_dvr.call_encrypt_block();

  //auth tag write error during encrypt block command 
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x0);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x1);
  errors+=sinc_dvr.call_encrypt_block(SINC_STATUS_AUTH_TAG_W_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_INITIALIZED);
  check_sp_bus_and_mpu_err(intr, 0, 0);

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
