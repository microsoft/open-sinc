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
// File          : sinc_reinit_after_gate.c
// Description   : C test that re-initializes SInC after a clock-gating event

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"
#include <drivers/int/int_driver.h>
#include <drivers/pcu/pcu_driver.h>
#include "ext_int_regs.h"

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  hw_status(" Inside function: %s.\n", __func__);

  if( (params->CLKGATE) || (params->PWRGATE))
  {
    PCU_DRIVER pcu_driver(PCU_HSP_OFFSET, true);
    pcu_driver.enable_interrupts();
    if(params->CLKGATE)
    {
      enable_external_interrupts();
    }
  }
}

uint32_t repeat_val(uint32_t input,uint32_t index,uint32_t * arr)
{
  for(uint32_t i=0;i<index;i++)
  {
    if(arr[i] == input)
    {
      return 1;
    }
  }
  return 0;
}

//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, block_num, key_slot;
  //uint32_t ciram_start_addr, ciram_end_addr;//, iram_start_addr, iram_end_addr, dram_start_addr, dram_end_addr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value[10];
  uint32_t block_table[10];
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  uint32_t nonce[3];
  PCU_DRIVER pcu_driver(PCU_HSP_OFFSET,true);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //ciram_start_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  //ciram_end_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);
  

  dmb_addr = SYS_SRAM4_BASE_ADDR;
  

  uint32_t* sram_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);

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
  CCS_DRIVER ccs_dvr = CCS_DRIVER(ccs_cmd_buf,NULL,NULL,NULL);

  //setup key in KSU for SINC to use
  key_attr = rand();
  key_attr |= (KSU_ATTR_IS_DEVICE_SECRET | KSU_ATTR_AES_ENCRYPT_ALLOWED | KSU_ATTR_AES_DECRYPT_ALLOWED);
  key_attr &= (~KSU_ATTR_KEY_SIZE_384);

  key_slot = rand() % SSY_HSP_KSU_NUM_KEYS;

  errors+=ccs_dvr.gen_random_key_fixed_attr(key_slot,key_attr);

  //generate list of 10 random unique blocks and 10 random iniital_values
  for(uint32_t i=0;i<10;i++)
  {
    do{
      block_num = rand() % 32768;
    } while(repeat_val(block_num,i,block_table));
    block_table[i] = block_num;
    initial_value[i] = rand();
  }

  //setup registers
  random_fill(nonce,3);
  sinc_dvr.write_num_of_blocks(1);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(key_slot);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  errors+=sinc_dvr.transition_to_initialized();

  //encrypt first 5
  for(uint32_t i=0;i<5;i++)
  {
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[i]);
    sinc_dvr.write_block_encr_num(block_table[i]);
    errors+=sinc_dvr.call_encrypt_block();
  }

  errors+=sinc_dvr.transition_to_cache_active();

  hw_status("done transition_to_cache_active\n");
  flush_uart();

  //check data
  for(uint32_t i=0;i<5;i++)
  {
    block_num = block_table[i];
    hw_status("Calling wordcmp on %d words starting from address 0x%08x\n",1024*2,SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*block_num);
    flush_uart();
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[i]);
    if(wordcmp((uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,(uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*block_num),128))
    {
      hw_errmsg("wordcmp saw mismatch\n");
      errors++;
    }
    hw_status("finished\n");
    flush_uart();
  }

  //reinit
  errors+=sinc_dvr.call_sinc_reinit();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_INITIALIZED);

  //clock or power gate
  if(params->CLKGATE)
  {              
      hw_status("checking clockgaten");
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE) 
  {
      hw_status("checking powergate\n");
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH);
      sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
      sinc_dvr.write_num_of_blocks(1);
  }

  //encrypt second 5
  for(uint32_t i=5;i<10;i++)
  {
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[i]);
    sinc_dvr.write_block_encr_num(block_table[i]);
    errors+=sinc_dvr.call_encrypt_block();
  }

  //transition back to cache active
  errors+=sinc_dvr.transition_to_cache_active();
  hw_status("done transition_to_cache_active\n");
  flush_uart();

  //check all data
  for(uint32_t i=0;i<10;i++)
  {
    block_num = block_table[i];
    hw_status("Calling wordcmp on %d words starting from address 0x%08x\n",1024*2,SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*block_num);
    flush_uart();
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[i]);
    if(wordcmp((uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,(uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*block_num),128))
    {
      hw_errmsg("wordcmp saw mismatch\n");
      errors++;
    }
    hw_status("finished\n");
    flush_uart();
  }

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
