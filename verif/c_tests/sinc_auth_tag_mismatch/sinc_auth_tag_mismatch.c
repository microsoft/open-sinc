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
// File          : sinc_auth_tag_mismatch.c
// Description   : C test that injects an authentication tag mismatch and verifies SInC error reporting

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"

uint32_t block_table[10];

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
  //Handle to fetch parameters from params.h
  //TestParams* params = (TestParams*) hw_getTestParamsPtr();
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, block, cache_tag, block_sel, auth_tag_word, auth_tag_bit, word_num, set;
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  AEB_DRIVER adriver;
  

  //uint32_t ciram_start_addr, ciram_end_addr;//, iram_start_addr, iram_end_addr, dram_start_addr, dram_end_addr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value, offset_addr, full_addr, rdata, wdata, exp_rdata;
  uint32_t nonce[3];

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //ciram_start_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  //ciram_end_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);
  

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

  sinc_dvr.write_block_encr_num(0);
  sinc_dvr.write_num_of_blocks(16);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  random_fill(nonce,3);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)block_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr((uint32_t)tag_addr_ptr);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  if(params->disable_encryption == 1)
  {
    adriver.enable(AEB_SINC_AUTHEN_DISABLE);
  }

  for(uint32_t corrupt_tag_iteration=0;corrupt_tag_iteration<3;corrupt_tag_iteration++)
  {

    errors+=sinc_dvr.transition_to_initialized();

    //pick 10 random blocks in a random set
    //set is bits 15:9 in address
    //tag is bits 23:16 in address

    set = rand() & 0x7f;

    for(uint32_t i=0;i<10;i++)
    {
      do{
        cache_tag = rand() & 0xff;
        block = (cache_tag << 7) | set;
      } while(repeat_val(block,i,block_table));
      block_table[i] = block;
    }
    
    //encrypt reproducible data into each block
    initial_value = rand();
    for(uint32_t i=0;i<10;i++)
    {
      offset_addr = block_table[i]*512;
      sinc_dvr.write_block_encr_num(block_table[i]);
      sinc_dvr.write_num_of_blocks(1);
      for(uint32_t i=0;i<128;i++)
      {
        hw_write32((uint32_t*)(SSY_HSP_SHAREDRAM_BASE_ADDR+i*4),offset_addr + i*4 + initial_value);
      }
      errors+=sinc_dvr.call_encrypt_block();
    }

    errors+=sinc_dvr.transition_to_cache_active();

    //select random bit in auth tag for random block to corrupt and random word within block to read
    block_sel = rand() % 10;
    block = block_table[block_sel];
    auth_tag_word = rand() % 4;
    auth_tag_bit = rand() % 32;
    word_num = rand() % 128;

    //access word before we corrupt it and check no errors
    offset_addr = block*512 + word_num*4;
    full_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr;
    hw_status("reading address 0x%08x\n",full_addr);
    rdata = hw_read32((uint32_t*)full_addr);
    exp_rdata = offset_addr + initial_value;
    if(rdata != exp_rdata)
    {
      hw_errmsg("compare saw mismatch read 0x%08x expected 0x%08x at addr 0x%08x\n",rdata,exp_rdata,full_addr);
      errors++;
      hw_done(HW_TEST_FAIL);
      return;
    }

    errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_ACTIVE);

    //corrupt bit in auth tag
    rdata = hw_read32(tag_addr_ptr + block*4 + auth_tag_word);
    hw_status("read auth tag for block %d tag word %d at address 0x%08x, read back 0x%08x\n",block,auth_tag_word,tag_addr_ptr + block*4 + auth_tag_word,rdata);
    wdata = rdata ^ (1<<auth_tag_bit);
    hw_write32(tag_addr_ptr + block*4 + auth_tag_word,wdata);
    hw_status("wrote auth tag for block %d tag word %d at address 0x%08x, write data 0x%08x\n",block,auth_tag_word,tag_addr_ptr + block*4 + auth_tag_word,wdata);

    //read back and expect no issue since block is still in cache
    hw_status("reading address 0x%08x\n",full_addr);
    rdata = hw_read32((uint32_t*)full_addr);
    exp_rdata = offset_addr + initial_value;

    if(rdata != exp_rdata)
    {
      hw_errmsg("compare saw mismatch read 0x%08x expected 0x%08x at addr 0x%08x\n",rdata,exp_rdata,full_addr);
      errors++;
      hw_done(HW_TEST_FAIL);
      return;
    }

    errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_ACTIVE);

    //evict block from cache by reading 4 other blocks in same set
    for(uint32_t i=0;i<4;i++)
    {
      offset_addr = block_table[(block_sel+i+1)%10]*512 + (rand() % 128)*4;
      full_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr;
      hw_status("reading address 0x%08x\n",full_addr);
      hw_read32((uint32_t*)full_addr);
    }

    //fetch block with corrupted tag agaian and expect to go to failed state
    offset_addr = block*512 + word_num*4;
    full_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr;

    hw_status("reading address 0x%08x\n",full_addr);
    rdata = hw_read32((uint32_t*)full_addr);
    exp_rdata = offset_addr + initial_value;

    if(params->disable_encryption == 0)
    {
      if(rdata == exp_rdata)
      {
        hw_errmsg("compare saw match read 0x%08x at addr 0x%08x after tag corruption so expected mismatch\n",rdata,full_addr);
        errors++;
        hw_done(HW_TEST_FAIL);
        return;
      }

      errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_FAILED);
    }
    else
    {
      if(rdata != exp_rdata)
      {
        hw_errmsg("compare saw mismatch read 0x%08x at addr 0x%08x after tag corruption but dis auth check aeb is set\n",rdata,full_addr);
        errors++;
        hw_done(HW_TEST_FAIL);
        return;
      }

      errors+=sinc_dvr.check_sinc_state(SINC_STATE_CACHE_ACTIVE);
    }

    errors+=sinc_dvr.call_sinc_reset();
    random_fill(nonce,3);
    sinc_dvr.write_all_aes_iv_nonce(nonce);
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
