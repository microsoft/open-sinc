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
// File          : sinc_performance_counter_check.c
// Description   : C test that validates SInC performance counter behavior under traffic

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>

uint32_t set_num[10];
uint32_t tag_table[10][4];
uint32_t valid_table[10][4];
uint32_t tag_table_counter[10];
uint32_t block_table[10][10];

uint32_t tag_in_block_table(uint32_t tag, uint32_t set_num_index)
{
  for(uint32_t i=0;i<4;i++)
  {
    if(valid_table[set_num_index][i] == 1)
    {
      if(tag_table[set_num_index][i] == tag)
      {
        return 1;
      }
    }
  }
  return 0;
}

uint32_t check_hit(uint32_t set_num_index, uint32_t block_table_index)
{
  uint32_t tag, counter;

  tag = block_table[set_num_index][block_table_index];

  if(tag_in_block_table(tag,set_num_index))
  {
    return 1;
  }
  else
  {
    counter = tag_table_counter[set_num_index];
    tag_table[set_num_index][counter] = tag;
    valid_table[set_num_index][counter] = 1;
    if(counter==3)
    {
      tag_table_counter[set_num_index] = 0;
    }
    else
    {
      tag_table_counter[set_num_index] = counter + 1;
    }
    return 0;
  }
}



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
  uint32_t key_attr, set, tag, set_num_index, block_table_index, exp_miss, exp_hit, word_num;
  

  //uint32_t ciram_start_addr, ciram_end_addr;//, iram_start_addr, iram_end_addr, dram_start_addr, dram_end_addr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value, offset_addr, rdata, exp_rdata;

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

  sinc_dvr.write_block_encr_num(0);
  sinc_dvr.write_num_of_blocks(16);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_aes_iv_nonce_0(rand());
  sinc_dvr.write_aes_iv_nonce_1(rand());
  sinc_dvr.write_aes_iv_nonce_2(rand());
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  errors+=sinc_dvr.transition_to_initialized();

  //pick 10 random sets and 10 random blocks within each set
  //set is bits 15:9 in address
  //tag is bits 23:16 in address

  for(uint32_t i=0;i<10;i++)
  {
    do{
      set = (rand() >> 9) & 0x7f;
    } while(repeat_val(set,i,set_num));
    set_num[i] = set;
  }

  for(uint32_t j=0;j<10;j++)
  {
    for(uint32_t i=0;i<10;i++)
    {
      
      do{
        tag = (rand() >> 16) & 0xff;
      } while(repeat_val(tag,i,block_table[j]));
      block_table[j][i] = tag;
    }
  }

  for(uint32_t j=0;j<10;j++)
  {
    tag_table_counter[j] = 0;
    for(uint32_t i=0;i<4;i++)
    {
      valid_table[j][i] = 0;
    }
  }
  
  //encrypt reproducible data into each block
  initial_value = rand();
  for(uint32_t j=0;j<10;j++)
  {
    for(uint32_t i=0;i<10;i++)
    {
      offset_addr = ((block_table[j][i] & 0xff)<<16) | ((set_num[j] & 0x7f)<<9);
      sinc_dvr.write_block_encr_num(offset_addr>>9);
      sinc_dvr.write_num_of_blocks(1);
      for(uint32_t i=0;i<128;i++)
      {
        hw_write32((uint32_t*)(SSY_HSP_SHAREDRAM_BASE_ADDR+i*4),offset_addr + i*4 + initial_value);
      }
      errors+=sinc_dvr.call_encrypt_block();
    }
  }

  errors+=sinc_dvr.transition_to_cache_active();

  sinc_dvr.write_perf_cntr_ctrl(SINC_PERF_HIT_CNTR_EN|SINC_PERF_MISS_CNTR_EN|SINC_PERF_LAT_CNTR_EN);

  //access random words
  exp_miss = 0;
  exp_hit = 0;

  hw_status("exp_miss is 0x%08x act_miss 0x%08x\n",exp_miss,sinc_dvr.read_miss_cntr_lower());
  hw_status("exp_hit is 0x%08x act_hit 0x%08x\n",exp_hit,sinc_dvr.read_hit_cntr_lower());
  
  hw_status("Accessing 200 random words\n");
  for(uint32_t i=0;i<200;i++)
  {
    if((i%25) == 0)
    {
      hw_status("Accessing random word %d\n",i);
    }
    set_num_index = rand() % 10;
    block_table_index = rand() % 10;
    word_num = rand() % 128;
    set = set_num[set_num_index];
    tag = block_table[set_num_index][block_table_index];
    if(check_hit(set_num_index,block_table_index))
    {
      exp_hit++;
    }
    else
    {
      exp_miss++;
    }
    offset_addr = ((tag & 0xff)<<16) | ((set & 0x7f)<<9);
    rdata = hw_read32((uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr + word_num*4));
    exp_rdata = offset_addr + word_num*4 + initial_value;
    if(rdata != exp_rdata)
    {
      hw_errmsg("compare saw mismatch read 0x%08x expected 0x%08x at addr 0x%08x\n",rdata,exp_rdata,(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr + word_num*4));
      errors++;
      hw_done(HW_TEST_FAIL);
      return;
    }
    errors+=sinc_dvr.check_perf_counters(exp_miss,exp_hit);
  }

  //check all data
  for(uint32_t j=0;j<10;j++)
  {
    for(uint32_t i=0;i<10;i++)
    {
      if(check_hit(j,i))
      {
        exp_hit+=128;
      }
      else
      {
        exp_miss++;
        exp_hit+=127;
      }
      offset_addr = ((block_table[j][i] & 0xff)<<16) | ((set_num[j] & 0x7f)<<9);
      
      //compare against expected
      for(uint32_t i=0;i<128;i++)
      {
        rdata = hw_read32((uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr + i*4));
        exp_rdata = offset_addr + i*4 + initial_value;
        if(rdata != exp_rdata)
        {
          hw_errmsg("compare saw mismatch read 0x%08x expected 0x%08x at addr 0x%08x\n",rdata,exp_rdata,(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + offset_addr + i*4));
          errors++;
          hw_done(HW_TEST_FAIL);
          return;
        }
      }
      errors+=sinc_dvr.check_perf_counters(exp_miss,exp_hit);
    }
  }

  hw_status("Hit counter read back 0x%08x%08x\n",sinc_dvr.read_hit_cntr_upper(),sinc_dvr.read_hit_cntr_lower());
  hw_status("Miss counter read back 0x%08x%08x\n",sinc_dvr.read_miss_cntr_upper(),sinc_dvr.read_miss_cntr_lower());
  hw_status("Latency counter read back 0x%08x%08x\n",sinc_dvr.read_lat_cntr_upper(),sinc_dvr.read_lat_cntr_lower());


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
