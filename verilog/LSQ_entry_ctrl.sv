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
    input   lsq_entry_o   [C_LSQ_ENTRY_NUM-1:0]   lsq_array_i     ,
    input   logic                               dp_sel_i        ,   //  Dispatch select
    input   DP_LSQ                              dp_lsq_i        ,
    input   FU_LSQ      [C_LSQ_IN_NUM-1:0]      fu_lsq_i        ,
    output  MEM_IN                              lsq_entry_mem_o ,
    input   MEM_OUT                             mem_lsq_i       ,
    input   logic                               mem_grant_i     ,
    input   BC_FU                               bc_lsq_entry_i  ,
    input   ROB_LSQ                             rob_lsq_i       ,
    output  lsq_entry_o                           lsq_entry_o         //  The contents of this entry
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
    LSQ_STATE   cstate      ;
    LSQ_STATE   nstate      ;

    lsq_entry_o   next_lsq_entry  ;
    logic [C_LSQ_IDX_WIDTH-1:0] depend_tag;

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
// Logic Divider
// --------------------------------------------------------------------
always_ff @(posedge clk_i) begin
    if (rst_i) begin
        lsq_entry_o <=  `SD 'b0;
    end else begin
        lsq_entry_o <=  `SD next_lsq_entry;
    end
end

always_comb begin
    nstate  =   cstate;
    case (cstate)
        ST_IDLE     :   begin
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
        ST_ADDR     :   begin
            // LOAD
            if (lsq_entry_o.cmd == BUS_LOAD) begin
                // Loop over all the LOAD/STORE FU output
                for (int in_idx = 0; in_idx < C_LSQ_IN_NUM; in_idx++) begin
                    // IF   the rob_idx of FU output matches the rob_idx of the entry
                    if ((lsq_entry_o.rob_idx == fu_lsq_i[in_idx].rob_idx) && fu_lsq_i[in_idx].valid) begin
                        // IF   All the older STORE addresses are known and there is no dependency
                        // ->   Go to ST_RD_MEM to read from memory
                        if ((older_store_known == 1'b1) && (depend == 1'b0)) begin
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
        ST_DEPEND   :   begin
            // IF   All the older STORE addresses are known
            if (older_store_known == 1'b1) begin
                // IF   There is no dependency
                // ->   Go to ST_RD_MEM to read from memory
                if (depend == 1'b0) begin
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
        ST_RD_MEM   :   begin
            // IF   The memory interface is granted to this entry 
            // AND  The request is confirmed by memory
            if ((mem_grant_i == 1'b1) && (mem_lsq_i.response != 'd0)) begin
                // IF   Cache miss
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
        ST_WAIT_MEM :   begin
            if (mem_lsq_i.tag == next_lsq_entry.mem_tag) begin
                next_lsq_entry.state        =   ST_LOAD_CP      ;
                next_lsq_entry.data_valid   =   1'b1            ;
                next_lsq_entry.data         =   mem_lsq_i.data  ;
            end
        end
        ST_LOAD_CP  :   begin
            if (bc_lsq_entry_i.broadcasted == 1'b1) begin
                next_lsq_entry.state    =   ST_RETIRE   ;
            end
        end
        ST_RETIRE   :   begin
            for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                if ((rt_idx < rob_lsq_i.rt_num) 
                && (rob_lsq_i.rob_idx[rt_idx] == lsq_entry_o.rob_idx)) begin
                    next_lsq_entry.retire   =   1'b1;
                end
            end

            if (rt_sel_i) begin
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
                end else begin
                    next_lsq_entry.state    =   ST_WR_MEM;
                end
            end

        end
        ST_WR_MEM   :   begin
            if (mem_lsq_i) begin
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

always_comb begin
    if (tail_i > head_i) begin
        for (int entry_idx = head_i; entry_idx < tail_i; entry_idx++) begin
            for (int dep_idx = head_i; dep_idx <= entry_idx; dep_idx++) begin 
                if (lsq_array_i[entry_idx].cmd == BUS_LOAD) begin
                    if (lsq_array_i[dep_idx].cmd == BUS_STORE  && lsq_array_i[dep_idx].addr_valid) begin
                        if (lsq_array_i[entry_idx].addr == lsq_array_i[dep_idx].addr && lsq_array_i[entry_idx].mem_size == lsq_array_i[dep_idx].mem_size) begin
                            depend_tag[entry_idx] = 1'b1;
                        end
                    end
                end
            end
        end
    end else begin
        for (int entry_idx = head_i; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            for (int dep_idx = head_i; dep_idx <= entry_idx; dep_idx++) begin 
                if (lsq_array_i[entry_idx].cmd == BUS_LOAD) begin
                    if (lsq_array_i[dep_idx].cmd == BUS_STORE  && lsq_array_i[dep_idx].addr_valid) begin
                        if (lsq_array_i[entry_idx].addr == lsq_array_i[dep_idx].addr && lsq_array_i[entry_idx].mem_size == lsq_array_i[dep_idx].mem_size) begin
                            depend_tag[entry_idx] = 1'b1;
                        end
                    end
                end
            end
        end

        for (int entry_idx = 0; entry_idx < tail; entry_idx++) begin
            for (int dep_idx = 0; dep_idx <= entry_idx; dep_idx++) begin 
                if (lsq_array_i[entry_idx].cmd == BUS_LOAD) begin
                    if (lsq_array_i[dep_idx].cmd == BUS_STORE  && lsq_array_i[dep_idx].addr_valid) begin
                        if (lsq_array_i[entry_idx].addr == lsq_array_i[dep_idx].addr && lsq_array_i[entry_idx].mem_size == lsq_array_i[dep_idx].mem_size) begin
                            depend_tag[entry_idx] = 1'b1;
                        end
                    end
                end
            end
        end
    end
end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
