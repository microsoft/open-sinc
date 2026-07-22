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
// File        : sinc_ramwrap_user_params_pkg.sv
// Description : 

`ifndef SINC_RAMWRAP_USER_PARAMS_PKG
`define SINC_RAMWRAP_USER_PARAMS_PKG

//---------------------------------------------------------------------------//
// This example code shows how to specify the configuration parameters for   //
// one instantiation of ramwrap system. The user needs to instantiate        //
// one ramwrap system per clock domain.                                      //
//---------------------------------------------------------------------------//

package ramwrap_user_params_pkg;
    `ifdef SIMULATION
    import uvm_pkg::*;
    `endif
    import ramwrap_sys_params_pkg::*;

    // Decide the number of RAMWRAP systems needed; each clock domain
    // needs one RAMWRAP system.  In this simplistic example, we will have only
    // one system.
    parameter num_ramwrap_sys = 1;

    // Create an enumerated type that can be used to index through
    // the parameter arrays for each RAMWRAP system.
    // Create a unique name for each RAMWRAP system; in this example
    // there is only one system; please keep this short since all
    // parameters for each RAMWRAP system will have the sysname prefixed
    // so that the configuration routine can match up the correct
    // system with the parameter names.  Note: sysname is the string
    // equivalent of the enumerated values which can be got by using
    // the .name() SV function on the enumerated variable.
    typedef enum byte unsigned {
        RAMWRAPMS // RAMWRAP Member Scope
    } ramwrap_sys_names_t;

    parameter ramwrap_sys_params_t ramwrap_sys_params[num_ramwrap_sys] =
        '{
            //===================================================================//
            // Parameters for RAMWRAP System "RAMWRAPMS"                                 //
            //===================================================================//
            '{
                sys_id: RAMWRAPMS,
                `ifdef SIMULATION
                sys_name: "RAMWRAPMS",
                // Need to provide UVM hierarchical paths to the UVM Agents
                uvm_path: "*.ramwrap_sys_env0",
                hdl_path: "hdl_top.ramwrap_sys_inst",
                `endif
                // First specify how many sub agents are present in the system.
                // These numbers should come from the TB config that needs the maximum
                // number of the sub agents.  Then based on TB config you can
                // individually enable the required agents alone using the
                // *_en parameters below.
                num_engine_agents: 0,
                num_erase_agents: 2,
                num_mem_agents: 2,
                num_inject_agents: 2,

                // Enable only the required masters based on TB Config using "CONF_HAS__"
                // defines; in this simple case, the master is always enabled.
                // The RAMWRAP_MAX_NUM_MASTERS macro must be defined per config and it will
                // the same for all the RAMWRAP systems used in that config.  Since the
                // parameter structures use this define to size the arrays for master_en
                // and master_params, all the elements of the array need
                // to be specified, irrespective of the value of num_masters for a given
                // RAMWRAP system.  This is additional overhead; however this is better compared
                // writing lots of lines of code in the create_config function.
                // The default value of RAMWRAP_MAX_NUM_MASTERS macro is defined to be 4, so that
                // an example of specifying the overhead is given here.
                engine_agent_en:
                '{
                    1, 1
                },

                //---------------------------------------------------------------------//
                // Per-Agent Configuation:                                             //
                // Embedding the example code directly here for this simple case.      //
                // This code should be auto-generated using script based on DUT        //
                // characteristics and included using `include here.                   //
                //---------------------------------------------------------------------//

                //-------------------------Masters-Configuration-----------------------//
                engine_params: // Start-engine_agent_params
                '{
                    //ENGINE0_params - Cache Sram RamWrapper
                    '{
                        client_num : 0,

                        client_name: "CACHE_MEM_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_PASSIVE,

                        // address width
                        addr_width: 14,
                        // data width
                        data_width: 156,
                        // support erase
                        support_erase: 1,
                        // support RMW
                        support_rmw:1,

                        support_rmw_pipeline: 0, //FIXME: USE DEFINE once TB is ready

                        support_write_back: 0, //FIXME:USE DEFINE once TB is ready

                        support_parity: 0, //FIXME: USE DEFINE once TB is ready

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    }, //End-ENGINE0_params
                    //ENGINE1_params - Cache VTAG RamWrapper
                    '{
                        client_num : 1,

                        client_name: "CACHE_VTAG_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_PASSIVE,

                        // address width
                        addr_width: 7,
                        // data width
                        data_width: 40,
                        // support erase
                        support_erase: 1,
                        // support RMW
                        support_rmw:1,

                        support_rmw_pipeline: 0, //FIXME: USE DEFINE once TB is ready

                        support_write_back: 0, //FIXME:USE DEFINE once TB is ready

                        support_parity:1, //FIXME: USE DEFINE once TB is ready

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    } //End-ENGINE1_params
                }, //End-engine_agent_params

                erase_agent_en:
                '{
                    1, 1
                },

                //---------------------------------------------------------------------//
                // Per-Agent Configuation:                                             //
                // Embedding the example code directly here for this simple case.      //
                // This code should be auto-generated using script based on DUT        //
                // characteristics and included using `include here.                   //
                //---------------------------------------------------------------------//

                //-------------------------Masters-Configuration-----------------------//
                erase_params: // Start-erase_agent_params
                '{
                    //ERASE0_params - Cache MEM
                    '{
                        client_num : 0,

                        client_name: "CACHE_MEM_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_ACTIVE,

                        erase_start_addr: `MSFT_SP_CIRAM0_ERASE_START_ADDR,
                        // end address
                        erase_end_addr: `MSFT_SP_CIRAM0_ERASE_END_ADDR,
                        // start address
                        engn_erase_start_addr: `MSFT_SP_CIRAM0_ENGN_ERASE_START_ADDR,
                        // end address
                        engn_erase_end_addr: `MSFT_SP_CIRAM0_ENGN_ERASE_END_ADDR,
                        // data width
                        data_width: `MSFT_SP_CIRAM0_LOGICAL_MEM_WIDTH,
                        // support erase
                        support_erase: `MSFT_SP_CIRAM0_SUPPORT_ERASE,

                        support_engn_erase: `MSFT_SP_CIRAM0_SUPPORT_ENGN_ERASE,
                        // erase data
                        erase_data_type: "RANDOM",
                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4,
                        // Extended Misc port
                        support_trivium_erase: 1
                    }, //End-ERASE0_params
                    //ERASE1_params - Cache VTAG
                    '{
                        client_num : 1,

                        client_name: "CACHE_VTAG_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_PASSIVE,

                        erase_start_addr: 0,
                        // end address
                        erase_end_addr: 'h7f0,
                        // start address
                        engn_erase_start_addr: 0,
                        // end address
                        engn_erase_end_addr: 'h7f0,
                        // data width
                        data_width: 40,
                        // support erase
                        support_erase: 0,

                        support_engn_erase: 1,
                        // erase data
                        erase_data_type: "RANDOM",
                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4,
                        // Extended Misc port
                        support_trivium_erase: 1
                    } //End-ERASE1_params
                }, //End-erase_agent_params

                // Enable only the required masters based on TB Config using "CONF_HAS__"
                // defines; in this simple case, the master is always enabled.
                // The RAMWRAP_MAX_NUM_MASTERS macro must be defined per config and it will
                // the same for all the RAMWRAP systems used in that config.  Since the
                // parameter structures use this define to size the arrays for master_en
                // and master_params, all the elements of the array need
                // to be specified, irrespective of the value of num_masters for a given
                // RAMWRAP system.  This is additional overhead; however this is better compared
                // writing lots of lines of code in the create_config function.
                // The default value of RAMWRAP_MAX_NUM_MASTERS macro is defined to be 4, so that
                // an example of specifying the overhead is given here.
                mem_agent_en:
                '{
                    1, 1
                },

                //---------------------------------------------------------------------//
                // Per-Agent Configuation:                                             //
                // Embedding the example code directly here for this simple case.      //
                // This code should be auto-generated using script based on DUT        //
                // characteristics and included using `include here.                   //
                //---------------------------------------------------------------------//

                //-------------------------Masters-Configuration-----------------------//
                mem_params: // Start-engine_agent_params
                '{
                    //MEM0_params - Cache MEM
                    '{
                        client_num : 0,

                        client_name: "CACHE_MEM_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_PASSIVE,

                        // address width
                        addr_width: `MSFT_SP_CIRAM0_ADDR_WIDTH,
                        // data width
                        data_width: `MSFT_SP_CIRAM0_DATA_WIDTH,

                        support_secded: 1,

                        support_scrambling: 1,

                        shuffling_arr: '{0}, //FIXME

                        inversion_arr: '{0}, //FIXME

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    }, //End-MEM0_params
                    //MEM1_params - Cache VTAG
                    '{
                        client_num : 1,

                        client_name: "CACHE_VTAG_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_PASSIVE,

                        // address width
                        addr_width: 7,
                        // data width
                        data_width: 40,

                        support_secded: 1,

                        support_scrambling: 1,

                        shuffling_arr: '{0}, //FIXME

                        inversion_arr: '{0}, //FIXME

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    } //End-MEM1_params
                }, //End-engine_agent_params

                inject_agent_en:
                '{
                    1, 1
                },

                //-------------------------Masters-Configuration-----------------------//
                inject_params: // Start-inject_agent_params
                '{
                    //INJECT0_params - CACHE MEM
                    '{
                        client_num : 0,

                        client_name: "CACHE_MEM_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_ACTIVE,

                        // start address
                        start_addr: `MSFT_SP_CIRAM0_ERASE_START_ADDR,
                        // end address
                        end_addr: `MSFT_SP_CIRAM0_ERASE_END_ADDR,
                        // data width
                        data_width: `MSFT_SP_CIRAM0_LOGICAL_MEM_WIDTH,
                        // support erase
                        support_inject: 1,
                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    }, //End-INJECT0_params
                    //INJECT1_params - CACHE VTAG
                    '{
                        client_num : 1,

                        client_name: "CACHE_MEM_RAMWRAPPER",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_ACTIVE,

                        // start address
                        start_addr: 0,
                        // end address
                        end_addr: 'h7f0,
                        // data width
                        data_width: 40,
                        // support erase
                        support_inject: 1,
                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    } //End-INJECT1_params
                } //End-erase_agent_params
            } //End-RAMWRAPMS_params
        }; //End-All_RAMWRAP_params

endpackage : ramwrap_user_params_pkg

`endif // SINC_RAMWRAP_USER_PARAMS_PKG
