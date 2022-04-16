/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_memory_switch.sv                                //
//                                                                     //
//  Description :  Schedule the access of LSQ entries to               //
//                 Memory Interface.                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_memory_switch #(
    parameter   C_LSQ_ENTRY_NUM    =   `LSQ_ENTRY_NUM
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   MEM_IN  [C_LSQ_ENTRY_NUM-1:0]       lsq_entry_mem_i ,   //  Memory request from each LSQ entry
    input   MEM_OUT                             mem_lsq_i       ,
    output  logic   [C_LSQ_ENTRY_NUM-1:0]       memory_grant_o  ,   //  One-hot grant
    output  MEM_IN                              lsq_mem_o           //  Shared Memory Interface
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_LSQ_IDX_WIDTH =   $clog2(C_LSQ_ENTRY_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_LSQ_ENTRY_NUM-1:0]       arbiter_req                 ;
    logic   [C_LSQ_ENTRY_NUM-1:0]       load_req                    ;
    logic   [C_LSQ_ENTRY_NUM-1:0]       store_req                   ;
    logic                               arbiter_ack                 ;
    logic   [C_LSQ_IDX_WIDTH-1:0]       grant_idx                   ;
    logic                               grant_valid                 ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   LSQ_rr_arbiter
// Description  :   Work-Conserving Round Robin Arbiter
// --------------------------------------------------------------------
    LSQ_rr_arbiter LSQ_rr_arbiter_inst (
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
        // Pick the LSQ entries with valid Memory requests
        load_req    =   'b0;
        store_req   =   'b0;
        for (int unsigned entry_idx = 1; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            if (lsq_entry_mem_i[entry_idx].command == BUS_LOAD) begin
                load_req[entry_idx]     =   1'b1;
            end
            if (lsq_entry_mem_i[entry_idx].command == BUS_STORE) begin
                store_req[entry_idx]    =   1'b1;
            end
        end

        // IF   there is any STORE request
        // ->   Mask all the LOAD request
        if (store_req != 'b0) begin
            arbiter_req =   store_req;
        // ELSE
        // ->   Request LOAD
        end else begin
            arbiter_req =   load_req;
        end

        // Generate acknowledge signal for arbiter to switch priority
        arbiter_ack =   1'b0;
        if ((grant_valid == 1'b1) && (mem_lsq_i.response != 'd0)) begin
            arbiter_ack =   1'b1;
        end

        // Route the granted request to the Memory Interface
        // Output grant signals to the LSQ entries
        lsq_mem_o       =   'b0 ;
        memory_grant_o  =   'b0 ;
        if (grant_valid) begin
            lsq_mem_o       =   lsq_entry_mem_i[grant_idx]    ;
            memory_grant_o  =   {{(C_LSQ_ENTRY_NUM-1){1'b0}}, 1'b1} << grant_idx;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
