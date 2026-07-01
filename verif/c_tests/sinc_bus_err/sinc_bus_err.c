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
// File          : sinc_bus_err.c
// Description   : C test that injects bus errors and verifies SInC error reporting

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/int/int_driver.h>
#include <drivers/crypto/crypto_driver.h>
#include <drivers/crypto/crypto_err_isr.h>

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
  SINC_DRIVER sinc_dvr;
  DMB_DRIVER dmb4hsp;
  uint64_t dmb_addr;
  unsigned int errors = 0;
  uint32_t key_attr, crypto_err_intsts, int_count;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value;
  INT_DRIVER *intr = intr->get_instance();
  CRYPTO_DRIVER crypto;

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //disable interrupts
  intr->disable_interrupt(IRQ, HSP_DMB_IRQ);
  intr->enable_interrupt(IRQ, HSP_CRYPTO_ERR_IRQ, crypto_err_interrupt_handler);
  crypto.set_crypto_err_int_en_bit(SINC_BIT);

  dmb_addr = SYS_SRAM4_BASE_ADDR;

  uint32_t* sram_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);
  dmb4hsp.set_priv_perm_data(sram_addr_ptr,0x0);
  dmb4hsp.set_user_perm_data(sram_addr_ptr,0x0);
  dmb4hsp.set_crypto_perm_data(sram_addr_ptr,0x0);

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
  sinc_dvr.write_num_of_blocks(2);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_aes_iv_nonce_0(0);
  sinc_dvr.write_aes_iv_nonce_1(0);
  sinc_dvr.write_aes_iv_nonce_2(0);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  errors+=sinc_dvr.transition_to_initialized();

  //copy some data into shared ram to encrypt
  initial_value = rand();
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value);

  //copy function to sharedram for encryption
  sinc_dvr.copy_func(SSY_HSP_SHAREDRAM_BASE_ADDR+512,function1,function2);

  int_count = 0;

  //do encrypt block
  errors+=sinc_dvr.call_encrypt_block(SINC_STATUS_CACHE_BLOCK_W_ERR_ENCR_BLOCK);

  int_count = intr->int_info[HSP_CRYPTO_ERR_IRQ].int_trig_count;
  if(int_count != 1)
  {
    hw_errmsg("int_count is 0x%08x, expected 1\n",int_count);
    errors++;
  }
  else
  {
    hw_status("int_count is 0x%08x\n",int_count);
  }

  crypto_err_intsts = intr->int_info[HSP_CRYPTO_ERR_IRQ].int_message[INT_CRYPTO_ERR_INTSTS];
  if((crypto_err_intsts & (1 <<SINC_BIT)) == 0)
  {
    hw_errmsg("Did not see sinc error in crypto_err_intsts 0x%08x\n",crypto_err_intsts);
    errors++;
  }
  else
  {
    hw_status("crypto_err_intsts is 0x%08x\n",crypto_err_intsts);
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
