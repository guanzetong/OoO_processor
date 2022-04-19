`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module AMT_svsim #(
    parameter   C_RT_NUM            =   3         ,
    parameter   C_ARCH_REG_NUM      =   32   ,
    parameter   C_TAG_IDX_WIDTH     =   $clog2(96)  ,
    parameter   C_THREAD_NUM        =   2     ,
    parameter   C_THREAD_IDX_WIDTH  =   $clog2(C_THREAD_NUM)
)(
    input   logic                                   clk_i           ,
    input   logic                                   rst_i           ,
    input   logic                                   rollback_i      , 
    input   logic       [C_THREAD_IDX_WIDTH-1:0]    thread_idx_i    ,
    input   ROB_AMT     [C_RT_NUM-1:0]   			rob_amt_i       , 
    output  AMT_ENTRY  [C_ARCH_REG_NUM-1:0] 		amt_o
);

    

  AMT AMT( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rollback_i }}, 
        {>>{ thread_idx_i }}, {>>{ rob_amt_i }}, {>>{ amt_o }} );
endmodule
`endif
