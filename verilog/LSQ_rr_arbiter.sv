/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_rr_arbiter.sv                                   //
//                                                                     //
//  Description :  Work-Conserving Round Robin Arbiter                 // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_rr_arbiter #(
    parameter   C_REQ_NUM       =   `LSQ_ENTRY_NUM      ,
    parameter   C_REQ_IDX_WIDTH =   $clog2(C_REQ_NUM)
) (
    input   logic                           clk_i       ,   //  Clock
    input   logic                           rst_i       ,   //  Reset
    input   logic   [C_REQ_NUM-1:0]         req_i       ,
    input   logic                           ack_i       ,
    output  logic   [C_REQ_IDX_WIDTH-1:0]   grant_o     ,
    output  logic                           valid_o     
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_REQ_IDX_WIDTH-1:0]       top_idx                     ;
    logic   [C_REQ_IDX_WIDTH-1:0]       next_top_idx                ;

    logic   [C_REQ_NUM-1:0]             req_rank                    ;
    logic   [C_REQ_IDX_WIDTH-1:0]       grant_rank                  ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Round-Robin priority
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            top_idx     <=  `SD 'd0;
        end else begin
            top_idx     <=  `SD next_top_idx;
        end
    end

    always_comb begin
        next_top_idx    =   top_idx;
        if (ack_i) begin
            if (grant_o + 1 >= C_REQ_NUM) begin
                next_top_idx    =   'd0;
            end else begin
                next_top_idx    =   grant_o + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// Generate grant
// --------------------------------------------------------------------
    always_comb begin
        // Rank the requests according to priority
        // LSB of req_rank is of top priority
        // if (top_idx > 0) begin
        //     req_rank    =   {req_i[(top_idx-1):0], req_i[(C_REQ_NUM-1):top_idx]};
        // end else begin
        //     req_rank    =   req_i;
        // end
        req_rank    =   (req_i >> top_idx) | (req_i << (C_REQ_NUM-top_idx));

        // The grant index with respect to req_rank
        grant_rank  =   0;
        for (int unsigned req_idx = C_REQ_NUM; req_idx > 0; req_idx--) begin
            if (req_rank[req_idx-1]) begin
                grant_rank  =   (req_idx - 1);
            end
        end

        // The grant index with respect to the original req_i
        if (top_idx + grant_rank >= C_REQ_NUM) begin
            grant_o =   top_idx + grant_rank - C_REQ_NUM;
        end else begin
            grant_o =   top_idx + grant_rank;
        end

        // Assert valid_o when there is any asserted request
        valid_o =   |req_i;
    end

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule
