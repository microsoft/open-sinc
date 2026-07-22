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
// File        : sinc_ccpui_user_params_pkg.sv
// Description : 

`ifndef SINC_CCPUI_USER_PARAMS_PKG
`define SINC_CCPUI_USER_PARAMS_PKG

//---------------------------------------------------------------------------//
// This example code shows how to specify the configuration parameters for   //
// one instantiation of ccpui system. The user needs to instantiate        //
// one ccpui system per clock domain.                                      //
//---------------------------------------------------------------------------//

// FIXME-HW: use sinc_ccpui_user_params
package ccpui_user_params_pkg;
    `ifdef SIMULATION
    import uvm_pkg::*;
    `endif
    import ccpui_sys_params_pkg::*;

    // Decide the number of CCPUI systems needed; each clock domain
    // needs one CCPUI system.  In this simplistic example, we will have only
    // one system.
    parameter num_ccpui_sys = 1;

    // Create an enumerated type that can be used to index through
    // the parameter arrays for each CCPUI system.
    // Create a unique name for each CCPUI system; in this example
    // there is only one system; please keep this short since all
    // parameters for each CCPUI system will have the sysname prefixed
    // so that the configuration routine can match up the correct
    // system with the parameter names.  Note: sysname is the string
    // equivalent of the enumerated values which can be got by using
    // the .name() SV function on the enumerated variable.
    typedef enum byte unsigned {
        CCPUIMS // CCPUI Member Scope
    } ccpui_sys_names_t;

    parameter ccpui_sys_params_t ccpui_sys_params[num_ccpui_sys] =
        '{
            //===================================================================//
            // Parameters for CCPUI System "CCPUIMS"                                 //
            //===================================================================//
            '{
                sys_id: CCPUIMS,
                sys_name: "CCPUIMS",
                // Need to provide UVM hierarchical paths to the UVM Agents
                uvm_path: "*.ccpui_sys_env0",
                hdl_path: "hdl_top.ccpui_sys_inst",
                // First specify how many sub agents are present in the system.
                // These numbers should come from the TB config that needs the maximum
                // number of the sub agents.  Then based on TB config you can
                // individually enable the required agents alone using the
                // *_en parameters below.
                num_cpu_mem_agents: 1,
                num_mpu_agents: 1,

                // Enable only the required masters based on TB Config using "CONF_HAS__"
                // defines; in this simple case, the master is always enabled.
                // The CCPUI_MAX_NUM_MASTERS macro must be defined per config and it will
                // the same for all the CCPUI systems used in that config.  Since the
                // parameter structures use this define to size the arrays for master_en
                // and master_params, all the elements of the array need
                // to be specified, irrespective of the value of num_masters for a given
                // CCPUI system.  This is additional overhead; however this is better compared
                // writing lots of lines of code in the create_config function.
                // The default value of CCPUI_MAX_NUM_MASTERS macro is defined to be 4, so that
                // an example of specifying the overhead is given here.
                cpu_mem_agent_en:
                '{
                    1'b1
                },

                mpu_agent_en:
                '{
                    1'b1
                },

                //---------------------------------------------------------------------//
                // Per-Agent Configuation:                                             //
                // Embedding the example code directly here for this simple case.      //
                // This code should be auto-generated using script based on DUT        //
                // characteristics and included using `include here.                   //
                //---------------------------------------------------------------------//

                //-------------------------Component-Configuration-----------------------//
                cpu_mem_params: // Start-cpu_mem_agent_params
                '{
                    //CPU_MEM0_params
                    '{
                        client_num : 0,

                        client_name: "CORE_CPU_MEM",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_ACTIVE,

                        // when force is enabled, driver can do back to back requests with blocking force statement,
                        // otherwise there has to be 1 cycle delay between transactions due to Busy
                        enable_force: 1,

                        // address width
                        addr_width: 22,
                        // data width
                        data_width: 32,

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    } //End-CPU_MEM0_params
                }, //End-cpu_mem_agent_params

                mpu_params: // Start-mpu_agent_params
                '{
                    //MPU0_params
                    '{
                        client_num : 0,

                        client_name: "CORE_MPU",

                        // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
                        // defines; in this simple case, it is set to active all the time.
                        is_active: UVM_ACTIVE,

                        // address width
                        addr_width: 13,
                        // data width
                        data_width: 32,
                        // EIRAM_SIZE/4 - 16KB - 4K pages
                        mpu_pages: 4096,

                        // Number of cycles to wait after reset before
                        // launching the first transaction.
                        reset_recovery_cycles: 4
                    } //End-MPU0_params
                } //End-mpu_agent_params
            } //End-CCPUIMS_params
        }; //End-All_CCPUI_params

endpackage : ccpui_user_params_pkg

`endif // SINC_CCPUI_USER_PARAMS_PKG
