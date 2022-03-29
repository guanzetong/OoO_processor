/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  IB.sv                                               //
//                                                                     //
//  Description :  Issue Buffer. Buffering the issued instructions to  //
//                 different types of Function Units, and route them   //
//                 to a specific Function Unit based on availibility.  //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module IB #(
    parameter   C_IS_NUM        =   `IS_NUM         ,
    parameter   C_ALU_NUM       =   `ALU_NUM        , 
    parameter   C_MULT_NUM      =   `MULT_NUM       , 
    parameter   C_BR_NUM        =   `BR_NUM         , 
    parameter   C_LOAD_NUM      =   `LOAD_NUM       , 
    parameter   C_STORE_NUM     =   `STORE_NUM      , 
    parameter   C_FU_NUM        =   `FU_NUM         ,
    parameter   C_ALU_Q_SIZE    =   `ALU_Q_SIZE     ,
    parameter   C_MULT_Q_SIZE   =   `MULT_Q_SIZE    ,
    parameter   C_BR_Q_SIZE     =   `BR_Q_SIZE      ,
    parameter   C_LOAD_Q_SIZE   =   `LOAD_Q_SIZE    ,
    parameter   C_STORE_Q_SIZE  =   `STORE_Q_SIZE   
) (
    input   logic                       clk_i           ,   //  Clock
    input   logic                       rst_i           ,   //  Reset
    output  IB_RS                       ib_rs_o         ,
    input   RS_IB   [C_IS_NUM-1:0]      rs_ib_i         ,
    input   FU_IB   [C_FU_NUM-1:0]      fu_ib_i         ,
    output  IB_FU   [C_FU_NUM-1:0]      ib_fu_o         ,
    input   BR_MIS                      br_mis_i        ,
    input   logic                       exception_i     ,
    // For Testing
    output  IS_INST [C_ALU_Q_SIZE  -1:0]    ALU_queue_mon_o     ,
    output  IS_INST [C_MULT_Q_SIZE -1:0]    MULT_queue_mon_o    ,
    output  IS_INST [C_BR_Q_SIZE   -1:0]    BR_queue_mon_o      ,
    output  IS_INST [C_LOAD_Q_SIZE -1:0]    LOAD_queue_mon_o    ,
    output  IS_INST [C_STORE_Q_SIZE-1:0]    STORE_queue_mon_o   
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ALU_BASE      =   0                           ;
    localparam  C_MULT_BASE     =   C_ALU_BASE + C_ALU_NUM      ;
    localparam  C_BR_BASE       =   C_MULT_BASE + C_MULT_NUM    ;
    localparam  C_LOAD_BASE     =   C_BR_BASE + C_BR_NUM        ;
    localparam  C_STORE_BASE    =   C_LOAD_BASE + C_LOAD_NUM    ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   ALU_queue
// Description  :   Queue to store the ALU operations
// --------------------------------------------------------------------
    IB_channel #(
        .C_SIZE         (C_ALU_Q_SIZE   ),
        .C_IN_NUM       (C_IS_NUM       ),
        .C_OUT_NUM      (C_ALU_NUM      ),
        .C_FU_TYPE      ("ALU"          )
    ) ALU_channel (
        .clk_i          (clk_i                                      ),
        .rst_i          (rst_i                                      ),
        .rs_ib_i        (rs_ib_i                                    ),
        .ready_o        (ib_rs_o.ALU_ready                          ),
        .fu_ib_i        (fu_ib_i[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE] ),
        .ib_fu_o        (ib_fu_o[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE] ),
        .br_mis_i       (br_mis_i                                   ),
        .exception_i    (exception_i                                ),
        .queue_mon_o    (ALU_queue_mon_o                            )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   MULT_queue
// Description  :   Queue to store the MULT operations
// --------------------------------------------------------------------
    IB_channel #(
        .C_SIZE         (C_MULT_Q_SIZE  ),
        .C_IN_NUM       (C_IS_NUM       ),
        .C_OUT_NUM      (C_MULT_NUM     ),
        .C_FU_TYPE      ("MULT"         )
    ) MULT_channel (
        .clk_i          (clk_i                                          ),
        .rst_i          (rst_i                                          ),
        .rs_ib_i        (rs_ib_i                                        ),
        .ready_o        (ib_rs_o.MULT_ready                             ),
        .fu_ib_i        (fu_ib_i[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE]  ),
        .ib_fu_o        (ib_fu_o[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE]  ),
        .br_mis_i       (br_mis_i                                       ),
        .exception_i    (exception_i                                    ),
        .queue_mon_o    (MULT_queue_mon_o                               )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   BR_queue
// Description  :   Queue to store the BR operations
// --------------------------------------------------------------------
    IB_channel #(
        .C_SIZE         (C_BR_Q_SIZE    ),
        .C_IN_NUM       (C_IS_NUM       ),
        .C_OUT_NUM      (C_BR_NUM       ),
        .C_FU_TYPE      ("BR"           )
    ) BR_channel (
        .clk_i          (clk_i                                      ),
        .rst_i          (rst_i                                      ),
        .rs_ib_i        (rs_ib_i                                    ),
        .ready_o        (ib_rs_o.BR_ready                           ),
        .fu_ib_i        (fu_ib_i[C_BR_BASE+C_BR_NUM-1:C_BR_BASE]    ),
        .ib_fu_o        (ib_fu_o[C_BR_BASE+C_BR_NUM-1:C_BR_BASE]    ),
        .br_mis_i       (br_mis_i                                   ),
        .exception_i    (exception_i                                ),
        .queue_mon_o    (BR_queue_mon_o                             )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   LOAD_queue
// Description  :   Queue to store the LOAD operations
// --------------------------------------------------------------------
    IB_channel #(
        .C_SIZE         (C_LOAD_Q_SIZE  ),
        .C_IN_NUM       (C_IS_NUM       ),
        .C_OUT_NUM      (C_LOAD_NUM     ),
        .C_FU_TYPE      ("LOAD"         )
    ) LOAD_channel (
        .clk_i          (clk_i                                          ),
        .rst_i          (rst_i                                          ),
        .rs_ib_i        (rs_ib_i                                        ),
        .ready_o        (ib_rs_o.LOAD_ready                             ),
        .fu_ib_i        (fu_ib_i[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]  ),
        .ib_fu_o        (ib_fu_o[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]  ),
        .br_mis_i       (br_mis_i                                       ),
        .exception_i    (exception_i                                    ),
        .queue_mon_o    (LOAD_queue_mon_o                               )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   STORE_queue
// Description  :   Queue to store the STORE operations
// --------------------------------------------------------------------
    IB_channel #(
        .C_SIZE         (C_STORE_Q_SIZE ),
        .C_IN_NUM       (C_IS_NUM       ),
        .C_OUT_NUM      (C_STORE_NUM    ),
        .C_FU_TYPE      ("STORE"        )
    ) STORE_channel (
        .clk_i          (clk_i                                              ),
        .rst_i          (rst_i                                              ),
        .rs_ib_i        (rs_ib_i                                            ),
        .ready_o        (ib_rs_o.STORE_ready                                ),
        .fu_ib_i        (fu_ib_i[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]   ),
        .ib_fu_o        (ib_fu_o[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]   ),
        .br_mis_i       (br_mis_i                                           ),
        .exception_i    (exception_i                                        ),
        .queue_mon_o    (STORE_queue_mon_o                                  )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
