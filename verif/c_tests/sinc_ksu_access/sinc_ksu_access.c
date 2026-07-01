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
// File          : sinc_ksu_access.c
// Description   : C test that exercises Key Storage Unit (KSU) accesses through SInC

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include "drivers/aeb/aeb_driver.h"

#define EXP_NO_FETCH_ERROR    0
#define EXP_FETCH_ERROR       1

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t check_key_fetch(CCS_DRIVER *ccs_cmd, SINC_DRIVER * sinc_dvr, uint32_t key_attr, uint32_t exp_error)
{
  uint32_t errors = 0;
  errors+=ccs_cmd->gen_random_key_fixed_attr(0,key_attr);

    //transition to initialized, for invalid cases should expect fetch error
    if(exp_error==EXP_FETCH_ERROR)
    {
      errors+=sinc_dvr->transition_to_initialized(SINC_STATUS_KEY_FETCH_ERR);
      errors+=sinc_dvr->check_sinc_state(SINC_STATE_CACHE_FAILED);
    }
    else
    {
      errors+=sinc_dvr->transition_to_initialized(SINC_STATUS_NO_ERROR);
    }

    errors+=sinc_dvr->call_sinc_reset();

    errors+=sinc_dvr->check_sinc_state(SINC_STATE_DISABLED);
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
  uint32_t vld_key_attr;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  AEB_DRIVER adriver;

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
  CCS_DRIVER ccs_cmd = CCS_DRIVER(ccs_cmd_buf,NULL,NULL,NULL);

  //setup sinc registers
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

  vld_key_attr =  rand();
  vld_key_attr |= (KSU_ATTR_IS_DEVICE_SECRET | KSU_ATTR_AES_ENCRYPT_ALLOWED | KSU_ATTR_AES_DECRYPT_ALLOWED);
  vld_key_attr &= (~KSU_ATTR_KEY_SIZE_384);

  //valid attributes
  hw_status("Testing valid attributes\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr, EXP_NO_FETCH_ERROR);

  //invalid attributes - is device secret not set
  hw_status("Testing is device secret not set in attributes\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_IS_DEVICE_SECRET, EXP_FETCH_ERROR);

  //invalid attributes - aes encrypt allowed not set
  hw_status("Testing aes encrypt allowed not set in attributes\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_AES_ENCRYPT_ALLOWED, EXP_FETCH_ERROR);

  //invalid attributes - aes decrypt allowed not set
  hw_status("Testing aes decrypt allowed not set in attributes\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_AES_DECRYPT_ALLOWED, EXP_FETCH_ERROR);

  //invalid attributes - key size 384 set
  hw_status("Testing key size 384 set in attributes\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr | KSU_ATTR_KEY_SIZE_384, EXP_FETCH_ERROR);

  //set aeb for ksu to ignore invalid attributes then retry all cases
  hw_status("Setting aeb for ksu to ignore invalid attribute\n");
  adriver.enable(AEB_KSU_ATTRCHK_BYPASS);

  //valid attributes
  hw_status("Testing valid attributes with attrchk bypass aeb set\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr, EXP_NO_FETCH_ERROR);

  //invalid attributes - is device secret not set
  hw_status("Testing is device secret not set in attributes with attrchk bypass aeb set\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_IS_DEVICE_SECRET, EXP_NO_FETCH_ERROR);

  //invalid attributes - aes encrypt allowed not set
  hw_status("Testing aes encrypt allowed not set in attributes with attrchk bypass aeb set\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_AES_ENCRYPT_ALLOWED, EXP_NO_FETCH_ERROR);

  //invalid attributes - aes decrypt allowed not set
  hw_status("Testing aes decrypt allowed not set in attributes with attrchk bypass aeb set\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr & ~KSU_ATTR_AES_DECRYPT_ALLOWED, EXP_NO_FETCH_ERROR);

  //invalid attributes - key size 384 set
  hw_status("Testing key size 384 set in attributes with attrchk bypass aeb set\n");
  errors+=check_key_fetch(&ccs_cmd, &sinc_dvr, vld_key_attr | KSU_ATTR_KEY_SIZE_384, EXP_NO_FETCH_ERROR);

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
