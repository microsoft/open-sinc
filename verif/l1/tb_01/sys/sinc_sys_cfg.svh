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
// File        : sinc_sys_cfg.svh
// Description : This class defines System Configurations for Key Vault TB.

`ifndef SINC_SYS_CFG_SVH
`define SINC_SYS_CFG_SVH

class sinc_sys_cfg extends uvm_object;  // {

  `uvm_object_utils(sinc_sys_cfg);

  //-----------------------------------------------------------------
  // VARIABLES
  //-----------------------------------------------------------------

  // Variable: _instance
  // static member that points to singleton
  protected static sinc_sys_cfg _instance;

  // Variable: comp_cfg
  // Associative array of component config objects
  protected sinc_comp_cfg comp_cfg[sinc_comp_e];

  // Variable: number of SINCs available in this sim
  protected int num_sinc = 0;

  // Variable: list of components available in this sim. This is a function of the num_sinc.
  protected sinc_comp_e _comp_list[$];
  protected bit        _comp_hash[sinc_comp_e];
  protected mstr_type_e _comp_master_list[$];

  //-----------------------------------------------------------------
  // FUNCTIONS
  //-----------------------------------------------------------------

  //-----------------------------------------------------------------
  //
  function new(string name="sinc_sys_cfg");
    super.new(name);

    if (_instance != null) begin
      `uvm_fatal("sinc_sys_cfg::new: illegal instance of singleton","Can't instance a singleton more than once. Use sinc_env_pkg::sinc_sys_cfg::get_inst() instead")
    end
    _instance = this;

    `uvm_info("SINC_SYS_CFG/new", $sformatf("Initializing sinc_sys_cfg\n"), UVM_HIGH)

    init();
  endfunction : new

  //-----------------------------------------------------------------
  // Function: get_inst
  // A static function which returns the singleton instance of this class.
  static function sinc_sys_cfg get_inst();
    if (_instance != null) begin
      return _instance;
    end
    else begin
      //`uvm_error("sinc_sys_cfg::get_inst: not created","This singleton must first be created using sinc_env_pkg::sinc_sys_cfg::create()")
      return null;
    end
  endfunction : get_inst

  //-----------------------------------------------------------------
  // Function: init
  // A function to initialize sinc_sys_cfg
  // CS TB initializes after setting the values of num_sincs in cs_tb_env
  function void init();

    init_comp_cfgs();

    // determine available components 
    begin
      sinc_comp_e comp = comp.first();
      while (comp != comp.last()) begin
        if (comp_cfg.exists(comp)) begin
          _comp_list.push_back(comp);
          _comp_hash[comp] = 1;
          `uvm_info("sinc_sys_config:", $sformatf("Add %0s as _comp_list", comp.name()), UVM_LOW);
        end
        comp = comp.next();
      end
    end

    dump_sys_cfg();

  endfunction : init

  //-----------------------------------------------------------------
  // Function: get_instance_id
  //   Returns instanceID associated with supplied component.
  //
  function int get_instance_id (sinc_comp_e comp);
    validate_comp (comp);
    return comp_cfg[comp].instance_id;
  endfunction : get_instance_id

  //-----------------------------------------------------------------
  // Function: get_type_instance_name
  //   Returns component type instance name (ex. )
  //
  function string get_type_instance_name (sinc_comp_e comp);
    validate_comp (comp);
    return comp_cfg[comp].type_instance_name;
  endfunction : get_type_instance_name

  //-----------------------------------------------------------------
  // Function: get_comp_type_name
  //   Returns component type name (ex. )
  //
  function string get_comp_type_name (sinc_comp_e comp);
    validate_comp (comp);
    return comp_cfg[comp].comp_type_name;
  endfunction : get_comp_type_name

  //-----------------------------------------------------------------
  // Function: get_comp_id
  //  Returns comp_id for specified instance_id
  function sinc_env_pkg::sinc_comp_e get_comp_id (int inst_id);
    foreach(comp_cfg[comp_id]) begin
      if(comp_cfg[comp_id].instance_id == inst_id) begin
        return comp_id;
      end
    end

    return sinc_env_pkg::SINC_NULL;

  endfunction : get_comp_id

  extern virtual function void validate_comp (sinc_comp_e comp);
  extern virtual function bit  is_valid_comp (sinc_comp_e comp);

  extern virtual function void dump_sys_cfg();

  extern virtual function void             init_comp_cfgs         ();

  extern virtual function int              get_comp_index         (sinc_comp_e comp);
  extern virtual function int              get_comp_addr_width    (sinc_comp_e comp);
  extern virtual function longint unsigned get_comp_addr_mask     (sinc_comp_e comp);
  extern virtual function sinc_comp_cfg     get_comp_cfg           (sinc_comp_e comp);
  extern virtual function sinc_comp_cfg     get_comp_cfg_from_comp_type (comp_type_e comp_type);
  extern virtual function sinc_comp_cfg     get_comp_cfg_from_comp_type_vcs (comp_type_e comp_type);
  extern virtual function req_cmd_list_t   get_valid_cmd_types     (sinc_comp_e src_comp, comp_type_e dst_comp_type);
  extern virtual function comp_type_list_t get_valid_access_comp_types  (sinc_comp_e src_comp);
  extern virtual function comp_type_e      get_valid_access_comp_type(sinc_comp_e src_comp);
  extern virtual function sinc_comp_list_t    get_valid_src_comp  (sinc_comp_e dst_comp);
  extern virtual function comp_type_list_t   get_all_valid_access_comp_types  (sinc_comp_e src_comp);
  extern virtual function sinc_cmd_e        get_valid_cmd_type (sinc_comp_e src_comp, comp_type_e dst_comp_type);
  extern virtual function sinc_comp_e       get_comp_from_string   (string name);
  extern virtual function string           get_hdl_path           (sinc_comp_e comp);
  extern virtual function sinc_comp_list_t  get_full_comp_list     ();
  extern virtual function sinc_comp_list_t  get_comp_list          (comp_type_e comp_id=COMP_NULL);
  extern virtual function sinc_comp_list_t  get_key_comp_list      ();
  //  extern virtual function sinc_comp_list_t  get_key_slot_comp_list ();
  extern virtual function sinc_comp_list_t  get_sp_comp_list       ();
  extern virtual function mstr_type_e      get_mstr_comp_type       (sinc_comp_e comp);
  extern virtual function mstr_type_e      get_mstr_comp_type_by_userbits  (bit [3:0] axuser);
  extern virtual function sinc_comp_e       get_src_comp_from_userbits (mstr_type_e axuser);
  extern virtual function comp_type_e      get_slv_comp_type       (sinc_comp_e comp);
  extern virtual function comp_type_e      get_comp_type      (sinc_comp_e comp);
  extern virtual function comp_type_e      get_comp_type_vcs  (sinc_comp_e comp);
  extern virtual function sinc_comp_e       get_compe_by_axi_id    (int axi_id);
  extern virtual function int              get_axi_id_by_compe    (sinc_comp_e axi_comp);

  extern virtual function int             get_addr_msb         (sinc_comp_e comp);
  extern virtual function int             get_addr_lsb         (sinc_comp_e comp);
  extern virtual function int             get_key_num         ();

  extern virtual function bit             is_axi_intf_comp        (sinc_comp_e comp);
  extern virtual function bit             is_kli_intf_comp        (sinc_comp_e comp);
  extern virtual function bit             is_mstr_comp            (sinc_comp_e comp);
  extern virtual function bit             is_rp_comp              (sinc_comp_e comp);
  extern virtual function bit             is_sp_comp              (sinc_comp_e comp);
  extern virtual function bit             is_cce_comp             (sinc_comp_e comp);
  extern virtual function bit             is_sha_comp             (sinc_comp_e comp);
  extern virtual function bit             is_pka_comp             (sinc_comp_e comp);
  extern virtual function bit             is_aes_comp             (sinc_comp_e comp);
  extern virtual function bit             is_msb_comp             (sinc_comp_e comp);
  extern virtual function bit             is_kli_comp             (sinc_comp_e comp);
  extern virtual function bit             is_sinc_reg_comp         (sinc_comp_e comp);
  extern virtual function bit             is_ksb_comp             (sinc_comp_e comp);

  extern virtual function bit             is_key_comp             (sinc_comp_e comp);
  extern virtual function bit             is_attr_comp            (sinc_comp_e comp);
  extern virtual function bit             is_pcr_comp             (sinc_comp_e comp);

  // ********************************************************************************
  // Function: is_aligned_addr
  // return true if given address is aligned
  extern virtual function bit is_aligned_addr(address_t addr, bit is_pcr=0);

  // ********************************************************************************
  // Function: is_valid_req
  // return true if given request is valid
  extern virtual function bit is_valid_req(sinc_comp_e req_src, comp_type_e req_dst, sinc_cmd_e req_cmd);

endclass : sinc_sys_cfg // }

//-----------------------------------------------------------------
// Function: dump_sys_cfg
//   Dumps to stdout system config info
//
function void sinc_sys_cfg::dump_sys_cfg ();
  string  str;
  int     idx=1;
  str = $sformatf("this sim has %0d total components:\n",
                  _comp_list.size());
  foreach (_comp_list[i]) begin
    sinc_comp_e comp = _comp_list[i];
    str = $sformatf("%0s%0d) Component: %0s \n", str, idx, comp.name());
    idx++;
  end
  `uvm_info("SINC_SYS_CFG/COMPONENTS", str, UVM_NONE);

endfunction : dump_sys_cfg

//-----------------------------------------------------------------
// Function: validate_comp
//   Errors out if supplied component is not legal in this build
//
function void sinc_sys_cfg::validate_comp (sinc_comp_e comp);
  if (!is_valid_comp(comp)) begin
    $stacktrace;
    `uvm_error("validate_comp: illegal component name",
              $sformatf("sinc_sys_cfg::validate_comp() does not recognize component '%0s' [0x%0d]. Maybe this resides outside enabled %0d SINCs. Search this log file for [SINC_SYS_CFG/COMPONENTS] for a list of all present SINC components",
                comp.name(), comp, num_sinc))
  end
endfunction : validate_comp

//-----------------------------------------------------------------
// Function: is_valid_comp
//  returns true if this component is present in this config
//
function bit sinc_sys_cfg::is_valid_comp (sinc_comp_e comp);
  is_valid_comp = comp_cfg.exists(comp);
endfunction : is_valid_comp

//-----------------------------------------------------------------
// Function: get_comp_index
//  returns the component's index. 
//
function int sinc_sys_cfg::get_comp_index (sinc_comp_e comp);
  validate_comp (comp);
  get_comp_index = comp_cfg[comp].port_num;
endfunction : get_comp_index

//-----------------------------------------------------------------
// Function: get_comp_addr_width
//  returns the component's address width
//
function int sinc_sys_cfg::get_comp_addr_width (sinc_comp_e comp);
  validate_comp (comp);
  get_comp_addr_width = comp_cfg[comp].addr_width;
endfunction : get_comp_addr_width

//-----------------------------------------------------------------
// Function: get_comp_addr_mask
//  returns the component's address bit mask
//
function longint unsigned sinc_sys_cfg::get_comp_addr_mask (sinc_comp_e comp);
  validate_comp (comp);
  get_comp_addr_mask = comp_cfg[comp].addr_mask;
endfunction : get_comp_addr_mask

//-----------------------------------------------------------------
// Function: get_comp_cfg
//  returns the component's config object which contains all the attributes
//  about the specified component.
//
function sinc_comp_cfg sinc_sys_cfg::get_comp_cfg (sinc_comp_e comp);
  validate_comp (comp);
  get_comp_cfg = comp_cfg[comp];
endfunction : get_comp_cfg

//-----------------------------------------------------------------
// Function: get_comp_cfg_from_comp_type
//  returns the component's config object which contains all the attributes
//  about the specified component.
//
function sinc_comp_cfg sinc_sys_cfg::get_comp_cfg_from_comp_type (comp_type_e comp_type);
  sinc_comp_e comp;
  sinc_comp_list_t comp_list;

  comp_list = get_comp_list(comp_type);
  comp = comp_list.pop_front();
  validate_comp (comp);
  get_comp_cfg_from_comp_type = comp_cfg[comp];
endfunction : get_comp_cfg_from_comp_type

function sinc_comp_cfg sinc_sys_cfg::get_comp_cfg_from_comp_type_vcs (comp_type_e comp_type);
  sinc_comp_e comp;
  sinc_comp_list_t comp_list;

  comp_list = get_comp_list_vcs(comp_type);
  comp = comp_list.pop_front();
  //validate_comp (comp);
  get_comp_cfg_from_comp_type_vcs = comp_cfg[comp];
endfunction : get_comp_cfg_from_comp_type_vcs

//-----------------------------------------------------------------
// Function: get_comp_from_string
//  Returns comp_id from a string
function sinc_comp_e sinc_sys_cfg::get_comp_from_string (string name);
  foreach(comp_cfg[comp_id])   begin
    if(comp_id.name() == name) begin return(comp_id); end
  end
  return sinc_env_pkg::SINC_NULL;
endfunction : get_comp_from_string

//-----------------------------------------------------------------
// Function: get_hdl_path
//  returns the HDL verilog path to this component instance
//
function string sinc_sys_cfg::get_hdl_path (sinc_comp_e comp);
  validate_comp (comp);

  if (comp_cfg[comp].hdl_path == "") begin
    $stacktrace;
    `uvm_error("get_hdl_path: NULL_PATH",
              $sformatf("get_hdl_path::comp %0s has NULL hdl_path", comp.name()))
  end
  get_hdl_path = comp_cfg[comp].hdl_path;
endfunction : get_hdl_path

//-----------------------------------------------------------------
// Function: get_valid_cmd_types
//  Returns a list of components present on the test unit.
//
function req_cmd_list_t sinc_sys_cfg::get_valid_cmd_types (sinc_comp_e src_comp, comp_type_e dst_comp_type);
  req_cmd_list_t valid_cmd_type_list;
  sinc_comp_cfg dst_comp_cfg;

  `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s ", src_comp.name(), dst_comp_type.name()), UVM_DEBUG);

  dst_comp_cfg = get_comp_cfg_from_comp_type(dst_comp_type);
  valid_cmd_type_list = dst_comp_cfg.valid_master_cmd_list[get_comp_type(src_comp)];
  if (valid_cmd_type_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s has no access cmd type", src_comp.name(), dst_comp_type.name()), UVM_LOW);
  end else begin
    foreach (valid_cmd_type_list[i]) begin
      `uvm_info("sinc_sys_config:", $sformatf("has access cmd type %0s", valid_cmd_type_list[i].name()), UVM_DEBUG);
    end
  end

  
  return valid_cmd_type_list;
endfunction : get_valid_cmd_types

function sinc_cmd_e sinc_sys_cfg::get_valid_cmd_type (sinc_comp_e src_comp, comp_type_e dst_comp_type);
  req_cmd_list_t valid_cmd_type_list;
  sinc_comp_cfg dst_comp_cfg;
  sinc_cmd_e sinc_cmd;
 
  //`uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s ", src_comp.name(), dst_comp_type.name()), UVM_DEBUG);

  dst_comp_cfg = get_comp_cfg_from_comp_type_vcs(dst_comp_type);
  valid_cmd_type_list = dst_comp_cfg.valid_master_cmd_list[get_comp_type_vcs(src_comp)];
  if (valid_cmd_type_list.size() == 0) begin
    //`uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, dst_comp:%0s has no access cmd type", src_comp.name(), dst_comp_type.name()), UVM_LOW);
  end else begin
    int rand_index = $urandom_range(valid_cmd_type_list.size()-1, 0);
    
    sinc_cmd = valid_cmd_type_list[rand_index];
    
    foreach (valid_cmd_type_list[i]) begin
      //`uvm_info("sinc_sys_config:", $sformatf("has access cmd type %0s", valid_cmd_type_list[i].name()), UVM_DEBUG);
    end
  end

  return sinc_cmd;
endfunction : get_valid_cmd_type

//-----------------------------------------------------------------
// Function: get_valid_access_comp_types
//  Returns a list of KSB components present on the test unit.
//
function comp_type_list_t sinc_sys_cfg::get_valid_access_comp_types(sinc_comp_e src_comp);
  comp_type_list_t valid_comp_type_list;
  req_cmd_list_t valid_cmd_type_list;
  sinc_comp_cfg src_cfg;

  `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_DEBUG);

  src_cfg = get_comp_cfg(src_comp);
  valid_comp_type_list = src_cfg.valid_ksb_access_comp_list;
  if (valid_comp_type_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_LOW);
  end else begin
    foreach (valid_comp_type_list[i]) begin
      `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_DEBUG);
    end
  end
  
  return valid_comp_type_list;
endfunction : get_valid_access_comp_types

function comp_type_e sinc_sys_cfg::get_valid_access_comp_type(sinc_comp_e src_comp);
  comp_type_list_t valid_comp_type_list;
  req_cmd_list_t valid_cmd_type_list;
  sinc_comp_cfg src_cfg;
  comp_type_e comp_type = COMP_NULL;

  `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_HIGH);

  src_cfg = comp_cfg[src_comp];;
  valid_comp_type_list = src_cfg.valid_ksb_access_comp_list;
  if (valid_comp_type_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_HIGH);
  end else begin
    
    int rand_index = $urandom_range(valid_comp_type_list.size()-1, 0);
    
    comp_type = valid_comp_type_list[rand_index];
    
    foreach (valid_comp_type_list[i]) begin
       `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_HIGH);
    end
  end
  
  return comp_type;
endfunction : get_valid_access_comp_type

//-----------------------------------------------------------------
// Function: get_valid_src_comp
//  Returns a list of KSB components present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_valid_src_comp(sinc_comp_e dst_comp);
  comp_type_list_t valid_src_list;
  sinc_comp_cfg dst_cfg;
  sinc_comp_list_t valid_comp_e_list;

  `uvm_info("sinc_sys_config:", $sformatf("dst_comp :%0s", dst_comp.name()), UVM_DEBUG);

  dst_cfg = get_comp_cfg(dst_comp);
  valid_src_list = dst_cfg.valid_mstr_list;

  if (valid_src_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("dst_comp :%0s, can not be accessed by any src", dst_comp.name()), UVM_LOW);
  end else begin
    foreach (valid_src_list[i]) begin
      sinc_comp_list_t comp_list;
      `uvm_info("sinc_sys_config:", $sformatf("%0s has access component to %0s ", valid_src_list[i].name(), dst_comp.name()), UVM_DEBUG);
      comp_list = get_comp_list(valid_src_list[i]);
      foreach (comp_list[j]) begin
        valid_comp_e_list.push_back(comp_list[j]);
      end
    end
  end
  
  return valid_comp_e_list;
endfunction : get_valid_src_comp

//-----------------------------------------------------------------
// Function: get_all_valid_access_comp_types
//  Returns a list of all components present on the test unit.
//
function comp_type_list_t sinc_sys_cfg::get_all_valid_access_comp_types(sinc_comp_e src_comp);
  comp_type_list_t valid_comp_type_list;
  req_cmd_list_t valid_cmd_type_list;
  sinc_comp_cfg src_cfg;

  `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s", src_comp.name()), UVM_DEBUG);

  src_cfg = get_comp_cfg(src_comp);
  valid_comp_type_list = src_cfg.valid_sinc_access_comp_list;
  if (valid_comp_type_list.size() == 0) begin
    `uvm_info("sinc_sys_config:", $sformatf("src_comp :%0s, has no access to any KSB components", src_comp.name()), UVM_LOW);
  end else begin
    foreach (valid_comp_type_list[i]) begin
      `uvm_info("sinc_sys_config:", $sformatf("has access component: %0s", valid_comp_type_list[i].name()), UVM_DEBUG);
    end
  end
  
  return valid_comp_type_list;
endfunction : get_all_valid_access_comp_types


//-----------------------------------------------------------------
// Function: get_full_comp_list
//  Returns a list of components present on the test unit.
//
function sinc_comp_list_t sinc_sys_cfg::get_full_comp_list ();
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  return _comp_list;
endfunction : get_full_comp_list

//-----------------------------------------------------------------
// Function: get_comp_list
//  Returns a list of components present on SINC. 
//

function sinc_comp_list_t sinc_sys_cfg::get_comp_list (comp_type_e comp_id=COMP_NULL);
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  `uvm_info("sinc_sys_config:", $sformatf("get_comp_list for comp_type:%0s ", comp_id.name()), UVM_HIGH);
  foreach (_comp_list[i]) begin
    comp = _comp_list[i];
    if((comp_id==COMP_NULL)||((comp_id!=COMP_NULL) && (get_comp_type_vcs(comp)==comp_id))) 
      begin
       `uvm_info("sinc_sys_config:", $sformatf("push comp_e:%0s ", comp.name()), UVM_HIGH);
      comp_list.push_back(comp);
    end
  end

  return comp_list;
endfunction : get_comp_list

//-----------------------------------------------------------------
// Function: get_key_comp_list
//  returns a list of key components present.
//
function sinc_comp_list_t sinc_sys_cfg::get_key_comp_list ();
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  foreach (_comp_list[i]) begin
    comp = _comp_list[i];
    if (comp_cfg[comp].is_ksb_key) begin
      comp_list.push_back(comp);
    end
  end
  return comp_list;
endfunction : get_key_comp_list

//-----------------------------------------------------------------
// Function: get_sp_comp_list
//  returns a list of Security Processor components present.
//
function sinc_comp_list_t sinc_sys_cfg::get_sp_comp_list ();
  sinc_comp_e      comp;
  sinc_comp_list_t comp_list;

  foreach (_comp_list[i]) begin
    comp = _comp_list[i];
    if (comp_cfg[comp].is_sp) begin
      comp_list.push_back(comp);
    end
  end
  return comp_list;
endfunction : get_sp_comp_list


//-----------------------------------------------------------------
// Function: get_mstr_comp_type
//  returns master component type comp_type_e for provided component.
//
function mstr_type_e sinc_sys_cfg::get_mstr_comp_type (sinc_comp_e comp);
/*
  if (comp_cfg.exists(comp)) begin
      if (comp_cfg[comp].is_sp) return sinc_env_pkg::MSTR_SP;
      if (comp_cfg[comp].is_cce) return sinc_env_pkg::MSTR_CCE;
      if (comp_cfg[comp].is_sha) return sinc_env_pkg::MSTR_SHA;
      if (comp_cfg[comp].is_pka) return sinc_env_pkg::MSTR_PKA;
      if (comp_cfg[comp].is_aes) return sinc_env_pkg::MSTR_AES;
  end
  else begin
    $stacktrace;
    `uvm_error("get_mstr_comp_type: illegal component specified",
              $sformatf("sinc_sys_cfg::get_mstr_comp_type() supplied comp=%0h is not a legal component",
                comp))
  end

  $stacktrace;
  `uvm_error("get_mstr_comp_type: illegal master component specified",
              $sformatf("sinc_sys_cfg::get_mstr_comp_type() supplied comp %0s is not a master type",
                comp.name()))
  return mstr_type_e'(0);
 */
endfunction : get_mstr_comp_type


//-----------------------------------------------------------------
// Function: get_slv_comp_type
//  returns slave component type like KEY, ATTR, PCR, REG
//
function comp_type_e sinc_sys_cfg::get_slv_comp_type     (sinc_comp_e comp);

  if (comp_cfg.exists(comp)) begin
      if (comp_cfg[comp].is_ksb_key) return sinc_env_pkg::COMP_KSB_KEY;
      if (comp_cfg[comp].is_ksb_attr) return sinc_env_pkg::COMP_KSB_ATTR;
      if (comp_cfg[comp].is_ksb_pcr) return sinc_env_pkg::COMP_KSB_PCR;
      if (comp_cfg[comp].is_reg) return sinc_env_pkg::COMP_REG;
  end
  else begin
    $stacktrace;
    `uvm_error("get_slv_comp_type: illegal component specified",
              $sformatf("sinc_sys_cfg::get_slv_comp_type() supplied comp=%0h is not a legal component",
                comp))
  end

  $stacktrace;
  `uvm_error("get_slv_comp_type: illegal slave component specified",
              $sformatf("sinc_sys_cfg::get_slv_comp_type() supplied comp %0s is not a slave type",
                comp.name()))
  return comp_type_e'(0);
endfunction : get_slv_comp_type

  
//-----------------------------------------------------------------
// Function: get_first_mstr_comp
//  returns first master component present on SINC.
//
function sinc_comp_e sinc_sys_cfg::get_first_mstr_comp ();
  sinc_comp_e      comp;

  foreach (_comp_list[i]) begin
    comp = _comp_list[i];
    if (comp_cfg[comp].is_master) return comp;
  end

  $stacktrace;
  `uvm_error("get_first_mstr_comp: master component not present",
             $sformatf("sinc_sys_cfg::get_first_mstr_comp() master component is not present on SINC"))
  return SINC_NULL;
endfunction : get_first_mstr_comp

//-----------------------------------------------------------------
// Function: is_axi_intf_comp
//  returns true if supplied comp is using AXI interface.
//
function bit sinc_sys_cfg::is_axi_intf_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_axi_intf;
endfunction : is_axi_intf_comp

//-----------------------------------------------------------------
// Function: is_kli_intf_comp
//  returns true if supplied comp is using KLI interface.
//
function bit sinc_sys_cfg::is_kli_intf_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_kli_intf;
endfunction : is_kli_intf_comp

//-----------------------------------------------------------------
// Function: is_rp_comp
//  returns true if supplied comp enum is a RP type.
//
function bit sinc_sys_cfg::is_rp_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_rp;
endfunction : is_rp_comp


//-----------------------------------------------------------------
// Function: is_sp_comp
//  returns true if supplied comp enum is a SP type.
//
function bit sinc_sys_cfg::is_sp_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_sp;
endfunction : is_sp_comp

//-----------------------------------------------------------------
// Function: is_cce_comp
//  returns true if supplied comp enum is a CCE type.
//
function bit sinc_sys_cfg::is_cce_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_cce;
endfunction : is_cce_comp

//-----------------------------------------------------------------
// Function: is_sha_comp
//  returns true if supplied comp enum is a SHA type.
//
function bit sinc_sys_cfg::is_sha_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_sha;
endfunction : is_sha_comp

//-----------------------------------------------------------------
// Function: is_pka_comp
//  returns true if supplied comp enum is a PKA type.
//
function bit sinc_sys_cfg::is_pka_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_pka;
endfunction : is_pka_comp

//-----------------------------------------------------------------
// Function: is_aes_comp
//  returns true if supplied comp enum is a AES type.
//
function bit sinc_sys_cfg::is_aes_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_aes;
endfunction : is_aes_comp

//-----------------------------------------------------------------
// Function: is_msb_comp
//  returns true if supplied comp enum is a MSB type.
//
function bit sinc_sys_cfg::is_msb_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_msb;
endfunction : is_msb_comp

//-----------------------------------------------------------------
// Function: is_kli_comp
//  returns true if supplied comp enum is a KLI type.
//
function bit sinc_sys_cfg::is_kli_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_kli;
endfunction : is_kli_comp

//-----------------------------------------------------------------
// Function: is_sinc_reg_comp
//  returns true if supplied comp enum is a SINC_REG type.
//
function bit sinc_sys_cfg::is_sinc_reg_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_reg;
endfunction : is_sinc_reg_comp


//-----------------------------------------------------------------
// Function: is_ksb_comp
//  returns true if supplied comp enum is a KSB type.
//
function bit sinc_sys_cfg::is_ksb_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_ksb;
endfunction : is_ksb_comp
  
//-----------------------------------------------------------------
// Function: is_key_comp
//  returns true if supplied comp enum is a KEY type.
//

function bit sinc_sys_cfg::is_key_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_ksb_key;
endfunction : is_key_comp


//-----------------------------------------------------------------
// Function: is_attr_comp
//  returns true if supplied comp enum is a ATTR type.
//

function bit sinc_sys_cfg::is_attr_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_ksb_attr;
endfunction : is_attr_comp


//-----------------------------------------------------------------
// Function: is_pcr_comp
//  returns true if supplied comp enum is a PCR type.
//

function bit sinc_sys_cfg::is_pcr_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_ksb_pcr;
endfunction : is_pcr_comp

//-----------------------------------------------------------------
// Function: is_aligned_addr
//
function bit sinc_sys_cfg::is_aligned_addr(address_t addr, bit is_pcr);
  address_t byte_addr;
  if (is_pcr) begin
    byte_addr = addr % 8'h20;
    `uvm_info("SYS_CFG_DEBUG", $sformatf("add:%0h , byte_addr:%0d", addr, byte_addr),  UVM_DEBUG)
    if ((addr % 8'h4) == 0) begin
      return 1;
    end else begin
      return 0;
    end
  end else begin
    if ((addr % 8'h20) == 0) begin
      return 1;
    end else begin
      return 0;
    end
  end

endfunction : is_aligned_addr

//-----------------------------------------------------------------
// Function: is_valid_req
//
function bit sinc_sys_cfg::is_valid_req(sinc_comp_e req_src, comp_type_e req_dst, sinc_cmd_e req_cmd);
  bit is_valid_dst = 0;
  bit is_valid_cmd = 0;
  comp_type_list_t valid_dst_comp_type_list;
  req_cmd_list_t valid_cmd_type_list;
  if (!is_valid_comp (req_src)) begin
    return 0;
  end

  if (req_dst == COMP_NULL) begin
    return 0;
  end

  valid_dst_comp_type_list = get_all_valid_access_comp_types(req_src);
  valid_cmd_type_list = get_valid_cmd_types(req_src, req_dst);

  foreach (valid_dst_comp_type_list[i]) begin
    if (valid_dst_comp_type_list[i] == req_dst) begin
      is_valid_dst = 1;
    end
  end

  foreach (valid_cmd_type_list[i]) begin
    if (valid_cmd_type_list[i] == req_cmd) begin
      is_valid_cmd = 1;
    end
  end

  return is_valid_dst && is_valid_cmd;
  
endfunction : is_valid_req
  
//-----------------------------------------------------------------
// Function: get_comp_type
// Returns component type of enum. This should go to sys cfg
// Component types should be leaf level without subtypes
function comp_type_e sinc_sys_cfg::get_comp_type(sinc_comp_e comp);
  //  `uvm_info("sinc_sys_config:", $sformatf("get_comp_type for comp_e:%0s ", comp.name()), UVM_HIGH);
  if      (is_rp_comp(comp))      return(COMP_RP);
  if      (is_sp_comp(comp))      return(COMP_SP);
  else if (is_cce_comp(comp))      return(COMP_CCE);
  else if (is_sha_comp(comp))     return(COMP_SHA);
  else if (is_pka_comp(comp))      return(COMP_PKA);
  else if (is_aes_comp(comp))      return(COMP_AES);
  else if (is_msb_comp(comp))      return(COMP_MSB);
  //  else if (is_ksb_comp(comp))    return(COMP_KSB);
  else if (is_kli_comp(comp))    return(COMP_KLI);
  else if (is_sinc_reg_comp(comp))    return(COMP_REG);
  else if (is_key_comp(comp))    return(COMP_KSB_KEY);
  else if (is_attr_comp(comp))      return(COMP_KSB_ATTR);
  else if (is_pcr_comp(comp))  return(COMP_KSB_PCR);
  `uvm_error("get_comp_type",$sformatf("Unknown component type for %s\n",comp));
endfunction

function comp_type_e sinc_sys_cfg::get_comp_type_vcs(sinc_comp_e comp);
  //  `uvm_info("sinc_sys_config:", $sformatf("get_comp_type for comp_e:%0s ", comp.name()), UVM_HIGH);
  if      (comp_cfg[comp].is_rp)      return(COMP_RP);
  if      (comp_cfg[comp].is_sp)      return(COMP_SP);
  else if (comp_cfg[comp].is_cce)      return(COMP_CCE);
  else if (comp_cfg[comp].is_sha)     return(COMP_SHA);
  else if (comp_cfg[comp].is_pka)      return(COMP_PKA);
  else if (comp_cfg[comp].is_aes)      return(COMP_AES);
  else if (comp_cfg[comp].is_msb)      return(COMP_MSB);
  //  else if (is_ksb_comp(comp))    return(COMP_KSB);
  else if (comp_cfg[comp].is_kli)    return(COMP_KLI);
  else if (comp_cfg[comp].is_reg)    return(COMP_REG);
  else if (comp_cfg[comp].is_ksb_key)    return(COMP_KSB_KEY);
  else if (comp_cfg[comp].is_ksb_attr)      return(COMP_KSB_ATTR);
  else if (comp_cfg[comp].is_ksb_pcr)  return(COMP_KSB_PCR);
  
endfunction


//-----------------------------------------------------------------
// Function: get_compe_by_axi_id_type
// Returns component type of enum. This should go to sys cfg
// Component types should be leaf level without subtypes
function sinc_comp_e sinc_sys_cfg::get_compe_by_axi_id(int axi_id);
  case (axi_id)
    `SINC__RP0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_RP0;
    end
    `SINC__SP0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_SP0;
    end
    `SINC__CCE0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_CCE0;
    end
    `SINC__SHA0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_SHA0;
    end
    `SINC__PKA0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_PKA0;
    end
    `SINC__AES0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_AES0;
    end
    `SINC__MSB0_FABRIC_ID : begin
      return sinc_env_pkg::SINC_MSB0;
    end
    default : begin
      return sinc_env_pkg::SINC_NULL;
      //`uvm_error("get_comp_type",$sformatf("Unknown axi id %s\n",axi_id))
    end
  endcase 

endfunction

//-----------------------------------------------------------------
// Function: get_mstr_comp_type_by_userbits
// Returns master component type of enum. 
// Component types should be leaf level without subtypes
function mstr_type_e sinc_sys_cfg::get_mstr_comp_type_by_userbits(bit [3:0] axuser);
  case (axuser)
    `SINC__RP_USER : begin
      return sinc_env_pkg::MSTR_RP;
    end
    `SINC__SP_USER : begin
      return sinc_env_pkg::MSTR_SP;
    end
    `SINC__CCE_USER : begin
      return sinc_env_pkg::MSTR_CCE;
    end
    `SINC__SHA_USER : begin
      return sinc_env_pkg::MSTR_SHA;
    end
    `SINC__PKA_USER : begin
      return sinc_env_pkg::MSTR_PKA;
    end
    `SINC__AES_USER : begin
      return sinc_env_pkg::MSTR_AES;
    end
    `SINC__MSB_USER : begin
      return sinc_env_pkg::MSTR_MSB;
    end
    default : begin
      return sinc_env_pkg::MSTR_NULL;
      //`uvm_error("get_comp_type",$sformatf("Unknown axi id %s\n",axi_id))
    end
  endcase 

endfunction

//-----------------------------------------------------------------
// Function: get_src_comp_from_userbits
// Returns src_comp based on the axuser bits
function sinc_comp_e sinc_sys_cfg::get_src_comp_from_userbits (mstr_type_e axuser);
  case(axuser)
    sinc_env_pkg::MSTR_RP : begin
	  return sinc_env_pkg::SINC_RP0;
    end
    sinc_env_pkg::MSTR_SP : begin
	  return sinc_env_pkg::SINC_SP0;
    end
    sinc_env_pkg::MSTR_CCE : begin
	  return sinc_env_pkg::SINC_CCE0;
    end
    sinc_env_pkg::MSTR_SHA : begin
	  return sinc_env_pkg::SINC_SHA0;
    end
    sinc_env_pkg::MSTR_PKA : begin
	  return sinc_env_pkg::SINC_PKA0;
    end
    sinc_env_pkg::MSTR_AES : begin
	  return sinc_env_pkg::SINC_AES0;
	end
	sinc_env_pkg::MSTR_MSB : begin
	  return sinc_env_pkg::SINC_MSB0;
	end
	sinc_env_pkg::MSTR_NULL : begin
	  return sinc_env_pkg::SINC_NULL;
	end
	default : `uvm_error("get_src_comp_from_userbits", $sformatf("Unknown axi comp"))
  endcase
endfunction
//-----------------------------------------------------------------
// Function: get_compe_by_axi_id_type
// Returns component type of enum. This should go to sys cfg
// Component types should be leaf level without subtypes
function int sinc_sys_cfg::get_axi_id_by_compe(sinc_comp_e axi_comp);
  case (axi_comp)
    sinc_env_pkg::SINC_RP0 : begin
      return `SINC__RP_AXI_ID;
    end
    sinc_env_pkg::SINC_SP0 : begin
      return `SINC__SP_AXI_ID;
    end
    sinc_env_pkg::SINC_CCE0 : begin
      return `SINC__CCE_AXI_ID;
    end
    sinc_env_pkg::SINC_SHA0 : begin
      return `SINC__SHA_AXI_ID;
    end
    sinc_env_pkg::SINC_PKA0 : begin
      return `SINC__PKA_AXI_ID;
    end
    sinc_env_pkg::SINC_AES0 : begin
      return `SINC__AES_AXI_ID;
    end
    sinc_env_pkg::SINC_MSB0 : begin
      return `SINC__MSB_AXI_ID;
    end
    default :    `uvm_error("get_comp_type",$sformatf("Unknown axi comp %s\n",axi_comp.name()))
  endcase 
endfunction


//-----------------------------------------------------------------
// Function: is_mstr_comp
//  returns true if supplied comp enum is a master type.
//
function bit sinc_sys_cfg::is_mstr_comp (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].is_master;
endfunction : is_mstr_comp

//-----------------------------------------------------------------
// Function: get_addr_msb
//
function int sinc_sys_cfg::get_addr_msb       (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].addr_msb;
endfunction : get_addr_msb


//-----------------------------------------------------------------
// Function: get_addr_lsb
//
function int sinc_sys_cfg::get_addr_lsb       (sinc_comp_e comp);
  validate_comp (comp);
  return comp_cfg[comp].addr_lsb;
endfunction : get_addr_lsb

//-----------------------------------------------------------------
// Function: get_key_num
//  returns number of keys in the KSB
//
function int sinc_sys_cfg::get_key_num();
  int key_num;

  key_num = sinc_features_pkg::get_feature("KEY_NUM");
  return key_num;
endfunction : get_key_num

//-----------------------------------------------------------------
// Function: init_comp_cfgs
//  Initializes config for each SINC component.
//
function void sinc_sys_cfg::init_comp_cfgs ();
  int key_num = sinc_features_pkg::get_feature("KEY_NUM");
  int attr_num = sinc_features_pkg::get_feature("KEY_NUM");
  int pcr_num = sinc_features_pkg::get_feature("PCR_NUM");
  bit [15:0] key_band_length = sinc_features_pkg::get_feature("KEY_BAND_LENGTH");
  bit [15:0] attr_band_length = sinc_features_pkg::get_feature("ATTR_BAND_LENGTH");
  bit [15:0] pcr_band_length = sinc_features_pkg::get_feature("PCR_BAND_LENGTH");
  int key_base_id;
  int attr_base_id;
  int pcr_base_id;
  int sp_base_id;
  sinc_env_pkg::comp_type_e comp_type;
  sinc_env_pkg::sinc_cmd_e cmd;

  begin
    mstr_type_e mstr_comp = mstr_comp.first();
    while (mstr_comp != mstr_comp.last()) begin
      _comp_master_list.push_back(mstr_comp);
      mstr_comp = mstr_comp.next();
    end
  end


  // config KEY components
  comp_cfg[KSB_KEY0]     = new("KSB_KEY0_comp_cfg");
  comp_cfg[KSB_KEY0].comp_id      = KSB_KEY0;
  comp_cfg[KSB_KEY0].comp_type      = COMP_KSB_KEY;  
  comp_cfg[KSB_KEY0].comp_type_name        = "KEY";
  comp_cfg[KSB_KEY0].type_instance_name    = "KSB_KEY0";
  comp_cfg[KSB_KEY0].instance_id  = 0;
  comp_cfg[KSB_KEY0].start_addr  = get_feature("AXI_KEY_BASE_ADDR");

  // access control configuration for KEY slots, excluding attributes match
  foreach (_comp_master_list[i]) begin
    case (_comp_master_list[i])
      sinc_env_pkg::MSTR_KLI : begin
        if (has_feature("KLI_KEY_RANGES")) begin
          if (sinc_features_pkg::get_feature("KLI_KEY_RANGES") == 1) begin
            comp_type = sinc_env_pkg::COMP_KLI;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("KLI_KEY_WR")) begin
              if (get_feature("KLI_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::KLI_WRITE);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_KLI
      
      sinc_env_pkg::MSTR_RP : begin
        if (has_feature("RP_KEY_RANGES")) begin
          if (get_feature("RP_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_RP;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("RP_KEY_WR")) begin
              if (get_feature("RP_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("RP_KEY_RD")) begin
              if (get_feature("RP_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_RP

      sinc_env_pkg::MSTR_SP: begin
        if (has_feature("SP_KEY_RANGES")) begin
          if (has_feature("SP_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SP;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SP_KEY_WR")) begin
              if (get_feature("SP_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SP_KEY_RD")) begin
              if (get_feature("SP_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SP

      sinc_env_pkg::MSTR_CCE: begin
        if (has_feature("CCE_KEY_RANGES")) begin
          if (get_feature("CCE_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_CCE;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("CCE_KEY_WR")) begin
              if (get_feature("CCE_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("CCE_KEY_RD")) begin
              if (get_feature("CCE_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_CCE

      sinc_env_pkg::MSTR_AES: begin
        if (has_feature("AES_KEY_RANGES")) begin
          if (get_feature("AES_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_AES;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("AES_KEY_WR")) begin
              if (get_feature("AES_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("AES_KEY_RD")) begin
              if (get_feature("AES_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_AES

      sinc_env_pkg::MSTR_PKA: begin
        if (has_feature("PKA_KEY_RANGES")) begin
          if (get_feature("PKA_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_PKA;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("PKA_KEY_WR")) begin
              if (get_feature("PKA_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("PKA_KEY_RD")) begin
              if (get_feature("PKA_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_PKA

      sinc_env_pkg::MSTR_SHA: begin
        if (has_feature("SHA_KEY_RANGES")) begin
          if (get_feature("SHA_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SHA;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SHA_KEY_WR")) begin
              if (get_feature("SHA_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SHA_KEY_RD")) begin
              if (get_feature("SHA_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SHA

      sinc_env_pkg::MSTR_MSB: begin
        if (has_feature("MSB_KEY_RANGES")) begin
          if (get_feature("MSB_KEY_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_MSB;
            comp_cfg[KSB_KEY0].valid_mstr_list.push_back(comp_type);
            if (has_feature("MSB_KEY_WR")) begin
              if (get_feature("MSB_KEY_WR")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("MSB_KEY_RD")) begin
              if (get_feature("MSB_KEY_RD")) begin
                comp_cfg[KSB_KEY0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_MSB

      default :  `uvm_error("INVALID_DST_ADDR_TYPE", $sformatf("Trying to use %0x as master type", _comp_master_list[i]))
    endcase // case (dst_addr_type)
  end // foreach (_comp_master_list[i])

  // config KEY Slots in KSB_KEY0
  //foreach (key_num[id]) begin
  for (int id=0; id < key_num; id++) begin
    string key_id = $sformatf("KEY_SLOT_%0d", id);
    comp_cfg[KSB_KEY0].slot_cfg[id] = new({"SINC", key_id, "comp_cfg"});
    comp_cfg[KSB_KEY0].slot_cfg[id].is_key_slot = 1;
    comp_cfg[KSB_KEY0].slot_cfg[id].comp_type_name = "KEY_SLOT";
    comp_cfg[KSB_KEY0].slot_cfg[id].type_instance_name = key_id;
    comp_cfg[KSB_KEY0].slot_cfg[id].instance_id = id;
    comp_cfg[KSB_KEY0].slot_cfg[id].start_addr = comp_cfg[KSB_KEY0].start_addr + (id * key_band_length);
    comp_cfg[KSB_KEY0].slot_cfg[id].slot_width = sinc_features_pkg::get_feature("KEY_SLOT_WIDTH");
    `uvm_info("sinc_sys_config:", $sformatf("Configure %0s[%0s], with start address: 'h%0h ", comp_cfg[KSB_KEY0].slot_cfg[id].comp_type_name, 
                                           comp_cfg[KSB_KEY0].slot_cfg[id].type_instance_name, comp_cfg[KSB_KEY0].slot_cfg[id].start_addr), UVM_DEBUG);
  end
  comp_cfg[KSB_KEY0].is_master    = 0;
  comp_cfg[KSB_KEY0].is_slave     = 0;
  comp_cfg[KSB_KEY0].is_sp  = 0;
  comp_cfg[KSB_KEY0].is_cce  = 0;
  comp_cfg[KSB_KEY0].is_sha  = 0;
  comp_cfg[KSB_KEY0].is_pka  = 0;
  comp_cfg[KSB_KEY0].is_aes  = 0;
  comp_cfg[KSB_KEY0].is_ksb  = 1;
  comp_cfg[KSB_KEY0].is_ksb_key  = 1;
  comp_cfg[KSB_KEY0].is_ksb_attr  = 0;
  comp_cfg[KSB_KEY0].is_ksb_pcr  = 0;
  
  // access configurations
  comp_cfg[KSB_KEY0].addr_width          = `SINC_KSB_KEYS_WIDTH;
  comp_cfg[KSB_KEY0].addr_mask           = `SINC_KSB_KEYS_MASK;
  comp_cfg[KSB_KEY0].addr_msb            = `SINC_KSB_KEYS_MSB;
  comp_cfg[KSB_KEY0].addr_lsb            = `SINC_KSB_KEYS_LSB;
  
  comp_cfg[KSB_KEY0].num_key_ranges     = key_num;
  
  `uvm_info("new KEY cfg", $sformatf("KEY COMP_CFG = \n%s ",comp_cfg[KSB_KEY0].sprint()), UVM_HIGH);

  // print out valid master list and cmd list for current component
  if (comp_cfg[KSB_KEY0].valid_mstr_list.size() !== 0) begin
    `uvm_info("SINC_SYS_CFG:", $sformatf("valid master list and valid cmd for component :%0s ", comp_cfg[KSB_KEY0].type_instance_name), UVM_HIGH);
    foreach (comp_cfg[KSB_KEY0].valid_master_cmd_list[i]) begin
      `uvm_info("SINC_SYS_CFG:", $sformatf("%0s can be access by %0s with:", comp_cfg[KSB_KEY0].type_instance_name, 
                                          i.name()), UVM_HIGH);
      
      foreach (comp_cfg[KSB_KEY0].valid_master_cmd_list[i,j]) begin
        `uvm_info("SINC_SYS_CFG:", $sformatf("command:%0s", comp_cfg[KSB_KEY0].valid_master_cmd_list[i][j].name()), UVM_HIGH);
      end
    end
  end


  // config ATTR components
  comp_cfg[KSB_ATTR0]     = new("KSB_ATTR0_comp_cfg");
  comp_cfg[KSB_ATTR0].comp_id      = KSB_ATTR0;
  comp_cfg[KSB_ATTR0].comp_type      = COMP_KSB_ATTR;
  comp_cfg[KSB_ATTR0].comp_type_name        = "ATTR";
  comp_cfg[KSB_ATTR0].type_instance_name    = "KSB_ATTR0";
  comp_cfg[KSB_ATTR0].instance_id  = 0;
  comp_cfg[KSB_ATTR0].start_addr  = get_feature("AXI_KEY_BASE_ADDR") + 'h20;

    // access control configuration for ATTR slots, excluding attributes match
  foreach (_comp_master_list[i]) begin
    case (_comp_master_list[i])
      sinc_env_pkg::MSTR_KLI : begin
        if (has_feature("KLI_ATTR_RANGES")) begin
          if (sinc_features_pkg::get_feature("KLI_ATTR_RANGES") == 1) begin
            comp_type = sinc_env_pkg::COMP_KLI;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("KLI_ATTR_WR")) begin
              if (get_feature("KLI_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::KLI_WRITE);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_KLI
      
      sinc_env_pkg::MSTR_RP : begin
        if (has_feature("RP_ATTR_RANGES")) begin
          if (get_feature("RP_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_RP;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("RP_ATTR_WR")) begin
              if (get_feature("RP_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("RP_ATTR_RD")) begin
              if (get_feature("RP_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_RP

      sinc_env_pkg::MSTR_SP: begin
        if (has_feature("SP_ATTR_RANGES")) begin
          if (has_feature("SP_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SP;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SP_ATTR_WR")) begin
              if (get_feature("SP_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SP_ATTR_RD")) begin
              if (get_feature("SP_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SP

      sinc_env_pkg::MSTR_CCE: begin
        if (has_feature("CCE_ATTR_RANGES")) begin
          if (get_feature("CCE_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_CCE;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("CCE_ATTR_WR")) begin
              if (get_feature("CCE_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("CCE_ATTR_RD")) begin
              if (get_feature("CCE_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_CCE

      sinc_env_pkg::MSTR_AES: begin
        if (has_feature("AES_ATTR_RANGES")) begin
          if (get_feature("AES_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_AES;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("AES_ATTR_WR")) begin
              if (get_feature("AES_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("AES_ATTR_RD")) begin
              if (get_feature("AES_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_AES

      sinc_env_pkg::MSTR_PKA: begin
        if (has_feature("PKA_ATTR_RANGES")) begin
          if (get_feature("PKA_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_PKA;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("PKA_ATTR_WR")) begin
              if (get_feature("PKA_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("PKA_ATTR_RD")) begin
              if (get_feature("PKA_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_PKA

      sinc_env_pkg::MSTR_SHA: begin
        if (has_feature("SHA_ATTR_RANGES")) begin
          if (get_feature("SHA_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SHA;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SHA_ATTR_WR")) begin
              if (get_feature("SHA_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SHA_ATTR_RD")) begin
              if (get_feature("SHA_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SHA

      sinc_env_pkg::MSTR_MSB: begin
        if (has_feature("MSB_ATTR_RANGES")) begin
          if (get_feature("MSB_ATTR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_MSB;
            comp_cfg[KSB_ATTR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("MSB_ATTR_WR")) begin
              if (get_feature("MSB_ATTR_WR")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("MSB_ATTR_RD")) begin
              if (get_feature("MSB_ATTR_RD")) begin
                comp_cfg[KSB_ATTR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_MSB

      default :  `uvm_error("INVALID_DST_ADDR_TYPE", $sformatf("Trying to use %0x as master type", _comp_master_list[i]))
    endcase // case (dst_addr_type)
  end // foreach (_comp_master_list[i])


  for (int id=0; id < attr_num; id++) begin
    string attr_id = $sformatf("ATTR_SLOT_%0d", id);
    comp_cfg[KSB_ATTR0].slot_cfg[id] = new({"SINC", attr_id, "comp_cfg"});
    comp_cfg[KSB_ATTR0].slot_cfg[id].is_attr_slot = 1;
    comp_cfg[KSB_ATTR0].slot_cfg[id].comp_type_name = "ATTR_SLOT";
    comp_cfg[KSB_ATTR0].slot_cfg[id].type_instance_name = attr_id;
    comp_cfg[KSB_ATTR0].slot_cfg[id].instance_id = id;
    comp_cfg[KSB_ATTR0].slot_cfg[id].start_addr = comp_cfg[KSB_ATTR0].start_addr + (id * attr_band_length);
    comp_cfg[KSB_ATTR0].slot_cfg[id].slot_width = sinc_features_pkg::get_feature("ATTR_SLOT_WIDTH");
    `uvm_info("sinc_sys_config:", $sformatf("Configure %0s[%0s], with start address: 'h%0h ", comp_cfg[KSB_ATTR0].slot_cfg[id].comp_type_name, 
                                           comp_cfg[KSB_ATTR0].slot_cfg[id].type_instance_name, comp_cfg[KSB_ATTR0].slot_cfg[id].start_addr), UVM_DEBUG);
  end
  comp_cfg[KSB_ATTR0].is_master    = 0;
  comp_cfg[KSB_ATTR0].is_slave     = 0;
  comp_cfg[KSB_ATTR0].is_sp  = 0;
  comp_cfg[KSB_ATTR0].is_cce  = 0;
  comp_cfg[KSB_ATTR0].is_sha  = 0;
  comp_cfg[KSB_ATTR0].is_pka  = 0;
  comp_cfg[KSB_ATTR0].is_aes  = 0;
  comp_cfg[KSB_ATTR0].is_ksb  = 1;
  comp_cfg[KSB_ATTR0].is_ksb_attr  = 1;
  comp_cfg[KSB_ATTR0].is_ksb_key  = 0;
  comp_cfg[KSB_ATTR0].is_ksb_pcr  = 0;
  
  // access configurations
  /*
  comp_cfg[KSB_ATTR0].len_width           = `SINC__KEY_SIZE;
  comp_cfg[KSB_ATTR0].addr_width          = `SINC__KEY_ADDR__SIZE;
  comp_cfg[KSB_ATTR0].addr_mask           = `SINC__KEY_ADDR_MASK;
  comp_cfg[KSB_ATTR0].addr_msb            = `SINC__KEY_ADDR_MSB;
  comp_cfg[KSB_ATTR0].addr_lsb            = `SINC__KEY_ADDR_LSB;
  comp_cfg[KSB_ATTR0].data_width          = `SINC__KEY_DATA_SIZE;
  */
  comp_cfg[KSB_ATTR0].num_attr_ranges     = attr_num;
  
  `uvm_info("new ATTR cfg", $sformatf("ATTR COMP_CFG = \n%s ",comp_cfg[KSB_ATTR0].sprint()), UVM_HIGH);

  // print out valid master list and cmd list for current component
  if (comp_cfg[KSB_ATTR0].valid_mstr_list.size() !== 0) begin
    `uvm_info("SINC_SYS_CFG:", $sformatf("valid master list and valid cmd for component :%0s ", comp_cfg[KSB_ATTR0].type_instance_name), UVM_HIGH);
    foreach (comp_cfg[KSB_ATTR0].valid_master_cmd_list[i]) begin
      `uvm_info("SINC_SYS_CFG:", $sformatf("%0s can be access by %0s with:", comp_cfg[KSB_ATTR0].type_instance_name, 
                                          i.name()), UVM_HIGH);
      
      foreach (comp_cfg[KSB_ATTR0].valid_master_cmd_list[i,j]) begin
        `uvm_info("SINC_SYS_CFG:", $sformatf("command:%0s", comp_cfg[KSB_ATTR0].valid_master_cmd_list[i][j].name()), UVM_HIGH);
      end
    end
  end


  // config PCR components
  comp_cfg[KSB_PCR0]     = new("KSB_PCR0_comp_cfg");
  comp_cfg[KSB_PCR0].comp_id      = KSB_PCR0;
  comp_cfg[KSB_PCR0].comp_type      = COMP_KSB_PCR;
  comp_cfg[KSB_PCR0].comp_type_name        = "PCR";
  comp_cfg[KSB_PCR0].type_instance_name    = "KSB_PCR0";
  comp_cfg[KSB_PCR0].instance_id  = 0;
  comp_cfg[KSB_PCR0].start_addr  = get_feature("AXI_PCR_BASE_ADDR");

  // access control configuration for PCR slots, excluding attributes match
    foreach (_comp_master_list[i]) begin
    case (_comp_master_list[i])
      sinc_env_pkg::MSTR_KLI : begin
        if (has_feature("KLI_PCR_RANGES")) begin
          if (sinc_features_pkg::get_feature("KLI_PCR_RANGES") == 1) begin
            comp_type = sinc_env_pkg::COMP_KLI;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("KLI_PCR_WR")) begin
              if (get_feature("KLI_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::KLI_WRITE);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_KLI
      
      sinc_env_pkg::MSTR_RP : begin
        if (has_feature("RP_PCR_RANGES")) begin
          if (get_feature("RP_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_RP;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("RP_PCR_WR")) begin
              if (get_feature("RP_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("RP_PCR_RD")) begin
              if (get_feature("RP_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_RP

      sinc_env_pkg::MSTR_SP: begin
        if (has_feature("SP_PCR_RANGES")) begin
          if (has_feature("SP_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SP;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SP_PCR_WR")) begin
              if (get_feature("SP_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SP_PCR_RD")) begin
              if (get_feature("SP_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SP

      sinc_env_pkg::MSTR_CCE: begin
        if (has_feature("CCE_PCR_RANGES")) begin
          if (get_feature("CCE_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_CCE;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("CCE_PCR_WR")) begin
              if (get_feature("CCE_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("CCE_PCR_RD")) begin
              if (get_feature("CCE_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_CCE

      sinc_env_pkg::MSTR_AES: begin
        if (has_feature("AES_PCR_RANGES")) begin
          if (get_feature("AES_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_AES;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("AES_PCR_WR")) begin
              if (get_feature("AES_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("AES_PCR_RD")) begin
              if (get_feature("AES_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_AES

      sinc_env_pkg::MSTR_PKA: begin
        if (has_feature("PKA_PCR_RANGES")) begin
          if (get_feature("PKA_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_PKA;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("PKA_PCR_WR")) begin
              if (get_feature("PKA_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("PKA_PCR_RD")) begin
              if (get_feature("PKA_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_PKA

      sinc_env_pkg::MSTR_SHA: begin
        if (has_feature("SHA_PCR_RANGES")) begin
          if (get_feature("SHA_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SHA;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SHA_PCR_WR")) begin
              if (get_feature("SHA_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SHA_PCR_RD")) begin
              if (get_feature("SHA_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SHA

      sinc_env_pkg::MSTR_MSB: begin
        if (has_feature("MSB_PCR_RANGES")) begin
          if (get_feature("MSB_PCR_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_MSB;
            comp_cfg[KSB_PCR0].valid_mstr_list.push_back(comp_type);
            if (has_feature("MSB_PCR_WR")) begin
              if (get_feature("MSB_PCR_WR")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("MSB_PCR_RD")) begin
              if (get_feature("MSB_PCR_RD")) begin
                comp_cfg[KSB_PCR0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_MSB

      default :  `uvm_error("INVALID_DST_ADDR_TYPE", $sformatf("Trying to use %0x as master type", _comp_master_list[i]))
    endcase // case (dst_addr_type)
  end // foreach (_comp_master_list[i])


  for (int id=0; id < pcr_num; id++) begin
    string pcr_id = $sformatf("PCR_SLOT_%0d", id);
    comp_cfg[KSB_PCR0].slot_cfg[id] = new({"SINC", pcr_id, "comp_cfg"});
    comp_cfg[KSB_PCR0].slot_cfg[id].is_pcr_slot = 1;
    comp_cfg[KSB_PCR0].slot_cfg[id].comp_type_name = "PCR_SLOT";
    comp_cfg[KSB_PCR0].slot_cfg[id].type_instance_name = pcr_id;
    comp_cfg[KSB_PCR0].slot_cfg[id].instance_id = id;
    comp_cfg[KSB_PCR0].slot_cfg[id].start_addr = comp_cfg[KSB_PCR0].start_addr + (id * pcr_band_length);
    comp_cfg[KSB_PCR0].slot_cfg[id].slot_width = sinc_features_pkg::get_feature("PCR_SLOT_WIDTH");
    `uvm_info("sinc_sys_config:", $sformatf("Configure %0s[%0s], with start address: 'h%0h ", comp_cfg[KSB_PCR0].slot_cfg[id].comp_type_name, 
                                           comp_cfg[KSB_PCR0].slot_cfg[id].type_instance_name, comp_cfg[KSB_PCR0].slot_cfg[id].start_addr), UVM_DEBUG);
  end
  comp_cfg[KSB_PCR0].is_master    = 0;
  comp_cfg[KSB_PCR0].is_slave     = 0;
  comp_cfg[KSB_PCR0].is_sp  = 0;
  comp_cfg[KSB_PCR0].is_cce  = 0;
  comp_cfg[KSB_PCR0].is_sha  = 0;
  comp_cfg[KSB_PCR0].is_pka  = 0;
  comp_cfg[KSB_PCR0].is_aes  = 0;
  comp_cfg[KSB_PCR0].is_ksb  = 1;
  comp_cfg[KSB_PCR0].is_ksb_key  = 0;
  comp_cfg[KSB_PCR0].is_ksb_attr  = 0;
  comp_cfg[KSB_PCR0].is_ksb_pcr  = 1;
  
  // access configurations
  comp_cfg[KSB_PCR0].len_width           = `SINC_KSB_PCRS_SIZE;
  comp_cfg[KSB_PCR0].addr_width          = `SINC_KSB_KEYS_WIDTH;
  comp_cfg[KSB_PCR0].addr_mask           = `SINC_KSB_PCRS_MASK;
  comp_cfg[KSB_PCR0].addr_msb            = `SINC_KSB_PCRS_MSB;
  comp_cfg[KSB_PCR0].addr_lsb            = `SINC_KSB_PCRS_LSB;
  // comp_cfg[KSB_PCR0].data_width          = `SINC__PCR_DATA_SIZE;
  
  comp_cfg[KSB_PCR0].num_pcr_ranges     = pcr_num;
  
  `uvm_info("new PCR cfg", $sformatf("PCR COMP_CFG = \n%s ",comp_cfg[KSB_PCR0].sprint()), UVM_HIGH);

    // print out valid master list and cmd list for current component
  if (comp_cfg[KSB_PCR0].valid_mstr_list.size() !== 0) begin
    `uvm_info("SINC_SYS_CFG:", $sformatf("valid master list and valid cmd for component :%0s ", comp_cfg[KSB_PCR0].type_instance_name), UVM_HIGH);
    foreach (comp_cfg[KSB_PCR0].valid_master_cmd_list[i]) begin
      `uvm_info("SINC_SYS_CFG:", $sformatf("%0s can be access by %0s with:", comp_cfg[KSB_PCR0].type_instance_name, 
                                          i.name()), UVM_HIGH);
      
      foreach (comp_cfg[KSB_PCR0].valid_master_cmd_list[i,j]) begin
        `uvm_info("SINC_SYS_CFG:", $sformatf("command:%0s", comp_cfg[KSB_PCR0].valid_master_cmd_list[i][j].name()), UVM_HIGH);
      end
    end
  end

    ////////////////////////// config SINC Register  /////////////////////////////////////
  comp_cfg[SINC_REG0]              = new("SINC_REG0_comp_cfg");
  comp_cfg[SINC_REG0].comp_id      = SINC_REG0;
  comp_cfg[SINC_REG0].comp_type      = COMP_REG;
  comp_cfg[SINC_REG0].comp_type_name        = "REG";
  comp_cfg[SINC_REG0].type_instance_name    = "SINC_REG0";
  comp_cfg[SINC_REG0].instance_id  = 0;
  comp_cfg[SINC_REG0].is_master    = 0;
  comp_cfg[SINC_REG0].is_slave     = 0;
  comp_cfg[SINC_REG0].is_axi_intf = 1;
  comp_cfg[SINC_REG0].is_reg  = 1;
  
  // interface parameters
  
  comp_cfg[SINC_REG0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");
  comp_cfg[SINC_REG0].start_addr           = sinc_features_pkg::get_feature("AXI_REG_BASE_ADDR");
  comp_cfg[SINC_REG0].data_width            = sinc_features_pkg::get_feature("AXI_REG_LIMIT_ADDR");

    // access control configuration for SINC Registers
    foreach (_comp_master_list[i]) begin
    case (_comp_master_list[i])
      sinc_env_pkg::MSTR_KLI : begin
        if (has_feature("KLI_REG_RANGES")) begin
          if (sinc_features_pkg::get_feature("KLI_REG_RANGES") == 1) begin
            // KLI doesn't support register access
          end
        end
      end // case: sinc_env_pkg::MSTR_KLI
      
      sinc_env_pkg::MSTR_RP : begin
        if (has_feature("RP_REG_RANGES")) begin
          if (get_feature("RP_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_RP;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("RP_REG_WR")) begin
              if (get_feature("RP_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("RP_REG_RD")) begin
              if (get_feature("RP_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_RP

      sinc_env_pkg::MSTR_SP: begin
        if (has_feature("SP_REG_RANGES")) begin
          if (has_feature("SP_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SP;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SP_REG_WR")) begin
              if (get_feature("SP_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SP_REG_RD")) begin
              if (get_feature("SP_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SP

      sinc_env_pkg::MSTR_CCE: begin
        if (has_feature("CCE_REG_RANGES")) begin
          if (get_feature("CCE_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_CCE;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("CCE_REG_WR")) begin
              if (get_feature("CCE_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("CCE_REG_RD")) begin
              if (get_feature("CCE_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_CCE

      sinc_env_pkg::MSTR_AES: begin
        if (has_feature("AES_REG_RANGES")) begin
          if (get_feature("AES_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_AES;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("AES_REG_WR")) begin
              if (get_feature("AES_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("AES_REG_RD")) begin
              if (get_feature("AES_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_AES

      sinc_env_pkg::MSTR_PKA: begin
        if (has_feature("PKA_REG_RANGES")) begin
          if (get_feature("PKA_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_PKA;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("PKA_REG_WR")) begin
              if (get_feature("PKA_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("PKA_REG_RD")) begin
              if (get_feature("PKA_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_PKA

      sinc_env_pkg::MSTR_SHA: begin
        if (has_feature("SHA_REG_RANGES")) begin
          if (get_feature("SHA_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_SHA;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("SHA_REG_WR")) begin
              if (get_feature("SHA_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("SHA_REG_RD")) begin
              if (get_feature("SHA_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_SHA

      sinc_env_pkg::MSTR_MSB: begin
        if (has_feature("MSB_REG_RANGES")) begin
          if (get_feature("MSB_REG_RANGES")) begin
            comp_type = sinc_env_pkg::COMP_MSB;
            comp_cfg[SINC_REG0].valid_mstr_list.push_back(comp_type);
            if (has_feature("MSB_REG_WR")) begin
              if (get_feature("MSB_REG_WR")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_WRITE);
              end
            end
            if (has_feature("MSB_REG_RD")) begin
              if (get_feature("MSB_REG_RD")) begin
                comp_cfg[SINC_REG0].valid_master_cmd_list[comp_type].push_back(sinc_env_pkg::SINC_AXI_SUB_READ);
              end
            end
          end
        end
      end // case: sinc_env_pkg::MSTR_MSB

      default :  `uvm_error("INVALID_DST_ADDR_TYPE", $sformatf("Trying to use %0x as master type", _comp_master_list[i]))
    endcase // case (dst_addr_type)
  end // foreach (_comp_master_list[i])

`uvm_info("new REG cfg", $sformatf("REG COMP_CFG = \n%s ",comp_cfg[SINC_REG0].sprint()), UVM_HIGH);


  ////////////////////////// config RP  /////////////////////////////////////
  comp_cfg[SINC_RP0]              = new("SINC_RP0_comp_cfg");
  comp_cfg[SINC_RP0].comp_id      = SINC_RP0;
  comp_cfg[SINC_RP0].comp_type      = COMP_RP;
  comp_cfg[SINC_RP0].comp_type_name        = "RP";
  comp_cfg[SINC_RP0].type_instance_name    = "SINC_RP0";
  comp_cfg[SINC_RP0].instance_id  = sinc_features_pkg::has_feature("RP_AXI_ID") ? sinc_features_pkg::get_feature("RP_AXI_ID") : 0;
  comp_cfg[SINC_RP0].is_master    = 1;
  comp_cfg[SINC_RP0].is_slave     = 0;
  comp_cfg[SINC_RP0].is_axi_intf = 1;
  comp_cfg[SINC_RP0].is_rp  = 1;
  comp_cfg[SINC_RP0].is_cce  = 0;
  comp_cfg[SINC_RP0].is_sha  = 0;
  comp_cfg[SINC_RP0].is_pka  = 0;
  comp_cfg[SINC_RP0].is_aes  = 0;
  comp_cfg[SINC_RP0].is_ksb  = 0;
  comp_cfg[SINC_RP0].is_ksb_key  = 0;
  comp_cfg[SINC_RP0].is_ksb_attr  = 0;
  comp_cfg[SINC_RP0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_RP0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("RP_KEY_RANGES")) begin
    comp_cfg[SINC_RP0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("RP_ATTR_RANGES")) begin
    comp_cfg[SINC_RP0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("RP_PCR_RANGES")) begin
    comp_cfg[SINC_RP0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_RP0)].size()) begin
        comp_cfg[SINC_RP0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_RP0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_RP0].valid_sinc_access_comp_list = comp_cfg[SINC_RP0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_RP0].valid_ksb_access_comp_list = comp_cfg[SINC_RP0].valid_ksb_access_comp_list.unique();


`uvm_info("new RP cfg", $sformatf("RP COMP_CFG = \n%s ",comp_cfg[SINC_RP0].sprint()), UVM_HIGH);

  ////////////////////////// config SP  /////////////////////////////////////
  comp_cfg[SINC_SP0]              = new("SINC_SP0_comp_cfg");
  comp_cfg[SINC_SP0].comp_id      = SINC_SP0;
  comp_cfg[SINC_SP0].comp_type      = COMP_SP;
  comp_cfg[SINC_SP0].comp_type_name        = "SP";
  comp_cfg[SINC_SP0].type_instance_name    = "SINC_SP0";
  comp_cfg[SINC_SP0].instance_id  = sinc_features_pkg::has_feature("SP_AXI_ID") ? sinc_features_pkg::get_feature("SP_AXI_ID") : 0;
  comp_cfg[SINC_SP0].is_master    = 1;
  comp_cfg[SINC_SP0].is_slave     = 0;
  comp_cfg[SINC_SP0].is_axi_intf = 1;
  comp_cfg[SINC_SP0].is_sp  = 1;
  comp_cfg[SINC_SP0].is_cce  = 0;
  comp_cfg[SINC_SP0].is_sha  = 0;
  comp_cfg[SINC_SP0].is_pka  = 0;
  comp_cfg[SINC_SP0].is_aes  = 0;
  comp_cfg[SINC_SP0].is_ksb  = 0;
  comp_cfg[SINC_SP0].is_ksb_key  = 0;
  comp_cfg[SINC_SP0].is_ksb_attr  = 0;
  comp_cfg[SINC_SP0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_SP0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("SP_KEY_RANGES")) begin
    comp_cfg[SINC_SP0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("SP_ATTR_RANGES")) begin
    comp_cfg[SINC_SP0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("SP_PCR_RANGES")) begin
    comp_cfg[SINC_SP0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_SP0)].size()) begin
        comp_cfg[SINC_SP0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_SP0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_SP0].valid_sinc_access_comp_list = comp_cfg[SINC_SP0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_SP0].valid_ksb_access_comp_list = comp_cfg[SINC_SP0].valid_ksb_access_comp_list.unique();


`uvm_info("new SP cfg", $sformatf("SP COMP_CFG = \n%s ",comp_cfg[SINC_SP0].sprint()), UVM_HIGH);

  ////////////////////////// config CCE  /////////////////////////////////////
  comp_cfg[SINC_CCE0]              = new("SINC_CCE0_comp_cfg");
  comp_cfg[SINC_CCE0].comp_id      = SINC_CCE0;
  comp_cfg[SINC_CCE0].comp_type      = COMP_CCE;
  comp_cfg[SINC_CCE0].comp_type_name        = "CCE";
  comp_cfg[SINC_CCE0].type_instance_name    = "SINC_CCE0";
  comp_cfg[SINC_CCE0].instance_id  = sinc_features_pkg::has_feature("CCE_AXI_ID") ? sinc_features_pkg::get_feature("CCE_AXI_ID") : 0;
  comp_cfg[SINC_CCE0].is_master    = 1;
  comp_cfg[SINC_CCE0].is_slave     = 0;
  comp_cfg[SINC_CCE0].is_axi_intf = 1;
  comp_cfg[SINC_CCE0].is_cce  = 1;
  comp_cfg[SINC_CCE0].is_sha  = 0;
  comp_cfg[SINC_CCE0].is_pka  = 0;
  comp_cfg[SINC_CCE0].is_aes  = 0;
  comp_cfg[SINC_CCE0].is_ksb  = 0;
  comp_cfg[SINC_CCE0].is_ksb_key  = 0;
  comp_cfg[SINC_CCE0].is_ksb_attr  = 0;
  comp_cfg[SINC_CCE0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_CCE0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("CCE_KEY_RANGES")) begin
    comp_cfg[SINC_CCE0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("CCE_ATTR_RANGES")) begin
    comp_cfg[SINC_CCE0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("CCE_PCR_RANGES")) begin
    comp_cfg[SINC_CCE0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_CCE0)].size()) begin
        comp_cfg[SINC_CCE0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_CCE0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_CCE0].valid_sinc_access_comp_list = comp_cfg[SINC_CCE0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_CCE0].valid_ksb_access_comp_list = comp_cfg[SINC_CCE0].valid_ksb_access_comp_list.unique();

`uvm_info("new CCE cfg", $sformatf("CCE COMP_CFG = \n%s ",comp_cfg[SINC_CCE0].sprint()), UVM_HIGH);

    ////////////////////////// config SHA  /////////////////////////////////////
  comp_cfg[SINC_SHA0]              = new("SINC_SHA0_comp_cfg");
  comp_cfg[SINC_SHA0].comp_id      = SINC_SHA0;
  comp_cfg[SINC_SHA0].comp_type      = COMP_SHA;
  comp_cfg[SINC_SHA0].comp_type_name        = "SHA";
  comp_cfg[SINC_SHA0].type_instance_name    = "SINC_SHA0";
  comp_cfg[SINC_SHA0].instance_id  = sinc_features_pkg::has_feature("SHA_AXI_ID") ? sinc_features_pkg::get_feature("SHA_AXI_ID") : 0;
  comp_cfg[SINC_SHA0].is_master    = 1;
  comp_cfg[SINC_SHA0].is_slave     = 0;
  comp_cfg[SINC_SHA0].is_axi_intf = 1;
  comp_cfg[SINC_SHA0].is_sha  = 1;
  comp_cfg[SINC_SHA0].is_cce  = 0;
  comp_cfg[SINC_SHA0].is_pka  = 0;
  comp_cfg[SINC_SHA0].is_aes  = 0;
  comp_cfg[SINC_SHA0].is_ksb  = 0;
  comp_cfg[SINC_SHA0].is_ksb_key  = 0;
  comp_cfg[SINC_SHA0].is_ksb_attr  = 0;
  comp_cfg[SINC_SHA0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_SHA0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("SHA_KEY_RANGES")) begin
    comp_cfg[SINC_SHA0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("SHA_ATTR_RANGES")) begin
    comp_cfg[SINC_SHA0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("SHA_PCR_RANGES")) begin
    comp_cfg[SINC_SHA0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_SHA0)].size()) begin
        comp_cfg[SINC_SHA0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_SHA0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_SHA0].valid_sinc_access_comp_list = comp_cfg[SINC_SHA0].valid_sinc_access_comp_list.unique();
  // comp_cfg[SINC_SHA0].valid_ksb_access_comp_list = comp_cfg[SINC_SHA0].valid_ksb_access_comp_list.unique();

`uvm_info("new SHA cfg", $sformatf("SHA COMP_CFG = \n%s ",comp_cfg[SINC_SHA0].sprint()), UVM_HIGH);

    ////////////////////////// config PKA  /////////////////////////////////////
  comp_cfg[SINC_PKA0]              = new("SINC_PKA0_comp_cfg");
  comp_cfg[SINC_PKA0].comp_id      = SINC_PKA0;
  comp_cfg[SINC_PKA0].comp_type      = COMP_PKA;
  comp_cfg[SINC_PKA0].comp_type_name        = "PKA";
  comp_cfg[SINC_PKA0].type_instance_name    = "SINC_PKA0";
  comp_cfg[SINC_PKA0].instance_id  = sinc_features_pkg::has_feature("PKA_AXI_ID") ? sinc_features_pkg::get_feature("PKA_AXI_ID") : 0;
  comp_cfg[SINC_PKA0].is_master    = 1;
  comp_cfg[SINC_PKA0].is_slave     = 0;
  comp_cfg[SINC_PKA0].is_axi_intf = 1;
  comp_cfg[SINC_PKA0].is_pka  = 1;
  comp_cfg[SINC_PKA0].is_cce  = 0;
  comp_cfg[SINC_PKA0].is_sha  = 0;
  comp_cfg[SINC_PKA0].is_aes  = 0;
  comp_cfg[SINC_PKA0].is_ksb  = 0;
  comp_cfg[SINC_PKA0].is_ksb_key  = 0;
  comp_cfg[SINC_PKA0].is_ksb_attr  = 0;
  comp_cfg[SINC_PKA0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_PKA0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("PKA_KEY_RANGES")) begin
    comp_cfg[SINC_PKA0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("PKA_ATTR_RANGES")) begin
    comp_cfg[SINC_PKA0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("PKA_PCR_RANGES")) begin
    comp_cfg[SINC_PKA0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin

    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_PKA0)].size()) begin
        comp_cfg[SINC_PKA0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_PKA0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_PKA0].valid_sinc_access_comp_list = comp_cfg[SINC_PKA0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_PKA0].valid_ksb_access_comp_list = comp_cfg[SINC_PKA0].valid_ksb_access_comp_list.unique();

`uvm_info("new PKA cfg", $sformatf("PKA COMP_CFG = \n%s ",comp_cfg[SINC_PKA0].sprint()), UVM_HIGH);

    ////////////////////////// config AES  /////////////////////////////////////
  comp_cfg[SINC_AES0]              = new("SINC_AES0_comp_cfg");
  comp_cfg[SINC_AES0].comp_id      = SINC_AES0;
  comp_cfg[SINC_AES0].comp_type      = COMP_AES;
  comp_cfg[SINC_AES0].comp_type_name        = "AES";
  comp_cfg[SINC_AES0].type_instance_name    = "SINC_AES0";
  comp_cfg[SINC_AES0].instance_id  = sinc_features_pkg::has_feature("AES_AXI_ID") ? sinc_features_pkg::get_feature("AES_AXI_ID") : 0;
  comp_cfg[SINC_AES0].is_master    = 1;
  comp_cfg[SINC_AES0].is_slave     = 0;
  comp_cfg[SINC_AES0].is_axi_intf = 1;
  comp_cfg[SINC_AES0].is_aes  = 1;
  comp_cfg[SINC_AES0].is_cce  = 0;
  comp_cfg[SINC_AES0].is_sha  = 0;
  comp_cfg[SINC_AES0].is_pka  = 0;
  comp_cfg[SINC_AES0].is_ksb  = 0;
  comp_cfg[SINC_AES0].is_ksb_key  = 0;
  comp_cfg[SINC_AES0].is_ksb_attr  = 0;
  comp_cfg[SINC_AES0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_AES0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("AES_KEY_RANGES")) begin
    comp_cfg[SINC_AES0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("AES_ATTR_RANGES")) begin
    comp_cfg[SINC_AES0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("AES_PCR_RANGES")) begin
    comp_cfg[SINC_AES0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_AES0)].size()) begin
        comp_cfg[SINC_AES0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_AES0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_AES0].valid_sinc_access_comp_list = comp_cfg[SINC_AES0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_AES0].valid_ksb_access_comp_list = comp_cfg[SINC_AES0].valid_ksb_access_comp_list.unique();

`uvm_info("new AES cfg", $sformatf("AES COMP_CFG = \n%s ",comp_cfg[SINC_AES0].sprint()), UVM_HIGH);

    ////////////////////////// config MSB  /////////////////////////////////////
  comp_cfg[SINC_MSB0]              = new("SINC_MSB0_comp_cfg");
  comp_cfg[SINC_MSB0].comp_id      = SINC_MSB0;
  comp_cfg[SINC_MSB0].comp_type      = COMP_MSB;
  comp_cfg[SINC_MSB0].comp_type_name        = "MSB";
  comp_cfg[SINC_MSB0].type_instance_name    = "SINC_MSB0";
  comp_cfg[SINC_MSB0].instance_id  = sinc_features_pkg::has_feature("MSB_AXI_ID") ? sinc_features_pkg::get_feature("MSB_AXI_ID") : 0;
  comp_cfg[SINC_MSB0].is_master    = 1;
  comp_cfg[SINC_MSB0].is_slave     = 0;
  comp_cfg[SINC_MSB0].is_axi_intf = 1;
  comp_cfg[SINC_MSB0].is_msb  = 1;
  comp_cfg[SINC_MSB0].is_cce  = 0;
  comp_cfg[SINC_MSB0].is_sha  = 0;
  comp_cfg[SINC_MSB0].is_pka  = 0;
  comp_cfg[SINC_MSB0].is_aes  = 0;
  comp_cfg[SINC_MSB0].is_ksb  = 0;
  comp_cfg[SINC_MSB0].is_ksb_key  = 0;
  comp_cfg[SINC_MSB0].is_ksb_attr  = 0;
  comp_cfg[SINC_MSB0].is_ksb_pcr  = 0;
  
  // interface parameters
  comp_cfg[SINC_MSB0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("MSB_KEY_RANGES")) begin
    comp_cfg[SINC_MSB0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("MSB_ATTR_RANGES")) begin
    comp_cfg[SINC_MSB0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("MSB_PCR_RANGES")) begin
    comp_cfg[SINC_MSB0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_MSB0)].size()) begin
        comp_cfg[SINC_MSB0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_MSB0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_MSB0].valid_sinc_access_comp_list = comp_cfg[SINC_MSB0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_MSB0].valid_ksb_access_comp_list = comp_cfg[SINC_MSB0].valid_ksb_access_comp_list.unique();

`uvm_info("new MSB cfg", $sformatf("MSB COMP_CFG = \n%s ",comp_cfg[SINC_MSB0].sprint()), UVM_HIGH);

    ////////////////////////// config KLI  /////////////////////////////////////
  comp_cfg[SINC_KLI0]              = new("SINC_KLI0_comp_cfg");
  comp_cfg[SINC_KLI0].comp_id      = SINC_KLI0;
  comp_cfg[SINC_KLI0].comp_type      = COMP_KLI;
  comp_cfg[SINC_KLI0].comp_type_name        = "KLI";
  comp_cfg[SINC_KLI0].type_instance_name    = "SINC_KLI0";
  comp_cfg[SINC_KLI0].is_master    = 1;
  comp_cfg[SINC_KLI0].is_slave     = 0;
  comp_cfg[SINC_KLI0].is_kli_intf = 1;
  comp_cfg[SINC_KLI0].is_kli  = 1;
  comp_cfg[SINC_KLI0].is_cce  = 0;
  comp_cfg[SINC_KLI0].is_sha  = 0;
  comp_cfg[SINC_KLI0].is_pka  = 0;
  comp_cfg[SINC_KLI0].is_aes  = 0;
  comp_cfg[SINC_KLI0].is_ksb  = 0;
  comp_cfg[SINC_KLI0].is_ksb_key  = 0;
  comp_cfg[SINC_KLI0].is_ksb_attr  = 0;
  comp_cfg[SINC_KLI0].is_ksb_pcr  = 0;
  
  // interface parameters
  // comp_cfg[SINC_KLI0].addr_width          = sinc_features_pkg::get_feature("AXI_ADDRESS_WIDTH");;

  if (sinc_features_pkg::has_feature("KLI_KEY_RANGES")) begin
    comp_cfg[SINC_KLI0].num_key_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("KLI_ATTR_RANGES")) begin
    comp_cfg[SINC_KLI0].num_attr_ranges     = sinc_features_pkg::get_feature("KEY_NUM");
  end
  
  if (sinc_features_pkg::has_feature("KLI_PCR_RANGES")) begin
    comp_cfg[SINC_KLI0].num_pcr_ranges     = sinc_features_pkg::get_feature("PCR_NUM");
  end

  foreach (comp_cfg[i]) begin
    if (comp_cfg[i].is_ksb || comp_cfg[i].is_reg) begin
      if (comp_cfg[i].valid_master_cmd_list[get_comp_type(SINC_KLI0)].size()) begin
        comp_cfg[SINC_KLI0].valid_sinc_access_comp_list.push_back(comp_cfg[i].comp_type);
        if (comp_cfg[i].is_ksb) begin
          comp_cfg[SINC_KLI0].valid_ksb_access_comp_list.push_back(comp_cfg[i].comp_type);
        end
      end
    end    
  end
  comp_cfg[SINC_KLI0].valid_sinc_access_comp_list = comp_cfg[SINC_KLI0].valid_sinc_access_comp_list.unique();
  comp_cfg[SINC_KLI0].valid_ksb_access_comp_list = comp_cfg[SINC_KLI0].valid_ksb_access_comp_list.unique();
  
  `uvm_info("new KLI cfg", $sformatf("KLI COMP_CFG = \n%s ",comp_cfg[SINC_KLI0].sprint()), UVM_HIGH);

endfunction : init_comp_cfgs

 
`endif //  `ifndef SINC_SYS_CFG_SVH

  
