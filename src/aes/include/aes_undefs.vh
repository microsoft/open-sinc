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
// File         : aes_undefs.vh
// Description  : `undef counterpart to aes.vh; clears all AES macros so they
//                can be safely redefined elsewhere.

`undef AES_SSIZE

// key length
`undef AES128
`undef AES192
`undef AES256

// modes
`undef ECB
`undef CBC
`undef CTR
`undef CFB
`undef OFB
`undef XTS

// XTS unit size
`undef XTS16
`undef XTS512
`undef XTS1024
`undef XTS2048
`undef XTS4096

// register offset
`undef OFST_CMDADDR
`undef OFST_STATUS



