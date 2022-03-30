/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pipeline_dp.sv                                      //
//                                                                     //
//  Description :  Integrate Dispatcher, RS, ROB, PRF, IB              // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module pipeline_dp (
    input   logic                               clk_i               ,   // Clock
    input   logic                               rst_i               ,   // Reset
    input   FIQ_DP                              fiq_dp              ,   // From FIQ to DP
    output  DP_FIQ                              dp_fiq              ,   // From DP to FIQ
    input   logic                               exception_i         ,   // External exception
    // Testing
    //      Dispatch
    output  DP_RS                               dp_rs_mon_o         ,   // From Dispatcher to RS
    //      Issue
    output  RS_IB                               rs_ib_mon_o         ,   // From RS to IB
    //      Execute
    output  IB_FU   [C_FU_NUM-1:0]              ib_fu_mon_o         ,   // From IB to FU
    //      Complete
    output  FU_BC                               fu_bc_mon_o         ,   // From FU to BC
    output  CDB                                 cdb_mon_o           ,   // CDB
    //      Retire
    output  logic   [C_RT_NUM-1:0][C_XLEN-1:0]  rt_pc_o             ,   // PC of retired instructions
    output  logic   [C_RT_NUM-1:0]              rt_valid_o          ,   // Retire valid
    output  ROB_AMT [C_RT_NUM-1:0]              rob_amt_mon_o       ,   // From ROB to AMT
    output  ROB_FL                              rob_fl_mon_o        ,   // From ROB to FL
    output  ROB_VFL                             rob_vfl_mon_o       ,   // From ROB to VFL
    output  BR_MIS                              br_mis_mon_o        ,   // Branch Misprediction
    //      Contents
    output  ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_mon_o           ,   // ROB contents monitor
    output  RS_ENTRY [C_RS_ENTRY_NUM-1:0]       rs_mon_o            ,   // RS contents monitor
    output  MT_ENTRY [C_ARCH_REG_NUM-1:0]       mt_mon_o            ,   // Map Table contents monitor
    output  IS_INST  [C_ALU_Q_SIZE  -1:0]       ALU_queue_mon_o     ,   // IB queue monitor
    output  IS_INST  [C_MULT_Q_SIZE -1:0]       MULT_queue_mon_o    ,   // IB queue monitor
    output  IS_INST  [C_BR_Q_SIZE   -1:0]       BR_queue_mon_o      ,   // IB queue monitor
    output  IS_INST  [C_LOAD_Q_SIZE -1:0]       LOAD_queue_mon_o    ,   // IB queue monitor
    output  IS_INST  [C_STORE_Q_SIZE-1:0]       STORE_queue_mon_o       // IB queue monitor
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
    ROB_DP                                  rob_dp          ;
    DP_ROB                                  dp_rob          ;
    DP_MT_READ  [C_DP_NUM-1:0]              dp_mt_read      ;
    DP_MT_WRITE [C_DP_NUM-1:0]              dp_mt_write     ;
    FL_DP                                   fl_dp           ;
    DP_FL                                   dp_fl           ;
    // FIQ_DP                               fiq_dp          ;
    // DP_FIQ                               dp_fiq          ;
    RS_DP                                   rs_dp           ;
    DP_RS                                   dp_rs           ;
    CDB                                     cdb             ;
    RS_IB       [`IS_NUM-1:0]               rs_ib           ;
    IB_RS                                   ib_rs           ;
    RS_PRF      [`IS_NUM-1:0]               rs_prf          ;
    PRF_RS      [`IS_NUM-1:0]               prf_rs          ;
    BR_MIS                                  br_mis          ;
    ROB_AMT     [`RT_NUM-1:0]               rob_amt         ;
    ROB_FL                                  rob_fl          ;
    ROB_VFL                                 rob_vfl         ;
    FU_IB       [`FU_NUM-1:0]               fu_ib           ;
    IB_FU       [`FU_NUM-1:0]               ib_fu           ;
    BC_PRF                                  bc_prf          ;
    VFL_ENTRY   [`FL_ENTRY_NUM-1:0]         vfl             ;
    AMT_ENTRY   [`ARCH_REG_NUM-1:0]         amt             ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   DP
// Description  :   Dispatcher
// --------------------------------------------------------------------
    DP DP_inst (
        .rob_dp_i       (rob_dp         ),
        .dp_rob_o       (dp_rob         ),
        .mt_dp_i        (mt_dp          ),
        .dp_mt_read_o   (dp_mt_read     ),
        .dp_mt_write_o  (dp_mt_write    ),
        .fl_dp_i        (fl_dp          ),
        .dp_fl_o        (dp_fl          ),
        .fiq_dp_i       (fiq_dp         ),
        .dp_fiq_o       (dp_fiq         ),
        .rs_dp_i        (rs_dp          ),
        .dp_rs_o        (dp_rs          )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   RS
// Description  :   Reservation Station
// --------------------------------------------------------------------
    RS RS_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rs_dp_o        (rs_dp          ),
        .dp_rs_i        (dp_rs          ),
        .cdb_i          (cdb            ),
        .rs_ib_o        (rs_ib          ),
        .ib_rs_i        (ib_rs          ),
        .rs_prf_o       (rs_prf         ),
        .prf_rs_i       (prf_rs         ),
        .br_mis_i       (br_mis         ),
        .exception_i    (exception_i    ),
        //RS testing
        .rs_mon_o       (rs_mon_o       )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   ROB
// Description  :   Reorder Buffer
// --------------------------------------------------------------------
    ROB ROB_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rob_dp_o       (rob_dp         ),
        .dp_rob_i       (dp_rob         ),
        .cdb_i          (cdb            ),
        .rob_amt_o      (rob_amt        ),
        .rob_fl_o       (rob_fl         ),
        .rob_vfl_o      (rob_vfl        ),
        .exception_i    (exception_i    ),
        .br_mis_o       (br_mis         ),
        //ROB testing
        .rob_mon_o      (rob_mon_o      ),
        .rt_pc_o        (rt_pc_o        ),
        .rt_valid_o     (rt_valid_o     )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   IB
// Description  :   Issue Buffer
// --------------------------------------------------------------------
    IB IB_inst (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .ib_rs_o            (ib_rs              ),
        .rs_ib_i            (rs_ib              ),
        .fu_ib_i            (fu_ib              ),
        .ib_fu_o            (ib_fu              ),
        .br_mis_i           (br_mis             ),
        .exception_i        (exception_i        ),
        //IB testing    
        .ALU_queue_mon_o    (ALU_queue_mon_o    ),
        .MULT_queue_mon_o   (MULT_queue_mon_o   ),
        .BR_queue_mon_o     (BR_queue_mon_o     ),
        .LOAD_queue_mon_o   (LOAD_queue_mon_o   ),
        .STORE_queue_mon_o  (STORE_queue_mon_o  )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   PRF
// Description  :   Physical Register File
// --------------------------------------------------------------------
    PRF PRF_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rs_prf_i       (rs_prf         ),
        .prf_rs_o       (prf_rs         ),
        .bc_prf_i       (bc_prf         )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   MT
// Description  :   Map Table
// --------------------------------------------------------------------
    MT MT_sim (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rollback_i     (rollback_i     ),    
        .cdb_i          (cdb            ),
        .dp_mt_read_i   (dp_mt_read     ),
        .dp_mt_write_i  (dp_mt_write    ),
        .amt_i          (amt            ),
        .mt_dp_o        (mt_dp          ),
         // For Testing
        .mt_mon_o       (mt_mon_o       )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   AMT
// Description  :   Arch. Map Table
// --------------------------------------------------------------------
    AMT AMT_inst (
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .rollback_i     (exception_i || br_mis  ),    
        .rob_amt_i      (rob_amt                ),
        .amt_o          (amt                    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   FU
// Description  :   Arch. Map Table
// --------------------------------------------------------------------
    FU FU_inst (
        .fu_bc          (fu_bc        ),
        .bc_fu          (bc_fu        ),
        .fu_ib          (fu_ib        ),
        .ib_fu          (ib_fu        )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   BC
// Description  :   Broadcaster
// --------------------------------------------------------------------
    BC BC_inst (
        .fu_bc          (fu_bc        ),
        .bc_fu          (bc_fu        ),
        .bc_prf         (bc_prf       )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   FL
// Description  :   Freelist
// --------------------------------------------------------------------
    FL_sim FL_inst (
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .fl_dp_o        (fl_dp                  ),
        .dp_fl_i        (dp_fl                  ),
        .rob_fl_i       (rob_fl                 ),
        .vfl_i          (vfl                    ),
        .rollback_i     (exception_i || br_mis  )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   VFL
// Description  :   Victim Freelist
// --------------------------------------------------------------------
    VFL_sim VFL_inst (
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .rob_vfl_i      (rob_vfl                ),
        .vlf_o          (vlf                    ),
        .roll_back_i    (exception_i || br_mis  )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    // Testing
    //      Dispatch
    assign  dp_rs_mon_o     =   dp_rs       ;
    //      Issue
    assign  rs_ib_mon_o     =   rs_ib       ;
    //      Execute
    assign  ib_fu_mon_o     =   ib_fu       ;
    //      Complete
    assign  fu_bc_mon_o     =   fu_bc       ;
    assign  cdb_mon_o       =   cdb         ;
    //      Retire
    assign  rob_amt_mon_o   =   rob_amt     ;
    assign  rob_fl_mon_o    =   rob_fl      ;
    assign  rob_vfl_mon_o   =   rob_vfl     ;
    assign  br_mis_mon_o    =   br_mis      ;
// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule