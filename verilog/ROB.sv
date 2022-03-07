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

`define DP_WIDTH        2   //The width of Dispatch.
`define CDB_WIDTH       2   //The number of entries on CDB, or the width of Complete
`define RT_WIDTH        2   //The width of Retire.
`define ROB_ENTRY_NUM   32  //The number of ROB entries.
`define ARCH_REG_NUM    32  //The number of Architectural registers.
`define PHY_REG_NUM     64  //The number of Physical registers.
`define BR_NUM          1   //The number of Branch Resolver


`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ROB_IDX_WIDTH       $clog2(`ROB_ENTRY_NUM)

`timescale 1ns/100ps

// Grouping of signals going to ( and from ) a specific module?
typedef struct packed {
    logic   [`DP_WIDTH-1:0]                       dp_en         ;
    logic   [`ARCH_REG_IDX_WIDTH*`DP_WIDTH-1:0]   arch_reg      ;
    logic   [`TAG_WIDTH*`DP_WIDTH-1:0]            tag           ;
    logic   [`TAG_WIDTH*`DP_WIDTH-1:0]            tag_old       ;
    logic   [`DP_WIDTH-1:0]                       br_predict    ;
} DP_ROB;

typedef struct packed {
    logic [`RT_WIDTH-1:0] MT_key_val rob_amt_o;
} ROB_AMT; // 

typedef struct packed {
    logic valid;
    logic [`ARCH_REG_IDX_WIDTH] arch_reg; // Key
    logic [`TAG_IDX_WIDTH] phy_reg;       // Value
} MT_key_val;

typedef struct packed {
    logic ready;
    logic [`ARCH_REG_IDX_WIDTH] arch_reg;
    logic [`TAG_IDX_WIDTH] phy_reg      ;
} MT_ENTRY;

typedef struct packed {
    logic valid;
    logic [`TAG_IDX_WIDTH] phy_reg;
} ROB_FL;

// Signal coming from complete stage
typedef struct packed{
    logic                       valid   ;   // Is this signal valid?
    logic [`TAG_IDX_WIDTH-1:0]  tag     ;   // Physical Register
    logic [`ROB_IDX_WIDTH-1:0]  rob_idx ;   // Used to locate rob entry
} CDB;

typedef struct packed {
    logic [`XLEN-1:0]           PC ;
    // logic [`XLEN-1:0] NPC, 
    logic                       valid;
    logic [`ROB_IDX_WIDTH-1:0]  arch_reg;
    logic [`TAG_IDX_WIDTH-1:0]  tag_old;
    logic [`TAG_IDX_WIDTH-1:0]  tag;
    logic                       complete;
    logic                       br_predict;
} ROB_ENTRY; // 

typedef struct packed {
    logic br_valid  ;
    logic br_result ;
    logic br_rob_idx;
} BR_ROB;

module ROB # ( 
    parameter   C_DP_WIDTH          =   `DP_WIDTH       ,
    parameter   C_CDB_WIDTH         =   `CDB_WIDTH      ,
    parameter   C_RT_WIDTH          =   `RT_WIDTH       ,
    parameter   C_ROB_ENTRY_NUM     =   `ROB_ENTRY_NUM  ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM    ,
    parameter   C_BR_NUM            =   `BR_NUM         
) (
    input   logic                           clk_i               ,   // Clock
    input   logic                           rst_i               ,   // Reset
    output  logic   [C_DP_WIDTH-1:0 ]       rob_ready_o         ,   // To Dispatcher, Entry readiness for structural hazard detection
    input   CDB     [C_CDB_WIDTH-1:0]       cdb_i               ,   // From Complete stage - CDB
    input   DP_ROB                          dp_rob_i            ,   // From Dispatcher - DP_ROB
    output  ROB_AMT                         rob_amt_o           ,   // To Architectural Map Table - ROB_AMT
    output  ROB_FL  [C_RT_WIDTH-1:0]        rob_fl_o            ,   // To Free List - ROB_FL
    input   BR_ROB  [C_BR_NUM-1:0]          br_rob_i            ,   // From Branch Resolver - BR_ROB
    input   logic                           precise_state_en_i      // From Exception Controller
);


// Local Parameters Declarations Start
    parameter   C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM);
    parameter   C_TAG_IDX_WIDTH         =   $clog2(C_PHY_REG_NUM);
    parameter   C_ROB_IDX_WIDTH         =   $clog2(C_ROB_ENTRY_NUM);
// Local Parameters Declarations End


// Signal Declarations Start
    logic       [ROB_IDX_WIDTH:0]       head        ;
    logic       [ROB_IDX_WIDTH:0]       tail        ;
    logic       [ROB_IDX_WIDTH:0]       next_head   ; 
    logic       [ROB_IDX_WIDTH:0]       next_tail   ;
    ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_arr     ;
    logic       [C_RT_WIDTH:0]          retire_and  ;
    logic       [C_ROB_IDX_WIDTH-1:0]   
    
    logic                               full        ;
    logic                               empty       ;

    logic       [ROB_IDX_WIDTH:0]       avail_num   ;
// Signal Declarations End


// RTL Logic Start

//      Calculate the number of available entries
    always_comb begin
        // Head and tail on the same page -> Substract directly
        if (tail[ROB_IDX_WIDTH-1:0] > next_head[ROB_IDX_WIDTH-1:0]) begin
            avail_num   =   tail[ROB_IDX_WIDTH-1:0] - next_head[ROB_IDX_WIDTH-1:0];
        // Head and tail not on the same page -> Add C_ROB_ENTRY_NUM before substraction
        end else if (tail[ROB_IDX_WIDTH-1:0] < next_head[ROB_IDX_WIDTH-1:0]) begin
            avail_num   =   tail[ROB_IDX_WIDTH-1:0] + C_ROB_ENTRY_NUM - next_head[ROB_IDX_WIDTH-1:0];
        // Head and tail meet -> Full or Empty
        end else begin
            //  Head and tail on the same page -> ROB is empty
            if (tail[ROB_IDX_WIDTH] == next_head[ROB_IDX_WIDTH]) begin
                avail_num   =   C_ROB_ENTRY_NUM;
            //  Head and tail not on the same page -> ROB is full
            end else begin
                avail_num   =   0;
            end
        end
    end

//      Configure the rob ready signal.
    always_comb begin
        // All signals are high as long as there are more than enough entries.
        if (avail_num >= C_DP_WIDTH) begin
            rob_ready_o =   {C_DP_WIDTH{1'b1}};
        // If there's no available entires, everything is low.
        //! The reason why this is extra is that the {{avail_num{1'b0}}{1'b0}} syntax cannot work when avail_num == 0.
        end else if (avail_num == 0) begin
            rob_ready_o =   {C_DP_WIDTH{1'b0}};
        end else begin
            // LSB refers to the lowest index available.
            // Make a 0*1* signal (where the lowest bits indicates possible signals to dispatch).
            rob_ready_o =   {{(C_DP_WIDTH-avail_num){1'b0}},{avail_num{1'b1}}};
        end
    end

//      Head pointer
    always_ff @( posedge clk_i ) begin
        if (rst_i == 1'b1 || precise_state_en_i == 1'b1) begin
            head <= 0;
        end else begin
            head <= next_head;
        end 
    end

    always_comb begin
        next_head = head;
        retire_and[0] = 1'b1;
        for (integer index = 0; index < C_RT_WIDTH; index++) begin
            if (rob_arr[head[ROB_IDX_WIDTH-1:0] + index].complete == 1) begin 
                next_head = next_head + retire_and[index];
                retire_and[index+1] = retire_and[index] & 1'b1;
            end else begin
                retire_and[index+1] = retire_and[index] & 1'b0;
            end
        end
    end

//      Tail pointer

    always_ff @(posedge clk_i) begin
        if (rst_i == 1'b1 || precise_state_en_i == 1'b1) begin
            tail <= 1'b0;
        end else begin
            tail <= next_tail;
        end

    always_comb begin
        next_tail = tail;
        for (integer index = 0; index < C_DP_WIDTH; index++) begin
            if (dp_en_i[index] == 1'b1) begin 
                next_tail = next_tail + 1;
            end
        end
    end
// RTL Logic End

endmodule

// START -> 0

// tail -> 1'b0, 5'd0
// head -> 1'b0, 5'd0

// XOR tail[MSB], head[MSB]

// END -> 11

casez (rob_arr[head:head+C_RT_WIDTH].complete)
    'bXX01: 
    'bX011: 
    default: 
endcase