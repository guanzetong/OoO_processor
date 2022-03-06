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
    logic   [`DISPATCH_WIDTH-1:0]                       dispatch_en_i           ,
    logic   [`ARCH_REG_IDX_WIDTH*`DISPATCH_WIDTH-1:0]   dispatch_arch_reg_i     ,
    logic   [`TAG_WIDTH*`DISPATCH_WIDTH-1:0]            dispatch_tag_i          ,
    logic   [`TAG_WIDTH*`DISPATCH_WIDTH-1:0]            dispatch_tag_old_i      ,
    logic   [`DISPATCH_WIDTH-1:0]                       dispatch_br_predict_i   
} DISPATCH_ROB;

typedef struct packed {
    logic  update_en;

} ROB_ARCH_MAP_TABLE; // 

typedef struct packed {
    bit valid;
    bit [`TAG_IDX_WIDTH] arch_reg;
    bit [`TAG_IDX_WIDTH] phy_reg;
} MAP_TABLE_ENTRY;

typedef struct packed {
    bit valid;
    bit [`TAG_IDX_WIDTH] phy_reg;
} FREED_REG;
// ROB_FREE_LIST rob_free.data[ 0 ].valid;

typedef struct packed{
    logic                       cdb_valid   ,   // Is this signal valid?
    logic [`TAG_IDX_WIDTH-1:0]  cdb_tag     ,   // Physical Register
    logic [`ROB_IDX_WIDTH-1:0]  rob_index       // Used to locate rob entry
} CDB_PACKET;

typedef struct packed {
    // logic [`XLEN-1:0] PC, 
    // logic [`XLEN-1:0] NPC, 
    logic [`TAG_IDX_WIDTH-1:0] T_old,
    logic [`TAG_IDX_WIDTH-1:0] T_new,
 
    logic [`ROB_IDX_WIDTH-1:0] arch_reg,
    logic           complete,
} ROB_ENTRY; // 

typedef struct packed {
    logic branch_valid,
    logic branch_result,
    logic branch_rob_num,
} branch_rob;


module ROB # 
    ( 
    parameter   C_DISPATCH_WIDTH    =   `DISPATCH_WIDTH   ,
    parameter   C_CDB_WIDTH         =   `CDB_WIDTH        ,
    parameter   C_RETIRE_WIDTH      =   `RETIRE_WIDTH     ,
    parameter   C_ROB_ENTRY_NUM     =   `ROB_ENTRY_NUM    ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM     ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM      
    ) 
    (
    input                              clk_i, rst_i, // Clock and reset respectively
    input  [ C_DISPATCH_WIDTH ]       dispatch_en_i, // Dispatch enable. Used to tell how many ROB entries to allocate
    input  [ C_DISPATCH_WIDTH ] dispatch_arch_reg_i,
    input                            dispatch_tag_i,
    input                        dispatch_tag_old_i,
    input                        precise_state_en_i,
    input                            branch_valid_i,

    output         [ C_DISPATCH_WIDTH ] rob_ready_o
    output   [C_RETIRE_WIDTH-1:0] FREED_REG phy_reg_freed_o,
    output   [C_RETIRE_WIDTH-1:0] MAP_TABLE_ENTRY arch_map_entry_update_o,
    );

endmodule


