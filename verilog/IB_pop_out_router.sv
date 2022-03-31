/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB_pop_out_router.sv                                //
//                                                                     //
//  Description :  Router for Pop-out from IB_queue.                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB_pop_out_router #(
    parameter   C_IN_NUM        =   `ALU_NUM    ,
    parameter   C_OUT_NUM       =   `ALU_NUM    
) (
    input   IS_INST [C_IN_NUM-1:0]      s_data_i        ,
    input   logic   [C_IN_NUM-1:0]      s_valid_i       ,
    output  logic   [C_IN_NUM-1:0]      s_ready_o       ,
    input   FU_IB   [C_OUT_NUM-1:0]     fu_ib_i         ,
    output  IB_FU   [C_OUT_NUM-1:0]     ib_fu_o         
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_IN_IDX_WIDTH  =   $clog2(C_IN_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_OUT_NUM-1:0]                         ready           ;
    logic   [C_OUT_NUM-1:0][C_IN_IDX_WIDTH:0]       pop_out_route   ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Pop-out Router logic defined in Function
// --------------------------------------------------------------------
    function automatic logic [C_OUT_NUM-1:0][C_IN_IDX_WIDTH:0] route;
        input   logic   [C_IN_NUM-1:0]  valid_i ;
        input   logic   [C_OUT_NUM-1:0] ready_i ;
        int     in_idx  ;
        begin
            in_idx =   0;
            route   =   0;
            for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                if (ready_i[out_idx] && valid_i[in_idx]) begin
                    route[out_idx][C_IN_IDX_WIDTH]      =   1'b1    ;
                    route[out_idx][C_IN_IDX_WIDTH-1:0]  =   in_idx  ;
                    in_idx++;
                end
            end
        end
    endfunction

// --------------------------------------------------------------------
// Concatenate the ready signals from FUs
// --------------------------------------------------------------------
    always_comb begin
        for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
            ready[out_idx]    =   fu_ib_i[out_idx].ready;
        end
    end

// --------------------------------------------------------------------
// Route the data from queue to output
// --------------------------------------------------------------------
    generate
        if (C_IN_NUM >= 2) begin
            always_comb begin
                ib_fu_o         =   'b0;
                pop_out_route   =   route(s_valid_i, ready);
                for (int unsigned out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                    ib_fu_o[out_idx].is_inst    =   s_data_i[pop_out_route[out_idx][C_IN_IDX_WIDTH-1:0]];
                    ib_fu_o[out_idx].valid      =   pop_out_route[out_idx][C_IN_IDX_WIDTH];
                end
            end
        end else begin
            always_comb begin
                ib_fu_o =   'b0;
                for (int unsigned out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                    ib_fu_o[out_idx].is_inst    =   s_data_i;
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Output ready signal to clear the poped-out entry
// --------------------------------------------------------------------
    generate
        if (C_IN_NUM >= 2) begin
            always_comb begin
                s_ready_o   =   'b0;
                for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                    if (ib_fu_o[out_idx].valid && fu_ib_i[out_idx].ready) begin
                        s_ready_o[pop_out_route[out_idx][C_IN_IDX_WIDTH-1:0]]   =   1'b1;
                    end
                end
            end
        end else begin
            always_comb begin
                s_ready_o   =   'b0;
                for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                    if (ib_fu_o[out_idx].valid && fu_ib_i[out_idx].ready) begin
                        s_ready_o   =   1'b1;
                    end
                end
            end
        end
    endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
