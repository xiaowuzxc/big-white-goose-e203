 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  This module to implement the regular ALU instructions
//
//
// ====================================================================
`include "e203_defines.v"

module e203_exu_alu_rglr(

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The Handshake Interface 
  //
  input  alu_i_valid, // Handshake valid
  output alu_i_ready, // Handshake ready

  input  [`E203_XLEN-1:0] alu_i_rs1,
  input  [`E203_XLEN-1:0] alu_i_rs2,
  input  [`E203_XLEN-1:0] alu_i_imm,
  input  [`E203_PC_SIZE-1:0] alu_i_pc,
  input  [`E203_DECINFO_ALU_WIDTH-1:0] alu_i_info,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ALU Write-back/Commit Interface
  output alu_o_valid, // Handshake valid
  input  alu_o_ready, // Handshake ready
  //   The Write-Back Interface for Special (unaligned ldst and AMO instructions) 
  output [`E203_XLEN-1:0] alu_o_wbck_wdat,
  output alu_o_wbck_err,   
  output alu_o_cmt_ecall,   
  output alu_o_cmt_ebreak,   
  output alu_o_cmt_wfi,   


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // To share the ALU datapath
  // 
  // The operands and info to ALU
  output alu_req_alu_add ,
  output alu_req_alu_sub ,
  output alu_req_alu_xor ,
  output alu_req_alu_sll ,
  output alu_req_alu_srl ,
  output alu_req_alu_sra ,
  output alu_req_alu_or  ,
  output alu_req_alu_and ,
  output alu_req_alu_slt ,
  output alu_req_alu_sltu,
  output alu_req_alu_lui ,
  output [`E203_XLEN-1:0] alu_req_alu_op1,
  output [`E203_XLEN-1:0] alu_req_alu_op2,
  output alu_req_alu_sh1add,/*rtl change*/
  output alu_req_alu_sh2add,/*rtl change*/
  output alu_req_alu_sh3add,/*rtl change*/
  output alu_req_alu_andn  ,/*rtl change*/
  output alu_req_alu_orn   ,/*rtl change*/
  output alu_req_alu_xnor  ,/*rtl change*/
  output alu_req_alu_clz   ,/*rtl change*/
  output alu_req_alu_ctz   ,/*rtl change*/
  output alu_req_alu_cpop  ,/*rtl change*/
  output alu_req_alu_bmax  ,/*rtl change*/
  output alu_req_alu_bmaxu ,/*rtl change*/
  output alu_req_alu_bmin  ,/*rtl change*/
  output alu_req_alu_bminu ,/*rtl change*/
  output alu_req_alu_sextb ,/*rtl change*/
  output alu_req_alu_sexth ,/*rtl change*/
  output alu_req_alu_zexth ,/*rtl change*/
  output alu_req_alu_rol   ,/*rtl change*/
  output alu_req_alu_ror   ,/*rtl change*/
  output alu_req_alu_orcb  ,/*rtl change*/
  output alu_req_alu_rev8  ,/*rtl change*/
  output alu_req_alu_clmul ,/*rtl change*/
  output alu_req_alu_clmulh,/*rtl change*/
  output alu_req_alu_clmulr,/*rtl change*/
  output alu_req_alu_bclr  ,/*rtl change*/
  output alu_req_alu_bext  ,/*rtl change*/
  output alu_req_alu_binv  ,/*rtl change*/
  output alu_req_alu_bset  ,/*rtl change*/
  output alu_req_alu_mul   ,/*rtl change*/
  output alu_req_alu_mulh  ,/*rtl change*/
  output alu_req_alu_mulhsu,/*rtl change*/
  output alu_req_alu_mulhu ,/*rtl change*/

  input  [`E203_XLEN-1:0] alu_req_alu_res,

  input  clk,
  input  rst_n
  );

  wire op2imm  = alu_i_info [`E203_DECINFO_ALU_OP2IMM ];
  wire op1pc   = alu_i_info [`E203_DECINFO_ALU_OP1PC  ];

  assign alu_req_alu_op1  = op1pc  ? alu_i_pc  : alu_i_rs1;
  assign alu_req_alu_op2  = op2imm ? alu_i_imm : alu_i_rs2;

  wire nop    = alu_i_info [`E203_DECINFO_ALU_NOP ] ;
  wire ecall  = alu_i_info [`E203_DECINFO_ALU_ECAL ];
  wire ebreak = alu_i_info [`E203_DECINFO_ALU_EBRK ];
  wire wfi    = alu_i_info [`E203_DECINFO_ALU_WFI ];

     // The NOP is encoded as ADDI, so need to uncheck it
  assign alu_req_alu_add  = alu_i_info [`E203_DECINFO_ALU_ADD ] & (~nop);
  assign alu_req_alu_sub  = alu_i_info [`E203_DECINFO_ALU_SUB ];
  assign alu_req_alu_xor  = alu_i_info [`E203_DECINFO_ALU_XOR ];
  assign alu_req_alu_sll  = alu_i_info [`E203_DECINFO_ALU_SLL ];
  assign alu_req_alu_srl  = alu_i_info [`E203_DECINFO_ALU_SRL ];
  assign alu_req_alu_sra  = alu_i_info [`E203_DECINFO_ALU_SRA ];
  assign alu_req_alu_or   = alu_i_info [`E203_DECINFO_ALU_OR  ];
  assign alu_req_alu_and  = alu_i_info [`E203_DECINFO_ALU_AND ];
  assign alu_req_alu_slt  = alu_i_info [`E203_DECINFO_ALU_SLT ];
  assign alu_req_alu_sltu = alu_i_info [`E203_DECINFO_ALU_SLTU];
  assign alu_req_alu_lui  = alu_i_info [`E203_DECINFO_ALU_LUI ];
/*rtl change*/
  assign alu_req_alu_sh1add  = alu_i_info [`E203_DECINFO_ALU_SH1ADD];
  assign alu_req_alu_sh2add  = alu_i_info [`E203_DECINFO_ALU_SH2ADD];
  assign alu_req_alu_sh3add  = alu_i_info [`E203_DECINFO_ALU_SH3ADD];
  assign alu_req_alu_andn    = alu_i_info [`E203_DECINFO_ALU_ANDN  ];
  assign alu_req_alu_orn     = alu_i_info [`E203_DECINFO_ALU_ORN   ];
  assign alu_req_alu_xnor    = alu_i_info [`E203_DECINFO_ALU_XNOR  ];
  assign alu_req_alu_clz     = alu_i_info [`E203_DECINFO_ALU_CLZ   ];
  assign alu_req_alu_ctz     = alu_i_info [`E203_DECINFO_ALU_CTZ   ];
  assign alu_req_alu_cpop    = alu_i_info [`E203_DECINFO_ALU_CPOP  ];
  assign alu_req_alu_bmax    = alu_i_info [`E203_DECINFO_ALU_MAX   ];
  assign alu_req_alu_bmaxu   = alu_i_info [`E203_DECINFO_ALU_MAXU  ];
  assign alu_req_alu_bmin    = alu_i_info [`E203_DECINFO_ALU_MIN   ];
  assign alu_req_alu_bminu   = alu_i_info [`E203_DECINFO_ALU_MINU  ];
  assign alu_req_alu_sextb   = alu_i_info [`E203_DECINFO_ALU_SEXTB ];
  assign alu_req_alu_sexth   = alu_i_info [`E203_DECINFO_ALU_SEXTH ];
  assign alu_req_alu_zexth   = alu_i_info [`E203_DECINFO_ALU_ZEXTH ];
  assign alu_req_alu_rol     = alu_i_info [`E203_DECINFO_ALU_ROL   ];
  assign alu_req_alu_ror     = alu_i_info [`E203_DECINFO_ALU_ROR   ];
  assign alu_req_alu_orcb    = alu_i_info [`E203_DECINFO_ALU_ORCB  ];
  assign alu_req_alu_rev8    = alu_i_info [`E203_DECINFO_ALU_REV8  ];
  assign alu_req_alu_clmul   = alu_i_info [`E203_DECINFO_ALU_CLMUL ];
  assign alu_req_alu_clmulh  = alu_i_info [`E203_DECINFO_ALU_CLMULH];
  assign alu_req_alu_clmulr  = alu_i_info [`E203_DECINFO_ALU_CLMULR];
  assign alu_req_alu_bclr  = alu_i_info [`E203_DECINFO_ALU_BCLR ];
  assign alu_req_alu_bext  = alu_i_info [`E203_DECINFO_ALU_BEXT ];
  assign alu_req_alu_binv  = alu_i_info [`E203_DECINFO_ALU_BINV ];
  assign alu_req_alu_bset  = alu_i_info [`E203_DECINFO_ALU_BSET ];
  assign alu_req_alu_mul   = alu_i_info [`E203_DECINFO_ALU_MUL   ];
  assign alu_req_alu_mulh  = alu_i_info [`E203_DECINFO_ALU_MULH  ];
  assign alu_req_alu_mulhsu= alu_i_info [`E203_DECINFO_ALU_MULHSU];
  assign alu_req_alu_mulhu = alu_i_info [`E203_DECINFO_ALU_MULHU ];
/*rtl change*/
  assign alu_o_valid = alu_i_valid;
  assign alu_i_ready = alu_o_ready;
  assign alu_o_wbck_wdat = alu_req_alu_res;

  assign alu_o_cmt_ecall  = ecall;   
  assign alu_o_cmt_ebreak = ebreak;   
  assign alu_o_cmt_wfi = wfi;   
  
  // The exception or error result cannot write-back
  assign alu_o_wbck_err = alu_o_cmt_ecall | alu_o_cmt_ebreak | alu_o_cmt_wfi;

endmodule
