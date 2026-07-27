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
// File          : sinc_cache_disabled_mem_access.c
// Description   : C test that performs memory accesses while the SInC cache is disabled

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/sinc/sinc_driver.h>
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
  uint32_t errors = 0;
  uint32_t ciram_start_addr, ciram_end_addr, wdata, rdata, sp_bus_err_cnt;

  INT_DRIVER *intr = intr->get_instance(); ///< instance Interrupt Driver 
  intr->enable_interrupt(IRQ, HSP_SP_BUS_ERR_IRQ, (ISR_t)sp_bus_err_interrupt_handler); ///< Enable sp bus error interrupt
  intr->enable_interrupt(IRQ, HSP_MPU_IRQ, (ISR_t)mpu_interrupt_handler);
  intr->enable_interrupt(IRQ, HSP_DBT_IRQ, (ISR_t)mpu_dabort_handler);

  ciram_start_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  ciram_end_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_CIRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_CIRAM_WIDTH/8);

  //check that we can read and all registers as a sanity check
  sinc_dvr.read_all_regs();

  //test reading and writing to various parts of ciram
  errors+=sinc_dvr.test_ram_rw(ciram_start_addr, ciram_end_addr);

  //test executing from various parts of ciram
  errors+=sinc_dvr.test_ram_func(ciram_start_addr, ciram_end_addr, function1, function2);

  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);

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

}

//--------------------------------------------------------------------------------
// {{{ CLEANUP_TEST
//--------------------------------------------------------------------------------
VOID CLEANUP_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}
