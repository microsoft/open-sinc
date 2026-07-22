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
// File        : hdl_top.sv
// Description : This top level module instantiates all synthesizable

`ifndef SINC_HDL_TOP
`define SINC_HDL_TOP

`include "tb_pal_if.sv"
`include "peek_poke.sv"
`include "peek_poke_if.sv"
`include "clk_interface.sv"
`include "rst_interface.sv"
`include "sideband_interface.svh"
`include "sinc_v_if.svh"
`include "sinc_mem_bkdoor_if.svh"

module hdl_top;

  import sinc_parameters_pkg::*;
  import uvmf_base_pkg_hdl::*;
  import pal_user_params_pkg::*;
  import ramwrap_user_params_pkg::*;
  import ccpui_user_params_pkg::*;

  // pragma uvmf custom clock_generator begin
  logic        cpl_hspclk;
  logic        rtc_clk;
  logic        cpl_msp1clk;
  logic        cpl_refclk;
  logic        ro_clk;
  logic        clkg_override;
  logic        tck;
  logic [31:0] hsp_spare6_fuse_control_timebase = '0;
  logic        hcpul_xpc_halt                   = 1;

  // CACHE IRAM
  logic                                                      cache_mem_ck;
  logic [sinc_parameters_pkg::SINC_CACHE_MEM_ADDR_WIDTH:0]   cache_mem_addr_w;
  logic                                                      cache_mem_we_w;
  logic                                                      cache_mem_cs_w;
  logic [sinc_parameters_pkg::SINC_CACHE_MEM_DATA_WIDTH-1:0] cache_mem_din_w;
  logic [sinc_parameters_pkg::SINC_CACHE_MEM_DATA_WIDTH-1:0] cache_mem_dout_w;

  // CACHE VTAG
  logic                                                       cache_vtag_ck;
  logic [sinc_parameters_pkg::SINC_CACHE_VTAG_ADDR_WIDTH:0]   cache_vtag_addr_w;
  logic [3:0]                                                 cache_vtag_we_w;
  logic [3:0]                                                 cache_vtag_cs_w;
  logic [sinc_parameters_pkg::SINC_CACHE_VTAG_DATA_WIDTH-1:0] cache_vtag_din_w;
  logic [sinc_parameters_pkg::SINC_CACHE_VTAG_DATA_WIDTH-1:0] cache_vtag_dout_w;

  logic                                  mem_err_uncorr_o;
  logic [`MSFT_SP_CIRAM0_ADDR_WIDTH-1:0] mem_err_addr_o;
  logic [2:0]                            mem_err_corr_o;

  clk_interface clk_if (
    .rtc_clk                         ( rtc_clk                         ),
    .Cpl_HSPCLK                      ( cpl_hspclk                      ),
    .Cpl_MSP1CLK                     ( cpl_msp1clk                     ),
    .Cpl_REFCLK                      ( cpl_refclk                      ),
    .TCK                             ( tck                             ),
    .ro_clk                          ( ro_clk                          ),
    .clkg_override                   ( clkg_override                   ),
    .hsp_spare6_fuse_control_timebase( hsp_spare6_fuse_control_timebase),
    .hcpul_xpc_halt                  ( hcpul_xpc_halt                  )
  );

  // pragma uvmf custom clock_generator end

  // pragma uvmf custom reset_generator begin
  logic hsp_resetn_hspclk;
  rst_interface rst_if ( .clk(cpl_hspclk), .rstn(hsp_resetn_hspclk) );
  // pragma uvmf custom reset_generator end

  //----------------------------------------------------------------
  // Protocol Abstraction Layer (PAL)
  // PAL axi system interface One instance needed per clock domain.
  //----------------------------------------------------------------
  pal_axi_sys_if #( .num_masters(pal_user_params_pkg::pal_sys_params[PALEX].num_masters),
                    .num_slaves (pal_user_params_pkg::pal_sys_params[PALEX].num_slaves )
  )
  axi_sys_if (cpl_hspclk, hsp_resetn_hspclk);

  // Instantiate peek_poke module for backdoor access (one per TB)
  peek_poke peek_poke();

  // Instantiate the peek_poke interface for backdoor access from UVM
  // This is just one instance per TB i.e., common for
  // all the PAL systems in a TB.
  peek_poke_if peek_poke_if();

  // Instantiate the pal axi system module
  // One instance needed per clock domain.
  // The mapped parameters come from pal_user_params_pkg
  pal_axi_sys #( .sys_params(pal_user_params_pkg::pal_sys_params[PALEX])
  )
  pal_axi_sys_inst ( axi_sys_if );

  //----------------------------------------------------------------
  // RAMWRAP SYS Environment Layer BEGIN
  // ramwrap system interface One instance needed per clock domain.
  //----------------------------------------------------------------
  ramwrap_sys_if #( .num_engines  (ramwrap_user_params_pkg::ramwrap_sys_params[RAMWRAPMS].num_engine_agents),
                    .num_erases   (ramwrap_user_params_pkg::ramwrap_sys_params[RAMWRAPMS].num_erase_agents ),
                    .num_memifs   (ramwrap_user_params_pkg::ramwrap_sys_params[RAMWRAPMS].num_mem_agents   ),
                    .num_injectifs(ramwrap_user_params_pkg::ramwrap_sys_params[RAMWRAPMS].num_inject_agents)
  )
  ramwrap_sys_if (cpl_hspclk, hsp_resetn_hspclk);

  // Instantiate the ramwrap system module
  // One instance needed per clock domain.
  // The mapped parameters come from ramwrap_user_params_pkg
  ramwrap_sys #( .sys_params(ramwrap_user_params_pkg::ramwrap_sys_params[RAMWRAPMS])
  )
  ramwrap_sys_inst ( ramwrap_sys_if );

  //----------------------------------------------------------------
  // RAMWRAP SYS Environment Layer END
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // GPAES SYS Environment Layer BEGIN
  // gpaes system interface One instance needed per clock domain.
  //----------------------------------------------------------------
  gpaes_sys_if m_gpaes_sys_if (cpl_hspclk, hsp_resetn_hspclk);

  // Instantiate the gpaes system module
  // One instance needed per clock domain.
  // The mapped parameters come from gpaes_user_params_pkg
  gpaes_sys #( .uvm_path_inst(sinc_parameters_pkg::SINC_GPAES_UVM_PATH_INST),
	       .SYS_NAME(sinc_parameters_pkg::SINC_GPAES_SYS_NAME)
  )
  gpaes_sys_inst ( m_gpaes_sys_if );

  //----------------------------------------------------------------
  // GPAES SYS Environment Layer END
  //----------------------------------------------------------------

  //----------------------------------------------------------------
  // CCPUI SYS Environment Layer BEGIN
  // ccpui system interface One instance needed per clock domain.
  //----------------------------------------------------------------
  ccpui_sys_if #( .num_cpu_mems(ccpui_user_params_pkg::ccpui_sys_params[CCPUIMS].num_cpu_mem_agents),
                  .num_mpus    (ccpui_user_params_pkg::ccpui_sys_params[CCPUIMS].num_mpu_agents    )
  )
  ccpui_sys_if (cpl_hspclk, hsp_resetn_hspclk);

  // Instantiate the ccpui system module
  // One instance needed per clock domain.
  // The mapped parameters come from ccpui_user_params_pkg
  ccpui_sys #( .sys_params(ccpui_user_params_pkg::ccpui_sys_params[CCPUIMS])
  )
  ccpui_sys_inst ( ccpui_sys_if );

  //----------------------------------------------------------------
  // CCPUI SYS Environment Layer END
  //----------------------------------------------------------------

  // TB IF for TB Status
  tb_pal_if tb_if();

  // Key Vault virtual interface
  sinc_v_if sinc_v_if
  (
    .clk   (cpl_hspclk       ),
    .resetn(hsp_resetn_hspclk)
  );

  // DUT Instance
  sinc_top #(
`ifdef SINC_WITH_NO_SEED_LOADING
    .NO_SEED_LOADING       (SINC_NO_SEED_LOADING                  ),
`endif
    .DATA_WIDTH            (32                                    ),
    .EIRAM_SIZE            (`MSFT_SP_EIRAM0_SIZE/1024             ),
    .ADDR_WIDTH            (`MSFT_SP_EIRAM0_ADDR_WIDTH            ),
    .CACHE_MEM_WIDTH       (`MSFT_SP_CIRAM0_LOGICAL_MEM_WIDTH     ),
    .CACHE_MEM_ADDR_WIDTH  (`MSFT_SP_CIRAM0_ADDR_WIDTH            ),
    .CACHE_VTAG_WIDTH      (`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH - 4), // xjdong: CACHE_VTAG_WIDTH doesn't inlcude 4 bits of Parity
    .CACHE_VTAG_ADDR_WIDTH (`MSFT_SINC_VTAG0_ADDR_WIDTH           ),
    .KSU_KEY_SLOT_BASE_ADDR(`KSU_KEY_SLOT_BASE_ADDR               ),
    .RNG_SEED_BASE_ADDR    (`RNG_SEED_BASE_ADDR                   ),
    .REG_BASE_ADDR         (`SINC_REG_BASE_ADDR                   ),
    .REG_END_ADDR          (`SINC_REG_END_ADDR                    ),
    .AXI_SUB_BLEN          (4                                     )

  ) sinc (
    // Inputs
    //Clock/Reset/Misc signals
    .clk_i                         (cpl_hspclk                                 ),
    .rstn_i                        (hsp_resetn_hspclk                          ),
    .lp_rstn_i                     (hsp_resetn_hspclk                          ),
    .clkg_override_i               (1'b0                                       ), // DV 0.8 item, Low priority waived in a prior project
    .clkg_test_mode_i              (1'b0                                       ), // DV 0.8 item, Low priority waived in a prior project
    .disable_encr_auth_check_i     (sinc_v_if.disable_encr_auth_check          ), // DV 0.8 item, Low priority waived in a prior project
    .sinc_err_parity_chk_disable_i (1'b1                                       ), // DV 0.8 item, Low priority waived in a prior project
    .sinc_iso_en_i                 (1'b0                                       ), // DV 0.8 item, Low priority waived in a prior project
    .sinc_ret_en_ni                (1'b1                                       ), // DV 0.8 item, Low priority waived in a prior project
    .sinc_err_chk_disable_i        (sinc_v_if.sinc_err_chk_disabled            ), // DV 0.8 item, Low priority waived in a prior project
    //****************************************************************
    // CPU Interface
    //****************************************************************
    .cpu_sinc_en_i                 (ccpui_sys_if.ccpui_cpu_mem_mif[0].En       ),
    .cpu_sinc_we_i                 (ccpui_sys_if.ccpui_cpu_mem_mif[0].Wr       ),
    .cpu_sinc_wr_byte_en_i         (ccpui_sys_if.ccpui_cpu_mem_mif[0].ByteEn   ),
    .cpu_sinc_addr_i               (ccpui_sys_if.ccpui_cpu_mem_mif[0].Addr     ),
    .cpu_sinc_wdata_i              (ccpui_sys_if.ccpui_cpu_mem_mif[0].WrData   ),
    .cpu_sinc_loadstore_i          (ccpui_sys_if.ccpui_cpu_mem_mif[0].LoadStore),
    .cpu_sinc_priv_mode_i          (ccpui_sys_if.ccpui_cpu_mem_mif[0].PrivMode ),
    .sinc_cpu_rdata_vld_o          (ccpui_sys_if.ccpui_cpu_mem_mif[0].RdDataVld),
    .sinc_cpu_rdata_o              (ccpui_sys_if.ccpui_cpu_mem_mif[0].RdData   ),
    .sinc_cpu_r_err_o              (ccpui_sys_if.ccpui_cpu_mem_mif[0].RdErr    ),
    .sinc_cpu_busy_o               (ccpui_sys_if.ccpui_cpu_mem_mif[0].Busy     ),
    .sinc_cpu_non_active_state     (                                           ),

    // AXI-4 Interface
    // Read Address channel
    .sinc_axi_sub_araddr  (axi_sys_if.axi_mif[0].ARADDR ),
    .sinc_axi_sub_aruser  (axi_sys_if.axi_mif[0].ARUSER ), //(axi_sys_if.axi_mif[0].ARUSER),
    .sinc_axi_sub_arburst (axi_sys_if.axi_mif[0].ARBURST), //(axi_sys_if.axi_mif[0].ARBURST),
    .sinc_axi_sub_arcache (axi_sys_if.axi_mif[0].ARCACHE), //(ARCACHE),
    .sinc_axi_sub_arid    (axi_sys_if.axi_mif[0].ARID   ), //(axi_sys_if.axi_mif[0].ARID),
    .sinc_axi_sub_arlen   (axi_sys_if.axi_mif[0].ARLEN  ), //(axi_sys_if.axi_mif[0].ARLEN),
    .sinc_axi_sub_arlock  (axi_sys_if.axi_mif[0].ARLOCK ), //(ARLOCK),
    .sinc_axi_sub_arprot  (axi_sys_if.axi_mif[0].ARPROT ), //(axi_sys_if.axi_mif[0].ARPROT),
    .sinc_axi_sub_arsize  (axi_sys_if.axi_mif[0].ARSIZE ), //(axi_sys_if.axi_mif[0].ARSIZE),
    .sinc_axi_sub_arvalid (axi_sys_if.axi_mif[0].ARVALID), //(axi_sys_if.axi_mif[0].ARVALID),
    .sinc_axi_sub_arready (axi_sys_if.axi_mif[0].ARREADY),

    // Read Data channel
    .sinc_axi_sub_rready (axi_sys_if.axi_mif[0].RREADY),
    .sinc_axi_sub_rdata  (axi_sys_if.axi_mif[0].RDATA ),
    .sinc_axi_sub_rid    (axi_sys_if.axi_mif[0].RID   ),
    .sinc_axi_sub_rlast  (axi_sys_if.axi_mif[0].RLAST ),
    .sinc_axi_sub_rresp  (axi_sys_if.axi_mif[0].RRESP ),
    .sinc_axi_sub_rvalid (axi_sys_if.axi_mif[0].RVALID),
    .sinc_axi_sub_ruser  (axi_sys_if.axi_mif[0].RUSER ),

    // Write Address channel
    .sinc_axi_sub_awaddr  (axi_sys_if.axi_mif[0].AWADDR ), //(axi_sys_if.axi_mif[0].AWADDR),
    .sinc_axi_sub_awuser  (axi_sys_if.axi_mif[0].AWUSER ), //(axi_sys_if.axi_mif[0].AWUSER),
    .sinc_axi_sub_awburst (axi_sys_if.axi_mif[0].AWBURST), //(axi_sys_if.axi_mif[0].AWBURST),
    .sinc_axi_sub_awcache (axi_sys_if.axi_mif[0].AWCACHE), //(AWCACHE[3:0]),
    .sinc_axi_sub_awid    (axi_sys_if.axi_mif[0].AWID   ), //(axi_sys_if.axi_mif[0].AWID),
    .sinc_axi_sub_awlen   (axi_sys_if.axi_mif[0].AWLEN  ), //(axi_sys_if.axi_mif[0].AWLEN),
    .sinc_axi_sub_awlock  (axi_sys_if.axi_mif[0].AWLOCK ), //(AWLOCK),
    .sinc_axi_sub_awprot  (axi_sys_if.axi_mif[0].AWPROT ), //(axi_sys_if.axi_mif[0].AWPROT),
    .sinc_axi_sub_awsize  (axi_sys_if.axi_mif[0].AWSIZE ), //(axi_sys_if.axi_mif[0].AWSIZE),
    .sinc_axi_sub_awvalid (axi_sys_if.axi_mif[0].AWVALID), //(axi_sys_if.axi_mif[0].AWVALID),
    .sinc_axi_sub_awready (axi_sys_if.axi_mif[0].AWREADY),

    // Write Data channel
    .sinc_axi_sub_wdata  (axi_sys_if.axi_mif[0].WDATA ),
    .sinc_axi_sub_wlast  (axi_sys_if.axi_mif[0].WLAST ),
    .sinc_axi_sub_wstrb  (axi_sys_if.axi_mif[0].WSTRB ),
    .sinc_axi_sub_wvalid (axi_sys_if.axi_mif[0].WVALID),
    .sinc_axi_sub_wready (axi_sys_if.axi_mif[0].WREADY),
    .sinc_axi_sub_buser  (axi_sys_if.axi_mif[0].BUSER ),
    // .sinc_axi_sub_wuser              ('0),

    // Write Response channel
    .sinc_axi_sub_bready (axi_sys_if.axi_mif[0].BREADY),
    .sinc_axi_sub_bid    (axi_sys_if.axi_mif[0].BID   ),
    .sinc_axi_sub_bresp  (axi_sys_if.axi_mif[0].BRESP ),
    .sinc_axi_sub_bvalid (axi_sys_if.axi_mif[0].BVALID),

    // Master Interface
    // Read Address channel
    .sinc_axi_mgr_araddr  (hdl_top.axi_sys_if.axi_sif[0].ARADDR ),
    .sinc_axi_mgr_aruser  (hdl_top.axi_sys_if.axi_sif[0].ARUSER ),
    .sinc_axi_mgr_arburst (hdl_top.axi_sys_if.axi_sif[0].ARBURST),
    .sinc_axi_mgr_arcache (hdl_top.axi_sys_if.axi_sif[0].ARCACHE),
    .sinc_axi_mgr_arid    (hdl_top.axi_sys_if.axi_sif[0].ARID   ),
    .sinc_axi_mgr_arlen   (hdl_top.axi_sys_if.axi_sif[0].ARLEN  ),
    .sinc_axi_mgr_arlock  (hdl_top.axi_sys_if.axi_sif[0].ARLOCK ),
    .sinc_axi_mgr_arprot  (hdl_top.axi_sys_if.axi_sif[0].ARPROT ),
    .sinc_axi_mgr_arsize  (hdl_top.axi_sys_if.axi_sif[0].ARSIZE ),
    .sinc_axi_mgr_arvalid (hdl_top.axi_sys_if.axi_sif[0].ARVALID),
    .sinc_axi_mgr_arready (hdl_top.axi_sys_if.axi_sif[0].ARREADY),

    // Read Data channel
    .sinc_axi_mgr_rready (hdl_top.axi_sys_if.axi_sif[0].RREADY),
    .sinc_axi_mgr_rdata  (hdl_top.axi_sys_if.axi_sif[0].RDATA ),
    .sinc_axi_mgr_ruser  (hdl_top.axi_sys_if.axi_sif[0].RUSER ),
    .sinc_axi_mgr_rid    (hdl_top.axi_sys_if.axi_sif[0].RID   ),
    .sinc_axi_mgr_rlast  (hdl_top.axi_sys_if.axi_sif[0].RLAST ),
    .sinc_axi_mgr_rresp  (hdl_top.axi_sys_if.axi_sif[0].RRESP ),
    .sinc_axi_mgr_rvalid (hdl_top.axi_sys_if.axi_sif[0].RVALID),

    // Write Address channel
    .sinc_axi_mgr_awready (hdl_top.axi_sys_if.axi_sif[0].AWREADY),
    .sinc_axi_mgr_awaddr  (hdl_top.axi_sys_if.axi_sif[0].AWADDR ),
    .sinc_axi_mgr_awuser  (hdl_top.axi_sys_if.axi_sif[0].AWUSER ),
    .sinc_axi_mgr_awburst (hdl_top.axi_sys_if.axi_sif[0].AWBURST),
    .sinc_axi_mgr_awcache (hdl_top.axi_sys_if.axi_sif[0].AWCACHE),
    // .sinc_axi_mgr_awid (hdl_top.axi_sys_if.axi_sif[0].AWID[`HSP_AXI_MST_ID_WIDTH-1:0]),
    .sinc_axi_mgr_awid    (hdl_top.axi_sys_if.axi_sif[0].AWID   ),
    .sinc_axi_mgr_awlen   (hdl_top.axi_sys_if.axi_sif[0].AWLEN  ),
    .sinc_axi_mgr_awlock  (hdl_top.axi_sys_if.axi_sif[0].AWLOCK ),
    .sinc_axi_mgr_awprot  (hdl_top.axi_sys_if.axi_sif[0].AWPROT ),
    .sinc_axi_mgr_awsize  (hdl_top.axi_sys_if.axi_sif[0].AWSIZE ),
    .sinc_axi_mgr_awvalid (hdl_top.axi_sys_if.axi_sif[0].AWVALID),

    // Write Data channel
    .sinc_axi_mgr_wdata  (hdl_top.axi_sys_if.axi_sif[0].WDATA ),
    .sinc_axi_mgr_wready (hdl_top.axi_sys_if.axi_sif[0].WREADY),
    //.sinc_axi_mgr_wid      (axi_sys_if.axi_sif[0].WID),
    .sinc_axi_mgr_wlast  (hdl_top.axi_sys_if.axi_sif[0].WLAST ),
    .sinc_axi_mgr_wstrb  (hdl_top.axi_sys_if.axi_sif[0].WSTRB ),
    .sinc_axi_mgr_wvalid (hdl_top.axi_sys_if.axi_sif[0].WVALID),

    // Write Response channel
    .sinc_axi_mgr_bready (hdl_top.axi_sys_if.axi_sif[0].BREADY),
    .sinc_axi_mgr_bid    (hdl_top.axi_sys_if.axi_sif[0].BID   ),
    .sinc_axi_mgr_bresp  (hdl_top.axi_sys_if.axi_sif[0].BRESP ),
    .sinc_axi_mgr_bvalid (hdl_top.axi_sys_if.axi_sif[0].BVALID),
    .sinc_axi_mgr_buser  (hdl_top.axi_sys_if.axi_sif[0].BUSER ),

    // Memory Erase Interface
    .sinc_erase_start_i    (ramwrap_sys_if.ramwrap_erase_mif[0].ERASE_START   ),
    .sinc_erase_data_i     (ramwrap_sys_if.ramwrap_erase_mif[0].ERASE_WDATA   ),
    .sinc_erase_done_o     (ramwrap_sys_if.ramwrap_erase_mif[0].ERASE_DONE    ),
    .sinc_erase_busy_o     (ramwrap_sys_if.ramwrap_erase_mif[0].ERASE_BUSY    ),
    .sinc_err_erase_busy_o (ramwrap_sys_if.ramwrap_erase_mif[0].ERR_ERASE_BUSY),
    // .sinc_erase_busy_o              (ramwrap_sys_if.ramwrap_erase_mif[0].TRIVIUM_ERASE_VLD),

    // Memory Error Inject and Error Log Interface
    .sinc_err_inject_en_i   (ramwrap_sys_if.ramwrap_inject_mif[0].inject     ),
    .sinc_err_inject_addr_i (ramwrap_sys_if.ramwrap_inject_mif[0].inject_addr),
    .sinc_err_inject_data_i (ramwrap_sys_if.ramwrap_inject_mif[0].inject_data),
    .sinc_err_inject_done_o (ramwrap_sys_if.ramwrap_inject_mif[0].inject_done),

    .sinc_err_uncorr_o (mem_err_uncorr_o),
    .sinc_err_addr_o   (mem_err_addr_o  ),
    .sinc_err_corr_o   (mem_err_corr_o  ),

    // Memory Memory Interface
    .sinc_ciram_clk_o   (cache_mem_ck    ),
    .sinc_ciram_addr_o  (cache_mem_addr_w),
    .sinc_ciram_we_o    (cache_mem_we_w  ),
    .sinc_ciram_en_o    (cache_mem_cs_w  ),
    .sinc_ciram_rdata_i (cache_mem_dout_w),
    .sinc_ciram_wdata_o (cache_mem_din_w ),

    .sinc_vtag_clk_o   (cache_vtag_ck    ),
    .sinc_vtag_addr_o  (cache_vtag_addr_w),
    .sinc_vtag_we_o    (cache_vtag_we_w  ),
    .sinc_vtag_en_o    (cache_vtag_cs_w  ),
    .sinc_vtag_rdata_i (cache_vtag_din_w ),
    .sinc_vtag_wdata_o (cache_vtag_dout_w),

    // MPU Interface
    .sinc_mpu_reg_addr_i     (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_addr    ),
    .sinc_mpu_reg_wr_i       (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_wr      ),
    .sinc_mpu_reg_rd_i       (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_rd      ),
    .sinc_mpu_reg_wdata_i    (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_wdata   ),
    .sinc_mpu_reg_rdata_o    (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_rdata   ),
    .sinc_mpu_reg_resp_o     (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_resp    ),
    .sinc_mpu_reg_resp_vld_o (ccpui_sys_if.ccpui_mpu_mif[0].mpu_reg_resp_vld),
    .sinc_mpu_err_accvio_o   (ccpui_sys_if.ccpui_mpu_mif[0].mpu_err_accvio  ),
    .sinc_mpu_disable_i      (ccpui_sys_if.ccpui_mpu_mif[0].mpu_disable     ),
    .sinc_chkpt_spramnx_i    (ccpui_sys_if.ccpui_mpu_mif[0].chkpt_spramnx   ),

    // sideband signals
    .sinc_done_o (sinc_v_if.sinc_done),
    .sinc_err_o  (sinc_v_if.sinc_err )

  );

  msftDvIp_fpga_ram #(
    .RAM_WIDTH            (sinc_parameters_pkg::SINC_CACHE_MEM_RAM_WIDTH),
    .RAM_DEPTH            (sinc_parameters_pkg::SINC_CACHE_MEM_RAM_DEPTH),
    .RAM_BACK_DOOR_ENABLE (0                                            )
  ) cache_sram (
    .clk  (cache_mem_ck    ),
    .cs   (cache_mem_cs_w  ),
    .addr (cache_mem_addr_w),
    .we   (cache_mem_we_w  ),
    .din  (cache_mem_din_w ),
    .dout (cache_mem_dout_w)
  );

  // msftDvIp_fpga_ram #(
  //                     .RAM_WIDTH (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_WIDTH),
  //                     .RAM_DEPTH (sinc_parameters_pkg::SINC_CACHE_VTAG_RAM_DEPTH),
  //                     .RAM_BACK_DOOR_ENABLE (0)
  //                     ) cache_vtag (
  //                                   .clk     (cache_vtag_ck),
  //                                   .cs      (cache_vtag_cs_w),
  //                                   .addr    (cache_vtag_addr_w),
  //                                   .we      (cache_vtag_we_w),
  //                                   .din     (cache_vtag_dout_w),
  //                                   .dout    (cache_vtag_din_w)
  //                         );

  sinc_vtag_ram_wrap hsp_wrap_vtag (/*AUTOINST*/
    // Outputs
    .rd_data  (cache_vtag_din_w[`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH-1:0]), // Templated
    // Inputs
    .clk      (cpl_hspclk                                              ), // Templated
    .en       (cache_vtag_cs_w[3:0]                                    ), // Templated
    .addr     (cache_vtag_addr_w[`MSFT_SINC_VTAG0_ADDR_WIDTH-1:0]      ), // Templated
    .mem_ctrl (0                                                       ),
    .rstn     (hsp_resetn_hspclk                                       ), // Templated
    .pg_ret   (0                                                       ),
    .pg_sd    (0                                                       ),
    .pg_ds    (0                                                       ),
    .wr_en    (cache_vtag_we_w[3:0]                                    ), // Templated
    .wr_data (cache_vtag_dout_w[`MSFT_SINC_VTAG0_LOGICAL_MEM_WIDTH-1:0])); // Templated

  //----------------------------------------------------------------
  // DUT to monitor connections START
  //----------------------------------------------------------------

  // Virtual interface
  // assign sinc_v_if.mem_erase_start = m_sinc.sinc_erase_start_i;
  // assign sinc_v_if.mem_erase_done  = m_sinc.sinc_erase_done_o;

  // RamWrap Cache Mem
  assign ramwrap_sys_if.mem_rif[0].ram_adr = sinc.sinc_ciram_addr_o;
  assign ramwrap_sys_if.mem_rif[0].ram_me  = sinc.sinc_ciram_en_o;
  assign ramwrap_sys_if.mem_rif[0].ram_we  = sinc.sinc_ciram_we_o;
  assign ramwrap_sys_if.mem_rif[0].ram_di  = sinc.sinc_ciram_rdata_i;
  assign ramwrap_sys_if.mem_rif[0].ram_qi  = sinc.sinc_ciram_wdata_o;

  // RamWrap Cache VTAG
  assign ramwrap_sys_if.mem_rif[1].ram_adr = sinc.sinc_vtag_addr_o;
  assign ramwrap_sys_if.mem_rif[1].ram_me  = sinc.sinc_vtag_en_o;
  assign ramwrap_sys_if.mem_rif[1].ram_we  = sinc.sinc_vtag_we_o;
  assign ramwrap_sys_if.mem_rif[1].ram_di  = sinc.sinc_vtag_rdata_i;
  assign ramwrap_sys_if.mem_rif[1].ram_qi  = sinc.sinc_vtag_wdata_o;

  // get around for RTL missing inject busy
  assign ramwrap_sys_if.ramwrap_inject_mif[0].inject_busy = 0;
  assign ramwrap_sys_if.ramwrap_inject_mif[1].inject_busy = 0;

  // assign unused QoS signal for AXI SUB
  assign hdl_top.axi_sys_if.axi_sif[0].ARQOS = 0;
  assign hdl_top.axi_sys_if.axi_sif[0].AWQOS = 0;
  assign hdl_top.axi_sys_if.axi_sif[0].WUSER = 0;

  // GPAES
  assign m_gpaes_sys_if.gpaes_seed_mif.seed_i = sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.seed_i;
  assign m_gpaes_sys_if.gpaes_seed_mif.seed_vld_i =  sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.seed_vld_i;
  assign m_gpaes_sys_if.gpaes_seed_mif.seed_rdy_o = sinc.u_sinc_cmu.u_crypto_wrap.u_gp_aes.seed_rdy_o;

  // connect Trivium enable bit
  assign ramwrap_sys_if.ramwrap_erase_mif[0].TRIVIUM_ERASE_VLD = sinc.sinc_erase_busy_o;

  //----------------------------------------------------------------
  // DUT to monitor connections END
  //----------------------------------------------------------------

  initial begin // tbx vif_binding_block
    import uvm_pkg::uvm_config_db;

    // HSP VIRT Sequencer uses "*" as the instance in its config_db::get call,
    // ::get does not treat '*' like a wildcard, so it will only match with literal '*'
    // However DVLINT complains when using "*" (wildcard) in the set call
    const static string HSP_VIRT_SEQ_GET_KEY = "*";

    // The monitor_bfm and driver_bfm for each interface is placed into the uvm_config_db.
    // They are placed into the uvm_config_db using the string names defined in the parameters package.
    // The string names are passed to the agent configurations by test_top through the top level configuration.
    // They are retrieved by the agents configuration class for use by the agent.
    uvm_config_db #(virtual clk_interface)::set(uvm_root::get(), "uvm_test_top.environment.m_clk_agent", "clk_vif", clk_if              );
    uvm_config_db #(virtual clk_interface)::set(uvm_root::get(), HSP_VIRT_SEQ_GET_KEY, "clk_vif", clk_if                                    );
    uvm_config_db #(virtual rst_interface)::set(uvm_root::get(), "uvm_test_top.environment.m_rst_agent", "rst_vif", rst_if              );
    uvm_config_db #(virtual tb_pal_if    )::set(uvm_root::get(), "uvm_test_top.environment.pal_sys_wrapper_env.tb_vseqr", "tb_if", tb_if);
    uvm_config_db #(virtual peek_poke_if )::set(uvm_root::get(), "uvm_test_top.*", "peek_poke_if", peek_poke_if                         );
    uvm_config_db #(virtual sinc_v_if    )::set(uvm_root::get(), UVMF_VIRTUAL_INTERFACES, "SINC_V_IF", sinc_v_if                        );

    // Memory backdoor interface
    uvm_config_db #(virtual sinc_mem_bkdoor_if)::set( uvm_root::get() , UVMF_VIRTUAL_INTERFACES , "mem_bkdoor_if" , `SINC_TB_TOP.sinc_mem_bkdoor_if_inst);

    // LUT RAM Wrapper monitor
  end

endmodule : hdl_top

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif
