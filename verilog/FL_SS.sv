/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  FL_SS.sv                                            //
//                                                                     //
//  Description :  Freelist that support N-way superscalar             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module FL_SS #(
    parameter   C_FL_ENTRY_NUM  =   `FL_ENTRY_NUM       ,
    parameter   C_DP_NUM        =   `DP_NUM             ,
    parameter   C_RT_NUM        =   `RT_NUM             ,
    parameter   C_ARCH_REG_NUM  =   `ARCH_REG_NUM       ,
    parameter   C_PHY_REG_NUM   =   `PHY_REG_NUM        ,
    parameter   C_TAG_IDX_WIDTH =   `TAG_IDX_WIDTH      
) (
    input   logic               clk_i           ,   //  Clock
    input   logic               rst_i           ,   //  Reset
    input   logic               rollback_i      ,  
    input   DP_FL               dp_fl_i         ,
    input   ROB_FL              rob_fl_i        ,
    input   FL_ENTRY            vfl_fl_i        ,
    output  FL_DP               fl_dp_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_FL_IDX_WIDTH  =   $clog2(C_FL_ENTRY_NUM);
    localparam  C_FL_NUM_WIDTH  =   $clog2(C_FL_ENTRY_NUM+1);

    localparam  C_RT_NUM_WIDTH  =   $clog2(C_RT_NUM+1);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    FL_ENTRY    [C_FL_ENTRY_NUM-1:0]            fl_entry            ;   // Freelist entry
    FL_ENTRY    [C_FL_ENTRY_NUM-1:0]            next_fl_entry       ;   // Next state of freelist entry
    
    // logic       [C_FL_IDX-1:0]            fl_rollback_idx;
    
    logic       [C_FL_IDX_WIDTH-1:0]            head                ;
    logic       [C_FL_IDX_WIDTH-1:0]            tail                ;   
    logic       [C_FL_IDX_WIDTH-1:0]            next_head           ;
    logic       [C_FL_IDX_WIDTH-1:0]            next_tail           ;  
    logic                                       head_rollover       ;   // check head/tail at same page
    logic                                       tail_rollover       ;   

    logic       [C_FL_NUM_WIDTH-1:0]            avail_num           ;   // 0 ~ C_FL_ENTRY_NUM

    logic       [C_RT_NUM_WIDTH-1:0]            rt_num              ;

    logic       [C_RT_NUM-1:0][C_RT_NUM-1:0]    rt_route            ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Push-in Router
// --------------------------------------------------------------------
    function automatic logic [C_RT_NUM-1:0][C_RT_NUM-1:0] route;
        input   ROB_FL  rob_fl_i;
        int     out_idx  ;
        begin
            out_idx =   0;
            route   =   0;
            for (int in_idx = 0; in_idx < C_RT_NUM; in_idx++) begin
                if ((in_idx < rob_fl_i.rt_num) && (rob_fl_i.tag[in_idx] != 'd0)) begin
                    route[out_idx][in_idx]  =   1'b1    ;
                    out_idx++;
                end
            end
        end
    endfunction

// --------------------------------------------------------------------
// Head & Tail pointers
// --------------------------------------------------------------------
    // Update pointers
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head            <=  `SD 'd0;
            tail            <=  `SD 'd0;
        end else if (rollback_i) begin
            head            <=  `SD 'd0;
            tail            <=  `SD 'd0;
        end else begin
            head            <=  `SD next_head;
            tail            <=  `SD next_tail;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head_rollover   <=  `SD 'd0;
            tail_rollover   <=  `SD 'd1;
        end else if (rollback_i) begin
            head_rollover   <=  `SD 'd0;
            tail_rollover   <=  `SD 'd1;
        end else begin
            if (head + dp_fl_i.dp_num >= C_FL_ENTRY_NUM) begin
                head_rollover   <=  `SD ~head_rollover;
            end
            if (tail + rob_fl_i.rt_num >= C_FL_ENTRY_NUM) begin
                tail_rollover   <=  `SD ~tail_rollover;
            end
        end
    end

    always_comb begin
        next_head   =   head + dp_fl_i.dp_num;

        rt_num  =   rob_fl_i.rt_num;
        for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
            if (rob_fl_i.tag[rt_idx] == 'd0) begin
                rt_num = rt_num - 'd1;
            end
        end
        next_tail   =   tail + rt_num;
    end

    always_comb begin
        if (head_rollover == tail_rollover) begin
            avail_num   =   tail - head;
        end else begin
            avail_num   =   tail + C_FL_ENTRY_NUM - head;
        end

        if (avail_num > C_DP_NUM) begin
            fl_dp_o.avail_num   =   C_DP_NUM;
        end else begin
            fl_dp_o.avail_num   =   avail_num;
        end
    end

// --------------------------------------------------------------------
// Dispatch tags allocation
// --------------------------------------------------------------------
    always_comb begin
        for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            if (head + dp_idx >= C_FL_ENTRY_NUM) begin
                fl_dp_o.tag[dp_idx] =   fl_entry[head + dp_idx - C_FL_ENTRY_NUM];
            end else begin
                fl_dp_o.tag[dp_idx] =   fl_entry[head + dp_idx];
            end
        end
    end

// --------------------------------------------------------------------
// Retire tags push-in
// --------------------------------------------------------------------
    always_comb begin
        next_fl_entry   =   fl_entry;
        rt_route        =   route(rob_fl_i);
        for (int unsigned in_idx = 0; in_idx < C_RT_NUM; in_idx++) begin
            for (int unsigned out_idx = 0; out_idx < C_RT_NUM; out_idx++) begin
                if (rt_route[out_idx][in_idx] == 1'b1) begin
                    if (tail + out_idx >= C_FL_ENTRY_NUM) begin
                        next_fl_entry[tail + out_idx - C_FL_ENTRY_NUM]  =   rob_fl_i.tag[in_idx];
                    end else begin
                        next_fl_entry[tail + out_idx]   =   rob_fl_i.tag[in_idx];
                    end
                end
            end
        end
    end

    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin 
            if (rst_i) begin 
                fl_entry[entry_idx].tag <=  `SD entry_idx + C_ARCH_REG_NUM; // initial with [32:63] preg tag
            end else if (rollback_i) begin 
                fl_entry[entry_idx]     <=  `SD vfl_fl_i[entry_idx];
            end else begin 
                fl_entry[entry_idx]     <=  `SD next_fl_entry[entry_idx];
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
