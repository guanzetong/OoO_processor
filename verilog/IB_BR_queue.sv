/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB_BR_queue.sv                                      //
//                                                                     //
//  Description :  Instruction Queue inside Issue Buffer. The depth    // 
//                 is configurable.                                    //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB_BR_queue #(
    parameter   C_SIZE      =   `BR_Q_SIZE      ,
    parameter   C_IN_NUM    =   `IS_NUM         ,
    parameter   C_OUT_NUM   =   `BR_NUM         ,
    parameter   C_IDX_WIDTH =   $clog2(C_SIZE)
) (
    // For Testing
`ifdef DEBUG
    output  IS_INST [C_SIZE-1:0]        queue_mon_o     ,
    output  logic   [C_SIZE-1:0]        valid_mon_o     ,
    output  logic   [C_IDX_WIDTH-1:0]   head_mon_o      ,
    output  logic   [C_IDX_WIDTH-1:0]   tail_mon_o      ,
`endif
    input   logic                       clk_i           ,   // Clock
    input   logic                       rst_i           ,   // Reset
    // Push-In
    input   logic   [C_IN_NUM-1:0]      s_valid_i       ,   // Push-in Valid
    output  logic   [C_IN_NUM-1:0]      s_ready_o       ,   // Push-in Ready
    input   IS_INST [C_IN_NUM-1:0]      s_data_i        ,   // Push-in Data
    // Pop-Out
    output  logic   [C_OUT_NUM-1:0]     m_valid_o       ,   // Pop-out Valid
    input   logic   [C_OUT_NUM-1:0]     m_ready_i       ,   // Pop-out Ready
    output  IS_INST [C_OUT_NUM-1:0]     m_data_o        ,   // Pop-out Data
    // Flush
    input   BR_MIS                      br_mis_i        ,   // Branch Misprediction
    input   logic                       exception_i         // External Exception
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    // localparam  C_IDX_WIDTH =   $clog2(C_SIZE);
    localparam  C_NUM_WIDTH     =   $clog2(C_SIZE+1);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_IDX_WIDTH-1:0]                   head            ;
    logic   [C_IDX_WIDTH-1:0]                   tail            ;
    logic                                       head_rollover   ;
    logic                                       tail_rollover   ;

    logic   [C_IDX_WIDTH-1:0]                   next_head       ;
    logic   [C_IDX_WIDTH-1:0]                   next_tail       ;
    logic   [C_NUM_WIDTH-1:0]                   push_in_num     ;
    logic   [C_NUM_WIDTH-1:0]                   pop_out_num     ;

    IS_INST [C_SIZE-1:0]                        queue           ;
    logic   [C_SIZE-1:0]                        valid           ;

    logic   [C_NUM_WIDTH-1:0]                   data_num        ;
    logic   [C_NUM_WIDTH-1:0]                   empty_num       ;

    logic   [C_IN_NUM-1:0]                      push_in_en      ;
    logic   [C_SIZE-1:0]                        push_in_sel     ;
    IS_INST [C_SIZE-1:0]                        push_in_switch  ;
    logic   [C_OUT_NUM-1:0]                     pop_out_en      ;
    logic   [C_SIZE-1:0]                        pop_out_sel     ;
    logic   [C_OUT_NUM-1:0]                     squash_flag     ;

    logic   [C_IN_NUM-1:0][C_IDX_WIDTH-1:0]     push_in_idx     ;
    logic   [C_OUT_NUM-1:0][C_IDX_WIDTH-1:0]    pop_out_idx     ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Push-in & Pop-out handshake
// --------------------------------------------------------------------
    assign  push_in_en  =   s_valid_i & s_ready_o;
    assign  pop_out_en  =   m_valid_o & m_ready_i;

// --------------------------------------------------------------------
// Calculate the number of input and output 
// --------------------------------------------------------------------
    always_comb begin
        push_in_num =   0;
        for (int unsigned in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
            if (push_in_en[in_idx]) begin
                push_in_num =   push_in_num + 'd1;
            end
        end
    end

    always_comb begin
        pop_out_num =   0;
        for (int unsigned out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
            if (pop_out_en[out_idx] || squash_flag[out_idx]) begin
                pop_out_num =   pop_out_num + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// Pointer movement
// --------------------------------------------------------------------
    // Pointer sequential
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head    <=  `SD 'd0;
            tail    <=  `SD 'd0;
        end else if (exception_i) begin
            head    <=  `SD 'd0;
            tail    <=  `SD 'd0;
        end else begin
            head    <=  `SD next_head;
            tail    <=  `SD next_tail;
        end
    end

    // Next state of pointers
    always_comb begin
        if (head + pop_out_num >= C_SIZE) begin
            next_head   =   head + pop_out_num - C_SIZE;
        end else begin
            next_head   =   head + pop_out_num;
        end
        
        if (tail + push_in_num >= C_SIZE) begin
            next_tail   =   tail + push_in_num - C_SIZE;
        end else begin
            next_tail   =   tail + push_in_num;
        end
    end

    // Pointer rollover states
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else if (exception_i) begin
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else begin
            if (head + pop_out_num >= C_SIZE) begin
                head_rollover   <=  `SD ~head_rollover;
            end
            if (tail + push_in_num >= C_SIZE) begin
                tail_rollover   <=  `SD ~tail_rollover;
            end
        end
    end

// --------------------------------------------------------------------
// Number of Empty entries and Data entries
// --------------------------------------------------------------------
    always_comb begin
        if (head_rollover == tail_rollover) begin
            empty_num   =   C_SIZE - (tail - head) + pop_out_num;
            data_num    =   tail - head;
        end else begin
            empty_num   =   head - tail + pop_out_num;
            data_num    =   C_SIZE - (head - tail);
        end
    end

// --------------------------------------------------------------------
// Push-in Entry
// --------------------------------------------------------------------
    always_comb begin
        push_in_switch  =   0;
        for (int unsigned in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
            // Push-in Ready
            if (in_idx < empty_num) begin
                s_ready_o[in_idx]   =   1'b1;
            end else begin
                s_ready_o[in_idx]   =   1'b0;
            end

            // Push-in Data
            //  Derive the entry indexes to be pushed-in
            if (in_idx + tail >= C_SIZE) begin
                push_in_idx[in_idx] =   in_idx + tail - C_SIZE;
            end else begin
                push_in_idx[in_idx] =   in_idx + tail;
            end
            //  Route the input to update the entry contents
            push_in_switch[push_in_idx[in_idx]] =   s_data_i[in_idx];
        end

        // Select the entries to push-in
        push_in_sel =   (push_in_en << tail) | (push_in_en >> (C_SIZE - tail));
    end

// --------------------------------------------------------------------
// Pop-out Entry
// --------------------------------------------------------------------
    always_comb begin
        for (int unsigned out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
            // Pop-out Data
            //  Derive the entry indexes to be popped-out
            if (out_idx + head >= C_SIZE) begin
                pop_out_idx[out_idx] =   out_idx + head - C_SIZE;
            end else begin
                pop_out_idx[out_idx] =   out_idx + head;
            end
            //  Route the entry content to the output
            m_data_o[out_idx]   =   queue[pop_out_idx[out_idx]];

            // Pop-out Valid
            // If the pop-out channel is within head and tail pointers
            if (out_idx < data_num) begin
                // If the instruction is not squashed
                // -> Pop-out valid asserted
                if ((valid[pop_out_idx[out_idx]] == 1'b1)
                && (br_mis_i.valid[queue[pop_out_idx[out_idx]].thread_idx] == 1'b0)) begin
                    m_valid_o[out_idx]      =   1'b1;
                    squash_flag[out_idx]    =   1'b0;
                // Else, the instruction is squashed
                end else begin
                    // If it is the first to pop-out
                    // -> Pop-out valid deasserted, and squash flag asserted
                    if (out_idx == 0) begin
                        m_valid_o[out_idx]      =   1'b0;
                        squash_flag[out_idx]    =   1'b1;
                    // Else
                    // the entry is ready to pop-out if the previous instructions
                    // are all ready to pop-out or squashed
                    end else begin
                        m_valid_o[out_idx]      =   1'b0;
                        squash_flag[out_idx]    =   pop_out_en[out_idx-1] || squash_flag[out_idx-1];
                    end
                end
            end else begin
                m_valid_o[out_idx]      =   1'b0;
                squash_flag[out_idx]    =   1'b0;
            end
        end
        pop_out_sel =   (pop_out_en << head) | (pop_out_en >> (C_SIZE - head))
                    | (squash_flag << head) | (squash_flag >> (C_SIZE - head));
    end

// --------------------------------------------------------------------
// Queue Entry
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_SIZE; entry_idx++) begin
            // Reset
            if (rst_i) begin
                valid[entry_idx]   <=  `SD 1'b0;
                queue[entry_idx]   <=  `SD 'b0;
            // External Exception
            end else if (exception_i) begin
                valid[entry_idx]   <=  `SD 1'b0;
                queue[entry_idx]   <=  `SD 'b0;
            // Push-in the entry (including Pop-up at the same time)
            end else if (push_in_sel[entry_idx]) begin
                valid[entry_idx]    <=  `SD 1'b1;
                queue[entry_idx]    <=  `SD push_in_switch[entry_idx];
            // Only Pop-out the entry -> Clear it
            end else if (pop_out_sel[entry_idx]) begin
                valid[entry_idx]    <=  `SD 1'b0;
                queue[entry_idx]    <=  `SD 'b0;
            // Branch Misprediction of a thread -> Empty the entry
            end else if (valid[entry_idx] && br_mis_i.valid[queue[entry_idx].thread_idx]) begin
                valid[entry_idx]    <=  `SD 1'b0;
                queue[entry_idx]    <=  `SD queue[entry_idx];
            // Otherwise -> Latch
            end else begin
                valid[entry_idx]    <=  `SD valid[entry_idx];
                queue[entry_idx]    <=  `SD queue[entry_idx];
            end
        end
    end

// --------------------------------------------------------------------
// Queue Entry
// --------------------------------------------------------------------
`ifdef DEBUG
    assign  queue_mon_o =   queue   ;
    assign  valid_mon_o =   valid   ;
    assign  head_mon_o  =   head    ;
    assign  tail_mon_o  =   tail    ;
`endif

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
