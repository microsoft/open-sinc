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
// File        : sinc_address_range_lib.svh
// Description : This class collects system configurations for each component, generate there addresses based

`ifndef SINC_ADDRESS_RANGE_LIB_SVH
`define SINC_ADDRESS_RANGE_LIB_SVH
// Class to describe SINC slot address ranges
/*
class sinc_slot_range;
  address_t      range_start,range_end;   // Start address and end of the range 
  int            range_index;             // Integer range index of this address range on  addr_ranges[sinc_comp_e][$]
  sinc_comp_e addr_type;                    // Address type of this address range
  sinc_comp_e    comp_type;               // Component type of the component where this address range resides
  int            reg_index;               // Index used by the key register which defines the properties of this range
  sinc_sys_cfg     sys_cfg;

  extern         function           new(sinc_comp_e comp_type, sinc_comp_e addr_type, int inst_id, address_t range_start, address_t range_end, string message);
  extern virtual function void      check_range_boundary(string name);  
  extern         function bit       is_range_hit_base(address_t address);  
  extern virtual function bit       is_range_hit(address_t address);  
  extern         function void      update_message(int verbosity=0);
  extern virtual function void      update(int verbosity=0);
  extern virtual function sinc_comp_e  get_comptype();
endclass: sinc_slot_range

// Creates a new address range
function sinc_slot_range::new(sinc_comp_e comp_type, sinc_comp_e addr_type, int inst_id, address_t range_start, address_t range_end, string message);
  `uvm_info("sinc_address_range",$sformatf("Created new slot [%s][%0d][%s]range %s", comp_type.name(), inst_id, addr_type.name(),message),UVM_LOW);
  this.range_index = inst_id;
  this.comp_type   = comp_type;
  this.addr_type   = addr_type  ;
  this.range_start = range_start;
  this.range_end   = range_end;
  sys_cfg = sinc_sys_cfg::get_inst();
   
endfunction

function void sinc_slot_range::update(int verbosity=0);  
  update_message(verbosity);
endfunction

function void sinc_slot_range::update_message(int verbosity=0);  
  //if(verbosity>0)`uvm_info("sinc_address_range",$sformatf("Updated range to:\n%s",stringify()),UVM_HIGH);
endfunction

function void sinc_slot_range::check_range_boundary(string name);  
  if(range_start > range_end)  `uvm_warning(name,$sformatf("Start address [%016x] should be less than end address [%016x]",range_start,range_end));  
endfunction

// Returns true if range is hit
function bit sinc_slot_range::is_range_hit_base(address_t address);

  if((this.range_start <= address  )&&
     (this.range_end   >= address  ))
    begin
      return(1);
    end
  return(0);
endfunction

// Returns true if range is hit
function bit sinc_slot_range::is_range_hit(address_t address);  
  return(is_range_hit_base(address));
endfunction

// Returns the destination component id for this address
function sinc_comp_e sinc_slot_range::get_comptype();
  return(this.comp_type);
endfunction

// Class to describe sinc address ranges
class sinc_address_range;
  uvm_reg        reg_list[$];                                      // List of registers whose values affects the functionality of this address range
  address_t      range_base, range_start,range_end;                // Start address and end of the range 
  address_axi_t  range_base_axi, range_start_axi,range_end_axi;    // Start address and end of the axi range 
  address_kli_t  range_base_kli, range_start_kli,range_end_kli;    // Start address and end of the kli range
  bit            enabled;                                          // Boolean indicating if the range is enabled or not
  sinc_comp_e addr_type;                                        // Address type of this address range
  sinc_comp_e    comp_type;                                        // Component type of the component where this address range resides
  sinc_comp_e     comp_id;                                          // Component id of the component where this address range resides
  int            range_index;                                      // Integer range index of this address range on  addr_ranges[sinc_comp_e][$]
  // intention of reg_index is using register offset to get register address value, but this might not exist in SINC, so no actual meaning here other than index identifier.
  int            reg_index;                                        // Index used by the key register which defines the properties of this range
  reg_t          dst_id;                                           // Destination of a request which hits this range (int)
  sinc_comp_e     dst_compid;                                       // Destination of a request which hits this range (sinc_comp_e)
  int            dst_instid;                                       // Destination of a instance id which hits this range
  address_t      four_gb         = 33'h100000000;
  address_t      four_gb_minus_1 = 32'hFFFFFFFF;
  sinc_sys_cfg                      sys_cfg;
  sinc_comp_cfg   comp_cfg;
  extern         function           new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  extern virtual function void      init();

  extern         function string    stringify_base();  
  extern         function string    get_range_size();
  extern virtual function string    stringify();  
  extern virtual function void      check_range_boundary(string name);  
  extern virtual function address_t get_normalized_address(address_t address);
  extern         function bit       is_range_hit_base(address_t address);  
  extern virtual function bit       is_range_hit(address_t address);  
  extern         function address_t remove_bits(address_t address,int offset,int num_bits);
  extern         function address_t replace_bits(address_t address,int offset,int num_bits,address_t inbits);
  extern         function address_t insert_bits(address_t address,int offset,int num_bits,address_t inbits);
  extern         function address_t extract_bits(address_t address,int offset,int num_bits);
  extern         function void      update_message(int verbosity=0);
  extern virtual function void      update(int verbosity=0);
  extern virtual function int       get_dst_id(address_t address);
  extern virtual function sinc_comp_e  get_dst_compid(address_t address);
  extern virtual function int       get_dst_slotid(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_addrtype(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_comptype(address_t address);
  extern         function void      apply_address_mask();
endclass: sinc_address_range

// Creates a new address range
function sinc_address_range::new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  `uvm_info("sinc_address_range",$sformatf("Created new [%s][%s]range %s",comp_id.name(),addr_type.name(),message),UVM_LOW);
  this.comp_id     = comp_id;
  this.comp_type   = comp_type;
  this.addr_type   = addr_type  ;
  this.range_start = range_start;
  this.range_end   = range_end;
  sys_cfg = sinc_sys_cfg::get_inst();
  comp_cfg         = sys_cfg.get_comp_cfg(comp_id);
  apply_address_mask();
endfunction

function void sinc_address_range::init();
  // Nothing here
endfunction

function void sinc_address_range::update(int verbosity=0);  
  update_message(verbosity);
endfunction

function void sinc_address_range::update_message(int verbosity=0);  
  if(verbosity>0)`uvm_info("sinc_address_range",$sformatf("Updated range to:\n%s",stringify()),UVM_HIGH);
endfunction

// Return address range information as a string
function string sinc_address_range::stringify();
  return(stringify_base());
endfunction

// Returns size of range as human readable string
function string sinc_address_range::get_range_size();
  longint size  = ((range_end > range_start) ? (range_end - range_start+1) : 0);
  if(size >= 64'd1099511627776 ) begin return($sformatf("%4dT",size/64'd1099511627776)); end // Terra 
  else if(size >= 64'd1073741824    ) begin return($sformatf("%4dG",size/64'd1073741824   )); end // Giga
  else if(size >= 64'd1048576       ) begin return($sformatf("%4dM",size/64'd1048576      )); end // Mega
  else if(size >= 64'd1024          ) begin return($sformatf("%4dk",size/64'd1024         )); end // kilo
  else                                begin return($sformatf("%4dB",size                  )); end // Byte
endfunction

// Return address range information as a string
function string sinc_address_range::stringify_base();
  return($sformatf("[%-8s][%-15s][%02d][%-18s][%016x - %016x][%03x][%4s]",
		   ((enabled) ? "Enabled" : "Disabled"),comp_id.name(),range_index,addr_type.name(),range_start,range_end,dst_id,get_range_size()));
endfunction

function void sinc_address_range::check_range_boundary(string name);  
  if(range_start > range_end)  `uvm_warning(name,$sformatf("Start address [%016x] should be less than end address [%016x]",range_start,range_end));  
endfunction

// Returns the normalized address
function address_t sinc_address_range::get_normalized_address(address_t address);  
  `uvm_info("sinc_address_range",$sformatf("Generic get_normalized_address function should not be used. Simply returning the input address"),UVM_HIGH);
  `uvm_info("sinc_address_range",$sformatf("Normalized addr is 0x%0x\n",address),UVM_HIGH);  
  return(address);
endfunction

// Returns true if range is hit
function bit sinc_address_range::is_range_hit_base(address_t address); 
  
  if((this.enabled     == 1        ) &&
     (this.range_start <= address  ) &&
     (this.range_end   >= address  ))
    begin
      return(1);
    end

  return(0);
endfunction


// Returns true if range is hit
function bit sinc_address_range::is_range_hit(address_t address); 
  return(is_range_hit_base(address));
endfunction

// Returns the destination fabric id for this address
function int sinc_address_range::get_dst_id(address_t address);
  return(dst_id);
endfunction

// Returns the destination component id for this address
function sinc_comp_e sinc_address_range::get_dst_compid(address_t address);
  return(dst_compid);
endfunction

// Returns the destination slot's instance id for this address
function int sinc_address_range::get_dst_slotid(address_t address);
  return(range_index);
endfunction

// Returns the destination slot address type
function sinc_comp_e sinc_address_range::get_dst_slot_addrtype(address_t address);
  return ADDR_FREE;
endfunction

// Returns the destination slot component type
function sinc_comp_e sinc_address_range::get_dst_slot_comptype(address_t address);
  return  COMP_NULL;
endfunction

// Remove num_bits bits from address starting from offset (width is decreased)
function address_t sinc_address_range::remove_bits(address_t address,int offset,int num_bits);
  address_t temp;
  // Extract lower address bits
  temp    = address & ((1 << offset)-1);
  // Extract upper after skipping num_bits address bits
  address = address & ~((1<<(offset+num_bits))-1);
  // Merge upper and lower address bits
  temp    = ((address >> num_bits) | temp);
  return(temp);
endfunction

// Insert num_bits of inbits into address starting from offset (width is increased)
function address_t sinc_address_range::insert_bits(address_t address,int offset,int num_bits,address_t inbits);
  address_t temp;
  // Extract lower address bits
  temp    = address &  ((1 << offset)-1);
  // Extract upper address bits
  address = address & ~((1 << offset)-1);
  // Insert inbits between upper & lower address bits
  temp    =  ((address << num_bits) | ((inbits & ((1<<num_bits)-1))<<offset) | temp);
  return(temp);
endfunction

// Replace num_bits of address starting from offset using num_bits of inbits (width is unchanged)
function address_t sinc_address_range::replace_bits(address_t address,int offset,int num_bits,address_t inbits);
  address_t temp;
  address_t num_bits_mask = ((1<<num_bits)-1);
  address =  address & ~(num_bits_mask << offset);
  temp    =  (address | ((inbits & num_bits_mask)<<offset));
  return(temp);
endfunction

// Extract num_bits starting from offset
function address_t sinc_address_range::extract_bits(address_t address,int offset,int num_bits);
  address_t temp;
  temp = address >> offset;
  temp = temp & ((1 << num_bits)-1);
  return(temp);
endfunction

// Apply address masks defined by cfg
function void sinc_address_range::apply_address_mask();
  if(comp_cfg.is_master)
    begin
      range_start = range_start & comp_cfg.addr_mask;
      range_end   = range_end   & comp_cfg.addr_mask;
    end
endfunction

// Following are helper classes for address decoder

// Class to describe KLI access to KEY address range
class sinc_kli_key_range extends sinc_address_range;
  address_kli_t base_addr_kli, limit_addr_kli;
  address_kli_t base_addr, limit_addr, range_slot_start;
  address_kli_t  range_base_kli, range_start_kli,range_end_kli;   // Start address and end of the kli range
  sinc_slot_range key_slot_range[$];

  bit       comp_enabled;

  extern         function           new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  extern virtual function void      init();
  extern virtual function string    stringify();  
  extern virtual function void      update(int verbosity=0);
  extern         function void      update_range_boundary();
  extern virtual function bit       is_range_hit(address_t address);  
  extern virtual function bit       is_kli_abort_address(address_t address);
  extern virtual function int       get_dst_slotid(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_addrtype(address_t address);
  extern virtual function sinc_comp_e  get_dst_slot_comptype(address_t address);
  

endclass : sinc_kli_key_range

// Creates a new KEY range
function sinc_kli_key_range::new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  super.new(comp_id,comp_type,addr_type,range_start,range_end,message);
endfunction

// Initialize configuration dependency
function void sinc_kli_key_range::init();
  base_addr_kli        = sinc_features_pkg::get_feature64("KLI_BASE_ADDR");
  limit_addr_kli       = sinc_features_pkg::get_feature64("KLI_LIMIT_ADDR");

  `uvm_info("sinc_kli_key_range",$sformatf("base_addr_kli:%0d, limit_addr_kli:%0d\n", 
                                         base_addr_kli, limit_addr_kli),UVM_HIGH);

endfunction

// updates the new KLI Key range
function void sinc_kli_key_range::update(int verbosity=0);
  
  // KLI Key Base Fields
  base_addr           = base_addr_kli;
  // KLI Key Limit Field
  limit_addr          = limit_addr_kli;
  // dst_id = ?
  dst_compid = sinc_env_pkg::SINC_KEY0;

  range_start = base_addr_kli;
  range_end   = range_start + limit_addr;

  enabled             = sinc_features_pkg::has_feature("KLI_KEY_RANGES");
  update_range_boundary();

  if(enabled)
    begin
      check_range_boundary("sinc_kli_key_range");
    end

  update_message(verbosity);
  `uvm_info("sinc_kli_key_range",$sformatf("set range start:%0d, range_end:%0d\n", 
                                         range_start, range_end),UVM_HIGH);
  
endfunction

// Update helper function
function void sinc_kli_key_range::update_range_boundary();
  range_start_kli   = base_addr;
  range_end_kli     = limit_addr;
  range_base_kli    = range_start_kli;  
  //apply_address_mask();

  `uvm_info("sinc_kli_key_range",$sformatf("range_start_kli:%0d, range_end_kli:%0d, range_base_kli:%0d\n", 
                                         range_start_kli, range_end_kli,range_base_kli),UVM_HIGH);

  if(enabled)
    begin
      range_slot_start = range_start_kli;
      for (int i; i < comp_cfg.num_key_ranges; i++) begin
	sinc_slot_range key_slot;

	key_slot = sinc_slot_range::new(COMP_SINC_KEY, ADDR_KEY, i, range_slot_start, (range_slot_start + 1), "");
	key_slot.reg_index = i;
	if (range_slot_start > limit_addr) begin
          `uvm_error("update_range_boundary",$sformatf("This key slot configuration is not supported"));  
	end
	
	`uvm_info("sinc_kli_key_range",$sformatf("kli->key[%0d] range_slot_start:%0d\n", 
                                               i, range_slot_start),UVM_HIGH);

	key_slot_range.push_back(key_slot);
	range_slot_start += 1;
      end
    end
endfunction

// Return address range information as a string
function string sinc_kli_key_range::stringify();
  return($sformatf("%s[%016x - %016x]",stringify_base(),range_start,range_end));
endfunction

// Returns true if address falls in the master abort range which can overlap DRAM
function bit sinc_kli_key_range::is_kli_abort_address(address_t address);
  // implement the is_legal_kli_addr method 
  return (0);
endfunction

// Returns true if range is hit
function bit sinc_kli_key_range::is_range_hit(address_t address); 
  if (is_kli_abort_address(address)) begin
    return (0);
  end

  return(is_range_hit_base(address));
endfunction

// Returns the destination slot id for this address
function int sinc_kli_key_range::get_dst_slotid(address_t address);
  const string METHOD_NAME = "sinc_kli_key_range::get_dst_slotid";
  foreach (key_slot_range[index]) begin
    if ((key_slot_range[index].range_start <= address) &&
        (key_slot_range[index].range_end   > address))
      begin
	return key_slot_range[index].reg_index;
      end
  end

  return -1;
endfunction

// Returns the destination slot component type
function sinc_comp_e sinc_kli_key_range::get_dst_slot_comptype(address_t address);
  const string METHOD_NAME = "sinc_kli_key_range::get_dst_slot_comptype";
  foreach (key_slot_range[id]) begin
    if (key_slot_range[id].is_range_hit(address)) begin
      return key_slot_range[id].comp_type;
    end
  end

  return COMP_NULL;
endfunction

// Returns the destination slot address type
function sinc_comp_e sinc_kli_key_range::get_dst_slot_addrtype(address_t address);
  const string METHOD_NAME = "sinc_kli_key_range::get_dst_slot_addrtype";
  foreach (key_slot_range[id]) begin
    if (key_slot_range[id].is_range_hit(address)) begin
      `uvm_info("get_dst_slot_addrtype_hit",$sformatf("Check addr %0h hit on %0s [%0s]",address, dst_compid.name(), key_slot_range[id].addr_type.name()),UVM_DEBUG); 
      return key_slot_range[id].addr_type;
    end
  end

  return ADDR_FREE;
endfunction

// Class to describe AXI access to KEY address range
class sinc_axi_key_range extends sinc_address_range;
  address_axi_t  base_addr_axi, base_addr_key_axi, limit_addr_key_axi;
  address_axi_t  base_addr_attr_axi, limit_addr_attr_axi;
  address_axi_t  base_key_addr, limit_key_slot_addr, base_attr_addr, limit_attr_slot_addr;
  address_axi_t  key_hole;
  address_axi_t  base_addr, range_slot_start;
  address_axi_t  range_base_axi, range_start_axi,range_end_axi;   // Start address and end of the axi range
  address_axi_t  range_start_key_slot, range_end_key_slot, range_start_attr_slot, range_end_attr_slot;

  sinc_slot_range key_slot_range[$];
  sinc_slot_range attr_slot_range[$];

  int slot_id;
  sinc_comp_e addr_type_list[$];                                                         // Address type of this address range
  sinc_comp_e    comp_type_list[$];                                                         // Component type of the component where this address range resides

  bit       comp_enabled;

  extern         function           new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  extern virtual function void      init();
  extern virtual function string    stringify();  
  extern virtual function void      update(int verbosity=0);
  extern         function void      update_range_boundary();
  extern virtual function bit       is_range_hit(address_t address);  
  extern virtual function bit       is_axi_abort_address(address_t address);
  extern virtual function int       get_dst_slotid(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_addrtype(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_comptype(address_t address);

endclass : sinc_axi_key_range

// Creates a new KEY range
function sinc_axi_key_range::new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  super.new(comp_id,comp_type,addr_type,range_start,range_end,message);
endfunction

// Initialize configuration dependency
function void sinc_axi_key_range::init();
  base_addr_axi = sinc_features_pkg::get_feature64("AXI_REG_BASE_ADDR");
  base_addr_key_axi   = sinc_features_pkg::get_feature64("AXI_KEY_BASE_ADDR");
  limit_addr_key_axi  = sinc_features_pkg::get_feature64("AXI_KEY_LIMIT_ADDR");
  limit_key_slot_addr = sinc_features_pkg::get_feature64("AXI_KEY_SLOT_LIMIT_ADDR");

  base_addr_attr_axi   = sinc_features_pkg::get_feature64("AXI_KEY_BASE_ADDR") + 32'h20;
  limit_addr_attr_axi  = sinc_features_pkg::get_feature64("AXI_ATTR_LIMIT_ADDR");
  limit_attr_slot_addr = sinc_features_pkg::get_feature64("AXI_ATTR_SLOT_LIMIT_ADDR");

  key_hole = sinc_features_pkg::get_feature64("AXI_KEY_HOLE");
endfunction

// updates the new AXI Key range
function void sinc_axi_key_range::update(int verbosity=0);
  sinc_comp_cfg   key_comp_cfg;
  sinc_comp_cfg   attr_comp_cfg;
  sinc_comp_e m_comp_type;
  range_start = base_addr_key_axi;
  range_end   = range_start + limit_addr_attr_axi;

  dst_compid = sinc_env_pkg::SINC_KEY0;

  key_comp_cfg = sys_cfg.get_comp_cfg(SINC_KEY0);
  m_comp_type = sys_cfg.get_comp_type(comp_id);
  if (key_comp_cfg.valid_master_cmd_list[m_comp_type].size()) begin
    enabled             = 1;
  end

  attr_comp_cfg = sys_cfg.get_comp_cfg(SINC_ATTR0);
  if (attr_comp_cfg.valid_master_cmd_list[m_comp_type].size()) begin
    enabled             = 1;
  end
  
  update_range_boundary();

  if(enabled)
    begin
      check_range_boundary("sinc_axi_key_range");
    end
  update_message(verbosity);
endfunction

// Update helper function
function void sinc_axi_key_range::update_range_boundary();

  // create key and attr slots
  if(enabled)
    begin
      range_start_key_slot = base_addr_key_axi;
      range_end_key_slot   = range_start_key_slot + limit_key_slot_addr;

      range_start_attr_slot = base_addr_attr_axi;
      range_end_attr_slot   = range_start_attr_slot + limit_attr_slot_addr;

      `uvm_info("sinc_update_range_boundary",$sformatf("key_start_addr:%0h, limit_key_slot_addr:%0h , range_end_key_slot:%0h, attr_start_addr:%0h, limit_attr_slot_addr:%0h, range_end_attr_slot:%0h\n", 
                                                     range_start_key_slot, limit_key_slot_addr, range_end_key_slot, range_start_attr_slot, limit_attr_slot_addr, range_end_attr_slot),UVM_HIGH);

      for (int i=0; i < comp_cfg.num_key_ranges; i++) begin
	sinc_slot_range key_slot;
	sinc_slot_range attr_slot;

	key_slot = sinc_slot_range::new(COMP_SINC_KEY, ADDR_KEY, i, range_start_key_slot, range_end_key_slot, "");
	attr_slot = sinc_slot_range::new(COMP_SINC_ATTR, ADDR_ATTR, i, range_start_attr_slot, range_end_attr_slot, "");

	if (range_end_key_slot > (base_addr_axi + limit_addr_key_axi)) begin
          `uvm_error("update_range_boundary",$sformatf("This key slot configuration is not supported"));  
	end

	if (range_end_attr_slot > (base_addr_axi + limit_addr_attr_axi)) begin
          `uvm_error("update_range_boundary",$sformatf("This key slot configuration is not supported"));  
	end

	`uvm_info("sinc_update_range_boundary",$sformatf("key[%0d] key_start_addr:%0h, key_end_addr:%0h, limit_key_slot_addr:%0h , attr_start_addr:%0h, attr_end_addr:%0h, limit_attr_slot_addr:%0h\n", 
                                                       i, range_start_key_slot, range_end_key_slot, limit_key_slot_addr, range_start_attr_slot, range_end_attr_slot, limit_attr_slot_addr),UVM_HIGH);


	// self-check if Key Attributes are attached to Key
	if (range_start_attr_slot !== range_end_key_slot + 1) begin
	  `uvm_error("sinc_update_range_boundary", $sformatf("Key Attribute is not attached to Key for key[%0d], key_end_addr:%0h, attr_start_addr:%0h\n",
                                                           i, range_end_key_slot, range_start_attr_slot));

	end

	key_slot_range.push_back(key_slot);
	attr_slot_range.push_back(attr_slot);

	// update next key slot address range
	range_start_key_slot += key_hole;
	range_end_key_slot = range_start_key_slot + limit_key_slot_addr;

	// update next key slot address range
	range_start_attr_slot += key_hole;
	range_end_attr_slot = range_start_attr_slot + limit_attr_slot_addr;

      end
    end
endfunction

// Return address range information as a string
function string sinc_axi_key_range::stringify();
  return($sformatf("%s[%016x - %016x]",stringify_base(),range_start,range_end));
endfunction


// Returns true if address falls in the master abort range which can overlap DRAM
function bit sinc_axi_key_range::is_axi_abort_address(address_t address);
  // implement the is_legal_kli_addr method 

  return (0);
endfunction

// Returns true if range is hit
function bit sinc_axi_key_range::is_range_hit(address_t address);

  //  if (is_axi_abort_address(address)) begin
  //    return (0);
  //  end

  if (!is_range_hit_base(address)) begin
    return (0);
  end

  `uvm_info("get_addr_types_hit",$sformatf("Check addr %0h hit on %0s",address, dst_compid.name()),UVM_DEBUG); 

  foreach (key_slot_range[id]) begin
    if (key_slot_range[id].is_range_hit(address)) begin
      return (1);
    end
  end

  foreach (attr_slot_range[id]) begin
    if (attr_slot_range[id].is_range_hit(address)) begin
      return (1);
    end
  end

  return (0);
endfunction

// Returns the destination slot id for this address
function int sinc_axi_key_range::get_dst_slotid(address_t address);
  const string METHOD_NAME = "sinc_axi_key_range::get_dst_slotid";

  `uvm_info("get_addr_types_hit",$sformatf("Check addr %0h hit on %0s",address, dst_compid.name()),UVM_DEBUG); 
  foreach (key_slot_range[index]) begin
    if (key_slot_range[index].is_range_hit(address)) begin
      return key_slot_range[index].range_index;
    end
  end

  foreach (attr_slot_range[id]) begin
    if (attr_slot_range[id].is_range_hit(address)) begin
      return attr_slot_range[id].range_index;
    end
  end

  return -1;
endfunction

// Returns the destination slot address type
function sinc_comp_e sinc_axi_key_range::get_dst_slot_addrtype(address_t address);
  const string METHOD_NAME = "sinc_axi_key_range::get_dst_slot_addrtype";
  foreach (key_slot_range[id]) begin
    if (key_slot_range[id].is_range_hit(address)) begin
      `uvm_info("get_dst_slot_addrtype",$sformatf("Check addr %0h hit on %0s [%0s]",address, dst_compid.name(), key_slot_range[id].addr_type.name()),UVM_HIGH); 
      return key_slot_range[id].addr_type;
    end
  end

  foreach (attr_slot_range[id]) begin
    if (attr_slot_range[id].is_range_hit(address)) begin
      `uvm_info("get_dst_slot_addrtype",$sformatf("Check addr %0h hit on %0s [%0s]",address, dst_compid.name() , attr_slot_range[id].addr_type.name()),UVM_HIGH); 
      return attr_slot_range[id].addr_type;
    end
  end

  return ADDR_FREE;
endfunction

// Returns the destination slot component type
function sinc_comp_e sinc_axi_key_range::get_dst_slot_comptype(address_t address);
  const string METHOD_NAME = "sinc_axi_key_range::get_dst_slot_comptype";
  foreach (key_slot_range[id]) begin
    if (key_slot_range[id].is_range_hit(address)) begin
      return key_slot_range[id].comp_type;
    end
  end

  foreach (attr_slot_range[id]) begin
    if (attr_slot_range[id].is_range_hit(address)) begin
      return key_slot_range[id].comp_type;
    end
  end

  return COMP_NULL;
endfunction

//////////////////////////
// Class to describe AXI access to PCR address range
class sinc_axi_pcr_range extends sinc_address_range;
  address_axi_t  base_addr_axi, base_addr_pcr_axi, limit_addr_pcr_axi;
  address_axi_t  base_addr_attr_axi, limit_addr_attr_axi;
  address_axi_t  base_pcr_addr, limit_pcr_slot_addr, base_attr_addr, limit_attr_slot_addr;
  address_axi_t  pcr_hole;
  address_axi_t  base_addr, range_slot_start;
  address_axi_t  range_base_axi, range_start_axi,range_end_axi;   // Start address and end of the axi range
  address_axi_t  range_start_pcr_slot, range_end_pcr_slot, range_start_arrt_slot, range_end_attr_slot;

  sinc_slot_range pcr_slot_range[$];

  int slot_id;
  sinc_comp_e addr_type_list[$];                               // Address type of this address range
  sinc_comp_e    comp_type_list[$];                               // Component type of the component where this address range resides


  bit       comp_enabled;

  extern         function           new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  extern virtual function void      init();
  extern virtual function string    stringify();  
  extern virtual function void      update(int verbosity=0);
  extern         function void      update_range_boundary();
  extern virtual function bit       is_range_hit(address_t address);  
  extern virtual function bit       is_axi_abort_address(address_t address);
  extern virtual function int       get_dst_slotid(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_addrtype(address_t address);
  extern virtual function sinc_comp_e       get_dst_slot_comptype(address_t address);

endclass : sinc_axi_pcr_range

// Creates a new PCR range
function sinc_axi_pcr_range::new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  super.new(comp_id,comp_type,addr_type,range_start,range_end,message);
endfunction

// Initialize configuration dependency
function void sinc_axi_pcr_range::init();
  base_addr_axi   = sinc_features_pkg::get_feature64("AXI_REG_BASE_ADDR");
  base_addr_pcr_axi   = sinc_features_pkg::get_feature64("AXI_PCR_BASE_ADDR");
  limit_addr_pcr_axi  = sinc_features_pkg::get_feature64("AXI_PCR_LIMIT_ADDR");
  limit_pcr_slot_addr = sinc_features_pkg::get_feature64("AXI_PCR_SLOT_LIMIT_ADDR");

  pcr_hole = sinc_features_pkg::get_feature64("AXI_PCR_HOLE");
endfunction

// updates the new AXI Pcr range
function void sinc_axi_pcr_range::update(int verbosity=0);
  sinc_comp_cfg   pcr_comp_cfg;
  sinc_comp_e    m_comp_type;
  range_start = base_addr_pcr_axi;
  range_end   = range_start + limit_addr_pcr_axi;

  dst_compid = sinc_env_pkg::SINC_PCR0;

  pcr_comp_cfg = sys_cfg.get_comp_cfg(SINC_PCR0);
  m_comp_type = sys_cfg.get_comp_type(comp_id);
  if (pcr_comp_cfg.valid_master_cmd_list[m_comp_type].size()) begin
    enabled             = 1;
  end

  update_range_boundary();

  if(enabled)
    begin
      check_range_boundary("sinc_axi_pcr_range");
    end
  update_message(verbosity);
endfunction

// Update helper function
function void sinc_axi_pcr_range::update_range_boundary();
  // create pcr slots
  if(enabled)
    begin
      range_start_pcr_slot = base_addr_pcr_axi;
      range_end_pcr_slot   = range_start_pcr_slot + limit_pcr_slot_addr;

      for (int i=0; i < comp_cfg.num_pcr_ranges; i++) begin
	sinc_slot_range pcr_slot;

	pcr_slot = sinc_slot_range::new(COMP_SINC_PCR, ADDR_PCR, i, range_start_pcr_slot, range_end_pcr_slot, "");

	if (range_end_pcr_slot > (base_addr_axi + limit_addr_pcr_axi)) begin
          `uvm_error("update_range_boundary",$sformatf("This pcr slot configuration is not supported"));  
	end

	pcr_slot_range.push_back(pcr_slot);

	// update next pcr slot address range
	range_start_pcr_slot += pcr_hole;
	range_end_pcr_slot = range_start_pcr_slot + limit_pcr_slot_addr;
      end
    end
endfunction

// Return address range information as a string
function string sinc_axi_pcr_range::stringify();
  return($sformatf("%s[%016x - %016x]",stringify_base(),range_start,range_end));
endfunction


// Returns true if address falls in the master abort range which can overlap DRAM
function bit sinc_axi_pcr_range::is_axi_abort_address(address_t address);
  // implement the is_legal_kli_addr method 

  return (0);
endfunction

// Returns true if range is hit
function bit sinc_axi_pcr_range::is_range_hit(address_t address); 
  if (is_axi_abort_address(address)) begin
    return (0);
  end

  if (!is_range_hit_base(address)) begin
    return (0);
  end

  foreach (pcr_slot_range[id]) begin
    if (pcr_slot_range[id].is_range_hit(address)) begin
      return (1);
    end
  end

  return (0);
endfunction

// Returns the destination slot id for this address
function int sinc_axi_pcr_range::get_dst_slotid(address_t address);
  const string METHOD_NAME = "sinc_axi_pcr_range::get_dst_slotid";

  `uvm_info("pcr_get_addr_types_hit",$sformatf("Check addr %0h hit on %0s",address, dst_compid.name()),UVM_DEBUG); 
  foreach (pcr_slot_range[index]) begin
    if (pcr_slot_range[index].is_range_hit(address)) begin
      `uvm_info("pcr_get_addr_types_hit",$sformatf("addr %0h hit on slot %0d",address, pcr_slot_range[index].range_index),UVM_DEBUG); 
      return pcr_slot_range[index].range_index;
    end
  end

  return -1;
endfunction

// Returns the destination slot address type
function sinc_comp_e sinc_axi_pcr_range::get_dst_slot_addrtype(address_t address);
  const string METHOD_NAME = "sinc_axi_pcr_range::get_dst_slot_addrtype";
  foreach (pcr_slot_range[id]) begin
    if (pcr_slot_range[id].is_range_hit(address)) begin
      return pcr_slot_range[id].addr_type;
    end
  end

  return ADDR_FREE;
endfunction

// Returns the destination slot component type
function sinc_comp_e sinc_axi_pcr_range::get_dst_slot_comptype(address_t address);
  const string METHOD_NAME = "sinc_axi_pcr_range::get_dst_slot_comptype";
  foreach (pcr_slot_range[id]) begin
    if (pcr_slot_range[id].is_range_hit(address)) begin
      return pcr_slot_range[id].comp_type;
    end
  end

  return COMP_NULL;
endfunction

//////////////////////////
// Class to describe AXI access to Reg address range
class sinc_axi_reg_range extends sinc_address_range;
  address_axi_t  base_addr_reg_axi, limit_addr_reg_axi;
  address_axi_t  base_reg_addr, limit_reg_slot_addr, base_attr_addr, limit_attr_slot_addr;
  address_axi_t  reg_hole;
  address_axi_t  base_addr, range_slot_start;
  address_axi_t  range_base_axi, range_start_axi,range_end_axi;   // Start address and end of the axi range
  address_axi_t  range_start_reg_slot, range_end_reg_slot, range_start_arrt_slot, range_end_attr_slot;

  sinc_slot_range reg_slot_range[$];

  int slot_id;
  sinc_comp_e addr_type_list[$];                              // Address type of this address range
  sinc_comp_e    comp_type_list[$];                              // Component type of the component where this address range resides

  bit       comp_enabled;

  extern         function           new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  extern virtual function void      init();
  extern virtual function string    stringify();  
  extern virtual function void      update(int verbosity=0);
  extern         function void      update_range_boundary();
  extern virtual function bit       is_range_hit(address_t address);  
  extern virtual function bit       is_axi_abort_address(address_t address);
endclass : sinc_axi_reg_range

// Creates a new REG range
function sinc_axi_reg_range::new(sinc_comp_e comp_id,sinc_comp_e comp_type,sinc_comp_e addr_type,address_t range_start,address_t range_end,string message);
  super.new(comp_id,comp_type,addr_type,range_start,range_end,message);
endfunction

// Initialize configuration dependency
function void sinc_axi_reg_range::init();
  base_addr_reg_axi   = sinc_features_pkg::get_feature64("AXI_REG_BASE_ADDR");
  limit_addr_reg_axi  = sinc_features_pkg::get_feature64("AXI_REG_LIMIT_ADDR");
endfunction

// updates the new AXI Reg range
function void sinc_axi_reg_range::update(int verbosity=0);
  sinc_comp_cfg   reg_comp_cfg;
  sinc_comp_e m_comp_type;

  range_start = base_addr_reg_axi;
  range_end   = range_start + limit_addr_reg_axi;

  dst_compid = sinc_env_pkg::SINC_REG0;

  reg_comp_cfg = sys_cfg.get_comp_cfg(SINC_REG0);
  m_comp_type = sys_cfg.get_comp_type(comp_id);
  if (reg_comp_cfg.valid_master_cmd_list[m_comp_type].size()) begin
    enabled             = 1;
  end

  update_range_boundary();

  if(enabled)
    begin
      check_range_boundary("sinc_axi_reg_range");
    end
  update_message(verbosity);
endfunction

// Update helper function
function void sinc_axi_reg_range::update_range_boundary();
  // create reg slots
  if(enabled)
    begin
      //
    end
endfunction

// Return address range information as a string
function string sinc_axi_reg_range::stringify();
  return($sformatf("%s[%016x - %016x]",stringify_base(),range_start,range_end));
endfunction


// Returns true if address falls in the master abort range which can overlap DRAM
function bit sinc_axi_reg_range::is_axi_abort_address(address_t address);
  // implement the is_legal_kli_addr method 
  return (0);
endfunction

// Returns true if range is hit
function bit sinc_axi_reg_range::is_range_hit(address_t address); 
  if (!is_range_hit_base(address)) begin
    return (0);
  end

  return (1);
endfunction
*/
`endif  // SINC_ADDRESS_RANGE_LIB_SVH


