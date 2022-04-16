/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_fsm.sv                                          //
//                                                                     //
//  Description :  LSQ_fsm                                             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_entry_control # (
    parameter   C_LSQ_ENTRY_NUM =   `LSQ_ENTRY_NUM;
    parameter   C_LSQ_IDX_WIDTH =   $clog2(C_LSQ_ENTRY_NUM);
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   logic       [C_LSQ_IDX_WIDTH-1:0]   lsq_idx_i       ,   //  Entry index of this entry
    input   logic       [C_LSQ_IDX_WIDTH-1:0]   head_i          ,
    input   logic       [C_LSQ_IDX_WIDTH-1:0]   tail_i          ,
    input   LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0]   lsq_array_i     ,
    input   logic                               dp_sel_i        ,   //  Dispatch select
    input   DP_LSQ                              dp_lsq_i        ,
    input   FU_LSQ      [C_LSQ_IN_NUM-1:0]      fu_lsq_i        ,
    output  MEM_IN                              lsq_entry_mem_o ,
    input   MEM_OUT                             mem_lsq_i       ,
    input   logic                               mem_grant_i     ,
    input   BC_FU                               bc_lsq_entry_i  ,
    input   ROB_LSQ                             rob_lsq_i       ,
    output  LSQ_ENTRY                           lsq_entry_o         //  The contents of this entry
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
    LSQ_ENTRY                           next_lsq_entry      ;
    logic                               depend_flag         ;
    logic       [C_LSQ_IDX_WIDTH-1:0]   depend_idx          ;
    logic       [C_LSQ_ENTRY_NUM-1:0]   store_check         ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Entry contents update
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            lsq_entry_o.state       <=  `SD ST_IDLE     ;
            lsq_entry_o.cmd         <=  `SD BUS_NONE    ;
            lsq_entry_o.pc          <=  `SD 'd0         ;
            lsq_entry_o.tag         <=  `SD 'd0         ;
            lsq_entry_o.rob_idx     <=  `SD 'd0         ;
            lsq_entry_o.mem_size    <=  `SD BYTE        ;
            lsq_entry_o.addr        <=  `SD 'd0         ;
            lsq_entry_o.addr_valid  <=  `SD 1'b0        ;
            lsq_entry_o.data        <=  `SD 'b0         ;
            lsq_entry_o.data_valid  <=  `SD 1'b0        ;
            lsq_entry_o.retire      <=  `SD 1'b0        ;
            lsq_entry_o.mem_tag     <=  `SD 'd0         ;
        end else begin
            lsq_entry_o <=  `SD next_lsq_entry;
        end
    end

    always_comb begin
        nstate  =   cstate;
        case (cstate)
            // Idle state, this entry is available for new LOAD/STORE
            ST_IDLE     :   begin
                // IF   this entry is selected to be allocated
                // ->   Go to ST_ADDR to wait for the result of address calculation
                if (dp_sel_i) begin
                    next_lsq_entry.state    =   ST_ADDR;
                    if (lsq_idx_i < tail_i) begin
                        next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                    end else begin
                        next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i-tail_i] ;
                        next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i-tail_i] ;
                        next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i-tail_i] ;
                        next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i-tail_i] ;
                        next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i-tail_i] ;
                    end
                end
            end
            // Wait for LOAD/STORE address from FU
            ST_ADDR     :   begin
                // LOAD
                if (lsq_entry_o.cmd == BUS_LOAD) begin
                    // Loop over all the LOAD/STORE FU output
                    for (int in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                        // IF   the rob_idx of FU output matches the rob_idx of the entry
                        if ((lsq_entry_o.rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid) begin
                            // IF   All the older STORE addresses are known and there is no dependency
                            // ->   Go to ST_RD_MEM to read from memory
                            if ((older_store_known == 1'b1) && (depend_flag == 1'b0)) begin
                                next_lsq_entry.state    =   ST_RD_MEM   ;
                            // ELSE Any older STORE addresses unknown or there is a dependency
                            // ->   Go to ST_DEPEND to wait for dependency resolution
                            end else begin
                                next_lsq_entry.state    =   ST_DEPEND   ;
                            end
                            next_lsq_entry.addr_valid   =   1'b1                    ;
                            next_lsq_entry.addr         =   fu_lsq_i[in_idx].addr   ;
                        end
                    end
                // STORE
                end else begin
                    // Loop over all the LOAD/STORE FU output
                    for (int in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                        // IF   the rob_idx of FU output matches the rob_idx of the entry
                        // ->   Go to ST_RETIRE to wait for retire
                        if ((lsq_entry_o.rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid) begin
                            next_lsq_entry.state        =   ST_RETIRE               ;
                            next_lsq_entry.data_valid   =   1'b1                    ;
                            next_lsq_entry.data         =   fu_lsq_i[in_idx].data   ;
                            next_lsq_entry.addr_valid   =   1'b1                    ;
                            next_lsq_entry.addr         =   fu_lsq_i[in_idx].addr   ;
                        end
                    end
                end
            end
            // Check and Wait for depenency resolution (This state is only for LOAD instructions):
            // 1. Check if all older STORE address are known.
            // 2. Check if any older STORE write to the same address with same mem_size
            ST_DEPEND   :   begin
                // IF   All the older STORE addresses are known
                if (older_store_known == 1'b1) begin
                    // IF   There is no dependency
                    // ->   Go to ST_RD_MEM to read from memory
                    if (depend_flag == 1'b0) begin
                        next_lsq_entry.state    =   ST_RD_MEM   ;
                    // ELSE there is a dependency on older STORE
                    // ->   Go to ST_LOAD_CP to complete LOAD instruction
                    // ->   Forward the nearest older STORE data
                    end else begin
                        next_lsq_entry.state        =   ST_LOAD_CP                  ;
                        next_lsq_entry.data         =   lsq_array_i[depend_idx].data;
                        next_lsq_entry.data_valid   =   1'b1                        ;
                    end
                end
            end
            // Send read request to memory/cache and wait for response
            ST_RD_MEM   :   begin
                // IF   The memory interface is granted to this entry 
                // AND  The request is confirmed by memory
                if ((mem_grant_i == 1'b1) && (mem_lsq_i.response != 'd0)) begin
                    // IF   Long Memory Latency or Cache miss
                    // ->   Go to ST_WAIT_MEM
                    if (mem_lsq_i.tag != mem_lsq_i.response) begin
                        next_lsq_entry.state        =   ST_WAIT_MEM         ;
                        next_lsq_entry.mem_tag      =   mem_lsq_i.response  ;
                    // ELSE Cache hit
                    // ->   Go to ST_RETIRE
                    end else begin
                        next_lsq_entry.state        =   ST_LOAD_CP      ;
                        next_lsq_entry.data_valid   =   1'b1            ;
                        next_lsq_entry.data         =   mem_lsq_i.data  ;
                    end
                end
            end
            // Wait for memory/cache to return the data
            ST_WAIT_MEM :   begin
                // IF   The memory return tag matches the mem_tag of this entry
                // ->   The data returned from memory is for this entry
                if (mem_lsq_i.tag == next_lsq_entry.mem_tag) begin
                    next_lsq_entry.state        =   ST_LOAD_CP      ;
                    next_lsq_entry.data_valid   =   1'b1            ;
                    next_lsq_entry.data         =   mem_lsq_i.data  ;
                end
            end
            // Complete the LOAD, request CDB
            ST_LOAD_CP  :   begin
                if (bc_lsq_entry_i.broadcasted == 1'b1) begin
                    next_lsq_entry.state    =   ST_RETIRE   ;
                end
            end
            // Wait for ROB to retire the LOAD/STORE.
            ST_RETIRE   :   begin
                // Loop over all the Retire channels
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                    // IF   the retire channel is valid
                    // AND  the rob_idx retired matches the rob_idx of this entry
                    // ->   Assert the retire bit of this entry
                    //      and wait to be selected to retire from LSQ
                    if ((rt_idx < rob_lsq_i.rt_num) 
                    && (rob_lsq_i.rob_idx[rt_idx] == lsq_entry_o.rob_idx)) begin
                        next_lsq_entry.retire   =   1'b1;
                    end
                end

                // IF   Selected to retire from LSQ
                if (rt_sel_i) begin
                    // IF   LOAD
                    // ->   Clear the entry and go back to ST_IDLE
                    if (lsq_entry_o.cmd == BUS_LOAD) begin
                        next_lsq_entry.state        =   ST_IDLE     ;
                        next_lsq_entry.cmd          =   BUS_NONE    ;
                        next_lsq_entry.pc           =   'd0         ;
                        next_lsq_entry.tag          =   'd0         ;
                        next_lsq_entry.rob_idx      =   'd0         ;
                        next_lsq_entry.mem_size     =   BYTE        ;
                        next_lsq_entry.addr         =   'd0         ;
                        next_lsq_entry.addr_valid   =   1'b0        ;
                        next_lsq_entry.data         =   'b0         ;
                        next_lsq_entry.data_valid   =   1'b0        ;
                        next_lsq_entry.retire       =   1'b0        ;
                        next_lsq_entry.mem_tag      =   'd0         ;
                    // IF   STORE
                    // ->   Go to ST_WR_MEM to write the data to memory/cache
                    end else begin
                        next_lsq_entry.state    =   ST_WR_MEM;
                    end
                end
            end
            // Send write request to memory/cache and wait for response
            ST_WR_MEM   :   begin
                // IF   The write request is confirmed by memory/cache
                // ->   Clear the entry and go back to ST_IDLE
                if (mem_lsq_i.response != 'd0) begin
                    next_lsq_entry.state        =   ST_IDLE     ;
                    next_lsq_entry.cmd          =   BUS_NONE    ;
                    next_lsq_entry.pc           =   'd0         ;
                    next_lsq_entry.tag          =   'd0         ;
                    next_lsq_entry.rob_idx      =   'd0         ;
                    next_lsq_entry.mem_size     =   BYTE        ;
                    next_lsq_entry.addr         =   'd0         ;
                    next_lsq_entry.addr_valid   =   1'b0        ;
                    next_lsq_entry.data         =   'b0         ;
                    next_lsq_entry.data_valid   =   1'b0        ;
                    next_lsq_entry.retire       =   1'b0        ;
                    next_lsq_entry.mem_tag      =   'd0         ;
                end
            end
            default: 
        endcase    
    end

// --------------------------------------------------------------------
// Check dependency
// --------------------------------------------------------------------

    // Generate per-entry STORE address valid signal
    // If it is a LOAD, bypass
    always_comb begin
        store_check =   'b0;
        // Loop over the entries
        for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            // IF   the entry is STORE and the address is known
            // ->   Assert the bit to indicate a positive check
            if (lsq_array_i[entry_idx].cmd == BUS_STORE  && lsq_array_i[entry_idx].addr_valid) begin
                store_check[entry_idx]  =   1'b1;
            // ELSE the entry is LOAD
            // ->   Assert the bit to bypass this entry
            end else if (lsq_array_i[entry_idx].cmd == BUS_LOAD) begin
                store_check[entry_idx]  =   1'b0;
            end
        end
    end

    // Check older STORE address validity
    // and dependency
    always_comb begin
        older_store_known   =   1'b1    ;
        depend_flag         =   1'b0    ;
        depend_idx          =   'd0     ;
        // IF   there is no rollover in the queue
        if (lsq_idx_i > head_i) begin
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                // Only check the entries between the head pointer and this entry
                if ((entry_idx >= head_i) && (entry_idx < lsq_idx_i)) begin
                    // IF   any store_check bit is 0
                    // ->   Not all the older STORE addresses are known
                    if (store_check[entry_idx] == 1'b0) begin
                        older_store_known   =   1'b0;
                    end

                    // IF   the address and mem_size of a older store matches
                    //      this entry
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr == lsq_array_i[entry_idx].addr)
                    && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                    end
                end
            end
        // ELSE there is a rollover in the queue (head_i > lsq_idx_i)
        end else begin
            // Should start checking from [head_i] to [C_LSQ_ENTRY_NUM-1],
            // rollover back to [0], and then continue checking to [lsq_idx_i-1]

            // For older STORE address validity check, the sequence of checking doesn't matter
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                // Only check the entries between the head pointer and this entry
                // Check older STORES
                if ((entry_idx >= head_i) || (entry_idx < lsq_idx_i)) begin
                    // IF   any store_check bit is 0
                    // ->   Not all the older STORE addresses are known
                    if (store_check[entry_idx] == 1'b0) begin
                        older_store_known   =   1'b0;
                    end
                end
            end

            // For dependency check, the sequence of checking matters!!!
            // 1. Check entry from [head_i] to [C_LSQ_ENTRY_NUM-1]
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if (entry_idx >= head_i) begin
                    // IF   the address and mem_size of a older store matches
                    //      this entry
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr == lsq_array_i[entry_idx].addr)
                    && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                    end
                end
            end

            // 2. Check entry from [0] to [lsq_idx_i-1]
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if (entry_idx < lsq_idx_i) begin
                    // IF   the address and mem_size of a older store matches
                    //      this entry
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr == lsq_array_i[entry_idx].addr)
                    && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                    end
                end
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
