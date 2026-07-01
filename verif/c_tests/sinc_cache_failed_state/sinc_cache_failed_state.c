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
// File          : sinc_cache_failed_state.c
// Description   : C test that drives the SInC cache into the failed state and checks recovery/reporting

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

uint32_t check_write_read_in_cache_failed(INT_DRIVER *intr) {
  uint32_t wdata, rdata, addr, sp_bus_err_cnt, mpu_intr_cnt, errors=0;
  
  //check read in cache failed state
  do {
    wdata = rand();
  } while(wdata == 0);
  
  hw_status("testing write to ciram in cache failed\n");
  hw_write32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS, wdata);
  
  hw_status("testing read to ciram in cache failed\n");
  rdata = hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);

  //check the data wasn't written
  if(wdata == rdata)
  {
    hw_errmsg("rdata 0x%08x matched wdata 0x%08x but expected write and read to be blocked\n",rdata,wdata);
    errors++;
  }

  //check interrupt counts, need to delay a bit so read doesn't beat interrupt
  for(uint32_t i=0;i<100;i++);
  sp_bus_err_cnt = intr->int_info[HSP_SP_BUS_ERR_IRQ].int_trig_count;
  mpu_intr_cnt = intr->int_info[HSP_MPU_IRQ].int_trig_count;

  if(sp_bus_err_cnt != 0)
  {
    hw_errmsg("sp bus err cnt is %d expected %d\n",sp_bus_err_cnt,0);
    errors++;
  }

  if(mpu_intr_cnt != 2)
  {
    hw_errmsg("mpu intr coun is %d expected %d\n",mpu_intr_cnt,2);
    errors++;
  }

  addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);
  hw_status("testing write to end of ciram in cache failed\n");
  hw_write32((uint32_t*)addr, wdata);
  
  hw_status("testing read to end of ciram in cache failed\n");
  rdata = hw_read32((uint32_t*)addr);

  //check the data wasn't written
  if(wdata == rdata)
  {
    hw_errmsg("rdata 0x%08x matched wdata 0x%08x but expected write and read to be blocked\n",rdata,wdata);
    errors++;
  }

  //check interrupt counts, need to delay a bit so read doesn't beat interrupt
  for(uint32_t i=0;i<100;i++);
  sp_bus_err_cnt = intr->int_info[HSP_SP_BUS_ERR_IRQ].int_trig_count;
  mpu_intr_cnt = intr->int_info[HSP_MPU_IRQ].int_trig_count;

  if(sp_bus_err_cnt != 2)
  {
    hw_errmsg("sp bus err cnt is %d expected %d\n",sp_bus_err_cnt,2);
    errors++;
  }

  if(mpu_intr_cnt != 2)
  {
    hw_errmsg("mpu intr coun is %d expected %d\n",mpu_intr_cnt,2);
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
  MISC_DRIVER misc;
  INT_DRIVER *intr = intr->get_instance();
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, initial_value;
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
  
  //1. HW fault in SInC
  //need to force fsm to bad state, tbd on how
  misc.set_scratch0(1);
  hw_sleep(10);
  errors+=sinc_dvr.check_status_for_err_bits(sinc_dvr.read_status(),SINC_STATUS_SINC_HW_FAULT);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  misc.set_scratch0(0);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  errors+=check_write_read_in_cache_failed(intr);
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  
  
  //2. Key fetch error covered in ksu access test
  
  //3. Cache block read error during encrypt block or fetch block
  //for during encrypt block can point write_block_encr_addr to after the end of shared ram
  errors+=sinc_dvr.transition_to_initialized();
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_MAX_ADDR);
  sinc_dvr.write_num_of_blocks(1);
  errors+=sinc_dvr.call_encrypt_block(SINC_STATUS_CACHE_BLOCK_R_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);

  //for during fetch block need to do a cache miss after blocking dmb access to 
  errors+=sinc_dvr.transition_to_initialized();
  errors+=sinc_dvr.transition_to_cache_active();
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x0);
  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);
  errors+=sinc_dvr.check_cmd_result_status_failure(sinc_dvr.wait_for_no_cmd_in_progress(),SINC_STATUS_CACHE_BLOCK_R_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x1);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);


  //4. Authentication tag check error
  // overwrite tag data with bad tag
  errors+=sinc_dvr.transition_to_initialized();
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,0);
  sinc_dvr.write_num_of_blocks(1);
  errors+=sinc_dvr.call_encrypt_block();
  //corrupt random bit in tag
  hw_write32(tag_addr_ptr,hw_read32(tag_addr_ptr) ^ (1 << (rand() % 32)));
  errors+=sinc_dvr.transition_to_cache_active();
  //read ciram to trigger cache miss
  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);
  errors+=sinc_dvr.check_cmd_result_status_failure(sinc_dvr.wait_for_no_cmd_in_progress(),SINC_STATUS_AUTH_TAG_CHK_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  
  //5. Authentication tag read error
  //use separate dmb segment for tag storange and block access then do a cache miss
  errors+=sinc_dvr.transition_to_initialized();
  errors+=sinc_dvr.transition_to_cache_active();
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x0);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x1);
  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);
  errors+=sinc_dvr.check_cmd_result_status_failure(sinc_dvr.wait_for_no_cmd_in_progress(),SINC_STATUS_AUTH_TAG_R_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  dmb4hsp.set_crypto_perm_data(tag_addr_ptr,0x1);
  dmb4hsp.set_crypto_perm_data(block_addr_ptr,0x1);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);

  //7. Cache block write error during fetch block
  //do a cache miss then immediately trigger ciram erase, or other way around
  //not possible at L3 since read to do a cache miss would need to complete before code moves on to ciram erase
 
  
  //8. AES error
  errors+=sinc_dvr.transition_to_initialized();

  //check sinc works after cache failed
  sinc_dvr.write_num_of_blocks(1);
  misc.set_scratch0(2);
  errors+=sinc_dvr.call_encrypt_block(SINC_STATUS_AES_ERR);
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
  errors+=sinc_dvr.check_all_aes_iv_nonce_cleared();
  misc.set_scratch0(0);
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);

  //check that sinc still works again after final reset
  errors+=sinc_dvr.transition_to_initialized();

  //check sinc works after cache failed
  initial_value = rand();
  sinc_dvr.write_num_of_blocks(1);
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value);
  errors+=sinc_dvr.call_encrypt_block();
  errors+=sinc_dvr.transition_to_cache_active();
  errors+=sinc_dvr.check_known_data(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS,128,initial_value);
  

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
