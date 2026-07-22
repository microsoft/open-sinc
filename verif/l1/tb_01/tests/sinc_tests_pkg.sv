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
// File        : sinc_tests_pkg.sv
// Description : This package contains all tests currently written for

`ifndef SINC_TESTS_PKG
`define SINC_TESTS_PKG

package sinc_tests_pkg;

  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import pal_pkg::*;
  import pal_params_pkg::*;

  import csr_pkg_sinc_regs::*;
  import sinc_regmodel_pkg::*;
  import sinc_parameters_pkg::*;
  import sinc_env_pkg::*;
  import sinc_sequences_pkg::*;

  `include "uvm_macros.svh"

  // pragma uvmf custom package_imports_additional begin
  // pragma uvmf custom package_imports_additional end

  `include "test_top.svh"
  `include "sinc_negative_base_test.svh"

  // pragma uvmf custom package_item_additional begin
  // UVMF_CHANGE_ME : When adding new tests to the src directory
  //    be sure to add the test file here so that it will be
  //    compiled as part of the test package.  Be sure to place
  //    the new test after any base tests of the new test.
  // pragma uvmf custom package_item_additional end

endpackage  : sinc_tests_pkg

// pragma uvmf custom external begin
// pragma uvmf custom external end

`endif  // SINC_TESTS_PKG
