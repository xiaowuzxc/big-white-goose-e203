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
//  This module to implement the datapath of ALU
//
// ====================================================================
`include "e203_defines.v"

module e203_exu_alu_dpath(

  //////////////////////////////////////////////////////
  // ALU request the datapath
  input  alu_req_alu,

  input  alu_req_alu_add ,
  input  alu_req_alu_sub ,
  input  alu_req_alu_xor ,
  input  alu_req_alu_sll ,
  input  alu_req_alu_srl ,
  input  alu_req_alu_sra ,
  input  alu_req_alu_or  ,
  input  alu_req_alu_and ,
  input  alu_req_alu_slt ,
  input  alu_req_alu_sltu,
  input  alu_req_alu_lui ,
  input  alu_req_alu_sh1add,/*rtl change*/
  input  alu_req_alu_sh2add,/*rtl change*/
  input  alu_req_alu_sh3add,/*rtl change*/
  input  alu_req_alu_andn  ,/*rtl change*/
  input  alu_req_alu_orn   ,/*rtl change*/
  input  alu_req_alu_xnor  ,/*rtl change*/
  input  alu_req_alu_clz   ,/*rtl change*/
  input  alu_req_alu_ctz   ,/*rtl change*/
  input  alu_req_alu_cpop  ,/*rtl change*/
  input  alu_req_alu_bmax  ,/*rtl change*/
  input  alu_req_alu_bmaxu ,/*rtl change*/
  input  alu_req_alu_bmin  ,/*rtl change*/
  input  alu_req_alu_bminu ,/*rtl change*/
  input  alu_req_alu_sextb ,/*rtl change*/
  input  alu_req_alu_sexth ,/*rtl change*/
  input  alu_req_alu_zexth ,/*rtl change*/
  input  alu_req_alu_rol   ,/*rtl change*/
  input  alu_req_alu_ror   ,/*rtl change*/
  input  alu_req_alu_orcb  ,/*rtl change*/
  input  alu_req_alu_rev8  ,/*rtl change*/
  input  alu_req_alu_clmul ,/*rtl change*/
  input  alu_req_alu_clmulh,/*rtl change*/
  input  alu_req_alu_clmulr,/*rtl change*/
  input  alu_req_alu_bclr,/*rtl change*/
  input  alu_req_alu_bext,/*rtl change*/
  input  alu_req_alu_binv,/*rtl change*/
  input  alu_req_alu_bset,/*rtl change*/
  input  alu_req_alu_mul   ,/*rtl change*/
  input  alu_req_alu_mulh  ,/*rtl change*/
  input  alu_req_alu_mulhsu,/*rtl change*/
  input  alu_req_alu_mulhu ,/*rtl change*/
  input  [`E203_XLEN-1:0] alu_req_alu_op1,
  input  [`E203_XLEN-1:0] alu_req_alu_op2,

  output [`E203_XLEN-1:0] alu_req_alu_res,

  //////////////////////////////////////////////////////
  // BJP request the datapath
  input  bjp_req_alu,

  input  [`E203_XLEN-1:0] bjp_req_alu_op1,
  input  [`E203_XLEN-1:0] bjp_req_alu_op2,
  input  bjp_req_alu_cmp_eq ,
  input  bjp_req_alu_cmp_ne ,
  input  bjp_req_alu_cmp_lt ,
  input  bjp_req_alu_cmp_gt ,
  input  bjp_req_alu_cmp_ltu,
  input  bjp_req_alu_cmp_gtu,
  input  bjp_req_alu_add,

  output bjp_req_alu_cmp_res,
  output [`E203_XLEN-1:0] bjp_req_alu_add_res,

  //////////////////////////////////////////////////////
  // AGU request the datapath
  input  agu_req_alu,

  input  [`E203_XLEN-1:0] agu_req_alu_op1,
  input  [`E203_XLEN-1:0] agu_req_alu_op2,
  input  agu_req_alu_swap,
  input  agu_req_alu_add ,
  input  agu_req_alu_and ,
  input  agu_req_alu_or  ,
  input  agu_req_alu_xor ,
  input  agu_req_alu_max ,
  input  agu_req_alu_min ,
  input  agu_req_alu_maxu,
  input  agu_req_alu_minu,

  output [`E203_XLEN-1:0] agu_req_alu_res,

  input  agu_sbf_0_ena,
  input  [`E203_XLEN-1:0] agu_sbf_0_nxt,
  output [`E203_XLEN-1:0] agu_sbf_0_r,

  input  agu_sbf_1_ena,
  input  [`E203_XLEN-1:0] agu_sbf_1_nxt,
  output [`E203_XLEN-1:0] agu_sbf_1_r,

`ifdef E203_SUPPORT_SHARE_MULDIV //{
  //////////////////////////////////////////////////////
  // MULDIV request the datapath
  input  muldiv_req_alu,

  input  [`E203_ALU_ADDER_WIDTH-1:0] muldiv_req_alu_op1,
  input  [`E203_ALU_ADDER_WIDTH-1:0] muldiv_req_alu_op2,
  input                              muldiv_req_alu_add,
  input                              muldiv_req_alu_sub,
  output [`E203_ALU_ADDER_WIDTH-1:0] muldiv_req_alu_res,

  input           muldiv_sbf_0_ena,
  input  [33-1:0] muldiv_sbf_0_nxt,
  output [33-1:0] muldiv_sbf_0_r,

  input           muldiv_sbf_1_ena,
  input  [33-1:0] muldiv_sbf_1_nxt,
  output [33-1:0] muldiv_sbf_1_r,
`endif//E203_SUPPORT_SHARE_MULDIV}

  input  clk,
  input  rst_n
  );

  `ifdef E203_XLEN_IS_32
      // This is the correct config since E200 is 32bits core
  `else
      !!! ERROR: There must be something wrong, our core must be 32bits wide !!!
  `endif

  wire [`E203_XLEN-1:0] mux_op1;
  wire [`E203_XLEN-1:0] mux_op2;

  wire [`E203_XLEN-1:0] misc_op1 = mux_op1[`E203_XLEN-1:0];
  wire [`E203_XLEN-1:0] misc_op2 = mux_op2[`E203_XLEN-1:0];

  // Only the regular ALU use shifter
  wire [`E203_XLEN-1:0] shifter_op1 = alu_req_alu_op1[`E203_XLEN-1:0];
  wire [`E203_XLEN-1:0] shifter_op2 = alu_req_alu_op2[`E203_XLEN-1:0];

  wire op_max;  
  wire op_min ; 
  wire op_maxu;
  wire op_minu;

  wire op_add;
  wire op_sub;
  wire op_addsub = op_add | op_sub; 

  wire op_or;
  wire op_xor;
  wire op_and;

  wire op_sll;
  wire op_srl;
  wire op_sra;

  wire op_slt;
  wire op_sltu;

  wire op_mvop2;

  wire op_sh1add;/*rtl change*/
  wire op_sh2add;/*rtl change*/
  wire op_sh3add;/*rtl change*/
  wire op_andn  ;/*rtl change*/
  wire op_orn   ;/*rtl change*/
  wire op_xnor  ;/*rtl change*/
  wire op_clz   ;/*rtl change*/
  wire op_ctz   ;/*rtl change*/
  wire op_cpop  ;/*rtl change*/
  wire op_bmax  ;/*rtl change*/
  wire op_bmaxu ;/*rtl change*/
  wire op_bmin  ;/*rtl change*/
  wire op_bminu ;/*rtl change*/
  wire op_sextb ;/*rtl change*/
  wire op_sexth ;/*rtl change*/
  wire op_zexth ;/*rtl change*/
  wire op_rol   ;/*rtl change*/
  wire op_ror   ;/*rtl change*/
  wire op_orcb  ;/*rtl change*/
  wire op_rev8  ;/*rtl change*/
  wire op_clmul ;/*rtl change*/
  wire op_clmulh;/*rtl change*/
  wire op_clmulr;/*rtl change*/
  wire op_bclr;/*rtl change*/
  wire op_bext;/*rtl change*/
  wire op_binv;/*rtl change*/
  wire op_bset;/*rtl change*/
  wire op_mul   ;/*rtl change*/
  wire op_mulh  ;/*rtl change*/
  wire op_mulhsu;/*rtl change*/
  wire op_mulhu ;/*rtl change*/

  wire op_cmp_eq ;
  wire op_cmp_ne ;
  wire op_cmp_lt ;
  wire op_cmp_gt ;
  wire op_cmp_ltu;
  wire op_cmp_gtu;

  wire cmp_res;

  wire sbf_0_ena;
  wire [33-1:0] sbf_0_nxt;
  wire [33-1:0] sbf_0_r;

  wire sbf_1_ena;
  wire [33-1:0] sbf_1_nxt;
  wire [33-1:0] sbf_1_r;


  //////////////////////////////////////////////////////////////
  // Impelment the Left-Shifter
  //
  // The Left-Shifter will be used to handle the shift op
  wire [`E203_XLEN-1:0] shifter_in1;
  wire [5-1:0] shifter_in2;
  wire [`E203_XLEN-1:0] shifter_res;


  wire op_shift = op_sra | op_sll | op_srl; 
  
     // Make sure to use logic-gating to gateoff the 
  assign shifter_in1 = {`E203_XLEN{op_shift}} &
          //   In order to save area and just use one left-shifter, we
          //   convert the right-shift op into left-shift operation
           (
               (op_sra | op_srl) ? 
                 {
    shifter_op1[00],shifter_op1[01],shifter_op1[02],shifter_op1[03],
    shifter_op1[04],shifter_op1[05],shifter_op1[06],shifter_op1[07],
    shifter_op1[08],shifter_op1[09],shifter_op1[10],shifter_op1[11],
    shifter_op1[12],shifter_op1[13],shifter_op1[14],shifter_op1[15],
    shifter_op1[16],shifter_op1[17],shifter_op1[18],shifter_op1[19],
    shifter_op1[20],shifter_op1[21],shifter_op1[22],shifter_op1[23],
    shifter_op1[24],shifter_op1[25],shifter_op1[26],shifter_op1[27],
    shifter_op1[28],shifter_op1[29],shifter_op1[30],shifter_op1[31]
                 } : shifter_op1
           );
  assign shifter_in2 = {5{op_shift}} & shifter_op2[4:0];

  assign shifter_res = (shifter_in1 << shifter_in2);

  wire [`E203_XLEN-1:0] sll_res = shifter_res;
  wire [`E203_XLEN-1:0] srl_res =  
                 {
    shifter_res[00],shifter_res[01],shifter_res[02],shifter_res[03],
    shifter_res[04],shifter_res[05],shifter_res[06],shifter_res[07],
    shifter_res[08],shifter_res[09],shifter_res[10],shifter_res[11],
    shifter_res[12],shifter_res[13],shifter_res[14],shifter_res[15],
    shifter_res[16],shifter_res[17],shifter_res[18],shifter_res[19],
    shifter_res[20],shifter_res[21],shifter_res[22],shifter_res[23],
    shifter_res[24],shifter_res[25],shifter_res[26],shifter_res[27],
    shifter_res[28],shifter_res[29],shifter_res[30],shifter_res[31]
                 };
  
  wire [`E203_XLEN-1:0] eff_mask = (~(`E203_XLEN'b0)) >> shifter_in2;
  wire [`E203_XLEN-1:0] sra_res =
               (srl_res & eff_mask) | ({32{shifter_op1[31]}} & (~eff_mask));



  //////////////////////////////////////////////////////////////
  // Impelment the Adder
  //
  // The Adder will be reused to handle the add/sub/compare op

     // Only the MULDIV request ALU-adder with 35bits operand with sign extended 
     // already, all other unit request ALU-adder with 32bits opereand without sign extended
     //   For non-MULDIV operands
  wire op_unsigned = op_sltu | op_cmp_ltu | op_cmp_gtu | op_maxu | op_minu;
  wire [`E203_ALU_ADDER_WIDTH-1:0] misc_adder_op1 =
      {{`E203_ALU_ADDER_WIDTH-`E203_XLEN{(~op_unsigned) & misc_op1[`E203_XLEN-1]}},misc_op1};
  wire [`E203_ALU_ADDER_WIDTH-1:0] misc_adder_op2 =
      {{`E203_ALU_ADDER_WIDTH-`E203_XLEN{(~op_unsigned) & misc_op2[`E203_XLEN-1]}},misc_op2};


  wire [`E203_ALU_ADDER_WIDTH-1:0] adder_op1 = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_req_alu_op1 :
`endif//E203_SUPPORT_SHARE_MULDIV}
      misc_adder_op1;
  wire [`E203_ALU_ADDER_WIDTH-1:0] adder_op2 = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_req_alu_op2 :
`endif//E203_SUPPORT_SHARE_MULDIV}
      misc_adder_op2;

  wire adder_cin;
  wire [`E203_ALU_ADDER_WIDTH-1:0] adder_in1;
  wire [`E203_ALU_ADDER_WIDTH-1:0] adder_in2;
  wire [`E203_ALU_ADDER_WIDTH-1:0] adder_res;

  wire adder_add;
  wire adder_sub;

  assign adder_add =
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_req_alu_add :
`endif//E203_SUPPORT_SHARE_MULDIV}
      op_add; 
  assign adder_sub =
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_req_alu_sub :
`endif//E203_SUPPORT_SHARE_MULDIV}
               (
                   // The original sub instruction
               (op_sub) 
                   // The compare lt or gt instruction
             | (op_cmp_lt | op_cmp_gt | 
                op_cmp_ltu | op_cmp_gtu |
                op_max | op_maxu |
                op_min | op_minu |
                op_slt | op_sltu 
               ));

  wire adder_addsub = adder_add | adder_sub; 
  

     // Make sure to use logic-gating to gateoff the 
  assign adder_in1 = {`E203_ALU_ADDER_WIDTH{adder_addsub}} & (adder_op1);
  assign adder_in2 = {`E203_ALU_ADDER_WIDTH{adder_addsub}} & (adder_sub ? (~adder_op2) : adder_op2);
  assign adder_cin = adder_addsub & adder_sub;

  assign adder_res = adder_in1 + adder_in2 + adder_cin;



  //////////////////////////////////////////////////////////////
  // Impelment the XOR-er
  //
  // The XOR-er will be reused to handle the XOR and compare op

  wire [`E203_XLEN-1:0] xorer_in1;
  wire [`E203_XLEN-1:0] xorer_in2;

  wire xorer_op = 
               op_xor
                   // The compare eq or ne instruction
             | (op_cmp_eq | op_cmp_ne); 

     // Make sure to use logic-gating to gateoff the 
  assign xorer_in1 = {`E203_XLEN{xorer_op}} & misc_op1;
  assign xorer_in2 = {`E203_XLEN{xorer_op}} & misc_op2;

  wire [`E203_XLEN-1:0] xorer_res = xorer_in1 ^ xorer_in2;
     // The OR and AND is too light-weight, so no need to gate off
  wire [`E203_XLEN-1:0] orer_res  = misc_op1 | misc_op2; 
  wire [`E203_XLEN-1:0] ander_res = misc_op1 & misc_op2; 



/*rtl change*/
//-----------------------B ext + MUL-------------------------
//-----------------------B ext + MUL-------------------------
//-----------------------B ext + MUL-------------------------
//////////////////////////////////////////////////////////////
// Impelment the Zba
wire [`E203_XLEN-1:0] sh1adder_in1;
wire [`E203_XLEN-1:0] sh1adder_in2;
wire [`E203_XLEN-1:0] sh2adder_in1;
wire [`E203_XLEN-1:0] sh2adder_in2;
wire [`E203_XLEN-1:0] sh3adder_in1;
wire [`E203_XLEN-1:0] sh3adder_in2;
wire [`E203_XLEN-1:0] andner_in1;
wire [`E203_XLEN-1:0] andner_in2;
wire [`E203_XLEN-1:0] orner_in1;
wire [`E203_XLEN-1:0] orner_in2;
wire [`E203_XLEN-1:0] xnorer_in1;
wire [`E203_XLEN-1:0] xnorer_in2;
wire [`E203_XLEN-1:0] clzer_in1;
wire [`E203_XLEN-1:0] clzer_in2;
wire [`E203_XLEN-1:0] ctzer_in1;
wire [`E203_XLEN-1:0] ctzer_in2;
wire [`E203_XLEN-1:0] cpoper_in1;
wire [`E203_XLEN-1:0] cpoper_in2;
wire [`E203_XLEN-1:0] bmaxer_in1;
wire [`E203_XLEN-1:0] bmaxer_in2;
wire signed[`E203_XLEN-1:0] bmaxuer_in1;
wire signed[`E203_XLEN-1:0] bmaxuer_in2;
wire [`E203_XLEN-1:0] bminer_in1;
wire [`E203_XLEN-1:0] bminer_in2;
wire signed[`E203_XLEN-1:0] bminuer_in1;
wire signed[`E203_XLEN-1:0] bminuer_in2;
wire [`E203_XLEN-1:0] sextber_in1;
wire [`E203_XLEN-1:0] sextber_in2;
wire [`E203_XLEN-1:0] sexther_in1;
wire [`E203_XLEN-1:0] sexther_in2;
wire [`E203_XLEN-1:0] zexther_in1;
wire [`E203_XLEN-1:0] zexther_in2;
wire [`E203_XLEN-1:0] roler_in1;
wire [`E203_XLEN-1:0] roler_in2;
wire [`E203_XLEN-1:0] rorer_in1;
wire [`E203_XLEN-1:0] rorer_in2;
wire [`E203_XLEN-1:0] orcber_in1;
wire [`E203_XLEN-1:0] orcber_in2;
wire [`E203_XLEN-1:0] rev8er_in1;
wire [`E203_XLEN-1:0] rev8er_in2;
wire [`E203_XLEN-1:0] clmuler_in1;
wire [`E203_XLEN-1:0] clmuler_in2;
wire [`E203_XLEN-1:0] bclrer_in1;
wire [`E203_XLEN-1:0] bclrer_in2;
wire [`E203_XLEN-1:0] bexter_in1;
wire [`E203_XLEN-1:0] bexter_in2;
wire [`E203_XLEN-1:0] binver_in1;
wire [`E203_XLEN-1:0] binver_in2;
wire [`E203_XLEN-1:0] bseter_in1;
wire [`E203_XLEN-1:0] bseter_in2;
wire signed[`E203_XLEN-1+1:0] muler_in1;
wire signed[`E203_XLEN-1+1:0] muler_in2;


wire sh1adder_op = op_sh1add | (op_cmp_eq | op_cmp_ne);
wire sh2adder_op = op_sh2add | (op_cmp_eq | op_cmp_ne);
wire sh3adder_op = op_sh3add | (op_cmp_eq | op_cmp_ne);
wire andner_op = op_andn | (op_cmp_eq | op_cmp_ne);
wire orner_op = op_orn | (op_cmp_eq | op_cmp_ne);
wire xnorer_op = op_xnor | (op_cmp_eq | op_cmp_ne);
wire clzer_op = op_clz | (op_cmp_eq | op_cmp_ne);
wire ctzer_op = op_ctz | (op_cmp_eq | op_cmp_ne);
wire cpoper_op = op_cpop | (op_cmp_eq | op_cmp_ne);
wire bmaxer_op = op_bmax | (op_cmp_eq | op_cmp_ne);
wire bmaxuer_op = op_bmaxu | (op_cmp_eq | op_cmp_ne);
wire bminer_op = op_bmin | (op_cmp_eq | op_cmp_ne);
wire bminuer_op = op_bminu | (op_cmp_eq | op_cmp_ne);
wire sextber_op = op_sextb | (op_cmp_eq | op_cmp_ne);
wire sexther_op = op_sexth | (op_cmp_eq | op_cmp_ne);
wire zexther_op = op_zexth | (op_cmp_eq | op_cmp_ne);
wire roler_op = op_rol | (op_cmp_eq | op_cmp_ne);
wire rorer_op = op_ror | (op_cmp_eq | op_cmp_ne);
wire orcber_op = op_orcb | (op_cmp_eq | op_cmp_ne);
wire rev8er_op = op_rev8 | (op_cmp_eq | op_cmp_ne);
wire clmuler_op = op_clmul | (op_cmp_eq | op_cmp_ne);
wire clmulher_op = op_clmulh | (op_cmp_eq | op_cmp_ne);
wire clmulrer_op = op_clmulr | (op_cmp_eq | op_cmp_ne);
wire bclrer_op = op_bclr | (op_cmp_eq | op_cmp_ne); 
wire bexter_op = op_bext | (op_cmp_eq | op_cmp_ne); 
wire binver_op = op_binv | (op_cmp_eq | op_cmp_ne); 
wire bseter_op = op_bset | (op_cmp_eq | op_cmp_ne); 
wire muler_op = op_mul    | (op_cmp_eq | op_cmp_ne); 
wire mulher_op = op_mulh  | (op_cmp_eq | op_cmp_ne); 
wire mulhsuer_op = op_mulhsu| (op_cmp_eq | op_cmp_ne); 
wire mulhuer_op = op_mulhu  | (op_cmp_eq | op_cmp_ne);

    // Make sure to use logic-gating to gateoff the 
assign sh1adder_in1 = {`E203_XLEN{sh1adder_op}} & misc_op1;
assign sh1adder_in2 = {`E203_XLEN{sh1adder_op}} & misc_op2;
assign sh2adder_in1 = {`E203_XLEN{sh2adder_op}} & misc_op1;
assign sh2adder_in2 = {`E203_XLEN{sh2adder_op}} & misc_op2;
assign sh3adder_in1 = {`E203_XLEN{sh3adder_op}} & misc_op1;
assign sh3adder_in2 = {`E203_XLEN{sh3adder_op}} & misc_op2;
assign andner_in1 = {`E203_XLEN{andner_op}} & misc_op1;
assign andner_in2 = {`E203_XLEN{andner_op}} & misc_op2;
assign orner_in1 = {`E203_XLEN{orner_op}} & misc_op1;
assign orner_in2 = {`E203_XLEN{orner_op}} & misc_op2;
assign xnorer_in1 = {`E203_XLEN{xnorer_op}} & misc_op1;
assign xnorer_in2 = {`E203_XLEN{xnorer_op}} & misc_op2;
assign clzer_in1 = {`E203_XLEN{clzer_op}} & misc_op1;
assign clzer_in2 = {`E203_XLEN{clzer_op}} & misc_op2;
assign ctzer_in1 = {`E203_XLEN{ctzer_op}} & misc_op1;
assign ctzer_in2 = {`E203_XLEN{ctzer_op}} & misc_op2;
assign cpoper_in1 = {`E203_XLEN{cpoper_op}} & misc_op1;
assign cpoper_in2 = {`E203_XLEN{cpoper_op}} & misc_op2;
assign bmaxer_in1 = {`E203_XLEN{bmaxer_op}} & misc_op1;
assign bmaxer_in2 = {`E203_XLEN{bmaxer_op}} & misc_op2;
assign bmaxuer_in1 = {`E203_XLEN{bmaxuer_op}} & misc_op1;
assign bmaxuer_in2 = {`E203_XLEN{bmaxuer_op}} & misc_op2;
assign bminer_in1 = {`E203_XLEN{bminer_op}} & misc_op1;
assign bminer_in2 = {`E203_XLEN{bminer_op}} & misc_op2;
assign bminuer_in1 = {`E203_XLEN{bminuer_op}} & misc_op1;
assign bminuer_in2 = {`E203_XLEN{bminuer_op}} & misc_op2;
assign sextber_in1 = {`E203_XLEN{sextber_op}} & misc_op1;
assign sextber_in2 = {`E203_XLEN{sextber_op}} & misc_op2;
assign sexther_in1 = {`E203_XLEN{sexther_op}} & misc_op1;
assign sexther_in2 = {`E203_XLEN{sexther_op}} & misc_op2;
assign zexther_in1 = {`E203_XLEN{zexther_op}} & misc_op1;
assign zexther_in2 = {`E203_XLEN{zexther_op}} & misc_op2;
assign roler_in1 = {`E203_XLEN{roler_op}} & misc_op1;
assign roler_in2 = {`E203_XLEN{roler_op}} & misc_op2;
assign rorer_in1 = {`E203_XLEN{rorer_op}} & misc_op1;
assign rorer_in2 = {`E203_XLEN{rorer_op}} & misc_op2;
assign orcber_in1 = {`E203_XLEN{orcber_op}} & misc_op1;
assign orcber_in2 = {`E203_XLEN{orcber_op}} & misc_op2;
assign rev8er_in1 = {`E203_XLEN{rev8er_op}} & misc_op1;
assign rev8er_in2 = {`E203_XLEN{rev8er_op}} & misc_op2;
assign clmuler_in1 = {`E203_XLEN{clmuler_op|clmulher_op|clmulrer_op}} & misc_op1;
assign clmuler_in2 = {`E203_XLEN{clmuler_op|clmulher_op|clmulrer_op}} & misc_op2;
assign bclrer_in1 = {`E203_XLEN{bclrer_op}} & misc_op1;
assign bclrer_in2 = {`E203_XLEN{bclrer_op}} & misc_op2;
assign bexter_in1 = {`E203_XLEN{bexter_op}} & misc_op1;
assign bexter_in2 = {`E203_XLEN{bexter_op}} & misc_op2;
assign binver_in1 = {`E203_XLEN{binver_op}} & misc_op1;
assign binver_in2 = {`E203_XLEN{binver_op}} & misc_op2;
assign bseter_in1 = {`E203_XLEN{bseter_op}} & misc_op1;
assign bseter_in2 = {`E203_XLEN{bseter_op}} & misc_op2;

assign muler_in1 = {33{muler_op|mulher_op|mulhsuer_op}}&{misc_op1[31],misc_op1} | {33{mulhuer_op}}&{1'b0,misc_op1};
assign muler_in2 = {33{muler_op|mulher_op}}&{misc_op2[31],misc_op2} | {33{mulhuer_op|mulhsuer_op}}&{1'b0,misc_op2};

//-------------alu jie guo-------------
reg [`E203_XLEN-1:0]sh1adder_res;
reg [`E203_XLEN-1:0]sh2adder_res;
reg [`E203_XLEN-1:0]sh3adder_res;
reg [`E203_XLEN-1:0]andner_res;
reg [`E203_XLEN-1:0]orner_res;
reg [`E203_XLEN-1:0]xnorer_res;
reg [`E203_XLEN-1:0]clzer_res;
reg [`E203_XLEN-1:0]ctzer_res;
reg [`E203_XLEN-1:0]cpoper_res;
reg [`E203_XLEN-1:0]bmaxer_res;
reg [`E203_XLEN-1:0]bmaxuer_res;
reg [`E203_XLEN-1:0]bminer_res;
reg [`E203_XLEN-1:0]bminuer_res;
reg [`E203_XLEN-1:0]sextber_res;
reg [`E203_XLEN-1:0]sexther_res;
reg [`E203_XLEN-1:0]zexther_res;
reg [`E203_XLEN-1:0]roler_res;
reg [`E203_XLEN-1:0]rorer_res;
reg [`E203_XLEN-1:0]orcber_res;
reg [`E203_XLEN-1:0]rev8er_res;
reg [`E203_XLEN-1:0]clmuler_res;
reg [`E203_XLEN-1:0]clmulher_res;
reg [`E203_XLEN-1:0]clmulrer_res;
reg [`E203_XLEN-1:0]bclrer_res;
reg [`E203_XLEN-1:0]binver_res;
reg [`E203_XLEN-1:0]bseter_res;
reg [`E203_XLEN-1:0]bexter_res;
reg [`E203_XLEN-1:0]muler_res;
reg [`E203_XLEN-1:0]mulher_res;
reg [`E203_XLEN-1:0]mulhsuer_res;
reg [`E203_XLEN-1:0]mulhuer_res;
//BBBer_res <= BBBer_in1 BBBer_in2

integer i;
reg [63:0]clmuldo;
//-------------Zba-------------

always @(*) begin
sh1adder_res = sh1adder_in2 + (sh1adder_in1 << 1 );//sh1add

sh2adder_res = sh2adder_in2 + (sh2adder_in1 << 2 );//sh2add

sh3adder_res = sh3adder_in2 + (sh3adder_in1 << 3 );//sh3add

end
//BBBer_res <= BBBer_in1 BBBer_in2
//-------------Zbb-------------

always @(*) begin
andner_res = andner_in1 & (~andner_in2);//andn

orner_res = orner_in1 | (~orner_in2);//orn

xnorer_res = ~ (xnorer_in1 ^ xnorer_in2);//xnor

end


reg [4:0]  clz_out_tmp;
always @(*) begin

  if(clzer_in1[31]) clz_out_tmp = 5'd0;
	else if(clzer_in1[30]) clz_out_tmp = 5'd1;
	else if(clzer_in1[29]) clz_out_tmp = 5'd2;
	else if(clzer_in1[28]) clz_out_tmp = 5'd3;
	else if(clzer_in1[27]) clz_out_tmp = 5'd4;
	else if(clzer_in1[26]) clz_out_tmp = 5'd5;
	else if(clzer_in1[25]) clz_out_tmp = 5'd6;
	else if(clzer_in1[24]) clz_out_tmp = 5'd7;
	else if(clzer_in1[23]) clz_out_tmp = 5'd8;
	else if(clzer_in1[22]) clz_out_tmp = 5'd9;
	else if(clzer_in1[21]) clz_out_tmp = 5'd10;
	else if(clzer_in1[20]) clz_out_tmp = 5'd11;
	else if(clzer_in1[19]) clz_out_tmp = 5'd12;
	else if(clzer_in1[18]) clz_out_tmp = 5'd13;
	else if(clzer_in1[17]) clz_out_tmp = 5'd14;
	else if(clzer_in1[16]) clz_out_tmp = 5'd15;
	else if(clzer_in1[15]) clz_out_tmp = 5'd16;
	else if(clzer_in1[14]) clz_out_tmp = 5'd17;
	else if(clzer_in1[13]) clz_out_tmp = 5'd18;
	else if(clzer_in1[12]) clz_out_tmp = 5'd19;
	else if(clzer_in1[11]) clz_out_tmp = 5'd20;
	else if(clzer_in1[10]) clz_out_tmp = 5'd21;
	else if(clzer_in1[9]) clz_out_tmp = 5'd22;
	else if(clzer_in1[8]) clz_out_tmp = 5'd23;
	else if(clzer_in1[7]) clz_out_tmp = 5'd24;
	else if(clzer_in1[6]) clz_out_tmp = 5'd25;
	else if(clzer_in1[5]) clz_out_tmp = 5'd26;
	else if(clzer_in1[4]) clz_out_tmp = 5'd27;
	else if(clzer_in1[3]) clz_out_tmp = 5'd28;
	else if(clzer_in1[2]) clz_out_tmp = 5'd29;
	else if(clzer_in1[1]) clz_out_tmp = 5'd30;
	else if(clzer_in1[0]) clz_out_tmp = 5'd31;
	else			clz_out_tmp = 5'd32;

	clzer_res = {27'd0,clz_out_tmp};

end

reg [4:0]  ctz_out_tmp;
always @(*) begin

  if(ctzer_in1[0]) ctz_out_tmp = 5'd0;
	else if(ctzer_in1[1]) ctz_out_tmp = 5'd1;
	else if(ctzer_in1[2]) ctz_out_tmp = 5'd2;
	else if(ctzer_in1[3]) ctz_out_tmp = 5'd3;
	else if(ctzer_in1[4]) ctz_out_tmp = 5'd4;
	else if(ctzer_in1[5]) ctz_out_tmp = 5'd5;
	else if(ctzer_in1[6]) ctz_out_tmp = 5'd6;
	else if(ctzer_in1[7]) ctz_out_tmp = 5'd7;
	else if(ctzer_in1[8]) ctz_out_tmp = 5'd8;
	else if(ctzer_in1[9]) ctz_out_tmp = 5'd9;
	else if(ctzer_in1[10]) ctz_out_tmp = 5'd10;
	else if(ctzer_in1[11]) ctz_out_tmp = 5'd11;
	else if(ctzer_in1[12]) ctz_out_tmp = 5'd12;
	else if(ctzer_in1[13]) ctz_out_tmp = 5'd13;
	else if(ctzer_in1[14]) ctz_out_tmp = 5'd14;
	else if(ctzer_in1[15]) ctz_out_tmp = 5'd15;
	else if(ctzer_in1[16]) ctz_out_tmp = 5'd16;
	else if(ctzer_in1[17]) ctz_out_tmp = 5'd17;
	else if(ctzer_in1[18]) ctz_out_tmp = 5'd18;
	else if(ctzer_in1[19]) ctz_out_tmp = 5'd19;
	else if(ctzer_in1[20]) ctz_out_tmp = 5'd20;
	else if(ctzer_in1[21]) ctz_out_tmp = 5'd21;
	else if(ctzer_in1[22]) ctz_out_tmp = 5'd22;
	else if(ctzer_in1[23]) ctz_out_tmp = 5'd23;
	else if(ctzer_in1[24]) ctz_out_tmp = 5'd24;
	else if(ctzer_in1[25]) ctz_out_tmp = 5'd25;
	else if(ctzer_in1[26]) ctz_out_tmp = 5'd26;
	else if(ctzer_in1[27]) ctz_out_tmp = 5'd27;
	else if(ctzer_in1[28]) ctz_out_tmp = 5'd28;
	else if(ctzer_in1[29]) ctz_out_tmp = 5'd29;
	else if(ctzer_in1[30]) ctz_out_tmp = 5'd30;
	else if(ctzer_in1[31]) ctz_out_tmp = 5'd31;
	else			ctz_out_tmp = 5'd32;
  
	ctzer_res = {27'd0,ctz_out_tmp};

end
/*

always @(*) begin
clzer_res=32'h0;//clz

for(i=0;(i<`E203_XLEN)&(~clzer_in1[`E203_XLEN-i]);i=i+1) begin
  clzer_res = clzer_res+1;
end

ctzer_res=32'h0;//ctz

for(i=0;(i<`E203_XLEN)&(~ctzer_in1[`E203_XLEN-i]);i=i+1) begin
  ctzer_res = ctzer_res+1;
end

end
*/
always @(*) begin
cpoper_res=32'h0;//cpop
for(i=0;i<`E203_XLEN;i=i+1) begin
  if(cpoper_in1[i]) 
    cpoper_res=cpoper_res+1;
end

if(bmaxer_in1>bmaxer_in2)//max
  bmaxer_res=bmaxer_in1;
else
  bmaxer_res=bmaxer_in2;

if(bmaxuer_in1>bmaxuer_in2)//maxu
  bmaxuer_res=bmaxuer_in1;
else
  bmaxuer_res=bmaxuer_in2;

if(bminer_in1<bminer_in2)//min
  bminer_res=bminer_in1;
else
  bminer_res=bminer_in2;

if(bminuer_in1<bminuer_in2)//minu
  bminuer_res=bminuer_in1;
else
  bminuer_res=bminuer_in2;

sextber_res={{25{sextber_in1[7]}},sextber_in1[6:0]};//sextb

sexther_res={{17{sexther_in1[15]}},sexther_in1[14:0]};//sexth

zexther_res={16'h0,zexther_in1[15:0]};//zexth

case (roler_in2[4:0])//rol
  5'd0:roler_res=roler_in1;
  5'd1:roler_res={roler_in1[31-1:0],roler_in1[31:31-0]};
  5'd2:roler_res={roler_in1[31-2:0],roler_in1[31:31-1]};
  5'd3:roler_res={roler_in1[31-3:0],roler_in1[31:31-2]};
  5'd4:roler_res={roler_in1[31-4:0],roler_in1[31:31-3]};
  5'd5:roler_res={roler_in1[31-5:0],roler_in1[31:31-4]};
  5'd6:roler_res={roler_in1[31-6:0],roler_in1[31:31-5]};
  5'd7:roler_res={roler_in1[31-7:0],roler_in1[31:31-6]};
  5'd8:roler_res={roler_in1[31-8:0],roler_in1[31:31-7]};
  5'd9:roler_res={roler_in1[31-9:0],roler_in1[31:31-8]};
  5'd10:roler_res={roler_in1[31-10:0],roler_in1[31:31-9]};
  5'd11:roler_res={roler_in1[31-11:0],roler_in1[31:31-10]};
  5'd12:roler_res={roler_in1[31-12:0],roler_in1[31:31-11]};
  5'd13:roler_res={roler_in1[31-13:0],roler_in1[31:31-12]};
  5'd14:roler_res={roler_in1[31-14:0],roler_in1[31:31-13]};
  5'd15:roler_res={roler_in1[31-15:0],roler_in1[31:31-14]};
  5'd16:roler_res={roler_in1[31-16:0],roler_in1[31:31-15]};
  5'd17:roler_res={roler_in1[31-17:0],roler_in1[31:31-16]};
  5'd18:roler_res={roler_in1[31-18:0],roler_in1[31:31-17]};
  5'd19:roler_res={roler_in1[31-19:0],roler_in1[31:31-18]};
  5'd20:roler_res={roler_in1[31-20:0],roler_in1[31:31-19]};
  5'd21:roler_res={roler_in1[31-21:0],roler_in1[31:31-20]};
  5'd22:roler_res={roler_in1[31-22:0],roler_in1[31:31-21]};
  5'd23:roler_res={roler_in1[31-23:0],roler_in1[31:31-22]};
  5'd24:roler_res={roler_in1[31-24:0],roler_in1[31:31-23]};
  5'd25:roler_res={roler_in1[31-25:0],roler_in1[31:31-24]};
  5'd26:roler_res={roler_in1[31-26:0],roler_in1[31:31-25]};
  5'd27:roler_res={roler_in1[31-27:0],roler_in1[31:31-26]};
  5'd28:roler_res={roler_in1[31-28:0],roler_in1[31:31-27]};
  5'd29:roler_res={roler_in1[31-29:0],roler_in1[31:31-28]};
  5'd30:roler_res={roler_in1[31-30:0],roler_in1[31:31-29]};
  5'd31:roler_res={roler_in1[31-31:0],roler_in1[31:31-30]};
  default : roler_res=roler_in1;
endcase

case (rorer_in2[4:0])//ror
  5'd0:rorer_res=rorer_in1;
  5'd1:rorer_res={rorer_in1[0:0],rorer_in1[31:1]};
  5'd2:rorer_res={rorer_in1[1:0],rorer_in1[31:2]};
  5'd3:rorer_res={rorer_in1[2:0],rorer_in1[31:3]};
  5'd4:rorer_res={rorer_in1[3:0],rorer_in1[31:4]};
  5'd5:rorer_res={rorer_in1[4:0],rorer_in1[31:5]};
  5'd6:rorer_res={rorer_in1[5:0],rorer_in1[31:6]};
  5'd7:rorer_res={rorer_in1[6:0],rorer_in1[31:7]};
  5'd8:rorer_res={rorer_in1[7:0],rorer_in1[31:8]};
  5'd9:rorer_res={rorer_in1[8:0],rorer_in1[31:9]};
  5'd10:rorer_res={rorer_in1[9:0],rorer_in1[31:10]};
  5'd11:rorer_res={rorer_in1[10:0],rorer_in1[31:11]};
  5'd12:rorer_res={rorer_in1[11:0],rorer_in1[31:12]};
  5'd13:rorer_res={rorer_in1[12:0],rorer_in1[31:13]};
  5'd14:rorer_res={rorer_in1[13:0],rorer_in1[31:14]};
  5'd15:rorer_res={rorer_in1[14:0],rorer_in1[31:15]};
  5'd16:rorer_res={rorer_in1[15:0],rorer_in1[31:16]};
  5'd17:rorer_res={rorer_in1[16:0],rorer_in1[31:17]};
  5'd18:rorer_res={rorer_in1[17:0],rorer_in1[31:18]};
  5'd19:rorer_res={rorer_in1[18:0],rorer_in1[31:19]};
  5'd20:rorer_res={rorer_in1[19:0],rorer_in1[31:20]};
  5'd21:rorer_res={rorer_in1[20:0],rorer_in1[31:21]};
  5'd22:rorer_res={rorer_in1[21:0],rorer_in1[31:22]};
  5'd23:rorer_res={rorer_in1[22:0],rorer_in1[31:23]};
  5'd24:rorer_res={rorer_in1[23:0],rorer_in1[31:24]};
  5'd25:rorer_res={rorer_in1[24:0],rorer_in1[31:25]};
  5'd26:rorer_res={rorer_in1[25:0],rorer_in1[31:26]};
  5'd27:rorer_res={rorer_in1[26:0],rorer_in1[31:27]};
  5'd28:rorer_res={rorer_in1[27:0],rorer_in1[31:28]};
  5'd29:rorer_res={rorer_in1[28:0],rorer_in1[31:29]};
  5'd30:rorer_res={rorer_in1[29:0],rorer_in1[31:30]};
  5'd31:rorer_res={rorer_in1[30:0],rorer_in1[31:31]};
  default : rorer_res=rorer_in1;
endcase


orcber_res = {{8{|orcber_in1[31:24]}},{8{|orcber_in1[23:16]}},{8{|orcber_in1[15:8]}},{8{|orcber_in1[7:0]}}};

rev8er_res={rev8er_in1[7:0],rev8er_in1[15:8],rev8er_in1[23:16],rev8er_in1[31:24]};//rev8

end

//BBBer_res <= BBBer_in1 BBBer_in2
//-------------Zbc-------------
always @(*) begin
clmuldo=64'h0;
for(i=0;i<32;i=i+1) begin
  if(clmuler_in2[i])//==1
    clmuldo=clmuldo^(clmuler_in1<<i);
end
clmuler_res=clmuldo[31:0];
clmulher_res=clmuldo[63:32];
clmulrer_res=clmuldo[62:31];
end
//BBBer_res <= BBBer_in1 BBBer_in2
//-------------Zbs-------------

always @(*) begin
bexter_res = bexter_in1[bexter_in2[4:0]];
for(i=0;i<`E203_XLEN;i=i+1) begin 
  bclrer_res[i] = (i==bclrer_in2[4:0])?1'b0:bclrer_in1[i];
  binver_res[i] = (i==binver_in2[4:0])?~binver_in1[i]:binver_in1[i];
  bseter_res[i] = (i==bseter_in2[4:0])?1'b1:bseter_in1[i];
  end
end
//-------------Zbs-------------
/*
wire signed[32:0] muler_in1;
wire signed[32:0] muler_in2;

reg [`E203_XLEN-1:0]muler_res;
reg [`E203_XLEN-1:0]mulher_res;
reg [`E203_XLEN-1:0]mulhsuer_res;
reg [`E203_XLEN-1:0]mulhuer_res;
*/
reg signed[65:0]mul_out;

always @(*) begin
  mul_out=muler_in1*muler_in2;

  muler_res=mul_out[31:0];
  mulher_res=mul_out[63:32];
  mulhsuer_res=mul_out[63:32];
  mulhuer_res=mul_out[63:32];
end
//-------------MUL-------------


//-------------MUL-------------

//-----------------------B ext-------------------------
//-----------------------B ext-------------------------
//-----------------------B ext-------------------------
/*rtl change*/



  //////////////////////////////////////////////////////////////
  // Generate the CMP operation result
       // It is Non-Equal if the XOR result have any bit non-zero
  wire neq  = (|xorer_res); 
  wire cmp_res_ne  = (op_cmp_ne  & neq);
       // It is Equal if it is not Non-Equal
  wire cmp_res_eq  = op_cmp_eq  & (~neq);
       // It is Less-Than if the adder result is negative
  wire cmp_res_lt  = op_cmp_lt  & adder_res[`E203_XLEN];
  wire cmp_res_ltu = op_cmp_ltu & adder_res[`E203_XLEN];
       // It is Greater-Than if the adder result is postive
  wire op1_gt_op2  = (~adder_res[`E203_XLEN]);
  wire cmp_res_gt  = op_cmp_gt  & op1_gt_op2;
  wire cmp_res_gtu = op_cmp_gtu & op1_gt_op2;

  assign cmp_res = cmp_res_eq 
                 | cmp_res_ne 
                 | cmp_res_lt 
                 | cmp_res_gt  
                 | cmp_res_ltu 
                 | cmp_res_gtu; 

  //////////////////////////////////////////////////////////////
  // Generate the mvop2 result
  //   Just directly use op2 since the op2 will be the immediate
  wire [`E203_XLEN-1:0] mvop2_res = misc_op2;

  //////////////////////////////////////////////////////////////
  // Generate the SLT and SLTU result
  //   Just directly use op2 since the op2 will be the immediate
  wire op_slttu = (op_slt | op_sltu);
  //   The SLT and SLTU is reusing the adder to do the comparasion
       // It is Less-Than if the adder result is negative
  wire slttu_cmp_lt = op_slttu & adder_res[`E203_XLEN];
  wire [`E203_XLEN-1:0] slttu_res = 
               slttu_cmp_lt ?
               `E203_XLEN'b1 : `E203_XLEN'b0;


  //////////////////////////////////////////////////////////////
  // Generate the Max/Min result
  wire maxmin_sel_op1 =  ((op_max | op_maxu) &   op1_gt_op2) 
                      |  ((op_min | op_minu) & (~op1_gt_op2));

  wire [`E203_XLEN-1:0] maxmin_res  = maxmin_sel_op1 ? misc_op1 : misc_op2;  

  //////////////////////////////////////////////////////////////
  // Generate the final result
  wire [`E203_XLEN-1:0] alu_dpath_res = 
        ({`E203_XLEN{op_or       }} & orer_res )
      | ({`E203_XLEN{op_and      }} & ander_res)
      | ({`E203_XLEN{op_xor      }} & xorer_res)
      | ({`E203_XLEN{op_addsub   }} & adder_res[`E203_XLEN-1:0])
      | ({`E203_XLEN{op_srl      }} & srl_res)
      | ({`E203_XLEN{op_sll      }} & sll_res)
      | ({`E203_XLEN{op_sra      }} & sra_res)
      | ({`E203_XLEN{op_mvop2    }} & mvop2_res)
      | ({`E203_XLEN{op_slttu    }} & slttu_res)
      | ({`E203_XLEN{op_sh1add  }} & sh1adder_res)/*rtl change*/
      | ({`E203_XLEN{op_sh2add  }} & sh2adder_res)/*rtl change*/
      | ({`E203_XLEN{op_sh3add  }} & sh3adder_res)/*rtl change*/
      | ({`E203_XLEN{op_andn    }} & andner_res)/*rtl change*/
      | ({`E203_XLEN{op_orn     }} & orner_res)/*rtl change*/
      | ({`E203_XLEN{op_xnor    }} & xnorer_res)/*rtl change*/
      | ({`E203_XLEN{op_clz     }} & clzer_res)/*rtl change*/
      | ({`E203_XLEN{op_ctz     }} & ctzer_res)/*rtl change*/
      | ({`E203_XLEN{op_cpop    }} & cpoper_res)/*rtl change*/
      | ({`E203_XLEN{op_bmax    }} & bmaxer_res)/*rtl change*/
      | ({`E203_XLEN{op_bmaxu   }} & bmaxuer_res)/*rtl change*/
      | ({`E203_XLEN{op_bmin    }} & bminer_res)/*rtl change*/
      | ({`E203_XLEN{op_bminu   }} & bminuer_res)/*rtl change*/
      | ({`E203_XLEN{op_sextb   }} & sextber_res)/*rtl change*/
      | ({`E203_XLEN{op_sexth   }} & sexther_res)/*rtl change*/
      | ({`E203_XLEN{op_zexth   }} & zexther_res)/*rtl change*/
      | ({`E203_XLEN{op_rol     }} & roler_res)/*rtl change*/
      | ({`E203_XLEN{op_ror     }} & rorer_res)/*rtl change*/
      | ({`E203_XLEN{op_orcb    }} & orcber_res)/*rtl change*/
      | ({`E203_XLEN{op_rev8    }} & rev8er_res)/*rtl change*/
      | ({`E203_XLEN{op_clmul   }} & clmuler_res)/*rtl change*/
      | ({`E203_XLEN{op_clmulh  }} & clmulher_res)/*rtl change*/
      | ({`E203_XLEN{op_clmulr  }} & clmulrer_res)/*rtl change*/
      | ({`E203_XLEN{op_bclr    }} & bclrer_res)/*rtl change*/
      | ({`E203_XLEN{op_bext    }} & bexter_res)/*rtl change*/
      | ({`E203_XLEN{op_binv    }} & binver_res)/*rtl change*/
      | ({`E203_XLEN{op_bset    }} & bseter_res)/*rtl change*/
      | ({`E203_XLEN{op_mul     }} & muler_res)/*rtl change*/
      | ({`E203_XLEN{op_mulh    }} & mulher_res)/*rtl change*/
      | ({`E203_XLEN{op_mulhsu  }} & mulhsuer_res)/*rtl change*/
      | ({`E203_XLEN{op_mulhu   }} & mulhuer_res)/*rtl change*/
      | ({`E203_XLEN{op_max | op_maxu | op_min | op_minu}} & maxmin_res)
        ;

  //////////////////////////////////////////////////////////////
  // Implement the SBF: Shared Buffers
  sirv_gnrl_dffl #(33) sbf_0_dffl (sbf_0_ena, sbf_0_nxt, sbf_0_r, clk);
  sirv_gnrl_dffl #(33) sbf_1_dffl (sbf_1_ena, sbf_1_nxt, sbf_1_r, clk);

  /////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////
  //  The ALU-Datapath Mux for the requestors 

  localparam DPATH_MUX_WIDTH = ((`E203_XLEN*2)+21+27+4);/*rtl change*/

  assign  {
     mux_op1
    ,mux_op2
    ,op_max  
    ,op_min  
    ,op_maxu 
    ,op_minu 
    ,op_add
    ,op_sub
    ,op_or
    ,op_xor
    ,op_and
    ,op_sll
    ,op_srl
    ,op_sra
    ,op_slt
    ,op_sltu
    ,op_mvop2
    ,op_sh1add/*rtl change*/
    ,op_sh2add/*rtl change*/
    ,op_sh3add/*rtl change*/
    ,op_andn  /*rtl change*/
    ,op_orn   /*rtl change*/
    ,op_xnor  /*rtl change*/
    ,op_clz   /*rtl change*/
    ,op_ctz   /*rtl change*/
    ,op_cpop  /*rtl change*/
    ,op_bmax  /*rtl change*/
    ,op_bmaxu /*rtl change*/
    ,op_bmin  /*rtl change*/
    ,op_bminu /*rtl change*/
    ,op_sextb /*rtl change*/
    ,op_sexth /*rtl change*/
    ,op_zexth /*rtl change*/
    ,op_rol   /*rtl change*/
    ,op_ror   /*rtl change*/
    ,op_orcb  /*rtl change*/
    ,op_rev8  /*rtl change*/
    ,op_clmul /*rtl change*/
    ,op_clmulh/*rtl change*/
    ,op_clmulr/*rtl change*/
    ,op_bclr/*rtl change*/
    ,op_bext/*rtl change*/
    ,op_binv/*rtl change*/
    ,op_bset/*rtl change*/
    ,op_mul   /*rtl change*/
    ,op_mulh  /*rtl change*/
    ,op_mulhsu/*rtl change*/
    ,op_mulhu /*rtl change*/
    ,op_cmp_eq 
    ,op_cmp_ne 
    ,op_cmp_lt 
    ,op_cmp_gt 
    ,op_cmp_ltu
    ,op_cmp_gtu
    }
    = 
        ({DPATH_MUX_WIDTH{alu_req_alu}} & {
             alu_req_alu_op1
            ,alu_req_alu_op2
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,alu_req_alu_add
            ,alu_req_alu_sub
            ,alu_req_alu_or
            ,alu_req_alu_xor
            ,alu_req_alu_and
            ,alu_req_alu_sll
            ,alu_req_alu_srl
            ,alu_req_alu_sra
            ,alu_req_alu_slt
            ,alu_req_alu_sltu
            ,alu_req_alu_lui// LUI just move-Op2 operation
            ,alu_req_alu_sh1add/*rtl change*/
            ,alu_req_alu_sh2add/*rtl change*/
            ,alu_req_alu_sh3add/*rtl change*/
            ,alu_req_alu_andn  /*rtl change*/
            ,alu_req_alu_orn   /*rtl change*/
            ,alu_req_alu_xnor  /*rtl change*/
            ,alu_req_alu_clz   /*rtl change*/
            ,alu_req_alu_ctz   /*rtl change*/
            ,alu_req_alu_cpop  /*rtl change*/
            ,alu_req_alu_bmax  /*rtl change*/
            ,alu_req_alu_bmaxu /*rtl change*/
            ,alu_req_alu_bmin  /*rtl change*/
            ,alu_req_alu_bminu /*rtl change*/
            ,alu_req_alu_sextb /*rtl change*/
            ,alu_req_alu_sexth /*rtl change*/
            ,alu_req_alu_zexth /*rtl change*/
            ,alu_req_alu_rol   /*rtl change*/
            ,alu_req_alu_ror   /*rtl change*/
            ,alu_req_alu_orcb  /*rtl change*/
            ,alu_req_alu_rev8  /*rtl change*/
            ,alu_req_alu_clmul /*rtl change*/
            ,alu_req_alu_clmulh/*rtl change*/
            ,alu_req_alu_clmulr/*rtl change*/
            ,alu_req_alu_bclr/*rtl change*/
            ,alu_req_alu_bext/*rtl change*/
            ,alu_req_alu_binv/*rtl change*/
            ,alu_req_alu_bset/*rtl change*/
            ,alu_req_alu_mul   /*rtl change*/
            ,alu_req_alu_mulh  /*rtl change*/
            ,alu_req_alu_mulhsu/*rtl change*/
            ,alu_req_alu_mulhu /*rtl change*/
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
        })
      | ({DPATH_MUX_WIDTH{bjp_req_alu}} & {
             bjp_req_alu_op1
            ,bjp_req_alu_op2
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,bjp_req_alu_add
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,bjp_req_alu_cmp_eq 
            ,bjp_req_alu_cmp_ne 
            ,bjp_req_alu_cmp_lt 
            ,bjp_req_alu_cmp_gt 
            ,bjp_req_alu_cmp_ltu
            ,bjp_req_alu_cmp_gtu

        })
      | ({DPATH_MUX_WIDTH{agu_req_alu}} & {
             agu_req_alu_op1
            ,agu_req_alu_op2
            ,agu_req_alu_max  
            ,agu_req_alu_min  
            ,agu_req_alu_maxu 
            ,agu_req_alu_minu 
            ,agu_req_alu_add
            ,1'b0
            ,agu_req_alu_or
            ,agu_req_alu_xor
            ,agu_req_alu_and
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,agu_req_alu_swap// SWAP just move-Op2 operation
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0/*rtl change*/
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
            ,1'b0
        })
        ;
  
  assign alu_req_alu_res     = alu_dpath_res[`E203_XLEN-1:0];
  assign agu_req_alu_res     = alu_dpath_res[`E203_XLEN-1:0];
  assign bjp_req_alu_add_res = alu_dpath_res[`E203_XLEN-1:0];
  assign bjp_req_alu_cmp_res = cmp_res;
`ifdef E203_SUPPORT_SHARE_MULDIV //{
  assign muldiv_req_alu_res  = adder_res;
`endif//E203_SUPPORT_SHARE_MULDIV}

  assign sbf_0_ena = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_sbf_0_ena : 
`endif//E203_SUPPORT_SHARE_MULDIV}
                 agu_sbf_0_ena;
  assign sbf_1_ena = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_sbf_1_ena : 
`endif//E203_SUPPORT_SHARE_MULDIV}
                 agu_sbf_1_ena;

  assign sbf_0_nxt = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_sbf_0_nxt : 
`endif//E203_SUPPORT_SHARE_MULDIV}
                 {1'b0,agu_sbf_0_nxt};
  assign sbf_1_nxt = 
`ifdef E203_SUPPORT_SHARE_MULDIV //{
      muldiv_req_alu ? muldiv_sbf_1_nxt : 
`endif//E203_SUPPORT_SHARE_MULDIV}
                 {1'b0,agu_sbf_1_nxt};

  assign agu_sbf_0_r = sbf_0_r[`E203_XLEN-1:0];
  assign agu_sbf_1_r = sbf_1_r[`E203_XLEN-1:0];

`ifdef E203_SUPPORT_SHARE_MULDIV //{
  assign muldiv_sbf_0_r = sbf_0_r;
  assign muldiv_sbf_1_r = sbf_1_r;
`endif//E203_SUPPORT_SHARE_MULDIV}

endmodule                                      
                                               
                                               
                                               
