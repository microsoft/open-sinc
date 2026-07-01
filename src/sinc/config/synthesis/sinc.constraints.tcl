
#README: Constraint file is separated into 3 sections.  Add constraints in the right section to keep things sane.
  # Section 1: Common constraints between FPGA and non-FPGA (everything here if this block is not going in FPGA)
  # Section 2: ASIC specific constraints (sdc/tcl)
  # Section 3: FPGA specific constraints (xdc)

puts "BEGIN [info script]"


############################################################
# COMMON CONSTRAINTS
############################################################ 
if {![info exists synopsys_program_name]} {
    set SYN_FPGA 1
    set source_switches ""
} else {
    set SYN_FPGA 0
    set source_switches "-e -v"
}

# (Open-source release) No project-level pre_compile.tcl is shipped. If
# your environment provides one, source it here before this file is read.


if {[info proc proc.convert_time_unit] eq {}} {
 proc proc.convert_time_unit {time_in_ns} {
  if {![string is double -strict ${time_in_ns}]} {
   return -code error "Expect time_in_ns to be a floating point number but got '${time_in_ns}'."
  }
  global synopsys_program_name TECH
  if {[info exists synopsys_program_name] && (${synopsys_program_name} eq {dc_shell} && [get_attribute [current_design] design_time_unit] == 0.001 || (${synopsys_program_name} eq {pt_shell} || ${synopsys_program_name} eq {pwr_shell}) && [get_attribute [current_design] time_unit_in_second] == 0.001)} {
   return [expr ${time_in_ns} * 1000]
  }
  return ${time_in_ns}
 }
}

if {![info exists HSP_HIER]} {
 set HSP_HIER ""
}

set clk_in_period [proc.convert_time_unit 1.6]              ;# 500MHz*1.25(25% margin) = 625MHz (1e9/625.00e6) = 1.6 ns
# An arbitrary period.
set async_clk_period [proc.convert_time_unit 8]

### CREATE CLOCK
# At a minimum, you will need to set up your clocks here, 1 create_clock line per clock
# e.g.  create_clock -name CLK -period 4.0 [get_ports clk_port_name]

#----------------------------------------------------
# HSPCLK and FMCCLK
#----------------------------------------------------
create_clock -name CLKM.clk_i -period ${clk_in_period} [get_ports ${HSP_HIER}clk_i]
set_clock_uncertainty [proc.convert_time_unit 0.18] [get_clocks CLKM.clk_i] -setup
set_clock_uncertainty [proc.convert_time_unit 0.039] [get_clocks CLKM.clk_i] -hold
set_clock_transition [proc.convert_time_unit 0.15] CLKM.clk_i -max
set_clock_transition [proc.convert_time_unit 0.02] CLKM.clk_i -min

create_clock -name CLKV.async -period ${async_clk_period}
set_clock_uncertainty 0 -from [get_clocks CLKV.async] -to [get_clocks {CLKM.clk_i}]

#----------------------------------------------------
# Clock Groups
#----------------------------------------------------

set_clock_groups -asynchronous -name clk_grp.CLKV.async -allow_paths \
 -group CLKV.async \
 -group {CLKM.clk_i}


# Also create "virtual" versions of each of the clocks above for IO constraints
# NOTE: Virtual clocks should not be placed on a clock port like non-virtual clocks
# create_clock -name V_CLK -period $MY_CLOCK_PERIOD

### CLOCK TO CLOCK EXCEPTIONS
# Set false_path/multicycle_path here if needed
# e.g.  set_false_path -from [get_ports port_name] -to [get_ports port_name]

# AES SubBytes affine-multiply false path.
#
# Each aes_sbox stores its mid-round value in invi_mdpl_r. The post-
# inversion datapath instantiates BOTH aes_affine_mul_m (encrypt branch)
# and aes_affine_mul_mi (decrypt branch); a dir_i mux selects which one
# drives sbox_o. The core only encrypts OR decrypts on a given cycle, so
# the worst-case combinational path from one sbox register through both
# affine-mul blocks back into another sbox register is never functionally
# exercised. Cutting this through-path eases timing closure inside SubBytes.
#
# RTL hierarchy (per aes_round0 / aes_subbytes0):
#   row_sbox[m].column_sbox[n].aes_sbox_x
#       .aes_affine_mul_m0 .aes_basic_affine_mul_m_x   (encrypt branch)
#       .aes_affine_mul_mi0.aes_basic_affine_mul_mi_x  (decrypt branch)
#       .invi_mdpl_r                                   (mid-round flop)
#
# Guarded so this is a silent no-op under non-DC tools or if the AES
# hierarchy is absent.
if {[info exists synopsys_program_name]} {
    set _sbox "${HSP_HIER}u_sinc_cmu/u_crypto_wrap/u_gp_aes/aes_core0/aes_datapath0/aes_round0/aes_subbytes0/row_sbox*column_sbox*aes_sbox_x"

    set _from_pins [get_pins -quiet "${_sbox}/*_reg*/CK"]
    if {${_from_pins} eq {}} {
        set _from_pins [get_pins -quiet "${_sbox}/*_reg*/CP"]
    }

    set _through_pins [get_pins -quiet "
        ${_sbox}/aes_affine_mul_m0/aes_basic_affine_mul_m_x/*/X
        ${_sbox}/aes_affine_mul_mi0/aes_basic_affine_mul_mi_x/*/X
    "]
    if {${_through_pins} eq {}} {
        set _through_pins [get_pins -quiet "
            ${_sbox}/aes_affine_mul_m0/aes_basic_affine_mul_m_x/*/Z*
            ${_sbox}/aes_affine_mul_mi0/aes_basic_affine_mul_mi_x/*/Z*
        "]
    }

    if {${_from_pins} ne {} && ${_through_pins} ne {}} {
        set_false_path -from ${_from_pins} -through ${_through_pins} \
            -to [get_pins "${_sbox}/invi_mdpl_r*/D*"] \
            -comment {AES SubBytes encrypt and decrypt affine-mul branches are mutually exclusive per cycle (selected by dir_i).}

        # Keep the affine-mul cells from being optimized away in DC so the
        # through-pin lookup above remains valid.
        if {$synopsys_program_name eq "dc_shell"} {
            set _aff_cells [get_cells -quiet "
                ${_sbox}/aes_affine_mul_m0/aes_basic_affine_mul_m_x/*
                ${_sbox}/aes_affine_mul_mi0/aes_basic_affine_mul_mi_x/*
            "]
            if {${_aff_cells} ne {}} { set_size_only ${_aff_cells} }
        }
    }
}


#----------------------------------------------------
# Case Analysis
#----------------------------------------------------

set_case_analysis 0 [get_ports ${HSP_HIER}clkg_test_mode_i]


### IO CONSTRAINTS
# If DC_APPLY_DEFAULT_DELAY is set to 1, a default delay of 66% of the clock cycle will be applied to every non-clock I/O port.
# Alternatively, you can add input/output delays here.
# e.g.  set_input_delay 10 -clock CLK [all_inputs]
#	remove_input_delay [get_ports CLK]   
# set MY_IO_DLY_MAX [expr $MY_CLOCK_PERIOD * 0.66]

# clkg_test_mode_i is an asynchronous scan/clock-gating control. Constrain it
# against the async virtual clock and bound its propagation into the design.
set_input_delay 0 -clock [get_clocks CLKV.async] [get_ports ${HSP_HIER}clkg_test_mode_i]
set_max_delay [proc.convert_time_unit 0.07] -ignore_clock_latency -from [get_ports ${HSP_HIER}clkg_test_mode_i]

# Asynchronous control / reset / retention / isolation inputs. These are not
# launched by CLKM.clk_i, so constrain them against the async virtual clock.
set sinc_async_inputs {
    rstn_i
    lp_rstn_i
    clkg_override_i
    sinc_ret_en_ni
    sinc_iso_en_i
}
set_input_delay 0 -clock [get_clocks CLKV.async] [get_ports ${sinc_async_inputs}]


set sinc_inputs {
    disable_encr_auth_check_i
    sinc_axi_mgr_r*
    sinc_axi_mgr_b*
    sinc_axi_mgr_arready
    sinc_axi_mgr_awready
    sinc_axi_mgr_wready
    sinc_axi_sub_ar*
    sinc_axi_sub_aw*
    sinc_axi_sub_w*
    sinc_axi_sub_rready
    sinc_axi_sub_bready
    sinc_err_chk_disable_i
    sinc_err_parity_chk_disable_i
    cpu_sinc*
    sinc_erase_start_i
    sinc_erase_data_i
    sinc_err_inject_en_i
    sinc_err_inject_addr_i
    sinc_err_inject_data_i
    sinc_ciram_rdata_i
    sinc_vtag_rdata_i
    sinc_mpu_reg_addr_i
    sinc_mpu_reg_wr_i
    sinc_mpu_reg_rd_i
    sinc_mpu_reg_wdata_i
    sinc_mpu_disable_i
    sinc_chkpt_spramnx_i
}

set sinc_outputs {
    sinc_axi_mgr_ar*
    sinc_axi_mgr_aw*
    sinc_axi_mgr_w*
    sinc_axi_mgr_rready
    sinc_axi_mgr_bready
    sinc_axi_sub_r*
    sinc_axi_sub_b*
    sinc_axi_sub_arready
    sinc_axi_sub_awready
    sinc_axi_sub_wready
    sinc_err_o
    sinc_err_parity_o
    sinc_done_o
    sinc_active_o
    sinc_cpu*
    sinc_erase_done_o
    sinc_erase_busy_o
    sinc_err_erase_busy_o
    sinc_err_inject_done_o
    sinc_err_uncorr_o
    sinc_err_addr_o
    sinc_err_corr_o
    sinc_ciram_clk_o
    sinc_ciram_addr_o
    sinc_ciram_we_o
    sinc_ciram_en_o
    sinc_ciram_wdata_o
    sinc_vtag_clk_o
    sinc_vtag_addr_o
    sinc_vtag_we_o
    sinc_vtag_en_o
    sinc_vtag_wdata_o
    sinc_mpu_reg_rdata_o
    sinc_mpu_reg_resp_o
    sinc_mpu_reg_resp_vld_o
    sinc_mpu_err_accvio_o
}

set_input_delay [expr ${clk_in_period} - [proc.convert_time_unit 0.60]] -clock [get_clocks CLKM.clk_i] [get_ports ${sinc_inputs}]


set_output_delay [expr ${clk_in_period} - [proc.convert_time_unit 0.32]] -clock [get_clocks CLKM.clk_i] [get_ports ${sinc_outputs}]


### OTHER CONSTRAINTS
# e.g.  set_multicycle_path -setup 5 -from [get_ports port_name]
#	set_multicycle_path -hold 4 -from [get_ports port_name]

if {[info exists synopsys_program_name] && $synopsys_program_name == "dc_shell"} {

   # Prevent DC from optimizing TIE cells
   set tie_cells [get_cells -hierarchical -filter is_hierarchical==false&&(ref_name=~*TIE*)]
   foreach_in_collection tcell $tie_cells {
     set tc_name [get_attribute -quiet $tcell full_name]
     set_dont_touch $tc_name
     set_dont_touch_network [get_pins $tc_name/Z*]
   }

   # There is a set_false_path through the following cells so set these cells as size_only so that they don't get optimized out.

   set enable_recovery_removal_arcs true

   # Standard cells that must not be ungrouped (preserve clock-gating cells so
   # downstream CTS / DFT handling stays intact). Only modules present in this
   # open-source release are listed; integrators may append their own CDC /
   # DFT primitive module names here.
   set no_ungroup_design_name_patterns {
     c_clock_gate
     c_clock_gate_ovr
   }
   foreach design_name_pattern ${no_ungroup_design_name_patterns} {
     set cells [sort_collection -dictionary [get_references -quiet -hierarchical ${design_name_pattern}] full_name]
     if {${cells} ne {}} {
       puts "Info: set_ungroup false on the following [sizeof_collection ${cells}] instances of '${design_name_pattern}'.\n[join [get_object_name ${cells}] \n]"
       set_ungroup ${cells} false
     } else {
       puts "Warning: No module name matches $design_name_pattern. Investigate whether this module is used in this design."
     }
   }

   # TECH cells size_only
   #c_clock_gate
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/ICG)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_or
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/or_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_and
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_mux
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/clk_mux)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_inv
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/clk_inv)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_buff 
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/clk_buff)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clock_root
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/CTS_ROOT_BUF)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_mux2
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/mux2)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_inv
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/inv_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_reg, c_reg_cdn, c_reg_sdn, c_reg_cdn_sdn
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/i_reg)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_and4
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/and4_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_and
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/and_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_or
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/or_gate)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_buff
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/buff)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_clkdiv_sample
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/r_2d_reg)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_full_adder
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/full_addr)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }

   #c_dft_occ_clk_gate, c_dft_occ_clk_mux
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_inv_sm)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_and)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_inv)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_dft_cap_cntl)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_or_cap_ctl)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_ck_and)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_or_mux_ctl)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   set size_only_cells [get_cells -hierarchical -filter is_hierarchical==false&&(full_name=~*/u_ck_mux)]
   if {${size_only_cells} ne {}} {
     set_size_only -all_instances [get_cells ${size_only_cells}]
   }
   
}

############################################################
# ASIC SPECIFIC CONSTRAINTS
############################################################ 
if {$SYN_FPGA==0} {
    # TODO (open-source): add ASIC IO constraints here if needed.
}


############################################################
# FPGA SPECIFIC CONSTRAINTS
############################################################ 
if {$SYN_FPGA==1} {
    # TODO (open-source): add FPGA IO constraints here if needed.
}

puts "END [info script]"
