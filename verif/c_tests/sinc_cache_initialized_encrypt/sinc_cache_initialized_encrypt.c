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
// File          : sinc_cache_initialized_encrypt.c
// Description   : C test that exercises encryption with the SInC cache in the initialized state

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"
#include "drivers/aes/aes_wrap_driver.h"
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
    bool verbose = true;
    PCU_DRIVER pcu_driver(PCU_HSP_OFFSET, verbose);
    pcu_driver.enable_interrupts();
    if(params->CLKGATE)
    {
      enable_external_interrupts();
    }
  }
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
  unsigned int errors = 0;
  uint32_t key_attr, key_slot;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  SINC_FUNC_PTR copied_function;
  uint32_t initial_value;
  uint32_t num_blocks;
  uint32_t block_encr_num;
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  AEB_DRIVER adriver;
  uint32_t nonce[3];
  bool verbose = true;
  PCU_DRIVER pcu_driver(PCU_HSP_OFFSET,verbose);
  
#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();


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

  if(params->disable_encryption == 1)
  {
    adriver.enable(AEB_SINC_AUTHEN_DISABLE);
  }

  random_fill(nonce,3);
  num_blocks = 2;
  block_encr_num = rand()%(32768-num_blocks);
  sinc_dvr.write_block_encr_num(block_encr_num);
  sinc_dvr.write_num_of_blocks(num_blocks);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(key_slot);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  errors+=sinc_dvr.transition_to_initialized();

  //copy some data into shared ram to encrypt
  initial_value = rand();
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value);

  //copy function to sharedram for encryption
  sinc_dvr.copy_func(SSY_HSP_SHAREDRAM_BASE_ADDR+512,function1,function2);

  if(params->CLKGATE == 1)
  {              
      hw_status("checking clockgate %d\n",params->CLKGATE);
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE == 1) 
  {
      hw_status("checking powergate %d\n",params->PWRGATE);
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH);
      sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
      sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
      sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
      sinc_dvr.write_block_encr_num(block_encr_num);
      sinc_dvr.write_num_of_blocks(num_blocks);
  }

  //do encrypt block
  errors+=sinc_dvr.call_encrypt_block();

  if(params->CLKGATE == 2)
  {              
      hw_status("checking clockgate %d\n",params->CLKGATE);
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE == 2) 
  {
      hw_status("checking powergate %d\n",params->PWRGATE);
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH); 
  }


  errors+=sinc_dvr.transition_to_cache_active();


  //check data
  errors+=sinc_dvr.check_known_data(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*block_encr_num,128,initial_value);

  errors+=sinc_dvr.check_ciphertext(&ccs_dvr,NULL,block_encr_num,1,initial_value,params->disable_encryption);
  
  if(errors) {
    hw_done(HW_TEST_FAIL);
    return;
  }


  copied_function=(SINC_FUNC_PTR)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*(block_encr_num+1));
  errors+=sinc_dvr.compare_func(copied_function,function1);

  errors+=sinc_dvr.check_ciphertext(&ccs_dvr,(uint32_t*)(SSY_HSP_SHAREDRAM_BASE_ADDR+512),block_encr_num+1,0,0,params->disable_encryption);

  //check that we can still do some commands after fetching blocks
  errors+=sinc_dvr.call_sinc_reset();
  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);
  //restore needed registers for initialized state if we did power gating
  if(params->PWRGATE != 0)
  {
    sinc_dvr.write_block_encr_key(key_slot);
  }
  //pwrgate 1 case already restored these so only need to do for pwrgate 2 case
  if(params->PWRGATE == 2)
  {
    sinc_dvr.write_block_encr_num(block_encr_num);
    sinc_dvr.write_num_of_blocks(num_blocks);
    sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  }
  errors+=sinc_dvr.transition_to_initialized();
  errors+=sinc_dvr.call_encrypt_block();

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
