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
// File          : sinc_onoff_ret_check_disabled.c
// Description   : C test that verifies retention state across power on/off when SInC is disabled

#include "bifrost.h"
#include "params.h"
#include <crypto.h>
#include <drivers/ccs/ccs_driver.h>
#include <drivers/sinc/sinc_driver.h>
#include <drivers/dmb/dmb_driver.h>
#include <drivers/int/int_driver.h>
#include <drivers/pcu/pcu_driver.h>
#include "ext_int_regs.h"

uint32_t set_table[11];

void modify_mpu_pages(uint32_t initial_value_mpu)
{
  uint32_t new_privilege_attrib, new_user_attrib;
  for(uint32_t i=0;i<512;i++)
  {
    new_privilege_attrib = ((0xabcdabcd * i + initial_value_mpu) & 0x77777777);
    new_user_attrib = ((0x12341234 * i + initial_value_mpu) & 0x77777777);
    hw_write32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_PRIVILEGE_ATTRIB_0+i*4),new_privilege_attrib);
    hw_write32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_USER_ATTRIB_0+i*4),new_user_attrib);
  }
}

uint32_t check_mpu_pages(uint32_t initial_value_mpu)
{
  uint32_t exp_privilege_attrib, exp_user_attrib, act_privilege_attrib, act_user_attrib;
  uint32_t errors = 0;
  for(uint32_t i=0;i<512;i++)
  {
    //calculate expected values
    exp_privilege_attrib = ((0xabcdabcd * i + initial_value_mpu) & 0x77777777);
    exp_user_attrib = ((0x12341234 * i + initial_value_mpu) & 0x77777777);
    
    //read actual values
    act_privilege_attrib = hw_read32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_PRIVILEGE_ATTRIB_0+i*4));
    act_user_attrib = hw_read32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_USER_ATTRIB_0+i*4));

    //compare actual and expected
    if(act_privilege_attrib!=exp_privilege_attrib) {
      hw_errmsg("priv attr reg %0d is 0x%08x expected 0x%08x",i,act_privilege_attrib,exp_privilege_attrib);
      errors++;
    }

    if(act_user_attrib!=exp_user_attrib) {
      hw_errmsg("priv user reg %0d is 0x%08x expected 0x%08x",i,act_user_attrib,exp_privilege_attrib);
      errors++;
    }

    //reset mpu back to all allowed
    hw_write32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_PRIVILEGE_ATTRIB_0+i*4),0x77777777);
    hw_write32((uint32_t*)(SSY_HSP_MPU_SPCIRAM_USER_ATTRIB_0+i*4),0x77777777);
  }
  return errors;
}

void record_all_sinc_regs(SINC_DRIVER * sinc_dvr, uint32_t * reg_storage_arr)
{
    reg_storage_arr[0]=sinc_dvr->read_block_encr_num();
    reg_storage_arr[1]=sinc_dvr->read_num_of_blocks();
    reg_storage_arr[2]=sinc_dvr->read_block_encr_addr();
    reg_storage_arr[3]=sinc_dvr->read_block_encr_key();
    reg_storage_arr[4]=sinc_dvr->read_aes_iv_nonce_0();
    reg_storage_arr[5]=sinc_dvr->read_aes_iv_nonce_1();
    reg_storage_arr[6]=sinc_dvr->read_aes_iv_nonce_2();
    reg_storage_arr[7]=sinc_dvr->read_ext_block_base_addr();
    reg_storage_arr[8]=sinc_dvr->read_ext_auth_tag_base_addr();
    reg_storage_arr[9]=sinc_dvr->read_status();
    reg_storage_arr[10]=sinc_dvr->read_hit_cntr_lower();
    reg_storage_arr[11]=sinc_dvr->read_hit_cntr_upper();
    reg_storage_arr[12]=sinc_dvr->read_miss_cntr_lower();
    reg_storage_arr[13]=sinc_dvr->read_miss_cntr_upper();
    reg_storage_arr[14]=sinc_dvr->read_lat_cntr_lower();
    reg_storage_arr[15]=sinc_dvr->read_lat_cntr_upper();
    reg_storage_arr[16]=sinc_dvr->read_perf_cntr_ctrl();
    reg_storage_arr[17]=sinc_dvr->read_aes_test_data_in_0();
    reg_storage_arr[18]=sinc_dvr->read_aes_test_data_in_1();
    reg_storage_arr[19]=sinc_dvr->read_aes_test_data_in_2();
    reg_storage_arr[20]=sinc_dvr->read_aes_test_data_in_3();
    reg_storage_arr[21]=sinc_dvr->read_aes_test_data_out_0();
    reg_storage_arr[22]=sinc_dvr->read_aes_test_data_out_1();
    reg_storage_arr[23]=sinc_dvr->read_aes_test_data_out_2();
    reg_storage_arr[24]=sinc_dvr->read_aes_test_data_out_3();
    reg_storage_arr[25]=sinc_dvr->read_aes_test_ctrl();
    reg_storage_arr[26]=sinc_dvr->read_aes_test_status();
    reg_storage_arr[27]=sinc_dvr->read_encr_block_status();
}

uint32_t check_sinc_reg(uint32_t exp_value, const char * reg_name, uint32_t act_value)
{
  if(exp_value != act_value)
  {
    hw_errmsg("register %s act value 0x%08x does not match expected 0x%08x\n",reg_name,act_value,exp_value);
    return 1;
  }
  return 0;
}

uint32_t check_all_sinc_regs(SINC_DRIVER * sinc_dvr, uint32_t * reg_storage_arr)
{
    uint32_t errors = 0;
    
    errors+=check_sinc_reg(0,"block_encr_num",sinc_dvr->read_block_encr_num());
    errors+=check_sinc_reg(0,"num_of_block",sinc_dvr->read_num_of_blocks());
    errors+=check_sinc_reg(0,"block_encr_addr",sinc_dvr->read_block_encr_addr());
    errors+=check_sinc_reg(0,"block_encr_key",sinc_dvr->read_block_encr_key());
    errors+=check_sinc_reg(reg_storage_arr[4],"aes_iv_nonce_0",sinc_dvr->read_aes_iv_nonce_0());
    errors+=check_sinc_reg(reg_storage_arr[5],"aes_iv_nonce_1",sinc_dvr->read_aes_iv_nonce_1());
    errors+=check_sinc_reg(reg_storage_arr[6],"aes_iv_nonce_2",sinc_dvr->read_aes_iv_nonce_2());
    errors+=check_sinc_reg(reg_storage_arr[7],"ext_block_base_addr",sinc_dvr->read_ext_block_base_addr());
    errors+=check_sinc_reg(reg_storage_arr[8],"ext_auth_tag_base_addr",sinc_dvr->read_ext_auth_tag_base_addr());
    errors+=check_sinc_reg((reg_storage_arr[9]&0x3ff),"status",sinc_dvr->read_status());
    errors+=check_sinc_reg(0,"hit_cntr_lower",sinc_dvr->read_hit_cntr_lower());
    errors+=check_sinc_reg(0,"hit_cntr_upper",sinc_dvr->read_hit_cntr_upper());
    errors+=check_sinc_reg(0,"miss_cntr_lower",sinc_dvr->read_miss_cntr_lower());
    errors+=check_sinc_reg(0,"miss_cntr_upper",sinc_dvr->read_miss_cntr_upper());
    errors+=check_sinc_reg(0,"lat_cntr_lower",sinc_dvr->read_lat_cntr_lower());
    errors+=check_sinc_reg(0,"lat_cntr_upper",sinc_dvr->read_lat_cntr_upper());
    errors+=check_sinc_reg(0,"perf_cntr_ctrl",sinc_dvr->read_perf_cntr_ctrl());
    errors+=check_sinc_reg(0,"aes_test_data_in_0",sinc_dvr->read_aes_test_data_in_0());
    errors+=check_sinc_reg(0,"aes_test_data_in_1",sinc_dvr->read_aes_test_data_in_1());
    errors+=check_sinc_reg(0,"aes_test_data_in_2",sinc_dvr->read_aes_test_data_in_2());
    errors+=check_sinc_reg(0,"aes_test_data_in_3",sinc_dvr->read_aes_test_data_in_3());
    errors+=check_sinc_reg(0,"aes_test_data_out_0",sinc_dvr->read_aes_test_data_out_0());
    errors+=check_sinc_reg(0,"aes_test_data_out_1",sinc_dvr->read_aes_test_data_out_1());
    errors+=check_sinc_reg(0,"aes_test_data_out_2",sinc_dvr->read_aes_test_data_out_2());
    errors+=check_sinc_reg(0,"aes_test_data_out_3",sinc_dvr->read_aes_test_data_out_3());
    errors+=check_sinc_reg(0,"aes_test_ctrl",sinc_dvr->read_aes_test_ctrl());
    errors+=check_sinc_reg(0,"aes_test_status",sinc_dvr->read_aes_test_status());
    errors+=check_sinc_reg(0,"encr_block_status",sinc_dvr->read_encr_block_status());

    return errors;
}

//--------------------------------------------------------------------------------
// {{{ INIT_TEST
//--------------------------------------------------------------------------------
VOID INIT_TEST() {
  hw_status(" Inside function: %s.\n", __func__);

  PCU_DRIVER pcu_driver(PCU_HSP_OFFSET, true);
  pcu_driver.enable_interrupts();
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
  uint32_t dis_val, set;
  uint32_t register_storage[32];
  TestParams* params = (TestParams*) hw_getTestParamsPtr();
  PCU_DRIVER pcu_driver(PCU_HSP_OFFSET,true);

  uint32_t initial_value, initial_value_mpu, ciram_addr;

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

  sinc_dvr.write_block_encr_num(5);
  sinc_dvr.write_num_of_blocks(16);
  sinc_dvr.write_block_encr_addr(SSY_HSP_SHAREDRAM_BASE_ADDR);
  sinc_dvr.write_block_encr_key(7);
  sinc_dvr.write_aes_iv_nonce_0(rand());
  sinc_dvr.write_aes_iv_nonce_1(rand());
  sinc_dvr.write_aes_iv_nonce_2(rand());
  sinc_dvr.write_ext_block_base_addr((uint32_t)sram_addr_ptr);
  sinc_dvr.write_ext_auth_tag_base_addr(((uint32_t)sram_addr_ptr) + 0x1000000);
  hw_status("Wrote settings to sinc registers about to transition to init state\n");

  for(uint32_t i=0;i<11;i++)
  {
    
    do{
      set = rand() & 0x7f;
    } while(repeat_val(set,i,set_table));
    set_table[i] = set;
  }

  set = set_table[10];

  initial_value = rand();
  //write ciram in locations used by first 10 sets
  for(uint32_t i=0;i<10;i++)
  {
    ciram_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + 512*set_table[i];
    sinc_dvr.setup_known_data(ciram_addr,128,initial_value);
  }

  hw_status("Modifying MPU pages\n");

  //modify mpu
  initial_value_mpu = rand();
  modify_mpu_pages(initial_value_mpu);

  //randomly disable reset reinit or both
  dis_val = rand()%3;
  switch(dis_val) {
    case 0:
      hw_status("Disabling reinit\n");
      sinc_dvr.write_cmd(SINC_CMD_DISABLE_REINIT);
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_REINIT_DISABLED);
      break;
    case 1:
      hw_status("Disabling reset\n");
      sinc_dvr.write_cmd(SINC_CMD_DISABLE_RESET);
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_RESET_DISABLED);
      break;
    case 2:
      hw_status("Disabling reinit and reset\n");
      sinc_dvr.write_cmd(SINC_CMD_DISABLE_REINIT);
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_REINIT_DISABLED);
      sinc_dvr.write_cmd(SINC_CMD_DISABLE_RESET);
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_RESET_DISABLED);
      break;
  }

  hw_status("Recording sinc registers\n");

  //record all sinc registers
  record_all_sinc_regs(&sinc_dvr, register_storage);

  //do powergate
  hw_status("checking powergate\n");
  errors+= pcu_driver.pcu_pwrgate_checks(0,0,params->DIS_PWR_SWTITCH);

  //check mpu after powergate
  errors+= check_mpu_pages(initial_value_mpu);

  //check disable reset/reinit
  switch(dis_val) {
    case 0:
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_REINIT_DISABLED);
      break;
    case 1:
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_RESET_DISABLED);
      break;
    case 2:
      errors+=sinc_dvr.read_status_check_bits(SINC_STATUS_SINC_REINIT_DISABLED|SINC_STATUS_SINC_RESET_DISABLED);
      break;
  }

  //check registers
  check_all_sinc_regs(&sinc_dvr, register_storage);

  //check data written before powergate is still there
  for(uint32_t i=0;i<10;i++)
  {
    ciram_addr = SSY_CPU0_MEMORY_DEF_HSP_CIRAM_ADDRESS + 512*set_table[i];
    errors+=sinc_dvr.check_known_data(ciram_addr,128,initial_value);
  }

  errors+=sinc_dvr.check_sinc_state(SINC_STATE_DISABLED);

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
