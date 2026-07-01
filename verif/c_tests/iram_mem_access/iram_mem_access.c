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
// File          : iram_mem_access.c
// Description   : C test that performs a write/read sweep across SInC IRAM to validate basic memory access

#include "bifrost.h"
#include "params.h"
#include <crypto.h>

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
  uint32_t errors = 0;
  //uint32_t iram_size_1k;
  uint32_t rdata, exp_data;
  uint32_t start_addr, end_addr;

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //iram_size_1k = (SSY_CPU0_MEMORY_DEF_HSP_IRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_IRAM_WIDTH/8)/1024;
  

  //for(uint32_t i=0;i<iram_size_1k;i++)
  hw_status("Setting up 64k known data at address 0x%08x\n",SSY_CPU0_MEMORY_DEF_HSP_IRAM_ADDRESS);
  start_addr = SSY_CPU0_MEMORY_DEF_HSP_IRAM_ADDRESS;
  end_addr = SSY_CPU0_MEMORY_DEF_HSP_IRAM_ADDRESS + (SSY_CPU0_MEMORY_DEF_HSP_IRAM_DEPTH*SSY_CPU0_MEMORY_DEF_HSP_IRAM_WIDTH/8);
  for(uint32_t addr=start_addr;addr<end_addr;addr+=4)
  {
    hw_write32((uint32_t *)addr,0x12345678 + addr);
  }

  //check data
  hw_status("Checking 64k known data at address 0x%08x\n",SSY_CPU0_MEMORY_DEF_HSP_IRAM_ADDRESS);
  for(uint32_t addr=start_addr;addr<end_addr;addr+=4)
  {
    hw_write32((uint32_t *)0x8F000240,1);
    hw_write32((uint32_t *)0x8F000244,addr);
    rdata = hw_read32((uint32_t *)addr);
    hw_write32((uint32_t *)0x8F000240,2);
    exp_data = 0x12345678 + addr;
    hw_write32((uint32_t *)0x8F000240,3);
    if(rdata != exp_data)
    {
      hw_errmsg("read data 0x%08x does not match expected data 0x%08x at addr 0x%08x\n",rdata, exp_data, addr);
    }
    hw_write32((uint32_t *)0x8F000240,3);
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
