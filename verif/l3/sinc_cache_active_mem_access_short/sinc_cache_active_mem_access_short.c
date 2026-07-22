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
// File          : sinc_cache_active_mem_access_short.c
// Description   : Short variant of the cache-active memory access test for quick smoke runs

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t function1(uint32_t x){
   return x-5;
}

uint32_t function2(uint32_t x){
  return x+5;
}

//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  //Handle to fetch parameters from params.h
  //TestParams* params = (TestParams*) hw_getTestParamsPtr();
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, next_block_num, cur_block_num;
  //uint32_t ciram_start_addr, ciram_end_addr;//, iram_start_addr, iram_end_addr, dram_start_addr, dram_end_addr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value[1000];

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
  CCS_DRIVER ccs_cmd = CCS_DRIVER(ccs_cmd_buf,NULL,NULL,NULL);

  //setup key in KSU for SINC to use
  key_attr = rand();
  key_attr |= (KSU_ATTR_IS_DEVICE_SECRET | KSU_ATTR_AES_ENCRYPT_ALLOWED | KSU_ATTR_AES_DECRYPT_ALLOWED);
  key_attr &= (~KSU_ATTR_KEY_SIZE_384);

  errors+=ccs_cmd.gen_random_key_fixed_attr(0,key_attr);

  next_block_num = (256/8)*16;
  sinc_dvr.write_block_encr_num(next_block_num);
  sinc_dvr.write_num_of_blocks(16);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_aes_iv_nonce_0(0);
  sinc_dvr.write_aes_iv_nonce_1(0);
  sinc_dvr.write_aes_iv_nonce_2(0);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  errors+=sinc_dvr.transition_to_initialized();

  for(uint32_t i=0;i<1;i++)
  {
    initial_value[i] = rand();
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,1024*2,initial_value[i]);
    errors+=sinc_dvr.call_encrypt_block();
    next_block_num += 16;
    sinc_dvr.write_block_encr_num(next_block_num);
  }

  errors+=sinc_dvr.transition_to_cache_active();

  //check data
  cur_block_num = (256/8)*16;
  for(uint32_t i=0;i<1;i++)
  {
    hw_status("Calling wordcmp on %d words starting from address 0x%08x\n",1024*2,SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num);
    flush_uart();
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,1024*2,initial_value[i]);
    if(wordcmp((uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,(uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num),1024*2))
    {
      hw_errmsg("wordcmp saw mismatch");
      errors++;
    }
    cur_block_num += 16;
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
