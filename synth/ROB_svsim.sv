`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module ROB_svsim # ( 
    parameter   C_DP_NUM            =   2         ,
    parameter   C_CDB_NUM           =   2        ,
    parameter   C_RT_NUM            =   2         ,
    parameter   C_ROB_ENTRY_NUM     =   32  ,
    parameter   C_ARCH_REG_NUM      =   32   ,
    parameter   C_PHY_REG_NUM       =   64    
) (
    input   logic                           clk_i               ,       input   logic                           rst_i               ,       output  ROB_DP  [C_DP_NUM-1:0]          rob_dp_o            ,       input   DP_ROB  [C_DP_NUM-1:0]          dp_rob_i            ,       output  ROB_RS  [C_DP_NUM-1:0]          rob_rs_o            ,       input   CDB     [C_CDB_NUM-1:0]         cdb_i               ,       output  ROB_AMT [C_RT_NUM-1:0]          rob_amt_o           ,       output  ROB_FL  [C_RT_NUM-1:0]          rob_fl_o            ,       input   logic                           exception_i         ,       output  logic                           br_flush_o          
);



  ROB ROB( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rob_dp_o }}, {>>{ dp_rob_i }}, 
        {>>{ rob_rs_o }}, {>>{ cdb_i }}, {>>{ rob_amt_o }}, {>>{ rob_fl_o }}, 
        {>>{ exception_i }}, {>>{ br_flush_o }} );
endmodule
`endif
