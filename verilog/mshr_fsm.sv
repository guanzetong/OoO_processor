/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_fsm.sv                                         //
//                                                                     //
//  Description :  Finite State Machine to derive the state of a       //
//                 MSHR entry.                                         // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_fsm (
    input   MSHR_STATE          cstate_i            ,   //  Current state
    output  MSHR_STATE          nstate_o            ,   //  Next State
    input   BUS_COMMAND         bus_cmd_i           ,   //  The command on Processor Interface
    input   logic               cache_mem_grant_i   ,   //  Indicate if the cache_mem Interface is granted to this entry
    input   logic               memory_grant_i      ,   //  Indicate if the Memory Interface is granted to this entry
    input   logic               cache_mem_hit_i     ,   //  Indicate if there is a hit in cache_mem
    input   logic               mshr_hit_i          ,   //  Indicate if there is a match of miss address in MSHR
    input   logic               dp_sel_i            ,   //  Dispatch select
    input   logic               cp_sel_i            ,   //  Complete select of the older miss to the same address
    input   logic   [4-1:0]     mem_response_i      ,   //  Response of Memory Interface
    input   logic   [4-1:0]     mem_tag_i           ,   //  Tag of Memory Interface
    input   logic   [4-1:0]     entry_tag_i         ,   //  Tag of Memory transaction recorded in MSHR entry
    input   logic               evict_dirty_i           //  Indicate whether a write-back to Memory is needed.
);

// ====================================================================
// RTL Logic Start
// ====================================================================

    always_comb begin
        nstate_o  =   cstate_i  ;
        case (cstate_i)
            ST_IDLE     :   begin
                // IF   there is a valid transaction on Processor Interface
                // AND  the cache_mem Interface is granted to this entry
                // AND  it is a miss
                // AND  the entry is selected to hold the new miss
                if ((bus_cmd_i != BUS_NONE) && (cache_mem_grant_i == 1'b1)
                && (cache_mem_hit_i == 1'b0) && (dp_sel_i == 1'b1)) begin
                    // IF   there is an older transaction to the same addreess
                    if (mshr_hit_i) begin
                        nstate_o    =   ST_DEPEND   ;
                    end else begin
                        nstate_o    =   ST_RD_MEM   ;
                    end
                end
            end
            ST_DEPEND   :   begin
                // IF   the older transaction the entry is linked to completed
                if (cp_sel_i == 1'b1) begin
                    nstate_o    =   ST_UPDATE
                end
            end
            ST_RD_MEM   :   begin
                // IF   the read transaction is confirmed by Memory Interface
                if ((memory_grant_i == 1'b1) && (mem_response_i != 'd0)) begin
                    nstate_o    =   ST_WAIT_MEM ;
                end
            end
            ST_WAIT_MEM :   begin
                // IF   the data is returned from the Memory
                if (mem_tag_i == entry_tag_i) begin
                    nstate_o    =   ST_UPDATE   ;
                end
            end
            ST_UPDATE   :   begin
                // IF   the req interface is granted to this entry
                if (cache_mem_grant_i == 1'b1) begin
                    // IF   a dirty block is evicted
                    if (evict_dirty_i == 1'b1) begin
                        nstate_o    =   ST_EVICT;
                    // ELSE
                    // ->   Miss Handling Completed
                    end else begin
                        nstate_o    =   ST_IDLE ;
                    end
                end
            end
            ST_EVICT    :   begin
                // IF   the write back transaction to Memory is confirmed
                // ->   Miss Handling Completed
                if ((memory_grant_i == 1'b1) && (mem_response_i != 'd0)) begin
                    nstate_o    =   ST_IDLE ;
                end
            end
            default     :   begin
                nstate_o    =   ST_IDLE ;
            end
        endcase
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
