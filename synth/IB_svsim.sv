`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module IB_svsim #(
    parameter   C_IS_NUM            =   3                 ,
    parameter   C_ALU_NUM           =   3                , 
    parameter   C_MULT_NUM          =   2               , 
    parameter   C_BR_NUM            =   1                 , 
    parameter   C_LOAD_NUM          =   1               , 
    parameter   C_STORE_NUM         =   1              , 
    parameter   C_FU_NUM            =   (3 + 2 + 1 + 1 + 1)                 ,
    parameter   C_ALU_Q_SIZE        =   8             ,
    parameter   C_MULT_Q_SIZE       =   8            ,
    parameter   C_BR_Q_SIZE         =   8              ,
    parameter   C_LOAD_Q_SIZE       =   8            ,
    parameter   C_STORE_Q_SIZE      =   8           ,
    parameter   C_ALU_IDX_WIDTH     =   $clog2(C_ALU_Q_SIZE  )  ,
    parameter   C_MULT_IDX_WIDTH    =   $clog2(C_MULT_Q_SIZE )  ,
    parameter   C_BR_IDX_WIDTH      =   $clog2(C_BR_Q_SIZE   )  ,
    parameter   C_LOAD_IDX_WIDTH    =   $clog2(C_LOAD_Q_SIZE )  ,
    parameter   C_STORE_IDX_WIDTH   =   $clog2(C_STORE_Q_SIZE)
) (
    input   logic                       clk_i           ,       input   logic                       rst_i           ,       output  IB_RS                       ib_rs_o         ,
    input   RS_IB   [C_IS_NUM-1:0]      rs_ib_i         ,
    input   FU_IB   [C_FU_NUM-1:0]      fu_ib_i         ,
    output  IB_FU   [C_FU_NUM-1:0]      ib_fu_o         ,
    input   BR_MIS                      br_mis_i        ,
    input   logic                       exception_i     ,
        output  IS_INST [C_ALU_Q_SIZE  -1:0]    ALU_queue_mon_o     ,
    output  IS_INST [C_MULT_Q_SIZE -1:0]    MULT_queue_mon_o    ,
    output  IS_INST [C_BR_Q_SIZE   -1:0]    BR_queue_mon_o      ,
    output  IS_INST [C_LOAD_Q_SIZE -1:0]    LOAD_queue_mon_o    ,
    output  IS_INST [C_STORE_Q_SIZE-1:0]    STORE_queue_mon_o   ,

    output  logic   [C_ALU_Q_SIZE  -1:0]    ALU_valid_mon_o     ,
    output  logic   [C_MULT_Q_SIZE -1:0]    MULT_valid_mon_o    ,
    output  logic   [C_BR_Q_SIZE   -1:0]    BR_valid_mon_o      ,
    output  logic   [C_LOAD_Q_SIZE -1:0]    LOAD_valid_mon_o    ,
    output  logic   [C_STORE_Q_SIZE-1:0]    STORE_valid_mon_o   ,

    output  logic   [C_ALU_IDX_WIDTH  -1:0] ALU_head_mon_o      ,
    output  logic   [C_ALU_IDX_WIDTH  -1:0] ALU_tail_mon_o      ,
    output  logic   [C_MULT_IDX_WIDTH -1:0] MULT_head_mon_o     ,
    output  logic   [C_MULT_IDX_WIDTH -1:0] MULT_tail_mon_o     ,
    output  logic   [C_BR_IDX_WIDTH   -1:0] BR_head_mon_o       ,
    output  logic   [C_BR_IDX_WIDTH   -1:0] BR_tail_mon_o       ,
    output  logic   [C_LOAD_IDX_WIDTH -1:0] LOAD_head_mon_o     ,
    output  logic   [C_LOAD_IDX_WIDTH -1:0] LOAD_tail_mon_o     ,
    output  logic   [C_STORE_IDX_WIDTH-1:0] STORE_head_mon_o    ,
    output  logic   [C_STORE_IDX_WIDTH-1:0] STORE_tail_mon_o    
    
);

    

  IB IB( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ ib_rs_o }}, {>>{ rs_ib_i }}, 
        {>>{ fu_ib_i }}, {>>{ ib_fu_o }}, {>>{ br_mis_i }}, 
        {>>{ exception_i }}, {>>{ ALU_queue_mon_o }}, {>>{ MULT_queue_mon_o }}, 
        {>>{ BR_queue_mon_o }}, {>>{ LOAD_queue_mon_o }}, 
        {>>{ STORE_queue_mon_o }}, {>>{ ALU_valid_mon_o }}, 
        {>>{ MULT_valid_mon_o }}, {>>{ BR_valid_mon_o }}, 
        {>>{ LOAD_valid_mon_o }}, {>>{ STORE_valid_mon_o }}, 
        {>>{ ALU_head_mon_o }}, {>>{ ALU_tail_mon_o }}, 
        {>>{ MULT_head_mon_o }}, {>>{ MULT_tail_mon_o }}, 
        {>>{ BR_head_mon_o }}, {>>{ BR_tail_mon_o }}, {>>{ LOAD_head_mon_o }}, 
        {>>{ LOAD_tail_mon_o }}, {>>{ STORE_head_mon_o }}, 
        {>>{ STORE_tail_mon_o }} );
endmodule
`endif
