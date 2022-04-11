/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_proc_switch.sv                                 //
//                                                                     //
//  Description :  Schedule the access of MSHR entries to              //
//                 Processor Interface.                                // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_proc_switch #(
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   MEM_IN  [C_MSHR_ENTRY_NUM-1:0]      mshr_proc_i     ,   //  Processor request from each MSHR entry
    output  logic   [C_MSHR_ENTRY_NUM-1:0]      proc_grant_o    ,   //  One-hot grant
    output  MEM_IN                              proc_o              //  Shared Processor Interface
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
    logic   [C_MSHR_ENTRY_NUM-1:0]      response_req                ;
    logic   [C_MSHR_ENTRY_NUM-1:0]      tag_req                     ;
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
        // Extract response requests and tag requests from all the requests
        response_req    =   'b0 ;
        tag_req         =   'b0 ;
        for (int unsigned entry_idx = 1; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            if (mshr_proc_i[entry_idx].response != 'd0) begin
                response_req[entry_idx]  =   1'b1;
            end

            if (mshr_proc_i[entry_idx].tag != 'd0) begin
                tag_req[entry_idx]  =   1'b1;
            end
        end

        // Prioritize response request over tag request
        if (response_req != 'b0) begin
            arbiter_req =   response_req;
        end else begin
            arbiter_req =   tag_req     ;
        end

        // Generate acknowledge signal for arbiter to switch priority
        arbiter_ack     =   grant_valid;

        // Route the granted request to the proc Interface
        // Output grant signals to the MSHR entries
        proc_o          =   'b0 ;
        proc_grant_o    =   'b0 ;
        if (grant_valid) begin
            proc_o  =   mshr_proc_i[grant_idx]    ;
            proc_grant_o  =   {{(C_MSHR_ENTRY_NUM-1){1'b0}}, 1'b1} << grant_idx;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
