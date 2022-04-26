/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_entry_ctrl.sv                                   //
//                                                                     //
//  Description :  LSQ entry controller                                // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_entry_ctrl # (
    parameter   C_XLEN              =   `XLEN                   ,
    parameter   C_RT_NUM            =   `RT_NUM                 ,
    parameter   C_THREAD_NUM        =   `THREAD_NUM             ,
    parameter   C_LSQ_ENTRY_NUM     =   `LSQ_ENTRY_NUM          ,
    parameter   C_LOAD_NUM          =   `LOAD_NUM               ,
    parameter   C_STORE_NUM         =   `STORE_NUM              ,
    parameter   C_LSQ_IN_NUM        =   C_LOAD_NUM + C_STORE_NUM,
    parameter   C_THREAD_IDX_WIDTH  =   $clog2(C_THREAD_NUM)    ,
    parameter   C_LSQ_IDX_WIDTH     =   $clog2(C_LSQ_ENTRY_NUM) 
) (
    input   logic                                   clk_i           ,   //  Clock
    input   logic                                   rst_i           ,   //  Reset
    input   logic       [C_LSQ_IDX_WIDTH-1:0]       lsq_idx_i       ,   //  Entry index of this entry
    input   logic       [C_THREAD_IDX_WIDTH-1:0]    thread_idx_i    ,   //  Entry index of this entry
    // Global control
    input   LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0]       lsq_array_i     ,
    input   logic       [C_LSQ_IDX_WIDTH-1:0]       head_i          ,
    input   logic       [C_LSQ_IDX_WIDTH-1:0]       tail_i          ,
    input   logic                                   dp_sel_i        ,   //  Dispatch select
    input   logic                                   rt_sel_i        ,   //  Retire(from LSQ) select
    output  logic                                   rob_retire_o    ,
    // Interface with other modules
    input   DP_LSQ                                  dp_lsq_i        ,   //  From Dipatcher
    input   FU_LSQ      [C_LSQ_IN_NUM-1:0]          fu_lsq_i        ,   //  From FU
    output  MEM_IN                                  lsq_entry_mem_o ,   //  To Memory/Cache
    input   MEM_OUT                                 mem_lsq_i       ,   //  From Memory/Cache
    input   logic                                   mem_grant_i     ,   //  Memory interface grant
    output  FU_BC                                   lsq_entry_bc_o  ,   //  To Broadcaster
    input   BC_FU                                   bc_lsq_entry_i  ,   //  From Broadcaster
    input   ROB_LSQ                                 rob_lsq_i       ,   //  From ROB
    input   logic                                   rollback_i      ,
    // Entry contents
    output  LSQ_ENTRY                               lsq_entry_o         //  The contents of this entry
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CHECK_OFFSET  =   $clog2(C_XLEN/8);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    LSQ_ENTRY                           next_lsq_entry      ;
    logic                               forward_flag        ;
    logic                               depend_flag         ;
    logic       [C_LSQ_IDX_WIDTH-1:0]   depend_idx          ;
    logic       [C_LSQ_ENTRY_NUM-1:0]   store_check         ;
    logic                               older_store_known   ;

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
        if (rst_i || rollback_i) begin
            lsq_entry_o.state       <=  `SD LSQ_ST_IDLE ;
            lsq_entry_o.cmd         <=  `SD BUS_NONE    ;
            lsq_entry_o.pc          <=  `SD 'd0         ;
            lsq_entry_o.tag         <=  `SD 'd0         ;
            lsq_entry_o.rob_idx     <=  `SD 'd0         ;
            lsq_entry_o.mem_size    <=  `SD BYTE        ;
            lsq_entry_o.sign        <=  `SD 1'b0        ;
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
        next_lsq_entry  =   lsq_entry_o;
        rob_retire_o    =   1'b0;
        case (lsq_entry_o.state)
            // Idle state, this entry is available for new LOAD/STORE
            LSQ_ST_IDLE     :   begin
                // IF   this entry is selected to be allocated
                // ->   Go to LSQ_ST_ADDR to wait for the result of address calculation
                if (dp_sel_i) begin
                    next_lsq_entry.state    =   LSQ_ST_ADDR;
                    if (lsq_idx_i < tail_i) begin
                        next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        next_lsq_entry.sign     =   dp_lsq_i.sign    [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                    end else begin
                        next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i-tail_i] ;
                        next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i-tail_i] ;
                        next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i-tail_i] ;
                        next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i-tail_i] ;
                        next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i-tail_i] ;
                        next_lsq_entry.sign     =   dp_lsq_i.sign    [lsq_idx_i-tail_i] ;
                    end
                end
            end
            // Wait for LOAD/STORE address from FU
            LSQ_ST_ADDR     :   begin
                // LOAD
                if (lsq_entry_o.cmd == BUS_LOAD) begin
                    // Loop over all the LOAD/STORE FU output
                    for (int in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                        // IF   the rob_idx of FU output matches the rob_idx of the entry
                        if ((lsq_entry_o.rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid
                        && (fu_lsq_i[in_idx].thread_idx == thread_idx_i)) begin
                            next_lsq_entry.addr_valid   =   1'b1                    ;
                            next_lsq_entry.addr         =   fu_lsq_i[in_idx].addr   ;
                        end
                    end
                    
                    if (lsq_entry_o.addr_valid == 1'b1) begin
                        // IF   All the older STORE addresses are known and there is no dependency
                        // ->   Go to LSQ_ST_RD_MEM to read from memory
                        if ((older_store_known == 1'b1) && (depend_flag == 1'b0)) begin
                            next_lsq_entry.state    =   LSQ_ST_RD_MEM   ;
                        // ELSE Any older STORE addresses unknown or there is a dependency
                        // ->   Go to LSQ_ST_DEPEND to wait for dependency resolution
                        end else begin
                            next_lsq_entry.state    =   LSQ_ST_DEPEND   ; 
                        end
                    end
                // STORE
                end else begin
                    // Loop over all the LOAD/STORE FU output
                    for (int in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                        // IF   the rob_idx of FU output matches the rob_idx of the entry
                        // ->   Go to LSQ_ST_ROB_RETIRE to wait for retire
                        if ((lsq_entry_o.rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid
                        && (fu_lsq_i[in_idx].thread_idx == thread_idx_i)) begin
                            next_lsq_entry.state        =   LSQ_ST_ROB_RETIRE       ;
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
            LSQ_ST_DEPEND   :   begin
                // IF   All the older STORE addresses are known
                if (older_store_known == 1'b1) begin
                    // IF   There is no dependency
                    // ->   Go to LSQ_ST_RD_MEM to read from memory
                    if (depend_flag == 1'b0) begin
                        next_lsq_entry.state    =   LSQ_ST_RD_MEM   ;
                    // ELSE there is a dependency on older STORE
                    // AND  Store to load forwarding is legitimate
                    // ->   Go to LSQ_ST_LOAD_CP to complete LOAD instruction
                    // ->   Forward the nearest older STORE data
                    end else if (forward_flag == 1'b1) begin
                        next_lsq_entry.state        =   LSQ_ST_LOAD_CP;
                        next_lsq_entry.data_valid   =   1'b1;
                        // IF   it is a signed LOAD
                        if (lsq_entry_o.sign == 1'b0) begin
                            case (lsq_entry_o.mem_size)
                                BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){lsq_array_i[depend_idx].data[ 8-1]}}, lsq_array_i[depend_idx].data[ 8-1:0]};
                                HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){lsq_array_i[depend_idx].data[16-1]}}, lsq_array_i[depend_idx].data[16-1:0]};
                                default :   next_lsq_entry.data =   lsq_array_i[depend_idx].data;
                            endcase
                        // ELSE it is an unsigned LOAD
                        end else begin
                            case (lsq_entry_o.mem_size)
                                BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){1'b0}}, lsq_array_i[depend_idx].data[ 8-1:0]};
                                HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){1'b0}}, lsq_array_i[depend_idx].data[16-1:0]};
                                default :   next_lsq_entry.data =   lsq_array_i[depend_idx].data;
                            endcase
                        end
                    end
                    // ELSE There is a dependency and no forwarding 
                    // ->   Wait for the dependency to be resolved
                end
            end
            // Send read request to memory/cache and wait for response
            LSQ_ST_RD_MEM   :   begin
                // IF   The memory interface is granted to this entry 
                // AND  The request is confirmed by memory
                if ((mem_grant_i == 1'b1) && (mem_lsq_i.response != 'd0)) begin
                    // IF   Long Memory Latency or Cache miss
                    // ->   Go to LSQ_ST_WAIT_MEM
                    if (mem_lsq_i.tag != mem_lsq_i.response) begin
                        next_lsq_entry.state        =   LSQ_ST_WAIT_MEM     ;
                        next_lsq_entry.mem_tag      =   mem_lsq_i.response  ;
                    // ELSE Cache hit
                    // ->   Go to LSQ_ST_RETIRE
                    end else begin
                        next_lsq_entry.state        =   LSQ_ST_LOAD_CP  ;
                        next_lsq_entry.data_valid   =   1'b1            ;
                        // IF   it is a signed LOAD
                        if (lsq_entry_o.sign == 1'b0) begin
                            case (lsq_entry_o.mem_size)
                                BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){mem_lsq_i.data[ 8-1]}}, mem_lsq_i.data[ 8-1:0]};
                                HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){mem_lsq_i.data[16-1]}}, mem_lsq_i.data[16-1:0]};
                                default :   next_lsq_entry.data =   mem_lsq_i.data;
                            endcase
                        // ELSE it is an unsigned LOAD
                        end else begin
                            case (lsq_entry_o.mem_size)
                                BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){1'b0}}, mem_lsq_i.data[ 8-1:0]};
                                HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){1'b0}}, mem_lsq_i.data[16-1:0]};
                                default :   next_lsq_entry.data =   mem_lsq_i.data;
                            endcase
                        end
                    end
                end
            end
            // Wait for memory/cache to return the data
            LSQ_ST_WAIT_MEM :   begin
                // IF   The memory return tag matches the mem_tag of this entry
                // ->   The data returned from memory is for this entry
                if (mem_lsq_i.tag == next_lsq_entry.mem_tag) begin
                    next_lsq_entry.state        =   LSQ_ST_LOAD_CP  ;
                    next_lsq_entry.data_valid   =   1'b1            ;
                    // IF   it is a signed LOAD
                    if (lsq_entry_o.sign == 1'b0) begin
                        case (lsq_entry_o.mem_size)
                            BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){mem_lsq_i.data[ 8-1]}}, mem_lsq_i.data[ 8-1:0]};
                            HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){mem_lsq_i.data[16-1]}}, mem_lsq_i.data[16-1:0]};
                            default :   next_lsq_entry.data =   mem_lsq_i.data;
                        endcase
                    // ELSE it is an unsigned LOAD
                    end else begin
                        case (lsq_entry_o.mem_size)
                            BYTE    :   next_lsq_entry.data =   {{(C_XLEN- 8){1'b0}}, mem_lsq_i.data[ 8-1:0]};
                            HALF    :   next_lsq_entry.data =   {{(C_XLEN-16){1'b0}}, mem_lsq_i.data[16-1:0]};
                            default :   next_lsq_entry.data =   mem_lsq_i.data;
                        endcase
                    end
                end
            end
            // Complete the LOAD, request CDB
            LSQ_ST_LOAD_CP  :   begin
                if (bc_lsq_entry_i.broadcasted == 1'b1) begin
                    next_lsq_entry.state    =   LSQ_ST_ROB_RETIRE   ;
                end
            end
            // Wait for ROB to retire the LOAD/STORE.
            LSQ_ST_ROB_RETIRE   :   begin
                // Loop over all the Retire channels
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                    // IF   the retire channel is valid
                    // AND  the rob_idx retired matches the rob_idx of this entry
                    // ->   Assert the retire bit of this entry
                    //      and wait to be selected to retire from LSQ
                    if ((rt_idx < rob_lsq_i.rt_num)
                    && (rob_lsq_i.rob_idx[rt_idx] == lsq_entry_o.rob_idx)) begin
                        rob_retire_o    =   1'b1;
                        if (lsq_entry_o.cmd == BUS_LOAD) begin
                            next_lsq_entry.retire   =   1'b1            ;
                            next_lsq_entry.state    =   LSQ_ST_RETIRE   ;
                        end else begin
                            next_lsq_entry.state    =   LSQ_ST_WR_MEM   ;
                        end
                    end
                end
            end
            // Send write request to memory/cache and wait for response
            LSQ_ST_WR_MEM   :   begin
                // IF   The memory interface is granted to this entry
                // AND  The write request is confirmed by memory/cache
                // ->   Go to LSQ_ST_RETIRE to retire from LSQ
                if ((mem_grant_i == 1'b1) && (mem_lsq_i.response != 'd0)) begin
                    next_lsq_entry.state    =   LSQ_ST_RETIRE   ;
                    next_lsq_entry.retire   =   1'b1            ;
                end
            end
            LSQ_ST_RETIRE   :   begin
                // IF   Selected to retire from LSQ
                if (rt_sel_i) begin
                    if (dp_sel_i) begin
                        next_lsq_entry.state        =   LSQ_ST_ADDR ;
                        next_lsq_entry.addr_valid   =   1'b0        ;
                        next_lsq_entry.data         =   'b0         ;
                        next_lsq_entry.data_valid   =   1'b0        ;
                        next_lsq_entry.retire       =   1'b0        ;
                        next_lsq_entry.mem_tag      =   'd0         ;
                        if (lsq_idx_i < tail_i) begin
                            next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                            next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                            next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                            next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                            next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                            next_lsq_entry.sign     =   dp_lsq_i.sign    [lsq_idx_i+C_LSQ_ENTRY_NUM-tail_i] ;
                        end else begin
                            next_lsq_entry.cmd      =   dp_lsq_i.cmd     [lsq_idx_i-tail_i] ;
                            next_lsq_entry.pc       =   dp_lsq_i.pc      [lsq_idx_i-tail_i] ;
                            next_lsq_entry.tag      =   dp_lsq_i.tag     [lsq_idx_i-tail_i] ;
                            next_lsq_entry.rob_idx  =   dp_lsq_i.rob_idx [lsq_idx_i-tail_i] ;
                            next_lsq_entry.mem_size =   dp_lsq_i.mem_size[lsq_idx_i-tail_i] ;
                            next_lsq_entry.sign     =   dp_lsq_i.sign    [lsq_idx_i-tail_i] ;
                        end
                    end else begin
                        next_lsq_entry.state        =   LSQ_ST_IDLE ;
                        next_lsq_entry.cmd          =   BUS_NONE    ;
                        next_lsq_entry.pc           =   'd0         ;
                        next_lsq_entry.tag          =   'd0         ;
                        next_lsq_entry.rob_idx      =   'd0         ;
                        next_lsq_entry.mem_size     =   BYTE        ;
                        next_lsq_entry.sign         =   1'b0        ;
                        next_lsq_entry.addr         =   'd0         ;
                        next_lsq_entry.addr_valid   =   1'b0        ;
                        next_lsq_entry.data         =   'b0         ;
                        next_lsq_entry.data_valid   =   1'b0        ;
                        next_lsq_entry.retire       =   1'b0        ;
                        next_lsq_entry.mem_tag      =   'd0         ;
                    end
                end
            end
            default: begin
                next_lsq_entry.state        =   LSQ_ST_IDLE ;
                next_lsq_entry.cmd          =   BUS_NONE    ;
                next_lsq_entry.pc           =   'd0         ;
                next_lsq_entry.tag          =   'd0         ;
                next_lsq_entry.rob_idx      =   'd0         ;
                next_lsq_entry.mem_size     =   BYTE        ;
                next_lsq_entry.sign         =   1'b0        ;
                next_lsq_entry.addr         =   'd0         ;
                next_lsq_entry.addr_valid   =   1'b0        ;
                next_lsq_entry.data         =   'b0         ;
                next_lsq_entry.data_valid   =   1'b0        ;
                next_lsq_entry.retire       =   1'b0        ;
                next_lsq_entry.mem_tag      =   'd0         ;
            end
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
                store_check[entry_idx]  =   1'b1;
            end
        end
    end

    // Check older STORE address validity
    // and dependency
    always_comb begin
        older_store_known   =   1'b1    ;
        forward_flag        =   1'b0    ;
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

                    // IF   the address (aligned to 4 bytes) of a older store matches this entry
                    // AND  the address (aligned to 4 bytes) of a older store is valid
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr[C_XLEN-1:C_CHECK_OFFSET] == lsq_array_i[entry_idx].addr[C_XLEN-1:C_CHECK_OFFSET])
                    && (lsq_array_i[entry_idx].addr_valid == 1'b1)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                        // IF   the address (within 4 bytes offset) of a older store matches this entry
                        // AND  the mem size matches as well
                        // ->   Upon dependency, a store to load forwarding is legitimate
                        if ((lsq_entry_o.addr[C_CHECK_OFFSET-1:0] == lsq_array_i[entry_idx].addr[C_CHECK_OFFSET-1:0])
                        && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                            forward_flag    =   1'b1;
                        end
                    end
                end
            end
        // IF   there is a rollover in the queue (head_i > lsq_idx_i)
        end else if (lsq_idx_i < head_i) begin
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
                    // IF   the address (aligned to 4 bytes) of a older store matches this entry
                    // AND  the address (aligned to 4 bytes) of a older store is valid
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr[C_XLEN-1:C_CHECK_OFFSET] == lsq_array_i[entry_idx].addr[C_XLEN-1:C_CHECK_OFFSET])
                    && (lsq_array_i[entry_idx].addr_valid == 1'b1)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                        // IF   the address (within 4 bytes offset) of a older store matches this entry
                        // AND  the mem size matches as well
                        // ->   Upon dependency, a store to load forwarding is legitimate
                        if ((lsq_entry_o.addr[C_CHECK_OFFSET-1:0] == lsq_array_i[entry_idx].addr[C_CHECK_OFFSET-1:0])
                        && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                            forward_flag    =   1'b1;
                        end
                    end
                end
            end

            // 2. Check entry from [0] to [lsq_idx_i-1]
            for (int unsigned entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                if (entry_idx < lsq_idx_i) begin
                    // IF   the address (aligned to 4 bytes) of a older store matches this entry
                    // AND  the address (aligned to 4 bytes) of a older store is valid
                    // ->   There is a dependency.
                    //      Because the loop sequence is from the head to this entry,
                    //      if there are multiple matches, only the nearest one is picked.
                    if ((lsq_array_i[entry_idx].cmd == BUS_STORE)
                    && (lsq_entry_o.addr[C_XLEN-1:C_CHECK_OFFSET] == lsq_array_i[entry_idx].addr[C_XLEN-1:C_CHECK_OFFSET])
                    && (lsq_array_i[entry_idx].addr_valid == 1'b1)) begin
                        depend_flag =   1'b1;
                        depend_idx  =   entry_idx;
                        // IF   the address (within 4 bytes offset) of a older store matches this entry
                        // AND  the mem size matches as well
                        // ->   Upon dependency, a store to load forwarding is legitimate
                        if ((lsq_entry_o.addr[C_CHECK_OFFSET-1:0] == lsq_array_i[entry_idx].addr[C_CHECK_OFFSET-1:0])
                        && (lsq_entry_o.mem_size == lsq_array_i[entry_idx].mem_size)) begin
                            forward_flag    =   1'b1;
                        end
                    end
                end
            end
        end
        // ELSE     head_o == lsq_idx_i
        // ->       This entry is the oldest one in LSQ, so no dependency
    end

// --------------------------------------------------------------------
// Memory/Cache Interface
// --------------------------------------------------------------------
    always_comb begin
        lsq_entry_mem_o =   'd0 ;
        case (lsq_entry_o.state)
            LSQ_ST_RD_MEM   :   begin
                lsq_entry_mem_o.addr    =   lsq_entry_o.addr    ;
                lsq_entry_mem_o.data    =   'b0                 ;
                lsq_entry_mem_o.size    =   lsq_entry_o.mem_size;
                lsq_entry_mem_o.command =   lsq_entry_o.cmd     ;
            end
            LSQ_ST_WR_MEM   :   begin
                lsq_entry_mem_o.addr    =   lsq_entry_o.addr    ;
                lsq_entry_mem_o.data    =   lsq_entry_o.data    ;
                lsq_entry_mem_o.size    =   lsq_entry_o.mem_size;
                lsq_entry_mem_o.command =   lsq_entry_o.cmd     ;
            end
        endcase
    end

// --------------------------------------------------------------------
// Broadcaster Interface
// --------------------------------------------------------------------
    always_comb begin
        lsq_entry_bc_o  =   'b0;
        if (lsq_entry_o.state == LSQ_ST_LOAD_CP) begin
            lsq_entry_bc_o.valid        =   1'b1                ;
            lsq_entry_bc_o.pc           =   lsq_entry_o.pc      ;
            lsq_entry_bc_o.write_reg    =   1'b1                ;
            lsq_entry_bc_o.rd_value     =   lsq_entry_o.data    ;
            lsq_entry_bc_o.tag          =   lsq_entry_o.tag     ;
            lsq_entry_bc_o.br_inst      =   1'b0                ;
            lsq_entry_bc_o.br_result    =   1'b0                ;
            lsq_entry_bc_o.br_target    =   'd0                 ;
            lsq_entry_bc_o.thread_idx   =   thread_idx_i        ;
            lsq_entry_bc_o.rob_idx      =   lsq_entry_o.rob_idx ;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
