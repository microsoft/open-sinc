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
// File          : sinc_aes_test_mode.c
// Description   : C test that exercises SInC AES test mode (known-answer encrypt/decrypt)

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include "drivers/aes/aes_wrap_driver.h"
#include "drivers/aeb/aeb_driver.h"
#include <drivers/dmb/dmb_driver.h>

uint32_t do_aes_test_mode_cmd(SINC_DRIVER * sinc_dvr, sinc_aes_struct_t * aes_data, uint32_t key_slot, uint32_t encrypt, uint32_t gcm_mode = 1, uint32_t reuse_key = 0, uint32_t num_blocks = 1)
{
  uint32_t errors = 0;
  uint32_t status;

  //1.	FW sets aes_test_en field to 1 in cmd register to enter AES test mode.
  sinc_dvr->write_cmd(SINC_CMD_AES_TEST_EN);

  //2.	FW loads block_encr_key, aes_iv_nonce*, and aes_test_data_in* registers.
  sinc_dvr->write_block_encr_key(key_slot);
  if(gcm_mode)
  {
    sinc_dvr->write_all_aes_iv_nonce(aes_data->init_vector);
  }
  

  //3.	FW waits for cfg_key_iv_rdy = 1 in aes_test_status register.
  sinc_dvr->wait_for_cfg_key_iv_rdy();

  for(uint32_t i=0;i<num_blocks;i++)
  {
      //part of step 2 but better done here to work for multiple blocks
      if(encrypt)
      {
        sinc_dvr->write_all_aes_test_data_in(aes_data->plaintext + i*4);
      }
      else
      {
        sinc_dvr->write_all_aes_test_data_in(aes_data->ciphertext + i*4);
      }
    
    //4.	FW loads mode, dir, key_len fields, set cfg_key_iv_vld = 1, and data_iv_vld = 0 in the aes_test_ctrl register. FW can additionally set reuse_key = 1 if it wants to reuse previously loaded key.
    sinc_dvr->set_aes_test_ctrl_mode_params(encrypt,gcm_mode,reuse_key);

    //a.	If reuse-key = 0, SInC reads the key from KSU.
    //5.	FW waits for data_in_rdy = 1 in aes_test_status register.
    sinc_dvr->wait_for_data_in_rdy();

    //6.	FW loads data_in_byte_cnt and data_in_last fields and set data_in_vld = 1 in the aes_test_ctrl register.
    //set last only if last block
    if(i == num_blocks-1)
    {
      sinc_dvr->set_aes_test_ctrl_data_params(1);
    }
    else
    {
      sinc_dvr->set_aes_test_ctrl_data_params(0);
    }

    //7.	FW waits for data_out_vld = 1 in aes_test_status register.
    sinc_dvr->wait_for_data_out_vld();

    //8.	FW reads aes_test_data_out* registers to get the AES output block and then set data_out_ack field to 1 in cmd register.
    if(encrypt)
    {
      errors+=sinc_dvr->compare_test_data_out(aes_data->ciphertext + i*4,"ciphertext");
    }
    else
    {
      errors+=sinc_dvr->compare_test_data_out(aes_data->plaintext + i*4,"plaintext");
    }

    sinc_dvr->write_aes_test_ctrl(SINC_AES_TEST_CTRL_DATA_OUT_ACK);
  }

  if(gcm_mode)
  {
    //9.	If there are more blocks to process, repeat the process from step #4. If the last output block is read, proceed to next step.
    //10.	In AES in GCM mode, then FW waits for data_out_vld = 1 and tag_out = 1 in aes_test_status register.
    sinc_dvr->wait_for_data_out_vld_and_tag_out();

    //11.	FW reads aes_test_data_out* registers to get the authentication tag and then set data_out_ack = 1 in aes_test_ctrl register.
    errors+=sinc_dvr->compare_test_data_out(aes_data->ciphertext + num_blocks*4,"tag");
    sinc_dvr->write_aes_test_ctrl(SINC_AES_TEST_CTRL_DATA_OUT_ACK);
  }

  //12.	FW can repeat from step #2 for next data payload OR exit out of test mode by setting aes_test_en = 0 in cmd register.
  sinc_dvr->write_cmd(0);

  status = sinc_dvr->wait_for_no_cmd_in_progress();
  errors+=sinc_dvr->check_cmd_result_status_success(status);
  
  return errors;
}

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);
}

uint32_t key_arr[8] = {0xd9adbd31, 0x04c29866, 0x44e19caa, 0xe14aa98e, 0x0b9a4afb, 0x3b779d3c, 0x2218bb51, 0x228f6b66};
uint32_t iv_arr[3] = {0x6ce0180d, 0xc95a727c, 0xcee162e3};
uint32_t message_arr[4] = {0x8e16b52d, 0xf8562593, 0x22069a08, 0x7d011d98};
uint32_t ct_arr[4] = {0x186243fa, 0x63d16196, 0x6da5d6fc, 0x5a40f08b};
uint32_t tag_arr[4] = {0x1bac36d6, 0xc35cddbe, 0xc27d72ee, 0x89944aab};

uint32_t key_arr2[8] = {0xe1bf8e4c, 0xb2c14e44, 0x98c603d5, 0x2caf5966, 0x94fefa94, 0xe8c1725f, 0xcf5a6a48, 0xf8a0b8ed};
uint32_t iv_arr2[3] = {0xe0603347, 0x998824ad, 0x95898559};
uint32_t ct_arr2[4] = {0x1081c7d2, 0x108f7eac, 0x57f00d7c, 0x0cc9d70b};
uint32_t tag_arr2[4] = {0x9b376ac2, 0x28ef986d, 0xced8ea52, 0xa733a883};


//--------------------------------------------------------------------------------
// {{{ RUN_TEST
//--------------------------------------------------------------------------------
VOID RUN_TEST(UINT32 iteration) {
  //Handle to fetch parameters from params.h
  //TestParams* params = (TestParams*) hw_getTestParamsPtr();
  SINC_DRIVER sinc_dvr;
  AES_DRIVER aes;

  unsigned int errors = 0;
  uint32_t key_slot;
  uint32_t * ccs_cmd_buf;
  uint32_t * input_buf;
  uint32_t encrypt, gcm_mode, reuse_key, num_blocks, initial_value;
  ALLOC_MEM * mem;
  AEB_DRIVER adriver;
  sinc_aes_struct_t aes_data;
  uint32_t *aes_cmd_ptr;
  uint64_t dmb_addr;
  uint32_t* block_addr_ptr;
  uint32_t* tag_addr_ptr;
  DMB_DRIVER dmb4hsp;
  uint32_t nonce[3];

  random_fill(nonce,3);
  dmb_addr = SYS_SRAM4_BASE_ADDR;
  block_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr,0x0,0xA,0x0);
  tag_addr_ptr = (uint32_t *) dmb4hsp.dmb_acquire(dmb_addr + 0x1000000,0x0,0xA,0x0);

#ifdef PLAT__L3
  hsp_rng_enable(0x1);
#else
  hsp_rng_enable(0xf);
#endif
  hsp_rng_wait_done();

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

  //allocate buffer for data input for command
    input_buf = (uint32_t*)mem->alloc(48);
    if(input_buf == NULL)
    {
        hw_errmsg(" Request Input Buffer Memory size not available in Memory selected.  \n");
        hw_done(HW_TEST_FAIL);
        return;
    }
  
  //construct ccs driver
  CCS_DRIVER ccs_cmd = CCS_DRIVER(ccs_cmd_buf,input_buf,NULL,NULL);

  /**<Allocate buffers for AES CMD */
  aes_cmd_ptr = (uint32_t*)mem->alloc(1280);
  if(aes_cmd_ptr == NULL)
  {
      hw_errmsg(" Request Command struct Memory size not available %d in Memory selected.  \n",(sizeof(AES_CMD)/4));
      errors++;
      hw_done(HW_TEST_FAIL);
  } 

  aes_data.init_vector = aes_cmd_ptr + sizeof(AES_CMD)/4; 
  aes_data.key = aes_data.init_vector + 4;
  aes_data.plaintext = aes_data.key + 8;
  aes_data.ciphertext = aes_data.plaintext + 128;

  hw_status("Setting AEB for KSU to ignore attributes on SInC key read\n");
  adriver.enable(AEB_KSU_ATTRCHK_BYPASS);

  reuse_key = 0;
  for(gcm_mode=0;gcm_mode<2;gcm_mode++)
  {
    for(encrypt=0;encrypt<2;encrypt++)
    {
      num_blocks = (rand() % 4) + 1;
      hw_status("gcm_mode = %d encrypt = %d num_blocks = %d\n",gcm_mode,encrypt,num_blocks);
      hw_status("Generating random aes data using model\n");
      sinc_dvr.gen_random_aes_data(&aes,aes_cmd_ptr,&aes_data,gcm_mode,num_blocks);

      //setup key in KSU for SINC to use
      key_slot = rand() % SSY_HSP_KSU_NUM_KEYS;
      errors+=sinc_dvr.setup_key(&ccs_cmd,key_slot,aes_data.key);
      errors+=do_aes_test_mode_cmd(&sinc_dvr, &aes_data, key_slot, encrypt, gcm_mode, reuse_key, num_blocks);

      if(errors) {
        hw_done(HW_TEST_FAIL);
        return;
      }
    }
  }

  //swicth off reuse key and randomize other parameters
  for(uint32_t i=0;i<30;i++)
  {
    reuse_key = reuse_key ^ 0x1;
    gcm_mode = rand() & 0x1;
    encrypt = rand() & 0x1;
    num_blocks = (rand() % 4) + 1;

    hw_status("gcm_mode = %d encrypt = %d num_blocks = %d reuse_key = %d\n",gcm_mode,encrypt,num_blocks,reuse_key);
    hw_status("Generating random aes data using model\n");

    if(reuse_key == 0)
    {
      sinc_dvr.gen_random_aes_data(&aes,aes_cmd_ptr,&aes_data,gcm_mode,num_blocks);
    }
    else
    {
      //don't regen key data when using cmode, take prior version
      sinc_dvr.gen_random_aes_data(&aes,aes_cmd_ptr,&aes_data,gcm_mode,num_blocks,aes_data.key);
    }
    

    //setup key in KSU for SINC to use if not reusing key
    if(reuse_key == 0)
    {
      key_slot = rand() % SSY_HSP_KSU_NUM_KEYS;
      errors+=sinc_dvr.setup_key(&ccs_cmd,key_slot,aes_data.key);
      errors+=do_aes_test_mode_cmd(&sinc_dvr, &aes_data, key_slot, encrypt, gcm_mode, reuse_key, num_blocks);
    }
    else
    {
      //tell setup key to call genrandom key
      key_slot = rand() % SSY_HSP_KSU_NUM_KEYS;
      errors+=sinc_dvr.setup_key(&ccs_cmd,key_slot,NULL,1);
      errors+=do_aes_test_mode_cmd(&sinc_dvr, &aes_data, key_slot, encrypt, gcm_mode, reuse_key, num_blocks);
    }

    if(errors) {
      hw_done(HW_TEST_FAIL);
      return;
    }
    

  }

  sinc_dvr.write_block_encr_num(0);
  sinc_dvr.write_num_of_blocks(1);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(0);
  sinc_dvr.write_all_aes_iv_nonce(nonce);
  sinc_dvr.write_ext_block_base_addr((uint32_t)block_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr((uint32_t)tag_addr_ptr);
  errors+=sinc_dvr.transition_to_initialized();
  initial_value = rand();
  sinc_dvr.write_num_of_blocks(1);
  sinc_dvr.setup_known_data(SSY_HSP_SHAREDRAM_BASE_ADDR,128,initial_value);
  errors+=sinc_dvr.call_encrypt_block();
  errors+=sinc_dvr.transition_to_cache_active();
  errors+=sinc_dvr.check_known_data(SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS,128,initial_value);


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
