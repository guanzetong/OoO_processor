`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module ROB_svsim # ( 
    parameter   C_DP_NUM            =   2                 ,
    parameter   C_CDB_NUM           =   2                ,
    parameter   C_RT_NUM            =   2                 ,
    parameter   C_ROB_ENTRY_NUM     =   16          ,
    parameter   C_ARCH_REG_NUM      =   32           ,
    parameter   C_PHY_REG_NUM       =   96            ,
    parameter   C_XLEN              =   32                   ,
    parameter   C_ROB_IDX_WIDTH     =   $clog2(C_ROB_ENTRY_NUM) ,
    parameter   C_THREAD_NUM        =   2             ,
    parameter   C_THREAD_IDX_WIDTH  =   $clog2(C_THREAD_NUM)
) (
     

    input   logic                               clk_i           ,       input   logic                               rst_i           ,       output  ROB_DP                              rob_dp_o        ,       input   DP_ROB                              dp_rob_i        ,       input   CDB     [C_CDB_NUM-1:0]             cdb_i           ,       output  ROB_AMT [C_RT_NUM-1:0]              rob_amt_o       ,       output  ROB_FL                              rob_fl_o        ,           input   logic                               exception_i     ,       input   logic   [C_THREAD_IDX_WIDTH-1:0]    thread_idx_i    ,       output  logic                               br_mis_valid_o  ,       output  logic   [C_XLEN-1:0]                br_target_o     ,       output  ROB_LSQ                             rob_lsq_o       ,       output  logic   [C_RT_NUM-1:0][C_XLEN-1:0]  rt_pc_o         ,
    output  logic   [C_RT_NUM-1:0]              rt_valid_o      ,
    output  logic   [C_RT_NUM-1:0]              rt_wfi_o        ,
    output  logic   [C_ROB_IDX_WIDTH-1:0]       rob_head_mon_o  
);



  ROB ROB( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rob_dp_o }}, {>>{ dp_rob_i }}, 
        {>>{ cdb_i }}, {>>{ rob_amt_o }}, {>>{ rob_fl_o }}, 
        {>>{ exception_i }}, {>>{ thread_idx_i }}, {>>{ br_mis_valid_o }}, 
        {>>{ br_target_o }}, {>>{ rob_lsq_o }}, {>>{ rt_pc_o }}, 
        {>>{ rt_valid_o }}, {>>{ rt_wfi_o }}, {>>{ rob_head_mon_o }} );
endmodule
`endif
