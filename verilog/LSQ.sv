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

    input   LSQ_ENTRY   lsq_entry_i,

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
genvar entry_idx;
generate
    
endgenerate

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


// ====================================================================
// Entry Manipulation
// ====================================================================


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
