/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_memory_switch.sv                               //
//                                                                     //
//  Description :  Schedule the access of MSHR entries to              //
//                 Memory Interface.                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_memory_switch #(
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   MEM_IN  [C_MSHR_ENTRY_NUM-1:0]      mshr_memory_i   ,   //  Memory request from each MSHR entry
    output  logic   [C_MSHR_ENTRY_NUM-1:0]      memory_grant_o  ,   //  One-hot grant
    output  MEM_IN                              mem_o               //  Shared Memory Interface
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
        for (int unsigned entry_idx = 0; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            if ((mshr_memory_i[entry_idx].command == BUS_LOAD)
            || (mshr_memory_i[entry_idx].command == BUS_STORE)) begin
                arbiter_req[entry_idx]  =   1'b1;
            end
        end

        // Generate acknowledge signal for arbiter to switch priority
        arbiter_ack     =   1'b0;
        if ((grant_valid == 1'b1) && (mem_i.response != 'd0)) begin
            arbiter_ack     =   1'b1;
        end

        // Route the granted request to the Memory Interface
        mem_o   =   'b0;
        if (grant_valid) begin
            mem_o   =   mshr_memory_i[grant_idx]    ;
        end

        // Output grant signals to the MSHR entries
        memory_grant_o  =   {{(C_MSHR_ENTRY_NUM-1){1'b0}}, 1'b1} << grant_idx;
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
