# Copyright (c) Microsoft Corporation and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# File          : sinc.clocks.sdc
# Description   : Clock definitions used for SInC reset-domain crossing (RDC) analysis

# Clock set to 1200MHz
set CLOCK_PERIOD 0.833

# Reduce period 10% for ocv
set CLOCK_OCV [expr $CLOCK_PERIOD * 0]
set CLOCK_PERIOD [expr $CLOCK_PERIOD - $CLOCK_OCV]
set HALF_CLOCK [expr $CLOCK_PERIOD/2]

create_clock -name clk_i -add -period $CLOCK_PERIOD -waveform [list 0.0 $HALF_CLOCK] [get_ports clk_i]
set_clock_groups -allow_paths -asynchronous -name Group_clk_i -group clk_i
