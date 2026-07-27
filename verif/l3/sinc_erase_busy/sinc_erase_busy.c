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
// File          : sinc_erase_busy.c
// Description   : C test that exercises the SInC erase-busy behavior and status reporting

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


//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
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
  uint32_t key_attr, erase_intsts, done_sts;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t nonce[3];
  Creg_regs_mem_err *mem_err_ptr;
  mem_err_ptr = (Creg_regs_mem_err *)SSY_HSP_CREG_MEM_ADDR;

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
  
  
  hw_status("Testing case where we erase then fetch block\n");
  errors+=sinc_dvr.transition_to_initialized();
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,0);
  sinc_dvr.write_num_of_blocks(1);
  errors+=sinc_dvr.call_encrypt_block();
  errors+=sinc_dvr.transition_to_cache_active();

  //Start erase then read ext memory
  done_sts = mem_err_ptr->MEM_ERASE_DONE_STS;
  mem_err_ptr->MEM_ERASE_DONE_STS = done_sts;

  mem_err_ptr->MEM_ERASE_EN = (1<<MEM_SPCIRAM);

  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);

  do {
    done_sts = (mem_err_ptr->MEM_ERASE_DONE_STS & (1<<MEM_SPCIRAM));
  } while(done_sts == 0);

  erase_intsts = mem_err_ptr->MEM_ERASE_ERR_INTSTS;
  if((erase_intsts & (1<<MEM_SPCIRAM)) == 0)
  {
    hw_errmsg("Expected bit 0x%08x set in mem_erase_err_intsts but saw 0x%08x\n",(1<<MEM_SPCIRAM),erase_intsts);
    errors++;
  }
  else
  {
    hw_status("Saw expected ciram erase busy bit 0x%08x in mem_erase_err_intsts value 0x%08x\n",(1<<MEM_SPCIRAM),erase_intsts);
  }
  mem_err_ptr->MEM_ERASE_ERR_INTSTS = erase_intsts;

  hw_status("Sinc status is 0x%0x\n",sinc_dvr.read_status());
  sinc_dvr.wait_for_no_cmd_in_progress_no_timeout();

  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);

  hw_status("Testing case where we erase then read ciram\n");
  //Start erase then read ext memory
  done_sts = mem_err_ptr->MEM_ERASE_DONE_STS;
  mem_err_ptr->MEM_ERASE_DONE_STS = done_sts;

  mem_err_ptr->MEM_ERASE_EN = (1<<MEM_SPCIRAM);

  hw_read32((uint32_t*)SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS);

  do {
    done_sts = (mem_err_ptr->MEM_ERASE_DONE_STS & (1<<MEM_SPCIRAM));
  } while(done_sts == 0);
  mem_err_ptr->MEM_ERASE_EN = (1<<MEM_SPCIRAM);

  erase_intsts = mem_err_ptr->MEM_ERASE_ERR_INTSTS;
  if((erase_intsts & (1<<MEM_SPCIRAM)) == 0)
  {
    hw_errmsg("Expected bit 0x%08x set in mem_erase_err_intsts but saw 0x%08x\n",(1<<MEM_SPCIRAM),erase_intsts);
    errors++;
  }
  else
  {
    hw_status("Saw expected ciram erase busy bit 0x%08x in mem_erase_err_intsts value 0x%08x\n",(1<<MEM_SPCIRAM),erase_intsts);
  }
  mem_err_ptr->MEM_ERASE_ERR_INTSTS = erase_intsts;

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
