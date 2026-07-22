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
// File          : sinc_cache_disabled_mem_access_byte.c
// Description   : C test that performs byte-granularity accesses while the SInC cache is disabled

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/sinc/sinc_driver.h>

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  //Handle to fetch parameters from params.h
  //TestParams* params = (TestParams*) hw_getTestParamsPtr();

  unsigned int errors = 0;
  uint8_t * data_8b = (uint8_t *) SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  uint32_t * data_32b = (uint32_t *) SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS;
  uint32_t rdata;

  //byte write and word read
  data_8b[0] = 0x12;
  data_8b[1] = 0x34;
  data_8b[2] = 0x56;
  data_8b[3] = 0x78;
  
  rdata = data_32b[0];

  if(rdata!=0x78563412)
  {
    hw_errmsg("At ADDR 0x%08x wrote 0x%08x as 4 byte writes but read back 0x%08x\n",&data_32b[0],0x78563412,rdata);
    errors++;
  }

  //word write and byte read
  data_32b[0] = 0xabcdef87;
  
  rdata = data_8b[0];
  if(rdata!=0x87)
  {
    hw_errmsg("At ADDR 0x%08x wrote 0x%08x but byte 0 read back was 0x%02x\n",&data_32b[0],0xabcdef87,rdata);
    errors++;
  }

  rdata = data_8b[1];
  if(rdata!=0xef)
  {
    hw_errmsg("At ADDR 0x%08x wrote 0x%08x but byte 1 read back was 0x%02x\n",&data_32b[0],0xabcdef87,rdata);
    errors++;
  }

  rdata = data_8b[2];
  if(rdata!=0xcd)
  {
    hw_errmsg("At ADDR 0x%08x wrote 0x%08x but byte 2 read back was 0x%02x\n",&data_32b[0],0xabcdef87,rdata);
    errors++;
  }

  rdata = data_8b[3];
  if(rdata!=0xab)
  {
    hw_errmsg("At ADDR 0x%08x wrote 0x%08x but byte 3 read back was 0x%02x\n",&data_32b[0],0xabcdef87,rdata);
    errors++;
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
