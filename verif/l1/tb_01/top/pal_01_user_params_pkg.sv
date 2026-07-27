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
// File        : pal_01_user_params_pkg.sv
// Description : MSFT Protocol Abstraction Layer

`ifndef PAL_USER_PARAMS_PKG
`define PAL_USER_PARAMS_PKG

//---------------------------------------------------------------------------//
// This example code shows how to specify the configuration parameters for   //
// one instantiation of pal system.  However, the user needs to instantiate  //
// one pal system per clock domain.
//---------------------------------------------------------------------------//

package pal_user_params_pkg;
  `ifdef SIMULATION
  import uvm_pkg::*;
  `endif
  import pal_params_pkg::*;
  import sinc_parameters_pkg::*;

  // Decide the number of PAL systems needed; each clock domain
  // needs one PAL system.  In this simplistic example, we will have only
  // one system.
  parameter num_pal_sys = 1;

  // Create an enumerated type that can be used to index through
  // the parameter arrays for each PAL system.
  // Create a unique name for each PAL system; in this example
  // there is only one system; please keep this short since all
  // parameters for each PAL system will have the sysname prefixed
  // so that the configuration routine can match up the correct
  // system with the parameter names.  Note: sysname is the string
  // equivalent of the enumerated values which can be got by using
  // the .name() SV function on the enumerated variable.
  typedef enum byte unsigned {
    PALEX
  } pal_sys_names_t;

  parameter pal_sys_params_t pal_sys_params[num_pal_sys] =
    '{
      //===================================================================//
      // Parameters for PAL System "PALEX"                                 //
      //===================================================================//
      '{
        sys_id: PALEX,
        `ifdef SIMULATION
        sys_name: "PALEX",
        // Need to provide UVM hierarchical paths to the UVM Agents
        uvm_path: "*.pal_env0",
        hdl_path: "hdl_top.pal_axi_sys_inst",
        `endif
        // First specify how many masters and slaves are present in the system.
        // These numbers should come from the TB config that needs the maximum
        // number of masters and/or slaves.  Then based on TB config you can
        // individually enable the required masters and slaves alone using the
        // master_en and slave_en parameters below.
        num_masters: 1,
        num_slaves: 1,

        `ifdef PAL_USE_PAXOS_AXI_SLAVE
        // Identify the master that is supposed to configure the PAXOS Slave
        // This could be different for different TB config using "CONF_HAS__"
        // defines.
        paxos_cfg_master_num: 0,
        `endif //PAL_USE_PAXOS_AXI_SLAVE

        // Enable only the required masters based on TB Config using "CONF_HAS__"
        // defines; in this simple case, the master is always enabled.
        // The PAL_MAX_NUM_MASTERS macro must be defined per config and it will
        // the same for all the PAL systems used in that config.  Since the
        // parameter structures use this define to size the arrays for master_en
        // and master_params, all the elements of the array need
        // to be specified, irrespective of the value of num_masters for a given
        // PAL system.  This is additional overhead; however this is better compared
        // writing lots of lines of code in the create_config function.
        // The default value of PAL_MAX_NUM_MASTERS macro is defined to be 4, so that
        // an example of specifying the overhead is given here.
        master_en:
        '{
          1
        },

        // Enable only the required slaves based on TB Config using "CONF_HAS__"
        // defines; in this simple case, the slave is always enabled.
        // The PAL_MAX_NUM_SLAVES macro must be defined per config and it will
        // the same for all the PAL systems used in that config.  Since the
        // parameter structures use this define to size the arrays for slave_en
        // and slave_params, all the elements of the array need
        // to be specified, irrespective of the value of num_slaves for a given
        // PAL system.  This is additional overhead; however this is better compared
        // writing lots of lines of code in the create_config function.
        // The default value of PAL_MAX_NUM_SLAVES macro is defined to be 4, so that
        // an example of specifying the overhead is given here.
        slave_en:
        '{
          1
        },

        // Specify the type of master agents based on the TB Configuration
        // To use the default master type based on VIP code inclusion defines,
        // you can use `default_master_type_define; user can also select any type of
        // master here by specifying any valid value from the enumerated type
        // pal_master_type_t
        master_type:
        '{
          /*
           //`default_master_type gives you this:
           `ifdef PAL_USE_SNPS_AXI_VIP
           SNPS_AXI_MASTER,
           `else
           MSFT_AXI_MASTER,
           `endif
           */
          `default_master_type_define
        },

        // Specify the type of slave agents based on the TB Configuration
        // To use the default slave type based on VIP code inclusion defines,
        // you can use `default_slave_type_define; user can also select any type of
        // master here by specifying any valid value from the enumerated type
        // pal_slave_type_t
        slave_type:
        '{
          /*
           //`default_slave_type gives you this:
           `ifdef PAL_USE_PAXOS_AXI_SLAVE
           PAXOS_AXI_SLAVE
           `else
           `ifdef PAL_USE_SNPS_AXI_VIP
           SNPS_AXI_SLAVE
           `else
           PAXOS_AXI_SLAVE
           `endif
           `endif
           */
          `default_slave_type_define
        },

        //---------------------------------------------------------------------//
        // Per-Agent Configuation:                                             //
        // Embedding the example code directly here for this simple case.      //
        // This code should be auto-generated using script based on DUT        //
        // characteristics and included using `include here.                   //
        //---------------------------------------------------------------------//

        //-------------------------Masters-Configuration-----------------------//
        master_params:
        '{
          //Master 0
          '{
            client_num : 0,

            // Helps to name the client so that the debug messages can carry these
            // names.  Also used to parse plusargs for each master.  The plusargs
            // for any master should follow this convention:
            // <sysname>_<m_client_name>_<parameter_name>
            `ifdef SIMULATION
            client_name: "M0",

            // Set the Active/Passive mode based on TB Config using "CONF_HAS__"
            // defines; in this simple case, it is set to active all the time.
            is_active: UVM_ACTIVE,
            `endif

            // Read-Only OR Write-Only or Read-Write
            dir_type: PAL_DIR_READ_WRITE,

            // Signal widths
            addr_width: 32,
            // Wr Burst Length Width
            wr_len_width: 8,
            // Rd Burst Length Width
            rd_len_width: 8,
            // Maximum supported Wr Burst Length based on design limitation
            // Also depends on bus width of the AWLEN signal
            max_wr_blen: 256,
            // Maximum supported Rd Burst Length based on design limitation
            // Also depends on bus width of the ARLEN signal
            max_rd_blen: 256,
            // Write TagID Width
            wr_tag_id_width: `HSP_AXI_SLV_ID_WIDTH,
            // Maximum supported Wr Tag ID based on design limitation
            // Also depends on bus width of the AWID signal
            max_wr_tag_id: ((2 ** `HSP_AXI_SLV_ID_WIDTH) - 1),
            // Read TagID Width
            //rd_tag_id_width: 7,
            rd_tag_id_width: `HSP_AXI_SLV_ID_WIDTH,
            // Maximum supported Rd Tag ID based on design limitation
            // Also depends on bus width of the ARID signal
            max_rd_tag_id: ((2 ** `HSP_AXI_SLV_ID_WIDTH) - 1),
            // Wr Data Bus Width
            wr_bus_width_in_bytes: `HSP_AXI_SLV_DWIDTH / 8,
            // Rd Data Bus Width
            rd_bus_width_in_bytes: `HSP_AXI_SLV_DWIDTH / 8,
            // Max Wr Burst Length * Wr Data Bus Width in bytes
            max_wr_size_in_bytes: 64,
            // Max Rd Burst Length * Rd Data Bus Width in bytes
            max_rd_size_in_bytes: 64,
            // ARUSER signal width
            aruser_width: `PAL_MAX_ADDR_USER_WIDTH,
            // AWUSER signal width
            awuser_width: `PAL_MAX_ADDR_USER_WIDTH,
            `ifdef MS_AXI_EXTENSION
            `ifndef PAL_USE_PAXOS_AXI_SLAVE
            ruser_width: `MSFT_AXI_SLV_RU_WIDTH,
            wuser_width: `MSFT_AXI_SLV_WU_WIDTH,
            buser_width: `MSFT_AXI_SLV_BU_WIDTH,

            //All of these are example configs.
            awuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            wuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            buser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            aruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            ruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            num_outstanding_wr_trans: 0,
            num_outstanding_rd_trans: 0,

            `else
            ruser_width: `MSFT_AXI_SLV_RU_WIDTH,
            wuser_width: `MSFT_AXI_SLV_WU_WIDTH,
            buser_width: `MSFT_AXI_SLV_BU_WIDTH,

            awuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            wuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            buser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            aruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            ruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            // These parameters are not used by PAXOS.
            // These numbers should match the wr_output_queue_depth
            // and rd_input_queue_depth params of PAXOS respectively
            // to represent the reality.
            num_outstanding_wr_trans: 0,
            num_outstanding_rd_trans: 0,
            `endif
            `endif
            // AXI Page boundary is 4 KBytes; allows to specify a smaller value
            // based on design limitation, if any.
            lin_page_mask: 16'h00ff, //4K boundary
            // Number of outstanding transactions.
            num_outstanding_trans: 4,
            // Number of cycles to wait after reset before
            // launching the first transaction.
            reset_recovery_cycles: 4
          } //End-Master0_params

        }, //End-Master_params

        //--------------------------Slaves-Configuration-----------------------//
        slave_params:
        '{
          //Slave 0
          '{
            client_num : 0,
            `ifdef SIMULATION
            client_name: "S0",
            // Set the Acite/Passive mode based on TB Config using "CONF_HAS__"
            // defines; in this simple case, it is set to active all the time.
            is_active: UVM_ACTIVE,
            `endif

            // Read-Only OR Write-Only or Read-Write
            dir_type: PAL_DIR_READ_WRITE,

            num_regions: 4,
            // Signal widths
            addr_width: 32,
            // Wr Burst Length Width
            wr_len_width: 8,
            // Rd Burst Length Width
            rd_len_width: 8,
            // Maximum supported Wr Burst Length based on design limitation
            // Also depends on bus width of the AWLEN signal
            max_wr_blen: 256,
            // Maximum supported Rd Burst Length based on design limitation
            // Also depends on bus width of the ARLEN signal
            max_rd_blen: 256,
            // Write TagID Width
            wr_tag_id_width: 1,
            // Maximum supported Wr Tag ID based on design limitation
            // Also depends on bus width of the AWID signal
            max_wr_tag_id: '1,
            // Read TagID Width
            rd_tag_id_width: 1,
            // Maximum supported Rd Tag ID based on design limitation
            // Also depends on bus width of the ARID signal
            max_rd_tag_id: '1,
            // Wr Data Bus Width
            wr_bus_width_in_bytes: 4,
            // Rd Data Bus Width
            rd_bus_width_in_bytes: 4,
            // Max Wr Burst Length * Wr Data Bus Width in bytes
            max_wr_size_in_bytes: 64,
            // Max Rd Burst Length * Rd Data Bus Width in bytes
            max_rd_size_in_bytes: 64,
            // ARUSER signal width
            aruser_width: `PAL_MAX_ADDR_USER_WIDTH,
            // AWUSER signal width
            awuser_width: `PAL_MAX_ADDR_USER_WIDTH,

            `ifdef MS_AXI_EXTENSION
            ruser_width: `MSFT_AXI_SLV_RU_WIDTH,
            wuser_width: `MSFT_AXI_SLV_WU_WIDTH,
            buser_width: `MSFT_AXI_SLV_BU_WIDTH,

            //All of these are example configs.
            awuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            wuser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            buser_func: '{
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0} },

            aruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0},
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            ruser_func: '{
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 },
              '{func: NOTUSED, msb:0, lsb:0 } },

            num_outstanding_wr_trans: 0,
            num_outstanding_rd_trans: 0,
            `endif

            // AXI Page boundary is 4 KBytes; allows to specify a smaller value
            // based on design limitation, if any.
            lin_page_mask: 16'h00ff, //4K boundary
            `ifdef PAL_USE_PAXOS_AXI_SLAVE
            //Paxos general settings
            start_addr_config: 64'hAF08_0000,
            end_addr_config: 64'hAF08_03ff,
            mem_size: 2**30,
            wr_input_num_queues: 8,
            wr_input_queue_depth: 32,
            rd_input_queue_depth: 32,
            wr_output_queue_depth: 32,
            rd_output_queue_depth: 64,
            wrap_en: 1,
            //Paxos performance monitor settings
            perf_mon_en: 0,
            latency_window_size: 20,
            bandwidth_window_size: 1000,
            histogram_min: 0,
            histogram_max: 200,
            `else
            // Number of outstanding transactions.
            num_outstanding_trans: 1,
            `endif //PAL_USE_PAXOS_AXI_SLAVE
            //----Per-Region-Parameters----//
            //Although this example uses only two regions,
            //the PAL_MAX_NUM_SLAVE_REGIONS macro is common
            //for all the PAL systems in a config and hence
            //can be bigger (upto 16).  Since all the members
            //need to be defined here per SV rules, we are showing
            //an example of how to define dummy parameters for
            //unused members of the array; in this example config
            //PAL_MAX_NUM_SLAVE_REGIONS is set to 16; thus there
            //are 14 dummy elements.
            region_params:
            //     Example: default PAL_MAX_NUM_SLAVE_REGIONS=16
            //     Two regions are configured
            '{
              //Region 0
              '{
                start_addr: sinc_parameters_pkg::SINC_DMB_START_ADDR, //External MEM 32'h9000_0000
                end_addr: sinc_parameters_pkg::SINC_DMB_END_ADDR // 32'hFFFF_FFFF
              },
              //Region 1
              '{
                start_addr: 32'h8F0A_0000, // RNG - hardcoded from a prior project HSP_ADDR_MAP_RNG_OFFSET
                end_addr: 32'h8F0A_0000 + (4 * 1024) - 'h1 // find end address
              },
              //Region 2
              '{
                start_addr: 32'h8F0C_4000, // KSU - hardcoded from a prior project HSP_ADDR_MAP_KSB_KEYS_ADDRESS
                end_addr: 32'h8F0C_4000 + 'h1FFF// 63 keys + padding
              },
              //Region 3
              '{
                start_addr: 32'h8F02_0000, // SHAREDRAM - hardcoded from a prior project HSP_ADDR_MAP_SHAREDRAM_ADDRESS
                end_addr: 32'h8F02_0000 + 'h0_FFFF // 32'h8f030000
              },
              // others are not configured
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params,
              `dummy_slave_region_params
            } //End-region_params
          } //End-Slave0
        } //End-Slave_params
      } //End-PALEX_params
    }; //End-All_PAL_params

endpackage : pal_user_params_pkg

`endif // PAL_USER_PARAMS_PKG
