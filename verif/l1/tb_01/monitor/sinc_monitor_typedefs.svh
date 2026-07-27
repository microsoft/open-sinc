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
// File        : sinc_monitor_typedefs.svh
// Description : 

`ifndef SINC_MONITOR_TYPEDEFS__SVH
`define SINC_MONITOR_TYPEDEFS__SVH

// Enum for sinc_done_o
typedef enum {SINC_DONE_LOW = 0,
              SINC_DONE_POSEDGE = 1,
              SINC_ERROR_LOW,
              SINC_ERROR_POSEDGE} sinc_sideband_e;


`endif
