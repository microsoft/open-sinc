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
// File          : params.h
// Description   : Test parameters for the sinc_cache_initialized_encrypt C test

#pragma once
#include <bifrost.h>

TEST_PARAMS_CLASS(TestParams);
class TestParams: public BifrostTestParams
{
public:
  UINT32 disable_encryption;
  UINT32 PWRGATE;
  UINT32 CLKGATE;
  UINT32 DIS_PWR_SWTITCH;

  void initParams() {
    disable_encryption = 0;
    PWRGATE = 0;
    CLKGATE = 0;
    DIS_PWR_SWTITCH = 0;
  }
 
  void yamlParams();
};

// Not using TestVars feature
NO_TEST_VARS;
