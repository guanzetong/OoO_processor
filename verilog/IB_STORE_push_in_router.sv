/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB_STORE_push_in_router.sv                          //
//                                                                     //
//  Description :  Router for Push-in to IB_STORE_queue.               // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB_STORE_push_in_router #(
    parameter   C_IN_NUM        =   `IS_NUM         ,
    parameter   C_OUT_NUM       =   `IS_NUM         
) (
    input   RS_IB   [C_IN_NUM-1:0]      rs_ib_i         ,
    output  logic                       ready_o         ,
    output  logic   [C_OUT_NUM-1:0]     m_valid_o       ,   // Push-in Valid
    input   logic   [C_OUT_NUM-1:0]     m_ready_i       ,
    output  IS_INST [C_OUT_NUM-1:0]     m_data_o            // Push-in Data
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_IN_IDX_WIDTH  =   $clog2(C_IN_NUM)    ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_IN_NUM-1:0]                  valid           ;
    logic   [C_OUT_NUM-1:0][C_IN_NUM-1:0]   push_in_route   ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Output queue readiness
// --------------------------------------------------------------------
    assign  ready_o =   &m_ready_i;

// --------------------------------------------------------------------
// Push-in Router logic defined in Function
// --------------------------------------------------------------------
    function automatic logic [C_OUT_NUM-1:0][C_IN_NUM-1:0] route;
        input   logic   [C_IN_NUM-1:0]  valid_i;
        int     out_idx  ;
        begin
            out_idx =   0;
            route   =   0;
            for (int in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
                if (valid_i[in_idx]) begin
                    route[out_idx][in_idx]  =   1'b1    ;
                    out_idx++;
                end
            end
        end
    endfunction

// --------------------------------------------------------------------
// Select the operations to a type of Function Unit
// --------------------------------------------------------------------
    always_comb begin
        for (int in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
            valid[in_idx]   =   rs_ib_i[in_idx].valid & rs_ib_i[in_idx].is_inst.wr_mem;
        end
    end

// --------------------------------------------------------------------
// Router Output
// --------------------------------------------------------------------
    always_comb begin
        m_valid_o       =   'b0;
        m_data_o        =   'b0;
        push_in_route   =   route(valid);
        for (int out_idx = 0; out_idx < C_OUT_NUM; out_idx++) begin
            for (int unsigned in_idx = 0; in_idx < C_IN_NUM; in_idx++) begin
                if (push_in_route[out_idx][in_idx]) begin
                    m_data_o[out_idx]    =   rs_ib_i[in_idx].is_inst;
                    m_valid_o[out_idx]   =   1'b1;
                end
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
