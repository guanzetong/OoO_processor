/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  ROB.sv                                              //
//                                                                     //
//  Description :  ROB MODULE of the pipeline;                         // 
//                 Reorders out of order instructions                  //
//                 and update state (as if) in the archiectural        //
//                 order.                                              //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`define C_DISPATCH_WIDTH_M  2   //The width of Dispatch.
`define C_CDB_WIDTH_M       2   //The number of entries on CDB, or the width of Complete
`define C_RETIRE_WIDTH_M    2   //The width of Retire.
`define C_ROB_ENTRY_NUM_M   32  //The number of ROB entries.
`define C_ARCH_REG_NUM_M    32  //The number of Architectural registers.
`define C_PHY_REG_NUM_M     64  //The number of Physical registers.

`define C_ARCH_REG_WIDTH_M  $clog2(`C_ARCH_REG_NUM)
`define C_TAG_WIDTH_M  $clog2(`C_PHY_REG_NUM_M)

`timescale 1ns/100ps

typedef struct packed {
    logic   [`C_DISPATCH_WIDTH_M-1:0]                       dispatch_en_i,
    logic   [`C_ARCH_REG_WIDTH_M*`C_DISPATCH_WIDTH_M-1:0]   dispatch_arch_reg_i,
    logic   [`C_TAG_WIDTH_M*`C_DISPATCH_WIDTH_M-1:0]        dispatch_tag_i,
    logic   [`C_TAG_WIDTH_M*`C_DISPATCH_WIDTH_M-1:0]        dispatch_tag_old_i,
    logic   [`C_DISPATCH_WIDTH_M-1:0]                       dispatch_br_predict_i
} DISPATCH_ROB;

typedef struct packed {

} FREE_LIST_IN;

typedef struct packed {

} ROB_MAP_TABLE; // 

typedef struct packed {

} ROB_FREE_LIST; // 

module ROB # 
    ( 
    parameter   C_DISPATCH_WIDTH    =   `C_DISPATCH_WIDTH_M ,
    parameter   C_CDB_WIDTH         =   `C_CDB_WIDTH_M      ,
    parameter   C_RETIRE_WIDTH      =   `C_RETIRE_WIDTH_M   ,
    parameter   C_ROB_ENTRY_NUM     =   `C_ROB_ENTRY_NUM_M  ,
    parameter   C_ARCH_REG_NUM      =   `C_ARCH_REG_NUM_M   ,
    parameter   C_PHY_REG_NUM       =   `C_PHY_REG_NUM_M    
    ) 
    (
    input                              clk_i, rst_i, // Clock and reset respectively
    input  [ C_DISPATCH_WIDTH ]       dispatch_en_i, // Dispatch enable. Used to tell how many ROB entries to allocate
    input  [ C_DISPATCH_WIDTH ] dispatch_arch_reg_i,
    input                            dispatch_tag_i,
    input                        dispatch_tag_old_i,

    output         [ C_DISPATCH_WIDTH ] rob_ready_o
    );

endmodule
