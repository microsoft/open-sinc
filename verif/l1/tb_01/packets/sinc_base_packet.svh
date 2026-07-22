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
// File        : sinc_base_packet.svh
// Description : This is basic packet used for base class of SINC stimulus.

`ifndef SINC_BASE_PACKET
`define SINC_BASE_PACKET

//---------------------------------
// SINC Packet Class
//---------------------------------
class sinc_base_packet extends uvm_sequence_item;
  rand int m_pre_delay;
  rand int m_post_delay;

  `uvm_object_utils(sinc_base_packet)

  // Variable: m_sys_cfg
  // config parameters for each SINC component on each SINC
  sinc_env_pkg::sinc_sys_cfg m_sys_cfg;

  //---------------------------------
  // Constructor
  //---------------------------------
  function new( string name = "sinc_base_packet" );
    super.new(name);
    m_sys_cfg = sinc_env_pkg::sinc_sys_cfg::get_inst();
  endfunction : new

  //---------------------------------
  // post_randomize()
  //---------------------------------
  function void post_randomize ();
  endfunction : post_randomize

  //---------------------------------
  // print_packet()
  //---------------------------------

  virtual function void print_packet ( int iter_n=0 );
  endfunction : print_packet

  //---------------------------------
  // Constraints
  //---------------------------------
  extern constraint packet_pre_delay_c;
  extern constraint packet_post_delay_c;

endclass : sinc_base_packet

constraint sinc_base_packet::packet_pre_delay_c {
  // fixme-hw: introduce delay
  m_pre_delay == 0;
}

constraint sinc_base_packet::packet_post_delay_c {
  // fixme-hw: introduce delay
  m_post_delay == 0;
}

`endif // SINC_BASE_PACKET
