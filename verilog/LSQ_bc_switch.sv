/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ_proc_switch.sv                                 //
//                                                                     //
//  Description :  Schedule the access of LSQ entries to              //
//                 Processor Interface.                                // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ_bc_switch #(
    parameter   C_LSQ_ENTRY_NUM =   `LSQ_ENTRY_NUM  ,
    parameter   C_LOAD_NUM      =   `LOAD_NUM
) (
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    input   FU_BC   [C_LSQ_ENTRY_NUM-1:0]       lsq_entry_bc_i  ,   //  Broadcast request from each LSQ entry
    input   BC_FU   [C_LOAD_NUM-1:0]            bc_lsq_i        ,   //  Broadcaster repsonse
    output  FU_BC   [C_LOAD_NUM-1:0]            lsq_bc_o        ,   //  Shared Broadcaster Interface
    output  BC_FU   [C_LSQ_ENTRY_NUM-1:0]       bc_lsq_entry_o      //  Broadcaster response to LSQ entries
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_LSQ_IDX_WIDTH        =   $clog2(C_LSQ_ENTRY_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_LOAD_NUM-1:0][C_LSQ_ENTRY_NUM-1:0]   arbiter_req     ;
    logic   [C_LOAD_NUM-1:0][C_LSQ_ENTRY_NUM-1:0]   arbiter_mask    ;
    logic   [C_LOAD_NUM-1:0]                        arbiter_ack     ;
    logic   [C_LOAD_NUM-1:0][C_LSQ_IDX_WIDTH-1:0]   grant_idx       ;
    logic   [C_LOAD_NUM-1:0]                        grant_valid     ;
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
    genvar idx ;
    generate
        for (idx = 0; idx < C_LOAD_NUM; idx++) begin
            LSQ_rr_arbiter LSQ_rr_arbiter_inst (
                .clk_i      (clk_i              ),
                .rst_i      (rst_i              ),
                .req_i      (arbiter_req[idx]   ),
                .ack_i      (arbiter_ack[idx]   ),
                .grant_o    (grant_idx  [idx]   ),
                .valid_o    (grant_valid[idx]   )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        arbiter_req     =   'b0;
        arbiter_ack     =   'b0;
        lsq_bc_o        =   'b0;
        bc_lsq_entry_o  =   'b0;
        arbiter_mask    =   'b0;
        for (int unsigned arbiter_idx = 1; arbiter_idx < C_LOAD_NUM; arbiter_idx++) begin
            // Generate requests to all the arbiters
            // The first arbiter
            if (arbiter_idx == 0) begin
                for (int unsigned entry_idx = 1; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
                    if (lsq_entry_bc_i[entry_idx].valid == 1'b1) begin
                        arbiter_req[arbiter_idx][entry_idx]  =   1'b1;
                    end
                end
            // Others
            // Mask the granted reqeust of the previous arbiter
            end else begin
                arbiter_req[arbiter_idx]    =   arbiter_req[arbiter_idx-1] & (~arbiter_mask[arbiter_idx-1]);
            end

            // Generate acknowledge signal for arbiter to switch priority
            arbiter_ack[arbiter_idx]    =   bc_lsq_i[arbiter_idx].broadcasted;

            // Route the granted request to the Broadcaster Interface
            // Output response signals to the LSQ entries
            if (grant_valid[arbiter_idx]) begin
                lsq_bc_o[arbiter_idx]   =   lsq_entry_bc_i[grand_idx[arbiter_idx]];
                bc_lsq_entry_o[grant_idx[arbiter_idx]]  =   bc_lsq_i[arbiter_idx];
            end

            // Generate mask
            if (grant_valid[arbiter_idx]) begin
                arbiter_mask[arbiter_idx]   =   {{(C_LSQ_ENTRY_NUM-1){1'b0}}, 1'b1} << grant_idx;
            end
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
