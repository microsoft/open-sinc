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
// File          : sinc_restore_after_reset.c
// Description   : C test that restores SInC state after a reset and verifies functional recovery

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);

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
  uint32_t block_num, aes_key_slot, kek_key_slot, key_attr;
  uint32_t * initial_value;
  //TestParams* params = (TestParams*) hw_getTestParamsPtr();
  uint32_t * nonce;
  uint32_t * block_table;
  uint32_t * key_blob;
  uint32_t hsp_reset_count;
  ALLOC_MEM * mem;
  uint32_t * ccs_dvr_buf;
  uint32_t * input_buf;
  uint32_t * output_buf;

  hsp_reset_count = hsp_reset_count_rpc();

  hw_status("hsp_reset_count is %d\n", hsp_reset_count);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  dmb_addr = SYS_SRAM4_BASE_ADDR;
  uint32_t* sram_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);

  dmb_addr = SYS_SRAM2_BASE_ADDR;
  uint32_t* sram2_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);

  //allocate buffer for command struct
  mem = new ALLOC_MEM((uint32_t *)SSY_HSP_SHAREDRAM_BASE_ADDR, 8);
  mem->alloc_init();
  ccs_dvr_buf = (uint32_t*)mem->alloc(24); 
  if(ccs_dvr_buf == NULL)
  {
      hw_errmsg(" Request CCS CMD Pointer Buffer Memory size not available in Memory selected.  \n");
      hw_done(HW_TEST_FAIL);
      return;
  }
  
  //allocate buffer for data input for command
  input_buf = (uint32_t*)mem->alloc(48);
  if(input_buf == NULL)
  {
      hw_errmsg(" Request Input Buffer Memory size not available in Memory selected.  \n");
      hw_done(HW_TEST_FAIL);
      return;
  }
  
  //allocate buffer for data output for command
  output_buf = (uint32_t*)mem->alloc(48);
  if(output_buf == NULL)
  {
      hw_errmsg(" Request Output Buffer Memory size not available in Memory selected.  \n");
      hw_done(HW_TEST_FAIL);
      return;
  }

  //construct ccs driver
  CCS_DRIVER ccs_dvr = CCS_DRIVER(ccs_dvr_buf,input_buf,output_buf,NULL);

  //setup key in KSU for SINC to use
  key_attr = rand();
  key_attr |= (KSU_ATTR_IS_DEVICE_SECRET | KSU_ATTR_AES_ENCRYPT_ALLOWED | KSU_ATTR_AES_DECRYPT_ALLOWED) | KSU_ATTR_SAVE_KEY_ALLOWED;
  key_attr &= ~(KSU_ATTR_KEY_SIZE_384|KSU_ATTR_IS_EPHEMERAL_KEY);

  //get random ketslot not equal to 0
  aes_key_slot = (rand() % (SSY_HSP_KSU_NUM_KEYS-1))+1;
  kek_key_slot = 0;

  errors+=ccs_dvr.gen_random_key_fixed_attr(aes_key_slot,key_attr);

  //assign pointers to data needed between tests in external memory
  //if first reset then generate data, otherwise it now points to correct data
  nonce = sram2_addr_ptr;
  block_table = nonce+3;
  initial_value = block_table+10;
  key_blob = initial_value+10;
  ccs_dvr.set_data_out((uint32_t)key_blob);
  if(hsp_reset_count == 0) 
  {
    random_fill(nonce,3);
    //generate list of 10 random unique blocks and 10 tandom iniital_values
    for(uint32_t i=0;i<10;i++)
    {
      do{
        block_num = rand() % 32768;
      } while(repeat_val(block_num,i,block_table));
      block_table[i] = block_num;
      initial_value[i] = rand();
    }
    //generate keyblob for key
    errors+=ccs_dvr.do_fixed_command(CMD_CCS_SAVE_KEY, 0, aes_key_slot, kek_key_slot, NULL, 0);
  }

  //load key
  if(hsp_reset_count == 1) 
  {
    errors+=ccs_dvr.do_fixed_command(CMD_CCS_LOAD_KEY, aes_key_slot, 0, kek_key_slot, key_blob, 0);
  }
 
  sinc_dvr.write_num_of_blocks(1);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(aes_key_slot);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  errors+=sinc_dvr.transition_to_initialized();

  //encrypt blocks if first reset
  if(hsp_reset_count == 0) 
  {
    for(uint32_t i=0;i<10;i++)
    {
      //hw_status("Block num is %d initial value is 0x%08x\n",block_num,initial_value[i]);
      sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[i]);
      sinc_dvr.write_block_encr_num(block_table[i]);
      errors+=sinc_dvr.call_encrypt_block();
    }
  }

  errors+=sinc_dvr.transition_to_cache_active();

  //check data
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

  if(errors) 
  {
    hw_done(HW_TEST_FAIL);
    return;
  }

  if(hsp_reset_count == 0) 
  {
    hsp_reset_rpc();
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
