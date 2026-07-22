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
// File        : sinc_csd.svh
// Description : 

`ifndef SINC_CSD
`define SINC_CSD

//===========================================================================
// Class: sinc_csd
//
//===========================================================================
class sinc_csd extends uvm_object; // {

  // Variable: type_instance_name
  // String version of comp type instance name (ex. SINC_CACHE)
  string m_type_instance_name = "SINC_CACHE_STORAGE_DIRECTORY";

  // Variable: comp_type_name
  // String version of comp type name (ex. CACHE)
  string m_comp_type_name = "CACHE";

  // Variable: instance_id
  // Indicates this component's instanceID
  int m_instance_id;

  // Variable: is_cache
  // Indicates this is a cache set
  bit m_is_cache;

  // Variable: csd_cache
  // Holds the top level data abstraction of secure cache data structures
  sinc_csd_cache_comp_w_cfg m_csd_cache;

  // Variable: cache_blocks
  // Holds the plaintxt of the cache block's data (DMB's block data is encrypted plaintxt)
  csd_cache_block_t m_cache_blocks[sinc_parameters_pkg::SINC_CACHE_BLOCK_TOTAL_NUM];

  // Variable: valid_cache_lines_handle_q
  // Holds valid cache line's handle in a queue
  sinc_csd_cache_line_comp_w_cfg m_valid_cache_lines_handle_q[$];

  // Variable: cache_sets_has_partial_valid_line_q
  // Holds cache set index that has valid cache line in it
  int m_cache_sets_has_partial_valid_line_q[$];

  // Variable: cache_sets_has_full_valid_line_q
  // Holds cache set index that has valid cache line in it
  int m_cache_sets_has_full_valid_line_q[$];

  mem_configuration m_mem_config;
  // handle to the ECC encode/decode helper object
  mem_hamming_code  m_ham;

  typedef virtual sinc_mem_bkdoor_if sinc_mem_bkdoor_if_t;
  sinc_mem_bkdoor_if_t m_mem_bkdoor_if_h;

  // Variable: m_csd_initialized
  // Set when CSD has called init function
  bit m_csd_initialized = 0;

  `uvm_object_utils_begin(sinc_csd)
    `uvm_field_int ( m_instance_id, UVM_ALL_ON)
    `uvm_field_int ( m_is_cache, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sinc_csd");
    super.new(name);

    // csd_cache = new("SINC_CACHE_COMP");

  endfunction : new

  // return the current cache set's data
  // extern virtual function cache_t get_cache_by_id();

  // create cache sets
  extern virtual function void init_csd(bit en_bkdoor_load = 1);

  // reset cache sets
  extern virtual function void reset_csd();

  extern virtual function void bkdoor_load_csd();

  // return true if corresponding read address result cache hit
  extern virtual function bit is_cache_hit(csd_address_t cpu_word_address);

  // return valid lines of corresponding cache set
  extern virtual function int get_num_cache_lines_per_set(csd_address_t cpu_word_address);

  // update cache line
  // return true if success
  extern virtual function bit update_cache_line(csd_address_t cpu_word_address);

  // update cache block
  // return true if success
  extern virtual function bit update_cache_block(csd_address_t cpu_word_address, csd_cache_block_t cache_block);

  // get cpu word data
  // return cpu word data
  // when cache_active, CSD use whole address range fetch cache block then return corresponding word
  // when cache_disable, CSD use local address range locate the MEM line to return word
  extern virtual function bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] get_cpu_word_data(csd_address_t cpu_word_address, bit is_cache_active);

  // set cpu word data
  // return 1 if succeed
  extern virtual function bit set_cpu_word_data(csd_address_t cpu_word_address, bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] set_data, bit [(sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH / 8) - 1:0] we);

  // get random valid cache line
  // return the cache line handle if there is one, from valid_cache_lines_handle_q
  extern virtual function sinc_csd_cache_line_comp_w_cfg get_random_valid_cache_line();

  // get random cache line
  // return the cache line randomly selected from existing cache lines
  extern virtual function sinc_csd_cache_line_comp_w_cfg get_random_cache_line();

  // get random cache set that has none of the cache lines valid
  extern virtual function bit get_rand_cache_set_non_valid (ref sinc_csd_cache_set_comp_w_cfg cache_set);

  // get random cache set that has partial of the cache lines valid
  extern virtual function bit get_rand_cache_set_partial_valid (ref sinc_csd_cache_set_comp_w_cfg cache_set);

  // get random cache set that has full of the cache lines valid
  extern virtual function bit get_rand_cache_set_full_valid (ref sinc_csd_cache_set_comp_w_cfg cache_set);
endclass : sinc_csd // }

// function cache_t sinc_csd::get_cache();
//   return(m_cache);
// endfunction : get_cache_data

function void sinc_csd::init_csd(bit en_bkdoor_load = 1);
  cache_mem_w_ecc_t   orig_data;
  cache_mem_decoded_t decoded_data;

  `uvm_info("sinc_csd::init_csd:", $sformatf("Initialize Cache Storage Directory, %0d Way-Associate-Cache, Sets [%0d], Block_Size[%0d B], m_csd_initialized [%0d]",
      sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE, sinc_parameters_pkg::SINC_CACHE_SETS_NUM, sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE, m_csd_initialized), UVM_LOW)

  if (!m_csd_initialized) begin
    // init on cache -> sets -> cache_line -> mem_line
    // csd_cache = new("csd_cache"); //sinc_csd_cache_comp_w_cfg::type_id::create ("csd_cache");
    m_csd_cache = sinc_csd_cache_comp_w_cfg::type_id::create ("csd_cache");
    m_csd_cache.initiate_csd_sets();

    // load erased cache ram to CSD
    if (en_bkdoor_load) begin
      bkdoor_load_csd();
    end

    m_csd_initialized = 1;
  end else begin
    if (en_bkdoor_load) begin
      bkdoor_load_csd();
    end
  end
endfunction : init_csd

function void sinc_csd::reset_csd();

  `uvm_info("sinc_csd::reset_csd:", $sformatf("Reset Cache Storage Directory, %0d Way-Associate-Cache, Sets [%0d], Block_Size[%0d B], m_csd_initialized [%0d]",
      sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE, sinc_parameters_pkg::SINC_CACHE_SETS_NUM, sinc_parameters_pkg::SINC_CACHE_BLOCK_SIZE, m_csd_initialized), UVM_LOW)

  m_csd_cache  = null;
  m_csd_initialized = 0;
  m_valid_cache_lines_handle_q.delete();
  m_cache_sets_has_partial_valid_line_q.delete();
  m_cache_sets_has_full_valid_line_q.delete();
  init_csd(1);

endfunction : reset_csd

function void sinc_csd::bkdoor_load_csd();
  cache_mem_w_ecc_t            orig_data;
  cache_mem_decoded_t          decoded_data;
  int                          cache_line_idx;
  int                          cache_set_idx;
  int                          cache_line_offset_per_set;
  int                          mem_line_per_cache_mem = sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE / sinc_parameters_pkg::SINC_MEM_LINE_WIDTH;
  int                          mem_line_idx_offset;
  sinc_csd_mem_line_comp_w_cfg mem_line_obj;

  `uvm_info("sinc_csd::init_csd:", $sformatf("Backdoor load Cache Storage Directory, MEM Depth [%0d]",
      sinc_parameters_pkg::SINC_CACHE_MEM_RAM_DEPTH), UVM_LOW)

  // load erased cache ram to CSD
  for (int cache_mem_addr = 0; cache_mem_addr < sinc_parameters_pkg::SINC_CACHE_MEM_RAM_DEPTH; cache_mem_addr++) begin
    // for (int cache_mem_addr = 0; cache_mem_addr < 2; cache_mem_addr++) begin
    // fixme-hw:
    // 1: this is not working for 128 (ADO: )
    // 2: ham object need to grab every time do decode
    m_ham       = m_mem_config.get_model();
    orig_data = m_mem_bkdoor_if_h.cache_mem_read(cache_mem_addr);

    m_ham.decode(orig_data, cache_mem_addr, 0);
    decoded_data = m_ham.m_data;

    // store the decoded data to corresponding cache line's mem line
    // decoded_data is 128 bits, for a cache block it needs 32 * 128 bits
    // converting cache_mem_addr to mem_line object

    // locate cache line index
    cache_line_idx = cache_mem_addr / sinc_parameters_pkg::SINC_CACHE_MEM_LINES_PER_CACHE;

    // locate cache set index
    cache_set_idx = cache_line_idx / sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

    // locate cache line offset per set
    cache_line_offset_per_set = cache_line_idx % sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

    // locate which MEM_LINE to update per cache line
    mem_line_idx_offset = (cache_mem_addr * mem_line_per_cache_mem) % sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE;

    //if ((cache_mem_addr < 100) || (cache_mem_addr == (sinc_parameters_pkg::SINC_CACHE_MEM_RAM_DEPTH-1))) begin // for debug purpose, only print the line debuger intested in
    `uvm_info("sinc_csd::init_csd:", $sformatf("\nCache_mem_addr[%0d], original ['h%0h], decoded ['h%0h]",
        cache_mem_addr, orig_data, decoded_data), UVM_HIGH)
    //end

    // triage the 128 bits decoded data to word mem_line in cache storage directory
    for (int idx = 0; idx < (sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE / sinc_parameters_pkg::SINC_MEM_LINE_WIDTH); idx++) begin
      mem_line_obj= m_csd_cache.m_cache_sets[cache_set_idx].m_cache_lines[cache_line_offset_per_set].m_mem_lines[mem_line_idx_offset + idx];

      if (mem_line_obj == null) begin
        `uvm_error("sinc_csd",
          $sformatf("Not able to allocate mem_line for cache_set_idx [%0d], cache_line_offset_per_set [%0d], mem_lines[%0d], ",
            cache_set_idx, cache_line_offset_per_set, (mem_line_idx_offset + idx)))
      end
      mem_line_obj.m_mem_line_data = decoded_data[sinc_parameters_pkg::SINC_MEM_LINE_WIDTH * idx +: sinc_parameters_pkg::SINC_MEM_LINE_WIDTH];
      //if ((cache_mem_addr < 100) || (cache_mem_addr == (sinc_parameters_pkg::SINC_CACHE_MEM_RAM_DEPTH-1))) begin // for debug purpose, only print the line debuger intested in
      `uvm_info("sinc_csd::init_csd:", $sformatf("\nstore in cache_set[%0d], cache_line[%0d], cache_line_offset_per_set[%0d], mem_line_idx_offset[%0d], mem_data['h%0h]",
          cache_set_idx, cache_line_idx, cache_line_offset_per_set, mem_line_idx_offset + idx, mem_line_obj.m_mem_line_data), UVM_HIGH)
      //end

      if (mem_line_obj.m_mem_line_data == 32'hdead_beef) begin
        `uvm_error("sinc_csd",
          $sformatf("Capture ECC error when preload cache storage directory from cache mem on cache_mem_addr[%0d], orig_data['h%0h], data['h%0h], ",
            cache_mem_addr, orig_data, decoded_data))
      end

      // check on cache settings
      if ((mem_line_obj.m_cache_set_idx !== cache_set_idx) ||
          (mem_line_obj.m_cache_line_idx !== cache_line_idx) ||
          (mem_line_obj.m_cache_line_offset_per_set !== cache_line_offset_per_set) ||
          (mem_line_obj.m_cache_mem_line_offset_per_cache_line !== (mem_line_idx_offset + idx)))
        `uvm_error("sinc_csd",
          $sformatf("Back door load CSD with missmatched config on: cache_set_idx[%0d] vs. [%0d], cache_line_idx[%0d] vs. [%0d], cache_line_offset_per_set[%0d] vs. [%0d], cache_mem_line_offset_per_cache_line[%0d] vs. [%0d], ",
            mem_line_obj.m_cache_set_idx, cache_set_idx, mem_line_obj.m_cache_line_idx, cache_line_idx, mem_line_obj.m_cache_line_offset_per_set, cache_line_offset_per_set, mem_line_obj.m_cache_mem_line_offset_per_cache_line, (mem_line_idx_offset+idx)))
    end

  end

endfunction : bkdoor_load_csd

function bit sinc_csd::is_cache_hit(csd_address_t cpu_word_address);
  sinc_csd_cache_set_comp_w_cfg cache_set_h;                                                // handler to the cache set
  sinc_cache_set_t              cache_set     = cpu_word_address[`SINC_CACHE_SET_RANGE_SEL];
  sinc_cache_tag_t              cache_tag     = cpu_word_address[`SINC_CACHE_TAG_RANGE_SEL];
  int                           cache_set_idx = int'(cache_set);
  bit                           is_cache_hit_ret;

  cache_set_h = m_csd_cache.m_cache_sets[cache_set_idx];
  foreach (cache_set_h.m_cache_lines[set_line_idx]) begin
    if (cache_set_h.m_cache_lines[set_line_idx].m_is_valid) begin
      if (cache_set_h.m_cache_lines[set_line_idx].m_cache_tag == cache_tag) begin
        is_cache_hit_ret = 1;
      end
    end
  end

  `uvm_info(m_type_instance_name, $sformatf("CPU address['h%0h], is_cache_hit['h%0h], cache_set[%0d], cache_tag[%0d]", cpu_word_address, is_cache_hit_ret, cache_set, cache_tag), UVM_HIGH)

  return (is_cache_hit_ret);

endfunction : is_cache_hit

function int sinc_csd::get_num_cache_lines_per_set(csd_address_t cpu_word_address);
  sinc_csd_cache_set_comp_w_cfg cache_set_h;                                                  // handler to the cache set
  sinc_cache_set_t              cache_set       = cpu_word_address[`SINC_CACHE_SET_RANGE_SEL];
  sinc_cache_tag_t              cache_tag       = cpu_word_address[`SINC_CACHE_TAG_RANGE_SEL];
  int                           valid_lines_cnt = 0;
  int                           cache_set_idx   = int'(cache_set);

  cache_set_h = m_csd_cache.m_cache_sets[cache_set_idx];
  foreach (cache_set_h.m_cache_lines[set_line_idx]) begin
    if (cache_set_h.m_cache_lines[set_line_idx].m_is_valid) begin
      valid_lines_cnt++;
    end
  end

  `uvm_info(m_type_instance_name, $sformatf("CPU address['h%0h], cache_set[%0d]", cpu_word_address, cache_set), UVM_HIGH)

  return (valid_lines_cnt);

endfunction : get_num_cache_lines_per_set

function bit sinc_csd::update_cache_line(csd_address_t cpu_word_address);
  sinc_csd_cache_set_comp_w_cfg  cache_set_h;                                                               // handler to the cache set
  sinc_csd_cache_line_comp_w_cfg cache_line_h;                                                              // handler to the cache line
  sinc_cache_set_t               cache_set        = cpu_word_address[`SINC_CACHE_SET_RANGE_SEL];
  sinc_cache_tag_t               cache_tag        = cpu_word_address[`SINC_CACHE_TAG_RANGE_SEL];
  int                            cache_set_idx    = int'(cache_set);
  int                            cache_block_idx  = int'(cpu_word_address[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
  csd_cache_block_t              cache_block_data = m_cache_blocks[cache_block_idx];
  bit                            is_full_valid    = 1;

  cache_set_h = m_csd_cache.m_cache_sets[cache_set_idx];

  // find the line to update, tracked by m_cache_fifo_idx
  `uvm_info("update_cache_line", $sformatf("CPU address['h%0h], cache_set[%0d], cache_tag[%0d], cache_block_num[%0d], m_cache_fifo_idx[%0d], cache_block_data['h%0h]", cpu_word_address, cache_set, cache_tag, cache_block_idx, cache_set_h.m_cache_fifo_idx, cache_block_data), UVM_HIGH)

  cache_line_h = cache_set_h.m_cache_lines[cache_set_h.m_cache_fifo_idx];
  void'(cache_line_h.set_cache_line_data(cache_block_data));
  cache_line_h.m_is_valid    = 1;
  cache_line_h.m_cache_tag = cache_tag;
  cache_set_h.m_cache_fifo_idx++;

  // additional check for cache consistency
  if (cache_line_h.m_cache_set !== cache_set) begin
    `uvm_error("sinc_csd",
      $sformatf("Found missmatched cache_set, cache_set_indx [%0d], cache_line handel's cache_set[%0d], ",
        cache_set, cache_line_h.m_cache_set))
  end

  // add valid cache line to valid_cache_lines_handle_q
  m_valid_cache_lines_handle_q.push_back(cache_line_h);

  // update cache sets list for set has partial valid cache line
  foreach (cache_set_h.m_cache_lines[i]) begin
    if (!cache_set_h.m_cache_lines[i].m_is_valid) begin
      is_full_valid = 0;
    end
  end

  if (!is_full_valid) begin
    int found_idx[$] = m_cache_sets_has_partial_valid_line_q.find_first_index(x) with (x == cache_set_idx);
    if (!found_idx.size()) begin
      m_cache_sets_has_partial_valid_line_q.push_back(cache_set_idx);
      `uvm_info("update_cache_line", $sformatf("Cache_set [%0d] is added to cache_sets_has_partial_valid_line_q", cache_set_idx), UVM_HIGH)
    end
  end else begin
    int found_partial_idx[$] = m_cache_sets_has_partial_valid_line_q.find_first_index(x) with (x == cache_set_idx);
    int found_full_idx[$]    = m_cache_sets_has_full_valid_line_q.find_first_index(x) with (x == cache_set_idx);
    if (found_partial_idx.size()) begin
      m_cache_sets_has_partial_valid_line_q.delete(found_partial_idx[0]);
      m_cache_sets_has_full_valid_line_q.push_back(cache_set_idx);
      `uvm_info("update_cache_line", $sformatf("Cache_set [%0d] is delted from cache_sets_has_partial_valid_line_q, add to cache_sets_has_full_valid_line_q", cache_set_idx), UVM_HIGH)
    end
  end

  m_cache_sets_has_partial_valid_line_q = m_cache_sets_has_partial_valid_line_q.unique();
  m_cache_sets_has_full_valid_line_q    = m_cache_sets_has_full_valid_line_q.unique();
  `uvm_info("update_cache_line", $sformatf("m_cache_sets_has_partial_valid_line_q.size = [%0d], m_cache_sets_has_full_valid_line_q = [%0d]", m_cache_sets_has_partial_valid_line_q.size(), m_cache_sets_has_full_valid_line_q.size()), UVM_HIGH)

  return (1);

endfunction : update_cache_line

function bit sinc_csd::update_cache_block(csd_address_t cpu_word_address, csd_cache_block_t cache_block);
  int cache_block_idx = int'(cpu_word_address[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
  m_cache_blocks[cache_block_idx] = cache_block;

  `uvm_info(m_type_instance_name, $sformatf("Update cache block [%0d], with data['h%0h], corresponding cpu_address['h%0h]", cache_block_idx, cache_block, cpu_word_address), UVM_HIGH)

  return (1);

endfunction : update_cache_block

function bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] sinc_csd::get_cpu_word_data(csd_address_t cpu_word_address, bit is_cache_active);
  int                                                    word_sel         = int'(cpu_word_address % sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET);
  bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] cpu_word_data;
  sinc_csd_cache_set_comp_w_cfg                          cache_set_h;                                                                                               // handler to the cache set
  sinc_csd_cache_line_comp_w_cfg                         cache_line_h;                                                                                              // handler to the cache line
  bit                                                    is_cache_hit     = 0;
  sinc_cache_set_t                                       cache_set        = cpu_word_address[`SINC_CACHE_SET_RANGE_SEL];
  sinc_cache_tag_t                                       cache_tag        = cpu_word_address[`SINC_CACHE_TAG_RANGE_SEL];
  int                                                    cache_set_idx    = int'(cache_set);
  int                                                    cache_block_idx  = int'(cpu_word_address[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
  csd_cache_block_t                                      cache_block_data = m_cache_blocks[cache_block_idx];

  // cache_set_h = csd_cache.cache_sets[cache_set_idx];
  // cache_line_h = cache_set_h.cache_lines[cache_set_h.m_cache_fifo_idx];

  // find the line to update, tracked by m_cache_fifo_idx
  `uvm_info(m_type_instance_name, $sformatf("get_cpu_word_data, CPU address['h%0h], is_cache_active['h%0h]", cpu_word_address, is_cache_active), UVM_HIGH)

  if (is_cache_active) begin
    // return the cache block data
    cpu_word_data = cache_block_data[word_sel*32 +: 32];
    `uvm_info(m_type_instance_name, $sformatf("CPU address['h%0h], cache_block_idx[%0d], word_sel[%0d], return data['h%0h] ",
        cpu_word_address, cache_block_idx, word_sel, cpu_word_data), UVM_HIGH)

  end else begin
    // locate the cache line's mem data
    int set_sel;
    int line_num;
    int line_sel;

    // Cache act as local memory when cache not active
    csd_address_t cpu_local_address = csd_address_t'(cpu_word_address[`SINC_CACHE_ADDR_RANGE_SEL]);

    // locate the cache line number
    line_num = (cpu_local_address / sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE);

    // locate the cache set the line belong to
    set_sel = line_num / sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

    // N-Way cache set's line selection
    line_sel = line_num % sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

    cache_set_h  = m_csd_cache.m_cache_sets[set_sel];
    cache_line_h = cache_set_h.m_cache_lines[line_sel];

    cpu_word_data = cache_line_h.m_mem_lines[word_sel].m_mem_line_data;

    `uvm_info(m_type_instance_name, $sformatf("CPU address['h%0h], cpu_local_address['h%0h], line_num[%0d], set_sel[%0d], line_sel[%0d], return data['h%0h] ",
        cpu_word_address, cpu_local_address, line_num, set_sel, line_sel, cpu_word_data), UVM_HIGH)

  end

  // `uvm_info(type_instance_name, $sformatf("CPU address['h%0h], is_cache_hit['h%0h], cache_set[%0d], cache_tag[%0d]", cpu_word_address, is_cache_hit, cache_set, cache_tag), UVM_HIGH)

  return (cpu_word_data);

endfunction : get_cpu_word_data

function bit sinc_csd::set_cpu_word_data(csd_address_t cpu_word_address, bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] set_data, bit [(sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH / 8) - 1:0] we);
  // bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] cpu_word_data;
  int                                                    word_sel         = int'(cpu_word_address % sinc_parameters_pkg::SINC_CACHE_BLOCK_FETCH_CPU_ADDRESS_OFFSET);
  sinc_csd_cache_set_comp_w_cfg                          cache_set_h;                                                                                               // handler to the cache set
  sinc_csd_cache_line_comp_w_cfg                         cache_line_h;                                                                                              // handler to the cache line
  bit                                                    is_cache_hit     = 0;
  sinc_cache_set_t                                       cache_set        = cpu_word_address[`SINC_CACHE_SET_RANGE_SEL];
  sinc_cache_tag_t                                       cache_tag        = cpu_word_address[`SINC_CACHE_TAG_RANGE_SEL];
  int                                                    cache_set_idx    = int'(cache_set);
  int                                                    cache_block_idx  = int'(cpu_word_address[`SINC_CACHE_BLOCK_NUM_RANGE_SEL]);
  csd_cache_block_t                                      cache_block_data = m_cache_blocks[cache_block_idx];
  // locate the cache line's mem data
  int                                                    set_sel;
  int                                                    line_num;
  int                                                    line_sel;
  mem_line_data_t                                        orig_data;
  bit [sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH-1:0] masked_set_data  = set_data;

  // Cache act as local memory when cache not active (SINC only allow CPU write in non active mode)
  csd_address_t cpu_local_address = csd_address_t'(cpu_word_address[`SINC_CACHE_ADDR_RANGE_SEL]);

  // locate the cache line number
  line_num = (cpu_local_address / sinc_parameters_pkg::SINC_MEM_LINE_NUM_PER_CACHE_LINE);

  // locate the cache set the line belong to
  set_sel = line_num / sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

  // N-Way cache set's line selection
  line_sel = line_num % sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;

  cache_set_h  = m_csd_cache.m_cache_sets[set_sel];
  cache_line_h = cache_set_h.m_cache_lines[line_sel];
  orig_data    = cache_line_h.m_mem_lines[word_sel].m_mem_line_data;

  for (int byte_en_sel=0; byte_en_sel < (sinc_parameters_pkg::SINC_CPU_MEM_DATA_WIDTH / 8); byte_en_sel++) begin
    if (we[byte_en_sel]) begin
      masked_set_data[byte_en_sel*8 +: 8] = set_data[byte_en_sel*8 +: 8];
    end else begin
      masked_set_data[byte_en_sel*8 +: 8] = orig_data[byte_en_sel*8 +: 8];
    end
  end

  cache_line_h.m_mem_lines[word_sel].m_mem_line_data = masked_set_data;

  `uvm_info(m_type_instance_name, $sformatf("CPU address['h%0h], cpu_local_address['h%0h], line_num[%0d], set_sel[%0d], line_sel[%0d], set_data['h%0h], masked_set_data['h%0h] - result ['h%0h] ",
      cpu_word_address, cpu_local_address, line_num, set_sel, line_sel, set_data, masked_set_data, cache_line_h.m_mem_lines[word_sel].m_mem_line_data), UVM_HIGH)

endfunction : set_cpu_word_data

function sinc_csd_cache_line_comp_w_cfg sinc_csd::get_random_valid_cache_line();
  int rand_index;
  int valid_cache_line_size = m_valid_cache_lines_handle_q.size();

  if (valid_cache_line_size > 0) begin
    if (!(std::randomize(rand_index) with {
            rand_index >= 0;
            rand_index < valid_cache_line_size;
          })) begin
      `uvm_fatal(get_name(), "Unable to randomize rand_index")
    end

    `uvm_info("get_random_valid_cache_line", $sformatf("Return cache line in m_valid_cache_lines_handle_q: set['h%0h], tag['h%0h]",
        m_valid_cache_lines_handle_q[rand_index].m_cache_set, m_valid_cache_lines_handle_q[rand_index].m_cache_tag), UVM_HIGH)
    return (m_valid_cache_lines_handle_q[rand_index]);
  end else begin
    `uvm_info("get_random_valid_cache_line", $sformatf("Found [%0d] cache line in m_valid_cache_lines_handle_q", m_valid_cache_lines_handle_q.size()), UVM_HIGH)
    return (null);
  end

endfunction : get_random_valid_cache_line

function sinc_csd_cache_line_comp_w_cfg sinc_csd::get_random_cache_line();
  int rand_set_index;
  int rand_line_index;
  int valid_cache_line_size = m_valid_cache_lines_handle_q.size();

  if (!(std::randomize(rand_set_index) with {
          rand_set_index >= 0;
          rand_set_index < sinc_parameters_pkg::SINC_CACHE_SETS_NUM;
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize rand_index")
  end

  if (!(std::randomize(rand_line_index) with {
          rand_line_index >= 0;
          rand_line_index < sinc_parameters_pkg::SINC_N_WAY_ASSOCIATE_CACHE_LINE;
        })) begin
    `uvm_fatal(get_name(), "Unable to randomize rand_index")
  end

  `uvm_info("get_random_cache_line", $sformatf("Return cache line: set['h%0h], tag['h%0h]",
      m_csd_cache.m_cache_sets[rand_set_index].m_cache_lines[rand_line_index].m_cache_set, m_csd_cache.m_cache_sets[rand_set_index].m_cache_lines[rand_line_index].m_cache_tag), UVM_HIGH)

  return (m_csd_cache.m_cache_sets[rand_set_index].m_cache_lines[rand_line_index]);

endfunction : get_random_cache_line

function bit sinc_csd::get_rand_cache_set_non_valid(ref sinc_csd_cache_set_comp_w_cfg cache_set);
  int rand_index;
  bit rand_success = 1;

  if ((m_cache_sets_has_partial_valid_line_q.size() + m_cache_sets_has_full_valid_line_q.size()) < sinc_parameters_pkg::SINC_CACHE_LINE_NUM) begin
    if (!std::randomize(rand_index) with {
          if (m_cache_sets_has_partial_valid_line_q.size()) {
            !(rand_index inside {m_cache_sets_has_partial_valid_line_q});
          }
          if (m_cache_sets_has_full_valid_line_q.size()) {
            !(rand_index inside {m_cache_sets_has_full_valid_line_q});
          }

          rand_index >= 0;
          rand_index < sinc_parameters_pkg::SINC_CACHE_SETS_NUM;
        }) begin
      `uvm_fatal(get_name(), "Unable to randomize rand_index")
    end
  end else begin
    rand_success = 0;
  end

  if (rand_success) begin
    cache_set = m_csd_cache.m_cache_sets[rand_index];
    `uvm_info("get_rand_cache_set_non_valid", $sformatf("Found cache set index [%0d], SET_ADDR['h%0h]", rand_index, cache_set.m_cache_set), UVM_HIGH)
  end else begin
    `uvm_info("get_rand_cache_set_non_valid", $sformatf("Not able to find a cache set that has non valid lines, rand_success[%0d]", rand_success), UVM_HIGH)
  end

  return (rand_success);

endfunction : get_rand_cache_set_non_valid

function bit sinc_csd::get_rand_cache_set_partial_valid(ref sinc_csd_cache_set_comp_w_cfg cache_set);
  int rand_index;
  bit rand_success = 1;

  if (m_cache_sets_has_partial_valid_line_q.size()) begin
    if (!std::randomize(rand_index) with {
          (rand_index inside {m_cache_sets_has_partial_valid_line_q});
        }) begin
      `uvm_fatal(get_name(), "Unable to randomize rand_index")
    end
  end else begin
    rand_success = 0;
  end

  if (rand_success) begin
    cache_set = m_csd_cache.m_cache_sets[rand_index];
    `uvm_info("get_rand_cache_set_partial_valid", $sformatf("Found cache set index [%0d], SET_ADDR['h%0h]", rand_index, cache_set.m_cache_set), UVM_HIGH)
  end else begin
    `uvm_info("get_rand_cache_set_partial_valid", $sformatf("Not able to find a cache set that has non valid lines, rand_success[%0d]", rand_success), UVM_HIGH)
  end

  return (rand_success);

endfunction : get_rand_cache_set_partial_valid

function bit sinc_csd::get_rand_cache_set_full_valid(ref sinc_csd_cache_set_comp_w_cfg cache_set);
  int rand_index;
  bit rand_success = 1;

  if (m_cache_sets_has_full_valid_line_q.size()) begin
    if (!std::randomize(rand_index) with {
          (rand_index inside {m_cache_sets_has_full_valid_line_q});
        }) begin
      `uvm_fatal(get_name(), "Unable to randomize rand_index")
    end
  end else begin
    // rand_success = 0;
    // pick the first partial
    if (m_cache_sets_has_partial_valid_line_q.size()) begin
      rand_index = m_cache_sets_has_partial_valid_line_q[0];
    end
  end

  if (rand_success) begin
    cache_set = m_csd_cache.m_cache_sets[rand_index];
    `uvm_info("get_rand_cache_set_full_valid", $sformatf("Found cache set index [%0d], SET_ADDR['h%0h]", rand_index, cache_set.m_cache_set), UVM_HIGH)
  end else begin
    `uvm_info("get_rand_cache_set_full_valid", $sformatf("Not able to find a cache set that has non valid lines, rand_success[%0d]", rand_success), UVM_HIGH)
  end

  return (rand_success);

endfunction : get_rand_cache_set_full_valid

`endif // SINC_CSD
