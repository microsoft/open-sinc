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
// File          : sinc_intr.c
// Description   : C test that exercises SInC interrupt generation and CPU handling

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/int/int_driver.h>
#include <drivers/crypto/crypto_driver.h>
#include <drivers/crypto/crypto_done_isr.h>
#include "drivers/mem_err/mem_err_defines.h"

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t check_int_count(uint32_t int_count, uint32_t exp_int_count)
{
  if(int_count != exp_int_count)
  {
    hw_errmsg("int_count is %d, expected %d\n",int_count,exp_int_count);
    return 1;
  }
  else
  {
    hw_status("int_count is 0x%08x\n",int_count);
    return 0;
  }
}

uint32_t check_crypto_intsts(uint32_t crypto_done_intsts)
{
  if((crypto_done_intsts & (1 <<SINC_BIT)) == 0)
  {
    hw_errmsg("Did not see sinc bit in crypto_done_intsts 0x%08x\n",crypto_done_intsts);
    return 1;
  }
  else
  {
    hw_status("crypto_done_intsts is 0x%08x\n",crypto_done_intsts);
    return 0;
  }
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
  uint32_t key_attr, exp_int_count, done_sts;
  ALLOC_MEM * mem;
  uint32_t * ccs_cmd_buf;
  uint32_t initial_value;
  INT_DRIVER *intr = intr->get_instance();
  CRYPTO_DRIVER crypto;
  Creg_regs_mem_err *mem_err_ptr;
  mem_err_ptr = (Creg_regs_mem_err *)SSY_HSP_CREG_MEM_ADDR;

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

  //setup interrupts and clear existing
  crypto.set_crypto_done_intsts(1 << SINC_BIT);
  intr->disable_interrupt(IRQ, HSP_DMB_IRQ);
  intr->enable_interrupt(IRQ, HSP_CRYPTO_DONE_IRQ, crypto_done_interrupt_handler);
  crypto.set_crypto_done_int_en_bit(SINC_BIT);
  exp_int_count = 0;

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
  sinc_dvr.write_num_of_blocks(2);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_aes_iv_nonce_0(0);
  sinc_dvr.write_aes_iv_nonce_1(0);
  sinc_dvr.write_aes_iv_nonce_2(0);
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");
  flush_uart();

  errors+=sinc_dvr.transition_to_initialized();

  exp_int_count++;
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //copy some data into shared ram to encrypt
  initial_value = rand();
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value);

  //do encrypt block
  flush_uart();
  exp_int_count++;
  errors+=sinc_dvr.call_encrypt_block();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //transition to cache active
  flush_uart();
  exp_int_count++;
  errors+=sinc_dvr.transition_to_cache_active();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //reinint
  flush_uart();
  exp_int_count++;
  errors+=sinc_dvr.call_sinc_reinit();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //reset
  flush_uart();
  exp_int_count++;
  errors+=sinc_dvr.call_sinc_reset();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //aes_test_mode
  flush_uart();
  exp_int_count++;
  sinc_dvr.write_cmd(SINC_CMD_AES_TEST_EN);
  sinc_dvr.write_cmd(0);
  hw_sleep(10);
  flush_uart();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

  //memory erase
  flush_uart();
  exp_int_count++;
  //clear prior done status
  done_sts = mem_err_ptr->MEM_ERASE_DONE_STS;
  mem_err_ptr->MEM_ERASE_DONE_STS = done_sts;

  mem_err_ptr->MEM_ERASE_EN = (1<<MEM_SPCIRAM);
  do {
    done_sts = (mem_err_ptr->MEM_ERASE_DONE_STS & (1<<MEM_SPCIRAM));
  } while(done_sts == 0);
  hw_sleep(10);
  flush_uart();
  errors+=check_int_count(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_trig_count,exp_int_count);
  errors+=check_crypto_intsts(intr->int_info[HSP_CRYPTO_DONE_IRQ].int_message[INT_CRYPTO_DONE_INTSTS]);

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
