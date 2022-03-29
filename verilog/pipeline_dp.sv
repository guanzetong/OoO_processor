/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pipeline_dp.sv                                      //
//                                                                     //
//  Description :  Integrate Dispatcher, RS, ROB, PRF, IB              // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module pipeline_dp #(
    parameter   C_PARAM     =   0                   //  A place holder. Delete it.
) (
    input   logic                       clk_i       ,   //  Clock
    input   logic                       rst_i       ,   //  Reset
    input   FIQ_DP                      fiq_dp      ,
    output  DP_FIQ                      dp_fiq      ,
    input   CDB     [C_CDB_NUM-1:0]     cdb         ,
    output  ROB_AMT [C_RT_NUM-1:0]      rob_amt     ,
    output  ROB_FL                      rob_fl      ,
    input   FU_IB   [C_FU_NUM-1:0]      fu_ib       ,
    output  IB_FU   [C_FU_NUM-1:0]      ib_fu       ,
    input   BC_PRF                      bc_prf      ,
    output  BR_MIS                      br_mis      ,
    input   logic                       exception_i ,

    // //MT
    // input   logic                          rollback_i   ,    

    // input   DP_MT_READ  [C_DP_NUM-1:0]     dp_mt_read   ,
    // input   DP_MT_WRITE [C_DP_NUM-1:0]     dp_mt_write  ,
    // input   AMT_ENTRY [C_MT_ENTRY_NUM-1:0] amt          ,
    // output  MT_DP       [C_DP_NUM-1:0]     mt_dp        ,

    // //AMT
    // input   ROB_AMT      [C_RT_NUM-1:0]         rob_amt , 
    // output  AMT_OUTPUT   [C_MT_ENTRY_NUM-1:0]   amt_o   ,

    // //FU

    // //BC
    // input   FU_BC                          fu_bc  ,
    // output  BC_FU                          bc_fu  ,
    // output  BC_PRF                         bc_prf ,

    //ROB testing
    output  ROB_ENTRY   [C_ROB_ENTRY_NUM-1:0]   rob_mon_o       ,
    output  logic   [C_RT_NUM-1:0][C_XLEN-1:0]  rt_pc_o         ,
    output  logic   [C_RT_NUM-1:0]              rt_valid_o      ,

    //RS testing
    output  RS_ENTRY [C_RS_ENTRY_NUM-1:0]    rs_mon_o           ,

    //MT_sim testing
    output  MT_ENTRY [C_ARCH_REG_NUM-1:0]    mt_mon_o           ,

    //IB testing
    output  IS_INST  [C_ALU_Q_SIZE  -1:0]    ALU_queue_mon_o    ,
    output  IS_INST  [C_MULT_Q_SIZE -1:0]    MULT_queue_mon_o   ,
    output  IS_INST  [C_BR_Q_SIZE   -1:0]    BR_queue_mon_o     ,
    output  IS_INST  [C_LOAD_Q_SIZE -1:0]    LOAD_queue_mon_o   ,
    output  IS_INST  [C_STORE_Q_SIZE-1:0]    STORE_queue_mon_o  ,

    //monitor
    output  DP_RS                       dp_rs_mon_o             ,
    output  CDB                         cdb_mon_o               ,
    output  RS_IB                       rs_ib_mon_o             
    //*output IB_FU                     ib_fu_mon_o
    //*output FU_BC                     fu_bc_mon_o
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
    ROB_DP                      rob_dp      ;
    DP_ROB                      dp_rob      ;
    MT_DP   [`DP_NUM-1:0]       mt_dp       ;
    DP_MT   [`DP_NUM-1:0]       dp_mt       ;
    FL_DP                       fl_dp       ;
    DP_FL                       dp_fl       ;
    // FIQ_DP                      fiq_dp      ;
    // DP_FIQ                      dp_fiq      ;
    RS_DP                       rs_dp       ;
    DP_RS                       dp_rs       ;
    // CDB                         cdb         ;
    RS_IB   [`IS_NUM-1:0]       rs_ib       ;
    IB_RS                       ib_rs       ;
    RS_PRF  [`IS_NUM-1:0]       rs_prf      ;
    PRF_RS  [`IS_NUM-1:0]       prf_rs      ;
    BR_MIS                      br_mis      ;
    // ROB_AMT [C_RT_NUM-1:0]      rob_amt     ;
    // ROB_FL                      rob_fl      ;
    // FU_IB   [C_FU_NUM-1:0]      fu_ib       ;
    // IB_FU   [C_FU_NUM-1:0]      ib_fu       ;
    // BC_PRF                      bc_prf      ;

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
        .dp_mt_o        (dp_mt          ),
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
        .clk_i           (clk_i         ),
        .rst_i           (rst_i         ),
        .ib_rs_o         (ib_rs         ),
        .rs_ib_i         (rs_ib         ),
        .fu_ib_i         (fu_ib         ),
        .ib_fu_o         (ib_fu         ),
        .br_mis_i        (br_mis        ),
        .exception_i     (exception_i   ),
        //IB testing    
        .ALU_queue_mon_o    (ALU_queue_mon_o  ),
        .MULT_queue_mon_o   (MULT_queue_mon_o ),
        .BR_queue_mon_o     (BR_queue_mon_o   ),
        .LOAD_queue_mon_o   (LOAD_queue_mon_o ),
        .STORE_queue_mon_o  (STORE_queue_mon_o)
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
        .clk_i          (clk_i        ),
        .rst_i          (rst_i        ),
        .rollback_i     (rollback_i   ),    
        .cdb_i          (cdb          ),
        .dp_mt_read_i   (dp_mt_read   ),
        .dp_mt_write_i  (dp_mt_write  ),
        .amt_i          (amt          ),
        .mt_dp_o        (mt_dp        ),
         // For Testing
        .mt_mon_o       (mt_mon_o)
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   AMT
// Description  :   Arch. Map Table
// --------------------------------------------------------------------
    AMT AMT_inst (
        .clk_i          (clk_i        ),
        .rst_i          (rst_i        ),
        .rollback_i     (rollback_i   ),    
        .rob_amt_i      (rob_amt      ),
        .amt_o          (amt_o        )
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

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    assign dp_rs_mon_o = dp_rs  ;
    assign cdb_mon_o   = cdb    ;
    assign rs_ib_mon_o = rs_ib  ;
// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule