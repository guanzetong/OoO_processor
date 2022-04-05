/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB_MULT_pop_out_router.sv                            //
//                                                                     //
//  Description :  Router for Pop-out from IB_MULT_queue.               // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB_MULT_pop_out_router #(
    parameter   C_IN_NUM        =   `MULT_NUM    ,
    parameter   C_OUT_NUM       =   `MULT_NUM    
) (
    input   IS_INST [C_IN_NUM-1:0]      s_data_i        ,
    input   logic   [C_IN_NUM-1:0]      s_valid_i       ,
    output  logic   [C_IN_NUM-1:0]      s_ready_o       ,
    input   FU_IB   [C_OUT_NUM-1:0]     fu_ib_i         ,
    output  IB_FU   [C_OUT_NUM-1:0]     ib_fu_o         
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_OUT_NUM-1:0]                 ready           ;
    logic   [C_OUT_NUM-1:0][C_IN_NUM-1:0]   pop_out_route   ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Pop-out Router logic defined in Function
// --------------------------------------------------------------------
    function automatic logic [C_OUT_NUM-1:0][C_IN_NUM-1:0] route;
        input   logic   [C_IN_NUM-1:0]  valid_i ;
        input   logic   [C_OUT_NUM-1:0] ready_i ;
        int     in_idx  ;
        begin
            in_idx =   0;
            route   =   0;
            for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
                if (ready_i[out_idx] && valid_i[in_idx]) begin
                    route[out_idx][in_idx]  =   1'b1    ;
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
// Output ready signal to clear the poped-out entry
// --------------------------------------------------------------------
    always_comb begin
        ib_fu_o         =   'b0 ;
        s_ready_o       =   'b0 ;
        pop_out_route   =   route(s_valid_i, ready);
        for (int unsigned out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
            for (int unsigned in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
                if (pop_out_route[out_idx][in_idx]) begin
                    ib_fu_o[out_idx].is_inst    =   s_data_i[in_idx];
                    ib_fu_o[out_idx].valid      =   1'b1;
                    s_ready_o[in_idx]           =   1'b1;
                end
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
