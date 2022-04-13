/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mem_switch.sv                                       //
//                                                                     //
//  Description :  mem_switch                                          // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mem_switch #(
    parameter   C_REQ_NUM   =   2   
) (
    input   logic                       clk_i           ,   //  Clock
    input   logic                       rst_i           ,   //  Reset
    input   MEM_IN  [C_REQ_NUM-1:0]     req2mem_i       ,
    input   MEM_OUT                     mem2req_i       ,
    output  logic   [C_REQ_NUM-1:0]     memory_grant_o  ,
    output  MEM_IN                      switch2mem_o    
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
// Module name  :   mem_fixed_priority_arbiter
// Description  :   Fixed Priority abitration on memory interface
// --------------------------------------------------------------------
    mem_fixed_priority_arbiter (
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
        // Pick the requesters with valid Memory requests
        arbiter_req =   'b0;
        for (int unsigned req_idx = 1; req_idx < C_MSHR_ENTRY_NUM; req_idx++) begin
            if (req2mem_i[req_idx].command != BUS_NONE) begin
                arbiter_req[req_idx]    =   1'b1;
            end
        end

        // Generate acknowledge signal for arbiter to switch priority
        arbiter_ack     =   1'b0;
        if ((grant_valid == 1'b1) && (mem2req_i.response != 'd0)) begin
            arbiter_ack     =   1'b1;
        end

        // Route the granted request to the proc Interface
        // Output grant signals to the MSHR entries
        switch2mem_o    =   'b0 ;
        memory_grant_o  =   'b0 ;
        if (grant_valid) begin
            switch2mem_o    =   req2mem_i[grant_idx]    ;
            memory_grant_o  =   {{(C_REQ_NUM-1){1'b0}}, 1'b1} << grant_idx;
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
