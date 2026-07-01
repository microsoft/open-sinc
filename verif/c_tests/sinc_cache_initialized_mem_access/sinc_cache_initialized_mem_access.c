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
// File          : sinc_cache_initialized_mem_access.c
// Description   : C test that performs memory accesses with the SInC cache in the initialized state

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/int/int_driver.h>
#include <drivers/mpu/mpu_isr.h>
#include <drivers/sp_bus_err/sp_bus_err_isr.h>

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
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  uint64_t dmb_addr;
  uint32_t errors = 0;
  uint32_t key_attr, initial_value;
  uint32_t ciram_start_addr, ciram_end_addr, wdata, rdata, sp_bus_err_cnt;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;

  INT_DRIVER *intr = intr->get_instance(); ///< instance Interrupt Driver 
  intr->enable_interrupt(IRQ, HSP_SP_BUS_ERR_IRQ, (ISR_t)sp_bus_err_interrupt_handler); ///< Enable sp bus error interrupt
  intr->enable_interrupt(IRQ, HSP_MPU_IRQ, (ISR_t)mpu_interrupt_handler);
  intr->enable_interrupt(IRQ, HSP_DBT_IRQ, (ISR_t)mpu_dabort_handler);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  ciram_start_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  ciram_end_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);

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
  sinc_dvr.write_num_of_blocks(0);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_aes_iv_nonce_0(0);
  sinc_dvr.write_aes_iv_nonce_1(0);
  sinc_dvr.write_aes_iv_nonce_2(0);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  hw_status("status read back 0x%08x\n",sinc_dvr.read_status());

  //setup some data into ciram before we transition so we can check that transition doesn't wipe it
  initial_value = rand();
  sinc_dvr.setup_known_data(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS,128,initial_value);

  errors+=sinc_dvr.transition_to_initialized();

  //check data written before transition is still there
  errors+=sinc_dvr.check_known_data(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS,128,initial_value);

  //test writing and reading to various parts of ciram
  errors+=sinc_dvr.test_ram_rw(ciram_start_addr, ciram_end_addr);

  //test executing from various parts of ciram
  errors+=sinc_dvr.test_ram_func(ciram_start_addr, ciram_end_addr, function1, function2);

  //read and write above cached iram
  do {
    wdata = rand();
  } while(wdata == 0);
  
  
  hw_status("testing write above ciram\n");
  hw_write32((uint32_t*)ciram_end_addr, wdata);
  
  hw_status("testing read above ciram\n");
  rdata = hw_read32((uint32_t*)ciram_end_addr);

  //check the data wasn't written
  if(wdata == rdata)
  {
    hw_errmsg("rdata 0x%08x matched wdata 0x%08x but expected write and read to be blocked\n",rdata,wdata);
  }

  //check interrupt counts, need to delay a bit so read doesn't beat interrupt
  for(uint32_t i=0;i<100;i++);
  sp_bus_err_cnt = intr->int_info[HSP_SP_BUS_ERR_IRQ].int_trig_count;

  if(sp_bus_err_cnt != 2)
  {
    hw_errmsg("sp bus err cnt is %d expected %d\n",sp_bus_err_cnt,2);
  }

  if(errors) {
    hw_done(HW_TEST_FAIL);
  } else {
    hw_done(HW_TEST_PASS);
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
