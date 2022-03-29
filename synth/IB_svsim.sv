`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module IB_svsim #(
    parameter   C_IS_NUM        =   2         ,
    parameter   C_ALU_NUM       =   3        , 
    parameter   C_MULT_NUM      =   2       , 
    parameter   C_BR_NUM        =   1         , 
    parameter   C_LOAD_NUM      =   1       , 
    parameter   C_STORE_NUM     =   1      , 
    parameter   C_FU_NUM        =   3 + 2 + 1 + 1 + 1         ,
    parameter   C_ALU_Q_SIZE    =   8     ,
    parameter   C_MULT_Q_SIZE   =   8    ,
    parameter   C_BR_Q_SIZE     =   8      ,
    parameter   C_LOAD_Q_SIZE   =   8    ,
    parameter   C_STORE_Q_SIZE  =   8   
) (
    input   logic                       clk_i           ,       input   logic                       rst_i           ,       output  IB_RS                       ib_rs_o         ,
    input   RS_IB   [C_IS_NUM-1:0]      rs_ib_i         ,
    input   FU_IB   [C_FU_NUM-1:0]      fu_ib_i         ,
    output  IB_FU   [C_FU_NUM-1:0]      ib_fu_o         ,
    input   BR_MIS                      br_mis_i        ,
    input   logic                       exception_i     
);

    

  IB IB( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ ib_rs_o }}, {>>{ rs_ib_i }}, 
        {>>{ fu_ib_i }}, {>>{ ib_fu_o }}, {>>{ br_mis_i }}, 
        {>>{ exception_i }} );
endmodule
`endif
