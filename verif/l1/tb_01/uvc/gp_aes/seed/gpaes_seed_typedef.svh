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
// File        : gpaes_seed_typedef.svh
// Description : MSFT Gpaes Seed required type defines, enums etc.

`ifndef GPAES_SEED_TYPEDEF__SVH
`define GPAES_SEED_TYPEDEF__SVH

// seed interface
typedef virtual gpaes_seed_if gpaes_seed_vif;
typedef virtual gpaes_seed_if.mp_passive gpaes_seed_passive_vif;

typedef enum { RANDOM, ZERO } seed_data_type_e;
typedef enum { START, DONE } seed_event_e;

typedef bit [`GPAES_MAX_SEED_DATA_WIDTH - 1:0] max_seed_data_t;

`endif //GPAES_SEED_TYPEDEF__SVH

