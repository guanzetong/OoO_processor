/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB_channel.sv                                       //
//                                                                     //
//  Description :  IB_channel                                          // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB_channel #(
    parameter   C_SIZE          =   8           ,
    parameter   C_IN_NUM        =   `IS_NUM     ,
    parameter   C_OUT_NUM       =   `ALU_NUM    ,
    parameter   C_FU_TYPE       =   "ALU"       
) (
    input   logic                   clk_i           ,   // Clock
    input   logic                   rst_i           ,   // Reset
    // RS Interface
    input   RS_IB   [C_IN_NUM-1:0]  rs_ib_i         ,   // Issue channel from RS
    output  logic                   ready_o         ,   // Queue ready output to RS
    // FU Interface
    input   FU_IB   [C_OUT_NUM-1:0] fu_ib_i         ,   // FU ready input
    output  IB_FU   [C_OUT_NUM-1:0] ib_fu_o         ,   // Issue channel to FU
    // Flush
    input   BR_MIS                  br_mis_i        ,   // Branch Misprediction
    input   logic                   exception_i     ,   // External Exception
    // For Testing
    output  IS_INST [C_SIZE-1:0]    queue_mon_o     ,
    output  logic   [C_SIZE-1:0]    valid_mon_o     
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic       [C_IN_NUM-1:0]      push_in_valid       ;
    logic       [C_IN_NUM-1:0]      push_in_ready       ;
    IS_INST     [C_IN_NUM-1:0]      push_in_data        ;

    logic       [C_OUT_NUM-1:0]     pop_out_valid       ;
    logic       [C_OUT_NUM-1:0]     pop_out_ready       ;
    IS_INST     [C_OUT_NUM-1:0]     pop_out_data        ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   IB_push_in_router
// Description  :   Router for Push-in to IB_queue. 
// --------------------------------------------------------------------
    IB_push_in_router #(
        .C_IN_NUM       (C_IN_NUM       ),
        .C_OUT_NUM      (C_IN_NUM       ),
        .C_FU_TYPE      (C_FU_TYPE      )
    ) IB_push_in_router_inst (
        .rs_ib_i        (rs_ib_i        ),
        .ready_o        (ready_o        ),
        .m_valid_o      (push_in_valid  ),
        .m_ready_i      (push_in_ready  ),
        .m_data_o       (push_in_data   )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   IB_queue
// Description  :   Instruction queue to a type of FU. 
// --------------------------------------------------------------------
    IB_queue #(
        .C_SIZE         (C_SIZE         ),
        .C_IN_NUM       (C_IN_NUM       ),
        .C_OUT_NUM      (C_OUT_NUM      )
    ) IB_queue_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .s_valid_i      (push_in_valid  ),
        .s_ready_o      (push_in_ready  ),
        .s_data_i       (push_in_data   ),
        .m_valid_o      (pop_out_valid  ),
        .m_ready_i      (pop_out_ready  ),
        .m_data_o       (pop_out_data   ),
        .br_mis_i       (br_mis_i       ),
        .exception_i    (exception_i    ),
        .queue_mon_o    (queue_mon_o    ),
        .valid_mon_o    (valid_mon_o    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   IB_pop_out_router
// Description  :   Router for Pop-out from IB_queue. 
// --------------------------------------------------------------------
    IB_pop_out_router #(
        .C_IN_NUM       (C_OUT_NUM      ),
        .C_OUT_NUM      (C_OUT_NUM      )
    ) IB_pop_out_router_inst (
        .s_data_i       (pop_out_data   ),
        .s_valid_i      (pop_out_valid  ),
        .s_ready_o      (pop_out_ready  ),
        .fu_ib_i        (fu_ib_i        ),
        .ib_fu_o        (ib_fu_o        )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

endmodule
