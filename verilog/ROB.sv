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

`timescale 1ns/100ps

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

// Grouping of signals going to ( and from ) a specific module?

typedef struct packed {
    logic   [`XLEN-1:0]                 PC          ;
    logic                               valid       ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   arch_reg    ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag_old     ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic                               br_predict  ;
    logic                               complete    ;
    logic                               retire      ;
} ROB_ENTRY;

typedef struct packed {
    logic                               ready       ;
    logic   [`ARCH_REG_IDX_WIDTH]       arch_reg    ;
    logic   [`TAG_IDX_WIDTH]            phy_reg     ;
} MT_ENTRY;

typedef struct packed {
    logic                               dp_en       ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   arch_reg    ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag_old     ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic                               br_predict  ;
} DP_ROB;

typedef struct packed {
    logic   [`ROB_IDX_WIDTH-1:0]        rob_idx     ;
} ROB_RS;

typedef struct packed {
    logic                               valid       ;
    logic   [`ARCH_REG_IDX_WIDTH]       arch_reg    ;   // Key
    logic   [`TAG_IDX_WIDTH]            phy_reg     ;   // Value
} ROB_AMT;

typedef struct packed {
    logic                               valid       ;
    logic   [`TAG_IDX_WIDTH]            phy_reg     ;
} ROB_FL;

// Signal coming from complete stage
typedef struct packed{
    logic                               valid       ;   // Is this signal valid?
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;   // Physical Register
    logic   [`ROB_IDX_WIDTH-1:0]        rob_idx     ;   // Used to locate rob entry
} CDB;

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
    input   DP_ROB  [C_DP_WIDTH-1:0]        dp_rob_i            ,   // From Dispatcher - DP_ROB
    output  ROB_RS  [C_DP_WIDTH-1:0]        rob_rs_o            ,   // To Reservation Station - ROB_RS   
    input   CDB     [C_CDB_WIDTH-1:0]       cdb_i               ,   // From Complete stage - CDB
    output  ROB_AMT [C_RT_WIDTH-1:0]        rob_amt_o           ,   // To Architectural Map Table - ROB_AMT
    output  ROB_FL  [C_RT_WIDTH-1:0]        rob_fl_o            ,   // To Free List - ROB_FL
    input   BR_ROB  [C_BR_NUM-1:0]          br_rob_i            ,   // From Branch Resolver - BR_ROB
    input   logic                           precise_state_en_i      // From Exception Controller
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM);
    localparam  C_TAG_IDX_WIDTH         =   $clog2(C_PHY_REG_NUM);
    localparam  C_ROB_IDX_WIDTH         =   $clog2(C_ROB_ENTRY_NUM);
    localparam  C_RT_NUM_WIDTH          =   $clog2(C_RT_WIDTH);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    //  Pointer
    logic       [C_ROB_IDX_WIDTH:0]     head        ;
    logic       [C_ROB_IDX_WIDTH:0]     tail        ;
    logic       [C_ROB_IDX_WIDTH:0]     next_head   ; 
    logic       [C_ROB_IDX_WIDTH:0]     next_tail   ;
    ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_arr     ;
    logic       [C_RT_WIDTH:0]          retire_and  ; // Used for next_head

    logic       [C_ROB_IDX_WIDTH:0]     avail_num   ;

    logic       [C_ROB_ENTRY_NUM-1:0]   head_one_hot;
    logic       [C_RT_WIDTH-1:0]        retire_valid;
    logic       [C_RT_NUM_WIDTH-1:0]    retire_num  ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// ROB entry from dispatcher
// --------------------------------------------------------------------
    always_comb begin
        for (integer index = 0; index<C_DP_WIDTH; index++) begin 
            rob_arr[tail[ROB_IDX_WIDTH-1:0]].valid = dp_rob_i[index].dp_en;
            rob_arr[tail[ROB_IDX_WIDTH-1:0]].arch_reg = dp_rob_i[index].
        end
        
    end

    always_ff @(posedge clk_i) begin 
        if (rst_i) begin 
            rob_arr[tail[ROB_IDX_WIDTH-1:0]].valid    <= `SD 0;
            rob_arr[tail[ROB_IDX_WIDTH-1:0]].complete <= `SD 0;
        end else begin 
            for (integer index = 0; index<C_DP_WIDTH; index++) begin 
                rob_arr[tail[ROB_IDX_WIDTH-1:0]+index].valid = dp_rob_i[index].dp_en;

                rob_arr[tail[ROB_IDX_WIDTH-1:0]].arch_reg = dp_rob_i[index].arch_reg;
                rob_arr[tail[ROB_IDX_WIDTH-1:0]].tag = dp_rob_i[index].tag;
                rob_arr[tail[ROB_IDX_WIDTH-1:0]].tag_old = dp_rob_i[index].tag_old;
                rob_arr[tail[ROB_IDX_WIDTH-1:0]].br_predict = dp_rob_i[index].br_predict;
        end
        end
    end

    always_ff @(posedge clk_i) begin 
        for (integer index = 0; index<C_DP_WIDTH; index++) begin 
            if (rst_i) begin 
                rob_arr[tail[ROB_IDX_WIDTH-1:0]+index].valid    <= `SD 0;
                rob_arr[tail[ROB_IDX_WIDTH-1:0]+index].complete <= `SD 0;
            end else begin
                
            end
        end
    end

// 
//      for (0 ~ ROB_ENTRY_NUM-1)
//          if rst_i
// 
//          else if (dp_en == 1 & dp_one_hot[index])
//              ASSIGN tail entry
//          else if (retire_valid == 1 & entry.retire)
//              clear valid complete
//          else
//              entry <= entry
//  dp_one_hot = {DP_WIDTH{1'b1}} << tail[C_ROB_IDX_WIDTH-1:0]
// 
// 
// 0001110
// 0011100
// 0111000
// 1110000
// retire_one_hot = {}


// --------------------------------------------------------------------
// Calculate the number of available entries
// --------------------------------------------------------------------
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

// --------------------------------------------------------------------
// Configure the rob ready signal.
// --------------------------------------------------------------------
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

// --------------------------------------------------------------------
// Head and Tail pointers
// --------------------------------------------------------------------
    always_ff @( posedge clk_i ) begin
        if (rst_i == 1'b1 || precise_state_en_i == 1'b1) begin
            head    <=  `SD 0;
            tail    <=  `SD 0;
        end else begin
            head    <=  `SD next_head;
            tail    <=  `SD next_tail;
        end 
    end

// Header pointer Next-state Logic
    // always_comb begin
    //     next_head = head;
    //     retire_and[0] = 1'b1;
    //     for (integer index = 0; index < C_RT_WIDTH; index++) begin
    //         if (rob_arr[head[ROB_IDX_WIDTH-1:0] + index].complete == 1'b1) begin 
    //             next_head = next_head + retire_and[index];
    //             retire_and[index+1] = retire_and[index] & 1'b1;
    //         end else begin
    //             retire_and[index+1] = retire_and[index] & 1'b0;
    //         end
    //     end
    // end
    //! We should also consider the tail bound (where the tail ends) -> This may be OK if we ensure that non-valid entries aren't considered (use complete bit to ensure this doesn't happen and/or valid bit).
    //! Consider seperating next_state and current state (for ROB) -> Make it edge-triggered. (Otherwise it may complicate how ROB is updated).
    //! This provides an oppurtunity to simply add up the signals that are high (in this one high) to determine how much to increment head pointer. May lead to simpler harwdware.
    //! We can also use this to piggy back off to set how the retire signals
    //should be set.
    
    assign  head_one_hot    =   1'b1 << head[C_ROB_IDX_WIDTH-1:0];

    always_comb begin
        // Retire bit in each entry
        //      Index == 0
        assign   [0].retire   =   head_one_hot[0] ?
                                        rob_arr[0].complete : 
                                        rob_arr[C_ROB_ENTRY_NUM-1].retire & rob_arr[0].complete;

        //      Index == 1 ~ (C_ROB_ENTRY_NUM-1)
        for (integer index = 1; index < C_ROB_ENTRY_NUM; index++) begin
            assign  rob_arr[index].retire   =   head_one_hot[index] ?
                                                rob_arr[index].complete : 
                                                rob_arr[index-1].retire & rob_arr[index].complete;
        end

        // Retire channels' valid
        for (integer offset = 0; offset < C_RT_WIDTH; offset++) begin
            assign  retire_valid[offset]    =   rob_arr[head[C_ROB_IDX_WIDTH-1:0]+offset].retire;
        end

        // Next Head. A thermometer code to binary encoder is needed to calculate the number
        // of retire entries.
        next_head   =   head;
        for (integer pos = 0; pos < C_RT_WIDTH; pos++) begin
            next_head   =   next_head + retire_valid[pos];
        end
    end

// Tail pointer Next-state Logic

    always_comb begin
        next_tail = tail;
        for (integer index = 0; index < C_DP_WIDTH; index++) begin
            if (dp_en_i[index] == 1'b1) begin 
                next_tail = next_tail + 1;
            end
        end
    end

// --------------------------------------------------------------------
// ROB update to free list and architecture map table
// --------------------------------------------------------------------
    always_comb begin
        for (integer index = 0; index < C_RT_WIDTH; index++) begin
            if (retire_valid[index] == 1'b1) begin
                rob_fl_o[index].valid    = 1'b1;
                rob_amt_o[index].valid   = 1'b1;
            end else begin 
                rob_fl_o[index].valid    = 1'b0;
                rob_amt_o[index].valid   = 1'b0;
            end
            rob_fl_o[index].phy_reg  = rob_arr[head].tag_old;
            rob_amt_o[index].phy_reg = rob_arr[head].tag;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================

endmodule

// START -> 0

// tail -> 1'b0, 5'd0
// head -> 1'b0, 5'd0

// XOR tail[MSB], head[MSB]

// END -> 11
