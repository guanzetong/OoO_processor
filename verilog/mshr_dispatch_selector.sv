/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_dispatch_selector.sv                           //
//                                                                     //
//  Description :  Select a empty MSHR entry for the new request       //
//                 from processor                                      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_dispatch_selector #(
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM     
) (
    input   MSHR_ENTRY  [C_MSHR_ENTRY_NUM-1:0]      mshr_array_i    ,
    output  logic       [C_MSHR_ENTRY_NUM-1:0]      dp_sel_o        
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_MSHR_IDX_WIDTH        =   $clog2(C_MSHR_ENTRY_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                               dp_idx_valid            ;
    logic   [C_MSHR_IDX_WIDTH-1:0]      dp_idx                  ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        // Scan through the empty entry, and select the one with smallest index
        dp_idx          =   'd0;
        dp_idx_valid    =   1'b0;
        for (int unsigned entry_idx = C_MSHR_ENTRY_NUM - 1; entry_idx > 0; entry_idx--) begin
            if (mshr_array[entry_idx].cmd == BUS_NONE) begin
                dp_idx          =   entry_idx;
                dp_idx_valid    =   1'b1;
            end
        end
        // Generate per-entry dp_sel
        dp_sel_o    =   'b0;
        if (dp_idx_valid) begin
            dp_sel_o    =   {{(C_MSHR_ENTRY_NUM-1){1'b0}}, 1'b1} << dp_idx;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
