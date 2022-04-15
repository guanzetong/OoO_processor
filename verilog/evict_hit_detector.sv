/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  evict_hit_detector.sv                               //
//                                                                     //
//  Description :  Compare the address from pocessor with the          //
//                 evict_addr of the valid MSHR entries.               //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module evict_hit_detector #(
    parameter   C_XLEN              =   `XLEN                   ,
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM         ,
    parameter   C_CACHE_BLOCK_SIZE  =   `CACHE_BLOCK_SIZE       ,
    parameter   C_MSHR_IDX_WIDTH    =   $clog2(C_MSHR_ENTRY_NUM)    
) (
    input   MEM_IN                                  proc2cache_i    ,
    input   MSHR_ENTRY  [C_MSHR_ENTRY_NUM-1:0]      mshr_array_i    ,
    output  logic                                   evict_hit_o     ,
    output  logic       [C_MSHR_IDX_WIDTH-1:0]      evict_hit_idx_o 
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CACHE_OFFSET_WIDTH    =   $clog2(C_CACHE_BLOCK_SIZE);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        evict_hit_o      =   1'b0;
        evict_hit_idx_o  =   'd0;
        if (proc2cache_i.command != BUS_NONE) begin
            for (int unsigned entry_idx = 1; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
                // IF   the entry content is valid
                // AND  the address from processor matches the address of current entry
                // AND  current entry is the least older miss to this address
                // ->   MSHR hit is detected
                if ((mshr_array_i[entry_idx].cmd != BUS_NONE)
                &&  (mshr_array_i[entry_idx].evict_dirty == 1'b1)
                &&  (mshr_array_i[entry_idx].evict_addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH] 
                == proc2cache_i.addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH])) begin
                    evict_hit_o      =   1'b1;
                    evict_hit_idx_o  =   entry_idx;
                end
            end
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
