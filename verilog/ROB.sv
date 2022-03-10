/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  ROB.sv                                              //
//                                                                     //
//  Description :  ROB MODULE of the pipeline;                         // 
//                 Reorders out of order instructions                  //
//                 and update state (as if) in the program             //
//                 order.                                              //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module ROB # ( 
    parameter   C_DP_NUM            =   `DP_NUM         ,
    parameter   C_CDB_NUM           =   `CDB_NUM        ,
    parameter   C_RT_NUM            =   `RT_NUM         ,
    parameter   C_ROB_ENTRY_NUM     =   `ROB_ENTRY_NUM  ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM    ,
    parameter   C_BR_NUM            =   `BR_NUM         
) (
    input   logic                           clk_i               ,   // Clock
    input   logic                           rst_i               ,   // Reset
    output  ROB_DP  [C_DP_NUM-1:0]          rob_dp_o            ,   // To Dispatcher - ROB_DP, Entry readiness for structural hazard detection
    input   DP_ROB  [C_DP_NUM-1:0]          dp_rob_i            ,   // From Dispatcher - DP_ROB
    output  ROB_RS  [C_DP_NUM-1:0]          rob_rs_o            ,   // To Reservation Station - ROB_RS   
    input   CDB     [C_CDB_NUM-1:0]         cdb_i               ,   // From Complete stage - CDB
    output  ROB_AMT [C_RT_NUM-1:0]          rob_amt_o           ,   // To Architectural Map Table - ROB_AMT
    output  ROB_FL  [C_RT_NUM-1:0]          rob_fl_o            ,   // To Free List - ROB_FL
    input   logic                           exception_i             // From Exception Controller
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM)  ;
    localparam  C_TAG_IDX_WIDTH         =   $clog2(C_PHY_REG_NUM)   ;
    localparam  C_ROB_IDX_WIDTH         =   $clog2(C_ROB_ENTRY_NUM) ;
    localparam  C_RT_IDX_WIDTH          =   $clog2(C_RT_NUM)        ;
    localparam  C_DP_IDX_WIDTH          =   $clog2(C_DP_NUM)        ;
    localparam  C_CDB_IDX_WIDTH         =   $clog2(C_CDB_NUM)       ;

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Pointers
    logic       [C_ROB_IDX_WIDTH:0]     head                                ;
    logic       [C_ROB_IDX_WIDTH:0]     tail                                ;
    logic       [C_ROB_IDX_WIDTH:0]     next_head                           ; 
    logic       [C_ROB_IDX_WIDTH:0]     next_tail                           ;
    logic       [C_ROB_ENTRY_NUM-1:0]   head_sel                            ;

    // ROB array
    ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_arr                             ;

    // Dispatch
    logic       [C_DP_NUM-1:0]          rob_ready                           ;
    logic       [C_DP_NUM-1:0]          dp_en_concat                        ;
    logic       [C_ROB_ENTRY_NUM-1:0]   dp_sel                              ;

    // Complete
    logic       [C_ROB_ENTRY_NUM-1:0]   cp_sel                              ;
    logic       [C_CDB_IDX_WIDTH-1:0]   cp_idx      [C_ROB_ENTRY_NUM-1:0]   ;

    // Branch mispredict
    logic       [C_ROB_ENTRY_NUM-1:0]   br_mispredict                       ;
    logic                               br_flush                            ;

    // Retire
    logic       [C_ROB_ENTRY_NUM-1:0]   rt_window                           ;
    logic       [C_ROB_ENTRY_NUM-1:0]   rt_sel                              ;
    logic       [C_RT_NUM-1:0]          rt_valid                            ;

    logic       [C_ROB_IDX_WIDTH:0]     avail_num                           ;
    logic       [C_RT_IDX_WIDTH:0]      rt_num                              ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Head entry selector
// --------------------------------------------------------------------
    assign  head_sel    =   1'b1 << head[C_ROB_IDX_WIDTH-1:0];

// --------------------------------------------------------------------
// Dispatch entry selector
// --------------------------------------------------------------------
    always_comb begin
        // Concatenate dp_en from the dispatch channels
        for (integer idx = 0; idx < C_DP_NUM; idx++) begin
            dp_en_concat[idx] =   dp_rob_i[idx].dp_en;
        end

        // Circular left shift to assert the selected entries
        // e.g. 8'b00001111 << 5 => 8'b11100001
        dp_sel  =   (dp_en_concat << tail[C_ROB_IDX_WIDTH-1:0]) ||
                    (dp_en_concat >> (C_ROB_NUM_WIDTH - tail[C_ROB_IDX_WIDTH-1:0]));

        // Output dispatched entries index to Reservation Station
        for (integer idx = 0; idx < C_DP_NUM; idx++) begin
            rob_rs_o[idx].rob_idx   =   tail[C_ROB_IDX_WIDTH-1:0] + idx;
        end
    end

// --------------------------------------------------------------------
// Complete entry selector
// --------------------------------------------------------------------
    always_comb begin 
        for (integer entry_idx = 0; entry_idx < C_ROB_ENTRY_NUM; entry_idx++) begin
            cp_sel[entry_idx]   =   0;
            cp_idx[entry_idx]   =   0;
            // Check if any rob_idx from valid CDB channels
            // matches the current entry idx
            for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin 
                if ((entry_idx == cdb_i[cdb_idx].rob_idx) && cdb_i[cdb_idx].valid)begin
                    cp_sel[entry_idx]   =   1'b1;
                    cp_idx[entry_idx]   =   cdb_idx;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Retire entry selector
// --------------------------------------------------------------------
    always_comb begin
        // Whether an entry can be retired depends on:
        // 1. If consecutive entries between the head entry and itself
        // are all completed.
        // 2. Its own complete bit.

        // Select the entries in the retire window.
        rt_window   =   ({C_RT_NUM{1'b1}} << head[C_ROB_IDX_WIDTH-1:0]) ||
                        ({C_RT_NUM{1'b1}} >> (C_ROB_NUM_WIDTH - tail[C_ROB_IDX_WIDTH-1:0]));

        // Select the entries that are ready to retire
        rt_sel  =   {C_ROB_ENTRY_NUM{1'b0}};
        for (integer idx = 0; idx < C_ROB_ENTRY_NUM; idx++) begin
            // If the entry is in the retire window -> go on to check if it is ready to retire
            if (rt_window[idx]) begin
                // idx == 0
                if (idx == 0) begin
                    rt_sel[0]   =   head_sel[0] ?
                                    rob_arr[0].complete : 
                                    rt_sel[C_ROB_ENTRY_NUM-1] & rob_arr[0].complete;
                // idx == 1 ~ (C_ROB_ENTRY_NUM-1)
                end else begin
                    if (rt_window[idx]) begin
                        rt_sel[idx] =   head_sel[idx] ?
                                        rob_arr[idx].complete : 
                                        rt_sel[idx-1] & rob_arr[idx].complete;
                    end
                end
            end
        end

        // Output retire valid signal to Architectural Map Table 
        // & Free List
        for (integer idx = 0; idx < RT_NUM; idx++) begin
            rt_valid[idx]   =   rt_sel[head[C_ROB_IDX_WIDTH-1:0]+idx];
        end
    end

// --------------------------------------------------------------------
// Branch miprediction detection & flush
// --------------------------------------------------------------------
    always_comb begin
        br_flush    =   0;
        for (integer idx = 0; idx < C_ROB_NUM_WIDTH; idx++) begin
            br_mispredict[idx]  =   (rob_arr[idx].br_predict 
                                    != rob_arr[idx].br_result);
            // Once the mispredicted branch retires, flush the ROB entries
            if (rt_sel[idx] && br_mispredict[idx]) begin
                br_flush    =   1;
            end
        end
    end

// --------------------------------------------------------------------
// Entry content manipulation
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (integer idx = 0; idx < C_ROB_ENTRY_NUM; idx++) begin
            // System synchronous reset
            if (rst_i) begin
                rob_arr[idx].valid      <=  `SD 1'b0;
                rob_arr[idx].complete   <=  `SD 1'b0;
            // Precise state by exception
            end else if (exception_i) begin
                rob_arr[idx].valid      <=  `SD 1'b0;
                rob_arr[idx].complete   <=  `SD 1'b0;
            // Flush by branch misprediction
            end else if (br_flush) begin
                rob_arr[idx].valid      <=  `SD 1'b0;
                rob_arr[idx].complete   <=  `SD 1'b0;
            // Dispatch
            end else if (dp_sel[idx]) begin
                rob_arr[idx].valid      <=  `SD 1'b1;
                rob_arr[idx].complete   <=  `SD 1'b0;
                rob_arr[idx].pc         <=  `SD dp_rob_i[idx-tail[C_ROB_ENTRY_NUM-1:0]].pc;
                rob_arr[idx].arch_reg   <=  `SD dp_rob_i[idx-tail[C_ROB_ENTRY_NUM-1:0]].arch_reg;
                rob_arr[idx].tag        <=  `SD dp_rob_i[idx-tail[C_ROB_ENTRY_NUM-1:0]].tag;
                rob_arr[idx].tag_old    <=  `SD dp_rob_i[idx-tail[C_ROB_ENTRY_NUM-1:0]].tag_old;
                rob_arr[idx].br_predict <=  `SD dp_rob_i[idx-tail[C_ROB_ENTRY_NUM-1:0]].br_predict;
            // Retire
            end else if (rt_sel[idx]) begin
                rob_arr[idx].complete   <=  `SD 1'b0; 
                rob_arr[idx].valid      <=  `SD 1'b0;
            // Complete
            end else if (cp_sel[idx] && rob_arr[idx].valid) begin
                rob_arr[idx].complete   <=  `SD 1'b1;
                rob_arr[idx].br_result  <=  `SD cdb_i[cp_idx[idx]].br_result;
            end
        end
    end

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
            // Head and tail on the same page -> ROB is empty
            if (tail[ROB_IDX_WIDTH] == next_head[ROB_IDX_WIDTH]) begin
                avail_num   =   C_ROB_ENTRY_NUM;
            // Head and tail not on the same page -> ROB is full
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
        if (avail_num >= C_DP_NUM) begin
            rob_ready   =   {C_DP_NUM{1'b1}};
        // If there's no available entires, everything is low.
        //! The reason why this is extra is that the {{avail_num{1'b0}}{1'b0}} syntax cannot work when avail_num == 0.
        end else if (avail_num == 0) begin
            rob_ready   =   {C_DP_NUM{1'b0}};
        // LSB refers to the lowest idx available.
        // Make a 0*1* signal (where the lowest bits indicates possible signals to dispatch).
        end else begin
            rob_ready   =   {{(C_DP_NUM-avail_num){1'b0}},{avail_num{1'b1}}};
        end

        // Output to dispatcher
        for (integer idx = 0; idx < C_DP_NUM; idx++) begin
            rob_dp_o[idx].rob_ready =   rob_ready[idx];
        end
    end

// --------------------------------------------------------------------
// Head and Tail pointers
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head    <=  `SD 0;
            tail    <=  `SD 0;
        end else if (exception_i) begin
            head    <=  `SD 0;
            tail    <=  `SD 0;
        end else if (br_flush) begin
            head    <=  `SD 0;
            tail    <=  `SD 0;
        end else begin
            head    <=  `SD next_head;
            tail    <=  `SD next_tail;
        end 
    end

    // Header pointer Next-state Logic
    always_comb begin
        // A thermometer code to binary encoder
        // calculates the number of retire entries.
        next_head   =   head;
        for (integer idx = 0; idx < C_RT_NUM; idx++) begin
            if (rt_valid[idx]) begin
                next_head   =   head + idx + 'd1;
            end
        end
    end

    // Tail pointer Next-state Logic
    always_comb begin
        // A thermometer code to binary encoder
        // calculates the number of dispatched entries.
        next_tail   =   tail;
        for (integer idx = 0; idx < C_DP_NUM; idx++) begin
            if (dp_rob_i[idx].dp_en) begin 
                next_tail   =   tail + idx + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// ROB update to free list and architecture map table
// --------------------------------------------------------------------
    always_comb begin
        for (integer idx = 0; idx < C_RT_NUM; idx++) begin
            rob_fl_o[idx].valid    =    rt_valid[idx];
            rob_amt_o[idx].valid   =    rt_valid[idx];
            rob_fl_o[idx].phy_reg  =    rob_arr[head+idx].tag_old;
            rob_amt_o[idx].phy_reg =    rob_arr[head+idx].tag;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule
