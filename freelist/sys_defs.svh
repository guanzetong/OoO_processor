/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__
`endif 

`define IF_NUM          2
`define DP_NUM          2   // The number of Dispatch channels.
`define IS_NUM          2   // The number of Issue channels.
`define CDB_NUM         2   // The number of CDB/Complete channels.
`define RT_NUM          2   // The number of Retire channels.
`define ROB_ENTRY_NUM   32  // The number of ROB entries.
`define RS_ENTRY_NUM    16	// The number of RS entries.
`define ARCH_REG_NUM    32  // The number of Architectural registers.
`define PHY_REG_NUM     64  // The number of Physical registers.
`define THREAD_NUM      2

`define ALU_NUM         3
`define MULT_NUM        2
`define BR_NUM          1
`define LOAD_NUM        1
`define STORE_NUM       1
`define FU_NUM          `ALU_NUM + `MULT_NUM + `BR_NUM + `LOAD_NUM + `STORE_NUM

`define ALU_Q_SIZE      8
`define MULT_Q_SIZE     8
`define BR_Q_SIZE       8
`define LOAD_Q_SIZE     8
`define STORE_Q_SIZE    8


`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ROB_IDX_WIDTH       $clog2(`ROB_ENTRY_NUM)
`define RS_IDX_WIDTH        $clog2(`RS_ENTRY_NUM)
`define THREAD_IDX_WIDTH    $clog2(`THREAD_NUM)

`define DP_NUM_WIDTH        $clog2(`DP_NUM+1)
`define RT_NUM_WIDTH        $clog2(`RT_NUM+1)

`define FL_ENTRY_NUM (`ROB_ENTRY_NUM)
`define FL_IDX ($clog(NUM_FL_ENTRIES))

`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ZERO_PREG ({`TAG_IDX_WIDTH{1'b0}})


typedef struct packed {
    logic   [`RT_NUM_WIDTH-1:0]                     rt_num      ;
    logic   [`RT_NUM-1:0][`TAG_IDX_WIDTH-1:0]       phy_reg     ;
    logic   [`TAG_IDX_WIDTH-1:0] tag;
} ROB_FL; // Combined


typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num   ;   
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag         ;
} FL_DP; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     dp_num      ;
} DP_FL; // Combined

typedef enum logic [1:0] {
	RD_USED  = 2'h0,
	RD_NONE  = 2'h1
} RD_SEL;

typedef enum logic [1:0] {
	RS1_USED  = 2'h0,
	RS1_NONE  = 2'h1
} RS1_SEL;

typedef enum logic [1:0] {
	RS2_USED  = 2'h0,
	RS2_NONE  = 2'h1
} RS2_SEL;

// Interface End