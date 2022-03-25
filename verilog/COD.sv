/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  COD.sv                                              //
//                                                                     //
//  Description :  Calculate the Center Of Dispatched RS index.        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module COD #(
    parameter   C_DP_NUM        =   `DP_NUM                 ,
    parameter   C_RS_ENTRY_NUM  =   `RS_ENTRY_NUM           ,
    parameter   C_RS_IDX_WIDTH  =   $clog2(C_RS_ENTRY_NUM)
) (
    input   logic   [C_DP_NUM-1:0][C_RS_IDX_WIDTH-1:0]  rs_idx_i    ,
    input   logic   [C_DP_NUM-1:0]                      valid_i     ,
    output  logic   [C_RS_IDX_WIDTH-1:0]                cod_o       
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_DP_NUM_WDITH  =   $clog2(C_DP_NUM);
    localparam  C_ADDER_IN_NUM  =   2 ** C_DP_NUM_WDITH;
    localparam  C_SUM_WIDTH     =   C_DP_NUM_WDITH + C_RS_IDX_WIDTH;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_SUM_WIDTH-1:0]     sum     ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        sum =   0;
        for (int i = 0; i < C_ADDER_IN_NUM; i++) begin
            // Add the actual dispatched RS entry indexes
            if (i < C_DP_NUM) begin
                // Add the rs_idx_i input if it is valid
                if (valid_i[i]) begin
                    sum =   sum + rs_idx_i[i];
                // Else add the center index of RS
                // Note that with right shift, the center is
                // biased to the lower half, so the LSB of i is
                // added to balance.
                end else begin
                    sum =   sum + (C_RS_ENTRY_NUM >> 1) + i[0];
                end
            // Add the center index of RS
            end else begin
                sum =   sum + (C_RS_ENTRY_NUM >> 1) + i[0];
            end
        end

        // Calculate the COD with right shift.
        cod_o   =   sum >> C_DP_NUM_WDITH;
    end
// ====================================================================
// RTL Logic End
// ====================================================================

endmodule
