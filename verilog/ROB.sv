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

module ROB # ( 
    parameter   C_DP_NUM            =   `DP_NUM         ,
    parameter   C_CDB_NUM           =   `CDB_NUM        ,
    parameter   C_RT_NUM            =   `RT_NUM         ,
    parameter   C_ROB_ENTRY_NUM     =   `ROB_ENTRY_NUM  ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM    ,
    parameter   C_XLEN              =   `XLEN           
) (
    input   logic                           clk_i               ,   // Clock
    input   logic                           rst_i               ,   // Reset
    output  ROB_DP                          rob_dp_o            ,   // To Dispatcher - ROB_DP, Entry readiness for structural hazard detection
    input   DP_ROB                          dp_rob_i            ,   // From Dispatcher - DP_ROB
    input   CDB     [C_CDB_NUM-1:0]         cdb_i               ,   // From Complete stage - CDB
    output  ROB_AMT [C_RT_NUM-1:0]          rob_amt_o           ,   // To Architectural Map Table - ROB_AMT
    output  ROB_FL                          rob_fl_o            ,   // To Free List - ROB_FL
    output  ROB_VFL [C_RT_NUM-1:0]          rob_vfl_o           ,   // To Victim Free List - ROB_VFL
    input   logic                           exception_i         ,   // From Exception Controller
    output  logic                           br_mis_valid_o      ,
    output  logic   [C_XLEN-1:0]            br_target_o         ,

    // For testing
    output  ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_mon_o       ,
    output  logic   [C_RT_NUM-1:0][C_XLEN-1:0]  rt_pc_o         ,
    output  logic   [C_RT_NUM-1:0]              rt_valid_o      
);

//synopsys sync_set_reset ‘‘rst_i’’

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM)      ;
    localparam  C_TAG_IDX_WIDTH         =   $clog2(C_PHY_REG_NUM)       ;
    localparam  C_ROB_IDX_WIDTH         =   $clog2(C_ROB_ENTRY_NUM)     ;
    localparam  C_RT_IDX_WIDTH          =   $clog2(C_RT_NUM)            ;
    localparam  C_DP_IDX_WIDTH          =   $clog2(C_DP_NUM)            ;
    localparam  C_CDB_IDX_WIDTH         =   $clog2(C_CDB_NUM)           ;

    localparam  C_ROB_NUM_WIDTH         =   $clog2(C_ROB_ENTRY_NUM+1)   ;
    localparam  C_DP_NUM_WIDTH          =   $clog2(C_DP_NUM+1)          ;
    localparam  C_RT_NUM_WIDTH          =   $clog2(C_RT_NUM+1)          ;

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Pointers
    logic       [C_ROB_IDX_WIDTH-1:0]   head                                ;
    logic       [C_ROB_IDX_WIDTH-1:0]   tail                                ;
    logic       [C_ROB_IDX_WIDTH-1:0]   next_head                           ;   
    logic       [C_ROB_IDX_WIDTH-1:0]   next_tail                           ;   
    logic                               head_rollover                       ;
    logic                               tail_rollover                       ;
    logic       [C_ROB_ENTRY_NUM-1:0]   head_sel                            ;

    // ROB array
    ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_array                           ;

    // Dispatch
    logic       [C_ROB_ENTRY_NUM-1:0]   dp_sel                              ;
    logic       [C_DP_NUM_WIDTH-1:0]    dp_num                              ;

    // Complete
    logic       [C_ROB_ENTRY_NUM-1:0]   cp_sel                              ;
    logic       [C_CDB_IDX_WIDTH-1:0]   cp_idx      [C_ROB_ENTRY_NUM-1:0]   ;

    // Branch mispredict
    logic       [C_ROB_ENTRY_NUM-1:0]   br_mispredict                       ;
    logic       [C_ROB_IDX_WIDTH-1:0]   br_mis_idx                          ;

    // Retire
    logic       [C_ROB_ENTRY_NUM-1:0]   rt_window                           ;
    logic       [C_ROB_ENTRY_NUM-1:0]   rt_sel                              ;
    logic       [C_RT_NUM-1:0]          rt_valid                            ;
    logic       [C_RT_NUM_WIDTH-1:0]    rt_num                              ;

    logic       [C_ROB_NUM_WIDTH:0]     avail_num                           ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Head and Tail pointers
// --------------------------------------------------------------------
    // Sequential Logic
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head            <=  `SD 'd0;
            tail            <=  `SD 'd0;
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else if (exception_i) begin
            head            <=  `SD 0;
            tail            <=  `SD 0;
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else if (br_mis_valid_o) begin
            head            <=  `SD 0;
            tail            <=  `SD 0;
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else begin
            head    <=  `SD next_head;
            tail    <=  `SD next_tail;
            if (head + rt_num >= C_ROB_ENTRY_NUM) begin
                head_rollover   <=  `SD ~head_rollover;
            end
            if (tail + dp_num >= C_ROB_ENTRY_NUM) begin
                tail_rollover   <=  `SD ~tail_rollover;
            end
        end 
    end

    // Next-state Logic
    always_comb begin
        if (head + rt_num >= C_ROB_ENTRY_NUM) begin
            next_head   =   head + rt_num - C_ROB_ENTRY_NUM;
        end else begin
            next_head   =   head + rt_num;
        end

        if (tail + dp_num >= C_ROB_ENTRY_NUM) begin
            next_tail   =   tail + dp_num - C_ROB_ENTRY_NUM;
        end else begin
            next_tail   =   tail + dp_num;
        end
    end

    // Calculate the number of available entries based on head and tail
    always_comb begin
        if (head_rollover == tail_rollover) begin
            avail_num   =   C_ROB_ENTRY_NUM - (tail - head) + rt_num;
        end else begin
            avail_num   =   head - tail + rt_num;
        end

        if (avail_num > C_DP_NUM) begin
            rob_dp_o.avail_num  =   C_DP_NUM;
        end else begin
            rob_dp_o.avail_num  =   avail_num;
        end
    end

// --------------------------------------------------------------------
// Dispatch
// --------------------------------------------------------------------
    always_comb begin
        // Number of newly dispatched instructions
        dp_num  =   dp_rob_i.dp_num;

        // Per-entry select bit for dispatch
        dp_sel  =   'b0;
        if (tail + dp_num >= C_ROB_ENTRY_NUM) begin
            for (int unsigned entry_idx = 0; entry_idx < C_ROB_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail) || (entry_idx < ((tail + dp_num) - C_ROB_ENTRY_NUM))) begin
                    dp_sel[entry_idx]   =   1'b1;
                end
            end
        end else begin
            for (int unsigned entry_idx = 0; entry_idx < C_ROB_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail) && (entry_idx < tail + dp_num)) begin
                    dp_sel[entry_idx]   =   1'b1;
                end
            end
        end


        // Output dispatched entries index to Reservation Station
        for (int unsigned idx = 0; idx < C_DP_NUM; idx++) begin
            if (tail + idx >= C_ROB_ENTRY_NUM) begin
                rob_dp_o.rob_idx[idx]   =   tail + idx - C_ROB_ENTRY_NUM;
            end else begin
                rob_dp_o.rob_idx[idx]   =   tail + idx;
            end
        end
    end

// --------------------------------------------------------------------
// Complete
// --------------------------------------------------------------------
    always_comb begin 
        for (int unsigned entry_idx = 0; entry_idx < C_ROB_ENTRY_NUM; entry_idx++) begin
            cp_sel[entry_idx]   =   0;
            cp_idx[entry_idx]   =   0;
            // Check if any rob_idx from valid CDB channels
            // matches the current entry idx
            for (int unsigned cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin 
                if ((entry_idx == cdb_i[cdb_idx].rob_idx) && cdb_i[cdb_idx].valid)begin
                    cp_sel[entry_idx]   =   1'b1;
                    cp_idx[entry_idx]   =   cdb_idx;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Retire
// --------------------------------------------------------------------
    always_comb begin
        // Whether an entry can be retired depends on:
        // 1. If consecutive entries between the head entry and itself
        // are all completed.
        // 2. Its own complete bit.

        // Head entry selector
        head_sel    =   1'b1 << head;

        // Select the entries in the retire window.
        rt_window   =   ({C_RT_NUM{1'b1}} << head) |
                        ({C_RT_NUM{1'b1}} >> (C_ROB_ENTRY_NUM - head));

        // Select the entries that are ready to retire
        rt_sel  =   {C_ROB_ENTRY_NUM{1'b0}};
        for (int unsigned idx = 0; idx < C_ROB_ENTRY_NUM; idx++) begin
            // If the entry is in the retire window -> go on to check if it is ready to retire
            if (rt_window[idx] && rob_array[idx].valid) begin
                // idx == 0
                if (idx == 0) begin
                    rt_sel[0]   =   head_sel[0] ?
                                    rob_array[0].complete : 
                                    rt_sel[C_ROB_ENTRY_NUM-1] & rob_array[0].complete;
                // idx == 1 ~ (C_ROB_ENTRY_NUM-1)
                end else begin
                    if (rt_window[idx]) begin
                        rt_sel[idx] =   head_sel[idx] ?
                                        rob_array[idx].complete : 
                                        rt_sel[idx-1] & rob_array[idx].complete;
                    end
                end
            end
        end

        // Output retire valid signal to Architectural Map Table 
        // & Free List
        for (int unsigned idx = 0; idx < C_RT_NUM; idx++) begin
            if (head + idx >= C_ROB_ENTRY_NUM) begin
                rt_valid[idx]   =   rt_sel[head+idx-C_ROB_ENTRY_NUM];
            end else begin
                rt_valid[idx]   =   rt_sel[head+idx];
            end
        end

        // A thermometer code to binary encoder
        // calculates the number of retire entries.
        rt_num  =   0;
        for (int unsigned idx = 0; idx < C_RT_NUM; idx++) begin
            if (rt_valid[idx]) begin
                rt_num  =   rt_num + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// Branch miprediction detection & flush
// --------------------------------------------------------------------
    always_comb begin
        br_mis_valid_o  =   1'b0;
        br_target_o     =   'b0;
        br_mis_idx      =   'd0;
        for (int unsigned idx = 0; idx < C_ROB_ENTRY_NUM; idx++) begin
            br_mispredict[idx]  =   (rob_array[idx].br_predict 
                                    != rob_array[idx].br_result);
            // Once the mispredicted branch retires, flush the ROB entries
            if (rt_sel[idx] && br_mispredict[idx]) begin
                br_mis_valid_o  =   1'b1;
                br_target_o     =   rob_array[idx].br_target;
                br_mis_idx      =   idx;
            end
        end
    end

// --------------------------------------------------------------------
// Entry content manipulation
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned idx = 0; idx < C_ROB_ENTRY_NUM; idx++) begin
            // System synchronous reset
            if (rst_i) begin
                // rob_array[idx].valid        <=  `SD 1'b0;
                // rob_array[idx].complete     <=  `SD 1'b0;
                rob_array[idx]  <=  `SD 'b0;
            // Precise state by exception
            end else if (exception_i) begin
                // rob_array[idx].valid        <=  `SD 1'b0;
                // rob_array[idx].complete     <=  `SD 1'b0;
                rob_array[idx]  <=  `SD 'b0;
            // Flush by branch misprediction
            end else if (br_mis_valid_o) begin
                // rob_array[idx].valid        <=  `SD 1'b0;
                // rob_array[idx].complete     <=  `SD 1'b0;
                rob_array[idx]  <=  `SD 'b0;
            // Dispatch
            end else if (dp_sel[idx]) begin
                rob_array[idx].valid        <=  `SD 1'b1;
                rob_array[idx].complete     <=  `SD 1'b0;
                if (idx < tail) begin
                    rob_array[idx].pc           <=  `SD dp_rob_i.pc        [idx+C_ROB_ENTRY_NUM-tail];
                    rob_array[idx].rd           <=  `SD dp_rob_i.rd        [idx+C_ROB_ENTRY_NUM-tail];
                    rob_array[idx].tag          <=  `SD dp_rob_i.tag       [idx+C_ROB_ENTRY_NUM-tail];
                    rob_array[idx].tag_old      <=  `SD dp_rob_i.tag_old   [idx+C_ROB_ENTRY_NUM-tail];
                    rob_array[idx].br_predict   <=  `SD dp_rob_i.br_predict[idx+C_ROB_ENTRY_NUM-tail];
                end else begin
                    rob_array[idx].pc           <=  `SD dp_rob_i.pc        [idx-tail];
                    rob_array[idx].rd           <=  `SD dp_rob_i.rd        [idx-tail];
                    rob_array[idx].tag          <=  `SD dp_rob_i.tag       [idx-tail];
                    rob_array[idx].tag_old      <=  `SD dp_rob_i.tag_old   [idx-tail];
                    rob_array[idx].br_predict   <=  `SD dp_rob_i.br_predict[idx-tail];
                end
            // Retire
            end else if (rt_sel[idx]) begin
                // rob_array[idx].valid        <=  `SD 1'b0;
                // rob_array[idx].complete     <=  `SD 1'b0; 
                rob_array[idx]  <=  `SD 'b0;
            // Complete
            end else if (cp_sel[idx] && rob_array[idx].valid) begin
                rob_array[idx].complete     <=  `SD 1'b1;
                rob_array[idx].br_result    <=  `SD cdb_i[cp_idx[idx]].br_result;
                rob_array[idx].br_target    <=  `SD cdb_i[cp_idx[idx]].br_target;
            end else begin
                rob_array[idx]  <= `SD rob_array[idx]; // Maintain value.
            end
        end
    end

// --------------------------------------------------------------------
// ROB update to free list and architecture map table
// --------------------------------------------------------------------
    always_comb begin
        if (conditions) begin
            
        end
        rob_fl_o.rt_num =   rt_num;
        for (int unsigned idx = 0; idx < C_RT_NUM; idx++) begin
            if (head + idx >= C_ROB_ENTRY_NUM) begin
                rob_fl_o.tag_old[idx]   =   rob_array[head+idx-C_ROB_ENTRY_NUM].tag_old;
                rob_fl_o.tag[idx]       =   rob_array[head+idx-C_ROB_ENTRY_NUM].tag;
                rob_amt_o[idx].phy_reg  =   rob_array[head+idx-C_ROB_ENTRY_NUM].tag;
                rob_amt_o[idx].arch_reg =   rob_array[head+idx-C_ROB_ENTRY_NUM].rd;
                rob_vfl_o[idx].tag      =   rob_array[head+idx-C_ROB_ENTRY_NUM].tag;
                rob_vfl_o[idx].tag_old  =   rob_array[head+idx-C_ROB_ENTRY_NUM].tag_old;
            end else begin
                rob_fl_o.tag_old[idx]   =   rob_array[head+idx].tag_old;
                rob_fl_o.tag[idx]       =   rob_array[head+idx].tag;
                rob_amt_o[idx].phy_reg  =   rob_array[head+idx].tag;
                rob_amt_o[idx].arch_reg =   rob_array[head+idx].rd;
                rob_vfl_o[idx].tag      =   rob_array[head+idx].tag;
                rob_vfl_o[idx].tag_old  =   rob_array[head+idx].tag_old;
            end
            rob_amt_o[idx].wr_en    =   rt_valid[idx] && (!br_mis_valid_o);
            rob_vfl_o[idx].wr_en    =   rt_valid[idx] && (!br_mis_valid_o);
        end
    end

// --------------------------------------------------------------------
// For Pipeline Testing
// --------------------------------------------------------------------
    assign  rob_mon_o   =   rob_array;

    always_comb begin
        for (int unsigned idx = 0; idx < C_RT_NUM; idx++) begin
            if (head + idx >= C_ROB_ENTRY_NUM) begin
                rt_pc_o[idx]    =   rob_array[head+idx-C_ROB_ENTRY_NUM].pc;
            end else begin
                rt_pc_o[idx]    =   rob_array[head+idx].pc;
            end
            
            if (idx < rt_num) begin
                rt_valid_o[idx] =   1'b1;
            end else begin
                rt_valid_o[idx] =   1'b0;
            end
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================

endmodule