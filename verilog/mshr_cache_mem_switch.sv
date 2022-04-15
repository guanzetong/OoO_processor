/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_cache_mem_switch.sv                            //
//                                                                     //
//  Description :  Schedule the access of MSHR entries to              //
//                 the interface between cache_ctrl and cache_mem.     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_cache_mem_switch #(
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM
) (
    input   logic                                       clk_i               ,   //  Clock
    input   logic                                       rst_i               ,   //  Reset
    input   CACHE_CTRL_MEM  [C_MSHR_ENTRY_NUM-1:0]      mshr_cache_mem_i    ,   //  cache_mem request from each MSHR entry
    output  logic           [C_MSHR_ENTRY_NUM-1:0]      cache_mem_grant_o   ,   //  One-hot grant
    output  CACHE_CTRL_MEM                              cache_ctrl_mem_o        //  cache_mem interface
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
    logic   [C_MSHR_ENTRY_NUM-1:0]      arbiter_req                 ;
    logic                               arbiter_ack                 ;
    logic   [C_MSHR_IDX_WIDTH-1:0]      grant_idx                   ;
    logic                               grant_valid                 ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   mshr_rr_arbiter
// Description  :   Work-Conserving Round Robin Arbiter
// --------------------------------------------------------------------
    mshr_rr_arbiter mshr_rr_arbiter_inst (
        .clk_i      (clk_i          ),
        .rst_i      (rst_i          ),
        .req_i      (arbiter_req    ),
        .ack_i      (arbiter_ack    ),
        .grant_o    (grant_idx      ),
        .valid_o    (grant_valid    )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        // Pick the MSHR entries with valid Memory requests
        arbiter_req =   'b0;
        for (int unsigned entry_idx = 1; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            if (mshr_cache_mem_i[entry_idx].req_cmd != REQ_NONE) begin
                arbiter_req[entry_idx]  =   1'b1;
            end
        end

        // Generate acknowledge signal for arbiter to switch priority
        arbiter_ack     =   grant_valid;

        // Route the granted request to the Memory Interface
        // Output grant signals to the MSHR entries
        cache_ctrl_mem_o    =   'b0;
        cache_mem_grant_o   =   'b0;
        if (grant_valid) begin
            cache_ctrl_mem_o    =   mshr_cache_mem_i[grant_idx];
            cache_mem_grant_o   =   {{(C_MSHR_ENTRY_NUM-1){1'b0}}, 1'b1} << grant_idx;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
