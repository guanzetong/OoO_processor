/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  template.sv                                         //
//                                                                     //
//  Description :  template                                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module lsq #(
    parameter   C_DP_NUM        =   `DP_NUM;
    parameter   C_DP_NUM_WIDTH  = `DP_NUM_WIDTH;
    parameter   C_ROB_IDX_WIDTH = `ROB_IDX_WIDTH;
    parameter   C_TAG_IDX_WIDTH = `TAG_IDX_WIDTH;
    parameter   C_RT_NUM        = `RT_NUM;
    parameter   C_LSQ_ENTRY_NUM = `LSQ_ENTRY_NUM;
    parameter   C_LSQ_IDX_WIDTH       = $clog2(`LSQ_ENTRY_NUM);
    parameter   C_LSQ_IN_NUM    = `LOAD_NUM + `STORE_NUM;
    parameter   C_LOAD_NUM      = `LOAD_NUM;
) (
    input   logic               clk_i           ,   //  Clock
    input   logic               rst_i           ,   //  Reset
    input   ROB_LSQ                            rob_lsq_i,
    input   DP_LSQ                              dp_lsq_i,
    input   FU_LSQ   [C_LSQ_IN_NUM-1:0]           fu_lsq_i,
    input   BC_FU               bc_lsq_i,
    input   MEM_OUT             cache_lsq_i,
    output  LSQ_DP              lsq_dp_o,
    output  FU_BC    [C_LOAD_NUM]           lsq_bc_o,
    output  MEM_IN              lsq_cache_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0] lsq_entry;
LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0] next_lsq_entry; 
logic   [C_LSQ_IDX_WIDTH-1:0]   head;
logic   [C_LSQ_IDX_WIDTH-1:0]   tail;
logic   [C_LSQ_IDX_WIDTH-1:0]   next_head;
logic   [C_LSQ_IDX_WIDTH-1:0]   next_tail;  
logic   head_rollover;
logic   tail_rollover;
logic   lsq_dp_num;
logic   lsq_rt_num;
logic avail_num;
logic   [C_LSQ_ENTRY_NUM-1:0]   dp_sel;

LSQ_STATE cstate, nstate;


// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   sub_module_name
// Description  :   sub module function
// --------------------------------------------------------------------


// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Head and Tail pointer
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head <= `SD 'd0;
            tail <= `SD 'd0;
            head_rollover <= `SD 'd0;
            tail_rollover <= `SD 'd0;
        end else begin
            head <= `SD next_head;
            tail <= `SD next_tail;
            if (head + lsq_rt_num >= C_LSQ_ENTRY_NUM) begin
                head_rollover <= `SD ~head_rollover;
            end
            if (tail + lsq_dp_num >= C_LSQ_ENTRY_NUM) begin
                tail_rollover <= `SD ~tail_rollover;
            end
        end
    end


    always_comb begin
        if (head + lsq_rt_num >= C_LSQ_ENTRY_NUM) begin
            next_head = head + lsq_rt_num - C_LSQ_ENTRY_NUM;
        end else begin
            next_head = head + lsq_rt_num;
        end
        if (tail + lsq_dp_num >= C_LSQ_ENTRY_NUM) begin
            next_tail = tail + lsq_dp_num - C_LSQ_ENTRY_NUM;
        end else begin
            next_tail = tail + lsq_dp_num;
        end
    end

    // avail entry num update logic
    always_comb begin
        if (head_rollover == tail_rollover) begin
            avail_num = C_LSQ_ENTRY_NUM - (tail - head) + lsq_rt_num;
        end else begin
            avail_num = head - tail + lsq_rt_num;
        end

        if (avail_num > C_DP_NUM) begin
            lsq_dp_o.avail_num = C_DP_NUM;
        end else begin
            lsq_dp_o.avail_num = avail_num;
        end
    end

// ====================================================================
// STORE/LOAD Dispatch
// ====================================================================

    always_comb begin
        lsq_dp_num = dp_lsq_i.dp_num;

        if (tail + dp_num >= C_LSQ_ENTRY_NUM) begin
            for (int entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail) || (entry_idx < ((tail + lsq_dp_num) - C_LSQ_ENTRY_NUM))) begin
                    dp_sel[entry_idx]   =   1'b1;
                end
            end
        end else begin
            for (int entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if ((entry_idx >= tail) && (entry_idx < tail + lsq_dp_num)) begin
                    dp_sel[entry_idx]   =   1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk_i) begin
        for (int entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            // Reset
            if (rst_i) begin 
                lsq_entry <= `SD 'd0;
            // Dispatch
            end else if (dp_sel[entry_idx]) begin
                if (entry_idx < tail) begin
                    lsq_entry[entry_idx].valid      <=  `SD 1'b1                                                ;
                    lsq_entry[entry_idx].cmd        <=  `SD dp_lsq_i.cmd     [entry_idx+C_LSQ_ENTRY_NUM-tail]   ;
                    lsq_entry[entry_idx].pc         <=  `SD dp_lsq_i.pc      [entry_idx+C_LSQ_ENTRY_NUM-tail]   ;
                    lsq_entry[entry_idx].tag        <=  `SD dp_lsq_i.tag     [entry_idx+C_LSQ_ENTRY_NUM-tail]   ;
                    lsq_entry[entry_idx].rob_idx    <=  `SD dp_lsq_i.rob_idx [entry_idx+C_LSQ_ENTRY_NUM-tail]   ;
                    lsq_entry[entry_idx].mem_size   <=  `SD dp_lsq_i.mem_size[entry_idx+C_LSQ_ENTRY_NUM-tail]   ;
                end else begin
                    lsq_entry[entry_idx].valid      <=  `SD 1'b1                             ;
                    lsq_entry[entry_idx].cmd        <=  `SD dp_lsq_i.cmd     [entry_idx-tail];
                    lsq_entry[entry_idx].pc         <=  `SD dp_lsq_i.pc      [entry_idx-tail];
                    lsq_entry[entry_idx].tag        <=  `SD dp_lsq_i.tag     [entry_idx-tail];
                    lsq_entry[entry_idx].rob_idx    <=  `SD dp_lsq_i.rob_idx [entry_idx-tail];
                    lsq_entry[entry_idx].mem_size   <=  `SD dp_lsq_i.mem_size[entry_idx-tail];
                end
            // Address Calculation Complete
            end else if ((lsq_entry[entry_idx].valid == 1'b1) && (lsq_entry[entry_idx].addr_valid == 1'b0)) begin
                for (int unsigned in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                    if ((lsq_entry[entry_idx].rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid) begin
                        if (lsq_entry[entry_idx].cmd == BUS_STORE) begin
                            lsq_entry[entry_idx].data_valid <=  `SD 1'b1                    ;
                            lsq_entry[entry_idx].data       <=  `SD fu_lsq_i[in_idx].data   ;
                            lsq_entry[entry_idx].complete   <=  `SD 1'b1                    ;
                            lsq_entry[entry_idx].addr_valid <=  `SD 1'b1                    ;
                            lsq_entry[entry_idx].addr       <=  `SD fu_lsq_i[in_idx].addr   ;
                        end else begin
                            lsq_entry[entry_idx].addr_valid <=  `SD 1'b1                    ;
                            lsq_entry[entry_idx].addr       <=  `SD fu_lsq_i[in_idx].addr   ;
                        end
                    end
                end
            // Data Load Complete
            end else if ((lsq_entry[entry_idx].cmd == BUS_LOAD) && (lsq_entry[entry_idx].addr_valid == 1'b1)) begin

            // Store 
            end else if ((lsq_entry[entry_idx].cmd == BUS_STORE) && (lsq_entry[entry_idx].addr_valid == 1'b1)) begin

            end
        end
    end

// ====================================================================
// STORE/LOAD Complete
// ====================================================================

LSQ_IN_NUM = LOAD_NUM + STORE_NUM fu_lsq
LOAD_NUM fu_bc_o
    // store complete
    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            for (int unsigned in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                if ((lsq_entry[entry_idx].rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid) begin
                    lsq_entry[entry_idx].data_valid <=  `SD fu_lsq_i[in_idx].valid  ;
                    lsq_entry[entry_idx].addr_valid <=  `SD fu_lsq_i.valid  ;
                    lsq_entry[entry_idx].data       <=  `SD fu_lsq_i.data   ;
                    lsq_entry[entry_idx].addr       <=  `SD fu_lsq_i.addr   ;
                end
            end
        end
    end

// load complete state transition logic
always_comb begin
    next_load_complete_state = IDLE;
    case(load_complete_state)
        IDLE: if (conditions) begin
            
        end
        default:
    endcase
end



always_ff @(posedge clk_i) begin
    if (rst_i) begin
        cstate  <=  `SD ST_IDLE;
    end else begin
        cstate  <=  `SD nstate;
    end
end

always_comb begin
    nstate  =   cstate;
    case (cstate)
        ST_IDLE     :   begin
            if (dp_sel) begin
                
            end
        end
        ST_ADDR     :   begin

        end
        ST_DEPEND   :   begin

        end
        ST_RD_MEM   :   begin

        end
        ST_LOAD_CP  :   begin

        end
        ST_RETIRE   :   begin

        end
        ST_WR_MEM   :   begin

        end
        default: 
    endcase    
end

// ====================================================================
// Entry Manipulation
// ====================================================================


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
