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
// File         : aes.vh
// Description  : Compile-time defines for the AES IP (key sizes, modes,
//                round counts, datapath/control state encodings).

`define AES_SSIZE 160

// key length
`define AES128   4'b0001
`define AES192   4'b0010
`define AES256   4'b0011


// modes
`define ECB      4'b0001
`define CBC      4'b0010
`define CTR      4'b0011
`define CFB      4'b0100
`define OFB      4'b0101
`define XTS      4'b0110

// XTS unit size
`define XTS16    4'b0001
`define XTS512   4'b0010
`define XTS1024  4'b0011
`define XTS2048  4'b0100
`define XTS4096  4'b0101

// register offset
`define OFST_CMDADDR    12'h000
`define OFST_STATUS     12'h004

