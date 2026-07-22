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
// File        : hvl_top.sv
// Description : This module loads the test package and starts the UVM phases.

`ifndef SINC_HVL_TOP
`define SINC_HVL_TOP

module hvl_top;

  import uvm_pkg::*;
  import sinc_tests_pkg::*;

  // pragma uvmf custom module_item_additional begin
  // pragma uvmf custom module_item_additional end

  initial begin
    $timeformat(-9, 3, "ns", 5);
    run_test();
  end

endmodule : hvl_top

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif
