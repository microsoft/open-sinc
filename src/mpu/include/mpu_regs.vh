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

`ifndef _MPU_REGS_VH_
`define _MPU_REGS_VH_



// ##########################################################################
//        ADDRESS MACROS
// ##########################################################################

// Address Space for Addressmap: mpu_regs
// Source filename: mpu_regs.csr, line: 109
// Register: mpu_regs.mpu_status
`define MPU_REGS_MPU_STATUS_ADDRESS 8'h00
`define MPU_REGS_MPU_STATUS_BYTE_ADDRESS 8'h00


// ##########################################################################
//        TEMPLATE MACROS
// ##########################################################################

// Addressmap type: mpu_regs
// Addressmap template: mpu_regs
// Source filename: mpu_regs.csr, line: 28
`define MPU_REGS_SIZE 9'h100
`define MPU_REGS_BYTE_SIZE 9'h100
// Register member: mpu_regs.mpu_status
// Register type referenced: mpu_regs::mpu_status
// Register template referenced: mpu_regs::mpu_status
`define MPU_REGS_MPU_STATUS_OFFSET 8'h00
`define MPU_REGS_MPU_STATUS_BYTE_OFFSET 8'h00
`define MPU_REGS_MPU_STATUS_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_WRITE_ACCESS 1
`define MPU_REGS_MPU_STATUS_RESET_VALUE 32'h00000000
`define MPU_REGS_MPU_STATUS_RESET_MASK 32'hffffffff
`define MPU_REGS_MPU_STATUS_READ_MASK 32'hffffffff
`define MPU_REGS_MPU_STATUS_WRITE_MASK 32'h80000000

// Register type: mpu_regs::mpu_status
// Register template: mpu_regs::mpu_status
// Source filename: mpu_regs.csr, line: 46
// Field member: mpu_regs::mpu_status.accvio_clear
// Source filename: mpu_regs.csr, line: 52
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_MSB 31
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_LSB 31
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_WIDTH 1
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_RANGE 31:31
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_WRITE_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_RESET 1'b0
`define MPU_REGS_MPU_STATUS_ACCVIO_CLEAR_FIELD_MASK 32'h80000000
// Field member: mpu_regs::mpu_status.accvio_id
// Source filename: mpu_regs.csr, line: 96
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_MSB 30
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_LSB 27
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_WIDTH 4
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_RANGE 30:27
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_WRITE_ACCESS 0
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_RESET 4'h0
`define MPU_REGS_MPU_STATUS_ACCVIO_ID_FIELD_MASK 32'h78000000
// Field member: mpu_regs::mpu_status.accvio_ex
// Source filename: mpu_regs.csr, line: 87
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_MSB 26
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_LSB 26
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_WIDTH 1
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_RANGE 26:26
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_WRITE_ACCESS 0
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_RESET 1'h0
`define MPU_REGS_MPU_STATUS_ACCVIO_EX_FIELD_MASK 32'h04000000
// Field member: mpu_regs::mpu_status.accvio_wr
// Source filename: mpu_regs.csr, line: 78
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_MSB 25
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_LSB 25
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_WIDTH 1
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_RANGE 25:25
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_WRITE_ACCESS 0
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_RESET 1'h0
`define MPU_REGS_MPU_STATUS_ACCVIO_WR_FIELD_MASK 32'h02000000
// Field member: mpu_regs::mpu_status.accvio_rd
// Source filename: mpu_regs.csr, line: 69
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_MSB 24
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_LSB 24
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_WIDTH 1
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_RANGE 24:24
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_WRITE_ACCESS 0
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_RESET 1'h0
`define MPU_REGS_MPU_STATUS_ACCVIO_RD_FIELD_MASK 32'h01000000
// Field member: mpu_regs::mpu_status.accvio_addr
// Source filename: mpu_regs.csr, line: 60
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_MSB 23
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_LSB 0
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_WIDTH 24
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_RANGE 23:0
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_READ_ACCESS 1
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_WRITE_ACCESS 0
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_RESET 24'h000000
`define MPU_REGS_MPU_STATUS_ACCVIO_ADDR_FIELD_MASK 32'h00ffffff

`endif
