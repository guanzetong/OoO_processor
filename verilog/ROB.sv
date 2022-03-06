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

`define DISPATCH_WIDTH  2   //The width of Dispatch.
`define CDB_WIDTH       2   //The number of entries on CDB, or the width of Complete
`define RETIRE_WIDTH    2   //The width of Retire.
`define ROB_ENTRY_NUM   32  //The number of ROB entries.
`define ARCH_REG_NUM    32  //The number of Architectural registers.
`define PHY_REG_NUM     64  //The number of Physical registers.


`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ROB_IDX_WIDTH       $clog2(`ROB_ENTRY_NUM)

`timescale 1ns/100ps

// Grouping of signals going to ( and from ) a specific module?
typedef struct packed {
    logic   [`DISPATCH_WIDTH-1:0]                               dispatch_en_i,
    logic   [`ARCH_REG_IDX_WIDTH*`DISPATCH_WIDTH-1:0]     dispatch_arch_reg_i,
    logic   [`TAG_WIDTH*`DISPATCH_WIDTH-1:0]                   dispatch_tag_i,
    logic   [`TAG_WIDTH*`DISPATCH_WIDTH-1:0]               dispatch_tag_old_i,
    logic   [`DISPATCH_WIDTH-1:0]                       dispatch_br_predict_i
} DISPATCH_ROB;

typedef struct packed {
    
} FREE_LIST_IN;

typedef struct packed {
    logic  
} ROB_MAP_TABLE; // 

typedef struct packed {
} ROB_FREE_LIST; // 

typedef struct packed{
    logic cdb_valid,                     // Is this signal valid?
    logic [`TAG_IDX_WIDTH-1:0] cdb_tag,  // Physical Register
    logic [`ROB_IDX_WIDTH-1:0] rob_index // Used to locate rob entry
} CDB_PACKET;

typedef struct packed {
    logic [`XLEN-1:0] PC, 
    logic [`XLEN-1:0] NPC, 
    logic [`TAG_IDX_WIDTH-1:0] T_old,
    logic [`TAG_IDX_WIDTH-1:0] T_new,
    ALU_FUNC alu_func,
    ALU_OPA_SELECT sel_a,
    ALU_OPB_SELECT sel_b,

    logic [`ROB_IDX_WIDTH-1:0] arch_reg,
    logic           complete,
    tag
} ROB_ENTRY; // 

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


