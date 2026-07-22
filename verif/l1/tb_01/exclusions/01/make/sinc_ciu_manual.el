//==================================================
// This file contains the Excluded objects
// Format Version: 2
// Date: Mon Nov 25 12:17:24 2024
// ExclMode: default
//==================================================
CHECKSUM: "2796863742 3353693150"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
ANNOTATION: "The given tests for parity check passed for both success and fail."
Branch 9 "3746149238" "ciu_cache_sm_r" (8) "ciu_cache_sm_r CIU_IDLE ,0,-,0,-,0,-,-,0,1,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-"
ANNOTATION: "This line will be 11 instead of 01 after review"
Branch 8 "3688740497" "(ciu_mem_write_r && (!(mpu_acc_vio || ext_acc_vio_r)))" (4) "(ciu_mem_write_r && (!(mpu_acc_vio || ext_acc_vio_r))) 1,MISSING_DEFAULT"
ANNOTATION: "This line will be 11 instead of 01 after review"
Branch 4 "659858255" "block_read_sel_r" (4) "block_read_sel_r MISSING_DEFAULT"
ANNOTATION: "Unreachable as only two cases to make the state transition (warm reset and FW command) that won't hit WAIT instead of IDLE."
Branch 9 "3746149238" "ciu_cache_sm_r" (19) "ciu_cache_sm_r CIU_WAIT ,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,1,0,1,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-"
ANNOTATION: "Unreachable as only two cases to make the state transition (warm reset and FW command) that won't hit WAIT instead of IDLE."
Branch 9 "3746149238" "ciu_cache_sm_r" (22) "ciu_cache_sm_r CIU_WAIT ,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,0,-,-,1,0,1,-,-,-,-,-,-,-,-,-,-,-,-,-"
CHECKSUM: "354253666 825816526"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_vtag
Branch 3 "800047430" "vtag_sm_r" (4) "vtag_sm_r MISSING_DEFAULT,-,-"
Branch 2 "632644451" "ciu_vtag_update" (4) "ciu_vtag_update 1,MISSING_DEFAULT"
CHECKSUM: "2796863742 123888985"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
Condition 28 "4032513255" "(cpu_mem_en && ((!cpu_mem_we))) 1 -1" (1 "01")
Condition 24 "686428720" "(pending_cpu_mem_write_r && cache_active_mode) 1 -1" (3 "11")
ANNOTATION: "Unreachable after fixing some other places"
Condition 24 "686428720" "(pending_cpu_mem_write_r && cache_active_mode) 1 -1" (2 "10")
ANNOTATION: "This one would be hit under current situation after a erview."
Condition 43 "1983024460" "((ciu_acc_vio && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ)) || cpu_access_upon_mpu_busy) 1 -1" (3 "10")
Condition 58 "215009831" "(sync_eng_erase_r && ((!mem_ciu_erase_busy_r))) 1 -1" (2 "10")
Condition 59 "1869272944" "(mem_ciu_erase_busy_r && mem_ciu_engn_erase_done) 1 -1" (1 "01")
Condition 41 "2390603907" "(cpu_mem_we && ( | cpu_mem_wr_byte_en )) 1 -1" (1 "01")
Condition 82 "310294137" "(cache_active_mode && vtag_cache_hit && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ) && ((!cache_miss_r))) 1 -1" (1 "0111")
Condition 71 "2554744547" "(cache_active_mode && cmu_mem_we) 1 -1" (1 "01")
Condition 86 "1397627517" "(valid_cpu_read || mem_rread || valid_cpu_write) 1 -1" (3 "010")
Condition 85 "1199105748" "((valid_cpu_read || mem_rread || valid_cpu_write) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE) && ((!mpu_busy))) 1 -1" (3 "110")
Condition 60 "1546265392" "(((!cmu_busy)) && ((!cpu_read_upon_erase_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((cpu_mem_en && ((!cpu_mem_we)) && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || pending_cpu_mem_read_r)) 1 -1" (1 "0111")
Condition 68 "643416086" "(cpu_mem_en && valid_cpu_mem_we && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) 1 -1" (1 "011")
Condition 12 "3190163338" "((sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE) && pending_cpu_mem_read_r) 1 -1" (1 "01")
Condition 13 "1228459919" "(sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE) 1 -1" (1 "0")
ANNOTATION: "This line will be 11 instead of 01 after review"
Condition 25 "1093175481" "(mpu_acc_vio || ext_acc_vio_r || other_error_r || ext_mem_erase_busy) 1 -1" (4 "0100")
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 29 "1555091249" "(cpu_mem_en && valid_cpu_mem_we) 1 -1" (1 "01")
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 44 "1016434546" "(ciu_acc_vio && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_MEM_READ)) 1 -1"
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 35 "1020672200" "(mpu_acc_vio || ext_acc_vio_r || other_error_r) 1 -1" (3 "010")
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 65 "4227742666" "(((!cmu_busy)) && ((!cpu_write_upon_erase_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((!cache_active_mode)) && ((cpu_mem_en && valid_cpu_mem_we && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || pending_cpu_mem_write_r)) 1 -1" (1 "01111")
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 54 "947957508" "(cpu_mem_en && valid_cpu_mem_we) 1 -1" (1 "01")
ANNOTATION: "Only have such combinations: either 10 or 11"
Condition 51 "389965862" "(cpu_mem_en && valid_cpu_mem_we) 1 -1" (1 "01")
ANNOTATION: "This line will be 11 instead of 01 after review"
Condition 26 "2222145539" "(mpu_acc_vio || ext_acc_vio_r) 1 -1" (2 "01")
ANNOTATION: "This line will be 11 instead of 01 after review"
Condition 18 "2440919963" "(mpu_acc_vio || ext_acc_vio_r) 1 -1" (2 "01")
CHECKSUM: "354253666 86165860"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_vtag
ANNOTATION: "The given tests for parity check passed for both success and fail."
Condition 2 "2913784820" "( ~^ data_in ) 1 -1" (1 "0")
CHECKSUM: "2796863742 3107236552"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
ANNOTATION: "Unreachable after fixing some other places"
Block 67 "1174229862" "nxt_pending_cpu_mem_write = 1'b0;"
ANNOTATION: "Unreachable after fixing some other places"
Block 66 "3715094042" "if ((pending_cpu_mem_write_r && cache_active_mode))"
ANNOTATION: "Unreachable as only two cases to make the state transition (warm reset and FW command) that won't hit WAIT instead of IDLE."
Block 90 "1118000513" "nxt_pending_cpu_access_upon_cache_failed = 1'b0;"
ANNOTATION: "Unreachable as only two cases to make the state transition (warm reset and FW command) that won't hit WAIT instead of IDLE."
Block 96 "191339905" "nxt_pending_cpu_access_upon_cache_failed = 1'b0;"
CHECKSUM: "3898638994 2129446375"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
ANNOTATION: "The given tests for parity check passed for both success and fail."
Branch 9 "3110176888" "ciu_cache_sm_r" (18) "ciu_cache_sm_r CIU_WAIT ,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,1,0,1,-,-,-,-,-,-,-,-,-,-,-,-,-"
ANNOTATION: "Only have such combinations: either 10 or 11"
Branch 9 "3110176888" "ciu_cache_sm_r" (7) "ciu_cache_sm_r CIU_IDLE ,0,-,0,-,0,-,-,1,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-"
CHECKSUM: "3898638994 2129446375"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
Condition 22 "3837274661" "(cpu_mem_en && ((!cpu_mem_we))) 1 -1" (1 "01")
Condition 22 "3837274661" "(cpu_mem_en && ((!cpu_mem_we))) 1 -1" (1 "01")
Condition 22 "3837274661" "(cpu_mem_en && ((!cpu_mem_we))) 1 -1" (1 "01")
CHECKSUM: "2039572270 2644001201"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
Condition 46 "867983715" "(cpu_mem_en && cpu_mem_we && cache_active_mode) 1 -1" (1 "011")
Condition 56 "3586286911" "(((!cmu_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((!cache_active_mode)) && ((cpu_mem_en && valid_cpu_mem_we && (sinc_ciu_fsm_t'(ciu_cache_sm_r) == CIU_IDLE)) || pending_cpu_mem_write_r)) 1 -1" (1 "0111")
Condition 27 "2892222312" "(cpu_mem_en && cpu_mem_we && ( | cpu_mem_wr_byte_en )) 1 -1" (1 "011")
Condition 27 "2892222312" "(cpu_mem_en && cpu_mem_we && ( | cpu_mem_wr_byte_en )) 1 -1" (2 "101")
CHECKSUM: "3617724345 1536763533"
INSTANCE: hdl_top.sinc.u_sinc_ciu.u_ciu_ctrl
Condition 52 "3344230533" "(((!cmu_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((!cache_active_mode)) && cpu_mem_en && valid_cpu_mem_we) 1 -1" (4 "11101")
Condition 52 "3344230533" "(((!cmu_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((!cache_active_mode)) && cpu_mem_en && valid_cpu_mem_we) 1 -1" (1 "01111")
Condition 48 "1703666554" "(((!cmu_busy)) && ((!cpu_read_upon_erase_busy)) && (sinc_state_t'(cmu_sinc_state) != CACHE_FAILED) && ((cpu_mem_en && ((!cpu_mem_we))) || pending_cpu_mem_read_r)) 1 -1" (1 "0111")
