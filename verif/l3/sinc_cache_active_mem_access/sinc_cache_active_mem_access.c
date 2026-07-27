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
// File          : sinc_cache_active_mem_access.c
// Description   : C test that performs memory accesses while the SInC cache is in the active state

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"
#include <drivers/int/int_driver.h>
#include <drivers/mpu/mpu_isr.h>
#include <drivers/sp_bus_err/sp_bus_err_isr.h>
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

uint32_t function1(uint32_t x){
   return x-5;
}

uint32_t function2(uint32_t x){
  return x+5;
}

uint32_t check_int_cnt(uint32_t exp_sp_bus_err_cnt, uint32_t exp_mpu_intr_cnt)
{
  INT_DRIVER *intr = intr->get_instance();
  uint32_t sp_bus_err_cnt, mpu_intr_cnt;
  uint32_t errors = 0;

  for(uint32_t i=0;i<100;i++);
  sp_bus_err_cnt = intr->int_info[HSP_SP_BUS_ERR_IRQ].int_trig_count;
  mpu_intr_cnt = intr->int_info[HSP_MPU_IRQ].int_trig_count;

  if(sp_bus_err_cnt != exp_sp_bus_err_cnt)
  {
    hw_errmsg("sp bus err count is %d expected %d\n",sp_bus_err_cnt,exp_sp_bus_err_cnt);
    errors++;
  }

  if(mpu_intr_cnt != exp_mpu_intr_cnt)
  {
    hw_errmsg("mpu intr count is %d expected %d\n",mpu_intr_cnt,exp_mpu_intr_cnt);
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
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, start_block_num, offset_block_num, cur_block_num, key_slot, waddr, num_blocks_to_encrypt, num_encrypts;
  //uint32_t ciram_start_addr, ciram_end_addr;//, iram_start_addr, iram_end_addr, dram_start_addr, dram_end_addr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value[1000];
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  uint32_t nonce[3];
  AEB_DRIVER adriver;
  MPU_INT_REGS_t *mpu_int_regs = (MPU_INT_REGS_t *)(SSY_HSP_MPU_ERROR_REGS);
  INT_DRIVER *intr = intr->get_instance(); ///< instance Interrupt Driver 
  intr->enable_interrupt(IRQ, HSP_SP_BUS_ERR_IRQ, (ISR_t)sp_bus_err_interrupt_handler); ///< Enable sp bus error interrupt
  intr->enable_interrupt(IRQ, HSP_MPU_IRQ, (ISR_t)mpu_interrupt_handler);
  intr->enable_interrupt(IRQ, HSP_DBT_IRQ, (ISR_t)mpu_dabort_handler);
  mpu_int_regs->MPU_INTEN = (1<<MPU_SPCIRAM);
  PCU_DRIVER pcu_driver(PCU_HSP_OFFSET,true);

  if(params->CLKGATE == 3)
  {              
      hw_status("checking clockgate %d\n",params->CLKGATE);
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE == 3) 
  {
      hw_status("checking powergate %d\n",params->PWRGATE);
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH); 
  }

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

  if(params->disable_encryption == 1)
  {
    adriver.enable(AEB_SINC_AUTHEN_DISABLE);
  }

  //get num_blocks_to_encrypt from param and make sure it is a non zero multiple of 16
  num_blocks_to_encrypt = params->num_blocks_to_encrypt;
  if((num_blocks_to_encrypt == 0) || (num_blocks_to_encrypt%16))
  {
    num_blocks_to_encrypt = (params->num_blocks_to_encrypt/16 + 1)*16;
  }
  num_encrypts = num_blocks_to_encrypt/16;

  //pick a random block less than 32768 - >num_blocks_to_encrypt, we are encrypting 768 blocks
  //there are 32768 total blocks in external memory, so 31999 is max start block to not overdlow
  start_block_num = rand() % (32768-num_blocks_to_encrypt);
  cur_block_num = start_block_num;
  random_fill(nonce,3);
  sinc_dvr.write_block_encr_num(cur_block_num);
  sinc_dvr.write_num_of_blocks(16);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(key_slot);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  if(params->CLKGATE == 4)
  {              
      hw_status("checking clockgate %d\n",params->CLKGATE);
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE == 4) 
  {
      hw_status("checking powergate %d\n",params->PWRGATE);
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH);
      sinc_dvr.write_block_encr_num(cur_block_num);
      sinc_dvr.write_num_of_blocks(16);
      sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
      sinc_dvr.write_block_encr_key(key_slot);
      sinc_dvr.write_all_aes_iv_nonce(nonce); 
  }

  errors+=sinc_dvr.transition_to_initialized();

  

  for(uint32_t i=0;i<num_encrypts;i++)
  {
    initial_value[i] = rand();
    //hw_status("Block num is %d initial value is 0x%08x\n",cur_block_num,initial_value[i]);
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,1024*2,initial_value[i]);
    errors+=sinc_dvr.call_encrypt_block();
    cur_block_num += 16;
    sinc_dvr.write_block_encr_num(cur_block_num);
  }

  errors+=sinc_dvr.transition_to_cache_active();

  hw_status("done transition_to_cache_active\n");
  flush_uart();

  if(params->CLKGATE == 1)
  {              
      hw_status("checking clockgate %d\n",params->CLKGATE);
      errors+= pcu_driver.pcu_clkgate_checks(0);
  }
  else if(params->PWRGATE == 1) 
  {
      hw_status("checking powergate %d\n",params->PWRGATE);
      errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH); 
  }

  //check writes to ciram in cache active state causes sp bus err
  waddr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  hw_status("testing write in cache active state to address 0x%08x\n",waddr);
  hw_write32((uint32_t*)waddr,0xabcdabcd);
  errors+=check_int_cnt(0,1);
  waddr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8) - 4;
  hw_status("testing write in cache active state to address 0x%08x\n",waddr);
  hw_write32((uint32_t*)waddr,0xabcdabcd);
  errors+=check_int_cnt(0,2);
  waddr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);
  hw_status("testing write in cache active state to address 0x%08x\n",waddr);
  hw_write32((uint32_t*)waddr,0xabcdabcd);
  errors+=check_int_cnt(0,3);
  waddr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + SSY_HSP_HW_MEM_EXT_MEM_SIZE - 4;
  hw_status("testing write in cache active state to address 0x%08x\n",waddr);
  hw_write32((uint32_t*)waddr,0xabcdabcd);
  errors+=check_int_cnt(0,4);

  //check data
  cur_block_num = start_block_num;
  for(uint32_t i=0;i<num_encrypts;i++)
  {
    hw_status("Calling wordcmp on %d words starting from address 0x%08x\n",1024*2,SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num);
    flush_uart();
    sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,1024*2,initial_value[i]);
    if(wordcmp((uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,(uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num),1024*2))
    {
      hw_errmsg("wordcmp saw mismatch\n");
      errors++;
    }
    cur_block_num += 16;
    hw_status("finished\n");
    flush_uart();
  }

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

  //check random blocks
  //
  for(uint32_t i=0;i<10;i++)
  {
    offset_block_num = rand() % num_blocks_to_encrypt;
    cur_block_num = start_block_num + offset_block_num;
    hw_status("Calling wordcmp on %d words starting from address 0x%08x\n",128,SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num);
    flush_uart();
    sinc_dvr.setup_known_data_offset(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value[offset_block_num/16],(offset_block_num%16)*128);
    if(wordcmp((uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,(uint32_t*)(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS+512*cur_block_num),128))
    {
      hw_errmsg("wordcmp saw mismatch\n");
      errors++;
    }
    errors+=sinc_dvr.check_ciphertext(&ccs_dvr,(uint32_t*)SSY_HSP_SHAREDRAM_BASE_ADDR,cur_block_num,0,0,params->disable_encryption);
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
