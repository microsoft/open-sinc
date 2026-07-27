# SINC Test List

This document contains a comprehensive list of all SINC tests with their stimulus types and descriptions.

| Test Name | Stimulus Type | Description |
|-----------|---------------|-------------|
| sinc_sanity | Direct | Basic requests to SInC DUT, directive driven stimulus to exercise each function. |
| sinc_sanity_dis_auth_check | Direct | Sanity test with DIS_ENCR_AUTH_CHECK set to 1. |
| sinc_sanity_preload | Direct | Sanity test with backdoor preload mem feature enabled. |
| sinc_sanity_dis_reset | Direct | Sanity test with DISABLE_RESET set to 1. |
| sinc_sanity_reinit | Direct | Sanity test focusing on REINIT state. |
| sinc_sanity_dis_reinit | Direct | Sanity test focusing on REINIT state plus DISABLE_REINIT set 1. |
| sinc_sanity_reg | Direct | Sanity test focusing on register testing. |
| sinc_sanity_cpu_mem | Direct | Sanity test focusing on CPU transactions with other operations turned off. |
| sinc_sanity_cpu_mem_preload | Direct | Sanity test focusing on CPU transactions with BACKDOOR_PRELOAD_MEM enabled. |
| sinc_sanity_mpu_config | Direct | Sanity test focusing on MPU transactions. |
| sinc_sanity_fw_op | Direct | Sanity test focusing on FW operations. |
| sinc_sanity_aes | Direct | Sanity test focusing on AES commands. |
| sinc_invalid_aes_test_directed | Direct | Invalid AES test commands to verify error handling. |
| sinc_resp_error_aes_test_directed | Direct | Invalid AES test commands due to AXI subordinate response errors. |
| sinc_legal_valid_rand | Random | Legal and valid requests only. |
| sinc_legal_valid_rand_dis_auth_check | Random | Legal and valid requests with DIS_AUTH set 1. |
| sinc_rand_auth_check | Random | Legal and valid requests with AUTH_CHECK enabled. |
| sinc_rand_auth_check_cache_active | Random, State Focused | Legal and valid requests mostly at CACHE ACTIVE state. |
| sinc_legal_valid_rand_w_min_delay | Random, Performance Oriented | Legal and valid requests with minimum delay. |
| sinc_legal_valid_rand_with_reset | Random | Legal and valid requests with random reset during test. |
| sinc_legal_valid_rand_with_erase | Random | Legal and valid requests with random erase during test. |
| sinc_legal_valid_rand_fw_op_with_erase_and_reset | Random | Legal and valid requests with combination of FW_Operation, Erase, and Reset. |
| sinc_legal_valid_rand_fw_op_with_mpu_read | Random | Legal and valid requests with more MPU reads. |
| sinc_legal_valid_rand_most_erase | Random, Operation Focused | Legal and valid requests, focus on testing erase. |
| sinc_legal_valid_rand_cache_active_with_erase | Random, State Focused | Legal and valid requests, focus on testing erase in CACHE ACTIVE state. |
| sinc_legal_valid_rand_cache_disabled | Random, State Focused | Legal and valid requests, focus on testing in CACHE DISABLED state. |
| sinc_legal_valid_rand_cache_initialized | Random, State Focused | Legal and valid requests, focus on testing in CACHE INITIALIZED state. |
| sinc_legal_valid_rand_cache_active | Random, State Focused | Legal and valid requests, mostly done in CACHE ACTIVE state. |
| sinc_legal_valid_rand_axi_including_fw_op | Random, Protocol Focused | Legal and valid AXI requests and FW operations. |
| sinc_legal_valid_rand_fw_op_no_disable | Random, Protocol Focused | Legal and valid AXI requests and FW operations, avoiding DISABLE state. |
| sinc_legal_valid_rand_axi_non_fw_op | Random, Protocol Focused | Legal and valid AXI requests, no FW operations. |
| sinc_legal_valid_rand_fw_op_only_aes | Random, Protocol Focused | Legal and valid AXI requests and FW operations, only AES test commands. |
| sinc_legal_valid_rand_fw_op_no_aes | Random, Protocol Focused | Legal and valid AXI requests and FW operations, never AES test commands. |
| sinc_legal_valid_rand_cpu_cmd_in_disable_state | Random, State Focused | Legal and valid CPU commands and FW operations in CACHE DISABLED state. |
| sinc_legal_valid_rand_cpu_cmd_in_init_state | Random, State Focused | Legal and valid CPU commands and FW operations in CACHE INITIALIZED state. |
| sinc_legal_valid_rand_cpu_cmd_in_active_state_high_hit | Random, Performance Focused | Legal and valid CPU read requests in CACHE ACTIVE state with high cache hit ratio (90%). |
| sinc_legal_valid_rand_cpu_cmd_in_active_state_high_miss | Random, Performance Focused | Legal and valid CPU read requests in CACHE ACTIVE state with high cache miss ratio (90%). |
| sinc_legal_valid_rand_mpu_req_init_state | Random, State Focused | MPU requests and FW operations in CACHE INITIALIZED state. |
| sinc_legal_valid_rand_mpu_req_active_state | Random, State Focused | MPU requests and FW operations in CACHE ACTIVE state. |
| sinc_legal_valid_rand_mpu_req | Random | MPU requests and FW operations. |
| sinc_invalid_rand | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_rand_at_cache_failed | Random with errors | Invalid access to SInC in CACHE FAILED state. |
| sinc_invalid_rand_at_cache_failed_erase | Random with errors | Invalid access to SInC in CACHE FAILED state with erase operations. |
| sinc_invalid_rand_w_min_delay | Random with errors, Performance Oriented | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_non_severe | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_severe | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_fw_fault_w_rng_fetch_fail_high_reset_high_set_init | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_severe_at_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_invalid_cmd_for_cache_disabled | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_invalid_cmd_for_cache_initization | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_axi_rand_invalid_cmd_for_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_fw_fault_w_rng_fetch_fail | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_fw_encr_blcok_fail | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_non_severe | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_non_severe_non_blocking_tran_cache_active | Random with errors, Performance Oriented | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_non_severe_non_blocking_tran | Random with errors, Performance Oriented | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_legal_valid_rand_cpu_cmd_non_blocking_tran | Random, Performance Oriented | Legal and valid CPU commands and FW operations using non-blocking transactions with back-to-back operations. |
| sinc_invalid_cpu_rand_w_tag_mismatch | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_at_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_non_severe_at_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_cpu_rand_at_cache_active_w_tag_mismatch | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_severe_cpu_rand_at_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_invalid_concurrent_rand | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_active | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_concurrent_erase_rand_at_cache_fail | Random with favor of | Higher chance to do severe error, then operate erase and CPU transactions |
| sinc_invalid_concurrent_rand_at_cache_active_erase_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_initialization_erase_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_disabled_erase_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_disabled_cpu_erase_same_time | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_active_cpu_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_initialization_cpu_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_disabled_cpu_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_active_axi_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_initialization_axi_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_disabled_axi_during | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_concurrent_rand_at_cache_active_cpu_during_erase | Random with errors | Intentionally doing CPU request during Erase operation. |
| sinc_invalid_concurrent_rand_at_cache_disable_cpu_during_erase | Random with errors | Intentionally doing CPU request during Erase operation. |
| sinc_invalid_concurrent_rand_at_cache_active_erase_during_cpu | Random with errors | Intentionally doing CPU request during Erase operation. |
| sinc_invalid_concurrent_rand_at_cache_disable_erase_during_cpu | Random with errors | Intentionally doing CPU request during Erase operation. |
| sinc_invalid_concurrent_rand_at_cache_active_w_cache_fail | Random with errors | Invalid access to SInC with legal and valid requests. Have concurrent transactions. |
| sinc_invalid_mpu_rand | Random with errors | Invalid access to SInC with legal and valid requests. Allow only one error scenario. |
| sinc_multiple_invalid_rand | Random with errors | Invalid access to SInC with legal and valid requests. Allow multiple error scenarios. |
| sinc_legal_valid_rand_cpu_cmd_in_active_state_w_cache_pool | Random, Performance Focused | Legal and valid CPU read requests in CACHE ACTIVE state with high cache hit ratio and access within cache pool (pool size 10). |
| sinc_ecc_base_test | Direct | Error injection and check correctable and uncorrectable error. |
| sinc_ecc_disable_state_uncorr_err_direct_test | Direct | SINC 2 bit ecc error check in cache disabled state |
| sinc_ecc_init_state_uncorr_err_direct_test | Direct | SINC 2 bit ecc error check in cache init state |
| sinc_ecc_active_state_uncorr_err_direct_test | Direct | SINC 2 bit ecc error check in cache active state |
| sinc_ecc_correctable_err_direct_test | Direct | SINC single bit ecc error check |
| sinc_ecc_corr_err_chk_disabled_direct_test | Direct | SINC single bit ecc error check with error check disabled |
| sinc_ecc_uncorr_err_chk_disabled_direct_test | Direct | SINC 2 bit ecc error check in cache active state with error check disabled |
| sinc_rand_fsm_fault_err_on_cmu_cache_fsm | Random with errors | FSM fault error injection on CMU cache FSM, avoiding DISABLE state. |
| sinc_rand_fsm_fault_err_on_sinc_sub_state_fsm | Random with errors | FSM fault error injection on SINC sub-state FSM, avoiding DISABLE state. |
| sinc_rand_fsm_fault_err_on_cmu_dma_r_fsm | Random with errors | FSM fault error injection on CMU DMA read FSM, focusing on CPU read operations. |
| sinc_rand_fsm_fault_err_on_cmu_dma_w_fsm | Random with errors | FSM fault error injection on CMU DMA write FSM, focusing on CPU write operations. |
| sinc_rand_fsm_fault_err_on_aes_ctrl_fsm | Random with errors | FSM fault error injection on AES control FSM, avoiding DISABLE state. |
| sinc_rand_fsm_fault_err_on_gpaes_mode_main_fsm | Random with errors | FSM fault error injection on GPAES mode main FSM, avoiding DISABLE state. |
| sinc_rand_fsm_fault_err_on_gpaes_ghash_mul_fsm | Random with errors | FSM fault error injection on GPAES GHASH multiplier FSM. |
| sinc_rand_fsm_fault_err_on_gpaes_mode_ghash_fsm | Random with errors | FSM fault error injection on GPAES mode GHASH FSM, focusing on AES test commands. |
| sinc_rand_fsm_fault_err_on_aes_ctrl_fsm_with_aes_test | Random with errors | FSM fault error injection on AES control FSM, focusing on AES test commands. |
| sinc_rand_fsm_fault_err_on_cmu_ctrl_fsm | Random with errors | FSM fault error injection on CMU control FSM, focusing on CPU read operations, avoiding DISABLE state. |
| sinc_rand_fsm_fault_err_on_gpaes_sub_state_fsm | Random with errors | FSM fault error injection on GPAES sub-state FSM. |
| sinc_rand_fsm_fault_err_on_ciu_cache_fsm | Random with errors | FSM fault error injection on CIU cache FSM. |
| sinc_vtag_parity_err_test | Direct | VTAG parity error injection and check. Runs deterministically, DISABLED/ACTIVE + INJECT/NO_INJECT with randomized address kept constant throughout iterations. |
| sinc_vtag_parity_err_rand_test | Random with errors | VTAG parity error injection and check with completely randomized iterations. |
| sinc_cpu_b2b_cache_fail_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit back to back CPU RD with cache fail scenarios |
| sinc_cpu_req_on_last_erase_mem_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit CPU RD happen at last erase mem slot timing |
| sinc_concurrent_fw_op_and_fetch_block_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit CPU RD happen at last erase mem slot timing |
| sinc_lp_rst_rng_fetch_fail_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset follow with RNG fetch fail |
| sinc_lp_rst_rng_fetch_fail_on_iot_seed_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset follow with RNG fetch fail during IOT seed stage |
| sinc_soc_rst_rng_fetch_fail_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset follow with RNG fetch fail |
| sinc_pow_rst_rng_fetch_fail_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset follow with RNG fetch fail |
| sinc_lp_rst_from_active_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset from active state |
| sinc_soc_rst_from_active_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset from active state |
| sinc_pow_rst_from_active_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset from active state |
| sinc_lp_rst_from_disable_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset from disabled state |
| sinc_soc_rst_from_disable_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset from disabled state |
| sinc_pow_rst_from_disable_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset from disabled state |
| sinc_lp_rst_from_init_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset from init state |
| sinc_soc_rst_from_init_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset from init state |
| sinc_pow_rst_from_init_state_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset from init state |
| sinc_lp_rst_from_active_state_during_aes_compute_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset during AES compute |
| sinc_soc_rst_from_active_state_during_aes_compute_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset during AES compute |
| sinc_pow_rst_from_active_state_during_aes_compute_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset during AES compute |
| sinc_lp_rst_from_active_state_during_axi_transaction_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit low power reset during AXI transaction |
| sinc_soc_rst_from_active_state_during_axi_transaction_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit SOC reset during AXI transaction |
| sinc_pow_rst_from_active_state_during_axi_transaction_direct_err_test | Direct, Coverage Oriented | Coverage oriented test to hit power reset during AXI transaction |
| sinc_fw_fault_injection | Direct | Test firmware fault injection on SINC FW |
