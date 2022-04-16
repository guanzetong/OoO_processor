/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_global_ctrl.sv                                  //
//                                                                     //
//  Description :  LSQ_global_ctrl                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_global_ctrl #(
    parameter   C_DP_NUM        =   `DP_NUM                     ,
    parameter   C_LSQ_ENTRY_NUM =   `LSQ_ENTRY_NUM              ,
    parameter   C_LSQ_IDX_WIDTH =   $clog2(C_LSQ_ENTRY_NUM)     ,
    parameter   C_LSQ_NUM_WIDTH =   $clog2(C_LSQ_ENTRY_NUM+1)
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   DP_LSQ                              dp_lsq_i        ,
    input   LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0]   lsq_array_i     ,
    output  logic       [C_LSQ_IDX_WIDTH-1:0]   head_o          ,
    output  logic       [C_LSQ_IDX_WIDTH-1:0]   tail_o          ,
    output  logic       [C_LSQ_ENTRY_NUM-1:0]   dp_sel_o        ,
    output  logic       [C_LSQ_ENTRY_NUM-1:0]   rt_sel_o        ,
    output  LSQ_DP                              lsq_dp_o        
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Pointers
    logic   [C_LSQ_IDX_WIDTH-1:0]   next_head       ;
    logic   [C_LSQ_IDX_WIDTH-1:0]   next_tail       ;  
    logic                           head_rollover   ;
    logic                           tail_rollover   ;

    // Numbers

    logic   [C_LSQ_NUM_WIDTH-1:0]   lsq_dp_num      ;
    logic   [C_LSQ_NUM_WIDTH-1:0]   lsq_rt_num      ;
    logic   [C_LSQ_NUM_WIDTH-1:0]   avail_num       ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Head and tail_o pointers movement
// --------------------------------------------------------------------
    // Sequential update
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head_o          <=  `SD 'd0;
            tail_o          <=  `SD 'd0;
            head_rollover   <=  `SD 'd0;
            tail_rollover   <=  `SD 'd0;
        end else begin
            head_o  <=  `SD next_head;
            tail_o  <=  `SD next_tail;
            if (head_o + lsq_rt_num   >= C_LSQ_ENTRY_NUM) begin
                head_rollover   <=  `SD ~head_rollover;
            end
            if (tail_o + lsq_dp_num   >= C_LSQ_ENTRY_NUM) begin
                tail_rollover   <=  `SD ~tail_rollover;
            end
        end
    end

    // Next state
    always_comb begin
        if (head_o + lsq_rt_num   >= C_LSQ_ENTRY_NUM) begin
            next_head   =   head_o + lsq_rt_num   - C_LSQ_ENTRY_NUM;
        end else begin
            next_head   =   head_o + lsq_rt_num  ;
        end
        if (tail_o + lsq_dp_num   >= C_LSQ_ENTRY_NUM) begin
            next_tail   =   tail_o + lsq_dp_num   - C_LSQ_ENTRY_NUM;
        end else begin
            next_tail   =   tail_o + lsq_dp_num  ;
        end
    end

// --------------------------------------------------------------------
// Number of available entries 
// --------------------------------------------------------------------
    always_comb begin
        if (head_rollover == tail_rollover) begin
            avail_num   = C_LSQ_ENTRY_NUM - (tail_o - head_o) + lsq_rt_num  ;
        end else begin
            avail_num   = head_o - tail_o + lsq_rt_num  ;
        end

        if (avail_num > C_DP_NUM) begin
            lsq_dp_o.avail_num  =   C_DP_NUM;
        end else begin
            lsq_dp_o.avail_num  =   avail_num;
        end
    end

// --------------------------------------------------------------------
// Dipatch entry select
// --------------------------------------------------------------------
    always_comb begin
        lsq_dp_num  =   dp_lsq_i.dp_num;
        // Per-entry select bit for dispatch
        dp_sel_o    =   'b0;
        if (tail_o + lsq_dp_num >= C_LSQ_ENTRY_NUM) begin
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail_o) || (entry_idx < ((tail_o + lsq_dp_num) - C_LSQ_ENTRY_NUM))) begin
                    dp_sel_o[entry_idx]   =   1'b1;
                end
            end
        end else begin
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail_o) && (entry_idx < tail_o + lsq_dp_num)) begin
                    dp_sel_o[entry_idx]   =   1'b1;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Retire entry select
// --------------------------------------------------------------------
    always_comb begin
        rt_sel_o    =   'b0;
        // IF   there is no rollover
        if (head_rollover == tail_rollover) begin
            // Loop over the entries
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                // IF   Pointed to by the head pointer
                if (entry_idx == head_o) begin
                    // IF   It is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if (lsq_array_i[entry_idx].retire == 1'b1) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                // ELSE Other valid entries
                end else if ((entry_idx > head_o) && (entry_idx < tail_o)) begin
                    // IF   the previous one is not a STORE
                    // AND  the previous one is selected to retire from LSQ
                    // AND  this entry is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if ((lsq_array_i[entry_idx-1].cmd != BUS_STORE)
                    && (rt_sel_o[entry_idx-1] == 1'b1)
                    && (lsq_array_i[entry_idx].retire == 1'b1)) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                end 
            end
        // ELSE there is a rollover 
        end else begin
            // Loop over the entries
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                // IF   Pointed to by the head pointer
                if (entry_idx == head_o) begin
                    // IF   It is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if (lsq_array_i[entry_idx].retire == 1'b1) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                // ELSE Other valid entries (between [head_o] and [C_LSQ_ENTRY_NUM-1])
                end else if (entry_idx > head_o) begin
                    // IF   the previous one is not a STORE
                    // AND  the previous one is selected to retire from LSQ
                    // AND  this entry is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if ((lsq_array_i[entry_idx-1].cmd != BUS_STORE)
                    && (rt_sel_o[entry_idx-1] == 1'b1)
                    && (lsq_array_i[entry_idx].retire == 1'b1)) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                end 
            end
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                // IF   Pointed to by the head pointer
                if (entry_idx == 0 && tail_o != 0) begin
                    // IF   It is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if (lsq_array_i[C_LSQ_ENTRY_NUM-1].retire == 1'b1) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                // ELSE Other valid entries (between [head_o] and [C_LSQ_ENTRY_NUM-1])
                end else if (entry_idx < tail_o) begin
                    // IF   the previous one is not a STORE
                    // AND  the previous one is selected to retire from LSQ
                    // AND  this entry is retired from ROB
                    // ->   Select this entry to retire from LSQ
                    if ((lsq_array_i[entry_idx-1].cmd != BUS_STORE)
                    && (rt_sel_o[entry_idx-1] == 1'b1)
                    && (lsq_array_i[entry_idx].retire == 1'b1)) begin
                        rt_sel_o[entry_idx] =   1'b1;
                    end
                end 
            end
        end
    end

    // Retire entry number
    always_comb begin
        lsq_rt_num  =   'd0;
        for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            if (rt_sel_o[entry_idx]) begin
                lsq_rt_num  =   lsq_rt_num + 'd1;
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
